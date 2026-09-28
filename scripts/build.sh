#!/bin/sh
# Build the Rust LibraryLink kernel and install it into the paclet.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cargo build --release --manifest-path "$ROOT/physarum-rs/Cargo.toml"

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)  SYSID=MacOSX-ARM64;  LIB=libphysarum.dylib ;;
  Darwin-x86_64) SYSID=MacOSX-x86-64; LIB=libphysarum.dylib ;;
  Linux-x86_64)  SYSID=Linux-x86-64;  LIB=libphysarum.so ;;
  Linux-aarch64) SYSID=Linux-ARM64;   LIB=libphysarum.so ;;
  *) echo "unsupported platform"; exit 1 ;;
esac

DEST="$ROOT/Physarum/LibraryResources/$SYSID"
mkdir -p "$DEST"
# Remove first: overwriting a loaded/signed dylib in place gets processes SIGKILLed on macOS.
rm -f "$DEST/$LIB"
cp "$ROOT/physarum-rs/target/release/$LIB" "$DEST/$LIB"
echo "Installed $DEST/$LIB"
