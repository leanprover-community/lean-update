module

public import LeanUpdate.GitHub.Repository
public import LeanUpdate.IO
public import LeanUpdate.Terminal

namespace GitHub

/-- the maximum length of a GitHub issue body -/
public def Issue.maxBodyLength : Nat := 65536

/-- GitHub issue -/
public structure Issue where
  title : String
  labelName : String
  labelColor : String
  repo : Repository
  /-- issue body. The maximum length of an issue body is **65536** characters. -/
  body : String

/-- create an issue -/
public def Issue.create (issue : Issue) : IO Unit := do
  let _out ← IO.Process.successOutput {
    cmd := "gh"
    args := #[
      "issue", "create",
      "--repo", issue.repo.toString,
      "--title", issue.title,
      "--body", issue.body,
      "--label", issue.labelName
    ]
  }
  IO.println <| log% s!"Successfully created issue '{issue.title}' in repository {issue.repo} with label '{issue.labelName}'"

end GitHub
