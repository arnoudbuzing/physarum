# PhysarumArt3D

Grows a 3D slime-mould simulation and renders it in one call.

## Syntax

| Form | Meaning |
| --- | --- |
| `PhysarumArt3D[]` | grows and renders the `"Classic"` preset |
| `PhysarumArt3D["preset"]` | grows and renders a named preset from [$PhysarumPresets](PhysarumPresets.md) |
| `PhysarumArt3D[spec]` | grows and renders any specification accepted by [PhysarumSimulation3D](PhysarumSimulation3D.md) |
| `PhysarumArt3D[spec, opts]` | with options |

## Details

* `PhysarumArt3D[spec, opts]` is shorthand for:

  ```wolfram
  sim = PhysarumSimulation3D[spec, (simulation options)];
  sim = PhysarumEvolve[sim, steps];
  PhysarumImage3D[sim, (image options)]      (* or PhysarumGraphics3D *)
  ```
* `"Output"` chooses the result: `"Image3D"` (the default), `"Graphics3D"`, or `"Simulation"` for the
  evolved [PhysarumSimulation3DObject](PhysarumSimulation3DObject.md) itself.
* It accepts the options of [PhysarumSimulation3D](PhysarumSimulation3D.md), of
  [PhysarumImage3D](PhysarumImage3D.md) and of [PhysarumGraphics3D](PhysarumGraphics3D.md), plus
  `"Steps"` and `"Output"`.
* The default `"Steps"` is 300.
* Use `SeedRandom[n]` before the call to get a repeatable result.

## Examples

```wolfram
PhysarumArt3D[]
PhysarumArt3D["Rivals", "Output" -> "Graphics3D"]
PhysarumArt3D["Classic", "Output" -> "Graphics3D", Method -> "Points"]
PhysarumArt3D[<|"SensorAngle" -> 45 Degree, "SensorDistance" -> 12|>, "Size" -> 80, "Steps" -> 400]
```

## See also

[PhysarumSimulation3D](PhysarumSimulation3D.md) ·
[PhysarumImage3D](PhysarumImage3D.md) ·
[PhysarumGraphics3D](PhysarumGraphics3D.md) ·
[PhysarumArt](PhysarumArt.md)
