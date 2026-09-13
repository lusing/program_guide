const std = @import("std");

fn workerThread(arg: usize) void {
    const thread_id = std.Thread.getCurrentId();
    std.debug.print("Worker {} running on thread {}\n", .{ arg, thread_id });

    for (0..5) |i| {
        std.debug.print("Worker {} iteration {}\n", .{ arg, i });
        std.time.sleep(100 * std.time.ns_per_ms);
    }
}

pub fn main() !void {
    var thread1 = try std.Thread.spawn(.{}, workerThread, .{1});
    var thread2 = try std.Thread.spawn(.{}, workerThread, .{2});

    thread1.join();
    thread2.join();

    std.debug.print("All threads completed\n", .{});
}
