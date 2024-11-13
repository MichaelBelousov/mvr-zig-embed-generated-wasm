const std = @import("std");
const CrossTarget = std.zig.CrossTarget;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const web_target_query = CrossTarget.parse(.{
        .arch_os_abi = "wasm32-freestanding",
        .cpu_features = "mvp+atomics+bulk_memory",
    }) catch unreachable;
    const web_target = b.resolveTargetQuery(web_target_query);

    const intrinsics = b.addExecutable(.{
        .name = "intrinsics",
        .root_source_file = b.path("./src/intrinsics.zig"),
        .target = web_target,
        .optimize = optimize,
        .strip = switch (optimize) {
            .ReleaseFast, .ReleaseSmall => true,
            else => false,
        },
    });
    intrinsics.entry = .disabled;
    intrinsics.rdynamic = true;

    // FIXME: use .getEmittedAsm to get the wasm output from zig and drop wasm2wat dep!
    // FIXME: build wasm2wat as a dep
    // const intrinsics_to_wat_step = b.addSystemCommand(&.{"wasm2wat"});
    // intrinsics_to_wat_step.addFileArg(intrinsics.getEmittedBin());
    // intrinsics_to_wat_step.addArg("-o");
    // const intrinsics_wat_file = intrinsics_to_wat_step.addOutputFileArg("grappl-intrinsics.wat");
    // intrinsics_to_wat_step.step.dependOn(&intrinsics.step);

    const exe = b.addExecutable(.{
        .name = "zig-embedfile-wat",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.step.dependOn(&intrinsics.step);

    exe.root_module.addAnonymousImport("intrinsics", .{
        .root_source_file = intrinsics.getEmittedAsm(),
        //.root_source_file = intrinsics_wat_file,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);
}
