# PhysarumImage

Renders the trail map of a simulation as an `Image`.

## Syntax

| Form | Meaning |
| --- | --- |
| `PhysarumImage[sim]` | renders the [PhysarumSimulationObject](PhysarumSimulationObject.md) `sim` |
| `PhysarumImage[sim, opts]` | renders it with the given options |

## Details

* The picture shows the **trail**, not the agents. Bright places are places where many agents have
  travelled, so the strands of the network show up as bright lines. See the
  [mini tutorial](../README.md#model-1-many-simple-agents-how-the-network-forms) for how to read it.
* Each species has its own trail layer. Every layer is scaled so that its brightest 0.5% of
  cells (the `"Clip"` quantile) saturate, then compressed with `"Gamma"`, so that faint filaments
  stay visible. Cells that hold food are left out when the scale is chosen, so strong food does
  not wash out the network.
* There are two ways to turn the layers into colors:
  * **One species with a `ColorFunction`**: the trail brightness is mapped through the color
    function (a color-function name such as `"SunsetColors"`, or a function on the interval 0 to 1).
  * **Otherwise**: each species is drawn in its own color (from `"Colors"`). On a dark
    `Background` the colors add up like light. On a light background they multiply like
    ink on paper. A background counts as light when its brightness is at least 0.5.
* Then a soft halo (`"Glow"`) is added around bright strands.
* Any option left as `Automatic` takes its value from the style stored in the simulation, which
  comes from the preset. A simulation made from a preset therefore looks the same every time,
  and a species you define yourself is drawn in its `"Color"` (cyan for the first species by
  default) on black.
* `ColorFunction` is ignored when there is more than one species, or when `"Colors"` is given.

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `ColorFunction` | Automatic | color function for a single species. Automatic takes the preset's, and `None` draws the species color. |
| `"Colors"` | Automatic | list with a color for each species. Automatic uses the species `"Color"` values. |
| `Background` | Automatic | background color. Automatic takes the preset's, or black. |
| `"Gamma"` | Automatic | brightness exponent applied to the scaled trail. Below 1 brightens faint trails. Preset default, else 0.7. |
| `"Glow"` | Automatic | strength of the halo around bright strands, from 0 (none) to 1. Preset default, else 0.35. |
| `"Clip"` | Automatic | quantile of trail values that maps to full brightness. Preset default, else 0.995. |
| `"ShowFood"` | `False` | paint the food sources on top of the picture |
| `"FoodColor"` | `RGBColor[1, 0.3, 0.35]` | color of the food sources |
| `"ShowWalls"` | `True` | paint the walls |
| `"WallColor"` | `GrayLevel[0.25]` | color of the walls |
| `ImageSize` | Automatic | size of the image. Automatic is one pixel per grid cell. |

## Examples

### Render a simulation

```wolfram
sim = PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 220], 300];
PhysarumImage[sim]
```

### Change the colors

A named color scheme:

```wolfram
PhysarumImage[sim, ColorFunction -> "SunsetColors"]
PhysarumImage[sim, ColorFunction -> "DeepSeaColors"]
```

Your own gradient. The function receives the trail brightness between 0 and 1:

```wolfram
PhysarumImage[sim, ColorFunction -> (Blend[{Black, DarkGreen, Yellow, White}, #] &)]
```

A single color on a chosen background (no `ColorFunction`):

```wolfram
PhysarumImage[sim, ColorFunction -> None, "Colors" -> {Cyan}, Background -> Black]
```

### Gamma, glow and clipping

```wolfram
PhysarumImage[sim, "Glow" -> 0]                     (* crisp, no halo *)
PhysarumImage[sim, "Glow" -> 0.6, "Gamma" -> 0.5]   (* soft and bright, faint filaments visible *)
PhysarumImage[sim, "Gamma" -> 1.5]                  (* only the strongest strands *)
```

### Ink on paper

A light `Background` switches the drawing from glowing light to ink:

```wolfram
PhysarumImage[sim, Background -> White, "Colors" -> {Darker[Blue]}, ColorFunction -> None, "Glow" -> 0]
```

### Several species

Every species has a color. Compare the same simulation drawn with the default palette and with
your own colors:

```wolfram
rivals = PhysarumEvolve[PhysarumSimulation["Rivals", "Size" -> 250], 400];
PhysarumImage[rivals]
PhysarumImage[rivals, "Colors" -> {Orange, Cyan}]
PhysarumImage[rivals, "Colors" -> {Black, Red}, Background -> White, "Glow" -> 0]
```

### Show food and walls

`"ShowFood"` is off by default, so that the food does not hide the network:

```wolfram
SeedRandom[5];
food = RandomReal[{0.15, 0.85}, {9, 2}];
sim = PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 220, "Food" -> food, "FoodStrength" -> 50], 500];
{PhysarumImage[sim], PhysarumImage[sim, "ShowFood" -> True], PhysarumImage[sim, "ShowFood" -> True, "FoodColor" -> White]}
```

Walls are drawn by default:

```wolfram
disk = Graphics[Disk[{0.5, 0.5}, 0.25], PlotRange -> {{0, 1}, {0, 1}}];
walled = PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 250, "Walls" -> disk], 400];
{PhysarumImage[walled], PhysarumImage[walled, "ShowWalls" -> False], PhysarumImage[walled, "WallColor" -> Red]}
```

### Size

```wolfram
PhysarumImage[sim, ImageSize -> 600]
PhysarumImage[sim, ImageSize -> 100]      (* a thumbnail *)
```

### Presets side by side

Each preset carries its own color scheme:

```wolfram
Table[PhysarumArt[p, "Size" -> 200, "Steps" -> 300], {p, {"Classic", "Filaments", "Nebula", "Leopard"}}]
```

## See also

[PhysarumArt](PhysarumArt.md) ·
[PhysarumAnimate](PhysarumAnimate.md) ·
[PhysarumSimulationObject](PhysarumSimulationObject.md) ·
[$PhysarumPresets](PhysarumPresets.md)
