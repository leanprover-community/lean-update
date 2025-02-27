# Lean Update

A GitHub Action that attempts to update Lean and dependencies of a Lean project. This is basically a fork of [oliver-butterley/lean-update](https://github.com/oliver-butterley/lean-update) but more feature-rich.

## Description of Functionality

1. This Action first installs [elan](https://github.com/leanprover/elan) and runs `lake update`. This fetches any new Lean prereleases or releases and updates all dependent packages to their latest versions.

1. If `lake update` determines that all dependencies are already up to date, this Action does nothing further.

1. Subsequently, this GitHub Action calls another GitHub Action called [lean-action](https://github.com/leanprover/lean-action) to check if the updated code works correctly. This performs the build process, runs tests if a test driver is configured, and executes lint checks if a lint driver is set up. Whether to perform tests or lint checks is automatically determined by lean-action.

1. This Action classifies the results of lean-action into two categories: success or failure.
    1. If successful, it behaves according to the setting specified in the `on_update_succeeds` option. By default, this is set to `pr`, which submits the updated code as a pull request. However, if the `what_to_update` option is set to `lean-toolchain`, the Action does nothing unless the Lean version has been updated.
    1. If it fails, it behaves according to the setting specified in the `on_update_fails` option. By default, this is set to `issue`, which submits an issue indicating that the update failed.

## Usage Examples

I am using this GitHub Action in the following repository. This might be helpful as a reference.

* <https://github.com/Seasawher/mathlib4-help> This repository runs this action daily to update the output whenever mathlib is updated.
* <https://github.com/lean-ja/lean-by-example> This repository verifies that code examples work with the latest mathlib to ensure their correctness. However, since updating mathlib requires rebuilding it in the local development environment, PRs are only created when `lean-toolchain` is updated.
