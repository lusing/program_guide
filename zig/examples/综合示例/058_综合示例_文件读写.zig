const std = @import("std");

pub fn main() !void {
    const io = std.Options.debug_io;
    const dir = std.Io.Dir.cwd();

    var file = try dir.createFile(io, "test.txt", .{});
    defer file.close(io);

    try file.writeStreamingAll(io, "Hello, Zig File!\n");
    std.debug.print("Wrote file successfully\n", .{});
}
