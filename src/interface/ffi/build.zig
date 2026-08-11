// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//
// FFI build: compiles src/main.zig and runs its inline tests plus the
// integration tests in test/integration_test.zig (which import the FFI as
// a module). The previous build.zig here was EMPTY scaffolding — `zig build`
// exited 0 without compiling a single line, so main.zig's compile errors
// sat undetected. `zig build test` is the honest gate now, wired into
// `just test`.

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ffi_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        // std.heap.c_allocator (used for all FFI-boundary allocation) is
        // only available when linking libc.
        .link_libc = true,
    });
    const main_tests = b.addTest(.{ .root_module = ffi_mod });

    const integration_mod = b.createModule(.{
        .root_source_file = b.path("test/integration_test.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    integration_mod.addImport("ffi", ffi_mod);
    const integration_tests = b.addTest(.{ .root_module = integration_mod });

    const test_step = b.step("test", "Run FFI unit + integration tests");
    test_step.dependOn(&b.addRunArtifact(main_tests).step);
    test_step.dependOn(&b.addRunArtifact(integration_tests).step);
}
