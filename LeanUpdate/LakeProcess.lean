module

open IO Process System

/--
Unset Lean/Lake toolchain-specific variables before running `lake update` in the
target package. The lean-update executable itself runs under the action
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
