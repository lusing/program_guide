const std = @import("std");

const Queue = struct {
    items: std.ArrayList(i32),

    fn init() Queue {
        return .{ .items = .empty };
    }

    fn deinit(self: *Queue, allocator: std.mem.Allocator) void {
        self.items.deinit(allocator);
    }
};

fn producer(queue: *Queue, id: usize, count: usize) void {
    _ = queue;
    for (0..count) |i| {
        const item = @as(i32, @intCast(id * 100 + i));
        std.debug.print("-producer{} sent: {}\n", .{ id, item });
    }
}

fn consumer(queue: *Queue, id: usize, count: usize) void {
    _ = queue;
    for (0..count) |i| {
        std.debug.print("-consumer{} received: {}\n", .{ id, i });
    }
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var queue = Queue.init();
    defer queue.deinit(allocator);

    const thread1 = try std.Thread.spawn(.{}, producer, .{ &queue, 0, 5 });
    const thread2 = try std.Thread.spawn(.{}, consumer, .{ &queue, 0, 5 });
    thread1.join();
    thread2.join();

    std.debug.print("All producers finished\n", .{});
}
