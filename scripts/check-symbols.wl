(* Check that PacletInfo "Symbols" matches the public symbols of the package. *)
PacletDirectoryLoad[FileNameJoin[{Directory[], "Physarum"}]];
Needs["ArnoudBuzing`Physarum`"];
declared = Sort @ Lookup[Rest /@ Cases[PacletObject["ArnoudBuzing/Physarum"]["Extensions"], {"Kernel", __}], "Symbols"][[1]];
actual = Sort["ArnoudBuzing`Physarum`" <> # & /@ Names["ArnoudBuzing`Physarum`*"]];
Print["declared == actual: ", declared === actual];
Print["missing from PacletInfo: ", Complement[actual, declared]];
Print["extra in PacletInfo: ", Complement[declared, actual]];
