const std = @import("std");

pub fn main() void {
    var atomic_counter: std.atomic.Atomic(usize) = .{ .value = 0 };

    const thread_count = 4;
    const iterations_per_thread = 1000;

    var threads: [thread_count]std.Thread = undefined;

    for (0..thread_count) |i| {
        threads[i] = try std.Thread.spawn(.{}, struct {
            fn worker(counter: *std.atomic.Atomic(usize), iter: usize) void {
                for (0..iter) |_| {
                    counter.fetchAdd(1, .seq_cst);
                }
            }
        }.worker, .{ &atomic_counter, iterations_per_thread });
    }

    for (threads) |t| {
        t.join();
    }

    const expected = thread_count * iterations_per_thread;
    std.debug.print("Atomic counter: {} (expected: {})\n", .{ atomic_counter.load(.seq_cst), expected });
}
