# PhysarumArt

Grows a slime-mould simulation and renders it in one call. It is the quickest way to get a picture.

## Syntax

| Form | Meaning |
| --- | --- |
| `PhysarumArt[]` | grows and renders the `"Classic"` preset |
| `PhysarumArt["preset"]` | grows and renders a named preset from [$PhysarumPresets](PhysarumPresets.md) |
| `PhysarumArt[spec]` | grows and renders any specification accepted by [PhysarumSimulation](PhysarumSimulation.md) |
| `PhysarumArt[spec, opts]` | with options |
| `PhysarumArt[opts]` | the `"Classic"` preset, with options |

## Details

* `PhysarumArt[spec, opts]` is shorthand for these three steps:

  ```wolfram
  sim = PhysarumSimulation[spec, (simulation options)];
  sim = PhysarumEvolve[sim, steps];
  PhysarumImage[sim, (image options)]
  ```
* It accepts every option of [PhysarumSimulation](PhysarumSimulation.md) and of
  [PhysarumImage](PhysarumImage.md), plus `"Steps"`. Each option goes to the function that uses it.
* The default `"Steps"` is the value stored with the preset (500 to 600 for the built-in presets), or
  500 for a species you define yourself.
* `"AgentDensity"` is not an option of `PhysarumArt`. It is part of the specification, so pass it
  in an Association: `PhysarumArt[<|"Species" -> {...}, "AgentDensity" -> 1|>]`. Use `"Agents"` to
  set an exact count.
* The result is an `Image`. It returns `$Failed` if the specification is invalid, and `$Aborted` if
  the evaluation was aborted.
* Use `SeedRandom[n]` before the call to get a repeatable picture.

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `"Steps"` | Automatic | the number of steps to grow. Automatic uses the preset's value. |
| `"Size"`, `"Agents"`, `"Initialization"`, `"Food"`, `"FoodStrength"`, `"FoodRadius"`, `"Walls"`, `"Wrap"` | | as for [PhysarumSimulation](PhysarumSimulation.md) |
| `ColorFunction`, `"Colors"`, `Background`, `"Gamma"`, `"Glow"`, `"Clip"`, `"ShowFood"`, `"ShowWalls"`, `"WallColor"`, `"FoodColor"`, `ImageSize` | | as for [PhysarumImage](PhysarumImage.md) |

Note that `"Size"` has a default of 512, so the pictures are 512 × 512 pixels.

## Examples

### One-shot pictures

```wolfram
PhysarumArt[]
PhysarumArt["Filaments"]
PhysarumArt["Marble", "Size" -> 768]
```

![All presets](../images/presets.png)

### Reproducible pictures

```wolfram
SeedRandom[7]; PhysarumArt["Nebula", "Size" -> 300]
SeedRandom[7]; PhysarumArt["Nebula", "Size" -> 300]      (* the same picture again *)
```

### More or fewer steps

```wolfram
Table[PhysarumArt["Classic", "Size" -> 220, "Steps" -> n], {n, {10, 60, 400}}]
```

### Change the look

```wolfram
PhysarumArt["Classic", ColorFunction -> "SunsetColors", "Glow" -> 0.6]
PhysarumArt["Classic", ColorFunction -> None, "Colors" -> {Cyan}, Background -> Black]
PhysarumArt["Ink"]                                      (* a preset that looks like ink on paper *)
```

### Your own species

Give the parameters you want to change. The rest take their defaults:

```wolfram
PhysarumArt[<|"SensorAngle" -> 22.5 Degree, "RotationAngle" -> 90 Degree|>, "Size" -> 220, "Steps" -> 400,
  ColorFunction -> "SunsetColors"]
```

![Sensor angle and rotation angle](../images/tutorial/angles.png)

All species parameters:

```wolfram
PhysarumArt[<|
   "SensorAngle"    -> 30 Degree,
   "SensorDistance" -> 12,
   "RotationAngle"  -> 30 Degree,
   "StepSize"       -> 1,
   "Deposit"        -> 1,
   "Decay"          -> 0.3,
   "Diffusion"      -> 0.1,
   "Jitter"         -> 0|>, "Steps" -> 500]
```

### Competing species

```wolfram
PhysarumArt[<|
   "Species" -> {
     <|"SensorDistance" -> 12, "Diffusion" -> 0.1, "Decay" -> 0.3, "Deposit" -> 1, "Repulsion" -> 2, "Color" -> Orange|>,
     <|"SensorDistance" -> 25, "Diffusion" -> 0.1, "Decay" -> 0.3, "Deposit" -> 1, "Repulsion" -> 2, "Color" -> Cyan, "Fraction" -> 2|>},
   "AgentDensity" -> 1|>, "Steps" -> 600]
```

### Start the agents in a shape

```wolfram
PhysarumArt["Classic", "Initialization" -> "Disk", "Wrap" -> False, "Steps" -> 200]
PhysarumArt["Classic", "Initialization" -> "Ring", "Wrap" -> False, "Steps" -> 200]
```

### Food

```wolfram
PhysarumArt["Classic", "Food" -> RandomReal[1, {12, 2}], "FoodStrength" -> 50, "ShowFood" -> True]

PhysarumArt["Filaments", "Food" -> "PHYSARUM", "FoodStrength" -> 5, "Initialization" -> "Food",
  "Size" -> {768, 256}]
```

![Growing towards text](../images/text.png)

### Walls

```wolfram
PhysarumArt["Classic", "Walls" -> Graphics[{Disk[{0, 0}, 0.3], Disk[{0.6, 0.5}, 0.15]}, PlotRange -> {{-1, 1}, {-1, 1}}]]
```

![Growing around walls](../images/walls.png)

## See also

[PhysarumSimulation](PhysarumSimulation.md) ·
[PhysarumEvolve](PhysarumEvolve.md) ·
[PhysarumImage](PhysarumImage.md) ·
[PhysarumAnimate](PhysarumAnimate.md) ·
[$PhysarumPresets](PhysarumPresets.md)
