(* Example: using the 3D Physarum simulation.
     wolfram -script scripts/example-3d.wl [outdir]
   Rendering Graphics3D to PNG needs the front end. *)

Needs["ArnoudBuzing`Physarum`"];   (* the installed paclet *)
outDir = If[Length[$CommandLine] > 3, Last[$CommandLine], FileNameJoin[{Directory[], "build", "example-3d"}]];
Quiet[CreateDirectory[outDir, CreateIntermediateDirectories -> True]];
save[name_, expr_] := Print[name, ": ", Export[FileNameJoin[{outDir, name <> ".png"}], expr, ImageSize -> 400]];

(* 1. Basic: create, evolve, look *)
SeedRandom[1];
sim = PhysarumSimulation3D["Classic", "Size" -> 64];       (* 64^3 voxels, ~79k agents *)
Print[sim["AgentCount"], " agents"];
sim = PhysarumEvolve[sim, 300];
save["1-surface", PhysarumGraphics3D[sim]];                 (* isosurface of the trail *)
save["1-points", PhysarumGraphics3D[sim, Method -> "Points"]];  (* the agents themselves *)
save["1-projection", Image[sim["Projection"]]];             (* flat max-projection *)

(* 2. Foraging: food points in the unit cube, a ball-shaped wall in the middle *)
SeedRandom[5];
food = RandomReal[{0.15, 0.85}, {8, 3}];
sim2 = PhysarumSimulation3D["Classic", "Size" -> 64,
  "Food" -> food, "FoodStrength" -> 50,
  "Walls" -> Ball[{0.5, 0.5, 0.5}, 0.2]];
sim2 = PhysarumEvolve[sim2, 400];
save["2-foraging", PhysarumGraphics3D[sim2]];

(* 3. Two competing species, one call *)
SeedRandom[3];
save["3-rivals", PhysarumArt3D["Rivals", "Size" -> 64, "Output" -> "Graphics3D"]];
