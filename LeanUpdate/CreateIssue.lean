module

import Lean
import LeanUpdate.GitHub.Action.Env
import LeanUpdate.GitHub.Issue
import LeanUpdate.Input
import LeanUpdate.PostUpdateValidation
public meta import LeanUpdate.GitHub.Repository
public meta import LeanUpdate.PostUpdateValidation
public import LeanUpdate.SizedStr
public import LeanUpdate.CheckChanges

open IO Process System

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
public def createIssueBody (result : PostUpdateValidationResult) (changedFiles : List String) : SizedStr 65536 := Id.run do
  let header :=
    if result.isSuccess then
      "Update availabe and validated successfully."
    else
      "Try `lake update` and then investigate why this update causes `lake build` or `lake test` to fail."
  let mut bodyList := [header]

  let changedFilesMsg : List String :=
    match changedFiles with
    | [] => []
    | _ =>
      let changedFileHeader := ["Files changed in update:", "",]
      changedFileHeader ++ changedFiles.map (fun file => s!"- {file}") ++ [""]
  bodyList := bodyList ++ changedFilesMsg

  let truncationNotice := "...(truncated)"
  if !result.buildResult.isOk then
    let buildOutput := result.buildResult.toString
      |> (String.truncateWithNotice · truncationNotice 32000)
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
        |> (String.truncateWithNotice · truncationNotice 32000)
      let testResultMsg := [
        "## Test Output",
        "",
        "````",
        testOutput,
        "````",
        ""
      ]
      bodyList := bodyList ++ testResultMsg
  let body := String.intercalate "\n" bodyList
  ⟨body, by apply sorry_proof⟩

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
