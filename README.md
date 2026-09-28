# Physarum

![Three competing species (the "Marble" preset)](images/hero.png)

A Wolfram Language paclet (`ArnoudBuzing/Physarum`) for **slime-mould simulations**. Hundreds of
thousands of simple agents follow each other's chemical trails, and glowing, vein-like
transport networks emerge. They look like *Physarum polycephalum*, the slime mould that
famously re-created the Tokyo rail network.

The model follows J. Jones, *"Characteristics of pattern formation and evolution in
approximations of Physarum transport networks"* (Artificial Life 16, 2010). It adds
multiple competing species, food sources and walls.

The hot inner loop (sense → rotate → move → deposit → diffuse) runs in a small Rust library,
called through LibraryLink and parallelized with rayon. Everything else is Wolfram
Language: setup, presets, rendering, animation and network extraction.

## Layout

```
Physarum/            the paclet
  PacletInfo.wl
  Kernel/Physarum.wl
  LibraryResources/<SystemID>/libphysarum.dylib   (built, not checked in)
physarum-rs/         Rust source of the simulation kernel
scripts/build.sh     builds the Rust library and installs it into the paclet
Tests/Physarum.wlt   test suite
images/              the pictures in this README
```

## Build & load

Requires a Rust toolchain (`cargo`) and Wolfram Language 14.1+.

```sh
./scripts/build.sh
```

```wolfram
PacletDirectoryLoad["/path/to/fun/Physarum"];
Needs["ArnoudBuzing`Physarum`"]
```

## Quick start

![All presets](images/presets.png)

```wolfram
(* one-shot: grow and render *)
PhysarumArt[]

(* the named presets *)
Keys[$PhysarumPresets]
(* {"Classic", "Filaments", "Nebula", "Leopard", "Mesh", "Marble", "Rivals", "Ink"} *)

PhysarumArt["Filaments"]
PhysarumArt["Marble", "Size" -> 768]
```

## Step by step

![From noise to network](images/growth.gif)

```wolfram
sim = PhysarumSimulation["Classic", "Size" -> 512];   (* a PhysarumSimulationObject *)
sim = PhysarumEvolve[sim, 400];                        (* advance 400 steps *)
PhysarumImage[sim]

sim["Step"]          (* 400 *)
sim["AgentCount"]
sim["Trail"]         (* {species, h, w} array of chemo-attractant *)
sim["Properties"]
```

Rendering options for `PhysarumImage` (and `PhysarumArt`):

```wolfram
PhysarumImage[sim, ColorFunction -> "SunsetColors"]
PhysarumImage[sim, ColorFunction -> None, "Colors" -> {Cyan}, Background -> Black]
PhysarumImage[sim, "Glow" -> 0.6, "Gamma" -> 0.5]
PhysarumImage[sim, Background -> White, "Colors" -> {Darker[Blue]}, "Glow" -> 0]  (* ink on paper *)
```

## Your own species

A species is an Association. Unspecified keys use the defaults. Angles are in radians,
so use `Degree`.

```wolfram
PhysarumArt[<|
  "SensorAngle"    -> 30 Degree,   (* angle between the three forward sensors *)
  "SensorDistance" -> 12,          (* how far ahead agents sense, in pixels   *)
  "RotationAngle"  -> 30 Degree,   (* how sharply agents turn                 *)
  "StepSize"       -> 1,
  "Deposit"        -> 1,           (* trail laid per step                     *)
  "Decay"          -> 0.3,         (* fraction of trail lost per step         *)
  "Diffusion"      -> 0.1,         (* 0 = no blur, 1 = full 3x3 blur per step *)
  "Jitter"         -> 0            (* random wiggle added to the heading      *)
|>, "Steps" -> 500]
```

Multiple species: give a list. `"Repulsion"` makes each species avoid the others' trails.

```wolfram
PhysarumArt[<|
  "Species" -> {
    <|"SensorDistance" -> 12, "Diffusion" -> 0.1, "Decay" -> 0.3, "Deposit" -> 1, "Repulsion" -> 2, "Color" -> Orange|>,
    <|"SensorDistance" -> 25, "Diffusion" -> 0.1, "Decay" -> 0.3, "Deposit" -> 1, "Repulsion" -> 2, "Color" -> Cyan, "Fraction" -> 2|>
  },
  "AgentDensity" -> 1
|>, "Steps" -> 600]
```

Some parameter regimes worth exploring:

| Look | Parameters |
| --- | --- |
| fine mesh | `SensorDistance` 6, `Diffusion` 0.1, `Decay` 0.3 |
| fibrous cells | `SensorDistance` 15–30, `Diffusion` 0.1 |
| leopard spots | `SensorAngle` 90°, `RotationAngle` 11.25° |
| dense web | `SensorAngle` 22.5°, `RotationAngle` 90° |
| thick loops | defaults (`Decay` 0.1, `Diffusion` 1) |

## Initialization, food and walls

```wolfram
(* start the agents in a shape: "Random", "Disk", "Ring", "Burst", "Food", or any String/Graphics/Image *)
PhysarumArt["Classic", "Initialization" -> "Disk", "Wrap" -> False, "Steps" -> 200]

(* food: agents are drawn to it. Points in the unit square, or text/graphics/images *)
PhysarumArt["Filaments", "Food" -> "PHYSARUM", "FoodStrength" -> 5, "Initialization" -> "Food", "Size" -> {768, 256}]

PhysarumArt["Classic", "Food" -> RandomReal[1, {12, 2}], "FoodStrength" -> 50, "ShowFood" -> True]

(* walls: anything maskable; agents cannot enter them *)
PhysarumArt["Classic", "Walls" -> Graphics[{Disk[{0, 0}, 0.3], Disk[{0.6, 0.5}, 0.15]}, PlotRange -> {{-1, 1}, {-1, 1}}]]
```

![Growing towards text](images/text.png)

![Growing around walls](images/walls.png)

## Animation

```wolfram
frames = PhysarumAnimate["Classic", 60, 10];               (* 60 frames, 10 steps each *)
ListAnimate[frames]

PhysarumAnimate[PhysarumSimulation["Marble", "Size" -> 384], 120, 5, "Output" -> "Video"]
```

## Transport networks → `Graph`

`PhysarumNetwork` works like the famous slime-mould experiments. It puts food at the given
points, lets the mould grow between them, then reads the result off as a `Graph`:

1. threshold the trail map (gamma-compressed so faint filaments survive), thin it to a skeleton;
2. collapse junction pixel clusters into single nodes, and walk the pixel chains between them.
   Resampling every few pixels keeps the edges curved;
3. attach each food source to its nearest network vertex, and delete dead ends that lead to
   no food.

The graph carries `VertexCoordinates` (in your coordinates) and Euclidean `EdgeWeight`s.
Food sources are the vertices `"Food1"`, `"Food2"`, … (or the original `Entity` for
entity input).

```wolfram
pts = RandomReal[1, {14, 2}];
g = PhysarumNetwork[pts]

PhysarumNetwork[pts, "Output" -> "Image"]         (* the grown mould, food highlighted *)
PhysarumNetwork[pts, "Output" -> "Association"]   (* Graph, Simulation, Image, Skeleton, Food *)
PhysarumNetwork[pts, "Backbone" -> True]          (* only edges on shortest food-to-food paths *)

(* compare the mould with the minimum spanning tree *)
FindSpanningTree[PhysarumNetwork[pts, "Backbone" -> True]]
```

![Grown mould, extracted graph, backbone](images/network.png)

Useful options: `"Size"` (grid resolution, default 400), `"Steps"` (2000),
`"AgentDensity"` (0.3), `"FoodStrength"` (300), `"Walls"`, `"Species"`, and
`"DeleteDeadEnds"` / `"Backbone"`.

### Geographic networks

Give `GeoPosition`s or entities with a position (cities, airports, landmarks, …), and use
`"Output" -> "GeoGraphics"`. Entities are resolved with one batched `EntityValue[..., "Position"]`
lookup, and the graph's food vertices are the entities themselves:

```wolfram
cities = Entity["City", #] & /@ {
  {"Amsterdam", "NoordHolland", "Netherlands"}, {"Rotterdam", "ZuidHolland", "Netherlands"},
  {"TheHague", "ZuidHolland", "Netherlands"}, {"Utrecht", "Utrecht", "Netherlands"},
  {"Eindhoven", "NoordBrabant", "Netherlands"}, {"Groningen", "Groningen", "Netherlands"},
  {"Zwolle", "Overijssel", "Netherlands"}, {"Maastricht", "Limburg", "Netherlands"}};

PhysarumNetwork[cities, "Output" -> "GeoGraphics", "Backbone" -> True]

g = PhysarumNetwork[cities, "Backbone" -> True];
GraphDistance[g, cities[[1]], cities[[8]]]   (* hops along the mould from Amsterdam to Maastricht *)
```

Here is a network for the 15 largest Dutch cities:

![A slime-mould rail network for the Netherlands](images/netherlands.png)

The mould knows nothing about water: pass a land/sea mask as `"Walls"` for a more
realistic network. Occasionally a food source ends up with no strand to it (the
graph is then not connected); a larger `"Steps"` or `"FoodStrength"` usually fixes that.

## Tests

```sh
wolframscript -code 'TestReport["Tests/Physarum.wlt"]'
```

## Performance

A 512×512 grid with 131k agents runs about 300 steps per second on an Apple M-series machine.
Evaluations can be aborted as usual (the Rust loop checks for aborts every step).

## License

MIT
