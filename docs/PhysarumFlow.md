# PhysarumFlow

Runs the tube-and-flow model of the slime mould (Tero *et al.*): protoplasm flows through a network
of tubes, tubes that carry more flow become thicker, and tubes that carry little wither. It solves
mazes and grows adaptive transport networks.

## Syntax

| Form | Meaning |
| --- | --- |
| `PhysarumFlow[maze, {p1, p2, ...}]` | runs the model through the free cells of a maze `Image`, with food at the points `pi` of the unit square. Returns an `Image` by default. |
| `PhysarumFlow[{p1, p2, ...}]` | grows a flow network between food sources given as points in the plane. Returns a `Graph` by default. |
| `PhysarumFlow[graph, {v1, v2, ...}]` | runs the model on a `Graph`, with food at the vertices `vi`. Returns a `Graph` by default. |
| `PhysarumFlow[..., opts]` | with options |

## Details

### The model

* The network is a set of tubes. Tube *e* has a length *L* and a conductivity *D* that starts at 1.
* Food at one place **pumps** protoplasm in (flux `"Flux"`), and food elsewhere **drains** it. The
  flow splits over the tubes like electric current in a circuit: the pressures follow from
  Kirchhoff's laws, and the flow through a tube is *Q = D/L (p₁ − p₂)*.
* Every tube adapts: *dD/dt = f(|Q|) − D*. Tubes with a lot of flow thicken, and tubes with
  little flow shrink.
* With **two** food sources, the first one pumps and the second one drains, and *f(Q) = |Q|*. Only the
  shortest path between them survives.
* With **more than two** food sources, each step picks one source at random to pump, and lets all the
  others drain. Now *f(Q) = |Q|^γ / (1 + |Q|^γ)* with γ = 1.8. The result is a network that serves
  all the sources, and `"Flux"` decides how lean or how redundant it is.
* Set `"Exponent"` to a number to use a different γ (always with the second form of *f*).

### The three forms

* **Maze image.** Free (black) pixels are nodes and neighbouring free pixels are joined by tubes.
  White pixels are walls. The food points are in the unit square with y pointing up (`{0, 0}` is the
  bottom left). Each food point is moved to the nearest free pixel. Make mazes with
  [PhysarumMaze](PhysarumMaze.md).
* **Points.** A lattice (with diagonals) is laid over the points, with 8% padding.
  `"Resolution"` sets the number of lattice nodes along the longest side, and each point is moved to
  its nearest node. The mould then grows through the lattice, and the result is a graph of the
  surviving tubes.
* **Graph.** The food sources are vertices of the graph. Tube lengths are the `EdgeWeight`s if the
  graph is weighted, else the distances between the `VertexCoordinates` if you set them,
  else 1. An automatic layout is never used, because it has no physical meaning.

### Output

* The **graph** output keeps every tube whose conductivity is at least `"Threshold"` times the
  largest one, plus the food vertices. Each tube has the edge property `"Conductivity"`
  (read it with `PropertyValue[{g, edge}, "Conductivity"]`) and is drawn with a thickness in
  proportion to it. Food vertices are red.
* The **image** output shows the maze with the tubes glowing in proportion to their conductivity,
  and the food in red.
* `"Frames"` returns up to 41 evenly spaced pictures (or graphs) from the run.
* `"History"` returns the conductivity of every tube after every step (`"Steps"` + 1 vectors).
  It is the raw data behind the pictures. The order of the tubes for graph input is `EdgeList[graph]`.
* `"Conductivity"` returns the final conductivities, as an Association from edges to values.
  For a maze the edges are `UndirectedEdge`s between pixel positions `{row, column}`.
* The result is random when there are more than two food sources (the source is chosen
  at random). Use `RandomSeeding` to get repeatable runs.

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `"Steps"` | Automatic | number of adaptation steps. Automatic is 200 for two food sources and 600 for more. |
| `"Flux"` | 2 | how much protoplasm the source pumps in. Low values give a lean, tree-like network. High values keep extra cross-links. |
| `"Exponent"` | Automatic | γ in *f(Q) = \|Q\|^γ/(1 + \|Q\|^γ)*. Automatic is 1.8, except for two food sources, where *f(Q) = \|Q\|*. |
| `"TimeStep"` | 0.3 | size of each adaptation step. Smaller values are steadier but need more steps. |
| `"Threshold"` | 0.01 | tubes with less than this fraction of the maximum conductivity are dropped from the graph |
| `"Resolution"` | 50 | number of lattice nodes along the longest side (points input only) |
| `"Output"` | Automatic | what to return. Automatic is `"Image"` for a maze and `"Graph"` otherwise. |
| `ImageSize` | 400 | width of the picture, for maze output |
| `RandomSeeding` | Automatic | seed for the random choice of the source |

### `"Output"` values

| Value | Result |
| --- | --- |
| `"Image"` | the picture of the final state (maze input). For the other forms this returns the graph. |
| `"Graph"` | the surviving tubes, as a `Graph` with `"Conductivity"` on every edge |
| `"Frames"` | a list of up to 41 pictures (mazes) or graphs from the run |
| `"History"` | the conductivity vectors of all steps |
| `"Conductivity"` | the final conductivity of each tube, as an Association |

## Examples

### Solve a maze

Put food at the entrance and at the exit, and let the flow decide. `"Loops"` opens extra walls, so
there are several routes:

```wolfram
maze = PhysarumMaze[10, "Loops" -> 8, RandomSeeding -> 3];
PhysarumFlow[maze, {{0.05, 0.95}, {0.95, 0.05}}]
```

Watch how the maze is solved:

```wolfram
frames = PhysarumFlow[maze, {{0.05, 0.95}, {0.95, 0.05}}, "Output" -> "Frames"];
{maze, frames[[2]], frames[[8]], Last[frames]}
ListAnimate[frames]
```

![Maze solving by flow reinforcement](../images/tutorial/maze.png)

In the beginning the whole maze carries flow. Dead ends carry none and fade almost at once. Longer
routes carry a little less flow, so they thin a little, which gives them even less flow. That runaway
effect leaves only the shortest route.

### Check the answer

The final conductivities show which tubes survived. For example, count the tubes that keep more
than a tenth of the largest conductivity. After solving, these should form the shortest route:

```wolfram
cond = PhysarumFlow[maze, {{0.05, 0.95}, {0.95, 0.05}}, "Output" -> "Conductivity"];
Length[cond]                                     (* the number of tubes in the maze *)
Count[Values[cond], x_ /; x > 0.1 Max[cond]]      (* the tubes of the surviving path *)
```

### A transport network

Points in the plane grow a network on a lattice:

```wolfram
SeedRandom[7]; pts = RandomReal[1, {14, 2}];
PhysarumFlow[pts]
```

`"Flux"` trades economy for redundancy. A low flux gives a lean tree, and a high flux keeps extra
links:

```wolfram
Table[PhysarumFlow[pts, "Flux" -> f, "Resolution" -> 80, RandomSeeding -> 1], {f, {1, 4, 16}}]
```

![Flux trades economy for redundancy](../images/tutorial/flux.png)

### Work with the result

The result is an ordinary `Graph` with a conductivity on every edge:

```wolfram
g = PhysarumFlow[pts, "Resolution" -> 60, RandomSeeding -> 1];
{VertexCount[g], EdgeCount[g], ConnectedGraphQ[g]}
PropertyValue[{g, First[EdgeList[g]]}, "Conductivity"]
```

### Any graph

Food is given as vertices. Without coordinates or weights every tube has length 1:

```wolfram
PhysarumFlow[GridGraph[{15, 15}], {1, 225}]
```

Give the graph edge weights to make some tubes longer than others. Here the direct edge is long,
so the flow prefers the route through the middle:

```wolfram
ring = Graph[{1 <-> 2, 2 <-> 3, 1 <-> 3}, EdgeWeight -> {1, 1, 5}];
PhysarumFlow[ring, {1, 3}, "Output" -> "Conductivity"]
```

### Choose the number of steps

```wolfram
PhysarumFlow[maze, {{0.05, 0.95}, {0.95, 0.05}}, "Steps" -> 20]      (* not solved yet *)
PhysarumFlow[maze, {{0.05, 0.95}, {0.95, 0.05}}, "Steps" -> 400]     (* solved *)
```

### The history

```wolfram
hist = PhysarumFlow[GridGraph[{5, 5}], {1, 25}, "Output" -> "History"];
Dimensions[hist]                        (* {201, 40}: 201 states of 40 tubes *)
ListLinePlot[Transpose[hist], PlotRange -> All, AxesLabel -> {"step", "conductivity"}]
```

Every curve is one tube. Most tubes die out, and a few grow. The survivors are the shortest routes.

### Picture size

```wolfram
PhysarumFlow[maze, {{0.05, 0.95}, {0.95, 0.05}}, ImageSize -> 800]
```

## Messages

| Message | Cause |
| --- | --- |
| `PhysarumFlow::food` | fewer than two food sources lie on the graph or in the free part of the maze |

## See also

[PhysarumMaze](PhysarumMaze.md) ·
[PhysarumNetwork](PhysarumNetwork.md)

**References:** A. Tero, R. Kobayashi, T. Nakagaki, *J. Theor. Biol.* 244, 553 (2007) ·
A. Tero *et al.*, *Science* 327, 439 (2010).
