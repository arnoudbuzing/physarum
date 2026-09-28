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
  With[{walls = w["Walls"], w0 = PhysarumSimulation["Classic", "Size" -> 64, "Agents" -> 2000,
      "Walls" -> Graphics[Disk[{0, 0}, 0.5], PlotRange -> {{-1, 1}, {-1, 1}}]]},
    Total[Extract[walls, {Floor[#[[2]]] + 1, Floor[#[[1]]] + 1} & /@ Join[w["Agents"], w0["Agents"]]]]],
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
  mz = PhysarumMaze[6, RandomSeeding -> 1];
  {ImageQ[mz], ImageDimensions[mz]},
  {True, {31, 31}},
  TestID -> "Maze"
];

VerificationTest[
  (* in a loop-free maze exactly one route survives: the solution path *)
  hist = PhysarumFlow[mz, {{0.05, 0.95}, {0.95, 0.05}}, "Output" -> "History"];
  cond = Last[hist];
  {Length[hist], Count[cond, x_ /; x > 0.5 Max[cond]] > 0, Count[cond, x_ /; x > 0.01 Max[cond]] < Length[cond]/2},
  {201, True, True},
  TestID -> "FlowMaze"
];

VerificationTest[
  (* two food sources on a path graph with a detour: the short route wins *)
  gd = Graph[{1 <-> 2, 2 <-> 3, 1 <-> 4, 4 <-> 5, 5 <-> 6, 6 <-> 3}];
  c = PhysarumFlow[gd, {1, 3}, "Output" -> "Conductivity"];
  {c[UndirectedEdge[1, 2]] > 0.9 Max[c], c[UndirectedEdge[4, 5]] < 0.01 Max[c]},
  {True, True},
  TestID -> "FlowShortestPath"
];

VerificationTest[
  SeedRandom[2];
  gf = PhysarumFlow[RandomReal[1, {6, 2}], "Resolution" -> 25, "Steps" -> 200, RandomSeeding -> 1];
  {GraphQ[gf], ConnectedGraphQ[gf], NumericQ[PropertyValue[{gf, First[EdgeList[gf]]}, "Conductivity"]]},
  {True, True, True},
  TestID -> "FlowPoints"
];

VerificationTest[
  PhysarumFlow[PathGraph[Range[4]], {1}],
  $Failed,
  {PhysarumFlow::food},
  TestID -> "FlowBadFood"
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
