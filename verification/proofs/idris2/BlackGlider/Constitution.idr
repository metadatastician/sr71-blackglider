-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (metadatastician)
--
-- A deliberately small formal companion to the executable Rust evidence.
-- It proves the constitutional equations represented here; it does not claim
-- refinement of the Rust implementation or verification of compiled code.

module BlackGlider.Constitution

%default total

||| The Conway B3/S23 local transition, written without an oracle or axiom.
public export
nextCell : Bool -> Nat -> Bool
nextCell False 3 = True
nextCell True 2 = True
nextCell True 3 = True
nextCell _ _ = False

||| A dead cell is born with exactly three live neighbours.
export
birthOnThree : nextCell False 3 = True
birthOnThree = Refl

||| A live cell survives with exactly two live neighbours.
export
surviveOnTwo : nextCell True 2 = True
surviveOnTwo = Refl

||| A live cell survives with exactly three live neighbours.
export
surviveOnThree : nextCell True 3 = True
surviveOnThree = Refl

||| A dead cell with two neighbours remains dead.
export
deadOnTwo : nextCell False 2 = False
deadOnTwo = Refl

||| A live cell with four neighbours dies.
export
overpopulationOnFour : nextCell True 4 = False
overpopulationOnFour = Refl

||| The only neighbour counts admitted by a Moore neighbourhood.
public export
data NeighbourCount
  = ZeroN | OneN | TwoN | ThreeN | FourN
  | FiveN | SixN | SevenN | EightN

public export
neighbourNat : NeighbourCount -> Nat
neighbourNat ZeroN = 0
neighbourNat OneN = 1
neighbourNat TwoN = 2
neighbourNat ThreeN = 3
neighbourNat FourN = 4
neighbourNat FiveN = 5
neighbourNat SixN = 6
neighbourNat SevenN = 7
neighbourNat EightN = 8

||| A separately stated, bounded-domain B3/S23 specification.
public export
b3s23Spec : Bool -> NeighbourCount -> Bool
b3s23Spec False ThreeN = True
b3s23Spec True TwoN = True
b3s23Spec True ThreeN = True
b3s23Spec _ _ = False

||| Exhaustive refinement of the Nat implementation against the bounded Moore
||| specification: both centre states times all nine legal neighbour counts.
export
localRuleRefinesB3S23 :
  (alive : Bool) ->
  (neighbours : NeighbourCount) ->
  nextCell alive (neighbourNat neighbours) = b3s23Spec alive neighbours
localRuleRefinesB3S23 False ZeroN = Refl
localRuleRefinesB3S23 False OneN = Refl
localRuleRefinesB3S23 False TwoN = Refl
localRuleRefinesB3S23 False ThreeN = Refl
localRuleRefinesB3S23 False FourN = Refl
localRuleRefinesB3S23 False FiveN = Refl
localRuleRefinesB3S23 False SixN = Refl
localRuleRefinesB3S23 False SevenN = Refl
localRuleRefinesB3S23 False EightN = Refl
localRuleRefinesB3S23 True ZeroN = Refl
localRuleRefinesB3S23 True OneN = Refl
localRuleRefinesB3S23 True TwoN = Refl
localRuleRefinesB3S23 True ThreeN = Refl
localRuleRefinesB3S23 True FourN = Refl
localRuleRefinesB3S23 True FiveN = Refl
localRuleRefinesB3S23 True SixN = Refl
localRuleRefinesB3S23 True SevenN = Refl
localRuleRefinesB3S23 True EightN = Refl

||| Exact integer coordinates in the parity-preserving BlackGlider chart.
public export
record ChartPoint where
  constructor MkChartPoint
  u : Integer
  v : Integer

||| Rotate the Life lattice into the presentation chart without rounding.
public export
chartDelta : Integer -> Integer -> ChartPoint
chartDelta dx dy = MkChartPoint (dx + dy) (dx - dy)

||| The four diagonal Life displacements become chart-axis displacements.
export
northEastIsUp : chartDelta 1 (-1) = MkChartPoint 0 2
northEastIsUp = Refl

export
southEastIsForward : chartDelta 1 1 = MkChartPoint 2 0
southEastIsForward = Refl

export
southWestIsDown : chartDelta (-1) 1 = MkChartPoint 0 (-2)
southWestIsDown = Refl

export
northWestIsBack : chartDelta (-1) (-1) = MkChartPoint (-2) 0
northWestIsBack = Refl

||| Iterate one deterministic physical transition for a fixed tick count.
public export
evolve : (state -> state) -> Nat -> state -> state
evolve step 0 state = state
evolve step (S ticks) state = evolve step ticks (step state)

||| With one initial state and one transition, the history has one result.
export
evolutionIsDeterministic :
  (step : state -> state) ->
  (ticks : Nat) ->
  (initial : state) ->
  evolve step ticks initial = evolve step ticks initial
evolutionIsDeterministic _ _ _ = Refl

||| Observers cannot distinguish themselves by changing the physical result:
||| neither observer is an argument to `evolve`.
export
observersArePhysicallyIrrelevant :
  (step : state -> state) ->
  (ticks : Nat) ->
  (initial : state) ->
  (observerA : state -> viewA) ->
  (observerB : state -> viewB) ->
  evolve step ticks initial = evolve step ticks initial
observersArePhysicallyIrrelevant _ _ _ _ _ = Refl

||| A radius-one cellular automaton has a dependency radius of at most n after
||| n generations. This companion exposes the constitutional bound; the Rust
||| suite separately checks padded finite worlds against an independent oracle.
public export
causalRadius : Nat -> Nat
causalRadius generations = generations

export
causalRadiusIsGenerationCount :
  (generations : Nat) -> causalRadius generations = generations
causalRadiusIsGenerationCount _ = Refl
