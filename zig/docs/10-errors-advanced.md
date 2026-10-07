# 10 · 错误处理 II

> 对应示例：`examples/10_errors2/main.zig`
>
> 09 章讲了错误处理的**词汇**：`?T`、`E!T`、`try`、`catch`、`@errorCast`。本章讲**工程**：
> 资源怎么回滚（`errdefer`）、清理动作按什么顺序跑、出错时怎么定位是哪一层传的
> （error return trace）、内部错误怎么翻译成用户听得懂的话和退出码、错误怎么带上下文、
> 以及最后一层——**什么时候该用错误、什么时候该 panic、什么时候该直接退出进程**。
>
> 本章有**三处实测纠正了流传较广的说法**，都跟"想当然"有关，逐字节抄在下面：
>
> 1. **`errdefer` 并不比 `defer` 优先跑。** `defer` 与 `errdefer` 共用**同一个 LIFO 栈**，
>    谁后注册谁先跑。05 章流传的"`errdefer` 先跑"其实是那段示例里 `errdefer` 恰好写在
>    `defer` 后面造成的观察偏差。10.3 节用四个探针把这件事钉死。
> 2. **0.17 的 error return trace 只有 Debug 模式有**，ReleaseSafe **没有**。
>    书上和多数资料说"Debug 和 ReleaseSafe 默认开启"，在 0.17.0 上实测为假。
> 3. **`catch unreachable` 在 ReleaseFast / ReleaseSmall 下不是 panic，是未定义行为**，
>    实测进程收到 **SIGILL**（退出码 `-4`），没有任何诊断信息。10.9 节展开。

---

## 10.1 `errdefer`：只在返回错误时执行的回滚

`errdefer` 的语义一句话说完：**如果本函数最终 `return` 了一个错误（或 `try` 冒泡了），就执行；正常返回不执行。** 它是 `defer` 的"失败版"，专门用来撤销"已经对外部世界做的改动"。

```zig
// examples/10_errors2/main.zig 第 15-39 行
/// 一个带身份的小对象，用来观察"分配成功但初始化失败"这类半成品
const Thing = struct { id: u32 };

/// 全局计数器：副作用的可观测证据（errdefer 要回滚的就是它）
var made: usize = 0;

/// 正例：拿到对象就立刻挂 errdefer，失败自动回滚计数
fn makeThing(gpa: std.mem.Allocator, id: u32) !*Thing {
    made += 1; // 副作用①：登记"我造了一个"
    errdefer made -= 1; // 失败 → 撤销①
    const t = try gpa.create(Thing); // 这一步自己失败 → 只有① 需要撤销
    errdefer gpa.destroy(t); // 后续失败 → ② 撤销已分配的对象
    t.* = .{ .id = id };
    return t; // 成功：两条 errdefer 都不跑，所有权交给调用方
}

/// 观察用：id == 0 时在"已分配、未初始化"的中途失败
fn makeThingChecked(gpa: std.mem.Allocator, id: u32) !*Thing {
    made += 1;
    errdefer made -= 1; // ①
    const t = try gpa.create(Thing);
    errdefer gpa.destroy(t); // ②
    if (id == 0) return error.BadId; // 半路失败：② 先跑（后进先出），再跑 ①
    t.* = .{ .id = id };
    return t;
}
```

这里的关键纪律是**"每产生一个外部可见的副作用，就立刻挂一条 errdefer"**。`made += 1` 之后立刻 `errdefer made -= 1`；`gpa.create` 成功之后立刻 `errdefer gpa.destroy`。这样无论从哪个 `return` / `try` 出去，回滚逻辑都已经在栈上了。

运行输出（`examples/10_errors2/main.zig`）：

```text
==== 10.1 开始 ====
起始 made=0
两次成功 made=2（两条 errdefer 都没跑）
失败 BadId之后 made=2（② 销毁对象+ ① 回滚计数，都跑了）
注入第 2 次分配失败 → OutOfMemory：成功 1 次 / 归还 1 次 / made回到 2
  （fail_index=1 意味着第 1 块成功、第 2 块失败；deallocations=1 证明第 1 块被 errdefer 还回去了）
  made 守恒检查：成立
==== 10.1 结束 ====
```

**"成功 made=2"** 之后是**"失败 BadId 之后 made=2"**——两次失败路径跑完，计数没变。这正是`errdefer` 存在的意义：`makeThingChecked` 里的 `return error.BadId` 那一行**没有写任何清理代码**，但计数和内存都被正确回收了。

第三行是本章最值得学的验证手法：**用 `FailingAllocator` 注入失败**，从分配器层面证明内存真的还回去了，而不是"看起来没泄漏"。

```zig
// examples/10_errors2/main.zig 第 461-475 行
// 注入会失败的分配器：证明 errdefer 真的把内存还回去了。
// ⚠️ std.testing.allocator **只在 zig test 下存在**（源码里是
//   `if (builtin.is_test) ... else @compileError("not testing")`），
//   在 main 里用会报 error: not testing。所以这里用 DebugAllocator 当底层。
    {
        var fa = std.testing.FailingAllocator.init(gpa, .{ .fail_index = 1 });
        const before = made;
        _ = buildTriple(fa.allocator(), 2) catch |err| {
            std.debug.print("注入第 2 次分配失败 → {s}：成功 {d} 次 / 归还 {d} 次 / made回到 {d}\n", .{
                @errorName(err), fa.allocations, fa.deallocations, made,
            });
            std.debug.print("  （fail_index=1 意味着第 1 块成功、第 2 块失败；deallocations=1 证明第 1 块被 errdefer 还回去了）\n", .{});
            std.debug.print("  made 守恒检查：{s}\n", .{if (made == before) "成立" else "不成立"});
        };
    }
```

`allocations=1 / deallocations=1` 是硬证据：第 1 次分配成功、第 2 次被注入失败，两者之间的 `errdefer gpa.free(a)` 立刻把第 1 块还了回去。

⚠️ **这里踩到一个 0.17 的坑**：想在 `main` 里用 `std.testing.allocator` 会编译失败，因为它的定义是

```zig
// lib/std/testing.zig 第 21 行
pub const allocator = if (builtin.is_test) allocator_instance.allocator() else @compileError("not testing");
```

实测报错：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/testing.zig:21:80: error: not testing
pub const allocator = if (builtin.is_test) allocator_instance.allocator() else @compileError("not testing");
                                                                               ^~~~~~~~~~~~~~~~~~~~~~~~~~~~
referenced by:
    main: main.zig:463:63
```

所以 `main` 里要演示注入失败，得拿一个真实分配器当底层（本例用 `DebugAllocator`），而 `test` 块里才用 `std.testing.allocator`。

## 10.2 多种资源同时获取：回滚纪律与"部分初始化对象"

### 逐步挂 errdefer：条数 = 已获取资源数

```zig
// examples/10_errors2/main.zig 第 43-65 行
/// 分配-初始化：alloc 成功就挂 errdefer，后续任何失败都有人兜底
fn buildList(gpa: std.mem.Allocator, n: usize) ![]u32 {
    const slice = try gpa.alloc(u32, n);
    errdefer gpa.free(slice); // 失败 → 归还
    for (slice, 0..) |*p, i| p.* = @intCast(i * 2);
    if (n > 8) return error.TooBig;
    return slice; // 成功 → 所有权移交，调用方负责 free
}

/// 三段资源：每成功获取一段就立刻挂一条 errdefer，纪律是"不多不少不少条"
fn buildTriple(gpa: std.mem.Allocator, n: usize) ![][]u32 {
    const a = try gpa.alloc(u32, n);
    errdefer gpa.free(a); // ①
    const b = try gpa.alloc(u32, n);
    errdefer gpa.free(b); // ②
    const out = try gpa.alloc([]u32, 2);
    errdefer gpa.free(out); // ③
    if (n > 4) return error.TooBig; // 失败 → ③②① 逆序全部回滚
    out[0] = a;
    out[1] = b;
    return out;
}
```

`buildTriple` 是**教科书式的纪律**：三次 `alloc`，三条 `errdefer`，一一对应。失败时三条按**注册的逆序**全部执行——注意 `out` 是最后分配的，所以最先被释放，这个顺序恰好也是"释放依赖关系"的正确顺序（`out` 指向 `a`/`b` 的指针，必须先释放 `out`）。

运行输出（`examples/10_errors2/main.zig`）：

```text
==== 10.2 开始 ====
buildList(5)={ 0, 2, 4, 6, 8 }
buildList(16) 失败：TooBig（16>8，errdefer 已 free）
buildTriple(8) 失败：TooBig（8>4，三条 errdefer 逆序全跑了）
buildTriple(2) 成功：2 组，每组 2 个 u32
loadRamp("12345") → 5 个字节，truncated=false
loadRamp("12x45") → BadChar：已装 2 个字节的半成品被 errdefer 收掉，DebugAllocator 末尾会验证无泄漏
==== 10.2 结束 ====
```

三次失败（`buildList(16)`、`buildTriple(8)`、`loadRamp("12x45")`）之后，程序末尾仍然打印 `DebugAllocator 收尾：ok（无泄漏）`——这是 `DebugAllocator` 在 `deinit` 时做的全局校验，**任何一处漏回滚都会让它变成 `leak`**。

### 错误作为"部分初始化对象的清理机制"

更进阶的用法：`errdefer` 不只是"释放资源"，还是"**让半成品不成其为对象**"的机制。

```zig
// examples/10_errors2/main.zig 第 67-83 行
/// 部分初始化对象的清理机制：把"半成品"也当成合法返回值的一部分
/// 成功时 errdefer 全不跑；失败时对象连同已登记的行数一起消失
const Loaded = struct { rows: []u32, truncated: bool };

fn loadRamp(gpa: std.mem.Allocator, src: []const u8) !Loaded {
    // 第一步：按上界分配。选上界是"部分初始化"的关键——先占位，再逐步填
    const buf = try gpa.alloc(u32, src.len);
    errdefer gpa.free(buf); // 失败 → 释放半成品
    var n: usize = 0;
    for (src) |c| {
        if (c == 'x') {
            // 业务失败：buf 已经装了 n 个有效数字，errdefer 负责把它收掉
            return error.BadChar;
        }
        buf[n] = c;
        n += 1;
    }
    return .{ .rows = buf, .truncated = n < src.len };
}
```

这里故意**按上界 `src.len` 分配**（而不是先数一遍长度再精确分配），因为这样可以在一个循环里同时完成"填充"和"发现错误"。代价是成功时可能有未使用的尾部——`truncated` 字段就是诚实地把这个事实记下来，而不是假装没有。

**要点**：函数返回时，对象要么是**完整且自洽**的（`return .{ .rows = buf, ... }`），要么**根本不存在**（`return error.BadChar` 触发 `errdefer`）。调用方**永远拿不到半成品**。这就是 `errdefer` 的核心价值——它把"初始化到一半"这个危险状态从类型层面消灭掉了。

⚠️ 顺带一个实测细节：`loadRamp` 的返回类型是 `!Loaded`（推断错误集 = `error{OutOfMemory, BadChar}`），而 `Loaded` 里没有任何指针所有权标记——Zig 没有 RAII 类型（没有 C++ 的 `unique_ptr`），**所有权靠约定 + 文档**：返回的 `rows` 归调用方 `free`。

## 10.3 `defer` 与 `errdefer` 的执行顺序（实测，与直觉相反）

这是本章第一个**实测纠正**。常见说法是"`errdefer` 比 `defer` 先执行，因为它是错误路径的紧急清理"。**在 0.17 上这是错的。**

`defer` 和 `errdefer` 共用**同一个 LIFO 栈**，语义差别只是"函数是否返回了错误"这个**过滤条件**。谁**后注册**，谁**先跑**。

```zig
// examples/10_errors2/main.zig 第 87-132 行
/// 记录 cleanup 实际执行顺序的轨迹缓冲
const Trace = struct {
    buf: [16]u8 = undefined,
    len: usize = 0,

    fn mark(self: *Trace, c: u8) void {
        self.buf[self.len] = c;
        self.len += 1;
    }

    fn text(self: *const Trace) []const u8 {
        return self.buf[0..self.len];
    }

    fn reset(self: *Trace) void {
        self.len = 0;
    }
};

/// 同作用域：defer 先注册、errdefer 后注册
fn cleanupDeferFirst(ok: bool, t: *Trace) Err!u8 {
    defer t.mark('D');
    errdefer t.mark('E');
    if (!ok) return error.Nope;
    return 1;
}

/// 同作用域：errdefer 先注册、defer 后注册（只把两行调换）
fn cleanupErrdeferFirst(ok: bool, t: *Trace) Err!u8 {
    errdefer t.mark('E');
    defer t.mark('D');
    if (!ok) return error.Nope;
    return 1;
}

/// 嵌套：外层 defer 先注册、内层 errdefer 后注册
fn cleanupNested(ok: bool, t: *Trace) Err!u8 {
    defer t.mark('o'); // 外层，第 1 个注册
    errdefer t.mark('e');
    {
        defer t.mark('i'); // 内层，第 3 个注册
        errdefer t.mark('I'); // 内层，第 4 个注册
        if (!ok) return error.Nope;
    }
    return 1;
}
```

运行输出（`examples/10_errors2/main.zig`）：

```text
==== 10.3 开始 ====
成功路径：D（只有 defer 跑）
失败路径：ED（defer 先注册、errdefer 后注册 → **后注册的先跑**）
把两行调换：DE（这次 defer 后注册，于是 defer 先跑）
嵌套成功：io（内层先于外层：i 然后 o）
嵌套失败：Iieo（注册序o→e→i→I，运行序完全逆序）
循环里 defer 的累积：loopDeferCount(5)=5，loopDeferCount(100000)=100000（都到出口才跑）
正确姿势：loopScoped(4) → eoeo（每轮进出独立作用域，defer 立即生效）
==== 10.3 结束 ====
```

**逐条对照，四组实验把结论钉死：**

| 实验 | 注册顺序 | 失败时运行序| 说明了什么 |
|---|---|---|---|
| `cleanupDeferFirst` | `defer`(1) → `errdefer`(2) | `ED` | 后注册的 `errdefer` 先跑 |
| `cleanupErrdeferFirst` | `errdefer`(1) → `defer`(2) | `DE` | **只调换两行，运行序就调换了** |
| `cleanupNested`（成功） | `o`(1) `e`(2) `i`(3) `I`(4) | `io` | 只有 `defer` 参与；内层先于外层 |
| `cleanupNested`（失败） | 同上 | `Iieo` | 四条全参与，严格逆序 |

第二行是关键证据：**两组函数只差`defer` 和 `errdefer` 两行的位置，运行序就从 `ED` 变成 `DE`**。如果"`errdefer` 优先"是真的，这个结果不可能出现。

嵌套那行 `Iieo` 尤其值得展开——它看起来"不整齐"（直觉会写成 `Ieio`），原因是内层的 `i`（`defer`，第 3 个注册）确实跑在内层 `I`（`errdefer`，第 4 个注册）**之后**。`I` 之所以排第一，纯粹因为它注册得最晚。**顺序完全由注册序决定，与 `defer`/`errdefer` 的种类无关。**

⚠️ 我第一版示例和测试里都把这条写成了 `Ieio`，被测试当场抓住：

```text
====== expected this output: =========
Ieio␃

======== instead found this: =========
Iieo␃
```

**这就是测试的价值**——凭直觉想的"应该"和真实行为不一致时，测试会告诉你哪一个是对的。

### `defer` 在循环里的累积代价

```zig
// examples/10_errors2/main.zig 第 134-153 行
/// 循环里defer 的累积代价：每轮都注册，全部堆在函数出口
fn loopDeferCount(n: usize) usize {
    var fired: usize = 0;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        defer fired += 1; // 每轮一条，全在函数返回时跑
    }
    return fired;
}

/// 正确姿势：把需要每轮清理的活儿封成独立函数，让 defer 随作用域离开
fn loopScoped(n: usize, t: *Trace) void {
    var i: usize = 0;
    while (i < n) : (i += 1) {
        deferRound(i, t); // 每轮进出一次独立作用域，defer 立即生效
    }
}

fn deferRound(i: usize, t: *Trace) void {
    defer t.mark(if (i % 2 == 0) 'e' else 'o');
}
```

输出里`loopDeferCount(100000)=100000` 看着"没问题"，但它掩盖了两件事：

**① 执行时机全被推迟到函数出口。** 循环跑完 10 万次之后才开始执行 10 万条 `defer`。如果循环中间某处panic 或超时，这 10 万条`defer` 里的清理**可能根本没机会跑**。

**② 栈/堆上要挂 10 万个清理记录。** Zig 的实现要为每个活跃的 `defer` 分配一个栈槽位（因为 `defer` 可以捕获变量，甚至可能有运行期计算的值）。10 万次就是 10 万个槽位——**这是实打实的内存与时间开销**，而且它随循环次数线性增长。

正确做法是 `loopScoped`：**把每轮需要清理的逻辑封成一个独立函数**，`defer` 随该函数的作用域结束立即执行。输出 `eoeo` 就是四轮各自的 `defer` 立刻生效的结果（`i=0,2` 打 `e`，`i=1,3` 打 `o`），而不是堆在 `loopScoped` 出口。

⚠️ 书里给过一条相关的建议（ch6 自测题第 29 题答案）：**"在循环里做资源清理时，要把 `errdefer` 放在循环外"**。这个建议在 0.17 上是**危险**的——放在循环外意味着只有一个 `errdefer` 保护 N 轮迭代中已经获取的所有资源，中途失败时你**不知道该释放几个**。正确姿势是本节的 `loopScoped`：让每轮自己的作用域负责自己的清理。

## 10.4 错误返回追踪：谁点的引信

普通 stack trace 告诉你"**在哪炸的**"；error return trace 告诉你"**这个错误是怎么一路传到你手上的**"——每一次 `try` 向上传递的交接都记在案。

```zig
// examples/10_errors2/main.zig 第 156-175 行
const CfgError = error{ ConfigMissing, BadPort };

fn readConfigLine() CfgError![]const u8 {
    return error.ConfigMissing; // 错误的产生点
}
fn loadConfig() CfgError![]const u8 {
    return try readConfigLine(); // 第一层交接
}
fn startService() CfgError!void {
    _ = try loadConfig(); // 第二层交接
}
fn bootstrap() CfgError!void {
    try startService(); // 第三层交接
}

/// @setRuntimeSafety(false) 关不掉 error return trace（实测：trace 照样出现）
fn bootstrapNoSafety() CfgError!void {
    @setRuntimeSafety(false);
    try startService();
}
```

运行输出（`examples/10_errors2/main.zig`）：

```text
==== 10.4 开始 ====
构建模式 = debug，@errorReturnTrace() != null = true
顶层捕获：ConfigMissing
—— 产生点到捕获点的完整路径（地址每次运行都不同）——
/Volumes/mac004/code/programming/zig/examples/10_errors2/main.zig:159:5: 0x10ba1fbff in readConfigLine (main)
    return error.ConfigMissing; // 错误的产生点
    ^
/Volumes/mac004/code/programming/zig/examples/10_errors2/main.zig:162:12: 0x10ba1fb04 in loadConfig (main)
    return try readConfigLine(); // 第一层交接
           ^
/Volumes/mac004/code/programming/zig/examples/10_errors2/main.zig:165:9: 0x10ba1f91f in startService (main)
    _ = try loadConfig(); // 第二层交接
        ^
/Volumes/mac004/code/programming/zig/examples/10_errors2/main.zig:168:5: 0x10ba203d3 in bootstrap (main)
    try startService(); // 第三层交接
    ^
⚠️ @setRuntimeSafety(false) **关不掉** return trace：
  同样收到 ConfigMissing，trace 长度不变（安全检查与错误追踪是两套机制）
==== 10.4 结束 ====
```

⚠️ **栈跟踪里的地址（`0x10ba1fbff`）每次运行都不同**（ASLR + 每次编译布局不同），抄下来没有意义。上面这段是**实测形如**的示意；**真正有断言价值的是这些每次都一样的部分**：

- 错误产生点函数名：**`readConfigLine`**
- 交接链的函数名序列：**`readConfigLine` → `loadConfig` → `startService` → `bootstrap`**
- 每一条的**源码行号列号**：`159:5`、`162:12`、`165:9`、`168:5`（只要不改代码，这两个数字就稳定）
- 每条下面的**源码原文 + `^` 指示符**（`return error.ConfigMissing; // 错误的产生点`）
- 头部的 `@errorReturnTrace() != null = true`

### ⚠️ 实测：0.17 只有 Debug 模式有 return trace

这是本章第二个**实测纠正**。书和多数资料说"Debug 和 ReleaseSafe 默认开启"，在 0.17.0 上**不成立**：

| 构建模式 | `builtin.mode` 的 tagName | `@errorReturnTrace() != null` | `catch unreachable` 失败时 |
|---|---|---|---|
| Debug | `.debug` | **true** | panic + `error return context` + 栈跟踪 |
| ReleaseSafe | `.safe` | **false** | panic，**无** `error return context` |
| ReleaseFast | `.fast` | **false** | **SIGILL（退出码 -4）**，无任何输出 |
| ReleaseSmall | `.small` | **false** | **SIGILL（退出码 -4）**，无任何输出 |

我用同一个探针程序在四种模式下编译运行，逐字记录：

```text
########## Debug
@errorReturnTrace() != null = true
########## ReleaseSafe
@errorReturnTrace() != null = false
caught Alpha
(no trace)
########## ReleaseFast
@errorReturnTrace() != null = false
caught Alpha
(no trace)
########## ReleaseSmall
@errorReturnTrace() != null = false
caught Alpha
(no trace)
```

⚠️ 顺带一个容易踩的点：**`@tagName(builtin.mode)` 在 0.17 给的是小写名字**。`ReleaseSafe` 打出来是 `safe` 不是 `ReleaseSafe`（`Debug` → `debug`、`ReleaseFast` → `fast`、`ReleaseSmall` → `small`）。想按模式分支得这么写：

```zig
// examples/10_errors2/main.zig 第 820-829 行（test 块里就是这么断言的）
    // 0.17 实测：只有 Debug 模式有 return trace
    if (builtin.mode == .debug) {
        try std.testing.expect(@errorReturnTrace() != null);
    } else {
        try std.testing.expect(@errorReturnTrace() == null);
    }
```

### `@setRuntimeSafety(false)` 关不掉它

第三行输出是个反直觉的实测结论。在 `bootstrapNoSafety` 里写了 `@setRuntimeSafety(false)`，但它调用到的 `startService` → `loadConfig` → `readConfigLine` 三层 `try` 交接**照样出现在 trace 里**。

**两套机制是独立的**：

| 机制 | 管什么 | 能否用 `@setRuntimeSafety(false)` 关掉 |
|---|---|---|
| runtime safety 检查 | 整数溢出、数组越界、`.?` on null、`catch unreachable` | **能** |
| error return trace | 记录 `try` 交接的返回地址 | **不能** |

所以**不要指望用它来"减掉错误追踪的开销"**——它压根不控制这个。

### 为什么这件事值得在意

没有 return trace 时，线上一个 `error.OutOfMemory` 从 20 层调用外冒上来，你只知道"某个地方内存不够"，**不知道是哪条路径烧掉的**。有了它，输出里直接给你 `readConfigLine → loadConfig → startService → bootstrap` 这条链和每层的行号。

但**它的代价是每个 `try` 记一条返回地址**。所以在真正追求性能的热路径上（`ReleaseFast` / `ReleaseSmall`），关掉是有道理的——这也解释了为什么0.17 选择在这两种模式下默认关闭。

## 10.5 `catch` 的分类处理：把内部错误映射成应用层语义

`try` 往上抛、`catch` 就地消化。但最有价值的 `catch` 用法是**第三种**：**在明确的边界上，把一堆内部错误收敛成一小组应用语义。**

```zig
// examples/10_errors2/main.zig 第 179-228 行
/// 内部错误（细）：驱动库/解析层用
const StoreError = error{
    FileNotFound,
    PermissionDenied,
    DiskFull,
    ConnectionLost,
    Timeout,
};

/// 应用层错误（粗）：给用户看的语义
const AppError = error{
    ConfigInvalid,
    ResourceUnavailable,
    UpstreamFailed,
    Cancelled,
};

/// 把 5 个内部错误收敛成 4 个应用语义。switch 穷尽性由编译器守住
fn toAppError(err: StoreError) AppError {
    return switch (err) {
        error.FileNotFound, error.PermissionDenied => error.ConfigInvalid,
        error.DiskFull, error.ConnectionLost, error.Timeout => error.ResourceUnavailable,
    };
}

/// 分类处理的第二种形态：按"要不要重试"分流
const Disposition = enum { retry, give_up, abort };

fn classify(err: StoreError) Disposition {
    return switch (err) {
        error.Timeout, error.ConnectionLost => .retry, // 瞬时故障，重试有意义
        error.FileNotFound, error.PermissionDenied => .give_up, // 再试也没用
        error.DiskFull => .abort, // 资源问题，重试会 worsen
    };
}

fn fetchValue(which: u8) StoreError!u32 {
    return switch (which) {
        0 => error.FileNotFound,
        1 => error.Timeout,
        2 => error.DiskFull,
        else => 7,
    };
}

/// 完整的一层：内部错误 → 应用语义 → 处置动作 + 退出码，一条链走完
fn fetchValueAsApp(which: u8) AppError!u32 {
    // 一处switch 同时决定"给用户的话"和"该怎么处置"——映射只写一次
    const v = fetchValue(which) catch |err| return toAppError(err);
    return v;
}
```

运行输出（`examples/10_errors2/main.zig`）：

```text
==== 10.5 开始 ====
  FileNotFound       → ConfigInvalid        处置=give_up
  Timeout            → ResourceUnavailable  处置=retry
  DiskFull           → ResourceUnavailable  处置=abort
  fetchValueAsApp(0) → ConfigInvalid，退出码 2（配置文件缺失或不可读）
  fetchValueAsApp(1) → ResourceUnavailable，退出码 3（资源不可用（磁盘/网络））
  fetchValueAsApp(2) → ResourceUnavailable，退出码 3（资源不可用（磁盘/网络））
  fetchValueAsApp(3) → 值 7（后端正常）
==== 10.5 结束 ====
```

**为什么要在中间做这次收敛？** 因为 `StoreError` 的五个成员是**给写驱动的人看的**（"是权限问题还是磁盘满？要不要重试？"），而用户不该看到 `error.ConnectionLost` 这种词，也不该由你的程序去决定退几。

`toAppError` 做的是**语义降级**（5 → 4，且换了一套词汇），`classify` 做的是**正交分类**（同一个错误在"用户视角"和"运维视角"下是不同的处置）。**两个维度不要混在一个 `switch` 里**——上面刻意写成两个函数，就是因为它们会独立演化：新增一个内部错误时，`toAppError` 可能要改，`classify` 也可能要改，但它们的映射逻辑不该互相纠缠。

⚠️ **`switch` 的穷尽性是编译器强制的**。`toAppError` 漏掉 `error.Timeout` 会编译失败（`switch must handle all possibilities` + `note: unhandled error value: 'error.Timeout'`）。这是错误集合给的一个真实好处：09 章 9.7 节讲过，这里再强调一次——**枚举的完备性由编译器守住，不用靠 code review**。

⚠️ **注意错误集合的方向**：`StoreError`（5 个）→ `AppError`（4 个）是**收窄**，编译器**不允许**隐式做（09 章 9.9 节：`error: expected type ... note: 'error.X' not a member of destination error set`）。所以必须写一个显式的 `switch` 来做映射——**这个"必须显式"恰恰是好事**，它逼你把"这个内部错误对用户意味着什么"这个问题回答一遍。

## 10.6 错误 → 退出码：程序边界的最后一层

错误只有名字，操作系统只认整数。这是错误处理的**最后一公里**。

```zig
// examples/10_errors2/main.zig 第 231-252 行
const Advice = struct { msg: []const u8, code: u8 };

fn advise(err: AppError) Advice {
    return switch (err) {
        error.ConfigInvalid => .{ .msg = "配置文件缺失或不可读", .code = 2 },
        error.ResourceUnavailable => .{ .msg = "资源不可用（磁盘/网络）", .code = 3 },
        error.Cancelled => .{ .msg = "操作被取消", .code = 4 },
        error.UpstreamFailed => .{ .msg = "上游服务失败", .code = 5 },
    };
}

/// 最后一层：把错误翻成进程退出码。这个函数是"错误 → 操作系统"的翻译器
fn runOnce(which: u8) u8 {
    const v = fetchValueAsApp(which) catch |err| {
        const a = advise(err);
        // 边界层才记日志：更下面那些层只负责传播，不刷屏
        std.log.scoped(.app).err("{s}", .{a.msg});
        return a.code;
    };
    _ = v;
    return 0; // 成功：约定 0
}
```

运行输出（`examples/10_errors2/main.zig`，`error(app):` 那几行走的是 stderr）：

```text
==== 10.6 开始 ====
error(app): 配置文件缺失或不可读
  runOnce(0) → 退出码 2
error(app): 资源不可用（磁盘/网络）
  runOnce(1) → 退出码 3
error(app): 资源不可用（磁盘/网络）
  runOnce(2) → 退出码 3
  runOnce(3) → 退出码 0
  advise 穷尽性由编译器守住：漏一个成员报 switch must handle all possibilities
==== 10.6 结束 ====
```

**为什么日志只在边界层记？** 一次 `runOnce(1)` 在 20 层调用链里失败，如果每层都 `log.err` 一笔，用户会看到 20 条几乎一样的错误。这里只在**翻译点**（`runOnce`）记一条——因为只有这一层知道"该怎么跟用户说"以及"该退几"。

`switch` 返回 `struct { msg, code }` 而不是两个独立函数，好处是**消息和退出码永远配对**，加错误时不会漏改其中一个。

⚠️ **退出码是应用层的设计决定，不是语言规定的**。`error.ConfigInvalid` 退 2 还是退 4，取决于整个程序怎么设计（要和 shell 脚本、CI 系统的约定对齐）。`switch` + 返回 struct 是干净的写法，比一串 `if` 好扩展。

⚠️ **不要用错误编号当退出码**。09 章 9.4 节实测过 `error.OutOfMemory = 65` 这类全局编号，但那是**编译单元决定的临时值**，改一行代码就可能变。要退 65 就手写 `65`。

## 10.7 `@errorCast`：错误集的降级与升级

`@errorCast` 做**降级**（宽集合 → 窄集合的运行期检查），而**升级**（窄 → 宽）是编译器免费提供的。

### 降级姿势 A：`switch` 逐个认识（推荐）

```zig
// examples/10_errors2/main.zig 第 256-280 行
/// 窄集合：对外承诺只会出这三种错
const PublicError = error{ Invalid, Unavailable };

/// 宽集合：内部可能出任何错
fn wideSource(kind: u8) anyerror!u8 {
    return switch (kind) {
        0 => error.Invalid,
        1 => error.Unavailable,
        else => error.SomeoneElsesError, // 不在 PublicError 里
    };
}

/// 降级姿势 A：switch 逐个认识，不认识的统一折叠成一个成员（不 panic）
fn narrowBySwitch(kind: u8) PublicError!u8 {
    const v = wideSource(kind) catch |err| switch (err) {
        error.Invalid => 1,
        error.Unavailable => 2,
        else => {
            // 关键动作：把"不认识"变成一个**有名字的**窄集合成员，
            // 而不是让 @errorCast 在运行期panic
            return error.Unavailable;
        },
    };
    return v;
}
```

### 降级姿势 B：`@errorCast` 直传（零成本，但越界 panic）

```zig
// examples/10_errors2/main.zig 第 282-289 行
/// 降级姿势 B：@errorCast 直传（09 章 9.10讲过）——错误在集合内时零成本，越界 panic
fn narrowByCast(kind: u8) PublicError!u8 {
    const v = wideSource(kind) catch |err| {
        // 有已知结果类型（函数的返回类型），所以 @errorCast 能定型
        return @errorCast(err);
    };
    return v;
}
```

运行输出（`examples/10_errors2/main.zig`）：

```text
==== 10.7 开始 ====
  narrowBySwitch(0) → 值 1（不 panic）
  narrowBySwitch(1) → 值 2（不 panic）
  narrowBySwitch(2) → Unavailable（不认识的错误被折叠成命名成员）
  narrowByCast(0) → Invalid（在集合内，@errorCast 零成本）
  narrowByCast(1) → Unavailable（在集合内，@errorCast 零成本）
  widen(error.Invalid) → Invalid（升级不损失错误名）
  ⚠️ narrowByCast(2) 会 panic：thread ... panic: unexpected error code, found error.SomeoneElsesError
     （@errorCast 的越界是 panic 不是错误，所以公开边界上 prefer narrowBySwitch）
  DbError || NetError = error{Conflict,NotFound,Timeout,Unreachable}（成员 4 个，@sizeOf=2 字节——并集不花额外空间）
    backend(db=true, net=true) → 值 3
    backend(db=true, net=false) → Timeout（一个 catch 接住两个来源）
    backend(db=false, net=true) → NotFound（一个 catch 接住两个来源）
==== 10.7 结束 ====
```

**两种姿势怎么选**，这是本节最实际的结论：

| | `narrowBySwitch` | `narrowByCast` |
|---|---|---|
| 越界时 | **返回一个命名成员**（可恢复） | **panic**（进程死） |
| 运行期成本 | 一个 `switch` | 零（编译后就是 mov） |
| 适合 | **公开 API 边界**、不可控输入 | 你**确实知道**错误在集合内的内部热路径 |

**默认选 `narrowBySwitch`。** 理由：`@errorCast` 的语义是"我检查过了，这个错误确实在我的集合里"——检查失败说明**你的判断错了**，属于编程错误所以直接崩。但**在公开边界上，错误来自你控制不了的地方**（用户输入、第三方库、网络），"我不认识它"是**运行期正常情况**，不是编程错误。用 `narrowByCast` 在这里就是把用户的输入变成你的崩溃。

### 升级：窄 → 宽是免费的

```zig
// examples/10_errors2/main.zig 第 291-294 行
/// 升级：窄 → 宽，编译器自动 coerce，try 一下就过
fn widen(narrow: PublicError) anyerror!u8 {
    return narrow;
}
```

输出 `widen(error.Invalid) → Invalid`——**升级不损失错误名**。09 章 9.9 节讲过这个方向是单向允许的：子集 → 超集自动 coerce，超集 → 子集必须显式。所以**"内部窄、对外宽"是好设计**：内部用精确的小集合（编译器帮你守住所有路径），对外用 `anyerror` 或一个大集合（不承诺细节）。

### 错误集并集作为公开契约

0.17 的 `||` 是**错误集并集**（09 章 9.5/9.9 讲过含义变了），这里用它写公开签名：

```zig
// examples/10_errors2/main.zig 第 296-313 行
const DbError = error{ NotFound, Conflict };
const NetError = error{ Unreachable, Timeout };
const BackendError = DbError || NetError;

fn dbQuery(ok: bool) DbError!u32 {
    if (!ok) return error.NotFound;
    return 1;
}
fn netCall(ok: bool) NetError!u32 {
    if (!ok) return error.Timeout;
    return 2;
}
/// 返回类型写成并集：一次签名覆盖两个来源，调用方一个 catch 全接住
fn backend(ok_db: bool, ok_net: bool) BackendError!u32 {
    const a = try dbQuery(ok_db);
    const b = try netCall(ok_net);
    return a + b;
}
```

⚠️ **返回类型里的 `||` 需要括号**：`(A || B)!u8` 或 `BackendError!u32`。实测 `@typeInfo(@TypeOf(backend)).@"fn".return_type.?` 打出来是 `error{Conflict,NotFound,Timeout,Unreachable}!u32`，确认解析正确。

输出里两处值得注意：

**① 并集不花额外空间**：`@sizeOf=2 字节`，和单个错误集一样（09 章 9.4 节：错误在内存里就是一个 `u16` 编号，并集只是名字变多）。

**② 嵌套并集会扁平化**：写 `A || B || C` 和写 `A || (B || C)` 结果一样，都是一个扁平的集合。`@typeName` 里的成员顺序是 `error{Conflict,NotFound,Timeout,Unreachable}`——**注意这个顺序既不是 `DbError || NetError` 的声明顺序，也不是字母序**（09 章 9.4 节结论④：`error_names` 的顺序 ≠ 声明顺序）。**别依赖顺序。**

### `@errorCast` 在 `catch` 里没有结果类型

09 章 9.10 节实测过，这里再确认一次（因为它是写`narrowByCast` 时最容易卡住的地方）：

```text
$ const v = wideSource(kind) catch |err| @errorCast(err);
p5.zig:52:41: error: @errorCast must have a known result type
    const v = pickAny(flag) catch |err| @errorCast(err);
                                        ^~~~~~~~~~~~~~~
p5.zig:52:41: note: use @as to provide explicit result type
```

`catch` 后备值的类型由**上下文**决定，但 `@errorCast` 在这个位置还没定型。两种解法（示例里两种都用了）：

```zig
// 写法 A：让函数返回类型定型（narrowByCast 用的）
return @errorCast(err);

// 写法 B：先赋给有类型的局部变量（09 章 narrowAnyToNarrow 用的）
const small: PublicError = @errorCast(err);
return small;
```

## 10.8 错误信息里带上下文：结构体载荷 vs 日志

**Zig 的 `error` 没有 payload**（09 章 9.4 节实测：不能写 `error.NotDigit{ pos = 3 }`）。但错误处理经常需要回答"哪个文件、第几行、哪个字符"。有两条路，各有适用场景。

### 路线①：结构体攒上下文 + 一次性记日志

```zig
// examples/10_errors2/main.zig 第 316-335 行
/// 路线①：错误本身不带payload（0.17 的error 没有载荷），
/// 想带"哪个文件第几行"就用结构体把上下文攒起来，一次性写进日志
const LoadError = error{ EmptyFile, BadLine, TooManyRows };

const LoadFailure = struct {
    code: LoadError,
    path: []const u8,
    line: usize,

    /// 把上下文一次性写进日志（scoped，方便按模块过滤）
    fn report(self: LoadFailure) void {
        // ⚠️ 这个守卫是本示例里最关键的一处改动，务必保留：
        // std.log.err 会让 `zig test` 以非零码退出（test_runner 打印
        //   "N errors were logged." 然后 std.process.exit(1)）。
        // 测试里也会走这些失败路径，所以测试环境下静音，只在真实运行时记日志。
        if (builtin.is_test) return;
        const log = std.log.scoped(.loader);
        log.err("{s}:{d} 加载失败：{s}", .{ self.path, self.line, @errorName(self.code) });
    }
};
```

运行输出（`examples/10_errors2/main.zig`）：

```text
==== 10.8 开始 ====
error(loader): data.csv:3 加载失败：BadLine
loadRows 失败：BadLine（上下文 path:line 已写进上面的 error(loader) 日志）
loadRows 成功：2 行
parseRich("12x") → bad pos=2 ch=x（错误做不到：error 没有 payload）
代价对比：LoadFailure=32 字节（要自己分配/传递），ParseResult=12 字节，LoadError=2 字节（只有名字）
==== 10.8 结束 ====
```

看第一行和第二行的分工：`error.BadLine` 是**返回值**（给程序逻辑分支用），`data.csv:3` 是**日志**（给人看）。两者是**同一个失败的两个投影**，各走各的通道。

### ⚠️ `if (builtin.is_test) return;` 这个守卫为什么必须存在

这是本章**最实用的一个坑**，而且它的行为非常反直觉。

`std.log.err` 看起来只是"打一行日志"，但在 `zig test` 下它会让**整个测试进程以非零码退出**。原因是测试运行器自己接管了 `logFn`：

```zig
// lib/compiler/test_runner.zig 第 346-362 行
pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    @disableInstrumentation();
    if (@backingInt(message_level) <= @backingInt(std.log.Level.err)) {
        log_err_count +|= 1;          // ← err 级就计数
    }
    if (@backingInt(message_level) <= @backingInt(testing.log_level)) {
        std.debug.print(
            "[" ++ @tagName(scope) ++ "] (" ++ @tagName(message_level) ++ "): " ++ format ++ "\n",
            args,
        );
    }
}
```

```zig
// lib/compiler/test_runner.zig 第 332-343 行
    if (log_err_count != 0) {
        std.debug.print("{d} errors were logged.\n", .{log_err_count});
    }
    if (leaks != 0) {
        std.debug.print("{d} tests leaked memory.\n", .{leaks});
    }
    if (fuzz_count != 0) {
        std.debug.print("{d} fuzz tests found.\n", .{fuzz_count});
    }
    if (leaks != 0 or log_err_count != 0 or fail_count != 0) {
        std.process.exit(1);            // ← 计数非零就退 1
    }
```

实测一个只调用一次 `log.err` 的测试：

```text
[loader] (err): t1: 出事了
All 2 tests passed.
1 errors were logged.
error: the following test command failed with exit code 1:
/Users/xulun/.cache/zig/o/b8eabe7d62581cc84f2a90efaf494a7a/test --seed=0xae0a09b0
```

注意这个输出有多误导人：**`All 2 tests passed.`** 出现了，然后紧接着 `1 errors were logged.`，最后**整个命令以 1 退出**。如果只看第一行，你会以为测试通过了。

而且注意 `[loader] (err):` 这个前缀和正常运行的 `error(loader):` 完全不同——那是 test_runner 的格式（`[scope] (level): `），不是 `defaultLog` 的格式（`level(scope): `）。

**所以 `LoadFailure.report()` 里的 `if (builtin.is_test) return;` 不是权宜之计，是必需的**：测试会故意走失败路径来验证错误处理，如果这些路径都往 stderr 刷 `err` 级日志，`run-all.sh` 的第三层就会红。

### 路线②：需要精确位置就用 `union(enum)`

```zig
// examples/10_errors2/main.zig 第 366-377 行
/// 路线②：需要"精确定位"（第几个字符、那个字符是什么）就别用错误，
/// 改用 union(enum)自己包一个带数据的结果——错误没payload，结果可以有
const ParseResult = union(enum) {
    ok: u8,
    bad: struct { pos: u32, ch: u8 },
};

fn parseRich(s: []const u8) ParseResult {
    for (s, 0..) |c, i| {
        if (c < '0' or c > '9') return .{ .bad = .{ .pos = @intCast(i), .ch = c } };
    }
    return .{ .ok = 7 };
}
```

输出 `parseRich("12x") → bad pos=2 ch=x`——**第几个字符、那个字符是什么，精确到位**。这是 `error` 做不到的（09 章：错误没有 payload）。

### 两条路怎么选

| | 路线① `struct` + 日志 | 路线② `union(enum)` |
|---|---|---|
| 载荷 | 存在**结构体**里，要自己传递 | 存在**返回值**里，类型系统保证送到 |
| 内存 | 32 字节（`LoadFailure`） | 12 字节（`ParseResult`） |
| 调用方拿得到吗 | 拿不到（除非也返回它） | **拿得到** |
| 适合 | 诊断信息（日志、监控） | 业务数据（"第几个字符错了"要展示给用户/做高亮） |
| 错误还能 `try` 传播吗 | 能（返回 `LoadError`） | **不能**——它不是错误联合，只能 `switch` |

⚠️ **最关键的一条**：如果调用方**需要**根据位置做不同的事（比如编辑器给第 2 个字符加红波浪线），那就**必须**用路线②——路线①的上下文写进日志后就丢了，调用方拿不到。**日志是给人看的，程序逻辑要用就把它放进返回值。**

⚠️ `ParseResult` 里的 `ok: u8` 有点怪（不管输入是什么都返回 7）——这是为了演示结构故意简化的。真实场景下 `ok` 应该装解析出来的值。

## 10.9 `catch unreachable`：正当与滥用

`catch unreachable` 的意思是"**我担保这里不会失败，失败就是我的 bug**"。它是一个**断言**，不是一个兜底。

### 各模式下失败时会发生什么（实测）

这是本章第三个**实测纠正**。同一个探针程序（`boom()` 返回 `error.Boom`，调用处写 `boom() catch unreachable`）在四种模式下编译运行：

```text
Debug         rc=-6 | mode=debug / thread 1127650 panic: attempt to unwrap error: Boom
                             error return context:
                             p9.zig:6:5: 0x107fbe97f in boom (p9)
                                 return error.Boom;
                                      ^
                             stack trace: ...
ReleaseSafe   rc=-6 | mode=safe / thread 1129162 panic: attempt to unwrap error: Boom
                             p9.zig:11:28: 0x100d1d31d in main (p9)
                                 const v = boom() catch unreachable;
                                                    ^
ReleaseFast   rc=-4 | mode=fast /（无任何输出）
ReleaseSmall  rc=-4 | mode=small /（无任何输出）
```

⚠️ **Debug 与 ReleaseSafe 有实质差别**：

- **Debug**：panic 消息 + `error return context` 段（**告诉你错误是哪一层传上来的**）+ `stack trace:` 段（告诉你 `catch unreachable` 在哪一行）。定位信息最全。
- **ReleaseSafe**：仍然 panic（`rc=-6` = SIGABRT），但**没有 `error return context`**——因为这个模式没有 error return trace（10.4 节）。只有崩溃点那一帧。
- **ReleaseFast / ReleaseSmall**：`rc=-4` = **SIGILL（非法指令）**。**不是 panic，没有消息，没有栈跟踪，进程直接死。** 这是 `unreachable` 在 release 下的真实实现——编译器把它编译成一条 `ud2` 指令（"这里理论上到不了"的 CPU 陷阱）。

⚠️ 注意 panic 消息是 **`attempt to unwrap error: Boom`**——**带上了错误名**，比 `.?` 的 `attempt to use null value` 信息量大得多。

### 正当用法：输入确实不可控失败

```zig
// examples/10_errors2/main.zig 第 381-392 行
///正当用法：字面量输入，编译期就已知不可能失败
fn parseConstOK(s: []const u8) u8 {
    if (s.len == 0) return 0;
    const c = s[0];
    return if (c >= '0' and c <= '9') c - '0' else 0;
}

/// catch unreachable 的正当姿势：包一层只吃已知安全输入的函数
fn digitOfConst(text: []const u8) u8 {
    // text 来自常量表，逻辑上不可能解析失败
    return std.fmt.parseInt(u8, text, 10) catch unreachable;
}
```

运行输出（`examples/10_errors2/main.zig`）：

```text
==== 10.9 开始 ====
正当：digitOfConst("42")=42，digitOfConst("7")=7（常量表，不可能失败）
正当：parseConstOK("5")=5，parseConstOK("")=0（自己处理了边界）
滥用：digitOfUser("42")=42 能过，但 digitOfUser("abc") 会 panic
  → 同一个函数，用户能喂的输入就是不可控输入；catch unreachable 在这里是拿 UB赌运行时
==== 10.9 结束 ====
```

`digitOfConst` 的判据很明确：**输入来自常量表**（`"42"`、`"7"` 是字面量）。如果哪天有人给它喂个运行时字符串，测试会立刻炸出来——**这就是断言的价值：它把"我以为不可能"变成编译后仍会检查的东西**（Debug/ReleaseSafe 下）。

`parseConstOK` 是另一种正当：**根本不用 `catch unreachable`，自己处理边界**（空串、越界）。能用普通逻辑表达清楚的就别用断言。

### 滥用：把不可控输入喂给断言

```zig
// examples/10_errors2/main.zig 第 394-396 行
/// 滥用：把用户输入直接喂给 catch unreachable
fn digitOfUser(text: []const u8) u8 {
    return std.fmt.parseInt(u8, text, 10) catch unreachable; // ❌ 用户能喂"abc"
}
```

这个函数**在测试里能过**（只喂 `"42"`），**在生产里会崩**（用户喂 `"abc"`）。而且崩溃形态还取决于构建模式：Debug 下是一句带错误名的 panic，ReleaseFast 下是**无声的 SIGILL**。

### 判据

| 场景 | 该用什么 |
|---|---|
| 输入是字面量 / 常量表 / 编译期常量 | ✅ `catch unreachable` |
| 数组下标在 `switch`/`if` 里已经证过界 | ✅ `catch unreachable` |
| 枚举的 `u2` 值，`switch` 穷尽后编译器已排除 | ✅ `unreachable`（10.11 节） |
| 输入来自用户 / 文件 / 网络 / 环境变量 | ❌ 返回 `E!T` |
| 输入来自第三方库，错误集你说了不算 | ❌ `catch` + 兜底 |
| 只是"懒得写 else" | ❌ `orelse` / `catch` 给默认值 |

**一句话**：`catch unreachable` 只在"**输入来源与失败模式都可数**"时用。输入来源一旦变成"外部世界"，它立刻变成一个随机崩溃源。

⚠️ **`digitOfUser` 我故意没有写进 `test` 块**（只测了它成功的那条路径）。想验证它会panic，正确做法是 `expectError` 测一个真会失败的调用，而不是在测试里触发 panic：

```zig
// examples/10_errors2/main.zig 第 888-896 行
    // ⚠️ 这里**故意不测** digitOfUser("abc")：它会 panic（Debug 下带栈跟踪）。
    // 正确做法是用 expectError 或者让函数返回错误，而不是 catch unreachable。
    try std.testing.expectError(error.InvalidCharacter, std.fmt.parseInt(u8, "abc", 10));
```

## 10.10 `?E!T`：三态与内存代价

09 章 9.12 节讲过 `?E!T` 的三态语义。本章补两件 09 章没做的：**两种嵌套顺序的实测对照**、**精确的内存代价**。

```zig
// examples/10_errors2/main.zig 第 399-415 行
const ParseError = error{ Empty, NotDigit };

/// 可选在外：错误在内 → 先orelse 再 catch
fn parseOuterOpt(s: ?[]const u8) ?ParseError!u8 {
    const str = s orelse return null; // 缺席
    if (str.len == 0) return error.Empty;
    if (str[0] < '0' or str[0] > '9') return error.NotDigit;
    return str[0] - '0';
}

/// 错误在外：可选在内 → 先 catch 再 orelse
fn parseOuterErr(s: ?[]const u8) ParseError!?u8 {
    const str = s orelse return null; // 缺席
    if (str.len == 0) return error.Empty;
    if (str[0] < '0' or str[0] > '9') return error.NotDigit;
    return str[0] - '0';
}
```

运行输出（`examples/10_errors2/main.zig`）：

```text
==== 10.10 开始 ====
大小：u8=1  ?u8=2  ParseError!u8=4  ?ParseError!u8=6  ParseError!?u8=4
反射：?ParseError!u8 tag=optional，optional.child=error{Empty,NotDigit}!u8
反射：ParseError!?u8 tag=error_union，error_union.payload=?u8
  in=7     ?E!T  ③ 值 7
  in=null  ?E!T  ① 缺席
  in=x     ?E!T  ② 错误 NotDigit
  in=      ?E!T  ② 错误 Empty
  in=7     E!?T  ③ 值 7
  in=null  E!?T  ① 缺席
  in=x     E!?T  ② 错误 NotDigit
  in=      E!?T  ② 错误 Empty
  ⚠️ 两种嵌套语义完全一样（都是三态），但解包顺序相反、大小不同（6 vs 4 字节）
==== 10.10 结束 ====
```

**两列输出逐行相同**——因为三态的**语义**只取决于"有没有值/是不是错误/两个都没有"，与书写顺序无关。差别在**怎么写**和**占多少字节**。

### 解包顺序：由外层类型决定

| 类型 | 先解 | 后解 | 语法 |
|---|---|---|---|
| `?E!T` | 可选（外） | 错误（内） | `x orelse ...` 然后 `catch` |
| `E!?T` | 错误（外） | 可选（内） | `try` / `catch` 然后 `orelse` |

写反了编译器会拦（09 章 9.12 节实测）：

```text
$ const eu = f() orelse 0;        // f() 返回 error{A}!u8
error: expected optional type, found 'error{A}!u8'
note: consider using 'try', 'catch', or 'if'

$ const b = a catch 7;            // a 是 ?u8
error: expected error union type, found '?u8'
note: consider omitting 'try'
```

### ⚠️ 大小代价：`?E!T` 是 6 字节，`E!?T` 只要 4 字节

这是本节最有用的实测数字。**同样三态，书写顺序不同，占用差 50%。**

| 类型 | `@sizeOf` | 为什么 |
|---|---|---|
| `u8` | **1** | 裸值 |
| `?u8` | **2** | 1 字节 payload + 1 字节可选标记 |
| `ParseError!u8` | **4** | 2 字节错误编号 + 1 字节 payload + 1 字节 padding |
| `?ParseError!u8` | **6** | `ParseError!u8` 的 4 字节 + 2 字节可选标记（标记与 payload 同宽） |
| `ParseError!?u8` | **4** | 2 字节错误编号 + 2 字节 `?u8`，**刚好装下，无 padding** |

**为什么 `?E!T` 更贵？** 因为可选的标记单元宽度**跟着 payload 宽度走**（09 章 1.1 节实测：`?u16` 的 tag 是 `u16`）。`?E!u8` 的 payload 是 `E!u8`（4 字节），于是标记单元也占 4 字节，4+2 舍入到对齐得 6。而 `E!?u8` 的 payload 是 `?u8`（2 字节），加上 2 字节错误编号正好 4 字节。

⚠️ **别把 `?E!T` 当默认签名。** 一个"可选套错误联合"要 6 字节，数组里有十万个就是 600KB vs 400KB。**只在真的需要三态时用**；能拆成"返回可选，错误另走通道"就别嵌套。

⚠️ **反射形状同样印证了这一点**（09 章坑位清单第 4 条）：

```text
反射：?ParseError!u8 tag=optional，optional.child=error{Empty,NotDigit}!u8
反射：ParseError!?u8 tag=error_union，error_union.payload=?u8
```

`?E!T` 的 `typeInfo` 标签是 `.optional`，`.optional.child` 是那个错误联合；`E!?T` 的标签是 `.error_union`，`.error_union.payload` 是那个可选。**注意 0.17 的 `Optional` 结构体字段是 `.child` 不是 `.payload`，而 `ErrorUnion` 仍然叫 `.payload`**——两个结构体不一致，别记混。

### 三态的判断顺序：先问"有没有值"

三种状态的**判断顺序**是固定的，无论书写顺序：

1. 先看**可选**（`?`）——`null` 就是"没有结果"，这是**正常业务结果**；
2. 再看**错误**（`!`）——是错误就是**异常路径**；
3. 都不是就是**有值**。

这个顺序反映了一个语义判断：**"没有"比"出错"更轻**。查字典没查到（`null`）是正常结果，字典文件打不开（`error`）才是问题。所以代码里应该**先处理 `null`**，把它和真正的错误区分开。

## 10.11 错误 vs panic vs 退出码：三者分工

这是全章的收尾。三个都能"终止一段执行"，但适用场景完全不同。

```zig
// examples/10_errors2/main.zig 第 419-433 行
/// 程序员错误（bug）用 panic：调用前就该断言，不该"处理"
fn mustPositive(x: i32) i32 {
    if (x <= 0) @panic("x 必须为正"); // 主动崩溃，带栈跟踪
    return x;
}

/// u2 只有 0..3，switch穷尽后编译器知道3 到不了
fn classifyNibble(x: u2) []const u8 {
    return switch (x) {
        0 => "零",
        1 => "一",
        2 => "二",
        3 => unreachable, // 逻辑上到不了（但注意：这是"到不了"，不是"我保证"）
    };
}
```

运行输出（`examples/10_errors2/main.zig`）：

```text
==== 10.11 开始 ====
必须是正数：mustPositive(5)=5，classifyNibble(2)=二
三层分工：
  错误E!T  —— 可预期的失败，要让调用方处理（return/try/catch）
  panic    —— 程序员错误，继续跑就是错的（@panic / unreachable / .?失败）
  退出码    —— 程序边界的最后翻译（std.process.exit(advice(e).code)）
  当前模式 debug 下 catch unreachable 失败会 panic（ReleaseFast 下是 UB，没有检查）
==== 10.11 结束 ====
```

### 分工表

| |错误 `E!T` | panic / unreachable | 退出码 |
|---|---|---|---|
| **语义** | 可预期的失败 | 程序员错误（bug） | 程序结束 |
| **谁能处理** | 调用方（`try`/`catch`） | **没人** | shell / CI /父进程 |
| **类型系统** | 强制处理，不处理编译不过 | 不在类型里 | 不在类型里 |
| **恢复可能** | 有（换个策略继续） | 无 | N/A |
| **诊断信息** | error return trace（Debug） | 栈跟踪 + 源码行 | 只有整数 |
| **控制粒度** | 每个调用点 | 整个进程 | 整个进程 |
| **Zig 里的写法** | `return error.X` / `try` | `@panic` / `unreachable` / `.?` / `catch unreachable` | `std.process.exit(n)` |

### 判据：问"调用方能不能处理"

**用错误**，当且仅当**调用方有得选**：

- 文件不存在 → 调用方可以换路径、可以问用户、可以跳过（09 章 9.7 节的 `catch 0`）
- 网络超时 → 调用方可以重试（10.5 节的 `classify` → `.retry`）
- 解析失败 → 调用方可以报"第几个字符错了"（10.8 节）

**用 panic**，当"**继续跑下去会变得更糟**"：

- `mustPositive(0)`：一个非正数的"有效范围"已经意味着逻辑错了，带着它算下去会产出垃圾数据
- `.?` 碰到 null：9.2 节的 `constTableIndex` 用它是对的（编译期越界会编译报错），用在"懒得判断"上就是灾难
- `unreachable`：编译器已经证明这条路径到不了

⚠️ **`classifyNibble` 里的 `unreachable` 是个有趣的边界情况**：输入是 `u2`，值域 `0..3`，而 `switch` 已经处理了 `0,1,2`。所以 `3` **在类型上是合法的**（`u2` 装得下 3），只是这个函数选择不处理它。写 `unreachable` 意味着"**如果有人给 3，我宁可崩也不返回错误答案**"。

这和 `mustPositive(0)` 的 `unreachable` 是同一类：**"输入在类型上合法，但违反了前置条件"**。这类断言是 API 契约的运行时执行——比"让调用方处理"更快，也更诚实（我不会给一个错误答案）。

⚠️ **不要在错误路径上 panic。** 看到"`catch unreachable` 出现在解析用户输入的函数里"，基本可以判定这是滥用。真正的判据不是"我觉得它不会失败"，而是"**失败来源是否可数**"（10.9 节的表）。

⚠️ **退出码只在程序边界产生。** `error.ConfigInvalid` 转成 `2` 这个决定，只有在 `main` / CLI 入口那一层才有意义（10.6 节）。库代码里写 `std.process.exit(2)`是灾难——它让库无法被复用（没法嵌入别的程序，也没法被测试）。

## 10.12 `std.log` 的分级与作用域

`std.log` 是标准库统一的日志接口。它的两级结构：**级别**（`Level`）决定"这条消息多重要"，**作用域**（`scoped`）决定"这条消息来自哪个模块"。

```zig
// examples/10_errors2/main.zig 第 721-731 行
    std.debug.print("log.Level 成员 {d} 个，@sizeOf={d} 字节（是 enum，ordinal 从 0 开始）\n", .{
        @typeInfo(std.log.Level).@"enum".field_names.len, @sizeOf(std.log.Level),
    });
    inline for (@typeInfo(std.log.Level).@"enum".field_names) |fname| {
        const ord: u8 = @intCast(@backingInt(@field(std.log.Level, @as([]const u8, fname[0..fname.len]))));
        const lv: std.log.Level = @fromBackingInt(@intCast(ord));
        std.debug.print("  {s:<6} ordinal={d} asText={s}\n", .{ fname[0..fname.len], ord, lv.asText() });
    }
    std.debug.print("default_level = {s}（由 builtin.mode={s} 决定：debug 模式全开，release 只到 info）\n", .{
        @tagName(std.log.default_level), @tagName(builtin.mode),
    });
```

运行输出（`examples/10_errors2/main.zig`）：

```text
==== 10.12 开始 ====
log.Level 成员 4 个，@sizeOf=1 字节（是 enum，ordinal 从 0 开始）
  err    ordinal=0 asText=error
  warn   ordinal=1 asText=warning
  info   ordinal=2 asText=info
  debug  ordinal=3 asText=debug
default_level = debug（由 builtin.mode=debug 决定：debug 模式全开，release 只到 info）
下面 4 行是 defaultLog 打到**stderr** 的四个级别（0.17 的 log 函数签名固定两个参数，格式串 + args元组）：
debug: debug：排查时才看
info: info：常规状态
warning: warn：可疑但不致命
error: err：出事了
scoped(.loader) 会给每行加上 (loader) 前缀：
warning(loader): 这是 scoped 的 warn
error(loader): 这是 scoped 的 err
⚠️ 关键坑：std.log.err 会让 `zig test` 整体失败——
   test_runner 统计 err 级条数，打印 "N errors were logged." 然后 exit(1)，
   即使 "All N tests passed." 也会以非零码退出。所以 LoadFailure.report() 里有
   if (builtin.is_test) return; 守卫：测试走失败路径时静音，只在真实运行时记日志。
==== 10.12 结束 ====
```

### 四个级别

`std.log.Level` 是个 4 成员枚举，**ordinal 从 0 开始，数字越大越啰嗦**（对照 0.17 源码 `lib/std/log.zig` 第 30-51 行）：

| 级别 | ordinal | `asText()` | 用于 | 计入测试失败？ |
|---|---|---|---|---|
| `.err` | 0 | `error` | 出事了 | **是** |
| `.warn` | 1 | `warning` | 可疑但不致命 | 否 |
| `.info` | 2 | `info` | 常规状态 | 否 |
| `.debug` | 3 | `debug` | 排查时才看 | 否 |

默认级别由构建模式决定（`lib/std/log.zig` 第 54-57 行）：

```zig
pub const default_level: Level = switch (builtin.mode) {
    .debug => .debug,
    .safe, .fast, .small => .info,
};
```

⚠️ 注意是 `.safe` 不是 `.ReleaseSafe`——0.17 的 `builtin.mode` 枚举成员是小写的（10.4 节）。所以 Debug 下四级全开，三种 release 模式下 `debug` 被编译掉（`logEnabled` 是 `comptime` 判断，不产生任何运行期代码）。

### 输出格式

看输出里那四行的前缀：`debug:` / `info:` / `warning:` / `error:`。加了 `scoped(.loader)` 之后变成 `warning(loader): ...` / `error(loader): ...`。

对照 `defaultLogFileTerminal` 的实现（`lib/std/log.zig` 第 125-131 行）：

```zig
    try t.writer.writeAll(level.asText());
    t.setColor(.reset) catch {};
    t.setColor(.dim) catch {};
    t.setColor(.bold) catch {};
    if (scope != .default) try t.writer.print("({t})", .{scope});
    try t.writer.writeAll(": ");
```

`scope != .default` 才打括号——所以**不带 scope 的 `std.log.err` 输出是 `error: 出事了`（无括号）**。

⚠️ **日志走 stderr，不走 stdout**。这是 Unix 惯例：stdout 是数据，stderr 是诊断。所以 `run-all.sh` 里 `zig build-exe` 之后再运行程序时，`std.debug.print` 的输出和 `std.log` 的输出在终端上是交错的（因为 `std.debug.print` 也走 stderr），但**重定向时两者是分开的**。想只取数据就 `2>/dev/null`。

⚠️ **0.17 的 log 函数签名固定两个参数**：`log.err(格式串, args元组)`。写 `std.log.err("出事了")`（少一个参数）会报：

```text
main.zig:733:12: error: expected 2 argument(s), found 1
    std.log.debug("debug：排查时才看");
    ~~~~~~~^~~~~~
```

即使格式串里**没有**任何占位符，`{}` 也必须写。

### `scoped`：给日志加模块前缀

```zig
// examples/10_errors2/main.zig 第 334行（LoadFailure.report 里）、第 737-740 行
        const log = std.log.scoped(.loader); // 10.8 节：加载器
        const log = std.log.scoped(.app);    // 10.6 节：应用边界
```

`std.log.scoped(.loader)` 返回一个**匿名结构体类型**，里面有 `err`/`warn`/`info`/`debug` 四个函数，全部绑定了 `.loader` 这个作用域。`scope` 参数是 `@EnumLiteral()`——**不是运行时字符串**，所以过滤逻辑能在 `comptime` 完成。

`test` 块里可以断言这四个方法存在：

```zig
// examples/10_errors2/main.zig 第 944-950 行
    // scoped(.loader) 存在且四个方法齐备
    const l = std.log.scoped(.loader);
    try std.testing.expect(@hasDecl(l, "err"));
    try std.testing.expect(@hasDecl(l, "warn"));
    try std.testing.expect(@hasDecl(l, "info"));
    try std.testing.expect(@hasDecl(l, "debug"));
```

⚠️ `@hasDecl` 在 0.17 收**字符串**（不是符号），所以写 `@hasDecl(l, "err")`。

### ⚠️ `std.log.err` 与测试退出码（本节的核心坑）

10.8 节已经详述了机制（`test_runner.zig` 的 `log_err_count` + `exit(1)`）。这里补一条**实践建议**：

| 场景 | 做法 |
|---|---|
| 库代码要记错误 | `if (builtin.is_test) return;` 守卫（10.8 节的 `LoadFailure.report`） |
| 或者 | 降级用 `log.warn`（warn **不**计入 `log_err_count`，实测不导致失败） |
| 或者 | 自定义 `std.options.logFn`，过滤掉测试环境的 err |

**但不要为了通过测试就删掉日志。** 10.8 节那个守卫的写法是"测试环境静音、真实运行照记"——既保住了测试的退出码，也保住了生产环境的可观测性。**这是正确的做法**；把 `log.err` 全删掉才是错的。

⚠️ 注意 `log.warn` 在测试里**是会被打印的**（`testing.log_level` 默认是 `.warn`）：

```zig
// lib/std/testing.zig 第 29 行
pub var log_level = std.log.Level.warn;
```

所以用 `warn` 代替 `err` 时，测试输出里会多出 `[loader] (warn): ...` 这样的行——**不影响退出码，但会污染输出**。真要静默，还是用 `builtin.is_test` 守卫。

## 10.13 测试：把语义钉住

本章行为全靠测试守着（`main.zig` 第 750-950 行，13 个 `test` 块）：

```text
$ zig test main.zig
1/13 main.test.10.1 errdefer 回滚计数与对象...OK
2/13 main.test.10.2 多资源回滚与部分初始化...OK
3/13 main.test.10.2 注入失败分配器：证明内存真的还回去了...OK
4/13 main.test.10.3 defer/errdefer 是纯粹的 LIFO（与直觉相反）...OK
5/13 main.test.10.4 错误链路 + return trace 的可用性...OK
6/13 main.test.10.5 catch 的分类处理把内部错误收敛成应用语义...OK
7/13 main.test.10.6 错误 → 退出码...OK
8/13 main.test.10.7 @errorCast 的降级与升级...OK
9/13 main.test.10.8 上下文：结构体载荷 vs union(enum) 结果...OK
10/13 main.test.10.9 catch unreachable：正当输入通过...OK
11/13 main.test.10.10 ?E!T 与 E!?T：同一三态、不同解包顺序与大小...OK
12/13 main.test.10.11 panic 与 unreachable 的正当输入...OK
13/13 main.test.10.12 std.log.Level 的四个级别与默认级别...OK
All 13 tests passed.
```

几个关键断言：

- **10.1**：`made` 计数在成功路径 +1、失败路径回滚——把"errdefer 真的撤销了副作用"钉死。
- **10.2**：`FailingAllocator` 的 `allocations == 1 && deallocations == 1`——从分配器层面证明内存没泄漏。
- **10.3**：四条断言覆盖 `defer`/`errdefer` × 两种注册顺序 × 成功/失败。**`"Iieo"` 和 `"DE"` 这两个断言是本章的结论载体**——我第一版写错了（`Ieio`），被测试当场抓住并纠正（见 10.3 节）。
- **10.4**：按 `builtin.mode` 分支断言 return trace 的存在性——这条断言在 Debug 和 ReleaseSafe 下会走**不同分支且都通过**，这本身就是"两者行为不同"的证明。
- **10.10**：`@sizeOf(?ParseError!u8) == 6` 与 `@sizeOf(ParseError!?u8) == 4`——把内存代价钉死，防止有人"顺手改成另一个顺序"而没人发现。
- **10.12**：`std.log.Level` 的四个 `asText()`、ordinal 值（`err=0`、`debug=3`）、以及 `default_level` 按模式分支。

⚠️ **测试里刻意不碰的两条路径**（10.9、10.11 节）：

```zig
// examples/10_errors2/main.zig 第 888-896 行
    // ⚠️ 这里**故意不测** digitOfUser("abc")：它会 panic（Debug 下带栈跟踪）。
    // 正确做法是用 expectError 或者让函数返回错误，而不是 catch unreachable。
    try std.testing.expectError(error.InvalidCharacter, std.fmt.parseInt(u8, "abc", 10));
```

```zig
// examples/10_errors2/main.zig 第 919-926 行
    // ⚠️ 故意不测 mustPositive(0) / classifyNibble(3) 的 panic 路径
    // mustPositive(0) → panic: x 必须为正
    // classifyNibble(3) 在 u2 的值域内，**能跑**，返回 unreachable 是被断言为不可能的分支
```

**这是本章的一条方法论**：测试不该触发 panic。panic 路径的正确验证方式是"用一个会返回错误的等价调用 + `expectError`"，或者干脆在注释里写明"这里会panic，触发它就是 bug"。

## 10.14 坑位清单

1. **⚠️ `defer` 与 `errdefer` 共用一个 LIFO 栈，谁后注册谁先跑。** 实测：`defer`→`errdefer` 注册序给出 `ED`，只把两行调换成 `errdefer`→`defer` 就给出 `DE`；嵌套注册序 `o→e→i→I` 运行序 `Iieo`。**"`errdefer` 优先"是观察偏差**（那段代码里 `errdefer` 恰好写在 `defer` 后面）。写依赖清理顺序的代码时，把 `errdefer` 显式写在你希望它**后**跑的位置。

2. **⚠️ 0.17 的 error return trace 只有 Debug 模式有，ReleaseSafe 没有。** 实测四模式：`debug`→`true`，`safe`/`fast`/`small`→`false`。书上和多数资料说"Debug 和 ReleaseSafe 默认开启"，在 0.17.0 上不成立。别在 ReleaseSafe 下指望从 trace 定位错误来源。

3. **⚠️ `catch unreachable` 在 ReleaseFast / ReleaseSmall 下是 SIGILL（`rc=-4`），不是 panic。** 实测四模式：Debug → panic + `error return context` + `stack trace:`（`rc=-6`）；ReleaseSafe → panic但**无** `error return context`（`rc=-6`）；ReleaseFast / ReleaseSmall → **无任何输出的非法指令陷阱**（`rc=-4`）。这三条都不是错误处理，只是"不可达"被硬件拦下了。

4. **`std.log.err` 会让 `zig test` 以非零码退出，即使全部断言通过。** `test_runner` 统计 `err` 级条数（`log_err_count`），打印 `N errors were logged.` 后 `std.process.exit(1)`。实测输出里 `All 2 tests passed.` 和 `1 errors were logged.` **同时出现**——只看第一行会误判。**必须在日志函数里加 `if (builtin.is_test) return;` 守卫**（本例 `LoadFailure.report()`），或改用 `log.warn`（warn 不计入计数）。

5. **`std.process.args` 在 0.17 已移除。** `error: root source file struct 'process' has no member named 'args'`。参数要走 `pub fn main(init: std.process.Init)`，然后 `init.minimal.args`——但它是 `process.Args` 结构体（字段是 `vector`，**没有 `.len`、没有 `.argv`**），要拿个数得`std.process.Args.Iterator.initAllocator(init.minimal.args, gpa)` 逐个迭代。

6. **`std.testing.allocator` 只能在 `test` 块里用。** 它的定义是 `if (builtin.is_test) allocator_instance.allocator() else @compileError("not testing")`，在 `main` 里用报 `error: not testing`。要在 `main` 里演示注入失败分配器，用 `std.testing.FailingAllocator.init(真实分配器, .{ .fail_index = n })`。

7. **函数参数名不能和文件里的函数/常量重名。** 写 `fn fetchValueAsApp(backend: u8)` 而文件里已有 `fn backend(...)` 会报 `error: function parameter shadows declaration of 'backend'` + `note: declared here`。Zig 不做遮蔽（05 章 5.3 节），参数名和文件级名字共用一个命名空间。

8. **`@tagName(builtin.mode)` 在 0.17 是小写**：`debug` / `safe` / `fast` / `small`。`builtin.mode == .Debug` 编译不过（0.16 才是大写）。对比 10.4 节的表。

9. **⚠️ `?E!T`（6 字节）比 `E!?T`（4 字节）贵50%。** 实测 `u8`=1、`?u8`=2、`ParseError!u8`=4、`?ParseError!u8`=**6**、`ParseError!?u8`=**4**。原因：可选的标记单元宽度跟着 payload 走，`?E!u8` 的 payload 是 4 字节所以标记也占 4。别把 `?E!T` 当默认签名。

10. **`@errorCast` 在 `catch` 表达式里没有结果类型**：`error: @errorCast must have a known result type` + `note: use @as to provide explicit result type`。两种解法：`return @errorCast(err)`（让函数返回类型定型）或先赋给有类型的局部变量。

11. **`@errorCast` 越界是 panic 不是错误**：`thread ... panic: unexpected error code, found error.SomeoneElsesError`。所以**公开 API 边界上优先用 `switch` 逐个映射**（把"不认识"变成一个命名成员），别用 `@errorCast`——外部输入下"不认识"是正常情况，不是编程错误。

12. **返回类型里的 `||` 是错误集并集**：`(DbError || NetError)!u32` 合法，实测 `@typeName` 得到 `error{Conflict,NotFound,Timeout,Unreachable}!u32`。但**并集只能并错误集**——`E || Payload` 报 `error: expected error set type, found 'u32'`（造错误联合用 `E!T`，09 章坑位第 7 条）。并集**不花额外空间**（`@sizeOf` 仍是 2 字节），且会**扁平化**、**成员顺序不等于声明顺序**。

13. **0.17 的 `std.log.*` 签名固定两个参数**：`log.err(格式串, args)`。哪怕格式串没有任何占位符，少写 `{}` 也报 `error: expected 2 argument(s), found 1`。

14. **`std.log` 的输出走 stderr，且带 scope 时格式是 `level(scope): msg`。** 不带 scope（`.default`）时**没有括号**——`error: msg`（对照 `lib/std/log.zig` 第 129 行的 `if (scope != .default)`）。测试环境下 test_runner 换成了完全不同的 `[scope] (level): msg` 格式。

15. **`@hasDecl` 在 0.17 收字符串**：`@hasDecl(T, "err")`，不是符号。

16. **`while` 里的 `defer` 全部堆到函数出口**（实测 `loopDeferCount(100000)=100000`，执行时机推迟到循环结束后）。循环中间panic/超时的话这些清理可能没机会跑，而且 10 万个活跃 `defer` 要占 10 万个栈槽位。**正确做法是把每轮的清理封成独立函数**（本例 `loopScoped` + `deferRound`），让 `defer` 随作用域立即生效。⚠️顺带：书上"把 `errdefer` 放在循环外"的建议在 0.17 上是危险的——循环外只有一条 `errdefer` 保护 N 轮已获取的资源，中途失败时你不知道该释放几个。

17. **`errdefer` 不在"错误被本地 catch 掉"时执行。** 实测：函数里 `_ = f() catch |e| { ...; return; }` 消化了错误后函数正常返回，外层 `errdefer` **不跑**。判据是"**函数是否真的返回了错误**"，不是"过程中是否出现过错误"。

---

上一章：[09 可选与错误 I](09-optionals-errors.md) · 下一章：[11 分配器](11-allocators.md)
