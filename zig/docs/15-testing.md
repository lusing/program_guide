# 15 · 测试 ⭐

> 对应示例：`examples/15_testing/main.zig`（494 行）、`examples/15_testing/util.zig`
>
> 2.6 节已经说过"测试和源码写在一起"，那一节是**入门**。这一章是**深入**：
> 把 `zig test` 的每一个选项、`std.testing.*` 的每一个声明、
> 每一个断言失败时到底打印什么，全部在 0.17.0 上实测一遍。
>
> 本章有三条结论会**推翻你可能听过的说法**：
>
> 1. **0.17 没有 doctest**。《Learning Zig》ch7 说"文档注释里的 ```zig 示例自动当测试跑"——
>    实测 `zig test` 对这种写法报 `All 0 tests passed.`（**0 个测试**，退出码 0）。
> 2. **`expectEqual` 对指针/切片比的是地址，不是内容**。两个内容相同的 `u32` 会 FAIL；
>    而两个内容相同的字符串字面量因为被折叠成同一地址，反而**假 OK**。
> 3. **0.17 没有 `std.testing.benchmark`、没有 `std.time.Timer`、没有内建覆盖率**。
>    手写基准的计时接口换成了 `std.Io.Clock.now(.awake, io)`。
>
> 另外一条本教程独有的发现：**`zig test` 不分析 `pub fn main`**——
> 这正是本教程三层验证里第三层（`build-exe` + 运行）存在的理由。

---

## 15.1 测试是语言内建的：不用装任何东西

Zig 的测试是**语言关键字 + 标准库**的组合，没有任何框架要装、没有配置文件要写、没有依赖要声明：

```zig
// examples/15_testing/main.zig 第 60-67 行
pub fn main(init: std.process.Init) !void {
    // ═══ 15.1 测试是语言内建的：test 块 + zig test，什么都不用装 ═══
    begin("15.1");
    std.debug.print("builtin.is_test（本文件按 exe 编译，故为 {}）\n", .{builtin.is_test});
    std.debug.print("测试靠 `zig test main.zig` 跑——build.zig.zon 里没有一行测试依赖\n", .{});
    std.debug.print("test 块是**语言关键字**（不是库函数），语法和 0.16/0.15 完全一致\n", .{});
    std.debug.print("assertion 来自 std.testing.*，那是标准库的一部分，不需要外部框架\n", .{});
    end("15.1");
```

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.1 开始 ====
builtin.is_test（本文件按 exe 编译，故为 false）
测试靠 `zig test main.zig` 跑——build.zig.zon 里没有一行测试依赖
test 块是**语言关键字**（不是库函数），语法和 0.16/0.15 完全一致
assertion 来自 std.testing.*，那是标准库的一部分，不需要外部框架
==== 15.1 结束 ====
```

`test` 是**关键字**（和 `fn`、`struct`、`comptime` 同一级别），断言来自 `std.testing.*`（标准库）。
这个切分解释了一个常见困惑：`test` 块不需要 `import` 任何东西就能写，
但要用 `expectEqual` 就得先有 `const std = @import("std");`。

`builtin.is_test` 在 `zig test` 下是 `true`、在 `zig build-exe` 下是 `false`——
15.10 节的 `log.err` 守卫就靠它。

三个字的命令：

```bash
zig test main.zig                    # 编译 + 跑本文件（含引用到的模块）全部 test 块
zig test main.zig --test-filter 缓冲  # 只跑名字含「缓冲」的
```

**对比其它语言**：C++ 要引入 Catch2/gtest 依赖并写 `TEST_CASE` 宏；
Rust 要 `#[cfg(test)]` + `#[test]` 属性 + `cargo test`；
Go 要 `_test.go` 文件 + `testing.T` 接收者 + `t.Run`。
Zig 的 `test "名字" { ... }` 就是全部，编译产物是一个自带 runner 的可执行文件。

## 15.2 测试名就是标识符

`zig test` 逐条打印的名字是 **`<编译单元名>.test.<你写的名字>`**。
名字可以是中文，可以是任意 UTF-8 字节串——它不是标识符，是字符串。
但**同一个编译单元里重名是编译错误**。

```zig
// examples/15_testing/main.zig 第 69-77 行
    // ═══ 15.2 测试清单：名字就是标识符，重名是编译错误 ═══
    begin("15.2");
    std.debug.print("具名 test：编译单元名.test.名字 → main.test.repeat 重复拼接\n", .{});
    std.debug.print("匿名 test：没有名字 → main.test_0（本文件最后那个匿名 test 块）\n", .{});
    std.debug.print("嵌在 struct 里的 test：StructName.test.名字 → util.test.sluggify 行为\n", .{});
    std.debug.print("重复名字会报 duplicate test name '...'（实测，见文档 15.2）\n", .{});
    // 重复的名字（自己试）：把同一个名字写两遍 → 编译失败
    std.debug.print("struct 里的 test 也要被引用才进清单（本文件用 `_ = 那个struct;`）\n", .{});
    end("15.2");
```

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.2 开始 ====
具名 test：编译单元名.test.名字 → main.test.repeat 重复拼接
匿名 test：没有名字 → main.test_0（本文件最后那个匿名 test 块）
嵌在 struct 里的 test：StructName.test.名字 → util.test.sluggify 行为
重复名字会报 duplicate test name '...'（实测，见文档 15.2）
struct 里的 test 也要被引用才进清单（本文件用 `_ = 那个struct;`）
==== 15.2 结束 ====
```

三种命名形态，各有各的用处：

| 写法 | `zig test` 里显示的名字 | 用途 |
|---|---|---|
| `test "名字" { }` | `main.test.名字` | 绝大多数情况 |
| `test { }`（匿名） | `main.test_0`、`main.test_1`… | 只为"引用某个模块"的钩子（见 15.6） |
| struct 里的 `test "名字"` | `StructName.test.名字` | 测某个类型的静态方法 |

**重名是编译错误**（实测，把同一个名字写两遍）：

```text
ty4.zig:10:6: error: duplicate test name '重名test'
test "重名test" {
     ^~~~~~~~~~~~
ty4.zig:13:6: note: duplicate test here
test "重名test" {
     ^~~~~~~~~~~~
ty4.zig:1:1: note: struct declared here
const std = @import("std");
^~~~~~~~~
```

匿名 `test { }` 块的编号是**按编译单元**的，跨文件都会从 `_0` 开始。
本文件末尾那个匿名块拿到的是 `main.test_0`（因为文件里只有它一个匿名块）。

struct 里的 `test` 也要被引用才进清单——这是 15.6 节的主题。

**为什么要用中文命名**：测试名是**给人读的**。C 项目里常见的
`test_sluggify_returns_lowercase_with_dashes` 读起来是负担；
Zig 允许你写 `sluggify 行为`，失败报告里一眼就知道坏了什么。
本教程全书统一中文测试名。

## 15.3 `std.testing.*` 的真实存在性清单

这是本章最该抄走的一张表。**它由 `@hasDecl` 在运行时逐个探测**，
所以它不是文档摘抄，是这台机器上 0.17.0 的实测结果：

```zig
// examples/15_testing/main.zig 第 79-115 行
    // ═══ 15.3 断言族：存在什么、不存在什么 ═══
    begin("15.3");
    const names = [_]struct { n: []const u8, note: []const u8, has: bool }{
        .{ .n = "expect", .note = "布尔为真", .has = @hasDecl(std.testing, "expect") },
        .{ .n = "expectEqual", .note = "peer 类型解析后比值", .has = @hasDecl(std.testing, "expectEqual") },
        .{ .n = "expectEqualStrings", .note = "字符串，带 diff", .has = @hasDecl(std.testing, "expectEqualStrings") },
        .{ .n = "expectEqualSlices", .note = "切片逐元素（u8 走十六进制视图）", .has = @hasDecl(std.testing, "expectEqualSlices") },
        .{ .n = "expectEqualSentinel", .note = "切片 + 哨兵值", .has = @hasDecl(std.testing, "expectEqualSentinel") },
        .{ .n = "expectEqualDeep", .note = "深度比较（指针穿透）", .has = @hasDecl(std.testing, "expectEqualDeep") },
        .{ .n = "expectError", .note = "错误联合的具体错误", .has = @hasDecl(std.testing, "expectError") },
        .{ .n = "expectApproxEqAbs", .note = "浮点绝对容差", .has = @hasDecl(std.testing, "expectApproxEqAbs") },
        .{ .n = "expectApproxEqRel", .note = "浮点相对容差", .has = @hasDecl(std.testing, "expectApproxEqRel") },
        .{ .n = "expectFmt", .note = "格式化结果", .has = @hasDecl(std.testing, "expectFmt") },
        .{ .n = "expectStringStartsWith", .note = "前缀", .has = @hasDecl(std.testing, "expectStringStartsWith") },
        .{ .n = "expectStringEndsWith", .note = "后缀", .has = @hasDecl(std.testing, "expectStringEndsWith") },
        .{ .n = "checkAllAllocationFailures", .note = "穷举 OOM 路径", .has = @hasDecl(std.testing, "checkAllAllocationFailures") },
        .{ .n = "refAllDecls", .note = "引用所有声明", .has = @hasDecl(std.testing, "refAllDecls") },
        .{ .n = "failPrint", .note = "comptime 期转 @compileError", .has = @hasDecl(std.testing, "failPrint") },
        .{ .n = "expectNull", .note = "没有 → expect(opt == null)", .has = @hasDecl(std.testing, "expectNull") },
        .{ .n = "expectEqualError", .note = "没有 → 用 expectError", .has = @hasDecl(std.testing, "expectEqualError") },
        .{ .n = "expectDebugAssert", .note = "没有 → 编译器保证", .has = @hasDecl(std.testing, "expectDebugAssert") },
        .{ .n = "expectFalse", .note = "没有 → expect(!x)", .has = @hasDecl(std.testing, "expectFalse") },
        .{ .n = "expectAtLeast", .note = "没有 → 手写断言", .has = @hasDecl(std.testing, "expectAtLeast") },
        .{ .n = "expectVectorEqual", .note = "没有 → expectEqual 会走 vector 分支", .has = @hasDecl(std.testing, "expectVectorEqual") },
        .{ .n = "benchmark", .note = "0.17 已移除 → 手写 Io.Clock 计时", .has = @hasDecl(std.testing, "benchmark") },
    };
    var exist: usize = 0;
    var missing: usize = 0;
    for (names) |it| {
        std.debug.print("  {s:<30} {s}  {s}\n", .{ it.n, if (it.has) "存在  " else "不存在", it.note });
        if (it.has) exist += 1 else missing += 1;
    }
    std.debug.print("小计：{d} 个存在，{d} 个不存在\n", .{ exist, missing });
    // 没有 expectNull：判空自己写
    const opt: ?u8 = null;
    std.debug.print("判空写法：expect(opt == null)，本文件返回 {}\n", .{opt == null});
    end("15.3");
```

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.3 开始 ====
  expect                         存在    布尔为真
  expectEqual                    存在    peer 类型解析后比值
  expectEqualStrings             存在    字符串，带 diff
  expectEqualSlices              存在    切片逐元素（u8 走十六进制视图）
  expectEqualSentinel            存在    切片 + 哨兵值
  expectEqualDeep                存在    深度比较（指针穿透）
  expectError                    存在    错误联合的具体错误
  expectApproxEqAbs              存在    浮点绝对容差
  expectApproxEqRel              存在    浮点相对容差
  expectFmt                      存在    格式化结果
  expectStringStartsWith         存在    前缀
  expectStringEndsWith           存在    后缀
  checkAllAllocationFailures     存在    穷举 OOM 路径
  refAllDecls                    存在    引用所有声明
  failPrint                      存在    comptime 期转 @compileError
  expectNull                     不存在  没有 → expect(opt == null)
  expectEqualError               不存在  没有 → 用 expectError
  expectDebugAssert              不存在  没有 → 编译器保证
  expectFalse                    不存在  没有 → expect(!x)
  expectAtLeast                  不存在  没有 → 手写断言
  expectVectorEqual              不存在  没有 → expectEqual 会走 vector 分支
  benchmark                      不存在  0.17 已移除 → 手写 Io.Clock 计时
小计：15 个存在，7 个不存在
判空写法：expect(opt == null)，本文件返回 true
==== 15.3 结束 ====
```

**怎么自己复核**：这份清单不是猜的。`std/testing.zig` 只有 1437 行，
直接读它的 `pub fn` / `pub const` 列表；或者用一行探针：

```bash
printf 'const std=@import("std");\npub fn main() !void { _ = &std.testing.expectNull; }\n' > p.zig
zig build-exe p.zig -femit-bin=/dev/null
# error: root source file struct 'testing' has no member named 'expectNull'
```

几个值得单独说明的：

- **`expectNull` 不存在**（0.14 起就没有）。判空写 `expect(opt == null)`。
  想让失败信息更友好，用 `expectEqual(@as(?T, null), opt)`——0.17 会打印
  `expected null, found 3`（实测）。
- **`expectDebugAssert` 不存在**。Zig 的哲学是"编译期就保证"：
  `assert` 在 Debug/ReleaseSafe 下本来就是 `unreachable`，
  专门写一个测试去确认"断言会炸"没有意义。
- **`expectVectorEqual` 不存在**，因为 `expectEqual` 自己就有 `.vector` 分支
  （`std/testing.zig` 第 120-124 行）。
- **`failPrint` 是给自定义断言用的**：它在 `@inComptime()` 为真时
  把失败转成 `@compileError`（第 44-48 行）。15.14 节讲这个。
- **`random_seed`**（`pub var random_seed: u32`）也在这个结构体里，
  runner 在启动时从 `--seed=` 命令行参数给它赋值。写随机化测试时用它。

### 15.3.1 每个断言失败时到底打印什么

这是本章信息密度最高的一段。我把 12 个故意失败的断言放进一个文件跑 `zig test`，
下面是最有代表性的三段**实测输出**（stderr，含栈地址故只抄关键行）。

`expect(false)` —— **什么都不打印**，直接 FAIL：

```text
1/14 fails.test.fail-expect...FAIL (TestUnexpectedResult)
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/testing.zig:584:14: 0x101fc1f6f in expect (test)
    if (!ok) return error.TestUnexpectedResult;
             ^
/Volumes/mac004/code/programming/zig/build/probe15/fails.zig:4:5: 0x101fc1fc5 in test.fail-expect (test)
    try std.testing.expect(1 == 2);
    ^
2/14 fails.test.fail-expectEqual-int...expected 4, found 5
FAIL (TestExpectedEqual)
```

`expectEqualStrings` —— 双方内容 + 首个差异位置的 `^ ('\xNN')` 指示行：

```text
3/14 fails.test.fail-expectEqual-strings...
====== expected this output: =========
hello␃

======== instead found this: =========
hallo␃

======================================
First difference occurs on line 1:
expected:
hello
 ^ ('\x65')
found:
hallo
 ^ ('\x61')
FAIL (TestExpectedEqual)
```

逐条读（全部 12 个）：

| 断言 | 失败时第一行打印什么 |
|---|---|
| `expect(false)` | **不打印任何信息**，直接 `FAIL (TestUnexpectedResult)` |
| `expectEqual(4, 5)` | `expected 4, found 5` |
| `expectEqualStrings("hello", "hallo")` | `====== expected this output: =========` + 双方内容 + 首个差异位置的 `^ ('\xNN')` 指示行 |
| `expectEqualSlices(u8, ...)` | `slices differ. first difference occurs at index 4 (0x4)` + 十六进制视图 + ASCII 视图 |
| `expectError(error.Nope, ...)` | `expected error.Nope, found error.TooBig` |
| `expectApproxEqAbs(1.0, 1.5, 0.1)` | `actual 1.5, not within absolute tolerance 0.1 of expected 1` |
| `expectFmt("v=3", "v={d}", .{4})` | 委托给 `expectEqualStrings`，所以和字符串一样 |
| `expectEqualDeep(...)` | 先打 `expected 1, found 2`，再打 `Field n incorrect. expected 1, found 2` |
| `expectEqualSentinel(u8, 0, "ab", "ac")` | 委托给 `expectEqualSlices`，先打 slices differ |

**`expectEqualSlices(u8, ...)` 的输出最漂亮**——`u8` 走 `BytesDiffer` 视图，
一行同时给十六进制和可打印字符，差异位置染红：

```text
4/14 fails.test.fail-expectEqualSlices-u8...slices differ. first difference occurs at index 4 (0x4)

============ expected this output: =============  len: 8 (0x8)

61 62 63 64 65 66 67 68                           abcdefgh

============= instead found this: ==============  len: 8 (0x8)

61 62 63 64 58 66 67 68                           abcdXfgh

================================================
```

元素类型不是 `u8` 时走 `SliceDiffer`，逐元素打 `[index]: .{...}`：

```text
5/14 fails.test.fail-expectEqualSlices-struct...slices differ. first difference occurs at index 0 (0x0)

============ expected this output: =============  len: 1 (0x1)

[0]: .{ .x = 1, .y = 2 }

============= instead found this: ==============  len: 1 (0x1)

[0]: .{ .x = 1, .y = 3 }

================================================
```

**两个要注意的点**：

- **`expect(false)` 什么都不打印**。这是它和 `expectEqual` 最大的差别——
  调试时优先换成 `expectEqual` 或加一条注释说明失败原因。
- **`expectEqual` 比较结构体时逐字段递归**，所以错误信息精确到字段：

```text
10/14 fails.test.fail-expectEqual-struct-field...expected 1, found 2
FAIL (TestExpectedEqual)
```

## 15.4 `expectEqual` 的两个反直觉行为

### 15.4.1 peer 类型解析：类型不必完全一致

0.17 的 `expectEqual` **不是**"两个参数类型必须严格相同"，它做 **peer 类型解析**
（`std/testing.zig` 第 55-57 行）：

```zig
const T = @TypeOf(expected, actual);   // peer resolution
return expectEqualInner(T, expected, actual);
```

实测（三个都**编译通过且通过**）：

```zig
test "comptime_int 与 u8 peer" {
    const x: u8 = 5;
    try std.testing.expectEqual(5, x);       // ✅ 5 是 comptime_int，与 u8 peer 成 u8
}
test "大小不 peer" {
    const a: u8 = 5;
    const b: u16 = 5;
    try std.testing.expectEqual(a, b);       // ✅ u8 与 u16 peer 成 u16
}
```

```text
=== expectEqual(5, x:u8) ===
1/1 ty.test.comptime_int 与 u8 不peer...OK
All 1 tests passed.
=== expectEqual(a:u8, b:u16) ===
1/2 ty2.test.字面量会 peer 成 u8...OK
2/2 ty2.test.大小不peer...OK
All 2 tests passed.
```

⚠️ **这修正了本章 0.16 版本的旧说法**（"`expectEqual(5, x_u8)` 编译错，
`comptime_int` 不是 `u8`"）。那是 peer 解析出现之前的旧行为，0.17 不是了。
写测试时**不必再为了类型严格而处处 `@as`**——但对**字面量之外的窄类型转换**
仍要小心：`expectEqual(300, x_u8)` 会 peer 成 `u8` 然后**编译报错**（300 装不下），
而不是静默截断。这正是你想要的。

真正会编译失败的是**两个不同的类型**（即使字段全同）：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/testing.zig:56:15: error: incompatible types: 'ty3.A' and 'ty3.B'
    const T = @TypeOf(expected, actual);
              ^~~~~~~~~~~~~~~~~~~~~~~~~
ty3.zig:56:15: note: type 'ty3.A' here
ty3.zig:56:33: note: type 'ty3.B' here
```

```zig
// examples/15_testing/main.zig 第 313-320 行
test "assertion 家族：类型不 peer 时是编译错误" {
    const A = struct { x: u8 };
    // 下面这行编译不过（实测：incompatible types: 'A' and 'B'）：
    // const B = struct { x: u8 };
    // try std.testing.expectEqual(A{ .x = 1 }, B{ .x = 1 });
    // 字段全同也是两个不同类型 → expectEqual 拒绝（靠 @TypeOf 的 peer 解析）
    try std.testing.expectEqual(A{ .x = 1 }, A{ .x = 1 });
}
```

### 15.4.2 ⚠️ 指针和切片比的是**地址**

这条最反直觉，也最容易写出**假绿或假红**的测试。
`expectEqualInner` 的 `.pointer` 分支对 `.slice` 只比 `ptr` 和 `len`
（第 105-115 行），对 `.one`/`.many`/`.c` 只比指针值（第 98-104 行）：

```zig
.pointer => |pointer| {
    switch (pointer.size) {
        .one, .many, .c => {
            if (actual != expected) {
                failPrint("expected {*}, found {*}\n", .{ expected, actual });
                return error.TestExpectedEqual;
            }
        },
        .slice => {
            if (actual.ptr != expected.ptr) {
                failPrint("expected slice ptr {*}, found {*}\n", .{ expected.ptr, actual.ptr });
                return error.TestExpectedEqual;
            }
            // ...
```

实测：两个内容都是 7 的 `u32`，地址差 4 字节 → **FAIL**：

```text
1/5 ptr.test.ptr-expectEqual-one 运行时值...a=7 b=7 &a=u32@7ff7bd8590d0
expected u32@7ff7bd8590d0, found u32@7ff7bd8590d4
FAIL (TestExpectedEqual)
```

实测：两个内容都是 "abcd" 的字符串字面量，**地址相同 → 假 OK**：

```text
3/5 ptr.test.常量字面量折叠成同一地址？...p=[4:0]u8@102834fbe q=[4:0]u8@102834fbe
p.ptr==q.ptr ? true
OK
```

编译器把内容相同的字面量合并到同一份只读存储，所以 `expectEqual(@as([]const u8, "abcd"), @as([]const u8, "abcd"))`
**通过**——但它什么也没验证。而两个内容不同的字面量：

```text
2/5 ptr.test.slice-expectEqual 运行时切片...x=[4:0]u8@102834fbe
y=[4:0]u8@102834fd7
expected slice ptr u8@102834fbe, found u8@102834fd7
FAIL (TestExpectedEqual)
```

**结论**（示例里守着的正是这条）：

```zig
// examples/15_testing/main.zig 第 333-341 行
test "指针/切片用 expectEqual 比的是地址（所以别这么用）" {
    // 这两行是本教程的**反面教材**：内容相同、地址不同 → FAIL
    // try std.testing.expectEqual(&a, &b);
    // 正确写法是逐个字段比，或者用 expectEqualSlices(u8, ...)比内容
    var a = [_]u8{ 1, 2, 3 };
    var b = [_]u8{ 1, 2, 3 };
    try std.testing.expectEqualSlices(u8, &a, &b); // 比内容，不是比地址
    try std.testing.expectEqual(@as(usize, 3), a.len);
}
```

| 你想断言 | 用什么 |
|---|---|
| 两个字节串内容相同 | `expectEqualStrings` 或 `expectEqualSlices(u8, ...)` |
| 任意嵌套结构（含指针穿透） | `expectEqualDeep` |
| 两个指针**就是同一个** | `expectEqual(ptrA, ptrB)`（这正是它的语义） |
| 一个可选值是不是 null | `expectEqual(@as(?T, null), opt)` |

`expectEqualDeep` 是唯一会**穿透指针**比内容的：

```zig
// std/testing.zig 的 .pointer 分支里：.one 且子类型不是 fn/opaque → expected.* / actual.*
try std.testing.expectEqualDeep(&a, &b);   // ✅ 比内容
```

它的返回类型被收窄成 `error{TestExpectedEqual}!void`（只有一个可能的错误），
这意味着调用它时错误处理更简单。

### 15.4.3 main 里的说明

示例 main.zig 第 117-129 行把上面两条结论打印出来
（`// ═══ 15.4 expectEqual 的真实语义：peer 类型解析 + 指针比地址 ═══` 那一段）。

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.4 开始 ====
expectEqual 用 @TypeOf(expected, actual) 做 peer 类型解析（0.17）
  expectEqual(5, x:u8) 编译得过：comptime_int 与 u8 peer 成 u8
  expectEqual(a:u8, b:u16) 也编译得过：peer 成 u16
  但两个**不同**的结构体类型直接报 incompatible types（实测）
⚠️ expectEqual 对指针/切片比的是**地址**：
   两个内容相同、地址不同的 u32 → expected u32@... found u32@... FAIL
   两个内容相同的字符串字面量 → 编译器折叠成同一地址 → 假OK
   ⇒ 比内容必须用 expectEqualStrings / expectEqualSlices / expectEqualDeep
  想断言 null：expectEqual(@as(?u8, null), opt)（0.17 会打印 expected null, found ...）
==== 15.4 结束 ====
```

## 15.5 `zig test` 的全部选项（逐个实测）

`zig test --help` 的 `Test Options` 段落**只有 6 个选项**，逐字抄：

```text
Test Options:
  --test-filter [text]           Skip tests that do not match any filter
  --test-cmd [arg]               Specify test execution command one arg at a time
  --test-cmd-bin                 Appends test binary path to test cmd args
  --test-no-exec                 Compiles test binary without running it
  --test-runner [path]           Specify a custom test runner
  --test-execve                  Runs the test binary with execve if available instead of as a child process
```

**没有并行选项、没有覆盖率选项**（这两条实测确认，见 15.5.4 和 15.13）。

### 15.5.1 `--test-filter`：子串匹配

```bash
zig test main.zig --test-filter 第二个
```

实测输出（stderr）：

```text
1/1 t1.test.第二个测试：中文名直接做测试名...OK
All 1 tests passed.
```

"匹配任一 filter"意味着**可以给多次**，是 OR 关系。
被过滤掉的测试**根本不编进二进制**，所以过滤还能加速编译。

### 15.5.2 `--test-no-exec` + `-femit-bin`：拿到测试可执行文件

```bash
zig test t1.zig --test-no-exec -femit-bin=mytest   # 编译，产出 ./mytest，不跑
./mytest                                          # 自己跑
```

实测 `./mytest` 的输出和 `zig test` 完全一样：

```text
1/6 t1.test.第一个测试...OK
2/6 t1.test.第二个测试：中文名直接做测试名...OK
...
6/6 other.test.other 文件里的测试...OK
All 6 tests passed.
```

测试二进制**自己也是一个可执行文件**，接受三个参数（源码 `lib/compiler/test_runner.zig` 第 53-64 行）：
`--listen=-`（切到 build server 协议，`zig build test` 走这条）、
`--seed=<n>`（设置 `std.testing.random_seed`，写随机化测试用）、
`--cache-dir[=path]`（fuzz 模式的缓存目录）。

实测 `./mytest --seed=123` 正常跑完；`./mytest --bogus` 会 panic：

```text
thread 1202207 panic: unrecognized command line argument: --bogus
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/compiler/test_runner.zig:62:18: 0x106a85cdb in main (test)
            panic("unrecognized command line argument: {s}", .{arg});
```

### 15.5.3 `--test-runner`：换掉整个 runner

runner 就是一个 `main` 函数，能拿到 `builtin.test_functions`。
写一个只打印清单、不执行的 runner：

```zig
//! 自定义测试 runner：只列出测试清单，不逐个执行
const std = @import("std");
const builtin = @import("builtin");

pub fn main(init: std.process.Init.Minimal) void {
    _ = init;
    const io = std.Io.Threaded.global_single_threaded.io();
    var buf: [4096]u8 = undefined;
    var fw = std.Io.File.stdout().writer(io, &buf);
    const out = &fw.interface;
    out.print("自定义 runner：本次共编入 {d} 个测试\n", .{builtin.test_functions.len}) catch {};
    for (builtin.test_functions, 0..) |tf, i| {
        out.print("  [{d}] {s}\n", .{ i, tf.name }) catch {};
    }
    out.flush() catch {};
}
```

`zig test t1.zig --test-runner myrunner.zig` 实测输出：

```text
自定义 runner：本次共编入 6 个测试
  [0] t1.test.第一个测试
  [1] t1.test.第二个测试：中文名直接做测试名
  [2] t1.test.重复的数字
  [3] t1.test.第三个
  [4] t1.test.空 test 块（匿名）
  [5] other.test.other 文件里的测试
```

⚠️ **runner 的 `main` 签名是 `std.process.Init.Minimal`，不是 `std.process.Init`**。
两个坑（都实测撞到）：
写 `init.io` → `error: no field named 'io' in struct 'process.Init.Minimal'`；
写 `builtin.zig_backend.io()` → `error: no field or member function named 'io' in 'lang.CompilerBackend'`。
单线程要 io 就用 `std.Io.Threaded.global_single_threaded.io()`。

这个选项的实际用途：CI 里想统计测试数、或者把结果喂给自己的 reporter。

### 15.5.4 ⚠️ 没有并行选项（实测）

```bash
zig test main.zig --test-threads=4
```

```text
error: unrecognized parameter: --test-threads=4
```

`--help` 里搜 `thread`、`parallel`、`concurrent` 全部零命中。
`-j<N>` 有，但它是**编译并发度**（`Limit concurrent jobs (default is to use all CPU cores)`），
不是测试并行度。

**看源码确认**：`lib/compiler/test_runner.zig` 的 `mainTerminal` 是
一个朴素的 `for (test_fn_list, 0..) |test_fn, i|` 顺序循环（第 274 行），逐个跑、逐个 deinit。
**所以测试是严格串行的**——这也是 15.12 节"全局状态不共享"和
15.8 节"泄漏计数逐个累加"的前提。

想并行只能自己在测试里起线程（`io.concurrent`），但那会立刻撞上 15.11 节的死锁问题。

### 15.5.5 ⚠️ `--test-cmd` 不带 `--test-cmd-bin` 时测试**根本没跑**，退出码却是 0

这是本节最危险的一条。语义是：`--test-cmd` 逐个追加参数构成命令行，
`--test-cmd-bin` 决定**要不要把测试二进制路径追加进去**。

```bash
# ✅ 对：/usr/bin/env <测试二进制路径>
zig test t2.zig --test-cmd /usr/bin/env --test-cmd-bin
# 输出：1/1 t2.test.x...OK / All 1 tests passed.

# ❌ 错：只跑 /usr/bin/env，测试二进制压根没执行
zig test t2.zig --test-cmd /bin/echo
# 输出：（空）
# zig test 退出码：0    ← 绿灯！假绿！
```

实测确认：

```text
=== --test-cmd 但不 --test-cmd-bin：测试其实没跑，退出码仍是 0 ===
zig test 退出码=0
stdout:[] stderr:[]
```

**在任何用了 `--test-cmd` 的 CI 配置里，都要把"输出里有 N/N"当成硬断言**，
光看退出码会被这个坑骗过去。

包装器（模拟 valgrind / qemu）时注意 `--test-cmd` 是**一个 arg 一次**，
所以长命令要拆成多个 `--test-cmd`：

```bash
zig test main.zig \
  --test-cmd /bin/sh --test-cmd -c \
  --test-cmd 'exec "$1"' --test-cmd-bin
```

### 15.5.6 ⚠️ 只能有一个根源文件

```bash
zig test t2.zig other.zig
```

```text
error: found another zig file "other.zig" after root source file "t2.zig"
```

多文件测试靠 `--test-cmd`（每个文件编一个二进制）或 `zig build` 的
`addTest`（一次收多个模块），不能靠给 `zig test` 传多个 `.zig`。

### 15.5.7 ⚠️ `zig test` **不分析 `pub fn main`**

这是本教程三层验证的**全部理由**。实测：一个 `main` 里有类型错误的文件，
`zig test` **全绿**：

```text
=== zig test：main 里的类型错会被发现吗 ===
1/1 badmain.test.唯一测试...OK
All 1 tests passed.
```

而 `zig build-exe` 立刻炸：

```text
=== zig build-exe：===
badmain.zig:6:20: error: expected type 'u32', found '*const [15:0]u8'
    const x: u32 = "我是字符串";
                   ^~~~~~~~~~~~~~~~~
referenced by:
    callMain [inlined]: .../lib/std/start.zig:788:64
```

原因很直白：测试二进制里的入口是 **runner 的 main**，
你的 `main` 从头到尾没人引用，语义分析根本不会碰它。

**所以 `zig test` 绿 ≠ 代码能编译。** 本教程 `run-all.sh` 的第三层
（`zig build-exe` + 运行）就是补这个盲区，`zig build test` 也有同样的盲区
（`addTest` 只做语义分析，不产出可执行文件）。

### 15.5.8 示例里的选项清单

```zig
// examples/15_testing/main.zig 第 131-143 行
    // ═══ 15.5 --test-filter 与测试清单核对 ═══
    begin("15.5");
    std.debug.print("--test-filter [text]  跳过名字不匹配任一 filter 的测试（子串匹配）\n", .{});
    std.debug.print("--test-no-exec           只编译不跑（配合 -femit-bin 拿到测试可执行文件）\n", .{});
    std.debug.print("--test-runner [path]     换掉默认 runner（实测：换成只打印清单的 runner）\n", .{});
    std.debug.print("--test-cmd [arg]         指定执行命令，一个 arg 一次；配 --test-cmd-bin 追加二进制路径\n", .{});
    std.debug.print("--test-execve            有 execve 时用 execve 代替 fork 子进程\n", .{});
    std.debug.print("⚠️ 没有并行选项：--test-threads=4 报 unrecognized parameter（实测）\n", .{});
    std.debug.print("⚠️ --test-cmd 不带 --test-cmd-bin 时测试**根本没跑**，退出码却是 0（实测）\n", .{});
    std.debug.print("⚠️ 传第二个根文件报 found another zig file \"...\" after root source file（实测）\n", .{});
    std.debug.print("⚠️ zig test **不分析** pub fn main：main 里的类型错测试照绿（实测）\n", .{});
    std.debug.print("⚠️ 覆盖率：zig test --help 里 0 个 coverage 选项，也没有 gcov 报告工具（实测）\n", .{});
    end("15.5");
```

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.5 开始 ====
--test-filter [text]  跳过名字不匹配任一 filter 的测试（子串匹配）
--test-no-exec           只编译不跑（配合 -femit-bin 拿到测试可执行文件）
--test-runner [path]     换掉默认 runner（实测：换成只打印清单的 runner）
--test-cmd [arg]         指定执行命令，一个 arg 一次；配 --test-cmd-bin 追加二进制路径
--test-execve            有 execve 时用 execve 代替 fork 子进程
⚠️ 没有并行选项：--test-threads=4 报 unrecognized parameter（实测）
⚠️ --test-cmd 不带 --test-cmd-bin 时测试**根本没跑**，退出码却是 0（实测）
⚠️ 传第二个根文件报 found another zig file "..." after root source file（实测）
⚠️ zig test **不分析** pub fn main：main 里的类型错测试照绿（实测）
⚠️ 覆盖率：zig test --help 里 0 个 coverage 选项，也没有 gcov 报告工具（实测）
==== 15.5 结束 ====
```

## 15.6 测试放哪：同文件 vs 独立测试文件

Zig 的立场很明确：**测试和被测代码同文件**。理由在 2.6 节说过一次，这里补完细节。

`examples/15_testing/util.zig` 就是一个完整例子（17 行）：

```zig
//! 15 测试：模块也带自己的测试
const std = @import("std");

/// slug 化：小写 + 空格换连字符
pub fn sluggify(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    for (s) |ch| {
        try out.append(allocator, if (ch == ' ') '-' else std.ascii.toLower(ch));
    }
    return out.toOwnedSlice(allocator);
}

test "sluggify 行为" {
    const a = std.testing.allocator;
    const r = try sluggify(a, "Hello World!");
    defer a.free(r);
    try std.testing.expectEqualStrings("hello-world!", r);
}
```

### ⚠️ test 块只对**被引用到的**文件生效

这是"子模块测试静默缺席"的根源。实测：根文件 `t1.zig` 引用了 `other.zig`，
于是两边的测试都进清单（6 个）：

```text
1/6 t1.test.第一个测试...OK
2/6 t1.test.第二个测试：中文名直接做测试名...OK
3/6 t1.test.重复的数字...OK
4/6 t1.test.第三个...OK
5/6 t1.test.空 test 块（匿名）...OK
6/6 other.test.other 文件里的测试...OK
All 6 tests passed.
```

不引用就只有根文件的（实测：`t2.zig` 里只有 `test "x" {}`，没有别的）：

```text
All 1 tests passed.
```

**struct 里的 `test` 也一样**。实测 `ty5.zig`：`S` 里有一个 `test "struct 里的 test"`，
根文件有两个 `test` 都写了 `_ = S;`——结果是 3 个：

```text
1/3 ty5.test.顶层 test...OK
2/3 ty5.test.引用 S 里的 test...OK
3/3 ty5.S.test.struct 里的 test...OK
All 3 tests passed.
```

只要有一个地方引用了，它就进清单。

所以多文件工程（或者想跑子模块测试）的惯例是**在根文件放一个汇总入口**：

```zig
// examples/15_testing/main.zig 第 476-480 行
test {
    // 匿名 test 块：名字是 <编译单元>.test_0（15.2 节实测）
    // 这里的作用是把 util.zig 拽进测试清单 —— 引用即生效
    _ = util;
}
```

这就是那个匿名块的真正用途——它不是为了"跑点什么"，是为了**把子模块的测试拽进清单**。
多模块工程的写法是 `test { _ = 模块A; _ = 模块B; _ = 模块C; }`
（16 章 `zig build test` 收集全工程也是这个思路）。

```zig
// examples/15_testing/main.zig 第 145-153 行
    // ═══ 15.6 测试与源码同文件 vs 独立测试文件 ═══
    begin("15.6");
    std.debug.print("推荐：test 块写在被测代码同一个文件里，跟着代码走\n", .{});
    std.debug.print("本文件 test 块与 repeat/parseLike/greet 紧挨着 → 改函数时顺手改测试\n", .{});
    std.debug.print("多文件：test 块只对**被引用到的**文件生效（15.2 已实测：引用才进清单）\n", .{});
    std.debug.print("本文件用一个匿名 test 块把 util.zig 拽进清单（见文件末尾）\n", .{});
    std.debug.print("util.sluggify 被引用了吗？ {}\n", .{@hasDecl(util, "sluggify")});
    std.debug.print("参照：util.zig 里的测试名是 util.test.sluggify 行为\n", .{});
    end("15.6");
```

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.6 开始 ====
推荐：test 块写在被测代码同一个文件里，跟着代码走
本文件 test 块与 repeat/parseLike/greet 紧挨着 → 改函数时顺手改测试
多文件：test 块只对**被引用到的**文件生效（15.2 已实测：引用才进清单）
本文件用一个匿名 test 块把 util.zig 拽进清单（见文件末尾）
util.sluggify 被引用了吗？ true
参照：util.zig 里的测试名是 util.test.sluggify 行为
==== 15.6 结束 ====
```

### 什么时候该写测试

一条实用的判据：**当"改代码的人可能改错"的地方**。

- ✅ 值得写：有多个分支的逻辑、错误路径（`expectError`）、边界值（0/空/max）、
  任何手写的内存管理（`errdefer` 对不对）
- ⚠️ 值得写：任何**手写的格式串**（2.2 节的 `expectFmt`）——
  格式化行为变了测试先红
- ❌ 不必写：一行转发（`return foo(x)`）、语言本身保证的东西（溢出检查、越界检查）
- ❌ 不必写：**性能**（那是基准测试的活，15.13；而且 Debug 模式的数据没意义）
- ❌ 不必写：**"能不能编译"**（编译器管，15.5.7）

## 15.7 `std.testing.tmpDir`：自清理临时目录

需要落盘的测试（解析器、文件格式、编译器）用 `tmpDir`。它的形状是：

| 字段 | 类型 | 说明 |
|---|---|---|
| `.dir` | `std.Io.Dir` | 已打开的临时目录（**0.17 是 `Io.Dir`，不再是 `fs.Dir`**） |
| `.parent_dir` | `std.Io.Dir` | 父目录（`.zig-cache/tmp`） |
| `.sub_path` | `[16]u8` | base64 随机名（**不是路径字符串**） |
| `.cleanup()` | `void` | 递归删掉整棵子树 |

```zig
// examples/15_testing/main.zig 第 343-359 行
test "tmpDir：自清理临时目录的三个字段" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var f = try tmp.dir.createFile(std.testing.io, "t.txt", .{});
    var fbuf: [32]u8 = undefined;
    var fw = f.writer(std.testing.io, &fbuf);
    try fw.interface.print("hello", .{});
    try fw.interface.flush();
    f.close(std.testing.io);

    const got = try tmp.dir.readFileAlloc(std.testing.io, "t.txt", std.testing.allocator, .limited(64));
    defer std.testing.allocator.free(got);
    try std.testing.expectEqualStrings("hello", got);
}
```

注意 `readFileAlloc` 的第四个参数是 `.limited(64)`——0.17 的 `Io.Limit`
取代了旧的"最大字节数"参数（02 章 2.4 节提过 `Io.Limit`）。

完整路径是 `<cwd>/.zig-cache/tmp/<sub_path>`，`sub_path` 是 12 个随机字节的
base64url 编码（`std.testing.TmpDir.sub_path_len`，实测长度 16）。
每个测试拿到的名字都不一样，所以**并发跑也不会撞**——虽然 15.5.4 说测试是串行的。

### ⚠️ `tmpDir` 在 `main` 里调用会**编译失败**

`tmpDir` 的第一行是 `comptime assert(builtin.is_test);`
（`lib/std/testing.zig` 第 607 行）。在 `zig build-exe` 下它变成 `unreachable`，
报错长得很难认：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/debug.zig:442:14: error: reached unreachable code
    if (!ok) unreachable; // assertion failure
             ^~~~~~~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/testing.zig:607:20: note: called at comptime here
    comptime assert(builtin.is_test);
             ~~~~~~~~~~~~^~~~~~~~~~~~~~~~~
referenced by:
    main: m.zig:3:33
```

所以 main 里想演示临时目录，只能反射类型形状（示例 15.7 节就是这么做的）：

```zig
// examples/15_testing/main.zig 第 155-167 行
    // ═══ 15.7 std.testing.tmpDir：自清理临时目录 ═══
    begin("15.7");
    std.debug.print("std.testing.tmpDir(.{{}}) 返回 {s}，字段有：\n", .{@typeName(std.testing.TmpDir)});
    const T = @typeInfo(std.testing.TmpDir).@"struct";
    inline for (T.field_names, T.field_types) |fname, ftype| {
        std.debug.print("  .{s:<12} : {s}\n", .{ fname, @typeName(ftype) });
    }
    std.debug.print("⚠️ sub_path 是 [16]u8 数组（base64 随机名），不是路径字符串\n", .{});
    std.debug.print("   完整路径是 .zig-cache/tmp/<sub_path>，cleanup() 递归删整棵子树\n", .{});
    std.debug.print("⚠️ tmpDir 带 comptime assert(builtin.is_test) → 在 main 里调用**编译失败**\n", .{});
    std.debug.print("   （实测报 lib/std/testing.zig:607 reached unreachable code）\n", .{});
    std.debug.print("本节只反射类型形状；真正的调用在本文件末尾的 test 块里\n", .{});
    end("15.7");
```

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.7 开始 ====
std.testing.tmpDir(.{}) 返回 testing.TmpDir，字段有：
  .dir          : Io.Dir
  .parent_dir   : Io.Dir
  .sub_path     : [16]u8
⚠️ sub_path 是 [16]u8 数组（base64 随机名），不是路径字符串
   完整路径是 .zig-cache/tmp/<sub_path>，cleanup() 递归删整棵子树
⚠️ tmpDir 带 comptime assert(builtin.is_test) → 在 main 里调用**编译失败**
   （实测报 lib/std/testing.zig:607 reached unreachable code）
本节只反射类型形状；真正的调用在本文件末尾的 test 块里
==== 15.7 结束 ====
```

注意 `{{}}` 那个转义：格式串里的字面 `{` 要写 `{{`（02 章的坑位清单第 5 条附近）。

### ⚠️ 临时目录的清理时机

`cleanup()` 是 `defer` 的活，但**它删的是 `.zig-cache/tmp/` 下的子树**。
如果你在测试里 `cd` 进去或者把 `sub_path` 存到别处，清理会失败
（`cleanup` 内部是 `catch {}`，**静默吞掉错误**）。所以：**别把 `tmp` 传出测试函数**。

## 15.8 `std.testing.allocator`：泄漏检测的机制

这是本章最重要的机制，**判定时机和你的直觉不同**。

```zig
// examples/15_testing/main.zig 第 361-369 行
test "testing.allocator：deinit 返回泄漏**块数**" {
    // 真身是 heap.SafeAllocator，deinit() 返回泄漏块数 usize
    try std.testing.expect(!@hasDecl(std.testing, "print_error_trace")); // 0.17 已移除
    try std.testing.expect(@hasDecl(std.testing, "allocator_instance"));
    // 正常分配+释放 → 不泄漏
    const buf = try std.testing.allocator.alloc(u8, 16);
    defer std.testing.allocator.free(buf);
    try std.testing.expectEqual(@as(usize, 16), buf.len);
}
```

### 真身与配置

`std.testing.allocator` 的定义只有一行（`lib/std/testing.zig` 第 21 行）：

```zig
pub var allocator_instance: std.heap.SafeAllocator = undefined;
pub const allocator = if (builtin.is_test) allocator_instance.allocator() else @compileError("not testing");
```

- 真身是 **`std.heap.SafeAllocator`**（0.16 及之前叫 `DebugAllocator`）。
- **`deinit()` 返回泄漏块数 `usize`**，不是 void、不是字节数。所以
  `defer own.deinit();` 会报 `value of type 'usize' ignored`，得写 `defer _ = own.deinit();`。
- runner 每个测试前用这个配置初始化它
  （`lib/compiler/test_runner.zig` 第 275-278 行）：

```zig
testing.allocator_instance = .init(std.heap.page_allocator, .{
    .canary = 0xc3a701ba,
    .check_write_after_free = true,
});
```

`canary` 是写在分配块边界的哨兵值——**越界写会被抓到**。
`check_write_after_free` 让**写已释放内存**立刻炸。

### ⚠️ 判定在最后：泄漏的测试自己显示 `...OK`

这是最容易看漏的机制。看 runner 的 `mainTerminal`
（`lib/compiler/test_runner.zig` 第 274-343 行）的骨架：

```zig
for (test_fn_list, 0..) |test_fn, i| {
    testing.allocator_instance = .init(std.heap.page_allocator, .{ ... });
    testing.io_instance = .init(testing.allocator, .{ ... });
    defer {
        testing.io_instance.deinit();
        if (testing.allocator_instance.deinit() != 0) leaks += 1;   // ← 只累加计数
    }
    // ...
    if (test_fn.func()) |_| {
        ok_count += 1;
        if (!have_tty) std.debug.print("OK\n", .{});                // ← 照样打 OK
    } else |err| { ... }
}
root_node.end();
if (ok_count == test_fn_list.len) {
    std.debug.print("All {d} tests passed.\n", .{ok_count});       // ← 照样打 All N passed
} else { ... }
if (log_err_count != 0) std.debug.print("{d} errors were logged.\n", .{log_err_count});
if (leaks != 0) std.debug.print("{d} tests leaked memory.\n", .{leaks});
if (leaks != 0 or log_err_count != 0 or fail_count != 0) {
    std.process.exit(1);
}
```

**关键**：`deinit()` 的返回值只被用来 `leaks += 1`，
它**不影响 `test_fn.func()` 的结果**，所以那个测试打印的是 `...OK`。
判定推迟到全部测试跑完。

实测：4 个测试，第 2 个漏 16 字节、第 3 个漏 100000 字节
（后者走 large-alloc 路径），断言全部正确：

```text
1/4 leak.test.A 正常分配并释放...OK
2/4 leak.test.B 故意泄漏 16 字节...OK
[SafeAllocator] (err): leaked [addr: 1039f6010, len: 16 (0x10) align: 1] allocated at:
/Volumes/mac004/code/programming/zig/build/probe15/leak.zig:12:28: 0x1038e0b01 in test.B 故意泄漏 16 字节 (test)
    const buf = try a.alloc(u8, 16);
                           ^
...
3/4 leak.test.C 故意泄漏一大块（走 large alloc 路径）...OK
[SafeAllocator] (err): leaked [addr: 104d9d000, len: 100000 (0x186a0) align: 1] allocated at
...
4/4 leak.test.D 断言本身全过...OK
All 4 tests passed.
2 errors were logged.
2 tests leaked memory.
```

（这段输出里含内存地址，本教程不逐字节抄地址；断言性表述：
**分配点被精确定位到 `leak.zig:12:28` 和 `leak.zig:19:28`，
长度分别是 16 和 100000，地址每次运行不同。**）

四条结论：

1. **`All 4 tests passed.` 和 `2 tests leaked memory.` 同时出现**——不矛盾，
   前者说"断言全过"，后者说"内存不干净"。
2. **`2 errors were logged.` 是同一件事的第二个信号**：泄漏日志走的是
   `std.log.err` 通道（`SafeAllocator.zig` 第 712 行的 `scoped_log.err`），
   于是 runner 的 `log` 函数把它计进 `log_err_count`。
   **所以泄漏会同时触发两个失败计数。**
3. **退出码是 1**（`zig test` 的退出码随测试二进制）。
4. **`leaks` 数的是"测试个数"，不是"泄漏块数"**——
   上例泄漏了 2 块（也正好是 2 个测试）；一个测试漏 3 块只算 1。
   想知道块数得看每条 `[SafeAllocator] (err): leaked [...]` 日志。

### main 里的机制说明

```zig
// examples/15_testing/main.zig 第 169-178 行
    // ═══ 15.8 testing.allocator：泄漏即失败，但判负在最后 ═══
    begin("15.8");
    std.debug.print("std.testing.allocator 真身 = {s}\n", .{@typeName(@TypeOf(std.testing.allocator_instance))});
    std.debug.print("deinit() 返回泄漏**块数** usize，不是字节数\n", .{});
    std.debug.print("机制：每个测试跑完 runner 才 deinit 一次，计数累加到 leaks\n", .{});
    std.debug.print("⇒ 泄漏的测试自己显示 ...OK，最后统一打 `N tests leaked memory.` 并 exit(1)\n", .{});
    std.debug.print("⇒ 同一次还会打 `N errors were logged.`（泄漏日志走的是 log.err 通道）\n", .{});
    std.debug.print("所以 `All N tests passed.` 与 `N tests leaked memory.` 会**同时**出现\n", .{});
    std.debug.print("canary + check_write_after_free = true：写已释放内存立刻炸\n", .{});
    end("15.8");
```

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.8 开始 ====
std.testing.allocator 真身 = heap.SafeAllocator
deinit() 返回泄漏**块数** usize，不是字节数
机制：每个测试跑完 runner 才 deinit 一次，计数累加到 leaks
⇒ 泄漏的测试自己显示 ...OK，最后统一打 `N tests leaked memory.` 并 exit(1)
⇒ 同一次还会打 `N errors were logged.`（泄漏日志走的是 log.err 通道）
所以 `All N tests passed.` 与 `N tests leaked memory.` 会**同时**出现
canary + check_write_after_free = true：写已释放内存立刻炸
==== 15.8 结束 ====
```

### 用法：测试里永远用 `std.testing.allocator`

```zig
test "whatever" {
    const a = std.testing.allocator;   // ← 不要用 init.gpa / page_allocator
    const r = try repeat(a, "ab", 3);
    defer a.free(r);                   // ← defer 在失败路径也会跑，所以不泄漏
    try std.testing.expectEqualStrings("ababab", r);
}
```

`defer` 在断言失败抛错误时照常执行（Zig 的 `defer` 覆盖所有退出路径），
所以"断言失败"和"内存泄漏"不会互相掩盖。

⚠️ 反面做法：用 `page_allocator` 或 `init.gpa` 写测试——
内存泄漏就永远不会被发现，而且这些分配会活到进程结束。
本教程所有示例的测试都用 `std.testing.allocator`。

## 15.9 `FailingAllocator`：把 OOM 当成可注入的输入

16、20、24 章都会遇到同一个问题：**`error.OutOfMemory` 路径几乎没法手动测**。
你得在第 N 次分配时让分配器返回 null，然后检查前面的内存有没有泄漏。
`FailingAllocator` 就是干这个的。

### 两个名字都存在

| 名字 | 类型 | 说明 |
|---|---|---|
| `std.testing.FailingAllocator` | `type` | **类型**，用它的 `init` 造实例 |
| `std.testing.failing_allocator` | `mem.Allocator` | 全局那个，`fail_index = 0`（第一次分配就失败） |

⚠️ 实测：`std.testing.failing_allocator` 的真身类型是 `mem.Allocator`
（不是 `FailingAllocator`）——它已经是 `.allocator()` 的结果了。

`Config` 只有两个字段：`fail_index`（前 N 次分配成功，第 N+1 次返回 null，
默认 `maxInt(usize)` 即永不失败）和 `resize_fail_index`（同理，对 `resize`/`remap`）。

`FailingAllocator` 还统计 `alloc_index` / `allocated_bytes` / `freed_bytes` /
`allocations` / `deallocations` / `has_induced_failure`，
失败时能通过 `getStackTrace()` 拿到"被弄失败的那次分配"的调用栈。

### 手动指定失败点

被测对象（三次固定分配，`examples/15_testing/main.zig` 第 44-51 行）：

```zig
fn triple(gpa: std.mem.Allocator) !void {
    const a = try gpa.alloc(u8, 8);
    defer gpa.free(a);
    const b = try gpa.alloc(u8, 16);
    defer gpa.free(b);
    const c = try gpa.alloc(u8, 32);
    defer gpa.free(c);
}
```

对应的测试（`examples/15_testing/main.zig` 第 371-374 行）：

```zig
test "FailingAllocator：单独指定第 N 次分配失败" {
    var fa = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = 1 });
    try std.testing.expectError(error.OutOfMemory, triple(fa.allocator()));
}
```

⚠️ **靶子必须用固定次数的分配**。我第一次拿 `ArrayList` 当靶子，
`expectError` 报 `expected error.OutOfMemory, found void`——
因为 `ArrayList` 是**几何增长**的，`append` 100 次可能只触发 1 次分配，
`fail_index = 2` 根本没被碰到。改成三次固定 `alloc` 就稳定了。

### `checkAllAllocationFailures`：自动穷举

这个函数替你把 `fail_index = 0, 1, ..., N-1` 全跑一遍
（源码第 1145-1192 行）。策略是：

1. 先用无限内存跑一次，拿到**总分配次数** `needed_alloc_count`；
2. 对 `0..needed_alloc_count` 每个 `fail_index` 各跑一次；
3. 每次都要求：返回 `error.OutOfMemory`，且 `allocated_bytes == freed_bytes`。

```zig
// examples/15_testing/main.zig 第 376-380 行
test "checkAllAllocationFailures：穷举每一个 OOM 点" {
    // 第一次跑确定分配次数，再对 0..N-1 每个 fail_index 各跑一遍
    // triple 的三次分配都有 defer free ⇒ 全部路径都不泄漏 ⇒ 通过
    try std.testing.checkAllAllocationFailures(std.testing.allocator, triple, .{});
}
```

`triple` 的三次分配都有 `defer free`，所以 0/1/2 三个失败点全都不泄漏 ⇒ 通过。

**两个签名约束**（不满足直接 `@compileError`，实测报错）：

1. 被测函数**第一个参数必须是 `std.mem.Allocator`**；
2. 返回类型**必须是 `!void`**（payload 是 void 的错误联合）。

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/testing.zig:1198:17: error: Return type must be !void
                @compileError("Return type must be !void");
                ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fac.zig:35:47: note: generic function instantiated here
    try std.testing.checkAllAllocationFailures(std.testing.allocator, buildList, .{100});
```

所以你常要把"有返回值"的业务函数包一层：

```zig
fn buildList(gpa: std.mem.Allocator, n: usize) !void {   // ← 不是 ![]u32
    var out: std.ArrayList(u32) = .empty;
    defer out.deinit(gpa);
    for (0..n) |i| try out.append(gpa, @intCast(i));
}
```

第三个参数 `extra_args` 是被测函数**除第一个参数外**的参数元组。
`triple` 没有额外参数，所以是 `.{}`。

### 它能抓出漏掉的回滚

这是它的真正价值。给一个**故意漏掉 free** 的版本：

```zig
// examples/15_testing/main.zig 第 485-490 行
fn leakyTriple(gpa: std.mem.Allocator) !void {
    const a = try gpa.alloc(u8, 8);
    _ = a; // ← 没有 defer gpa.free(a)
    const b = try gpa.alloc(u8, 16);
    defer gpa.free(b);
}
```

```zig
// examples/15_testing/main.zig 第 382-392 行
test "checkAllAllocationFailures 能抓出漏掉的回滚" {
    // leakyTriple 故意漏掉第一笔的 free ⇒ fail_index=1 时报 error.MemoryLeakDetected。
    // backing 用 FixedBufferAllocator 而不是 testing.allocator：
    // 这样"故意漏的那 8 字节"不会污染全局测试分配器，也不会额外产生 err 日志。
    var buf: [256]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    try std.testing.expectError(
        error.MemoryLeakDetected,
        std.testing.checkAllAllocationFailures(fba.allocator(), leakyTriple, .{}),
    );
}
```

实测输出（stderr，`failPrint` 打出来的诊断，含地址故不逐字节抄）：

```text
13/24 main.test.checkAllAllocationFailures 能抓出漏掉的回滚...
fail_index: 1/2
allocated bytes: 8
freed bytes: 0
allocations: 1
deallocations: 0
allocation that was made to fail:
/Volumes/mac004/code/programming/zig/examples/15_testing/main.zig:488:28: 0x107e6f44f in leakyTriple (test)
    const b = try gpa.alloc(u8, 16);
                           ^
OK
```

注意 `13/24 ...OK`——**它通过了**，因为我们用 `expectError` 把
`error.MemoryLeakDetected` 当成**期望结果**。诊断信息照样打出来（这是 `failPrint` 的行为）。

⚠️ **backing 分配器别用 `std.testing.allocator`**：
"故意漏掉的那 8 字节"会挂到全局测试分配器上，导致整个 `zig test` 报
`1 tests leaked memory.` + `2 errors were logged.` 而失败（我第一次就踩了）。
用 `FixedBufferAllocator` 或独立的 `SafeAllocator` 就干净了。

### main 里的说明

```zig
// examples/15_testing/main.zig 第 180-187 行
    // ═══ 15.9 FailingAllocator：把 OOM 当成可注入的输入 ═══
    begin("15.9");
    std.debug.print("std.testing.FailingAllocator 存在；std.testing.failing_allocator 是全局那个\n", .{});
    std.debug.print("Config = {{ fail_index, resize_fail_index }}，第 N 次分配返回 null\n", .{});
    std.debug.print("std.testing.checkAllAllocationFailures(backing, fn, extra_args) 穷举所有 N\n", .{});
    std.debug.print("靶子 triple 有三次分配 + 三条 defer free ⇒ 0/1/2 三个失败点都不泄漏\n", .{});
    std.debug.print("⚠️ 被测函数第一个参数必须是 Allocator、返回类型必须 !void，否则 @compileError\n", .{});
    end("15.9");
```

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.9 开始 ====
std.testing.FailingAllocator 存在；std.testing.failing_allocator 是全局那个
Config = { fail_index, resize_fail_index }，第 N 次分配返回 null
std.testing.checkAllAllocationFailures(backing, fn, extra_args) 穷举所有 N
靶子 triple 有三次分配 + 三条 defer free ⇒ 0/1/2 三个失败点都不泄漏
⚠️ 被测函数第一个参数必须是 Allocator、返回类型必须 !void，否则 @compileError
==== 15.9 结束 ====
```

**什么时候该写这种测试**：任何**手写的 `errdefer` 回滚**。
`repeat` 里的 `errdefer out.deinit(allocator)`（示例第 20 行）
如果没有，`checkAllAllocationFailures(std.testing.allocator, repeatWrapper, ...)`
会立刻报 `error.MemoryLeakDetected`。这就是 15.9 的价值：
**它把"我以为我回滚了"变成"我确实回滚了"**。

## 15.10 `log_level` 与 `log.err` 的坑

先看默认：

```zig
// examples/15_testing/main.zig 第 189-197 行
    // ═══ 15.10 log_level 与 log.err 的坑 ═══
    begin("15.10");
    std.debug.print("std.testing.log_level 默认 = {t}（低于它的日志不打印）\n", .{std.testing.log_level});
    std.debug.print("测试 runner 里每跑一个测试前都会重置 log_level = .warn\n", .{});
    std.debug.print("⚠️ 但 log.err 会计数：runner 的 log 函数对 err 级无条件 log_err_count += 1\n", .{});
    std.debug.print("⚠️ 所以 test 块里 std.log.err(...) 即使断言全过也 exit(1)（实测）\n", .{});
    std.debug.print("   守卫写法：if (builtin.is_test) return;（本文件 logOrPanic 就是这么写的）\n", .{});
    std.debug.print("调高 log_level 只能让更多日志**打印**，不能阻止 err 计数\n", .{});
    end("15.10");
```

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.10 开始 ====
std.testing.log_level 默认 = warn（低于它的日志不打印）
测试 runner 里每跑一个测试前都会重置 log_level = .warn
⚠️ 但 log.err 会计数：runner 的 log 函数对 err 级无条件 log_err_count += 1
⚠️ 所以 test 块里 std.log.err(...) 即使断言全过也 exit(1)（实测）
   守卫写法：if (builtin.is_test) return;（本文件 logOrPanic 就是这么写的）
调高 log_level 只能让更多日志**打印**，不能阻止 err 计数
==== 15.10 结束 ====
```

### `log_level` 只是"打印阈值"

`pub var log_level = std.log.Level.warn;`（`std/testing.zig` 第 29 行，
源码里还挂着 `// TODO https://github.com/ziglang/zig/issues/5738`）。
runner 的 `log` 函数（test_runner.zig 第 346-362 行）只有两句要紧的：
第一句对 `err` 级**无条件** `log_err_count +|= 1`（不看 `log_level`），
第二句才判断要不要打印。两句逻辑**独立**。
所以调低 `log_level` 到 `.err` 甚至 `.debug` 只会让**更多**日志出现，
**阻止不了** err 计数。

实测把 `log_level` 调到 `.debug` 后，`std.log.debug` 打印了但不影响判定：

```text
1/2 log.test.守卫后：断言全过、无 err 日志...OK
2/2 log.test.对比：log_level 调到 err 也不改变计数...[default] (debug): 这条 debug 会打印但不计入 err 计数
OK
All 2 tests passed.
```

### ⚠️ `std.log.err` 在 test 块里会让 `zig test` 退出码非零

这是本教程的既有坑位（其它章也出现过）。实测：

```text
1/10 misc.test.跳过我...SKIP
2/10 misc.test.我跑...OK
3/10 misc.test.log_err 会污染...[default] (err): 我故意记一条 error 日志
OK
...
8 passed; 1 skipped; 1 failed.
1 errors were logged.
error: the following test command failed with exit code 1:
```

看第 3 行：断言过了、显示 `OK`，**但最后多了 `1 errors were logged.` 且退出码 1**。
机制和 15.8 的泄漏一模一样。

**守卫写法**（本文件守着的就是这个）：

```zig
// examples/15_testing/main.zig 第 263-267 行
/// 15.10 的守卫写法示范：测试环境不记err 日志
fn logOrPanic(comptime fmt: []const u8, args: anytype) void {
    if (builtin.is_test) return; // ← 少了这行，zig test 退出码就是 1
    std.log.err(fmt, args);
}
```

```zig
// examples/15_testing/main.zig 第 394-399 行
test "log.err 在 test 块里必须守卫" {
    logOrPanic("这行在测试环境被守卫掉了，不会计入 log_err_count", .{});
    try std.testing.expect(true);
    // 去掉 logOrPanic 里的 `if (builtin.is_test) return;` 再跑：
    // 断言仍全过，但最后会多一行 `1 errors were logged.` 且退出码 1
}
```

**什么时候需要守卫**：被测函数里有 `std.log.err` 的错误路径。
`expectError` 触发那种路径时，函数已经打完 err 日志了 → 计数 +1 → 测试整体失败。
这是很隐蔽的交互：**"测试通过了"和"整个测试运行失败了"同时发生**。

`builtin.is_test` 是编译期常量，所以这个分支在 `zig test` 下被完全消除，
**运行期零成本**。

## 15.11 测试替身：`testing.io` 是"显式依赖"哲学的回报

02 章 2.4 节说过 `std.process.Init` 的设计意图是"能被测试替换"。
现在看回报：

```zig
// examples/15_testing/main.zig 第 35-41 行
/// 15.11 测试替身：io 是显式参数，测试里传 std.testing.io
fn greet(io: std.Io, buf: []u8) ![]const u8 {
    _ = io; // 签名保留 io → 真实环境传 init.io，测试传 std.testing.io
    var w = std.Io.Writer.fixed(buf);
    try w.print("hello, {s}", .{"io"});
    return w.buffered();
}
```

**同一份代码，两个调用点**：

| 调用方 | 传的 io |
|---|---|
| `main` | `init.io`（真实事件循环） |
| `test` 块 | `std.testing.io`（测试环境） |

```zig
// examples/15_testing/main.zig 第 401-417 行
test "测试替身：testing.io + testing.Reader，输出不碰真实世界" {
    const io = std.testing.io;
    try std.testing.expectEqual(@as(?u8, null), null); // 判空

    // greet 的 io 参数在测试里传 testing.io，真实环境传 init.io —— 同一份代码
    var buf: [64]u8 = undefined;
    const got = try greet(io, &buf);
    try std.testing.expectEqualStrings("hello, io", got);

    // testing.Reader：按脚本喂字节，连文件都不用建
    var storage: [16]u8 = undefined;
    var r = std.testing.Reader.init(&storage, &.{ .{ .buffer = "abc" }, .{ .buffer = "de" } });
    var out: [8]u8 = undefined;
    var w = std.Io.Writer.fixed(&out);
    _ = try r.interface.streamRemaining(&w);
    try std.testing.expectEqualStrings("abcde", w.buffered());
}
```

`std.testing.io` 的真身是 `pub var io_instance: Io.Threaded`，
测试环境里它用 **`std.testing.allocator`** 初始化
（test_runner.zig 第 279-282 行）——所以**测试期间的 I/O 内部缓冲也被泄漏检测覆盖**。

`std.testing.Reader` 更有意思：它是一个 `Io.Reader`，
按你给的脚本**依次**吐出预设的 buffer。连文件都不用建：

```zig
var r = std.testing.Reader.init(&storage, &.{ .{ .buffer = "abc" }, .{ .buffer = "de" } });
// 第一次 stream() 返回 "abc"，第二次返回 "de"，第三次返回 error.EndOfStream
```

`std/testing.zig` 里还有 `ReaderIndirect`、`WriterIndirect`
（把一个 Reader 包成"总是写进自己缓冲"的 Reader，反之亦然），
用途是**测试缓冲边界**——比如强制 reader 反复 rebase。

### ⚠️ `std.testing.io` 在非测试编译下是 `@compileError`

定义只有一行（`std/testing.zig` 第 24 行）：

```zig
pub const io = if (builtin.is_test) io_instance.io() else @compileError("not testing");
```

所以 `main` 里写 `std.testing.io` 直接编译失败：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/testing.zig:24:59: error: not testing
pub const io = if (builtin.is_test) io_instance.io() else @compileError("not testing");
                                                          ^~~~~~~~~~~~~~~~~~~~~~~~~~~~
referenced by:
    main: main.zig:200:131
```

`std.testing.allocator` 同理（第 21 行）。这是好事：
**测试专用的东西不可能被误用到生产代码里**，编译器兜住了。

### ⚠️⚠️ 别在测试里用 `testing.io` 做同步原语——会死锁

这条是本教程上一版就记着的（引自 31 章），我重新实测确认了。
最小复现：持锁等一个永远不会成立的条件。

```zig
const std = @import("std");
test "Io.Condition.wait 在 testing.io 上" {
    const io = std.testing.io;
    var m: std.Io.Mutex = .init;
    m.lock(io) catch {};
    var cond: std.Io.Condition = .init;
    // 持锁等条件成立 → 必然挂死（因为没人能 signal）
    cond.wait(io, &m) catch {};
    try std.testing.expect(true);
}
```

实测结果：**15 秒仍未结束**，输出停在 `1/1 cond.test.Io.Condition.wait 在 testing.io 上...`，
没有任何进展。杀掉进程才结束。

原因：`std.testing.io` 背后是 `Io.Threaded` 的**单线程视图**
（test_runner 用 `Io.Threaded.global_single_threaded`），没有 worker 线程
去处理阻塞操作，`wait` 永远等不到唤醒。

**规则**：

| 想测什么 | 放哪 |
|---|---|
| 纯函数、数据结构、算法 | `test` 块 ✅ |
| 文件读写（`tmpDir`） | `test` 块 ✅（用 `testing.io`） |
| 原子操作、`std.atomic.Value` | `test` 块 ✅ |
| `io.concurrent` 起线程做点事再 await | `test` 块 ✅（实测能跑通） |
| **锁、条件变量、事件循环的编排** | **`main`**（用 `init.io`，那里有真线程池） |

⚠️ 顺带几个 `Io` API 的 0.17 形状（都实测撞过，收在坑位清单外但值得单说）：
`Threaded.init(gpa, .{})` **不返回错误联合**（写 `var t = ...`，不是 `try`）；
`Io.Mutex` / `Io.Condition` 是**值类型常量 `.init`** 不是 `.init()` 调用；
`io.concurrent(fn, args)` 的 `args` 是**类型化元组**（`fn(io: Io)` 传 `.{io}`），
返回的 `Future` 要用 `var` 接（`await` 接收者是 `*@This()`，接 `const` 报
`cast discards const qualifier`）。

### main 里的说明

```zig
// examples/15_testing/main.zig 第 199-211 行
    // ═══ 15.11 测试替身：显式依赖 io 的回报 ═══
    begin("15.11");
    std.debug.print("greet 的 io 是**显式参数** → 同一份代码，main 传 init.io、test 传 testing.io\n", .{});
    std.debug.print("main 里传的是 init.io，类型 = {s}\n", .{@typeName(@TypeOf(init.io))});
    var buf: [64]u8 = undefined;
    const got = try greet(init.io, &buf);
    std.debug.print("greet(传 init.io) = {s}（输出落在调用方的 buf，不碰真实 stdout）\n", .{got});
    std.debug.print("std.testing.io 在**非测试编译**下是 @compileError(\"not testing\")\n", .{});
    std.debug.print("   所以本节不能直接引用它——这是 0.17 的硬边界（实测：main 里写就编译失败）\n", .{});
    std.debug.print("更彻底的替身：std.testing.Reader —— 按预设脚本喂字节，无需真实文件\n", .{});
    std.debug.print("⚠️ 别在测试里用 testing.io 做同步原语：Io.Condition.wait 在它上面**死锁**（实测挂死）\n", .{});
    std.debug.print("   线程编排类测试放 main（用 init.io），测试只覆盖纯函数与原子操作\n", .{});
    end("15.11");
```

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.11 开始 ====
greet 的 io 是**显式参数** → 同一份代码，main 传 init.io、test 传 testing.io
main 里传的是 init.io，类型 = Io
greet(传 init.io) = hello, io（输出落在调用方的 buf，不碰真实 stdout）
std.testing.io 在**非测试编译**下是 @compileError("not testing")
   所以本节不能直接引用它——这是 0.17 的硬边界（实测：main 里写就编译失败）
更彻底的替身：std.testing.Reader —— 按预设脚本喂字节，无需真实文件
⚠️ 别在测试里用 testing.io 做同步原语：Io.Condition.wait 在它上面**死锁**（实测挂死）
   线程编排类测试放 main（用 init.io），测试只覆盖纯函数与原子操作
==== 15.11 结束 ====
```

## 15.12 测试隔离：全局状态在测试间**不共享**

先给结论，这条实测结果和很多人的直觉相反。

```zig
const std = @import("std");
var g: u32 = 0;
const box = struct { var inner: u32 = 0; };

test "AAA 第一个改 g 和 inner" {
    g += 1; box.inner += 1;
    std.debug.print("  [AAA] g={d} inner={d}\n", .{ g, box.inner });
    try std.testing.expectEqual(@as(u32, 1), g);
}
test "BBB 第二个读 g 和 inner" {
    std.debug.print("  [BBB] g={d} inner={d}\n", .{ g, box.inner });
    try std.testing.expectEqual(@as(u32, 1), g);   // ← 如果共享，这里应该是 2
}
test "CCC 第三个再读" {
    std.debug.print("  [CCC] g={d} inner={d}\n", .{ g, box.inner });
    try std.testing.expectEqual(@as(u32, 1), g);
}
```

实测输出：

```text
1/3 gs.test.AAA 第一个改g 和 inner...  [AAA] g=1 inner=1
OK
2/3 gs.test.BBB 第二个读g 和 inner...  [BBB] g=1 inner=1
OK
3/3 gs.test.CCC 第三个再读...  [CCC] g=1 inner=1
OK
All 3 tests passed.
```

**`g` 始终是 1，不累加。** 文件级 `var g` 和"struct 里的 var"都一样。

### 机制

Zig 是**按编译期实例**编译的：每个 `test` 块被当作一个独立的根去语义分析，
全局变量的存储是**该实例私有的**。所以每个测试看到的是自己的初始值。

这个机制有两个方向的好处：

1. **正面**：测试之间**天然没有全局状态污染**。
   不用写 `setUp` / `tearDown`（Java JUnit 的 `@BeforeEach`），
   不用 `beforeEach(fn)`（Go 的 `t.Cleanup`），不用 `fixture`（Rust 的常见模式）。
   因为根本没有共享状态可污染。
2. **反面**：**"上一个测试设置、下一个测试读取"这种写法必然失效**。
   你写了 `test A { global = 5; }` 和 `test B { expect(global == 5); }`，
   B 会看到初始值 0 而不是 5 —— 而且**测试还是绿的**（因为 B 里的断言如果写对了，
   反而会因为读到 0 而红；如果写的是 `expect(global == 0)`，就"假绿"了）。

所以规则是：**共享可变状态显式传参**（函数参数或 struct 字段），
不要靠全局变量在测试间传递信息。

```zig
// examples/15_testing/main.zig 第 419-423 行
test "测试隔离：全局 var 在测试间不共享（各测试独立实例）" {
    // 实测：三个 test 块里g始终是 1，不累加 —— 每个 test 是独立编译期实例
    globalCounter += 1;
    try std.testing.expectEqual(@as(u32, 1), globalCounter);
}
```

这个测试本身就是隔离性的**活证明**：它断言 `globalCounter == 1`，
哪天隔离机制变了（或者有人在别的测试里也 `+= 1`），它立刻红。

### 那"文件系统"和"网络"呢

| 资源 | 隔离做法 | 理由 |
|---|---|---|
| 内存 | `std.testing.allocator` + `defer free` | 每个测试一份全新分配器（15.8） |
| 临时文件 | `std.testing.tmpDir(.{})` + `defer cleanup()` | 随机 12 字节目录名（15.7） |
| 时间 | 传 `Io.Clock` 参数 / 注入时间戳 | 别在测试里读真实时钟做断言 |
| 随机数 | `std.testing.random_seed`（runner 从 `--seed=` 设） | 可复现 |
| 环境变量 | `std.testing.environ`（runner 填真实环境） | **不测**：依赖外部状态 |
| **网络** | **本教程坚持不测** | 需要外部服务 → CI 不确定 |

关于环境变量和网络：本教程的立场是**端到端测试不属于语言测试的范畴**。
`test` 块应该快（整个 `15_testing` 的 24 个测试在一秒内跑完）、确定、
不碰真实世界。需要网络的测试放到集成测试里，用构建系统单独跑（16 章）。

### main 里的说明

```zig
// examples/15_testing/main.zig 第 213-220 行
    // ═══ 15.12 测试隔离：全局状态在测试间是**重置**的 ═══
    begin("15.12");
    std.debug.print("实测：全局 var 在 3 个 test 块里始终读到 1，不累加\n", .{});
    std.debug.print("机制：每个测试函数是独立的编译期实例，各自带一份那份全局的存储\n", .{});
    std.debug.print("⇒ 写「上一个测试给全局赋值、下一个读」的测试 = 顺序脆弱，别这么干\n", .{});
    std.debug.print("⇒ 共享可变状态请显式传参（进函数参数或进 struct 字段）\n", .{});
    std.debug.print("文件系统：用 tmpDir 而不是固定路径；网络：本教程坚持不测\n", .{});
    end("15.12");
```

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.12 开始 ====
实测：全局 var 在 3 个 test 块里始终读到 1，不累加
机制：每个测试函数是独立的编译期实例，各自带一份那份全局的存储
⇒ 写「上一个测试给全局赋值、下一个读」的测试 = 顺序脆弱，别这么干
⇒ 共享可变状态请显式传参（进函数参数或进 struct 字段）
文件系统：用 tmpDir 而不是固定路径；网络：本教程坚持不测
==== 15.12 结束 ====
```

## 15.13 基准测试与覆盖率：0.17 的真实状态

### ⚠️ `std.testing.benchmark` 不存在

这条是本教程上一版（旧文档里写"`std.testing.tmpDir`、可用基准"）的更正。
0.17 里：

```text
root source file struct 'testing' has no member named 'benchmark'
```

而且**替代品也没有现成的**：`std.time.Timer` 也没了
（`root source file struct 'time' has no member named 'Timer'`）。

实测四连：

```text
  @hasDecl(std.testing, "benchmark") = false
  @hasDecl(std, "Benchmark") = false
  @hasDecl(std.time, "Timer") = false
  @hasDecl(std.Io, "Clock") = true
```

（`std.hash.benchmark` / `std.crypto.benchmark` 是**算法基准程序**，
是 `zig run` 跑的独立文件，不是 `zig test` 的设施。）

### 0.17 的计时接口：`std.Io.Clock`

计时器跟着 `Io` 一起做成了显式依赖（和 02 章的 `init.io` 一个思路）：
`std.Io.Clock` 是枚举，成员实测是 `real` / `awake` / `boot` /
`cpu_process` / `cpu_thread`。**没有 `.monotonic`**（我第一次写就撞了）：

```text
error: enum 'Io.Clock' has no member named 'monotonic'
```

计时用 `now` + `durationTo`：

被测对象（`examples/15_testing/main.zig` 第 53-58 行）：

```zig
fn work(n: usize) u64 {
    var acc: u64 = 0;
    for (0..n) |i| acc = acc *% 6364136223846793005 +% @as(u64, i);
    return acc;
}
```

main 里的用法（`examples/15_testing/main.zig` 第 222-234 行）：

```zig
    // ═══ 15.13 手写基准：0.17 没有 std.testing.benchmark ═══
    begin("15.13");
    std.debug.print("std.testing.benchmark 在 0.17 **不存在**（std.hash.benchmark 是另一个东西）\n", .{});
    std.debug.print("std.time.Timer 也没了 → 计时用 std.Io.Clock.now(.awake, io)\n", .{});
    const t0 = std.Io.Clock.now(.awake, init.io);
    var sink: u64 = 0;
    for (0..200) |_| sink +%= work(1000);
    const t1 = std.Io.Clock.now(.awake, init.io);
    const ns = t0.durationTo(t1).nanoseconds;
    std.debug.print("200 轮 work(1000)：{d} ns，约 {d} ns/轮（sink={d}）\n", .{ ns, @divTrunc(ns, 200), sink });
    std.debug.print("⚠️ 别在 Debug 模式报基准数字：安全检查全开，性能数据没意义\n", .{});
    std.debug.print("⚠️ 没有内建覆盖率：zig test --help 无 coverage 选项，也没有 gcov 报告器\n", .{});
    end("15.13");
```

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.13 开始 ====
std.testing.benchmark 在 0.17 **不存在**（std.hash.benchmark 是另一个东西）
std.time.Timer 也没了 → 计时用 std.Io.Clock.now(.awake, io)
200 轮 work(1000)：803362 ns，约 4016 ns/轮（sink=5810787426880774752）
⚠️ 别在 Debug 模式报基准数字：安全检查全开，性能数据没意义
⚠️ 没有内建覆盖率：zig test --help 无 coverage 选项，也没有 gcov 报告器
==== 15.13 结束 ====
```

⚠️ 上面那行 ns 数字**每次运行都不一样**（本机实测在 800000~900000 之间波动），
`sink` 恒定因为它是纯函数的结果。这也是为什么示例的 test 块只断言
`ns > 0` 而不锁死数字。`@divTrunc(ns, 200)` 而不是 `ns / 200`：
`Io.Duration.nanoseconds`
在 0.17 是 **i96**，有符号整数除法必须显式写 `@divTrunc`（否则
`error: division with 'i96' and 'comptime_int': signed integers must use @divTrunc ...`）。

测试里的写法（只断言"耗时为正"，不锁死数字）：

```zig
// examples/15_testing/main.zig 第 425-439 行
test "手写基准：std.testing.benchmark 不存在，计时用 Io.Clock" {
    try std.testing.expect(!@hasDecl(std.testing, "benchmark"));
    try std.testing.expect(!@hasDecl(std.time, "Timer"));
    try std.testing.expect(@hasDecl(std.Io, "Clock"));

    const io = std.testing.io;
    const t0 = std.Io.Clock.now(.awake, io);
    var sink: u64 = 0;
    for (0..50) |_| sink +%= work(500);
    const t1 = std.Io.Clock.now(.awake, io);
    const ns = t0.durationTo(t1).nanoseconds;
    // 只断言"耗时为正"这个事实，不锁死具体数字（Debug 模式下数字没意义）
    try std.testing.expect(ns > 0);
    try std.testing.expect(sink != 0);
}
```

**为什么手写基准不放在 `zig test` 里跑**：因为 `zig test` 默认是
**Debug 模式**（02 章 2.5 节），溢出检查、越界检查、边界检查全开，
性能大概是 ReleaseFast 的 1/10 到 1/30，报出来的数字没有意义。
真要测性能得：

```bash
zig test main.zig -OReleaseFast   # 但这样泄漏检测和断言仍在，安全网少了很多
```

更实际的做法是**写一个独立的 `zig run` 程序**测性能
（`std.hash/benchmark.zig` 就是这个模式的样板：文件头注释写着
`// zig run -O ReleaseFast --zig-lib-dir ../.. benchmark.zig`）。
本教程的 `main` 跑在 Debug 下，只用它演示**计时 API 的形状**，
不当性能数据看。

### ⚠️ 覆盖率：0.17 也没有内建方案

实测：

| 探针 | 结果 |
|---|---|
| `zig test --help \| grep -ci coverage` | **0** |
| `zig build-exe --help \| grep -i coverage` | 零命中 |
| `zig build-exe -fsanitize-coverage` | `error: unrecognized parameter: -fsanitize-coverage` |
| `lib/compiler/` 下找 gcov / cov / report 工具 | **没有** |

Zig 曾经有过 `zig test --coverage` 和 `zig-cov` 工具，**0.17 都没有了**。
标准库里唯一残留的是 `Step.Compile.sanitize_coverage_trace_pc_guard`，
而它的文档注释明说了用途（`lib/std/Build/Step/Compile.zig` 第 224-231 行）：

```zig
/// Enables coverage instrumentation that is only useful if you are using third
/// ...
/// This kind of coverage instrumentation is used by AFLplusplus v4.21c,
/// ... instruction for coverage, along with "trace cmp" which instruments
```

也就是说它**只服务于 AFL++ 模糊测试**，不是给人看覆盖率的。
而且它只能在 `zig build` 里配（`b.option(...)`），`zig test` 命令行给不了。

**所以"Zig 自带覆盖率工具"这句话在 0.17 是过期的。**
真要覆盖率，只能自己在 `zig build` 里加 `sanitize_coverage_trace_pc_guard = true`
再接外部工具（AFL++ / libFuzzer）。本教程不展开，因为那已经超出"语言测试"的范围。

## 15.14 编译期测试

Zig 有一种别的语言很少有的测试形态：**在编译期断言**。
它不是"运行期检查"，而是"这段代码编译得过"本身就是断言。

### 三种机制

| 机制 | 作用 | 失败表现 |
|---|---|---|
| `comptime { ... }` 块 | 顶层编译期代码，里面的断言失败 = **编译错误** | `@compileError` |
| `@compileError("...")` | 主动拒绝某种类型/值 | 编译错误（**这就是"测试编译失败"的手段**） |
| `@setEvalBranchQuota(N)` | 抬高 comptime 求值配额 | 不设则深循环撞上限 |

### 15.14.1 `comptime` 块里的断言失败 = 编译错误

看 `std/testing.zig` 第 43-49 行的 `failPrint`：

```zig
pub fn failPrint(comptime fmt: []const u8, args: anytype) void {
    if (@inComptime()) {
        @compileError(std.fmt.comptimePrint(fmt, args));
    } else if (backend_can_print) {
        std.debug.print(fmt, args);
    }
}
```

`@inComptime()` 为真时走 `@compileError`。实测一个 `comptime` 块里
断言故意写错：

```zig
comptime {
    std.testing.expectEqual(@as(u32, 4), 1 + 2); // 故意错
}
```

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/testing.zig:45:9: error: expected 4, found 3
        @compileError(std.fmt.comptimePrint(fmt, args));
        ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/testing.zig:92:26: note: called at comptime here
                failPrint("expected {any}, found {any}\n", .{ expected, actual });
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/testing.zig:57:28: note: called at comptime here
    return expectEqualInner(T, expected, actual);
/Volumes/mac004/code/programming/zig/build/probe15/ct4a.zig:14:28: note: called at comptime here
    std.testing.expectEqual(@as(u32, 4), 1 + 2); // 故意错
    ~~~~~~~~~~~~~~~~~~~~~~~^~~~~~~~~~~~~~~~~~~~~~~~
```

注意报的是 `error: expected 4, found 3`——和运行期 `expectEqual` 的
失败文本**一模一样**，只是变成了编译错误。

⚠️ **`comptime` 块里必须处理错误联合**（编译期不给你自动 `try`）：

```text
ct4a.zig:9:28: error: error union of type 'error{}!void' is ignored
```

所以写法是 `catch unreachable` 或 `catch @compileError(...)`：

```zig
// examples/15_testing/main.zig 第 441-447 行
test "编译期测试：comptime 块里断言失败会变成编译错误" {
    // 正常路径：这段在**编译期**求值，失败会变成 @compileError 而非测试失败
    comptime {
        std.testing.expectEqual(@as(u32, 385), sqSum(10)) catch unreachable; // 1²+...+10² = 385
    }
    try std.testing.expectEqual(@as(u32, 385), @as(u32, @intCast(sqSum(10))));
}
```

⚠️ **别把 `comptime` 断言写在普通 `test` 块里然后指望它变编译错误**。
在 `test` 块里，`try std.testing.expect(comptimeExpr)` 里的
`comptimeExpr` 是**编译期算出来的常量**，但 `try std.testing.expect` 本身
是**运行期调用**——失败会走 `error.TestUnexpectedResult`，是**测试失败**不是编译错误：

```text
5/6 ct.test.comptime 断言失败会变成编译错误...FAIL (TestUnexpectedResult)
```

要编译错误就必须放进 `comptime { }` 块（或 `@compileError`）。

### 15.14.2 表达"这段代码应该编译失败"

`@compileError` 是**唯一**手段。典型用法是**类型层面的语义约束**：

```zig
// examples/15_testing/main.zig 第 492-494 行
fn rejectsInt32(comptime T: type) void {
    if (T == i32) @compileError("i32 被明确禁止：这里用 f64");
}
```

```zig
// examples/15_testing/main.zig 第 449-454 行
test "编译期测试：用 @compileError 表达「这段应该编译失败」" {
    // 语义约束：业务上禁掉了 i32 → 在编译期就拒绝，而不是等运行期
    rejectsInt32(f64); // f64 允许
    // rejectsInt32(i32);← 取消注释：整个 zig test 编译失败，报 i32 被明确禁止
    try std.testing.expect(true);
}
```

取消注释后实测：

```text
ct3c.zig:8:24: error: sumIs 算错了
    if (acc != expect) @compileError("sumIs 算错了");
                       ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
referenced by:
    test.模式 A 正常: ct3c.zig:12:10
```

形态是：**调用点测试"不触发"，注释掉的那行是"如果触发会怎样"的活文档**。

这比"写一个测试然后期待它编译失败"要好，因为后者需要
`@compileError` + 子进程 + 解析编译器输出（`std.Build.Step.Compile` 的
`expectCompileError` 那套），而 `@compileError` 是**零成本**的：
它在编译期就完成了检查，运行时没有任何残留代码。

### 15.14.3 `@setEvalBranchQuota` 和 `comptime var`

深 comptime 循环会撞求值配额（默认 1000）。实测一个 10000 轮的
comptime 求和，不设配额：

```zig
fn slowComptime(n: comptime_int) comptime_int {
    var acc: comptime_int = 0;
    comptime var i: comptime_int = 0;
    inline while (i < n) : (i += 1) acc += i;
    return acc;
}
```

⚠️ 这里的 `var acc: comptime_int = 0;` 直接编译失败——0.17 收紧了一条规则：

```text
ct3a.zig:5:14: error: variable of type 'comptime_int' must be const or comptime
    var acc: comptime_int = 0;
             ^~~~~~~~~~~~
ct3a.zig:5:14: note: to modify this variable at runtime, it must be given an explicit fixed-size number type
```

**`comptime_int` 类型的变量必须写 `comptime var`**（因为它只在编译期存在，
"运行期修改一个 comptime_int"是没有意义的）。要运行期可改就写具体位宽
（`var acc: u64 = 0;`）。这和"顶层不能 `comptime var`"是同一族收紧。

正确写法（示例第 269-275 行）：

```zig
/// 15.14 编译期递归平方和
fn sqSum(comptime n: usize) comptime_int {
    comptime var acc: comptime_int = 0;
    comptime var i: usize = 1;
    inline while (i <= n) : (i += 1) acc += i * i;
    return acc;
}
```

10000 轮的版本配上 `@setEvalBranchQuota(100_000)` 就正常了。
`@setEvalBranchQuota` 只能出现在**函数体内部**（它作用于当前作用域），
写在文件顶层会报错。

### main 里的说明

```zig
// examples/15_testing/main.zig 第 236-244 行
    // ═══ 15.14 编译期测试 ═══
    begin("15.14");
    std.debug.print("comptime 块里的 std.testing.expectEqual 失败 → **编译错误**（failPrint 走 @compileError）\n", .{});
    std.debug.print("普通 test 块里的 comptime 表达式失败 → 运行期 TestExpectedEqual\n", .{});
    std.debug.print("@compileError 是表达「这段代码应该编译失败」的唯一手段\n", .{});
    std.debug.print("@setEvalBranchQuota(N) 抬高 comptime 求值配额（默认 1000）\n", .{});
    std.debug.print("深 comptime 循环不抬配额会撞上限（实测，见文档 15.14）\n", .{});
    std.debug.print("sqSum(10) = {d}（1²+...+10²，编译期算完，运行期零成本）\n", .{sqSum(10)});
    end("15.14");
```

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.14 开始 ====
comptime 块里的 std.testing.expectEqual 失败 → **编译错误**（failPrint 走 @compileError）
普通 test 块里的 comptime 表达式失败 → 运行期 TestExpectedEqual
@compileError 是表达「这段代码应该编译失败」的唯一手段
@setEvalBranchQuota(N) 抬高 comptime 求值配额（默认 1000）
深 comptime 循环不抬配额会撞上限（实测，见文档 15.14）
sqSum(10) = 385（1²+...+10²，编译期算完，运行期零成本）
==== 15.14 结束 ====
```

**什么时候该写编译期测试**：当"契约"本身就是**类型层面的**
（"这个函数不许收 i32"、"这两个类型必须同时出现"）。
运行期断言表达不了"这段代码根本不该被编译"这件事。

## 15.15 ⚠️ 0.17 没有 doctest：说清并给替代方案

《Learning Zig》ch7 提到：**"文档注释里的 ```zig 示例自动当测试跑"**（doctest）。
2.6 节的坑位清单里已经记了一条，这里给出完整实测。

### 实测：故意写错的文档块，`zig test` 说 `All 0 tests passed.`

```zig
const std = @import("std");

/// 这个文档示例是**故意错的**（1+2 不等于 4）。
/// ```zig
/// try std.testing.expectEqual(@as(u32, 4), 1 + 2);   // 必然失败
/// try std.testing.expect(false);                     // 必然失败
/// ```
pub fn add(a: u32, b: u32) u32 {
    return a + b;
}

// 没有 test 块的文件：
```

```text
$ zig test doc2.zig
退出码=0
All 0 tests passed.
```

**`All 0 tests passed.`，退出码 0。** 两行必然失败的断言既没被编译，
也没被执行。编译器源码里也搜不到 doctest 钩子。

顺带一个细节：文件里**有** `test` 块时，计数才是对的（doctest 不会额外增加计数）：

```text
$ zig test doc.zig
1/1 doc.test.add 正确...OK
All 1 tests passed.
```

——只有那 1 个真实 `test` 块，文档块不计数。

### 为什么没有，以及这个设计不是缺陷

doctest 要求编译器在解析文档注释时**执行** ```zig 代码块，这与三条原则冲突：
① Zig 不做 I/O 编译期求值，文档块里的代码可能依赖运行时才有的东西；
② doctest 假设"文档和测试不重复"，而 Zig 推荐的做法恰恰是
**文档示例和 test 块共享同一个被测函数**（本文件第 35-41 行的 `greet`
被 `main` 和 test 块各调一次，文档里的片段只是它的输出）；
③ doctest 让"编译失败"和"断言失败"混在一起，无法用退出码区分。

### 替代方案（本教程的路线）

**方案 1：文档示例同时抄一份成显式 `test` 块。**
本文件的 `sqSum` 就是这么守着的——15.14 节 main 里打印 `sqSum(10)`，
test 块里断言同一个值：

```zig
test "编译期测试：comptime 块里断言失败会变成编译错误" {
    comptime {
        std.testing.expectEqual(@as(u32, 385), sqSum(10)) catch unreachable;
    }
    try std.testing.expectEqual(@as(u32, 385), @as(u32, @intCast(sqSum(10))));
}
```

**方案 2（本教程全书采用）：让例子本身可运行。**
每章的 `examples/NN_xxx/main.zig` 都有 `pub fn main` 跑一遍所有概念，
文件末尾有 test 块断言同样的事实。三层验证（`fmt --check` → `test` →
`build-exe` + 运行）保证两者都正确。文档贴的是 `main.zig` 的**真实片段**，
不是手写的伪代码——所以文档里的代码**一定是能跑的**（因为它就是能跑的代码）。

**方案 3：`--test-no-exec -femit-bin` 拿测试二进制，CI 里分阶段跑。**

```bash
zig test main.zig --test-no-exec -femit-bin=tests.bin
# 阶段1：只编译（最快，反馈最快，语法/类型错在这里就抓到了）
# 阶段2：./tests.bin（跑断言，可能较慢）
```

这个拆分对大项目很有用：编译错误和断言失败是两类问题，分开报更清楚。

```zig
// examples/15_testing/main.zig 第 246-253 行
    // ═══ 15.15 doctest 不存在：替代方案 ═══
    begin("15.15");
    std.debug.print("0.17 没有 doctest：文档注释里的 ```zig 代码块**不会被编译也不会被跑**\n", .{});
    std.debug.print("实测：一个只有故意写错的```zig 块的文件 → `All 0 tests passed.` 退出码 0\n", .{});
    std.debug.print("替代方案 1：文档示例同时抄一份成显式 test 块（本文件 sqSum 就是这么守着的）\n", .{});
    std.debug.print("替代方案 2：让例子本身可运行（main 跑一遍 + test 断言），本教程全书路线\n", .{});
    std.debug.print("替代方案 3：--test-no-exec -femit-bin 拿到测试二进制再单独跑（CI 里分阶段用）\n", .{});
    end("15.15");
```

运行输出（`examples/15_testing/main.zig`）：

```text
==== 15.15 开始 ====
0.17 没有 doctest：文档注释里的 ```zig 代码块**不会被编译也不会被跑**
实测：一个只有故意写错的```zig 块的文件 → `All 0 tests passed.` 退出码 0
替代方案 1：文档示例同时抄一份成显式 test 块（本文件 sqSum 就是这么守着的）
替代方案 2：让例子本身可运行（main 跑一遍 + test 断言），本教程全书路线
替代方案 3：--test-no-exec -femit-bin 拿到测试二进制再单独跑（CI 里分阶段用）
==== 15.15 结束 ====
```

## 15.16 本章示例的完整测试清单

`zig test main.zig` 的**完整实测输出**（非 TTY，stderr）：

```text
1/24 main.test.测试名就是标识符，中文直接当测试名...OK
2/24 main.test.repeat 重复拼接...OK
3/24 main.test.repeat 零次得到空串...OK
4/24 main.test.assertion 家族：全部期望成功的用法...OK
5/24 main.test.assertion 家族：类型不 peer 时是编译错误...OK
6/24 main.test.assertion 家族：没有 expectNull，判空自己写...OK
7/24 main.test.expectError 断言错误联合的**具体**错误...OK
8/24 main.test.指针/切片用 expectEqual 比的是地址（所以别这么用）...OK
9/24 main.test.tmpDir：自清理临时目录的三个字段...OK
10/24 main.test.testing.allocator：deinit 返回泄漏**块数**...OK
11/24 main.test.FailingAllocator：单独指定第 N 次分配失败...OK
12/24 main.test.checkAllAllocationFailures：穷举每一个 OOM 点...OK
13/24 main.test.checkAllAllocationFailures 能抓出漏掉的回滚...
14/24 main.test.log.err 在 test 块里必须守卫...OK
15/24 main.test.测试替身：testing.io + testing.Reader，输出不碰真实世界...OK
16/24 main.test.测试隔离：全局 var 在测试间不共享（各测试独立实例）...OK
17/24 main.test.手写基准：std.testing.benchmark 不存在，计时用 Io.Clock...OK
18/24 main.test.编译期测试：comptime 块里断言失败会变成编译错误...OK
19/24 main.test.编译期测试：用 @compileError 表达「这段应该编译失败」...OK
20/24 main.test.refAllDecls：让编译器检查所有声明都被引用过...OK
21/24 main.test.SkipZigTest：主动跳过（不是失败）...OK
22/24 main.test.unreferenced 的测试故意缺席...OK
23/24 main.test_0...OK
24/24 util.test.sluggify 行为...OK
All 24 tests passed.
```

最后一行 `util.test.sluggify 行为` 来自 `util.zig`，**只是因为文件末尾那个匿名
`test { _ = util; }`**（15.6 节）。第 13 个测试的 `...` 后面跟着
`checkAllAllocationFailures` 的诊断（`fail_index: 1/2` / `allocated bytes: 8` / 分配点栈），
然后才是 `OK`——15.9 节讲的"用 `expectError` 把失败当期望结果"。

退出码 0，三层验证通过：

```text
[Toolchain] /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/zig (0.17.0)

[Example] 15_testing

[Done] 15_testing 验证通过。
```

### 几个辅助设施

**`refAllDecls`**（第 20 个测试）——
让编译器检查模块里所有 `pub` 声明都被引用过，防"声明了没人用"的静默腐烂：

```zig
test "refAllDecls：让编译器检查所有声明都被引用过" {
    // 惯用法：在测试里引用模块的所有 pub 声明，避免"声明了没人用"的静默腐烂
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(util);
}
```

⚠️ 它返回 `void`（不是 `!void`），**不能加 `try`**：
`error: expected error union type, found 'void'`。

**`SkipZigTest`**（第 21 个测试）——
主动跳过，runner 打印 `SKIP` 而不是 `FAIL`，且**不计入失败**：

```text
1/10 misc.test.跳过我...SKIP
2/10 misc.test.我跑...OK
```

全量跑时跳过、在 CI 的某个子集里跑（配合 `--test-filter` 反过来用）。
全绿时的汇总文本是 `N passed; M skipped; K failed.`（不是 `All N tests passed.`）——
因为 `All` 分支的条件是 `ok_count == test_fn_list.len`，跳过的测试不计入 `ok_count`。

## 15.17 坑位清单

1. **0.17 没有 doctest**：《Learning Zig》ch7 说"文档注释里的 ```zig 示例自动当测试跑"——
   实测一个只有**故意写错**的 ```zig 块的文件，`zig test` 报 `All 0 tests passed.`、
   **退出码 0**。编译器源码里也搜不到 doctest 钩子。文档示例想被验证，
   老实写成显式 `test` 块（本教程 15.15 节给了三个替代方案）。

2. **`expectEqual` 对指针/切片比的是地址，不是内容**。实测两个内容都是 7 的
   `u32` 报 `expected u32@7ff7bd8590d0, found u32@7ff7bd8590d4` → FAIL；
   而两个内容相同的字符串字面量因为被编译器折叠成同一地址，反而**假 OK**。
   比内容用 `expectEqualStrings` / `expectEqualSlices` / `expectEqualDeep`。

3. **`expectEqual` 在 0.17 做 peer 类型解析**（`@TypeOf(expected, actual)`），
   **不再要求类型严格一致**——`expectEqual(5, x: u8)` 和
   `expectEqual(a: u8, b: u16)` 都编译通过（旧文档说的"编译错"已过期）。
   但两个**不同**的结构体类型仍报 `incompatible types: 'ty3.A' and 'ty3.B'`。

4. **`std.testing.benchmark` 和 `std.time.Timer` 在 0.17 都不存在**
   （实测 `@hasDecl` 四连全是 `false`）。计时用
   `std.Io.Clock.now(.awake, io)` + `t0.durationTo(t1).nanoseconds`；
   `Io.Clock` **没有 `.monotonic`**（成员是 `real`/`awake`/`boot`/`cpu_process`/`cpu_thread`）。
   `Io.Duration.nanoseconds` 是 **i96**，`/ 200` 要写 `@divTrunc(ns, 200)`。

5. **0.17 没有内建覆盖率**：`zig test --help` 里 **0 个** coverage 选项，
   `-fsanitize-coverage` 报 `unrecognized parameter`，`lib/compiler/` 下没有
   gcov 报告工具。标准库只剩 `Step.Compile.sanitize_coverage_trace_pc_guard`，
   它的文档注释明说**只服务于 AFL++**。"Zig 自带覆盖率工具"这句话已过期。

6. **`zig test` 不分析 `pub fn main`**：实测 `main` 里有
   `const x: u32 = "我是字符串"` 时 `zig test` 报 `All 1 tests passed.`，
   而 `zig build-exe` 报 `expected type 'u32', found '*const [15:0]u8'`。
   **测试绿 ≠ 代码能编译**——这就是本教程三层验证第三层的理由。

7. **`--test-cmd` 不带 `--test-cmd-bin` 时测试根本没跑，退出码却是 0**（实测）。
   `zig test main.zig --test-cmd /bin/echo` 输出为空、退出码 0。
   用了 `--test-cmd` 的 CI 必须把"输出里有 N/N"当硬断言，不能只看退出码。

8. **没有测试并行选项**：`--test-threads=4` 报
   `error: unrecognized parameter: --test-threads=4`，`--help` 里搜
   thread/parallel/concurrent 零命中。源码 `test_runner.zig` 的 `mainTerminal`
   是朴素 `for` 顺序循环。`-j<N>` 是**编译**并发度，不是测试并行度。

9. **测试间的全局 `var` 不共享**：实测文件级 `var g` 和 struct 里的
   `var inner` 在三个 test 块里始终读到 1，不累加（每个 test 是独立的
   编译期实例，各带一份存储）。好处是天然无污染（不用 setUp/tearDown），
   坏处是"上一个测试设置、下一个读取"必然失效——**共享状态显式传参**。

10. **`std.testing.allocator` 的泄漏判定在最后**：实测泄漏的测试**自己显示
    `...OK`**，`All 4 tests passed.` 与 `2 tests leaked memory.`、
    `2 errors were logged.` **同时出现**，退出码 1。机制是 runner 每个测试
    跑完 `deinit()`，但返回值只用来 `leaks += 1`，不影响 `test_fn.func()`
    的结果。`leaks` 数的是**测试个数**不是块数。
    另外 **`deinit()` 返回 `usize`**（泄漏块数），`defer own.deinit();`
    会报 `value of type 'usize' ignored`，要写 `defer _ = own.deinit();`。

11. **`std.log.err` 在 test 块里会让 `zig test` 退出码非零**：
    实测断言全过、显示 `OK`，最后仍多一行 `1 errors were logged.` 且退出码 1。
    守卫写法 `if (builtin.is_test) return;`（`builtin.is_test` 是编译期常量，
    分支被完全消除，运行期零成本）。**调低 `log_level` 阻止不了计数**——
    runner 的 `log` 函数对 err 级是无条件 `log_err_count +|= 1`。

12. **`std.testing.io` / `std.testing.allocator` 在非测试编译下是
    `@compileError("not testing")`**：在 `main` 里写 `std.testing.io` 报
    `lib/std/testing.zig:24:59: error: not testing`。同理
    `std.testing.tmpDir` 在 main 里调用报
    `lib/std/debug.zig:442:14: error: reached unreachable code`
    （因为它有 `comptime assert(builtin.is_test)`）。所以 main 里只能反射类型形状。

13. **⚠️ 别在测试里用 `std.testing.io` 做同步原语**：
    `Io.Condition.wait` 在它上面**死锁**（实测 15 秒未结束，输出停在
    `1/1 cond.test...`，杀掉才停）。它背后是 `Io.Threaded` 的单线程视图，
    没有 worker 处理阻塞操作。线程/锁的编排测试放 `main`（用 `init.io`），
    测试只覆盖纯函数与原子操作。（`io.concurrent` + `await` 实测能跑通。）

14. **`checkAllAllocationFailures` 的两个签名约束**：被测函数第一个参数必须是
    `std.mem.Allocator`、返回类型必须是 `!void`，否则
    `@compileError("Return type must be !void")`。所以有返回值的业务函数要包一层。
    它的 **backing 分配器别用 `std.testing.allocator`**——"故意漏掉的字节"
    会挂到全局测试分配器上，让整个 `zig test` 判泄漏失败。
    用 `FixedBufferAllocator` 或独立的 `SafeAllocator`。

15. **`checkAllAllocationFailures` 的靶子必须用固定次数的分配**：
    拿 `ArrayList` 当靶子时 `fail_index = 2` 可能根本不被碰到（几何增长），
    `expectError` 报 `expected error.OutOfMemory, found void`。

16. **`comptime_int` 变量必须写 `comptime var`**：
    `var acc: comptime_int = 0;` 报
    `error: variable of type 'comptime_int' must be const or comptime`
    （和"顶层不能 `comptime var`"是同一族收紧）。另外函数体里不许声明 `fn`——
    `fn leaky(...)` 写在 test 块里报 `error: expected expression, found 'const'`。

17. **测试名重名是编译错误**：
    `error: duplicate test name '重名test'`。中文可以直接做测试名
    （UTF-8 字节串，不是标识符），实测 `zig test` 输出
    `2/6 t1.test.第二个测试：中文名直接做测试名...OK`。

18. **`--test-runner` 的 runner `main` 签名是 `std.process.Init.Minimal`**，
    不是 `std.process.Init`。写 `init.io` 报 `no field named 'io' in struct
    'process.Init.Minimal'`；`builtin.zig_backend.io()` 报
    `no field or member function named 'io' in 'lang.CompilerBackend'`。
    单线程要 io 用 `std.Io.Threaded.global_single_threaded.io()`。

19. **格式串里的字面 `{` 要写 `{{`**：15.7 节想打印
    `std.testing.tmpDir(.{})` 这个签名时，`.{}` 被当成占位符，报
    `error: too few arguments`。写成 `(.{{}})` 才对。

---

上一章：[14 泛型](14-generics.md) · 下一章：[16 构建与包管理](16-build.md)
