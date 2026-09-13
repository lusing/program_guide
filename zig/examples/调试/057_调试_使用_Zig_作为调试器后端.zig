const std = @import("std");

const LogLevel = enum {
    debug,
    info,
    warn,
    err,
};

fn log(level: LogLevel, comptime format: []const u8, values: anytype) void {
    const level_str = switch (level) {
        .debug => "DEBUG",
        .info => "INFO",
        .warn => "WARN",
        .err => "ERROR",
    };

    std.debug.print("[{s}] ", .{level_str});
    std.debug.print(format, values);
    std.debug.print("\n", .{});
}

pub fn main() void {
    log(.info, "Application started", .{});

    const allocator = std.heap.page_allocator;
    var data: std.ArrayList(i32) = .empty;
    defer data.deinit(allocator);

    log(.debug, "Adding items to list", .{});
    data.append(allocator, 1) catch unreachable;
    data.append(allocator, 2) catch unreachable;
    data.append(allocator, 3) catch unreachable;

    log(.info, "List contains {} items", .{data.items.len});

    for (data.items, 0..) |item, i| {
        log(.debug, "Item[{}] = {}", .{ i, item });
    }
}
