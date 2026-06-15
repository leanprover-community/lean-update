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
  parse := ReleaseKindToFetch.parse
  localValue? := some .tagged

/-- The directory of the target Lake package. This is a wrapper around `FilePath`. -/
public structure LakePackageDirectory where
  /-- the raw path supplied by the action input -/
  val : FilePath
deriving Wrapper

public instance : ActionInput LakePackageDirectory where
  envName := "LAKE_PACKAGE_DIRECTORY"
  parse := fun s => .ok ⟨FilePath.mk s⟩
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
public def resolveTargetLakePackageDirectory : IO FilePath := do
  let packageDir ← Input.get LakePackageDirectory
  let workspace? := (← IO.getEnv "GITHUB_WORKSPACE").map FilePath.mk
  pure <| resolveLakePackageDir workspace? packageDir

/-- The input whether to update the `lean-toolchain` file. This is a wrapper around `Bool`. -/
public structure UpdateLeanToolchain where
  val : Bool
deriving Wrapper

public instance : ActionInput UpdateLeanToolchain where
  envName := "UPDATE_LEAN_TOOLCHAIN"
  parse := fun s => do
    let b ← Bool.parse s
    pure ⟨b⟩
  localValue? := some ⟨true⟩
