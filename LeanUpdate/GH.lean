module

import LeanUpdate.Env
import LeanUpdate.HasParser

/-
utils for GitHub Action
-/

/-- this is used for local testing -/
def Local.GITHUB_OUTPUT : String := "tmp/output.txt"

/-- this is used for local testing -/
def Local.GITHUB_ENV : String := "tmp/env.txt"

/-- detect if the code is running in a GitHub Action environment -/
public def GH.isRunningGHAction : IO Bool := do
  let isActionStr? ← IO.getEnv "GITHUB_ACTIONS"
  match isActionStr? with
  | .some isActionStr =>
    let isAction ← IO.ofExcept <| Bool.parse isActionStr
    pure isAction
  | .none => pure false

def IO.FS.appendLineToFile (path : System.FilePath) (line : String) : IO Unit :=
  IO.FS.withFile path IO.FS.Mode.append fun h => do
    h.putStr s!"{line}\n"

/-- write a key-value pair to the GitHub Actions output -/
public def GH.writeOutput (key value : String) : IO Unit := do
  let line := s!"{key}={value}"
  if (← isRunningGHAction) then
    let GITHUB_OUTPUT ← IO.getEnv! "GITHUB_OUTPUT"
    IO.FS.appendLineToFile GITHUB_OUTPUT line
  else
    IO.FS.appendLineToFile Local.GITHUB_OUTPUT line
  IO.println s!"[Update GITHUB_OUTPUT]: {key}={value}"

/-- write a key-value pair to the GitHub Actions environment -/
public def GH.writeGHEnv (key value : String) : IO Unit := do
  let line := s!"LEAN_UPDATE_{key}={value}"
  if (← isRunningGHAction) then
    let GITHUB_ENV ← IO.getEnv! "GITHUB_ENV"
    IO.FS.appendLineToFile GITHUB_ENV line
  else
    IO.FS.appendLineToFile Local.GITHUB_ENV line
  IO.println s!"[Update GITHUB_ENV]: {line}"

def GH.readGHEnv (key : String) : IO (Option String) := do
  if (← isRunningGHAction) then
    IO.getEnv s!"LEAN_UPDATE_{key}"
  else
    pure none
