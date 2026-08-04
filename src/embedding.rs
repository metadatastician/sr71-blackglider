// SPDX-License-Identifier: MPL-2.0
use crate::life::World;

/// Exact doubled coordinates for the 45-degree BlackGlider chart.
/// Physical display coordinates are `(u/2, v/2)`; keeping the doubled values
/// integral preserves the parity sublattice without semantic floating point.
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd)]
pub struct ChartPoint {
    pub u: i64,
    pub v: i64,
}

impl ChartPoint {
    #[must_use]
    pub const fn from_life(x: i64, y: i64) -> Self {
        Self { u: x + y, v: x - y }
    }

    /// The exact inverse exists precisely on the same-parity image lattice.
    #[must_use]
    pub const fn to_life(self) -> Option<(i64, i64)> {
        if (self.u - self.v) % 2 != 0 {
            None
        } else {
            Some(((self.u + self.v) / 2, (self.u - self.v) / 2))
        }
    }

    #[must_use]
    pub fn display_xy(self) -> [f64; 2] {
        [self.u as f64 / 2.0, self.v as f64 / 2.0]
    }
}

#[derive(Clone, Copy, Debug)]
pub struct FlightFrame {
    pub centre: ChartPoint,
    pub radius: f64,
    pub curvature: f64,
    /// Rigid rotation about the forward axis, applied after surface formation.
    pub bank: f64,
    /// Rigid rotation about the lateral axis, applied after banking.
    pub pitch: f64,
}

impl Default for FlightFrame {
    fn default() -> Self {
        Self {
            centre: ChartPoint { u: 0, v: 0 },
            radius: 24.0,
            curvature: 0.0,
            bank: 0.0,
            pitch: 0.0,
        }
    }
}

/// A graph surface before camera attitude: chart x/y are carried directly into
/// the display calculation. Exact event identity remains in `ChartPoint`; the
/// floating-point position is presentation data only.
#[must_use]
pub fn graph_surface(point: ChartPoint, frame: FlightFrame) -> [f64; 3] {
    let [x, y] = point.display_xy();
    let [centre_x, centre_y] = frame.centre.display_xy();
    let dx = x - centre_x;
    let dy = y - centre_y;
    let radius = frame.radius.max(f64::EPSILON);
    let weight = (-(dx * dx + dy * dy) / (2.0 * radius * radius)).exp();
    [x, y, frame.curvature * weight]
}

/// Applies the intended rigid bank/pitch attitude in display arithmetic.
/// Mathematical rotations are invertible; no claim is made that arbitrary
/// floating-point inputs are collision-free. Canonical identity is retained
/// separately in `DrawCell::chart` and never recovered from this position.
#[must_use]
pub fn surface_point(point: ChartPoint, frame: FlightFrame) -> [f64; 3] {
    let [x, y, z] = graph_surface(point, frame);
    let [centre_x, centre_y] = frame.centre.display_xy();
    let (bank_sine, bank_cosine) = frame.bank.sin_cos();
    let banked_y = centre_y + (y - centre_y) * bank_cosine - z * bank_sine;
    let banked_z = (y - centre_y) * bank_sine + z * bank_cosine;
    let (pitch_sine, pitch_cosine) = frame.pitch.sin_cos();
    [
        centre_x + (x - centre_x) * pitch_cosine + banked_z * pitch_sine,
        banked_y,
        -(x - centre_x) * pitch_sine + banked_z * pitch_cosine,
    ]
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct DrawCell {
    pub cell: [usize; 2],
    pub chart: ChartPoint,
    pub position: [f64; 3],
}

#[must_use]
pub fn draw_list(world: &World, frame: FlightFrame) -> Vec<DrawCell> {
    world
        .live_cells()
        .map(|(x, y)| {
            let chart = ChartPoint::from_life(x as i64, y as i64);
            DrawCell {
                cell: [x, y],
                chart,
                position: surface_point(chart, frame),
            }
        })
        .collect()
}
