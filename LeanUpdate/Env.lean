module

open System

/-- Get environment variable or throw an error if not found. -/
public def IO.getEnv! (key : String) : IO String := do
  match (← IO.getEnv key) with
  | .some value => pure value
  | .none => throw <| IO.userError s!"Environment variable '{key}' not found"
