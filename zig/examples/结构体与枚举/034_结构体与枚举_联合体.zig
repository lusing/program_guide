const std = @import("std");

const Value = union(enum) {
    integer: i32,
    floating: f64,
    string: []const u8,
};

pub fn main() void {
    const v1 = Value{ .integer = 42 };

    switch (v1) {
        .integer => |val| std.debug.print("Integer: {}\n", .{val}),
        .floating => |val| std.debug.print("Float: {}\n", .{val}),
        .string => |val| std.debug.print("String: {s}\n", .{val}),
    }
}
