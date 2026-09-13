fn printAll(args: anytype) void {
    const fields = @typeInfo(@TypeOf(args)).@"struct".fields;
    inline for (fields) |field| {
        std.debug.print("{} ", .{@field(args, field.name)});
    }
    std.debug.print("\n", .{});
}

pub fn main() void {
    printAll(.{ 1, 2, 3, "hello", 3.14 });
}
