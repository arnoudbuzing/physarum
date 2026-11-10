---
Template: Symbol
Name: PhysarumNetwork
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/PhysarumNetwork
Keywords: [physarum, slime mold, transport network, graph, Steiner tree, geography, GeoPosition]
SeeAlso: [PhysarumFlow, PhysarumSimulation, PhysarumImage]
RelatedGuides: [Physarum]
---

## Usage

<code>PhysarumNetwork[{*p*<sub>1</sub>, *p*<sub>2</sub>, …}]</code> grows a slime mold between the 2D points *p*<sub>*i*</sub> and returns the resulting transport network as a [Graph]().

<code>PhysarumNetwork[{*geo*<sub>1</sub>, *geo*<sub>2</sub>, …}]</code> grows a transport network between [GeoPosition]() or geographic [Entity]() locations.

<code>PhysarumNetwork[*pts*, *opts*]</code> grows a network with the given options.

## Details & Options

- [PhysarumNetwork]() runs an agent simulation with food placed at the input locations, thresholds and thins the resulting trail map into a 1-pixel skeleton, and traces the skeleton into a weighted [Graph]() with [EuclideanDistance]() edge weights.
- Geographic inputs ([GeoPosition]() or [Entity]() values such as cities) are projected using an equirectangular projection at the mean latitude and attached as vertices of the resulting graph.
- [PhysarumNetwork]() accepts the following options:

| Option | Default | Description |
| --- | --- | --- |
| `"Size"` | `400` | grid resolution along the longest side |
| `"Steps"` | `2000` | number of simulation steps |
| `"AgentDensity"` | `0.3` | agents per grid cell |
| `"Species"` | [Automatic]() | species specification used to grow the network |
| `"FoodRadius"` | [Automatic]() | radius of each food source in cells |
| `"FoodStrength"` | `300` | attractant added per step at each food source |
| `"Walls"` | [None]() | obstacle mask that agents cannot cross |
| `"Padding"` | `0.15` | fractional margin added around the bounding box of the points |
| `"DeleteDeadEnds"` | [True]() | whether to prune branches that do not connect food sources |
| `"Backbone"` | [False]() | whether to keep only edges lying on shortest paths between food pairs |
| `"Threshold"` | [Automatic]() | binarization threshold ([Automatic]() uses Otsu's method) |
| `"Pruning"` | [Automatic]() | skeleton spur-pruning length in pixels |
| `"Resampling"` | `6` | pixel spacing used when resampling curved skeleton chains into graph edges |
| `"Initialization"` | `"Random"` | initial agent placement |
| `"Output"` | `"Graph"` | return format: `"Graph"`, `"Image"`, `"Simulation"`, `"GeoGraphics"` or `"Association"` |

## Basic Examples

Grow a transport network connecting 14 random points in the plane:

```wl
SeedRandom[3];
pts = RandomReal[1, {14, 2}];
g = PhysarumNetwork[pts]
```

---

Inspect the vertex count, edge count and connectivity of the extracted graph:

```wl
{VertexCount[g], EdgeCount[g], ConnectedGraphQ[g]}
```

## Scope

Grow a rail-like network between Dutch cities and display it on a map:

```wl
cities = Entity["City", #] & /@ {
    {"Amsterdam", "NoordHolland", "Netherlands"},
    {"Rotterdam", "ZuidHolland", "Netherlands"},
    {"TheHague", "ZuidHolland", "Netherlands"},
    {"Utrecht", "Utrecht", "Netherlands"},
    {"Eindhoven", "NoordBrabant", "Netherlands"},
    {"Groningen", "Groningen", "Netherlands"},
    {"Zwolle", "Overijssel", "Netherlands"},
    {"Maastricht", "Limburg", "Netherlands"}
};
PhysarumNetwork[cities, "Output" -> "GeoGraphics", "Backbone" -> True]
```

## Options

### `"Output"`

Return the grown trail image, thinned skeleton and extracted graph together using `"Output" -> "Association"`:

```wl
res = PhysarumNetwork[pts, "Output" -> "Association"];
{res["Image"], res["Skeleton"], res["Graph"]}
```

### `"Backbone"` and `"DeleteDeadEnds"`

Keep only edges on shortest paths between food sources:

```wl
PhysarumNetwork[pts, "Backbone" -> True]
```
