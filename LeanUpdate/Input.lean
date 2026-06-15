module

public meta import LeanUpdate.Deriving.ToString
public meta import LeanUpdate.Deriving.HasParser
public import LeanUpdate.HasParser
public import LeanUpdate.GH

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
  match (parseAs ReleaseKindToFetch "nightly" : Except String ReleaseKindToFetch) with
  | .ok .nightly => true
  | _ => false

/-- the input value of GitHub Action -/
public class ActionInput (α : Type) where
  /-- the environment variable name which stores the input value -/
  envName : String
  /-- parse function for the input value -/
  parse : String → Except String α
  /-- default value for local testing -/
  localValue? : Option α

/-- get the input value from the environment variable or the local default value -/
public def Input.get (α : Type) [ActionInput α] : IO α := do
  let envVarName := ActionInput.envName α
  match (← IO.getEnv envVarName) with
  | .some valueStr =>
    IO.ofExcept <| ActionInput.parse valueStr
  | .none =>
    if !(← GH.isRunningGHAction) then
      match (ActionInput.localValue? : Option α) with
      | some localVal => pure localVal
      | none => throw <| IO.userError s!"Environment variable '{envVarName}' not found and no local default value provided."
    else
      throw <| IO.userError s!"Environment variable '{envVarName}' not found."

public instance : ActionInput ReleaseKindToFetch where
  envName := "RELEASE_KIND_TO_FETCH"
  parse := ReleaseKindToFetch.parse
  localValue? := some .tagged
