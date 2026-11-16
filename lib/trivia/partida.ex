defmodule Trivia.Partida do
  @moduledoc """
  GenServer de una partida (sección 3.3). Un proceso por partida, supervisado
  con restart: :transient. Los argumentos son los mismos en cada reinicio:
  %{id, creador, cliente_pid, tema, total, tiempo, nivel}
  """
  use GenServer

  alias Trivia.{BancoPreguntas, Bot, GestorPartidas, Persistencia, Pregunta, Puntaje, Resultado}

  @max_jugadores 4
  @min_bots 2
  @pausa_entre_rondas 3_000

  # jugadores: %{nombre => pid que recibe las notificaciones}
  # ronda: nil o %{numero, inicio_ms, respuestas: %{jugador => {letra, instante_ms}}}
  defstruct [
    :id,
    :creador,
    :tema,
    :nivel,
    :total,
    :tiempo,
    estado: :esperando,
    jugadores: %{},
    bots: [],
    puntajes: %{},
    preguntas: [],
    pregunta_actual: 0,
    ronda: nil
  ]

  ## API del cliente
  def start_link(args), do: GenServer.start_link(__MODULE__, args)

  def agregar_bot(pid, dificultad), do: GenServer.call(pid, {:agregar_bot, dificultad})
  def iniciar(pid), do: GenServer.call(pid, :iniciar)
  def responder(pid, jugador, letra), do: GenServer.call(pid, {:responder, jugador, letra})
  def abandonar(pid, jugador), do: GenServer.call(pid, {:abandonar, jugador})

  ## Validaciones puras (se prueban sin levantar procesos)
  # Reciben el struct %Partida{} y devuelven :ok o {:error, razon}.

  def validar_agregar_bot(%__MODULE__{} = partida) do
    cond do
      partida.estado != :esperando -> {:error, :partida_iniciada}
      map_size(partida.jugadores) >= @max_jugadores -> {:error, :partida_llena}
      true -> :ok
    end
  end

  def validar_inicio(%__MODULE__{} = partida) do
    cond do
      partida.estado != :esperando -> {:error, :partida_iniciada}
      length(partida.bots) < @min_bots -> {:error, :bots_insuficientes}
      true -> :ok
    end
  end

  def validar_respuesta(%__MODULE__{} = partida, jugador, letra) do
    cond do
      partida.ronda == nil -> {:error, :sin_ronda_abierta}
      not Pregunta.letra_valida?(letra) -> {:error, :respuesta_invalida}
      Map.has_key?(partida.ronda.respuestas, jugador) -> {:error, :ya_respondio}
      true -> :ok
    end
  end

  ## Callbacks
  @impl true
  def init(args) do
    # cast (nunca call): el gestor está esperando al supervisor y un call lo bloquearía
    GestorPartidas.reportar(args.id, self())

    {:ok,
     %__MODULE__{
       id: args.id,
       creador: args.creador,
       tema: args.tema,
       nivel: args.nivel,
       total: args.total,
       tiempo: args.tiempo,
       jugadores: %{args.creador => args.cliente_pid},
       puntajes: %{args.creador => 0}
     }}
  end

  @impl true
  def handle_call({:agregar_bot, dificultad}, _from, partida) do
    case validar_agregar_bot(partida) do
      :ok ->
        nombre = "bot_#{length(partida.bots) + 1}"
        # start_link desde la partida: el bot queda enlazado y muere con ella
        {:ok, pid} = Bot.start_link(%{nombre: nombre, dificultad: dificultad, partida: self()})

        nueva = %{
          partida
          | jugadores: Map.put(partida.jugadores, nombre, pid),
            bots: [nombre | partida.bots],
            puntajes: Map.put(partida.puntajes, nombre, 0)
        }

        {:reply, {:ok, nombre}, nueva}

      {:error, razon} ->
        {:reply, {:error, razon}, partida}
    end
  end

  def handle_call(:iniciar, _from, partida) do
    case validar_inicio(partida) do
      :ok ->
        preguntas = BancoPreguntas.sortear(partida.tema, partida.total, partida.nivel)

        partida =
          %{partida | estado: :en_curso, preguntas: preguntas, pregunta_actual: 0}
          |> enviar_pregunta()

        {:reply, :ok, partida}

      {:error, razon} ->
        {:reply, {:error, razon}, partida}
    end
  end

  def handle_call({:responder, jugador, letra}, _from, partida) do
    case validar_respuesta(partida, jugador, letra) do
      :ok ->
        ahora = System.monotonic_time(:millisecond)

        ronda = %{
          partida.ronda
          | respuestas: Map.put(partida.ronda.respuestas, jugador, {letra, ahora})
        }

        partida = %{partida | ronda: ronda}

        # Si ya respondieron todos, la ronda cierra sin esperar al temporizador
        partida =
          if map_size(ronda.respuestas) >= map_size(partida.jugadores) do
            cerrar_ronda(partida)
          else
            partida
          end

        {:reply, :ok, partida}

      {:error, razon} ->
        {:reply, {:error, razon}, partida}
    end
  end

  # Antes de iniciar: solo el creador puede estar, así que la partida se cancela
  def handle_call({:abandonar, _jugador}, _from, %__MODULE__{estado: :esperando} = partida) do
    GestorPartidas.finalizada(partida.id)
    {:stop, :normal, :ok, partida}
  end

  # En curso: termina de inmediato y registra los puntajes obtenidos hasta ahora (6.5)
  def handle_call({:abandonar, _jugador}, _from, partida) do
    finalizar(partida)
    {:stop, :normal, :ok, partida}
  end

  @impl true
  def handle_info({:vence, numero_ronda}, partida) do
    # Si la ronda ya cerró (respondieron todos), este aviso viejo se ignora
    if partida.ronda != nil and partida.ronda.numero == numero_ronda do
      {:noreply, cerrar_ronda(partida)}
    else
      {:noreply, partida}
    end
  end

  def handle_info(:siguiente_ronda, partida) do
    siguiente = partida.pregunta_actual + 1

    if siguiente < length(partida.preguntas) do
      {:noreply, enviar_pregunta(%{partida | pregunta_actual: siguiente})}
    else
      finalizar(partida)
      {:stop, :normal, partida}
    end
  end

  def handle_info(_otro, partida), do: {:noreply, partida}

  ## Lógica de ronda

  defp enviar_pregunta(partida) do
    pregunta = Enum.at(partida.preguntas, partida.pregunta_actual)
    numero = partida.pregunta_actual + 1

    info = %{
      numero: numero,
      total: length(partida.preguntas),
      tema: pregunta.tema,
      nivel: pregunta.nivel,
      enunciado: pregunta.enunciado,
      opciones: pregunta.opciones,
      tiempo: partida.tiempo
    }

    # Solo los bots reciben la respuesta correcta (viven en el servidor)
    Enum.each(partida.jugadores, fn {nombre, pid} ->
      if bot?(nombre) do
        send(pid, {:pregunta, info, pregunta.respuesta})
      else
        send(pid, {:pregunta, info})
      end
    end)

    inicio_ms = System.monotonic_time(:millisecond)
    Process.send_after(self(), {:vence, numero}, partida.tiempo * 1000)

    %{partida | ronda: %{numero: numero, inicio_ms: inicio_ms, respuestas: %{}}}
  end

  defp cerrar_ronda(partida) do
    pregunta = Enum.at(partida.preguntas, partida.pregunta_actual)
    ronda = partida.ronda

    puntos_ronda =
      Enum.reduce(partida.jugadores, %{}, fn {nombre, _pid}, acc ->
        respuesta = Map.get(ronda.respuestas, nombre)

        resultado =
          case respuesta do
            nil -> :sin_respuesta
            {letra, _instante} when letra == pregunta.respuesta -> :correcta
            {_letra, _instante} -> :incorrecta
          end

        # Segundos restantes con decimales: Puntaje.bonificacion hace trunc al final
        restantes =
          case respuesta do
            {_letra, instante} ->
              max(0.0, partida.tiempo - (instante - ronda.inicio_ms) / 1000)

            nil ->
              0
          end

        puntos = Puntaje.de_ronda(pregunta.nivel, resultado, restantes, partida.tiempo)
        Map.put(acc, nombre, puntos)
      end)

    nuevos_puntajes =
      Enum.reduce(puntos_ronda, partida.puntajes, fn {nombre, puntos}, acc ->
        Map.update(acc, nombre, puntos, &(&1 + puntos))
      end)

    resumen = %{
      numero: ronda.numero,
      correcta: pregunta.respuesta,
      texto: pregunta.opciones[pregunta.respuesta],
      puntos_ronda: puntos_ronda,
      puntajes: nuevos_puntajes
    }

    Enum.each(partida.jugadores, fn {_nombre, pid} -> send(pid, {:fin_ronda, resumen}) end)

    # Después de la última ronda no hace falta esperar: se muestra el ranking ya
    if partida.pregunta_actual + 1 >= length(partida.preguntas) do
      send(self(), :siguiente_ronda)
    else
      Process.send_after(self(), :siguiente_ronda, @pausa_entre_rondas)
    end

    %{partida | ronda: nil, puntajes: nuevos_puntajes}
  end

  # Persiste el resultado y envía el ranking final a los humanos.
  # Sirve tanto para el final normal como para el abandono (secciones 6.5 y 7).
  defp finalizar(partida) do
    maximo = partida.puntajes |> Map.values() |> Enum.max()

    ganadores =
      partida.puntajes
      |> Enum.filter(fn {_jugador, puntos} -> puntos == maximo end)
      |> Enum.map(fn {jugador, _puntos} -> jugador end)
      |> Enum.sort()

    fecha =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601()

    Persistencia.agregar_resultado(%Resultado{
      fecha: fecha,
      id: partida.id,
      tema: partida.tema,
      nivel: Atom.to_string(partida.nivel),
      ganadores: ganadores,
      puntajes: partida.puntajes
    })

    ranking =
      partida.puntajes
      |> Enum.map(fn {jugador, puntos} -> %{jugador: jugador, puntaje: puntos} end)
      |> Enum.sort_by(fn fila -> {-fila.puntaje, fila.jugador} end)

    final = %{
      id: partida.id,
      tema: partida.tema,
      nivel: partida.nivel,
      ranking: ranking,
      ganadores: ganadores
    }

    Enum.each(partida.jugadores, fn {nombre, pid} ->
      if not bot?(nombre), do: send(pid, {:ranking_final, final})
    end)

    GestorPartidas.finalizada(partida.id)
  end

  defp bot?(nombre), do: String.starts_with?(nombre, "bot_")
end
