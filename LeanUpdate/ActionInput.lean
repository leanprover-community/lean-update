module

public import LeanUpdate.GH

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
