module

import Lean
import LeanUpdate.IO
import LeanUpdate.GitHub.Action.Env
public import LeanUpdate.Input

open IO Process System

/-- the result of `lake build` command -/
public abbrev BuildResult := Except String Unit

/-- the result of `lake test` command -/
public abbrev TestResult := Except String Unit

/-- the result of the post update validation -/
public structure UpdateValidationResult where
  /-- the result of `lake build` command. -/
  buildResult : BuildResult

  /-- the result of `lake test` command.
  this is `none` if `test_driver` not registered -/
  testResult : Option TestResult

/-- Run `lake build` command and get the result. -/
public def runLakeBuild (cwd : FilePath) (buildArgs : BuildArgs) : IO BuildResult := do
  let out ← IO.Process.lakeOutput cwd (args := #["build"] ++ buildArgs.val)
  if out.exitCode == 0 then
    return (Except.ok ())
  let buildOutput := out.stdout.trimAscii.copy ++ "\n" ++ out.stderr.trimAscii.copy
  pure (Except.error buildOutput)

/-- Check if `test_driver` is registered in the target package. -/
public def hasTestDriver (cwd : FilePath) : IO Bool := do
  let out ← IO.Process.lakeOutput cwd (args := #["check-test"])
  return out.exitCode == 0

/-- Run `lake test` command and get the result. -/
public def runLakeTest (cwd : FilePath) : IO TestResult := do
  let out ← IO.Process.lakeOutput cwd (args := #["test"])
  if out.exitCode == 0 then
    return (Except.ok ())
  let testOutput := out.stdout.trimAscii.copy ++ "\n" ++ out.stderr.trimAscii.copy
  pure (Except.error testOutput)

/-- Run post update validation including `lake build` and `lake test` commands. -/
public def runPostUpdateValidation (buildArgs : BuildArgs) : IO UpdateValidationResult := do
  let targetLakePackageDir ← getTargetLakePackageDirectory
  let buildResult ← runLakeBuild targetLakePackageDir buildArgs
  let hasTestDriver ← hasTestDriver targetLakePackageDir
  if hasTestDriver then
    IO.println <| log% "Target lake package has a test driver"
    let testResult ← runLakeTest targetLakePackageDir
    return { buildResult := buildResult, testResult := some testResult }
  else
    IO.println <| log% "Target lake package does not have a test driver, skipping tests"
    return { buildResult := buildResult, testResult := none }
