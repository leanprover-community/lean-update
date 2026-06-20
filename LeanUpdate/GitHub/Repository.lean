module

public import LeanUpdate.HasParser
public import LeanUpdate.IO
public import Lean

namespace GitHub

/-- GitHub repository -/
public structure Repository where
  owner : String
  name : String

/-- Convert a `Repository` to a string in the format `owner/repo`. -/
public protected def Repository.toString (repo : Repository) : String :=
  s!"{repo.owner}/{repo.name}"

public instance : ToString Repository where
  toString := Repository.toString

/-- Parse a string in the format "owner/repo" into a `Repository`. -/
public protected def Repository.parse (s : String) : Except String Repository :=
  match s.splitOn "/" with
  | [owner, name] => .ok { owner := owner, name := name }
  | _ => throw s!"Invalid repository format: '{s}'. Expected format is 'owner/repo'."

public instance : HasParser Repository where
  parse := Repository.parse

/-- Check if a GitHub repository has a specific label. -/
public def Repository.hasLabel (repo : Repository) (labelName : String) : IO Bool := do
  let out ← IO.Process.output {
    cmd := "gh"
    args := #["api", s!"repos/{repo}/labels/{labelName}", "--silent"]
  }
  pure <| out.exitCode == 0

/-- Create a GitHub label in a repository. -/
public def Repository.createLabel (repo : Repository) (labelName labelColor description : String) : IO Unit := do
  let _out ← IO.Process.successOutput {
    cmd := "gh"
    args := #[
      "api",
      s!"repos/{repo}/labels",
      "-F", s!"name={labelName}",
      "-F", s!"color={labelColor}",
      "-F", s!"description={description}"
    ]
  }
  IO.println s!"Created label '{labelName}' in repository {repo}"

/-- Create a GitHub label if it does not already exist in a repository. -/
public def Repository.createLabelIdem (repo : Repository) (labelName labelColor description : String) : IO Unit := do
  if !(← repo.hasLabel labelName) then
    repo.createLabel labelName labelColor description

/-- Check if a GitHub repository has an open issue with a specific label.
This is an idempotent version of `Repository.createLabel` -/
public def Repository.hasOpenIssueWithLabel (repo : Repository) (labelName : String) : IO Bool := do
  let out ← IO.Process.successOutput {
    cmd := "gh"
    args := #["issue", "list", "--repo", repo.toString, "--label", labelName, "--state", "open", "--json", "number"]
  }
  let json ← IO.ofExcept <| Lean.Json.parse out.stdout
  let issues ← IO.ofExcept <| json.getArr?
  pure <| !issues.isEmpty

end GitHub
