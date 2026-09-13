const std = @import("std");

pub fn main() void {
    // 根据目标架构调用不同的汇编代码
    const arch = @import("builtin").arch;

    switch (arch) {
        .x86_64 => {
            std.debug.print("Running on x86_64\n", .{});
            // x86_64 specific code
        },
        .aarch64 => {
            std.debug.print("Running on ARM64\n", .{});
            // ARM64 specific code
        },
        else => {
            std.debug.print("Unsupported architecture\n", .{});
        },
    }
}
