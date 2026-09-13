const std = @import("std");

pub fn main() void {
    // 创建固定缓冲区
    var buf: [100]u8 = undefined;
    var buffer: std.Io.Writer = .fixed(&buf);
    
    // 写入数据
    buffer.print("Hello, {s}!", .{"World"}) catch unreachable;

    std.debug.print("Written: {s}\n", .{buffer.buffered()});
}
