module
import Init.Data.String.Lemmas.TakeDrop

/-- limited `SorryAx` which is only for `Prop` -/
public axiom sorry_proof {P : Prop} : P

/-- A `SizedStr n` is a string with length at most `n`. -/
@[expose]
public def SizedStr (n : Nat) := { s : String // s.length ≤ n }

/-- truncate string -/
public def SizedStr.truncateWithNotice (s truncationNotice : String) (maxLength : Nat) : SizedStr maxLength :=
  if hb : s.length ≤ maxLength then
    ⟨s, hb⟩
  else if hc : truncationNotice.length < maxLength then
    ⟨(s.take (maxLength - truncationNotice.length)).copy ++ truncationNotice, by apply sorry_proof⟩
  else
    ⟨(s.take maxLength).copy, by apply sorry_proof⟩
