defmodule Trivia.NivelTest do
  use ExUnit.Case, async: true

  alias Trivia.{Nivel, Resultado}

  defp resultado(tema, puntajes) do
    %Resultado{fecha: "2026-11-01", id: "P-1", tema: tema, nivel: :basico, ganadores: ["ana"], puntajes: puntajes}
  end

  describe "nivel_de/1" do
    test "respeta los umbrales" do
      assert Nivel.nivel_de(59) == :basico
      assert Nivel.nivel_de(60) == :intermedio
      assert Nivel.nivel_de(179) == :intermedio
      assert Nivel.nivel_de(180) == :avanzado
    end

    test "un puntaje negativo es básico" do
      assert Nivel.nivel_de(-30) == :basico
    end
  end

  describe "nivel_en_tema/3" do
    test "suma solo el tema pedido y los negativos restan" do
      historial = [
        resultado("ciencia", %{"ana" => 70, "bot_1" => 500}),
        resultado("ciencia", %{"ana" => -20}),
        resultado("historia", %{"ana" => 500})
      ]

      assert Nivel.puntaje_por_tema(historial, "ana", "ciencia") == 50
      assert Nivel.nivel_en_tema(historial, "ana", "ciencia") == :basico
    end

    test "un tema nunca jugado empieza en básico" do
      assert Nivel.nivel_en_tema([], "ana", "arte") == :basico
    end
  end

  describe "reparto/2" do
    test "jugador básico con 5 preguntas" do
      assert Nivel.reparto(:basico, 5) == %{basico: 4, intermedio: 1, avanzado: 0}
    end

    test "jugador avanzado con 10 preguntas" do
      assert Nivel.reparto(:avanzado, 10) == %{basico: 0, intermedio: 3, avanzado: 7}
    end
  end
end
