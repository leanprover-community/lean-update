# Lean Update

A GitHub Action that attempts to update Lean and dependencies of a Lean project. This is basically a fork of [oliver-butterley/lean-update](https://github.com/oliver-butterley/lean-update) but more feature-rich.

## Quick Setup

Create a file named `update.yml` in the `.github/workflows` directory.

### If you want to keep dependencies always up-to-date

To keep dependencies always up-to-date, you might want to configure as follows:

```yml
name: Update Lean Project

on:
  schedule:
    - cron: "0 0 * * *" # every day
  workflow_dispatch: # allows workflow to be triggered manually

jobs:
  update_lean:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
      issues: write
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Update Lean project
        uses: Seasawher/lean-update@main
```

### When you only want to update when there is a new Lean version

If you want to skip updates unless there is a change to the `lean-toolchain` file, you might want to configure as follows:

```yml
name: Update Lean Project

on:
  schedule:
    - cron: "0 0 * * *" # every day
  workflow_dispatch: # allows workflow to be triggered manually

jobs:
  update_lean:
    runs-on: ubuntu-latest
    permissions:
      issues: write
      pull-requests: write
      contents: write
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Update Lean project
        uses: Seasawher/lean-update@main
        with:
          update_if_modified: lean-toolchain
```

## Description of Functionality

1. This Action first installs [elan](https://github.com/leanprover/elan) and runs `lake update`. This fetches any new Lean prereleases or releases and updates all dependent packages to their latest versions.

1. If `lake update` determines that all dependencies are already up to date, this Action does nothing further.

1. Subsequently, this GitHub Action calls another GitHub Action called [lean-action](https://github.com/leanprover/lean-action) to check if the updated code works correctly. This performs the build process, runs tests if a test driver is configured, and executes lint checks if a lint driver is set up. Whether to perform tests or lint checks is automatically determined by lean-action. However, you can configure what build arguments are passed to `lake build` when lean-action is executed using the `build_args` option.

1. This Action classifies the results of lean-action into two categories: success or failure.
    1. If successful, it behaves according to the setting specified in the `on_update_succeeds` option. By default, this is set to `pr`, which submits the updated code as a pull request. However, if the `update_if_modified` option is set to `lean-toolchain`, the Action does nothing unless the Lean version has been updated.
    1. If it fails, it behaves according to the setting specified in the `on_update_fails` option. By default, this is set to `issue`, which submits an issue indicating that the update failed.

## Details of Option

* `on_update_succeeds`: What to do when an update is available and the build is successful.
    * Allowed values: "silent", "commit", "issue" or "pr".
    * Default: "pr".
* `on_update_fails`: What to do when an update is available but the build fails.
    * Allowed values: "silent", "commit", "issue" or "pr".
    * Default: "issue".
* `update_if_modified`: Specifies which files, when updated during `lake update`, will cause the action to skip updates. For example, if "lean-toolchain" is specified, this GitHub Action will skip updates unless the Lean version is updated. Also, for example, if "lake-manifest.json" is specified, this GitHub Action will not skip updates as long as any dependent package is updated. Here, "skipping updates" means "not attempting to update code or send notifications when the build/test/lint succeed after lake update". Therefore, this option does not affect the behavior when the build/test/lint fail after lake update.
    * Allowed values: "lean-toolchain", "lake-manifest.json".
    * Default: "lake-manifest.json".
* `build_args`: Arguments to pass to the lean-action build process.
    * Example: "--log-level=warning --fail-level=warning"
    * Default: "--log-level=warning".

## Usage Examples

I am using this GitHub Action in the following repository. This might be helpful as a reference.

* <https://github.com/Seasawher/mathlib4-help> This repository runs this action daily to update the output whenever mathlib is updated.
* <https://github.com/lean-ja/lean-by-example> This repository verifies that code examples work with the latest mathlib to ensure their correctness. However, since updating mathlib requires rebuilding it in the local development environment, PRs are only created when `lean-toolchain` is updated.
