-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- ABI Proof: Non-null pointer safety
-- Template proof — customise for your project's pointer types.
-- All proofs MUST be constructive (no believe_me, no assert_total).

module ABI.Pointers

import Data.So

%default total

||| A pointer value that has been proven non-null.
||| The `So` constraint carries a compile-time witness that `ptr /= 0`.
|||
||| `nonNull` is ERASED (quantity 0), and must stay that way. The recorded
||| quarantine reason — ".nonNull declared at quantity 0 yet projected into a
||| value position" — is real, but the defect is in the ACCESSOR, not the
||| field: `safePtrNeverNull` returns a proof, so it is itself a proof and
||| belongs at quantity 0. De-erasing the field instead does compile, but it
||| is the wrong repair and it is not free: measured with
||| `idris2 --codegen refc --dumpcases`, an erased witness lets Idris2
||| newtype-optimise the record away entirely (SafePtr IS a bare Bits64,
||| `.ptr` is the identity), whereas an unrestricted witness emits a
||| two-field heap object per pointer and degrades `.ptr` to a case
||| destructure. Transparent single-word representation is the entire point
||| of a C-ABI pointer type.
|||
||| It is also what the SHIPPED seam does: `src/interface/Abi/Types.idr`
||| declares the same invariant as `0 prf : So (ptr /= 0)`. These template
||| proofs model that seam and must not teach the opposite of it.
public export
record SafePtr where
  constructor MkSafePtr
  ptr : Bits64
  {auto 0 nonNull : So (ptr /= 0)}

||| Proof that SafePtr can never hold a null (zero) value.
||| This is enforced by the `So` constraint in the record.
||| Quantity 0: it is a proof, not a runtime function.
export
0 safePtrNeverNull : (sp : SafePtr) -> So (sp.ptr /= 0)
safePtrNeverNull sp = sp.nonNull

||| Wrap a raw pointer with a runtime null check.
||| Returns Nothing if the pointer is null.
export
checkPtr : (raw : Bits64) -> Maybe SafePtr
checkPtr 0 = Nothing
checkPtr raw = case choose (raw /= 0) of
  Left prf => Just (MkSafePtr raw)
  Right _ => Nothing

||| Proof that checkPtr 0 always returns Nothing.
export
checkPtrZeroIsNothing : checkPtr 0 = Nothing
checkPtrZeroIsNothing = Refl

||| An opaque handle backed by a non-null pointer.
||| Use this for FFI resource handles (file descriptors, sockets, etc.).
public export
record Handle (tag : String) where
  constructor MkHandle
  safePtr : SafePtr

||| `So b` is a subsingleton: matching the first witness as `Oh` refines
||| `b` to `True`, after which the second witness can only be `Oh` too.
||| (Matching `Oh` directly inside safePtrEq's pattern fails — the boolean
||| is still an unsolved variable there, so the `True ~ not (p == 0)`
||| constraint can't be discharged at pattern time.)
export
soUnique : (w1, w2 : So b) -> w1 = w2
soUnique Oh Oh = Refl

||| Two SafePtrs with equal raw pointers are equal: the only other component
||| is the `So` witness, and witnesses are unique by `soUnique`.
export
safePtrEq : (s1, s2 : SafePtr) -> s1.ptr = s2.ptr -> s1 = s2
safePtrEq (MkSafePtr p {nonNull = w1}) (MkSafePtr p {nonNull = w2}) Refl =
  cong (\w => MkSafePtr p {nonNull = w}) (soUnique w1 w2)

||| Proof that two handles with equal pointers are equal.
|||
||| The original quarantined body matched a non-linear pattern
||| (`MkSafePtr p` twice) before the Refl could force the unification —
||| the recorded unification failure. Going through `safePtrEq` and `cong`
||| lets Refl do the forcing at the right layer.
export
handlePtrEq : (h1, h2 : Handle tag) -> h1.safePtr.ptr = h2.safePtr.ptr -> h1 = h2
handlePtrEq (MkHandle s1) (MkHandle s2) prf = cong MkHandle (safePtrEq s1 s2 prf)
