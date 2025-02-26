# Lean Update

A GitHub Action that attempts to update Lean and dependencies of a Lean project. This is basically a fork of [oliver-butterley/lean-update](https://github.com/oliver-butterley/lean-update) but more feature-rich.

## Usage

I am using this GitHub Action in the following repository. This might be helpful as a reference.

* <https://github.com/Seasawher/mathlib4-help> This repository runs this action daily to update the output whenever mathlib is updated.
* <https://github.com/lean-ja/lean-by-example> This repository verifies that code examples work with the latest mathlib to ensure their correctness. However, since updating mathlib requires rebuilding it in the local development environment, PRs are only created when `lean-toolchain` is updated.
