nb = Get["/Users/arnoudb/Library/Wolfram/Paclets/Repository/ArnoudBuzing__Physarum-0.1.0/Documentation/English/ReferencePages/Symbols/PhysarumAnimate.nb"];
Print["Installed paclet ShowAutoSpellCheck: ", Lookup[Options[nb], ShowAutoSpellCheck, "NotPresent"]];
usage = First @ Cases[nb, Cell[_, "Usage", ___], Infinity];
Print["Installed paclet Usage cell: "];
Print[usage];
