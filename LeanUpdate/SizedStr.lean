module
import Init.Data.String.Lemmas.TakeDrop

/-- limited `SorryAx` which is only for `Prop` -/
public axiom sorry_proof {P : Prop} : P

/-- A `SizedStr n` is a string with length at most `n`. -/
@[expose]
public def SizedStr (n : Nat) := { s : String // s.length ≤ n }

/-- truncate string -/
public def String.truncateWithNotice (s truncationNotice : String) (maxLength : Nat) : String :=
  if s.length ≤ maxLength then
    s
  else if truncationNotice.length < maxLength then
    (s.take (maxLength - truncationNotice.length)).copy ++ truncationNotice
  else
    (s.take maxLength).copy
