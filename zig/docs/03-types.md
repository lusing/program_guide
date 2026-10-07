# 03 · 类型与转型

> 对应示例：`examples/03_types/main.zig`
>
> Zig 没有隐式数值转换。这一章要建立的认知是：**Zig 的类型系统是一套
> "必须显式说明你在干什么"的机制**——每次窄化、每次重新解释、每次枚举与整数
> 往来，都要在源码里留下名字。读完你应该能自己回答：为什么
> `const x: u8 = 300;` 编译不过，而 `const y = 300;` 没问题。

---

## 3.1 `const` 是默认，`var` 要申请

```zig
// examples/03_types/main.zig 第 53-66 行（begin("3.1") 到 end("3.1")）
const answer: u32 = 42; // const：初始化后不可改
var count: i32 = 10; // var：可改；写了 var 却从不改会编译报错
count += 5;
std.debug.print("answer={d} count={d}\n", .{ answer, count });

// `var x: i32;`（不写初值）本身就是语法错误，必须给初值或显式 undefined。
// 显式 undefined 是"我明确知道这内存是脏的"的声明；Debug 下未初始化内存被填成 0x00。
const u8_undef: u8 = undefined;
const u32_undef: u32 = undefined;
const bool_undef: bool = undefined;
std.debug.print("undefined: u8=0x{x:0>2} u32=0x{x:0>8} bool={}\n", .{ u8_undef, u32_undef, bool_undef });
```

运行输出（`examples/03_types/main.zig`）：

```text
==== 3.1 开始 ====
answer=42 count=15
undefined: u8=0x00 u32=0x00000000 bool=false
==== 3.1 结束 ====
```

**① `var` 声明了却从不改是编译错误**（不是警告）：`error: local variable is never mutated` + `note: consider using 'const'`；反过来（`const` 却试图改值）同样报错。于是"这个绑定会不会变"无法被遗忘——收益是**所有变量的可变性在源码里一目了然**。

**② `undefined` 在 0.17 里被填成 `0x00`，不是老教程写的 `0xaa`。**《Learning Zig》ch3 说 Debug 下 `i32` 会打印 `-1431655766`（那是 0.16 及更早），0.17 实测是全零（见上面输出）。

⚠️ **别把 `undefined` 当"随便给个值"用**。它只绕过"必须初始化"的语法要求，读它就是读未初始化内存。之所以能安全打印，是因为 Debug 模式保证未初始化内存清零（`std.debug.runtime_safety` 为 true，02 章 2.5 节）；编译成 `fast`/`small` 后这个保证消失，同一程序会读到任意值。

## 3.2 任意位宽整数：`u3`、`i19`、`u128`

C 的整数只有 `char/short/int/long` 四个宽度，写协议字段或寄存器位域时只能手动抠位掩码。Zig 把它做成了语言特性——位宽是 `i`/`u` +任意正整数：

```zig
// examples/03_types/main.zig 第 68-79 行
const small: u3 = 5; // 3 位无符号，值域 0..7
const neg: i19 = -100000; // 19 位有符号
const wide: u128 = @as(u128, 1) << 100; // 128 位内建，移位不会丢位
const ptr_sized: usize = 1000; // 指针宽度，下标/长度都用它
std.debug.print("u3={d} i19={d} usize={d}\n", .{ small, neg, ptr_sized });
std.debug.print("1<<100 = {d}（0x{x}）\n", .{ wide, wide });
std.debug.print("sizeOf: u3={d} u128={d} usize={d} bool={d}\n", .{ @sizeOf(u3), @sizeOf(u128), @sizeOf(usize), @sizeOf(bool) });
std.debug.print("bitSizeOf: u3={d} i19={d} u128={d} usize={d}\n", .{ @bitSizeOf(u3), @bitSizeOf(i19), @bitSizeOf(u128), @bitSizeOf(usize) });
```

运行输出（`examples/03_types/main.zig`）：

```text
==== 3.2 开始 ====
u3=5 i19=-100000 usize=1000
1<<100 = 1267650600228229401496703205376（0x10000000000000000000000000）
sizeOf: u3=1 u128=16 usize=8 bool=1
bitSizeOf: u3=3 i19=19 u128=128 usize=64
==== 3.2 结束 ====
```

**`@sizeOf` vs `@bitSizeOf` 是本节重点**：`u3` 的 `sizeOf=1` 但 `bitSizeOf=3`。原因是内存**只能按字节寻址**——不管类型有几个有效位，最小占用都是 1 字节。所以：做内存布局（`extern struct`、网络字节）看 `@sizeOf`；做位域看`@bitSizeOf`。`u3` 剩下那 5 位是**填充位**，值不受影响——第 08 章的`packed struct` 就是把填充位挤掉的机制。`u128` 让 `1 << 100` 这种 64 位语言做不到的移位随手可做；`usize` 是"指针宽度"，下标和切片长度都用它（06 章）。

## 3.3 `comptime_int`：数字字面量根本没有类型

这是整章最容易让人卡住的概念。`@typeName` 说得很直白：三个字面量的类型都叫`comptime_int`（见下面输出第二行）。它有三个特性：**任意精度**（不是固定宽度，而是"编译器先记下这个数，用到时才定宽度"）、**只存在于编译期**、**落地时必须定型**（由上下文决定变成什么）。

```zig
// examples/03_types/main.zig 第 81-96 行
const dec = 123_456_789; // 十进制，下划线是给人看的
const hex = 0xFF; // 十六进制
const oct = 0o77; // 八进制，前缀是 0o 不是 0
const bin = 0b1010; // 二进制
const ch = 'A'; // comptime_int（字符字面量也是整数）
std.debug.print("dec={d} hex={d} oct={d} bin={d} ch={d}\n", .{ dec, hex, oct, bin, ch });
std.debug.print("字面量类型：dec={s} hex={s} bin={s}\n", .{
    @typeName(@TypeOf(dec)),
    @typeName(@TypeOf(hex)),
    @typeName(@TypeOf(bin)),
});
const f = 3.5; // 浮点字面量是 comptime_float
std.debug.print("浮点字面量类型={s}；5/2 类型={s} 值={d}\n", .{ @typeName(@TypeOf(f)), @typeName(@TypeOf(5 / 2)), 5 / 2 });
```

运行输出（`examples/03_types/main.zig`）：

```text
==== 3.3 开始 ====
dec=123456789 hex=255 oct=63 bin=10 ch=65
字面量类型：dec=comptime_int hex=comptime_int bin=comptime_int
浮点字面量类型=comptime_float；5/2 类型=comptime_int 值=2
==== 3.3 结束 ====
```

于是有了这一组差异：

| 写法 | 结果 |
|---|---|
| `const dec = 123_456_789;` | ✅ 合法，类型由后面用到它的地方决定 |
| `const x: u8 = 300;` | ❌ `type 'u8' cannot represent integer value '300'` |
| `const y: u3 = 8;` | ❌ `type 'u3' cannot represent integer value '8'` |

**为什么这是好事**：C 里 `unsigned char c = 300;` 编译通过，运行时 `c` 已经是 44 了，你得到一个静默错误的数据。Zig 让它编译期就炸。这是 `@intCast` 与`@truncate`语义的基础——**类型系统帮你守住值域**。

`'A'` 打印出 65，说明字符字面量也是 `comptime_int` 而非独立类型，类型靠上下文定：`const c: u8 = 'A';` 合法（65在 u8 值域内），而`const c: u8 = '中';`编译错（`'中'` 是 UTF-8 编码，值远超 u8）。`5 / 2` 的类型也是`comptime_int`、值是 2——**整数除法在这里是编译期算的**；运行期的整数除法要显式写运行期变量，`7 / 2 == 3`而不是 3.5，因为两边都是整数。

## 3.4 溢出：三个工具，三种语义

```zig
// examples/03_types/main.zig 第 98-123 行
var byte: u8 = 255;
byte +%= 1; // 环绕加：255 → 0，四种模式都不出错
var debt: i8 = -128;
debt -%= 1; // 环绕减：-128 → 127（无符号的 128 解释成 i8）
std.debug.print("255 +%= 1 → {d}；-128 -%= 1 → {d}\n", .{ byte, debt });
// 安全版 `+` 在 Debug/safe 模式越界就 panic（实测：thread ... panic: integer overflow）。
// 想要"不 panic 也不丢信息"就用 @addWithOverflow：它把溢出当成返回值。
// ⚠️ 0.17 的溢出标志是 **u1**（0 或 1），不是 bool——
// `try std.testing.expect(ov[1])` 会报 expected type 'bool', found 'u1'，得写 `ov[1] == 1`。
const add_ov = @addWithOverflow(@as(u8, 250), @as(u8, 10));
const sub_ov = @subWithOverflow(@as(u8, 5), @as(u8, 10));
const mul_ov = @mulWithOverflow(@as(u8, 16), @as(u8, 16));
std.debug.print("250+10={d}溢出={}  5-10={d}溢出={}  16*16={d}溢出={}\n", .{
    add_ov[0], add_ov[1] == 1,
    sub_ov[0], sub_ov[1] == 1,
    mul_ov[0], mul_ov[1] == 1,
});
var acc: u32 = 0; // u32 累加 10 万次没问题（换成 u8 会在第 256 次炸掉，见 3.5 节）
var step: u32 = 0;
while (step < 100_000) : (step += 1) acc += 1;
std.debug.print("u32累加 100000 次 = {d}\n", .{acc});
```

运行输出（`examples/03_types/main.zig`）：

```text
==== 3.4 开始 ====
255 +%= 1 → 0；-128 -%= 1 → 127
250+10=4溢出=true  5-10=251溢出=true  16*16=0溢出=true
u32累加 100000 次 = 100000
==== 3.4 结束 ====
```

每个算术运算符都有**两套写法**：安全版 `+ - *` 和环绕版 `+%= -%= *%=`。**"安全"的意思是把未定义行为变成崩溃**——实测安全版越界报`thread 682165 panic: integer overflow`，而且 panic 消息带**源码行号和列号**（Debug 模式下每一步都有安全网，这就是为什么本教程所有示例都跑 Debug 模式）。

**环绕版不是"bug 的借口"，它是明确声明的语义。** 哈希函数里的`h *%= 31 +% c`、序列号回绕、时间戳进位，这些场景回绕就是想要的行为。代码里那个 `%` 字符在说："我知道这里会溢出，我处理过它了。"

**第三个工具 `@addWithOverflow`** 给"既不想 panic、也不想丢信息"的场景：它返回 `[结果, 是否溢出]`，另有`@subWithOverflow` /`@mulWithOverflow`。看输出里的`250+10=4溢出=true`——250 + 10 在 u8 里回绕成 4（250+10-256），同时告诉你"确实溢出了"。C 里做同一件事要写成`if (a > MAX - b) { ... } else { ... }`，这里是一个表达式。

⚠️ **0.17 的溢出标志是 `u1` 不是 `bool`**（输出里 `溢出=true` 是因为示例显式写了 `== 1`）。直接写`try std.testing.expect(add_ov[1])` 会报`error: expected type 'bool', found 'u1'`。

## 3.5 唯一的隐式转换：宽化（以及它的陷阱）

Zig **几乎没有**隐式转换。唯一放行的是**宽化**：目标类型能表示源类型的**所有**可能值。

```zig
// examples/03_types/main.zig 第 125-152 行
const a8: u8 = 200;
var a16: u16 = 0;
a16 = a8; // 隐式宽化：目标类型能表示源的所有值，编译器放行
std.debug.print("u8 → u16 隐式宽化 = {d}\n", .{a16});
const f32v: f32 = 1.5;
const f64v: f64 = f32v; // 浮点同理：f32 → f64 放行
std.debug.print("f32 → f64 隐式宽化 = {d}\n", .{f64v});
// 反方向一律拒绝：u16 → u8、f64 → f32、bool → u8 都编译失败
//   const q: u8 = a16;   error: expected type 'u8', found 'u16'
//   const i: u8 = flag;   error: expected type 'u8', found 'bool'
//
// ⚠️ 陷阱：**算术结果永远不宽化**。u8 + u8 的结果类型还是 u8，不是 u16。
const e8: u8 = 100;
const diff = e8 -% a8; // 100 - 200：必须用环绕减，否则 Debug panic
std.debug.print("u8 -% u8 → 类型 {s} 值 {d}\n", .{ @typeName(@TypeOf(diff)), diff });
const g16: u16 = 30000;
const sum16 = g16 + g16; // 60000 装得进 u16；换成 g16=60000 就 panic
std.debug.print("u16 + u16 → 类型 {s} 值 {d}\n", .{ @typeName(@TypeOf(sum16)), sum16 });
// u8 + comptime_int 也**不会**宽化：a8 + 1000 直接编译错（u8 装不下 1000）
const widened = a8 + @as(u16, 1000); // 想要宽化就自己点名
std.debug.print("u8 + u16(1000) → 类型 {s} 值 {d}\n", .{ @typeName(@TypeOf(widened)), widened });
// 浮点除法两边类型不同也要点名：7.0 / 2 编译错（comptime_float vs comptime_int 二义）
const q = @as(f32, 7.0) / 2;
std.debug.print("@as(f32, 7.0) / 2 → 类型 {s} 值 {d}\n", .{ @typeName(@TypeOf(q)), q });
```

运行输出（`examples/03_types/main.zig`）：

```text
==== 3.5 开始 ====
u8 → u16 隐式宽化 = 200
f32 → f64 隐式宽化 = 1.5
u8 -% u8 → 类型 u8 值 156
u16 + u16 → 类型 u16 值 60000
u8 + u16(1000) → 类型 u16 值 1200
@as(f32, 7.0) / 2 → 类型 f32 值 3.5
==== 3.5 结束 ====
```

**为什么允许宽化**：宽化**不丢信息**，所以不需要你在源码里表态。`u8 → u16` 的 200 就是 200，永远不会错。反过来`u16 → u8` 可能丢，就必须点名。**为什么`bool → u8` 不算宽化**：这不是"同一个值换个宽度"，而是"换个语义"（真/假 → 1/0）。这条堵死了 C 里`if (x = 5)` 那类惨案的入口——布尔永远不能当数字用，`if (1)`在 Zig 里是编译错误。

### ⚠️ 最重要的陷阱：算术结果永不宽化

看输出第 3、4 行：`u8 -% u8` 结果类型是 **`u8`**，`u16 + u16` 是 **`u16`**。**Zig 的二元算术返回"最小可表示"的类型，两边同类型就返回那个类型。**这条规则制造了三个常见翻车点：

**① 累加到一半才炸。** `var acc: u8 = 0; for (0..300) |_| acc += 1;`在第 256 次 panic。同样循环换成 `u32` 跑 100000次没问题（见 3.4 节输出）。C 里这类写法更隐蔽——因为 C 会隐式提升到 `int`，Zig 不。**移植 C 代码时这是首要检查项。**

**② `u8 + comptime_int` 也不宽化。** 实测 `const i = a8 + 1000;` 直接编译错（`type 'u8' cannot represent integer value '1000'`）。不是"提升到 u16 再算"，而是"结果类型定成 u8，然后 1000 装不下"。想要更宽的结果就**自己点名**：`a8 + @as(u16, 1000)`（输出第 5 行，1200）。

**③ 浮点同理，而且更隐蔽。** `7.0 / 2` 编译错：`error: ambiguous coercion of division operands 'comptime_float' and'comptime_int'; non-zero remainder '1'`。编译器不知道该把 `2`变成什么。`@as(f32, 7.0) / 2` 明确指定左边是 f32 之后，右边自动定型成 f32，输出 3.5。

## 3.6 转型家族：每个内建各有各的语义

本章的**核心工具箱**。Zig 没有 `(u8)x` 这种 C 风格转换，全部换成带名字的内建——**名字本身就说明了你要干什么**。

| 内建 | 语义 | 越界/不合法的行为 |
|---|---|---|
| `@as(T, x)` | 类型协调（给 `comptime_int` 定型） | 值装不下 → **编译错** |
| `@intCast(x)` | 整数间**安全**转换 | 运行期 → panic；编译期可知 → 编译错 |
| `@truncate(x)` | 整数**砍位**（只留低位） | 不检查，永远成功 |
| `@intFromFloat` | 浮点 → 整数（截断小数） | 运行期 → panic |
| `@floatFromInt` / `@floatCast` | 整数 → 浮点 / 浮点改精度 | 丢精度（**静默**） |
| `@intFromBool` | 布尔 → 0/1 | — |
| `@intFromPtr` / `@ptrFromInt` | 指针 ↔ 整数地址 | 往返无损 |

```zig
// examples/03_types/main.zig 第 154-186 行
const wide_val: i32 = 300;
// @truncate：只保留低位，无视值域是否装得下
const t = @as(u8, @truncate(@as(u32, @bitCast(wide_val))));
std.debug.print("i32 300 的低 8 位 = {d}\n", .{t});
// @truncate 的**操作数必须是无符号整数**，有符号要先 @bitCast 过去
//   @truncate(@as(i32, 300)) → error: expected unsigned integer type, found 'i32'
//
// @intCast：值域检查版。值在编译期已知且越界，连编译都过不了
//   const bad: u8 = @intCast(@as(i32, 300));
//   → error: type 'u8' cannot represent integer value '300'
const fits: i32 = 200;
const c = @as(u8, @intCast(fits)); // 200 在 u8 值域内，OK
std.debug.print("@intCast(i32 200 → u8) = {d}\n", .{c});
// @intFromFloat：浮点 → 整数，**直接截断小数**（不是四舍五入）
const i_from_f: i32 = @intFromFloat(3.7);
const f_from_i: f64 = @floatFromInt(200); // 整数 → 浮点
const narrowed: f32 = @floatCast(@as(f64, 1.0 / 3.0)); // 浮点之间改精度
std.debug.print("@intFromFloat(3.7)={d} @floatFromInt(200)={d:.1} @floatCast(1/3)={d}\n", .{ i_from_f, f_from_i, narrowed });
const flag: bool = true;
const b1: u1 = @intFromBool(flag);
const n: u32 = 42;
const back: *const u32 = @ptrFromInt(@intFromPtr(&n)); // 地址往返无损
std.debug.print("@intFromBool(true)={d} 指针往返={d}\n", .{ b1, back.* });
// 位操作家族（0.17 没有 ** 幂运算符了，移位和 @popCount 顶上）
std.debug.print("0b1010 & 0b0110 = {d}；@popCount(0xF0F0)={d}；@ctz(0x10)={d}；@clz(0x10)={d}\n", .{ @as(u8, 0b1010) & @as(u8, 0b0110), @popCount(@as(u16, 0xF0F0)), @ctz(@as(u32, 0x10)), @clz(@as(u32, 0x10)) });
```

运行输出（`examples/03_types/main.zig`）：

```text
==== 3.6 开始 ====
i32 300 的低 8 位 = 44
@intCast(i32 200 → u8) = 200
@intFromFloat(3.7)=3 @floatFromInt(200)=200.0 @floatCast(1/3)=0.33333334
@intFromBool(true)=1 指针往返=42
0b1010 & 0b0110 = 2；@popCount(0xF0F0)=8；@ctz(0x10)=4；@clz(0x10)=27
==== 3.6 结束 ====
```

### `@truncate` 与 `@intCast` 的区别（本章最重要的一组对照）

两个都做"窄化"，语义**完全相反**：

| | `@truncate` | `@intCast` |
|---|---|---|
| 检查什么 | **不检查** | 检查**值域** |
| `i32 300 → u8` | ✅ 44（低 8 位） | ❌ panic |
| 设计意图 | "我知道会丢低位，我要的就是位模式" | "这个数必须在目标值域内，不许丢" |

`i32 300 的低 8 位 = 44` —— 300 是 `0x1_2C`，低 8 位是 `0x2C` = 44。这是**模运算**，不是转换。

⚠️ **`@truncate` 的操作数必须是无符号整数**。有符号要先 `@bitCast` 过去（示例第 159 行就是这么写的），否则报`error: expected unsigned integer type, found 'i32'`。这是"只取低位"语义的必然要求——有符号数的"高位"是符号位，砍掉它得到的数没有意义。`@bitCast` 在这里做的是**纯位搬运**，不改变数值语义。

### `@intFromFloat` 是截断不是四舍五入

`@intFromFloat(3.7) = 3`，`-3.7 → -3` 也是**向零截断**（不是向下取整，那会得到 -4）。要向下取整用 `@divFloor` / `@modFloor`（实测`@divTrunc(-7,2) = -3`，`@divFloor(-7,2) = -4`）。这些有单元测试守着（`examples/03_types/main.zig` 第 311-316 行，断言 `@truncate(300)==44`、`@intFromFloat(3.7)==3`、`@intFromFloat(-3.7)==-3`、f32 窄化后落在 0.333~0.334 之间）。

`@floatCast(1/3) = 0.33333334` 是 f32 的实际精度——**它真的降到了 f32 能表达的最近值**，不是随手截断成 0.3333。

### 0.17 没有 `**` 幂运算符

老教程里的 `2 ** 3` 在 0.17 报（报错文案有点误导，编译器把 `**` 解析成了 `*`然后抱怨空格不对称）：`error: binary operator '*' has whitespace on one side,but not the other`。替代品：用移位（`1 << n`）、`std.math.pow`，或自己写 comptime 函数。同理`[_]T{x} ** n`重复填充语法也移除了，改用 `@splat(x)`：

```zig
const sp: [4]u8 = @splat(7); // { 7, 7, 7, 7 }
```

## 3.7 `@bitCast`：同宽重解释，以及 0.17 的一个新限制

`@bitCast` 的语义是"**位不变，只换解释方式**"：

```zig
// examples/03_types/main.zig 第 188-207 行
const u: u32 = 0x41424344;
const raw: [4]u8 = @bitCast(u); // u32 ↔ [4]u8：两边 @sizeOf 相等即可
std.debug.print("0x{x:0>8} 的字节序（小端）= {any}\n", .{ u, raw });
// 0.17 的坑：@bitCast **不接受裸结构体**（extern struct 也不行）
//   const x: u64 = @bitCast(header);  → error: cannot @bitCast from 'main.Header'
// 正确姿势：asBytes + readInt/writeInt，按字节走
const header = Header{ .magic = 0x41424344, .len = 0x0102 };
const hbytes = std.mem.asBytes(&header);
std.debug.print("Header sizeOf={d} 字节={any}\n", .{ @sizeOf(Header), hbytes[0..@sizeOf(Header)] });
const magic_le = std.mem.readInt(u32, hbytes[0..4], .little);
const magic_be = std.mem.readInt(u32, hbytes[0..4], .big);
std.debug.print("readInt 小端=0x{x:0>8} 大端=0x{x:0>8}\n", .{ magic_le, magic_be });
var out: [4]u8 = undefined;
std.mem.writeInt(u32, &out, 0xAABBCCDD, .little);
std.debug.print("writeInt 小端 0xAABBCCDD → {any}\n", .{out});
```

运行输出（`examples/03_types/main.zig`）：

```text
==== 3.7 开始 ====
0x41424344 的字节序（小端）= { 68, 67, 66, 65 }
Header sizeOf=8 字节={ 68, 67, 66, 65, 2, 1, 0, 0 }
readInt 小端=0x41424344 大端=0x44434241
writeInt 小端 0xAABBCCDD → { 221, 204, 187, 170 }
==== 3.7 结束 ====
```

`{ 68, 67, 66, 65 }` 是 `0x44 0x43 0x42 0x41`——**小端序**：最低有效字节放在最低地址。这是 x86/ARM 的实际内存布局。

⚠️ **`@bitCast` 的两个硬约束**：

1. **两侧 `@sizeOf` 必须严格相等**。`u32`（4 字节）↔ `[4]u8` ✅；`u32` ↔ `[8]u8`（8 字节）❌ 编译错。
2. **⚠️ 0.17 不接受裸结构体**——连 `extern struct` 也不行。这是本教程实测踩到的新坑：`error: cannot @bitCast from 'main.Header'`。注意这**不是**因为宽度不等（`Header` 和 `u64` 都是 8 字节）。0.17直接把结构体排除在 `@bitCast` 之外了。顺带一个佐证：`extern struct { a: u8, b: u24 }` 本身就不合法——`error: extern structs cannot contain fields of type 'u24'`（extern 布局只允许 0 或 2 的幂次位宽）。

### 那结构体怎么按字节读写

用 **`std.mem.asBytes` + `std.mem.readInt` / `writeInt`**，这是 0.17 的正道。

看输出第 2 行：`Header` 声明是 `{ magic: u32, len: u16 }`，只有 6 字节数据，但 `sizeOf = 8`——**末尾 2 字节是 padding**。最后那个`[ 0, 0 ]` 就是对齐填出来的空隙。**这就是为什么"结构体直接当字节数组用"是错的**：padding 里的内容不确定，写进文件或发上网会产生不可复现的差异。`asBytes` + `readInt` 的写法显式指定了"取前 4字节、按小端解释成 u32"，完全绕开 padding。

`readInt` 的第三个参数是**字节序**，必须显式给：小端读 `0x41424344`，大端读 `0x44434241`（字节反过来）。网络协议一律大端，x86 内存布局一律小端。**这个参数没有默认值——Zig 不替你猜字节序。**

这段有测试守着（`main.zig` 第 322-341 行），验证 `writeInt` 和 `readInt`在两种字节序下都互为逆运算。

## 3.8 类型自省：`@TypeOf` / `@typeName` / `@typeInfo`

"在编译期检查类型"需要一套反射支撑。Zig 提供三个层次，从轻到重：

| 内建 | 问的问题 | 例子 |
|---|---|---|
| `@TypeOf(x)` | 这个**表达式**是什么类型？ | `@TypeOf(v32 * 2)` → `u32` |
| `@typeName(T)` | 把类型渲染成字符串 | `@typeName(u8)` → `"u8"` |
| `@typeInfo(T)` | 这个类型的**完整元数据** | `@typeInfo(u8).int.bits` → `8` |

注意 `@TypeOf` 接受**表达式**：`@TypeOf(v32 * 2)` 里的 `v32 * 2` 不会被求值，它只是拿来定类型。这也是它和 C 的`typeof`在语义上的差别——Zig 版的`@TypeOf` 对**表达式**建模，不是"变量的声明类型"。

```zig
// examples/03_types/main.zig 第 11-42 行（反射要用的类型 + 分派函数）
/// 演示用的小结构体：字段名与字段类型在 3.8 节被反射出来
const Header = extern struct {
    magic: u32,
    len: u16,
};
/// 3.8 节的错误集：@typeInfo 能列出全部名字
const StoreError = error{ NotFound, Corrupted };

/// 按类型分派的函数，证明 comptime 反射可以写正常代码
fn kindName(comptime T: type) []const u8 {
    return switch (@typeInfo(T)) {
        .int => "整数",
        .float => "浮点",
        .@"struct" => "结构体",
        // .array / .optional / .error_union / .error_set / .bool / .void … 略
        else => "其它",
    };
}
```

`kindName` 就是**泛型 + comptime 反射**的标准写法：参数是 `comptime T: type`，函数体在编译期对具体类型求值一次，返回值被固化。调用`kindName(Header)`时**不产生任何运行期开销**。

```zig
// examples/03_types/main.zig 第 209-244 行
const v32: u32 = 7;
std.debug.print("@TypeOf(v32)={s}；表达式 v32 * 2 的类型={s}\n", .{ @typeName(@TypeOf(v32)), @typeName(@TypeOf(v32 * 2)) });
std.debug.print("kindName(u8)={s} kindName(f64)={s} kindName([]u8)={s} kindName(?u8)={s}\n", .{ kindName(u8), kindName(f64), kindName([]u8), kindName(?u8) });
std.debug.print("kindName(Header)={s} kindName(Color)={s} kindName(StoreError)={s} kindName(anyerror!u8)={s}\n", .{ kindName(Header), kindName(Color), kindName(StoreError), kindName(anyerror!u8) });
std.debug.print("kindName(3)={s}（字面量在运行期会变成 u8）kindName(void)={s}\n", .{ kindName(@TypeOf(3)), kindName(void) });
// 反射结构体字段：0.17 是 field_names / field_types / layout（.tag 已改名）
const hi = @typeInfo(Header);
std.debug.print("Header layout={t}字段数={d}\n", .{ hi.@"struct".layout, hi.@"struct".field_names.len });
inline for (hi.@"struct".field_names, hi.@"struct".field_types) |fname, ftype| {
    // field_names 的元素是 [:0]const u8（带哨兵）；写成 fname[0..fname.len]
    // 得到的是 *const [N:0]u8，{s} 能直接吃。踩坑：写 fname[0..4 :0] 会报
    //   error: value in memory does not match slice sentinel
    // 因为哨兵在末尾第 5 字节，不是第 4 字节。
    // field_types 的元素是 `type`——编译期实体，运行期不存在，
    // 必须 inline for 逐个展开才能 @typeName（普通 for 会报 types are not available at runtime）。
    std.debug.print("  字段 {s} 类型={s}\n", .{ fname[0..fname.len], @typeName(ftype) });
}
std.debug.print("@alignOf(u32)={d} @offsetOf(Header, len)={d}\n", .{ @alignOf(u32), @offsetOf(Header, "len") });
const ce = @typeInfo(Color);
std.debug.print("Color 基整型={s} 字段数={d}\n", .{ @typeName(ce.@"enum".tag_type), ce.@"enum".field_names.len });
// field_values 的元素类型是 **comptime_int**（不是 u8）——普通 for 会报
// values of type 'comptime_int' must be comptime-known，但 index value is runtime-known。
inline for (ce.@"enum".field_names, ce.@"enum".field_values) |fname, fval| {
    std.debug.print("  {s} = {d}\n", .{ fname[0..fname.len], fval });
}
// 反射错误集：0.17 的 error_names 是**可空**的 ?[]const [:0]const u8
const se = @typeInfo(StoreError);
if (se.error_set.error_names) |enames| {
    std.debug.print("StoreError 错误数={d}\n", .{enames.len});
    for (enames) |ename| std.debug.print("  {s}\n", .{ename[0..ename.len]});
}
```

运行输出（`examples/03_types/main.zig`）：

```text
==== 3.8 开始 ====
@TypeOf(v32)=u32；表达式 v32 * 2 的类型=u32
kindName(u8)=整数 kindName(f64)=浮点 kindName([]u8)=指针 kindName(?u8)=可选
kindName(Header)=结构体 kindName(Color)=枚举 kindName(StoreError)=错误集 kindName(anyerror!u8)=错误联合
kindName(3)=comptime_int（字面量在运行期会变成 u8）kindName(void)=空
Header layout=extern字段数=2
  字段 magic 类型=u32
  字段 len 类型=u16
@alignOf(u32)=4 @offsetOf(Header, len)=4
Color 基整型=u8 字段数=3
  red = 1
  green = 2
  blue = 4
StoreError 错误数=2
  NotFound
  Corrupted
==== 3.8 结束 ====
```

### `@typeInfo` 的五个 0.17 变化（实测踩到）

这部分是本章最"版本敏感"的地方，全部在本机 0.17.0 上验证过。

**① `.@"struct".tag` 已改名为 `.layout`。** 老教程常写`@typeInfo(S).@"struct".tag == .@"packed"`。0.17 里报`error: no field named 'tag' in struct 'lang.Type.Struct'`。新名字是 `.layout`，取值 `auto` / `.@"extern"` /`.@"packed"`（枚举类型`std.lang.ContainerLayout`）。输出里 `Header layout=extern` 就是这个。

**② `std.meta.fields` 已废弃。** 0.17 走`@typeInfo(T).@"struct".field_names` / `.field_types` / `.field_attrs`/`.decl_names`。

**③ `field_types` 的元素是 `type`，必须用 `inline for`。** 普通 `for` 报`error: values of type 'type' must be comptime-known, but index value isruntime-known`+`note: types are not available at runtime`。道理很直白：**类型是编译期实体，运行期根本没有"类型"这个值**。`inline for`在编译期把循环展开，每次迭代的 `ftype` 都是编译期已知的。

**④ 哨兵切片要写全长度。** `field_names` 的元素是 `[:0]const u8`：想给 `{s}` 打印要写 `fname[0..fname.len]`（得到`*const [N:0]u8`），写`fname[0..4 :0]` 声称"第 4 字节是哨兵"会报`error: value in memory does not match slice sentinel`；而 `for (enames) |ename|`直接遍历`?[]const [:0]const u8` 会报`type '?[]const [:0]const u8' is not indexable and not a range`——**0.17 的`error_set.error_names` 是可空类型**，得先`if (x) |y|` 或 `.?`。

**⑤ `enum` 的 `field_values` 元素类型是 `comptime_int`**，也必须 `inline for`，否则报`values of type 'comptime_int' must be comptime-known,but index value is runtime-known`。

**顺带两个布局内建**：`@alignOf(u32) = 4`（u32 按 4 字节对齐）；`@offsetOf(Header, len) = 4`（`len` 在结构体里的字节偏移——`magic` 占 0..4，`len` 紧接着放，正好 4，不需要额外 padding）。这些在做二进制协议布局时是刚需（20 章的文件格式解析会用到）。

## 3.9 枚举 ↔ 整数：`@backingInt` / `@fromBackingInt`

枚举在内存里就是一个整数，但 Zig 把"取出来"和"塞回去"拆成了两个名字。

```zig
// examples/03_types/main.zig 第 17-20 行
/// 3.9 节的枚举：显式指定基整型 / 不写基整型，由编译器挑最小的
const Color = enum(u8) { red = 1, green = 2, blue = 4 };
const Level = enum { low, high };
```

```zig
// examples/03_types/main.zig 第 246-260 行
const g: Color = .green;
std.debug.print("@backingInt(Color.green)={d} @sizeOf(Color)={d}\n", .{ @backingInt(g), @sizeOf(Color) });
const blue: Color = @fromBackingInt(@as(u8, 4)); // 安全版：值域检查
const c2: Color = @enumFromInt(1); // 0.17 的名字，值域仍然检查
std.debug.print("@fromBackingInt(4)={t} @enumFromInt(1)={t}\n", .{ blue, c2 });
const lv: Level = .high;
std.debug.print("Level 基整型={s} @sizeOf={d} @backingInt(.high)={d}\n", .{ @typeName(@typeInfo(Level).@"enum".tag_type), @sizeOf(Level), @backingInt(lv) });
// 枚举 ↔ 整数 走字节视角
const cbytes = std.mem.asBytes(&g);
std.debug.print("Color.green 的字节={any}（首字节就是基整数值）\n", .{cbytes});
// ⚠️ 0.17 改名：@intFromEnum → @backingInt，@intToEnum → @enumFromInt。
```

运行输出（`examples/03_types/main.zig`）：

```text
==== 3.9 开始 ====
@backingInt(Color.green)=2 @sizeOf(Color)=1
@fromBackingInt(4)=blue @enumFromInt(1)=red
Level 基整型=u1 @sizeOf=1 @backingInt(.high)=1
Color.green 的字节={ 2 }（首字节就是基整数值）
==== 3.9 结束 ====
```

**0.17 的改名**（这一条会让大量旧代码直接编译失败）：

| 老名字 | 0.17 | 说明 |
|---|---|---|
| `@intFromEnum(e)` | `@backingInt(e)` | 枚举 → 整数 |
| `@intToEnum(E, n)` | `@enumFromInt(n)` | 整数 → 枚举 |
| | `@fromBackingInt(n)` | 整数 → 枚举（值域检查版） |

`Color` 显式写了 `enum(u8)`，所以基整型是 `u8`、`@sizeOf = 1`。`Level` 没写，编译器挑了 **`u1`**——两个成员，1位就够，这就是`Level 基整型=u1` 那行的含义。

`Color.green 的字节={ 2 }` 印证了"枚举就是整数"：`asBytes` 拿到的第一个（也是唯一）字节就是基整数值 2。**没有额外 tag、没有 vtable、没有指针**——这是 Zig 枚举能进协议报文的原因。

⚠️ `@enumFromInt` 的值域检查是真检查。实测传一个枚举里不存在的值，编译期就报错（值已知时）：`error: type 'u8' cannot represent integer value '300'`。值在运行期才知道的话会是 panic。

这段有测试守着（`main.zig` 第 367 行），包括"`Level` 的基整型是 `u1`"这个断言。

## 3.10 编译期算术：`comptime` 变量与纯编译期函数

前面所有内容都是"运行期怎么安全地转"。这一节反过来：**有些计算根本不必到运行期**。

```zig
// examples/03_types/main.zig 第 44-50 行
/// 纯编译期函数，调用点没有一行运行期代码
fn factorial(comptime n: u32) u64 {
    comptime var acc: u64 = 1;
    comptime var k: u32 = 2;
    inline while (k <= n) : (k += 1) acc *= k;
    return acc;
}
```

```zig
// examples/03_types/main.zig 第 262-275 行
comptime var sum: u32 = 0;
inline for (0..8) |i| sum += i; // inline for：循环体在编译期展开
std.debug.print("inline for 0..8 累加 = {d}（类型 {s}）\n", .{ sum, @typeName(@TypeOf(sum)) });
std.debug.print("factorial(10) = {d}（编译期算好的常量）\n", .{factorial(10)});
// 编译期块（labeled block）：普通块也可以整体在编译期求值
const area = comptime blk: {
    var partial: usize = 0;
    for (0..8) |k| partial += @sizeOf(u8) * k;
    break :blk partial;
};
std.debug.print("编译期求和 = {d}（0+1+…+7 字节）\n", .{area});
```

运行输出（`examples/03_types/main.zig`）：

```text
==== 3.10 开始 ====
inline for 0..8 累加 = 28（类型 u32）
factorial(10) = 3628800（编译期算好的常量） 
编译期求和 = 28（0+1+…+7 字节）
==== 3.10 结束 ====
```

**三种写法的区别**：`comptime var` 声明一个**编译期变量**（编译期就有确定值）；`inline for` / `inline while` 让循环在**编译期展开**，每次迭代都是编译期求值；`comptime blk: { ... break :blk x; }` 让整个块在编译期求值，`break :blk` 给出结果。

`factorial(10) = 3628800` 之所以能直接塞进 `std.debug.print` 的参数，是因为 `comptime n` 让整个函数在编译期求值一次，返回值被**固化成常量**。如果 `n`是运行期参数，这就必须写成普通 `fn`。

⚠️ **`inline for` 和 `for` 不是"性能选项"**。普通 `for` 循环体是运行期的，里面的 `sum += i` 编译不报错（因为`sum` 已经是 `u32`了）；但如果你想在编译期算错就报错，必须用 `inline for`——3.8 节那个 `field_values` 就是例子（元素是`comptime_int`，普通 `for` 直接编译失败）。

`0+1+…+7 = 28`（前 8 个自然数的和）。这段代码运行时**零开销**，28 是编译期算出来直接塞进二进制的。

**⚠️ 作用域遮蔽（shadowing）被禁止。** 写这一节的示例时踩到了：

```text
error: local variable 'acc' shadows local variable from outer scope
    var acc: usize = 0;
note: previous declaration here
    var acc: u32 = 0;
```

内层块里用了和外层相同的名字，编译器直接拒绝（`error: local variable 'acc'shadows local variable from outer scope`）。这印证了《Learning Zig》ch3 的说法（"inZig, scope shadowing is simply not allowed… This isn't JavaScript"）。原因很实在：同名变量会让"这一行到底在动哪个"变得需要动脑排查。代价是变通写法——给内层换个名字（如上面的 `partial`）。

### 测试：把语义钉住（本章行为全由它守住）

本章行为全靠测试守着（`main.zig` 第 279-402 行，9 个 `test` 块）：

```text
$ zig test main.zig
1/9 main.test.任意位宽整数与环绕运算符...OK
2/9 main.test.带溢出返回值的三个内建（标志位是 u1 不是 bool）...OK
3/9 main.test.@truncate 只看低位，@intCast 看值域，浮点互转截断小数...OK
4/9 main.test.@bitCast 同宽重解释，以及结构体走 asBytes + readInt...OK
5/9 main.test.writeInt 与 readInt 互为逆运算...OK
6/9 main.test.类型自省：kindName 与 @typeInfo 的三类元数据...OK
7/9 main.test.枚举与基整型互转...OK
8/9 main.test.编译期算术与宽化规则...OK
9/9 main.test.指针往返：@intFromPtr 与 @ptrFromInt...OK
All 9 tests passed.
```

第 6 个测试把三种元数据断言在一起——这正是"`@typeInfo` 能读结构体字段、枚举成员值、错误集名字"的证据（`main.zig` 第 343-365 行）：它断言`hi.@"struct".field_names[0][0..5] == "magic"`、`ce.@"enum".field_values[2] == 4`、`se.error_set.error_names.?` 的长度是 2 且首名是 `"NotFound"`。

⚠️ 注意 `field_values[2]` 在**测试里可以直接下标**（编译期求值），但在 `main` 里用普通 `for` 遍历它就编译失败（3.8 节那个坑）。同一种数据，访问方式不同。

## 3.11 坑位清单

1. **`var` 声明了却从不改 = 编译错误**（不是警告）：`error: local variable is never mutated` + `note: consider using 'const'`。
2. **0.17 的 `undefined` 被填成 `0x00`，不是老教程写的 `0xaa`**。《Learning Zig》ch3 说 Debug 下 i32 会打印 `-1431655766`（那是 0.16 及更早）。而且这个保证只在 `runtime_safety` 开启时存在——`fast`/`small` 模式下读 `undefined` 是未定义行为。
3. **`@sizeOf(u3) = 1` 但 `@bitSizeOf(u3) = 3`**：内存只能按字节寻址。做内存布局看前者，做位域看后者。`packed struct`（08 章）把填充位挤掉。
4. **字面量是 `comptime_int`（任意精度），但落地时必须装得下**：`const x: u8 = 300;` → `type 'u8' cannot represent integer value '300'`；`const x: u3 = 8;` → `type 'u3' cannot represent integer value '8'`。C 里这种代码能编译（然后静默得到错数据）。
5. **`@addWithOverflow` 的标志位是 `u1` 不是 `bool`**：`try std.testing.expect(ov[1])` → `error: expected type 'bool', found 'u1'`，得写 `ov[1] == 1`。
6. **算术结果永不宽化**：`u8 + u8` 结果还是 `u8`，`var acc: u8 = 0; for (0..300) |_| acc += 1;` 在第 256 次 panic。这是移植 C 代码时首要检查项（C 会隐式提升到 int，Zig 不）。
7. **`u8 + comptime_int` 也不宽化**：`const i = a8 + 1000;` 直接编译错（结果类型定成 u8，1000 装不下）。要宽化自己写 `a8 + @as(u16, 1000)`。
8. **`7.0 / 2` 编译错**：`error: ambiguous coercion of division operands 'comptime_float' and 'comptime_int'`。写 `@as(f32, 7.0) / 2`。
9. **`@truncate` 的操作数必须无符号**：直接喂 `i32` → `error: expected unsigned integer type, found 'i32'`，有符号先 `@bitCast` 成无符号。`@truncate` 不检查值域（300 → 44），要检查用 `@intCast`。
10. **0.17 没有 `**` 幂运算符**（报的是莫名其妙的"空格不对称"），`[_]T{x} ** n` 也没了 → 用 `@splat(x)`、`1 << n` 或 `std.math.pow`。
11. **`@bitCast` 不接受裸结构体**（连 `extern struct` 也不行）：`error: cannot @bitCast from 'main.Header'`。走 `std.mem.asBytes` + `std.mem.readInt`/`writeInt`。顺带：`extern struct` 不许含 `u24` 这类非 2 的幂次位宽字段。
12. **`readInt`/`writeInt` 的字节序没有默认值**，必须显式 `.little` / `.big`。另外结构体末尾有 padding（`Header` 数据 6 字节但 `sizeOf = 8`），别把 `asBytes` 的结果直接写进文件。
13. **`@typeInfo(T).@"struct".tag` 已改名 `.layout`**（取值 `auto`/`.@"extern"`/`.@"packed"`）；**`std.meta.fields` 已废弃** → 用 `.@"struct".field_names` / `.field_types`。
14. **`field_types`（元素 `type`）和 `field_values`（元素 `comptime_int`）只能用 `inline for`**：普通 `for` 报 `values of type 'type' must be comptime-known` / `must be comptime-known, but index value is runtime-known`。理由：类型是编译期实体，运行期不存在。
15. **`@typeInfo(E).error_set.error_names` 是可空的** `?[]const [:0]const u8`，得 `if (x) |y|` 或 `.?`；元素是哨兵切片，打印要写 `n[0..n.len]`，写 `n[0..4 :0]` 报 `value in memory does not match slice sentinel`。
16. **0.17 改名**：`@intFromEnum` → `@backingInt`，`@intToEnum` → `@enumFromInt`；`builtin.mode == .Debug` → `.debug`；**`@hasDecl(T, ident)` 的第二个参数必须给字符串**（`@hasDecl(std.mem, "copyForwards")`），给标识符报 `use of undeclared identifier`；**作用域遮蔽被禁止**（内层块用同名变量报 `shadows local variable from outer scope`）；**浮点互转是向零截断不是四舍五入**（`@intFromFloat(-3.7) = -3`，要向下取整用 `@divFloor`；`@floatCast` 丢精度是静默的）。

---

上一章：[02 第一个程序](02-hello.md) · 下一章：[04 控制流](04-control.md)
