import Lake
open Lake DSL

package "LeanUpdate" where
  version := v!"0.1.0"

@[default_target]
lean_lib «LeanUpdate» where
  -- add library configuration options here
  globs := #[.submodules `LeanUpdate]
  leanOptions := #[
    ⟨`linter.missingDocs, true⟩
  ]

@[test_driver]
lean_exe updateDependenciesEnvTest where
  root := `Test.UpdateDependenciesEnv
