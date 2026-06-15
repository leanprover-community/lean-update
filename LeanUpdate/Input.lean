module

public meta import LeanUpdate.Deriving.ToString
public meta import LeanUpdate.Deriving.HasParser
public meta import LeanUpdate.Deriving.Wrapper
public import LeanUpdate.HasParser
public import LeanUpdate.Wrapper
public import LeanUpdate.ActionInput
import LeanUpdate.Env

open System

/-- The kind of Lean release -/
public inductive ReleaseKindToFetch where
  /-- tagged release, such as `v4.30.0` or `v4.31.0-rc2` -/
  | tagged
  /-- nightly release -/
  | nightly
deriving Repr, BEq, ToString, HasParser

public instance : ActionInput ReleaseKindToFetch where
  envName := "RELEASE_KIND_TO_FETCH"
  parse := parseAs ReleaseKindToFetch
  localValue? := some .tagged

/-- The directory of the target Lake package. This is a wrapper around `FilePath`. -/
public structure LakePackageDirectory where
  /-- the raw path supplied by the action input -/
  val : FilePath
deriving Wrapper

public instance : ActionInput LakePackageDirectory where
  envName := "LAKE_PACKAGE_DIRECTORY"
  parse := parseAs LakePackageDirectory
  localValue? := some ⟨FilePath.mk "."⟩

/-- resolve a Lake package directory relative to the GitHub workspace when available -/
public def resolveLakePackageDir (workspace? : Option FilePath) (packageDir : FilePath) : FilePath :=
  if packageDir.isRelative then
    match workspace? with
    | .some workspace => workspace / packageDir
    | .none => packageDir
  else
    packageDir

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

/-- resolve the target Lake package directory supplied by the action input. -/
public def getTargetLakePackageDirectory : IO FilePath := do
  let packageDir ← Input.get LakePackageDirectory
  let workspace? := (← IO.getEnv "GITHUB_WORKSPACE").map FilePath.mk
  pure <| resolveLakePackageDir workspace? packageDir

/-- The input whether to update the `lean-toolchain` file. -/
public inductive UpdateLeanToolchain where
  | auto
  | never
deriving ToString, HasParser

public instance : ActionInput UpdateLeanToolchain where
  envName := "UPDATE_LEAN_TOOLCHAIN"
  parse := parseAs UpdateLeanToolchain
  localValue? := some .auto

/-- The input whether to perform a legacy update. This is a wrapper around `Bool`. -/
public structure LegacyUpdate where
  val : Bool
deriving Wrapper

public instance : ActionInput LegacyUpdate where
  envName := "LEGACY_UPDATE"
  parse := parseAs LegacyUpdate
  localValue? := some ⟨false⟩

/-- The input that controls when to trigger updates based on modified files. -/
public inductive UpdateIfModified where
  /-- watch `lean-toolchain` file -/
  | «lean-toolchain»
  /-- watch `lake-manifest.json` file -/
  | «lake-manifest.json»
deriving Repr, BEq, ToString, HasParser

#guard
  let str : List UpdateIfModified := [.«lean-toolchain», .«lake-manifest.json»]
  str.map toString == ["lean-toolchain", "lake-manifest.json"]

#guard parseAs UpdateIfModified "lean-toolchain" |>.isOk
#guard parseAs UpdateIfModified "lake-manifest.json" |>.isOk

public instance : ActionInput UpdateIfModified where
  envName := "UPDATE_IF_MODIFIED"
  parse := parseAs UpdateIfModified
  localValue? := some .«lake-manifest.json»
