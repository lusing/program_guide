const std = @import("std");

var mutex = std.Thread.Mutex{};
var condition = std.Thread.Condition{};

var ready = false;

fn worker() void {
    mutex.lock();
    defer mutex.unlock();

    while (!ready) {
        condition.wait(&mutex);
    }

    std.debug.print("Worker: Processing after signal\n", .{});
}

pub fn main() !void {
    var worker_thread = try std.Thread.spawn(.{}, worker, .{});

    std.time.sleep(100 * std.time.ns_per_ms);

    mutex.lock();
    ready = true;
    mutex.unlock();

    condition.broadcast();

    worker_thread.join();
}
