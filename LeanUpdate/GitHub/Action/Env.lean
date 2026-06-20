module

import LeanUpdate.IO
import LeanUpdate.HasParser

/-- this is used for local testing -/
def Local.GITHUB_OUTPUT : String := "tmp/output.txt"

/-- this is used for local testing -/
def Local.GITHUB_ENV : String := "tmp/env.txt"

namespace GitHub.Action

/-- detect if the code is running in a GitHub Action environment -/
public def isRunningGHAction : IO Bool := do
  let isActionStr? ← IO.getEnv "GITHUB_ACTIONS"
  match isActionStr? with
  | .some isActionStr =>
    let isAction ← IO.ofExcept <| Bool.parse isActionStr
    pure isAction
  | .none => pure false

/-- write a key-value pair to the GitHub Actions output -/
public def writeGHOutput (key value : String) : IO Unit := do
  let line := s!"{key}={value}"
  if (← isRunningGHAction) then
    let GITHUB_OUTPUT ← IO.getEnv! "GITHUB_OUTPUT"
    IO.FS.appendLineToFile GITHUB_OUTPUT line
  else
    IO.FS.appendLineToFile Local.GITHUB_OUTPUT line
  IO.println s!"[Update GITHUB_OUTPUT]: {key}={value}"

/-- write a key-value pair to the GitHub Actions environment -/
public def writeGHEnv (key value : String) : IO Unit := do
  let line := s!"LEAN_UPDATE_{key}={value}"
  if (← isRunningGHAction) then
    let GITHUB_ENV ← IO.getEnv! "GITHUB_ENV"
    IO.FS.appendLineToFile GITHUB_ENV line
  else
    IO.FS.appendLineToFile Local.GITHUB_ENV line
  IO.println s!"[Update GITHUB_ENV]: {line}"

def parseGHEnvLine (key line : String) : Option String :=
  let envLinePrefix := s!"LEAN_UPDATE_{key}="
  if line.startsWith envLinePrefix then
    some <| (line.drop envLinePrefix.length).toString
  else
    none

#guard
  let actual := parseGHEnvLine "CHANGED_FILES" "LEAN_UPDATE_CHANGED_FILES=lake-manifest.json lean-toolchain"
  let expected := some "lake-manifest.json lean-toolchain"
  actual == expected

#guard
  parseGHEnvLine "CHANGED_FILES" "LEAN_UPDATE_FILES_CHANGED=true" == none

/-- Read a value from the local GitHub Actions environment file. -/
def readLocalGHEnv (key : String) : IO String := do
  let path : System.FilePath := Local.GITHUB_ENV
  if !(← path.pathExists) then
    throw <| IO.userError s!"Local GitHub Actions environment file '{path}' not found"
  let content ← IO.FS.readFile path
  let result? := content.lines.toList
    |>.map (·.copy)
    |>.map (parseGHEnvLine key ·)
    |>.reverse
    |>.findSome? id
  pure <| result?.getD ""

/-- Read a value previously written through `GitHub.Action.writeGHEnv`. -/
public def readGHEnv (key : String) : IO (Option String) := do
  if (← isRunningGHAction) then
    IO.getEnv s!"LEAN_UPDATE_{key}"
  else
    readLocalGHEnv key

/-- Read a value previously written through `GitHub.Action.writeGHEnv`.
This function throws an error if the environment variable is not found or is empty. -/
public def readGHEnv! (key : String) : IO String := do
  if (← isRunningGHAction) then
    let some value ← IO.getEnv s!"LEAN_UPDATE_{key}"
      | throw <| IO.userError s!"Environment variable 'LEAN_UPDATE_{key}' not found"
    pure value
  else
    readLocalGHEnv key

end GitHub.Action
