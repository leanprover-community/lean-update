import Lake
open Lake DSL

package "LeanUpdate" where
  version := v!"0.1.0"

@[default_target]
lean_lib «LeanUpdate» where
  -- add library configuration options here
  globs := #[.one `LeanUpdate, .submodules `LeanUpdate]
  leanOptions := #[
    ⟨`linter.missingDocs, true⟩
  ]

lean_exe leanUpdate where
  root := `Main

@[test_driver]
lean_exe updateDependenciesEnvTest where
  root := `Test.UpdateDependenciesEnv
