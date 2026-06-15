module

public import Lean
import LeanUpdate.GH
import LeanUpdate.FindDep.Core

open Lean Std System

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
