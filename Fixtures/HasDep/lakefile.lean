import Lake
open Lake DSL

package "HasDep" where
  version := v!"0.1.0"

require plausible from git
  "https://github.com/leanprover-community/plausible" @ "main"

@[default_target]
lean_lib «HasDep» where
  -- add library configuration options here
