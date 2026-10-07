//! 子包：a "vendor" 风格的路径依赖。
//! 它只通过 b.addModule 暴露一个具名模块，不产出任何可执行文件——
//! 这是库包最典型的形态：主工程 b.dependency("zmath", …).module("zmath") 取的就是它。
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // addModule("zmath", …) 的第一个参数是「模块名」，
    // 主工程 dep.module("zmath") 里的字符串必须和它一模一样。
    _ = b.addModule("zmath", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
}
