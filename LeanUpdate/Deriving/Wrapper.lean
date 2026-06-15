module

public import Lean.Elab.Deriving.Basic
import Lean.Elab.Command
import Lean.Elab.Term.TermElabM
import Lean.Elab.Deriving.Util
import Lean.Structure
public import LeanUpdate.HasParser
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

The generated `Wrapper` instance wraps values using structure instance syntax
and unwraps values using the field projection. It also generates a `HasParser`
instance whenever the wrapped type has one.
-/
private def mkWrapperCommands (declName : Name) : TermElabM (Array Command) := do
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
  let hasParserClass := mkCIdent ``_root_.HasParser
  let hasParserParse := mkCIdent ``_root_.HasParser.parse
  let wrapFn := mkCIdent ``_root_.Wrapper.wrap
  let proj := mkCIdent projFn
  let field := mkIdent fieldName
  let wrapperCmd ← `(instance : $wrapperClass:ident $typeName:ident where
      wrappedType := $wrappedTypeStx:term
      wrap := fun x => {$field:ident := x}
      unwrap := $proj:ident)
  let hasParserCmd ←
    `(instance [$hasParserClass:ident $wrappedTypeStx:term] : $hasParserClass:ident $typeName:ident where
        parse s := do
          let value ← ($hasParserParse:ident s : Except String $wrappedTypeStx:term)
          pure <| $wrapFn:ident (α := $typeName:ident) value)
  return #[wrapperCmd, hasParserCmd]

private def mkWrapperInstanceHandler (declNames : Array Name) : CommandElabM Bool := do
  if !(← declNames.allM isInductive) || declNames.isEmpty then
    return false
  for declName in declNames do
    withoutExposeFromCtors declName do
      let cmds ← liftTermElabM <| mkWrapperCommands declName
      cmds.forM elabCommand
  return true

initialize
  registerDerivingHandler ``_root_.Wrapper mkWrapperInstanceHandler

end LeanUpdate.Deriving.Wrapper
