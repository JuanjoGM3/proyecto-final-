defmodule Trivia.Jugador do
  @moduledoc "Jugador registrado (sección 3.1). Sin estadísticas: se calculan desde el historial."
  @enforce_keys [:usuario, :clave]
  defstruct [:usuario, :clave]

  # Constructor con validación (guía 09, Pokemon.nuevo/2)
  def nuevo(usuario, clave) do
    cond do
      String.starts_with?(usuario, "bot_") -> {:error, :usuario_reservado}
      usuario == "" or String.contains?(usuario, " ") -> {:error, :usuario_invalido}
      true -> {:ok, %__MODULE__{usuario: usuario, clave: clave}}
    end
  end
end
