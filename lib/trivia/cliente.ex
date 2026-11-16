defmodule Trivia.Cliente do


  alias Trivia.{Errores, Receptor}

  @timeout 10_000

  @doc ~s|Uso, desde iex: Trivia.Cliente.iniciar("servidor@mi-maquina")|
  def iniciar(servidor) do
    nodo = String.to_atom(servidor)

    if Node.connect(nodo) == true do
      IO.puts("Conectado a #{nodo}. Escribe help para ver los comandos.")
      loop(nodo, Receptor.iniciar())
    else
      IO.puts(:standard_error, Errores.mensaje(:servidor_no_disponible))
    end
  end

  defp loop(nodo, receptor) do
    case leer() |> parsear() do
      :salir ->
        pedir(nodo, receptor, :disconnect)
        IO.puts("Hasta luego.")

      :help ->
        IO.puts(ayuda())
        loop(nodo, receptor)

      {:ok, comando} ->
        nodo |> pedir(receptor, comando) |> mostrar()
        loop(nodo, receptor)

      {:error, razon} ->
        mostrar({:error, razon})
        loop(nodo, receptor)
    end
  end

  defp leer do
    case IO.gets("> ") do
      linea when is_binary(linea) -> String.split(linea)
      _ -> ["exit"]
    end
  end

  defp pedir(nodo, receptor, comando) do
    GenServer.call({Trivia.Servidor, nodo}, {:peticion, receptor, comando}, @timeout)
  catch
    :exit, _ -> {:error, :servidor_no_disponible}
  end

  defp mostrar({:ok, mensaje}) when is_binary(mensaje), do: IO.puts(mensaje)
  defp mostrar({:ok, datos}), do: IO.inspect(datos)   # TODO: formato de score y ranking (sección 4.2)
  defp mostrar(:ok), do: :ok
  defp mostrar({:error, razon}), do: IO.puts(:standard_error, "Error: #{Errores.mensaje(razon)}")

  defp parsear(["connect", usuario, clave]), do: {:ok, {:connect, usuario, clave}}
  defp parsear(["disconnect"]), do: :salir
  defp parsear(["exit"]), do: :salir
  defp parsear(["help"]), do: :help
  defp parsear(["score"]), do: {:ok, :score}
  defp parsear(["ranking"]), do: {:ok, {:ranking, nil}}
  defp parsear(["ranking", tema]), do: {:ok, {:ranking, tema}}
  defp parsear(["add_bot", "facil"]), do: {:ok, {:add_bot, :facil}}
  defp parsear(["add_bot", "dificil"]), do: {:ok, {:add_bot, :dificil}}
  defp parsear(["start_game"]), do: {:ok, :start_game}
  defp parsear(["leave_game"]), do: {:ok, :leave_game}
  defp parsear(["answer", letra]), do: {:ok, {:answer, String.upcase(letra)}}

  defp parsear(["create_game", "tema=" <> tema, "preguntas=" <> preguntas, "tiempo=" <> tiempo]) do
    with {total, ""} <- Integer.parse(preguntas),
         {segundos, ""} <- Integer.parse(tiempo) do
      {:ok, {:create_game, tema, total, segundos}}
    else
      _ -> {:error, :comando_desconocido}
    end
  end

  defp parsear(_otro), do: {:error, :comando_desconocido}

  defp ayuda do

  end
end
