nb1 = Get["Physarum/Documentation/English/ReferencePages/Symbols/PhysarumAnimate.nb"];
nb2 = Get["Physarum/Documentation/English/ReferencePages/Symbols/PhysarumArt.nb"];

Print["--- PhysarumAnimate Head and Options ---"];
Print["StyleDefinitions: ", Lookup[Options[nb1], StyleDefinitions]];
Print["TaggingRules: ", Lookup[Options[nb1], TaggingRules]];

Print["\n--- PhysarumArt Head and Options ---"];
Print["StyleDefinitions: ", Lookup[Options[nb2], StyleDefinitions]];
Print["TaggingRules: ", Lookup[Options[nb2], TaggingRules]];

Print["\n--- PacletInfo Symbols and Documentation ---"];
pInfo = Get["Physarum/PacletInfo.wl"];
Print[pInfo];

Print["\n--- DocumentationSearch / PacletDocumentation check ---"];
Needs["PacletTools`"];
Print["PacletFind: ", PacletFind["ArnoudBuzing/Physarum"]];
