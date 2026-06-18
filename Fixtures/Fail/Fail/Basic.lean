def hello := "world"

inductive BinTree (α : Type) where
  | empty : BinTree α
  | node : α → BinTree α → BinTree α → BinTree α
deriving Repr

def leaf {α : Type} (a : α) : BinTree α := .node a .empty .empty

def BinTree.nodes {α : Type} : BinTree α → Nat
| .empty => 0
| .node _ l r => 1 + l.nodes + r.nodes

def BinTree.isCBalanced {α : Type} : BinTree α → Bool
  | .empty => true
  | .node _ l r =>
    Int.natAbs ((l.nodes : Int) - (r.nodes : Int)) ≤ 1 && l.isCBalanced && r.isCBalanced

namespace ListMonad

/-- monad instance of `List` -/
scoped instance : Monad List where
  pure := List.singleton
  bind := List.flatMap
  map := List.map

end ListMonad

open scoped ListMonad

/-- construct all completely balanced binary trees which contains `x` elements -/
partial def cbalTree (x : Nat) : List (BinTree Unit) :=
  match x with
  | 0 => [.empty]
  | n + 1 => do
    let q := n / 2
    let r := n % 2
    let indices := List.range (q+r+1) |>.drop q
    let i ← indices
    let left ← cbalTree i
    let right ← cbalTree (n - i)
    pure (BinTree.node () left right)

-- The following codes are for test and you should not edit these.

#eval (cbalTree 3).length = 1
#eval (cbalTree 3)|>.map BinTree.isCBalanced |>.and
#eval (cbalTree 4)|>.map BinTree.isCBalanced |>.and
#eval (cbalTree 4).length = 4
#eval (cbalTree 5)|>.map BinTree.isCBalanced |>.and
#eval (cbalTree 6)|>.map BinTree.isCBalanced |>.and
#eval (cbalTree 7).length = 1
