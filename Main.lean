module

import LeanUpdate.CheckChanges
import LeanUpdate.FindDep
import LeanUpdate.UpdateDependencies
import LeanUpdate.UpdateLeanToolchain

public def main (args : List String) : IO Unit := do
  match args with
  | ["checkChanges"] => runCheckChanges
  | ["findDependencies"] => runFindDependencies
  | ["updateDependencies"] => runUpdateDependencies
  | ["updateLeanToolchain"] => runUpdateLeanToolchain
  | _ => throw <| IO.userError "invalid arguments of leanUpdate"
