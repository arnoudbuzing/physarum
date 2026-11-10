Print["=== Checking Physarum/Documentation (Authoring) ==="];
nb1 = Get["Physarum/Documentation/English/ReferencePages/Symbols/PhysarumAnimate.nb"];
Print["ShowAutoSpellCheck in authoring: ", Lookup[Options[nb1], ShowAutoSpellCheck, "NotPresent"]];
usageCells1 = Cases[nb1, Cell[_, "Usage", ___], Infinity];
Print["Usage cell content: "];
Print[First[usageCells1]];

Print["\n=== Checking build/paclet (Built) ==="];
builtNbPath = "build/paclet/ArnoudBuzing__Physarum/Documentation/English/ReferencePages/Symbols/PhysarumAnimate.nb";
If[FileExistsQ[builtNbPath],
  nb2 = Get[builtNbPath];
  Print["ShowAutoSpellCheck in built: ", Lookup[Options[nb2], ShowAutoSpellCheck, "NotPresent"]];
  usageCells2 = Cases[nb2, Cell[_, "Usage", ___], Infinity];
  Print["Usage cell in built notebook: "];
  Print[First[usageCells2]];
,
  Print["Built file not found!"];
];

Print["\n=== Checking ALL authoring notebooks for ShowAutoSpellCheck ==="];
authoringFiles = FileNames["*.nb", "Physarum/Documentation/English", Infinity];
missingAuthoring = Select[authoringFiles, !MemberQ[Options[Get[#]], ShowAutoSpellCheck -> False] &];
Print["Missing in authoring: ", Length[missingAuthoring]];

Print["\n=== Checking ALL built notebooks for ShowAutoSpellCheck ==="];
builtFiles = FileNames["*.nb", "build/paclet/ArnoudBuzing__Physarum/Documentation/English", Infinity];
missingBuilt = Select[builtFiles, !MemberQ[Options[Get[#]], ShowAutoSpellCheck -> False] &];
Print["Missing in built: ", Length[missingBuilt]];
