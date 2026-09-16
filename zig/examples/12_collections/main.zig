//! 12 集合类型：ArrayList（unmanaged）、HashMap、排序
const std = @import("std");

fn lessThan(_: void, a: u32, b: u32) bool {
    return a < b;
}

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const mem = arena_state.allocator();

    // ═══ 12.1 ArrayList：unmanaged 风格（0.14+ 的唯一形态）
    var list: std.ArrayList(u32) = .empty;
    defer list.deinit(mem);
    try list.appendSlice(mem, &.{ 5, 3, 9, 1, 7 });
    try list.append(mem, 2);
    try list.insert(mem, 0, 100); // 指定位置插入
    std.debug.print("list：{any}（len={d}）\n", .{ list.items, list.items.len });
    const popped = list.pop().?; // 0.16 的 pop 返回 ?T（空表得 null，要 .?）
    _ = list.orderedRemove(0); // 有序删（保序搬移）
    std.debug.print("pop={d}，删首后：{any}\n", .{ popped, list.items });

    // ═══ 12.2 容量与 toOwnedSlice：把堆管理权交出去
    try list.ensureTotalCapacity(mem, 32);
    std.debug.print("capacity（已确保 ≥32）：{d}\n", .{list.capacity});
    const owned = try list.toOwnedSlice(mem); // list 变空；owned 归调用者
    defer mem.free(owned);
    std.debug.print("owned：{any}\n", .{owned});

    // ═══ 12.3 AutoHashMap：按键类型自动选哈希与相等
    var map = std.AutoHashMap(u32, []const u8).init(mem);
    defer map.deinit();
    try map.put(1, "一");
    try map.put(2, "二");
    const gop = try map.getOrPut(3); // 拿槽位自己决定插不插
    if (!gop.found_existing) gop.value_ptr.* = "三";
    std.debug.print("map[2]={s}，count={d}，含 1？{}\n", .{ map.get(2).?, map.count(), map.contains(1) });
    _ = map.remove(1);
    std.debug.print("删 1 后 count={d}\n", .{map.count()});

    // ═══ 12.4 StringHashMap：字符串按内容哈希（不是按地址）
    var colors = std.StringHashMap(u32).init(mem);
    defer colors.deinit();
    try colors.put("red", 0xFF0000);
    try colors.put("blue", 0x0000FF);
    std.debug.print("red=0x{x:0>6} blue=0x{x:0>6}\n", .{ colors.get("red").?, colors.get("blue").? });
    var it = colors.iterator(); // 迭代（顺序不保证）
    while (it.next()) |e| {
        std.debug.print("  {s} → 0x{x:0>6}\n", .{ e.key_ptr.*, e.value_ptr.* });
    }
    if (colors.fetchRemove("red")) |rm| { // 删除并取走键值
        std.debug.print("fetchRemove 拿走：{s} → 0x{x:0>6}\n", .{ rm.key, rm.value });
    }

    // ═══ 12.5 排序：std.mem.sort（pdq 家族，ctx 带比较上下文）
    var nums = [_]u32{ 42, 7, 19, 3, 88, 23 };
    std.mem.sort(u32, &nums, {}, lessThan);
    std.debug.print("升序：{any}\n", .{nums});

    // ═══ 12.6 定容集合：BoundedArray 已从 0.16 std 移除，用"数组 + 计数"自己管
    var fixed_buf: [4]u8 = undefined;
    var fixed_len: usize = 0;
    for ("zig") |ch| {
        fixed_buf[fixed_len] = ch;
        fixed_len += 1; // 容量就是数组长度，写满即满（越界有安全检查兜底）
    }
    std.debug.print("定容 4 槽用了 {d} 个：{s}\n", .{ fixed_len, fixed_buf[0..fixed_len] });

    std.debug.print("自检通过\n", .{});
}

test "集合操作" {
    const a = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(a);
    try list.appendSlice(a, "zig");
    try list.append(a, '!');
    try std.testing.expectEqualStrings("zig!", list.items);
    try std.testing.expectEqual(@as(u8, '!'), list.pop());

    var map = std.AutoHashMap(u8, u8).init(a);
    defer map.deinit();
    try map.put(1, 100);
    try std.testing.expectEqual(@as(u8, 100), map.get(1).?);
    try std.testing.expect(!map.contains(2));

    var arr = [_]u32{ 3, 1, 2 };
    std.mem.sort(u32, &arr, {}, lessThan);
    try std.testing.expectEqualSlices(u32, &.{ 1, 2, 3 }, &arr);
}
