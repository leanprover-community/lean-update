module

public meta import LeanUpdate.Deriving.ToString
public meta import LeanUpdate.Deriving.HasParser
public import LeanUpdate.HasParser

/-- The kind of Lean release -/
public inductive ReleaseKindToFetch where
  /-- tagged release, such as `v4.30.0` or `v4.31.0-rc2` -/
  | tagged
  /-- nightly release -/
  | nightly
deriving Repr, BEq, ToString, HasParser

#guard toString ReleaseKindToFetch.tagged == "tagged"
#guard toString ReleaseKindToFetch.nightly == "nightly"

#guard
  match ReleaseKindToFetch.parse "TAGGED" with
  | .ok .tagged => true
  | _ => false

#guard
  match (HasParser.parse ReleaseKindToFetch "nightly" : Except String ReleaseKindToFetch) with
  | .ok .nightly => true
  | _ => false

/-- get the release kind to fetch from the environment variable `RELEASE_KIND_TO_FETCH`. -/
public def getReleaseKindToFetch : IO ReleaseKindToFetch := do
  match (← IO.getEnv "RELEASE_KIND_TO_FETCH") with
  | .some kindStr => IO.ofExcept <| ReleaseKindToFetch.parse kindStr
  | .none => pure .tagged -- default value for local testing
