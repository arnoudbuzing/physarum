# PhysarumAnimate

Runs a simulation and renders the frames, as a list of images, an interactive animation or a video.

## Syntax

| Form | Meaning |
| --- | --- |
| `PhysarumAnimate[sim, frames, steps]` | evolves `sim` for `frames` frames of `steps` steps each, and returns the rendered frames |
| `PhysarumAnimate["preset", frames, steps]` | the same for a new simulation made from a preset (or any specification) |
| `PhysarumAnimate[..., opts]` | with options |

## Details

* The first frame is the simulation *after* the first `steps` steps, not the starting state. The
  last frame is at step `frames × steps` beyond the starting point of `sim`.
* `frames` and `steps` must be positive integers.
* If the first argument is not a simulation object, a simulation is created from it with
  [PhysarumSimulation](PhysarumSimulation.md) and default options. To set `"Size"` or other
  simulation options, create the simulation yourself and pass it in.
* The options of [PhysarumImage](PhysarumImage.md) (`ColorFunction`, `"Colors"`, `Background`,
  `"Gamma"`, `"Glow"`, `"Clip"`, `"ShowFood"`, `"ShowWalls"`, `"WallColor"`, `"FoodColor"`,
  `ImageSize`) are passed on to every frame.
* `"Output" -> "Video"` writes an MP4 file into `$TemporaryDirectory` and returns it as a `Video`.
  Use `Export` on the frames yourself if you want to keep a file or write a GIF.
* The simulation is evolved in one pass, and an aborted evaluation returns `$Aborted`.

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `"Output"` | `"Frames"` | what to return: `"Frames"`, `"Animation"` or `"Video"` (see below) |
| `FrameRate` | 30 | frames per second, for `"Animation"` and `"Video"` |
| `ColorFunction`, `"Colors"`, `Background`, `"Gamma"`, `"Glow"`, `"Clip"`, `"ShowFood"`, `"ShowWalls"`, `"WallColor"`, `"FoodColor"`, `ImageSize` | | as for [PhysarumImage](PhysarumImage.md) |

### `"Output"` values

| Value | Result |
| --- | --- |
| `"Frames"` | a list of `Image` objects |
| `"Animation"` | a `ListAnimate` control (not started automatically) |
| `"Video"` | a `Video` object, made from an MP4 file |

## Examples

### A list of frames

```wolfram
frames = PhysarumAnimate["Classic", 60, 10];       (* 60 frames, 10 steps each *)
Length[frames]                                       (* 60 *)
ListAnimate[frames]
```

![From noise to network](../images/growth.gif)

### Start from your own simulation

Create the simulation first to set its size, food, walls and species:

```wolfram
sim = PhysarumSimulation["Marble", "Size" -> 384];
frames = PhysarumAnimate[sim, 120, 5];
ListAnimate[frames, 30]
```

### A video

```wolfram
PhysarumAnimate[PhysarumSimulation["Marble", "Size" -> 384], 120, 5, "Output" -> "Video"]
PhysarumAnimate[PhysarumSimulation["Marble", "Size" -> 384], 120, 5, "Output" -> "Video", FrameRate -> 60]
```

### An animation control

```wolfram
PhysarumAnimate["Filaments", 40, 10, "Output" -> "Animation", FrameRate -> 15]
```

### Frames with their own look

The image options apply to every frame:

```wolfram
PhysarumAnimate["Classic", 30, 10, ColorFunction -> "SunsetColors", "Glow" -> 0.6, ImageSize -> 300]
```

### Watch a network grow to its food

```wolfram
SeedRandom[5];
food = RandomReal[{0.15, 0.85}, {9, 2}];
sim = PhysarumSimulation["Classic", "Size" -> 220, "Food" -> food, "FoodStrength" -> 50];
ListAnimate[PhysarumAnimate[sim, 60, 15, "ShowFood" -> True]]
```

### Export a GIF

```wolfram
Export["physarum.gif", PhysarumAnimate["Classic", 60, 10, ImageSize -> 300], "DisplayDurations" -> 1/20]
```

### Continue from a partly evolved state

The frames are made from a copy, so `sim` itself is unchanged. Evolve it yourself if you need the
final state:

```wolfram
sim = PhysarumSimulation["Classic", "Size" -> 200];
frames = PhysarumAnimate[sim, 10, 20];
sim["Step"]                          (* 0 *)
last = PhysarumEvolve[sim, 200];
```

## See also

[PhysarumEvolve](PhysarumEvolve.md) ·
[PhysarumImage](PhysarumImage.md) ·
[PhysarumSimulation](PhysarumSimulation.md) ·
[PhysarumArt](PhysarumArt.md)
