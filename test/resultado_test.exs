defmodule Trivia.ResultadoTest do
  use ExUnit.Case, async: true

  alias Trivia.Resultado

  test "una línea del historial se convierte en struct y de vuelta" do
    linea = "2026-11-09T10:00:00Z|P-1001|ciencia|basico|pedro|bot_1=22,bot_2=-11,pedro=48"
    resultado = Resultado.de_linea(linea)

    assert resultado.id == "P-1001"
    assert resultado.nivel == :basico
    assert resultado.ganadores == ["pedro"]
    assert resultado.puntajes == %{"pedro" => 48, "bot_1" => 22, "bot_2" => -11}
    assert resultado |> Resultado.a_linea() |> Resultado.de_linea() == resultado
  end

  test "ganador compartido" do
    resultado = Resultado.de_linea("2026-11-09|P-2|historia|avanzado|ana;pedro|ana=30,pedro=30")
    assert resultado.ganadores == ["ana", "pedro"]
  end
end
