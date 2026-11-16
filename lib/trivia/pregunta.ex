defmodule Trivia.Pregunta do
  @moduledoc "Pregunta del banco (sección 3.2)."
  @enforce_keys [:tema, :nivel, :enunciado, :opciones, :respuesta]
  defstruct [:tema, :nivel, :enunciado, :opciones, :respuesta]

  @letras ["A", "B", "C", "D"]

  def letras, do: @letras

  def letra_valida?(letra), do: letra in @letras

  @doc "Convierte un mapa leído de questions.json (claves en texto) en un struct."
  def de_mapa(%{"tema" => tema, "nivel" => nivel, "enunciado" => e, "opciones" => o, "respuesta" => r}) do
    %__MODULE__{tema: tema, nivel: Trivia.Nivel.de_texto(nivel), enunciado: e, opciones: o, respuesta: r}
  end
end
