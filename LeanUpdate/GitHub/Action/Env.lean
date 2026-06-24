module

import LeanUpdate.IO
public import LeanUpdate.HasParser
import LeanUpdate.Terminal
public import LeanUpdate.GitHub.Repository
import Std

open Std

/-- this is used for local testing -/
def Local.GITHUB_OUTPUT := "tmp/GITHUB_OUTPUT.txt"

/-- this is used for local testing -/
def Local.GITHUB_ENV := "tmp/GITHUB_ENV.txt"

def Local.GITHUB_REPOSITORY := "leanprover-community/lean-update"

namespace GitHub.Action

/-- detect if the code is running in a GitHub Action environment -/
public def isRunningGHAction : IO Bool := do
  let isActionStr? ← IO.getEnv "GITHUB_ACTIONS"
  match isActionStr? with
  | .some isActionStr =>
    let isAction ← IO.ofExcept <| Bool.parse isActionStr
    pure isAction
  | .none => pure false

/-- the github repository which the github action is running on -/
public def getGitHubRepository : IO Repository := do
  let github_repository? ← IO.getEnv "GITHUB_REPOSITORY"
  let gh_repo? ← IO.getEnv "GH_REPO"
  match github_repository? <|> gh_repo? with
  | .some repo =>
    IO.println <| log% s!"GitHub repository found in environment variables: {repo}"
    IO.ofExcept <| parseAs Repository repo
  | .none =>
    if (← GitHub.Action.isRunningGHAction) then
      throw <| IO.userError "Environment variable 'GITHUB_REPOSITORY' not found"
    else
      IO.println <| log% s!"GitHub repository not found in environment variables, using default: {Local.GITHUB_REPOSITORY}"
      IO.ofExcept <| parseAs Repository Local.GITHUB_REPOSITORY

/-- write a key-value pair to the GitHub Actions output -/
public def writeGHOutput (key value : String) : IO Unit := do
  let line := s!"{key}={value}"
  if (← isRunningGHAction) then
    let GITHUB_OUTPUT ← IO.getEnv! "GITHUB_OUTPUT"
    IO.FS.appendLineToFile GITHUB_OUTPUT line
  else
    IO.FS.appendLineToFile Local.GITHUB_OUTPUT line
  IO.println <| log% s!"{key}={value}"

/-- write a key-value pair to the GitHub Actions environment -/
public def writeGHEnv (key value : String) : IO Unit := do
  let line := s!"LEAN_UPDATE_{key}={value}"
  if (← isRunningGHAction) then
    let GITHUB_ENV ← IO.getEnv! "GITHUB_ENV"
    IO.FS.appendLineToFile GITHUB_ENV line
  else
    IO.FS.appendLineToFile Local.GITHUB_ENV line
  IO.println <| log% line

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

/-- Read and parse a value previously written through `GitHub.Action.writeGHEnv`. -/
public def readGHEnvAs (key : String) (expectedType : Type) [HasParser expectedType] : IO (Option expectedType) := do
  let some valueStr ← readGHEnv key
    | pure none
  let value ← IO.ofExcept <| parseAs expectedType valueStr
  pure <| some value

/-- Read a value previously written through `GitHub.Action.writeGHEnv`.
This function throws an error if the environment variable is not found or is empty. -/
public def readGHEnv! (key : String) : IO String := do
  if (← isRunningGHAction) then
    let some value ← IO.getEnv s!"LEAN_UPDATE_{key}"
      | throw <| IO.userError s!"Environment variable 'LEAN_UPDATE_{key}' not found"
    pure value
  else
    readLocalGHEnv key

/-- Read and parse a value previously written through `GitHub.Action.writeGHEnv`.
This function throws an error if the environment variable is not found or is empty. -/
public def readGHEnvAs! (key : String) (expectedType : Type) [HasParser expectedType] : IO expectedType := do
  let valueStr ← readGHEnv! key
  IO.ofExcept <| parseAs expectedType valueStr

end GitHub.Action
