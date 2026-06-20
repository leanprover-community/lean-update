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
    let _ ← runPostUpdateValidation
  | _ => throw <| IO.userError "invalid arguments of leanUpdate"
