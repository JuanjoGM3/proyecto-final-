defmodule Trivia.Puntaje do

  @puntos %{basico: {10, -5}, intermedio: {15, -8}, avanzado: {20, -10}}

  def bonificacion(segundos_restantes, tiempo_pregunta) do
    trunc(5 * segundos_restantes / tiempo_pregunta)
  end

  def de_ronda(_nivel, :sin_respuesta, _restantes, _tiempo), do: 0

  def de_ronda(nivel, :incorrecta, _restantes, _tiempo) do
    {_correcta, incorrecta} = Map.fetch!(@puntos, nivel)
    incorrecta
  end

  def de_ronda(nivel, :correcta, restantes, tiempo) do
    {correcta, _incorrecta} = Map.fetch!(@puntos, nivel)
    correcta + bonificacion(restantes, tiempo)
  end
end
