module

import LeanUpdate.Input
import LeanUpdate.IO

open IO Process

def lakeUpdateArgs (legacyUpdate : LegacyUpdate) : Array String :=
  if legacyUpdate then
    #["-R", "-Kenv=dev", "update"]
  else
    #["update"]

def lakeUpdateCommand (legacyUpdate : LegacyUpdate) : String :=
  if legacyUpdate then
    "lake -R -Kenv=dev update"
  else
    "lake update"

/-- Run the dependency update command. -/
public def runUpdateDependencies : IO Unit := do
  let legacyUpdate ← GitHub.Action.Input.get LegacyUpdate
  let targetLakePackageDir ← getTargetLakePackageDirectory
  if legacyUpdate then
    IO.println "Using legacy update command"
  else
    IO.println "Using standard update command"

  let out ← IO.Process.lakeOutput targetLakePackageDir (args := lakeUpdateArgs legacyUpdate)
  unless out.stdout.isEmpty do
    IO.print out.stdout
  unless out.stderr.isEmpty do
    IO.print out.stderr
  if out.exitCode != 0 then
    throw <| IO.userError s!"Dependency update command failed with exit code {out.exitCode}: {lakeUpdateCommand legacyUpdate}"
