const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

/**
 * Get the latest Lean version and update the lean-toolchain file
 */
try {
  // Get all release tags from leanprover/lean4
  console.log('Fetching release tags from leanprover/lean4...');
  const releasesJson = execSync('gh release list --repo leanprover/lean4 --json tagName', { encoding: 'utf8' });
  const releases = JSON.parse(releasesJson);

  // Filter out tags that are not in the form of "v*"
  const versionTags = releases
    .map(release => release.tagName)
    .filter(tag => tag.startsWith('v'));

  // Parse version tags as semver (removing the 'v' prefix)
  const semvers = versionTags
    .map(tag => tag.substring(1)) // Remove 'v' prefix
    .map(ver => {
      const parts = ver.split('.');
      return {
        major: parseInt(parts[0]),
        minor: parseInt(parts[1]),
        patch: parseInt(parts[2] || 0),
        original: ver
      };
    });

  // Sort versions and get the latest one
  semvers.sort((a, b) => {
    if (a.major !== b.major) return a.major - b.major;
    if (a.minor !== b.minor) return a.minor - b.minor;
    return a.patch - b.patch;
  });

  const latest = semvers[semvers.length - 1];
  console.log(`Latest Lean release is: v${latest.original}`);

  // Update lean-toolchain file
  const leanStyleVersion = `leanprover/lean4:v${latest.original}`;
  fs.writeFileSync('lean-toolchain', leanStyleVersion);
  console.log(`Updated lean-toolchain to: ${leanStyleVersion}`);

} catch (error) {
  console.error('Error updating Lean version:', error.message);
  process.exit(1);
}
