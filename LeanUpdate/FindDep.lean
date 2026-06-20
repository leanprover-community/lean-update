module

import LeanUpdate.GitHub.Action.Env
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
    GitHub.Action.writeGHOutput "has_dependency" "true"
    GitHub.Action.writeGHEnv "HAS_DEPENDENCY" "true"
  else
    IO.println "The repository has no dependencies."
    GitHub.Action.writeGHOutput "has_dependency" "false"
    GitHub.Action.writeGHEnv "HAS_DEPENDENCY" "false"
