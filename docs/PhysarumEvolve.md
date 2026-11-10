---
Template: Symbol
Name: PhysarumEvolve
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/PhysarumEvolve
Keywords: [physarum, slime mold, evolve, step, simulation]
SeeAlso: [PhysarumSimulation, PhysarumSimulation3D, PhysarumSimulationObject, PhysarumSimulation3DObject, PhysarumImage, PhysarumAnimate, PhysarumArt]
RelatedGuides: [Physarum]
---

## Usage

<code>PhysarumEvolve[*sim*, *n*]</code> advances the simulation *sim* (a [PhysarumSimulationObject]() or [PhysarumSimulation3DObject]()) by *n* steps and returns the new simulation object.

<code>PhysarumEvolve[*sim*]</code> advances *sim* by a single step.

## Details & Options

- Each step updates every agent in parallel (sense $\to$ rotate $\to$ move $\to$ deposit), then blurs (`"Diffusion"`), decays (`"Decay"`) and adds `"Stimulus"` across the trail map.
- Both 2D ([PhysarumSimulationObject]()) and 3D ([PhysarumSimulation3DObject]()) simulations are supported.
- *sim* is not modified in place; the returned object has `"Step"` increased by *n*.
- *n* must be a non-negative integer. `PhysarumEvolve[sim, 0]` returns *sim* unchanged.
- The inner loop runs in compiled Rust code via LibraryLink using all CPU cores and checks for user aborts at every step.
- Call [SeedRandom]() before creating and evolving a simulation for reproducible results.

## Basic Examples

Advance a 2D simulation by 300 steps and render the result:

```wl
sim = PhysarumSimulation["Classic", "Size" -> 220];
sim = PhysarumEvolve[sim, 300];
PhysarumImage[sim]
```

---

Advance by a single step:

```wl
sim = PhysarumSimulation["Classic", "Size" -> 100];
PhysarumEvolve[sim]["Step"]
```

## Scope

Advance a 3D simulation:

```wl
sim3D = PhysarumEvolve[PhysarumSimulation3D["Classic", "Size" -> 64], 200];
PhysarumGraphics3D[sim3D]
```

---

Capture snapshots at steps 2, 10, 50 and 350 using [FoldList]():

```wl
SeedRandom[1];
sim = PhysarumSimulation["Classic", "Size" -> 220];
states = FoldList[PhysarumEvolve, sim, {2, 8, 40, 300}];
PhysarumImage /@ Rest[states]
```

## Properties and Relations

Fixing the random seed before creating and evolving produces identical trail arrays:

```wl
SeedRandom[42];
a = PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 60], 20];
SeedRandom[42];
b = PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 60], 20];
a["Trail"] == b["Trail"]
```

---

Track the total trail in the grid over successive 10-step blocks:

```wl
sim = PhysarumSimulation["Classic", "Size" -> 150];
totals = Table[Total[(sim = PhysarumEvolve[sim, 10])["Trail"], 3], {30}];
ListLinePlot[totals, AxesLabel -> {"10-step blocks", "total trail"}]
```
