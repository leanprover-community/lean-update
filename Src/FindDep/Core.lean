module

public import Lean
import Src.GH

open Lean Std System

/-- detect if a JSON object has a nonempty array or object at the given key -/
public def jsonHasNonemptyValue (json : Json) (key : String) : Bool :=
  match json.getObjVal? key with
  | .ok (.arr arr) => !arr.isEmpty
  | .ok (.obj obj) => !obj.isEmpty
  | _ => false

private def exampleManifestStr.noDep : String := r#"
  {"version": "1.1.0",
  "packagesDir": ".lake/packages",
  "packages": [],
  "name": "SmokeSuccess",
  "lakeDir": ".lake"}
"#

#guard
  let result : Except String Bool := do
    let json ← Json.parse exampleManifestStr.noDep
    return ! jsonHasNonemptyValue json "packages"
  result.toOption.getD false

/-- read and parse the `lake-manifest.json` file -/
public def readLakeManifestFile (manifestPath : FilePath) : IO Lean.Json := do
  let raw ← IO.FS.readFile manifestPath
  match Json.parse raw with
  | .ok json => pure json
  | .error err => throw <| IO.userError s!"Failed to parse JSON: {err}"

/-- extract dependency package names from a parsed `lake-manifest.json` -/
public def getLakeManifestDependencyNames (json : Json) : Except String (Array String) := do
  let packagesJson ← json.getObjVal? "packages"
  let packages ←
    match packagesJson with
    | .arr packages => pure packages
    | _ => throw "`packages` must be an array"
  packages.mapM fun packageJson => do
    match packageJson.getObjVal? "name" with
    | .ok (.str name) => pure name
    | .ok _ => throw "package `name` must be a string"
    | .error err => throw s!"package is missing `name`: {err}"

private def exampleManifestStr.hasDep : String := r#"
  {"version": "1.2.0",
  "packagesDir": ".lake/packages",
  "packages":
  [{"url": "https://github.com/leanprover-community/plausible",
    "type": "git",
    "subDir": null,
    "scope": "",
    "rev": "744117af710b1c0400cd297c9ce91f8d0ad3a347",
    "name": "plausible",
    "manifestFile": "lake-manifest.json",
    "inputRev": "main",
    "inherited": false,
    "configFile": "lakefile.toml"}],
  "name": "HasDep",
  "lakeDir": ".lake",
  "fixedToolchain": false}
"#

#guard
  let result : Except String Bool := do
    let json ← Json.parse exampleManifestStr.hasDep
    return jsonHasNonemptyValue json "packages"
  result.toOption.getD false

#guard
  let result : Except String Bool := do
    let json ← Json.parse exampleManifestStr.hasDep
    let packages ← getLakeManifestDependencyNames json
    return packages == #["plausible"]
  result.toOption.getD false

private def exampleManifestStr.twoDeps : String := r#"
{"version": "1.2.0",
 "packagesDir": ".lake/packages",
 "packages":
 [{"url": "https://github.com/Seasawher/mdgen",
   "type": "git",
   "subDir": null,
   "scope": "Seasawher",
   "rev": "c003ac1229883b25d3b9e5df2fc0b2da453d3c8a",
   "name": "mdgen",
   "manifestFile": "lake-manifest.json",
   "inputRev": "main",
   "inherited": false,
   "configFile": "lakefile.lean"},
  {"url": "https://github.com/leanprover/lean4-cli.git",
   "type": "git",
   "subDir": null,
   "scope": "",
   "rev": "baf3e62fbb3502305076ca077e004aea78157c63",
   "name": "Cli",
   "manifestFile": "lake-manifest.json",
   "inputRev": "main",
   "inherited": true,
   "configFile": "lakefile.toml"}],
 "name": "TwoDeps",
 "lakeDir": ".lake",
 "fixedToolchain": false}
"#

#guard
  let result : Except String Bool := do
    let json ← Json.parse exampleManifestStr.twoDeps
    let packages ← getLakeManifestDependencyNames json
    return packages == #["mdgen", "Cli"]
  result.toOption.getD false
