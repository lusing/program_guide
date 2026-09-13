fn describe(comptime T: type, value: T) void {
    std.debug.print("Type: {}, Value: {}\n", .{ @typeName(T), value });
}

pub fn main() void {
    describe(i32, 42);
    describe(f64, 3.14);
    describe([]const u8, "Hello");
}
