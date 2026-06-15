module

import LeanUpdate.FetchLatest
import LeanUpdate.FindDep

public def main (args : List String) : IO Unit := do
  match args with
  | "findDependencies" :: [] => runFindDependencies
  | "fetchLatest" :: rest => runFetchLatest rest
  | _ => throw <| IO.userError "invalid arguments of leanUpdate"
