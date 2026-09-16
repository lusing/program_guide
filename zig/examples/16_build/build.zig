const std = @import("std");

// build.zig：不改构建，只描述构建——函数返回前一条编译命令都没跑，
// 而是把"要做什么"登记进 b（构建图），外部 runner 负责按依赖并行执行。
pub fn build(b: *std.Build) void {
    // 标准选项：-Dtarget / -Doptimize（zig build --help 可见）
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 可执行文件 = 名字 + 根模块（模块 = 源文件集合 + 编译选项）
    const exe = b.addExecutable(.{
        .name = "16_build",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe); // 安装到 zig-out/（默认 step）

    // run step：zig build run [-- 参数透传]
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // test step：zig build test（收集根模块里的 test 块编译成测试可执行文件再跑）
    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(unit_tests).step);
}
