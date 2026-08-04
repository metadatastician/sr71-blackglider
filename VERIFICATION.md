<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (metadatastician) -->

# Verification ledger

The complete foundation gate is `just test`: Rust evidence plus every gated
Idris2 module. `cargo test --all-targets` runs only the executable evidence.
"Green" means an exhaustive finite check or bounded trace passed; "checked"
means Idris2 accepted the stated theorem. Neither label silently expands the
claim's declared domain.

| Claim | Statement | Evidence | Status |
|---|---|---|---|
| C1 | All 512 possible centre-plus-neighbour configurations implement exactly B3/S23 | `c1_all_512_local_configurations_are_exactly_b3_s23` | green |
| C2 | The no-launch foundation world contains a stable 49-cell Snark | `c2_snark_is_a_stable_49_cell_counterfactual` | green |
| C3 | Raw B3/S23 turns the incoming NE signal into an outgoing SE glider | `c3_c4_snark_reaction_produces_only_a_causal_reflected_glider_and_recovers` | green |
| C4 | The Snark recovers and the final causal difference is exactly five output cells, with no ash | same reaction test | green |
| C5 | Headless and aggressively warped rendering produce identical canonical histories for 240 generations | `c5_rendering_is_observational_and_cannot_change_history` | green |
| C6 | The exact 45-degree chart maps NE/SE/SW/NW to up/forward/down/back | `c6_rotated_chart_maps_life_diagonals_to_blackglider_axes_exactly` | green |
| C7 | Canonical bytes reconstruct the initial world and reproduce its 240-generation result | `c7_replay_material_reconstructs_the_identical_history` | green |
| C8 | Every possible 4-by-4 finite world agrees for one generation with an independent synchronous oracle | `c8_every_4_by_4_world_matches_an_independent_synchronous_oracle` | green |
| C9 | The exact chart is collision-free and invertible on the sampled Life domain, with the inverse rejecting the wrong parity | `c9_exact_chart_is_bijective_onto_the_same_parity_sublattice` | green |
| C10 | The sampled height-graph embedding preserves chart events and sampled rigid-attitude outputs remain distinct | `c10_graph_surface_and_rigid_attitude_preserve_distinct_events` | green |
| C11 | All 16 glider heading/phase representatives are detected and translate correctly after four generations | `c11_all_16_glider_heading_phase_patterns_are_detected_and_translate_correctly` | green |
| C12 | All 512 centred 3-by-3 seeds agree between 9-by-9 and padded 15-by-15 dead worlds through three generations | `c12_causal_radius_bounds_finite_and_larger_dead_worlds` | green |
| C13 | Every defined presentation input leaves the canonical history equal to a headless run for 128 generations | `c13_presentation_inputs_have_no_physical_capability` | green |
| C14 | The constitutional companion's complete legal B3/S23 centre/count domain, chart headings, deterministic iterator, observer exclusion, and causal-radius equation typecheck constructively | `BlackGlider/Constitution.idr` via `scripts/check-proofs.sh idris2` | checked |

## C1 — complete local rule

A Life update depends on the centre bit and eight neighbour bits: \(2^9=512\)
inputs. The test enumerates all of them and compares `next_cell` with the direct
B3/S23 proposition. This is exhaustive for the local function, not a sampling
of familiar patterns.

## C2–C4 — genuine turn and causal identity

The actual world begins with a stable Snark plus an incoming glider. The
counterfactual begins with the identical Snark and no glider. Both use the same
kernel and dead boundary.

The committed lane is the canonical demonstration reaction at relative offset
`(0,29)`. The test runs 240 generations, detects a raw SE output causally absent
from the counterfactual, requires the reflector's original still-life cells to
recover, and finally requires the actual/counterfactual difference to contain
exactly five cells. The last assertion rejects a turn that leaves unreported
causal debris.

The offset is pinned because it was earned: the first transcription used
`(0,30)` by reading `7$` as seven blank rows rather than an advance of seven RLE
rows. That run permanently damaged the reflector and the claim stayed red until
the exact RLE semantics were corrected.

## C5 — geometry is a spectator

Two identical initial worlds evolve independently. One runs headlessly. The
other is passed twice per generation through substantially different local bank,
pitch, radius and centre values. The complete `World` values must remain equal
at every generation.

This behavioural check sits on a structural boundary: `draw_list` receives
`&World`; cell storage is private; and the embedding module has no transition or
initialisation capability.

## C6 — rotated chart

The test applies the coordinate transform to all four unit diagonal
displacements and checks exact results:

| Raw Life displacement | BlackGlider displacement |
|---|---|
| `(1,-1)` | `(0,1)` up |
| `(1,1)` | `(1,0)` forward |
| `(-1,1)` | `(0,-1)` down |
| `(-1,-1)` | `(-1,0)` back |

This establishes an exact chart, not physical orthogonal glider motion.

## C7–C8 — replay and independent transition evidence

C7 serializes dimensions and every finite cell state in one canonical binary
form, reconstructs the world, and checks the stored 240-generation result. It
makes the demonstration reproducible without making a renderer or detector the
source of truth.

C8 enumerates all (2^{16}=65,536) states of a 4-by-4 dead-boundary world. Its
reference transition is separately written as a bitmask oracle and does not
call `next_cell` or `World::evolved`. This is exhaustive for that world size and
one step; it is not a universal implementation-equivalence proof.

## C9–C10 — exact chart and surface discipline

C9 enumerates 40,401 Life coordinates, rejects every collision in that set,
round-trips each point exactly, and confirms the parity constraint. Algebraically
the code uses (u=x+y,v=x-y), with inverse
(x=(u+v)/2,y=(u-v)/2) on the same-parity sublattice.

C10 checks a 41-by-41 event set. The graph surface retains exact chart
coordinates as its first two components before applying rigid bank and pitch.
The construction gives the intended non-folding argument; the executable test
is bounded sampled evidence, not a floating-point theorem over all inputs.

## C11 — complete glider catalogue

The four headings and four phases produce 16 representatives. Each is seeded
in isolation, recovered by the detector with a unique heading/phase identity,
evolved only by `World::evolved`, and found one heading unit away after the
glider's four-generation period. This covers the catalogue, not every possible
surrounding collision.

## C12 — finite-boundary discipline

Every 3-by-3 seed is placed with three dead cells of clearance and evolved in
both a 9-by-9 world and a padded 15-by-15 world. Equality through generation
three demonstrates the radius-one dependency bound over that exhaustive seed
domain. Claims for a future mission still require its own boundary-clear
certificate.

## C13 — input capability boundary

The public presentation commands alter `ViewState` only: bank, pitch, zoom,
tactical display, pause/resume state and display rate. The test applies all of
them while independently evolving equal worlds for 128 generations. The module
has no `World` parameter or physical command variant, giving a structural
boundary alongside the trace check.

## C14 — formal constitutional companion

`verification/proofs/idris2/BlackGlider/Constitution.idr` is total Idris2 and
uses no axioms or unsafe proof escape. Idris2 0.7.0 checks that the Nat-based
rule agrees with a separately stated bounded specification for both centre
states and every legal Moore-neighbour count (18 cases). It also checks the four
exact integer chart-direction equations, uniqueness of the declared
deterministic iterator, the fact that observers are absent from that iterator,
and `causalRadius n = n` for the defined function.

This is genuinely machine-checked, but deliberately small. It does **not** prove
that Rust's `World::evolved` refines the Idris2 definition, formally derive the
neighbour count for all 512 centre-plus-neighbour bit patterns, prove arbitrary
floating-point surface injectivity, or verify compiler output. Those are
separate obligations.

## Not yet claimed

- a playable mission or shipped browser artefact;
- live post-launch physical steering;
- a renderer beyond the proof-oriented draw-list embedding;
- that displayed distance or curvature is canonical Conway distance;
- that a frame manoeuvre changes mission outcome;
- infinite-plane equivalence beyond a measured boundary-clear interval;
- arbitrary-phase or arbitrary-lane Snark reflection;
- a machine-checked refinement from the Idris2 model to the Rust kernel;
- a verified compiler, standard library or executable binary;
- RSR release readiness while template metadata and broader gates remain under
  specialisation.
