module

public import Src.Env
public meta import Src.FindDep

deprecated_module "This file is for test only, don't import this" (since := "YYYY-MM-DD")

open Std System

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
