module

import LeanUpdate.GH
public import Lake.Load.Manifest
import LeanUpdate.Input

open Lean Lake Std System

/-- Run the dependency checker command. -/
public def runFindDependencies : IO Unit := do
  let targetLakePackageDir ← getTargetLakePackageDirectory
  let manifestFilePath := targetLakePackageDir / "lake-manifest.json"
  let manifest ← Lake.Manifest.load manifestFilePath
  let packageNames := manifest.packages
    |>.map fun package => package.name.toString (escape := false)
  let hasDep : Bool := !packageNames.isEmpty
  if hasDep then
    IO.println s!"The repository has some dependencies: {packageNames}"
    GH.writeOutput "has_dependency" "true"
    GH.writeGHEnv "HAS_DEPENDENCY" "true"
  else
    IO.println "The repository has no dependencies."
    GH.writeOutput "has_dependency" "false"
    GH.writeGHEnv "HAS_DEPENDENCY" "false"
