module

import LeanUpdate.GH
import LeanUpdate.Input

open IO Process System

def leanToolchainFile : String := "lean-toolchain"

def lakeManifestFile : String := "lake-manifest.json"

structure CheckChangesResult where
  filesChanged : Bool
  doUpdate : Bool
  changedFiles : String
  leanToolchainUpdated : Bool

def boolOutput (b : Bool) : String :=
  if b then "true" else "false"

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
  let leanToolchainUpdated ← hasGitDiffIgnoringWhitespace targetLakePackageDir leanToolchainFile
  let lakeManifestUpdated ← hasGitDiffIgnoringWhitespace targetLakePackageDir lakeManifestFile

  let changedFiles := #[]
  let changedFiles := if leanToolchainUpdated then changedFiles.push leanToolchainFile else changedFiles
  let changedFiles := if lakeManifestUpdated then changedFiles.push lakeManifestFile else changedFiles
  let filesChanged := !changedFiles.isEmpty
  let doUpdate :=
    match updateIfModified with
    | .«lean-toolchain» => leanToolchainUpdated
    | .«lake-manifest.json» => filesChanged

  pure {
    filesChanged
    doUpdate
    changedFiles := String.intercalate " " changedFiles.toList
    leanToolchainUpdated
  }

/-- Run the update checker command. -/
public def runCheckChanges : IO Unit := do
  let updateIfModified ← Input.get UpdateIfModified
  let targetLakePackageDir ← getTargetLakePackageDirectory
  let result ← checkChanges updateIfModified targetLakePackageDir

  IO.println s!"info: files_changed={boolOutput result.filesChanged}, do_update={boolOutput result.doUpdate}, changed_files={result.changedFiles}, lean_toolchain_updated={boolOutput result.leanToolchainUpdated}"

  GH.writeOutput "files_changed" (boolOutput result.filesChanged)
  GH.writeOutput "changed_files" result.changedFiles
  GH.writeOutput "do_update" (boolOutput result.doUpdate)
  GH.writeOutput "lean_toolchain_updated" (boolOutput result.leanToolchainUpdated)
