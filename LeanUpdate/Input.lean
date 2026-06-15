module

public meta import LeanUpdate.Deriving.ToString

/-- The kind of Lean release -/
public inductive ReleaseKindToFetch where
  /-- tagged release, such as `v4.30.0` or `v4.31.0-rc2` -/
  | tagged
  /-- nightly release -/
  | nightly
deriving Repr, BEq, ToString

#guard toString ReleaseKindToFetch.tagged == "tagged"
#guard toString ReleaseKindToFetch.nightly == "nightly"

/-- parse a string into a `ReleaseKindToFetch` -/
public def ReleaseKindToFetch.parse (s : String) : Except String ReleaseKindToFetch :=
  match s.toLower with
  | "tagged" => .ok .tagged
  | "nightly" => .ok .nightly
  | _ => throw s!"Invalid release kind: '{s}'. Allowed values are 'tagged' and 'nightly'."

/-- get the release kind to fetch from the environment variable `RELEASE_KIND_TO_FETCH`. -/
public def getReleaseKindToFetch : IO ReleaseKindToFetch := do
  match (← IO.getEnv "RELEASE_KIND_TO_FETCH") with
  | .some kindStr => IO.ofExcept <| ReleaseKindToFetch.parse kindStr
  | .none => pure .tagged -- default value for local testing
