---
Template: Symbol
Name: PhysarumSimulation3D
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/PhysarumSimulation3D
Keywords: [physarum, slime mold, 3D, voxel, volume, simulation, agents]
SeeAlso: [PhysarumSimulation3DObject, PhysarumEvolve, PhysarumImage3D, PhysarumGraphics3D, PhysarumArt3D, PhysarumSimulation, $PhysarumPresets]
RelatedGuides: [Physarum]
---

## Usage

<code>PhysarumSimulation3D[]</code> creates a new 3D slime-mold simulation using the `"Classic"` preset.

<code>PhysarumSimulation3D["*preset*"]</code> uses a named preset from [$PhysarumPresets]().

<code>PhysarumSimulation3D[*species*]</code> uses an [Association]() (or a list of associations) of species parameters.

<code>PhysarumSimulation3D[*spec*, *opts*]</code> creates a 3D simulation with the given options.

## Details & Options

- [PhysarumSimulation3D]() returns a [PhysarumSimulation3DObject]() in its initial state (step 0). Advance it with [PhysarumEvolve]() and render it with [PhysarumImage3D]() or [PhysarumGraphics3D]().
- Each 3D agent has a 3D position and unit heading vector, senses along its heading plus a randomly rotated ring of four sensors tilted by `"SensorAngle"`, turns by `"RotationAngle"` toward the strongest reading, moves by `"StepSize"`, and deposits `"Deposit"` into the voxel grid.
- The trail map diffuses over the $3 \times 3 \times 3$ neighborhood of each voxel and decays by `"Decay"` at every step.
- Food points and wall regions are specified in the **unit cube** $[0, 1]^3$ with $z$ pointing up.
- Masks for `"Food"`, `"Walls"` and `"Initialization"` can be 3D regions or primitives ([Ball](), [Cuboid](), [Cylinder](), [Ellipsoid](), [ImplicitRegion](), etc.), an [Image3D](), or a 3D numeric array in $[0, 1]$.
- [PhysarumSimulation3D]() accepts the following options:

| Option | Default | Description |
| --- | --- | --- |
| `"Size"` | `96` | grid size in voxels (`n` for $n \times n \times n$, or `{w, h, d}`) |
| `"Agents"` | [Automatic]() | exact agent count; [Automatic]() uses $\text{AgentDensity} \times w \times h \times d$ |
| `"Initialization"` | [Automatic]() | initial agent placement: `"Random"`, `"Ball"`, `"Shell"`, `"Burst"`, `"Food"` or a 3D mask |
| `"Food"` | [None]() | 3D food points in the unit cube or a 3D mask |
| `"FoodStrength"` | [Automatic]() | attractant added per step at full food intensity |
| `"FoodRadius"` | `2` | Gaussian radius in voxels for point food sources |
| `"Walls"` | [None]() | impassable 3D regions or mask |
| `"Wrap"` | [Automatic]() | whether the volume wraps periodically in all three axes |

## Basic Examples

Create a 3D simulation with the `"Classic"` preset, evolve it for 300 steps and render the surface:

```wl
SeedRandom[1];
sim = PhysarumSimulation3D["Classic", "Size" -> 64];
sim = PhysarumEvolve[sim, 300];
PhysarumGraphics3D[sim]
```

## Scope

Compare volume rendering, isosurface rendering and agent point-cloud rendering of the same simulation:

```wl
{PhysarumImage3D[sim], PhysarumGraphics3D[sim], PhysarumGraphics3D[sim, Method -> "Points"]}
```

## Options

### `"Food"` and `"Walls"`

Grow a 3D network between random food points around a spherical obstacle in the center of the unit cube:

```wl
SeedRandom[5];
food = RandomReal[{0.15, 0.85}, {8, 3}];
sim = PhysarumSimulation3D["Classic", "Size" -> 64,
    "Food" -> food, "FoodStrength" -> 50,
    "Walls" -> Ball[{0.5, 0.5, 0.5}, 0.22]];
PhysarumGraphics3D[PhysarumEvolve[sim, 400]]
```

### `"Initialization"`

Start agents on a spherical shell heading inward:

```wl
sim = PhysarumEvolve[PhysarumSimulation3D["Classic", "Size" -> 64, "Initialization" -> "Shell", "Wrap" -> False], 200];
PhysarumGraphics3D[sim]
```
