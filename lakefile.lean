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
  requiresModuleSystem := true

lean_exe leanUpdate where
  root := `Main
  supportInterpreter := true

lean_lib «LeanUpdateTest» where
  globs := #[.submodules `Test]

@[test_driver]
lean_exe run_test where
  root := `Test.Main
