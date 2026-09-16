//! 11 分配器：显式传递的内存策略（Zig 核心特色）
const std = @import("std");

// ═══ 11.7 惯用法：分配器是第一个参数（谁调用谁负责内存）
fn dupString(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    return allocator.dupe(u8, s);
}

// ═══ 11.4 Arena 场景：解析一批数据，统一回收
fn parseLine(arena: std.mem.Allocator, line: []const u8) ![]const []const u8 {
    var parts: std.ArrayList([]const u8) = .empty;
    var it = std.mem.tokenizeAny(u8, line, " ,"); // 任一字符都算分隔符（Sequence 是整段匹配）
    while (it.next()) |tok| {
        try parts.append(arena, try arena.dupe(u8, tok)); // 中间产物全挂 arena
    }
    return parts.toOwnedSlice(arena);
}

pub fn main() !void {
    // ═══ 11.1 栈优先：长度已知的小东西不碰堆
    var buf: [64]u8 = undefined;
    @memset(&buf, 'A');
    std.debug.print("栈上 64 字节：{s}...\n", .{buf[0..8]});

    // ═══ 11.2 page_allocator：直接向 OS 要页（最底层，每次分配整页开销）
    {
        const page = std.heap.page_allocator;
        const big = try page.alloc(u32, 1_000_000);
        defer page.free(big);
        std.debug.print("page_allocator：{d} 万 u32 = {d} MB\n", .{ big.len / 10000, big.len * 4 >> 20 });
    }

    // ═══ 11.3 DebugAllocator（旧名 GPA）：带泄漏检测的调试堆
    {
        var da = std.heap.DebugAllocator(.{}){};
        defer {
            const st = da.deinit(); // 收尾检查：有泄漏返回 .leak
            std.debug.print("DebugAllocator 收尾：{s}\n", .{@tagName(st)});
        }
        const gpa = da.allocator();
        const msg = try dupString(gpa, "分配器显式传递");
        defer gpa.free(msg);
        std.debug.print("dup 出来：{s}\n", .{msg});
    }

    // ═══ 11.4 Arena：一次 init，批量分配，deinit 统一回收
    {
        var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena_state.deinit(); // ← 所有 arena 分配在这里一次性归还
        const arena = arena_state.allocator();
        const words = try parseLine(arena, "the quick brown fox");
        std.debug.print("arena 切了 {d} 段：", .{words.len});
        for (words) |wd| std.debug.print("{s}/", .{wd});
        std.debug.print("\n", .{});
    }

    // ═══ 11.5 FixedBuffer：拿一块缓冲当堆（嵌入式/热路径/无堆环境）
    {
        var backing: [128]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&backing);
        const f = fba.allocator();
        _ = try f.alloc(u8, 50);
        _ = try f.alloc(u8, 50);
        if (f.alloc(u8, 50)) |_| {
            unreachable;
        } else |err| {
            std.debug.print("第三次分配按预期失败：{s}（缓冲只有 128）\n", .{@errorName(err)});
        }
        fba.reset(); // 归零复用
        const again = try f.alloc(u8, 100);
        std.debug.print("reset 后又能分 {d} 字节（无需逐个 free）\n", .{again.len});
    }

    // ═══ 11.6 smp_allocator：多线程/发布版的系统级选择
    {
        const smp = std.heap.smp_allocator;
        const block = try smp.alloc(u64, 100);
        defer smp.free(block);
        std.debug.print("smp_allocator：{d} 字节\n", .{block.len * 8});
    }

    std.debug.print("自检通过\n", .{});
}

test "分配器语义" {
    const a = std.testing.allocator; // 泄漏 = 测试失败（15 章细讲）
    const s = try dupString(a, "abc");
    defer a.free(s);
    try std.testing.expectEqualStrings("abc", s);

    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const words = try parseLine(arena_state.allocator(), "a b c");
    try std.testing.expectEqual(@as(usize, 3), words.len);
    try std.testing.expectEqualStrings("b", words[1]);
}
