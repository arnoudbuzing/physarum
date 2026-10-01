# PhysarumSimulationObject

The state of a Physarum agent simulation. You do not build one directly. Create one with
[PhysarumSimulation](PhysarumSimulation.md), advance it with [PhysarumEvolve](PhysarumEvolve.md), and
read its contents with the properties below.

## Syntax

| Form | Meaning |
| --- | --- |
| `sim["property"]` | the value of a property |
| `sim["Properties"]` | the list of standard properties |

## Details

* A simulation object is an **immutable value**. [PhysarumEvolve](PhysarumEvolve.md) returns a new
  object and leaves the original alone, so you can keep earlier states (for example with `FoldList`).
* Objects display as a summary box with a thumbnail of the trail map, the step count, the grid size,
  the number of agents and species, and whether the grid wraps.
* `PhysarumImage[sim]` renders the object. `sim["Image"]` is a shortcut for the same thing.
* Row and column conventions follow Wolfram Language arrays: in `"Trail"`, `"Stimulus"` and `"Walls"`
  the first index is the row, counted from the *top* of the image.

## Properties

| Property | Value |
| --- | --- |
| `"Step"` | the number of steps the simulation has been evolved |
| `"Size"` | `{width, height}` of the grid in cells |
| `"AgentCount"` | the total number of agents |
| `"Agents"` | an `n × 4` matrix with one row `{x, y, heading, species}` per agent |
| `"Trail"` | the trail map, an array of dimensions `{species, height, width}` |
| `"Stimulus"` | the food attractant added at every step, a `height × width` matrix |
| `"Walls"` | the wall mask, a `height × width` matrix of 0 and 1 |
| `"Species"` | the list of complete species Associations, with all defaults filled in |
| `"Wrap"` | `True` if the grid is a torus |
| `"Image"` | the rendered trail map, as from `PhysarumImage[sim]` |
| `"Properties"` | the list of the standard properties above |

The following properties also work, although they are not listed by `"Properties"`:

| Property | Value |
| --- | --- |
| `"Colors"` | the color of each species |
| `"Steps"` | the suggested number of steps from the specification (used by [PhysarumArt](PhysarumArt.md)) |
| `"Style"` | the default rendering style taken from the preset |
| `"Parameters"` | the numeric species parameter matrix given to the simulation library |
| `"Data"` | the whole underlying Association |

### Agents

Each row of `"Agents"` is `{x, y, heading, species}`:

* `x` runs from 0 to the width and `y` from 0 to the height. `y` is measured *down* from the top
  of the image, in the same direction as the rows of `"Trail"`.
* `heading` is an angle in radians.
* `species` is the index of the species, counted from **0**.

## Examples

### Look inside a simulation

```wolfram
sim = PhysarumSimulation["Classic", "Size" -> {80, 60}, "Agents" -> 500]
```

```wolfram
sim["Step"]                 (* 0 *)
sim["Size"]                 (* {80, 60} *)
sim["AgentCount"]           (* 500 *)
Dimensions[sim["Agents"]]   (* {500, 4} *)
Dimensions[sim["Trail"]]    (* {1, 60, 80}: one species, 60 rows, 80 columns *)
sim["Properties"]
```

### The trail changes as the simulation runs

The trail starts empty, and every step adds to it:

```wolfram
Total[sim["Trail"], 3]                             (* 0. *)
Total[PhysarumEvolve[sim, 25]["Trail"], 3] > 0     (* True *)
```

### Plot the agents themselves

The images made by [PhysarumImage](PhysarumImage.md) show the trail. To see where the agents are,
plot the rows of `"Agents"`. The `y` axis is flipped so that the picture matches the image:

```wolfram
evolved = PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 200], 300];
{w, h} = evolved["Size"];
ListPlot[{#[[1]], h - #[[2]]} & /@ evolved["Agents"],
  PlotStyle -> {PointSize[0.003], Black}, AspectRatio -> h/w, PlotRange -> {{0, w}, {0, h}}]
```

### Compare species

```wolfram
sim = PhysarumEvolve[PhysarumSimulation["Rivals", "Size" -> 200], 300];
Counts[sim["Agents"][[All, 4]]]          (* agents per species (species indices start at 0) *)
Total /@ Flatten /@ sim["Trail"]         (* how much trail each species has laid down *)
sim["Species"][[All, "SensorDistance"]]
```

### Keep every state

Because objects are immutable, you can keep all the intermediate states:

```wolfram
states = FoldList[PhysarumEvolve, PhysarumSimulation["Classic", "Size" -> 200], {5, 20, 100}];
#["Step"] & /@ states           (* {0, 5, 25, 125} *)
```

## See also

[PhysarumSimulation](PhysarumSimulation.md) ·
[PhysarumEvolve](PhysarumEvolve.md) ·
[PhysarumImage](PhysarumImage.md)
