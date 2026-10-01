# PhysarumNetwork

Lets a slime mould grow between food sources and reads the result off as a `Graph`.

This works like the classic slime-mould experiments: food is placed at the given points, the mould
grows between them, and the network of strands that remains is the answer.

## Syntax

| Form | Meaning |
| --- | --- |
| `PhysarumNetwork[{p1, p2, ...}]` | grows a mould between the points `pi` in the plane and returns its transport network as a `Graph` |
| `PhysarumNetwork[{geo1, geo2, ...}]` | the same for `GeoPosition` values or entities with a position (cities, airports, ...) |
| `PhysarumNetwork[input, opts]` | with options |

## Details

* The input is a list of at least two distinct points. It can be:
  * numeric pairs `{x, y}`, in any coordinates,
  * `GeoPosition` objects,
  * `Entity` objects that have a `"Position"` (cities, airports, landmarks, ...). All entities are
    looked up with a single batched `EntityValue[..., "Position"]`.

  Mixed lists of `GeoPosition` and `Entity` work. Anything else needs to be all points.
* The steps are:
  1. The points are scaled onto a grid, with some `"Padding"` around them. The longest side of the
     grid has `"Size"` cells. Food is placed at each point.
  2. Agents ([PhysarumSimulation](PhysarumSimulation.md)) grow for `"Steps"` steps.
  3. The trail map is compressed with a strong gamma so that faint filaments survive, smoothed,
     and thresholded (Otsu's method, unless `"Threshold"` is given).
  4. The result is thinned to a one-pixel skeleton, and short spurs (`"Pruning"`) are removed.
  5. Junction pixels are collapsed into single vertices, and the pixel chains between them are
     turned into edges, resampled every `"Resampling"` pixels so that edges follow the curves.
  6. Each food source is attached to the nearest network vertex.
  7. Dead ends that lead to no food are deleted (`"DeleteDeadEnds"`). With `"Backbone" -> True`,
     only edges on shortest paths between food sources are kept.
* The graph has:
  * `VertexCoordinates` in your coordinates,
  * Euclidean `EdgeWeight`s (so `GraphDistance`, `FindShortestPath` and
    `FindSpanningTree` work as expected),
  * vertices `"Food1"`, `"Food2"`, ... for the food sources (in input order), or the original
    `Entity` for entity input. The other vertices are integers.
  * a style that shows food as large red discs and the network as orange lines.
* For geographic input the coordinates are projected onto a local plane first (longitude scaled
  by the cosine of the mean latitude). `VertexCoordinates` of the resulting graph are in that
  plane, in degrees. Use `"Output" -> "GeoGraphics"` to see the network on a map.
* The mould does not know about geography. Pass a land/sea mask as `"Walls"` for more realistic
  networks. The mask is stretched over the whole padded grid (for a `Graphics`, its `PlotRange` is
  the grid), so to place a wall in your own coordinates, use the padded bounding box of the points
  as the `PlotRange` (see the example below).
* A food source can end up with no strand to it, so that the graph is not connected. A larger
  `"Steps"` or `"FoodStrength"` usually fixes that.
* The result is random. Use `SeedRandom[n]` before the call for a repeatable network.

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `"Size"` | 400 | number of grid cells along the longest side. Larger grids give more detail, and are slower. |
| `"Steps"` | 2000 | number of simulation steps |
| `"AgentDensity"` | 0.3 | agents per grid cell |
| `"Species"` | Automatic | species (or list of species) for the mould. Automatic uses a fine-network species. |
| `"FoodRadius"` | Automatic | radius of each food source, in grid cells. Automatic is `Max[2, Size/130]`. |
| `"FoodStrength"` | 300 | attractant given off by the food at every step |
| `"Walls"` | None | impassable regions, as a mask covering the padded grid (see [PhysarumSimulation](PhysarumSimulation.md)) |
| `"Padding"` | 0.15 | extra space around the points, as a fraction of their largest extent |
| `"DeleteDeadEnds"` | `True` | remove branches that do not lead to food |
| `"Backbone"` | `False` | keep only edges on shortest paths between food sources |
| `"Threshold"` | Automatic | binarization threshold for the trail image, between 0 and 1. Automatic uses Otsu's method. |
| `"Pruning"` | Automatic | length in cells of the skeleton spurs to remove. Automatic is `Max[w, h]/40`. |
| `"Resampling"` | 6 | distance in cells between the vertices along a strand. Larger values give straighter edges. |
| `"Initialization"` | `"Random"` | how the agents start, as in [PhysarumSimulation](PhysarumSimulation.md) |
| `"Output"` | `"Graph"` | what to return (see below) |

### `"Output"` values

| Value | Result |
| --- | --- |
| `"Graph"` | the transport network, as a `Graph` |
| `"Image"` | the grown mould as an image, with the food sources highlighted |
| `"Simulation"` | the [PhysarumSimulationObject](PhysarumSimulationObject.md) after growing |
| `"GeoGraphics"` | the network on a map (geographic input only) |
| `"Association"` | `<\|"Graph", "Simulation", "Image", "Skeleton", "Food"\|>`, plus `"GeoGraphics"` for geographic input |

In the `"Association"`, `"Skeleton"` is the thinned binary image the graph was read from, and
`"Food"` is the list of food vertices that are in the graph.

## Examples

### A network between random points

```wolfram
SeedRandom[3];
pts = RandomReal[1, {14, 2}];
g = PhysarumNetwork[pts]
```

The network is an ordinary `Graph`:

```wolfram
{VertexCount[g], EdgeCount[g], ConnectedGraphQ[g]}
VertexList[g][[-3 ;;]]                 (* the food vertices come last: "Food12", "Food13", "Food14" *)
```

### See the mould

```wolfram
PhysarumNetwork[pts, "Output" -> "Image"]
```

Everything at once:

```wolfram
res = PhysarumNetwork[pts, "Output" -> "Association"];
Keys[res]              (* {"Graph", "Simulation", "Image", "Skeleton", "Food"} *)
{res["Image"], res["Skeleton"], res["Graph"]}
```

![Grown mould, extracted graph, backbone](../images/network.png)

### Only the backbone

`"Backbone" -> True` keeps only the edges that lie on a shortest path between two food sources:

```wolfram
PhysarumNetwork[pts, "Backbone" -> True]
```

### Compare with a minimum spanning tree

```wolfram
mould = PhysarumNetwork[pts, "Backbone" -> True];
Total[PropertyValue[{mould, #}, EdgeWeight] & /@ EdgeList[mould]]              (* the mould's total length *)
tree = FindSpanningTree[mould];
Total[PropertyValue[{tree, #}, EdgeWeight] & /@ EdgeList[tree]]
```

### Distances along the network

Food vertices are named `"Food1"`, `"Food2"`, ...:

```wolfram
GraphDistance[mould, "Food1", "Food5"]            (* length along the mould *)
EuclideanDistance[pts[[1]], pts[[5]]]             (* straight line, for comparison *)
FindShortestPath[mould, "Food1", "Food5"]
```

### Quality versus speed

A smaller grid and fewer steps are much faster. A larger grid and more steps give a finer, smoother
network:

```wolfram
PhysarumNetwork[pts, "Size" -> 200, "Steps" -> 800, "Output" -> "Image"]
PhysarumNetwork[pts, "Size" -> 600, "Steps" -> 3000, "Output" -> "Image"]
```

### Make the mould more or less thorough

Stronger food and more agents connect more reliably. `"Resampling"` and `"Pruning"` change how the
strands are read off:

```wolfram
PhysarumNetwork[pts, "FoodStrength" -> 600, "AgentDensity" -> 0.5]
PhysarumNetwork[pts, "Resampling" -> 15]                       (* straighter edges *)
PhysarumNetwork[pts, "DeleteDeadEnds" -> False]                (* keep the side branches *)
```

### Walls

Agents cannot cross walls, and the network has to go around them. The wall mask covers the padded
grid, so give the `Graphics` the padded bounding box of the points as its `PlotRange`. Then the wall
is drawn in the same coordinates as the points:

```wolfram
pad = 0.15 Max[Max /@ Transpose[pts] - Min /@ Transpose[pts]];       (* the default "Padding" *)
box = Transpose[{Min /@ Transpose[pts] - pad, Max /@ Transpose[pts] + pad}];
walls = Graphics[Disk[{0.5, 0.5}, 0.1], PlotRange -> box];
PhysarumNetwork[pts, "Walls" -> walls, "Output" -> "Image"]
```

### Geographic networks

Entities with a position are looked up in one batch, and the food vertices are the entities
themselves:

```wolfram
cities = Entity["City", #] & /@ {
   {"Amsterdam", "NoordHolland", "Netherlands"}, {"Rotterdam", "ZuidHolland", "Netherlands"},
   {"TheHague", "ZuidHolland", "Netherlands"}, {"Utrecht", "Utrecht", "Netherlands"},
   {"Eindhoven", "NoordBrabant", "Netherlands"}, {"Groningen", "Groningen", "Netherlands"},
   {"Zwolle", "Overijssel", "Netherlands"}, {"Maastricht", "Limburg", "Netherlands"}};

PhysarumNetwork[cities, "Output" -> "GeoGraphics", "Backbone" -> True]
```

![A slime-mould rail network for the Netherlands](../images/netherlands.png)

The graph works with the entities as vertices:

```wolfram
g = PhysarumNetwork[cities, "Backbone" -> True];
GraphDistance[g, cities[[1]], cities[[8]]]     (* hops along the mould from Amsterdam to Maastricht *)
```

`GeoPosition` values work the same way:

```wolfram
PhysarumNetwork[{GeoPosition[{52.37, 4.90}], GeoPosition[{51.92, 4.48}], GeoPosition[{52.09, 5.12}],
   GeoPosition[{51.44, 5.47}]}, "Output" -> "GeoGraphics"]
```

## Messages

| Message | Cause |
| --- | --- |
| `PhysarumNetwork::pts` | the input is not a list of at least two distinct 2D points or `GeoPosition` values |
| `PhysarumNetwork::geo` | the position of an entity or location could not be determined |

## See also

[PhysarumFlow](PhysarumFlow.md) ·
[PhysarumSimulation](PhysarumSimulation.md) ·
[PhysarumImage](PhysarumImage.md)
