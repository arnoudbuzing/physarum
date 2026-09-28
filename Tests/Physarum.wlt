(* Run with:  wolframscript -code 'TestReport["Tests/Physarum.wlt"]'  (after ./scripts/build.sh) *)

BeginTestSection["Physarum"];

VerificationTest[
  PacletDirectoryLoad[FileNameJoin[{DirectoryName[$TestFileName, 2], "Physarum"}]];
  Needs["ArnoudBuzing`Physarum`"];
  MemberQ[$Packages, "ArnoudBuzing`Physarum`"],
  True,
  TestID -> "Load"
];

VerificationTest[
  Keys[$PhysarumPresets],
  {"Classic", "Filaments", "Nebula", "Leopard", "Mesh", "Marble", "Rivals", "Ink"},
  TestID -> "Presets"
];

VerificationTest[
  sim = PhysarumSimulation["Classic", "Size" -> {80, 60}, "Agents" -> 1000];
  {Head[sim], sim["Size"], sim["AgentCount"], Dimensions[sim["Trail"]], sim["Step"]},
  {PhysarumSimulationObject, {80, 60}, 1000, {1, 60, 80}, 0},
  TestID -> "Create"
];

VerificationTest[
  sim2 = PhysarumEvolve[sim, 25];
  {sim2["Step"], Dimensions[sim2["Agents"]], Total[sim2["Trail"], 3] > 0},
  {25, {1000, 4}, True},
  TestID -> "Evolve"
];

VerificationTest[
  (* agents stay on the torus *)
  With[{a = sim2["Agents"]}, {Min[a[[All, 1]]] >= 0, Max[a[[All, 1]]] < 80, Min[a[[All, 2]]] >= 0, Max[a[[All, 2]]] < 60}],
  {True, True, True, True},
  TestID -> "AgentBounds"
];

VerificationTest[
  (* same seed, same result *)
  SeedRandom[1]; a = PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 50, "Agents" -> 300], 10]["Trail"];
  SeedRandom[1]; b = PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 50, "Agents" -> 300], 10]["Trail"];
  a == b,
  True,
  TestID -> "Reproducible"
];

VerificationTest[
  PhysarumEvolve[PhysarumEvolve[sim, 10], 15]["Step"],
  25,
  TestID -> "EvolveComposes"
];

VerificationTest[
  img = PhysarumImage[sim2];
  {ImageQ[img], ImageDimensions[img]},
  {True, {80, 60}},
  TestID -> "Image"
];

VerificationTest[
  ImageQ /@ {
    PhysarumImage[sim2, ColorFunction -> "SunsetColors"],
    PhysarumImage[sim2, ColorFunction -> None, "Colors" -> {Cyan}],
    PhysarumImage[sim2, Background -> White, "Colors" -> {Blue}, "Glow" -> 0]},
  {True, True, True},
  TestID -> "ImageOptions"
];

VerificationTest[
  m = PhysarumSimulation["Marble", "Size" -> 64, "Agents" -> 900];
  {Dimensions[m["Trail"]], Sort[DeleteDuplicates[m["Agents"][[All, 4]]]], ImageQ[PhysarumImage[PhysarumEvolve[m, 5]]]},
  {{3, 64, 64}, {0., 1., 2.}, True},
  TestID -> "MultiSpecies"
];

VerificationTest[
  (* walls: no agent ends up inside a wall *)
  w = PhysarumEvolve[PhysarumSimulation["Classic", "Size" -> 64, "Agents" -> 2000,
    "Walls" -> Graphics[Disk[{0, 0}, 0.5], PlotRange -> {{-1, 1}, {-1, 1}}]], 30];
  With[{walls = w["Walls"]},
    Total[Extract[walls, {Floor[#[[2]]] + 1, Floor[#[[1]]] + 1} & /@ w["Agents"]]]],
  0.,
  TestID -> "Walls"
];

VerificationTest[
  f = PhysarumSimulation["Classic", "Size" -> 64, "Food" -> {{0.25, 0.25}, {0.75, 0.75}}, "Initialization" -> "Food"];
  {Max[f["Stimulus"]] > 0, f["Wrap"]},
  {True, False},
  TestID -> "Food"
];

VerificationTest[
  Length[PhysarumAnimate[PhysarumSimulation["Classic", "Size" -> 48], 3, 5]],
  3,
  TestID -> "Animate"
];

VerificationTest[
  ImageQ[PhysarumArt["Leopard", "Size" -> 64, "Steps" -> 20]],
  True,
  TestID -> "Art"
];

VerificationTest[
  SeedRandom[7];
  g = PhysarumNetwork[RandomReal[1, {6, 2}], "Size" -> 150, "Steps" -> 800];
  {GraphQ[g], Count[VertexList[g], _String] > 0, AllTrue[PropertyValue[g, EdgeWeight], Positive]},
  {True, True, True},
  TestID -> "Network"
];

VerificationTest[
  (* entities resolve via "Position" and become the food vertices (needs Knowledgebase access) *)
  cities = Entity["City", #] & /@ {{"Amsterdam", "NoordHolland", "Netherlands"},
    {"Rotterdam", "ZuidHolland", "Netherlands"}, {"Utrecht", "Utrecht", "Netherlands"}};
  SeedRandom[3];
  g = PhysarumNetwork[cities, "Size" -> 150, "Steps" -> 800];
  {GraphQ[g], SubsetQ[VertexList[g], cities]},
  {True, True},
  TestID -> "NetworkEntities"
];

VerificationTest[
  PhysarumNetwork[{Entity["City", {"Amsterdam", "NoordHolland", "Netherlands"}], Entity["City", {"Nowhere", "Nope", "Netherlands"}]}],
  $Failed,
  {PhysarumNetwork::geo},
  TestID -> "BadEntity"
];

VerificationTest[
  PhysarumSimulation["NoSuchPreset"],
  $Failed,
  {PhysarumSimulation::spec},
  TestID -> "BadPreset"
];

VerificationTest[
  PhysarumNetwork[{{0, 0}}],
  $Failed,
  {PhysarumNetwork::pts},
  TestID -> "BadNetworkInput"
];

EndTestSection[];
