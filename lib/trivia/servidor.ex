defmodule Trivia.Servidor do

  use GenServer

  alias Trivia.{GestorJugadores, GestorPartidas}

  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok), do: {:ok, %{}}

  @impl true
  def handle_call({:peticion, receptor, comando}, _from, estado) do
    {:reply, despachar(comando, receptor), estado}
  end

  defp despachar({:connect, usuario, clave}, receptor),
    do: GestorJugadores.conectar(usuario, clave, receptor)

  # Todo lo demás exige sesión (with, guía 06)
  defp despachar(comando, receptor) do
    with {:ok, usuario} <- GestorJugadores.usuario_de(receptor) do
      ejecutar(comando, usuario, receptor)
    end
  end

  defp ejecutar(:disconnect, usuario, receptor) do
    GestorPartidas.salir(usuario)
    GestorJugadores.desconectar(receptor)
    {:ok, "Sesión cerrada."}
  end

  defp ejecutar(:score, usuario, _receptor), do: GestorJugadores.score(usuario)
  defp ejecutar({:ranking, tema}, _usuario, _receptor), do: GestorJugadores.ranking(tema)

  defp ejecutar({:create_game, tema, total, tiempo}, usuario, receptor),
    do: GestorPartidas.crear(usuario, receptor, tema, total, tiempo)

  defp ejecutar({:add_bot, dificultad}, usuario, _receptor), do: GestorPartidas.agregar_bot(usuario, dificultad)
  defp ejecutar(:start_game, usuario, _receptor), do: GestorPartidas.iniciar(usuario)
  defp ejecutar(:leave_game, usuario, _receptor), do: GestorPartidas.salir(usuario)
  defp ejecutar({:answer, letra}, usuario, _receptor), do: GestorPartidas.responder(usuario, letra)
  defp ejecutar(_otro, _usuario, _receptor), do: {:error, :comando_desconocido}
end
