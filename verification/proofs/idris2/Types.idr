-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- Typing Proof: Core data type well-formedness
-- Template — replace with your project's core types.
-- All proofs MUST be constructive (no believe_me, no assert_total).

module Types

import Data.Nat

%default total

||| Example: A bounded natural number (0 to bound).
||| Replace with your project's core types.
|||
||| `inBounds` is ERASED (quantity 0). The recorded quarantine reason —
||| an erased field "is not accessible in this context" — pointed at the
||| ACCESSOR, not the field: `boundedLeMax` returns a proof, so it is a
||| proof and belongs at quantity 0 itself. De-erasing the field also
||| compiles, but it costs the newtype-transparent representation (measured:
||| `Bounded` becomes a two-field heap allocation) to buy nothing. See the
||| same reasoning, and the same repair, in ABI/Pointers.idr.
public export
record Bounded (bound : Nat) where
  constructor MkBounded
  value : Nat
  {auto 0 inBounds : LTE value bound}

||| Proof that a Bounded value is always <= bound.
||| Quantity 0: it is a proof, not a runtime function.
export
0 boundedLeMax : (b : Bounded bound) -> LTE b.value bound
boundedLeMax b = b.inBounds

||| Proof that zero is always a valid Bounded value.
export
zeroIsBounded : {bound : Nat} -> Bounded (S bound)
zeroIsBounded = MkBounded 0

||| Example: A non-empty list with a compile-time guarantee.
public export
data NonEmpty : List a -> Type where
  IsNonEmpty : NonEmpty (x :: xs)

||| Proof that cons always produces a non-empty list.
export
consIsNonEmpty : (x : a) -> (xs : List a) -> NonEmpty (x :: xs)
consIsNonEmpty _ _ = IsNonEmpty
