// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// SR-71 BlackGlider FFI Integration Tests
//
// Exercises the exported C-ABI surface of src/main.zig through the `ffi`
// module import wired in build.zig. Instantiated 2026-08-04 from the
// template placeholder ("placeholder test - implementation required"),
// which asserted only `expect(true)`.
//
// Run: `zig build test` (from src/interface/ffi/), or `just test`.

const std = @import("std");
const ffi = @import("ffi");

test "lifecycle: init -> is_initialized -> free" {
    const h = ffi.sr71_blackglider_init() orelse return error.InitFailed;
    try std.testing.expectEqual(@as(u32, 1), ffi.sr71_blackglider_is_initialized(h));
    ffi.sr71_blackglider_free(h);
}

test "is_initialized on null handle is 0, not a crash" {
    try std.testing.expectEqual(@as(u32, 0), ffi.sr71_blackglider_is_initialized(null));
}

test "process: ok on live handle, null_pointer on null handle" {
    const h = ffi.sr71_blackglider_init() orelse return error.InitFailed;
    defer ffi.sr71_blackglider_free(h);

    try std.testing.expectEqual(ffi.Result.ok, ffi.sr71_blackglider_process(h, 42));
    try std.testing.expectEqual(ffi.Result.null_pointer, ffi.sr71_blackglider_process(null, 42));
}

test "process_array: ok on buffer, null_pointer on null buffer" {
    const h = ffi.sr71_blackglider_init() orelse return error.InitFailed;
    defer ffi.sr71_blackglider_free(h);

    const buf = [_]u8{ 1, 2, 3, 4 };
    try std.testing.expectEqual(ffi.Result.ok, ffi.sr71_blackglider_process_array(h, &buf, buf.len));
    try std.testing.expectEqual(ffi.Result.null_pointer, ffi.sr71_blackglider_process_array(h, null, 0));
}

test "string round-trip: get_string allocates, free_string releases" {
    const h = ffi.sr71_blackglider_init() orelse return error.InitFailed;
    defer ffi.sr71_blackglider_free(h);

    const s = ffi.sr71_blackglider_get_string(h) orelse return error.NoString;
    defer ffi.sr71_blackglider_free_string(s);
    try std.testing.expectEqualStrings("Example result", std.mem.span(s));
}

test "get_string on null handle returns null and records an error" {
    try std.testing.expectEqual(@as(?[*:0]const u8, null), ffi.sr71_blackglider_get_string(null));
    const err = ffi.sr71_blackglider_last_error() orelse return error.NoErrorRecorded;
    try std.testing.expectEqualStrings("Null handle", std.mem.span(err));
}

test "callback registration: ok with callback, null_pointer without" {
    const h = ffi.sr71_blackglider_init() orelse return error.InitFailed;
    defer ffi.sr71_blackglider_free(h);

    const cb = struct {
        fn hit(_: u64, x: u32) callconv(.c) u32 {
            return x;
        }
    }.hit;
    try std.testing.expectEqual(ffi.Result.ok, ffi.sr71_blackglider_register_callback(h, cb));
    try std.testing.expectEqual(ffi.Result.null_pointer, ffi.sr71_blackglider_register_callback(h, null));
}

test "version and build info are non-empty and consistent" {
    const ver = std.mem.span(ffi.sr71_blackglider_version());
    try std.testing.expect(ver.len > 0);
    const info = std.mem.span(ffi.sr71_blackglider_build_info());
    try std.testing.expect(std.mem.indexOf(u8, info, "Zig") != null);
}
