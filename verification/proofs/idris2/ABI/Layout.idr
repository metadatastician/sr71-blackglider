-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- ABI Proof: Memory layout correctness
-- Proves struct size, alignment, and padding properties.
-- All proofs MUST be constructive (no believe_me, no assert_total).

module ABI.Layout

import Data.Nat

%default total

||| Witness that a type has a known size in bytes at compile time.
public export
interface HasSize (ty : Type) where
  sizeOf : Nat

||| Witness that a type has a known alignment in bytes.
public export
interface HasAlignment (ty : Type) where
  alignOf : Nat

||| Calculate padding needed to reach the next aligned offset.
||| paddingFor offset alignment = bytes to add so (offset + padding) `mod` alignment == 0
public export
paddingFor : (offset : Nat) -> (alignment : Nat) -> {auto 0 ok : NonZero alignment} -> Nat
paddingFor offset alignment = let r = modNatNZ offset alignment ok
                              in case r of
                                   Z => Z
                                   (S _) => minus alignment r

||| Proof that an offset with zero remainder needs zero padding.
export
alignedNeedsPadding : (n : Nat) -> (a : Nat) -> {auto 0 ok : NonZero a} ->
                      modNatNZ n a ok = 0 -> paddingFor n a = 0
alignedNeedsPadding n a prf = rewrite prf in Refl

||| A field within a struct, carrying its offset and size.
public export
record StructField where
  constructor MkField
  fieldName : String
  fieldOffset : Nat
  fieldSize : Nat
  fieldAlignment : Nat

||| Proof that a field is correctly aligned within a struct.
|||
||| Stated as divisibility — a non-zero alignment, plus a witness `k` with
||| `offset = k * alignment` — rather than
||| `modNatNZ offset alignment SIsNonZero = 0`. The mod phrasing was the
||| recorded quarantine reason: `SIsNonZero : NonZero (S n)` only unifies
||| with a literal successor, and an arbitrary `fieldAlignment f` is not
||| syntactically `S n` ("Can't solve constraint between: S ?x and
||| f .fieldAlignment"). Divisibility is constructive, needs no literal, and
||| is what C alignment actually means. It also matches the SHIPPED seam:
||| `src/interface/Abi/Layout.idr` already states alignment as `Divides`.
|||
||| The `NonZero` conjunct is NOT decoration. Without it this predicate is
||| strictly WEAKER than the mod phrasing at alignment 0: `(0 ** Refl)`
||| proves `FieldAligned (MkField "z" 0 8 0)`, certifying a field whose
||| alignment is zero — whereas the mod phrasing could not even be FORMED
||| at alignment 0, and in a total type theory unformable means uninhabited,
||| i.e. stronger. An earlier revision of this comment claimed the opposite
||| ("strictly stronger at alignment 0"); that was exactly backwards, and an
||| adversarial review caught it by building a complete `CABICompliant`
||| certificate for a size-0/alignment-0 struct that cannot exist in C.
||| Requiring `NonZero` closes the corner and restores the ordering the
||| comment originally claimed.
public export
FieldAligned : StructField -> Type
FieldAligned f = (NonZero (fieldAlignment f), (k ** fieldOffset f = k * fieldAlignment f))

||| Proof that a field does not overflow past a given struct size.
public export
FieldInBounds : (structSize : Nat) -> StructField -> Type
FieldInBounds sz f = LTE (fieldOffset f + fieldSize f) sz

||| A struct layout is a list of fields with a total size.
public export
record StructLayout where
  constructor MkLayout
  layoutName : String
  layoutFields : List StructField
  layoutSize : Nat
  layoutAlignment : Nat
