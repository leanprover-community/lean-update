module

/-- A type that can be parsed from a string. -/
public class HasParser (α : Type) where
  parseFn : String → Except String α

/-- Parse a string as a value of the given type. -/
public def HasParser.parse (α : Type) [HasParser α] (s : String) : Except String α :=
  HasParser.parseFn s

/-- parse a string into a `Bool` -/
public def Bool.parse (s : String) : Except String Bool :=
  match s.toLower with
  | "true" => .ok true
  | "false" => .ok false
  | _ => throw s!"Invalid boolean value: '{s}'. Allowed values are 'true' and 'false'."

public instance : HasParser Bool where
  parseFn := Bool.parse
