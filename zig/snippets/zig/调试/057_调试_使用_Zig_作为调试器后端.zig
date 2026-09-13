const std = @import("std");

// 自定义调试输出
const LogLevel = enum {
    debug,
    info,
    warn,
    error,
};

fn log(level: LogLevel, comptime format: []const u8, values: anytype) void {
    const level_str = switch (level) {
        .debug => "DEBUG",
        .info => "INFO",
        .warn => "WARN",
        .error => "ERROR",
    };

    std.debug.print("[{}] " ++ format ++ "\n", .{level_str} ++ values);
}

pub fn main() void {
    log(.info, "Application started", .{});

    var data = std.ArrayList(i32).init(std.heap.page_allocator);
    defer data.deinit();

    log(.debug, "Adding items to list", .{});
    data.append(1) catch unreachable;
    data.append(2) catch unreachable;
    data.append(3) catch unreachable;

    log(.info, "List contains {} items", .{data.items.len});

    for (data.items, 0..) |item, i| {
        log(.debug, "Item[{}] = {}", .{ i, item });
    }
}
