defmodule Trivia.PuntajeTest do
  use ExUnit.Case, async: true

  alias Trivia.Puntaje

  describe "de_ronda/4" do
    test "correcta con bonificación (tiempo 15)" do
      assert Puntaje.de_ronda(:basico, :correcta, 14, 15) == 14
      assert Puntaje.de_ronda(:basico, :correcta, 11, 15) == 13
      assert Puntaje.de_ronda(:avanzado, :correcta, 6, 15) == 22
      assert Puntaje.de_ronda(:basico, :correcta, 1, 15) == 10
    end

    test "la bonificación se reparte con el mismo criterio con tiempo 30" do
      assert Puntaje.de_ronda(:intermedio, :correcta, 28, 30) == 19
      assert Puntaje.de_ronda(:intermedio, :correcta, 2, 30) == 15
    end

    test "incorrecta resta según el nivel" do
      assert Puntaje.de_ronda(:basico, :incorrecta, 5, 15) == -5
      assert Puntaje.de_ronda(:intermedio, :incorrecta, 5, 15) == -8
      assert Puntaje.de_ronda(:avanzado, :incorrecta, 5, 15) == -10
    end

    test "sin responder vale 0" do
      assert Puntaje.de_ronda(:avanzado, :sin_respuesta, 0, 15) == 0
    end
  end
end
