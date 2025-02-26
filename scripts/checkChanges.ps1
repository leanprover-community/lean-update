# Initialize the arrays to track all changed files
$changedFiles = @()
$files_changed = $false

# Check for changes in the specified file(s)
$whatToUpdate = if ($env:WHAT_TO_UPDATE) { $env:WHAT_TO_UPDATE } else { "lean-toolchain" }
$whatToUpdateDiff = git diff -w $whatToUpdate

# If the specified file has changed, set files_changed to true
if ($whatToUpdateDiff) {
    $files_changed = $true
} else {
    $files_changed = $false
}

# Check all candidate files for changes
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
    changed_files = $changedFiles  # Return all changed files
} | ConvertTo-Json -Compress

Write-Output $result
