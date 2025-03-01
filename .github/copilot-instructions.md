## Notes for scripts called from action.yml

* Using `set-output` is deprecated. Use the `GITHUB_OUTPUT` environment variable instead.
* The content in `action.yml` and the `## Details of Option` section in `README.md` must always be in sync.
  * Therefore, whenever you modify `action.yml`, also update `README.md` accordingly.
  * When instructed to "sync", please verify that the content in `action.yml` and `README.md` are synchronized, and update them if they are not in sync.