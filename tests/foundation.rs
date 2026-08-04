// SPDX-License-Identifier: MPL-2.0
use std::f64::consts::PI;

use sr71_blackglider::{
    certificate::{ReactionCertificate, ReplayCertificate},
    embedding::{ChartPoint, FlightFrame, draw_list},
    glider::find_isolated_gliders,
    life::{World, next_cell, parse_rle},
    patterns::{SNARK_INPUT_OFFSET, SNARK_INPUT_RLE, SNARK_RLE},
};

const WIDTH: usize = 192;
const HEIGHT: usize = 192;
const ORIGIN: (i32, i32) = (72, 64);
type SeedPattern = (Vec<(i32, i32)>, (i32, i32));

fn patterns(with_launch: bool) -> Vec<SeedPattern> {
    let mut patterns = vec![(parse_rle(SNARK_RLE).unwrap(), ORIGIN)];
    if with_launch {
        patterns.push((
            parse_rle(SNARK_INPUT_RLE).unwrap(),
            (
                ORIGIN.0 + SNARK_INPUT_OFFSET.0,
                ORIGIN.1 + SNARK_INPUT_OFFSET.1,
            ),
        ));
    }
    patterns
}

#[test]
fn c1_all_512_local_configurations_are_exactly_b3_s23() {
    for bits in 0_u16..512 {
        let alive = (bits & 1) as u8;
        let neighbours = (1..9).map(|bit| ((bits >> bit) & 1) as u8).sum();
        let expected = u8::from(neighbours == 3 || (alive == 1 && neighbours == 2));
        assert_eq!(
            next_cell(alive, neighbours),
            expected,
            "local configuration {bits:09b}"
        );
    }
}

#[test]
fn c2_snark_is_a_stable_49_cell_counterfactual() {
    let snark = World::from_cells(WIDTH, HEIGHT, patterns(false)).unwrap();
    assert_eq!(snark.population(), 49);
    assert_eq!(snark.evolved(), snark);
}

#[test]
fn c3_c4_snark_reaction_produces_only_a_causal_reflected_glider_and_recovers() {
    let mut world = World::from_cells(WIDTH, HEIGHT, patterns(true)).unwrap();
    let mut counterfactual = World::from_cells(WIDTH, HEIGHT, patterns(false)).unwrap();
    let reflector = parse_rle(SNARK_RLE).unwrap();
    let mut observed_reflection = None;
    let mut recovered_after_reaction = false;

    for generation in 0..=240 {
        let gliders = find_isolated_gliders(&world, Some(&counterfactual));
        if let Some(glider) = gliders.iter().find(|glider| glider.heading == (1, 1)) {
            observed_reflection.get_or_insert((generation, glider.clone()));
        }
        if observed_reflection.is_some()
            && reflector
                .iter()
                .all(|&(x, y)| world.is_live((ORIGIN.0 + x) as usize, (ORIGIN.1 + y) as usize))
        {
            recovered_after_reaction = true;
        }
        world = world.evolved();
        counterfactual = counterfactual.evolved();
    }

    let (_, outgoing) = observed_reflection.expect("a raw B3/S23 NE output glider");
    assert!(
        recovered_after_reaction,
        "the complete Snark still life must recover"
    );
    let difference = world.causal_difference(&counterfactual);
    assert_eq!(
        difference.len(),
        5,
        "no causal ash beside output; difference={difference:?}; gliders={:?}",
        find_isolated_gliders(&world, Some(&counterfactual))
    );
    assert_eq!(outgoing.heading, (1, 1));

    let certificate = ReactionCertificate {
        actual_initial: World::from_cells(WIDTH, HEIGHT, patterns(true))
            .unwrap()
            .canonical_bytes(),
        no_signal_initial: World::from_cells(WIDTH, HEIGHT, patterns(false))
            .unwrap()
            .canonical_bytes(),
        generations: 240,
        expected_output_heading: (1, 1),
        expected_final_difference: 5,
    };
    let report = certificate
        .verify()
        .expect("the committed reaction certificate");
    assert_eq!(report.output.heading, (1, 1));
    assert_eq!(report.final_difference.len(), 5);
}

#[test]
fn c5_rendering_is_observational_and_cannot_change_history() {
    let mut headless = World::from_cells(WIDTH, HEIGHT, patterns(true)).unwrap();
    let mut rendered = headless.clone();
    for generation in 0..240 {
        assert_eq!(rendered, headless, "generation {generation}");
        let frame = FlightFrame {
            centre: ChartPoint { u: 192, v: 0 },
            radius: 8.0 + f64::from(generation % 37),
            curvature: f64::from(generation).cos() * 3.0,
            bank: f64::from(generation).sin() * PI,
            pitch: f64::from(generation).cos(),
        };
        let _first = draw_list(&rendered, frame);
        let _second = draw_list(
            &rendered,
            FlightFrame {
                bank: -f64::from(generation),
                ..frame
            },
        );
        headless = headless.evolved();
        rendered = rendered.evolved();
    }
}

#[test]
fn c6_rotated_chart_maps_life_diagonals_to_blackglider_axes_exactly() {
    let directions = [
        ([1, -1], [0, 2]),
        ([1, 1], [2, 0]),
        ([-1, 1], [0, -2]),
        ([-1, -1], [-2, 0]),
    ];
    let origin = ChartPoint::from_life(20, 20);
    for (raw, expected) in directions {
        let mapped = ChartPoint::from_life(20 + raw[0], 20 + raw[1]);
        assert_eq!([mapped.u - origin.u, mapped.v - origin.v], expected);
    }
}

#[test]
fn c7_replay_material_reconstructs_the_identical_history() {
    let initial = World::from_cells(WIDTH, HEIGHT, patterns(true)).unwrap();
    let certificate = ReplayCertificate::capture(&initial, 240);
    certificate.verify().unwrap();

    let reconstructed = World::from_canonical_bytes(&initial.canonical_bytes()).unwrap();
    assert_eq!(reconstructed, initial);
}
