module

import LeanUpdate.IO

open System

namespace LeanUpdateTest.LakeToolchainResolution

def fixtureDir : FilePath := "Fixtures" / "MathlibDep"

def pathWithActionLake : IO String := do
  let leanSysroot ← IO.getEnv! "LEAN_SYSROOT"
  let path ←
    if Platform.isWindows then
      match (← IO.getEnv "Path") with
      | some path => pure path
      | none => pure ((← IO.getEnv "PATH").getD "")
    else
      pure ((← IO.getEnv "PATH").getD "")
  pure <| SearchPath.toString ((FilePath.mk leanSysroot / "bin") :: SearchPath.parse path)

/--
Regression test for [issue #257](https://github.com/leanprover-community/lean-update/issues/257).

The test driver runs under the root package's toolchain, while `MathlibDep` is
pinned to a different Lean version. Lake must be resolved through Elan in the
fixture directory so that the fixture's `lean-toolchain` selects the executable.
-/
public def testInner : IO Unit := do
  let toolchain := (← IO.FS.readFile (fixtureDir / "lean-toolchain")).trimAscii
  let expectedVersion := toolchain.replace "leanprover/lean4:v" ""
  let out ← IO.Process.lakeOutput fixtureDir #["--version"]

  if out.exitCode != 0 then
    throw <| IO.userError s!"lake --version failed\nstdout:\n{out.stdout}\nstderr:\n{out.stderr}"

  unless out.stdout.contains s!"Lean version {expectedVersion}" do
    throw <| IO.userError s!"expected {toolchain}, but lake used a different toolchain:\n{out.stdout}"

public def test : IO Unit := do
  let currentExe ← IO.appPath
  let path ← pathWithActionLake
  let out ← IO.Process.output {
    cmd := currentExe.toString
    args := #["toolchain-resolution-inner"]
    env := #[("PATH", some path), ("Path", some path)]
  }

  if out.exitCode != 0 then
    throw <| IO.userError s!"lake should use the target package's toolchain\nstdout:\n{out.stdout}\nstderr:\n{out.stderr}"

end LeanUpdateTest.LakeToolchainResolution
