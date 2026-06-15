module

public import LeanUpdate.HasParser

/-- A type that wraps a value of another type. -/
public class Wrapper (α : Type u) where
  /-- The type of the wrapped value. -/
  wrappedType : Type v
  /-- Construct a wrapper value from the wrapped value. -/
  wrap : wrappedType → α
  /-- Extract the wrapped value. -/
  unwrap : α → wrappedType

/-- Any `Wrapper` can be coerced to its wrapped value. -/
public instance [w : Wrapper α] : CoeOut α w.wrappedType where
  coe := w.unwrap
