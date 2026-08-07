-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- ABI Proof: C ABI compliance
-- Proves that struct layouts are C ABI compliant.
-- All proofs MUST be constructive (no believe_me, no assert_total).

module ABI.Compliance

import Data.Nat

import ABI.Layout
import ABI.Platform

%default total

||| Evidence that every field in a layout is correctly aligned.
public export
data AllFieldsAligned : List StructField -> Type where
  AFANil  : AllFieldsAligned []
  AFACons : FieldAligned f -> AllFieldsAligned fs -> AllFieldsAligned (f :: fs)

||| Evidence that every field is within the struct bounds.
|||
||| AFBCons states `FieldInBounds size f` UNFOLDED (`LTE (fieldOffset f +
||| fieldSize f) size`): with the type-synonym head, idris2 0.7.0's
||| positivity checker fails the whole module with "Data.Nat.LTE not a data
||| type" and no source location. The two spellings are definitionally the
||| same type; ABI.Layout.FieldInBounds remains the canonical statement.
public export
data AllFieldsInBounds : (size : Nat) -> List StructField -> Type where
  AFBNil  : AllFieldsInBounds size []
  AFBCons : LTE (fieldOffset f + fieldSize f) size -> AllFieldsInBounds size fs -> AllFieldsInBounds size (f :: fs)

||| A struct layout is C ABI compliant when:
||| 1. All fields are aligned to their natural alignment
||| 2. All fields are within bounds of the struct size
||| 3. The struct size is a multiple of the struct alignment
|||
||| `sizeAligned` is stated as non-zero-alignment + divisibility, for the same
||| reason as `FieldAligned` in ABI.Layout: `SIsNonZero` cannot unify with an
||| arbitrary `layoutAlignment layout`, and divisibility ALONE would admit
||| `layoutAlignment = 0` (discharged by `(0 ** Refl)` when the size is also
||| 0) — certifying a struct that C cannot have, since C guarantees
||| `sizeof >= 1` and `alignof >= 1`. The `NonZero` conjunct is what keeps
||| this at least as strong as the mod phrasing it replaced.
public export
record CABICompliant (layout : StructLayout) where
  constructor MkCompliant
  fieldsAligned  : AllFieldsAligned (layoutFields layout)
  fieldsInBounds : AllFieldsInBounds (layoutSize layout) (layoutFields layout)
  sizeAligned    : (NonZero (layoutAlignment layout), (k ** layoutSize layout = k * layoutAlignment layout))

||| An empty struct is trivially compliant (size=1, alignment=1; 1 = 1 * 1).
||| The obligation is real, not decorative: substituting `(2 ** Refl)` for
||| `(1 ** Refl)` is rejected, because `1 = 2 * 1` does not reduce.
export
emptyStructCompliant : CABICompliant (MkLayout "empty" [] 1 1)
emptyStructCompliant = MkCompliant AFANil AFBNil (SIsNonZero, (1 ** Refl))
