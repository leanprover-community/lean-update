module

public import Lean

/-- Get environment variable or throw an error if not found. -/
public def IO.getEnv! (key : String) : IO String := do
  match (← IO.getEnv key) with
  | .some value => pure value
  | .none => throw <| IO.userError s!"Environment variable '{key}' not found"

/-- Term syntax for reading a required environment variable. -/
syntax "ENV[" str "]" : term

/-- Expand `ENV["KEY"]` to `IO.getEnv! "KEY"`. -/
macro_rules
  | `(ENV[$key:str]) => `(IO.getEnv! $key)
