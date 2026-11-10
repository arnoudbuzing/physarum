---
Template: Symbol
Name: PhysarumSimulation
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/PhysarumSimulation
Keywords: [physarum, slime mold, simulation, agents, trail, chemotaxis, emergence]
SeeAlso: [PhysarumSimulationObject, PhysarumEvolve, PhysarumImage, PhysarumArt, PhysarumAnimate, $PhysarumPresets, PhysarumSimulation3D]
RelatedGuides: [Physarum]
---

## Usage

<code>PhysarumSimulation[]</code> creates a new slime-mold simulation using the `"Classic"` preset.

<code>PhysarumSimulation["*preset*"]</code> uses a named preset from [$PhysarumPresets]().

<code>PhysarumSimulation[*species*]</code> uses an [Association]() (or a list of associations) of species parameters.

<code>PhysarumSimulation[*spec*, *opts*]</code> creates a simulation with the given options.

## Details & Options

- [PhysarumSimulation]() returns a [PhysarumSimulationObject]() in its initial state (step 0). Advance it with [PhysarumEvolve]() and render it with [PhysarumImage]().
- An **agent** is a point-sized particle with a 2D position and a heading angle. At each step, agents sense the trail map at three sensors ahead, turn toward the strongest concentration, move forward, and deposit trail.
- A **species** is an [Association]() of parameters. Omitted keys use the defaults below:

| Key | Default | Description |
| --- | --- | --- |
| `"SensorAngle"` | `22.5 Degree` | angle between the forward sensor and each side sensor |
| `"SensorDistance"` | `9` | distance ahead at which sensors sample the trail, in grid cells |
| `"RotationAngle"` | `45 Degree` | turning angle toward the strongest sensor per step |
| `"StepSize"` | `1` | distance moved per step, in grid cells |
| `"Deposit"` | `5` | trail added per agent per step |
| `"Decay"` | `0.1` | fraction of trail lost per step (`0` to `1`) |
| `"Diffusion"` | `1` | blending weight for the $3 \times 3$ box blur per step (`0` to `1`) |
| `"Jitter"` | `0` | random heading noise per step, in radians |
| `"Repulsion"` | `0` | avoidance weight for other species' trail layers |
| `"Fraction"` | `1` | relative share of agents assigned to this species |
| `"Color"` | [Automatic]() | display color when multiple species are rendered |

- A full specification (the form stored in [$PhysarumPresets]()) is an [Association]() with `"Species"` and optional keys `"AgentDensity"`, `"Steps"`, `"Initialization"`, `"Wrap"`, `"ColorFunction"`, `"Background"`, `"Gamma"`, `"Glow"` and `"Clip"`.
- With multiple species, each species deposits into its own trail layer and is repelled by the sum of the other layers weighted by `"Repulsion"`.
- [PhysarumSimulation]() accepts the following options:

| Option | Default | Description |
| --- | --- | --- |
| `"Size"` | `512` | grid size in cells (`n` for $n \times n$, or `{w, h}`) |
| `"Agents"` | [Automatic]() | exact agent count; [Automatic]() uses $\text{AgentDensity} \times w \times h$ |
| `"Initialization"` | [Automatic]() | initial agent layout: `"Random"`, `"Disk"`, `"Ring"`, `"Burst"`, `"Food"` or a mask |
| `"Food"` | [None]() | food sources as 2D points in the unit square or any mask |
| `"FoodStrength"` | [Automatic]() | attractant added per step at full food intensity |
| `"FoodRadius"` | `3` | Gaussian radius in cells for point food sources |
| `"Walls"` | [None]() | impassable obstacles given as a string, [Graphics](), [Region](), [Image]() or matrix |
| `"Wrap"` | [Automatic]() | whether boundaries wrap around; [Automatic]() is [True]() unless food or walls are present |

- Use [SeedRandom]() before calling [PhysarumSimulation]() for reproducible initial agent positions.

## Basic Examples

Create a simulation with the default `"Classic"` preset:

```wl
sim = PhysarumSimulation[]
```

---

Advance the simulation by 300 steps and render the trail map:

```wl
sim = PhysarumSimulation["Classic", "Size" -> 220];
sim = PhysarumEvolve[sim, 300];
PhysarumImage[sim]
```

## Scope

Use a named multi-species preset from [$PhysarumPresets]():

```wl
PhysarumSimulation["Marble", "Size" -> 300]
```

---

Specify custom species angles while leaving other parameters at their defaults:

```wl
PhysarumSimulation[<|"SensorAngle" -> 90 Degree, "RotationAngle" -> 11.25 Degree|>, "Size" -> 220]
```

---

Create a simulation with two competing species of different sensor distances and agent fractions:

```wl
sim = PhysarumSimulation[<|
    "Species" -> {
        <|"SensorDistance" -> 12, "Decay" -> 0.3, "Diffusion" -> 0.1, "Deposit" -> 1, "Repulsion" -> 2, "Color" -> Orange|>,
        <|"SensorDistance" -> 25, "Decay" -> 0.3, "Diffusion" -> 0.1, "Deposit" -> 1, "Repulsion" -> 2, "Color" -> Cyan, "Fraction" -> 2|>
    },
    "AgentDensity" -> 1|>, "Size" -> 300];
Dimensions[sim["Trail"]]
```

## Options

### `"Size"` and `"Agents"`

Set rectangular grid dimensions and an exact number of agents:

```wl
sim = PhysarumSimulation["Classic", "Size" -> {80, 60}, "Agents" -> 500];
{sim["Size"], sim["AgentCount"]}
```

### `"Food"`

Place food sources in the unit square (which automatically disables boundary wrapping):

```wl
SeedRandom[5];
food = RandomReal[{0.15, 0.85}, {9, 2}];
sim = PhysarumSimulation["Classic", "Size" -> 220, "Food" -> food, "FoodStrength" -> 50];
PhysarumImage[PhysarumEvolve[sim, 500], "ShowFood" -> True]
```

---

Use a text string as both the food mask and initial agent distribution:

```wl
sim = PhysarumSimulation["Filaments", "Size" -> {600, 200}, "Food" -> "PHYSARUM",
    "FoodStrength" -> 5, "Initialization" -> "Food"];
PhysarumImage[PhysarumEvolve[sim, 400], "ShowFood" -> True]
```

### `"Walls"`

Add circular obstacles with an explicit [PlotRange]():

```wl
walls = Graphics[{Disk[{0, 0}, 0.3], Disk[{0.6, 0.5}, 0.15]}, PlotRange -> {{-1, 1}, {-1, 1}}];
PhysarumImage[PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 300, "Walls" -> walls], 500]]
```

### `"Initialization"`

Start agents in a central disk, an outward burst, or shaped like a word:

```wl
{
    PhysarumSimulation["Classic", "Initialization" -> "Disk", "Wrap" -> False],
    PhysarumSimulation["Classic", "Initialization" -> "Burst", "Wrap" -> False],
    PhysarumSimulation["Classic", "Initialization" -> "PHYSARUM"]
}
```
