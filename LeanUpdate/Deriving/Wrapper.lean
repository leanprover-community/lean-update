module

public import Lean.Elab.Deriving.Basic
import Lean.Elab.Command
import Lean.Elab.Term.TermElabM
import Lean.Elab.Deriving.Util
import Lean.Structure
public import LeanUpdate.Wrapper

open Lean Elab Command Meta

namespace LeanUpdate.Deriving.Wrapper

open Lean.Elab.Deriving
open Lean.Parser.Term

private partial def mkWrappedTypeSyntax (wrappedType : Expr) : TermElabM Term := do
  match ← instantiateMVars wrappedType with
  | .const typeName _ => pure <| mkCIdent typeName
  | .app fn arg => do
      let fnStx ← mkWrappedTypeSyntax fn
      let argStx ← mkWrappedTypeSyntax arg
      `($fnStx:term $argStx:term)
  | .mdata _ wrappedType => mkWrappedTypeSyntax wrappedType
  | wrappedType =>
      throwError "deriving Wrapper only supports fields whose type can be rendered as a type expression, but found{indentExpr wrappedType}"

/--
Derive `Wrapper` for a structure with exactly one field.

The generated `Wrapper` instance unwraps values using the field projection.
-/
private def mkWrapperInstance (declName : Name) : TermElabM Command := do
  let indVal ← getConstInfoInduct declName
  unless indVal.numParams == 0 do
    throwError "deriving Wrapper only supports structures without parameters"
  unless indVal.numIndices == 0 do
    throwError "deriving Wrapper only supports structures without indices"

  let some structInfo := getStructureInfo? (← getEnv) declName
    | throwError "deriving Wrapper only supports structures"
  unless structInfo.fieldNames.size == 1 do
    throwError "deriving Wrapper only supports structures with exactly one field"

  let fieldName := structInfo.fieldNames[0]!
  let some projFn := getProjFnForField? (← getEnv) declName fieldName
    | throwError "failed to find projection for field `{fieldName}`"
  let projInfo ← getConstInfo projFn
  let wrappedType ← forallTelescopeReducing projInfo.type fun xs wrappedType => do
    unless xs.size == 1 do
      throwError "unexpected projection type for field `{fieldName}`"
    return wrappedType

  let typeName := mkCIdent declName
  let wrappedTypeStx ← mkWrappedTypeSyntax wrappedType
  let wrapperClass := mkCIdent ``_root_.Wrapper
  let proj := mkCIdent projFn
  `(instance : $wrapperClass:ident $typeName:ident where
      wrappedType := $wrappedTypeStx:term
      unwrap := $proj:ident)

private def mkWrapperInstanceHandler (declNames : Array Name) : CommandElabM Bool := do
  if !(← declNames.allM isInductive) || declNames.isEmpty then
    return false
  for declName in declNames do
    withoutExposeFromCtors declName do
      let cmd ← liftTermElabM <| mkWrapperInstance declName
      elabCommand cmd
  return true

initialize
  registerDerivingHandler ``_root_.Wrapper mkWrapperInstanceHandler

end LeanUpdate.Deriving.Wrapper
