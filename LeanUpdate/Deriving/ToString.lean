module

public import Lean.Elab.Deriving.Basic
import Lean.Elab.Command
import Lean.Elab.Term.TermElabM
import Lean.Elab.Deriving.Util
public import Init.Data.ToString.Basic

open Lean Elab Command Meta

namespace LeanUpdate.Deriving.ToString

open Lean.Elab.Deriving
open Lean.Parser.Term

/--
Derive `ToString` for enum-like inductive types.

Each constructor must have no fields. The derived string is the final component
of the constructor name, e.g. `ReleaseKindToFetch.tagged` becomes `"tagged"`.
-/
private def mkToStringEnumInstance (declName : Name) : TermElabM Command := do
  let indVal ← getConstInfoInduct declName
  unless indVal.numParams == 0 do
    throwError "deriving ToString only supports enum types without parameters"
  unless indVal.numIndices == 0 do
    throwError "deriving ToString only supports enum types without indices"

  let mut alts := #[]
  for ctorName in indVal.ctors do
    let ctorInfo ← getConstInfoCtor ctorName
    unless ctorInfo.numFields == 0 do
      throwError "deriving ToString only supports enum constructors without fields"
    let ctorStr := ctorInfo.name.eraseMacroScopes.getString!
    let alt ← `(matchAltExpr| | @$(mkIdent ctorInfo.name):ident => $(quote ctorStr))
    alts := alts.push alt

  let typeName := mkCIdent declName
  `(instance : ToString $typeName:ident := ⟨fun $alts:matchAlt*⟩)

private def mkToStringEnumInstanceHandler (declNames : Array Name) : CommandElabM Bool := do
  if !(← declNames.allM isInductive) || declNames.isEmpty then
    return false
  for declName in declNames do
    withoutExposeFromCtors declName do
      let cmd ← liftTermElabM <| mkToStringEnumInstance declName
      elabCommand cmd
  return true

initialize
  registerDerivingHandler ``_root_.ToString mkToStringEnumInstanceHandler

end LeanUpdate.Deriving.ToString
