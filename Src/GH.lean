module

public import Src.Env

/-
utils for GitHub Action
-/

/-- this is used for local testing -/
private def Local.GITHUB_OUTPUT : String := "output.txt"

/-- this is used for local testing -/
private def Local.GITHUB_ENV : String := "env.txt"

/-- detect if the code is running in a GitHub Action environment -/
def isRunningGHAction : IO Bool := do
  match (← IO.getEnv "GITHUB_ACTIONS") with
  | .some "true" => pure true
  | .some "True" => pure true
  | _ => pure false

def IO.FS.appendLineToFile (path : System.FilePath) (line : String) : IO Unit :=
  IO.FS.withFile path IO.FS.Mode.append fun h => do
    h.putStr s!"{line}\n"

/-- write a key-value pair to the GitHub Actions output -/
public def GH.writeOutput (key value : String) : IO Unit := do
  if (← isRunningGHAction) then
    let path ← IO.getEnv! "GITHUB_OUTPUT"
    IO.FS.appendLineToFile path s!"{key}={value}"
  else
    let line := s!"{key}={value}\n"
    IO.FS.appendLineToFile Local.GITHUB_OUTPUT line

def GH.writeGHEnv (key value : String) : IO Unit := do
  if (← isRunningGHAction) then
    let path ← IO.getEnv! "GITHUB_ENV"
    IO.FS.appendLineToFile path s!"LEAN_UPDATE_{key}={value}"
  else
    IO.FS.appendLineToFile Local.GITHUB_ENV s!"LEAN_UPDATE_{key}={value}"

def GH.readGHEnv (key : String) : IO (Option String) := do
  if (← isRunningGHAction) then
    IO.getEnv s!"LEAN_UPDATE_{key}"
  else
    pure none
