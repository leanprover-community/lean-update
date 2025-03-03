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
  console.error(`Error: ${updateIfModified} is not a valid option for update_if_modified`);
  console.error(`Valid options are: ${allCandidates.join(', ')}`);
  process.exit(1);
}

// Check all candidate files for changes
const fileChanges = {};
allCandidates.forEach(candidate => {
  try {
    const diff = execSync(`git diff -w ${candidate}`, { encoding: 'utf8' });
    fileChanges[candidate] = diff.length > 0;
    if (diff.length > 0) {
      changedFiles.push(candidate);
    }
  } catch (error) {
    console.error(`Error checking diff for ${candidate}:`, error);
    fileChanges[candidate] = false;
  }
});

// Determine if updates should proceed based on the specified update_if_modified value
if (updateIfModified === 'lean-toolchain') {
  // If update_if_modified is lean-toolchain, only proceed if lean-toolchain has changed
  doUpdate = fileChanges['lean-toolchain'];
} else if (updateIfModified === 'lake-manifest.json') {
  // If update_if_modified is lake-manifest.json, proceed if any file has changed
  doUpdate = changedFiles.length > 0;
}

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
