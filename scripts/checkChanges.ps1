# $fileToWatch = if ($env:WHAT_TO_UPDATE) { $env:WHAT_TO_UPDATE } else { "lean-toolchain" }

# Initialize the arrays to track all changed files
$changedFiles = @()

# Check for changes in lean-toolchain
$whatToUpdateIsUpdated = git diff -w $env:WHAT_TO_UPDATE
if ($whatToUpdateIsUpdated) {
    $files_changed = true
}

# Check for changes in lake-manifest.json
$lakeManifestDiff = git diff -w "lake-manifest.json"
$allCandidates = @("lean-toolchain", "lake-manifest.json")
foreach ($candidate in $allCandidates) {
    $diff = git diff -w $candidate
    if ($diff) {
        $changedFiles += $candidate
    }
}

# Create result object
$result = @{
    files_changed = $files_changed
    changed_files = $changedFiles  # Return all changed files, regardless of filter
} | ConvertTo-Json -Compress

Write-Output $result
