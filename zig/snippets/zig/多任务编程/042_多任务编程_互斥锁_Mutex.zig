const std = @import("std");

var global_counter: usize = 0;
var mutex = std.Thread.Mutex{};

fn increment() void {
    for (0..1000) |_| {
        mutex.lock();
        defer mutex.unlock();
        global_counter += 1;
    }
}

pub fn main() !void {
    var thread1 = try std.Thread.spawn(.{}, increment, .{});
    var thread2 = try std.Thread.spawn(.{}, increment, .{});

    thread1.join();
    thread2.join();

    std.debug.print("Final counter value: {}\n", .{global_counter});
}
