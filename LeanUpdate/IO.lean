module

open IO Process System

/-- Append a new line to a file. -/
public def IO.FS.appendLineToFile (path : System.FilePath) (line : String) : IO Unit :=
  IO.FS.withFile path IO.FS.Mode.append fun h => do
    h.putStr s!"{line}\n"

/-- Get environment variable or throw an error if not found. -/
public def IO.getEnv! (key : String) : IO String := do
  match (← IO.getEnv key) with
  | .some value => pure value
  | .none => throw <| IO.userError s!"Environment variable '{key}' not found"

/--
Unset Lean/Lake toolchain-specific variables before running `lake update` in
the target package. The lean-update executable itself runs under the action
package's Lake environment; inheriting those variables can make Lake restart
with a mixture of the old action toolchain and the target package's new
toolchain.
-/
public def cleanLakeEnv : Array (String × Option String) :=
  #[
    ("ELAN_TOOLCHAIN", none),
    ("LAKE", none),
    ("LAKE_CACHE_DIR", none),
    ("LAKE_HOME", none),
    ("LAKE_OVERRIDE_LEAN", none),
    ("DYLD_LIBRARY_PATH", none),
    ("LD_LIBRARY_PATH", none),
    ("LEAN", none),
    ("LEAN_AR", none),
    ("LEAN_CC", none),
    ("LEAN_GITHASH", none),
    ("LEAN_PATH", none),
    ("LEAN_SRC_PATH", none),
    ("LEAN_SYSROOT", none)
  ]

/-- Run `lake` in a target package directory with Lean/Lake toolchain env cleared. -/
public def IO.Process.lakeOutput (cwd : FilePath) (args : Array String) : IO Output :=
  IO.Process.output {
    cmd := "lake"
    args := args
    cwd := some cwd
    env := cleanLakeEnv
  }
