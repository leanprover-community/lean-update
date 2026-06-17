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

def GH.parseGHEnvLine (key line : String) : Option String :=
  let envLinePrefix := s!"LEAN_UPDATE_{key}="
  if line.startsWith envLinePrefix then
    some <| (line.drop envLinePrefix.length).toString
  else
    none

#guard
  let actual := GH.parseGHEnvLine "CHANGED_FILES" "LEAN_UPDATE_CHANGED_FILES=lake-manifest.json lean-toolchain"
  let expected := some "lake-manifest.json lean-toolchain"
  actual == expected

#guard
  GH.parseGHEnvLine "CHANGED_FILES" "LEAN_UPDATE_FILES_CHANGED=true" == none

/-- Read a value from the local GitHub Actions environment file. -/
def GH.readLocalGHEnv (key : String) : IO String := do
  let path : System.FilePath := Local.GITHUB_ENV
  if !(← path.pathExists) then
    throw <| IO.userError s!"Local GitHub Actions environment file '{path}' not found"
  let content ← IO.FS.readFile path
  let result? := content.lines.toList
    |>.map (·.copy)
    |>.map (GH.parseGHEnvLine key ·)
    |>.reverse
    |>.findSome? id
  match result? with
  | .some value => pure value
  | .none =>
    throw <| IO.userError s!"Local environment variable 'LEAN_UPDATE_{key}' not found in file '{path}'"

/-- Read a value previously written through `GH.writeGHEnv`. -/
public def GH.readGHEnv (key : String) : IO (Option String) := do
  if (← isRunningGHAction) then
    IO.getEnv s!"LEAN_UPDATE_{key}"
  else
    GH.readLocalGHEnv key

/-- Read a value previously written through `GH.writeGHEnv`.
This function throws an error if the environment variable is not found or is empty. -/
public def GH.readGHEnv! (key : String) : IO String := do
  if (← isRunningGHAction) then
    let some value ← IO.getEnv s!"LEAN_UPDATE_{key}"
      | throw <| IO.userError s!"Environment variable 'LEAN_UPDATE_{key}' not found"
    pure value
  else
    GH.readLocalGHEnv key
