# PhysarumSimulation3DObject

The state of a 3D Physarum agent simulation. Create one with
[PhysarumSimulation3D](PhysarumSimulation3D.md), advance it with [PhysarumEvolve](PhysarumEvolve.md),
and read its contents with the properties below.

## Syntax

| Form | Meaning |
| --- | --- |
| `sim["property"]` | the value of a property |
| `sim["Properties"]` | the list of standard properties |

## Details

* Like its 2D counterpart, a 3D simulation object is an **immutable value**:
  [PhysarumEvolve](PhysarumEvolve.md) returns a new object.
* Objects display as a summary box. The thumbnail is the `"Projection"`, which is fast to compute,
  rather than a volume rendering.
* **Array layout.** `"Trail"`, `"Stimulus"` and `"Walls"` are indexed `[[z, y, x]]`, and every index
  increases along its axis: the first slice is the *bottom* of the volume and the first row is the
  *front*. (This differs from the 2D object, whose rows count from the top of the image, and from
  `Image3D`, whose first slice is the top.) [PhysarumImage3D](PhysarumImage3D.md) takes care of the
  conversion.

## Properties

| Property | Value |
| --- | --- |
| `"Step"` | the number of steps the simulation has been evolved |
| `"Size"` | `{width, height, depth}` of the grid in voxels |
| `"AgentCount"` | the total number of agents |
| `"Agents"` | an `n × 7` matrix with one row `{x, y, z, hx, hy, hz, species}` per agent |
| `"Trail"` | the trail map, an array of dimensions `{species, depth, height, width}` |
| `"Stimulus"` | the food attractant added at every step, a `depth × height × width` array |
| `"Walls"` | the wall mask, a `depth × height × width` array of 0 and 1 |
| `"Species"` | the list of complete species Associations, with all defaults filled in |
| `"Wrap"` | `True` if the grid is periodic |
| `"Image3D"` | the volume rendering, as from `PhysarumImage3D[sim]` |
| `"Graphics3D"` | the surface rendering, as from `PhysarumGraphics3D[sim]` |
| `"Projection"` | a 2D `Image`: the maximum of the trail along z, seen from above |
| `"Properties"` | the list of the standard properties above |

`"Colors"`, `"Steps"`, `"Style"`, `"Parameters"` and `"Data"` also work, as for
[PhysarumSimulationObject](PhysarumSimulationObject.md).

### Agents

Each row of `"Agents"` is `{x, y, z, hx, hy, hz, species}`:

* `x`, `y` and `z` run from 0 to the width, height and depth. Divide by `sim["Size"]` to get
  unit-cube coordinates.
* `{hx, hy, hz}` is the heading, a unit vector.
* `species` is the index of the species, counted from **0**.

## Examples

```wolfram
sim = PhysarumEvolve[PhysarumSimulation3D["Classic", "Size" -> 64], 200];
sim["Properties"]
sim["Projection"]
Histogram[sim["Agents"][[All, 3]]]                  (* how the agents are spread over height *)
Image3D[Reverse[First[sim["Trail"]], {1, 2}]]      (* the raw trail, the right way up *)
```

## See also

[PhysarumSimulation3D](PhysarumSimulation3D.md) ·
[PhysarumEvolve](PhysarumEvolve.md) ·
[PhysarumImage3D](PhysarumImage3D.md) ·
[PhysarumGraphics3D](PhysarumGraphics3D.md) ·
[PhysarumSimulationObject](PhysarumSimulationObject.md)
