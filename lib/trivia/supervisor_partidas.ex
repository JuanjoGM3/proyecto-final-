defmodule Trivia.SupervisorPartidas do

  use DynamicSupervisor

  def start_link(_opts), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  def iniciar_partida(args) do
    hijo = Supervisor.child_spec({Trivia.Partida, args}, restart: :transient)
    DynamicSupervisor.start_child(__MODULE__, hijo)
  end
end
