module

import Lean
import LeanUpdate.GitHub.Action.Env
public import LeanUpdate.GitHub.Issue
import LeanUpdate.Input
public meta import LeanUpdate.GitHub.Repository
public import      LeanUpdate.PostUpdateValidation
public meta import LeanUpdate.PostUpdateValidation
public import LeanUpdate.CheckChanges
import all LeanUpdate.String

open IO Process System GitHub.Issue

/-- get the issue label name -/
public def PostUpdateValidationResult.createIssueLabelName (result : PostUpdateValidationResult) : String :=
  if result.isSuccess then
    "auto-update-lean"
  else
    "auto-update-lean-fail"

/-- get the issue title -/
public def PostUpdateValidationResult.createIssueTitle (result : PostUpdateValidationResult) : String :=
  if result.isSuccess then
    "Updates available and have been validated successfully"
  else
    "Updates available but manual intervention required"

/-- get the issue label color -/
public def PostUpdateValidationResult.createLabelColor (result : PostUpdateValidationResult) : String :=
  if result.isSuccess then
    "0E8A16"
  else
    "D73A4A"

/-- get the issue body -/
public def createIssueBody (result : PostUpdateValidationResult) (changedFiles : List String) : String := Id.run do
  let header :=
    if result.isSuccess then
      "Update availabe and validated successfully."
    else
      "Try `lake update` and then investigate why this update causes `lake build`, `lake test`, or `lake lint` to fail."
  let mut bodyList := [header, ""]

  let changedFilesMsg : List String :=
    match changedFiles with
    | [] => []
    | _ =>
      let changedFileHeader := [
        "## Files changed",
        "",
      ]
      changedFileHeader ++ changedFiles.map (fun file => s!"- `{file}`") ++ [""]
  bodyList := bodyList ++ changedFilesMsg

  let truncationNotice := "...(truncated)"
  let outputTruncationLimit := 20000
  if !result.buildResult.isOk then
    let buildOutput := result.buildResult.toString
      |> (String.truncate · truncationNotice outputTruncationLimit)
    let buildResultMsg := [
      "## Build Output",
      "",
      "````",
      buildOutput,
      "````",
      ""
    ]
    bodyList := bodyList ++ buildResultMsg

  if let some testResult := result.testResult? then
    if !Except.isOk testResult then
      let testOutput := testResult.toString
        |> (String.truncate · truncationNotice outputTruncationLimit)
      let testResultMsg := [
        "## Test Output",
        "",
        "````",
        testOutput,
        "````",
        ""
      ]
      bodyList := bodyList ++ testResultMsg

  if let some lintResult := result.lintResult? then
    if !Except.isOk lintResult then
      let lintOutput := lintResult.toString
        |> (String.truncate · truncationNotice outputTruncationLimit)
      let lintResultMsg := [
        "## Lint Output",
        "",
        "````",
        lintOutput,
        "````",
        ""
      ]
      bodyList := bodyList ++ lintResultMsg
  let body := String.intercalate "\n" bodyList

  return body

#guard
  let result : PostUpdateValidationResult := {
    buildResult := .error "build failed"
    testResult? := none
    lintResult? := none
  }
  let hasBuild := (createIssueBody result []).contains "Build Output"
  let hasTest := (createIssueBody result []).contains "Test Output"
  let hasLint := (createIssueBody result []).contains "Lint Output"
  hasBuild && !hasTest && !hasLint

#guard
  let result : PostUpdateValidationResult := {
    buildResult := .ok ()
    testResult? := some (.error "test failed")
    lintResult? := none
  }
  let hasBuild := (createIssueBody result []).contains "Build Output"
  let hasTest := (createIssueBody result []).contains "Test Output"
  let hasLint := (createIssueBody result []).contains "Lint Output"
  !hasBuild && hasTest && !hasLint

#guard
  let result : PostUpdateValidationResult := {
    buildResult := .ok ()
    testResult? := none
    lintResult? := some (.error "lint failed")
  }
  let hasBuild := (createIssueBody result []).contains "Build Output"
  let hasTest := (createIssueBody result []).contains "Test Output"
  let hasLint := (createIssueBody result []).contains "Lint Output"
  !hasBuild && !hasTest && hasLint

#guard
  let longOutput := String.ofList (List.replicate 70000 'x')
  let result : PostUpdateValidationResult := {
    buildResult := .error longOutput
    testResult? := some (.error longOutput)
    lintResult? := some (.error longOutput)
  }
  (createIssueBody result []).length ≤ 65536

/--
info: Try `lake update` and then investigate why this update causes `lake build`, `lake test`, or `lake lint` to fail.

## Files changed

- `sample.txt`
- `another.txt`

## Build Output

````
Sample build error message
````

## Test Output

````
Sample test error message
````

## Lint Output

````
Sample lint error message
````
-/
#guard_msgs in
#eval
  let sampleBuildResult : BuildResult := .error "Sample build error message"
  let sampleTestResult : Except String Unit := .error "Sample test error message"
  let sampleLintResult : Except String Unit := .error "Sample lint error message"
  let result : PostUpdateValidationResult := {
    buildResult := sampleBuildResult
    testResult? := some sampleTestResult
    lintResult? := some sampleLintResult
  }
  let body := createIssueBody result ["sample.txt", "another.txt"]
  f!"{body}"

/-- Create a GitHub issue describing an available Lean update. -/
public def runCreateIssue : IO Unit := do
  let validationResult ← runPostUpdateValidation
  let repo ← GitHub.Action.getGitHubRepository
  let labelName := validationResult.createIssueLabelName
  let labelColor := validationResult.createLabelColor

  let changedFiles : List String ← LeanUpdate.getChangedFiles
  let body := createIssueBody validationResult changedFiles
  if !(← GitHub.Action.isRunningGHAction) then
    IO.println <| log% "Not running in GitHub Action environment. Skipping issue creation."
  else
    repo.createLabelIdem labelName labelColor "Auto update for Lean dependencies"
    if (← repo.hasOpenIssueWithLabel labelName) then
      IO.println s!"An open issue with label '{labelName}' already exists. Skipping issue creation."
    else
      GitHub.Issue.create {
        title := validationResult.createIssueTitle
        labelName := validationResult.createIssueLabelName
        labelColor := validationResult.createLabelColor
        repo := repo
        body := body
      }
