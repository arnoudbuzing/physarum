---
Template: Symbol
Name: PhysarumAnimate
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/PhysarumAnimate
Keywords: [physarum, slime mold, animate, frames, video, evolution]
SeeAlso: [PhysarumEvolve, PhysarumImage, PhysarumSimulation, PhysarumArt]
RelatedGuides: [Physarum]
---

## Usage

<code>PhysarumAnimate[*sim*, *frames*, *steps*]</code> evolves *sim* for *frames* frames of *steps* steps each and returns the rendered frames.

<code>PhysarumAnimate["*preset*", *frames*, *steps*]</code> creates and animates a simulation from a preset name or species specification.

<code>PhysarumAnimate[*spec*, *frames*, *steps*, *opts*]</code> animates with the given options.

## Details & Options

- The first returned frame is the simulation after *steps* steps, and the last frame is at step $\text{frames} \times \text{steps}$ beyond the initial state of *sim*.
- If the first argument is not a [PhysarumSimulationObject](), a new simulation is created via <code>PhysarumSimulation[*spec*]</code>.
- All options of [PhysarumImage]() (`ColorFunction`, `"Colors"`, `Background`, `"Gamma"`, `"Glow"`, `"Clip"`, `"ShowFood"`, `"ShowWalls"`, `"WallColor"`, `"FoodColor"`, `ImageSize`) are forwarded to every rendered frame.
- [PhysarumAnimate]() accepts the following options:

| Option | Default | Description |
| --- | --- | --- |
| `"Output"` | `"Frames"` | return format: `"Frames"` (list of [Image]()s), `"Animation"` ([ListAnimate]()) or `"Video"` ([Video]()) |
| [FrameRate]() | `30` | frames per second for `"Animation"` and `"Video"` |

## Basic Examples

Generate 60 frames spaced 10 steps apart and animate them:

```wl
frames = PhysarumAnimate["Classic", 60, 10];
ListAnimate[frames]
```

## Scope

Configure size, food or walls on a [PhysarumSimulationObject]() before passing it to [PhysarumAnimate]():

```wl
sim = PhysarumSimulation["Marble", "Size" -> 384];
frames = PhysarumAnimate[sim, 120, 5];
ListAnimate[frames, 30]
```

## Options

### `"Output"` and `FrameRate`

Return an interactive [ListAnimate]() control directly:

```wl
PhysarumAnimate["Filaments", 40, 10, "Output" -> "Animation", FrameRate -> 15]
```

---

Render an MP4 [Video]() object at 60 frames per second:

```wl
PhysarumAnimate[PhysarumSimulation["Marble", "Size" -> 384], 120, 5, "Output" -> "Video", FrameRate -> 60]
```

### Rendering options

Pass [PhysarumImage]() options such as `"ShowFood"` or [ColorFunction]() to style every frame:

```wl
SeedRandom[5];
food = RandomReal[{0.15, 0.85}, {9, 2}];
sim = PhysarumSimulation["Classic", "Size" -> 220, "Food" -> food, "FoodStrength" -> 50];
ListAnimate[PhysarumAnimate[sim, 60, 15, "ShowFood" -> True]]
```
