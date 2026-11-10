(* Install the built .paclet archive from build/ and verify that it loads.
     wolfram -script scripts/paclet-install.wl *)

root = DirectoryName[$InputFileName, 2];
archive = Last[SortBy[FileNames["*.paclet", FileNameJoin[{root, "build"}]], FileDate], $Failed];
If[archive === $Failed, Print["No .paclet in build/ -- run scripts/paclet-build.wl first"]; Exit[1]];

p = PacletInstall[archive, ForceVersionInstall -> True];
Print["Installed: ", p];
Print["Location: ", p["Location"]];

Needs["ArnoudBuzing`Physarum`"];
Print["Loaded from: ", PacletFind["ArnoudBuzing/Physarum"][[1]]["Location"]];
sim = PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 64, "Agents" -> 500], 10];
Print["Smoke test: ", Head[sim], " with ", sim["AgentCount"], " agents"];
