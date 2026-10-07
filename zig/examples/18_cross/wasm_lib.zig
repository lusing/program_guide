//! 18 交叉编译：wasm32-freestanding 侧的模块。
//!
//! freestanding = 裸机目标：没有 OS、没有 libc、没有 `_start`、没有 std 的 I/O。
//! 所以这个文件：
//!   · **没有 `main`**（没有 OS 可言，就没有程序入口的概念）
//!   · **没有 `std.debug.print`**（它会拖进 std.Io.Threaded → 报 posix.system has no member 'getrandom'）
//!   · 只有 `export fn` / `export var` —— 宿主（wasmtime / node / 浏览器）按名字调
//!
//! 四条验证通道里它对应第三条：
//!   zig build-lib wasm_lib.zig -target wasm32-freestanding -femit-bin=18_cross.wasm
//!
//! ⚠️ **产物其实不是 wasm 模块**：不带 `-dynamic` 时 `link_mode=static`，
//!    `file` 看到的是 `current ar archive`（ar 归档里装着那个 wasm 目标文件）。
//!    想要能被宿主直接实例化的真模块，见文档 18.8 的 `-dynamic -fPIC` 路线。
//!
//! ⚠️ **本文件的 test 块不参与 `zig test main.zig`**（那是另一个编译单元）。
//!    而且在 freestanding 上**连编译测试二进制都做不到**——runner 要 std.Io.Threaded。
//!    真正能跑的语法验证是切到 wasi（实测通过）：
//!      zig test wasm_lib.zig -target wasm32-wasi --test-no-exec -femit-bin=out.wasm

// ── 18.8 宿主接口 ────────────────────────────────────────────────

/// 宿主最常用的形态：直接拿返回值。
/// node 侧：`i.exports.add(3, 4)`
export fn add(a: i32, b: i32) i32 {
    return a +% b;
}

/// 迭代版斐波那契。用 wrapping 算术（`+%`）而不是 `+`：
/// Debug 模式下溢出是编译错误，Release 模式才是回绕——写 `+%` 让两种模式行为一致。
export fn fib(n: u32) u32 {
    if (n <= 1) return n;
    var a: u32 = 0;
    var b: u32 = 1;
    var i: u32 = 1;
    while (i < n) : (i += 1) {
        const t = a +% b;
        a = b;
        b = t;
    }
    return b;
}

/// 「跑一次取一批结果」的形态：结果写进一个导出的可变全局。
///
/// ⚠️ **实测坑**：在 `-dynamic -fPIC` 产出的 wasm 里，宿主读这个 global 拿到的是
///    **加载时的快照**（永远是初值0），不是模块内部那个活的值。
///    最小复现（`export var g: i32 = 7; export fn bump() i32 { g += 1; return g; }`）：
///    node 里 `g.value` 初始 0、`bump()` 返回 8、再 `bump()` 返回 9、`g.value` 仍是 0。
///    原因：PIC 模式下模块数据在宿主提供的 linear memory 里，
///    而导出的 global 是 wasm 引擎在实例化时快照出来的独立对象。
///    ⇒ **跨边界只用返回值**。这个 `last` 只是给"同一模块内别的导出函数"中转用的。
export var last: i32 = 0;

/// 一次算三个值，全塞进 `last`。演示导出全局怎么配合返回值用。
export fn sum3(a: i32, b: i32, c: i32) i32 {
    last = a +% b +% c;
    return last;
}

/// 纯逻辑 + freestanding **可用**的 std：FNV-1a 32 位校验和。
/// 这条同时证明 `std.hash` 在 freestanding 上是安全的（它不碰系统熵）。
///
/// ⚠️ 参数是 `[*]const u8` + `usize` **两个参数**，不是 `[]const u8` 切片。
/// 原因（实测报错）：`export fn` 走的是目标 ABI，切片没有保证的内存布局——
///
///     error: parameter of type '[]const u8' not allowed in function with
///            calling convention 'x86_64_sysv'
///     note: slices have no guaranteed in-memory representation
///
///    这是 wasm 侧写导出函数的一条通用规则：ABI 边界上只能用标量和裸指针。
export fn checksum(ptr: [*]const u8, len: usize) u32 {
    var acc: u32 = 0x811c9dc5;
    var i: usize = 0;
    while (i < len) : (i += 1) {
        acc ^= ptr[i];
        acc *%= 0x01000193;
    }
    return acc;
}

/// 演示 `std.Io.Writer.fixed` 在 freestanding 上可用：它只写调用方给的内存缓冲，
/// 不碰任何 fd。返回写进去的**字节数**。
///
/// 格式串是 `"0x{x:0>4}"`——注意 `0x` 是**字面量**不是格式符，
/// 而 `{x:0>4}` 至少 4 位十六进制。所以 `fmtWidth(0x1)` 写出 `"0x0001"`，宽度是 6。
export fn fmtWidth(x: u32) usize {
    var buf: [16]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    w.print("0x{x:0>4}", .{x}) catch return 0;
    last = @intCast(w.buffered().len);
    return w.buffered().len;
}

/// 演示 `std.mem.sort` 在 freestanding 上可用（纯计算，无系统调用）。
/// 同样是 `[*]i32` + `usize` 形态；内部用 `ptr[0..len]` 造出切片给 sort。
/// 返回排序后首元素与末元素之和，让宿主能验证顺序确实变了。
export fn sortAndSpan(ptr: [*]i32, len: usize) i32 {
    if (len == 0) return 0;
    std.mem.sort(i32, ptr[0..len], {}, std.sort.asc(i32));
    return ptr[0] +% ptr[len - 1];
}

// ── 本地导入：freestanding 也需要 std 的纯逻辑部分 ────────────────
// 只 import std 本身，不 import std.fs / std.time / std.Thread —— 那些在 18.7 列了会炸。
const std = @import("std");

// ── 测试块 ────────────────────────────────────────────────────────
// ⚠️ 这些测试**跑不到 wasm**：zig build-lib 不执行 test，zig test -target
//    wasm32-freestanding 连编译都失败（runner 依赖 std.Io.Threaded）。
//    它们的价值有两层：
//      1. 作为 wasm 侧逻辑的活文档（每个 test 名说明一个导出函数的契约）
//      2. 在本机目标上真跑（`zig test wasm_lib.zig`，实测全绿）——
//         纯逻辑与平台无关，所以本机绿就说明 wasm 侧那套算法也绿
//    切到 wasi 目标也能真编（见文件头注释的命令）。

test "add：两数相加（含负数与回绕，验证 i32 wrapping 语义）" {
    try std.testing.expectEqual(@as(i32, 7), add(3, 4));
    try std.testing.expectEqual(@as(i32, 0), add(5, -5));
    // minInt + maxInt 在wrapping 下恰好是 -1（用 std.math.minInt，0.17 的 i32 上没有 .min 成员）
    try std.testing.expectEqual(@as(i32, -1), add(std.math.minInt(i32), std.math.maxInt(i32)));
}

test "fib：标准斐波那契数列前若干项" {
    try std.testing.expectEqual(@as(u32, 0), fib(0));
    try std.testing.expectEqual(@as(u32, 1), fib(1));
    try std.testing.expectEqual(@as(u32, 1), fib(2));
    try std.testing.expectEqual(@as(u32, 2), fib(3));
    try std.testing.expectEqual(@as(u32, 5), fib(5));
    try std.testing.expectEqual(@as(u32, 55), fib(10));
    // 递归定义的一致性：fib(n) == fib(n-1) + fib(n-2)
    try std.testing.expectEqual(fib(10), fib(9) +% fib(8));
}

test "sum3：结果同时写进 last（模块内中转用，不是给宿主读的）" {
    _ = sum3(1, 2, 3);
    try std.testing.expectEqual(@as(i32, 6), last);
    _ = sum3(-10, 4, 6);
    try std.testing.expectEqual(@as(i32, 0), last);
}

test "checksum：FNV-1a 32 位标准测试向量（与平台无关）" {
    try std.testing.expectEqual(@as(u32, 0x811c9dc5), checksum("".ptr, 0));
    try std.testing.expectEqual(@as(u32, 0xe40c292c), checksum("a".ptr, 1));
    try std.testing.expectEqual(@as(u32, 0xbf9cf968), checksum("foobar".ptr, 6));
    // 切片要先取 .ptr 和 .len —— 因为导出函数的签名是 ABI 形态
    const s = "hello";
    try std.testing.expectEqual(checksum(s.ptr, s.len), checksum(s.ptr, s.len));
}

test "fmtWidth：std.Io.Writer.fixed 在 freestanding 可用（只写内存不碰 fd）" {
    // "0x0001" → 6 字节；"0xabcd" → 6 字节（0x 是字面量，{x:0>4} 恰好 4 位）
    try std.testing.expectEqual(@as(usize, 6), fmtWidth(0x1));
    try std.testing.expectEqual(@as(usize, 6), fmtWidth(0xabcd));
    // last 被 fmtWidth 写成宽度（6）
    try std.testing.expectEqual(@as(i32, 6), last);
}

test "sortAndSpan：std.mem.sort 真的把数据排好了" {
    var a = [_]i32{ 5, -3, 9, 0, 7 };
    try std.testing.expectEqual(@as(i32, -3 + 9), sortAndSpan(a[0..].ptr, a.len));
    // 验证升序：相邻比较要用前一个元素的下标，a[i-1] 而非 a[i]
    for (a[1..], 1..) |x, i| try std.testing.expect(a[i - 1] <= x);

    // 零长切片不炸（宿主传空 buffer 时的常见情形）
    var b = [_]i32{};
    try std.testing.expectEqual(@as(i32, 0), sortAndSpan(b[0..].ptr, b.len));
}

test "本文件没有 main：freestanding 模块不是程序" {
    // 显式断言这一点：wasm_lib.zig 的根命名空间里确实没有 main
    try std.testing.expect(!@hasDecl(@This(), "main"));
    // ⚠️ 但 `@hasDecl(@This(), "add")` 是 **false**——实测结论：
    //    `export fn` 不等于 `pub fn`。只有 `pub export fn` 才让 @hasDecl 看见。
    //    所以下面改成**直接引用**每个导出（引用即验证它存在且能编译），
    //    这比 @hasDecl 更贴近"宿主真的能调到"这件事。
    try std.testing.expectEqual(@as(i32, 3), add(1, 2));
    try std.testing.expectEqual(@as(u32, 1), fib(2));
    _ = sum3(0, 0, 0);
    var bytes = [_]u8{'a'};
    try std.testing.expect(checksum(bytes[0..].ptr, bytes.len) != 0);
    _ = fmtWidth(0);
    var nums = [_]i32{ 2, 1 };
    _ = sortAndSpan(nums[0..].ptr, nums.len);
    // last 是 var 不是 fn：宿主按 global 读（这里用类型断言确认它是 i32）
    try std.testing.expect(@TypeOf(last) == i32);
}
