(* Build documentation for the ArnoudBuzing/Physarum paclet:
   1. Generates authoring notebooks from docs/*.md using MarkdownToNotebook
      ("Evaluate" -> False so examples remain unevaluated inputs, ShowAutoSpellCheck -> False).
   2. Builds and indexes the documentation notebooks with PacletDocumentationBuild / PacletBuild
      so they are styled and searchable in the Documentation Center.

   Run with:
     /Applications/Wolfram/15.0/Wolfram.app/Contents/MacOS/wolfram -script scripts/build-docs.wl *)

rootDir = DirectoryName[$InputFileName, 2];
pacletDir = FileNameJoin[{rootDir, "Physarum"}];
docDir = FileNameJoin[{pacletDir, "Documentation", "English"}];

Get[FileNameJoin[{rootDir, "scripts", "MarkdownToNotebook.wl"}]];
Needs["PacletTools`"];
Needs["DocumentationBuild`"];

(* Override InternalAssetsDirectory so it does not fail looking for internal WRI files in ~/DocumentationAssets *)
DocumentationBuild`Internal`InternalAssetsDirectory[] = None;

subdir["Symbol"] = {"ReferencePages", "Symbols"};
subdir["Guide"] = {"Guides"};
subdir["TechNote"] = {"Tutorials"};

mdFiles = Select[
  Sort @ FileNames["*.md", FileNameJoin[{rootDir, "docs"}]],
  FileBaseName[#] =!= "README" &
];

Print["Converting ", Length[mdFiles], " markdown docs into Physarum/Documentation/..."];

Do[
  Module[{info, tmpl, name, targetDir, targetNb, nb},
    info = MarkdownToNotebook[f, "Association", "Evaluate" -> False];
    tmpl = info["Template"];
    name = Lookup[info["Metadata"], "Name", FileBaseName[f]];
    targetDir = FileNameJoin[Join[{docDir}, subdir[tmpl]]];
    Quiet @ CreateDirectory[targetDir, CreateIntermediateDirectories -> True];
    targetNb = FileNameJoin[{targetDir, name <> ".nb"}];
    nb = MarkdownToNotebook[f, "Evaluate" -> False];
    nb = Append[DeleteCases[nb, (ShowAutoSpellCheck -> _)], ShowAutoSpellCheck -> False];
    Export[targetNb, nb];
    Print["  ", FileNameTake[f], " (", tmpl, ") -> ", StringReplace[targetNb, pacletDir <> "/" -> ""]];
  ],
  {f, mdFiles}
];

Print["\nBuilding and indexing documentation with PacletBuild..."];
buildDir = FileNameJoin[{rootDir, "build", "paclet"}];
Quiet @ DeleteDirectory[buildDir, DeleteContents -> True];

res = UsingFrontEnd @ PacletBuild[pacletDir, buildDir];
Print["PacletBuild result: ", res];

(* Ensure ShowAutoSpellCheck -> False on all built notebooks in buildDir as well *)
Do[
  With[{nb = Get[nbFile]},
    If[Head[nb] === Notebook,
      Export[nbFile, Append[DeleteCases[nb, (ShowAutoSpellCheck -> _)], ShowAutoSpellCheck -> False]]
    ]
  ],
  {nbFile, FileNames["*.nb", buildDir, Infinity]}
];

(* Copy the built notebooks and search indexes into Physarum/Documentation/English so local PacletDirectoryLoad and paclet archiving have full built documentation *)
builtDoc = FileNameJoin[{buildDir, "ArnoudBuzing__Physarum", "Documentation", "English"}];
If[DirectoryQ[builtDoc],
  (* Copy built symbol notebooks *)
  Do[
    CopyFile[f, FileNameJoin[{docDir, "ReferencePages", "Symbols", FileNameTake[f]}], OverwriteTarget -> True],
    {f, FileNames["*.nb", FileNameJoin[{builtDoc, "ReferencePages", "Symbols"}]]}
  ];
  (* Copy built guide notebook *)
  With[{g = FileNameJoin[{builtDoc, "Guides", "Physarum.nb"}]},
    If[FileExistsQ[g],
      CopyFile[g, FileNameJoin[{docDir, "Guides", "Physarum.nb"}], OverwriteTarget -> True]
    ]
  ];
  Print["  Installed built documentation notebooks (Reference.nb)"];
  (* Copy indexes *)
  Do[
    With[{src = FileNameJoin[{builtDoc, idx}], dst = FileNameJoin[{docDir, idx}]},
      If[FileExistsQ[src],
        Quiet @ DeleteDirectory[dst, DeleteContents -> True];
        Quiet @ DeleteFile[dst];
        CopyDirectory[src, dst];
        Print["  Installed index: ", idx];
      ]
    ],
    {idx, {"Index", "SearchIndex", "SpellIndex"}}
  ]
];

Print["Done! Documentation notebooks and search indexes are built."];
