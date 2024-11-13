const std = @import("std");

const intrinsics = @embedFile("intrinsics");

pub fn main() !void {
    std.debug.print("intrinsics:\n", .{});
    std.debug.print("{s}", .{intrinsics});
}
