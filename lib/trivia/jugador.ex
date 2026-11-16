defmodule Trivia.Jugador do
  @enforce_keys [:usuario, :clave]
  defstruct [:usuario, :clave]

  def nuevo(usuario, clave) do
    cond do
      String.starts_with?(usuario, "bot_") -> {:error, :usuario_reservado}
      usuario == "" or String.contains?(usuario, " ") -> {:error, :usuario_invalido}
      true -> {:ok, %__MODULE__{usuario: usuario, clave: clave}}
    end
  end
end
