repoDir = "/Users/arnoudb/Library/Wolfram/Paclets/Repository/ArnoudBuzing__Physarum-0.1.0";
fAnimate = FileNameJoin[{repoDir, "Documentation", "English", "ReferencePages", "Symbols", "PhysarumAnimate.nb"}];
fArt = FileNameJoin[{repoDir, "Documentation", "English", "ReferencePages", "Symbols", "PhysarumArt.nb"}];
fGuide = FileNameJoin[{repoDir, "Documentation", "English", "Guides", "Physarum.nb"}];

Print["Installed PhysarumAnimate StyleDefinitions: ", Lookup[Options[Get[fAnimate]], StyleDefinitions]];
Print["Installed PhysarumArt StyleDefinitions: ", Lookup[Options[Get[fArt]], StyleDefinitions]];
Print["Installed Guide StyleDefinitions: ", Lookup[Options[Get[fGuide]], StyleDefinitions]];
