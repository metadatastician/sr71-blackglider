// SPDX-License-Identifier: MPL-2.0
//! SR-71 BlackGlider's proof-bearing foundation.
//!
//! `life` is the sole physical layer. `embedding` observes an immutable world
//! and maps its cell events into a curved flight surface. It cannot steer them.

#![forbid(unsafe_code)]

pub mod certificate;
pub mod embedding;
pub mod glider;
pub mod input;
pub mod life;
pub mod patterns;
