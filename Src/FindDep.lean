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

/-- executable entry point for the dependency checker -/
public def main : IO Unit := do
  let lakePackageDir ← getLakePackageDir
  let manifestFilePath := lakePackageDir / "lake-manifest.json"
  let json ← readLakeManifestFile manifestFilePath
  let packageNames ← IO.ofExcept <| getLakeManifestDependencyNames json
  let hasDep : Bool := !packageNames.isEmpty
  if hasDep then
    IO.println s!"The repository has some dependencies: {packageNames}"
    GH.writeOutput "has_dependency" "true"
  else
    IO.println "The repository has no dependencies."
    GH.writeOutput "has_dependency" "false"
