module

import LeanUpdate.CheckChanges
import LeanUpdate.CreateIssue
import LeanUpdate.FindDep
import LeanUpdate.UpdateDependencies
import LeanUpdate.UpdateLeanToolchain
import LeanUpdate.PostUpdateValidation

public def main (args : List String) : IO Unit := do
  match args with
  | ["checkChanges"] => runCheckChanges
  | ["createIssue"] => runCreateIssue
  | ["findDependencies"] => runFindDependencies
  | ["updateDependencies"] => runUpdateDependencies
  | ["updateLeanToolchain"] => runUpdateLeanToolchain
  | ["validateUpdate"] =>
    let result ← runPostUpdateValidation
    if let .error err := result.buildResult then
      IO.eprintln err
    if let some (.error err) := result.testResult? then
      IO.eprintln err
    if let some (.error err) := result.lintResult? then
      IO.eprintln err
    if result.isFailure then
      throw <| IO.userError "post-update validation failed"
  | _ => throw <| IO.userError "invalid arguments of leanUpdate"
