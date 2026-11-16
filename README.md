# Trivia Concurrente

Proyecto Mix (guía 17). Servidor y clientes son nodos distintos: el rol lo decide el
nombre del nodo. Si empieza por `servidor`, se levanta el árbol de supervisión del juego;
cualquier otro nodo es un cliente y no levanta nada.

## Ejecutar (desde la carpeta que contiene mix.exs)

    mix deps.get
    mix test

    # Consola 1: servidor
    iex --sname servidor -S mix

    # Consola 2: cliente (el nombre de la máquina sale en el prompt del servidor)
    iex --sname pedro -S mix
    iex> Trivia.Cliente.iniciar("servidor@NOMBRE_DE_LA_MAQUINA")

## Formato de results.log

    fecha|id|tema|nivel|ganador(es)|jugador=puntos,jugador=puntos

## Notificaciones de la partida a los receptores

    {:pregunta, info}              # jugadores humanos
    {:pregunta, info, correcta}    # bots (el cliente nunca recibe la correcta)
    {:fin_ronda, resumen}
    {:ranking_final, ranking}
    {:aviso, texto}

