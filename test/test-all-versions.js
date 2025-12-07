/**
 * Test version sorting against ALL actual Lean 4 releases
 * Run with: node test/test-all-versions.js
 */

const { execSync } = require('child_process');
const { parseVersion, compareVersions } = require('../scripts/getLatest.js');

// Fetch all releases from GitHub
console.log('Fetching all releases from leanprover/lean4...\n');
const releasesJson = execSync('gh release list --repo leanprover/lean4 --limit 500 --json tagName', { encoding: 'utf8' });
const releases = JSON.parse(releasesJson);

const allVersions = releases
  .map(r => r.tagName)
  .filter(tag => tag.startsWith('v'))
  .map(tag => tag.substring(1));

// Sort them
const semvers = allVersions.map(parseVersion);
semvers.sort(compareVersions);

console.log('=== All Lean 4 versions sorted ===\n');

// Group by major.minor for readability
let currentMinor = null;
semvers.forEach((v, i) => {
  const minor = `${v.major}.${v.minor}`;
  if (minor !== currentMinor) {
    if (currentMinor !== null) console.log('');
    currentMinor = minor;
  }
  const marker = i === semvers.length - 1 ? ' ← LATEST' : '';
  const type = v.prerelease ? `(${v.prerelease})` : '(stable)';
  console.log(`  v${v.original} ${type}${marker}`);
});

console.log('\n=== Verification ===\n');

// Verify specific expectations
const latest = semvers[semvers.length - 1];
console.log(`Latest version: v${latest.original}`);
