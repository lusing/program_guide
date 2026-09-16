# 15 · 测试 ⭐

> 对应示例：`examples/15_testing/`
>
> 测试是语言内建的——没有框架要装、没有配置要写。

## 15.1 test 块与 zig test

```zig
test "repeat 重复拼接" {
    const a = std.testing.allocator;
    const r = try repeat(a, "ab", 3);
    defer a.free(r);
    try std.testing.expectEqualStrings("ababab", r);
}
```

```bash
zig test main.zig        # 跑本文件（含引用到的模块）全部 test 块
```

`test "描述" { ... }` 就是测试本体。**测试函数能返回错误**（`try` 直接用），断言失败和 try 失败都算测试失败。这个设计让测试代码和业务代码完全同构——没有 `TEST(a, b)` 宏、没有独立的 assert 体系。

## 15.2 断言族

| 断言 | 用途 |
|---|---|
| `expect(bool)` | 布尔为真 |
| `expectEqual(expected, actual)` | 值相等（**类型必须严格一致**） |
| `expectEqualStrings(a, b)` | 字符串（失败打印 diff） |
| `expectEqualSlices(T, a, b)` | 切片逐元素 |
| `expectError(err, error_union)` | 错误联合抛的是这个错 |
| `expectFmt(expected, fmt, args)` | 格式化输出对 |

```zig
try std.testing.expectError(error.TooBig, parseLike(9));
const opt: ?u8 = null;
try std.testing.expect(opt == null);   // 0.16 没有 expectNull，直接判空
```

注意 `expectEqual` 的两个参数**类型必须完全一致**——`expectEqual(5, some_u8)` 编译错（comptime_int ≠ u8），要写 `@as(u8, 5)`。这是刻意的：测试里的类型含糊会漏掉真 bug。

## 15.3 testing.allocator：泄漏即失败 ⭐

```zig
test "testing.allocator 抓泄漏" {
    const a = std.testing.allocator;
    const buf = try a.alloc(u8, 10);
    a.free(buf);        // ← 把这行注释掉再跑：测试直接判负
}
```

`std.testing.allocator` 背后是 11 章的 DebugAllocator——**测试结束时还有没释放的内存，测试就失败**，并把泄漏块的分配点（文件:行号）打出来。实测泄漏输出：

```text
1/1 l.test.leak demo...OK
[DebugAllocator] (err): memory address 0x13e030b0000 leaked:
F:\tmp\zigprobe\leak\l.zig:4:28: ... in test.leak demo (test_zcu.obj)
    const buf = try a.alloc(u8, 10);
```

（注意看：断言全过、泄漏照样判负——**内存正确性是一等测试目标**。）第 11 章"泄漏当场抓获"的承诺，在测试里是自动执行的。

## 15.4 多文件测试：引用即生效

```zig
// main.zig
test {
    _ = util;     // 不引用，util.zig 里的 test 块就不会跑
}
```

test 块只对**被引用到的文件**生效——顶层加一个空 test 块 `_ = @import("util.zig");` 把模块拽进来，它的测试才进入 `zig test` 的清单。多模块工程的惯例是根文件放一个 `test { _ = 模块A; _ = 模块B; }` 汇总入口（16 章的 `zig build test` 就是这么收集全工程的）。

## 15.5 过滤与辅助设施

```bash
zig test main.zig --test-filter "repeat"    # 只跑名字匹配的测试
zig test main.zig -lc                        # 链 libc（17 章 cImport 测试需要）
```

- `std.testing.tmpDir(.{})`：自清理临时目录（20/24 章的端到端测试用它落盘）。
- `std.testing.io`：测试环境里的 Io 实例——需要 io 参数的函数在测试里传它。
- `expectApproxEqAbs`：浮点容差比较。

## 15.6 一个完整的被测模块

```zig
// util.zig——模块自己带测试，跟着代码走
pub fn sluggify(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);          // 10 章模式：失败回滚
    for (s) |ch| try out.append(allocator, if (ch == ' ') '-' else std.ascii.toLower(ch));
    return out.toOwnedSlice(allocator);
}
test "sluggify 行为" {
    const a = std.testing.allocator;
    const r = try sluggify(a, "Hello World!");
    defer a.free(r);
    try std.testing.expectEqualStrings("hello-world!", r);
}
```

## 15.7 坑位清单

1. **`zig test` 不分析 `pub fn main`**：main 里的编译错误（比如转型问题）测试照绿——**build.ps1 三层验证的第三层（build-exe + 运行）就是补这个盲区**，别只跑测试就收工（本教程实测踩到：测试过了、exe 编译炸）。
2. **expectEqual 类型严格一致**：`expectEqual(4, x_u8)` 编译错——期望值 `@as` 成同类型；comptime_int 不是 u8。
3. **子模块测试没跑的假绿**：忘了 `test { _ = util; }`，util 的测试静默缺席——绿得莫名其妙时先查测试清单（输出里的 `N/M` 计数）。
4. **测试里 defer 照常执行**：断言失败抛错误也会走 defer 清理——所以 `defer a.free(r)` 在失败路径也不泄漏。
5. **0.16 没有 `expectNull`**：写 `expect(opt == null)`（其他 expect* 也以 `std/testing.zig` 源码为准——15.5 的探针方法）。

---
