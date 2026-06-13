module

public import Lean

open System

/-- Get environment variable or throw an error if not found. -/
public def IO.getEnv! (key : String) : IO String := do
  match (← IO.getEnv key) with
  | .some value => pure value
  | .none => throw <| IO.userError s!"Environment variable '{key}' not found"

/-- Term syntax for reading a required environment variable. -/
syntax "ENV[" str "]" : term

/-- Expand `ENV["KEY"]` to `IO.getEnv! "KEY"`. -/
macro_rules
  | `(ENV[$key:str]) => `(IO.getEnv! $key)


/-- resolve a Lake package directory relative to the GitHub workspace when available -/
public def resolveLakePackageDir (workspace? : Option FilePath) (packageDir : FilePath) : FilePath :=
  if packageDir.isRelative then
    match workspace? with
    | .some workspace => workspace / packageDir
    | .none => packageDir
  else
    packageDir

/-- get the directory of the Lake package to update.
Note: This github action itself is lake package. -/
public def getLakePackageDir : IO FilePath := do
  let packageDir : FilePath ←
    match (← IO.getEnv "LAKE_PACKAGE_DIRECTORY") with
    | .some path => pure path
    | .none =>
      -- for local testing
      pure "."
  let workspace? := (← IO.getEnv "GITHUB_WORKSPACE").map FilePath.mk
  pure <| resolveLakePackageDir workspace? packageDir
