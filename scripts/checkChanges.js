const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Get environment variables
const updateIfModified = process.env.UPDATE_IF_MODIFIED || "lake-manifest.json";
const packageDirectory = process.env.LAKE_PACKAGE_DIRECTORY || ".";

// Define all candidate files we should check, but with the package directory prefix
const allCandidates = ["lean-toolchain", "lake-manifest.json"].map(file =>
  path.join(packageDirectory, file).replace(/\\/g, '/') // Ensure forward slashes for Git
);

// Filter candidates based on what we're actually monitoring
const candidates = updateIfModified === "lean-toolchain"
  ? [allCandidates[0]]
  : allCandidates;

// Get the changed files
const changedFiles = [];
for (const file of candidates) {
  try {
    const status = execSync(`git status --porcelain ${file}`).toString().trim();
    if (status && status.startsWith(" M")) {
      changedFiles.push(file);
    }
  } catch (error) {
    console.error(`Error checking status for ${file}:`, error.message);
  }
}

// Output the results using the recommended GITHUB_OUTPUT environment variable
const githubOutput = process.env.GITHUB_OUTPUT;
if (githubOutput) {
  fs.appendFileSync(githubOutput, `files_changed=${changedFiles.length > 0}\n`);
  fs.appendFileSync(githubOutput, `do_update=${changedFiles.length > 0}\n`);
  fs.appendFileSync(githubOutput, `changed_files=${changedFiles.join(' ')}\n`);
}

// Debug information
console.log(`Monitoring files: ${candidates.join(', ')}`);
console.log(`Changed files: ${changedFiles.join(', ')}`);
