(* ::Package:: *)

(* ArnoudBuzing/Physarum
   Slime-mould agent simulations (after J. Jones, "Characteristics of pattern formation and
   evolution in approximations of Physarum transport networks", Artificial Life 16, 2010).

   The inner loop (sense / rotate / move / deposit / diffuse) runs in a small Rust library
   loaded through LibraryLink; everything else is Wolfram Language. *)

BeginPackage["ArnoudBuzing`Physarum`"];

PhysarumSimulation::usage =
  "PhysarumSimulation[] creates a new slime-mould simulation using the \"Classic\" preset.\n" <>
  "PhysarumSimulation[\"preset\"] uses a named preset from $PhysarumPresets.\n" <>
  "PhysarumSimulation[species] uses an Association (or a list of Associations) of species parameters.";

PhysarumSimulationObject::usage =
  "PhysarumSimulationObject[...] represents the state of a Physarum simulation.";

PhysarumEvolve::usage =
  "PhysarumEvolve[sim, n] advances the simulation sim (a PhysarumSimulationObject or PhysarumSimulation3DObject) by n steps and returns the new simulation object.";

PhysarumSimulation3D::usage =
  "PhysarumSimulation3D[] creates a new 3D slime-mould simulation using the \"Classic\" preset.\n" <>
  "PhysarumSimulation3D[\"preset\"] uses a named preset from $PhysarumPresets.\n" <>
  "PhysarumSimulation3D[species] uses an Association (or a list of Associations) of species parameters.";

PhysarumSimulation3DObject::usage =
  "PhysarumSimulation3DObject[...] represents the state of a 3D Physarum simulation.";

PhysarumImage3D::usage =
  "PhysarumImage3D[sim] renders the trail map of a PhysarumSimulation3DObject as a volume Image3D.";

PhysarumGraphics3D::usage =
  "PhysarumGraphics3D[sim] renders a PhysarumSimulation3DObject as Graphics3D, with the network as a surface or the agents as points.";

PhysarumArt3D::usage =
  "PhysarumArt3D[] grows and renders a 3D slime mould with the \"Classic\" preset.\n" <>
  "PhysarumArt3D[\"preset\"] grows and renders a named preset in 3D.\n" <>
  "PhysarumArt3D[spec, opts] accepts any PhysarumSimulation3D specification and options.";

PhysarumImage::usage =
  "PhysarumImage[sim] renders the trail map of a PhysarumSimulationObject as an Image.";

PhysarumAnimate::usage =
  "PhysarumAnimate[sim, frames, steps] evolves sim for frames frames of steps steps each and returns the rendered frames.";

PhysarumArt::usage =
  "PhysarumArt[] grows and renders a slime-mould image with the \"Classic\" preset.\n" <>
  "PhysarumArt[\"preset\"] grows and renders a named preset.\n" <>
  "PhysarumArt[spec, opts] accepts any PhysarumSimulation specification and options.";

PhysarumNetwork::usage =
  "PhysarumNetwork[{p1, p2, ...}] lets a slime mould grow between the food sources pi and returns the resulting transport network as a Graph.\n" <>
  "PhysarumNetwork[{GeoPosition[...], ...}] works with geographic locations.";

PhysarumFlow::usage =
  "PhysarumFlow[maze, {p1, p2, ...}] runs the Tero flow model (tubes carrying more protoplasm thicken, idle tubes wither) through the free cells of a maze image, with food at the points pi of the unit square.\n" <>
  "PhysarumFlow[{p1, p2, ...}] grows a flow network between food sources on a lattice.\n" <>
  "PhysarumFlow[g, {v1, v2, ...}] runs the flow model on the Graph g with food at vertices vi.";

PhysarumMaze::usage =
  "PhysarumMaze[n] generates an n\[Times]n maze as an Image with white walls.";

$PhysarumPresets::usage =
  "$PhysarumPresets is an Association of named simulation presets.";

PhysarumFlow::food = "Need at least two food sources that lie on the graph or in the free part of the maze.";

PhysarumSimulation::nolib = "The Physarum simulation library could not be loaded from `1`.";
PhysarumSimulation::spec = "`1` is not a valid preset name or species specification.";
PhysarumSimulation::mask = "Cannot interpret `1` as a mask.";
PhysarumEvolve::abort = "The simulation was aborted.";
PhysarumNetwork::pts = "Expected a list of at least two distinct 2D points or GeoPosition values.";
PhysarumNetwork::geo = "Could not determine geographic positions for `1`.";

Begin["`Private`"];

(* ::Section:: *)
(* Library *)

$pacletRoot = DirectoryName[$InputFileName, 2];

libraryFile[] := SelectFirst[
  FileNameJoin[{$pacletRoot, "LibraryResources", $SystemID, #}] & /@
    {"libphysarum.dylib", "libphysarum.so", "physarum.dll"},
  FileExistsQ,
  $Failed
];

$na = {LibraryDataType[NumericArray, "Real64"], "Constant"};

(* Both kernels take (agents, trail, stim, wall, params, wrap, nsteps, seed). A failed load
   is not memoized, so a later call (e.g. after building the library) tries again. *)
libLoad[name_String] := libLoad[name] = Module[{file = libraryFile[], fun},
  fun = If[StringQ[file],
    Quiet @ LibraryFunctionLoad[file, name,
      {$na, $na, $na, $na, $na, Integer, Integer, Integer},
      LibraryDataType[NumericArray, "Real64"]],
    $Failed
  ];
  If[Head[fun] =!= LibraryFunction,
    Message[PhysarumSimulation::nolib, FileNameJoin[{$pacletRoot, "LibraryResources", $SystemID}]];
    Throw[$Failed, $tag]
  ];
  fun
];

libEvolve := libLoad["physarum_evolve"];
libEvolve3D := libLoad["physarum_evolve3d"];

toNA[x_] := NumericArray[Developer`ToPackedArray[N[x]], "Real64"];

(* ::Section:: *)
(* Species & presets *)

$speciesKeys = {"SensorAngle", "SensorDistance", "RotationAngle", "StepSize",
  "Deposit", "Decay", "Diffusion", "Jitter", "Repulsion"};

$defaultSpecies = <|
  "SensorAngle" -> 22.5 Degree, "SensorDistance" -> 9, "RotationAngle" -> 45 Degree,
  "StepSize" -> 1, "Deposit" -> 5, "Decay" -> 0.1, "Diffusion" -> 1, "Jitter" -> 0,
  "Repulsion" -> 0, "Fraction" -> 1, "Color" -> Automatic
|>;

$defaultColors = {RGBColor[0.2, 0.85, 1.], RGBColor[1., 0.3, 0.6], RGBColor[1., 0.85, 0.25],
  RGBColor[0.45, 1., 0.45], RGBColor[0.7, 0.45, 1.], RGBColor[1., 0.55, 0.2]};

$sunset = Blend[{Black, RGBColor[0.18, 0.02, 0.3], RGBColor[0.7, 0.05, 0.5],
  RGBColor[1., 0.45, 0.2], RGBColor[1., 0.93, 0.7]}, #] &;

$fine = <|"SensorAngle" -> 30 Degree, "RotationAngle" -> 30 Degree, "Deposit" -> 1, "Decay" -> 0.3, "Diffusion" -> 0.1|>;

$PhysarumPresets = <|
  "Classic" -> <|
    "Species" -> {<|$fine, "SensorDistance" -> 6|>}, "AgentDensity" -> 0.3,
    "ColorFunction" -> $sunset, "Steps" -> 600
  |>,
  "Filaments" -> <|
    "Species" -> {<|$fine, "SensorDistance" -> 15|>}, "AgentDensity" -> 1,
    "ColorFunction" -> (Blend[{Black, RGBColor[0.02, 0.1, 0.3], RGBColor[0.1, 0.55, 0.9], RGBColor[0.85, 0.97, 1.]}, #] &),
    "Steps" -> 600
  |>,
  "Nebula" -> <|
    "Species" -> {<|$fine, "SensorDistance" -> 30|>}, "AgentDensity" -> 0.3,
    "ColorFunction" -> (Blend[{Black, RGBColor[0.15, 0.02, 0.25], RGBColor[0.55, 0.1, 0.6], RGBColor[1., 0.55, 0.35], White}, #] &),
    "Steps" -> 600
  |>,
  "Leopard" -> <|
    "Species" -> {<|"SensorAngle" -> 90 Degree, "RotationAngle" -> 11.25 Degree, "SensorDistance" -> 9|>},
    "ColorFunction" -> (Blend[{RGBColor[0.1, 0.05, 0.02], RGBColor[0.6, 0.3, 0.05], RGBColor[1., 0.8, 0.4]}, #] &),
    "Glow" -> 0, "Steps" -> 500
  |>,
  "Mesh" -> <|
    "Species" -> {<|"SensorAngle" -> 22.5 Degree, "RotationAngle" -> 90 Degree, "SensorDistance" -> 9|>},
    "ColorFunction" -> $sunset, "Steps" -> 500
  |>,
  "Marble" -> <|
    "Species" -> Table[<|$fine, "SensorDistance" -> 12, "Repulsion" -> 3|>, 3], "AgentDensity" -> 1,
    "Steps" -> 600
  |>,
  "Rivals" -> <|
    "Species" -> Table[<|$fine, "SensorDistance" -> 12, "Repulsion" -> 1|>, 2], "AgentDensity" -> 1,
    "Steps" -> 600
  |>,
  "Ink" -> <|
    "Species" -> {<|$fine, "SensorDistance" -> 12, "Color" -> RGBColor[0.1, 0.2, 0.5]|>}, "AgentDensity" -> 0.5,
    "Background" -> RGBColor[0.97, 0.95, 0.9], "Glow" -> 0, "Steps" -> 600
  |>
|>;

normalizeSpecies[a_Association] := Join[$defaultSpecies, KeyTake[a, Keys[$defaultSpecies]]];

presetQ[s_String] := KeyExistsQ[$PhysarumPresets, s];
presetQ[_] := False;

(* Canonical form: a preset association with a "Species" list of complete species. *)
resolveSpec[s_String?presetQ] := resolveSpec[$PhysarumPresets[s]];
resolveSpec[a_Association /; KeyExistsQ[a, "Species"]] :=
  MapAt[normalizeSpecies /@ Flatten[{#}] &, a, Key["Species"]];
resolveSpec[a_Association] := resolveSpec[<|"Species" -> {a}|>];
resolveSpec[l : {__Association}] := resolveSpec[<|"Species" -> l|>];
resolveSpec[other_] := (Message[PhysarumSimulation::spec, other]; Throw[$Failed, $tag]);

speciesMatrix[species_List] := N[Lookup[#, $speciesKeys] & /@ species];

speciesColors[species_List] := MapIndexed[
  Replace[#1["Color"], Automatic :> $defaultColors[[Mod[First[#2] - 1, Length[$defaultColors]] + 1]]] &,
  species
];

(* ::Section:: *)
(* Masks: turn strings, graphics, images, matrices into {h, w} arrays in [0, 1] *)

gray[img_Image] := ImageData[ColorConvert[RemoveAlphaChannel[img, White], "Grayscale"], "Real"];

(* Crop to content, scale to fit a fraction of the grid, and center. Content is bright. *)
fitCenter[img_Image, {w_, h_}, frac_] := Module[{c, s, r, dw, dh},
  c = ImageCrop[img];
  s = Min[frac w / ImageDimensions[c][[1]], frac h / ImageDimensions[c][[2]]];
  r = ImageResize[c, Max[1, Round[s #]] & /@ ImageDimensions[c]];
  {dw, dh} = {w, h} - ImageDimensions[r];
  ImageResize[
    ImagePad[r, {{Floor[dw/2], Ceiling[dw/2]}, {Floor[dh/2], Ceiling[dh/2]}}, Black],
    {w, h}]
];

inkImage[expr_] := ColorNegate @ ColorConvert[
  RemoveAlphaChannel[Rasterize[expr, "Image", Background -> White], White], "Grayscale"];

toMask[None | Automatic, {w_, h_}] := ConstantArray[0., {h, w}];
toMask[m_?MatrixQ, {w_, h_}] := Clip[ImageData[ImageResize[Image[N[m]], {w, h}], "Real"], {0, 1}];
toMask[img_Image, {w_, h_}] := gray[ImageResize[img, {w, h}]];
toMask[s_String, {w_, h_}] :=
  gray @ fitCenter[
    inkImage[Style[s, Bold, FontFamily -> "Helvetica", FontSize -> Max[48, Round[h/2]]]],
    {w, h}, 0.88];
toMask[g_Graphics, {w_, h_}] := gray @ ImageResize[
  inkImage[Show[g, ImageSize -> {w, h}, AspectRatio -> h/w, PlotRangePadding -> None,
    ImagePadding -> None, Frame -> False, Axes -> False]],
  {w, h}];
toMask[r_?RegionQ, size_] := toMask[Graphics[{Black, r}], size];
toMask[p : (_Disk | _Circle | _Rectangle | _Polygon | _Line | _Annulus | _List), size_] :=
  toMask[Graphics[{Black, p}], size];
toMask[other_, _] := (Message[PhysarumSimulation::mask, Short[other]]; Throw[$Failed, $tag]);

(* Food given as points in the unit square (y up): soft disks. *)
pointsQ[p_] := MatrixQ[p, NumericQ] && Last[Dimensions[p]] == 2;

foodMask[pts_?pointsQ, {w_, h_}, radius_] := Module[{grid, centers},
  centers = {#[[1]] w, (1 - #[[2]]) h} & /@ N[pts];
  grid = Table[{c - 0.5, r - 0.5}, {r, h}, {c, w}];
  Clip[Total[
    With[{d2 = Total[(grid - ConstantArray[#, {h, w}])^2, {3}] / (2. radius^2)},
      UnitStep[9. - d2] Exp[-Clip[d2, {0., 9.}]]] & /@ centers], {0, 1}]
];
foodMask[other_, size_, _] := toMask[other, size];

(* ::Section:: *)
(* Agent initialisation: {x, y, heading} triples in grid units *)

initAgents["Random", n_, {w_, h_}, _] :=
  Transpose[{RandomReal[w, n], RandomReal[h, n], RandomReal[2 Pi, n]}];

initAgents["Disk", n_, {w_, h_}, _] := Module[{r = 0.38 Min[w, h] Sqrt[RandomReal[1, n]], t = RandomReal[2 Pi, n]},
  Transpose[{w/2 + r Cos[t], h/2 + r Sin[t], RandomReal[2 Pi, n]}]];

initAgents["Ring", n_, {w_, h_}, _] := Module[{r = 0.42 Min[w, h], t = RandomReal[2 Pi, n]},
  Transpose[{w/2 + r Cos[t], h/2 + r Sin[t], t + Pi}]];

initAgents["Burst", n_, {w_, h_}, _] := Module[{r = 0.03 Min[w, h] Sqrt[RandomReal[1, n]], t = RandomReal[2 Pi, n]},
  Transpose[{w/2 + r Cos[t], h/2 + r Sin[t], t}]];

initAgents["Food", n_, size_, food_] := initAgents[food, n, size, food];

initAgents[mask_?MatrixQ, n_, {w_, h_}, _] := Module[{weights = Flatten[mask], idx},
  If[Total[weights] <= 0, Return[initAgents["Random", n, {w, h}, None]]];
  idx = RandomChoice[weights -> Range[w h], n] - 1;
  Transpose[{Mod[idx, w] + RandomReal[1, n], Quotient[idx, w] + RandomReal[1, n], RandomReal[2 Pi, n]}]
];

initAgents[spec_, n_, size_, food_] := initAgents[toMask[spec, size], n, size, food];

(* ::Section:: *)
(* PhysarumSimulation *)

Options[PhysarumSimulation] = {
  "Size" -> 512,
  "Agents" -> Automatic,
  "Initialization" -> Automatic,
  "Food" -> None,
  "FoodStrength" -> Automatic,
  "FoodRadius" -> 3,
  "Walls" -> None,
  "Wrap" -> Automatic
};

PhysarumSimulation[opts : OptionsPattern[]] := PhysarumSimulation["Classic", opts];

PhysarumSimulation[spec_, opts : OptionsPattern[]] := Catch[
  Module[{p, species, size, w, h, n, counts, food, stim, walls, agents, init, wrap, strength},
    p = resolveSpec[spec];
    species = p["Species"];
    If[!MatrixQ[speciesMatrix[species], Internal`RealValuedNumericQ],
      Message[PhysarumSimulation::spec, spec]; Throw[$Failed, $tag]];
    size = Replace[OptionValue["Size"], s_?NumericQ :> {s, s}];
    {w, h} = Round[size];
    n = Replace[OptionValue["Agents"], Automatic :> Round[Lookup[p, "AgentDensity", 0.5] w h]];

    walls = UnitStep[toMask[OptionValue["Walls"], {w, h}] - 0.5];
    food = foodMask[OptionValue["Food"], {w, h}, OptionValue["FoodRadius"]];
    strength = Replace[OptionValue["FoodStrength"], Automatic :> Max[Lookup[species, "Deposit"]]];
    stim = strength food (1 - walls);

    wrap = Replace[OptionValue["Wrap"], Automatic :>
      Lookup[p, "Wrap", OptionValue["Walls"] === None && OptionValue["Food"] === None]];

    init = Replace[OptionValue["Initialization"], Automatic :> Lookup[p, "Initialization", "Random"]];
    If[init === "Food" && OptionValue["Food"] === None, init = "Random"];

    counts = Differences @ Round[n Prepend[Accumulate[#], 0] &[#/Total[#] &[N @ Lookup[species, "Fraction"]]]];
    agents = Join @@ MapIndexed[
      With[{a = initAgents[init, #1, {w, h}, food]},
        If[#1 == 0, {}, Join[a, ConstantArray[{First[#2] - 1.}, #1], 2]]] &,
      counts];
    agents = dropBlocked[agents, walls, {w, h}];

    PhysarumSimulationObject[<|
      "Agents" -> toNA[agents],
      "Trail" -> toNA[ConstantArray[0., {Length[species], h, w}]],
      "Stimulus" -> toNA[stim],
      "Walls" -> toNA[walls],
      "Parameters" -> toNA[speciesMatrix[species]],
      "Species" -> species,
      "Colors" -> speciesColors[species],
      "Size" -> {w, h},
      "Wrap" -> TrueQ[wrap],
      "Step" -> 0,
      "Style" -> KeyTake[p, {"ColorFunction", "Background", "Gamma", "Glow", "Clip"}],
      "Steps" -> Lookup[p, "Steps", 500]
    |>]
  ],
  $tag
];

(* Move agents that start inside a wall to a random free cell. *)
dropBlocked[agents_, walls_, {w_, h_}] /; Max[walls] == 0 := agents;
dropBlocked[agents_, walls_, {w_, h_}] := Module[{free = 1 - walls, blocked},
  blocked = Pick[Range[Length[agents]],
    Extract[walls, {Clip[Floor[#[[2]]] + 1, {1, h}], Clip[Floor[#[[1]]] + 1, {1, w}]} & /@ agents], _?Positive];
  If[blocked === {}, agents,
    ReplacePart[agents, Thread[blocked -> MapThread[Append,
      {initAgents[free, Length[blocked], {w, h}, None], agents[[blocked, 4]]}]]]]
];

(* ::Section:: *)
(* PhysarumSimulationObject *)

PhysarumSimulationObject[a_Association]["Properties"] :=
  {"Agents", "Trail", "Stimulus", "Walls", "Species", "Size", "Step", "Wrap", "AgentCount", "Image"};
PhysarumSimulationObject[a_Association]["Agents"] := Normal[a["Agents"]];
PhysarumSimulationObject[a_Association]["Trail"] := Normal[a["Trail"]];
PhysarumSimulationObject[a_Association]["Stimulus"] := Normal[a["Stimulus"]];
PhysarumSimulationObject[a_Association]["Walls"] := Normal[a["Walls"]];
PhysarumSimulationObject[a_Association]["AgentCount"] := First[Dimensions[a["Agents"]]];
PhysarumSimulationObject[a_Association]["Image"] := PhysarumImage[PhysarumSimulationObject[a]];
PhysarumSimulationObject[a_Association]["Data"] := a;
PhysarumSimulationObject[a_Association][key_String] /; KeyExistsQ[a, key] := a[key];

PhysarumSimulationObject /: MakeBoxes[obj : PhysarumSimulationObject[a_Association], fmt_] :=
  BoxForm`ArrangeSummaryBox[PhysarumSimulationObject, obj,
    Quiet @ Check[PhysarumImage[obj, ImageSize -> 48, "Glow" -> 0], None],
    {
      BoxForm`SummaryItem[{"Step: ", a["Step"]}],
      BoxForm`SummaryItem[{"Size: ", Row[a["Size"], "\[Times]"]}]
    },
    {
      BoxForm`SummaryItem[{"Agents: ", First[Dimensions[a["Agents"]]]}],
      BoxForm`SummaryItem[{"Species: ", Length[a["Species"]]}],
      BoxForm`SummaryItem[{"Wrap: ", a["Wrap"]}]
    },
    fmt];

(* ::Section:: *)
(* PhysarumEvolve *)

PhysarumEvolve[sim : (_PhysarumSimulationObject | _PhysarumSimulation3DObject)] := PhysarumEvolve[sim, 1];

PhysarumEvolve[PhysarumSimulationObject[a_Association], n_Integer?NonNegative] :=
  Catch[PhysarumSimulationObject[evolveData[libEvolve, a, n]], $tag];

PhysarumEvolve[PhysarumSimulation3DObject[a_Association], n_Integer?NonNegative] :=
  Catch[PhysarumSimulation3DObject[evolveData[libEvolve3D, a, n]], $tag];

evolveData[lib_, a_Association, n_] := Module[{res, dims, na, cols},
  res = lib[a["Agents"], a["Trail"], a["Stimulus"], a["Walls"], a["Parameters"],
    Boole[a["Wrap"]], n, RandomInteger[2^62]];
  If[Head[res] =!= NumericArray || Length[res] == 0,
    Message[PhysarumEvolve::abort]; Throw[$Aborted, $tag]];
  {na, cols} = Dimensions[a["Agents"]];
  dims = Dimensions[a["Trail"]];
  (* split and reshape the flat result without leaving NumericArray *)
  <|a,
    "Agents" -> ArrayReshape[Take[res, cols na], {na, cols}],
    "Trail" -> ArrayReshape[Drop[res, cols na], dims],
    "Step" -> a["Step"] + n
  |>
];

(* ::Section:: *)
(* PhysarumImage *)

Options[PhysarumImage] = {
  ColorFunction -> Automatic,
  "Colors" -> Automatic,
  Background -> Automatic,
  "Gamma" -> Automatic,
  "Glow" -> Automatic,
  "Clip" -> Automatic,
  "ShowFood" -> False,
  "ShowWalls" -> True,
  "WallColor" -> GrayLevel[0.25],
  "FoodColor" -> RGBColor[1, 0.3, 0.35],
  ImageSize -> Automatic
};

(* Paint color over an image with a per-pixel alpha matrix. *)
overlay[img_Image, color_, alpha_?MatrixQ] := Module[{d = ImageData[ColorConvert[RemoveAlphaChannel[img], "RGB"], "Real"], c = rgb[color]},
  Image[d (1 - alpha) + TensorProduct[alpha, c]]
];

(* Food cells are excluded when choosing the brightness scale, so strong food
   sources do not wash out the network. *)
normalizeLayer[m_, clip_, gamma_, exclude_ : None] := Module[{top},
  top = Quantile[Flatten[If[exclude === None, m, m (1 - exclude)]], clip];
  If[top <= 0, top = Max[m, $MachineEpsilon]];
  Clip[m / top, {0, 1}]^gamma
];

rgb[c_] := List @@ ColorConvert[c, "RGB"][[;; 3]];

blendLayers[layers_, colors_, bg_] := Module[{b = rgb[bg], lum},
  lum = Total[b {0.3, 0.59, 0.11}];
  If[lum < 0.5,
    (* additive light on a dark ground *)
    Clip[ConstantArray[b, Dimensions[First[layers]]] + Total[MapThread[TensorProduct, {layers, rgb /@ colors}]], {0, 1}],
    (* multiplicative ink on a light ground *)
    Fold[#1 (1 - TensorProduct[#2[[1]], 1 - rgb[#2[[2]]]]) &,
      ConstantArray[b, Dimensions[First[layers]]], Transpose[{layers, colors}]]
  ]
];

PhysarumImage[PhysarumSimulationObject[a_Association], opts : OptionsPattern[]] := Module[
  {style = a["Style"], opt, layers, cf, colors, bg, img, glow, walls, w, h},
  opt[name_, default_] := Replace[OptionValue[name],
    Automatic :> Lookup[style, If[StringQ[name], name, SymbolName[name]], default]];
  {w, h} = a["Size"];
  layers = With[{food = Normal[a["Stimulus"]]},
    normalizeLayer[#, opt["Clip", 0.995], opt["Gamma", 0.7], If[Max[food] > 0, UnitStep[food - 10.^-3 Max[food]], None]] & /@
      Normal[a["Trail"]]];
  cf = opt[ColorFunction, None];
  colors = Replace[OptionValue["Colors"], Automatic :> a["Colors"]];
  bg = opt[Background, Black];

  img = If[Length[layers] == 1 && cf =!= None && OptionValue["Colors"] === Automatic,
    Colorize[Image[First[layers]], ColorFunction -> cf],
    Image[blendLayers[layers, colors, bg]]
  ];

  glow = opt["Glow", 0.35];
  If[glow > 0,
    img = With[{d = ImageData[img, "Real"], halo = ImageData[GaussianFilter[img, Max[1, Round[Max[w, h]/80]]], "Real"]},
      Image[1 - (1 - d) (1 - glow halo)]]];

  If[TrueQ[OptionValue["ShowFood"]] && Max[Normal[a["Stimulus"]]] > 0,
    img = overlay[img, OptionValue["FoodColor"],
      0.9 Clip[3 Normal[a["Stimulus"]] / Max[Normal[a["Stimulus"]]], {0, 1}]]];

  walls = Normal[a["Walls"]];
  If[TrueQ[OptionValue["ShowWalls"]] && Max[walls] > 0,
    img = overlay[img, OptionValue["WallColor"], walls]];

  If[OptionValue[ImageSize] =!= Automatic, img = Image[img, ImageSize -> OptionValue[ImageSize]]];
  img
];

(* ::Section:: *)
(* PhysarumAnimate *)

Options[PhysarumAnimate] = Join[{"Output" -> "Frames", FrameRate -> 30}, Options[PhysarumImage]];

PhysarumAnimate[spec : Except[_PhysarumSimulationObject], rest___] :=
  With[{sim = PhysarumSimulation[spec]}, PhysarumAnimate[sim, rest] /; Head[sim] === PhysarumSimulationObject];

PhysarumAnimate[sim_PhysarumSimulationObject, frames_Integer?Positive, steps_Integer?Positive, opts : OptionsPattern[]] :=
  Module[{states, images, imgOpts = FilterRules[{opts}, Options[PhysarumImage]], file},
    states = Rest @ NestList[PhysarumEvolve[#, steps] &, sim, frames];
    If[MemberQ[states, $Aborted], Return[$Aborted]];
    images = PhysarumImage[#, Sequence @@ imgOpts] & /@ states;
    Switch[OptionValue["Output"],
      "Animation", ListAnimate[images, OptionValue[FrameRate], AnimationRunning -> False],
      "Video",
        file = FileNameJoin[{$TemporaryDirectory, "physarum-" <> CreateUUID[] <> ".mp4"}];
        Video[Export[file, images, "MP4", FrameRate -> OptionValue[FrameRate]]],
      _, images
    ]
  ];

(* ::Section:: *)
(* PhysarumArt *)

Options[PhysarumArt] = Join[{"Steps" -> Automatic}, Options[PhysarumSimulation],
  DeleteCases[Options[PhysarumImage], ImageSize -> _], {ImageSize -> Automatic}];

PhysarumArt[opts : OptionsPattern[]] := PhysarumArt["Classic", opts];

PhysarumArt[spec_, opts : OptionsPattern[]] := Module[{sim, steps},
  sim = PhysarumSimulation[spec, Sequence @@ FilterRules[{opts}, Options[PhysarumSimulation]]];
  If[Head[sim] =!= PhysarumSimulationObject, Return[$Failed]];
  steps = Replace[OptionValue["Steps"], Automatic :> sim["Steps"]];
  sim = PhysarumEvolve[sim, steps];
  If[sim === $Aborted, Return[$Aborted]];
  PhysarumImage[sim, Sequence @@ FilterRules[{opts}, Options[PhysarumImage]]]
];

(* ::Section:: *)
(* 3D agent model

   Grids are stored as {d, h, w} arrays indexed [[z, y, x]], with every index increasing
   along its axis (z and y point up). Positions in the API are in the unit cube. Image3D puts
   its first slice at the top and its first row at the back, so arrays are reversed in z and y
   on the way to and from Image3D. *)

toImage3DData[m_] := Reverse[m, {1, 2}];
fromImage3DData[m_] := Reverse[m, {1, 2}];

gray3D[img_Image3D] := ImageData[ColorConvert[RemoveAlphaChannel[img, White], "Grayscale"], "Real"];

(* voxel centres {x, y, z} in the unit cube, flattened in storage order (z slowest) *)
voxelCentres[{w_, h_, d_}] :=
  Tuples[{(Range[d] - 0.5)/d, (Range[h] - 0.5)/h, (Range[w] - 0.5)/w}][[All, {3, 2, 1}]];

region3DQ[r_] := RegionQ[r] && RegionEmbeddingDimension[r] == 3;

toMask3D[None | Automatic, {w_, h_, d_}] := ConstantArray[0., {d, h, w}];
toMask3D[img_Image3D, {w_, h_, d_}] := Clip[fromImage3DData[gray3D[ImageResize[img, {w, h, d}]]], {0, 1}];
toMask3D[m_ /; ArrayQ[m, 3, NumericQ], size_] := toMask3D[Image3D[N[m]], size];
(* The precompiled RegionMember[r] is far faster on many points than RegionMember[r, pts],
   and testing each region of a list beats testing their RegionUnion. *)
toMask3D[l : {__?region3DQ}, size_] := Fold[vmax, toMask3D[#, size] & /@ l];
toMask3D[r_?region3DQ, {w_, h_, d_}] :=
  ArrayReshape[N @ Boole[RegionMember[r][voxelCentres[{w, h, d}]]], {d, h, w}];
toMask3D[other_, _] := (Message[PhysarumSimulation3D::mask, Short[other]]; Throw[$Failed, $tag]);

points3DQ[p_] := MatrixQ[p, NumericQ] && Last[Dimensions[p]] == 3;

(* Food given as points in the unit cube: soft balls, computed in a window around each point. *)
foodMask3D[pts_?points3DQ, {w_, h_, d_}, radius_] := Module[{m = ConstantArray[0., {d, h, w}], r = N[radius]},
  Do[
    Module[{c = p {w, h, d}, lo, hi, axes, s},
      lo = Max[1, #] & /@ Floor[c - 3 Sqrt[2] r];
      hi = MapThread[Min, {{w, h, d}, Ceiling[c + 3 Sqrt[2] r]}];
      If[And @@ Thread[lo <= hi],
        axes = MapThread[((Range[#1, #2] - 0.5 - #3)^2 / (2 r^2)) &, {lo, hi, c}];
        s = Outer[Plus, axes[[3]], axes[[2]], axes[[1]]];
        m[[lo[[3]] ;; hi[[3]], lo[[2]] ;; hi[[2]], lo[[1]] ;; hi[[1]]]] += UnitStep[9. - s] Exp[-Clip[s, {0., 9.}]]]],
    {p, N[pts]}];
  Clip[m, {0, 1}]
];
foodMask3D[other_, size_, _] := toMask3D[other, size];

randomDirections[n_] := Normalize /@ RandomVariate[NormalDistribution[], {n, 3}];

ballAgents[n_, {w_, h_, d_}, rmax_] := Module[{dirs = randomDirections[n], r},
  r = rmax Min[w, h, d] RandomReal[1, n]^(1/3);
  {ConstantArray[{w, h, d}/2, n] + r dirs, dirs}];

(* agents as {x, y, z, hx, hy, hz} rows in grid units *)
initAgents3D["Random", n_, {w_, h_, d_}, _] :=
  Join[Transpose[{RandomReal[w, n], RandomReal[h, n], RandomReal[d, n]}], randomDirections[n], 2];

initAgents3D["Ball", n_, size_, _] := Join[First[ballAgents[n, size, 0.38]], randomDirections[n], 2];

initAgents3D["Shell", n_, {w_, h_, d_}, _] := Module[{dirs = randomDirections[n]},
  Join[ConstantArray[{w, h, d}/2, n] + 0.42 Min[w, h, d] dirs, -dirs, 2]];

initAgents3D["Burst", n_, size_, _] := Join @@ Append[ballAgents[n, size, 0.03], 2];

initAgents3D["Food", n_, size_, food_] := initAgents3D[food, n, size, food];

initAgents3D[mask_ /; ArrayQ[mask, 3, NumericQ], n_, {w_, h_, d_}, _] := Module[{weights = Flatten[mask], idx},
  If[Total[weights] <= 0, Return[initAgents3D["Random", n, {w, h, d}, None]]];
  idx = RandomChoice[weights -> Range[w h d], n] - 1;
  Join[
    Transpose[{Mod[idx, w], Mod[Quotient[idx, w], h], Quotient[idx, w h]}] + RandomReal[1, {n, 3}],
    randomDirections[n], 2]
];

initAgents3D[spec_, n_, size_, food_] := initAgents3D[toMask3D[spec, size], n, size, food];

(* Move agents that start inside a wall to a random free cell. *)
dropBlocked3D[agents_, walls_, _] /; Max[walls] == 0 := agents;
dropBlocked3D[agents_, walls_, {w_, h_, d_}] := Module[{blocked},
  blocked = Pick[Range[Length[agents]],
    Extract[walls, {Clip[Floor[#[[3]]] + 1, {1, d}], Clip[Floor[#[[2]]] + 1, {1, h}], Clip[Floor[#[[1]]] + 1, {1, w}]} & /@ agents],
    _?Positive];
  If[blocked === {}, agents,
    ReplacePart[agents, Thread[blocked -> MapThread[Append,
      {initAgents3D[1 - walls, Length[blocked], {w, h, d}, None], agents[[blocked, 7]]}]]]]
];

Options[PhysarumSimulation3D] = {
  "Size" -> 96,
  "Agents" -> Automatic,
  "Initialization" -> Automatic,
  "Food" -> None,
  "FoodStrength" -> Automatic,
  "FoodRadius" -> 2,
  "Walls" -> None,
  "Wrap" -> Automatic
};

PhysarumSimulation3D::mask = "Cannot interpret `1` as a 3D mask.";
PhysarumSimulation3D::size = "\"Size\" must be a positive integer or a list of three positive integers.";

PhysarumSimulation3D[opts : OptionsPattern[]] := PhysarumSimulation3D["Classic", opts];

PhysarumSimulation3D[spec_, opts : OptionsPattern[]] := Catch[
  Module[{p, species, size, w, h, d, n, counts, food, stim, walls, agents, init, wrap, strength},
    p = resolveSpec[spec];
    species = p["Species"];
    If[!MatrixQ[speciesMatrix[species], Internal`RealValuedNumericQ],
      Message[PhysarumSimulation::spec, spec]; Throw[$Failed, $tag]];
    size = Replace[OptionValue["Size"], s_?NumericQ :> {s, s, s}];
    If[!MatchQ[Round[size], {_Integer?Positive, _Integer?Positive, _Integer?Positive}],
      Message[PhysarumSimulation3D::size]; Throw[$Failed, $tag]];
    {w, h, d} = Round[size];
    n = Replace[OptionValue["Agents"], Automatic :> Round[Lookup[p, "AgentDensity", 0.5] w h d]];

    walls = UnitStep[toMask3D[OptionValue["Walls"], {w, h, d}] - 0.5];
    food = foodMask3D[OptionValue["Food"], {w, h, d}, OptionValue["FoodRadius"]];
    strength = Replace[OptionValue["FoodStrength"], Automatic :> Max[Lookup[species, "Deposit"]]];
    stim = strength food (1 - walls);

    wrap = Replace[OptionValue["Wrap"], Automatic :>
      Lookup[p, "Wrap", OptionValue["Walls"] === None && OptionValue["Food"] === None]];

    init = Replace[OptionValue["Initialization"], Automatic :> Lookup[p, "Initialization", "Random"]];
    If[init === "Food" && OptionValue["Food"] === None, init = "Random"];
    (* the 2D-only shapes have 3D counterparts *)
    init = Replace[init, {"Disk" -> "Ball", "Ring" -> "Shell"}];

    counts = Differences @ Round[n Prepend[Accumulate[#], 0] &[#/Total[#] &[N @ Lookup[species, "Fraction"]]]];
    agents = Join @@ MapIndexed[
      With[{a = initAgents3D[init, #1, {w, h, d}, food]},
        If[#1 == 0, {}, Join[a, ConstantArray[{First[#2] - 1.}, #1], 2]]] &,
      counts];
    agents = dropBlocked3D[agents, walls, {w, h, d}];

    PhysarumSimulation3DObject[<|
      "Agents" -> toNA[agents],
      "Trail" -> toNA[ConstantArray[0., {Length[species], d, h, w}]],
      "Stimulus" -> toNA[stim],
      "Walls" -> toNA[walls],
      "Parameters" -> toNA[speciesMatrix[species]],
      "Species" -> species,
      "Colors" -> speciesColors[species],
      "Size" -> {w, h, d},
      "Wrap" -> TrueQ[wrap],
      "Step" -> 0,
      "Style" -> KeyTake[p, {"ColorFunction", "Background", "Gamma", "Clip"}],
      "Steps" -> Lookup[p, "Steps3D", 300]
    |>]
  ],
  $tag
];

PhysarumSimulation3DObject[a_Association]["Properties"] :=
  {"Agents", "Trail", "Stimulus", "Walls", "Species", "Size", "Step", "Wrap", "AgentCount", "Image3D", "Graphics3D", "Projection"};
PhysarumSimulation3DObject[a_Association]["Agents"] := Normal[a["Agents"]];
PhysarumSimulation3DObject[a_Association]["Trail"] := Normal[a["Trail"]];
PhysarumSimulation3DObject[a_Association]["Stimulus"] := Normal[a["Stimulus"]];
PhysarumSimulation3DObject[a_Association]["Walls"] := Normal[a["Walls"]];
PhysarumSimulation3DObject[a_Association]["AgentCount"] := First[Dimensions[a["Agents"]]];
PhysarumSimulation3DObject[a_Association]["Image3D"] := PhysarumImage3D[PhysarumSimulation3DObject[a]];
PhysarumSimulation3DObject[a_Association]["Graphics3D"] := PhysarumGraphics3D[PhysarumSimulation3DObject[a]];
PhysarumSimulation3DObject[a_Association]["Projection"] := projection3D[a];
PhysarumSimulation3DObject[a_Association]["Data"] := a;
PhysarumSimulation3DObject[a_Association][key_String] /; KeyExistsQ[a, key] := a[key];

(* A cheap 2D view: the maximum of each species' trail along z, seen from above. *)
projection3D[a_Association] := Module[{layers},
  layers = normalizeLayer[Fold[vmax, #], 0.995, 0.7] & /@ Normal[a["Trail"]];
  ImageReflect[Image[blendLayers[layers, a["Colors"], Black]], Top]
];

PhysarumSimulation3DObject /: MakeBoxes[obj : PhysarumSimulation3DObject[a_Association], fmt_] :=
  BoxForm`ArrangeSummaryBox[PhysarumSimulation3DObject, obj,
    Quiet @ Check[Image[projection3D[a], ImageSize -> 48], None],
    {
      BoxForm`SummaryItem[{"Step: ", a["Step"]}],
      BoxForm`SummaryItem[{"Size: ", Row[a["Size"], "\[Times]"]}]
    },
    {
      BoxForm`SummaryItem[{"Agents: ", First[Dimensions[a["Agents"]]]}],
      BoxForm`SummaryItem[{"Species: ", Length[a["Species"]]}],
      BoxForm`SummaryItem[{"Wrap: ", a["Wrap"]}]
    },
    fmt];

(* --- PhysarumImage3D: volume rendering with opacity following trail strength --- *)

Options[PhysarumImage3D] = {
  ColorFunction -> Automatic,
  "Colors" -> Automatic,
  Background -> Automatic,
  "Gamma" -> Automatic,
  "Clip" -> Automatic,
  "Opacity" -> 1,
  "Smoothing" -> 2,
  "ShowFood" -> False,
  "ShowWalls" -> True,
  "WallColor" -> GrayLevel[0.6],
  "FoodColor" -> RGBColor[1, 0.3, 0.35],
  ImageSize -> Automatic
};

(* Colour a whole array through a 256-entry lookup table: one cf call per entry, not per voxel. *)
colorize3D[m_, cf_String] := colorize3D[m, ColorData[cf]];
colorize3D[m_, cf_] := With[{lut = rgb[cf[#]] & /@ Subdivide[0., 1., 255]},
  ArrayReshape[lut[[Flatten[Round[255 Clip[m, {0, 1}]]] + 1]], Append[Dimensions[m], 3]]];

(* elementwise maximum of two arrays *)
vmax[a_, b_] := 0.5 (a + b + Abs[a - b]);

PhysarumImage3D[PhysarumSimulation3DObject[a_Association], opts : OptionsPattern[{PhysarumImage3D, Image3D}]] := Module[
  {style = a["Style"], opt, layers, cf, colors, bg, rgbData, alpha, food, walls, img, extra},
  opt[name_, default_] := Replace[OptionValue[name],
    Automatic :> Lookup[style, If[StringQ[name], name, SymbolName[name]], default]];
  food = Normal[a["Stimulus"]];
  (* a light blur keeps one-voxel-thin strands from rendering as stripes *)
  layers = normalizeLayer[If[OptionValue["Smoothing"] > 0, GaussianFilter[#, OptionValue["Smoothing"]], #],
      (* several species fill the volume with haze: a higher gamma keeps their strands apart *)
      opt["Clip", 0.995], opt["Gamma", If[Length[a["Species"]] == 1, 1, 2.5]],
      If[Max[food] > 0, UnitStep[food - 10.^-3 Max[food]], None]] & /@
    Normal[a["Trail"]];
  cf = opt[ColorFunction, None];
  colors = Replace[OptionValue["Colors"], Automatic :> a["Colors"]];
  bg = opt[Background, Black];

  (* colour from the trail, opacity from its strength *)
  If[Length[layers] == 1 && cf =!= None && OptionValue["Colors"] === Automatic,
    rgbData = colorize3D[First[layers], cf];
    alpha = First[layers],
    (* species colours weighted by their share of the trail in each voxel *)
    With[{total = Total[layers]},
      rgbData = Total[MapThread[TensorProduct, {layers, rgb /@ colors}]] / (total + $MachineEpsilon);
      alpha = Clip[total, {0, 1}]]
  ];
  alpha = Clip[OptionValue["Opacity"] alpha, {0, 1}];

  If[TrueQ[OptionValue["ShowFood"]] && Max[food] > 0,
    With[{f = Clip[3 food / Max[food], {0, 1}]},
      rgbData = rgbData (1 - f) + TensorProduct[f, rgb[OptionValue["FoodColor"]]];
      alpha = vmax[alpha, f]]];

  walls = Normal[a["Walls"]];
  If[TrueQ[OptionValue["ShowWalls"]] && Max[walls] > 0,
    rgbData = rgbData (1 - walls) + TensorProduct[walls, rgb[OptionValue["WallColor"]]];
    alpha = vmax[alpha, 0.08 walls]];

  extra = FilterRules[{opts}, Except[Options[PhysarumImage3D]]];
  img = Image3D[toImage3DData[Join[rgbData, ArrayReshape[alpha, Append[Dimensions[alpha], 1]], 4]],
    ColorSpace -> "RGB", Interleaving -> True, Background -> bg, Sequence @@ extra];
  If[OptionValue[ImageSize] =!= Automatic, img = Image3D[img, ImageSize -> OptionValue[ImageSize]]];
  img
];

(* --- PhysarumGraphics3D: isosurfaces of the trail, or the agents as points --- *)

Options[PhysarumGraphics3D] = {
  Method -> "Surface",
  "Colors" -> Automatic,
  Background -> Automatic,
  "Threshold" -> Automatic,
  "Smoothing" -> 1,
  "MaxPoints" -> 50000,
  "ShowFood" -> True,
  "ShowWalls" -> True,
  "WallColor" -> GrayLevel[0.6],
  "FoodColor" -> RGBColor[1, 0.3, 0.35],
  ImageSize -> Automatic
};

(* Isosurface of a {d, h, w} array at level thr, as a GraphicsComplex in grid coordinates.
   On grayscale input ImageMesh picks its own threshold, so the values first go through a
   steep sigmoid centred on thr: the surface then lands within about a voxel of thr and,
   unlike a binarized volume, stays smooth. *)
isoSurface[m_, thr_, smooth_] := Module[{v = m, mesh},
  If[smooth > 0, v = GaussianFilter[v, smooth]];
  mesh = Quiet @ ImageMesh[Image3D[toImage3DData[LogisticSigmoid[20 (v - thr)]]], Method -> "MarchingCubes"];
  If[!MeshRegionQ[mesh] && !BoundaryMeshRegionQ[mesh], Return[{}]];
  GraphicsComplex[MeshCoordinates[mesh], MeshCells[mesh, 2]]
];

PhysarumGraphics3D[PhysarumSimulation3DObject[a_Association], opts : OptionsPattern[{PhysarumGraphics3D, Graphics3D}]] := Module[
  {style = a["Style"], w, h, d, colors, bg, food, walls, prims, layers, thr, agents, extra},
  {w, h, d} = a["Size"];
  (* a single species with a preset colour scheme takes a bright colour from that scheme *)
  colors = Replace[OptionValue["Colors"], Automatic :>
    If[Length[a["Species"]] == 1 && KeyExistsQ[style, "ColorFunction"] && a["Species"][[1, "Color"]] === Automatic,
      {Replace[style["ColorFunction"], s_String :> ColorData[s]][0.75]},
      a["Colors"]]];
  bg = Replace[OptionValue[Background], Automatic :> Lookup[style, "Background", Black]];
  food = Normal[a["Stimulus"]];
  prims = Switch[OptionValue[Method],
    "Points",
      (* each agent is coloured by its species, brighter where the trail is stronger *)
      agents = Normal[a["Agents"]];
      If[Length[agents] > OptionValue["MaxPoints"], agents = RandomSample[agents, OptionValue["MaxPoints"]]];
      layers = normalizeLayer[#, 0.995, 0.7] & /@ Normal[a["Trail"]];
      With[{s = Round[agents[[All, 7]]] + 1,
          cell = Transpose[{Clip[Floor[agents[[All, 3]]] + 1, {1, d}], Clip[Floor[agents[[All, 2]]] + 1, {1, h}],
            Clip[Floor[agents[[All, 1]]] + 1, {1, w}]}]},
        {PointSize[Tiny], Point[agents[[All, ;; 3]], VertexColors ->
          (RGBColor @@ ((0.2 + 0.8 Extract[layers[[#1]], #2]) rgb[colors[[#1]]]) & @@@ Transpose[{s, cell}])]}],
    _,
      layers = normalizeLayer[#, 0.995, 1, If[Max[food] > 0, UnitStep[food - 10.^-3 Max[food]], None]] & /@ Normal[a["Trail"]];
      thr = Replace[OptionValue["Threshold"], Automatic :> 0.3];
      MapThread[{EdgeForm[], #2, Specularity[White, 30], isoSurface[#1, thr, OptionValue["Smoothing"]]} &, {layers, colors}]
  ];
  If[TrueQ[OptionValue["ShowFood"]] && Max[food] > 0,
    AppendTo[prims, {EdgeForm[], OptionValue["FoodColor"], isoSurface[food / Max[food], 0.2, 0]}]];
  walls = Normal[a["Walls"]];
  If[TrueQ[OptionValue["ShowWalls"]] && Max[walls] > 0,
    AppendTo[prims, {EdgeForm[], OptionValue["WallColor"], Opacity[0.25], isoSurface[walls, 0.5, 0]}]];
  extra = FilterRules[{opts}, Except[Options[PhysarumGraphics3D]]];
  Graphics3D[prims, Sequence @@ extra,
    PlotRange -> {{0, w}, {0, h}, {0, d}}, BoxRatios -> {w, h, d}, Background -> bg,
    Boxed -> True, BoxStyle -> GrayLevel[0.5], Lighting -> "Neutral", SphericalRegion -> True,
    ImageSize -> OptionValue[ImageSize]]
];

(* --- PhysarumArt3D --- *)

Options[PhysarumArt3D] = Join[{"Steps" -> Automatic, "Output" -> "Image3D"}, Options[PhysarumSimulation3D],
  DeleteCases[Options[PhysarumImage3D], ImageSize -> _], {ImageSize -> Automatic}];

PhysarumArt3D[opts : OptionsPattern[]] := PhysarumArt3D["Classic", opts];

PhysarumArt3D[spec_, opts : OptionsPattern[{PhysarumArt3D, PhysarumGraphics3D}]] := Module[{sim, steps},
  sim = PhysarumSimulation3D[spec, Sequence @@ FilterRules[{opts}, Options[PhysarumSimulation3D]]];
  If[Head[sim] =!= PhysarumSimulation3DObject, Return[$Failed]];
  steps = Replace[OptionValue["Steps"], Automatic :> sim["Steps"]];
  sim = PhysarumEvolve[sim, steps];
  If[sim === $Aborted, Return[$Aborted]];
  Switch[OptionValue["Output"],
    "Graphics3D", PhysarumGraphics3D[sim, Sequence @@ FilterRules[{opts}, Options[PhysarumGraphics3D]]],
    "Simulation", sim,
    _, PhysarumImage3D[sim, Sequence @@ FilterRules[{opts}, Options[PhysarumImage3D]]]
  ]
];

(* ::Section:: *)
(* PhysarumNetwork: grow a network between food sources and read it off as a Graph *)

$networkSpecies = <|"SensorAngle" -> 30 Degree, "RotationAngle" -> 30 Degree, "SensorDistance" -> 8,
  "Deposit" -> 1, "Decay" -> 0.3, "Diffusion" -> 0.15|>;

Options[PhysarumNetwork] = {
  "Size" -> 400,
  "Steps" -> 2000,
  "AgentDensity" -> 0.3,
  "Species" -> Automatic,
  "FoodRadius" -> Automatic,
  "FoodStrength" -> 300,
  "Walls" -> None,
  "Padding" -> 0.15,
  "DeleteDeadEnds" -> True,
  "Backbone" -> False,
  "Threshold" -> Automatic,
  "Pruning" -> Automatic,
  "Resampling" -> 6,
  "Initialization" -> "Random",
  "Output" -> "Graph"
};

geoLikeQ[x_] := MatchQ[x, _GeoPosition | _Entity];

(* Entities (cities, landmarks, ...) are resolved with a single batched "Position" lookup. *)
toGeoPositions[pts_List] := Module[{geo = pts, ents = Position[pts, _Entity, {1}, Heads -> False]},
  If[ents =!= {},
    geo = ReplacePart[geo, Thread[ents -> Quiet @ EntityValue[Extract[pts, ents], "Position"]]]];
  Replace[geo, g : Except[_GeoPosition] :> Quiet @ GeoPosition[g], {1}]
];

toPlane[pts_List] := Module[{latlon, lat0, geo},
  geo = toGeoPositions[pts];
  If[!MatchQ[geo, {GeoPosition[{_?NumericQ, _?NumericQ, ___}, ___] ..}],
    Message[PhysarumNetwork::geo, Select[Transpose[{pts, geo}], !MatchQ[#[[2]], _GeoPosition] &][[All, 1]]];
    Throw[$Failed, $tag]];
  latlon = Take[First[#], 2] & /@ geo;
  lat0 = Mean[latlon[[All, 1]]];
  <|"XY" -> ({#[[2]] Cos[lat0 Degree], #[[1]]} & /@ latlon), "Lat0" -> lat0|>
];

fromPlane[xy_, lat0_] := GeoPosition[{#[[2]], #[[1]] / Cos[lat0 Degree]}] & /@ xy;

PhysarumNetwork[input_List, opts : OptionsPattern[]] := Catch[
  Module[{geo, pts, xy, lat0, lo, hi, span, pad, unit, w, h, sim, trail, img, bin, skel, g,
      toData, coords, food, near, graph, radius, prune, out, species},
    geo = AllTrue[input, geoLikeQ];
    pts = If[geo, input, N[input]];
    If[Length[DeleteDuplicates[pts]] < 2 || !(geo || pointsQ[pts]),
      Message[PhysarumNetwork::pts]; Throw[$Failed, $tag]];
    If[geo, {xy, lat0} = Values[toPlane[pts]], xy = pts; lat0 = 0];

    (* padded bounding box -> grid *)
    {lo, hi} = {Min /@ Transpose[xy], Max /@ Transpose[xy]};
    span = Max[hi - lo];
    pad = OptionValue["Padding"] span;
    {lo, hi} = {lo - pad, hi + pad};
    {w, h} = Round[OptionValue["Size"] (hi - lo) / Max[hi - lo]];
    unit = (# - lo) / (hi - lo) & /@ xy;

    radius = Replace[OptionValue["FoodRadius"], Automatic :> Max[2, Round[Max[w, h]/130]]];
    species = Replace[OptionValue["Species"], Automatic :> $networkSpecies];
    sim = PhysarumSimulation[<|"Species" -> Flatten[{species}], "AgentDensity" -> OptionValue["AgentDensity"]|>,
      "Size" -> {w, h}, "Food" -> unit, "FoodRadius" -> radius, "FoodStrength" -> OptionValue["FoodStrength"],
      "Walls" -> OptionValue["Walls"], "Wrap" -> False, "Initialization" -> OptionValue["Initialization"]];
    If[Head[sim] =!= PhysarumSimulationObject, Throw[$Failed, $tag]];
    sim = PhysarumEvolve[sim, OptionValue["Steps"]];
    If[sim === $Aborted, Throw[$Aborted, $tag]];

    (* trail -> binary network -> skeleton -> graph *)
    trail = Total[sim["Trail"]];
    (* strong gamma compression keeps faint filaments connected after thresholding *)
    img = Image[normalizeLayer[trail, 0.995, 0.3, UnitStep[sim["Stimulus"] - 10.^-3 Max[sim["Stimulus"]]]]];
    img = GaussianFilter[img, 1.5];
    bin = Binarize[img, Replace[OptionValue["Threshold"], Automatic :> FindThreshold[img, Method -> "Otsu"]]];
    bin = DeleteSmallComponents[bin, Round[w h / 2000]];
    prune = Replace[OptionValue["Pruning"], Automatic :> Round[Max[w, h]/40]];
    skel = Pruning[Thinning[bin], prune];
    g = skeletonGraph[skel, OptionValue["Resampling"]];

    (* pixel coordinates (y up) -> user coordinates *)
    toData[p_] := lo + (hi - lo) (p / {w, h});
    coords = toData /@ First[g];
    graph = Graph[Range[Length[coords]], Last[g], VertexCoordinates -> coords];

    (* attach each food source to its nearest network vertex *)
    food = MapIndexed[If[MatchQ[#1, _Entity], #1, "Food" <> ToString[First[#2]]] &, pts];
    If[VertexCount[graph] > 0,
      near = Nearest[coords -> Automatic];
      graph = Graph[
        Join[VertexList[graph], food],
        Join[EdgeList[graph], MapThread[UndirectedEdge, {food, First /@ (near /@ xy)}]],
        VertexCoordinates -> Join[coords, xy]],
      graph = Graph[food, {}, VertexCoordinates -> xy]
    ];
    If[TrueQ[OptionValue["DeleteDeadEnds"]], graph = deleteDeadEnds[graph, food]];
    If[TrueQ[OptionValue["Backbone"]], graph = backbone[graph, food]];
    food = Select[food, MemberQ[VertexList[graph], #] &];
    With[{pos = AssociationThread[VertexList[graph], GraphEmbedding[graph]]},
      graph = Graph[VertexList[graph], EdgeList[graph],
        VertexCoordinates -> Normal[pos],
        EdgeWeight -> (EuclideanDistance[pos[#[[1]]], pos[#[[2]]]] & /@ EdgeList[graph]),
        (* per-vertex rules first, then the default; plain numbers would be relative to the
           (tiny) minimum vertex distance, so use sizes scaled to the whole plot *)
        VertexSize -> Append[(# -> {"Scaled", 0.018}) & /@ food, {"Scaled", 0.003}],
        VertexStyle -> Append[Thread[food -> RGBColor[0.9, 0.2, 0.25]], RGBColor[0.9, 0.55, 0.1]],
        VertexShapeFunction -> Append[(# -> "Circle") & /@ food, None],
        EdgeStyle -> Directive[RGBColor[0.9, 0.55, 0.1], AbsoluteThickness[1.5]]]
    ];

    out = OptionValue["Output"];
    Switch[out,
      "Graph", graph,
      "Simulation", sim,
      "Image", PhysarumImage[sim, "ShowFood" -> True],
      "GeoGraphics" /; geo, networkGeoGraphics[graph, food, lat0],
      "Association", <|"Graph" -> graph, "Simulation" -> sim, "Image" -> PhysarumImage[sim, "ShowFood" -> True],
        "Skeleton" -> skel, "Food" -> food,
        If[geo, "GeoGraphics" -> networkGeoGraphics[graph, food, lat0], Nothing]|>,
      _, graph
    ]
  ],
  $tag
];

(* Strip branches that lead nowhere: repeatedly remove non-food leaves, then drop
   components without food. What remains is the transport network between food sources. *)
deleteDeadEnds[graph_, food_] := Module[{g = graph, leaves},
  While[(leaves = Select[Complement[VertexList[g], food], VertexDegree[g, #] <= 1 &]) =!= {},
    g = VertexDelete[g, leaves]];
  Subgraph[g, Join @@ Select[ConnectedComponents[g], IntersectingQ[#, food] &]]
];

(* Keep only edges that lie on a shortest path between some pair of food sources. *)
backbone[graph_, food_] := Module[{g, pos, paths, keep},
  pos = AssociationThread[VertexList[graph], GraphEmbedding[graph]];
  g = Graph[graph, EdgeWeight -> (EuclideanDistance[pos[#[[1]]], pos[#[[2]]]] & /@ EdgeList[graph])];
  paths = FindShortestPath[g, #1, #2] & @@@ Subsets[Select[food, MemberQ[VertexList[g], #] &], {2}];
  keep = DeleteDuplicates[Sort /@ Flatten[UndirectedEdge @@@ Partition[#, 2, 1] & /@ paths]];
  g = EdgeDelete[graph, Complement[Sort /@ EdgeList[graph], keep]];
  VertexDelete[g, Select[Complement[VertexList[g], food], VertexDegree[g, #] == 0 &]]
];

(* Skeleton image -> {vertex positions (pixel coords, y up), undirected edges}.
   Junction pixel clusters collapse to single nodes; the pixel chains between nodes are
   walked and resampled every `step` pixels so that edges follow the curves. *)
skeletonGraph[skel_Image, step_Integer] := Module[
  {pos, m, near, adj, deg, nodeOf, nodes, clusters, chains, vpos, edges, next, comps,
    ends, loops, seen, walk = 0, interiors, offsets},
  pos = N[PixelValuePositions[skel, 1]] - 0.5;
  m = Length[pos];
  If[m < 2, Return[{{}, {}}]];
  near = Nearest[pos -> Automatic];
  adj = MapIndexed[DeleteCases[near[#1, {All, 1.5}], First[#2]] &, pos];
  deg = Length /@ adj;

  (* nodes: clusters of junction pixels, endpoints, and one pixel per junction-free loop *)
  nodeOf = ConstantArray[0, m];
  clusters = ConnectedComponents[Graph[Range[m],
    Flatten[Table[If[deg[[i]] >= 3, UndirectedEdge[i, #] & /@ Select[adj[[i]], deg[[#]] >= 3 && # > i &], {}], {i, m}]]]];
  clusters = Select[clusters, deg[[First[#]]] >= 3 &];
  Do[nodeOf[[clusters[[k]]]] = k, {k, Length[clusters]}];
  nodes = Mean[pos[[#]]] & /@ clusters;
  ends = Pick[Range[m], Thread[deg <= 1]];
  nodeOf[[ends]] = Length[nodes] + Range[Length[ends]];
  nodes = Join[nodes, pos[[ends]]];
  comps = ConnectedComponents[Graph[Range[m], Flatten[MapIndexed[UndirectedEdge[First[#2], #1] &, adj, {2}]]]];
  loops = First /@ Select[comps, Max[nodeOf[[#]]] == 0 &];
  nodeOf[[loops]] = Length[nodes] + Range[Length[loops]];
  nodes = Join[nodes, pos[[loops]]];

  (* walk every chain leaving a node until another node is reached; seen[[i]] == walk marks
     the pixels of the current walk, and the path is a linked list, so each step is O(1) *)
  seen = ConstantArray[0, m];
  chains = Reap[
    Do[If[nodeOf[[p]] > 0,
      Do[
        Module[{prev = p, cur = q, path = {}, len = 0},
          walk++;
          While[nodeOf[[cur]] == 0 && len <= m,
            path = {path, cur}; len++; seen[[cur]] = walk;
            next = SelectFirst[adj[[cur]], # != prev && seen[[#]] != walk &, None];
            If[next === None, Break[]];
            {prev, cur} = {cur, next}];
          If[nodeOf[[cur]] > 0 && (nodeOf[[cur]] != nodeOf[[p]] || len > 0),
            Sow[{nodeOf[[p]], nodeOf[[cur]], Flatten[path]}]]
        ],
        {q, Select[adj[[p]], nodeOf[[#]] != nodeOf[[p]] &]}]],
      {p, m}]
  ][[2]];
  chains = If[chains === {}, {}, First[chains]];
  (* each chain was found from both ends: keep one copy *)
  chains = DeleteDuplicatesBy[chains, {Sort[#[[;; 2]]], Sort[#[[3]]]} &];

  (* resample chains into polylines of intermediate vertices *)
  interiors = If[Length[#[[3]]] > step, Rest[pos[[#[[3, ;; ;; step]]]]], {}] & /@ chains;
  offsets = Length[nodes] + Most[Prepend[Accumulate[Length /@ interiors], 0]];
  vpos = Join[nodes, Join @@ interiors];
  edges = Flatten @ MapThread[
    UndirectedEdge @@@ Partition[Join[{#1[[1]]}, #2 + Range[Length[#3]], {#1[[2]]}], 2, 1] &,
    {chains, offsets, interiors}];
  edges = DeleteDuplicates[DeleteCases[Sort /@ edges, UndirectedEdge[a_, a_]]];
  {vpos, edges}
];

networkGeoGraphics[graph_, food_, lat0_] := Module[{coord},
  coord = AssociationThread[VertexList[graph], First[fromPlane[{#}, lat0]] & /@ GraphEmbedding[graph]];
  GeoGraphics[{
    {RGBColor[0.9, 0.35, 0.1], AbsoluteThickness[2], GeoPath[{coord[#[[1]]], coord[#[[2]]]}, "Rhumb"] & /@ EdgeList[graph]},
    {RGBColor[0.1, 0.2, 0.6], PointSize[0.012], Point[coord /@ food]}
  }]
];

(* ::Section:: *)
(* PhysarumMaze *)

Options[PhysarumMaze] = {"CellSize" -> 5, "WallWidth" -> 1, "Loops" -> 0, RandomSeeding -> Automatic};

(* Depth-first "recursive backtracker" maze; "Loops" re-opens extra walls so that
   there is more than one route between two points. *)
PhysarumMaze[n_Integer /; n >= 2, opts : OptionsPattern[]] := BlockRandom[
  Module[{cell = OptionValue["CellSize"], wall = OptionValue["WallWidth"], visited, stack, open = {},
      cur, nbrs, nxt, closed, m, carve},
    visited = ConstantArray[False, {n, n}];
    stack = {{1, 1}}; visited[[1, 1]] = True;
    While[stack =!= {},
      cur = Last[stack];
      nbrs = Select[cur + # & /@ {{1, 0}, {-1, 0}, {0, 1}, {0, -1}},
        1 <= #[[1]] <= n && 1 <= #[[2]] <= n && !visited[[#[[1]], #[[2]]]] &];
      If[nbrs === {},
        stack = Most[stack],
        nxt = RandomChoice[nbrs]; visited[[nxt[[1]], nxt[[2]]]] = True;
        AppendTo[open, Sort[{cur, nxt}]]; AppendTo[stack, nxt]]];
    closed = Complement[
      Select[Flatten[Table[{{{i, j}, {i + 1, j}}, {{i, j}, {i, j + 1}}}, {i, n}, {j, n}], 2], Max[#] <= n &],
      open];
    open = Join[open, RandomSample[closed, Min[OptionValue["Loops"], Length[closed]]]];

    m = ConstantArray[1., {n cell + wall, n cell + wall}];
    Do[m[[(i - 1) cell + wall + 1 ;; i cell, (j - 1) cell + wall + 1 ;; j cell]] = 0., {i, n}, {j, n}];
    carve[{a_, b_}] := If[a[[1]] == b[[1]],
      m[[(a[[1]] - 1) cell + wall + 1 ;; a[[1]] cell, a[[2]] cell + 1 ;; a[[2]] cell + wall]] = 0.,
      m[[a[[1]] cell + 1 ;; a[[1]] cell + wall, (a[[2]] - 1) cell + wall + 1 ;; a[[2]] cell]] = 0.];
    Scan[carve, open];
    Image[m]
  ],
  RandomSeeding -> OptionValue[RandomSeeding]
];

(* ::Section:: *)
(* PhysarumFlow: the Tero et al. current-reinforcement model

   Protoplasm flows through a network of tubes. Each step:
     1. one food source pumps in flux I0, the other food sources drain it (Kirchhoff's laws
        give the pressures p from a weighted graph Laplacian);
     2. every tube's flow is Q = D/L (p_i - p_j);
     3. conductivities adapt: dD/dt = f(|Q|) - D. Busy tubes thicken, idle tubes wither.
   With two food sources and f(Q) = |Q| only the shortest path survives (Tero et al., J. Theor.
   Biol. 244, 2007). With many food sources and a sigmoidal f the result is a robust transport
   network (Tero et al., Science 327, 2010). *)

Options[PhysarumFlow] = {
  "Steps" -> Automatic,
  "Flux" -> 2,
  "Exponent" -> Automatic,
  "TimeStep" -> 0.3,
  "Threshold" -> 0.01,
  "Resolution" -> 50,
  "Output" -> Automatic,
  ImageSize -> 400,
  RandomSeeding -> Automatic
};

incidence[pairs_, nv_] := With[{m = Length[pairs]},
  SparseArray[Join[
    Thread[Transpose[{Range[m], pairs[[All, 1]]}] -> 1.],
    Thread[Transpose[{Range[m], pairs[[All, 2]]}] -> -1.]], {m, nv}]];

(* conductivity vectors over time *)
teroHistory[b_, len_, food_, steps_, flux_, gamma_, dt_] := Module[
  {nv = Last[Dimensions[b]], k = Length[food], f, step, bt = Transpose[b]},
  f = Which[
    gamma === Automatic && k == 2, Abs,
    gamma === Automatic, (Abs[#]^1.8 / (1 + Abs[#]^1.8)) &,
    True, (Abs[#]^gamma / (1 + Abs[#]^gamma)) &];
  step[d_] := Module[{src, sinks, rhs, keep, lap, p = ConstantArray[0., nv], q},
    src = If[k == 2, food[[1]], RandomChoice[food]];
    sinks = DeleteCases[food, src];
    rhs = ConstantArray[0., nv];
    rhs[[src]] = flux; rhs[[sinks]] = -flux / Length[sinks];
    keep = Delete[Range[nv], First[sinks]];   (* ground one sink: p = 0 *)
    lap = bt . SparseArray[Band[{1, 1}] -> d / len, {Length[d], Length[d]}] . b;
    p[[keep]] = LinearSolve[lap[[keep, keep]] + 10.^-9 IdentityMatrix[nv - 1, SparseArray], rhs[[keep]]];
    q = (d / len) (b . p);
    d + dt (f[q] - d)
  ];
  NestList[step, ConstantArray[1., Length[len]], steps]
];

flowSteps[steps_, k_] := Replace[steps, Automatic :> If[k == 2, 200, 600]];

frameIndices[n_] := DeleteDuplicates[Round[Subdivide[1, n, Min[n - 1, 40]]]];

$tubeColor = RGBColor[1., 0.82, 0.15];
$foodColor = RGBColor[0.9, 0.2, 0.25];

(* --- general graphs --- *)

PhysarumFlow[g_?GraphQ, food_List, opts : OptionsPattern[]] := Catch[
  Module[{v = VertexList[g], e = EdgeList[g], idx, pairs, fi, len, coords, hist, steps},
    idx = AssociationThread[v -> Range[Length[v]]];
    fi = DeleteDuplicates @ Lookup[idx, food, Nothing];
    If[Length[fi] < 2, Message[PhysarumFlow::food]; Throw[$Failed, $tag]];
    pairs = Map[idx, List @@@ e, {2}];
    (* tube lengths: edge weights, else explicit vertex coordinates (never an automatic
       layout, which has no physical meaning), else 1 *)
    coords = If[MatchQ[Options[g, VertexCoordinates], {VertexCoordinates -> Automatic} | {}], None,
      Quiet @ GraphEmbedding[g]];
    len = Which[
      WeightedGraphQ[g], N @ PropertyValue[g, EdgeWeight],
      MatrixQ[coords, NumericQ], EuclideanDistance @@ coords[[#]] & /@ pairs,
      True, ConstantArray[1., Length[e]]];
    steps = flowSteps[OptionValue["Steps"], Length[fi]];
    hist = BlockRandom[
      teroHistory[incidence[pairs, Length[v]], len, fi, steps, OptionValue["Flux"],
        OptionValue["Exponent"], OptionValue["TimeStep"]],
      RandomSeeding -> OptionValue[RandomSeeding]];
    flowGraphOutput[g, e, v[[fi]], hist, OptionValue["Threshold"], Replace[OptionValue["Output"], Automatic -> "Graph"]]
  ],
  $tag
];

flowGraph[g_, e_, food_, d_, thr_] := Module[{top = Max[d, $MachineEpsilon], keep, sub},
  keep = Pick[Range[Length[e]], UnitStep[d - thr top], 1];
  sub = Graph[Union[VertexList[EdgeList[g][[keep]]], food], e[[keep]],
    VertexCoordinates -> Thread[# -> PropertyValue[{g, #}, VertexCoordinates] & /@ Union[VertexList[EdgeList[g][[keep]]], food]]];
  Graph[sub,
    Properties -> Thread[e[[keep]] -> ({"Conductivity" -> #} & /@ d[[keep]])],
    EdgeStyle -> Thread[e[[keep]] -> (Directive[$tubeColor, CapForm["Round"], AbsoluteThickness[0.5 + 6 #/top]] & /@ d[[keep]])],
    VertexSize -> Append[(# -> {"Scaled", 0.025}) & /@ food, {"Scaled", 0.002}],
    VertexStyle -> Append[Thread[food -> $foodColor], $tubeColor],
    VertexShapeFunction -> Append[(# -> "Circle") & /@ food, None],
    Background -> GrayLevel[0.08]]
];

flowGraphOutput[g_, e_, food_, hist_, thr_, out_] := Switch[out,
  "Conductivity", AssociationThread[e -> Last[hist]],
  "History", hist,
  "Frames", flowGraph[g, e, food, hist[[#]], thr] & /@ frameIndices[Length[hist]],
  _, flowGraph[g, e, food, Last[hist], thr]
];

(* --- food points in the plane: grow on a lattice with diagonals --- *)

PhysarumFlow[pts_?pointsQ, opts : OptionsPattern[]] := Catch[
  Module[{p = N[pts], lo, hi, pad, res, nx, ny, grid, g, near, food},
    {lo, hi} = {Min /@ Transpose[p], Max /@ Transpose[p]};
    pad = 0.08 Max[hi - lo]; {lo, hi} = {lo - pad, hi + pad};
    res = OptionValue["Resolution"];
    {nx, ny} = Max[2, #] & /@ Round[res (hi - lo) / Max[hi - lo]];
    grid = Flatten[Table[lo + (hi - lo) {i/(nx - 1), j/(ny - 1)}, {j, 0, ny - 1}, {i, 0, nx - 1}], 1];
    g = NearestNeighborGraph[grid, {All, 1.01 Sqrt[2] Max[(hi - lo) / ({nx, ny} - 1)]}];
    near = Nearest[grid -> Automatic];
    food = DeleteDuplicates[VertexList[g][[First[near[#]]]] & /@ p];
    PhysarumFlow[Graph[g, VertexCoordinates -> grid], food, opts]
  ],
  $tag
];

(* --- mazes: every free pixel is a node, 4-neighbours are tubes --- *)

PhysarumFlow[maze_Image, food_?pointsQ, opts : OptionsPattern[]] := Catch[
  Module[{m, h, w, free, nv, idx, pairs, b, near, fi, hist, render, out},
    m = UnitStep[gray[maze] - 0.5];
    {h, w} = Dimensions[m];
    free = Position[m, 0];
    nv = Length[free];
    idx = Normal @ SparseArray[free -> Range[nv], {h, w}];
    pairs = Select[Join[
        Transpose[{Flatten[idx[[All, ;; -2]]], Flatten[idx[[All, 2 ;;]]]}],
        Transpose[{Flatten[idx[[;; -2]]], Flatten[idx[[2 ;;]]]}]],
      Min[#] > 0 &];
    b = incidence[pairs, nv];
    near = Nearest[N[free] -> Automatic];
    fi = DeleteDuplicates[First[near[{(1 - #[[2]]) h + 0.5, #[[1]] w + 0.5}]] & /@ N[food]];
    If[Length[fi] < 2, Message[PhysarumFlow::food]; Throw[$Failed, $tag]];
    hist = BlockRandom[
      teroHistory[b, ConstantArray[1., Length[pairs]], fi, flowSteps[OptionValue["Steps"], Length[fi]],
        OptionValue["Flux"], OptionValue["Exponent"], OptionValue["TimeStep"]],
      RandomSeeding -> OptionValue[RandomSeeding]];

    render[d_] := Module[{node, tube, foodMask, px},
      node = (Abs[Transpose[b]] . d) / 2;
      tube = Normal @ SparseArray[free -> Clip[node / Max[node, $MachineEpsilon], {0, 1}]^0.5, {h, w}];
      foodMask = Normal @ SparseArray[free[[fi]] -> ConstantArray[1., Length[fi]], {h, w}];
      px = TensorProduct[m, {0.35, 0.35, 0.4}] + TensorProduct[tube (1 - foodMask), rgb[$tubeColor]] +
        TensorProduct[foodMask, rgb[$foodColor]] + TensorProduct[(1 - m) (1 - tube), {0.06, 0.05, 0.04}];
      ImageResize[Image[Clip[px, {0, 1}]], Round[OptionValue[ImageSize] {1, h/w}], Resampling -> "Nearest"]
    ];
    out = Replace[OptionValue["Output"], Automatic -> "Image"];
    Switch[out,
      "Frames", render[hist[[#]]] & /@ frameIndices[Length[hist]],
      "History", hist,
      "Conductivity", AssociationThread[UndirectedEdge @@@ Map[free[[#]] &, pairs, {2}] -> Last[hist]],
      _, render[Last[hist]]
    ]
  ],
  $tag
];

End[];
EndPackage[];
