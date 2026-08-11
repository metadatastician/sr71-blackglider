-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Typing Proof: Public API type safety
-- Template — replace with your project's API types.
-- Proves properties about exported function signatures.

-- Example: Result type used across API boundaries
inductive ApiResult (α : Type) where
  | ok    : α → ApiResult α
  | error : Nat → String → ApiResult α

namespace ApiResult
  -- Proof: map preserves structure (functor law: map id = id)
  def map (f : α → β) : ApiResult α → ApiResult β
    | .ok v      => .ok (f v)
    | .error c m => .error c m

  theorem map_id : ∀ (r : ApiResult α), map id r = r := by
    intro r
    cases r with
    | ok v => simp [map]
    | error c m => simp [map]

  -- Proof: map composition (functor law: map (g ∘ f) = map g ∘ map f)
  theorem map_comp (f : α → β) (g : β → γ) :
      ∀ (r : ApiResult α), map (g ∘ f) r = map g (map f r) := by
    intro r
    cases r with
    | ok v => simp [map, Function.comp]
    | error c m => simp [map]

end ApiResult

-- Example: Bounded confidence value (0.0 to 1.0 modelled as Nat/1000)
-- Replace with your project's numeric invariants
--
-- The bound is named `bound`, not `max`: `max` is a global function in
-- Lean 4, so it can never be auto-bound as an implicit — `BoundedNat max`
-- elaborated as `BoundedNat (max : α → α → α)`, the recorded quarantine
-- reason ("`max` used where Nat is expected").
structure BoundedNat (bound : Nat) where
  val : Nat
  le_bound : val ≤ bound

theorem bounded_nat_le (b : BoundedNat bound) : b.val ≤ bound :=
  b.le_bound

-- Proof: zero is always bounded
def zeroBounded (_h : 0 < bound) : BoundedNat bound :=
  ⟨0, Nat.zero_le bound⟩
