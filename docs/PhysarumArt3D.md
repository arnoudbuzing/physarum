---
Template: Symbol
Name: PhysarumArt3D
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/PhysarumArt3D
Keywords: [physarum, slime mold, 3D, generative art, Image3D, Graphics3D]
SeeAlso: [PhysarumSimulation3D, PhysarumImage3D, PhysarumGraphics3D, PhysarumArt, $PhysarumPresets]
RelatedGuides: [Physarum]
---

## Usage

<code>PhysarumArt3D[]</code> grows and renders a 3D slime mold with the `"Classic"` preset.

<code>PhysarumArt3D["*preset*"]</code> grows and renders a named preset from [$PhysarumPresets]() in 3D.

<code>PhysarumArt3D[*spec*, *opts*]</code> grows and renders any [PhysarumSimulation3D]() specification with the given options.

## Details & Options

- `PhysarumArt3D[spec, opts]` creates a simulation with [PhysarumSimulation3D](), evolves it for `"Steps"` steps with [PhysarumEvolve](), and renders it according to `"Output"`.
- It accepts all options of [PhysarumSimulation3D](), [PhysarumImage3D]() and [PhysarumGraphics3D](), plus:

| Option | Default | Description |
| --- | --- | --- |
| `"Steps"` | [Automatic]() | number of evolution steps (default `300`) |
| `"Output"` | `"Image3D"` | return format: `"Image3D"`, `"Graphics3D"` or `"Simulation"` |

## Basic Examples

Grow and render a 3D simulation as a volume [Image3D]():

```wl
PhysarumArt3D["Classic", "Size" -> 64]
```

---

Render two competing species as a 3D surface:

```wl
PhysarumArt3D["Rivals", "Size" -> 64, "Output" -> "Graphics3D"]
```

## Options

### `"Output"` and `Method`

Render the grown simulation as a 3D agent point cloud:

```wl
PhysarumArt3D["Classic", "Size" -> 64, "Output" -> "Graphics3D", Method -> "Points"]
```

### Custom species parameters

Grow a custom 3D species specification:

```wl
PhysarumArt3D[<|"SensorAngle" -> 45 Degree, "SensorDistance" -> 12|>,
    "Size" -> 64, "Steps" -> 300, "Output" -> "Graphics3D"]
```
