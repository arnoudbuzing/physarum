# $PhysarumPresets

An Association of the named parameter sets that can be used in place of a specification.

## Syntax

| Form | Meaning |
| --- | --- |
| `$PhysarumPresets` | the Association of all presets |
| `$PhysarumPresets["name"]` | the specification of one preset |
| `Keys[$PhysarumPresets]` | the names of the presets |

## Details

* A preset name can be given to [PhysarumSimulation](PhysarumSimulation.md),
  [PhysarumArt](PhysarumArt.md) and [PhysarumAnimate](PhysarumAnimate.md):
  `PhysarumArt["Filaments"]`.
* A preset is a *full specification*, the same form you can write yourself. See
  [PhysarumSimulation](PhysarumSimulation.md) for the list of keys. In addition to the species it can
  hold the agent density, the suggested number of steps, and a rendering style (color function,
  background, gamma, glow) that [PhysarumImage](PhysarumImage.md) uses.
* Options you pass explicitly always win over the preset. For example,
  `PhysarumArt["Classic", "Steps" -> 100]` runs 100 steps rather than the preset's 600.
* Most presets share a base species with `"SensorAngle"` and `"RotationAngle"` of 30°,
  `"Deposit"` 1, `"Decay"` 0.3 and `"Diffusion"` 0.1, and differ in how far the agents look
  (`"SensorDistance"`).

## The presets

![All presets](../images/presets.png)

| Preset | Species | Sensor distance | Agent density | Steps | Character |
| --- | --- | --- | --- | --- | --- |
| `"Classic"` | 1 | 6 | 0.3 | 600 | a fine network of glowing veins in sunset colors |
| `"Filaments"` | 1 | 15 | 1 | 600 | longer, fibrous strands in blue |
| `"Nebula"` | 1 | 30 | 0.3 | 600 | large, cloudy cells in purple and orange |
| `"Leopard"` | 1 | 9 | 0.5 (default) | 500 | isolated spots: sensor angle 90°, rotation angle 11.25° |
| `"Mesh"` | 1 | 9 | 0.5 (default) | 500 | a dense web: sensor angle 22.5°, rotation angle 90° |
| `"Marble"` | 3 | 12 | 1 | 600 | three species that repel each other (repulsion 3), in marbled veins |
| `"Rivals"` | 2 | 12 | 1 | 600 | two species that repel each other (repulsion 1) |
| `"Ink"` | 1 | 12 | 0.5 | 600 | dark blue ink on cream paper, without glow |

## Examples

### List the presets

```wolfram
Keys[$PhysarumPresets]
(* {"Classic", "Filaments", "Nebula", "Leopard", "Mesh", "Marble", "Rivals", "Ink"} *)
```

### Draw them all

```wolfram
Table[Labeled[PhysarumArt[p, "Size" -> 250], p], {p, Keys[$PhysarumPresets]}]
```

### Look at a preset

```wolfram
$PhysarumPresets["Rivals"]
$PhysarumPresets["Rivals", "Species"][[All, "Repulsion"]]         (* {1, 1} *)
Keys[$PhysarumPresets["Classic"]]
```

### Override a preset

Any option you give takes precedence over the preset:

```wolfram
PhysarumArt["Classic", "Steps" -> 100]
PhysarumArt["Filaments", ColorFunction -> "SunsetColors", "Size" -> 300]
```

### Build on a preset

A preset is an Association, so you can change one of its values and use the result as a
specification. Here is `"Classic"` with agents that look farther ahead:

```wolfram
mine = MapAt[Append[#, "SensorDistance" -> 20] & /@ # &, $PhysarumPresets["Classic"], "Species"];
PhysarumArt[mine, "Size" -> 300]
```

A specification of your own can carry the same keys as a preset:

```wolfram
PhysarumArt[<|
   "Species" -> {<|"SensorDistance" -> 12, "Decay" -> 0.3, "Diffusion" -> 0.1, "Deposit" -> 1|>},
   "AgentDensity" -> 0.5, "Steps" -> 400,
   "ColorFunction" -> (Blend[{Black, DarkGreen, Yellow, White}, #] &)|>, "Size" -> 300]
```

Setting `$PhysarumPresets` itself is not needed. The presets in the session are only a
convenience, and any Association with a `"Species"` key works.

## See also

[PhysarumSimulation](PhysarumSimulation.md) ·
[PhysarumArt](PhysarumArt.md) ·
[PhysarumImage](PhysarumImage.md)
