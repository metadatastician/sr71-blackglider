// SPDX-License-Identifier: MPL-2.0
use crate::{
    glider::{DetectedGlider, find_isolated_gliders},
    life::World,
};

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ReplayCertificate {
    pub initial_world: Vec<u8>,
    pub generations: usize,
    pub expected_world: Vec<u8>,
}

impl ReplayCertificate {
    #[must_use]
    pub fn capture(initial: &World, generations: usize) -> Self {
        let mut final_world = initial.clone();
        for _ in 0..generations {
            final_world = final_world.evolved();
        }
        Self {
            initial_world: initial.canonical_bytes(),
            generations,
            expected_world: final_world.canonical_bytes(),
        }
    }

    pub fn verify(&self) -> Result<(), String> {
        let mut world = World::from_canonical_bytes(&self.initial_world)?;
        for _ in 0..self.generations {
            world = world.evolved();
        }
        if world.canonical_bytes() == self.expected_world {
            Ok(())
        } else {
            Err("replay final world differs from the certificate".into())
        }
    }
}

#[derive(Clone, Debug)]
pub struct ReactionCertificate {
    pub actual_initial: Vec<u8>,
    pub no_signal_initial: Vec<u8>,
    pub generations: usize,
    pub expected_output_heading: (i8, i8),
    pub expected_final_difference: usize,
}

#[derive(Clone, Debug)]
pub struct ReactionReport {
    pub first_output_generation: usize,
    pub output: DetectedGlider,
    pub final_difference: Vec<(usize, usize)>,
}

impl ReactionCertificate {
    pub fn verify(&self) -> Result<ReactionReport, String> {
        let mut actual = World::from_canonical_bytes(&self.actual_initial)?;
        let mut counterfactual = World::from_canonical_bytes(&self.no_signal_initial)?;
        if (actual.width(), actual.height()) != (counterfactual.width(), counterfactual.height()) {
            return Err("actual and counterfactual dimensions differ".into());
        }
        let mut observed = None;
        for generation in 0..=self.generations {
            if observed.is_none() {
                observed = find_isolated_gliders(&actual, Some(&counterfactual))
                    .into_iter()
                    .find(|glider| glider.heading == self.expected_output_heading)
                    .map(|glider| (generation, glider));
            }
            if generation < self.generations {
                actual = actual.evolved();
                counterfactual = counterfactual.evolved();
            }
        }
        let (first_output_generation, output) = observed.ok_or_else(|| {
            format!(
                "no causal output glider with heading {:?}",
                self.expected_output_heading
            )
        })?;
        let final_difference = actual.causal_difference(&counterfactual);
        if final_difference.len() != self.expected_final_difference {
            return Err(format!(
                "final causal difference is {}, expected {}",
                final_difference.len(),
                self.expected_final_difference
            ));
        }
        Ok(ReactionReport {
            first_output_generation,
            output,
            final_difference,
        })
    }
}
