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

/-- the result of `lake lint` command -/
public abbrev LintResult := Except String Unit

/-- convert `BuildResult` to string -/
public def BuildResult.toString (result : BuildResult) : String :=
  match result with
  | Except.ok _ => "Build completed successfully"
  | Except.error err => err

/-- convert `TestResult` to string -/
public def TestResult.toString (result : TestResult) : String :=
  match result with
  | Except.ok _ => "All tests passed successfully"
  | Except.error err => err

/-- convert `LintResult` to string -/
public def LintResult.toString (result : LintResult) : String :=
  match result with
  | Except.ok _ => "All lint checks passed successfully"
  | Except.error err => err

/-- the result of the post update validation -/
public structure PostUpdateValidationResult where
  /-- the result of `lake build` command. -/
  buildResult : BuildResult

  /-- the result of `lake test` command.
  this is `none` if `test_driver` not registered -/
  testResult? : Option TestResult

  /-- the result of `lake lint` command.
  this is `none` if `lint_driver` not registered -/
  lintResult? : Option LintResult

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

/-- Check if `lint_driver` is registered in the target package. -/
public def hasLintDriver (cwd : FilePath) : IO Bool := do
  let out ← IO.Process.lakeOutput cwd (args := #["check-lint"])
  return out.exitCode == 0

/-- Run `lake lint` command and get the result. -/
public def runLakeLint (cwd : FilePath) : IO LintResult := do
  let out ← IO.Process.lakeOutput cwd (args := #["lint"])
  if out.exitCode == 0 then
    return (Except.ok ())
  let lintOutput := out.stdout.trimAscii.copy ++ "\n" ++ out.stderr.trimAscii.copy
  pure (Except.error lintOutput)

/-- result is success -/
public def PostUpdateValidationResult.isSuccess (result : PostUpdateValidationResult) : Bool :=
  result.buildResult.isOk
    && (result.testResult?.all (·.isOk))
    && (result.lintResult?.all (·.isOk))

/-- result is failure -/
public def PostUpdateValidationResult.isFailure (result : PostUpdateValidationResult) : Bool :=
  !result.isSuccess

/-- Run post update validation including `lake build`, `lake test`, and `lake lint` commands. -/
public def runPostUpdateValidation : IO PostUpdateValidationResult := do
  let buildArgs ← GitHub.Action.Input.get BuildArgs
  let targetLakePackageDir ← getTargetLakePackageDirectory
  let buildResult ← runLakeBuild targetLakePackageDir buildArgs

  let hasTestDriverResult ← hasTestDriver targetLakePackageDir
  let testResult? ←
    if hasTestDriverResult then
      IO.println <| log% "Target lake package has a test driver"
      let testResult ← runLakeTest targetLakePackageDir
      pure <| some testResult
    else
      IO.println <| log% "Target lake package does not have a test driver, skipping tests"
      pure none

  let hasLintDriverResult ← hasLintDriver targetLakePackageDir
  let lintResult? ←
    if hasLintDriverResult then
      IO.println <| log% "Target lake package has a lint driver"
      let lintResult ← runLakeLint targetLakePackageDir
      pure <| some lintResult
    else
      IO.println <| log% "Target lake package does not have a lint driver, skipping lint checks"
      pure none

  return { buildResult := buildResult, testResult? := testResult?, lintResult? := lintResult? }
