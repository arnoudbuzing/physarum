---
Template: Symbol
Name: $PhysarumPresets
Context: ArnoudBuzing`Physarum`
Paclet: ArnoudBuzing/Physarum
URI: ArnoudBuzing/Physarum/ref/$PhysarumPresets
Keywords: [physarum, slime mold, presets, parameters, species]
SeeAlso: [PhysarumArt, PhysarumSimulation, PhysarumImage, PhysarumSimulation3D, PhysarumArt3D]
RelatedGuides: [Physarum]
---

## Usage

<code>$PhysarumPresets</code> is an [Association]() of named simulation presets accepted by [PhysarumSimulation](), [PhysarumArt](), [PhysarumAnimate](), [PhysarumSimulation3D]() and [PhysarumArt3D]().

## Details & Options

- `Keys[$PhysarumPresets]` lists the available preset names, and `$PhysarumPresets["name"]` returns the full specification [Association]() for that preset.
- Each preset contains `"Species"`, `"Steps"` and optional `"AgentDensity"`, `"ColorFunction"`, `"Background"` and `"Glow"` entries:

| Preset | Species | Sensor Distance | Agent Density | Steps | Character |
| --- | --- | --- | --- | --- | --- |
| `"Classic"` | `1` | `6` | `0.3` | `600` | fine network of glowing veins in sunset colors |
| `"Filaments"` | `1` | `15` | `1` | `600` | long fibrous strands in deep blue and white |
| `"Nebula"` | `1` | `30` | `0.3` | `600` | broad sweeping arcs on a large scale |
| `"Leopard"` | `1` | `9` | `0.5` | `500` | spots and rings (`90°` sensor angle, `11.25°` rotation angle) |
| `"Mesh"` | `1` | `9` | `0.5` | `500` | tight web of sharp `90°` turns |
| `"Marble"` | `3` | `12` | `1` | `600` | three mutually repelling species in cyan, magenta and gold |
| `"Rivals"` | `2` | `12` | `1` | `600` | two competing species in cyan and magenta |
| `"Ink"` | `1` | `12` | `0.5` | `600` | dark blue strands on a warm paper background |

- Explicit options passed to [PhysarumSimulation](), [PhysarumArt]() or [PhysarumImage]() override the preset's values.

## Basic Examples

List the available preset names:

```wl
Keys[$PhysarumPresets]
```

---

Inspect the `"Classic"` preset specification:

```wl
Dataset[$PhysarumPresets["Classic"]]
```

## Scope

Render all built-in presets side by side:

```wl
AssociationMap[PhysarumArt[#, "Size" -> 180] &, Keys[$PhysarumPresets]]
```

---

Modify an existing preset by overriding one of its species parameters:

```wl
spec = $PhysarumPresets["Classic"];
spec["Species", 1, "SensorDistance"] = 20;
PhysarumArt[spec, "Size" -> 220]
```
