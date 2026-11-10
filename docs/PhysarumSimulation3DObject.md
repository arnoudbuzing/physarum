---
Template: Symbol
Name: PhysarumSimulation3DObject
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/PhysarumSimulation3DObject
Keywords: [physarum, slime mold, 3D, simulation object, state, voxel]
SeeAlso: [PhysarumSimulation3D, PhysarumEvolve, PhysarumImage3D, PhysarumGraphics3D, PhysarumSimulationObject]
RelatedGuides: [Physarum]
---

## Usage

<code>PhysarumSimulation3DObject[*assoc*]</code> represents the state of a 3D Physarum simulation.

<code>*sim*["*prop*"]</code> extracts the property *prop* from the 3D simulation object *sim*.

## Details & Options

- Create a [PhysarumSimulation3DObject]() with [PhysarumSimulation3D]() and advance it with [PhysarumEvolve]().
- Like [PhysarumSimulationObject](), a 3D simulation object is an **immutable value**.
- Its summary box displays a fast 2D maximum-intensity `"Projection"` thumbnail along the $z$ axis.
- The following properties can be extracted with `*sim*["*prop*"]`:

| Property | Description |
| --- | --- |
| `"Step"` | number of steps the simulation has been evolved |
| `"Size"` | `{width, height, depth}` of the voxel grid |
| `"AgentCount"` | total number of agents |
| `"Agents"` | $n \times 7$ matrix with rows `{x, y, z, hx, hy, hz, species}` |
| `"Trail"` | 4D array of dimensions `{species, depth, height, width}` |
| `"Stimulus"` | `depth × height × width` food attractant array |
| `"Walls"` | `depth × height × width` binary obstacle array (`0` or `1`) |
| `"Species"` | list of complete species [Association]()s |
| `"Wrap"` | [True]() if the grid is periodic |
| `"Image3D"` | volume rendering, equivalent to <code>PhysarumImage3D[*sim*]</code> |
| `"Graphics3D"` | surface rendering, equivalent to <code>PhysarumGraphics3D[*sim*]</code> |
| `"Projection"` | 2D maximum-intensity projection array along $z$ |
| `"Properties"` | list of standard property names |
| `"Data"` | the underlying [Association]() |

## Basic Examples

Create and evolve a 3D simulation and list its properties:

```wl
sim = PhysarumEvolve[PhysarumSimulation3D["Classic", "Size" -> 64], 200];
sim["Properties"]
```

---

Display the 2D maximum-intensity projection along $z$:

```wl
Image[sim["Projection"]]
```

## Scope

Inspect the distribution of agent heights along the $z$ axis:

```wl
Histogram[sim["Agents"][[All, 3]]]
```

---

Convert the raw first-species trail volume directly to an [Image3D]():

```wl
Image3D[Reverse[First[sim["Trail"]], {1, 2}]]
```
