module

open Lean

/-- add gray color to a string in terminal -/
public def gray (s : String) : String :=
  s!"\x1b[38;5;244m{s}\x1b[0m"

/-- gray code syntax in terminal -/
syntax (name := grayCode) "``" noWs ident "``" : term

macro_rules
  | `( ``$id`` ) => `(term| gray <| toString $id)

/-- add green color to a string in terminal -/
public def green (s : String) : String :=
  s!"\x1b[38;5;10m{s}\x1b[0m"

/-- add orange color to a string in terminal -/
public def orange (s : String) : String :=
  s!"\x1b[38;5;208m{s}\x1b[0m"

/-- add bright blue color to a string in terminal -/
public def blue (s : String) : String :=
  s!"\x1b[94m{s}\x1b[0m"

/-- add header for log messages -/
syntax "log%" term : term

macro_rules
  | `(log% $msg) => `(term|
    let header := blue s!"[{decl_name%}]"
    s!"{header}: { $msg }"
  )
