defmodule Trivia.Bot do

  use GenServer

  alias Trivia.{Partida, Pregunta}


  @acierto %{
    facil: %{basico: 40, intermedio: 30, avanzado: 20},
    dificil: %{basico: 80, intermedio: 70, avanzado: 60}
  }

  @ventana %{facil: {40, 90}, dificil: {10, 40}}

  def decidir(dificultad, nivel, correcta, tiempo_pregunta) do
    acierta? = :rand.uniform(100) <= @acierto[dificultad][nivel]

    letra =
      if acierta? do
        correcta
      else
        Enum.random(Pregunta.letras() -- [correcta])
      end

    {minimo, maximo} = @ventana[dificultad]
    porcentaje = minimo + :rand.uniform(maximo - minimo + 1) - 1

    {letra, div(porcentaje * tiempo_pregunta * 1000, 100)}
  end


  def start_link(args), do: GenServer.start_link(__MODULE__, args)

  @impl true
  def init(args) do

    Process.monitor(args.partida)
    {:ok, args}
  end

  @impl true
  def handle_info({:pregunta, info, correcta}, estado) do
    {letra, retardo} = decidir(estado.dificultad, info.nivel, correcta, info.tiempo)
    Process.send_after(self(), {:responder, letra}, retardo)
    {:noreply, estado}
  end

  def handle_info({:responder, letra}, estado) do

    try do
      Partida.responder(estado.partida, estado.nombre, letra)
      {:noreply, estado}
    catch
      :exit, _ -> {:stop, :normal, estado}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, _razon}, estado) do
    {:stop, :normal, estado}
  end


  def handle_info(_otro, estado), do: {:noreply, estado}
end
