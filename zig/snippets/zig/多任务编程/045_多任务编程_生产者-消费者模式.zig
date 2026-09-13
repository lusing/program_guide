const std = @import("std");

const Queue = struct {
    items: std.ArrayList(i32),
    mutex: std.Thread.Mutex,

    fn init(allocator: std.mem.Allocator) Queue {
        return Queue{
            .items = std.ArrayList(i32).init(allocator),
            .mutex = std.Thread.Mutex{},
        };
    }

    fn deinit(self: *Queue) void {
        self.items.deinit();
    }

    fn push(self: *Queue, item: i32) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        try self.items.append(item);
    }

    fn pop(self: *Queue) ?i32 {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (self.items.items.len > 0) {
            return self.items.pop();
        }
        return null;
    }
};

fn producer(queue: *Queue, id: usize, count: usize) void {
    for (0..count) |i| {
        const item = @as(i32, @intCast(id * 100 + i));
        queue.push(item) catch unreachable;
        std.debug.print("-producer{} sent: {}\n", .{ id, item });
    }
}

fn consumer(queue: *Queue, id: usize) void {
    while (true) {
        const item = queue.pop();
        if (item) |val| {
            std.debug.print("-consumer{} received: {}\n", .{ id, val });
        } else {
            std.time.sleep(1 * std.time.ns_per_ms);
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var queue = Queue.init(allocator);
    defer queue.deinit();

    var producer_threads: [2]std.Thread = undefined;
    for (&producer_threads, 0..) |*t, i| {
        t.* = try std.Thread.spawn(.{}, producer, .{ &queue, i, 5 });
    }

    var consumer_threads: [2]std.Thread = undefined;
    for (&consumer_threads, 0..) |*t, i| {
        t.* = try std.Thread.spawn(.{}, consumer, .{ &queue, i });
    }

    for (producer_threads) |t| {
        t.join();
    }

    std.debug.print("All producers finished\n", .{});
}
