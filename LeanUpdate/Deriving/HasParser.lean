module

public import Lean.Elab.Deriving.Basic
import Lean.Elab.Command
import Lean.Elab.Term.TermElabM
import Lean.Elab.Deriving.Util
public import LeanUpdate.HasParser

open Lean Elab Command Meta

namespace LeanUpdate.Deriving.HasParser

open Lean.Elab.Deriving
open Lean.Parser.Term

private def quoteValue (value : String) : String :=
  "'" ++ value ++ "'"

private def formatAllowedValues (values : Array String) : String :=
  String.intercalate ", " <| values.toList.map quoteValue

/--
Derive `HasParser` for enum-like inductive types.

Each constructor must have no fields. Parsing is case-insensitive, and matches
the final component of each constructor name.
-/
private def mkHasParserEnumCommands (declName : Name) : TermElabM (Array Command) := do
  let indVal ← getConstInfoInduct declName
  unless indVal.numParams == 0 do
    throwError "deriving HasParser only supports enum types without parameters"
  unless indVal.numIndices == 0 do
    throwError "deriving HasParser only supports enum types without indices"

  let mut alts := #[]
  let mut values := #[]
  for ctorName in indVal.ctors do
    let ctorInfo ← getConstInfoCtor ctorName
    unless ctorInfo.numFields == 0 do
      throwError "deriving HasParser only supports enum constructors without fields"
    let ctorStr := ctorInfo.name.eraseMacroScopes.getString!
    let normalizedCtorStr := ctorStr.toLower
    values := values.push normalizedCtorStr
    let alt ← `(matchAltExpr| | $(quote normalizedCtorStr) => .ok $(mkIdent ctorInfo.name):ident)
    alts := alts.push alt

  let parseName := declName ++ `parse
  let typeName := mkCIdent declName
  let typeStr := declName.eraseMacroScopes.getString!
  let errorPrefix := "Invalid " ++ typeStr ++ ": '"
  let errorSuffix := "'. Allowed values are " ++ formatAllowedValues values ++ "."
  let parserClass := mkCIdent ``_root_.HasParser

  let parseCmd ←
    `(public def $(mkIdent parseName):ident (s : String) : Except String $typeName:ident :=
        match s.toLower with
        $alts:matchAlt*
        | _ => .error ($(quote errorPrefix) ++ s ++ $(quote errorSuffix)))
  let instCmd ←
    `(instance : $parserClass:ident $typeName:ident where
        parseFn := $(mkIdent parseName):ident)
  return #[parseCmd, instCmd]

private def mkHasParserEnumInstanceHandler (declNames : Array Name) : CommandElabM Bool := do
  if !(← declNames.allM isInductive) || declNames.isEmpty then
    return false
  for declName in declNames do
    withoutExposeFromCtors declName do
      let cmds ← liftTermElabM <| mkHasParserEnumCommands declName
      cmds.forM elabCommand
  return true

initialize
  registerDerivingHandler ``_root_.HasParser mkHasParserEnumInstanceHandler

end LeanUpdate.Deriving.HasParser
