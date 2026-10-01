# PhysarumSimulation

Creates a slime-mould agent simulation. It returns a
[PhysarumSimulationObject](PhysarumSimulationObject.md) in its starting state (step 0). Advance it
with [PhysarumEvolve](PhysarumEvolve.md) and draw it with [PhysarumImage](PhysarumImage.md).

## Syntax

| Form | Meaning |
| --- | --- |
| `PhysarumSimulation[]` | a simulation using the `"Classic"` preset |
| `PhysarumSimulation["preset"]` | a simulation using a named preset from [$PhysarumPresets](PhysarumPresets.md) |
| `PhysarumSimulation[species]` | a simulation of a single species given as an Association of parameters |
| `PhysarumSimulation[{species1, species2, ...}]` | a simulation of several competing species |
| `PhysarumSimulation[<\|"Species" -> {...}, ...\|>]` | a full specification, in the same form as a preset |
| `PhysarumSimulation[spec, opts]` | any of the above, with options |

## Details

* An **agent** is a point-sized particle with a position and a heading. Agents sense the trail
  map, turn, move, and deposit more trail. See the
  [mini tutorial](../README.md#model-1-many-simple-agents-how-the-network-forms) for the picture.
* A **species** is an Association of parameters. Keys you leave out take the defaults below.
* A full specification (the form used by presets) is an Association that may contain these keys:

| Key | Default | Meaning |
| --- | --- | --- |
| `"Species"` | (required) | a species, or a list of species |
| `"AgentDensity"` | 0.5 | agents per grid cell, so the agent count is `density × width × height` |
| `"Steps"` | 500 | suggested number of steps, used by [PhysarumArt](PhysarumArt.md) |
| `"Initialization"` | `"Random"` | default for the `"Initialization"` option |
| `"Wrap"` | Automatic | default for the `"Wrap"` option |
| `"ColorFunction"`, `"Background"`, `"Gamma"`, `"Glow"`, `"Clip"` | | default rendering style, used by [PhysarumImage](PhysarumImage.md) |

* A species Association passed on its own (or in a list) cannot carry these extra keys. Wrap it
  as `<|"Species" -> species, "AgentDensity" -> 1|>` to set them.
* With several species, each species has its **own trail layer**. Species sense their own trail,
  and `"Repulsion"` makes them avoid the trails of the others.
* Food adds attractant to the trail map at every step. Agents that can smell it are drawn
  towards it, so strands that reach food are reinforced.
* Walls are impassable. Agents cannot enter them or see through them, and a wall pixel never
  receives trail. Agents that would start inside a wall are moved to a random free cell.
* The random number generator is the kernel's. Use `SeedRandom` to get repeatable initial layouts.

### Species parameters

| Key | Default | Meaning |
| --- | --- | --- |
| `"SensorAngle"` | `22.5 Degree` | angle between the forward sensor and each of the two side sensors |
| `"SensorDistance"` | 9 | how far ahead the sensors smell, in grid cells. It sets the scale of the network. |
| `"RotationAngle"` | `45 Degree` | how far an agent turns towards the strongest sensor in one step |
| `"StepSize"` | 1 | distance moved per step, in grid cells |
| `"Deposit"` | 5 | trail laid down per agent per step |
| `"Decay"` | 0.1 | fraction of trail lost per step (0 to 1). It is the mould's memory. |
| `"Diffusion"` | 1 | how much the trail spreads per step. 0 is no blur, 1 is a full 3×3 blur. |
| `"Jitter"` | 0 | random wiggle added to the heading each step, in radians (uniform in ±`Jitter`/2) |
| `"Repulsion"` | 0 | how strongly the species avoids other species' trails. Ignored with a single species. |
| `"Fraction"` | 1 | this species' share of the agents, relative to the other species |
| `"Color"` | Automatic | color used when several species are drawn. Automatic cycles through a palette. |

The default species does not give the `"Classic"` look. With slow decay and strong diffusion it
makes thick loops. Most presets use `"Deposit" -> 1`, `"Decay" -> 0.3` and `"Diffusion" -> 0.1`
instead, for finer networks.

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `"Size"` | 512 | grid size in cells. A number `n` gives an `n × n` grid, and `{w, h}` a rectangle. |
| `"Agents"` | Automatic | exact number of agents. Automatic uses `AgentDensity × w × h`. |
| `"Initialization"` | Automatic | how agents are placed. Automatic uses the specification's value, or `"Random"`. |
| `"Food"` | None | food sources: points in the unit square, or a mask (text, graphics, image, ...) |
| `"FoodStrength"` | Automatic | attractant added per step at full food intensity. Automatic is the largest species `"Deposit"`. |
| `"FoodRadius"` | 3 | radius in cells of each food point. Applies to point input only. |
| `"Walls"` | None | impassable regions, as any mask |
| `"Wrap"` | Automatic | whether the grid is a torus. Automatic is `True` unless food or walls are given. |

### `"Initialization"` values

| Value | Layout |
| --- | --- |
| `"Random"` | uniformly over the grid, with random headings |
| `"Disk"` | uniformly inside a disk in the middle of the grid |
| `"Ring"` | on a circle, heading inwards |
| `"Burst"` | in a tiny cluster in the centre, heading outwards |
| `"Food"` | placed over the food, in proportion to its intensity. Needs `"Food"`, else falls back to `"Random"`. |
| any mask | placed in proportion to the brightness of a string, `Graphics`, `Image`, ... |

## Examples

### The basics

```wolfram
sim = PhysarumSimulation[]                          (* "Classic" preset, 512 × 512 *)
sim = PhysarumSimulation["Marble", "Size" -> 300]   (* a preset with three competing species *)
```

Simulations are immutable values. Evolve one to get the next state:

```wolfram
sim = PhysarumSimulation["Classic", "Size" -> 220];
sim = PhysarumEvolve[sim, 300];
PhysarumImage[sim]
```

### An exact number of agents

```wolfram
sim = PhysarumSimulation["Classic", "Size" -> {80, 60}, "Agents" -> 500];
sim["AgentCount"]      (* 500 *)
sim["Size"]            (* {80, 60} *)
```

### Your own species

Only the keys you give are changed. Everything else keeps its default:

```wolfram
PhysarumSimulation[<|"SensorAngle" -> 90 Degree, "RotationAngle" -> 11.25 Degree|>, "Size" -> 220]
```

### Several species

Species are numbered in the order given. `"Fraction"` sets their relative sizes, so here the
second species gets twice as many agents as the first:

```wolfram
sim = PhysarumSimulation[<|
   "Species" -> {
     <|"SensorDistance" -> 12, "Decay" -> 0.3, "Diffusion" -> 0.1, "Deposit" -> 1, "Repulsion" -> 2, "Color" -> Orange|>,
     <|"SensorDistance" -> 25, "Decay" -> 0.3, "Diffusion" -> 0.1, "Deposit" -> 1, "Repulsion" -> 2, "Color" -> Cyan, "Fraction" -> 2|>},
   "AgentDensity" -> 1|>, "Size" -> 300];
Dimensions[sim["Trail"]]      (* {2, 300, 300}: one trail layer per species *)
Counts[sim["Agents"][[All, 4]]]
```

### Food

Food points are in the unit square, with y pointing up. Giving food (or walls) switches
`"Wrap"` off automatically, so agents cannot slip around the edges:

```wolfram
SeedRandom[5];
food = RandomReal[{0.15, 0.85}, {9, 2}];
sim = PhysarumSimulation["Classic", "Size" -> 220, "Food" -> food, "FoodStrength" -> 50];
sim["Wrap"]       (* False *)
PhysarumImage[PhysarumEvolve[sim, 500], "ShowFood" -> True]
```

Food can also be text, graphics or an image. Starting the agents on the food makes the letters
fill up quickly:

```wolfram
sim = PhysarumSimulation["Filaments", "Size" -> {600, 200}, "Food" -> "PHYSARUM",
   "FoodStrength" -> 5, "Initialization" -> "Food"];
PhysarumImage[PhysarumEvolve[sim, 400], "ShowFood" -> True]
```

![Growing towards text](../images/text.png)

### Walls

```wolfram
walls = Graphics[{Disk[{0, 0}, 0.3], Disk[{0.6, 0.5}, 0.15]}, PlotRange -> {{-1, 1}, {-1, 1}}];
PhysarumImage[PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 300, "Walls" -> walls], 500]]
```

![Growing around walls](../images/walls.png)

The `PlotRange` of the `Graphics` is what is mapped onto the grid, so give it explicitly. Here the
grid is the unit square, and the wall is a disk in its middle:

```wolfram
disk = Graphics[Disk[{0.5, 0.5}, 0.25], PlotRange -> {{0, 1}, {0, 1}}];
PhysarumSimulation["Classic", "Size" -> 200, "Walls" -> disk]
```

Without a `PlotRange`, the `Graphics` is stretched so that its contents fill the whole grid. A lone
`Disk` would then cover nearly all of it.

### Starting layouts

```wolfram
PhysarumSimulation["Classic", "Initialization" -> "Disk", "Wrap" -> False]
PhysarumSimulation["Classic", "Initialization" -> "Burst", "Wrap" -> False]
PhysarumSimulation["Classic", "Initialization" -> "PHYSARUM"]     (* agents start in the shape of the word *)
```

## Messages

| Message | Cause |
| --- | --- |
| `PhysarumSimulation::spec` | the specification is not a preset name, a species or a list of species, or a parameter is not a real number |
| `PhysarumSimulation::mask` | a `"Food"`, `"Walls"` or `"Initialization"` value could not be turned into a mask |
| `PhysarumSimulation::nolib` | the compiled simulation library was not found. See [BUILD.md](../BUILD.md). |

## See also

[PhysarumSimulationObject](PhysarumSimulationObject.md) ·
[PhysarumEvolve](PhysarumEvolve.md) ·
[PhysarumImage](PhysarumImage.md) ·
[PhysarumArt](PhysarumArt.md) ·
[$PhysarumPresets](PhysarumPresets.md)
