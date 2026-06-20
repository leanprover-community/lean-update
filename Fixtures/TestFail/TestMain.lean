def main : IO Unit :=
  throw <| IO.userError "intentional test failure"
