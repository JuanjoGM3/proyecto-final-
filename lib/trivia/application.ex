defmodule Trivia.Application do
  @moduledoc """
  Aplicación OTP (guía 17). El nodo cuyo nombre empieza por "servidor" levanta el
  árbol de supervisión del servidor; cualquier otro nodo (clientes, mix test) no
  levanta nada y solo usa Trivia.Cliente.

      iex --sname servidor -S mix    # servidor
      iex --sname pedro -S mix       # cliente
  """
  use Application

  @impl true
  def start(_type, _args) do
    hijos = if servidor?(), do: hijos_servidor(), else: []

    # :rest_for_one (guía 16): cada hijo depende de los anteriores de la lista
    Supervisor.start_link(hijos, strategy: :rest_for_one, name: Trivia.Supervisor)
  end

  def servidor? do
    node()
    |> Atom.to_string()
    |> String.starts_with?("servidor")
  end

  defp hijos_servidor do
    [
      Trivia.Persistencia,
      Trivia.BancoPreguntas,
      Trivia.GestorJugadores,
      Trivia.SupervisorPartidas,
      Trivia.GestorPartidas,
      Trivia.Servidor
    ]
  end
end
