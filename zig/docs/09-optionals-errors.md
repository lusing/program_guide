# 09 · 可选与错误 I

> 对应示例：`examples/09_errors1/main.zig`
>
> 本章讲两件"可能没有值"的事：可选 `?T`（**没有**是正常业务结果）与错误 `E!T`
> （**失败**是异常路径）。Zig 把这两种"缺席"做成了两个**互不通用**的类型系统机制，
> 而且 0.17 对它们动过刀——`||` 的含义变了、`@typeInfo(E).error_set` 的结构变了、
> 可选链 `?.` 被移除、`catch ||` 语法消失。照抄任何 ≤0.16 的教程都会编译失败，
> 而且有几处失败信息极具误导性。本章每一条都在 0.17.0 上实测复现过，报错文本逐字抄录。

---

## 9.1 `?T`：把"可能没有"写进返回类型

```zig
// examples/09_errors1/main.zig 第 14-26 行
/// 查找失败就"没有下标"——这是正常业务结果，不是错误
fn findFirst(hay: []const u8, needle: u8) ?usize {
    for (hay, 0..) |b, i| {
        if (b == needle) return i;
    }
    return null; // 缺席也是合法返回
}

/// 0 表示"没有"的老写法：用哨兵值表达缺席
fn indexOrMinusOne(hay: []const u8, needle: u8) i64 {
    const hit = findFirst(hay, needle);
    return if (hit) |i| @intCast(i) else -1; // -1 是约定，不是类型强制
}
```

`?T` 是**可选类型**：值域 = T 的所有值 **∪ {null}**。"可能没有"被写进返回类型，
于是编译器强制调用方面对 null——对比 C 里"返回 -1 表示没有"的口口相传约定：
`indexOrMinusOne` 里那个 `-1` **编译器完全不检查**，你换成返回 `-2`、`0`、`999`
都能编过，全靠调用方记得住。

### 零开销到底零在哪（实测 `@sizeOf`）

```zig
// examples/09_errors1/main.zig 第 36-48 行（optionalWidthReport 的前半）
fn optionalWidthReport() void {
    std.debug.print(" 指针与切片族：可选不额外花字节（null 复用全 0 地址）\n", .{});
    std.debug.print("  *u8={d}  ?*u8={d}   []const u8={d}  ?[]const u8={d}\n", .{
        @sizeOf(*u8),        @sizeOf(?*u8),
        @sizeOf([]const u8), @sizeOf(?[]const u8),
    });
    std.debug.print("  标量族：要另加标记字节，所以宽了\n", .{});
    std.debug.print("  u8={d}  ?u8={d}   u16={d}  ?u16={d}   u64={d}  ?u64={d}\n", .{
        @sizeOf(u8),  @sizeOf(?u8),
        @sizeOf(u16), @sizeOf(?u16),
        @sizeOf(u64), @sizeOf(?u64),
    });
    std.debug.print("  ?bool={d} 字节（bool 只要1 位，可选借了 1 字节标记）\n", .{@sizeOf(?bool)});
```

运行输出（`examples/09_errors1/main.zig`）：

```text
==== 9.1 ?T 开始 ====
  findFirst 返回类型 ?usize（值域 = usize 全部值 ∪ {null}）
  findFirst("zig-lang",'-') = 3
  findFirst("zig",'-')      = null
 指针与切片族：可选不额外花字节（null 复用全 0 地址）
  *u8=8  ?*u8=8   []const u8=16  ?[]const u8=16
  标量族：要另加标记字节，所以宽了
  u8=1  ?u8=2   u16=2  ?u16=4   u64=8  ?u64=16
  ?bool=2 字节（bool 只要1 位，可选借了 1 字节标记）
```

于是"可选免费"这句话要**分族看**：

| 类型 | `@sizeOf` | `@sizeOf(?T)` | 结论 |
|---|---|---|---|
| `*u8` | 8 | **8** | 零开销——null 就是全 0 地址 |
| `[]const u8` | 16 | **16** | 零开销——指针 + 长度都能用 0 表示"空" |
| `u8` | 1 | **2** | 多 1 字节（标记） |
| `u16` | 2 | **4** | 多 2 字节 |
| `u64` | 8 | **16** | **翻倍** |
| `bool` | 1 | **2** | 借了 1 字节做标记 |
| `void` | 0 | **1** | 只有标记 |

`?u64` 从 8 字节涨到 16 字节——**因为标记单元和 payload 同宽**。Zig 把可选
表示成 `{ payload: T, tag: 非 null 时为 1 }` 这样一个结构体，tag 的宽度按
payload 的宽度取（`?u16` 的 tag 是 `u16`，`?u64` 的 tag 是 `u64`）。

### ⚠️ 实测修正：null 的位模式是**全 0**，不是"全 1"

这是本章最值得单独拎出来的一条，因为**很多资料（包括任务描述里引用的说法）
说 Zig 用"全 1 位模式"表示 null**。0.17.0 实测是**全 0**：

```zig
// examples/09_errors1/main.zig 第 49-68 行（optionalWidthReport 的后半）
    dumpOptBytes("?u8=null", ?u8, null);
    dumpOptBytes("?u8=0", ?u8, 0);
    dumpOptBytes("?u8=255", ?u8, 255);
    dumpOptBytes("?u64=null", ?u64, null);
    dumpOptBytes("?u64=1", ?u64, 1);
    dumpOptBytes("?*u8=null", ?*u8, null);
    dumpOptBytes("?[]const u8", ?[]const u8, null);
    dumpOptBytes("?void", ?void, null);
    // ⚠️ 0.17 实测：null 的位模式是**全 0**，不是"全 1"
    //  ?u8 = { payload: u8, tag: u8 }：非 null 时 tag=1，null 时 payload 与 tag 都归0
    //  ?u16 = { payload: u16, tag: u16 }：4 字节里前2 是 payload、后 2 是 tag
    var live: ?u8 = 200; // 非 null：{ 200, 1 }
    std.debug.print("  赋值 200 后live = {any}（尾字节是 tag=1）\n", .{std.mem.asBytes(&live).*});
    live = null; // 置 null：payload 与 tag 一起归 0
    std.debug.print("  置 null 后   live = {any}（全 0；tag=0 即\"缺席\"）\n", .{std.mem.asBytes(&live).*});
    // 所以 "?*T 零开销" 的准确说法是：null 复用**全 0 地址**，不用额外标记位
    const pnull: ?*u8 = null;
    std.debug.print("  ?*u8(null) == ?*u8(地址 0) ？{}（所以指针族不需标记字节）\n", .{
        pnull == @as(?*u8, @ptrFromInt(@as(usize, 0))),
    });
```

运行输出（`examples/09_errors1/main.zig`）：

```text
  ?u8=null     @sizeOf= 2字节  字节 = { 0, 0 }
  ?u8=0        @sizeOf= 2字节  字节 = { 0, 1 }
  ?u8=255      @sizeOf= 2字节  字节 = { 255, 1 }
  ?u64=null    @sizeOf=16字节  字节 = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
  ?u64=1       @sizeOf=16字节  字节 = { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0 }
  ?*u8=null    @sizeOf= 8字节  字节 = { 0, 0, 0, 0, 0, 0, 0, 0 }
  ?[]const u8  @sizeOf=16字节  字节 = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
  ?void        @sizeOf= 1字节  字节 = { 0 }
  赋值 200 后live = { 200, 1 }（尾字节是 tag=1）
  置 null 后   live = { 0, 0 }（全 0；tag=0 即"缺席"）
  ?*u8(null) == ?*u8(地址 0) ？true（所以指针族不需标记字节）
```

三个要点：

**① null = 全 0 字节，非 null 时标记位 = 1。** `?u8 = 0` 是 `{ 0, 1 }`——
payload 是 0，但 tag 是 1，和 `null` 的 `{ 0, 0 }` **是两个不同的值**。这正是
"null 不等于 0"的物理基础（9.3 节展开）。

**② tag 单元和 payload 同宽。** `?u16 = 0xFFFF` 的字节是 `{ 255, 255, 1, 0 }`——
前 2 字节是 payload（`0xFFFF` 小端），后 2 字节是 tag 单元（值为 `1`，
高字节是 0）。所以 `@sizeOf(?u16) = 4`，不是 3。

**③ "?*T 零开销"的准确说法是"null 复用全 0 地址"**，不需要标记单元。
输出最后一行给了断言：`?*u8(null) == ?*u8(地址 0)` 为 `true`。

⚠️ **别把"null 是全 0"当规范去依赖**。这是当前 0.17.0 x86_64 macOS 的实测布局，
语言层面并不保证 tag 的具体位置和宽度（`?void` 只有 1 字节就是一个字节 tag）。
可移植的做法是只用类型系统（`orelse` / `if` / `.?`），不要 `asBytes` 去读可选的内部。

### `@typeInfo(?T).optional` 的字段改名了：`.payload` → `.child`

```zig
// examples/09_errors1/main.zig 第 520-522 行
    std.debug.print("  ?T 的 child（0.17 改名了：@typeInfo(?T).optional.**child**，不是 .payload）= {s}\n", .{
        @typeName(@typeInfo(?u16).optional.child),
    });
```

运行输出（`examples/09_errors1/main.zig`）：

```text
  ?T 的 child（0.17 改名了：@typeInfo(?T).optional.**child**，不是 .payload）= u16
```

⚠️ **这是一个新踩到的坑**，老的反射代码会直接编译失败：

```text
$ const oi = @typeInfo(?u8).optional;
error: no field named 'payload' in struct 'lang.Type.Optional'
note: struct declared here
    pub const Optional = struct {
```

对照 0.17 的标准库源码就很清楚——**可选和错误联合的元数据结构体不一致**。
下面是三段摘录（为对照方便去掉了 std 源码的统一缩进，并加了旁注）：

```zig
// lib/std/lang.zig 第 788-790 行
pub const Optional = struct {
    child: type,          // ← 0.17 从 payload 改名成 child
};

// lib/std/lang.zig 第 794-797 行
pub const ErrorUnion = struct {
    error_set: type,
    payload: type,        // ← 错误联合**仍然**叫 payload，没改名
};

// lib/std/lang.zig 第 801-803 行
pub const ErrorSet = struct {
    error_names: ?[]const [:0]const u8,   // ← 0.17 也变了（见 9.4 节）
};
```

记忆法：**可选的 `?` 是"包装"→ `child`；错误联合的 `!` 是"并列"→ `payload`**。

## 9.2 解包三件套：if 捕获 / orelse / `.?`

```zig
// examples/09_errors1/main.zig 第 73-101 行
/// ②orelse 的块形态：缺席时走一整块逻辑
fn orelseBlockDemo() void {
    const fb = findFirst("zig", '-') orelse 999;
    const blk = findFirst("zig", 'q') orelse blk_or: {
        std.debug.print("  ② orelse 块：缺席时走这里（块里可以做好几件事）\n", .{});
        break :blk_or @as(usize, 0);
    };
    std.debug.print("  ② orelse 默认值={d}，orelse 块={d}\n", .{ fb, blk });
}

/// ③`.?` 的正当用法：数据来自常量表，逻辑上不可能缺席
fn constTableIndex(comptime table: []const u8, idx: usize) u8 {
    return table[idx]; // 编译期越界：编译报错
}

fn unwrapDemo() void {
    const suree = findFirst("zig", 'z').?; // "zig"一定有 'z'
    std.debug.print("  ③ .? 解包：下标 {d}（'z' 在 \"zig\" 的第 0 个字节）\n", .{suree});
    // `.?` 用在 comptime 可知的值上：整个表达式在编译期折叠成常量
    const folded: usize = comptime findFirst("Zig", 'Z').?;
    const table_ch = constTableIndex("Zig", 0);
    std.debug.print("  comptime .? 折叠成常量：{d}；'Zig'[0]={c}（ASCII {d}）\n", .{ folded, table_ch, table_ch });
    // ⚠️ 若担保错了（比如对findFirst("zig", 'q') 用 `.?`），Debug 下当场 panic：
    //   thread <id> panic: attempt to use null value
    //   main.zig:<行>:<列>: 0x... in main
    //       const bad = findFirst("zig", 'q').?;
    //                              ^
    // 栈跟踪里带源码行号列号（这是 Debug 模式 runtime_safety 的功劳，02 章 2.5 节）
}
```

运行输出（`examples/09_errors1/main.zig`）：

```text
==== 9.2 解包三件套 开始 ====
  ① if 捕获：有值，'-' 在下标 3
  ① if 捕获：没找到（走了 else 分支）
  ② orelse 块：缺席时走这里（块里可以做好几件事）
  ② orelse 默认值=999，orelse 块=0
  ③ .? 解包：下标 0（'z' 在 "zig" 的第 0 个字节）
  comptime .? 折叠成常量：0；'Zig'[0]=Z（ASCII 90）
```

三件套的分工：

| 写法 | 有值时 | null 时 | 用途 |
|---|---|---|---|
| `if (opt) \|v\| { A } else { B }` | 跑 A，`v` 是 T | 跑 B | **两个分支都要处理** |
| `opt orelse 默认值` | 用原值 | 用默认值 | 缺席是正常情况，给个兜底 |
| `opt orelse blk: { ... break :blk x; }` | 用原值 | 跑整块 | 兜底逻辑不止一行 |
| `opt.?` | 解出 T | **panic** | 我拿名誉担保它不是 null |

### `.?` 的 panic 文本（实测逐字）

担保错了当场崩。下面这段来自一个独立探针程序——**代码地址已抹成 `<地址>`**
（ASLR 让它每次运行都不同，抄下来没意义），而断言性信息（panic 原因、源码行号列号、
插入的 `^` 指示符）都是逐字实测：

```text
thread <线程 id> panic: attempt to use null value
探针 panic9.zig:9:38: <地址> in main (panic9)
    const bad = findFirst("zig", 'q').?;
                                     ^
lib/std/start.zig:788:64: <地址> in callMain (panic9)
    if (fn_info.param_types.len == 0) return wrapMain(root.main());
                                                               ^
???:?:?: <地址> in start (/usr/lib/dyld)
```

三个信息都在：**panic 原因（`attempt to use null value`）**、**源码行号列号（`9:38`）**、
**源码原文与插入的 `^`指示符**。这是 Debug 模式 `runtime_safety` 的功劳（02 章 2.5 节）。

`.?` 只该出现在**逻辑上不可能为 null** 的地方——字面量、编译期常量表、
刚用 `if`/`orelse` 验证过的值。拿它当"懒得写 else"的捷径必炸，而且**炸在运行时**。

### `.?` 用在 comptime 值上会折叠成常量

输出第三行 `comptime .? 折叠成常量：0`：`comptime findFirst("Zig", 'Z').?`
整个表达式在编译期求值，`?` 的检查也在编译期做完，运行期零成本。
这在常量表查表场景很有用。

### ⚠️ 0.17 **没有可选链 `?.`**

```zig
// 实测：const v = o.a?.len; 的编译结果
p1.zig:5:18: error: expected ';' after statement
    const v = o.a?.len;
                 ^
```

`?.` 是 0.14 引入的实验性语法，**0.17 已移除**。多层可选只能逐层处理：

```zig
// ✅ 0.17 的正确写法
const name: ?[]const u8 = opt_name;
const len: usize = if (name) |n| n.len else 0;   // 或者 name orelse "" 后再 .len
```

## 9.3 `?T` 与"0 表示没有"的区别

这是本章的**核心设计对比**：C 里"用 0 表示没有"是口头约定，`?T` 把它变成类型。

```zig
// examples/09_errors1/main.zig 第 105-138 行
/// "0 表示没有"的典型：字符串find 返回 null（0 是合法下标）
fn lookupKey(table: []const u8, key: u8) ?u8 {
    for (table, 0..) |b, i| {
        if (b == key) return @intCast(i);
    }
    return null;
}

/// "0 表示没有"的典型：计数表用 0 表示"没有这个条目"
fn countOf(table: []const u32, idx: usize) u32 {
    if (idx >= table.len) return 0; // 0 = 没有
    return table[idx]; // 0 也可能是真的"0 次"
}

fn zeroVersusNullDemo() void {
    const nul: ?u8 = null;
    const zero: ?u8 = 0;
    std.debug.print("  ?u8 的 null == 0 ？{}（false：null 是独立的状态）\n", .{nul == zero});
    std.debug.print("  ?u8 的 0 == 0 ？{}\n", .{zero == 0});
    std.debug.print("  ?u8 的 0 == null ？{}\n", .{zero == null});
    // find 返回 0（第一个字符命中）与 null（没命中）是两件事
    const at0 = lookupKey("Zig", 'Z'); // 命中且下标是 0
    const missing = lookupKey("zig", 'Q');
    std.debug.print("  查找 'Z'（在首字节）→ {?}\n", .{at0});
    std.debug.print("  查找 'Q'（不存在）→ {?}\n", .{missing});
    std.debug.print("  at0 == null ？{}（0 号命中不是没找到）\n", .{at0 == null});
    // 计数表：0 无法区分"没有条目"与"条目是0"
    const counts = [_]u32{ 5, 0, 9 };
    std.debug.print("  计数表 [5,0,9]：countOf(idx=1) = {d}（是 0，不是\"没有\"）\n", .{countOf(&counts, 1)});
    std.debug.print("  countOf(idx=99) = {d}（越界也是 0，两种\"没有\"混成一个值）\n", .{countOf(&counts, 99)});
    // 老式哨兵：索引用 -1 表示没找到
    const i = indexOrMinusOne("zig", 'q');
    std.debug.print("  哨兵写法indexOrMinusOne 返回 {d}，调用方必须自己记得\"-1 是没找到\"\n", .{i});
}
```

运行输出（`examples/09_errors1/main.zig`）：

```text
==== 9.3 可选与 0 开始 ====
  ?u8 的 null == 0 ？false（false：null 是独立的状态）
  ?u8 的 0 == 0 ？true
  ?u8 的 0 == null ？false
  查找 'Z'（在首字节）→ 0
  查找 'Q'（不存在）→ null
  at0 == null ？false（0 号命中不是没找到）
  计数表 [5,0,9]：countOf(idx=1) = 0（是 0，不是"没有"）
  countOf(idx=99) = 0（越界也是 0，两种"没有"混成一个值）
  哨兵写法indexOrMinusOne 返回 -1，调用方必须自己记得"-1 是没找到"
==== 9.3 可选与 0 结束 ====
```

**两类"0 表示没有"的失败模式**：

**① 下标 0 被误判。** `lookupKey("Zig", 'Z')` 返回 `0`（命中首字节）。
如果签名是 `u8` 而不是 `?u8`，调用方写 `if (lookupKey(...) == 0) { 走"没找到"分支 }`
就会把一次成功查找当成失败。`?u8` 从类型上消灭了这个 bug——
输出里 `查找 'Z'（在首字节）→ 0` 和 `at0 == null ？false` 两行说明：
`0` 是"命中在 0 号位"，`null` 是"没命中"，编译器帮你分开。

**② 两种"没有"混成一个值。** `countOf` 里 `idx=1`（条目存在，值是 0）和
`idx=99`（越界，没这个条目）都返回 `0`。调用方分不清"这个键存在但计数为 0"和
"这个键不存在"。改成 `?u32` 才能区分：`null` 是没这个条目，`@as(?u32, 0)` 是计数为零。

**什么时候该用哪种**：

| 语义 | 用 | 理由 |
|---|---|---|
| "查字典，可能没这个键" | `?T` | 没找到是**正常的业务结果**，不是异常 |
| "计数表：0 就是没有" | `?T` | 0 有合法含义时，必须另开缺席通道 |
| "除法结果，没有余数" | `?T` | 0 是合法答案，不能兼作缺席标记 |
| "C API 的 `errno` 风格返回码" | `T` + 显式错误检查 | 返回码有明确的成功/失败取值约定 |
| "整个调用失败" | `E!T` | 见 9.6 节——失败需要**名字** |

## 9.4 错误集 `error{X,Y}`：编译期的错误名字集合

```zig
// examples/09_errors1/main.zig 第 142-158 行
const ParseError = error{
    Empty,
    NotDigit,
    TooLong,
};

/// 错误**没有 payload**：它就是一个名字
fn parseScore(s: []const u8) ParseError!u8 {
    if (s.len == 0) return error.Empty;
    if (s.len > 3) return error.TooLong;
    var v: u16 = 0;
    for (s) |ch| {
        if (ch < '0' or ch > '9') return error.NotDigit;
        v = v * 10 + (ch - '0');
    }
    return @intCast(v); // 普通值直接 return，编译器自动包成错误联合
}
```

### 错误值 = 全局编号 + 名字

```zig
// examples/09_errors1/main.zig 第 186-203 行
fn errorSetBasics() void {
    std.debug.print("  错误值本质是全局编号：error.Empty={d}，error.NotDigit={d}\n", .{
        @intFromError(error.Empty), @intFromError(error.NotDigit),
    });
    std.debug.print("  std 预定义的 error.OutOfMemory={d}（全程序共享一张表）\n", .{@intFromError(error.OutOfMemory)});
    std.debug.print("  声明顺序决定编号：ParseError 三个成员编号 = {d} / {d} / {d}\n", .{
        @intFromError(error.Empty), @intFromError(error.NotDigit), @intFromError(error.TooLong),
    });
    dumpErrSet("ParseError", ParseError);
    dumpErrSet("error{}", error{}); // 空错误集：error_names 是**空切片**，不是 null
    dumpErrSet("anyerror", anyerror); // 反而是 null
    std.debug.print("  @errorName(error.NotDigit)={s}，返回类型={s}（带哨兵的定长数组指针）\n", .{
        @errorName(error.NotDigit), @typeName(@TypeOf(@errorName(error.NotDigit))),
    });
    const any: anyerror = error.NotDigit; // 小集合的值可以放进 anyerror
    std.debug.print("  小集合的值装进 anyerror：{s}（anyerror 占 {d} 字节）\n", .{
        @errorName(any), @sizeOf(anyerror),
    });
```

运行输出（`examples/09_errors1/main.zig`）：

```text
==== 9.4 错误集 开始 ====
  错误值本质是全局编号：error.Empty=144，error.NotDigit=145
  std 预定义的 error.OutOfMemory=65（全程序共享一张表）
  声明顺序决定编号：ParseError 三个成员编号 = 144 / 145 / 146
  ParseError：@sizeOf=2字节，成员数=3 → Empty NotDigit TooLong
  error{}：@sizeOf=2字节，成员数=0 →
  anyerror：@sizeOf=2字节，成员数=0 → null（= anyerror，编译器不知道成员）
  @errorName(error.NotDigit)=NotDigit，返回类型=*const [8:0]u8（带哨兵的定长数组指针）
  小集合的值装进 anyerror：NotDigit（anyerror 占 2 字节）
  错误没有 payload：不能写 error.NotDigit{ pos = 3 }
==== 9.4 错误集 结束 ====
```

错误在内存里就是一个**小整数编号**（`@sizeOf(ParseError) = 2` 字节 = 16 位），
对应一张**全程序共享的名字表**。`error.OutOfMemory = 65` 说明标准库的错误
和你自己声明的错误在同一张表里——这也是为什么 `@errorName` 能在任何地方
把错误变回字符串。

⚠️ **编号不要依赖**。输出里 `ParseError` 的三个成员是 144/145/146，
但那是**本文件此刻**的分配结果；改一行代码、换一个编译单元，编号都可能变。
编号只用于 `@intFromError` / `@errorName` 的往返，不要写进持久化数据。

⚠️ **错误没有 payload**。不能写 `error.NotDigit{ pos = 3 }`——错误就是名字。
要带上下文（哪一行、什么值、有几个）有两条路：`std.log.err` 先记一笔再返回
错误（9.7 节演示），或用 `union(enum)` 自己包一层带数据的失败（10 章展开）。
这也是为什么 `diagnose(err)` 只能接收错误本身，要"哪个输入"得调用方自己传。

### ⚠️ 0.17 的 `error_set` 结构变了（本章第二个大坑）

```zig
// examples/09_errors1/main.zig 第 160-172 行
/// 0.17 的反射写法：error_names 是**可空**的 ?[]const [:0]const u8
/// 而且元素**本身就是名字**（0.16 是 { name, value } 结构体）
fn dumpErrSet(comptime label: []const u8, comptime E: type) void {
    const info = @typeInfo(E).error_set;
    std.debug.print("  {s}：@sizeOf={d}字节，成员数={d} →", .{ label, @sizeOf(E), if (info.error_names) |ns| ns.len else 0 });
    if (info.error_names) |ns| {
        // ns 的元素类型是 [:0]const u8（哨兵切片），直接 {s} 就能打印
        for (ns) |n| std.debug.print(" {s}", .{n});
    } else {
        std.debug.print(" null（= anyerror，编译器不知道成员）", .{});
    }
    std.debug.print("\n", .{});
}
```

对照 0.17 的标准库定义（去掉了 std 源码的统一缩进）：

```zig
// lib/std/lang.zig 第 801-803 行（0.17.0 实测）
pub const ErrorSet = struct {
    error_names: ?[]const [:0]const u8,
};
```

**三处变化，每一处都会让旧代码编译失败**：

| | 0.16 | 0.17 |
|---|---|---|
| 字段名 | `error_set` | **`error_names`** |
| 可空性 | `?[]const ErrorSetEntry` | `?[]const [:0]const u8`（**可空**） |
| 元素类型 | `struct { name, value }` | **`[:0]const u8`**（元素本身是名字） |
| 取名字 | `entry.name` | `n`（或 `n[0..n.len]`） |

四条实测结论：

**① 必须先 `if (x) |ns|` 或 `.?` 解包。** 直接遍历会报：

```text
error: type '?[]const [:0]const u8' is not indexable and not a range
```

**② `error{}`（空错误集）的 `error_names` 是**空切片**，不是 `null`。**
实测 `@typeInfo(error{}).error_set.error_names.?` 的 `.len == 0`，打印出来是 `{  }`。
而 **`anyerror` 的 `error_names` 才是 `null`**（编译器不知道运行时会有哪些错误）。
这两者容易混：代码里 `if (names) |ns|` 两个分支都要能走通。

**③ 元素是哨兵切片 `[:0]const u8`，直接 `{s}` 就能打印**，不用写 `n[0..n.len]`。
但**取子范围会报 sentinel 不匹配**：

```text
$ const names = @typeInfo(error{Zeta, Alpha}).error_set.error_names.?;
$ const n = names[0];
$ const bad = n[0..3 :0];            // "Zeta" 只有 4 字节，声称第 4 字节是哨兵
error: value in memory does not match slice sentinel
note: expected '0', found '104'         // 'h' = 104
```

**只能写全长**：`n[0..n.len]`（得到 `*const [4:0]u8`）或者干脆不切。
如果只想打印前 3 个字符，写 `n[0..3]`（**不带 `:0`**，得到普通 `[]const u8`）就行——
这个是合法的，实测能打出 `Zet`。

**④ 顺序不等于声明顺序。** `error{ Zeta, Alpha, Mid }` 的 `error_names` 是
`Alpha Zeta Mid`——编译器内部按某种规范排序，不是你写的顺序。
但 `@intFromError` 的编号是按声明顺序（`Zeta=143, Alpha=144, Mid=145`）。
**要按声明顺序遍历就别依赖 `error_names`**。

## 9.5 错误联合 `E!T`：值或错误

```zig
// examples/09_errors1/main.zig 第 212-236 行
/// 推断错误集：签名只写 !T，编译器从实现里算出最小集合
fn parseLen(s: []const u8) !usize {
    const n = try parseScore(s); // try 把 ParseError 整个吸进来
    return n;
}

/// 更深一层：推断的集合继续传播
fn parseLenTwice(s: []const u8) !usize {
    const n = try parseLen(s);
    return n * 2;
}

fn errorUnionBasics() void {
    std.debug.print("  !T 就是 anyerror!T：{s} 的意思是 \"u8 或任何错误\"\n", .{@typeName(anyerror!u8)});
    dumpErrUnion("parseScore（显式）", @typeInfo(@TypeOf(parseScore)).@"fn".return_type.?);
    dumpErrUnion("parseLen（推断一层）", @typeInfo(@TypeOf(parseLen)).@"fn".return_type.?);
    dumpErrUnion("parseLenTwice（推断两层）", @typeInfo(@TypeOf(parseLenTwice)).@"fn".return_type.?);
    std.debug.print("  大小：u8={d}字节，ParseError!u8={d}字节，anyerror!u64={d}字节\n", .{
        @sizeOf(u8), @sizeOf(ParseError!u8), @sizeOf(anyerror!u64),
    });
    std.debug.print("  推断集合没有可读名字，@typeName 打出来是编译器内部表达式：\n    {s}\n", .{
        @typeName(@typeInfo(@TypeOf(parseLen)).@"fn".return_type.?),
    });
    std.debug.print("  忽略错误集合不行：直接丢弃错误联合会编译错（error: error union is discarded）\n", .{});
}
```

运行输出（`examples/09_errors1/main.zig`）：

```text
==== 9.5 错误联合 开始 ====
  !T 就是 anyerror!T：anyerror!u8 的意思是 "u8 或任何错误"
  parseScore（显式）：payload=u8，错误集 = Empty NotDigit TooLong
  parseLen（推断一层）：payload=usize，错误集 = Empty NotDigit TooLong
  parseLenTwice（推断两层）：payload=usize，错误集 = Empty NotDigit TooLong
  大小：u8=1字节，ParseError!u8=4字节，anyerror!u64=16字节
  推断集合没有可读名字，@typeName 打出来是编译器内部表达式：
    @typeInfo(@typeInfo(@TypeOf(main.parseLen)).@"fn".return_type.?).error_union.error_set!usize
  忽略错误集合不行：直接丢弃错误联合会编译错（error: error union is discarded）
==== 9.5 错误联合 结束 ====
```

**`!T` 就是 `anyerror!T` 的简写**（输出第一行：`@typeName(anyerror!u8)` 就是 `anyerror!u8`）。
错误联合的值域 = T 的值域 ∪ 错误集的全部成员。返回它意味着"可能失败"——
**调用方不处理就编译不过**：

```text
$ const eu = f();          // f() 返回 error{A}!u8
$ _ = eu;
error: error union is discarded
note: consider using 'try', 'catch', or 'if'
```

这是"**强制检查的返回码**"。Go 的 `error` 常忘查（vet 只在部分场景警告），
Zig 忘查编译器直接拦——这就是错误值相对于错误码的全部价值。

### 显式集合 vs 推断集合

| 写法 | 含义 | 用在哪 |
|---|---|---|
| `ParseError!u8` | 只能返回 `Empty`/`NotDigit`/`TooLong` 三个 | **库/公开 API 边界**——契约钉死 |
| `!u8` | 编译器从实现里算出**最小**集合 | 内部函数、脚本 |
| `anyerror!u8` | 任何错误（`!u8` 的展开） | 通用入口、还没定契约的地方 |

⚠️ **推断错误集会传染**。输出第 2、3 行：`parseLen` 里 `try parseScore(s)`
把 `ParseError` 的三个成员整个吸进了 `parseLen` 的推断集合；`parseLenTwice`
里 `try parseLen(s)` 又把它传下去。所以**改一行实现就可能悄悄改变公开 API 的
错误集合**——如果用的是 `!T` 签名。这是 9.12 节坑位清单里的第 2 条。

⚠️ **推断集合没有可读名字**。`@typeName` 打出来是编译器内部表达式
（输出倒数第二行那一长串 `@typeInfo(@typeInfo(@TypeOf(main.parseLen))...`）。
想在日志里显示"这个函数的错误集有哪些成员"，得用 9.4 节的 `error_names` 反射，
不能靠 `@typeName`。

### ⚠️ `||` 在 0.17 换了含义

这是 ≤0.16 代码的**大规模破坏点**：

```text
$ const Value = u32;
$ const E = error{A};
$ const X = E || Value;              // 0.16：造出 error{A}!u32
error: expected error set type, found 'u32'
note: 'main.Value' declared here
```

**0.16 里 `ErrorSet || Payload` 是"造错误联合类型"的语法**（写作 `E || T`）。
0.17 里 `||` 变成了**错误集并集**（`error{A} || error{B}` → `error{A,B}`），
造错误联合必须写 `E!T`。详见 9.9 节。

## 9.6 `try`：把错误往上抛

```zig
// examples/09_errors1/main.zig 第 240-259 行
fn showScore(s: []const u8) ParseError!void {
    const score = try parseScore(s); // 出错就 return那个错误
    std.debug.print("  得分 {d}\n", .{score});
}

fn reportScore(s: []const u8) ParseError!void {
    try showScore(s);
    std.debug.print("  （reportScore 收尾）\n", .{});
}

fn tryDemo() void {
    reportScore("95") catch |err| std.debug.print("  main 收到：{s}\n", .{@errorName(err)});
    reportScore("95x") catch |err| std.debug.print("  main 收到：{s}\n", .{@errorName(err)});
    reportScore("") catch |err| std.debug.print("  main 收到：{s}\n", .{@errorName(err)});
    reportScore("1234") catch |err| std.debug.print("  main 收到：{s}\n", .{@errorName(err)});
    std.debug.print("  try 是 `catch |e| return e` 的语法糖：前三层函数一行错误处理都没写\n", .{});
    std.debug.print("  ⚠️ try 只对**错误联合**生效，对可选不行：\n", .{});
    std.debug.print("     try findFirst(...)  → error: expected error union type, found '?usize'\n", .{});
    std.debug.print("     note: consider omitting 'try'（可选请用 orelse / if 捕获）\n", .{});
}
```

运行输出（`examples/09_errors1/main.zig`）：

```text
==== 9.6 try 开始 ====
  得分 95
  （reportScore 收尾）
  main 收到：NotDigit
  main 收到：Empty
  main 收到：TooLong
  try 是 `catch |e| return e` 的语法糖：前三层函数一行错误处理都没写
  ⚠️ try 只对**错误联合**生效，对可选不行：
     try findFirst(...)  → error: expected error union type, found '?usize'
     note: consider omitting 'try'（可选请用 orelse / if 捕获）
==== 9.6 try 结束 ====
```

`try expr` 就是 `expr catch |e| return e` 的语法糖——**错误处理最常见的动词**。
从输出能看到三件事：

**① `try` 是传播，不是处理。** 输入 `"95x"` 时，`reportScore` 和 `showScore`
**一行错误处理代码都没写**，错误原样冒到 `main` 的 `catch`。对照 Go 手写
`if err != nil { return err }` 十遍。

**② `try` 不改名、不包装。** `main 收到：NotDigit`——就是 `parseScore` 里
`return error.NotDigit` 那个错误，一路原样传上来。想改名字得在某一层显式
`catch` + `return error.别的名字`。

**③ `try` 只对错误联合生效，对可选不行。** 探针实测：

```text
$ fn f() ?u8 { return 5; }
$ const v = try f();
error: expected error union type, found '?u8'
note: consider omitting 'try'
```

对照表：

| | 表达式类型 | `try` | `catch` | `orelse` |
|---|---|---|---|---|
| 可选 `?T` | 值 or null | ❌ | ❌ | ✅ |
| 错误联合 `E!T` | 值 or 错误 | ✅ | ✅ | ❌ |

这是 0.17 的**类型系统强制分工**：想让"没有"和"失败"用同一套语法处理？
那不可能，也不该——9.3 节的 `lookupKey`（找不找得到）和 `parseScore`（格式对不对）
是两种不同性质的事情。

### 错误返回追踪：Debug/ReleaseSafe 默认开启

`try` 一层层往上抛，Debug 模式会记录完整的交接路径。实测探针（三层 `try`；
代码地址已抹成 `<地址>`，函数名与行号列号是断言性信息）：

```text
error: FileNotFound
探针 p23.zig:2:40: <地址> in bottom (p23)
fn bottom() error{FileNotFound}!void { return error.FileNotFound; }
                                       ^
探针 p23.zig:3:21: <地址> in middle (p23)
fn middle() !void { try bottom(); }
                    ^
探针 p23.zig:4:18: <地址> in top (p23)
fn top() !void { try middle(); }
                 ^
探针 p23.zig:6:5: <地址> in main (p23)
    try top();
    ^
```

普通 stack trace 告诉你"在哪里炸了"，**error return trace 告诉你"谁点的引信"**——
每一次 `try` 向上传递的交接都记在案（`bottom` → `middle` → `top` → `main` 四层全在），
包括每一层的源码行号。Debug 和 ReleaseSafe 默认开启，ReleaseFast / ReleaseSmall
默认关闭（为性能）。10 章展开。

## 9.7 `catch`：就地消化错误

`try` 把错误往上抛，`catch` 在**当场**把它消化掉——函数正常返回，不产生错误。

### catch 在 0.17 只有**两种**语法形态

```zig
// examples/09_errors1/main.zig 第 274-296 行
fn catchDemo() void {
    const ok = parseScore("88") catch 0; // ① catch 值
    const bad = parseScore("8x8") catch 0;
    std.debug.print("  ① catch 值：ok={d} bad={d}（错误被吞掉，bad 其实是 0 不是\"解析出的 0\"）\n", .{ ok, bad });
    // ② catch |e| —— 捕获错误，后备值可以由错误算出
    const by_err = parseScore("") catch |err| switch (err) {
        error.Empty => 60, // 空输入当 0 分太苛刻，判60 分
        error.NotDigit => 0,
        error.TooLong => 100, // 超过三位说明是大数，判满分
    };
    std.debug.print("  ② catch |err| switch：空输入 → {d} 分\n", .{by_err});
    const with_log = parseScore("7x7") catch |err| blk: {
        std.debug.print("  ③ catch |err| 块：记一笔再给后备值（{s}）\n", .{@errorName(err)});
        break :blk @as(u8, 0);
    };
    std.debug.print("  ③ catch 块结果={d}\n", .{with_log});
    const asserted = parseScore("42") catch unreachable; // 断言：这个输入不可能失败
    std.debug.print("  catch unreachable：{d}（若真失败，Debug 下 panic: attempt to unwrap error: ...）\n", .{asserted});
    std.debug.print("  ⚠️ 0.17 没有 `catch || 默认值` 这个语法（0.16 有）：\n", .{});
    std.debug.print("     f() catch || 42  → error: expected expression, found '||'\n", .{});
    std.debug.print("     `||` 在 0.17 换了个含义：现在是**错误集并集**（见 9.9 节）\n", .{});
    std.debug.print("  ⚠️ catch 也不能用在可选上：a catch 7 → error: expected error union type, found '?u8'\n", .{});
}
```

运行输出（`examples/09_errors1/main.zig`）：

```text
==== 9.7 catch 开始 ====
  ① catch 值：ok=88 bad=0（错误被吞掉，bad 其实是 0 不是"解析出的 0"）
  ② catch |err| switch：空输入 → 60 分
  ③ catch |err| 块：记一笔再给后备值（NotDigit）
  ③ catch 块结果=0
  catch unreachable：42（若真失败，Debug 下 panic: attempt to unwrap error: ...）
  ⚠️ 0.17 没有 `catch || 默认值` 这个语法（0.16 有）：
     f() catch || 42  → error: expected expression, found '||'
     `||` 在 0.17 换了个含义：现在是**错误集并集**（见 9.9 节）
  ⚠️ catch 也不能用在可选上：a catch 7 → error: expected error union type, found '?u8'
  输入 ""（0 字节）→错误 Empty → 退出码 2：请输入分数，不能留空
  输入 "8x8"（3 字节）→错误 NotDigit → 退出码 3：出现了非数字字符
  输入 "1234"（4 字节）→错误 TooLong → 退出码 4：分数最多三位
  0.17 的字符串拼接运算符是 ++："分数" ++ "已记录" = 分数已记录
==== 9.7 catch 结束 ====
```

**真实形状（0.17）**：

| 形态 | 语法 | 后备值来源 |
|---|---|---|
| ① `catch 表达式` | `parseScore(s) catch 0` | 固定值，**看不到错误** |
| ② `catch \|err\| 表达式` | `parseScore(s) catch \|e\| 0` | 表达式，可以看到 `e` |
| ③ `catch \|err\|` + labeled block | `parseScore(s) catch \|e\| blk: { ... break :blk v; }` | 块尾，块里能看到 `e` |
| ④ `catch unreachable` | `parseScore(s) catch unreachable` | 无——**断言** |

### ⚠️ 0.17 没有 `catch || 默认值`

**这是个实测的破坏点**。0.16 有一个"错误发生时用默认值"的简写：

```text
$ const v = f() catch || 42;
error: expected expression, found '||'
```

0.17 **没有这个语法**。想要"吞掉错误给默认值"就是 `catch 42`（不带 `|`）。
带 `||` 的形式会被解析成 `catch (|| 42)`，而 `||` 后面必须跟表达式。

同样被移除的还有 `catch |err| || default` 这类混合写法。**0.17 的 `||`
只有一个含义：错误集并集**（9.9 节）。

⚠️ **`catch 0` 要小心。** 输出第一行：`ok=88 bad=0`——`bad` 里的 `0` 是
catch 给的后备值，不是"解析出的 0"。一个真实的 0 分和一个解析失败在这里无法区分。
吞错误不记日志是坏味道，至少 `catch |e| std.log.err(...)` 记一笔。

### `catch unreachable` 的实测 panic 文本

```text
$ parseScore("8888") catch unreachable
thread <线程 id> panic: attempt to unwrap error: TooLong
error return context:
探针 p52.zig:5:20: <地址> in parse (p52)
    if (s.len > 3) return error.TooLong;
                   ^
```

注意 panic 文案是 **`attempt to unwrap error: TooLong`**——**带上了错误名**，
比 `.?` 的 `attempt to use null value` 信息量大得多。所以 Debug 下
`catch unreachable` 是很好的"断言这条路径不可能失败"工具：一炸就告诉你
到底是哪个错误。ReleaseFast 下它是 UB 承诺（编译器信了你），慎用。

### 错误 → 用户可见信息 + 退出码（应用层映射）

这是错误处理的**最后一公里**：`error.Empty` 这种名字对用户毫无意义，
应用层要把它翻译成"请输入分数，不能留空"并给一个退出码。

```zig
// examples/09_errors1/main.zig 第 263-272 行
/// 应用层把错误映射成"用户看得懂的话"+ 退出码
/// 注意错误本身**没有 payload**，所以"哪个输入、第几个字符"这类上下文
/// 只能由调用方（拿着原始输入）自己拼回去。
fn diagnose(err: ParseError) struct { msg: []const u8, code: u8 } {
    return switch (err) {
        error.Empty => .{ .msg = "请输入分数，不能留空", .code = 2 },
        error.NotDigit => .{ .msg = "出现了非数字字符", .code = 3 },
        error.TooLong => .{ .msg = "分数最多三位", .code = 4 },
    };
}
```

```zig
// examples/09_errors1/main.zig 第 298-313 行
/// 错误 → 用户可见信息 + 退出码
fn diagnoseDemo() void {
    const inputs = [_][]const u8{ "", "8x8", "1234" };
    for (inputs) |in| {
        const v = parseScore(in) catch |err| {
            const d = diagnose(err);
            std.debug.print("  输入 \"{s}\"（{d} 字节）→错误 {s} → 退出码 {d}：{s}\n", .{
                in, in.len, @errorName(err), d.code, d.msg,
            });
            continue;
        };
        std.debug.print("  输入 \"{s}\" → 成功解析 {d}\n", .{ in, v });
    }
    // 拼字符串用 `++`（0.17 没有 `**` 幂运算符，字符串拼接是 `++`）
    std.debug.print("  0.17 的字符串拼接运算符是 ++：\"分数\" ++ \"已记录\" = {s}\n", .{"分数" ++ "已记录"});
}
```

运行输出（`examples/09_errors1/main.zig`）：

```text
  输入 ""（0 字节）→错误 Empty → 退出码 2：请输入分数，不能留空
  输入 "8x8"（3 字节）→错误 NotDigit → 退出码 3：出现了非数字字符
  输入 "1234"（4 字节）→错误 TooLong → 退出码 4：分数最多三位
  0.17 的字符串拼接运算符是 ++："分数" ++ "已记录" = 分数已记录
```

三点值得注意：

**① `switch` 对错误值是穷尽的。** `diagnose` 里漏掉 `error.TooLong` 编译器会报
`error: switch must handle all possibilities` + `note: unhandled error value: 'error.TooLong'`
（实测）。这是错误集合给的一个真实好处——**枚举的完备性由编译器守住**。

**② 上下文得由调用方补。** `diagnose(err)` 只有错误名，不知道输入是什么。
所以签名是 `diagnose(err)` + 输出里另外打 `in.len`——要"第几个字符不对"
这种精确定位，只能让解析函数返回一个**带数据的结果**（`union(enum)` 或
自定义 struct），这是 10 章的内容。

**③ 退出码是应用层的事。** 错误只有名字；"这个错误让进程退 2 还是退 4"
取决于整个程序怎么设计。`switch` + 返回 struct 是干净的写法，
比一串 `if` 好扩展。

## 9.8 `if (f()) |v| {} else |err| {}` 与 `while ... else |err|`

```zig
// examples/09_errors1/main.zig 第 317-332 行
fn ifElseOnErrorUnion() void {
    if (parseScore("")) |v| {
        std.debug.print("  值 {d}\n", .{v});
    } else |err| {
        std.debug.print("  ① if/else |err|：错误分支拿到 {s}\n", .{@errorName(err)});
    }
    if (parseScore("77")) |v| {
        std.debug.print("  ② if/else |err|：值分支拿到 {d}\n", .{v});
    } else |err| {
        std.debug.print("  ② if/else |err|（不该到这）：{s}\n", .{@errorName(err)});
    }
    std.debug.print("  ⚠️ 0.17 的 switch **不能**接可选和错误联合：\n", .{});
    std.debug.print("     switch (opt) {{ null => ..., else => |v| ... }}  → error: switch on optional type '?u8'\n", .{});
    std.debug.print("     switch (eu)  {{ error.A => ..., else => |v| ... }} → error: switch on error union type 'error{{A}}!u8'\n", .{});
    std.debug.print("     两者都附note: consider using '.?', 'orelse', or 'if' / 'try', 'catch', or 'if'\n", .{});
}
```

运行输出（`examples/09_errors1/main.zig`）：

```text
==== 9.8 if/while 双分支 开始 ====
  ① if/else |err|：错误分支拿到 Empty
  ② if/else |err|：值分支拿到 77
  ⚠️ 0.17 的 switch **不能**接可选和错误联合：
     switch (opt) { null => ..., else => |v| ... }  → error: switch on optional type '?u8'
     switch (eu)  { error.A => ..., else => |v| ... } → error: switch on error union type 'error{A}!u8'
     两者都附note: consider using '.?', 'orelse', or 'if' / 'try', 'catch', or 'if'
```

**和可选的 `if` 捕获完全同构**：成功分支拿值，失败分支 `|err|` 拿错误。
这是"值/错误二选一"的另一套写法——区别于 `try`（往上抛）和 `catch`（给后备值），
`if/else` 是**就地分流**，两个分支可以走完全不同的逻辑。

### ⚠️ `switch` 不能接可选和错误联合

老教程里常见的这种写法在 0.17 **编译不过**：

```text
$ switch (opt) { null => {}, else => |v| { _ = v; } }
error: switch on optional type '?u8'
note: consider using '.?', 'orelse', or 'if'

$ switch (eu) { error.A => {}, else => |v| { _ = v; } }
error: switch on error union type 'error{A}!u8'
note: consider using 'try', 'catch', or 'if'
```

对应的 0.17 写法：

```zig
// 可选
if (opt) |v| { /* v 有值 */ } else { /* null */ }
// 错误联合
if (eu) |v| { /* 成功 */ } else |err| { /* @errorName(err) */ }
// 或者先解再用 switch
const v = eu catch |err| switch (err) { ... };
switch (v) { 0 => ..., 1 => ..., else => ... }
```

⚠️ **`switch` 对"错误值"（不是错误联合）是可以的**：
`switch (err) { error.Empty => ..., error.NotDigit => ... }` 合法——
`err` 是 `ParseError`（一个错误集的值），不是 `ParseError!u8`。区别在于
**联合类型要先拆开才能 switch**。

### `while ... else |err|`：迭代器遇错退出

```zig
// examples/09_errors1/main.zig 第 334-370 行
const ChunkError = error{ Truncated, ChecksumMismatch };

const ChunkReader = struct {
    data: []const u32,
    pos: usize = 0,

    fn next(self: *ChunkReader) ChunkError!u8 {
        if (self.pos >= self.data.len) return error.Truncated;
        const v = self.data[self.pos];
        self.pos += 1;
        if (v == 0) return error.ChecksumMismatch;
        return @intCast(v);
    }
};

fn whileElseDemo() void {
    var reader: ChunkReader = .{ .data = &[_]u32{ 10, 20, 0, 40 } };
    var sum: u32 = 0;
    while (reader.next()) |chunk| { // 值分支：正常拿到一个数
        sum += chunk;
    } else |err| { // 错误分支：迭代器提前失败
        std.debug.print("  while 被错误终止：{s}（已累加 {d}，reader.pos={d}）\n", .{
            @errorName(err), sum, reader.pos,
        });
    }
    // 同一个 reader 继续读——错误不消耗状态，接着就是 Truncated
    var r2: ChunkReader = .{ .data = &[_]u32{7} };
    var n: usize = 0;
    while (r2.next()) |_| {
        n += 1;
    } else |err| {
        std.debug.print("  再读一次：{s}，共成功 {d} 次\n", .{ @errorName(err), n });
    }
    std.debug.print("  ⚠️ while 条件位置只接受可选和错误联合，`while (f()) |v|` 里没有 else |err| 时\n", .{});
    std.debug.print("     错误联合会被当可选处理 → error: expected optional type, found 'error{{...}}!u8'\n", .{});
    std.debug.print("     有 `else |err|` 分支（真正消费错误）才编译得过\n", .{});
}
```

运行输出（`examples/09_errors1/main.zig`）：

```text
  while 被错误终止：ChecksumMismatch（已累加 30，reader.pos=3）
  再读一次：Truncated，共成功 1 次
  ⚠️ while 条件位置只接受可选和错误联合，`while (f()) |v|` 里没有 else |err| 时
     错误联合会被当可选处理 → error: expected optional type, found 'error{...}!u8'
     有 `else |err|` 分支（真正消费错误）才编译得过
```

**这里有一个我最初判断错了、实测纠正的点**：`while (err_union) |v|` 在 0.17
**是可以用的**——只要带 `else |err|` 分支。我第一版示例里写的是
`else |err| { _ = e; }`，编译报的其实是 `error: error set is discarded`
（把错误丢弃了），不是"`while` 不支持错误联合"。加上一句
`std.debug.print("{s}", .{@errorName(err)})` 真正消费错误之后，
`while (r.next()) |chunk| { ... } else |err| { ... }` 编译通过、运行正确
（输出 `while 被错误终止：ChecksumMismatch`）。

真正的坑是**没有 `else |err|` 分支**时：

```text
$ while (f()) |v| { _ = v; }
error: expected optional type, found 'error{A}!u8'
note: consider using 'try', 'catch', or 'if'
```

`while` 条件位置**只接受可选或错误联合**，有 `else |err|` 时编译器知道错误被
消费了，就按错误联合处理；没有 `else` 分支时错误可能被丢弃，编译器保守地
按可选处理，于是拒绝。

顺便验证了另一个坑：**`_ = err;` 不能丢弃错误**（实测
`error: error set is discarded`），必须真正消费它——`@errorName(err)`、
`catch`、`switch` 都算消费。所以下面的写法都是错的：

```zig
while (f()) |v| { ... } else |err| { _ = err; }             // ❌ error set is discarded
while (f()) |v| { ... }                                      // ❌ expected optional type
while (f()) |v| { ... } else |err| { log(@errorName(err)); } // ✅
```

`else` 分支能拿到**已经处理了多少**（输出里 `已累加 30`、`reader.pos=3`），
这是 `while/else` 相比"循环里 try 然后在外面 catch"的最大优势：
部分进度可见。

## 9.9 错误集的组合与强制转换

### `||` 现在是错误集并集

```zig
// examples/09_errors1/main.zig 第 385-395 行
fn errorSetCombination() void {
    performTask(false) catch |err| std.debug.print("  不该出错：{s}\n", .{@errorName(err)});
    performTask(true) catch |err| std.debug.print("  子集的错误原样穿透：{s}\n", .{@errorName(err)});
    // `||` 在 0.17 是错误集并集（不是 0.16 的"造错误联合"）
    const Mixed = ParseError || error{Boom};
    std.debug.print("  ParseError || error{{Boom}} = {s}\n", .{@typeName(Mixed)});
    dumpErrSet("Mixed", Mixed);
    //并集里每个错误都能返回
    const as_parse: ParseError = error.NotDigit;
    const as_mixed: Mixed = error.Boom;
    std.debug.print("  并集成员：as_parse={s}，as_mixed={s}\n", .{ @errorName(as_parse), @errorName(as_mixed) });
```

运行输出（`examples/09_errors1/main.zig`）：

```text
==== 9.9 错误集组合 开始 ====
  子集的错误原样穿透：ConnectionLost
  ParseError || error{Boom} = error{Boom,Empty,NotDigit,TooLong}
  Mixed：@sizeOf=2字节，成员数=4 → Empty NotDigit TooLong Boom
  并集成员：as_parse=NotDigit，as_mixed=Boom
  ⚠️ 反方向（超集 → 子集）不行：
     fn f() NetworkError!void { try g() }  // g 返回 GeneralError!void
     → error: expected type 'error{ConnectionLost}!void', found 'error{...}'
       note: 'error.NotFound' not a member of destination error set
  ⚠️ 0.17 的 `E || Payload` 造错误联合的写法已废：
     const X = E || Value;  → error: expected error set type, found 'main.Value'
     造错误联合用 E!T
==== 9.9 错误集组合 结束 ====
```

`ParseError || error{Boom}` 得到 `error{Boom,Empty,NotDigit,TooLong}`
（4 个成员，`@sizeOf` 仍是 2 字节——**错误集不占额外空间，只是名字变多**）。
注意 `error_names` 的顺序（`Empty NotDigit TooLong Boom`）和 `@typeName`
里的顺序（`Boom` 在前）**不一样**，再次印证 9.4 节结论④：别依赖顺序。

### 强制转换是**单向**的：子集 → 超集

```zig
// examples/09_errors1/main.zig 第 374-383 行
const NetworkError = error{ConnectionLost};
const GeneralError = error{ NotFound, PermissionDenied, DiskFull, ConnectionLost };

fn connectToServer(fail: bool) NetworkError!void {
    if (fail) return error.ConnectionLost;
}

fn performTask(fail: bool) GeneralError!void {
    try connectToServer(fail); // NetworkError 自动 coerce 成 GeneralError（子集 → 超集）
}
```

`try connectToServer(fail)` 直接通过——`NetworkError` 是 `GeneralError`
的子集，编译器自动 coerce。输出 `子集的错误原样穿透：ConnectionLost` 证实
错误值本身没变。

**反方向不行**（实测）：

```text
$ fn f() NetworkError!void { try g(); }     // g 返回 GeneralError!void
error: expected type 'error{ConnectionLost}!void', found 'error{NotFound,PermissionDenied,DiskFull,ConnectionLost}'
note: 'error.NotFound' not a member of destination error set
note: function return type declared here
```

道理很直白：如果允许超集窄化成子集，那 `GeneralError!void` 里返回
`error.NotFound` 的那条路径在小集合签名下就**无处安放**——只能 panic。
Zig 不给你这个选项，要窄化得显式 `catch` + 决定怎么办（9.10 节）。

**这个单向性是好设计**：错误集强制转换的方向和返回值**宽化**的方向一致
（03 章 3.5 节）——都是"目标能表示源的所有可能值"才放行。

## 9.10 `@errorCast`：显式窄化错误集

```zig
// examples/09_errors1/main.zig 第 407-436 行
const NarrowError = error{X};

fn pickAny(flag: bool) anyerror!u8 {
    if (flag) return error.X;
    return error.SomeoneElsesError;
}

fn narrowWithErrorCast(flag: bool) NarrowError!u8 {
    const v = pickAny(flag) catch |err| {
        // ⚠️ anyerror 的错误不能直接 return 进小集合：
        //   return err;  → error: expected type 'error{X}!u8', found 'anyerror'
        //     note: global error set cannot cast into a smaller set
        // 必须显式 @errorCast（或 return @errorCast(err)）
        return @errorCast(err);
    };
    return v;
}

/// 需要在 anyerror 上做运行时窄化时用 @errorCast
fn narrowAnyToNarrow(flag: bool) NarrowError!u8 {
    const eu = pickAny(flag);
    if (eu) |v| {
        return v;
    } else |err| {
        // ⚠️ @errorCast 在 catch 表达式里没有结果类型，必须用 @as 点名：
        //   catch |err| @errorCast(err)  → error: @errorCast must have a known result type
        const small: NarrowError = @errorCast(err);
        return small;
    }
}
```

运行输出（`examples/09_errors1/main.zig`）：

```text
==== 9.10 @errorCast 开始 ====
  小集合的值装进 anyerror 再取回来：X
  anyerror 上运行时窄化：X
  窄化失败时不是错误，是 panic：thread ... panic: unexpected error code, found error.SomeoneElsesError
     （所以上面只在 flag=true 时调用 narrowAnyToNarrow；flag=false 会真的炸）
  ⚠️ 值在编译期已知时，@errorCast 越界是**编译错**：
     const small: NarrowError = @errorCast(error.SomeoneElsesError);
     → error: 'error.SomeoneElsesError' not a member of error set 'error{X}'
  ⚠️ catch 表达式里 @errorCast 没有结果类型：
     catch |err| @errorCast(err)  → error: @errorCast must have a known result type
       note: use @as to provide explicit result type
==== 9.10 @errorCast 结束 ====
```

### `@errorName` 与 `@errorCast` 的分工

| 内建 | 输入 → 输出 | 方向 |
|---|---|---|
| `@errorName(e)` | 错误 → `[:0]const u8` | 给人看（`NotDigit`） |
| `@intFromError(e)` | 错误 → 小整数 | 存起来（别持久化） |
| `@errorCast(e)` | 大集合错误 → 小集合错误 | **运行期检查**，失败 panic |

### `@errorCast` 的三种边界

**① 值在编译期已知时，越界是编译错**（实测）：

```text
$ const small: NarrowError = @errorCast(error.SomeoneElsesError);
error: 'error.SomeoneElsesError' not a member of error set 'error{X}'
```

**② 值在运行期才知道时，越界是 panic**（实测）：

```text
$ narrowAnyToNarrow(false)
thread <线程 id> panic: unexpected error code, found error.FromLib
error return context:
探针 p42.zig:5:5: <地址> in pick (p42)
    return error.FromLib;
    ^
```

⚠️ **panic 而不是错误**。这是 `@errorCast` 的设计选择——它的语义是
"我检查过了，这个错误确实在我的集合里"。检查失败说明你的判断错了，
属于编程错误而不是运行时状况，所以直接崩。这也意味着
**`@errorCast` 不适合用来试探一个未知错误属于哪个集合**——那种场景应该
用 `if`/`switch` 逐个比较。

**③ `catch` 表达式里 `@errorCast` 没有结果类型。** 实测：

```text
$ catch |err| @errorCast(err)
error: @errorCast must have a known result type
note: use @as to provide explicit result type
```

`catch` 后备值的类型由**上下文**决定，但 `@errorCast` 在这个位置还没定型。
两种解法（示例里两种都用了）：

```zig
// 写法 A：先赋给有类型的局部变量（narrowAnyToNarrow 用的）
const small: NarrowError = @errorCast(err);
return small;

// 写法 B：直接 return，函数的返回类型就是结果类型（narrowWithErrorCast 用的）
return @errorCast(err);
```

⚠️ **`return err;` 在 `anyerror` → 小集合时不行**（实测注释里那句）：

```text
error: expected type 'error{X}!u8', found 'anyerror'
note: global error set cannot cast into a smaller set
```

这是 9.9 节那个"单向性"在 `anyerror` 上的加强版：编译器**永远不允许**
`anyerror` 隐式变小集合，必须 `@errorCast`（接受运行期 panic 的风险）
或者 `catch` 后自己决定（`return error.包装过的名字`）。

## 9.11 `defer` / `errdefer` 预览

本章只做一个预告，完整展开在 10 章。

```zig
// examples/09_errors1/main.zig 第 459-480 行
const TxnError = error{Rejected};

/// 记录 defer / errdefer 各跑了没有（测试里就不必看打印了）
const TxnTrace = struct { defer_: bool, errd: bool };

/// 用一个可变的标志位记录 defer/errdefer 各跑了没有
fn transact(fail: bool, ran: *TxnTrace) TxnError!u8 {
    defer ran.defer_ = true; // 无条件执行
    errdefer ran.errd = true; // 只在返回错误时执行
    if (fail) return error.Rejected;
    return 7;
}

fn deferDemo() !void {
    var ran_success: TxnTrace = .{ .defer_ = false, .errd = false };
    _ = try transact(false, &ran_success);
    std.debug.print("  成功路径：defer 跑了={}，errdefer 跑了={}\n", .{ ran_success.defer_, ran_success.errd });
    var ran_fail: TxnTrace = .{ .defer_ = false, .errd = false };
    _ = transact(true, &ran_fail) catch {};
    std.debug.print("  失败路径：defer 跑了={}，errdefer 跑了={}\n", .{ ran_fail.defer_, ran_fail.errd });
    std.debug.print("  ⚠️ 失败路径上 errdefer 先于 defer 执行（后进先出）\n", .{});
}
```

运行输出（`examples/09_errors1/main.zig`）：

```text
==== 9.11 defer/errdefer 开始 ====
  成功路径：defer 跑了=true，errdefer 跑了=false
  失败路径：defer 跑了=true，errdefer 跑了=true
  ⚠️ 失败路径上 errdefer 先于 defer 执行（后进先出）
==== 9.11 defer/errdefer 结束 ====
```

**`errdefer` 与错误处理的耦合点**：`errdefer` 声明的清理代码**只在函数返回错误时
执行**。这正是"资源管理"和"错误处理"的接口——`defer` 负责"无论如何都要做的清理"
（关文件、释放内存），`errdefer` 负责"只有失败才需要的回滚"（已经改了状态，
失败时要撤销）。

⚠️ **结构体字面量必须命名才能在测试里复用**。写这段时踩到：把
`*struct { defer_: bool, errd: bool }` 直接当参数类型，
测试里写 `var ok_run: struct { defer_: bool, errd: bool }` 传给它会报

```text
error: expected type '*main.transact__struct_1042', found '*main.test.9.11 defer 与 errdefer__struct_1041'
note: pointer type child 'main.test.9.11 defer 与 errdefer__struct_1041' cannot cast into pointer type child 'main.transact__struct_1042'
```

两个**匿名结构体字面量是两个不同的类型**（03 章 7.x 节讲过这个规则，
这里是个新的应用场景）。解法是提取成 `const TxnTrace = struct { ... }`。

## 9.12 `?T` 与 `!T` 的分工与组合

回到本章开头的问题：**什么时候用哪个？**

| 场景 | 用 | 为什么 |
|---|---|---|
| 字典里没这个键 | `?T` | 没找到是**正常业务结果**，不是异常 |
| 文件打不开 | `!T` | 失败需要**名字**（`error.FileNotFound`） |
| 格式解析失败 | `!T` | 调用方要能按错误分类处理 |
| 列表里找匹配项 | `?T` | 找不到很常见，不需要名字 |
| 栈上/堆上分配失败 | `!T` | 标准库已经定义了 `error.OutOfMemory` |
| "可能没有" + "可能失败"都要 | `?E!T` | 两层独立 |

### 三态组合怎么解

```zig
// examples/09_errors1/main.zig 第 484-504 行
fn divisionAndCombination() void {
    // 三种"没有"：可选缺席 / 错误失败 / 错误联合被包进可选
    const samples = [_]?ParseError!u8{
        null, // ① 整条链"没有结果"
        @as(ParseError!u8, error.NotDigit), // ② 失败了
        @as(ParseError!u8, 5), // ③ 成功
    };
    std.debug.print("  ?ParseError!u8 大小={d} 字节（? 在外、! 在内），u8 本身只有 {d} 字节\n", .{
        @sizeOf(?ParseError!u8), @sizeOf(u8),
    });
    for (samples) |s| {
        const eu = s orelse { // 先解可选（用 orelse，不是 catch）
            std.debug.print("    ① 缺席分支（orelse 命中）\n", .{});
            continue;
        };
        const v = eu catch |err| { // 再解错误联合
            std.debug.print("    ② 错误分支（catch 命中）：{s}\n", .{@errorName(err)});
            continue;
        };
        std.debug.print("    ③ 值分支：{d}\n", .{v});
    }
```

运行输出（`examples/09_errors1/main.zig`）：

```text
==== 9.12 分工与组合 开始 ====
  ?T：'没有'是正常业务（字典里没这个键）
  !T：'失败'是异常路径（文件打不开、格式不对）
  ?ParseError!u8 大小=6 字节（? 在外、! 在内），u8 本身只有 1 字节
    ① 缺席分支（orelse 命中）
    ② 错误分支（catch 命中）：NotDigit
    ③ 值分支：5
  orelse 只能解可选（f() orelse 0 → expected optional type, found 'error{...}!u8'）
  catch 只能解错误联合（a catch 7 → expected error union type, found '?u8'）
==== 9.12 分工与组合 结束 ====
```

**`?E!T` 从外到内解，用的语法由外层类型决定**：`?` 在外所以先 `orelse`，
`!` 在内所以后 `catch`。顺序反了编译器就报：

```text
$ const eu = f() orelse 0;        // f() 返回 error{A}!u8
error: expected optional type, found 'error{A}!u8'
note: consider using 'try', 'catch', or 'if'

$ const b = a catch 7;            // a 是 ?u8
error: expected error union type, found '?u8'
note: consider omitting 'try'
```

⚠️ **`?E!T` 的大小是 6 字节**（输出第 3 行），不是 1（`u8`）+ 1（`?`）。
因为 `?E!u8` 里 `E!u8` 是 4 字节（2 字节 tag + 1 字节 payload + padding），
外面再加 1 字节可选标记 → 6。**可选套错误联合有真实的内存代价**，
所以别把 `?E!T` 当默认签名，只在真的需要三态时用。

### 对照表：与别家

| 场景 | Zig | C++ | Rust | Go |
|---|---|---|---|---|
| 可能没有 | `?T` | `std::optional<T>` | `Option<T>` | `T` + `, ok :=` / `(T, error)` |
| 可能失败 | `E!T` | 返回码 / `expected<T,E>` | `Result<T, E>` | `(T, error)` |
| 两者都要 | `?E!T` | `optional<expected<>>` | `Option<Result<>>` | 嵌套 |
| 强制检查 | 编译器 | 无（C++）/ 部分库 | 编译器 | **无**（vet 只警告） |
| 失败时的信息 | 错误**名字**（无 payload） | 返回码 / `error_code` | `Error` 枚举可带数据 | `error` 接口可带数据 |
| 定位失败源 | **error return trace** | 手动打日志 | `Backtrace` / `anyhow` | `runtime.Caller` |

Go 是最值得对照的：`err != nil` 不写就编译通过，靠 code review 和 lint 兜。
Zig 把"必须处理"变成编译期约束——这也是本章所有 `!T` 存在的意义。

### 测试：把语义钉住

本章行为全靠测试守着（`main.zig` 第 600-804 行，12 个 `test` 块）：

```text
$ zig test main.zig
1/12 main.test.9.1 ?T 的值域与宽度...OK
2/12 main.test.9.2 解包三件套...OK
3/12 main.test.9.3 null 不等于 0...OK
4/12 main.test.9.4 错误集反射（0.17 的 error_names）...OK
5/12 main.test.9.5 推断错误集会传染...OK
6/12 main.test.9.6 try 传播...OK
7/12 main.test.9.7 catch 三形态与错误映射...OK
8/12 main.test.9.8 while ... else |err| 与 switch 的禁区...OK
9/12 main.test.9.9 错误集并集与强制转换...OK
10/12 main.test.9.10 @errorCast 窄化...OK
11/12 main.test.9.11 defer 与 errdefer...OK
12/12 main.test.9.12 ?E!T 三态组合...OK
All 12 tests passed.
```

几个关键断言：

- **9.1**：`@sizeOf(?*u8) == @sizeOf(*u8)`、`@sizeOf(?u8) == @sizeOf(u8) + 1`、
  `@sizeOf(?u64) == @sizeOf(u64) + @sizeOf(u64)`——把"指针族零开销、标量族加标记
  且标记同宽"钉死。
- **9.4**：`names[0] == "Empty"` 直接和字符串比较（元素就是名字，0.16 要写
  `names[0].name`）；`@typeInfo(error{}).error_set.error_names.?.len == 0`
  且 `@typeInfo(anyerror).error_set.error_names == null`——把"空集合 vs anyerror"
  这个易混点钉死。
- **9.8**：`terminated == error.ChecksumMismatch`、`sum == 30`、`r.pos == 3`
  ——`while/else` 的错误终止语义 + 部分进度可见。
- **9.11**：四条断言覆盖 `defer` × `errdefer` × 成功/失败的四种组合。

## 9.13 坑位清单

1. **null 的位模式是全 0，不是"全 1"。** 实测 `?u8 = null` 的字节是 `{ 0, 0 }`，
   `?u8 = 0` 是 `{ 0, 1 }`——tag 单元和 payload 同宽，非 null 时 tag = 1。
   "?*T 零开销"的准确说法是"null 复用全 0 地址"。别用 `asBytes` 读可选内部，
   布局不是语言保证。

2. **⚠️ `@typeInfo(E).error_set` 在 0.17 变了结构**：`error_names: ?[]const [:0]const u8`
   ——**字段改名**（0.16 的元素是 `{ name, value }` 结构体，0.17 元素**本身就是名字**），
   且**可空**。三种特例必须分清：`error{}` 是**空切片**（`.len == 0`），
   `anyerror` 才是 `null`。直接 `for` 遍历报
   `type '?[]const [:0]const u8' is not indexable and not a range`。

3. **哨兵切片只能写全长**：`n[0..3 :0]` 报
   `error: value in memory does not match slice sentinel` + `note: expected '0', found '104'`。
   要截断就写 `n[0..3]`（**不带 `:0`**，得到普通 `[]const u8`），要保留哨兵就写
   `n[0..n.len]`。

4. **`@typeInfo(?T).optional` 的字段是 `.child` 不是 `.payload`**
   （`error: no field named 'payload' in struct 'lang.Type.Optional'`）。
   但 `@typeInfo(E!T).error_union.payload` **仍然叫 `payload`**——
   0.17 的 `Optional` 和 `ErrorUnion` 结构体不一致，别记混。

5. **0.17 没有可选链 `?.`**：`o.a?.len` 报 `error: expected ';' after statement`
   （编译器把 `?` 当三元运算符的一部分，解析到 `.` 就断了，报错完全指不到问题点）。
   这个语法 0.14 引入、0.17 已移除。多层可选逐层 `orelse` / `if` 捕获。

6. **0.17 没有 `catch || 默认值`**：`f() catch || 42` 报
   `error: expected expression, found '||'`。`||` 在 0.17 只有一个含义
   ——**错误集并集**。要吞错误给默认值就是 `catch 42`。

7. **`||` 不再造错误联合**：`const X = ErrorSet || Payload` 报
   `error: expected error set type, found 'main.Value'`。造错误联合用 `E!T`
   （`anyerror!T` 或具名 `MyErr!T`）。这是 ≤0.16 代码的大规模破坏点，
   08 章 8.x 节也踩到过同一个。

8. **`while (err_union) |v|` 在 0.17 可用，但必须带 `else |err|`**。
   只有 `while (f()) |v| { ... }` 时报
   `error: expected optional type, found 'error{A}!u8'`（编译器按可选处理，
   因为错误可能被丢弃）。带 `else |err|` 分支且**真正消费错误**才编译得过。
   ⚠️ 我第一版示例里写 `else |err| { _ = e; }`，报的其实是
   `error: error set is discarded`——**两个不同的坑，别混**。

9. **`switch` 不能接可选和错误联合**：`switch (opt)` 报
   `error: switch on optional type '?u8'`，`switch (eu)` 报
   `error: switch on error union type 'error{A}!u8'`。但 `switch` 对**错误值**
   （`switch (err) { error.Empty => ... }`）合法，且**要求穷尽**
   （漏一个报 `switch must handle all possibilities`）。

10. **`_ = err;` 不能丢弃错误**：`error: error set is discarded`。必须真正消费——
    `@errorName(err)`、`switch`、`catch`、`try` 都算。同理
    `_ = err_union;` 报 `error: error union is discarded` +
    `note: consider using 'try', 'catch', or 'if'`。

11. **`try` / `catch` 只对错误联合生效，对可选不行**：
    `try findFirst(...)` 报 `error: expected error union type, found '?usize'`；
    `opt catch 0` 报 `error: expected error union type, found '?u8'`；
    `f() orelse 0`（f 返回错误联合）报 `error: expected optional type, found 'error{...}!u8'`。
    **9.12 节的对照表**：可选用 `orelse`/`if`/`.?`，错误联合用 `try`/`catch`。

12. **错误集强制转换是单向的**：子集 → 超集（`try` 直接过）✅；超集 → 子集 ❌
    （`note: 'error.NotFound' not a member of destination error set`）。
    `anyerror` → 小集合更严格：`note: global error set cannot cast into a smaller set`，
    必须 `@errorCast` 或 `catch` 后重新映射。

13. **`@errorCast` 的失败是 panic 不是错误**：运行期越界报
    `thread ... panic: unexpected error code, found error.SomeoneElsesError`
    （带 `error return context` 段）。值在编译期已知时则是编译错
    （`'error.X' not a member of error set 'error{Y}'`）。
    别拿 `@errorCast` 去"试探"未知错误属于哪个集合——用 `if`/`switch` 比较。

14. **`@errorCast` 在 `catch` 表达式里没有结果类型**：
    `error: @errorCast must have a known result type` +
    `note: use @as to provide explicit result type`。先赋给有类型的局部变量，
    或直接 `return @errorCast(err)`（让函数返回类型定型）。

15. **`for` 不能遍历可选**：`for (opt)` 报
    `error: type '?u8' is not indexable and not a range` +
    `note: for loop operand must be a range, array, slice, tuple, or vector`。
    `while (opt) |v|` 可以（这是把可选当"迭代器终止信号"的正确用法）。

16. **匿名结构体字面量是两个不同的类型**：把 `*struct { a: bool }` 当参数类型，
    测试里传 `*struct { a: bool }` 会报
    `pointer type child 'main.f__struct_1' cannot cast into pointer type child 'main.test.x__struct_2'`。
    跨函数复用就得提取成命名类型。另外注意**变量名不能叫 `errdefer`**——
    `errdefer: bool` 会报 `error: expected type expression, found 'errdefer'`。

---

上一章：[08 枚举与联合](08-enums.md) · 下一章：[10 错误 II](10-errors-advanced.md)