module

import LeanUpdate.GH
import LeanUpdate.Input

open IO Process System

def filesToWatch : List String := ["lean-toolchain", "lake-manifest.json"]

structure CheckChangesResult where
  filesChanged : Bool
  doUpdate : Bool
  changedFiles : String
  leanToolchainUpdated : Bool

def hasGitDiffIgnoringWhitespace (cwd : FilePath) (path : String) : IO Bool := do
  let out ← IO.Process.output {
    cmd := "git"
    args := #["diff", "-w", "--", path]
    cwd := some cwd
  }
  if out.exitCode != 0 then
    let stderr := if out.stderr.isEmpty then "" else s!":\n{out.stderr}"
    throw <| IO.userError s!"Failed to check git diff for {path} with exit code {out.exitCode}{stderr}"
  pure !out.stdout.isEmpty

def checkChanges (updateIfModified : UpdateIfModified) (targetLakePackageDir : FilePath) : IO CheckChangesResult := do
  let changedFiles ← filesToWatch.filterM (hasGitDiffIgnoringWhitespace targetLakePackageDir)
  let leanToolchainUpdated ← hasGitDiffIgnoringWhitespace targetLakePackageDir "lean-toolchain"

  let filesChanged := !changedFiles.isEmpty
  let doUpdate :=
    match updateIfModified with
    | .«lean-toolchain» => leanToolchainUpdated
    | .«lake-manifest.json» => filesChanged

  pure {
    filesChanged
    doUpdate
    changedFiles := String.intercalate " " changedFiles
    leanToolchainUpdated
  }

/-- Run the update checker command. -/
public def runCheckChanges : IO Unit := do
  let updateIfModified ← Input.get UpdateIfModified
  let targetLakePackageDir ← getTargetLakePackageDirectory
  let result ← checkChanges updateIfModified targetLakePackageDir

  IO.println s!"info: files_changed={result.filesChanged}, do_update={result.doUpdate}, changed_files={result.changedFiles}, lean_toolchain_updated={result.leanToolchainUpdated}"

  GH.writeGHEnv "FILES_CHANGED" (toString result.filesChanged)
  GH.writeGHEnv "CHANGED_FILES" result.changedFiles
  GH.writeGHEnv "DO_UPDATE" (toString result.doUpdate)
  GH.writeGHEnv "LEAN_TOOLCHAIN_UPDATED" (toString result.leanToolchainUpdated)
