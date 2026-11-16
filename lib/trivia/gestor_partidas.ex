defmodule Trivia.GestorPartidas do
  @moduledoc "Crea y ubica partidas, y avisa al creador cuando una partida se reinicia (sección 8.5)."
  use GenServer

  alias Trivia.{BancoPreguntas, GestorJugadores, Partida, SupervisorPartidas}

  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def crear(creador, receptor, tema, total, tiempo),
    do: GenServer.call(__MODULE__, {:crear, creador, receptor, tema, total, tiempo})

  def agregar_bot(usuario, dificultad), do: con_partida(usuario, fn pid -> Partida.agregar_bot(pid, dificultad) end)
  def iniciar(usuario), do: con_partida(usuario, fn pid -> Partida.iniciar(pid) end)
  def responder(usuario, letra), do: con_partida(usuario, fn pid -> Partida.responder(pid, usuario, letra) end)
  def salir(usuario), do: con_partida(usuario, fn pid -> Partida.abandonar(pid, usuario) end)

  def reportar(id, pid), do: GenServer.cast(__MODULE__, {:reportar, id, pid})
  def finalizada(id), do: GenServer.cast(__MODULE__, {:finalizada, id})

  defp con_partida(usuario, funcion) do
    case GenServer.call(__MODULE__, {:pid_de, usuario}) do
      nil -> {:error, :sin_partida}
      pid -> funcion.(pid)
    end
  end

  @impl true
  def init(:ok), do: {:ok, %{partidas: %{}, por_jugador: %{}, contador: 1000}}

  @impl true
  def handle_call({:crear, creador, receptor, tema, total, tiempo}, _from, estado) do
    with :ok <- verificar_libre(estado, creador),
         nivel = GestorJugadores.nivel(creador, tema),
         :ok <- BancoPreguntas.validar(tema, total, nivel) do
      id = "P-#{estado.contador + 1}"
      args = %{id: id, creador: creador, cliente_pid: receptor, tema: tema, total: total, tiempo: tiempo, nivel: nivel}
      {:ok, pid} = SupervisorPartidas.iniciar_partida(args)

      nuevo = %{
        estado
        | contador: estado.contador + 1,
          partidas: Map.put(estado.partidas, id, %{pid: pid, receptor: receptor, creador: creador}),
          por_jugador: Map.put(estado.por_jugador, creador, id)
      }

      {:reply, {:ok, %{id: id, nivel: nivel}}, nuevo}
    else
      {:error, razon} -> {:reply, {:error, razon}, estado}
    end
  end

  def handle_call({:pid_de, usuario}, _from, estado) do
    case Map.get(estado.por_jugador, usuario) do
      nil -> {:reply, nil, estado}
      id -> {:reply, estado.partidas[id].pid, estado}
    end
  end

  @impl true
  def handle_cast({:reportar, id, pid}, estado) do
    case Map.get(estado.partidas, id) do
      %{pid: ^pid} ->
        {:noreply, estado}

      %{receptor: receptor} = entrada ->
        # Mismo id con otro PID: la partida se reinició tras una falla
        send(receptor, {:aviso, "La partida #{id} falló y se reinició sin su progreso. Agrega los bots y ejecuta start_game para jugar de nuevo."})
        {:noreply, %{estado | partidas: Map.put(estado.partidas, id, %{entrada | pid: pid})}}

      nil ->
        {:noreply, estado}
    end
  end

  def handle_cast({:finalizada, id}, estado) do
    case Map.pop(estado.partidas, id) do
      {nil, _} ->
        {:noreply, estado}

      {%{creador: creador}, partidas} ->
        {:noreply, %{estado | partidas: partidas, por_jugador: Map.delete(estado.por_jugador, creador)}}
    end
  end

  defp verificar_libre(estado, creador) do
    if Map.has_key?(estado.por_jugador, creador), do: {:error, :ya_en_partida}, else: :ok
  end
end
