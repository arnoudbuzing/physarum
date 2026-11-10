repoDir = "/Users/arnoudb/Library/Wolfram/Paclets/Repository/ArnoudBuzing__Physarum-0.1.0";
f1 = FileNameJoin[{repoDir, "Documentation", "English", "ReferencePages", "Symbols", "PhysarumAnimate.nb"}];
f2 = FileNameJoin[{repoDir, "Documentation", "English", "ReferencePages", "Symbols", "PhysarumArt.nb"}];

nb1 = Get[f1];
nb2 = Get[f2];

Print["=== nb1 (PhysarumAnimate) ==="];
Print["Options: ", Options[nb1]];
Print["Cell 1: ", First[nb1]];

Print["\n=== nb2 (PhysarumArt) ==="];
Print["Options: ", Options[nb2]];
Print["Cell 1: ", First[nb2]];
