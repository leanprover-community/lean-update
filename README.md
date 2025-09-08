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
    # this is needed for private repositories
    permissions:
      contents: write
      pull-requests: write
      issues: write

    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v5

      - name: Update Lean project
        uses: leanprover-community/lean-update@main
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
    # this is needed for private repositories
    permissions:
      contents: write
      pull-requests: write
      issues: write

    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v5
      - name: Update Lean project
        uses: leanprover-community/lean-update@main
        with:
          update_if_modified: lean-toolchain
```

### If you want to receive notifications on Zulip when the update fails

1. First, create a bot in Zulip and note its API key. Be careful not to create a new account - Zulip has a dedicated feature for "creating a bot".
2. Next, register the bot's API key as a secret named `ZULIP_API_KEY` in your repository. You can set up secrets from the repository's "Settings".
3. Prepare a workflow file like the following:

```yml
name: Update Lean Project

on:
  schedule:
    - cron: "0 0 * * *" # every day
  workflow_dispatch: # allows workflow to be triggered manually

jobs:
  update_lean:
    # this is needed for private repositories
    permissions:
      contents: write
      pull-requests: write
      issues: write

    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v5

      - name: Update Lean project
        id: lean-update
        uses: leanprover-community/lean-update@main
        with:
          on_update_fails: "silent"

      - name: Notification
        if: steps.lean-update.outputs.result == 'update-fail'  # only send a message when the update fails
        uses: zulip/github-actions-zulip/send-message@v1
        with:
          api-key: ${{ secrets.ZULIP_API_KEY }} # Zulip API key of your bot
          email: "***-bot@leanprover.zulipchat.com" # your Zulip bot's email
          organization-url: 'https://leanprover.zulipchat.com'
          to: "123456" # user_id
          type: "private" # private message
          content: |
             ❌ The update of ${{ github.repository }} has failed

             - [See Action Run](https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }})
             - [See Commit](https://github.com/${{ github.repository }}/commit/${{ github.sha }})
```

## Description of Functionality

1. This Action first installs [elan](https://github.com/leanprover/elan) and runs `lake update`. This fetches any new Lean prereleases or releases and updates all dependent packages to their latest versions.

1. If `lake update` determines that all dependencies are already up to date, this Action does nothing further.

1. Subsequently, this GitHub Action calls another GitHub Action called [lean-action](https://github.com/leanprover/lean-action) to check if the updated code works correctly. This performs the build process, runs tests if a test driver is configured, and executes lint checks if a lint driver is set up. Whether to perform tests or lint checks is automatically determined by lean-action. However, you can configure what build arguments are passed to `lake build` when lean-action is executed using the `build_args` option.

1. This Action classifies the results of lean-action into two categories: success or failure.
    1. If successful, it behaves according to the setting specified in the `on_update_succeeds` option. By default, this is set to `pr`, which submits the updated code as a pull request. However, if the `update_if_modified` option is set to `lean-toolchain`, the Action does nothing unless the Lean version has been updated.
    1. If it fails, it behaves according to the setting specified in the `on_update_fails` option. By default, this is set to `issue`, which submits an issue indicating that the update failed.

## Details of Option

### `on_update_succeeds`

What to do when an update is available and the build is successful.

Allowed values:
* `silent`: Do nothing
* `commit`: directly commit the updated files
* `issue`: notify the user by creating an issue. No new issue will be created if one already exists.
* `pr`: notify the user by creating a pull request. No new PR will be created if one already exists.

Default: `pr`.

### `on_update_fails`

What to do when an update is available and the build fails.

Allowed values:
* `silent`: Do nothing
* `issue`: notify the user by creating an issue. No new issue will be created if one already exists.
* `pr`: notify the user by creating a pull request. No new PR will be created if one already exists.

Default: `issue`.

### `update_if_modified`

Specifies which files, when updated during `lake update`, will cause the action to update code or notify the user.
This option does not affect the behavior when the build/test/lint fail after `lake update`.

Allowed values:
* `lean-toolchain`:
  If `lean-toolchain` is specified, this GitHub Action will skip updates unless the Lean version is updated.
  Here, "skipping updates" means "not attempting to update code or send notifications when the build/test/lint succeed after lake update".
* `lake-manifest.json`: if `lake-manifest.json` is specified, this GitHub Action will perform an update if any dependent package is updated.

Default: `lake-manifest.json`

### `build_args`

This GitHub Action uses leanprover/lean-action to build and test the repository.
This parameter determines what to pass to the build-args argument of leanprover/lean-action.

Default: `--log-level=warning`

### `lake_package_directory`

The directory containing the Lake package to build.
This parameter is passed to the lake-package-directory argument of leanprover/lean-action.

Default: `.`

### `update_lean_toolchain`

Controls whether to update the lean-toolchain file for projects with no dependencies.

Allowed values:
* `auto`: Automatically update lean-toolchain to the latest stable release (default behavior)
* `never`: Never update the lean-toolchain file

Default: `auto`

### `token`

A Github token to be used for committing and creating issues/PRs.

Default: `${{ github.token }}`

### `legacy_update`

If set to `true`, executes `lake -R -Kenv=dev update` instead of `lake update`.

Default: `false`

## Outputs

### `result`

The action outputs `no-update`, `update-success` or `update-fail` depending on the three possible scenarios.

Description of each value:
* `no-update`: No update was available.
* `update-success`: An update was available and lean-action step was successful.
* `update-fail`: An update was available but the lean-action step failed.

### `latest_lean`

The latest Lean release version, including both stable and pre-release versions.

### `notify`

Indicates whether there is an event worth notifying the user about.
Returns `true` in the following cases:
* When updates are available and the build succeeds. However, if `update_if_modified` is set to `lean-toolchain`, this is only true when the Lean version has been updated.
* When updates are available and the build fails.
Returns `false` in all other cases.
