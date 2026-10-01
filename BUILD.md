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
physarum-rs/         Rust source of the simulation kernel
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
PacletDirectoryLoad["/path/to/fun/Physarum"];
Needs["ArnoudBuzing`Physarum`"]
```

## Tests

```sh
wolframscript -code 'TestReport["Tests/Physarum.wlt"]'
```

## Performance

A 512×512 grid with 131k agents runs about 300 steps per second on an Apple M-series machine.
Evaluations can be aborted as usual (the Rust loop checks for aborts every step).
