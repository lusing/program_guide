# 08 · 枚举与联合

> 对应示例：`examples/08_enums/`

## 8.1 enum：封闭集合 + 方法

```zig
const Color = enum {
    red,
    green,
    blue,

    fn hex(self: Color) u32 {        // 枚举也能有方法（同 struct）
        return switch (self) {
            .red => 0xFF0000,
            .green => 0x00FF00,
            .blue => 0x0000FF,
        };
    }
};
const c = Color.green;
@tagName(c)     // "green"：值 → 名字
c.hex()         // 方法照常调用
```

enum 是**编译期封闭的符号集合**——合法值就那些，别的进不来（0.8 万个 `#define` 时代结束）。`.` 前缀（`.green`）是枚举值字面量，目标类型明确时可以省略类型名——`var st: State = .start;` 这种写法满地都是。

## 8.2 指定 tag 与非穷尽 `_`

```zig
const Level = enum(u8) {
    low = 10,
    mid = 50,
    high = 90,
    _,                  // 非穷尽声明
};
const lv: Level = @enumFromInt(50);       // mid
const unknown: Level = @enumFromInt(42);  // 也能装！（有 `_`）
@tagName(unknown)                          // 编译错：没有对应名字
```

`enum(u8)` 指定底层整数类型和显式值（与 C 枚举对接时关键）。**末尾的 `_` 声明"非穷尽"**：允许未知整数值进来——C 头文件里的枚举经常这么用（新版本加了值，旧代码不该编译失败）。代价：非穷尽枚举的 switch 必须 `else`，未知值不能 `@tagName`（没有名字可取）。

## 8.3 tagged union：安全的多选一

```zig
const Value = union(enum) {
    int: i64,              // 每个"形态"带不同类型的负载
    text: []const u8,
    list: []const f64,

    fn kind(self: Value) []const u8 {
        return switch (self) { .int => "整数", .text => "文本", .list => "列表" };
    }
};
var v: Value = .{ .int = 42 };   // 指定形态初始化
v = .{ .text = "hi" };           // 换形态 = 整体换值
```

`union(enum)`（标签联合/和类型）是 Zig 的**代数数据类型**：一块内存，编译器保证"只知道当前激活的是哪个形态"。内存布局 = tag + 最大负载。它是"这块数据可能是 A 也可能是 B"的正字法——C 的裸 union（读错字段 = UB）加了标签保护。

## 8.4 switch 捕获负载

```zig
switch (w) {
    .int => |i|  std.debug.print("整数 {d}\n", .{i}),    // |i| 拿到 int 负载
    .text => |t| std.debug.print("文本 {s}\n", .{t}),
    .list => |ls| std.debug.print("列表 {d} 项\n", .{ls.len}),
}
// 读错激活字段（w 是 .list 却写 w.int）→ Debug/ReleaseSafe 下 panic
```

04 章说过 switch 穷尽性——对 tagged union 它是**强制完整匹配所有形态**，配合 `|载荷|` 捕获就是模式匹配。直接读非激活字段在安全模式下是 panic 而非 UB。**改负载**用 `|*x|` 捕获指针。

## 8.5 packed struct：精确位布局

```zig
const Flags = packed struct {
    bold: bool = false,   // 1 bit
    italic: bool = false, // 1 bit
    size: u6 = 0,         // 6 bits——整体正好 1 字节
};
const f = Flags{ .bold = true, .size = 12 };
const bits: u8 = @bitCast(f);   // 0b0011_0001：整块位模式
```

`packed struct` 让字段**按位紧凑排列**（对照 C bitfield，但布局由 Zig 规则明确指定）：bool 占 1 位、`u6` 占 6 位。配合 03 章任意位宽整数，硬件寄存器/协议头的每一位都能精确建模。整块 `@bitCast` 到整数（或反向）是常用往返。**普通 struct 的字段顺序不保证布局**——跨语言/跨硬件共享布局必须 `extern struct` 或 `packed struct`（21 章）。

## 8.6 对照表：这些概念在别家叫什么

| 概念 | Zig | C++ | Rust |
|---|---|---|---|
| 符号集合 | `enum` | `enum class` | `enum` |
| 带数据的多选一 | `union(enum)` | `std::variant` | `enum`（自带） |
| 匹配 | `switch` + `\|载荷\|` | `std::visit` + overload | `match` |
| 位域 | `packed struct` | bitfield | 手写位运算 |

## 8.7 坑位清单

1. **非穷尽枚举未知值不能 `@tagName`**：值在集合里没有名字，取名字是编译错（comptime 已知）或 panic——先 `switch` 归类再取名。
2. **非穷尽枚举的 switch 必须有 `else`**：因为有未知值；反过来穷尽枚举别加 `else`（加了会吃掉未来新增形态的编译错误）。
3. **packed struct 字段顺序决定位位置**：与 C 结构对照时按声明顺序逐字段核对；调换字段 = 换位布局。
4. **`@enumFromInt` 未知值进穷尽枚举是运行期 panic**（安全模式）：要接外部整数先确认枚举声明 `_`。
5. **union 忘了初始化就读是 UB**：Debug 也能抓（坏 tag），但别依赖——初始化永远给 `.{ .形态 = 值 }`。

---

上一章：[07 结构体](07-structs.md) · 下一章：[09 可选与错误 I](09-optionals-errors.md)
