<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (metadatastician) -->

# Proof frontier

## The useful stopping line

SR-71 BlackGlider can prove its constitution before it has a game, but it
cannot prove an unspecified mission. This repository has reached the useful
constitutional boundary: it fixes what counts as physics, demonstrates one
genuine turn, makes the observer one-way, and records exactly which statements
are formal, exhaustive-finite, or bounded-trace evidence.

Further abstract work is possible now, but the next large gain in assurance
requires engineering a small, frozen mission specification. Otherwise proofs
would increasingly describe helper models rather than the experience that will
actually ship.

## Established before gameplay engineering

| Layer | Present evidence | Strength |
|---|---|---|
| Local physics | All 512 local bit configurations in Rust; all 18 legal centre/count cases against a separate Idris2 specification | exhaustive finite / checked model |
| Finite transition | All 65,536 4-by-4 worlds against an independent synchronous oracle | exhaustive finite |
| Signal | All four glider headings and four phases, including period-four translation | exhaustive catalogue |
| Genuine turn | One complete Snark lane, 240 generations, recovered reflector, exactly five causal output cells | bounded trace |
| Identity | Actual/no-launch histories and reaction certificate | bounded causal comparison |
| Replay | Exact finite-world encoding and reproduced terminal state | bounded deterministic replay |
| Coordinates | Exact doubled-integer chart, parity-aware inverse, four heading equations | checked equations / exhaustive sampled domain |
| Surface | Height-graph construction, retained canonical identity, immutable observer input | structural / bounded trace |
| Input | Presentation-only command type and 128-generation non-interference trace | capability boundary / bounded trace |

These results are enough to reject whole classes of future design proposals. A
feature that requires post-launch cell writes, a player-only transition, a
render-derived neighbourhood, or a commanded heading cannot enter as an
implementation detail: it contradicts the checked contract.

## More mathematics possible without new game design

The following are legitimate extensions, but none determines how the game is
played:

1. Prove the exact chart's parity-restricted bijection generally in Idris2,
   rather than by equations plus a large finite Rust domain.
2. Model a radius-one cellular automaton and prove the finite causal-cone bound
   by induction. The current Idris theorem checks the declared radius function;
   the Rust suite supplies bounded padded-world evidence.
3. Encode a sparse infinite-grid Life step in the proof assistant and prove the
   glider's four-phase translation directly.
4. Define a refinement boundary between the Idris model and Rust—through
   generated code, a proof-carrying trace checker, or a much smaller verified
   kernel API.
5. Give the canonical byte format a formal parser/serializer round-trip proof.

Items 1–3 strengthen the mathematical library. Items 4–5 start implementation
verification and need an explicit choice of verification architecture. None
should be represented as proof of the Rust executable until that refinement
link exists.

## Engineering required before the next project-specific proofs

The first mission must freeze these values:

- complete generation-zero patterns, including every reflector and control
  signal;
- finite world dimensions, dead-boundary semantics and maximum generation;
- allowed preflight choices and the exact meaning of post-launch input;
- objective success, failure, collision and BlackGlider identity predicates;
- which apparent manoeuvres are frame changes and which are detected Conway
  reactions;
- the renderer-facing event schema and the rule that canonical identity never
  comes back from floating-point positions.

Once those exist, useful proofs become concrete:

- no boundary event can influence the mission region before mission end;
- every successful turn has a raw B3/S23 reaction witness;
- every attributed output lies in the launch signal's causal difference;
- success/failure is invariant under camera, texture and surface choices;
- all reachable input paths either select pre-existing Life machinery or remain
  presentation-only;
- a checked replay certificate covers the exact shipped initial condition and
  mission horizon.

## What remains out of scope even then

A verified mission does not automatically verify Rust, LLVM, the operating
system, GPU drivers or floating-point rasterisation. Those require a separately
chosen trusted-computing-base strategy. They are not prerequisites for the
central claim if the canonical history and mission verdict can be reproduced by
a small independent checker from exact certificate material.

That suggests the preferred next architecture: keep the canonical kernel and
certificate checker small, exact and headless; let the production renderer be
spectacular but untrusted. The visual universe may bend. The Conway history
must remain independently replayable.
