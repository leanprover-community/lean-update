import Lake
open Lake DSL

package "Src" where
  version := v!"0.1.0"

@[default_target]
lean_lib «Src» where
  -- add library configuration options here
  globs := #[.submodules `Src]
  leanOptions := #[
    ⟨`linter.missingDocs, true⟩
  ]

@[default_target]
lean_exe findDependencies where
  root := `Src.FindDep
