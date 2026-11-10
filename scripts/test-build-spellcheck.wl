Needs["PacletTools`"];
Needs["DocumentationBuild`"];
DocumentationBuild`Internal`InternalAssetsDirectory[] = None;

rootDir = DirectoryName[$InputFileName, 2];
pacletDir = FileNameJoin[{rootDir, "Physarum"}];
buildDir = FileNameJoin[{rootDir, "build", "test-paclet"}];

Quiet @ DeleteDirectory[buildDir, DeleteContents -> True];

(* Add ShowAutoSpellCheck -> False to one authoring notebook *)
targetNb = FileNameJoin[{pacletDir, "Documentation", "English", "ReferencePages", "Symbols", "PhysarumAnimate.nb"}];
nb = Get[targetNb];
nb = Append[DeleteCases[nb, (ShowAutoSpellCheck -> _)], ShowAutoSpellCheck -> False];
Export[targetNb, nb];

Print["Authoring nb ShowAutoSpellCheck: ", Lookup[Options[Get[targetNb]], ShowAutoSpellCheck, "NotPresent"]];

(* Run PacletBuild *)
UsingFrontEnd @ PacletBuild[pacletDir, buildDir];

builtNbPath = FileNameJoin[{buildDir, "ArnoudBuzing__Physarum", "Documentation", "English", "ReferencePages", "Symbols", "PhysarumAnimate.nb"}];
If[FileExistsQ[builtNbPath],
  builtNb = Get[builtNbPath];
  Print["Built nb ShowAutoSpellCheck: ", Lookup[Options[builtNb], ShowAutoSpellCheck, "NotPresent"]];
,
  Print["Built nb not found!"];
];
