module

public import Src.Env
public meta import Src.FindDep

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
