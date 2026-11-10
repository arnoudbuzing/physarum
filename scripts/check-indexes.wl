Needs["DocumentationSearch`"];
idxDir = "Physarum/Documentation/English/Index";
searchIdxDir = "Physarum/Documentation/English/SearchIndex";

Print["Index exists: ", DirectoryQ[idxDir]];
Print["SearchIndex exists: ", DirectoryQ[searchIdxDir]];

Print["Search for PhysarumAnimate: "];
Print[DocumentationSearch`PacletLookupDocumentation["ArnoudBuzing/Physarum", "PhysarumAnimate"]];

Print["Search for PhysarumArt: "];
Print[DocumentationSearch`PacletLookupDocumentation["ArnoudBuzing/Physarum", "PhysarumArt"]];

Print["DocumentationSearch`PacletSearch: "];
Print[DocumentationSearch`PacletSearch["PhysarumAnimate", "ArnoudBuzing/Physarum"]];
Print[DocumentationSearch`PacletSearch["PhysarumArt", "ArnoudBuzing/Physarum"]];
