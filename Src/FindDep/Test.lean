module

public import Src.Env
public import Src.FindDep.Core

deprecated_module "This file is for test only, don't import this" (since := "YYYY-MM-DD")

open Std System

def testForGetLakeManifestDependencyNames (manifestPath : FilePath) (expect : Array String) : IO Unit := do
  let json ← readLakeManifestFile manifestPath
  let packages ← IO.ofExcept <| getLakeManifestDependencyNames json
  if packages != expect then
    throw <| IO.userError s!"Expected package names {expect}, got {packages}"

/-- run test -/
public def main : IO Unit := do
  testForGetLakeManifestDependencyNames "test/HasDep/lake-manifest.json" #["plausible"]
  testForGetLakeManifestDependencyNames "test/TwoDeps/lake-manifest.json" #["mdgen", "Cli"]
