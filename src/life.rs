// SPDX-License-Identifier: MPL-2.0

/// The complete physical state: B3/S23 on a finite rectangle with permanently
/// dead exterior cells. Cell storage is private; after construction the only
/// state transition exposed by this type is [`World::evolved`].
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct World {
    width: usize,
    height: usize,
    cells: Vec<u8>,
}

#[must_use]
pub const fn next_cell(alive: u8, neighbours: u8) -> u8 {
    if neighbours == 3 || (alive == 1 && neighbours == 2) {
        1
    } else {
        0
    }
}

impl World {
    /// Constructs generation zero. Overlapping initial patterns remain one
    /// live cell; coordinates outside the declared finite world are rejected.
    pub fn from_cells(
        width: usize,
        height: usize,
        patterns: impl IntoIterator<Item = (Vec<(i32, i32)>, (i32, i32))>,
    ) -> Result<Self, String> {
        let mut cells = vec![0; width * height];
        for (pattern, (origin_x, origin_y)) in patterns {
            for (pattern_x, pattern_y) in pattern {
                let x = origin_x + pattern_x;
                let y = origin_y + pattern_y;
                if x < 0 || y < 0 || x as usize >= width || y as usize >= height {
                    return Err(format!("initial cell outside finite world at {x},{y}"));
                }
                cells[y as usize * width + x as usize] = 1;
            }
        }
        Ok(Self {
            width,
            height,
            cells,
        })
    }

    #[must_use]
    pub const fn width(&self) -> usize {
        self.width
    }

    #[must_use]
    pub const fn height(&self) -> usize {
        self.height
    }

    #[must_use]
    pub fn is_live(&self, x: usize, y: usize) -> bool {
        self.cells[y * self.width + x] == 1
    }

    #[must_use]
    pub fn population(&self) -> usize {
        self.cells.iter().map(|&cell| usize::from(cell)).sum()
    }

    pub fn live_cells(&self) -> impl Iterator<Item = (usize, usize)> + '_ {
        self.cells.iter().enumerate().filter_map(|(index, &cell)| {
            (cell == 1).then_some((index % self.width, index / self.width))
        })
    }

    /// The sole post-initialisation physical transition.
    #[must_use]
    pub fn evolved(&self) -> Self {
        let mut cells = vec![0; self.cells.len()];
        for y in 0..self.height {
            for x in 0..self.width {
                let mut neighbours = 0;
                for dy in -1_i32..=1 {
                    for dx in -1_i32..=1 {
                        if dx == 0 && dy == 0 {
                            continue;
                        }
                        let nx = x as i32 + dx;
                        let ny = y as i32 + dy;
                        if nx >= 0
                            && ny >= 0
                            && (nx as usize) < self.width
                            && (ny as usize) < self.height
                            && self.is_live(nx as usize, ny as usize)
                        {
                            neighbours += 1;
                        }
                    }
                }
                cells[y * self.width + x] = next_cell(self.cells[y * self.width + x], neighbours);
            }
        }
        Self {
            width: self.width,
            height: self.height,
            cells,
        }
    }

    #[must_use]
    pub fn causal_difference(&self, counterfactual: &Self) -> Vec<(usize, usize)> {
        assert_eq!(
            (self.width, self.height),
            (counterfactual.width, counterfactual.height)
        );
        self.cells
            .iter()
            .zip(&counterfactual.cells)
            .enumerate()
            .filter_map(|(index, (actual, shadow))| {
                (actual != shadow).then_some((index % self.width, index / self.width))
            })
            .collect()
    }

    /// Stable replay material. This is an exact serialization, not a
    /// cryptographic digest: magic, dimensions as little-endian u64, then one
    /// canonical byte per cell in row-major order.
    #[must_use]
    pub fn canonical_bytes(&self) -> Vec<u8> {
        let mut bytes = Vec::with_capacity(24 + self.cells.len());
        bytes.extend_from_slice(b"SR71LIFE");
        bytes.extend_from_slice(&(self.width as u64).to_le_bytes());
        bytes.extend_from_slice(&(self.height as u64).to_le_bytes());
        bytes.extend_from_slice(&self.cells);
        bytes
    }

    pub fn from_canonical_bytes(bytes: &[u8]) -> Result<Self, String> {
        const HEADER: usize = 24;
        if bytes.len() < HEADER || &bytes[..8] != b"SR71LIFE" {
            return Err("not SR-71 canonical Life material".into());
        }
        let width = usize::try_from(u64::from_le_bytes(bytes[8..16].try_into().unwrap()))
            .map_err(|_| "canonical width is not representable on this platform")?;
        let height = usize::try_from(u64::from_le_bytes(bytes[16..24].try_into().unwrap()))
            .map_err(|_| "canonical height is not representable on this platform")?;
        let expected = width
            .checked_mul(height)
            .and_then(|cells| cells.checked_add(HEADER))
            .ok_or_else(|| "canonical dimensions overflow".to_string())?;
        if bytes.len() != expected {
            return Err(format!(
                "canonical material has {} bytes; expected {expected}",
                bytes.len()
            ));
        }
        let cells = bytes[HEADER..].to_vec();
        if cells.iter().any(|cell| *cell > 1) {
            return Err("canonical material contains a non-binary cell".into());
        }
        Ok(Self {
            width,
            height,
            cells,
        })
    }
}

/// A Moore-neighbour causal influence can travel at most this many lattice
/// cells after `generations` synchronous updates.
#[must_use]
pub const fn causal_radius(generations: usize) -> usize {
    generations
}

pub fn parse_rle(source: &str) -> Result<Vec<(i32, i32)>, String> {
    let body: String = source
        .lines()
        .filter(|line| !line.starts_with('#') && !line.starts_with('x'))
        .collect();
    let mut cells = Vec::new();
    let (mut x, mut y, mut count) = (0_i32, 0_i32, 0_i32);
    for token in body.chars().filter(|token| !token.is_whitespace()) {
        if let Some(digit) = token.to_digit(10) {
            count = count * 10 + digit as i32;
            continue;
        }
        let run = if count == 0 { 1 } else { count };
        count = 0;
        match token {
            'b' => x += run,
            'o' => {
                cells.extend((0..run).map(|offset| (x + offset, y)));
                x += run;
            }
            '$' => {
                y += run;
                x = 0;
            }
            '!' => break,
            other => return Err(format!("unsupported RLE token {other:?}")),
        }
    }
    Ok(cells)
}
