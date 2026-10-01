# PhysarumImage3D

Renders the trail map of a 3D simulation as a volume `Image3D`: strong trail is bright and opaque,
faint trail is dim and see-through.

## Syntax

| Form | Meaning |
| --- | --- |
| `PhysarumImage3D[sim]` | the volume rendering of the [PhysarumSimulation3DObject](PhysarumSimulation3DObject.md) `sim` |
| `PhysarumImage3D[sim, opts]` | with options |

## Details

* The result is an RGBA `Image3D` with the same dimensions as the grid. Colour comes from the trail,
  and opacity follows its strength.
* Each species' trail is lightly blurred (`"Smoothing"`), normalized (`"Clip"`), and
  gamma-corrected (`"Gamma"`).
* With **one species** and a `ColorFunction` (the presets have one), the colour function colours
  the volume. Otherwise each species is drawn in its own colour (`"Colors"`, or the species'
  `"Color"`), mixed in proportion to the species' share of the trail in each voxel.
* The default `"Gamma"` is 1 for one species and 2.5 for several. Several species fill the volume
  with faint trail, and the higher gamma keeps their strands apart.
* Unknown options are passed to `Image3D`, so `ViewPoint`, `Boxed`, `BoxRatios` and so on work.
* Volume rendering is the most faithful view of the trail, but it is slow to rotate for large grids.
  [PhysarumGraphics3D](PhysarumGraphics3D.md) is lighter.

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `ColorFunction` | Automatic | colour function for a single species. Automatic uses the preset's, or None. |
| `"Colors"` | Automatic | one colour per species |
| `Background` | Automatic | background colour. Automatic uses the preset's, or black. |
| `"Gamma"` | Automatic | gamma applied after normalization |
| `"Clip"` | Automatic | quantile of the trail that maps to full brightness (0.995) |
| `"Opacity"` | 1 | overall opacity scale |
| `"Smoothing"` | 2 | radius of the Gaussian blur applied first. 0 turns it off. |
| `"ShowFood"` | False | whether to draw the food sources |
| `"ShowWalls"` | True | whether to draw the walls (faint) |
| `"WallColor"` | `GrayLevel[0.6]` | colour of the walls |
| `"FoodColor"` | `RGBColor[1, 0.3, 0.35]` | colour of the food |
| `ImageSize` | Automatic | display size |

## Examples

```wolfram
sim = PhysarumEvolve[PhysarumSimulation3D["Classic"], 300];
PhysarumImage3D[sim]
PhysarumImage3D[sim, ColorFunction -> "SunsetColors", "Opacity" -> 0.5]
PhysarumImage3D[sim, ViewPoint -> Top, Boxed -> False]

PhysarumImage3D[PhysarumEvolve[PhysarumSimulation3D["Marble", "Size" -> 80], 300]]
```

## See also

[PhysarumGraphics3D](PhysarumGraphics3D.md) ·
[PhysarumArt3D](PhysarumArt3D.md) ·
[PhysarumSimulation3D](PhysarumSimulation3D.md) ·
[PhysarumImage](PhysarumImage.md)
