---
Template: Symbol
Name: PhysarumGraphics3D
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/PhysarumGraphics3D
Keywords: [physarum, slime mold, 3D, Graphics3D, isosurface, mesh, point cloud]
SeeAlso: [PhysarumImage3D, PhysarumArt3D, PhysarumSimulation3D, PhysarumSimulation3DObject]
RelatedGuides: [Physarum]
---

## Usage

<code>PhysarumGraphics3D[*sim*]</code> renders a [PhysarumSimulation3DObject]() *sim* as a 3D isosurface in [Graphics3D]().

<code>PhysarumGraphics3D[*sim*, *opts*]</code> renders *sim* with the given options.

## Details & Options

- With `Method -> "Surface"` (the default), each species' normalized trail volume is smoothed and converted to a triangle mesh at level `"Threshold"` via marching cubes.
- With `Method -> "Points"`, up to `"MaxPoints"` agents are drawn as colored 3D points shaded by trail strength.
- Additional [Graphics3D]() options such as [ViewPoint](), [Boxed]() and [Lighting]() are passed through.
- [PhysarumGraphics3D]() accepts the following options:

| Option | Default | Description |
| --- | --- | --- |
| [Method]() | `"Surface"` | rendering method: `"Surface"` or `"Points"` |
| `"Colors"` | [Automatic]() | list of colors, one per species |
| [Background]() | [Automatic]() | background color (preset default, or [Black]()) |
| `"Threshold"` | [Automatic]() | isosurface level in $[0, 1]$ of the normalized trail (default `0.3`) |
| `"Smoothing"` | `1` | Gaussian blur radius in voxels before surface extraction |
| `"MaxPoints"` | `50000` | maximum number of agents plotted when `Method -> "Points"` |
| `"ShowFood"` | [True]() | whether to render food sources as red surfaces |
| `"ShowWalls"` | [True]() | whether to render walls as translucent gray surfaces |
| `"WallColor"` | `GrayLevel[0.6]` | color used for walls |
| `"FoodColor"` | `RGBColor[1, 0.3, 0.35]` | color used for food sources |
| [ImageSize]() | [Automatic]() | display size |

## Basic Examples

Render the 3D trail network as a surface:

```wl
sim = PhysarumEvolve[PhysarumSimulation3D["Classic", "Size" -> 64], 300];
PhysarumGraphics3D[sim]
```

## Options

### `Method`

Render the agents directly as a 3D point cloud:

```wl
PhysarumGraphics3D[sim, Method -> "Points", "MaxPoints" -> 100000]
```

### `"Threshold"`

Raise `"Threshold"` to keep only the thickest core tubes:

```wl
{PhysarumGraphics3D[sim, "Threshold" -> 0.2], PhysarumGraphics3D[sim, "Threshold" -> 0.5]}
```
