const std = @import("std");

fn workerThread(arg: usize) void {
    const thread_id = std.Thread.getCurrentId();
    std.debug.print("Worker {} running on thread {}\n", .{ arg, thread_id });

    for (0..5) |i| {
        std.debug.print("Worker {} iteration {}\n", .{ arg, i });
        std.Thread.yield() catch unreachable;
    }
}

pub fn main() !void {
    const thread1 = try std.Thread.spawn(.{}, workerThread, .{1});
    const thread2 = try std.Thread.spawn(.{}, workerThread, .{2});

    thread1.join();
    thread2.join();

    std.debug.print("All threads completed\n", .{});
}
