module

public import Lean
import Src.GH

open Lean

/-- detect if a JSON object has a nonempty array or object at the given key -/
public def jsonHasNonemptyValue (json : Json) (key : String) : Bool :=
  match json.getObjVal? key with
  | .ok (.arr arr) => !arr.isEmpty
  | .ok (.obj obj) => !obj.isEmpty
  | _ => false

/-- read and parse the `lake-manifest.json` file -/
public def readLakeManifestFile (manifestPath : System.FilePath) : IO Lean.Json := do
  let raw ← IO.FS.readFile manifestPath
  match Json.parse raw with
  | .ok json => pure json
  | .error err => throw <| IO.userError s!"Failed to parse JSON: {err}"

def getLakePackageDir : IO String := do
  match (← IO.getEnv "LAKE_PACKAGE_DIRECTORY") with
  | .some path => pure path
  | .none =>
    -- for local testing
    pure "."

/-- executable entry point for the dependency checker -/
public def main : IO Unit := do
  let lakePackageDir ← getLakePackageDir
  let manifestFilePath := s!"{lakePackageDir}/lake-manifest.json"
  let manifestJson ← readLakeManifestFile manifestFilePath

  let hasDep : Bool := jsonHasNonemptyValue manifestJson "packages"
  if hasDep then
    IO.println "The repository has some dependencies."
    GH.writeOutput "outcome" "has-dependency"
  else
    IO.println "The repository has no dependencies."
    GH.writeOutput "outcome" "no-dependency"
