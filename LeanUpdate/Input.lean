module

public meta import LeanUpdate.Deriving.ToString
public meta import LeanUpdate.Deriving.HasParser
public meta import LeanUpdate.Deriving.Wrapper
public import LeanUpdate.HasParser
public import LeanUpdate.Wrapper
public import LeanUpdate.GitHub.Action.Input
import LeanUpdate.IO

open System GitHub Action

/-- The kind of Lean release -/
public inductive ReleaseKindToFetch where
  /-- tagged release, such as `v4.30.0` or `v4.31.0-rc2` -/
  | tagged
  /-- nightly release -/
  | nightly
deriving Repr, BEq, ToString, HasParser

public instance : Input ReleaseKindToFetch where
  envName := "RELEASE_KIND_TO_FETCH"
  parse := parseAs ReleaseKindToFetch
  localValue? := some .tagged

/-- The directory of the target Lake package. This is a wrapper around `FilePath`. -/
public structure LakePackageDirectory where
  /-- the raw path supplied by the action input -/
  val : FilePath
deriving Wrapper

public instance : Input LakePackageDirectory where
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
  let packageDir ← GitHub.Action.Input.get LakePackageDirectory
  let workspace? := (← IO.getEnv "GITHUB_WORKSPACE").map FilePath.mk
  pure <| resolveLakePackageDir workspace? packageDir

/-- The input whether to update the `lean-toolchain` file. -/
public inductive UpdateLeanToolchain where
  | auto
  | never
deriving ToString, HasParser

public instance : Input UpdateLeanToolchain where
  envName := "UPDATE_LEAN_TOOLCHAIN"
  parse := parseAs UpdateLeanToolchain
  localValue? := some .auto

/-- The input whether to perform a legacy update. This is a wrapper around `Bool`. -/
public structure LegacyUpdate where
  val : Bool
deriving Wrapper

public instance : Input LegacyUpdate where
  envName := "LEGACY_UPDATE"
  parse := parseAs LegacyUpdate
  localValue? := some ⟨false⟩

/-- Split the `build_args` action input into arguments for `lake build`. -/
public def splitBuildArgs (buildArgs : String) : Array String :=
  buildArgs
    |>.replace "\n" " "
    |>.replace "\t" " "
    |>.splitOn " "
    |>.filter (fun arg => !arg.isEmpty)
    |> List.toArray

#guard
  let actual := splitBuildArgs "  --log-level=warning  \nFoo\tBar  "
  let expected := #["--log-level=warning", "Foo", "Bar"]
  actual == expected

/-- The arguments passed to `lake build` during post-update validation. -/
public structure BuildArgs where
  /-- the raw arguments after splitting on ASCII whitespace -/
  val : Array String

public instance : Input BuildArgs where
  envName := "BUILD_ARGS"
  parse s := .ok ⟨splitBuildArgs s⟩
  localValue? := some ⟨#["--log-level=warning"]⟩

/-- The input that controls when to trigger updates based on modified files. -/
public inductive UpdateIfModified where
  /-- watch `lean-toolchain` file -/
  | «lean-toolchain»
  /-- watch `lake-manifest.json` file -/
  | «lake-manifest.json»
deriving Repr, BEq, ToString, HasParser

#guard
  let lst : List UpdateIfModified := [.«lean-toolchain», .«lake-manifest.json»]
  lst.map toString == ["lean-toolchain", "lake-manifest.json"]

#guard
  let lst : List String := ["lean-toolchain", "lake-manifest.json"]
  let result := lst
    |>.map (parseAs UpdateIfModified ·)
    |>.map Except.isOk
    |>.all id
  result

public instance : Input UpdateIfModified where
  envName := "UPDATE_IF_MODIFIED"
  parse := parseAs UpdateIfModified
  localValue? := some .«lake-manifest.json»
