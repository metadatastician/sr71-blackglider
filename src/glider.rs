// SPDX-License-Identifier: MPL-2.0
use std::collections::BTreeSet;

use crate::{
    life::{World, parse_rle},
    patterns::GLIDER_SE_RLE,
};

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DetectedGlider {
    pub anchor: (usize, usize),
    pub heading: (i8, i8),
    pub phase: usize,
    pub cells: Vec<(i32, i32)>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct GliderPattern {
    pub heading: (i8, i8),
    pub phase: usize,
    pub cells: Vec<(i32, i32)>,
}

fn normalise(cells: impl IntoIterator<Item = (i32, i32)>) -> Vec<(i32, i32)> {
    let cells: Vec<_> = cells.into_iter().collect();
    let min_x = cells.iter().map(|cell| cell.0).min().unwrap_or(0);
    let min_y = cells.iter().map(|cell| cell.1).min().unwrap_or(0);
    let mut result: Vec<_> = cells
        .into_iter()
        .map(|(x, y)| (x - min_x, y - min_y))
        .collect();
    result.sort_by_key(|&(x, y)| (y, x));
    result
}

fn base_phases() -> Vec<Vec<(i32, i32)>> {
    let seed = parse_rle(GLIDER_SE_RLE).expect("embedded glider RLE is valid");
    let mut world = World::from_cells(16, 16, [(seed, (6, 6))]).expect("glider fits");
    let mut phases = Vec::new();
    for _ in 0..4 {
        phases.push(normalise(
            world.live_cells().map(|(x, y)| (x as i32, y as i32)),
        ));
        world = world.evolved();
    }
    phases
}

#[must_use]
pub fn glider_catalog() -> Vec<GliderPattern> {
    let mut result = Vec::new();
    for sx in [-1_i8, 1] {
        for sy in [-1_i8, 1] {
            for (phase, shape) in base_phases().into_iter().enumerate() {
                result.push(GliderPattern {
                    heading: (sx, sy),
                    phase,
                    cells: normalise(
                        shape
                            .into_iter()
                            .map(|(x, y)| (i32::from(sx) * x, i32::from(sy) * y)),
                    ),
                });
            }
        }
    }
    result
}

#[must_use]
pub fn find_isolated_gliders(world: &World, absent_from: Option<&World>) -> Vec<DetectedGlider> {
    let mut result = Vec::new();
    let mut identities = BTreeSet::new();
    for entry in glider_catalog() {
        let GliderPattern {
            heading,
            phase,
            cells: shape,
        } = entry;
        let max_x = shape.iter().map(|cell| cell.0).max().unwrap() as usize;
        let max_y = shape.iter().map(|cell| cell.1).max().unwrap() as usize;
        for anchor_y in 0..world.height().saturating_sub(max_y) {
            for anchor_x in 0..world.width().saturating_sub(max_x) {
                if !shape
                    .iter()
                    .all(|&(x, y)| world.is_live(anchor_x + x as usize, anchor_y + y as usize))
                {
                    continue;
                }
                let expected: BTreeSet<_> = shape
                    .iter()
                    .map(|&(x, y)| (anchor_x + x as usize, anchor_y + y as usize))
                    .collect();
                let min_x = anchor_x.saturating_sub(1);
                let min_y = anchor_y.saturating_sub(1);
                let bound_x = (anchor_x + max_x + 1).min(world.width() - 1);
                let bound_y = (anchor_y + max_y + 1).min(world.height() - 1);
                let isolated = (min_y..=bound_y).all(|y| {
                    (min_x..=bound_x).all(|x| !world.is_live(x, y) || expected.contains(&(x, y)))
                });
                if !isolated {
                    continue;
                }
                if absent_from
                    .is_some_and(|shadow| expected.iter().all(|&(x, y)| shadow.is_live(x, y)))
                {
                    continue;
                }
                if identities.insert((anchor_x, anchor_y, heading, phase)) {
                    result.push(DetectedGlider {
                        anchor: (anchor_x, anchor_y),
                        heading,
                        phase,
                        cells: shape.clone(),
                    });
                }
            }
        }
    }
    result
}
