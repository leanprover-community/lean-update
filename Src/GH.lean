module

public import Src.Env

/-
utils for GitHub Action
-/

def outputFilePath : String := "output.txt"

/-- detect if the code is running in a GitHub Action environment -/
def isRunningGHAction : IO Bool := do
  match (← IO.getEnv "GITHUB_ACTIONS") with
  | .some "true" => pure true
  | .some "True" => pure true
  | _ => pure false

/-- write a key-value pair to the GitHub Actions output -/
public def GH.writeOutput (key value : String) : IO Unit := do
  if (← isRunningGHAction) then
    let path ← IO.getEnv! "GITHUB_OUTPUT"
    IO.FS.withFile path IO.FS.Mode.append fun h => do
      h.putStr s!"{key}={value}\n"
  else
    let line := s!"{key}={value}\n"
    IO.FS.withFile outputFilePath IO.FS.Mode.append fun h => do
      h.putStr line
