module

public meta import LeanUpdate.Deriving.ToString
public meta import LeanUpdate.Deriving.HasParser
public import LeanUpdate.HasParser
public import LeanUpdate.ActionInput

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
