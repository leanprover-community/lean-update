const { execSync } = require('child_process');
const fs = require('fs');

/**
 * Parse a version string into components
 * @param {string} ver - Version string without 'v' prefix (e.g., "4.15.0-rc1")
 */
function parseVersion(ver) {
  // Split version from prerelease suffix (e.g., "4.15.0-rc1" -> ["4.15.0", "rc1"])
  const hyphenIndex = ver.indexOf('-');
  let versionPart, prerelease;
  if (hyphenIndex === -1) {
    versionPart = ver;
    prerelease = null;
  } else {
    versionPart = ver.substring(0, hyphenIndex);
    prerelease = ver.substring(hyphenIndex + 1);
  }

  const parts = versionPart.split('.');
  return {
    major: parseInt(parts[0]),
    minor: parseInt(parts[1]),
    patch: parseInt(parts[2] || 0),
    prerelease: prerelease,
    original: ver
  };
}

/**
 * Compare two parsed versions for sorting (ascending order)
 */
function compareVersions(a, b) {
  if (a.major !== b.major) return a.major - b.major;
  if (a.minor !== b.minor) return a.minor - b.minor;
  if (a.patch !== b.patch) return a.patch - b.patch;

  // Handle prerelease comparison
  // Stable (null) comes after prereleases for the same version
  if (a.prerelease === null && b.prerelease === null) return 0;
  if (a.prerelease === null) return 1;
  if (b.prerelease === null) return -1;

  // Both have prereleases, compare them (e.g., "rc1" vs "rc2")
  return a.prerelease.localeCompare(b.prerelease, undefined, { numeric: true });
}

// Export for testing
module.exports = { parseVersion, compareVersions };

// Only run main logic if executed directly (not imported)
if (require.main === module) {
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
      .map(tag => tag.substring(1))
      .map(parseVersion);

    // Sort versions and get the latest one
    semvers.sort(compareVersions);

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
}
