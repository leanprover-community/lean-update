import Lake
open Lake DSL

package "Src" where
  version := v!"0.1.0"

@[default_target]
lean_lib «Src» where
  -- add library configuration options here
  globs := #[.submodules `Src]
  leanOptions := #[
    ⟨`linter.missingDocs, true⟩
  ]

lean_exe findDependencies where
  root := `Src.FindDep

lean_exe fetchLatest where
  root := `Src.FetchLatest


open IO Process

def getOutput (input : String) (stdIn : Option String := none) : IO Output := do
  let cmdList := input.splitOn " "
  let cmd := cmdList.head!
  let args := cmdList.tail |>.toArray
  let out ← IO.Process.output
    (args := {cmd := cmd, args := args})
    (input? := stdIn)
  if out.exitCode != 0 then
    throw <| IO.userError s!"Command '{input}' failed with exit code {out.exitCode} and error: {out.stderr.trimAscii}"
  return out

def runCmd (input : String) : IO Unit := do
  let out ← getOutput input
  let outStr := out.stdout.trimAscii
  if outStr != "" then
    IO.println outStr

lean_exe fetchLatestLeanTest where
  root := `Src.FetchLatest.Test

lean_exe findDepTest where
  root := `Src.FindDep.Test

@[test_driver]
script test do
  runCmd "lake exe fetchLatestLeanTest"
  runCmd "lake exe findDepTest"
  return 0
