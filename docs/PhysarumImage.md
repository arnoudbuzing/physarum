---
Template: Symbol
Name: PhysarumImage
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/PhysarumImage
Keywords: [physarum, slime mold, image, render, visualization, color, glow]
SeeAlso: [PhysarumArt, PhysarumAnimate, PhysarumSimulation, PhysarumSimulationObject, PhysarumImage3D, $PhysarumPresets]
RelatedGuides: [Physarum]
---

## Usage

<code>PhysarumImage[*sim*]</code> renders the trail map of a [PhysarumSimulationObject]() *sim* as an [Image]().

<code>PhysarumImage[*sim*, *opts*]</code> renders *sim* with the given options.

<code>PhysarumImage[{*sim*<sub>1</sub>, *sim*<sub>2</sub>, …}, *opts*]</code> renders each simulation in the list.

## Details & Options

- [PhysarumImage]() is listable over a list of [PhysarumSimulationObject]() expressions.
- Each species' trail layer is normalized so that the `"Clip"` quantile maps to `1`, then gamma-corrected by `"Gamma"`. Cells containing food are excluded when computing the normalization quantile so bright food sources do not wash out the network.
- With a single species and a [ColorFunction](), trail intensity in $[0, 1]$ is passed to the color function. Otherwise, each species is colored by `"Colors"` (additive blending on dark backgrounds, subtractive ink-like blending on light backgrounds).
- [PhysarumImage]() accepts the following options:

| Option | Default | Description |
| --- | --- | --- |
| [ColorFunction]() | [Automatic]() | color function for a single species; [None]() uses `"Colors"` |
| `"Colors"` | [Automatic]() | list of colors, one per species |
| [Background]() | [Automatic]() | background color (preset default, or [Black]()) |
| `"Gamma"` | [Automatic]() | brightness exponent applied after normalization (default `0.7`) |
| `"Glow"` | [Automatic]() | strength of the Gaussian halo around bright strands (`0` to `1`, default `0.35`) |
| `"Clip"` | [Automatic]() | quantile of trail intensity mapped to full brightness (default `0.995`) |
| `"ShowFood"` | [False]() | whether to overlay food sources |
| `"FoodColor"` | `RGBColor[1, 0.3, 0.35]` | color used for food sources |
| `"ShowWalls"` | [True]() | whether to draw walls |
| `"WallColor"` | `GrayLevel[0.25]` | color used for walls |
| [ImageSize]() | [Automatic]() | display size of the resulting [Image]() |

## Basic Examples

Render an evolved simulation with its preset's default styling:

```wl
sim = PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 220], 300];
PhysarumImage[sim]
```

---

Render with a built-in color scheme:

```wl
PhysarumImage[sim, ColorFunction -> "DeepSeaColors"]
```

## Options

### `ColorFunction`, `"Colors"` and `Background`

Use a custom pure function as the color gradient:

```wl
PhysarumImage[sim, ColorFunction -> (Blend[{Black, DarkGreen, Yellow, White}, #] &)]
```

---

Draw dark ink on a light background by setting `Background -> White` and `ColorFunction -> None`:

```wl
PhysarumImage[sim, Background -> White, "Colors" -> {Darker[Blue]}, ColorFunction -> None, "Glow" -> 0]
```

---

Override species colors in a multi-species simulation:

```wl
rivals = PhysarumEvolve[PhysarumSimulation["Rivals", "Size" -> 250], 400];
{PhysarumImage[rivals], PhysarumImage[rivals, "Colors" -> {Orange, Cyan}]}
```

### `"Glow"` and `"Gamma"`

Adjust the halo strength and gamma compression:

```wl
{
    PhysarumImage[sim, "Glow" -> 0],
    PhysarumImage[sim, "Glow" -> 0.6, "Gamma" -> 0.5],
    PhysarumImage[sim, "Gamma" -> 1.5]
}
```

### `"ShowFood"` and `"ShowWalls"`

Highlight food sources on top of the trail map:

```wl
SeedRandom[5];
food = RandomReal[{0.15, 0.85}, {9, 2}];
foraging = PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 220, "Food" -> food, "FoodStrength" -> 50], 500];
{PhysarumImage[foraging], PhysarumImage[foraging, "ShowFood" -> True]}
```
