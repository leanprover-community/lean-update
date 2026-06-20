module
import Init.Data.String.Lemmas.TakeDrop

/-- A `SizedStr n` is a string with length at most `n`. -/
@[expose]
public def SizedStr (n : Nat) := { s : String // s.length ≤ n }

public instance {n : Nat} : ToString (SizedStr n) where
  toString s := s.val

theorem SizedStr.take_spec (s : String) (n : Nat) : (s.take n).copy.length ≤ n := by
  rw [← String.length_toList, String.toList_copy_take]
  exact List.length_take_le n s.toList

grind_pattern SizedStr.take_spec => s.take n, String.length _

/-- `take` returns a `SizedStr` with length at most `n`. -/
public def SizedStr.take (s : String) (n : Nat) : SizedStr n :=
  ⟨s.take n |>.copy, by grind⟩

theorem SizedStr.append_spec {m n : Nat} (s1 : SizedStr m) (s2 : SizedStr n) : (s1.val ++ s2.val).length ≤ m + n := by
  rw [String.length_append]
  exact Nat.add_le_add s1.property s2.property

/-- `append` concatenates two `SizedStr`s, resulting in a `SizedStr`. -/
public def SizedStr.append {m n : Nat} (s1 : SizedStr m) (s2 : SizedStr n) : SizedStr (m + n) :=
  ⟨s1.val ++ s2.val, by exact SizedStr.append_spec s1 s2⟩
