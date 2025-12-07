/**
 * Tests for version parsing and sorting in getLatest.js
 */

const { parseVersion, compareVersions } = require('../scripts/getLatest.js');

function assert(condition, message) {
  if (!condition) {
    console.error(`FAIL: ${message}`);
    process.exit(1);
  }
}

// parseVersion
console.log('Testing parseVersion...');
let v = parseVersion('4.15.0');
assert(v.major === 4, `parseVersion('4.15.0').major: expected 4, got ${v.major}`);
assert(v.minor === 15, `parseVersion('4.15.0').minor: expected 15, got ${v.minor}`);
assert(v.patch === 0, `parseVersion('4.15.0').patch: expected 0, got ${v.patch}`);
assert(v.prerelease === null, `parseVersion('4.15.0').prerelease: expected null, got ${v.prerelease}`);

v = parseVersion('4.15.0-rc1');
assert(v.major === 4, `parseVersion('4.15.0-rc1').major: expected 4, got ${v.major}`);
assert(v.prerelease === 'rc1', `parseVersion('4.15.0-rc1').prerelease: expected 'rc1', got ${v.prerelease}`);

v = parseVersion('4.0');
assert(v.patch === 0, `parseVersion('4.0').patch: expected 0, got ${v.patch}`);
console.log('parseVersion tests passed');

// compareVersions
console.log('Testing compareVersions...');
let cmp = compareVersions(parseVersion('4.0.0'), parseVersion('3.0.0'));
assert(cmp > 0, `compareVersions('4.0.0', '3.0.0'): expected > 0, got ${cmp}`);
cmp = compareVersions(parseVersion('4.15.0'), parseVersion('4.14.0'));
assert(cmp > 0, `compareVersions('4.15.0', '4.14.0'): expected > 0, got ${cmp}`);
cmp = compareVersions(parseVersion('4.15.1'), parseVersion('4.15.0'));
assert(cmp > 0, `compareVersions('4.15.1', '4.15.0'): expected > 0, got ${cmp}`);
cmp = compareVersions(parseVersion('4.15.0'), parseVersion('4.15.0'));
assert(cmp === 0, `compareVersions('4.15.0', '4.15.0'): expected 0, got ${cmp}`);
cmp = compareVersions(parseVersion('4.15.0'), parseVersion('4.15.0-rc1'));
assert(cmp > 0, `compareVersions('4.15.0', '4.15.0-rc1'): expected > 0, got ${cmp}`);
cmp = compareVersions(parseVersion('4.15.0-rc2'), parseVersion('4.15.0-rc1'));
assert(cmp > 0, `compareVersions('4.15.0-rc2', '4.15.0-rc1'): expected > 0, got ${cmp}`);
cmp = compareVersions(parseVersion('4.16.0-rc1'), parseVersion('4.15.0'));
assert(cmp > 0, `compareVersions('4.16.0-rc1', '4.15.0'): expected > 0, got ${cmp}`);
console.log('compareVersions tests passed');

// sorting - full Lean4 version list as of 2025-12-07
const versions = [
  '4.0.0-m1', '4.0.0-m2', '4.0.0-m3', '4.0.0-m4', '4.0.0-m5',
  '4.0.0-rc1', '4.0.0-rc2', '4.0.0-rc3', '4.0.0-rc4', '4.0.0-rc5', '4.0.0',
  '4.1.0-rc1', '4.1.0',
  '4.2.0-rc1', '4.2.0-rc2', '4.2.0-rc3', '4.2.0-rc4', '4.2.0',
  '4.3.0-rc1', '4.3.0-rc2', '4.3.0',
  '4.4.0-rc1', '4.4.0',
  '4.5.0-rc1', '4.5.0',
  '4.6.0-rc1', '4.6.0', '4.6.1',
  '4.7.0-rc1', '4.7.0-rc2', '4.7.0',
  '4.8.0-rc1', '4.8.0-rc2', '4.8.0',
  '4.9.0-rc1', '4.9.0-rc2', '4.9.0-rc3', '4.9.0', '4.9.1',
  '4.10.0-rc1', '4.10.0-rc2', '4.10.0',
  '4.11.0-rc1', '4.11.0-rc2', '4.11.0-rc3', '4.11.0',
  '4.12.0-rc1', '4.12.0',
  '4.13.0-rc1', '4.13.0-rc2', '4.13.0-rc3', '4.13.0-rc4', '4.13.0',
  '4.14.0-rc1', '4.14.0-rc2', '4.14.0-rc3', '4.14.0',
  '4.15.0-rc1', '4.15.0',
  '4.16.0-rc1', '4.16.0-rc2', '4.16.0',
  '4.17.0-rc1', '4.17.0',
  '4.18.0-rc1', '4.18.0',
  '4.19.0-rc1', '4.19.0-rc2', '4.19.0-rc3', '4.19.0',
  '4.20.0-rc1', '4.20.0-rc2', '4.20.0-rc3', '4.20.0-rc4', '4.20.0-rc5', '4.20.0', '4.20.1-rc1', '4.20.1',
  '4.21.0-rc1', '4.21.0-rc2', '4.21.0-rc3', '4.21.0',
  '4.22.0-rc1', '4.22.0-rc2', '4.22.0-rc3', '4.22.0-rc4', '4.22.0',
  '4.23.0-rc1', '4.23.0-rc2', '4.23.0',
  '4.24.0-rc1', '4.24.0', '4.24.1',
  '4.25.0-rc1', '4.25.0-rc2', '4.25.0', '4.25.1', '4.25.2',
  '4.26.0-rc1', '4.26.0-rc2',
];

console.log('Testing sorting...');
const shuffled = [...versions].reverse();
const sorted = shuffled.map(parseVersion).sort(compareVersions).map(v => v.original);
assert(JSON.stringify(sorted) === JSON.stringify(versions), `sort order:\n\nexpected:\n${JSON.stringify(versions)},\n\ngot:\n${JSON.stringify(sorted)}`);
console.log('sorting tests passed');
