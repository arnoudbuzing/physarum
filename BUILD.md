# Building the Physarum paclet

Technical notes for building, testing and hacking on the `ArnoudBuzing/Physarum` paclet.
For what the paclet does and how to use it, see [README.md](README.md).

## Architecture

The hot inner loop of the agent model (sense → rotate → move → deposit → diffuse) runs in a
small Rust library, called through LibraryLink and parallelized with rayon. Everything else
is Wolfram Language: setup, presets, rendering, animation and network extraction.

The flow model (`PhysarumFlow`, `PhysarumMaze`) is pure Wolfram Language. Each step is a
sparse Kirchhoff solve followed by the conductivity update.

## Layout

```
Physarum/            the paclet
  PacletInfo.wl
  Kernel/Physarum.wl
  LibraryResources/<SystemID>/libphysarum.dylib   (built, not checked in)
physarum-rs/         Rust source of the simulation kernel (src/lib.rs: 2D, src/evolve3d.rs: 3D)
scripts/build.sh     builds the Rust library and installs it into the paclet
Tests/Physarum.wlt   test suite
images/              the pictures in the README
```

## Requirements

* A Rust toolchain (`cargo`)
* Wolfram Language 14.1+

## Build

```sh
./scripts/build.sh
```

This compiles `physarum-rs` in release mode and copies the library into
`Physarum/LibraryResources/<SystemID>/`. Supported platforms are macOS (ARM64, x86-64) and
Linux (x86-64, ARM64). The compiled library is not checked in.

## Load

```wolfram
PacletDirectoryLoad["/path/to/physarum/Physarum"];
Needs["ArnoudBuzing`Physarum`"]
```

## Documentation build

Documentation is authored in structured markdown under `docs/` and built into
standard Wolfram Language notebook documentation using `MarkdownToNotebook` and `PacletBuild`:

```sh
/Applications/Wolfram/15.0/Wolfram.app/Contents/MacOS/wolfram -script scripts/build-docs.wl
```

This converts each `docs/*.md` into authoring notebooks (`Documentation/English/ReferencePages/Symbols/`
and `Documentation/English/Guides/Physarum.nb`) and builds the documentation search and spell indexes
(`Index`, `SearchIndex`, `SpellIndex`).

## Paclet archive and install

```sh
/Applications/Wolfram/15.0/Wolfram.app/Contents/MacOS/wolfram -script scripts/paclet-build.wl
/Applications/Wolfram/15.0/Wolfram.app/Contents/MacOS/wolfram -script scripts/paclet-install.wl
```

The first creates `build/ArnoudBuzing__Physarum-<version>.paclet` (run `./scripts/build.sh`
first so the library is current). The second installs that archive with `PacletInstall`,
loads it and runs a quick smoke test. After installing, `Needs["ArnoudBuzing`Physarum`"]`
works without `PacletDirectoryLoad`.

## Tests

```sh
/Applications/Wolfram/15.0/Wolfram.app/Contents/MacOS/wolfram -script scripts/report.wl
```

This runs every `.wlt` file under `Tests/` and prints one line per test. To run a single
file, pass it as an argument:

```sh
/Applications/Wolfram/15.0/Wolfram.app/Contents/MacOS/wolfram -script scripts/report.wl Tests/Physarum.wlt
```

## Performance

A 512×512 grid with 131k agents runs about 300 steps per second on an Apple M-series machine.
In 3D, a 96³ grid with 265k agents runs about 75 steps per second.
Evaluations can be aborted as usual (the Rust loop checks for aborts every step).
