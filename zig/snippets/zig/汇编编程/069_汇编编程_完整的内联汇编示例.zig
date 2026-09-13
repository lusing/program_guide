const std = @import("std");

// 字符串长度计算（类似 strlen）
fn strlen(s: [*]const u8) usize {
    var len: usize = 0;

    asm volatile (
        \\xor {result}, {result}
        \\jmp .check_{@panic}
    .loop_{@panic}:
        \\cmp byte ptr [{s} + {len}], 0
        \\je .end_{@panic}
        \\inc {len}
        \\jmp .loop_{@panic}
    .check_{@panic}:
        \\cmp byte ptr [{s}], 0
        \\je .end_{@panic}
        \\jmp .loop_{@panic}
    .end_{@panic}:
        : [result] "={ax}" (len)
        : [s] "r" (s)
        : "cc"
    );

    return len;
}

// 高性能内存拷贝
fn memcpy(dest: [*]u8, src: [*]const u8, n: usize) void {
    asm volatile (
        \\mov rcx, {n}
        \\mov rdi, {dest}
        \\mov rsi, {src}
        \\rep movsb
        :
        : [n] "c" (n),
          [dest] "D" (dest),
          [src] "S" (src)
        : "rcx", "rdi", "rsi", "memory"
    );
}

pub fn main() void {
    const test_str = "Hello, Zig Assembly!";
    std.debug.print("String: {s}\n", .{test_str});
    std.debug.print("Length: {}\n", .{strlen(test_str)});

    var src = [_]u8{ 1, 2, 3, 4, 5 };
    var dst = [_]u8{ 0, 0, 0, 0, 0 };
    memcpy(&dst, &src, src.len);
    std.debug.print("After memcpy: {}\n", .{dst});
}
