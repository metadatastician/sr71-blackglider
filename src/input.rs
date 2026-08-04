// SPDX-License-Identifier: MPL-2.0

/// Post-launch input has presentation semantics only. This module deliberately
/// has no dependency on `life::World` and exposes no physical command variant.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum PresentationInput {
    Bank(f64),
    Pitch(f64),
    Zoom(f64),
    ToggleTactical,
    Pause,
    Resume,
    DisplayRate(u8),
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct ViewState {
    pub bank: f64,
    pub pitch: f64,
    pub zoom: f64,
    pub tactical: bool,
    pub paused: bool,
    pub display_rate: u8,
}

impl Default for ViewState {
    fn default() -> Self {
        Self {
            bank: 0.0,
            pitch: 0.0,
            zoom: 1.0,
            tactical: false,
            paused: false,
            display_rate: 1,
        }
    }
}

impl ViewState {
    pub fn apply(&mut self, input: PresentationInput) {
        match input {
            PresentationInput::Bank(value) => self.bank = value,
            PresentationInput::Pitch(value) => self.pitch = value,
            PresentationInput::Zoom(value) => self.zoom = value.max(f64::EPSILON),
            PresentationInput::ToggleTactical => self.tactical = !self.tactical,
            PresentationInput::Pause => self.paused = true,
            PresentationInput::Resume => self.paused = false,
            PresentationInput::DisplayRate(value) => self.display_rate = value.max(1),
        }
    }
}
