defmodule Trivia.BotTest do
  use ExUnit.Case, async: true

  alias Trivia.Bot

  describe "decidir/4" do
    test "bot fácil: letra válida y retardo entre 40% y 90% del tiempo" do
      Enum.each(1..200, fn _ ->
        {letra, retardo} = Bot.decidir(:facil, :basico, "B", 15)
        assert letra in ["A", "B", "C", "D"]
        assert retardo in 6000..13_500
      end)
    end

    test "bot difícil: retardo entre 10% y 40% del tiempo" do
      Enum.each(1..200, fn _ ->
        {_letra, retardo} = Bot.decidir(:dificil, :avanzado, "C", 15)
        assert retardo in 1500..6000
      end)
    end
  end
end
