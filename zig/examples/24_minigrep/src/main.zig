//! 24 实战迷你 grep：minigrep <模式> [目录]（递归 + 多线程 + 高亮）
const std = @import("std");
const search = @import("search.zig");

const Worker = struct {
    io: std.Io,
    needle: []const u8,
    out: std.ArrayList(search.Match) = .empty,
    mtx: std.Io.Mutex = .init,

    fn searchFile(self: *Worker, alloc: std.mem.Allocator, path: []const u8) void {
        const cwd = std.Io.Dir.cwd();
        const text = cwd.readFileAlloc(self.io, path, alloc, .limited(16 * 1024 * 1024)) catch return;
        defer alloc.free(text);
        const hits = search.searchLines(alloc, text, self.needle) catch return;
        defer alloc.free(hits);
        if (hits.len == 0) return;
        self.mtx.lockUncancelable(self.io); // 只在合并结果时上锁
        defer self.mtx.unlock(self.io);
        for (hits) |h| {
            const owned = search.Match{
                .path = alloc.dupe(u8, path) catch return,
                .line_no = h.line_no,
                .line = alloc.dupe(u8, h.line) catch return,
            };
            self.out.append(alloc, owned) catch return;
        }
    }
};

fn walkDir(io: std.Io, alloc: std.mem.Allocator, dir_path: []const u8, out: *std.ArrayList([]const u8)) !void {
    const cwd = std.Io.Dir.cwd();
    var dir = cwd.openDir(io, dir_path, .{ .iterate = true }) catch return; // 无权限等：跳过
    defer dir.close(io);
    var it = dir.iterate();
    while (try it.next(io)) |entry| {
        const full = try std.fs.path.join(alloc, &.{ dir_path, entry.name });
        switch (entry.kind) {
            .directory => try walkDir(io, alloc, full, out),
            .file => try out.append(alloc, full),
            else => {},
        }
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const mem = arena_state.allocator();

    // ═══ 参数：模式 + 目录（默认 src，保证 zig build run 输出确定）
    var args_it = try std.process.Args.Iterator.initAllocator(init.minimal.args, mem);
    _ = args_it.skip(); // 跳过程序名
    const needle = args_it.next() orelse {
        std.debug.print("用法：minigrep <模式> [目录]（默认搜 src）\n", .{});
        return;
    };
    const root = args_it.next() orelse "src";

    // ═══ 递归收集文件
    var files: std.ArrayList([]const u8) = .empty;
    walkDir(io, mem, root, &files) catch |e| {
        std.debug.print("打开目录 {s} 失败：{s}\n", .{ root, @errorName(e) });
        return e;
    };

    // ═══ 多线程：原子游标抢任务（比队列分发简单，且天然负载均衡）
    var worker: Worker = .{ .io = io, .needle = needle };
    const nt = @min(4, @max(1, files.items.len));
    var next: std.atomic.Value(usize) = std.atomic.Value(usize).init(0);
    var threads: [4]std.Thread = undefined;
    const Task = struct {
        fn run(w: *Worker, fl: []const []const u8, nx: *std.atomic.Value(usize), a: std.mem.Allocator) void {
            while (true) {
                const i = nx.fetchAdd(1, .monotonic);
                if (i >= fl.len) break;
                w.searchFile(a, fl[i]);
            }
        }
    };
    for (0..nt) |i| threads[i] = try std.Thread.spawn(.{}, Task.run, .{ &worker, files.items, &next, mem });
    for (threads[0..nt]) |t| t.join(); // 0.16 无 WaitGroup：join 即同步点

    // ═══ 输出（缓冲 Writer + ANSI 高亮）
    var buf: [4096]u8 = undefined;
    var w = std.Io.File.stdout().writer(io, &buf);
    const out = &w.interface;
    for (worker.out.items) |m| {
        try search.printHighlighted(out, m.path, m, needle);
    }
    try out.print("共 {d} 处命中，扫了 {d} 个文件（{d} 线程）\n", .{ worker.out.items.len, files.items.len, nt });
    try out.flush();
}

test "端到端：临时目录搜索" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "a.txt", .data = "hello zig\nno match\nzig again" });
    try tmp.dir.writeFile(io, .{ .sub_path = "b.txt", .data = "plain" });
    const hits = try search.searchLines(a, "hello zig\nno match\nzig again", "zig");
    defer a.free(hits);
    try std.testing.expectEqual(@as(usize, 2), hits.len);
    try std.testing.expectEqual(@as(usize, 3), hits[1].line_no);
}
