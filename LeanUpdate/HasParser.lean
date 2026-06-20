module

/-- A type that can be parsed from a string. -/
public class HasParser (α : Type) where
  parse : String → Except String α

/-- Parse a string as a value of the given type. -/
public def parseAs (α : Type) [HasParser α] (s : String) : Except String α :=
  HasParser.parse s


/- ## concrete instances

This section defines `HasParser` instances for concrete types used in this project.
-/
section

public instance : HasParser String where
  parse s := .ok s

/-- parse a string into a `Bool` -/
public def Bool.parse (s : String) : Except String Bool :=
  match s.toLower with
  | "true" => .ok true
  | "false" => .ok false
  | _ => throw s!"Invalid boolean value: '{s}'. Allowed values are 'true' and 'false'."

public instance : HasParser Bool where
  parse := Bool.parse

public instance : HasParser System.FilePath where
  parse s := .ok (System.FilePath.mk s)

end

/- ## inductive instances

This section defines `HasParser` instances for polymorphic types, such as `List α` or `Option α`
where `α` has a `HasParser` instance.
-/
section

/-- internal auxiliary function for parsing lists -/
public def parseListAux [HasParser α] (input : List String) : Except String (List α) :=
  let filterInput := input.filter (fun s => s != "")
  have : filterInput.length ≤ input.length := by grind
  match filterInput with
  | [] => .ok []
  | head :: rest => do
    let headParsed ← parseAs α head
    let restParsed ← parseListAux rest
    .ok (headParsed :: restParsed)
termination_by input.length

/-- parse a string into a list of elements of type `α` -/
public def parseList [HasParser α] (input : String) : Except String (List α) :=
  let inner := input
    |> (fun s : String => if s.startsWith "[" then s.drop 1 |>.copy else s)
    |> (fun s : String => if s.endsWith "]" then s.dropEnd 1 |>.copy else s)
    |> (String.replace · "," "")
  let parts := inner.splitOn " "
  parseListAux parts

public instance [HasParser α] : HasParser (List α) where
  parse s := parseList s

#guard
  let actual := parseAs (List Bool) "[true, false, true]"
  let expected := [true, false, true]
  actual.toOption == some expected

#guard
  let actual := parseAs (List String) "foo, bar, baz"
  let expected := ["foo", "bar", "baz"]
  actual.toOption == some expected

#guard
  let actual := parseAs (List String) "[]"
  let expected := []
  actual.toOption == some expected

#guard
  let actual := parseAs (List String) "   "
  let expected := []
  actual.toOption == some expected

end
