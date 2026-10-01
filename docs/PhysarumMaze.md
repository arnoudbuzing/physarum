# PhysarumMaze

Generates a maze as an image, for [PhysarumFlow](PhysarumFlow.md) to solve.

## Syntax

| Form | Meaning |
| --- | --- |
| `PhysarumMaze[n]` | generates an `n × n` maze as an `Image`, with white walls and black passages |
| `PhysarumMaze[n, opts]` | with options |

## Details

* `n` is the number of cells along each side, and must be an integer of at least 2.
* The maze is made with a depth-first "recursive backtracker" starting at the top-left cell. It is a
  *perfect* maze: there is exactly one route between any two cells.
* The image is square, with `n × CellSize + WallWidth` pixels on a side (51 × 51 for `n = 10` with
  the defaults). Walls are white (value 1) and passages are black (value 0). This is the form that
  [PhysarumFlow](PhysarumFlow.md) reads.
* `"Loops"` opens extra walls after the maze is made, so that there is more than one route between
  places. This is what makes the maze interesting for the flow model, which has to choose between
  competing routes.
* The random numbers are local to the call, so it does not disturb the random state of your session.
  Use `RandomSeeding` to get the same maze again.

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `"CellSize"` | 5 | width of a passage, in pixels |
| `"WallWidth"` | 1 | thickness of the walls, in pixels |
| `"Loops"` | 0 | number of extra walls to open. Values larger than the number of walls that are left open all of them. |
| `RandomSeeding` | Automatic | seed for the random number generator, for a repeatable maze |

## Examples

### A maze

```wolfram
PhysarumMaze[10]
ImageDimensions[PhysarumMaze[10]]         (* {51, 51} *)
```

### A repeatable maze

The same seed gives the same maze:

```wolfram
PhysarumMaze[10, RandomSeeding -> 1] == PhysarumMaze[10, RandomSeeding -> 1]        (* True *)
Table[PhysarumMaze[6, RandomSeeding -> s], {s, 4}]
```

### Loops

A perfect maze has one route. Opening a few walls creates alternatives:

```wolfram
Table[PhysarumMaze[10, "Loops" -> k, RandomSeeding -> 2], {k, {0, 5, 20}}]
```

### Bigger passages, thicker walls

```wolfram
PhysarumMaze[8, "CellSize" -> 12, "WallWidth" -> 3, RandomSeeding -> 1]
ImageDimensions[PhysarumMaze[10, "CellSize" -> 8, "WallWidth" -> 2]]         (* {82, 82} *)
```

### Enlarge a maze for display

The images are small. Enlarge them without smoothing:

```wolfram
ImageResize[PhysarumMaze[12, RandomSeeding -> 5], 400, Resampling -> "Nearest"]
```

### Solve it

```wolfram
maze = PhysarumMaze[10, "Loops" -> 8, RandomSeeding -> 3];
PhysarumFlow[maze, {{0.05, 0.95}, {0.95, 0.05}}]
```

![Maze solving by flow reinforcement](../images/tutorial/maze.png)

## See also

[PhysarumFlow](PhysarumFlow.md)
