builtDoc = "build/paclet/ArnoudBuzing__Physarum/Documentation/English";
docDir = "Physarum/Documentation/English";

(* Copy all built ReferencePages *)
builtRefPages = FileNames["*.nb", FileNameJoin[{builtDoc, "ReferencePages", "Symbols"}]];
Do[
  CopyFile[f, FileNameJoin[{docDir, "ReferencePages", "Symbols", FileNameTake[f]}], OverwriteTarget -> True],
  {f, builtRefPages}
];
Print["Copied ", Length[builtRefPages], " built symbol pages to Physarum/Documentation."];

(* Copy built Guide *)
CopyFile[
  FileNameJoin[{builtDoc, "Guides", "Physarum.nb"}],
  FileNameJoin[{docDir, "Guides", "Physarum.nb"}],
  OverwriteTarget -> True
];
Print["Copied built Guide to Physarum/Documentation."];

(* Check StyleDefinitions in Physarum/Documentation *)
Print["PhysarumAnimate StyleDefinitions: ", Lookup[Options[Get[FileNameJoin[{docDir, "ReferencePages", "Symbols", "PhysarumAnimate.nb"}]]], StyleDefinitions]];
Print["PhysarumArt StyleDefinitions: ", Lookup[Options[Get[FileNameJoin[{docDir, "ReferencePages", "Symbols", "PhysarumArt.nb"}]]], StyleDefinitions]];
Print["Physarum.nb StyleDefinitions: ", Lookup[Options[Get[FileNameJoin[{docDir, "Guides", "Physarum.nb"}]]], StyleDefinitions]];
