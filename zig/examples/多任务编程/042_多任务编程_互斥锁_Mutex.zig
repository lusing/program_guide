const std = @import("std");

var global_counter: usize = 0;
var mutex = std.atomic.Mutex.unlocked;

fn increment() void {
    for (0..1000) |_| {
        global_counter += 1;
    }
}

pub fn main() !void {
    const thread1 = try std.Thread.spawn(.{}, increment, .{});
    const thread2 = try std.Thread.spawn(.{}, increment, .{});

    thread1.join();
    thread2.join();

    std.debug.print("Final counter value: {}\n", .{global_counter});
    _ = mutex;
}
