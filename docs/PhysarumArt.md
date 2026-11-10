---
Template: Symbol
Name: PhysarumArt
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/PhysarumArt
Keywords: [physarum, slime mold, generative art, image, preset]
SeeAlso: [PhysarumSimulation, PhysarumEvolve, PhysarumImage, PhysarumAnimate, PhysarumArt3D, $PhysarumPresets]
RelatedGuides: [Physarum]
---

## Usage

<code>PhysarumArt[]</code> grows and renders a slime-mold image with the `"Classic"` preset.

<code>PhysarumArt["*preset*"]</code> grows and renders a named preset from [$PhysarumPresets]().

<code>PhysarumArt[*spec*, *opts*]</code> grows and renders any [PhysarumSimulation]() specification with the given options.

## Details & Options

- `PhysarumArt[spec, opts]` is equivalent to creating a simulation with [PhysarumSimulation](), advancing it with [PhysarumEvolve]() for `"Steps"` steps, and rendering it with [PhysarumImage]().
- It accepts all options of [PhysarumSimulation]() and [PhysarumImage](), plus `"Steps"`:

| Option | Default | Description |
| --- | --- | --- |
| `"Steps"` | [Automatic]() | number of evolution steps ([Automatic]() uses the preset's `"Steps"` value, or `500`) |
| `"Size"`, `"Agents"`, `"Initialization"`, `"Food"`, `"FoodStrength"`, `"FoodRadius"`, `"Walls"`, `"Wrap"` | | simulation options passed to [PhysarumSimulation]() |
| [ColorFunction](), `"Colors"`, [Background](), `"Gamma"`, `"Glow"`, `"Clip"`, `"ShowFood"`, `"ShowWalls"`, `"WallColor"`, `"FoodColor"`, [ImageSize]() | | rendering options passed to [PhysarumImage]() |

- Use [SeedRandom]() before calling [PhysarumArt]() for reproducible results.

## Basic Examples

Grow and render the default `"Classic"` preset:

```wl
PhysarumArt[]
```

---

Render named presets from [$PhysarumPresets]():

```wl
{PhysarumArt["Filaments", "Size" -> 250], PhysarumArt["Marble", "Size" -> 250], PhysarumArt["Ink", "Size" -> 250]}
```

## Scope

Grow a custom species specification:

```wl
PhysarumArt[<|"SensorAngle" -> 22.5 Degree, "RotationAngle" -> 90 Degree|>,
    "Size" -> 220, "Steps" -> 400, ColorFunction -> "SunsetColors"]
```

---

Grow two competing species with custom colors and relative fractions:

```wl
PhysarumArt[<|
    "Species" -> {
        <|"SensorDistance" -> 12, "Diffusion" -> 0.1, "Decay" -> 0.3, "Deposit" -> 1, "Repulsion" -> 2, "Color" -> Orange|>,
        <|"SensorDistance" -> 25, "Diffusion" -> 0.1, "Decay" -> 0.3, "Deposit" -> 1, "Repulsion" -> 2, "Color" -> Cyan, "Fraction" -> 2|>
    },
    "AgentDensity" -> 1|>, "Steps" -> 600]
```

## Options

### `"Steps"`

Compare the network after 10, 60 and 400 steps:

```wl
Table[PhysarumArt["Classic", "Size" -> 220, "Steps" -> n], {n, {10, 60, 400}}]
```

### `"Food"` and `"Walls"`

Grow filaments over a text food mask:

```wl
PhysarumArt["Filaments", "Food" -> "PHYSARUM", "FoodStrength" -> 5,
    "Initialization" -> "Food", "Size" -> {768, 256}]
```

---

Grow a network around circular walls:

```wl
PhysarumArt["Classic", "Walls" -> Graphics[{Disk[{0, 0}, 0.3], Disk[{0.6, 0.5}, 0.15]}, PlotRange -> {{-1, 1}, {-1, 1}}]]
```
