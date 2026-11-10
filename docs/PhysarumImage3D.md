---
Template: Symbol
Name: PhysarumImage3D
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/PhysarumImage3D
Keywords: [physarum, slime mold, 3D, volume, Image3D, visualization]
SeeAlso: [PhysarumGraphics3D, PhysarumArt3D, PhysarumSimulation3D, PhysarumSimulation3DObject, PhysarumImage]
RelatedGuides: [Physarum]
---

## Usage

<code>PhysarumImage3D[*sim*]</code> renders the trail map of a [PhysarumSimulation3DObject]() *sim* as a volume [Image3D]().

<code>PhysarumImage3D[*sim*, *opts*]</code> renders *sim* with the given options.

<code>PhysarumImage3D[{*sim*<sub>1</sub>, *sim*<sub>2</sub>, …}, *opts*]</code> renders each 3D simulation in the list.

## Details & Options

- [PhysarumImage3D]() is listable over a list of [PhysarumSimulation3DObject]() expressions.
- The result is an RGBA [Image3D]() with voxel opacity proportional to trail strength.
- Additional [Image3D]() options such as [ViewPoint](), [Boxed]() and [BoxRatios]() are passed through.
- [PhysarumImage3D]() accepts the following options:

| Option | Default | Description |
| --- | --- | --- |
| [ColorFunction]() | [Automatic]() | color function for a single species |
| `"Colors"` | [Automatic]() | list of colors, one per species |
| [Background]() | [Automatic]() | background color (preset default, or [Black]()) |
| `"Gamma"` | [Automatic]() | gamma exponent applied after normalization (`1` for one species, `2.5` for multiple) |
| `"Clip"` | [Automatic]() | quantile mapped to full intensity (default `0.995`) |
| `"Opacity"` | `1` | overall voxel opacity scale |
| `"Smoothing"` | `2` | Gaussian blur radius in voxels (`0` disables smoothing) |
| `"ShowFood"` | [False]() | whether to render food sources |
| `"ShowWalls"` | [True]() | whether to render walls |
| `"WallColor"` | `GrayLevel[0.6]` | color used for walls |
| `"FoodColor"` | `RGBColor[1, 0.3, 0.35]` | color used for food sources |
| [ImageSize]() | [Automatic]() | display size |

## Basic Examples

Render a 3D simulation as a volume [Image3D]():

```wl
sim = PhysarumEvolve[PhysarumSimulation3D["Classic", "Size" -> 64], 300];
PhysarumImage3D[sim]
```

## Options

### `ColorFunction` and `"Opacity"`

Customize the color function and overall opacity:

```wl
PhysarumImage3D[sim, ColorFunction -> "SunsetColors", "Opacity" -> 0.5]
```

### `Image3D` options

Pass standard [Image3D]() options such as [ViewPoint]() and [Boxed]():

```wl
PhysarumImage3D[sim, ViewPoint -> Top, Boxed -> False]
```
