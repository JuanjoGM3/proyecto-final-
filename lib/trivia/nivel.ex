defmodule Trivia.Nivel do
  @niveles [:basico, :intermedio, :avanzado]

  @porcentajes %{
    basico: %{basico: 70, intermedio: 30, avanzado: 0},
    intermedio: %{basico: 20, intermedio: 60, avanzado: 20},
    avanzado: %{basico: 0, intermedio: 30, avanzado: 70}
  }

  def niveles, do: @niveles

  def de_texto("basico"), do: :basico
  def de_texto("intermedio"), do: :intermedio
  def de_texto("avanzado"), do: :avanzado

  def nivel_de(puntaje) when puntaje < 60, do: :basico
  def nivel_de(puntaje) when puntaje < 180, do: :intermedio
  def nivel_de(_puntaje), do: :avanzado

  def puntaje_por_tema(entradas, usuario, tema) do
    entradas
    |> Enum.filter(fn entrada -> entrada.tema == tema end)
    |> Enum.map(fn entrada -> Map.get(entrada.puntajes, usuario, 0) end)
    |> Enum.sum()
  end

  def nivel_en_tema(entradas, usuario, tema) do
    entradas
    |> puntaje_por_tema(usuario, tema)
    |> nivel_de()
  end

  def reparto(nivel, total) do
    porcentajes = Map.fetch!(@porcentajes, nivel)

    otros =
      @niveles
      |> Enum.reject(fn n -> n == nivel end)
      |> Enum.map(fn n -> {n, div(total * porcentajes[n], 100)} end)
      |> Enum.into(%{})

    Map.put(otros, nivel, total - Enum.sum(Map.values(otros)))
  end
end
