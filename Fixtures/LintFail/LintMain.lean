def main : IO Unit :=
  throw <| IO.userError "intentional lint failure"
