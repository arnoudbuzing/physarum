Print["--- File in Physarum/Documentation ---"];
nb1 = Get["Physarum/Documentation/English/ReferencePages/Symbols/PhysarumAnimate.nb"];
Print["StyleDefinitions: ", Lookup[Options[nb1], StyleDefinitions]];
Print["ShowAutoSpellCheck: ", Lookup[Options[nb1], ShowAutoSpellCheck, "NotPresent"]];

Print["--- File in build/paclet ---"];
nb2 = Get["build/paclet/ArnoudBuzing__Physarum/Documentation/English/ReferencePages/Symbols/PhysarumAnimate.nb"];
Print["StyleDefinitions: ", Lookup[Options[nb2], StyleDefinitions]];
Print["ShowAutoSpellCheck: ", Lookup[Options[nb2], ShowAutoSpellCheck, "NotPresent"]];
