defmodule Trivia.BancoPreguntasTest do
  use ExUnit.Case, async: true

  alias Trivia.{BancoPreguntas, Pregunta}

  defp banco do
    Enum.flat_map([:basico, :intermedio, :avanzado], fn nivel ->
      Enum.map(1..8, fn n ->
        %Pregunta{tema: "ciencia", nivel: nivel, enunciado: "#{nivel} #{n}", opciones: %{}, respuesta: "A"}
      end)
    end)
  end

  describe "sortear_en/4" do
    test "cantidad, tema, sin repetir, reparto y orden por nivel" do
      sorteo = BancoPreguntas.sortear_en(banco(), "ciencia", 10, :avanzado)

      assert length(sorteo) == 10
      assert Enum.all?(sorteo, fn p -> p.tema == "ciencia" end)
      assert length(Enum.uniq(sorteo)) == 10
      assert Enum.count(sorteo, fn p -> p.nivel == :intermedio end) == 3
      assert Enum.count(sorteo, fn p -> p.nivel == :avanzado end) == 7
      assert Enum.map(sorteo, fn p -> p.nivel end) == List.duplicate(:intermedio, 3) ++ List.duplicate(:avanzado, 7)
    end
  end

  describe "validar_en/4" do
    test "tema inexistente" do
      assert BancoPreguntas.validar_en(banco(), "arte", 5, :basico) == {:error, :tema_inexistente}
    end

    test "preguntas insuficientes para el reparto" do
      assert BancoPreguntas.validar_en(banco(), "ciencia", 20, :basico) == {:error, :preguntas_insuficientes}
    end

    test "tema válido" do
      assert BancoPreguntas.validar_en(banco(), "ciencia", 10, :intermedio) == :ok
    end
  end
end
