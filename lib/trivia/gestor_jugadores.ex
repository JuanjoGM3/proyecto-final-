defmodule Trivia.GestorJugadores do
  @moduledoc "Registro, sesiones, puntajes y ranking. Las estadísticas se calculan desde el historial."
  use GenServer

  alias Trivia.{GestorPartidas, Jugador, Nivel, Persistencia}

  ## API del cliente
  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def conectar(usuario, clave, receptor), do: GenServer.call(__MODULE__, {:conectar, usuario, clave, receptor})
  def desconectar(receptor), do: GenServer.call(__MODULE__, {:desconectar, receptor})
  def usuario_de(receptor), do: GenServer.call(__MODULE__, {:usuario_de, receptor})

  def nivel(usuario, tema),
    do: Nivel.nivel_en_tema(Persistencia.historial(), usuario, tema)

  def score(usuario), do: {:ok, resumen(Enum.to_list(Persistencia.historial()), usuario)}
  def ranking(tema), do: {:ok, ranking_de(Enum.to_list(Persistencia.historial()), tema)}

  ## Estadísticas puras (reciben las entradas del historial)
  def resumen(entradas, usuario) do
    por_tema =
      entradas
      |> Enum.filter(fn e -> Map.has_key?(e.puntajes, usuario) end)
      |> Enum.reduce(%{}, fn e, acc ->
        Map.update(acc, e.tema, {e.puntajes[usuario], 1}, fn {suma, n} -> {suma + e.puntajes[usuario], n + 1} end)
      end)

    temas =
      por_tema
      |> Enum.map(fn {tema, {puntaje, _n}} -> {tema, %{puntaje: puntaje, nivel: Nivel.nivel_de(puntaje)}} end)
      |> Enum.into(%{})

    %{
      usuario: usuario,
      acumulado: por_tema |> Map.values() |> Enum.map(fn {puntaje, _n} -> puntaje end) |> Enum.sum(),
      partidas: por_tema |> Map.values() |> Enum.map(fn {_puntaje, n} -> n end) |> Enum.sum(),
      temas: temas
    }
  end

  # tema = nil -> ranking global. Las entradas de bots se ignoran.
  def ranking_de(entradas, tema) do
    entradas
    |> Enum.filter(fn e -> tema == nil or e.tema == tema end)
    |> Enum.reduce(%{}, fn e, acc ->
      Enum.reduce(e.puntajes, acc, fn {jugador, puntos}, acc2 ->
        if String.starts_with?(jugador, "bot_") do
          acc2
        else
          Map.update(acc2, jugador, {puntos, 1}, fn {suma, n} -> {suma + puntos, n + 1} end)
        end
      end)
    end)
    |> Enum.map(fn {jugador, {puntaje, partidas}} -> %{jugador: jugador, puntaje: puntaje, partidas: partidas} end)
    |> Enum.sort_by(fn fila -> {-fila.puntaje, fila.jugador} end)
  end

  ## Callbacks
  # Estado: %{pid_receptor => usuario}
  @impl true
  def init(:ok), do: {:ok, %{}}

  @impl true
  def handle_call({:conectar, usuario, clave, receptor}, _from, sesiones) do
    with {:ok, jugador} <- Jugador.nuevo(usuario, clave),
         :ok <- verificar_sin_sesion(sesiones, usuario),
         {:ok, mensaje} <- autenticar(jugador) do
      Process.monitor(receptor)
      {:reply, {:ok, mensaje}, Map.put(sesiones, receptor, usuario)}
    else
      {:error, razon} -> {:reply, {:error, razon}, sesiones}
    end
  end

  def handle_call({:usuario_de, receptor}, _from, sesiones) do
    case Map.get(sesiones, receptor) do
      nil -> {:reply, {:error, :sin_sesion}, sesiones}
      usuario -> {:reply, {:ok, usuario}, sesiones}
    end
  end

  def handle_call({:desconectar, receptor}, _from, sesiones),
    do: {:reply, :ok, Map.delete(sesiones, receptor)}

  # El cliente se cerró (guía 16, Process.monitor): se aplica la sección 6.5
  @impl true
  def handle_info({:DOWN, _ref, :process, receptor, _razon}, sesiones) do
    {usuario, restantes} = Map.pop(sesiones, receptor)
    # spawn: GestorPartidas.salir es un call y aquí no se debe bloquear
    if usuario, do: spawn(fn -> GestorPartidas.salir(usuario) end)
    {:noreply, restantes}
  end

  ## Funciones auxiliares
  defp verificar_sin_sesion(sesiones, usuario) do
    if usuario in Map.values(sesiones), do: {:error, :sesion_duplicada}, else: :ok
  end

  # Si no existe lo registra; si existe, compara la clave
  defp autenticar(jugador) do
    case Map.get(Persistencia.usuarios(), jugador.usuario) do
      nil ->
        :ok = Persistencia.registrar_usuario(jugador)
        {:ok, "Usuario #{jugador.usuario} registrado y conectado."}

      clave when clave == jugador.clave ->
        {:ok, "Bienvenido, #{jugador.usuario}."}

      _otra ->
        {:error, :clave_incorrecta}
    end
  end
end
