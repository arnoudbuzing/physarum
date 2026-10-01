# Function reference

Reference pages for every symbol in the `ArnoudBuzing/Physarum` paclet. For an introduction to
the slime mould and to the two models, see the main [README](../README.md).

Load the paclet first:

```wolfram
PacletDirectoryLoad["/path/to/physarum/Physarum"];
Needs["ArnoudBuzing`Physarum`"]
```

## Agent model (trail-following particles)

| Function | Purpose |
| --- | --- |
| [PhysarumArt](PhysarumArt.md) | grow and render a simulation in one call |
| [PhysarumSimulation](PhysarumSimulation.md) | create a simulation: species, food, walls, initial layout |
| [PhysarumSimulationObject](PhysarumSimulationObject.md) | the simulation state, and the properties you can read from it |
| [PhysarumEvolve](PhysarumEvolve.md) | advance a simulation by a number of steps |
| [PhysarumImage](PhysarumImage.md) | render the trail map of a simulation as an image |
| [PhysarumAnimate](PhysarumAnimate.md) | render a sequence of frames, an animation or a video |
| [PhysarumNetwork](PhysarumNetwork.md) | grow a mould between food sources and read it off as a `Graph` |
| [$PhysarumPresets](PhysarumPresets.md) | the named parameter sets |

## Agent model in 3D

| Function | Purpose |
| --- | --- |
| [PhysarumArt3D](PhysarumArt3D.md) | grow and render a 3D simulation in one call |
| [PhysarumSimulation3D](PhysarumSimulation3D.md) | create a 3D simulation: species, food, walls, initial layout |
| [PhysarumSimulation3DObject](PhysarumSimulation3DObject.md) | the 3D simulation state, and the properties you can read from it |
| [PhysarumImage3D](PhysarumImage3D.md) | render the trail as a volume `Image3D` |
| [PhysarumGraphics3D](PhysarumGraphics3D.md) | render the network as a `Graphics3D` surface or point cloud |

[PhysarumEvolve](PhysarumEvolve.md) advances 2D and 3D simulations alike.

## Flow model (tubes carrying protoplasm)

| Function | Purpose |
| --- | --- |
| [PhysarumFlow](PhysarumFlow.md) | shortest paths in mazes and adaptive transport networks |
| [PhysarumMaze](PhysarumMaze.md) | generate a maze for `PhysarumFlow` to solve |

## Conventions

* **Options** are given as `"Name" -> value` rules, and option names are strings unless they
  are built-in symbols (`ColorFunction`, `Background`, `ImageSize`, `FrameRate`, `RandomSeeding`).
* **Angles** are in radians. Use `Degree`, as in `30 Degree`.
* **Points** in food and maze arguments are in the *unit square*: `{0, 0}` is the bottom left and
  `{1, 1}` is the top right, with *y pointing up*.
* **Points and regions in 3D** are in the *unit cube*, with *z pointing up*.
* **Masks** (for `"Food"`, `"Walls"` and `"Initialization"`) can be given as a string, a
  `Graphics` object, an `Image`, or a matrix of values between 0 and 1. Strings are rendered in
  bold Helvetica, cropped and centred. A `Graphics` object is stretched over the whole grid: its
  `PlotRange` is the grid, so give it an explicit `PlotRange` to control where things end up. A
  bare primitive such as `Disk[...]` is stretched so that it fills the grid.
* **Reproducibility.** The agent model draws its random numbers from the kernel's random
  generator, so `SeedRandom[n]` before a call makes it repeatable. `PhysarumFlow` and
  `PhysarumMaze` take a `RandomSeeding` option instead.
