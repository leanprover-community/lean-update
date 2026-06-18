module

import LeanUpdate.UpdateDependencies

open System

namespace LeanUpdateTest.UpdateDependenciesEnv

def fakeLakeName : String :=
  if Platform.isWindows then
    "lake.exe"
  else
    "lake"

def executableRights : IO.FileRight where
  user := { read := true, write := true, execution := true }
  group := { read := true, execution := true }
  other := { read := true, execution := true }

def staleToolchainEnv : Array (String × String) :=
  #[
    ("ELAN_TOOLCHAIN", "old-toolchain"),
    ("LAKE", "old-lake"),
    ("LAKE_HOME", "old-lake-home"),
    ("LAKE_OVERRIDE_LEAN", "true"),
    ("LEAN", "old-lean"),
    ("LEAN_AR", "old-lean-ar"),
    ("LEAN_GITHASH", "old-lean-githash"),
    ("LEAN_PATH", "old-lean-path"),
    ("LEAN_SRC_PATH", "old-lean-src-path"),
    ("LEAN_SYSROOT", "old-toolchain-sysroot")
  ]

def installFakeLake (binDir : FilePath) : IO Unit := do
  let currentExe ← IO.appPath
  let fakeLake := binDir / fakeLakeName
  let exeBytes ← IO.FS.readBinFile currentExe
  IO.FS.writeBinFile fakeLake exeBytes
  unless Platform.isWindows do
    IO.setAccessRights fakeLake executableRights

def runAsFakeLake (args : List String) : IO Unit := do
  unless args == ["update"] do
    throw <| IO.userError s!"unexpected lake arguments: {args}"

  for (name, _) in staleToolchainEnv do
    if let some value ← IO.getEnv name then
      throw <| IO.userError s!"{name} leaked into lake update subprocess: {value}"

  IO.println "fake lake update ran"

def runInner : IO Unit := do
  runUpdateDependencies

def pathWithFakeLake (binDir : FilePath) : BaseIO String := do
  let path ←
    if Platform.isWindows then
      match (← IO.getEnv "Path") with
      | some path => pure path
      | none => pure ((← IO.getEnv "PATH").getD "")
    else
      pure ((← IO.getEnv "PATH").getD "")
  pure <| SearchPath.toString (binDir :: SearchPath.parse path)

def runOuter : IO Unit := do
  IO.FS.withTempDir fun tempDir => do
    let binDir := tempDir / "bin"
    let targetDir := tempDir / "target"
    IO.FS.createDirAll binDir
    IO.FS.createDirAll targetDir
    installFakeLake binDir

    let currentExe ← IO.appPath
    let path ← pathWithFakeLake binDir
    let out ← IO.Process.output {
      cmd := currentExe.toString
      args := #["inner"]
      env := #[
        ("PATH", some path),
        ("Path", some path),
        ("LAKE_PACKAGE_DIRECTORY", some targetDir.toString),
        ("LEGACY_UPDATE", some "false"),
        ("GITHUB_WORKSPACE", none)
      ] ++ staleToolchainEnv.map (fun (name, value) => (name, some value))
    }

    if out.exitCode != 0 then
      throw <| IO.userError s!"updateDependencies should not leak toolchain variables to lake update\nstdout:\n{out.stdout}\nstderr:\n{out.stderr}"

end LeanUpdateTest.UpdateDependenciesEnv

/--
Regression test for [issue #237](https://github.com/leanprover-community/lean-update/issues/237).

The default invocation sets up a fake `lake` executable and then starts this
same executable again as `inner` with stale Lean/Lake toolchain variables in the
environment. The inner process calls `runUpdateDependencies`; its `lake update`
subprocess resolves to this executable's `update` mode, which fails if those
toolchain variables leaked through.
-/
public def main (args : List String) : IO Unit := do
  match args with
  | ["inner"] => LeanUpdateTest.UpdateDependenciesEnv.runInner
  | ["update"] => LeanUpdateTest.UpdateDependenciesEnv.runAsFakeLake args
  | _ => LeanUpdateTest.UpdateDependenciesEnv.runOuter
