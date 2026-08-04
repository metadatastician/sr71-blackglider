// SPDX-License-Identifier: MPL-2.0
use std::collections::BTreeSet;

use sr71_blackglider::{
    embedding::{ChartPoint, FlightFrame, graph_surface, surface_point},
    glider::{find_isolated_gliders, glider_catalog},
    input::{PresentationInput, ViewState},
    life::{World, causal_radius},
};

type SeedPattern = (Vec<(i32, i32)>, (i32, i32));

fn world_from_mask(width: usize, height: usize, mask: u64) -> World {
    let cells = (0..width * height)
        .filter(|index| (mask >> index) & 1 == 1)
        .map(|index| ((index % width) as i32, (index / width) as i32))
        .collect();
    World::from_cells(width, height, [(cells, (0, 0))]).unwrap()
}

// Deliberately independent of World::evolved and next_cell.
fn reference_step(width: usize, height: usize, mask: u64) -> u64 {
    let mut result = 0_u64;
    for y in 0..height {
        for x in 0..width {
            let mut neighbours = 0;
            for dy in -1_i32..=1 {
                for dx in -1_i32..=1 {
                    if dx == 0 && dy == 0 {
                        continue;
                    }
                    let nx = x as i32 + dx;
                    let ny = y as i32 + dy;
                    if nx >= 0 && ny >= 0 && nx < width as i32 && ny < height as i32 {
                        neighbours += (mask >> (ny as usize * width + nx as usize)) & 1;
                    }
                }
            }
            let index = y * width + x;
            let alive = (mask >> index) & 1 == 1;
            if neighbours == 3 || (alive && neighbours == 2) {
                result |= 1 << index;
            }
        }
    }
    result
}

#[test]
fn c8_every_4_by_4_world_matches_an_independent_synchronous_oracle() {
    for mask in 0_u64..1 << 16 {
        let evolved = world_from_mask(4, 4, mask).evolved();
        let expected = reference_step(4, 4, mask);
        for y in 0..4 {
            for x in 0..4 {
                assert_eq!(
                    evolved.is_live(x, y),
                    (expected >> (y * 4 + x)) & 1 == 1,
                    "mask={mask:016b} cell={x},{y}"
                );
            }
        }
    }
}

#[test]
fn c9_exact_chart_is_bijective_onto_the_same_parity_sublattice() {
    let mut image = BTreeSet::new();
    for y in -100..=100 {
        for x in -100..=100 {
            let chart = ChartPoint::from_life(x, y);
            assert!(image.insert(chart), "chart collision for {x},{y}");
            assert_eq!(chart.to_life(), Some((x, y)));
            assert_eq!((chart.u - chart.v) % 2, 0);
        }
    }
    assert_eq!(ChartPoint { u: 0, v: 1 }.to_life(), None);
}

#[test]
fn c10_graph_surface_and_rigid_attitude_preserve_distinct_events() {
    let frame = FlightFrame {
        centre: ChartPoint { u: 10, v: -8 },
        radius: 12.0,
        curvature: 9.0,
        bank: 1.2,
        pitch: -0.7,
    };
    let mut graph_points = BTreeSet::new();
    let mut rendered = Vec::new();
    for y in -20..=20 {
        for x in -20..=20 {
            let chart = ChartPoint::from_life(x, y);
            let graph = graph_surface(chart, frame);
            assert!(graph_points.insert((chart.u, chart.v)));
            assert_eq!([graph[0], graph[1]], chart.display_xy());
            rendered.push(surface_point(chart, frame));
        }
    }
    for pair in rendered.windows(2) {
        assert_ne!(pair[0], pair[1]);
    }
}

#[test]
fn c11_all_16_glider_heading_phase_patterns_are_detected_and_translate_correctly() {
    let catalog = glider_catalog();
    assert_eq!(catalog.len(), 16);
    let identities: BTreeSet<_> = catalog
        .iter()
        .map(|pattern| (pattern.heading, pattern.phase))
        .collect();
    assert_eq!(identities.len(), 16);

    for pattern in catalog {
        let origin = (20, 20);
        let world = World::from_cells(48, 48, [(pattern.cells.clone(), origin)]).unwrap();
        let matches: Vec<_> = find_isolated_gliders(&world, None)
            .into_iter()
            .filter(|found| found.heading == pattern.heading && found.phase == pattern.phase)
            .collect();
        assert_eq!(
            matches.len(),
            1,
            "heading={:?} phase={}",
            pattern.heading,
            pattern.phase
        );

        let mut translated = world;
        for _ in 0..4 {
            translated = translated.evolved();
        }
        let expected_anchor = (
            (origin.0 + i32::from(pattern.heading.0)) as usize,
            (origin.1 + i32::from(pattern.heading.1)) as usize,
        );
        assert!(
            find_isolated_gliders(&translated, None)
                .iter()
                .any(|found| {
                    found.heading == pattern.heading
                        && found.phase == pattern.phase
                        && found.anchor == expected_anchor
                }),
            "four-generation translation failed for heading={:?} phase={}",
            pattern.heading,
            pattern.phase
        );
    }
}

#[test]
fn c12_causal_radius_bounds_finite_and_larger_dead_worlds() {
    assert_eq!(causal_radius(3), 3);
    for mask in 0_u64..512 {
        let seed: Vec<_> = (0..9)
            .filter(|index| (mask >> index) & 1 == 1)
            .map(|index| (index % 3, index / 3))
            .collect();
        let mut finite = World::from_cells(9, 9, [(seed.clone(), (3, 3))]).unwrap();
        let mut larger = World::from_cells(15, 15, [(seed, (6, 6))]).unwrap();
        for generation in 0..=3 {
            for y in 0..9 {
                for x in 0..9 {
                    assert_eq!(
                        finite.is_live(x, y),
                        larger.is_live(x + 3, y + 3),
                        "mask={mask:09b} generation={generation} cell={x},{y}"
                    );
                }
            }
            finite = finite.evolved();
            larger = larger.evolved();
        }
    }
}

#[test]
fn c13_presentation_inputs_have_no_physical_capability() {
    let seed: Vec<SeedPattern> = vec![(vec![(1, 0), (2, 1), (0, 2), (1, 2), (2, 2)], (10, 10))];
    let mut observed = World::from_cells(32, 32, seed.clone()).unwrap();
    let mut headless = World::from_cells(32, 32, seed).unwrap();
    let mut view = ViewState::default();
    let inputs = [
        PresentationInput::Bank(2.0),
        PresentationInput::Pitch(-1.0),
        PresentationInput::Zoom(0.25),
        PresentationInput::ToggleTactical,
        PresentationInput::Pause,
        PresentationInput::Resume,
        PresentationInput::DisplayRate(7),
    ];
    for generation in 0..128 {
        view.apply(inputs[generation % inputs.len()]);
        assert_eq!(observed, headless, "generation {generation}, view={view:?}");
        observed = observed.evolved();
        headless = headless.evolved();
    }
}
