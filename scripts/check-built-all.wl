builtDir = "build/paclet/ArnoudBuzing__Physarum/Documentation/English/ReferencePages/Symbols";
files = Sort @ FileNames["*.nb", builtDir];

Print["Checking ", Length[files], " built symbol notebooks:"];
Do[
  nb = Get[f];
  Print["  ", FileNameTake[f], ": ", Lookup[Options[nb], StyleDefinitions]];
  ,
  {f, files}
];

guideNb = "build/paclet/ArnoudBuzing__Physarum/Documentation/English/Guides/Physarum.nb";
Print["Guide notebook: ", Lookup[Options[Get[guideNb]], StyleDefinitions]];
