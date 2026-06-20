module

public import LeanUpdate.GitHub.Action.Env
public import LeanUpdate.Terminal

namespace GitHub.Action

/-- the input value of GitHub Action -/
public class Input (α : Type) where
  /-- the environment variable name which stores the input value -/
  envName : String
  /-- parse function for the input value -/
  parse : String → Except String α
  /-- default value for local testing -/
  localValue? : Option α

/-- get the input value from the environment variable or the local default value -/
public def Input.get (α : Type) [Input α] : IO α := do
  let envVarName := Input.envName α
  match (← IO.getEnv envVarName) with
  | .some valueStr =>
    IO.println <| log% s!"Input {``envVarName.toLower``} is set to {valueStr}"
    IO.ofExcept <| Input.parse valueStr
  | .none =>
    if !(← isRunningGHAction) then
      match (Input.localValue? : Option α) with
      | some localVal =>
        IO.println <| log% s!"Using local default value for {``envVarName.toLower``}"
        pure localVal
      | none => throw <| IO.userError s!"Environment variable {``envVarName``} not found and no local default value provided."
    else
      throw <| IO.userError s!"Environment variable {``envVarName``} not found."

end GitHub.Action
