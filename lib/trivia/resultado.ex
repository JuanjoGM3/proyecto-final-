defmodule Trivia.Resultado do

  @enforce_keys [:fecha, :id, :tema, :nivel, :ganadores, :puntajes]
  defstruct [:fecha, :id, :tema, :nivel, :ganadores, :puntajes]

  def a_linea(%__MODULE__{} = r) do
    puntajes =
      r.puntajes
      |> Enum.map(fn {jugador, puntos} -> "#{jugador}=#{puntos}" end)
      |> Enum.join(",")

    Enum.join([r.fecha, r.id, r.tema, r.nivel, Enum.join(r.ganadores, ";"), puntajes], "|")
  end

  def de_linea(linea) do
    [fecha, id, tema, nivel, ganadores, puntajes] = String.split(linea, "|")

    %__MODULE__{
      fecha: fecha,
      id: id,
      tema: tema,
      nivel: Trivia.Nivel.de_texto(nivel),
      ganadores: String.split(ganadores, ";"),
      puntajes:
        puntajes
        |> String.split(",")
        |> Enum.map(fn par ->
          [jugador, puntos] = String.split(par, "=")
          {jugador, String.to_integer(puntos)}
        end)
        |> Enum.into(%{})
    }
  end
end
