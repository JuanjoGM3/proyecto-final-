defmodule Trivia.Persistencia do
  @moduledoc """
  Único proceso que escribe en disco (sección 7): así las escrituras sobre users.json
  y results.log no se mezclan. Rutas con Path.join y __DIR__ (guía 11).
  """
  use GenServer

  alias Trivia.Resultado

  @datos Path.join(__DIR__, "../../data")
  @usuarios Path.join(@datos, "users.json")
  @historial Path.join(@datos, "results.log")
  @preguntas Path.join(@datos, "questions.json")

  ## API del cliente
  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def usuarios, do: GenServer.call(__MODULE__, :usuarios)
  def registrar_usuario(jugador), do: GenServer.call(__MODULE__, {:registrar, jugador})
  def agregar_resultado(resultado), do: GenServer.call(__MODULE__, {:resultado, resultado})

  @doc "Lista de %Pregunta{} leída de questions.json."
  def cargar_preguntas do
    with {:ok, contenido} <- File.read(@preguntas),
         {:ok, lista} <- Jason.decode(contenido) do
      {:ok, Enum.map(lista, &Trivia.Pregunta.de_mapa/1)}
    end
  end

  @doc "Stream perezoso de %Resultado{} (guía 10/11)."
  def historial do
    if File.exists?(@historial) do
      @historial
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.filter(fn linea -> linea != "" end)
      |> Stream.map(&Resultado.de_linea/1)
    else
      []
    end
  end

  ## Callbacks
  @impl true
  def init(:ok), do: {:ok, leer_usuarios()}

  # El estado es un mapa %{usuario => clave}
  @impl true
  def handle_call(:usuarios, _from, usuarios), do: {:reply, usuarios, usuarios}

  def handle_call({:registrar, jugador}, _from, usuarios) do
    nuevos = Map.put(usuarios, jugador.usuario, jugador.clave)
    guardar_usuarios(nuevos)
    {:reply, :ok, nuevos}
  end

  def handle_call({:resultado, resultado}, _from, usuarios) do
    respuesta = File.write(@historial, Resultado.a_linea(resultado) <> "\n", [:append])
    {:reply, respuesta, usuarios}
  end

  ## Funciones auxiliares
  defp leer_usuarios do
    with {:ok, contenido} <- File.read(@usuarios),
         {:ok, lista} <- Jason.decode(contenido) do
      lista
      |> Enum.map(fn u -> {u["usuario"], u["clave"]} end)
      |> Enum.into(%{})
    else
      _ -> %{}
    end
  end

  defp guardar_usuarios(usuarios) do
    lista = Enum.map(usuarios, fn {u, c} -> %{"usuario" => u, "clave" => c} end)
    File.write!(@usuarios, Jason.encode!(lista))
  end
end
