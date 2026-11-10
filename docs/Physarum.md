---
Template: Guide
Name: Physarum
Title: Physarum
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/guide/Physarum
Description: Slime-mold (Physarum polycephalum) agent and flow simulations for generative art, shortest paths and transport networks.
Keywords: [physarum, slime mold, agent-based, generative art, transport network, emergence, maze, Tero, Jones]
RelatedGuides: [GraphAndNetworks, ImageProcessing, CellularAutomata]
---

## Abstract

`ArnoudBuzing/Physarum` simulates the slime mold *Physarum polycephalum* using two classic models: Jeff Jones's multi-agent trail model (in 2D and 3D) for emergent pattern formation and generative art, and Tero *et al.*'s adaptive tube-flow model for maze solving and transport networks.

## Functions

### 2D Agent Simulations

- `PhysarumArt` grow and render a 2D slime-mold simulation in one call
- `PhysarumSimulation` create a 2D multi-agent simulation with species, food and walls
- `PhysarumSimulationObject` represent the state of a 2D simulation
- `PhysarumEvolve` advance a 2D or 3D simulation by a number of steps
- `PhysarumImage` render the trail map of a 2D simulation as an `Image`
- `PhysarumAnimate` evolve a simulation and return frames, an animation or a `Video`
- `$PhysarumPresets` association of named species and rendering presets

### 3D Agent Simulations

- `PhysarumArt3D` grow and render a 3D slime-mold simulation in one call
- `PhysarumSimulation3D` create a 3D multi-agent simulation in a voxel volume
- `PhysarumSimulation3DObject` represent the state of a 3D simulation
- `PhysarumImage3D` render the 3D trail map as a volume `Image3D`
- `PhysarumGraphics3D` render the 3D network as an isosurface or agent point cloud

### Transport Networks & Flow Model

- `PhysarumNetwork` grow an agent trail between points or `GeoPosition` locations and extract a `Graph`
- `PhysarumFlow` run the Tero current-reinforcement flow model on a maze, point set or `Graph`
- `PhysarumMaze` generate a 2D maze `Image` with optional loops
