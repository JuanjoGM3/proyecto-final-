defmodule Trivia.Pregunta do

  @enforce_keys [:tema, :nivel, :enunciado, :opciones, :respuesta]
  defstruct [:tema, :nivel, :enunciado, :opciones, :respuesta]

  @letras ["A", "B", "C", "D"]

  def letras, do: @letras

  def letra_valida?(letra), do: letra in @letras

  def de_mapa(%{"tema" => tema, "nivel" => nivel, "enunciado" => e, "opciones" => o, "respuesta" => r}) do
    %__MODULE__{tema: tema, nivel: Trivia.Nivel.de_texto(nivel), enunciado: e, opciones: o, respuesta: r}
  end
end
