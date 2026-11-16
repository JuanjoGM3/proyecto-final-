defmodule Trivia.SupervisorPartidas do
  @moduledoc "DynamicSupervisor de partidas (guía 16). Cada partida se agrega en tiempo de ejecución."
  use DynamicSupervisor

  def start_link(_opts), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  # :transient (guía 16): se reinicia si falla, no si termina bien
  def iniciar_partida(args) do
    hijo = Supervisor.child_spec({Trivia.Partida, args}, restart: :transient)
    DynamicSupervisor.start_child(__MODULE__, hijo)
  end
end
