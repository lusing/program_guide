# 08 · 枚举与联合

> 对应示例：`examples/08_enums/main.zig`
>
> 本章是 0.17 迁移里**改动最狠**的一章。枚举 ↔ 整数的三个内建函数全部改名，
> `@enumFromInt` 这个名字被回收给了一个语义不同的函数，`zig fmt` 会自动改写你的源码；
> 错误联合的 `||` 运算符也改了含义。照抄任何 ≤0.16 的教程都会编译失败，
> 而且有几处失败信息极具误导性。本章把每一条都在0.17.0 上实测过。

---

## 8.1 `enum`：封闭的符号集合 + 方法

```zig
// examples/08_enums/main.zig 第 12-26 行
/// 8.1 节的枚举：不写基整型，编译器挑能装下全部成员的最小类型
const Color = enum {
    red,
    green,
    blue,

    /// 枚举也能有方法，和 struct 一样
    fn hex(self: Color) u32 {
        return switch (self) {
            .red => 0xFF0000,
            .green => 0x00FF00,
            .blue => 0x0000FF,
        };
    }
};
```

```zig
// examples/08_enums/main.zig 第 160-177 行
    // ═══ 8.1 enum：封闭集合 + 方法 + @tagName═══
    begin("8.1");
    const c: Color = .green; // 目标类型明确时 `.` 前缀可省类型名
    std.debug.print("Color 成员数={d} 基整型={s} @sizeOf={d} @bitSizeOf={d}\n", .{
        @typeInfo(Color).@"enum".field_names.len,
        @typeName(@typeInfo(Color).@"enum".tag_type),
        @sizeOf(Color),
        @bitSizeOf(Color),
    });
    std.debug.print("@tagName(.green)={s}，.green.hex()=0x{x:0>6}\n", .{ @tagName(c), c.hex() });
    // 枚举就是整数：字节视角里只有基整数值，没有 tag、没有指针
    const cbytes = std.mem.asBytes(&c);
    std.debug.print(".green 的字节={any}（首字节就是基整数值）\n", .{cbytes});
    // 反射枚举成员：field_values 元素是 comptime_int，只能 inline for
    inline for (@typeInfo(Color).@"enum".field_names, @typeInfo(Color).@"enum".field_values) |fname, fval| {
        std.debug.print("  {s} = {d}\n", .{ fname[0..fname.len], fval });
    }
    end("8.1");
```

运行输出（`examples/08_enums/main.zig`）：

```text
==== 8.1 开始 ====
Color 成员数=3 基整型=u2 @sizeOf=1 @bitSizeOf=2
@tagName(.green)=green，.green.hex()=0x00ff00
.green 的字节={ 1 }（首字节就是基整数值）
  red = 0
  green = 1
  blue = 2
==== 8.1 结束 ====
```

**① 枚举在内存里就是一个整数。** `.green 的字节={ 1 }` —— 没有 tag、没有 vtable、没有指针（对照 8.4 节的 union，那才有额外开销）。这就是 Zig 枚举能直接进协议报文的原因。`@sizeOf = 1` 但 `@bitSizeOf = 2`：内存只能按字节寻址，`u2` 剩下的 6 位是填充位（03 章 3.2 节）。

**② 不写基整型时编译器挑最小的能装下的类型。** `Color 基整型=u2`——3 个成员，2 位就够（0/1/2）。这和老教程说的"默认 int"完全不同：C 的枚举默认是 `int`（至少 4 字节），Zig 默认是**刚好够用的最小位宽**。所以 Zig 枚举天然适合做位域。

**③ 不写赋值时隐式从 0 开始递增**（`red = 0, green = 1, blue = 2`）。这个细节在 8.3 节会咬人—— `@fromBackingInt(@intCast(2))` 拿到的是 `blue` 而不是 `green`。

**④ 枚举能有方法，`switch` 在方法体里穷尽匹配成员**，少一个就编译错（8.5 节有完整报错）。枚举不是"只能当常量用"的标签，它是真正的类型：可以挂方法、可以声明、可以 comptime 反射。

**⑤ `.` 前缀**是枚举值字面量。目标类型明确时（`const c: Color = .green`）可以省略类型名，这个写法在现代 Zig 代码里满地都是。

⚠️ **`field_values` 的元素类型是 `comptime_int`，只能用 `inline for`**（03 章 3.8 节踩过）：普通 `for` 会报 `error: values of type 'comptime_int' must be comptime-known, but index value is runtime-known`。枚举成员值本质是编译期常量，运行期不存在。

## 8.2 显式基整型与非穷尽 `_`

```zig
// examples/08_enums/main.zig 第 28-44 行
/// 8.2 节：显式基整型 + 显式赋值（C 互操作），末位 `_` 声明非穷尽
const Level = enum(u8) {
    low = 10,
    mid = 50,
    high = 90,
    _, // 非穷尽：未声明的整数值也能装进来
};

/// 8.2 节用：非穷尽枚举的 switch 必须留else，否则漏了"其它值"的处理
fn levelName(lv: Level) []const u8 {
    return switch (lv) {
        .low => "低",
        .mid => "中",
        .high => "高",
        else => "未知", // 非穷尽 → 必须有 else
    };
}
```

```zig
// examples/08_enums/main.zig 第 154-157 行
/// 8.3 节用：让未知值来自运行期（编译期已知的话 @tagName 会被编译器拦下）
fn levelFromByte(n: u8) Level {
    return @fromBackingInt(n);
}
```

```zig
// examples/08_enums/main.zig 第 179-197 行
    // ═══ 8.2 基整型 + 非穷尽 `_` ═══
    begin("8.2");
    const lv: Level = @fromBackingInt(@intCast(50));
    std.debug.print("Level 基整型={s}，lv={s}({d})\n", .{ @typeName(@typeInfo(Level).@"enum".tag_type), @tagName(lv), @backingInt(lv) });
    const unknown = levelFromByte(42); // 42 不在声明里，但有 `_` 所以装得下
    std.debug.print("未知值 {d} 也装得下：{s}\n", .{ @backingInt(unknown), levelName(unknown) });
    // ⚠️ 对未知值取名字：值编译期已知 → 编译错
    //   @tagName(@fromBackingInt(@intCast(42)))
    //   → error: no field with value '@fromBackingInt(42)' in enum 'main.Level'
    // 值运行期才知道 → 运行期 panic：thread ... panic: invalid enum value
    //
    // 正确姿势：先switch 归类，再 @tagName
    const raws = [_]u8{ 10, 50, 90, 42 };
    for (raws) |raw| {
        const lv2 = levelFromByte(raw);
        // ⚠️ 非穷尽枚举的 switch 必须留 else，否则 42 那个值会让编译失败
        std.debug.print("  原始 {d:>3} → {s}（backing {d}）\n", .{ raw, levelName(lv2), @backingInt(lv2) });
    }
    end("8.2");
```

运行输出（`examples/08_enums/main.zig`）：

```text
==== 8.2 开始 ====
Level 基整型=u8，lv=mid(50)
未知值 42 也装得下：未知
  原始  10 → 低（backing 10）
  原始  50 → 中（backing 50）
  原始  90 → 高（backing 90）
  原始  42 → 未知（backing 42）
==== 8.2 结束 ====
```

`enum(u8)` 指定底层整数类型（和 C 枚举对接时关键），`low = 10` 这类显式赋值也照抄C 的习惯。**末位的 `_` 声明"非穷尽"**：允许任何未声明的整数值装进来。C 头文件里的枚举经常需要这样——上游加了新值，你的旧代码不该编译失败。

### 非穷尽枚举的代价：取不到名字

**这是本节最重要的一条实测结论。** 对一个装进了未知值的非穷尽枚举调`@tagName`，行为分两种：

| 值的来源 | 行为 | 实测信息 |
|---|---|---|
| **编译期已知** | **编译错误** | `error: no field with value '@fromBackingInt(42)' in enum 'main.Level'` |
| **运行期才知道** | **运行期 panic** | `thread 893476 panic: invalid enum value` |

为什么不一样？因为未知值本身就是"非法状态"，而Zig 的策略是**尽量在编译期抓**。`@tagName` 需要一个编译期就能确定的名字映射表，遇到 `@fromBackingInt(42)`（不是任何已声明成员）直接编译错；当值来自函数参数、编译器无法静态判断时，运行时才知道它是非法的，于是 panic。

⚠️ 注意这两种情况下**没有 `undefined` 标签**这回事——有些教程说"会返回 `undefined` 标签"，0.17 实测是**报错/panic**。正确姿势是先`switch` 归类：

```zig
const name = switch (lv) {   // 非穷尽枚举必须留 else
    .low => "低",
    .mid => "中",
    .high => "高",
    else => "未知",            // 这里就是处理"取不到名字"的地方
};
```

### 非穷尽枚举的 `switch` 必须有 `else`

漏掉 `else` 会被编译期拦下（因为可能存在未知值）：

```text
error: switch on non-exhaustive enum must include 'else' or '_' prong or both
```

反过来，**穷尽枚举加 `else` 是允许的**（实测无报错）——只是会吃掉"以后新增成员时的编译错误"。这是权衡不是bug：读外部输入用非穷尽 + `else`，内部状态机用穷尽 + 不加 `else`。

## 8.3 0.17 改名链：`@backingInt` / `@fromBackingInt` / `@enumFromInt`

**本章的核心。** 0.17 把枚举转换的三个内建函数全改名了，而且**有一个名字被回收给了语义不同的函数**：

| 旧（≤0.16） | 新（0.17） | 说明 |
|---|---|---|
| `@intFromEnum(x)` | `@backingInt(x)` | 枚举 → 整数 |
| `@intToEnum(E, n)` | `@enumFromInt(n)` | ⚠️ **名字被回收，语义不同** |
| — | `@fromBackingInt(n)` | 整数 → 枚举，要求精确基整型 |

```zig
// examples/08_enums/main.zig 第 199-218 行
    // ═══ 8.3 0.17 改名链：@backingInt / @fromBackingInt / @enumFromInt ═══
    begin("8.3");
    // ≤0.16 的 @intFromEnum → 0.17 的 @backingInt
    std.debug.print("@backingInt(.green)={d}（类型 {s}）\n", .{ @backingInt(c), @typeName(@TypeOf(@backingInt(c))) });
    // @fromBackingInt 要求操作数**恰好是基整型**，所以字面量要 @intCast
    const from_lit: Level = @fromBackingInt(50);
    const from_cast: Level = @fromBackingInt(@intCast(50));
    std.debug.print("@fromBackingInt(50)={s}；@fromBackingInt(@intCast(50))={s}\n", .{ @tagName(from_lit), @tagName(from_cast) });
    // ⚠️ 传 u16 给 @fromBackingInt 编译错：expected type 'u8', found 'u16'
    // ⚠️ 而 0.17 的 @enumFromInt 接受任意整数宽度（它做的是 @intCast 语义）。
    // 下面这行就是"@enumFromInt(@as(u16, 2))"经 zig fmt 自动迁移后的等价写法——
    // 源码里不能直接写 @enumFromInt，否则 fmt --check 不过（见 8.3 节正文）。
    const widened: Color = @fromBackingInt(@intCast(@as(u16, 2)));
    std.debug.print("@enumFromInt(@as(u16, 2)) 等价写法 = {s}（原本接受非基整型）\n", .{@tagName(widened)});
    // ⚠️ 名字被回收：0.17 里 @enumFromInt 是合法名字但语义不同于老教程。
    // 老教程 @intToEnum(E, n) → 0.17 直接 @enumFromInt(n)（照抄会编译错：
    //   error: invalid builtin function: '@intToEnum'）
    //
    // zig fmt 会自动迁移前两处：@intFromEnum(x) → @backingInt(x)，
    // @enumFromInt(n) → @fromBackingInt(@intCast(n))。
```

运行输出（`examples/08_enums/main.zig`）：

```text
==== 8.3 开始 ====
@backingInt(.green)=1（类型 u2）
@fromBackingInt(50)=mid；@fromBackingInt(@intCast(50))=mid
@enumFromInt(@as(u16, 2)) 等价写法 = blue（原本接受非基整型）
builtin.mode=lang.Optimize
==== 8.3 结束 ====
```

### 易错点一：`@enumFromInt` 是合法名字，但语义不同

这是最容易踩的一条。老教程写`const c: Color = @intToEnum(Color, 50);`，两种迁法在新版本里**都能编译**，但含义变了：

**迁法 A（老名字直接删掉类型参数）**：`@enumFromInt(50)`
实测 0.17 里**编译通过、运行正确**。`@intFromEnum` 也仍能编译通过。但它们已经是**遗留别名**，官方推荐用新名字。

**迁法 B（照抄 `@intToEnum`）**：直接编译错
```text
error: invalid builtin function: '@intToEnum'
```

⚠️ **`@enumFromInt` 与 `@fromBackingInt` 语义不同，别混用**。实测区别在**接受的操作数宽度**上：

| | `@fromBackingInt` | `@enumFromInt` |
|---|---|---|
| 传 `u8`（Color 是 `enum(u8)`） | ✅ | ✅ |
| 传 `u16` / `u32` | ❌ 编译错 | ✅ |
| 内部语义 | 要求**恰好**是基整型 | `@intCast` 语义，任意整数宽度 |

`@fromBackingInt` 传 `u16` 的报错：
```text
error: expected type 'u8', found 'u16'
note: unsigned 8-bit int cannot represent all possible unsigned 16-bit values
```

**所以本章示例源码里写不出裸的 `@enumFromInt`** ——因为 `zig fmt` 会把它改写掉（见下）。

### 易错点二：`zig fmt` 会自动迁移前两处

实测把 `@intFromEnum(x)` / `@enumFromInt(n)` 放进文件跑 `zig fmt`，会被**自动改写**：

```text
// fmt 前
const n: u8 = @intFromEnum(c);
const c2: Color = @enumFromInt(@as(u8, 1));

// zig fmt 之后
const n: u8 = @backingInt(c);
const c2: Color = @fromBackingInt(@intCast(@as(u8, 1)));
```

**这就是为什么本章示例里 8.3 节那行写成了"等价写法"**：`run-all.sh` 第一层就是 `zig fmt --check .`，源码里只要留着 `@enumFromInt`，fmt 就会想改它，`--check` 立刻失败。这个坑很隐蔽——`zig test` 可能都过，只有 fmt 层拦你。

### 易错点三：`zig fmt` 不改枚举取值

`@intFromEnum` → `@backingInt` 这种**内建函数名**fmt 知道怎么迁移，但 `builtin.mode == .Debug` 这种**枚举成员名**它不管。实测：

```text
error: no field named 'Debug' in enum 'lang.Optimize'
note: enum declared here
pub const Optimize = enum {
```

0.17 把 `std.builtin.Optimize` 的成员改成了**全小写**：`.debug` / `.safe` / `.fast` / `.small`。这一条要自己手工改（或者干脆别用 `builtin.mode`）。

### 三条迁法的对照总结

| 你写的（≤0.16） | 0.17 编译 | 0.17 推荐写法 | fmt 自动改？ |
|---|---|---|---|
| `@intFromEnum(e)` | ✅（遗留别名） | `@backingInt(e)` | ✅ 会改成新写法 |
| `@intToEnum(E, n)` | ❌ 已删除 | `@fromBackingInt(@intCast(n))` | ❌ 不改，要手工 |
| `@enumFromInt(n)` | ✅（遗留别名） | `@fromBackingInt(@intCast(n))` | ✅ 会改成新写法 |
| `builtin.mode == .Debug` | ❌ 成员改名 | `.debug` | ❌ 不改，要手工 |

## 8.4 tagged union：安全的多选一，以及布局实测

`union(enum)` 语法在 0.17 **仍然存在**（实测确认）。这是 Zig 的代数数据类型：C的裸union读错字段是未定义行为，Zig 的 tagged union 加上标签保护。

```zig
// examples/08_enums/main.zig 第 46-66 行
/// 8.3 节的 tagged union（`union(enum)` 在 0.17 仍然可用）
const Value = union(enum) {
    int: i64,
    text: []const u8,
    list: []const f64,

    fn kind(self: Value) []const u8 {
        return switch (self) {
            .int => "整数",
            .text => "文本",
            .list => "列表",
        };
    }
};

/// 8.4 节用：`union(显式标签枚举)` 语法也还在，标签类型由你指定
const Payload = union(enum) {
    none,
    small: u8,
    big: []const u8,
};
```

```zig
// examples/08_enums/main.zig 第 223-243 行
    // ═══ 8.4 tagged union：安全的多选一 + 布局实测 ═══
    begin("8.4");
    std.debug.print("Value sizeOf={d} alignOf={d}，字段数={d}\n", .{ @sizeOf(Value), @alignOf(Value), @typeInfo(Value).@"union".field_names.len });
    const vtag = @typeInfo(Value).@"union".tag_type.?;
    std.debug.print("标签类型={s}，占 {d} 位\n", .{ @typeName(vtag), @bitSizeOf(vtag) });
    // 布局是"tag + 最大负载"再按对齐补齐，不是"指针 + tag"
    const Small = union(enum) { a: u8, b: u32, c: u64 };
    std.debug.print("{{a:u8,b:u32,c:u64}} sizeOf={d} alignOf={d}（u64=8，tag 的 2 位塞进尾部 padding）\n", .{ @sizeOf(Small), @alignOf(Small) });
    const WithSlice = union(enum) { s: []const u8, n: usize };
    std.debug.print("{{s:[]const u8,n:usize}} sizeOf={d}（16 负载 + tag，按对齐补到 8 的倍数）\n", .{@sizeOf(WithSlice)});
    // 裸 union 没有标签类型
    const Raw = union { a: u8, b: u16 };
    if (@typeInfo(Raw).@"union".tag_type) |t| {
        std.debug.print("Raw tag_type={s}\n", .{@typeName(t)});
    } else {
        std.debug.print("裸 union 的 tag_type=null（读错字段没人拦）\n", .{});
    }
    // union(显式标签枚举) 语法也还在
    const p_none: Payload = .{ .none = {} };
    std.debug.print("Payload(.none) 的 tag名={s}，sizeOf={d}\n", .{ @tagName(p_none), @sizeOf(Payload) });
    const p_small: Payload = .{ .small = 200 };
```

运行输出（`examples/08_enums/main.zig`）：

```text
==== 8.4 开始 ====
Value sizeOf=24 alignOf=8，字段数=3
标签类型=@typeInfo(main.Value).@"union".tag_type.?，占 2 位
{a:u8,b:u32,c:u64} sizeOf=16 alignOf=8（u64=8，tag 的 2 位塞进尾部 padding）
{s:[]const u8,n:usize} sizeOf=24（16 负载 + tag，按对齐补到 8 的倍数）
裸 union 的 tag_type=null（读错字段没人拦）
Payload(.none) 的 tag名=none，sizeOf=24
Payload(.small=200) tag名=small
==== 8.4 结束 ====
```

### 联合体布局：**tag + 最大负载**，不是"指针 + tag"

这是本章要求实测的重点，结论很明确：

| 类型 | `@sizeOf` | `@alignOf` | 布局解释 |
|---|---|---|---|
| `Value{int:i64, text:[]const u8, list:[]const f64}` | **24** | 8 | 最大负载是切片 16 字节 + tag → 按 8 对齐补到 24 |
| `{a:u8, b:u32, c:u64}` | **16** | 8 | 最大负载 u64 = 8 字节，tag 的 2 位塞进尾部 padding，**总size 仍是 8+8=16** |
| `{s:[]const u8, n:usize}` | **24** | 8 | 负载 16 + tag，按对齐补到 24（8的倍数） |
| `{a:u8, b:u16}`（`union(enum)`） | **4** | 2 | 负载 u16 = 2 字节（对齐 2），tag 塞 padding → 和裸 union 一样大 |
| 裸`union{a:u8, b:u16}` | **4** | 2 | 同上但**没有 tag** |

**要点：**

1. **不是"指针 + tag"。** 有些教程说 tagged union 会退化成"指针 + 标签"（类似 Rust 的 niche优化或 C++ 的 `variant`），但 Zig **不是**。`{a:u8,b:u32,c:u64}` 的size 是 **16**，不是 8（tag）+ 8（最大负载），因为 tag 完全藏进了 u64 后面padding 的空隙里。

2. **tag 是编译器自动生成的匿名enum**，位宽按形态数取最小值。`Value` 3 个形态 → tag 占 **2 位**（`@typeInfo(Value).@"union".tag_type.?`）。

3. ⚠️ **`@typeName` 打印 tag 类型会泄露内部表示**：输出是 `@typeInfo(main.Value).@"union".tag_type.?` —— 这是编译器生成的匿名类型，没有人类可读的名字。别指望能打印它，只能打印 `@tagName(值)`（8.5 节）。

4. **`payload: void` 的形态（如 `bye`）不占负载空间**，只贡献 tag 的一位。

### 裸 union vs tagged union

`union { a: u8, b: u16 }` 是**裸 union**，`@typeInfo(...).@"union".tag_type` 是 `null`（可空！），读错字段编译器不拦——这就是 C 风格 union 的全部风险。实测输出那行`裸 union 的 tag_type=null（读错字段没人拦）`。

⚠️ **`tag_type` 是可空类型 `?type`**，直接写 `.?` 在运行期会 panic（`attempt to use null value`），必须 `if (x) |t|` 或 `.?`。

### `union(enum)` 语法确认

**实测确认 `union(enum)` 和 `union(显式标签枚举)` 在 0.17 都存在**。后者让你自己指定标签类型（用于自定义 tag 编号、或共享一个已有枚举）：

```zig
const Tag = enum { alpha, beta, gamma };
const Tagged = union(Tag) { alpha: u8, beta: []const u8, gamma: f64 };
```

实测结果：`@tagName(union值)` 返回标签名（`.alpha` → `"alpha"`），`@sizeOf(Tagged) = 24`，且 `@typeInfo(Tagged).@"union".tag_type.?` 打印为 **`v2.Tag`**（有可读名字）——这和 `union(enum)` 的匿名 tag 形成对比。`Payload(.none)` 那行也验证了 `payload: void` 的形态能正常初始化为 `.{ .none = {} }`。

## 8.5 `switch` 穷尽性：漏一种形态就是编译错

这是 union 相比 C 裸union 最大的价值：**编译器强制你处理所有可能**。

```zig
// examples/08_enums/main.zig 第 247-265 行
    // ═══ 8.5 switch 捕获负载：tagged union 的正确打开方式 ═══
    begin("8.5");
    const w: Value = .{ .list = &.{ 1.5, 2.5, 3.5 } };
    // 联合体的 switch 必须处理每一种可能，漏一种就是编译错：
    //   error: switch must handle all possibilities
    //   note: unhandled enumeration value: 'text'
    switch (w) {
        .int => |i| std.debug.print("整数 {d}\n", .{i}),
        .text => |t| std.debug.print("文本 {s}\n", .{t}),
        .list => |ls| std.debug.print("列表 {d} 项，首项 {d:.1}\n", .{ ls.len, ls[0] }),
    }
    // 换形态就是整体换值
    var val: Value = .{ .int = 42 };
    std.debug.print("kind={s}\n", .{val.kind()});
    val = .{ .text = "hi" };
    std.debug.print("kind={s}，取值 {s}\n", .{ val.kind(), val.text });
    // 读错激活字段：标签是编译期已知 → 直接编译错（不是运行期panic！）
    //   v.int 其中 v = Value{ .text = "hi" }
    //   → error: access of union field 'int' while field 'text' is active
```

运行输出（`examples/08_enums/main.zig`）：

```text
==== 8.5 开始 ====
列表 3 项，首项 1.5
kind=整数
kind=文本，取值 hi
==== 8.5 结束 ====
```

### 穷尽性检查的报错（实测）

**枚举漏一个成员**：

```text
error: switch must handle all possibilities
note: unhandled enumeration value: 'blue'
note: enum 'main.Color' declared here
```

**tagged union 漏一个形态**（报的是**内部 tag 枚举**的名字）：

```text
error: switch must handle all possibilities
note: unhandled enumeration value: 'list'
note: enum '@typeInfo(main.Value).@"union".tag_type.?' declared here
```

注意 union 的报错里那个`@typeInfo(...).tag_type.?` ——再次印证了 tag 是匿名生成类型。

### `|载荷|` 捕获：拿到当前激活字段的值

`.list => |ls|` 里的 `ls` **只在对应形态下存在**，类型自动是该字段的类型。这就是"模式匹配"：编译器保证你拿到的 `ls` 一定是 `[]const f64`，不会是别的。

**改负载**用 `|*x|` 捕获指针（如 `.coords => |*c| c.x += 1;`）。不捕获也可以直接写 `.list => std.debug.print("...", .{w.list.len})`——union 值可按字段名访问（但只在 `switch` 的对应分支内安全）。

### ⚠️ 读错激活字段：**0.17 默认编译错**

老教程说"读错字段 → Debug/ReleaseSafe 下 panic"。**0.17 实测更严格**：

| 标签来源 | 行为 | 实测信息 |
|---|---|---|
| **编译期已知**（如直接写 `const v: Value = .{ .text = "hi" }; v.int`） | **编译错误** | `error: access of union field 'int' while field 'text' is active` |
| **运行期才知道**（来自函数参数） | **运行期 panic** | `thread 904993 panic: access of union field 'int' while field 'text' is active` |

两种情况**错误/panic 文案完全一样**。0.17 的策略：标签静态可知时直接在编译期拦，运行期才 panic。**这比老教程说的"Debug 下 panic"更强——ReleaseSafe 下如果标签来自外部数据（比如网络包解码），依然会 panic。**

## 8.6 `packed struct`：位域与位模式

`packed struct` 让字段按位紧凑排列，是 03 章 3.2 节那个"`u3` 占1 字节但只有 3 位"的正解。

```zig
// examples/08_enums/main.zig 第 68-80 行
/// 8.5 节的位域：1 + 1 + 6 = 8 位，正好一个字节
const Flags = packed struct {
    bold: bool = false, // 1 bit，占 bit0
    italic: bool = false, // 1 bit，占 bit1
    size: u6 = 0, // 6 bits，占 bit2..bit7
};

/// 8.6 节用：跨字段的位模式（硬件寄存器画像）
const Reg = packed struct {
    a: u4, // bit0..bit3
    b: u4, // bit4..bit7
    c: u8, // bit8..bit15
};
```

```zig
// examples/08_enums/main.zig 第 269-289 行
    // ═══ 8.6 packed struct：精确到位 ═══
    begin("8.6");
    std.debug.print("Flags sizeOf={d} bitSizeOf={d}（1+1+6=8 位，装进 1 字节）\n", .{ @sizeOf(Flags), @bitSizeOf(Flags) });
    const f = Flags{ .bold = true, .size = 12 };
    const bits: u8 = @bitCast(f); // packed struct 是 @bitCast 唯一能吃的结构体
    std.debug.print("Flags{{bold=true,size=12}} → 0b{b:0>8}（bold=bit0，size=bit2..7）\n", .{bits});
    // 反向：整数造packed struct
    const from_int: Flags = @bitCast(@as(u8, 0b0011_0001));
    std.debug.print("0b00110001 反解：bold={} italic={} size={d}\n", .{ from_int.bold, from_int.italic, from_int.size });
    // 全1 验证位顺序
    const all1: u8 = @bitCast(Flags{ .bold = true, .italic = true, .size = 0b111111 });
    std.debug.print("bold+italic+size=63 → 0b{b:0>8}\n", .{all1});
    // packed struct 里的 enum 字段按 bitSizeOf 算位
    const Mode = enum(u2) { off, on };
    const Ctl = packed struct { en: bool, mode: Mode, level: u5 };
    std.debug.print("Ctl bitSizeOf={d}（bool 1 位 + enum(u2) 2 位 + u5 = 8）\n", .{@bitSizeOf(Ctl)});
    const ctl: Ctl = .{ .en = true, .mode = .on, .level = 3 };
    std.debug.print("Ctl{{en=true,mode=on,level=3}} → 0x{x:0>2}\n", .{@as(u8, @bitCast(ctl))});
    // ⚠️ packed struct 不能放指针
    //   packed struct { ptr: *const u8 }
    //   → error: packed structs cannot contain fields of type '*const u8'
```

运行输出（`examples/08_enums/main.zig`）：

```text
==== 8.6 开始 ====
Flags sizeOf=1 bitSizeOf=8（1+1+6=8 位，装进 1 字节）
Flags{bold=true,size=12} → 0b00110001（bold=bit0，size=bit2..7）
0b00110001 反解：bold=true italic=false size=12
bold+italic+size=63 → 0b11111111
Ctl bitSizeOf=8（bool 1 位 + enum(u2) 2 位 + u5 = 8）
Ctl{en=true,mode=on,level=3} → 0x1b
==== 8.6 结束 ====
```

**① 位顺序：第一个字段在最低位。** `Flags{bold=true, size=12}` → `0b0011_0001`。`bold` 占 bit0（=1），`italic` 占 bit1（=0），`size` 占 bit2..bit7（=`0b001100`=12）。全1 的`Flags{bold,italic,size=63}` → `0b11111111`，确认无空隙。

**② packed struct 是 `@bitCast` 唯一能吃的结构体。** 03 章 3.7 节实测`@bitCast` 拒绝裸结构体（连 `extern struct` 也不行，报 `cannot @bitCast from 'main.Header'`）——**但 `packed struct` 是唯一例外**。这是因为 packed struct 保证 `@sizeOf` 等于 `@bitSizeOf`（无padding），位模式完全确定，`@bitCast` 有唯一正确答案。

双向都行：`@bitCast(f)` 得整数，`@bitCast(@as(u8, 0b00110001))` 得结构体。**做协议头/寄存器读写这就是标准姿势。**

**③ packed struct 里的 `enum` 字段按 `@bitSizeOf` 占位。** `Ctl{en:bool, mode:enum(u2), level:u5}` → 总共 1+2+5 = 8 位，`bitSizeOf = 8`。`enum(u2)` 就占 2 位，和写`u2` 完全一样。

**④ `@offsetOf` 对 packed struct 恒为 0**（8.8 节实测）——packed 没有字节偏移的概念，字段是按位而非按字节寻址的。所以别用 `@offsetOf` 去算packed struct 的字段位置，用 `@bitCast` 整块处理。

⚠️ **packed struct 不能放指针**（实测）：
```text
error: packed structs cannot contain fields of type '*const u8'
note: pointers cannot be directly bitpacked
note: consider using 'usize' and '@intFromPtr'
```
理由很直白——指针是 64 位"数值"但没有紧凑的位表示。要存指针就用 `usize` + `@intFromPtr`。

⚠️ **packed struct 里的嵌套 struct 必须也是 packed**（8.7 节实测踩到）：`packed union` 里放普通 `struct { hi: u8, lo: u8 }` 会报 `packed unions cannot contain fields of type '...struct'` + `note: non-packed structs do not have a bit-packed representation`。

## 8.7 `packed union` 与位操作

`packed union` 是"同一块位，不同视角"。0.17 里它的规则比一般 union 更严。

```zig
// examples/08_enums/main.zig 第 82-87 行
/// 8.7 节用：packed union 的所有字段**位宽必须相同**（u16 与 packed struct{u8,u8} 都是 16 位）
const Pair = packed struct { hi: u8, lo: u8 };
const Word = packed union {
    bits: u16,
    pair: Pair,
};
```

```zig
// examples/08_enums/main.zig 第 293-316 行
    // ═══ 8.7 packed union 与位运算 ═══
    begin("8.7");
    std.debug.print("Word sizeOf={d} bitSizeOf={d} alignOf={d}（u16 与 packed struct{{hi,lo}} 都是 16 位）\n", .{ @sizeOf(Word), @bitSizeOf(Word), @alignOf(Word) });
    // ⚠️ packed union 的所有字段位宽必须相同，否则编译错：
    //   packed union { a: u8, b: u16 }
    //   → error: field bit width does not match earlier field
    //     note: all fields in a packed union must have the same bit width
    const wv: Word = .{ .bits = 0xBEEF };
    std.debug.print("Word{{.bits=0xBEEF}} @bitCast 回 u16 = 0x{x:0>4}\n", .{@as(u16, @bitCast(wv))});
    const wp: Word = .{ .pair = .{ .hi = 0xBE, .lo = 0xEF } };
    std.debug.print("换成 .pair 视角bits = 0x{x:0>4}（hi 在高字节）\n", .{wp.bits});
    // extern union 对照：按对齐走，不是按位
    const EU = extern union { a: u8, b: u16 };
    std.debug.print("extern union sizeOf={d} alignOf={d}（对齐到 2 字节）\n", .{ @sizeOf(EU), @alignOf(EU) });
    // 位操作家族
    std.debug.print("popCount(0xF0F0)={d}；0b1011<<2={b:0>6}；@ctz(0b1000_0000)={d}\n", .{
        @popCount(@as(u16, 0xF0F0)),
        @as(u8, 0b1011) << 2,
        @ctz(@as(u8, 0b1000_0000)),
    });
    // 用位运算直接从 packed struct 读写单个字段（不@bitCast 整块）
    var rf = Flags{ .size = 0 };
    rf.italic = true;
    rf.size = @truncate(@as(u16, 0b11_0001) >> 2); // 手工算：借 u16 中转再截断
```

运行输出（`examples/08_enums/main.zig`）：

```text
==== 8.7 开始 ====
Word sizeOf=2 bitSizeOf=16 alignOf=2（u16 与 packed struct{hi,lo} 都是 16 位）
Word{.bits=0xBEEF} @bitCast 回 u16 = 0xbeef
换成 .pair 视角bits = 0xefbe（hi 在高字节）
extern union sizeOf=2 alignOf=2（对齐到 2 字节）
popCount(0xF0F0)=8；0b1011<<2=101100；@ctz(0b1000_0000)=7
手工位运算：italic=true size=12 → 0x32
==== 8.7 结束 ====
```

### ⚠️ `packed union` 所有字段位宽必须相同

这是本章新踩到的坑，实测报错：

```text
error: field bit width does not match earlier field
note: field type 'u16' has bit width '16'
note: other field type 'u8' has bit width '8'
note: all fields in a packed union must have the same bit width
```

所以 `packed union { a: u8, b: u16 }` **是非法的**。本节用 `Word` 举例：`bits: u16`（16 位）和 `pair: Pair`（`packed struct {hi:u8, lo:u8}`，也是 16 位）位宽相同，合法。

⚠️ **字段不能用数组**：`packed union { bytes: [2]u8, half: u16 }` 报 `packed unions cannot contain fields of type '[2]u8'` + `note: type does not have a bit-packed representation`。**数组没有位表示**——要表达"两个字节的视角"得用 packed struct（见上面的 `Pair`）。

### packed union 的位宽是精确匹配的

`Word` 的 `@sizeOf = @bitSizeOf = 2`，所以 `@bitCast(Word)` ↔ `u16` 双向都行。换成 `u8` 就报：
```text
error: @bitCast size mismatch: destination type 'Word' has 8 bits but source type 'u16' has 16 bits
```

`wp.bits = 0xefbe` 说明 `.pair` 视角下`hi` 在**高字节**（小端序：低地址存低字节，但 `hi: u8` 是 pair 的第一个字段，占 packed struct 的 bit8..15）。

### ⚠️ 一次只能初始化一个字段

```zig
.{ .hi = 0xBE, .lo = 0xEF }   // ❌ error: cannot initialize multiple union fields at once;
                              //      unions can only have one active field
```

tagged union 和裸 union 都一样——初始化就是"声明哪个形态是激活的"，同时给两个字段等于同时声明两个激活形态，逻辑上自相矛盾。要设置多个字段，得先初始化一个再逐个赋值。

### 位操作家族

0.17 没有 `**` 幂运算符（03 章），位操作用移位和 `@popCount` / `@ctz` / `@clz` / `@bitSizeOf`：

- `@popCount(x)`：二进制里1 的个数
- `@ctz(x)`：trailing zeros，末尾连续0 的个数（`@ctz(0b1000_0000) = 7`）
- `@clz(x)`：leading zeros
- `@bitSizeOf(T)`：类型占几位

手工位运算那行演示了不用 `@bitCast` 整块、直接操作单字段的写法：`@truncate(@as(u16, 0b11_0001) >> 2)` 把 16 位模式移位后截断成 `u6`。

## 8.8 跨字节位域：`Reg` 与 `@offsetOf` 的陷阱

```zig
// examples/08_enums/main.zig 第 320-326 行
    // ═══ 8.8 Reg：跨字节的位域 ═══
    begin("8.8");
    std.debug.print("Reg sizeOf={d} bitSizeOf={d}\n", .{ @sizeOf(Reg), @bitSizeOf(Reg) });
    const r = Reg{ .a = 0xF, .b = 0x1, .c = 0x23 };
    const rb: u16 = @bitCast(r);
    std.debug.print("Reg{{a=0xF,b=0x1,c=0x23}} → 0x{x:0>4}（a 在 bit0-3，b 在 bit4-7，c 在高字节）\n", .{rb});
    // @offsetOf 对 packed struct 恒为 0（没有字节偏移概念）
```

运行输出（`examples/08_enums/main.zig`）：

```text
==== 8.8 开始 ====
Reg sizeOf=2 bitSizeOf=16
Reg{a=0xF,b=0x1,c=0x23} → 0x231f（a 在 bit0-3，b 在 bit4-7，c 在高字节）
@offsetOf(Flags, "size")=0（packed 没有字节偏移）
==== 8.8 结束 ====
```

`Reg{a=0xF, b=0x1, c=0x23}` → `0x231F`：`a`(0xF) 在 bit0-3 → `0x000F`，`b`(0x1) 在 bit4-7 → `0x0010`，`c`(0x23) 在高字节 → `0x2300`。合起来 `0x231F`。**位序严格按声明顺序从低到高**，跨字节边界也连续。

⚠️ **`@offsetOf` 对 packed struct 恒为 0**。别用它算 packed struct 的字段位置——packed 是按位寻址的，没有字节偏移这概念。要操作位，用 `@bitCast` 整块进出，或直接读字段名。

## 8.9 用union 表达"消息"（对接 30 章协议解析）

这是union 最有价值的用法：**一条消息可能是若干种形态之一**。和 30 章 HTTP 解析同构。

```zig
// examples/08_enums/main.zig 第 89-152 行
/// 8.9 节用：把 union 变成一条协议消息（30 章 HTTP 解析同构）
const Message = union(enum) {
    ping: u64,
    text: []const u8,
    coords: struct { x: i32, y: i32 },
    bye: void,

    /// 编码：每种形态自己决定字节布局
    fn encode(self: Message, buf: []u8) EncodeError!usize {
        switch (self) {
            .ping => |v| {
                if (buf.len < 9) return error.NoSpace;
                buf[0] = 1;
                std.mem.writeInt(u64, buf[1..9], v, .big); // 网络字节序，一律大端
                return 9;
            },
            .text => |s| {
                if (buf.len < 1 + s.len) return error.NoSpace;
                buf[0] = 2;
                @memcpy(buf[1 .. 1 + s.len], s);
                return 1 + s.len;
            },
            .coords => |c| {
                if (buf.len < 9) return error.NoSpace;
                buf[0] = 3;
                std.mem.writeInt(i32, buf[1..5], c.x, .big);
                std.mem.writeInt(i32, buf[5..9], c.y, .big);
                return 9;
            },
            .bye => {
                buf[0] = 4;
                return 1;
            },
        }
    }

    /// 解码：tag 是整数，用普通 switch 分派；这里靠 union 的穷尽性兜底
    fn decode(buf: []const u8) DecodeError!Message {
        if (buf.len < 1) return error.Empty;
        return switch (buf[0]) {
            1 => if (buf.len < 9) error.Short else Message{ .ping = std.mem.readInt(u64, buf[1..9], .big) },
            2 => Message{ .text = buf[1..] },
            3 => if (buf.len < 9) error.Short else Message{ .coords = .{
                .x = std.mem.readInt(i32, buf[1..5], .big),
                .y = std.mem.readInt(i32, buf[5..9], .big),
            } },
            4 => Message{ .bye = {} },
            else => error.UnknownTag,
        };
    }

    /// 打印也写成一次穷尽匹配——漏一种形态编译器会拦
    fn label(self: Message) []const u8 {
        return switch (self) {
            .ping => "ping",
            .text => "text",
            .coords => "coords",
            .bye => "bye",
        };
    }
};

const EncodeError = error{NoSpace};
const DecodeError = error{ Empty, Short, UnknownTag };
```

```zig
// examples/08_enums/main.zig 第 330-360 行
    // ═══ 8.9 用union 表达"消息" ═══
    begin("8.9");
    var buf: [32]u8 = undefined;
    const outbox = [_]Message{
        .{ .ping = 0xDEADBEEF },
        .{ .text = "hello" },
        .{ .coords = .{ .x = -3, .y = 42 } },
        .{ .bye = {} },
    };
    for (outbox) |m| {
        const n = try m.encode(&buf);
        std.debug.print("编码 {s} → {d} 字节 {any}\n", .{ m.label(), n, buf[0..n] });
        const back = try Message.decode(buf[0..n]);
        // 解码回来还是同一个 union，形态一致
        std.debug.print("  解码 → {s}", .{back.label()});
        switch (back) {
            .ping => |v| std.debug.print("（{d}）", .{v}),
            .text => |t| std.debug.print("（{s}）", .{t}),
            .coords => |xy| std.debug.print("（{d},{d}）", .{ xy.x, xy.y }),
            .bye => std.debug.print("（无负载）", .{}),
        }
        std.debug.print("\n", .{});
    }
    // 未知 tag：解码函数自己返回 error.UnknownTag（错误联合，不是 panic）
    // ⚠️ 这里必须写 &.{99}：数组字面量要 coerce 成切片得加 &，
    //    `zig test` 能过但 `zig build-exe` 会报 array literal requires address-of operator
    const bad_tag = Message.decode(&.{99});
    if (bad_tag) |m| {
        std.debug.print("喂一个未知 tag 99 → 意外解出 {s}\n", .{m.label()});
    } else |e| {
        std.debug.print("喂一个未知 tag 99 → {s}（错误联合，不是 panic）\n", .{@errorName(e)});
```

运行输出（`examples/08_enums/main.zig`）：

```text
==== 8.9 开始 ====
编码 ping → 9 字节 { 1, 0, 0, 0, 0, 222, 173, 190, 239 }
  解码 → ping（3735928559）
编码 text → 6 字节 { 2, 104, 101, 108, 108, 111 }
  解码 → text（hello）
编码 coords → 9 字节 { 3, 255, 255, 255, 253, 0, 0, 0, 42 }
  解码 → coords（-3,42）
编码 bye → 1 字节 { 4 }
  解码 → bye（无负载）
喂一个未知 tag 99 → UnknownTag（错误联合，不是 panic）
==== 8.9 结束 ====
```

**这个模式为什么好**：每种消息形态自己知道怎么编码/解码（`encode`/`decode`），tag 的编号（1/2/3/4）由你在 `encode` 里显式写进第一个字节。`decode` 把外部字节流还原成 union，调用方用 `switch` 穷尽处理——**漏一种形态编译器拦你**。这就是 30 章 HTTP/二进制协议解析的骨架。

`coords` 的编码 `x=-3` 是 `{ 255, 255, 255, 253 }`——`i32` 补码 + 大端，这就是 `std.mem.writeInt(..., .big)` 的作用。**协议字节序没有默认值，Zig 不替你猜**（03 章 3.7 节）。

`bye: void` 只占 1 字节（就是 tag 本身）——**无负载形态零开销**。

未知 tag（99）走错误联合返回 `error.UnknownTag`（输出 `UnknownTag`），**不是 panic**。这是设计选择：外部输入不可信时，返回错误让上层决定怎么处理，而不是让整个程序崩。⚠️ 8.10 节讲这个错误联合到底是什么类型。

## 8.10 union 与错误联合 `!T` 的关系

⚠️ **0.17 的大变化：`||` 不再是"造错误联合"，而是"错误集并集"。**

老教程（≤0.16）写 `MyError || Payload` 来造错误联合类型。0.17 实测**编译失败**：

```text
error: expected error set type, found 'main.Value'
note: union declared here
```

因为 `||` 现在**两边都必须是错误集**，只做集合并集。造错误联合要用 `E!T` 语法（感叹号，注意和 `!u32` 的 `anyerror` 区别）：

```zig
// examples/08_enums/main.zig 第 364-376 行
    // ═══ 8.10 union 与错误联合 !T 的关系 ═══
    begin("8.10");
    // ⚠️ 0.17 的大变化：`||` 变成**错误集并集**运算，不再是"造错误联合"。
    //   error{A} || Val(union) → error: expected error set type, found 'main.Val'
    // 造错误联合要用 `E!T` 语法：
    const MyErr = error{ Oops, Bad };
    std.debug.print("MyErr || error{{Boom}} = {s}（集合并集）\n", .{@typeName(MyErr || error{Boom})});
    std.debug.print("MyErr!i64 = {s}（错误联合类型）\n", .{@typeName(MyErr!i64)});
    std.debug.print("anyerror!Value = {s}（错误联合的 payload 可以是 union）\n", .{@typeName(anyerror!Value)});
    std.debug.print("anyerror!?Value = {s}（? 在外、! 在内，sizeOf={d}）\n", .{ @typeName(anyerror!?Value), @sizeOf(anyerror!?Value) });
    const ei = @typeInfo(MyErr!i64);
    std.debug.print("error_union 分支：error_set={s} payload={s}\n", .{ @typeName(ei.error_union.error_set), @typeName(ei.error_union.payload) });
    // 区别：tagged union 用**类型系统**穷尽；错误联合运行时才决定是值还是错误
```

运行输出（`examples/08_enums/main.zig`）：

```text
==== 8.10 开始 ====
MyErr || error{Boom} = error{Bad,Boom,Oops}（集合并集）
MyErr!i64 = error{Bad,Oops}!i64（错误联合类型）
anyerror!Value = anyerror!main.Value（错误联合的 payload 可以是 union）
anyerror!?Value = anyerror!?main.Value（? 在外、! 在内，sizeOf=40）
error_union 分支：error_set=error{Bad,Oops} payload=i64
Value 是 24 字节，MyErr!Value 是 32 字节（多了错误通道）
==== 8.10 结束 ====
```

### 两种"多选一"的本质区别

| | tagged union（`union(enum)`） | 错误联合（`E!T`） |
|---|---|---|
| 形态数 | **编译期固定**（声明了几个就是几个） | **2 种**：值 / 错误 |
| 谁决定 | 写代码的人（编译期） | 运行期（数据/环境） |
| 怎么匹配 | `switch`，**编译器强制穷尽** | `if (x) |v|` / `else |e|`，漏了也能编 |
| 错误信息 | 无（匹配完整才编译过） | 有：读哪一半由你选 |
| 内存 | tag + 最大负载 | 错误集 + payload（多出判别位） |

**关键差异**：tagged union 的形态集合是**类型的一部分**（编译期就知道，永远不会变）；错误联合永远是"要么值要么错误"这 2 种，**运行期才决定**。所以 8.9 节的 `decode` 返回 `DecodeError!Message`——外层是错误联合（可能失败），内层 `Message` 是 tagged union（成功后是 4 种形态之一）。

`MyErr!Value` 是 32 字节 vs `Value` 24 字节——多出的 8 字节是"这是值还是错误"的判别位 + 对齐。**错误联合比裸 payload 大**，因为要额外空间标记成功/失败。

`anyerror!?Value` 是在错误联合外套了个可选（`?` 在外、`!` 在内），size 40。

### `@typeInfo` 的 error_union 分支

```zig
const ei = @typeInfo(MyErr!i64);
ei.error_union.error_set;  // error{Bad,Oops} —— 错误集类型
ei.error_union.payload;    // i64 —— payload 类型
```

⚠️ `error_set` 是**错误集类型**不是切片，**`payload` 是 `type`**（编译期实体）。要遍历错误名得用 `.error_set.error_names`（可空，见 03 章 3.8 节）。

### 测试：把语义钉住

本章行为全靠测试守着（`main.zig` 第 383-520 行，9 个 `test` 块）：

```text
$ zig test main.zig
1/9 main.test.enum 的基整型、@tagName 与 @backingInt...OK
2/9 main.test.非穷尽枚举能装未知值，但取不到名字...OK
3/9 main.test.0.17 改名：@fromBackingInt 要精确基整型...OK
4/9 main.test.tagged union 的布局与穷尽 switch...OK
5/9 main.test.union(显式标签枚举) 与 payload: void...OK
6/9 main.test.packed struct 的位布局：@bitCast 是它唯一的往返方式...OK
7/9 main.test.packed union 要求所有字段位宽相同...OK
8/9 main.test.union 表达消息：编码解码往返...OK
9/9 main.test.错误联合：0.17 用 E!T，|| 只合并错误集...OK
All 9 tests passed.
```

几个值得注意的断言：

- **`@bitSizeOf(Color 的 tag_type) == 2`**（第 1 个测试）——"3 个成员 → 2 位"这条规则钉住了。
- **非穷尽枚举 42 装得下但 `levelName` 返回"未知"**（第 2 个测试）——非穷尽的两种行为（能装、没名字）一起断言。
- **`@sizeOf(Value) == 24`、`@bitSizeOf(tag_type) == 2`**（第 4 个测试）——"tag + 最大负载"布局的实测值钉住。
- **`@bitCast(f) == 0b0011_0001`、`@bitCast(r) == 0x231F`**（第 6、7 个测试）——位布局钉死，防止编译器改位序。
- **`MyErr!Value` 是 32 字节、`Value` 是 24 字节**（第 9 个测试）——错误联合额外开销钉住。

⚠️ 注意测试里那些 `@as(Type, @fromBackingInt(...))` 的写法——因为 `expectEqual` 的参数是 `anytype`，`@fromBackingInt` / `@bitCast` 这类需要确定结果类型的内建在 `anytype` 位置上报 `error: @fromBackingInt must have a known result type`，得用 `@as` 显式点名（或把期望值写成有类型的形式让编译器推断）。

## 8.11 坑位清单

1. **`@enumFromInt` 是 0.17 的合法名字但语义不同于老教程。** ≤0.16 的`@intToEnum(E, n)` 在 0.17 完全删除（`error: invalid builtin function: '@intToEnum'`），而 `@enumFromInt(n)` 是新的推荐名——但它接受**任意整数宽度**（`@intCast` 语义），而 `@fromBackingInt` 要求**精确基整型**。两者别混用。

2. **`zig fmt` 会自动把 `@intFromEnum` → `@backingInt`、`@enumFromInt` → `@fromBackingInt(@intCast(...))`**。这意味着源码里**不能留**这些旧写法——`zig fmt --check` 会失败（`run-all.sh` 第一层就拦）。但 fmt **不**改 `@intToEnum`（已删除，得手工改）和枚举成员名如 `builtin.mode == .Debug`（0.17 是 `.debug`，实测 `error: no field named 'Debug' in enum 'lang.Optimize'`）。

3. **非穷尽枚举装入未知值后取不到名字。** 值编译期已知 → `@tagName` 编译错（`error: no field with value '@fromBackingInt(42)' in enum 'main.Level'`）；值运行期才知道 → panic（`thread ... panic: invalid enum value`）。**没有"返回 undefined 标签"这回事**。正确做法是先 `switch` 归类。

4. **非穷尽枚举的 `switch` 必须有 `else`/`_`**：漏了报 `error: switch on non-exhaustive enum must include 'else' or '_' prong or both`。反过来穷尽枚举加 `else` 是允许的（会吃掉未来新增成员的编译错误）。

5. **tagged union 和枚举的穷尽 `switch` 漏一种就编译错**：`error: switch must handle all possibilities` + `note: unhandled enumeration value: 'xxx'`。union 的报错里那个 tag 类型名是 `@typeInfo(...).@"union".tag_type.?`（匿名生成类型）。

6. **读错激活字段：0.17 默认编译错**（不是运行期 panic）。标签编译期已知 → `error: access of union field 'int' while field 'text' is active`；运行期才知道 → panic（同一句文案）。老教程说"Debug 下 panic"低估了 0.17 的严格度。

7. **`packed union` 所有字段位宽必须相同**：`packed union { a: u8, b: u16 }` 报 `error: field bit width does not match earlier field` + `note: all fields in a packed union must have the same bit width`。字段也不能是数组（`[2]u8` → `packed unions cannot contain fields of type '[2]u8'`，数组无位表示）。嵌套 struct 必须是 packed。

8. **union 一次只能初始化一个字段**：`.{ .hi = 0xBE, .lo = 0xEF }` 报 `error: cannot initialize multiple union fields at once; unions can only have one active field`（tagged 和裸 union 都一样）。

9. **⚠️ 0.17 的 `||` 变成错误集并集，不再造错误联合。** `MyError || Payload` 编译错（`error: expected error set type, found 'main.Value'`）。造错误联合用 `E!T` 语法（`anyerror!T` 或具名`MyErr!T`）。这是 ≤0.16 代码的大规模破坏点。

10. **`@typeInfo(union).tag_type` 是可空的 `?type`**。裸 union 是 `null`，直接 `.?` 会运行期 panic（`attempt to use null value`），必须 `if (x) |t|`。且 tag 类型是**匿名的**，`@typeName` 打印出来是 `@typeInfo(main.Value).@"union".tag_type.?` 这种内部表示，别指望有可读名字。

11. **`packed struct` 不能放指针**：`packed struct { ptr: *const u8 }` 报 `error: packed structs cannot contain fields of type '*const u8'` + `note: pointers cannot be directly bitpacked` + `note: consider using 'usize' and '@intFromPtr'`。要用 `usize`。

12. **`@offsetOf` 对 packed struct 恒为 0**（没有字节偏移概念）。操作 packed struct 的位用 `@bitCast` 整块进出或直接读字段名。

13. **`packed struct` 是 `@bitCast` 唯一能吃的结构体。** 03 章实测 `@bitCast` 拒绝裸结构体和 `extern struct`（`error: cannot @bitCast from 'main.Header'`），但 packed struct 因为无 padding、位模式确定，是唯一例外。

14. **枚举不写赋值时隐式从 0 递增**（不是 C 的"自动挑一个 int"）。`Color{red,green,blue}` 是 0/1/2，所以 `@fromBackingInt(2)` 拿 `blue`。默认基整型是最小位宽（3 成员 → `u2`），不是 C 的 `int`。

15. **往穷尽枚举装越界值：两个内建的报错不一样。** `@fromBackingInt(@intCast(bad))` 里 `bad` 是 `u16`=300 时，`@intCast` 先炸：`error: type 'u8' cannot represent integer value '300'`；若值已经是 `u8`（比如运行期读来的 200），则是运行期 panic `thread ... panic: invalid enum value`。而 `@enumFromInt(@as(u16, 300))` 因为接受任意宽度，报的是 `error: enum 'main.Color' has no tag with value '300'`。接外部整数前先确认枚举声明了 `_`。

16. **`zig test` 过不代表 `zig build-exe` 过。** 本章 8.9 节的 `Message.decode(bad)` 原本传 `const bad = [_]u8{99}`：`zig test` 能过，`zig build-exe` 报 `error: array literal requires address-of operator (&) to coerce to slice type '[]const u8'`——comptime 上下文与运行期上下文的 coercion 宽严不同。必须写 `&.{99}`。这也是 `run-all.sh` 分三层的价值。

17. **作用域遮蔽被禁止**（贯穿本章）：`main` 里 8.9 节的 `var buf` 和我最初在 8.2 节写的 `const buf` 撞名，编译器报 `error: capture 'c' shadows local constant from outer scope` / `error: local variable is never mutated`（`var` 却没改）。Zig 不允许内层遮蔽外层同名变量，代价是变通写法（换名字如 `raws`）。

18. **`anytype` 参数位置上内建函数要确定结果类型。** `std.testing.expectEqual(Level.high, @fromBackingInt(@as(u8, 90)))` 报 `error: @fromBackingInt must have a known result type` + `note: result type is unknown due to anytype parameter`。得写 `@as(Level, @fromBackingInt(...))`。`@bitCast` 同理。

---

上一章：[07 结构体](07-structs.md) · 下一章：[09 可选与错误 I](09-optionals-errors.md)