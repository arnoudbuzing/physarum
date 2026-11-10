guideAuthoring = Get["Physarum/Documentation/English/Guides/Physarum.nb"];
guideBuilt = Get["build/paclet/ArnoudBuzing__Physarum/Documentation/English/Guides/Physarum.nb"];

Print["=== Links in authoring guide Physarum.nb ==="];
Print[Cases[guideAuthoring, (ButtonBox | TemplateBox)[__, (ButtonData | TagBox) -> _], Infinity]];

Print["\n=== Links mentioning PhysarumArt in authoring guide ==="];
Print[Cases[guideAuthoring, b_ /; !FreeQ[b, "PhysarumArt"], Infinity]];

Print["\n=== Links mentioning PhysarumArt in built guide ==="];
Print[Cases[guideBuilt, b_ /; !FreeQ[b, "PhysarumArt"], Infinity]];

animAuthoring = Get["Physarum/Documentation/English/ReferencePages/Symbols/PhysarumAnimate.nb"];
animBuilt = Get["build/paclet/ArnoudBuzing__Physarum/Documentation/English/ReferencePages/Symbols/PhysarumAnimate.nb"];

Print["\n=== SeeAlso in authoring PhysarumAnimate ==="];
Print[Cases[animAuthoring, Cell[_, "SeeAlso", ___], Infinity]];

Print["\n=== SeeAlso in built PhysarumAnimate ==="];
Print[Cases[animBuilt, Cell[_, "SeeAlso", ___], Infinity]];
