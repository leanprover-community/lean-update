module

import LeanUpdate.UpdateDependencies

open System

namespace Test.UpdateDependenciesEnv

def fakeLakeName : String :=
  if Platform.isWindows then
    "lake.exe"
  else
    "lake"

def executableRights : IO.FileRight where
  user := { read := true, write := true, execution := true }
  group := { read := true, execution := true }
  other := { read := true, execution := true }

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

  if let some leanSysroot ← IO.getEnv "LEAN_SYSROOT" then
    throw <| IO.userError s!"LEAN_SYSROOT leaked into lake update subprocess: {leanSysroot}"

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
        ("GITHUB_WORKSPACE", none),
        ("LEAN_SYSROOT", some "old-toolchain-sysroot")
      ]
    }

    if out.exitCode != 0 then
      throw <| IO.userError s!"updateDependencies should not leak LEAN_SYSROOT to lake update\nstdout:\n{out.stdout}\nstderr:\n{out.stderr}"

end Test.UpdateDependenciesEnv

public def main (args : List String) : IO Unit := do
  match args with
  | ["inner"] => Test.UpdateDependenciesEnv.runInner
  | ["update"] => Test.UpdateDependenciesEnv.runAsFakeLake args
  | _ => Test.UpdateDependenciesEnv.runOuter
