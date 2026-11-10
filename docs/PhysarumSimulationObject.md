---
Template: Symbol
Name: PhysarumSimulationObject
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/PhysarumSimulationObject
Keywords: [physarum, slime mold, simulation object, state, trail, agents]
SeeAlso: [PhysarumSimulation, PhysarumEvolve, PhysarumImage, PhysarumSimulation3DObject]
RelatedGuides: [Physarum]
---

## Usage

<code>PhysarumSimulationObject[*assoc*]</code> represents the state of a 2D Physarum simulation.

<code>*sim*["*prop*"]</code> extracts the property *prop* from the simulation object *sim*.

## Details & Options

- Create a [PhysarumSimulationObject]() with [PhysarumSimulation]() and advance it with [PhysarumEvolve]().
- Simulation objects are **immutable values**: [PhysarumEvolve]() returns a new [PhysarumSimulationObject]() and leaves the original unchanged.
- In a notebook, a [PhysarumSimulationObject]() formats as a compact summary box with a thumbnail preview and key metadata (`"Size"`, `"Agents"` and `"Step"`).
- The following properties can be extracted with `*sim*["*prop*"]`:

| Property | Description |
| --- | --- |
| `"Step"` | number of steps the simulation has been evolved |
| `"Size"` | `{width, height}` of the grid in cells |
| `"AgentCount"` | total number of agents |
| `"Agents"` | $n \times 4$ matrix with rows `{x, y, heading, species}` |
| `"Trail"` | 3D array of dimensions `{species, height, width}` holding the chemoattractant trail |
| `"Stimulus"` | `height × width` matrix of food attractant added each step |
| `"Walls"` | `height × width` binary obstacle mask (`0` or `1`) |
| `"Species"` | list of complete species [Association]()s |
| `"Wrap"` | [True]() if the grid wraps around its borders |
| `"Image"` | rendered trail image, equivalent to <code>PhysarumImage[*sim*]</code> |
| `"Properties"` | list of standard property names |
| `"Data"` | the underlying [Association]() |

- In `"Agents"`, `x` runs from `0` to `width`, `y` runs from `0` (top) to `height` (bottom), `heading` is in radians in $[0, 2\pi)$, and `species` is the 0-based species index.

## Basic Examples

Create a simulation and query its properties:

```wl
sim = PhysarumSimulation["Classic", "Size" -> {80, 60}, "Agents" -> 500];
sim["Properties"]
```

---

Inspect the step count, grid dimensions, agent count and array shapes:

```wl
{sim["Step"], sim["Size"], sim["AgentCount"], Dimensions[sim["Agents"]], Dimensions[sim["Trail"]]}
```

## Scope

The trail map starts at zero and accumulates as the simulation runs:

```wl
{Total[sim["Trail"], 3], Total[PhysarumEvolve[sim, 25]["Trail"], 3] > 0}
```

---

Plot the agent positions directly with [ListPlot]():

```wl
evolved = PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 200], 300];
{w, h} = evolved["Size"];
ListPlot[{#[[1]], h - #[[2]]} & /@ evolved["Agents"],
    PlotStyle -> {PointSize[0.003], Black}, AspectRatio -> h/w, PlotRange -> {{0, w}, {0, h}}]
```

---

Compare agent counts and total trail across competing species:

```wl
rivals = PhysarumEvolve[PhysarumSimulation["Rivals", "Size" -> 200], 300];
{Counts[rivals["Agents"][[All, 4]]], Total /@ Flatten /@ rivals["Trail"]}
```

## Applications

Keep intermediate states along a run with [FoldList]():

```wl
states = FoldList[PhysarumEvolve, PhysarumSimulation["Classic", "Size" -> 200], {5, 20, 100}];
#["Step"] & /@ states
```
