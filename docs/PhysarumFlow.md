---
Template: Symbol
Name: PhysarumFlow
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/PhysarumFlow
Keywords: [physarum, slime mold, Tero, flow model, Kirchhoff, shortest path, maze, transport network]
SeeAlso: [PhysarumMaze, PhysarumNetwork]
RelatedGuides: [Physarum]
---

## Usage

<code>PhysarumFlow[*maze*, {*p*<sub>1</sub>, *p*<sub>2</sub>, …}]</code> runs the Tero current-reinforcement flow model through the free cells of a maze [Image](), with food at the unit-square points *p*<sub>*i*</sub>.

<code>PhysarumFlow[{*p*<sub>1</sub>, *p*<sub>2</sub>, …}]</code> grows an adaptive flow network between food sources on a 2D lattice.

<code>PhysarumFlow[*g*, {*v*<sub>1</sub>, *v*<sub>2</sub>, …}]</code> runs the flow model on the [Graph]() *g* with food at vertices *v*<sub>*i*</sub>.

<code>PhysarumFlow[*spec*, *opts*]</code> runs the flow model with the given options.

## Details & Options

- In the Tero *et al.* model, protoplasm flows through a network of tubes where each tube has length $L_e$ and conductivity $D_e$ (initially `1`).
- At each step, one food source pumps in flux $I_0$ (`"Flux"`) while the remaining food sources drain it equally. Pressures follow from Kirchhoff's laws via [LinearSolve]() on the weighted graph Laplacian, giving flow $Q_e = (D_e / L_e) \Delta p_e$, and conductivities adapt according to $dD_e/dt = f(|Q_e|) - D_e$.
- With two food sources and $f(Q) = |Q|$, only the shortest path between the two sources survives. With more than two food sources and $f(Q) = |Q|^\gamma / (1 + |Q|^\gamma)$, a fault-tolerant transport network emerges.
- [PhysarumFlow]() accepts the following options:

| Option | Default | Description |
| --- | --- | --- |
| `"Steps"` | [Automatic]() | number of adaptation steps (`200` for two food sources, `600` for more) |
| `"Flux"` | `2` | total flux pumped in at each step (higher flux retains more cross-links) |
| `"Exponent"` | [Automatic]() | feedback exponent $\gamma$ (`1.8` by default for $>2$ sources) |
| `"TimeStep"` | `0.3` | Euler integration step size $dt$ |
| `"Threshold"` | `0.01` | minimum fraction of maximum conductivity kept in the output [Graph]() |
| `"Resolution"` | `50` | lattice nodes along the longest side for point-set input |
| `"Output"` | [Automatic]() | return format: `"Image"`, `"Graph"`, `"Frames"`, `"History"` or `"Conductivity"` |
| [ImageSize]() | `400` | output image width for maze input |
| [RandomSeeding]() | [Automatic]() | random seed for source selection when $>2$ food sources are present |

## Basic Examples

Solve a maze with multiple loops by placing food at the top-left and bottom-right corners:

```wl
maze = PhysarumMaze[10, "Loops" -> 8, RandomSeeding -> 3];
PhysarumFlow[maze, {{0.05, 0.95}, {0.95, 0.05}}]
```

---

Grow an adaptive transport network between 14 points in the plane:

```wl
SeedRandom[7];
pts = RandomReal[1, {14, 2}];
PhysarumFlow[pts]
```

## Scope

Run the flow model on an explicit [Graph]():

```wl
PhysarumFlow[GridGraph[{15, 15}], {1, 225}]
```

---

On a weighted graph, the flow reinforces the shortest weighted path:

```wl
ring = Graph[{1 <-> 2, 2 <-> 3, 1 <-> 3}, EdgeWeight -> {1, 1, 5}];
PhysarumFlow[ring, {1, 3}, "Output" -> "Conductivity"]
```

## Options

### `"Flux"`

Vary `"Flux"` to trade network economy (tree-like) for redundancy (looped):

```wl
Table[PhysarumFlow[pts, "Flux" -> f, "Resolution" -> 60, RandomSeeding -> 1], {f, {1, 4, 16}}]
```

### `"Output"`

Plot the conductivity history of every tube on a $5 \times 5$ grid graph:

```wl
hist = PhysarumFlow[GridGraph[{5, 5}], {1, 25}, "Output" -> "History"];
ListLinePlot[Transpose[hist], PlotRange -> All, AxesLabel -> {"step", "conductivity"}]
```
