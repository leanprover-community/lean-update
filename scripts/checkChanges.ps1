$leanToolchainDiff = git diff -w "lean-toolchain"
$lakeManifestDiff = git diff -w "lake-manifest.json"
$changedFiles = @()

if ($leanToolchainDiff) { $changedFiles += "lean-toolchain" }
if ($lakeManifestDiff) { $changedFiles += "lake-manifest.json" }

if ($changedFiles.Count -gt 0) {
    Write-Output "files_changed=true"
    Write-Output "changed_files=$( $changedFiles -join ', ' )"
} else {
    Write-Output "files_changed=false"
    Write-Output "changed_files="
}
