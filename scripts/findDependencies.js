const fs = require('fs');
const path = require('path');

/**
 * Determine whether the repository has dependencies by inspecting
 * the `packages` key in lake-manifest.json. Writes `outcome` to GITHUB_OUTPUT
 * as either `has-depencency` or `no-depencency` (kept as-is to match current usage).
 */
(function main() {
  try {
    const manifestPath = path.resolve('lake-manifest.json');

    if (!fs.existsSync(manifestPath)) {
      console.error(`File not found: ${manifestPath}`);
      process.exit(1);
    }

    const raw = fs.readFileSync(manifestPath, 'utf8');
    const json = JSON.parse(raw);

    const pkgs = json && json.packages;
    let hasDeps = false;

    if (Array.isArray(pkgs)) {
      hasDeps = pkgs.length > 0;
    } else if (pkgs && typeof pkgs === 'object') {
      hasDeps = Object.keys(pkgs).length > 0;
    } else {
      // If packages is missing or not an object/array, treat as no dependencies
      hasDeps = false;
    }

    const outcome = hasDeps ? 'has-depencency' : 'no-depencency';
    console.log(hasDeps ? 'The repository has some dependencies.' : 'The repository has no dependencies.');

    const githubOutput = process.env.GITHUB_OUTPUT;
    if (githubOutput) {
      fs.appendFileSync(githubOutput, `outcome=${outcome}\n`);
    } else {
      // Fallback for environments without GITHUB_OUTPUT
      console.log(`::set-output name=outcome::${outcome}`);
    }
  } catch (err) {
    console.error('Error while checking dependencies:', err && err.message ? err.message : err);
    process.exit(1);
  }
})();

