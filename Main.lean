module

import LeanUpdate.CheckChanges
import LeanUpdate.CreateIssue
import LeanUpdate.FindDep
import LeanUpdate.UpdateDependencies
import LeanUpdate.UpdateLeanToolchain

public def main (args : List String) : IO Unit := do
  match args with
  | ["checkChanges"] => runCheckChanges
  | ["createIssue", "success"] => runCreateIssue .success
  | ["createIssue", "failure"] => runCreateIssue .failure
  | ["findDependencies"] => runFindDependencies
  | ["updateDependencies"] => runUpdateDependencies
  | ["updateLeanToolchain"] => runUpdateLeanToolchain
  | _ => throw <| IO.userError "invalid arguments of leanUpdate"
