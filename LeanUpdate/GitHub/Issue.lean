module

public import LeanUpdate.GitHub.Repository
public import LeanUpdate.SizedStr
public import LeanUpdate.IO
public import LeanUpdate.Terminal

namespace GitHub

/-- GitHub issue -/
public structure Issue where
  title : String
  labelName : String
  labelColor : String
  repo : Repository
  body : SizedStr 65536

/-- create an issue -/
public def Issue.create (issue : Issue) : IO Unit := do
  let _out ← IO.Process.successOutput {
    cmd := "gh"
    args := #[
      "issue", "create",
      "--repo", issue.repo.toString,
      "--title", issue.title,
      "--body", issue.body.val,
      "--label", issue.labelName
    ]
  }
  IO.println <| log% s!"Successfully created issue '{issue.title}' in repository {issue.repo} with label '{issue.labelName}'"

end GitHub
