# 04 · 控制流

> 对应示例：`examples/04_control/`

## 4.1 if 是表达式

```zig
fn gradeLabel(score: u8) []const u8 {
    return if (score >= 90) "优秀" else if (score >= 60) "及格" else "不及格";
}
```

Zig 没有三元运算符 `?:`——**if/else 本身就是表达式**，能放在 `return`、赋值、参数位置。C++ 里 `cond ? a : b` 和 `if` 两套写法，Zig 一套打天下。

## 4.2 while 与 continue 表达式

```zig
var i: usize = 0;
var sum: usize = 0;
while (i < 5) : (i += 1) {   // 冒号后是"每轮结束执行"的表达式
    if (i == 2) continue;    // continue 也会先跑 : (i += 1)
    sum += i;
}
```

`: (i += 1)` 这个**continue 表达式**把"步进"写进循环头，循环体里忘掉 `i += 1` 导致死循环的经典事故从语法上消灭。`while (opt) |v|` 还能直接迭代可选值/错误联合（第 09 章）。

## 4.3 for 全家福

```zig
const names = [_][]const u8{ "C", "Zig", "Rust" };
const years = [_]u16{ 1972, 2016, 2015 };

for (names, years, 0..) |n, y, idx| { ... }  // zip 多序列 + 下标
for (0..3) |k| { ... }                       // 范围（左闭右开）
for (arr) |v| { ... }                        // 数组/切片
for (arr) |*v| { ... }                       // 取元素指针（要修改时）
```

**没有 C 风格 `for (i = 0; i < n; i++)`**——设计立场：下标循环的常见目的是遍历，那就用 `for`；真需要复杂步进用 `while` + continue 表达式。多序列 zip 写法 `for (a, b) |x, y|` 长度必须相等（编译期已知长度时编译器检查）。

## 4.4 label：从内层直接操作外层

```zig
outer: for (0..3) |row| {
    for (0..3) |col| {
        if (col == 2) continue :outer;  // 直接进入外层下一轮
        if (row == 2) break :outer;     // 直接终止外层
    }
}
```

标签贴在循环（或块）前面，`break :label` / `continue :label` 跨层跳转。**嵌套超过两层还想用标签时，先想想是不是该拆函数**——标签是逃生门，不是正门。

## 4.5 switch：穷尽性是编译期保证

```zig
const desc = switch (v) {
    1, 2, 3 => "低",       // 多值并列
    4...9 => "中",         // 范围（三个点！切片才是两个点）
    10...99 => "高",
    else => "爆表",        // 非穷尽类型（u8）必须 else
};
```

Zig 的 switch 与 C 的三处本质区别：**分支必须穷尽**（漏了编译错，加新枚举值时编译器替你找全所有 switch）；**没有 fallthrough**（不用 break）；**是表达式**（每个分支产出一个值）。对枚举（第 08 章）使用时穷尽性检查最闪亮：给 enum 加个字段，全项目的 switch 立刻列队报错。

## 4.6 switch 捕获联合的负载

```zig
const Shape = union(enum) { circle: f64, rect: struct { w: f64, h: f64 } };
const s = Shape{ .rect = .{ .w = 3, .h = 4 } };
const area: f64 = switch (s) {
    .circle => |r| 3.14159 * r * r,   // |r| 捕获该形态的负载
    .rect => |d| d.w * d.h,
};
```

tagged union（第 08 章）配 switch 捕获是 Zig 的"模式匹配"——分支名是 `.形态名`，`|载荷|` 直接拿到值。这是日常代码里 switch 最常见的形态。

## 4.7 labeled switch：状态机式 continue

```zig
var st: State = .start;
const total = sw: switch (st) {
    .start => {
        st = .running;
        continue :sw .running;   // 就地跳到另一个分支继续
    },
    .running => {
        st = .done;
        continue :sw .done;
    },
    .done => break :sw ticks,
};
```

0.14 新增：`continue :label .enum_value` 让 switch 变成**状态机循环**——不用外面包 while，分支之间直接"续跳"。处理解析器、协议状态机时比"循环包 switch"少一层嵌套。

## 4.8 坑位清单

1. **范围是三个点 `4...9`**：写成两个点（切片语法）编译错；新手最常犯的笔误之一。
2. **switch 漏 else（非穷尽类型）编译错**：对 `u8` 这类大值域类型别忘 `else =>`；对 enum 反过来——穷尽了就别加 else（加了会掩盖未来新增的枚举值）。
3. **for 里改集合**：遍历中 append/remove 底层数组是 UB（迭代器可能悬空）——先收集要改什么，遍历完再改。
4. **`for (arr) |v|` 的 v 是拷贝**：要改元素用 `|*v|` 捕获指针，或用下标循环。
5. **continue 表达式在 continue 时也会执行**：靠 `: (i += 1)` 步进的循环里 continue 不会跳过步进（这正是它比 `for(;;)` 安全的地方）。

---
