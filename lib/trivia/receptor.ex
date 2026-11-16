defmodule Trivia.Receptor do
  @moduledoc "CLIENTE: proceso que recibe las notificaciones de la partida (como ChatClient, guía 16)."

  def iniciar, do: spawn(fn -> loop() end)

  defp loop do
    receive do
      {:pregunta, info} ->
        imprimir_pregunta(info)

      {:fin_ronda, resumen} ->
        IO.inspect(resumen, label: "\nFin de la ronda")   # TODO: formato de la sección 6.2

      {:ranking_final, ranking} ->
        IO.inspect(ranking, label: "\nRanking final")     # TODO: formato de la sección 7

      {:aviso, texto} ->
        IO.puts("\n#{texto}")

      otro ->
        IO.inspect(otro, label: "\nMensaje desconocido")
    end

    loop()
  end

  defp imprimir_pregunta(info) do
    IO.puts("\n═══ Pregunta #{info.numero} de #{info.total} - #{info.tema} - Nivel #{info.nivel} ═══")
    IO.puts(info.enunciado)

    info.opciones
    |> Enum.map(fn {letra, texto} -> "#{letra}) #{texto}" end)
    |> Enum.join("      ")
    |> IO.puts()

    IO.puts("Tiempo: #{info.tiempo} segundos\n")
  end
end
