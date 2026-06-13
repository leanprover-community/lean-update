module

public import Lean
import Std.Time.Format
public import Std.Time.Zoned
public import Lake.Util.Version
public meta import Lake.Util.Version

open IO Process Lean Std Time

/-- kind of Lean release -/
public inductive ReleaseKind where
  /-- tagged release, such as `v4.30.0` or `v4.31.0-rc2` -/
  | tagged
  /-- nightly release -/
  | nightly
deriving Repr

instance : ToString ReleaseKind where
  toString
    | .tagged => "tagged"
    | .nightly => "nightly"

/-- Lean release including nightly -/
public structure LeanRelease where
  kind : ReleaseKind
  name : String
  createdAt : ZonedDateTime
deriving Repr

/-- Lean's tagged release -/
public structure LeanTaggedRelease where
  name : Lake.StdVer
  createdAt : ZonedDateTime
deriving Repr

def LeanTaggedRelease.toLeanRelease (tagged : LeanTaggedRelease) : LeanRelease :=
  { kind := .tagged, name := tagged.name.toString, createdAt := tagged.createdAt }

def dropRedundantField (json : Json) : Except String Json := do
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
public def fetchAllLeanReleaseJson (kind : ReleaseKind) : IO Json := do
  match kind with
  | .nightly =>
    let fetchUrl := "https://release.lean-lang.org/"
    let out ← IO.Process.output {
      cmd := "curl",
      args := #["-fsSL", fetchUrl],
    }
    let outStr := out.stdout.trimAscii.copy
    if out.exitCode != 0 then
      throw <| IO.userError s!"Failed to fetch release info from {fetchUrl}: {outStr}"
    let json ← IO.ofExcept <| Json.parse outStr
    let nightlyJson ← IO.ofExcept <| json.getObjVal? "nightly"
    let simpleJson ← IO.ofExcept <| dropRedundantField nightlyJson
    return simpleJson
  | .tagged =>
    let out ← IO.Process.output {
      cmd := "gh",
      args := #["release", "list", "--repo", "leanprover/lean4", "--limit", "1000", "--json", "name,createdAt"],
    }
    let outStr := out.stdout.trimAscii.copy
    if out.exitCode != 0 then
      throw <| IO.userError s!"Failed to fetch release info from GitHub: {outStr}"
    let json ← IO.ofExcept <| Json.parse outStr
    return json

def parseLeanReleaseJson (json : Json) : Except String (Array LeanRelease) := do
  let arr ← json.getArr?
  arr.mapM fun item => do
    let name ← item.getObjValAs? String "name"
    let createdAtStr ← item.getObjValAs? String "createdAt"
    let createdAt ← ZonedDateTime.fromISO8601String createdAtStr
    let kind := if name.startsWith "nightly-" then .nightly else .tagged
    pure { kind, name, createdAt }

open Lake

def filterLeanReleaseByTime (releases : Array LeanRelease) (cutoff? : Option ZonedDateTime) : Array LeanRelease :=
  match cutoff? with
  | some cutoff => releases.filter fun release => release.createdAt.toTimestamp ≤ cutoff.toTimestamp
  | none => releases

/-- parse `name` part of LeanRelease.
This function is only for tagged releases. -/
def parseLeanTagVersion (s : String) : Except String StdVer :=
  StdVer.parse (if s.startsWith "v" then (s.drop 1).copy else s)

-- test for `parseLeanTagVersion`
#eval show IO Unit from do
  let verRc ← IO.ofExcept <| parseLeanTagVersion "v4.31.0-rc2"
  let verStable ← IO.ofExcept <| parseLeanTagVersion "4.31.0"
  if verRc > verStable then
    throw <| IO.userError s!"Unexpected version order: {verRc} should not be newer than {verStable}"

def LeanRelease.toTagged (leanRelease : LeanRelease) : Except String LeanTaggedRelease := do
  match leanRelease.kind with
  | .tagged =>
    let version ← parseLeanTagVersion leanRelease.name
    pure { name := version, createdAt := leanRelease.createdAt }
  | .nightly =>
    throw s!"Cannot convert nightly release '{leanRelease.name}' to tagged release"

/--
Get the latest Lean release of the given `kind : ReleaseKind`.

Argument `now` is used for test purposes.
This function return the latest release which is not newer than `now` if `now` is given.
-/
public def getLatestLeanRelease (kind : ReleaseKind) (now? : Option ZonedDateTime := none) : IO LeanRelease := do
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

private def testForGetLatestLeanRelease (kind : ReleaseKind) (now expected : String) : IO Unit := do
  let nowZdt ← IO.ofExcept <| ZonedDateTime.fromISO8601String now
  let latest ← getLatestLeanRelease kind (some nowZdt)
  if latest.name != expected then
    throw <| IO.userError s!"Expected latest {kind} release to be '{expected}', got {latest.name}"

#eval testForGetLatestLeanRelease .nightly "2026-06-13T00:00:00Z" "nightly-2026-06-10"

#eval testForGetLatestLeanRelease .tagged "2026-04-15T00:00:00Z" "4.30.0-rc1"

#eval testForGetLatestLeanRelease .tagged "2026-06-13T00:00:00Z" "4.31.0-rc2"

#eval testForGetLatestLeanRelease .tagged "2025-12-07T00:00:00Z" "4.26.0-rc2"

public def main : IO Unit := do
  sorry
