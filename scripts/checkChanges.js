const { execSync } = require('child_process');
const fs = require('fs');

// Initialize variables to track all changed files
const changedFiles = [];
let doUpdate = false;

// Define all candidate files we should check
const allCandidates = ["lean-toolchain", "lake-manifest.json"];

// Check for changes in the specified file(s)
const updateIfModified = process.env.UPDATE_IF_MODIFIED;

// Validate that updateIfModified is in allCandidates
if (!allCandidates.includes(updateIfModified)) {
  console.error(`Error: ${updateIfModified} is not a valid option for UPDATE_IF_MODIFIED`);
  console.error(`Valid options are: ${allCandidates.join(', ')}`);
  process.exit(1);
}

try {
  const updateIfModifiedDiff = execSync(`git diff -w ${updateIfModified}`, { encoding: 'utf8' });
  doUpdate = updateIfModifiedDiff.length > 0;
} catch (error) {
  console.error(`Error checking diff for ${updateIfModified}:`, error);
  doUpdate = false;
}

// Check all candidate files for changes
allCandidates.forEach(candidate => {
  try {
    const diff = execSync(`git diff -w ${candidate}`, { encoding: 'utf8' });
    if (diff.length > 0) {
      changedFiles.push(candidate);
    }
  } catch (error) {
    console.error(`Error checking diff for ${candidate}:`, error);
  }
});

// Create result object
const result = {
  files_changed: changedFiles.length > 0,
  do_update: doUpdate,
  changed_files: changedFiles.join(' ')
};

console.log('info:', JSON.stringify(result, null, 2));

// Use the recommended GITHUB_OUTPUT approach
const githubOutput = process.env.GITHUB_OUTPUT;
if (githubOutput) {
  fs.appendFileSync(githubOutput, `files_changed=${result.files_changed}\n`);
  fs.appendFileSync(githubOutput, `changed_files=${result.changed_files}\n`);
  fs.appendFileSync(githubOutput, `do_update=${result.do_update}\n`);
}
