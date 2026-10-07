# 04 · 控制流

> 对应示例：`examples/04_control/main.zig`
>
> 控制流是 Zig 里**最不像 C 的一章**。C 的 `if` 是语句、`?:` 是表达式；
> Zig 只有一种东西——**能产出值的表达式**，而且编译器会检查它穷不穷尽。
> 读完你应该能解释清楚：为什么 `while (opt) |v|` 在 0.17 里
> **不能**用在错误联合上，为什么 `switch` 枚举写 `else` 反而编译不过，
> 以及 `continue :label` 怎么让状态机少一层嵌套。

---

## 4.1 `if` 是表达式：Zig 没有三元运算符

C 里 `cond ? a : b` 和 `if (c) a else b` 是两套写法，Zig 只留一套——因为 `if` 本身就是**能产出值的表达式**，可以直接出现在 `return` 右边、赋值右边、函数参数位置。

```zig
// examples/04_control/main.zig 第 61-77 行
begin("4.1");
const a: u32 = 5;
const b: u32 = 4;
// if 直接产出值，出现在赋值右边
const result: u32 = if (a != b) 47 else 3089;
std.debug.print("if 表达式 = {d}\n", .{result});
// else if 链同样是表达式：把 if-else 赋值写成一个 return
std.debug.print("85 → {s}，59 → {s}\n", .{ gradeLabel(85), gradeLabel(59) });
// 嵌套 if 也是表达式——想写"合并两个可选"时最自然的形态
const m1: ?u8 = 3;
const m2: ?u8 = null;
const merged: u8 = if (m1) |x| if (m2) |y| x + y else x else 0;
std.debug.print("合并 {any} 与 {any} = {d}（m2 是 null，退回 m1）\n", .{ m1, m2, merged });
// if 的条件必须是 bool：`if (1)` 编译不过（03 章 3.5 节：bool 不能当数字用）
std.debug.print("条件类型 = {s}\n", .{@typeName(@TypeOf(a != b))});
end("4.1");
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.1 开始 ====
if 表达式 = 47
85 → 及格，59 → 不及格
合并 3 与 null = 3（m2 是 null，退回 m1）
条件类型 = bool
==== 4.1 结束 ====
```

`gradeLabel` 是这条规则最实用的形态（`main.zig` 第 468-471 行）：

```zig
/// if-else 链当表达式用：整个函数体就是一个 return，没有临时变量
fn gradeLabel(score: u8) []const u8 {
    return if (score >= 90) "优秀" else if (score >= 60) "及格" else "不及格";
}
```

**为什么不给三元运算符**：Zig 的立场是"一条控制流只留一种语法"。三元运算符和 `if` 表达同一个概念却有两种拼法，混用时读代码的人要先判断作者是手快写错了还是有意用了 `?:`。只留 `if` 之后，**`if` 在所有位置都是表达式**，不存在"这个位置能不能用表达式"的记忆负担。代价是多写几个词——原书那句说得准："Why be concise when you can be clear?"

`merged` 那行是本节的隐藏重点：`if (m1) |x|` 里 `m1` 是 `?u8`，`|x|` 是**载荷捕获**（4.2 节展开）。它让"两个可能不存在的值怎么合并"变成一个纯表达式，没有临时变量、没有 `if (a != null && b != null)` 这种双条件检查。注意 `merged = 3`：`m2` 是 null 时退回 `m1` 的值（不是 0），因为内层 `if (m2) |y| x + y else x` 的 else 分支产出的是 `x`——这是"两个可选"退化成"一个可选"之后唯一还剩下的信息。

最后一行 `条件类型 = bool` 是个提醒：**Zig 的 `if` 条件必须是 `bool`**。C 允许 `if (1)`、`if (ptr)`，Zig 都不允许（03 章 3.5 节：`bool → u8` 不算宽化）。这条堵死了 `if (x = 5)` 那类惨案。

## 4.2 `if` 捕获可选与错误联合

`if` 的真正威力在于它能**拆开两种"可能失败"的类型**：`?T`（可能有值）和 `E!T`（可能出错）。写法是在条件后面加 `|捕获|`：

```zig
// examples/04_control/main.zig 第 79-107 行
begin("4.2");
const maybe: ?u8 = 7;
if (maybe) |v| {
    std.debug.print("可选有值：{d}\n", .{v});
} else {
    std.debug.print("可选是 null\n", .{});
}
// 错误联合：成功走 |v|，失败走 |err|，err 是 error set 值
if (sumHex("1a2b")) |v| {
    std.debug.print("sumHex(\"1a2b\") = 0x{x} = {d}\n", .{ v, v });
} else |err| {
    std.debug.print("sumHex 失败：{s}\n", .{@errorName(err)});
}
if (sumHex("zz")) |v| {
    std.debug.print("不该走到这：{d}\n", .{v});
} else |err| {
    std.debug.print("sumHex(\"zz\") 失败：{s}\n", .{@errorName(err)});
}
if (sumHex("1ffffffff")) |v| {
    std.debug.print("不该走到这：{d}\n", .{v});
} else |err| {
    std.debug.print("sumHex(\"1ffffffff\") 失败：{s}\n", .{@errorName(err)});
}
std.debug.print("错误集大小 = {d}，声明顺序 = {s}\n", .{ @typeInfo(ParseError).error_set.error_names.?.len, @typeName(ParseError) });
end("4.2");
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.2 开始 ====
可选有值：7
sumHex("1a2b") = 0x1a2b = 6699
sumHex("zz") 失败：BadDigit
sumHex("1ffffffff") 失败：Overflow
错误集大小 = 3，声明顺序 = error{BadDigit,Empty,Overflow}
==== 4.2 结束 ====
```

被调用的两个函数是本章的"分派对象"（`main.zig` 第 12-35 行）：

```zig
/// 4.2/4.3 节的分派对象：一个自己声明的错误集（不是 anyerror）
const ParseError = error{ Empty, BadDigit, Overflow };

/// 4.2 节：把"字符→数值"的失败做成错误联合，而不是返回哨兵值
fn parseHexDigit(ch: u8) ParseError!u8 {
    return switch (ch) {
        '0'...'9' => ch - '0',
        'a'...'f' => ch - 'a' + 10,
        'A'...'F' => ch - 'A' + 10,
        else => error.BadDigit,
    };
}

/// 4.2 节：调用方用 try 往上抛，决策留给调用者
fn sumHex(text: []const u8) ParseError!u32 {
    var acc: u32 = 0;
    for (text) |ch| {
        const digit = try parseHexDigit(ch);
        const wide: u32 = digit; // 算术不宽化（03 章 3.5节）：先点出u32
        if (acc > (std.math.maxInt(u32) - wide) / 16) return error.Overflow;
        acc = acc * 16 + wide;
    }
    return acc;
}
```

**设计要点**：函数**不决定**"出错了该怎么办"，它只负责"出错了就如实报上来"。`parseHexDigit` 遇到 `'z'` 返回 `error.BadDigit`，至于这是致命错误、要填默认值还是要跳过，由调用方在 `if` 的分支里说了算。C 的做法是返回 `-1` 之类的哨兵值，调用方必须记住"这个函数有一半概率返回垃圾"；Zig 把这件事变成**类型的一部分**（`ParseError!u8`），忘了处理就编译不过。

⚠️ **`if (mx and my) |x, y|` 在 0.17 不存在**（坑位 #3）。这是《Learning Zig》ch4 的一处错误（原书说它能"同时解包两个可选"），实测报 `expected '|', found ','`。`if` 的捕获语法只接受**一个** `|...|`。想在 0.17 里合并两个可选，正解是 4.1 节那种嵌套，或者先把其中一个 `orelse` 掉再捕获另一个（4.3 节）。

### ⚠️ `_ = err;` 不能用

想在 `else |err|` 分支里"先忽略错误"会撞墙：`error: error set is discarded`（坑位 #4）。**0.17 要求错误值被真正消费掉**，能消费它的操作只有三种：`@errorName(err)` 拿名字、`err == error.BadDigit` 做比较、`switch (err) { ... }` 逐个列。所以"忽略"只能写成 `if (err == error.Empty) { ... }` 这样明确表态，没有"静默丢弃"的写法。这个设计是对的：一个 `else |err|` 分支总该对错误做点什么。

## 4.3 `orelse` / `catch` / `catch |err|`：给"可能没有"兜底

`if` 适合"两种情况都要处理"，`orelse` / `catch` 适合"**只要一个值**"——不关心到底是 null 还是错误，直接给默认。

```zig
// examples/04_control/main.zig 第 109-132 行
begin("4.3");
const missing: ?u8 = null;
const present: ?u8 = 5;
std.debug.print("null orelse 0 = {d}；有值 orelse 0 = {d}（有值时 orelse 根本不参与）\n", .{ missing orelse 0, present orelse 0 });
// catch 处理错误联合；`catch |err|` 拿到错误值
std.debug.print("失败 catch 0 = {d} ", .{sumHex("zz") catch 0});
std.debug.print("成功 catch 0 = {d}\n", .{sumHex("1a") catch 0});
std.debug.print("catch |err| 区分错误 = {d}\n", .{
    sumHex("zz") catch |err| @as(u32, if (err == error.BadDigit) 16 else 32),
});
// ⚠️ 0.17：{d} 不能直接打印错误联合（error: invalid format string 'd' for type
//     'ParseError!i32'），要先把成功/失败拆开，再决定用哪个格式符
if (firstEvenOrFail(&[_]i32{ 1, 2, 4 })) |v| {
    std.debug.print("firstEvenOrFail([1,2,4]) = {d}\n", .{v});
} else |err| {
    std.debug.print("不该到这：{s}\n", .{@errorName(err)});
}
if (firstEvenOrFail(&[_]i32{ 1, 3, 5, 7 })) |v| {
    std.debug.print("不该到这：{d}\n", .{v});
} else |err| {
    std.debug.print("firstEvenOrFail([1,3,5,7]) 失败 = {s}\n", .{@errorName(err)});
}
end("4.3");
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.3 开始 ====
null orelse 0 = 0；有值 orelse 0 = 5（有值时 orelse 根本不参与）
失败 catch 0 = 0 成功 catch 0 = 26
catch |err| 区分错误 = 16
firstEvenOrFail([1,2,4]) = 2
firstEvenOrFail([1,3,5,7]) 失败 = Empty
==== 4.3 结束 ====
```

三个运算符，一句话记住：

| 写法 | 左边类型 | 行为 |
|---|---|---|
| `opt orelse d` | `?T` | 是 null 就给 `d` |
| `err catch d` | `E!T` | 是错误就给 `d` |
| `err catch \|e\| v` | `E!T` | 是错误就用 `v`（`v` 里能看到 `e`） |

`成功 catch 0 = 26` 是 `0x1a`——成功路径下 `catch` 右边**根本没被看一眼**。这个惰性有测试守着（`main.zig` 第 523 行起的 `orelse / catch / catch |err|` 测试）：

```zig
// examples/04_control/main.zig 第 531-539 行
// 有值时 orelse 右边不被求值（下面用带副作用的运行期函数证明这一点）
var evaluated = false;
// orelse 的右边只在左边为 null 时才求值。用带副作用的运行期函数调用做证明：
// 直接写进orelse 表达式里（先存进const 的话调用本身就已经执行了）。
try std.testing.expectEqual(@as(u8, 5), present orelse mkFallback(&evaluated));
try std.testing.expect(!evaluated);
// 反过来左边是 null 时一定走右边
try std.testing.expectEqual(@as(u8, 0), missing orelse mkFallback(&evaluated));
try std.testing.expect(evaluated);
```

⚠️ **不要用 `const fallback = 危险函数(); x orelse fallback` 这个写法来"证明惰性"**——`const fallback = ...` 那一步就已经把函数调掉了，无论后面走不走 else。必须把调用**直接写进 `orelse` 的右边**，副作用才能真正反映"有没有被求值"。这是写测试时容易自己骗自己的地方。

### `orelse return`：把"没有就往上抛"写成一个词

上面 `firstEvenOrFail` 的实现（`main.zig` 第 453-460 行）：

```zig
// examples/04_control/main.zig 第 453-460 行
/// 4.3 节：把"没有就往上抛"写成一个词（Zig 不允许在函数体里嵌套 fn 声明）
fn firstEvenOrFail(xs: []const i32) ParseError!i32 {
    for (xs, 0..) |x, i| {
        if (@mod(x, 2) == 0) return x;
        if (i == 3) return error.Empty;
    }
    return error.Empty;
}
```

⚠️ 两个实测踩到的点：

1. **Zig 不允许在函数体里嵌套 `fn` 声明**。最初把 `firstEvenOrFail` 写在 `main` 里面，报 `error: expected ',' after initializer`。函数必须提到文件顶层。
2. **`{d}` 不能直接打印错误联合**。`std.debug.print("...{d}", .{firstEvenOrFail(...)})` 报 `error: invalid format string 'd' for type 'error{BadDigit,Empty,Overflow}!i32'`。必须先用 `if`/`catch` 把成功值取出来，再用 `else |err|` + `@errorName` 拿名字。

## 4.4 `while` 与 continue 表达式

Zig 的 `while (条件) : (每轮结束的表达式)` 把 C 的步进表达式搬进了循环头。这是**唯一一个** `continue` 表达式**也会执行**的循环构造——所以"写了 `continue` 忘记步进导致死循环"这个经典事故在语法层面被消灭了。

```zig
// examples/04_control/main.zig 第 134-163 行
begin("4.4");
var i: usize = 0;
var sum: usize = 0;
while (i < 5) : (i += 1) {
    if (i == 2) continue; // continue 也会先跑 : (i += 1)，所以不会死循环
    sum += i;
}
std.debug.print("0..4 去掉 2 = {d}；循环结束时 i = {d}\n", .{ sum, i });
// while 可以直接迭代"可空序列的元素"，遇到 null 自然停
const opt_iter = [_]?u8{ 7, null, 9 };
var oi: usize = 0;
while (opt_iter[oi]) |v| : (oi += 1) {
    std.debug.print("  可选元素 {d}\n", .{v});
}
std.debug.print("停在第 {d} 个（null 处停住，后面的 9 没被看到）\n", .{oi});
var n: u8 = 0;
while (n < 8) : (n += 1) {
    if (parseHexDigit('0' + n)) |d| {
        std.debug.print("  数字 {d}\n", .{d});
    } else |err| {
        std.debug.print("  在 '{c}' 处停止：{s}\n", .{ @as(u8, '0' + n), @errorName(err) });
        break;
    }
}
end("4.4");
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.4 开始 ====
0..4 去掉 2 = 8；循环结束时 i = 5
  可选元素 7
停在第 1 个（null 处停住，后面的 9 没被看到）
  数字 0
  数字 1
  数字 2
  数字 3
  数字 4
  数字 5
  数字 6
  数字 7
==== 4.4 结束 ====
```

**输出第 1 行是本节的核心证据**：`sum = 8`（0+1+3+4），但循环结束时 `i = 5` 而不是 1。因为 `continue` 之前先跑了 `: (i += 1)`。如果步进不保证执行，`i == 2` 时就会永远停在那里。这条性质有测试守着（`main.zig` 第 554-555 行断言 `sum == 8 && i == 5`）。

### ⚠️ `while (expr) |v|` 在 0.17 **只吃可选**，不吃错误联合

这是本章最值得记住的版本变化（坑位 #1）。写 `while (sumHex("f")) |v| { ... }` 会报 `expected optional type, found 'error{BadDigit,Empty,Overflow}!u32'`。

**为什么**：`while` 的 `|v|` 捕获语义是"**值为 null 就结束循环**"——只有 `?T` 能回答"是不是没有值"这个问题。错误联合里的错误是一个**值**（error set 的成员），不是"没有值"，没法用来决定循环是否继续。编译器直接拒绝这种猜测，于是 0.17 的答案是：**错误联合一律用 `if`/`catch` 在循环体里处理**（输出里那段"数字 0..7"就是正确写法）。

顺带说，`while (opt_iter[oi]) |v|` 这种写法在**数组**上是安全的（每次都重新求值下标），但如果换成切片（06 章）要小心：`while (slice[i]) |v|` 在遍历中改变 `slice` 的长度会导致下标越界。

## 4.5 循环也是表达式：`else` 与 `break value`

这是 0.17 里最优雅、也最容易被误读的构造。**循环可以是一个表达式**，用 `break 值` 产出值、用 `else 产出值` 兜底。

```zig
// examples/04_control/main.zig 第 165-197 行
begin("4.5");
// else 分支的语义是"**没有因为 break 提前退出**"——包括一次都没迭代的情况
var acc: u32 = 0;
const stopped_early = for ("7f") |ch| {
    const digit = try parseHexDigit(ch);
    acc = acc * 16 + digit;
    if (acc > 0x10) break true; // break 带值 → 整个 for 表达式的值
} else false;
std.debug.print("累加到 0x{x}，超过 0x10 就停 = {}（走了 break 分支）\n", .{ acc, stopped_early });
acc = 0;
const ran_to_end = for ("12") |ch| {
    const digit = try parseHexDigit(ch);
    acc = acc * 16 + digit;
    if (acc > 0xFFFF) break true;
} else false;
std.debug.print("累加到 0x{x}，跑完没 break = {}（走了 else 分支）\n", .{ acc, ran_to_end });
// 一次都没迭代也算"没 break"→ else 照样执行
var touched: usize = 0;
_ = for ([_]u8{}) |_| {
    touched += 1;
    unreachable; // 永不执行
} else true;
std.debug.print("空序列：循环体执行 {d} 次，else 仍然执行\n", .{touched});
// while 也有 else
var k: u8 = 0;
const hit_two = while (k < 5) : (k += 1) {
    if (k == 2) break true;
} else false;
std.debug.print("while-else：k 停在 {d}，hit={}\n", .{ k, hit_two });
end("4.5");
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.5 开始 ====
累加到 0x7f，超过 0x10 就停 = true（走了 break 分支）
累加到 0x12，跑完没 break = false（走了 else 分支）
空序列：循环体执行 0 次，else 仍然执行
while-else：k 停在 2，hit=true
==== 4.5 结束 ====
```

### `else` 的准确定义（纠正一个流传的说法）

**`else` 的条件是"没有因为 `break` 提前退出"，不是"循环体一次都没执行"。** 空序列（0 次迭代）也算"没有 break"，所以 `else` 会执行——输出第 3 行就是这个意思（`touched = 0` 但 `else true` 照样跑）。

《Learning Zig》的自测题 Q9 答案是 b（"when the loop body doesn't execute at all"），这只是在"空序列"这个特例上碰巧对。准确的表述是 a："循环完整跑完或一次都没跑"（即没有 `break`）。

**这个设计的价值**：把"遍历 + 找到就停 + 区分找到没找到"三件事压成一个表达式。输出第 1、2 行对照着看——同样是"循环里有个阈值判断"，`break true` 得 `true`，`else false` 得 `false`。用 C 写需要一个循环外的 `bool found` 再在循环后判断它。

⚠️ **一个易踩的类型坑**：如果 `break :label 某值` 出现在循环里，而循环**没有写 `else`**，那么"正常走完"那条出口的值是 `void`，编译报：

```text
error: incompatible types: 'usize' and 'void'
    find: for (0..5) |a| {
    ~~~~~~^~~
note: type 'usize' here
            if (a * a + b * b == 9) break :find @as(usize, a * 10 + b);
```

解法就是补 `else 0`（见 4.8 节的 `find`）或者包一层 labeled block（4.9 节）。**直觉上会以为"找到就 break，所以走不到走完那条路"，但编译器不做这个流分析**——它要求所有出口类型一致。

## 4.6 `for` 的四种迭代形态

Zig 的 `for` 只有一个关键字，没有 C 风格的 `for (i = 0; i < n; i++)`。四种形态：

```zig
// examples/04_control/main.zig 第 199-227 行
begin("4.6");
const names = [_][]const u8{ "C", "Zig", "Rust" };
const years = [_]u16{ 1972, 2016, 2015 };
// ① 多序列 zip + 0.. 当下标
for (names, years, 0..) |name, year, idx| {
    std.debug.print("  [{d}] {s} 诞生于 {d}\n", .{ idx, name, year });
}
// ② 范围：0..5 左闭右开
var range_sum: usize = 0;
for (0..5) |idx_k| range_sum += idx_k;
std.debug.print("0..5 的和 = {d}\n", .{range_sum});
// ③ 切片：遍历一部分（冒号后两个点才是切片语法）
var head: i32 = 0;
for (names[0..2]) |name| {
    std.debug.print("  前两个：{s}（{d} 字节）\n", .{ name, name.len });
    head += 1;
}
std.debug.print("names[0..2] 长度 = {d}\n", .{head});
// ④ 按下标：拿不到下标就多写一个序列
var idx_sum: usize = 0;
for (0..names.len) |idx| idx_sum += idx;
std.debug.print("下标之和 = {d}\n", .{idx_sum});
// 没有 C 风格 for (i = 0; i < n; i++)：需要复杂步进就写 while + continue 表达式
var rev: usize = 0;
var down: usize = names.len;
while (down > 0) : (down -= 1) rev = rev * 10 + down;
std.debug.print("倒着数 = {d}\n", .{rev});
end("4.6");
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.6 开始 ====
  [0] C 诞生于 1972
  [1] Zig 诞生于 2016
  [2] Rust 诞生于 2015
0..5 的和 = 10
  前两个：C（1 字节）
  前两个：Zig（3 字节）
names[0..2] 长度 = 2
下标之和 = 3
倒着数 = 321
==== 4.6 结束 ====
```

| 形态 | 语法 | 用在哪 |
|---|---|---|
| 序列 / 数组 / 切片 | `for (a) \|v\|` | 遍历一切 |
| 范围（左闭右开） | `for (0..n) \|i\|` | 只要下标 / 定次数 |
| 多序列 zip | `for (a, b, 0..) \|x, y, i\|` | 并行遍历 + 下标 |
| 指针 | `for (&a) \|*p\|` | 要**改**元素（4.7 节） |

**为什么没有 C 风格 for**：Zig 的立场是"C 风格 for 的绝大多数用法其实是遍历，那就用 `for`；真需要复杂步进才写 `while`"。输出最后一行 `倒着数 = 321` 就是那种场景：步进是**递减**，用 `for` 表达不出来，就写 `while (down > 0) : (down -= 1)`。**能一眼看出步进规律的用 for，看不出就用 while**——这是个很实用的判据。

**范围是左闭右开**（`0..5` 得 0,1,2,3,4，和为 10）。为什么？因为它和切片长度天然对齐：`xs[0..n]` 恰好是 n 个元素，`0..n` 恰好迭代 n 次。同一个数字 `n` 在两处含义相同，少一个心智转换。

⚠️ **多序列 zip 要求长度一致**。`for (a, b)` 在编译期能看出两个序列长度不同时会报错；长度是运行期才知道的（切片）就不检查，会按最短的迭代。所以别用它遍历长度可能不同的两个切片。

⚠️ **原书自测题 Q8 的答案过时了**：它给的 `for (items) |value, index|` 是 0.11 及更早的写法，0.12 起（含 0.17）必须写成多对象形式 `for (items, 0..) |value, index|`。

## 4.7 指针捕获：改的是元素，不是副本

`for (arr) |v|` 里的 `v` 是**元素的拷贝**，改它等于改了空气。要改元素必须用指针捕获，而且**序列本身要加 `&`**。

```zig
// examples/04_control/main.zig 第 229-250 行
begin("4.7");
var nums = [_]u8{ 1, 2, 3 };
for (nums) |v| {
    _ = v; // v 是拷贝，改它没用
}
for (&nums) |*p| p.* *%= 10; // p 是 *u8，改的是数组本身
std.debug.print("for (&nums) |*p| 改完 = {any}\n", .{nums});
for (&nums) |*p| {
    if (p.* == 20) p.* = 99;
}
std.debug.print("再改一个 = {any}\n", .{nums});
// 指针捕获 + 下标组合：这就是"边遍历边改元素"的标准写法
var flags = [_]bool{ false, true, false };
for (&flags, 0..) |*flag, idx_f| {
    if (flag.*) continue;
    flag.* = @as(bool, idx_f == 2);
}
std.debug.print("flags = {any}（下标 2 的 false 被翻成 true）\n", .{flags});
end("4.7");
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.7 开始 ====
for (&nums) |*p| 改完 = { 10, 20, 30 }
再改一个 = { 10, 99, 30 }
flags = { false, true, true }（下标 2 的 false 被翻成 true）
==== 4.7 结束 ====
```

输出第 1 行 `{ 10, 20, 30 }` 是证据：`for (&nums) |*p| p.* *%= 10;` 一行就地把三个元素都改了。这不是"Zig 迭代方式很高效"，而是"**类型系统逼你说了你要干什么**"——值捕获明摆着是拷贝，你想改就必须走指针，于是每个读者都知道这里在原地修改。

⚠️ **漏掉 `&` 会报一个很友好的错**：

```text
error: pointer capture of non pointer type '[3]u8'
    for (a) |*v| { v.* +%= 1; }
             ^~~
note: consider using '&' here
```

编译器直接告诉你"这里应该加 `&`"。这比 C 里"我以为改了其实没改"的静默错误强得多。

⚠️ `p.* *%= 10` 里的 `*%=` 是**环绕**乘法（03 章 3.4 节）。这里 10 装得进 u8 用 `*=` 也行，但环绕版明确表达了"我知道会溢出"。

指针捕获让"边遍历边改"很容易写，于是也很容易写出 UB：**在 `for` 里对底层数组做 `append`/`remove`/`realloc`**——迭代器持有的下标或指针会失效。要"边遍历边改"就先收集要改什么，遍历完再统一改。

## 4.8 标签一：labeled loop 跨层跳出

标签贴在 `for` / `while` 前面，`break :label` 跳出**任意层**，`continue :label` 从深层跳到外层下一轮。

```zig
// examples/04_control/main.zig 第 252-271 行
begin("4.8");
var visited: usize = 0;
outer: for (1..4) |x| {
    for (1..4) |y| {
        if (y > x) continue :outer; // 跳到外层下一轮
        visited += 1;
    }
}
std.debug.print("continue :outer → visited = {d}\n", .{visited});
// break :label value 想产出值时，走完的出口也要给值 → 用 else 补
var pairs: usize = 0;
const found: usize = find: for (0..5) |row| {
    for (0..5) |col| {
        pairs += 1;
        if (row * row + col * col == 9) break :find @as(usize, row * 10 + col);
    }
} else 0;
std.debug.print("break :find → 找到 {d}，用了 {d} 次迭代（找到就一层跳出）\n", .{ found, pairs });
end("4.8");
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.8 开始 ====
continue :outer → visited = 6
break :find → 找到 3，用了 4 次迭代（找到就一层跳出）
==== 4.8 结束 ====
```

`visited = 6` 值得算一遍：`x` 从 1 到 3，每轮里 `y <= x` 的 `y` 才计数（`y > x` 就 `continue :outer`），于是 1+2+3 = 6。**这个"只算上三角"的逻辑用 `flag` 布尔变量要写一堆判断，用标签是三行。**

`found = 3` 来自 `row = 0, col = 3`（`0×0 + 3×3 = 9`），编码成 `row * 10 + col = 3`，**用了 4 次迭代**（row=0 那轮 col 迭代 0、1、2、3 才命中）。注意命中的是 `row = 0` 而不是直觉上的 `row = 3`——遍历是从外到内，`row = 0` 时 `col = 3` 就已经凑出 3 的平方了。这个"编码"手法本身也是 4.5 节的一个用途：`break :find 值` 一边跳出两层循环，一边把答案送出去。

⚠️ 注意 `found` 那行末尾的 `} else 0;`。**没有它编译不过**（坑位 #6：`incompatible types: 'usize' and 'void'`）。直觉上"那种组合走完的机会几乎没有"，但编译器不做这种流分析——它只要求 `break :find usize` 和"走完"两条出口类型一致。

**什么时候该用标签**：嵌套超过两层、且内层的某个条件要决定"外层还要不要继续"。**什么时候不该用**：能用 `if` 表达清楚就别用——标签是逃生门，不是正门。原书那句吐槽说得不错："Using labeled continue is a surefire way to ensure only you understand your code."

## 4.9 标签二：labeled block

块也可以有标签。带标签的块有**两个**用途：从任意深层 `break :label` 出来，以及给"多语句求一个值"一个结果位置。

```zig
// examples/04_control/main.zig 第 273-296 行
begin("4.9");
const first_even = blk: {
    var idx: usize = 0;
    while (idx < 10) : (idx += 1) {
        if (@mod(idx, 2) == 0) break :blk idx; // 从 while 内部跳出任意多层
    }
    break :blk @as(usize, 999); // 兜底出口：块必须有值
};
std.debug.print("第一个偶数下标 = {d}\n", .{first_even});
// labeled block 能把 defer 圈在局部：块结束 = defer 触发
const rect_area = blk: {
    defer std.debug.print("  （块里的 defer，块结束就跑）\n", .{});
    break :blk areaOf(.{ .rect = .{ .w = 3, .h = 4 } });
};
std.debug.print("labeled block 的值 = {d:.1}\n", .{rect_area});
// labeled block 的第二个用途：给多语句一个结果位置（Zig 没有逗号表达式）
const swapped = blk: {
    const x: i32 = 3;
    const y: i32 = 4;
    break :blk .{ y, x };
};
std.debug.print("交换两个常量 = {any}\n", .{swapped});
end("4.9");
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.9 开始 ====
第一个偶数下标 = 0
  （块里的 defer，块结束就跑）
labeled block 的值 = 12.0
交换两个常量 = .{ 4, 3 }
==== 4.9 结束 ====
```

**和labeled loop 的区别**：标签贴在**块**上而不是循环上。价值在两处：

**① 从 `while`/`for` 内部直接跳出块。** `first_even` 里 `break :blk idx` 写在 while 体内，跨了两层（循环 + 块）跳出来。对比 4.8 节的 `break :find`——那个必须写在 for 头上，因为它要跳的是**循环**；`break :blk` 跳的是**块**，而块包住了循环，所以从里面直接写就行。这类"找到就返回"的逻辑用 labeled block 比用 labeled loop 更短。

**② 给多语句一个结果位置。** Zig **没有逗号运算符**（`(a, b)` 不存在）。`swapped` 展示了替代写法：块里定义几个 `const`，最后 `break :blk` 给出值。`comptime blk: { ... }`（03 章 3.10 节）是它的编译期版本。

⚠️ **块必须有值出口**。`first_even` 写了两处 `break :blk`（命中 + 兜底 999）——如果 while 正常走完没有 break，块的值从哪来？编译器要求每个块都有确定的出口。这也是为什么兜底值写 999（一个"不可能是答案"的数）——真出这个值说明逻辑错了。

**块和 defer 的关系**（本节彩蛋）：`rect_area` 里的 `defer` **在块结束时就跑了**（输出第 2 行，出现在 `labeled block 的值` 那行之前）。`defer` 绑定的是**它所在的作用域**，labeled block 就是一个作用域。所以 labeled block 还是**给 defer 划定生命周期**的工具——不用手写一个函数把它包起来。

## 4.10 `switch`：多值、范围、穷尽性

Zig 的 `switch` 与 C 的三处本质区别：**必须穷尽**（漏了编译错）、**没有 fallthrough**（不用 `break`）、**是表达式**（每个分支产出一个值）。

```zig
// examples/04_control/main.zig 第 298-338 行
begin("4.10");
for ([_]u8{ 1, 3, 5, 9, 200 }) |v| {
    // u8 值域 256 个，编译器无法证明穷尽 → 必须写 else
    const desc = switch (v) {
        1, 2, 3 => "低", // 多值并列，不用 fallthrough
        4...9 => "中", // 范围是三个点；写1..3 报 error: expected '=>', found '..'
        10...99 => "高",
        else => "爆表",
    };
    std.debug.print("{d}→{s} ", .{ v, desc });
}
std.debug.print("\n", .{});
// 枚举不需要 else：写多了反而报 error: unreachable else prong; all cases already handled
const c: Color = .green;
const color_name = switch (c) {
    .red => "红",
    .green => "绿",
    .blue => "蓝",
};
std.debug.print("Color 穷尽 = {s}；Color 有 {d} 个成员\n", .{ color_name, @typeInfo(Color).@"enum".field_names.len });
// 范围可以带负数，端点必须同类
for ([_]i32{ -100, -1, 0, 5, 50 }) |v| {
    const bucket = switch (v) {
        -100...0 => "负或零",
        1...9 => "个位",
        10...99 => "两位",
        else => "三位以上",
    };
    std.debug.print("{d}→{s} ", .{ v, bucket });
}
std.debug.print("\n", .{});
// switch 也是表达式，每个分支必须同类型
const grade: u8 = 77;
const verdict = switch (grade) {
    90...100 => "A+",
    60...89 => "及格",
    else => "要补考",
};
std.debug.print("77 分 → {s}\n", .{verdict});
end("4.10");
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.10 开始 ====
1→低 3→低 5→中 9→中 200→爆表 
Color 穷尽 = 绿；Color 有 3 个成员
-100→负或零 -1→负或零 0→负或零 5→个位 50→两位 
77 分 → 及格
==== 4.10 结束 ====
```

### 范围是三个点：`4...9`

`1...3` 是闭区间 [1,3]；切片语法 `a[0..2]` 是左闭右开。两个都用两个点会混淆，所以 switch 的范围**故意**用三个点提醒你"这是范围不是切片"。写 `1..3 =>` 的报错是：

```text
error: expected '=>', found '..'
        1..3 => "低",
         ^~
```

范围端点可以带负数（`-100...0`），两端类型必须一致——`switch (v)` 里 `v` 是什么类型，`...` 两端就是什么类型。

### 穷尽性：什么时候要 `else`，什么时候不要

| 被 switch 的类型 | 要写 `else` 吗 | 写错了会怎样 |
|---|---|---|
| `u8`/`i32`/区间… | **必须写** | 漏了报 `error: switch must handle all possibilities` |
| `enum` | **不能写** | 写了报 `error: unreachable else prong; all cases already handled` |
| `bool` | 不能写 | 同上 |
| `union(enum)` | 不能写 | 同上 |

编译器**能**穷尽证明的类型（枚举、bool、union(enum)）不许多写 `else`；**不能**穷尽证明的类型（整数、范围、浮点）必须写——整数有 2³² 个可能值，穷举不过来，`else` 是逃生舱。

这条规则的价值在枚举上体现得最充分：**给 `enum Color` 加一个新成员 `.yellow`，全项目所有 `switch (c)` 立刻编译报错**。C/Java 的 switch 漏了枚举成员编译通过，运行时进 `default` 分支——可能对，可能错，你在 3 点钟的线上才会知道。

### 三个 `...` 对照 C

1. **穷尽由编译器保证**（不是你的自觉）
2. **没有 fallthrough**：多个值共享代码要**显式**并列写成 `1, 2, 3 => "低"`
3. **是表达式**：每个分支产出一个值，整个 switch 可以出现在赋值右边

## 4.11 `switch` 捕获 `union(enum)` 的负载

Zig 的 `union(enum)`（带标签联合，08 章）+ `switch` 捕获 = 模式匹配。分支名是形态名，`|载荷|` 直接拿到该形态存的**值**。

```zig
// examples/04_control/main.zig 第 40-55 行
/// 4.11 节的测试用：给 union(enum) 的 rect 形态起个名字，好写 ?Dims
const Dims = struct { w: f64, h: f64 };

const Shape = union(enum) {
    dot,
    circle: f64,
    rect: Dims,
};

fn areaOf(s: Shape) f64 {
    return switch (s) {
        .dot => 0,
        .circle => |r| 3.0 * r * r,
        .rect => |rect| rect.w * rect.h,
    };
}
```

```zig
// examples/04_control/main.zig 第 340-347 行
begin("4.11");
std.debug.print("dot   面积 = {d:.1}\n", .{areaOf(.{ .dot = {} })});
std.debug.print("circle 面积 = {d:.2}（3.0 * 2 * 2）\n", .{areaOf(.{ .circle = 2 })});
std.debug.print("rect   面积 = {d:.1}（3 * 4）\n", .{areaOf(.{ .rect = .{ .w = 3, .h = 4 } })});
// 捕获的载荷是"该形态字段的**副本**"，类型就是字段类型
std.debug.print("载荷类型：|r| 是 {s}，|rect| 是 {s}\n", .{ @typeName(@TypeOf(@as(Shape, undefined).circle)), @typeName(@TypeOf(@as(Shape, undefined).rect)) });
end("4.11");
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.11 开始 ====
dot   面积 = 0.0
circle 面积 = 12.00（3.0 * 2 * 2）
rect   面积 = 12.0（3 * 4）
载荷类型：|r| 是 f64，|rect| 是 main.Dims
==== 4.11 结束 ====
```

**捕获到的类型就是字段类型**（输出第 4 行）。`|r|` 是 `f64`，`|rect|` 是 `main.Dims`。因为是**副本**，修改它不影响原联合——需要修改就写 `|*r|` 拿指针（03 章的 3.x 节讨论过指针捕获）。

**`areaOf` 是本节真正要教的东西**：函数体就是一个 `switch` 表达式，没有临时变量、没有 `if (s == .circle) { ... } else if ...`。这是 Zig 里写"多形态数据"的标准形态。

⚠️ **`union(enum)` 不能在 switch 里漏形态**，也不能加 `else`。漏了报 `error: switch must handle all possibilities`，加了报 `unreachable else prong`。

## 4.12 标签三：labeled switch 状态机

`continue :label` 作用在 labeled `switch` 上，让 switch 变成**状态机循环**——不用在外面包 `while`，分支之间直接"续跳"。

```zig
// examples/04_control/main.zig 第 349-407 行
begin("4.12");
var st: St = .idle;
const ticks: u8 = 2; // 状态机走过的步数（写法二里手工数）
// 写法一：枚举操作数 + continue :label（不包 while）
const walk = sw: switch (st) {
    .idle => {
        st = .running;
        continue :sw st;
    },
    .running => {
        st = .done;
        continue :sw st;
    },
    .done => break :sw ticks,
};
std.debug.print("枚举版：idle→running→done，终值 {d}，st 现在是 {t}\n", .{ walk, st });
// 写法二：整数操作数（0.14+：continue :label 后面不必是枚举值）
var code: u8 = 1;
var seen: [8]u8 = undefined;
var seen_len: usize = 0;
const final_code: u8 = code_sw: switch (code) {
    1 => {
        seen[seen_len] = 1;
        seen_len += 1;
        code = 2;
        continue :code_sw code;
    },
    2 => {
        seen[seen_len] = 2;
        seen_len += 1;
        code = 9;
        continue :code_sw code;
    },
    9 => break :code_sw 99,
    else => break :code_sw 0,
};
std.debug.print("整数版：见过 {any}，终值 {d}（9 不是枚举成员，靠 else 兜底）\n", .{ seen[0..seen_len], final_code });
end("4.12");
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.12 开始 ====
枚举版：idle→running→done，终值 2，st 现在是 done
整数版：见过 { 1, 2 }，终值 99（9 不是枚举成员，靠 else 兜底）
对照写法：while 包 switch 要额外管一个 op 变量，步数 2
==== 4.12 结束 ====
```

`St` 定义在 `main.zig` 第 57-58 行：`const St = enum { idle, running, done };`。

### 对照：少了什么

输出第 3 行是同样的状态机用 `while` 包 `switch` 写出来的版本（代码在 `main.zig` 第 387-406 行）。对比之后 labeled switch 省掉的是：一个循环变量（`while (true)` 本身）、一个额外的状态变量（`op`）、一层嵌套缩进、以及两处重复的"改状态 + continue"。

`while` 版的 `1 => { op = 2; steps += 1; continue; }` 里，"下一步去 2"这个信息分散在两行；labeled switch 版里跳转目标和跳转时机挨在一起。这就是原书说的"没有隐藏的状态变量"。

### 操作数不必是枚举

**写法二**（输出第 2 行）用的是 `u8` 操作数，0.14 起 `continue :label` 后面可以跟任意值。这让 labeled switch 可以用在"字节码解释器 / 协议状态码"这类没有枚举的地方。代价是**必须写 `else`**——`u8` 穷尽不了（见 4.10 节的表）。

⚠️ **labeled switch 也要标类型**（坑位 #7）。`break :sw 2` 里的 `2` 是 `comptime_int`（03 章 3.3 节），而 switch 整体是运行期控制流，报 `value with comptime-only type 'comptime_int' depends on runtime control flow`。解法是**给结果标类型**（`const out: u8 = ...`）或**在 break 里点出类型**（`break :sw @as(u8, 2)`）。示例两个分支都用了后者。

## 4.13 `defer` / `errdefer`：控制流的倒序退出

`defer` 在**作用域**结束时执行，而且是**后进先出**。`errdefer` 只在函数**以错误返回**时执行。

```zig
// examples/04_control/main.zig 第 409-414 行
begin("4.13");
defer std.debug.print("main 的 defer：main 退出时才跑（全程序最后一行）\n", .{});
deferOrder();
_ = scoped() catch {};
end("4.13");
```

```zig
// examples/04_control/main.zig 第 473-486 行
/// defer 是后进先出：两个 defer 按注册顺序的**逆序**执行
fn deferOrder() void {
    std.debug.print("deferOrder：\n", .{});
    defer std.debug.print("  defer A\n", .{}); // 后注册
    defer std.debug.print("  defer B\n", .{}); // 先注册
    std.debug.print("  body\n", .{});
}

/// errdefer 只在本函数**以错误返回**时执行；defer 无论成败都执行
fn scoped() ParseError!u8 {
    errdefer std.debug.print("  errdefer：只在出错时跑\n", .{});
    defer std.debug.print("  scoped 的 defer：无论成败都跑\n", .{});
    return error.Empty;
}
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.13 开始 ====
deferOrder：
  body
  defer B
  defer A
  scoped 的 defer：无论成败都跑
  errdefer：只在出错时跑
==== 4.13 结束 ====
```

**后进先出**：`body` 先跑，然后 `defer B`（先注册）再 `defer A`（后注册）。这是**栈**语义，和 RAII（22 章）、文件句柄管理是同一套：后打开的资源先关闭，符合依赖方向。

**`errdefer` 的触发条件很窄**：只有当函数**用错误返回**时。本例 `scoped` 直接 `return error.Empty`，所以它跑了。输出里的顺序也说明了执行次序：`scoped` 的 `defer` 先跑（无论成败），`errdefer` 后跑——错误路径上"先做常规清理，再做错误补救"的自然顺序。注意调用方写的是 `_ = scoped() catch {};`，**`catch {}` 不影响 `errdefer` 触发**：`errdefer` 关心的是"函数有没有以错误返回"，不是"调用方最后怎么处理"。

⚠️ **`scoped()` 返回 `u8`，`scoped() catch {}`（void）类型不匹配**：

```text
error: incompatible types: 'u8' and 'void'
    scoped() catch {};
                   ^~
```

必须写 `_ = scoped() catch {};`（丢掉返回值），或 `catch @as(u8, 0)` 给个同类型的兜底值。`defer` / `errdefer` 与错误处理的完整关系见 09 章。

## 4.14 `@branchHint`：给分支预测器一个提示

0.17 里唯一的"分支微调"内建。**它不改语义**，只影响 LLVM 生成的分支权重和代码布局。

```zig
// examples/04_control/main.zig 第 416-432 行
begin("4.14");
const flag: u8 = 7;
if (flag > 3) {
    // ⚠️ 0.17 的 @branchHint 是**独立语句**，且必须放在分支体的第一句。
    @branchHint(.likely);
    std.debug.print("flag > 3：大概率分支\n", .{});
}
if (flag > 1000) {
    @branchHint(.unlikely);
    std.debug.print("flag > 1000（小概率分支，不会执行到这里）\n", .{});
}
// 它不改语义，只影响 LLVM 生成的分支权重与代码布局。
end("4.14");
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.14 开始 ====
flag > 3：大概率分支
==== 4.14 结束 ====
```

⚠️ **语法和多数教程写的不一样**。老写法 `if (@branchHint(.likely) c > 3)` 在 0.17 报：

```text
error: expected ')', found 'an identifier'
    if (@branchHint(.likely) c > 3) {
                             ^
```

而在 `if` **之前**独立写一行也报：

```text
error: '@branchHint' must appear as the first statement in a function or conditional branch
    @branchHint(.likely);
```

正确姿势是**放在分支体的第一句**（`if` 或 `else` 的花括号里）。这个约束是合理的：分支权重必须紧贴它影响的那个分支，写在"外面"就说不清影响谁。

**什么时候该用**：默认 LLVM 已经能从模式匹配、错误率统计里推断出大部分分支权重。`@branchHint` 留给"确实知道但推断不出来"的场景——一个从来走不到的防御性分支、或一个 99% 命中的热路径。**不要拿它当优化手段乱加**（原书对 `inline` 循环的告诫同理："unless you have a compelling reason—and a note from your doctor"）。

## 4.15 `inline for`：循环体在编译期展开

普通 `for` 的迭代值是**运行期**的，`inline for` 让每次迭代都是**编译期常量**。于是循环体里可以做类型层面的 gymnastics。

```zig
// examples/04_control/main.zig 第 434-448 行
begin("4.15");
// 普通 for 的迭代值是运行期的；inline for 让每次迭代都是编译期常量，
// 于是循环体里可以用 switch 按值挑**类型**（03 章 3.10 节）
comptime var name_bytes: usize = 0;
inline for ([_]type{ u8, i32, f64 }) |T| {
    name_bytes += @typeName(T).len;
}
std.debug.print("u8/i32/f64 的类型名长度之和 = {d}（2+3+3，编译期算好）\n", .{name_bytes});
// 同样的形状写普通 for 就编译不过：普通 for 的 T 是运行期的，
// 而"类型"是编译期实体 → error: values of type 'type' must be comptime-known
comptime var sizes: usize = 0;
inline for ([_]type{ u8, i32, f64 }) |T| sizes += @sizeOf(T);
std.debug.print("sizeOf 之和 = {d}\n", .{sizes});
end("4.15");
```

运行输出（`examples/04_control/main.zig`）：

```text
==== 4.15 开始 ====
u8/i32/f64 的类型名长度之和 = 8（2+3+3，编译期算好）
sizeOf 之和 = 13
==== 4.15 结束 ====
```

`8 = 2 + 3 + 3`（`"u8"`/`"i32"`/`"f64"` 的长度），`13 = 1 + 4 + 8`（`@sizeOf` 之和）。两个数**编译期就定下来了**，运行期零开销。

**为什么普通 `for` 不行**：`[_]type{ u8, i32, f64 }` 的元素类型是 `type`——**编译期实体**（03 章 3.8 节）。普通 `for` 的 `T` 是运行期的索引值，于是 `error: values of type 'type' must be comptime-known`。`inline for` 在编译期把循环展开三次，每次的 `T` 都被固化成 `u8`/`i32`/`f64` 一个具体类型，问题消失。

**代价**（原书"Caution with inline loops"说得对）：`inline for` 会**增加编译时间和二进制体积**（每种类型生成一份代码）。只在"必须按类型/按编译期常量生成不同代码"时用，别拿它当性能开关。03 章 3.10 节的 `factorial(n)` 是同一个技术。

## 4.16 测试：把语义钉住

本章 16 个 `test` 块，验证的是**语义**而不只是"能跑"：

```bash
$ zig test main.zig
1/16 main.test.if 是表达式：整条if-else 链可以是一个值...OK
2/16 main.test.if 捕获可选与错误联合...OK
3/16 main.test.orelse / catch / catch |err|...OK
4/16 main.test.continue 表达式在 continue 时也会执行...OK
5/16 main.test.循环 else：有 break 走 break，没 break（含 0 次迭代）走 else...OK
6/16 main.test.for 的四种迭代形态...OK
7/16 main.test.指针捕获改的是元素本身...OK
8/16 main.test.labeled loop：跨层 break 与 continue...OK
9/16 main.test.labeled block：从深层跳出 + 圈住 defer...OK
10/16 main.test.switch 的range 是三个点，且要穷尽...OK
11/16 main.test.switch 对枚举穷尽：不需要 else...OK
12/16 main.test.switch 捕获 union(enum) 负载...OK
13/16 main.test.labeled switch 走完状态机...OK
14/16 main.test.defer 后进先出，errdefer 只在出错时跑...OK
15/16 main.test.inline for 在编译期展开...OK
16/16 main.test.@branchHint 不改语义，只改分支权重...OK
All 16 tests passed.
```

三个写法值得学：

**① 用"带副作用的函数"证明惰性求值**（第 3 个测试，见 4.3 节）。这是测 `orelse` / `catch` 这类短路语义唯一可靠的办法。

**② 用 `expect` 验证"没发生的事"**。第 5 个测试断言空序列的循环体一次没跑；第 3 个测试断言 `orelse` 右边没被求值。这类"证明某条路径没走"的断言比"验证结果值对"更能钉住语义。

**③ 对照实验**（第 7 个测试，`main.zig` 第 626-633 行）：先断言指针捕获真的改了原数组，再断言值捕获**改不动**它：

```zig
// examples/04_control/main.zig 第 626-633 行
var nums = [_]u8{ 1, 2, 3 };
for (&nums) |*p| p.* *%= 10;
try std.testing.expectEqualSlices(u8, &.{ 10, 20, 30 }, &nums);
// 对照：值捕获拿到的是副本
var copy = nums;
for (copy) |v| {
    _ = v;
}
try std.testing.expectEqualSlices(u8, &nums, &copy);
```

而第 4 个测试（`main.zig` 第 556-564 行）钉住的是"while 捕获可选只走一步"：

```zig
// examples/04_control/main.zig 第 556-564 行
// while 迭代可选元素：null 处自然停止
const seq = [_]?u8{ 7, null, 9 };
var seen: u8 = 0;
var idx: usize = 0;
while (seq[idx]) |v| : (idx += 1) {
    seen += v;
}
try std.testing.expectEqual(@as(usize, 1), idx); // 只走到第 1 个
try std.testing.expectEqual(@as(u8, 7), seen);
```

`idx == 1` 而不是 2 或 3——因为 `null` 在下标 1 处。数组里那个 `9` **一次都没被访问**，这不是巧合，是 4.4 节那条规则的直接后果。

## 4.17 坑位清单

1. **`while (err_union) |v|` 在 0.17 不再支持**：`error: expected optional type, found 'error{...}!u32'` + `note: consider using 'try', 'catch', or 'if'`。`while` 的 `|v|` 捕获只能问"是不是没有值"，错误联合里的错误是个**值**，回答不了这个问题。错误联合一律用 `if`/`catch` 在循环体里处理。
2. **`switch` 在 0.17 也不能接可选和错误联合**：`switch (opt)` 报 `error: switch on optional type '?u8'` + `note: consider using '.?', 'orelse', or 'if'`；`switch (err_union)` 报 `error: switch on error union type 'error{...}!u8'`。解法是 `orelse` 拆包，或 `if (opt) |v|`。
3. **`if (mx and my) |x, y|` 不存在**（《Learning Zig》ch4 的一处错误）：`error: expected '|', found ','`。只能捕获一个，可选合并用嵌套 `if`。
4. **`_ = err;` 不能丢弃错误值**：`error: error set is discarded`。错误值必须被 `@errorName`、比较、或 `switch` 真正消费掉。同理 `{d}` 也打印不了错误联合（`error: invalid format string 'd' for type 'error{...}!u32'`），要先用 `if`/`catch` 拆开再决定格式符。
5. **`@branchHint` 是独立语句且必须放分支体第一句**：`if (@branchHint(.likely) c > 3)` 报 `expected ')', found 'an identifier'`；写在 `if` 前面报 `'@branchHint' must appear as the first statement in a function or conditional branch`。正确写法是 `if (c > 3) { @branchHint(.likely); ... }`。
6. **`break :label 值` 必须配 `else`**：循环"正常走完"那条出口的值是 `void`，不补 `else` 就报 `error: incompatible types: 'usize' and 'void'`。编译器不做"这个 break 一定会发生"的流分析。
7. **labeled switch 的结果要标类型**：`break :sw 2` 里的 `2` 是 `comptime_int`，报 `error: value with comptime-only type 'comptime_int' depends on runtime control flow`。解法：`const out: u8 = sw: switch (...)` 或 `break :sw @as(u8, 2)`。
8. **函数体里不能嵌套 `fn` 声明**：写在 `main` 内部报 `error: expected ',' after initializer`。辅助函数一律提到文件顶层。
9. **`for (arr) |*v|` 必须配 `&`**：`error: pointer capture of non pointer type '[3]u8'` + `note: consider using '&' here`。漏了 `&` 捕获到的是拷贝——**遍历中修改底层集合则是 UB**（`append`/`remove` 让迭代器失效），要先收集再统一改。
10. **switch 的范围是三个点 `4...9`**：写两个点报 `error: expected '=>', found '..'`。两个点是切片 `xs[0..2]`（左闭右开），三个点是范围（**两端都闭**）——`1...3` 含 1 和 3。
11. **枚举 switch 写了 `else` 会报错**：`error: unreachable else prong; all cases already handled`。反过来，`u8` 这类值域大的类型**必须**写 `else`，漏了报 `error: switch must handle all possibilities`。穷尽性由编译器证明，不要手动补 `else`。
12. **循环的 `else` 是"没 break"，不是"没执行"**：一次都没迭代也会走 `else`。原书自测题 Q9 的答案 b 只在空序列这个特例上碰巧成立，准确表述是"没有因为 break 提前退出"。
13. **`catch` 的兜底值类型必须和成功值一致**：`scoped() catch {}` 报 `error: incompatible types: 'u8' and 'void'`。要么 `_ = ... catch {}` 丢掉结果，要么 `catch @as(u8, 0)`。且 `catch` 的右边**只在出错时求值**。
14. **`defer` 是后进先出**（栈语义），`errdefer` 只在函数**以错误返回**时触发——调用方用 `catch` 消费错误不影响它的触发。`defer` 绑定作用域，所以 labeled block 可以用它划定生命周期（4.9 节）。
15. **算术结果永不宽化会咬到控制流代码**：`std.math.maxInt(u32) - digit`（`digit` 是 `u8`）报 `type 'u8' cannot represent integer value '4294967295'`，得先 `const wide: u32 = digit;`。多序列 zip 也要求长度一致，长度是运行期才知道的（切片）则按最短的迭代。
16. **`var` 声明了却从不改是编译错误**（不是警告）：`error: local variable is never mutated`。**作用域遮蔽同样被禁止**（`capture 'k' shadows local variable from outer scope`）——同名捕获变量要改名。两者都是 03 章那条规则的延续。

---

上一章：[03 类型与转型](03-types.md) · 下一章：[05 函数](05-functions.md)
