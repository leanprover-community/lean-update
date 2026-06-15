module

import LeanUpdate.Env
import LeanUpdate.FetchLatest.Core
import LeanUpdate.GH

/-- Run the `fetchLatest` command.
Release kind is taken from the environment variable `RELEASE_KIND_TO_FETCH`.
But it would be overridden if a command-line argument is provided. -/
public def runFetchLatest (args : List String) : IO Unit := do
  let kindStr ← if args.length == 1 then pure args.head! else getReleaseKindToFetch
  IO.println s!"Fetching the latest {kindStr} Lean release..."

  let releaseKind ← IO.ofExcept <| ReleaseKind.ofString kindStr
  let latestRelease ← getLatestLeanRelease releaseKind
  IO.println s!"Latest {releaseKind} Lean release: {latestRelease.toString}"
  GH.writeOutput "latest_lean" latestRelease.toString
