(* Build the installable .paclet archive into build/.
   Run after ./scripts/build.sh so that the LibraryLink binary is up to date.
     wolfram -script scripts/paclet-build.wl *)

root = DirectoryName[$InputFileName, 2];
src = FileNameJoin[{root, "Physarum"}];
out = FileNameJoin[{root, "build"}];
Quiet[CreateDirectory[out]];

lib = FileNameJoin[{src, "LibraryResources", $SystemID, "libphysarum.dylib"}];
If[!FileExistsQ[lib], Print["Missing ", lib, " -- run ./scripts/build.sh first"]; Exit[1]];

(* If PacletBuild output exists, prefer the built paclet archive *)
builtPaclet = FileNameJoin[{out, "paclet", "ArnoudBuzing__Physarum-0.1.0.paclet"}];
archive = If[FileExistsQ[builtPaclet],
  target = FileNameJoin[{out, "ArnoudBuzing__Physarum-0.1.0.paclet"}];
  CopyFile[builtPaclet, target, OverwriteTarget -> True];
  target,
  CreatePacletArchive[src, out]
];
Print["Created: ", archive];
Print[PacletObject[File[archive]]];
