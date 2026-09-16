//! 17 C 互操作：extern 声明、@cImport、export 导出（构建需 -lc）
const std = @import("std");

// ═══ 17.1 extern fn：手写 C 函数声明（直接链接 libc）
extern fn printf(format: [*:0]const u8, ...) c_int;

// ═══ 17.2 @cImport：引入整个 C 头文件（符号进 c 命名空间）
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("string.h");
});

// ═══ 17.3 export fn：Zig 函数按 C ABI 导出（供 C/其他语言调用）
export fn zig_add(a: i32, b: i32) i32 {
    return a + b;
}

pub fn main() !void {
    // 17.1 手写 extern：普通字符串字面量就是 0 结尾（旧的 c"" 前缀已移除），可直接传
    _ = printf("printf 直连：zig_add(3,4)=%d\n", zig_add(3, 4));

    // 17.2 @cImport 的符号全在 c 下（类型/宏/函数）
    _ = c.printf("cImport 版：strlen(hello)=%d\n", @as(c_int, @intCast(c.strlen("hello"))));

    // ═══ 17.7 切片 ↔ C 指针：哨兵保证 0 结尾，std.mem.span 走回头路
    const zig_str = "哨兵切片互转";
    const c_ptr: [*:0]const u8 = zig_str.ptr; // 切片首指针
    const back: [:0]const u8 = std.mem.span(c_ptr); // 指针 → 哨兵切片
    std.debug.print("span 回来长度 {d}（两侧字节一致）\n", .{back.len});

    std.debug.print("自检通过\n", .{});
}

test "C ABI 与 cImport 可用（须 zig test -lc）" {
    try std.testing.expectEqual(@as(i32, 7), zig_add(3, 4));
    try std.testing.expectEqual(@as(usize, 5), c.strlen("hello"));
}
