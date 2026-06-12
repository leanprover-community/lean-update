module

public import Lean
import Src.GH

open Lean Std System

/-- resolve a Lake package directory relative to the GitHub workspace when available -/
public def resolveLakePackageDir (workspace? : Option FilePath) (packageDir : FilePath) : FilePath :=
  if packageDir.isRelative then
    match workspace? with
    | .some workspace => workspace / packageDir
    | .none => packageDir
  else
    packageDir

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

-- test for `test/HasDep`, which has a single dependency on `plausible`
#eval show IO Unit from do
  let json ← readLakeManifestFile "test/HasDep/lake-manifest.json"
  let packages ← IO.ofExcept <| getLakeManifestDependencyNames json
  if packages != #["plausible"] then
    throw <| IO.userError s!"Expected package name `plausible`, got {packages}"

-- test for `test/TwoDeps`, which has two dependencies on `mdgen` and `Cli`
#eval show IO Unit from do
  let json ← readLakeManifestFile "test/TwoDeps/lake-manifest.json"
  let packages ← IO.ofExcept <| getLakeManifestDependencyNames json
  if HashSet.ofArray packages != HashSet.ofArray #["mdgen", "Cli"] then
    throw <| IO.userError s!"Expected package names `mdgen` and `Cli`, got {packages}"

-- test for resolving a relative input path from the GitHub workspace
#guard
  let workspace : FilePath := "/tmp/workspace"
  let packageDir : FilePath := "."
  let resolved := resolveLakePackageDir (.some workspace) packageDir
  resolved == workspace / packageDir

-- test for preserving an absolute input path
#guard
  let workspace : FilePath := "/tmp/workspace"
  let packageDir : FilePath := "/tmp/other"
  let resolved := resolveLakePackageDir (.some workspace) packageDir
  resolved == packageDir

def getLakePackageDir : IO FilePath := do
  let packageDir : FilePath ←
    match (← IO.getEnv "LAKE_PACKAGE_DIRECTORY") with
    | .some path => pure path
    | .none =>
      -- for local testing
      pure "."
  let workspace? := (← IO.getEnv "GITHUB_WORKSPACE").map FilePath.mk
  pure <| resolveLakePackageDir workspace? packageDir

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
