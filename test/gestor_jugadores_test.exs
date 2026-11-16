defmodule Trivia.GestorJugadoresTest do
  use ExUnit.Case, async: true

  alias Trivia.{GestorJugadores, Resultado}

  defp resultado(tema, puntajes) do
    %Resultado{fecha: "2026-11-01", id: "P-1", tema: tema, nivel: :basico, ganadores: ["ana"], puntajes: puntajes}
  end

  setup do
    historial = [
      resultado("ciencia", %{"ana" => 72, "bot_1" => 22, "bot_2" => -11}),
      resultado("historia", %{"ana" => 13, "pedro" => 40, "bot_1" => 99}),
      resultado("ciencia", %{"pedro" => -10, "bot_1" => 5})
    ]

    {:ok, historial: historial}
  end

  test "resumen: acumulado, partidas y nivel por tema", %{historial: historial} do
    resumen = GestorJugadores.resumen(historial, "ana")

    assert resumen.acumulado == 85
    assert resumen.partidas == 2
    assert resumen.temas["ciencia"] == %{puntaje: 72, nivel: :intermedio}
    assert resumen.temas["historia"] == %{puntaje: 13, nivel: :basico}
  end

  test "ranking global ignora a los bots", %{historial: historial} do
    ranking = GestorJugadores.ranking_de(historial, nil)

    assert Enum.map(ranking, fn fila -> fila.jugador end) == ["ana", "pedro"]
    assert hd(ranking) == %{jugador: "ana", puntaje: 85, partidas: 2}
  end

  test "ranking filtrado por tema", %{historial: historial} do
    ranking = GestorJugadores.ranking_de(historial, "ciencia")

    assert Enum.map(ranking, fn fila -> {fila.jugador, fila.puntaje} end) == [{"ana", 72}, {"pedro", -10}]
  end
end
