Compilar y probar

Desde la carpeta que contiene `mix.exs`:

```
mix deps.get
mix compile
mix test
```

Levantar el servidor y los clientes

Cada uno en su propia consola:

```
# Consola 1: servidor
iex --sname servidor -S mix

# Consola 2: cliente de Pedro
iex --sname pedro -S mix

# Consola 3: cliente de Carlos
iex --sname carlos -S mix
```

El nombre del servidor debe empezar por `servidor`. Los clientes no.

## Conectar un cliente

En la consola del cliente, con el nombre completo del servidor (aparece en su prompt, por ejemplo `servidor@mi-maquina`):

```
iex> Trivia.Cliente.iniciar("servidor@mi-maquina")
> connect pedro 1234
```

Comandos del juego

| Comando | Qué hace |
|---|---|
| `connect <usuario> <clave>` | Inicia sesión; si el usuario no existe, lo registra. |
| `disconnect` | Cierra la sesión y sale del cliente. |
| `score` | Puntaje acumulado, partidas jugadas y nivel por tema. |
| `ranking` | Ranking histórico global. |
| `ranking <tema>` | Ranking histórico de un tema. |
| `create_game tema=<tema> preguntas=<n> tiempo=<segundos>` | Crea una partida. |
| `add_bot facil` / `add_bot dificil` | Agrega un bot a la partida. |
| `start_game` | Inicia la partida (necesita 2 bots como mínimo). |
| `answer A` / `B` / `C` / `D` | Responde la pregunta en curso. |
| `leave_game` | Abandona la partida. |
| `help` | Muestra los comandos. |
| `exit` | Igual que `disconnect`. |

Temas disponibles: `ciencia`, `historia`, `geografia`, `deportes`.

Ejemplo

```
> connect pedro 1234
> create_game tema=ciencia preguntas=5 tiempo=15
> add_bot dificil
> add_bot facil
> start_game
> answer B
> score
> ranking ciencia
> exit
```
