//! 0.17 的 C 互操作全部由构建系统完成：
//!   b.addTranslateC   —— 把 C 头文件翻译成 Zig 模块（0.17 起 @cImport 已移除）
//!   addCSourceFiles   —— 把 .c 文件交给 zig cc 前端，与 Zig 代码一起链接
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ① 翻译头文件 → 一个名为 ci 的 Zig 模块
    const tc = b.addTranslateC(.{
        .root_source_file = b.path("include/ci.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true, // strlen/strcmp 在 libc 里
    });
    const ci_module = tc.createModule(); // 私有模块：只给本工程用
    // 头文件自己 #include 了别的系统头（如 string.h），需要额外的 include 路径时用：
    // tc.addSystemIncludePath(.{ .cwd_relative = "/usr/include" });

    // ①' 第二组头文件（结构体 / 数组 / 函数指针）→ 又一个私有模块。
    // 同一个 addTranslateC 步骤可以多次调用，各自带名字，互不干扰。
    const tc_ext = b.addTranslateC(.{
        .root_source_file = b.path("include/ci_ext.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const ci_ext_module = tc_ext.createModule();

    // ② Zig 主模块：imports 里挂上翻译结果，并链接 C 源文件
    const main_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "ci", .module = ci_module },
            .{ .name = "ci_ext", .module = ci_ext_module },
        },
    });
    main_mod.addCSourceFiles(.{
        .root = b.path("csrc"),
        .files = &.{ "ci.c", "ci_ext.c" },
        .flags = &.{ "-I", "include" },
    });

    const exe = b.addExecutable(.{
        .name = "17_cinterop",
        .root_module = main_mod,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.addPassthruArgs(); // 0.17：b.args 已移除，改用 addPassthruArgs
    const run_step = b.step("run", "跑 C 互操作示例");
    run_step.dependOn(&run_cmd.step);

    const tests = b.addTest(.{ .root_module = main_mod });
    const test_step = b.step("test", "跑单元测试");
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
