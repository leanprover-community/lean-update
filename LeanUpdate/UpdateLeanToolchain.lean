module

import LeanUpdate.IO
import LeanUpdate.GitHub.Action.Env
public meta import LeanUpdate.Input
public import LeanUpdate.Input
import Std.Time.Format
public meta import Lake.Util.Version
public import Lake.Util.Version
public import Std.Time
public import LeanUpdate.Terminal

open IO Process Lean Std Time

/-- Lean release including nightly -/
public structure LeanRelease where
  kind : ReleaseKindToFetch
  name : String
  createdAt : DateTime

/-- Lean's tagged release -/
public structure LeanTaggedRelease where
  name : Lake.StdVer
  createdAt : DateTime
deriving Repr

instance : Inhabited LeanTaggedRelease where
  default := { name := default, createdAt := default }

/-- Convert a Lean release to the toolchain version string. -/
public protected def LeanRelease.toString (release : LeanRelease) : String :=
  match release.kind with
  | .tagged => "v" ++ release.name
  | .nightly => release.name

def LeanTaggedRelease.toLeanRelease (tagged : LeanTaggedRelease) : LeanRelease :=
  { kind := .tagged, name := tagged.name.toString, createdAt := tagged.createdAt }

#guard
  let release : LeanRelease := { kind := .nightly, name := "nightly-2021-02-18", createdAt := default }
  release.toString == "nightly-2021-02-18"

#guard
  let release : LeanRelease := { kind := .tagged, name := "4.31.0-rc2", createdAt := default }
  release.toString == "v4.31.0-rc2"

def normalizeNightlyJson (json : Json) : Except String Json := do
  let arr ← json.getArr?
  let arr' ← arr.mapM fun item => do
    let name ← item.getObjValAs? String "name"
    let createdAt ← item.getObjValAs? String "created_at"
    pure <| Json.mkObj [
      ("name", Json.str name),
      ("createdAt", Json.str createdAt)
    ]
  pure <| Json.arr arr'

/-- get all Lean releases as JSON.
`kind` specifies the type of release to fetch -/
public def fetchAllLeanReleaseJson (kind : ReleaseKindToFetch) : IO Json := do
  match kind with
  | .nightly =>
    let fetchUrl := "https://release.lean-lang.org/"
    let out ← IO.Process.output {
      cmd := "curl",
      args := #["-fsSL", fetchUrl],
    }
    let outStr := out.stdout.trimAscii.copy
    if out.exitCode != 0 then
      throw <| IO.userError s!"Failed to fetch release info from {fetchUrl}: \n{out.stderr}"
    let json ← IO.ofExcept <| Json.parse outStr
    let nightlyJson ← IO.ofExcept <| json.getObjVal? "nightly"
    let simpleJson ← IO.ofExcept <| normalizeNightlyJson nightlyJson
    return simpleJson
  | .tagged =>
    let out ← IO.Process.output {
      cmd := "gh",
      args := #["release", "list", "--repo", "leanprover/lean4", "--limit", "50", "--json", "name,createdAt"],
    }
    let outStr := out.stdout.trimAscii.copy
    if out.exitCode != 0 then
      throw <| IO.userError s!"Failed to fetch release info from GitHub: \n{out.stderr}"
    let json ← IO.ofExcept <| Json.parse outStr
    return json

def parseLeanReleaseJson (json : Json) : Except String (Array LeanRelease) := do
  let arr ← json.getArr?
  arr.mapM fun item => do
    let name ← item.getObjValAs? String "name"
    let createdAtStr : String ← item.getObjValAs? String "createdAt"
    let createdAt ← DateTime.fromISO8601String createdAtStr
    let kind := if name.startsWith "nightly-" then .nightly else .tagged
    pure { kind, name, createdAt }

open Lake

def filterLeanReleaseByTime (releases : Array LeanRelease) (cutoff? : Option DateTime) : Array LeanRelease :=
  match cutoff? with
  | some cutoff => releases.filter fun release => release.createdAt.toTimestamp ≤ cutoff.toTimestamp
  | none => releases

/-- parse `name` part of LeanRelease.
This function is only for tagged releases. -/
def parseLeanTagVersion (s : String) : Except String StdVer :=
  StdVer.parse (if s.startsWith "v" then (s.drop 1).copy else s)

-- test for `parseLeanTagVersion`
#guard
  let result : Except String Bool := do
    let verRc ← parseLeanTagVersion "v4.31.0-rc2"
    let verStable ← parseLeanTagVersion "4.31.0"
    return verRc < verStable
  result.toOption.getD false

def LeanRelease.toTagged (leanRelease : LeanRelease) : Except String LeanTaggedRelease := do
  match leanRelease.kind with
  | .tagged =>
    let version ← parseLeanTagVersion leanRelease.name
    pure { name := version, createdAt := leanRelease.createdAt }
  | .nightly =>
    throw s!"Cannot convert nightly release '{leanRelease.name}' to tagged release"

def LeanRelease.toTagged! (leanRelease : LeanRelease) : LeanTaggedRelease :=
  match leanRelease.toTagged with
  | .ok tagged => tagged
  | .error err => panic! s!"Failed to convert LeanRelease '{leanRelease.name}' to tagged release: {err}"

/--
Get the latest Lean release of the given `kind : ReleaseKindToFetch`.

Argument `now` is used for test purposes.
This function return the latest release which is not newer than `now` if `now` is given.
-/
public def getLatestLeanRelease (kind : ReleaseKindToFetch) (now? : Option DateTime := none) : IO LeanRelease := do
  let json ← fetchAllLeanReleaseJson kind
  let releases ← IO.ofExcept <| parseLeanReleaseJson json
  let filteredReleases := filterLeanReleaseByTime releases now?

  if h : filteredReleases.size = 0 then
    throw <| IO.userError s!"No {kind} Lean release found"
  else
    match kind with
    | .nightly => pure filteredReleases[0]
    | .tagged =>
      let taggedReleases ← filteredReleases
        |>.map LeanRelease.toTagged
        |>.mapM IO.ofExcept
      let sortedTaggedReleases := taggedReleases.qsort (fun r1 r2 => r1.name > r2.name)
      if h2 : sortedTaggedReleases.size = 0 then
        throw <| IO.userError s!"No valid tagged Lean release found"
      else
        pure sortedTaggedReleases[0].toLeanRelease

def String.toDateTime! (s : String) : DateTime :=
  match DateTime.fromISO8601String s with
  | .ok dt => dt
  | .error err => panic! s!"Failed to parse '{s}' as DateTime: {err}"

local instance : Coe String DateTime where
  coe s := s.toDateTime!

def exampleTaggedRelease : Array LeanTaggedRelease :=
  let releases : Array LeanRelease := #[
    ⟨.tagged, "v4.28.1", "2026-04-14T12:52:44Z"⟩,
    ⟨.tagged, "v4.29.1", "2026-04-14T12:40:04Z"⟩,
    ⟨.tagged, "v4.30.0-rc1", "2026-04-01T05:19:37Z"⟩,
    ⟨.tagged, "v4.29.0", "2026-03-27T12:45:03Z"⟩,
    ⟨.tagged, "v4.29.0-rc8", "2026-03-24T11:17:09Z"⟩,
  ]
  releases.map LeanRelease.toTagged!

#guard
  let sorted := exampleTaggedRelease.qsort (fun r1 r2 => r1.name > r2.name)
  sorted[0]!.name.toString == "4.30.0-rc1"

/-- Run the `updateLeanToolchain` command.

* This command get the latest Lean release from internet.
  Note that `lake update` command also modifies the `lean-toolchain` file.
  So the resulting `lean-toolchain` file may not be the same as the latest release fetched by this command.
* The command read `UPDATE_LEAN_TOOLCHAIN`.
  If it is set to `never`, this command does nothing. -/
public def runUpdateLeanToolchain : IO Unit := do
  let updateLeanToolchain ← GitHub.Action.Input.get UpdateLeanToolchain

  let releaseKind ← GitHub.Action.Input.get ReleaseKindToFetch
  let latestRelease ← getLatestLeanRelease releaseKind
  IO.println <| log% s!"Latest {releaseKind} Lean release: {latestRelease.toString}"
  GitHub.Action.writeGHOutput "latest_lean" latestRelease.toString
  GitHub.Action.writeGHEnv "LATEST_LEAN" latestRelease.toString

  match updateLeanToolchain with
  | .auto =>
    let targetLakePackageDir ← getTargetLakePackageDirectory
    let leanToolchainFile := targetLakePackageDir / "lean-toolchain"
    IO.FS.writeFile leanToolchainFile s!"leanprover/lean4:{latestRelease.toString}\n"
    IO.println <| log% s!"Updated {leanToolchainFile} with the latest {releaseKind} Lean release."
  | .never =>
    IO.println <| log% "Skipping fetching the latest Lean release and updating lean-toolchain file."
    IO.println <| log% "Skipping setting the output `latest_lean` and environment variable `LEAN_UPDATE_LATEST_LEAN`."
