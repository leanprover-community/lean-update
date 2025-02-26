$leanToolchainDiff = git diff -w "lean-toolchain"
$lakeManifestDiff = git diff -w "lake-manifest.json"
$changedFiles = @()

if ($leanToolchainDiff) { $changedFiles += "lean-toolchain" }
if ($lakeManifestDiff) { $changedFiles += "lake-manifest.json" }

$result = @{
    files_changed = $changedFiles.Count -gt 0
    changed_files = $changedFiles
} | ConvertTo-Json -Compress
Write-Output $result
