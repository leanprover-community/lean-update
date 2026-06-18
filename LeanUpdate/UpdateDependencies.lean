module

import LeanUpdate.Input

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

/--
Unset Lean/Lake toolchain-specific variables before running `lake update` in the
target package. The lean-update executable itself runs under the action
package's Lake environment; inheriting those variables can make Lake restart
with a mixture of the old action toolchain and the target package's new
toolchain.
-/
def emptyLakeEnv : Array (String × Option String) :=
  #[
    ("ELAN_TOOLCHAIN", none),
    ("LAKE", none),
    ("LAKE_HOME", none),
    ("LAKE_OVERRIDE_LEAN", none),
    ("LEAN", none),
    ("LEAN_AR", none),
    ("LEAN_GITHASH", none),
    ("LEAN_PATH", none),
    ("LEAN_SRC_PATH", none),
    ("LEAN_SYSROOT", none)
  ]

/-- Run the dependency update command. -/
public def runUpdateDependencies : IO Unit := do
  let legacyUpdate ← Input.get LegacyUpdate
  let targetLakePackageDir ← getTargetLakePackageDirectory
  if legacyUpdate then
    IO.println "Using legacy update command"
  else
    IO.println "Using standard update command"

  let out ← IO.Process.output {
    cmd := "lake"
    args := lakeUpdateArgs legacyUpdate
    cwd := some targetLakePackageDir
    env := emptyLakeEnv
  }
  unless out.stdout.isEmpty do
    IO.print out.stdout
  unless out.stderr.isEmpty do
    IO.print out.stderr
  if out.exitCode != 0 then
    throw <| IO.userError s!"Dependency update command failed with exit code {out.exitCode}: {lakeUpdateCommand legacyUpdate}"
