
$leanToolchainDiff = git diff -w "lean-toolchain"
$lakeManifestDiff = git diff -w "lake-manifest.json"

if ($leanToolchainDiff -or $lakeManifestDiff) {
    Write-Output "files_changed=true"
} else {
    Write-Output "files_changed=false"
}
