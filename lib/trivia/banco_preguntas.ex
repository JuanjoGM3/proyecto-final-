defmodule Trivia.BancoPreguntas do

  use GenServer

  alias Trivia.{Nivel, Persistencia}

  ## API del cliente
  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def validar(tema, total, nivel), do: GenServer.call(__MODULE__, {:validar, tema, total, nivel})
  def sortear(tema, total, nivel), do: GenServer.call(__MODULE__, {:sortear, tema, total, nivel})

  ## Funciones puras (se prueban sin proceso)
  def validar_en(preguntas, tema, total, nivel) do
    del_tema = Enum.filter(preguntas, fn p -> p.tema == tema end)

    if del_tema == [] do
      {:error, :tema_inexistente}
    else
      alcanzan? =
        nivel
        |> Nivel.reparto(total)
        |> Enum.all?(fn {n, cantidad} -> contar(del_tema, n) >= cantidad end)

      if alcanzan?, do: :ok, else: {:error, :preguntas_insuficientes}
    end
  end

  def sortear_en(preguntas, tema, total, nivel) do
    del_tema = Enum.filter(preguntas, fn p -> p.tema == tema end)
    reparto = Nivel.reparto(nivel, total)

    Nivel.niveles()
    |> Enum.flat_map(fn n ->
      del_tema
      |> Enum.filter(fn p -> p.nivel == n end)
      |> sacar_al_azar(Map.fetch!(reparto, n))
    end)
  end

  defp contar(preguntas, nivel), do: Enum.count(preguntas, fn p -> p.nivel == nivel end)

  # Recursión (guía 08): saca `n` elementos al azar sin repetir
  defp sacar_al_azar(_lista, 0), do: []

  defp sacar_al_azar(lista, n) do
    elegido = Enum.at(lista, :rand.uniform(length(lista)) - 1)
    [elegido | sacar_al_azar(List.delete(lista, elegido), n - 1)]
  end

  ## Callbacks
  @impl true
  def init(:ok) do
    case Persistencia.cargar_preguntas() do
      {:ok, preguntas} -> {:ok, preguntas}
      {:error, razon} -> {:stop, razon}
    end
  end

  @impl true
  def handle_call({:validar, tema, total, nivel}, _from, preguntas),
    do: {:reply, validar_en(preguntas, tema, total, nivel), preguntas}

  def handle_call({:sortear, tema, total, nivel}, _from, preguntas),
    do: {:reply, sortear_en(preguntas, tema, total, nivel), preguntas}
end
