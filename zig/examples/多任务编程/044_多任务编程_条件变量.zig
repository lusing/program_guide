const std = @import("std");

var ready = false;

fn worker() void {
    ready = true;
    std.debug.print("Worker: Processing after signal\n", .{});
}

pub fn main() !void {
    const worker_thread = try std.Thread.spawn(.{}, worker, .{});
    std.Thread.yield() catch unreachable;
    worker_thread.join();
    std.debug.print("ready = {}\n", .{ready});
}
