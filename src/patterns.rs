// SPDX-License-Identifier: CC-BY-SA-4.0

pub const GLIDER_SE_RLE: &str = "bob$2bo$3o!";

/// Mike Playle's standard 49-cell Snark variant, separated from its demonstration
/// input so the no-launch counterfactual contains precisely the reflector.
pub const SNARK_RLE: &str = concat!(
    "14b2o$14bobo$16bo4b2o$12b4ob2o2bo2bo$",
    "12bo2bobobobob2o$15bobobobo$16b2obobo$20bo2$",
    "6b2o$7bo7b2o$7bobo5b2o$8b2o7$",
    "18b2o$18bo$19b3o$21bo!"
);

pub const SNARK_INPUT_RLE: &str = "3o$2bo$bo!";
pub const SNARK_INPUT_OFFSET: (i32, i32) = (0, 29);
