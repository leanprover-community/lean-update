module

import Src.FetchLatest.Core
import Std.Time.Format
import Std.Time.Zoned

deprecated_module "This file is for test only, don't import this" (since := "YYYY-MM-DD")

open Std Time

private def testForGetLatestLeanRelease (kind : ReleaseKind) (now expected : String) : IO Unit := do
  let nowZdt ← IO.ofExcept <| ZonedDateTime.fromISO8601String now
  let latest ← getLatestLeanRelease kind (some nowZdt)
  if latest.name != expected then
    throw <| IO.userError s!"Expected latest {kind} release to be '{expected}', got {latest.name}"

/-- Run integration tests for fetching the latest Lean release. -/
public def main : IO Unit := do
  testForGetLatestLeanRelease .nightly "2026-06-13T00:00:00Z" "nightly-2026-06-10"
  testForGetLatestLeanRelease .tagged "2026-04-15T00:00:00Z" "4.30.0-rc1"
  testForGetLatestLeanRelease .tagged "2026-06-13T00:00:00Z" "4.31.0-rc2"
  testForGetLatestLeanRelease .tagged "2025-12-07T00:00:00Z" "4.26.0-rc2"
