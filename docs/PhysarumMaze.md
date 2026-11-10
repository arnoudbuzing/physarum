---
Template: Symbol
Name: PhysarumMaze
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/PhysarumMaze
Keywords: [physarum, slime mold, maze, labyrinth, shortest path]
SeeAlso: [PhysarumFlow]
RelatedGuides: [Physarum]
---

## Usage

<code>PhysarumMaze[*n*]</code> generates an $n \times n$ maze as an [Image]() with white walls and black passages.

<code>PhysarumMaze[*n*, *opts*]</code> generates a maze with the given options.

## Details & Options

- *n* must be an integer $\ge 2$.
- [PhysarumMaze]() uses a randomized depth-first recursive backtracker starting at the top-left cell to generate a perfect spanning-tree maze, then opens `"Loops"` additional interior walls to create competing paths for [PhysarumFlow]().
- The resulting [Image]() has dimensions $(n \times \text{CellSize} + \text{WallWidth}) \times (n \times \text{CellSize} + \text{WallWidth})$ pixels, with `1.` (white) for walls and `0.` (black) for free passages.
- [PhysarumMaze]() accepts the following options:

| Option | Default | Description |
| --- | --- | --- |
| `"CellSize"` | `5` | width of a cell passage in pixels |
| `"WallWidth"` | `1` | thickness of walls in pixels |
| `"Loops"` | `0` | number of extra interior walls to open |
| [RandomSeeding]() | [Automatic]() | random seed for repeatable maze generation |

## Basic Examples

Generate a $10 \times 10$ maze and enlarge it without interpolation:

```wl
ImageResize[PhysarumMaze[10, RandomSeeding -> 1], 250, Resampling -> "Nearest"]
```

## Options

### `"Loops"`

Open extra interior walls to introduce alternative routes:

```wl
Table[ImageResize[PhysarumMaze[10, "Loops" -> k, RandomSeeding -> 2], 180, Resampling -> "Nearest"], {k, {0, 5, 20}}]
```

### `"CellSize"` and `"WallWidth"`

Adjust passage width and wall thickness:

```wl
PhysarumMaze[8, "CellSize" -> 12, "WallWidth" -> 3, RandomSeeding -> 1]
```

## Applications

Generate a looped maze and solve it with [PhysarumFlow]():

```wl
maze = PhysarumMaze[10, "Loops" -> 8, RandomSeeding -> 3];
PhysarumFlow[maze, {{0.05, 0.95}, {0.95, 0.05}}]
```
