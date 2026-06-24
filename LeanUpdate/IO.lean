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

namespace IO.Process

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
public def lakeOutput (cwd : FilePath) (args : Array String) : IO Output :=
  IO.Process.output {
    cmd := "lake"
    args := args
    cwd := some cwd
    env := cleanLakeEnv
  }

/-- a variant of `IO.Process.output` that ensures the process succeeds. -/
public abbrev SuccessOutput := { out : Output // out.exitCode == 0 }

/-- get `stdout` of `SuccessOutput` -/
public def SuccessOutput.stdout (so : SuccessOutput) : String := so.val.stdout

/-- Run a process and ensure it succeeds, printing error and `stderr` if available.

**Note** This function will not print `stdout`.
-/
public def successOutput (args : SpawnArgs) (input? : Option String := none) : IO SuccessOutput := do
  let out ← IO.Process.output args (input? := input?)
  IO.println s!"Ran process: {args.cmd} {args.args.toList}"

  if h : out.exitCode != 0 then
    throw <| IO.userError s!"Process failed with exit code {out.exitCode}:\n{out.stderr}"
  else if !out.stderr.isEmpty then
    IO.println s!"Process succeeded but had stderr output:\n{out.stderr}"
    pure ⟨out, by grind⟩
  else
    pure ⟨out, by grind⟩

end IO.Process
