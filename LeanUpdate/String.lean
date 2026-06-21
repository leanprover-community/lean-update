module

/-- truncate string -/
public def String.truncateWithNotice (s truncationNotice : String) (maxLength : Nat) : String :=
  if s.length ≤ maxLength then
    s
  else if truncationNotice.length < maxLength then
    (s.take (maxLength - truncationNotice.length)).copy ++ truncationNotice
  else
    (s.take maxLength).copy

/-- the specification for `String.truncateWithNotice` -/
theorem String.truncateWithNotice_spec (s notice : String) (max : Nat) :
  (String.truncateWithNotice s notice max).length ≤ max := by
  fun_cases String.truncateWithNotice s notice max
  case case1 =>
    assumption
  case case2 if1 if2 =>
    simp only [length_append]
    rw [← length_toList, toList_copy_take, List.length_take]
    rw [length_toList]
    omega
  case case3 if1 if2 =>
    rw [← length_toList, toList_copy_take, List.length_take]
    rw [length_toList]
    omega
