-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- ABI Proof: Platform-specific type size proofs
-- Proves that C type sizes are correct per platform.
-- All proofs MUST be constructive (no believe_me, no assert_total).

module ABI.Platform

import Data.Nat

%default total

||| Supported target platforms for ABI verification.
public export
data Platform = Linux64 | LinuxARM64 | MacOS64 | MacOSARM64
              | Windows64 | FreeBSD64 | WASM32

||| Pointer size in bytes for each platform.
public export
ptrSize : Platform -> Nat
ptrSize WASM32 = 4
ptrSize _ = 8

||| C `int` size in bytes.
public export
cIntSize : Platform -> Nat
cIntSize _ = 4

||| C `size_t` size in bytes (matches pointer size).
public export
cSizeT : Platform -> Nat
cSizeT = ptrSize

||| Proof that size_t always equals pointer size on all platforms.
export
sizeTEqPtrSize : (p : Platform) -> cSizeT p = ptrSize p
sizeTEqPtrSize _ = Refl

||| Proof that pointer size is always 4 or 8 bytes.
export
ptrSizeValid : (p : Platform) -> Either (ptrSize p = 4) (ptrSize p = 8)
ptrSizeValid WASM32 = Left Refl
ptrSizeValid Linux64 = Right Refl
ptrSizeValid LinuxARM64 = Right Refl
ptrSizeValid MacOS64 = Right Refl
ptrSizeValid MacOSARM64 = Right Refl
ptrSizeValid Windows64 = Right Refl
ptrSizeValid FreeBSD64 = Right Refl

||| Proof that C int is always 4 bytes on all platforms.
export
cIntAlways4 : (p : Platform) -> cIntSize p = 4
cIntAlways4 _ = Refl

||| Proof that pointer size is always at least 4 bytes.
|||
||| One expression proves every case: `LTEZero : LTE 0 n` for ANY n, so four
||| applications of LTESucc give `LTE 4 4` (WASM32) and `LTE 4 8` (the rest)
||| alike. The original quarantined body used `lteRefl`, which idris2 0.7.0's
||| Data.Nat does not export.
export
ptrSizeAtLeast4 : (p : Platform) -> LTE 4 (ptrSize p)
ptrSizeAtLeast4 WASM32 = LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))
ptrSizeAtLeast4 Linux64 = LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))
ptrSizeAtLeast4 LinuxARM64 = LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))
ptrSizeAtLeast4 MacOS64 = LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))
ptrSizeAtLeast4 MacOSARM64 = LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))
ptrSizeAtLeast4 Windows64 = LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))
ptrSizeAtLeast4 FreeBSD64 = LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))
