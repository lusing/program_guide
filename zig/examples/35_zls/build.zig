//! 35 · ZLS 与编辑器工具链 —— "保存即编译检查"的 build.zig 写法。
//!
//! 用法对照 docs/35-zls.md：
//!   zig build        正常编译并安装到 zig-out/
//!   zig build test   跑单元测试
//!   zig build check  只验证"能编译"，不安装任何产物 ← ZLS 保存时跑的就是它
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const exe = b.addExecutable(.{ .name = "zls_demo", .root_module = exe_mod });
    b.installArtifact(exe);

    // run 步骤：zig build run
    const run = b.addRunArtifact(exe);
    const run_step = b.step("run", "运行演示程序");
    run_step.dependOn(&run.step);

    // test 步骤：zig build test
    const unit_tests = b.addTest(.{ .root_module = exe_mod });
    const run_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "跑单元测试");
    test_step.dependOn(&run_tests.step);

    // ── check 步骤：本章的核心 ─────────────────────────────────────
    // 同一个模块再登记一次编译，但**不** installArtifact：
    // 编译器把类型检查/语义分析跑完就停，不产出、不拷贝任何二进制。
    // ZLS 配置 enable_build_on_save=true + build_on_save_args=["check"]
    // 之后，每次保存编辑器里跑的就是这一步。
    const exe_check = b.addExecutable(.{ .name = "zls_demo_check", .root_module = exe_mod });
    const check = b.step("check", "只检查能否编译（ZLS 保存时调用）");
    check.dependOn(&exe_check.step);
}
