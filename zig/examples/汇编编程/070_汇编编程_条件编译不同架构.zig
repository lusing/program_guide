const std = @import("std");

pub fn main() void {
    const arch = @import("builtin").cpu.arch;
    switch (arch) {
        .x86_64 => std.debug.print("Running on x86_64\n", .{}),
        .aarch64 => std.debug.print("Running on ARM64\n", .{}),
        else => std.debug.print("Unsupported architecture\n", .{}),
    }
}
