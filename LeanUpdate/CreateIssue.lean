module

import Lean
import LeanUpdate.Env
import LeanUpdate.GH
import LeanUpdate.Input
import LeanUpdate.LakeProcess

open IO Process System

def maxIssueBodyLength : Nat := 65536

def truncationNotice : String := "...(truncated)"

structure IssueConfig where
  title : String
  description : String
  labelName : String
  labelColor : String
  repo : String
  changedFiles : String

/-- The issue type to create after the update build. -/
public inductive IssueKind where
  /-- The update build succeeded. -/
  | success
  /-- The update build failed. -/
  | failure

def IssueKind.title : IssueKind → String
  | .success => "Updates available and have been tested to build correctly"
  | .failure => "Updates available but manual intervention required"

def IssueKind.description : IssueKind → String
  | .success => ""
  | .failure => "Try `lake update` and then investigate why this update causes the lean build to fail."

def IssueKind.labelName : IssueKind → String
  | .success => "auto-update-lean"
  | .failure => "auto-update-lean-fail"

def IssueKind.labelColor : IssueKind → String
  | .success => "0E8A16"
  | .failure => "D73A4A"

def getGitHubRepository : IO String := do
  let github_repository? ← IO.getEnv "GITHUB_REPOSITORY"
  let gh_repo? ← IO.getEnv "GH_REPO"
  match github_repository? <|> gh_repo? with
  | .some repo => pure repo
  | .none =>
    if (← GH.isRunningGHAction) then
      throw <| IO.userError "Environment variable 'GITHUB_REPOSITORY' not found"
    else
      pure "owner/repo"

def getIssueConfig (kind : IssueKind) : IO IssueConfig := do
  pure {
    title := kind.title
    description := kind.description
    labelName := kind.labelName
    labelColor := kind.labelColor
    repo := ← getGitHubRepository
    changedFiles := ← GH.readGHEnv! "CHANGED_FILES"
  }

def splitChangedFiles (changedFiles : String) : List String :=
  changedFiles
    |>.replace "\n" " "
    |>.replace "\t" " "
    |>.splitOn " "
    |>.filter fun file => !file.isEmpty

def changedFilesBulletList (changedFiles : String) : String :=
  splitChangedFiles changedFiles
    |>.map (fun file => s!"- {file}")
    |> String.intercalate "\n"

#guard
  splitChangedFiles "lake-manifest.json lean-toolchain\nMain.lean\t" ==
    ["lake-manifest.json", "lean-toolchain", "Main.lean"]

#guard
  changedFilesBulletList "lake-manifest.json lean-toolchain" ==
    "- lake-manifest.json\n- lean-toolchain"

def issueHeader (config : IssueConfig) : String :=
  let bulletList := changedFilesBulletList config.changedFiles
  let filesChanged :=
    if bulletList.isEmpty then
      ""
    else
      s!"\n{bulletList}"
  if config.description.isEmpty then
    s!"Files changed in update:{filesChanged}"
  else
    s!"{config.description}\n\nFiles changed in update:{filesChanged}"

def issueBodyTemplate (header buildOutput : String) : String :=
  String.intercalate "\n" [
    header,
    "",
    "## Build Output",
    "",
    "````",
    buildOutput,
    "````",
    ""
  ]

def issueBodyFixedLength : Nat :=
  (issueBodyTemplate "" "").length

#guard
  issueBodyTemplate "Files changed in update:" "ok" ==
    "Files changed in update:\n\n## Build Output\n\n````\nok\n````\n"

def truncateWithNotice (s : String) (maxLength : Nat) : String :=
  if s.length ≤ maxLength then
    s
  else if truncationNotice.length < maxLength then
    (s.take (maxLength - truncationNotice.length)).copy ++ truncationNotice
  else
    (s.take maxLength).copy

def createIssueBody (config : IssueConfig) (buildOutput : String) : String :=
  let header := issueHeader config
  let maxHeaderLength := maxIssueBodyLength - issueBodyFixedLength
  let (header, availableBuildOutputLength) :=
    if maxIssueBodyLength < header.length + issueBodyFixedLength then
      (truncateWithNotice header maxHeaderLength, 0)
    else
      (header, maxIssueBodyLength - header.length - issueBodyFixedLength)
  let buildOutput := truncateWithNotice buildOutput availableBuildOutputLength
  issueBodyTemplate header buildOutput

#guard
  let longText := String.ofList (List.replicate 70000 'x')
  let config : IssueConfig := {
    title := ""
    description := longText
    labelName := "auto-update-lean"
    labelColor := "0E8A16"
    repo := "owner/repo"
    changedFiles := "lake-manifest.json lean-toolchain"
  }
  (createIssueBody config longText).length ≤ maxIssueBodyLength

def throwProcessError (description : String) (out : Output) : IO Unit := do
  let stderr := out.stderr.trimAscii.copy
  if stderr.isEmpty then
    throw <| IO.userError s!"{description} failed with exit code {out.exitCode}"
  else
    throw <| IO.userError s!"{description} failed with exit code {out.exitCode}:\n{stderr}"

def runLakeBuild (cwd : FilePath) (buildArgs : BuildArgs) : IO String := do
  let out ← IO.Process.lakeOutput cwd (args := #["build"] ++ buildArgs.val)
  let stderr :=
    if out.stderr.isEmpty then
      ""
    else if out.stdout.isEmpty || out.stdout.endsWith "\n" then
      out.stderr
    else
      "\n" ++ out.stderr
  pure <| out.stdout ++ stderr

def labelExists (repo labelName : String) : IO Bool := do
  let out ← IO.Process.output {
    cmd := "gh"
    args := #["api", s!"repos/{repo}/labels/{labelName}", "--silent"]
  }
  pure <| out.exitCode == 0

def ensureLabel (config : IssueConfig) : IO Unit := do
  unless (← labelExists config.repo config.labelName) do
    IO.println s!"Creating {config.labelName} label..."
    let out ← IO.Process.output {
      cmd := "gh"
      args := #[
        "api",
        s!"repos/{config.repo}/labels",
        "-F", s!"name={config.labelName}",
        "-F", s!"color={config.labelColor}",
        "-F", "description=Auto update for Lean dependencies"
      ]
    }
    if out.exitCode != 0 then
      throwProcessError s!"Creating {config.labelName} label" out

def hasOpenIssueWithLabel (repo labelName : String) : IO Bool := do
  let out ← IO.Process.output {
    cmd := "gh"
    args := #["issue", "list", "--repo", repo, "--label", labelName, "--state", "open", "--json", "number"]
  }
  if out.exitCode != 0 then
    throwProcessError s!"Listing open issues with label '{labelName}'" out
  let json ← IO.ofExcept <| Lean.Json.parse out.stdout
  let issues ← IO.ofExcept <| json.getArr?
  pure <| !issues.isEmpty

def createIssue (config : IssueConfig) (body : String) : IO Unit := do
  let out ← IO.Process.output {
    cmd := "gh"
    args := #[
      "issue", "create",
      "--repo", config.repo,
      "--title", config.title,
      "--body", body,
      "--label", config.labelName
    ]
  }
  if out.exitCode != 0 then
    throwProcessError "Creating issue" out
  unless out.stdout.isEmpty do
    IO.print out.stdout
  unless out.stderr.isEmpty do
    IO.print out.stderr

def printIssuePreview (config : IssueConfig) (body : String) : IO Unit := do
  IO.println "Issue creation preview (not submitted):"
  IO.println s!"Repository: {config.repo}"
  IO.println s!"Title: {config.title}"
  IO.println s!"Label: {config.labelName}"
  IO.println ""
  IO.println "Body:"
  IO.println body

/-- Create a GitHub issue describing an available Lean update. -/
public def runCreateIssue (kind : IssueKind) : IO Unit := do
  let config ← getIssueConfig kind
  let targetLakePackageDir ← getTargetLakePackageDirectory
  let buildArgs ← Input.get BuildArgs
  let isRunningGHAction ← GH.isRunningGHAction
  let buildOutput ← runLakeBuild targetLakePackageDir buildArgs
  let body := createIssueBody config buildOutput
  if !isRunningGHAction then
    printIssuePreview config body
  else
    ensureLabel config
    if (← hasOpenIssueWithLabel config.repo config.labelName) then
      IO.println s!"An open issue with label '{config.labelName}' already exists. Skipping issue creation."
    else
      createIssue config body
