const std = @import("std");

pub fn main() void {
    // 打印调用栈
    std.debug.print("Current function: {}\n", .{@functionName()});

    // 打印文件和行号
    std.debug.print("File: {}, Line: {}\n", .{ @src().file, @src().line });

    // 性能计数（使用纳秒时间戳）
    const start = std.time.nanoTimestamp();
    // ... 一些操作 ...
    const end = std.time.nanoTimestamp();
    std.debug.print("Execution time: {} ns\n", .{end - start});
}
