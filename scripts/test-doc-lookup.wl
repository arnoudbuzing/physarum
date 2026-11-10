Needs["PacletTools`"];

Print["--- DocumentationLink / PacletManager lookup ---"];
Print["FindFile for PhysarumAnimate: ", FindFile["ArnoudBuzing/Physarum/ref/PhysarumAnimate"]];
Print["FindFile for PhysarumArt: ", FindFile["ArnoudBuzing/Physarum/ref/PhysarumArt"]];

Print["\nPacletFind: ", PacletFind["ArnoudBuzing/Physarum"]];

Print["\nPacletManager PacletResource: "];
Needs["PacletManager`"];
Print["Resource PhysarumAnimate: ", PacletManager`PacletResource["ArnoudBuzing/Physarum", "ReferencePages/Symbols/PhysarumAnimate.nb"]];
Print["Resource PhysarumArt: ", PacletManager`PacletResource["ArnoudBuzing/Physarum", "ReferencePages/Symbols/PhysarumArt.nb"]];

Print["\nDocumentationSearch: "];
Needs["DocumentationSearch`"];
Print["Search for PhysarumAnimate: ", DocumentationSearch`PacletLookupDocumentation["ArnoudBuzing/Physarum", "PhysarumAnimate"]];
Print["Search for PhysarumArt: ", DocumentationSearch`PacletLookupDocumentation["ArnoudBuzing/Physarum", "PhysarumArt"]];
