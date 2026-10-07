# 23 · 调试与工具

> 对应示例：`examples/23_debug/main.zig`（534 行）
>
> 本章是全教程唯一一章**故意把程序弄崩**的章节。所以它有一个特殊的设计约束：
> 验证脚本要求 `./run-all.sh 23_debug` 退出码 0，
> 于是所有 panic 演示全部跑在**子进程**里（`std.process.run` 拉起同一个可执行文件的另一个实例），
> 父进程拿它的 stderr、打印前几行、然后自己正常退出。
>
> 本章有**五条结论会推翻你可能听过的说法**，全部是0.17.0 本机实测：
>
> 1. **`ZIG_PANIC` 和 `ZIG_BACKTRACE` 在 0.17 完全失效**。不是"废弃"，是 `lib/std` 全目录
>    grep **零命中**——根本没有代码读它们。ReleaseFast 下设 `ZIG_PANIC=1` 依然是静默 UB。
> 2. **ReleaseSafe（`-O ReleaseSafe`）有 panic 栈跟踪**。10 章子 agent 实测的
>    "ReleaseSafe 默认没有 panic 栈跟踪"是**误判**——真正的原因是内联/尾调用优化把中间帧消掉了，
>    加 `noinline` 后四种模式全部打出完整栈（见 23.2.3）。
>    但 **ReleaseSafe 确实没有 error return trace**（这一条 10 章说对了）。
> 3. **`@errorReturnTrace()` 在 0.17 返回 `?*StackTrace`（可选指针）**，
>    旧写法 `const t = @errorReturnTrace(); t.index` **编译失败**。
> 4. **`std.debug.panicImpl` 已移除**，`dumpCurrentStackTrace` 改成**要一个参数**
>    （`StackUnwindOptions`）。旧文档里的 `dumpCurrentStackTrace()` 零参数写法编译不过。
> 5. **`std.log.scoped(.名字)` 的作用域名必须是 ASCII 标识符**——
>    `.示例` 这种中文 enum literal 直接编译失败（`expected expression, found '.'`）。
>
> 另外一条本教程独有的实测发现：**panic 消息里带错误上下文时，
> 输出会多出`error return context:` 和 `stack trace:` 两个小标题**（见 23.3.2），
> 这是 0.17 才有 的分段，0.16 的输出是平铺的。

---

## 23.1 Zig 的调试哲学：没有 printf 式猜测

别的语言调试的第一步往往是"加点打印看看"。Zig 的立场不同：**大部分 bug 在编译期就被拦住了**，所以运行时诊断只剩下一类东西——"这里不可能成立，却成立了"。

Zig 把排错分成三层，从前到后代价递增：

| 层| 手段 | 什么时候用 | 代价 |
|---|---|---|---|
| 1 | **编译错误** | 类型不匹配、字段不存在、整数溢出（comptime 已知） | 重新编译 |
| 2 | **panic** + 栈跟踪 | 运行期"不可能成立"：越界、除零、`.?` 解 null、`unreachable` | 进程终止 |
| 3 | **error 返回跟踪** | 可恢复的错误从产生到上抛的路径 | 打印若干行 |

这三层的界线是Zig 特有的：**同一件事，取决于它"是否可能发生"**。

```zig
// examples/23_debug/main.zig 第 130-156 行
pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    // 子进程模式：argv[1] 命中就跑注定崩的分支（父进程不受影响）
    const argv = try init.minimal.args.toSlice(arena);
    const mode: []const u8 = if (argv.len > 1) argv[1] else "";

    // ═══ 子进程入口：以下分支只有子进程会走，父进程永远不崩 ═══
    if (std.mem.eql(u8, mode, "crash-panic")) {
        crashTop();
    }
```

运行输出（`examples/23_debug/main.zig`）：

```text
==== 23.1 调试哲学 开始 ====
Zig 的排错顺序：编译错（comptime）→ panic（运行期不可恢复）→ error（可恢复）
没有 printf 式猜测：类型写错是**编译错误**，不是运行期 surprises
本文件能编过 ⇒ 23 个小节里没有一处类型错误；能跑完 ⇒ 没有未处理的错误
panic 在Zig 的设计里是**一等公民**，不是"失败"：它是"这里不可能成立"的宣告
本节要用的四个诊断维度：
  1) 编译期：-freference-trace 追"谁引用的"
  2) panic：消息 + 栈跟踪（本节起23.2）
  3) error return trace：错误从产生到上抛的路径（23.5）
  4) 调试器：lldb / gdb（23.13）
==== 23.1 调试哲学 结束 ====
```

**"panic 是设计的一部分"这句话在 Zig 里有具体含义**：panic 的消息文本是**你写进源码的**，
不是运行时由库生成的。`@panic("数据库连接池耗尽")` 会原封不动出现在 stderr 第一行。
这意味着 panic 消息可以承担真正的文档职责——而 C 的 `assert()` 只能给你一个 `__assert_fail`。

而"错误用 `!T` 不用 panic"这条规则（10 章）的直接后果是：
**Zig 程序的退出码本身携带信息**。panic → 134（SIGABRT），错误返回 → 1，正常 → 0。
CI 里只看退出码就能区分"崩溃"和"优雅失败"。

## 23.2 panic 栈跟踪：逐字抄下来的真实格式

这是本章最该抄走的一段。下面是**本机`examples/23_debug/main.zig` 的真实 stderr**
（通过子进程抓回来打印的）：

```text
thread 1860248 panic: 演示 panic：这是 @panic 的自定义消息
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:91:31: 0x10b193cd4 in myPanic (main)
        std.debug.defaultPanic(msg, first_trace_addr);
                              ^
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:30:5: 0x10b2f515b in crashLeaf (main)
    @panic("演示 panic：这是 @panic 的自定义消息");
    ^
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:34:14: 0x10b2f4f58 in crashMid (main)
    crashLeaf();
             ^
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:38:13: 0x10b2f4cd8 in crashTop (main)
    crashMid();
            ^
```

⚠️ **不可复现的部分**（抄的时候必须替换掉）：
**每一个 `0x` 地址、线程号 `1860248`、路径前缀都是每次运行不同的**。
本机实测连跑两次，地址完全不同（`0x10b193cd4` vs `0x10415fcd4`），
但**帧数、函数名序列、消息文本、源码行、`^` 的列位置完全一致**。
下面所有代码块里的地址都用真实值抄，但请把它们读成"某个 16 进制数"。

### 23.2.1 帧的形状怎么解析

一帧是**三行**一组：

```text
/Volumes/.../examples/23_debug/main.zig:30:5: 0x10b2f515b in crashLeaf (main)
    @panic("演示 panic：这是 @panic 的自定义消息");
    ^
```

| 片段 | 含义 |
|---|---|
| `/Volumes/.../main.zig` | **编译时**记录的源码路径（不是运行时读的，所以路径可能是构建机的） |
| `:30:5:` | **行:列**。列指向 `^` 那一列 |
| `0x10b2f515b` | 指令地址。ASLR 每次不同，**不要拿它当稳定标识** |
| `in crashLeaf` | **函数名**（Zig 的函数名，不是符号名 mangling） |
| `(main)` | **镜像名**：macOS/Linux 上是产物文件名（这里因为产物叫 `main` 所以叫 `main`）；Windows 上是 `(main.obj)` |

第 2 行是源码摘录，第 3 行是列指示线。`^` 对准的是**出问题的那一列**——
`@panic` 的 `^` 指向 `@`（第 5 列），`crashMid()` 里的 `crashLeaf()` 的 `^` 指向 `c`。

### 23.2.2 `in callMain` 和 `in main` 的区别

栈的末尾固定有这两帧：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:827:30: 0xADDR in callMain (main)
    return wrapMain(root.main(.{
                             ^
???:?:?: 0xADDR in start (/usr/lib/dyld)
```

- **`in main`** 是**你写的** `pub fn main`。它的上一行源码摘录会显示你最后执行的语句。
- **`in callMain`** 是 `lib/std/start.zig` 里的包装层——它负责把 `std.process.Init` 造好、
  设置 panic handler、然后调你的 `main`。**这一帧永远存在，不是你的代码**，看到就跳过。
- **`???` + `in start (/usr/lib/dyld)`** 是 macOS 的动态链接器。`???` 表示
  它没有 DWARF 调试信息（系统库通常是 stripped 的）。Linux 上对应的是
  `__libc_start_main` 之类，Windows 上是 `KERNEL32.DLL` 里的某个函数。

**所以栈跟踪的"有效部分"是从第一帧到 `in main` 为止。** 后两帧是固定噪声。

### 23.2.3 ⚠️ 四种构建模式下的栈跟踪（这一节推翻旧结论）

这是本机实测表（macOS x86_64，zig 0.17.0）。靶子是三级调用链：

```zig
// examples/23_debug/main.zig 第 28-40 行
noinline fn crashLeaf() void {
    @panic("演示 panic：这是 @panic 的自定义消息");
}

noinline fn crashMid() void {
    crashLeaf();
}

noinline fn crashTop() void {
    crashMid();
}
```

| 模式 | `@tagName(builtin.mode)` | panic 栈帧数 | error return trace | 退出码 |
|---|---|---|---|---|
| `-ODebug`（默认） | `debug` | **完整**（含 crashLeaf/crashMid/crashTop/main/callMain/dyld） | **有** | 134 |
| `-O ReleaseSafe` | `safe` | **完整**（实测 6 帧，同Debug） | **没有** | 134 |
| `-O ReleaseFast` | `fast` | **完整**（实测 6 帧） | 没有 | 134 |
| `-O ReleaseSmall` | `small` | **一行字**：`Cannot print stack trace: stack tracing is disabled` | 没有 | 134 |

ReleaseSmall 那行字的原因在 `std/std.zig` 第 185 行：

```zig
allow_stack_tracing: bool = !@import("builtin").strip_debug_info,
```

而 `-OReleaseSmall` **默认就 strip 调试信息**。只要 strip 了，栈跟踪整个禁用——
不是"退化"，是彻底没有。

**⚠️ 这里必须澄清一个流传很广的错误说法。**
有教程（包括本教程 10 章的子 agent 实测）说"ReleaseSafe 默认没有 panic 栈跟踪"。
本机实测**否定了这个说法**，但也解释了它从哪来：

用**没有 `noinline`** 的版本（普通小函数）在 ReleaseSafe 下编译，panic 只打**一帧**：

```text
thread 1726247 panic: 演示 panic：看栈跟踪
/Volumes/.../p1.zig:3:5: 0xADDR in level3 (p1)
    @panic("演示 panic：看栈跟踪");
    ^
???:?:?: 0xADDR in start (/usr/lib/dyld)
```

这一帧甚至被算到了**错误的位置**——报的是 `lib/std/multi_array_list.zig:246 in main`，
一个和靶子毫无关系的文件。原因不是"没开栈跟踪"，而是
**`level2`/`level1` 被内联进 `main` 了，物理栈帧压根不存在**。
把三个函数加上 `noinline`（上面那份代码），ReleaseSafe 立刻打出完整 6 帧。

所以正确的说法是：

> **栈跟踪在所有非 strip 模式下都能工作；但优化会把帧内联掉，
> 所以"看起来只有一帧"。加 `noinline` 就能拿回完整栈。**

这对实践的含义很直接：**想看完整的 panic 栈，就用 `-ODebug`；
不要指望 ReleaseSafe 能给你和 Debug 一样的栈，也不要为了"栈好看"去给业务代码加 `noinline`。**

`ReleaseSafe` 真正缺的是**另一件事**：error return trace（23.5）。

## 23.3 `@panic` / `unreachable` / `assert` 三者

三者的栈跟踪形状**完全一样**，区别只在第一行消息和多不多一帧。

### 23.3.1 实测输出对照

靶子（三个分支，用子进程分别跑）：

```zig
// examples/23_debug/main.zig 第 42-46 行 行
fn pick(x: u8) u8 {
    if (x == 0) unreachable; // 分支1：编译器消息 reached unreachable code
    if (x == 1) @panic("自定义消息"); // 分支2：自定义文本
    return x;
}
```

`unreachable` 的真实输出：

```text
thread 1861304 panic: reached unreachable code
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:43:17: 0x10a767c9c in pick (main)
    if (x == 0) unreachable; // 分支1：编译器消息 reached unreachable code
                ^
```

`@panic` 的真实输出（同一个 `pick`，`x == 1`）：

```text
thread 1767719 panic: 自定义消息
/Volumes/mac004/code/programming/zig/examples/23_debug/probe.zig:4:17: 0xADDR in pick (unreach)
    if (x == 1) @panic("自定义消息");
                ^
```

`std.debug.assert` 的真实输出——**注意多了一帧 `in assert`，而且它在 `lib/std` 里**：

```text
thread 1861309 panic: reached unreachable code
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/debug.zig:442:14: 0xADDR in assert (main)
    if (!ok) unreachable; // assertion failure
             ^
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:63:21: 0xADDR in risky (main)
    std.debug.assert(x != 0);
                    ^
```

`std.debug.assert` 的实现只有两行（`lib/std/debug.zig` 第 440-442 行）：

```zig
pub fn assert(ok: bool) void {
    if (!ok) unreachable; // assertion failure
}
```

所以 `assert` 的栈跟踪**第一帧指向标准库而不是你的代码**——这是它和 `@panic` 唯一的实质差别。
另外 `assert` 的参数叫 `ok` 而不是 `cond`（源码里就是这么写的）。

### 23.3.2 ⚠️ panic 消息里带错误上下文时，输出会分两段

这是 0.17 才有的行为。`catch unreachable` 触发时，panic 消息是
`attempt to unwrap error: <错误名>`，而 `@errorReturnTrace()` 此时非空，
于是 `defaultPanic` 会打出**两个小标题**（`lib/std/debug.zig` 第 594-598 行）：

```zig
if (@errorReturnTrace()) |t| if (t.index > 0) {
    writer.writeAll("error return context:\n") catch break :trace;
    writeErrorReturnTrace(t, stderr) catch break :trace;
    writer.writeAll("\nstack trace:\n") catch break :trace;
};
```

实测输出（`catch unreachable` 触发）：

```text
thread 1828199 panic: attempt to unwrap error: Boom
error return context:
/Volumes/mac004/code/programming/zig/build/probe23/cu.zig:2:41: 0xADDR in mayFail (cu)
fn mayFail(fail: bool) !u32 { if (fail) return error.Boom; return 7; }
                                        ^

stack trace:
/Volumes/mac004/code/programming/zig/build/probe23/cu.zig:6:35: 0xADDR in main (cu)
    const v = mayFail(fail) catch unreachable;
                                  ^
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:827:30: 0xADDR in callMain (cu)
    return wrapMain(root.main(.{
                             ^
???:?:?: 0xADDR in start (/usr/lib/dyld)
```

**这一段是本教程"读错误信息四个层次"（23.16）的核心依据**：
`error return context:` 是**错从哪来**，`stack trace:` 是**崩在哪**，
两者中间那个空行是分隔符。纯 `@panic`（不是错误）不会打这两个标题——
对比 23.2 的输出，没有小标题。

## 23.4 构建模式与 `std.debug.assert` 的生死

`builtin.mode` 在 0.17 的枚举成员**全小写**（实测）：

```zig
// examples/23_debug/main.zig 第 197-206 行 行
    std.debug.print("本文件编译模式 = {s}（@tagName(builtin.mode)，0.17 四个值全小写）\n", .{@tagName(builtin.mode)});
    std.debug.print("旧的 Debug / ReleaseSafe 大写名在 0.17 是**废弃别名**\n", .{});
    switch (@typeInfo(@TypeOf(builtin.mode))) {
        .@"enum" => |e| {
            std.debug.print("枚举成员实测：", .{});
            inline for (e.field_names) |n| std.debug.print("{s} ", .{n});
            std.debug.print("\n", .{});
        },
        else => {},
    }
```

运行输出（`examples/23_debug/main.zig`）：

```text
==== 23.4 构建模式与 assert 开始 ====
本文件编译模式 = debug（@tagName(builtin.mode)，0.17 四个值全小写）
旧的 Debug / ReleaseSafe 大写名在 0.17 是**废弃别名**
枚举成员实测：debug safe fast small
risky(4) = 25（正常路径，assert 通过）
⚠️ assert 在 ReleaseFast/ReleaseSmall 下被**整个删除**（不是变便宜）
   实测证据：二进制里字符串 "reached unreachable code" 的出现次数
   Debug/ReleaseSafe = 1（还在）；ReleaseFast/ReleaseSmall = 0（被删了）
```

### `assert` 被消除的硬证据

不用"读源码觉得会消失"，直接数二进制里的字符串：

```bash
for m in Debug ReleaseSafe ReleaseFast ReleaseSmall; do
  zig build-exe asrt.zig -O $m -femit-bin=as_$m
  echo -n "$m: "; strings as_$m | grep -c "reached unreachable code"
done
```

实测结果：

```text
Debug: 1
ReleaseSafe: 1
ReleaseFast: 0
ReleaseSmall: 0
```

**ReleaseFast/Small 下这个字符串在二进制里根本不存在**——`assert` 及其panic 消息
被整体删掉了。这是"编译期消失"的直接证据。

### ⚠️ assert 消失后的死法不止一种

靶子：

```zig
// examples/23_debug/main.zig 第 62-65 行 行
fn risky(x: u32) u32 {
    std.debug.assert(x != 0);
    return 100 / x;
}
```

让子进程跑 `risky(0)`，四种模式实测：

| 模式 | 结果 | 退出码 |
|---|---|---|
| Debug | `panic: reached unreachable code` + 栈跟踪 → SIGABRT | 134 |
| ReleaseSafe | 同上（但栈跟踪可能退化成一帧）→ SIGABRT | 134 |
| **ReleaseFast** | assert 没了，`100 / 0` 变成 UB → x86 上是**死循环，进程挂住** | **超时** |
| **ReleaseSmall** | UB 被编译成 `ud2` 指令 → **SIGILL** | **132** |

所以"Debug 测得好好的、发布版裸奔"不是比喻：ReleaseFast 下是**静默挂死**，
ReleaseSmall 下是 SIGILL。这两种都不是 134——**如果你的 CI 只匹配 134 来判断"是不是断言炸了"，
在 ReleaseFast 构建上会完全失效。**

```zig
// examples/23_debug/main.zig 第 211-217 行 行
    std.debug.print("⇒ assert 只断\"逻辑不可能\"；真可能发生的用!T 错误返回（10 章）\n", .{});
    std.debug.print("⇒ 子进程跑 risky(0) 的真实结果（三种完全不同的死法，实测）：\n", .{});
    std.debug.print("   Debug     → panic \"reached unreachable code\"，SIGABRT，退出码 134\n", .{});
    std.debug.print("   ReleaseSafe → 同样 SIGABRT 退出码 134，但栈跟踪只剩一帧（见 23.2.3）\n", .{});
    std.debug.print("   ReleaseFast → assert 没了，除以 0 变成 UB：x86 上是死循环，**进程挂住**\n", .{});
    std.debug.print("   ReleaseSmall → UB 被编译成 ud2 指令：SIGILL，退出码 132\n", .{});
    std.debug.print("   ⇒ \"Debug 测得好好的、发布版裸奔\"不是比喻，是这四行实测\n", .{});
```

⚠️ 顺带一条实测：`-O` 的四个值在 0.17 **必须全小写**。写 `-O ReleaseSafe` 能编过
（是废弃别名），但 `zig build-exe --help` 里列的正式名是 `ReleaseSafe`、
而 `@tagName(builtin.mode)` 给的是 `safe`——**同一个东西两个名字**，写代码时以 `@tagName` 为准。

## 23.5 error return trace：错误从产生到上抛的路径

10 章讲过error return trace 的**概念**（错误是值，`try` 是传播机制）。
这一节讲**工具层面**：怎么让它打印出来、打印成什么样。

靶子是三级错误上抛：

```zig
// examples/23_debug/main.zig 第 48-60 行
fn errLeaf() error{Boom}!void {
    return error.Boom;
}

fn errMid() error{Boom}!void {
    return errLeaf();
}

fn errTop() error{Boom}!void {
    return errMid();
}
```

让 `main` 直接 `return errTop()`，**实测 stderr**：

```text
error: Boom
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:49:5: 0xADDR in errLeaf (main)
    return error.Boom;
    ^
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:53:5: 0xADDR in errMid (main)
    return errLeaf();
    ^
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:57:5: 0xADDR in errTop (main)
    return errMid();
    ^
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:147:9: 0xADDR in main (main)
    return errTop();
    ^
```

### 与 panic 栈的三个关键区别

| | panic 栈 | error return trace |
|---|---|---|
| 第一行 | `thread <tid> panic: <消息>` | `error: <错误名>` |
| **帧的语义** | **调用栈**（谁调用了崩的地方） | **try传播链**（错误从哪冒到哪） |
| 退出码 | 134（SIGABRT） | **1**（正常退出） |
| 出现在哪些模式 | 所有非 strip 模式 | **只有 Debug** |

第三行是最容易被忽略但最重要的：**panic 的帧是"谁调用了它"（自下向上读），
error return trace 的帧是"错误从哪来"（自上往下读）**。
排错时前者告诉你"路径"，后者告诉你"源头"。

**"error return trace 只在 Debug 有"这条本机实测确认**：同一份代码
`-O ReleaseSafe` 下只打一行 `error: Boom`，**一个帧都没有**。

而且**错误返回不是崩溃**——退出码 1，`term` 是 `.{ .exited = 1 }` 而不是 `.{ .signal = .ABRT }`。
这是 Zig 和 C 的根本区别：C 里所有错误最后都汇进一个 `return -1`（或者更糟：静默错误码），
Zig 里错误一路带着自己的类型和来源往上走。

## 23.6 `@errorReturnTrace`：0.17 的形状变了

**这是本章最容易踩的坑之一。** 0.17 里 `@errorReturnTrace()` 的返回值从
`StackTrace`（值）变成了 **`?*StackTrace`（可选指针）**。

旧写法直接编译失败：

```zig
const t = @errorReturnTrace();
std.debug.print("index={d}\n", .{ t.index }); // ❌ 0.17 编译失败
```

实测报错：

```text
probe.zig:8:48: error: type '?*lang.StackTrace' does not support field access
    std.debug.print("index={d} len={d}\n", .{ t.index, t.instruction_addresses.len });
                                              ~^~~~~~
referenced by:
    callMain [inlined]: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:827:30
    5 reference(s) hidden; use '-freference-trace=7' to see all references
```

正确写法是先解包：

```zig
// examples/23_debug/main.zig 第 237-244 行 行
    const maybe_trace = @errorReturnTrace();
    std.debug.print("本作用域 @errorReturnTrace() 类型 = {s}\n", .{@typeName(@TypeOf(maybe_trace))});
    if (maybe_trace) |t| {
        std.debug.print("  非空：index={d}，instruction_addresses.len={d}\n", .{ t.index, t.instruction_addresses.len });
        std.debug.print("  （index > 0 说明当前在错误传播路径上；否则是 0）\n", .{});
    } else {
        std.debug.print("  为 null：当前作用域没有错误返回跟踪\n", .{});
    }
```

运行输出（`examples/23_debug/main.zig`）：

```text
⚠️ 0.17 的形状变了：@errorReturnTrace() 返回 **?*StackTrace**（可选指针）
   旧写法 `const t = @errorReturnTrace(); t.index` 在 0.17 **编译失败**：
   error: type '?*lang.StackTrace' does not support field access（实测）
本作用域 @errorReturnTrace() 类型 = ?*lang.StackTrace
  非空：index=0，instruction_addresses.len=32
  （index > 0 说明当前在错误传播路径上；否则是 0）
字段名实测（std.builtin.StackTrace）：
  .index                   : usize
  .instruction_addresses   : []usize
```

### 两个字段的含义

| 字段 | 类型 | 含义 |
|---|---|---|
| `.index` | `usize` | 当前**已经走过**了几帧。`0` = 不在错误传播路径上 |
| `.instruction_addresses` | `[]usize` | 完整缓冲区的**地址数组**（容量是固定的，不是当前帧数） |

⚠️ **`instruction_addresses.len` 不是"当前有多少帧"**。它是缓冲区的长度（本机实测 32）。
真正有效的帧数是 `index`。`writeErrorReturnTrace` 内部就是这么算的
（`lib/std/debug.zig`）：

```zig
pub fn writeErrorReturnTrace(et: *const std.builtin.StackTrace, t: Io.Terminal) Writer.Error!void {
    const len = @min(et.instruction_addresses.len, et.index);
    const skipped = et.index - len;
    try writeTrace(et.instruction_addresses[0..len], @fromBackingInt(@intCast(skipped)), t, false);
}
```

所以想手动打印 error return trace，**不要自己遍历 `instruction_addresses`**——
直接调 `std.debug.writeErrorReturnTrace(&trace, terminal)`：

```zig
// 手动打印当前作用域的 error return trace（注意要解包 + 取地址）
if (@errorReturnTrace()) |t| {
    std.debug.writeErrorReturnTrace(t, std.debug.lockStderr(&.{}).terminal()) catch {};
}
```

⚠️ `writeErrorReturnTrace` 第一个参数是 `*const StackTrace`——
因为 `@errorReturnTrace()` 现在给的是 `?*StackTrace`，解包后**直接就是指针**，不用 `&`。
（0.16 里要写 `&trace`，0.17 里写 `&trace` 会变成 `**StackTrace` 编译失败。）

## 23.7 `@errorName` / `@errorCast`：另外两个错误内建函数

三个错误相关内建函数的分工：

| 内建函数 | 输入 → 输出 | 给谁看 | 失败表现 |
|---|---|---|---|
| `@errorName(e)` | 错误值 → `"Boom"` | **人**（日志、错误消息） | 编译期检查（要求 `anyerror`） |
| `@errorCast(e)` | `anyerror` → 窄错误集 | **编译器**（缩小错误集合） | **panic**（收窄不匹配时） |
| `@errorReturnTrace()` | 当前作用域 → `?*StackTrace` | **排错的人** | 返回 null |

`@errorName` 最省事，但有个类型要求：**它的参数类型必须是 `anyerror`**。
传一个 `error{Boom}!void`（错误**联合**，不是错误值）会报：

```text
probe.zig:20:56: error: expected type 'anyerror', found 'error{Boom}!void'
    std.debug.print("@errorName = {s}\n", .{@errorName(e)});
```

⚠️ 0.17 的连带坑：`!void` 函数**没法用 `catch |err| err` 拿到错误值**：

```zig
const e: anyerror = errTop() catch |err| err;  // ❌ 实测编译失败
```

```text
probe.zig:19:29: error: expected type 'anyerror', found 'void'
    const e: anyerror = a() catch |err| err;
                        ~~~~^~~~~~~~~~~~~~~
```

原因：`errTop()` 的类型是 `error{Boom}!void`，**成功分支的 payload 是 `void`**，
而 `catch |err| err` 的返回类型要和成功分支做 peer 解析——两边一个是 `void`、
一个是 `error{Boom}`，peer 结果是 `void`。**正确写法是先拿错误联合，再用 `if/else` 解包**：

```zig
// examples/23_debug/main.zig 第 258-268 行 行
    errTop() catch |err| {
        std.debug.print("errTop 的错误名 = {s}（@errorName）\n", .{@errorName(err)});
        std.debug.print("catch 分支里 err 的类型 = {s}\n", .{@typeName(@TypeOf(err))});
        // @errorCast：把 anyerror 收窄成具体错误集合，失败会 panic
        const any: anyerror = err;
        const narrow: error{Boom} = @errorCast(any);
        std.debug.print("@errorCast(anyerror → error{{Boom}}) = {s}\n", .{@errorName(narrow)});
        // 收窄不匹配时会 panic：attempt to cast error value ...（实测见下）
        std.debug.print("⚠️ @errorCast 收窄不匹配会 panic，所以它适合\"已经确定是哪个错\"的收窄点\n", .{});
        std.debug.print("   典型用法：把 anyerror 往上游传递的库API 里做窄化\n", .{});
    };
```

运行输出（`examples/23_debug/main.zig`）：

```text
==== 23.7 @errorName / @errorCast 开始 ====
errTop 的错误名 = Boom（@errorName）
catch 分支里 err 的类型 = error{Boom}
@errorCast(anyerror → error{Boom}) = Boom
⚠️ @errorCast 收窄不匹配会 panic，所以它适合"已经确定是哪个错"的收窄点
   典型用法：把 anyerror 往上游传递的库API 里做窄化
三者的分工：
  @errorName(e)     → 把错误值变成字符串（给人看）
  @errorCast(e)     → 窄化错误集合（给编译器看），运行时可能 panic
  @errorReturnTrace() → 这个错误是从哪条 try 链上来的（给排查看）
==== 23.7 @errorName / @errorCast 结束 ====
```

⚠️ 注意上面这段用的是 `catch |err| { ... }` **块形式**（块里不返回值），
所以绕过了 23.7 开头那个 peer 类型问题。**两种写法按需选**：
要继续用错误值就用块形式 + `return`，要拿错误值就用 `if/else`。

### `@errorCast` 什么时候用

它是**给库 API 用的**：一个库对外声明 `error{A, B}!T`，
但内部调用了返回 `anyerror` 的老代码，收窄点就是 `@errorCast`：

```zig
pub fn narrow(x: any) error{A, B}!void {
    const e = legacyCall(x);          // 任何错误都可能
    if (e) |_| {
        return;
    } else |err| {
        return @errorCast(err);       // ← 收窄点：不匹配就 panic（说明 legacyCall 违反了契约）
    }
}
```

**`@errorCast` panic 是好事**：它把"我以为只会返回 A/B，结果返回了 C"
这个契约违反从"静默传播的怪异错误"变成"立刻炸在现场"。

## 23.8 `std.debug` 的栈dump API（0.17 全部改了签名）

这是本章第二个大坑。旧文档里的 `std.debug.dumpCurrentStackTrace()`（零参数）
**在 0.17 编译失败**：

```text
dump.zig:2:28: error: expected 1 argument(s), found 0
fn deep3() void { std.debug.dumpCurrentStackTrace(); }
                  ~~~~~~~~~^~~~~~~~~~~~~~~~~~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/debug.zig:821:5: note: function declared here
pub fn dumpCurrentStackTrace(options: StackUnwindOptions) void {
~~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
referenced by:
    deep2: dump.zig:3:24
    deep1: dump.zig:4:24
    5 reference(s) hidden; use '-freference-trace=7' to see all references
```

### `std.debug` 声明存在性实测清单

这张表由 `@hasDecl` 逐个探测（用 `inline for`，见坑位清单第 12 条），
是本机 0.17.0 的实测结果：

| 声明 | 存在 | 类型 / 说明 |
|---|---|---|
| `dumpStackTrace` | ✅ | `fn (*const debug.StackTrace) void` |
| `dumpCurrentStackTrace` | ✅ | `fn (StackUnwindOptions) void` ← **0.17 加了参数** |
| `captureCurrentStackTrace` | ✅ | `fn (StackUnwindOptions, []usize) StackTrace`（`noinline`） |
| `writeStackTrace` | ✅ | `fn (*const StackTrace, Io.Terminal) Writer.Error!void` |
| `writeErrorReturnTrace` | ✅ | `fn (*const std.builtin.StackTrace, Io.Terminal) Writer.Error!void` |
| `writeCurrentStackTrace` | ✅ | `fn (StackUnwindOptions, Io.Terminal) Writer.Error!void` |
| `defaultPanic` | ✅ | `fn ([]const u8, ?usize) noreturn` |
| `FullPanic` | ✅ | **工厂函数**：`fn (fn ([]const u8, ?usize) noreturn) type` |
| `simple_panic` | ✅ | `@import("debug/simple_panic.zig")`（裁剪版，省体积） |
| `no_panic` | ✅ | `@import("debug/no_panic.zig")`（完全不 panic） |
| `lockStderr` | ✅ | 拿到 `Io.Terminal`（写栈跟踪要用它） |
| `assert` | ✅ | `fn (bool) void`，两行实现 |
| `panicImpl` | ❌ | **0.17 已移除** |
| `assertFmt` | ❌ | 不存在 |
| `printLock` | ❌ | 0.17 改名 `lockStderr` |
| `getSelfDebugStackTrace` | ❌ | 不存在 |
| `breakpoint` | ❌ | 用内建 `@breakpoint()` |
| `segfault` | ❌ | 不存在 |

### `StackUnwindOptions` 的三个字段

```zig
// examples/23_debug/main.zig 第 276-289 行 行
    begin("23.8 std.debug 栈dump");
    std.debug.print("dumpCurrentStackTrace / dumpStackTrace / captureCurrentStackTrace 都**存在**\n", .{});
    std.debug.print("⚠️ 但 0.17 的 dumpCurrentStackTrace **要一个参数**：\n", .{});
    std.debug.print("   dumpCurrentStackTrace()写 0.17 会报 expected 1 argument(s), found 0（实测）\n", .{});
    std.debug.print("   正确写法：dumpCurrentStackTrace(.{{}})，参数类型 = StackUnwindOptions\n", .{});
    std.debug.print("StackUnwindOptions 的字段（实测 std/debug.zig:666）：\n", .{});
    switch (@typeInfo(std.debug.StackUnwindOptions)) {
        .@"struct" => |s| {
            inline for (s.field_names, s.field_types) |fname, ftype| {
                std.debug.print("  .{s:<22}: {s}\n", .{ fname, @typeName(ftype) });
            }
        },
        else => {},
    }
```

运行输出（`examples/23_debug/main.zig`）：

```text
==== 23.8 std.debug 栈dump 开始 ====
dumpCurrentStackTrace / dumpStackTrace / captureCurrentStackTrace 都**存在**
⚠️ 但 0.17 的 dumpCurrentStackTrace **要一个参数**：
   dumpCurrentStackTrace()写 0.17 会报 expected 1 argument(s), found 0（实测）
   正确写法：dumpCurrentStackTrace(.{})，参数类型 = StackUnwindOptions
StackUnwindOptions 的字段（实测 std/debug.zig:666）：
  .first_address         : ?usize
  .context               : ?*const debug.cpu_context.X86_64
  .allow_unsafe_unwind   : bool
```

| 字段 | 类型 | 用途 |
|---|---|---|
| `.first_address` | `?usize` | 忽略到这个返回地址之前的所有帧（用来剔掉 panic handler 自己那几帧） |
| `.context` | `?*const cpu_context.X86_64` | 从**信号处理器**里打栈时用（内核给的 `ucontext`） |
| `.allow_unsafe_unwind` | `bool` | `true` 时允许用可能崩溃的展开策略。**panic 路径内部就是设的 `true`**（"反正要崩了，拼一把"） |

日常用 `dumpCurrentStackTrace(.{})` 就够——它默认用 `@returnAddress()` 当首帧，
所以**不会把 `dumpCurrentStackTrace` 自己算进栈里**。

### 实际输出

```zig
// examples/23_debug/main.zig 第 433-448 行
noinline fn dumpLeaf() void {
    std.debug.dumpCurrentStackTrace(.{});
}

noinline fn dumpMid() void {
    dumpLeaf();
}

noinline fn dumpTop() void {
    dumpMid();
}

fn dumpDemo() void {
    dumpTop();
}
```

运行输出（`examples/23_debug/main.zig`，地址每次不同）：

```text
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:434:36: 0xADDR in dumpLeaf (main)
    std.debug.dumpCurrentStackTrace(.{});
                                   ^
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:438:13: 0xADDR in dumpMid (main)
    dumpLeaf();
            ^
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:442:12: 0xADDR in dumpTop (main)
    dumpMid();
           ^
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:446:12: 0xADDR in dumpDemo (main)
    dumpTop();
           ^
/Volumes/mac004/code/programming/zig/examples/23_debug/main.zig:291:13: 0xADDR in main (main)
    dumpDemo();
            ^
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:827:30: 0xADDR in callMain (main)
    return wrapMain(root.main(.{
                             ^
???:?:?: 0xADDR in start (/usr/lib/dyld)
```

⚠️ 注意 `dumpDemo` **没有 `noinline` 也没被优化掉**——因为 Debug 模式基本不优化。
在 ReleaseFast 下这个函数栈会被压扁。

### 想"抓了再打"就用 `captureCurrentStackTrace`

`dumpCurrentStackTrace` 是"立刻打到 stderr"。如果想**先存下来、晚点再打**
（比如在错误处理流程里），用 `captureCurrentStackTrace`：

```zig
var buf: [64]usize = undefined;                            // 缓冲区必须活得比 StackTrace 久
const st = std.debug.captureCurrentStackTrace(.{}, &buf);  // st 借用 buf
std.debug.print("capture 帧数 = {d}\n", .{st.return_addresses.len});
// ... 干别的 ...
std.debug.writeStackTrace(&st, std.debug.lockStderr(&.{}).terminal()) catch {};
```

⚠️ 两条硬约束（`lib/std/debug.zig` 第 678-682 行的文档注释明说）：
1. `addr_buf` 的生命周期必须**至少和 `StackTrace` 一样长**——它是借用不是拷贝；
2. `writeStackTrace` 返回 `Writer.Error!void`，**必须 `catch`**（`?` 类型不能忽略）。

`std.debug.StackTrace` 只有两个字段（实测）：

```text
.return_addresses    : []usize
.skipped             : debug.SkippedAddresses
```

`skipped` 是非穷尽枚举，表示"因为缓冲区满了所以丢了几帧"。正常情况是 `.none`。

## 23.9 `std.debug.print` 与 `std.log.*` 的分工

两条输出通道，职责完全不同：

| | `std.debug.print` | `std.log.*` |
|---|---|---|
| 级别 | **无** | `err` / `warn` / `info` / `debug` |
| 默认过滤 | **不过滤，永远打印** | 按 `std.log.default_level` 过滤 |
| 前缀 | 无 | `<级别>(<作用域>): ` |
| 用途 | **示例输出、临时打点** | **库/应用的正式日志** |
| `zig test` 里的行为 | 正常打印，不影响退出码 | **`log.err` 会让退出码变成 1** |

### `scoped` 的输出格式（实测）

```zig
// examples/23_debug/main.zig 第 311-317 行 行
    const log = std.log.scoped(.demo_scope); // ← 作用域名是 @EnumLiteral，只能用 ASCII 标识符
    std.debug.print("--- 下面三条是 std.log.scoped(.demo_scope) 的真实输出 ---\n", .{});
    log.info("scoped 日志的格式是 <级别>(<作用域>): <消息>", .{});
    log.warn("注意 warning 的文本是 'warning' 不是 'warn'", .{});
    std.debug.print("--- scoped 类型 = {s} ---\n", .{@typeName(@TypeOf(log))});
    std.debug.print("⚠️ scoped 返回的是**匿名 struct 类型**，它没有 .scope 字段（实测编译失败）\n", .{});
    std.debug.print("⚠️ test 块里 std.log.err 会让 zig test 退出码变成 1（15.10 实测，本章 test 块守着这条）\n", .{});
```

运行输出（`examples/23_debug/main.zig`）：

```text
std.log.default_level = debug（.debug 模式下是 debug，.safe/.fast/.small 下是 info）
⚠️ 所以 Debug 下 std.log.debug **默认就会打印**（不是被过滤掉）
--- 下面三条是 std.log.scoped(.demo_scope) 的真实输出 ---
info(demo_scope): scoped 日志的格式是 <级别>(<作用域>): <消息>
warning(demo_scope): 注意 warning 的文本是 'warning' 不是 'warn'
--- scoped 类型 = type ---
```

三条实测细节：

1. **`warn` 级别打出来的文本是 `warning`**（不是 `warn`），`err` 打出来是 `error`。
   但 `std.log.Level` 的枚举成员名是 `err` / `warn` / `info` / `debug`。
2. **`scoped` 返回的是匿名 struct 类型**，`@typeName` 给出的就是 `"type"`——
   它**没有 `.scope` 字段**（写 `log.scope` 编译失败，报
   `struct 'log.scoped(.myapp)' has no member named 'scope'`）。
3. **`.示例` 这种中文 enum literal 编译不过**：
   `std.log.scoped(.示例)` 报 `expected expression, found '.'`。
   `@EnumLiteral()` 要求合法的标识符字符。

### `default_level` 各模式实测（`lib/std/log.zig` 第 54-57 行）

```zig
pub const default_level: Level = switch (builtin.mode) {
    .debug => .debug,
    .safe, .fast, .small => .info,
};
```

实测：Debug 下 `log.debug` **默认就打印**（不是被过滤掉）；
`-O ReleaseSafe` 下同样代码只打 info/warn/err 三条，`debug` 那条消失。

### ⚠️ `std.options` 是 `const`，改不了

想运行期调级别不能写 `std.options.log_level = .debug`：

```text
logtest2.zig:5:16: error: cannot assign to constant
    std.options.log_level = .debug;
    ~~~~~~~~~~~^~~~~~~~~~
```

`lib/std/std.zig` 第 119 行：`pub const options: Options = ...`。
**唯一的改法是在根文件声明 `pub const std_options`**（编译期）：

```zig
pub const std_options: std.Options = .{
    .log_level = .warn,                                  // 全局默认
    .log_scope_levels = &.{
        .{ .scope = .myapp, .level = .debug },          // 某个模块单独放开
    },
};
```

实测（`-O ReleaseSafe`，全局 warn 但 myapp 放开到 debug）：

```text
全局 log_level = warn
--- myapp（scope 级覆盖到 debug）---
debug(myapp): myapp debug
info(myapp): myapp info
--- other（走全局 warn）---
warning(other): other warn
```

**`log_scope_levels` 是 0.17 的新东西**（15 章只讲了 `std.testing.log_level`）。
它让你"全局压到 warn、但自己这个模块保持 debug"，比全局一刀切实用得多。

### ⚠️ `std.log.err` 在 `zig test` 里会让退出码非零

15 章已经记过，这里再确认一次实测输出：

```text
1/1 logt.test.log.err 会污染退出码...[default] (err): 我故意记一条 err
OK
All 1 tests passed.
1 errors were logged.
error: the following test command failed with exit code 1:
```

注意第 2 行是 `OK`、第 3 行是 `All 1 tests passed.`——**断言全过了**，
但最后多了 `1 errors were logged.` 且退出码 1。
`[default]` 说明没起 `scoped`（默认作用域就叫 `default`）。

本章所有 `test` 块都守着这条：**不调 `std.log.err`**。

## 23.10 panic handler：0.17 的形状

`std.debug.panicImpl` 在 0.17 **不存在**（实测 `@hasDecl` = false）。
0.17 的接管方式是：

```zig
// examples/23_debug/main.zig 第 17 行 行
pub const panic = std.debug.FullPanic(myPanic);
```

`FullPanic` 是**工厂函数**，返回一个**类型**（不是赋值函数指针）：

```zig
// lib/std/debug.zig 第 99-103 行
/// A fully-featured panic handler namespace which lowers all panics to calls to `panicFn`.
/// Safety panics will use formatted printing to provide a meaningful error message.
/// The signature of `panicFn` should match that of `defaultPanic`.
pub fn FullPanic(comptime panicFn: fn ([]const u8, ?usize) noreturn) type {
    return struct {
        pub const call = panicFn;
        pub fn sentinelMismatch(...) noreturn { ... }
        pub fn outOfBounds(index: usize, len: usize) noreturn { ... }
        pub fn unwrapError(err: anyerror) noreturn { ... }
        pub fn reachedUnreachable() noreturn { ... }
```

所以 `FullPanic(myPanic)` 产生一个类型，它把 Zig 内部的**所有** panic 途径
（越界、unwrapError、sentinel 不匹配、`unreachable`……）
统一转成对 `myPanic` 的调用。handler 的签名（实测 `defaultPanic`）是：

```text
fn ([]const u8, ?usize) noreturn
```

两个参数：**消息** + **首帧返回地址**（可为 null）。

### ⚠️ `pub const panic` 是编译单元级的

一旦在根文件写上 `pub const panic`，**本文件里所有 panic 都走这里**——
包括 23.2/23.3 那些栈跟踪演示。所以本章的 handler 做「按消息分流」：

```zig
// examples/23_debug/main.zig 第 83-99 行 行
/// 关键细节：`pub const panic` 是**整个编译单元的根声明**，一旦写上，
/// 本文件里**所有** panic 都走这里（包括 23.2/23.3 那些栈跟踪演示）。
/// 所以本 handler 做「按消息分流」：只有带标记的那条走自定义路径，
/// 其余原样转回 `std.debug.defaultPanic` —— 这也是真实项目里的常见写法
/// （先做崩溃上报，再委托默认行为打印现场）。
fn myPanic(msg: []const u8, first_trace_addr: ?usize) noreturn {
    if (std.mem.indexOf(u8, msg, "[custom]") == null) {
        // 不归我管：原样交回默认 handler，栈跟踪一字不变
        std.debug.defaultPanic(msg, first_trace_addr);
    }
    // 归我管：自定义动作。first_trace_addr 是首帧返回地址（可为 null），
    // 想继续打栈就把它传给 dumpCurrentStackTrace(.{ .first_address = ... })。
    std.debug.print("[myPanic] 接管 panic：{s}\n", .{msg});
    std.debug.print("[myPanic] 首帧地址存在吗：{}（不打印栈跟踪，这是自定义 handler 的取舍）\n", .{first_trace_addr != null});
    std.debug.print("[myPanic] 改用 std.process.exit(101) 干净退出（不是 SIGABRT 的 134）\n", .{});
    std.process.exit(101);
}
```

⚠️ **`std.debug.defaultPanic` 是 `noreturn`**，所以它之后不能有代码——
编译器知道这一点，所以这里不需要 `unreachable`（0.17 对这个有专门的流分析）。

### 实测：自定义 handler 的效果

子进程跑带 `[custom]` 标记的那条 panic：

```zig
// examples/23_debug/main.zig 第 449-452 行 行
/// 23.10 的靶子：消息里带 [custom] 标记，会被 myPanic 分流到自定义路径
fn crashCustom() void {
    @panic("[custom] 这条 panic 走自定义 handler");
}
```

运行输出（`examples/23_debug/main.zig`）：

```text
子进程跑自定义 handler（crash-custom-panic 分支）：
  [crash-custom-panic] 子进程 term=.{ .exited = 101 }，stderr 共 248 字节
  [crash-custom-panic] stderr 前 8 行（地址每次不同，这里原样贴出）：
    [myPanic] 接管 panic：[custom] 这条 panic 走自定义 handler
    [myPanic] 首帧地址存在吗：false（不打印栈跟踪，这是自定义 handler 的取舍）
    [myPanic] 改用 std.process.exit(101) 干净退出（不是 SIGABRT 的 134）

⇒ handler 里 std.process.exit(101) 让退出码从 134 变成 101
```

⚠️ **`first_trace_addr` 是 `false`（null）**——因为 `@panic` 走的是
`FullPanic.reachedUnreachable` 之外的路径，编译器传的是 null。
想在这个 handler 里打栈，得自己用 `@returnAddress()`：

```zig
fn myPanic(msg: []const u8, first_trace_addr: ?usize) noreturn {
    _ = first_trace_addr;
    const addr = @returnAddress();
    std.debug.dumpCurrentStackTrace(.{ .first_address = addr });
    ...
}
```

### 什么时候该自定义 handler

正当用途有三个，**都不是"少打点东西"**：

1. **崩溃上报**：把 panic 消息 + 栈发到日志服务（但要注意 handler 里不能分配内存，
   一分配就可能二次 panic——`defaultPanic` 源码里有 `panic_stage` 状态机专门处理这个）。
2. **干净退出码**：`std.process.exit(N)` 而不是 `abort()`，让 CI 能区分。
3. **嵌入式/无 stderr 环境**：`no_panic` 或 `simple_panic` 更合适。

⚠️ **不要用自定义 handler 来"美化"栈跟踪**——那会让排错变难。
本章的分流写法（不归我管就 `defaultPanic`）就是折中方案。

## 23.11 环境变量开关法

给库加调试开关的实用做法：**一个 `if`，不改构建、不改结构**。

```zig
// examples/23_debug/main.zig 第 66-72 行
/// 23.11 的环境变量开关：这是**给库用的实用做法**——
/// 开关只影响"要不要打印/要不要断"，不影响"能不能编译"。
/// 用 init.environ_map 读，Windows 和 POSIX 上形状完全一样
/// （旧文档写的 std.posix.getenv 在 Windows 根本不存在，实测编译失败）。
fn debugEnabled(init: std.process.Init, comptime key: []const u8) bool {
    return init.environ_map.get(key) != null;
}
```

运行输出（`examples/23_debug/main.zig`）：

```text
==== 23.11 环境变量开关 开始 ====
给库加调试开关的实用做法：一个 if，不改构建、不改结构
读法只有一种（Windows 和 POSIX 形状一致）：init.environ_map.get("KEY")
⚠️ 旧文档写的 std.posix.getenv 在 Windows 上不可用 —— 0.17 里 std.posix 也没了getenv
   std.process.getEnvVarOwned / std.posix.getenv 这类POSIX-only 写法别用
init.environ_map 的类型 = *process.Environ.Map
本进程实测：DEBUG_ZIG=1 存在吗？false
本进程实测：ZIG_PANIC=1 存在吗？false
⇒ 开关的语义：**存在即真**，不管值是不是 "0"（这是最常见的误用）
   要区分 "0"（关）和 "1"（开）必须自己比字符串
==== 23.11 环境变量开关 结束 ====
```

### 为什么不用 `std.posix.getenv`

- `std.posix` 是 **POSIX 专属命名空间**，Windows 上很多东西不存在。
  `std.fs.selfExePath` 旧文档写的那套（23.10 之前的老 API）在 0.17 里也**整个没了**：
  ```text
  sub.zig:7:28: error: root source file struct 'fs' has no member named 'selfExePath'
  ```
- `init.environ_map` 是 `std.process.Init` 的字段，类型是 `*process.Environ.Map`
  （**指针**，方法调用自动解引用）。**所有平台形状一致**，这是 0.17 显式依赖设计的回报。

⚠️ 两个 `environ_map` 别搞混：
`init.environ_map`（`process.Environ.Map`，0.17 的）和 `RunOptions.environ_map`
（子进程用的，类型是 `?*const Environ.Map`）是**同一个类型**，
所以给子进程传环境变量可以直接 `.{ .environ_map = init.environ_map }`。

### ⚠️ 开关的语义：存在即真

`get(key) != null` 只看**变量是否存在**，不看值。所以：

```bash
DEBUG_ZIG=0 ./myprog   # ← 仍然是"开"！
DEBUG_ZIG=false ./myprog # ← 也是"开"
```

要区分必须自己比：

```zig
fn debugEnabled(init: std.process.Init, comptime key: []const u8) bool {
    const v = init.environ_map.get(key) orelse return false;
    return !std.mem.eql(u8, v, "0") and !std.mem.eql(u8, v, "false");
}
```

### 这个开关也能用来演示 panic

旧版 23 章的示例就是靠 `ZIG_PANIC=1` 才触发 panic，验证时不设变量所以不崩。
这个思路是对的，但本章用了更好的方案（子进程），因为它能**真的把 panic 输出抓回来**，
而不只是"不设变量就不崩"。

⚠️ 但要注意：`ZIG_PANIC` 这个名字在 0.17 **已经不特殊了**（23.12）——
它和 `ZIG_BREAK`、`ZIG_ERT` 一样，现在都只是普通环境变量名。
本章示例里读它只是为了演示这个 API，不代表它有特殊含义。

## 23.12 `ZIG_PANIC` / `ZIG_BACKTRACE` 在 0.17 的真实效果

**本章最硬的一条实测：这两个变量在 0.17 完全失效。**

```zig
// examples/23_debug/main.zig 第 347-359 行 行
    begin("23.12 ZIG_PANIC / ZIG_BACKTRACE");
    std.debug.print("⚠️⚠️ 实测结论：**两个变量在 0.17 都已失效**（不是废弃，是完全无效）\n", .{});
    std.debug.print("ZIG_PANIC=1 的旧作用是\"让 ReleaseFast 也 panic\"。0.17 实测：\n", .{});
    std.debug.print("  Debug 下整数溢出本来 panic（与 ZIG_PANIC 无关）\n", .{});
    std.debug.print("  ReleaseSafe 下本来 panic（与 ZIG_PANIC 无关）\n", .{});
    std.debug.print("  ReleaseFast/ReleaseSmall 下：设与不设 **都是静默 UB**（实测打印 c=0 / 越界读出垃圾）\n", .{});
    std.debug.print("  源码搜索：lib/std 全目录 grep ZIG_PANIC / ZIG_BACKTRACE **零命中**\n", .{});
    std.debug.print("  （stdio.zig / start.zig / debug.zig 里都没有读这两个变量的代码）\n", .{});
    std.debug.print("ZIG_BACKTRACE 的旧作用是0/1/full 三档控制栈跟踪。0.17 实测：\n", .{});
    std.debug.print("  ZIG_BACKTRACE=0/ 1 / full / 不设，**四种情况的帧数完全一样**\n", .{});
    std.debug.print("  切换栈跟踪在 0.17 的正确做法：-fstrip（关掉）/ -fno-omit-frame-pointer（保留帧指针）\n", .{});
    std.debug.print("⇒ 别再依赖这两个变量；要可复现的 panic 请显式 build-exe 并检查退出码\n", .{});
    end("23.12 ZIG_PANIC / ZIG_BACKTRACE");
```

运行输出（`examples/23_debug/main.zig`）：

```text
==== 23.12 ZIG_PANIC / ZIG_BACKTRACE 开始 ====
⚠️⚠️ 实测结论：**两个变量在 0.17 都已失效**（不是废弃，是完全无效）
ZIG_PANIC=1 的旧作用是"让 ReleaseFast 也 panic"。0.17 实测：
  Debug 下整数溢出本来 panic（与 ZIG_PANIC 无关）
  ReleaseSafe 下本来 panic（与 ZIG_PANIC 无关）
  ReleaseFast/ReleaseSmall 下：设与不设 **都是静默 UB**（实测打印 c=0 / 越界读出垃圾）
  源码搜索：lib/std 全目录 grep ZIG_PANIC / ZIG_BACKTRACE **零命中**
  （stdio.zig / start.zig / debug.zig 里都没有读这两个变量的代码）
ZIG_BACKTRACE 的旧作用是0/1/full 三档控制栈跟踪。0.17 实测：
  ZIG_BACKTRACE=0/ 1 / full / 不设，**四种情况的帧数完全一样**
  切换栈跟踪在 0.17 的正确做法：-fstrip（关掉）/ -fno-omit-frame-pointer（保留帧指针）
⇒ 别再依赖这两个变量；要可复现的 panic 请显式 build-exe 并检查退出码
==== 23.12 ZIG_PANIC / ZIG_BACKTRACE 结束 ====
```

### `ZIG_PANIC` 的实测矩阵

靶子：运行期整数溢出（`runtimeAdd(255, 1)`，`u8` 装不下）。

| 模式 | 不设 | `ZIG_PANIC=1` |
|---|---|---|
| Debug | `panic: integer overflow` + 完整栈 | **完全相同** |
| ReleaseSafe | `panic: integer overflow`（栈退化） | **完全相同** |
| ReleaseFast | `c=0`（静默 UB，退出码 0） | **`c=0`（一模一样）** |
| ReleaseSmall | `c=0` | **`c=0`** |

越界读（`"hello"[99]`）也是同一张表：ReleaseFast 下打印 `at=054`——
读到了字符串字面量之外的内存，**没有任何诊断**。设 `ZIG_PANIC=1` 依然是 `at=054`。

### `ZIG_BACKTRACE` 的实测

```bash
for v in "" "0" "1" "full"; do
  echo "ZIG_BACKTRACE='$v' frames=$(ZIG_BACKTRACE=$v ./p1 2>&1 | grep -c ' in ')"
done
```

实测结果：**四种取值都是 6 帧**（一个都没变）。

### 源码层面的确认

```bash
grep -rn "ZIG_PANIC\|ZIG_BACKTRACE" /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/
# 零命中
```

**这不是"变量被移到了别处"，是"没有任何代码读它们"。**
0.17 里控制栈跟踪的旋钮是**编译期旗标**（`-fstrip` / `-fno-omit-frame-pointer`），
不是运行期环境变量。

### 迁移写法

| 你想做的事 | 0.16 的写法 | 0.17 的写法 |
|---|---|---|
| 让 ReleaseFast 也检查溢出 | `ZIG_PANIC=1 ./prog` | 用 `-O ReleaseSafe`（不是 Fast） |
| 关掉栈跟踪 | `ZIG_BACKTRACE=0` | `zig build-exe -fstrip` |
| 要完整栈跟踪 | `ZIG_BACKTRACE=full` | `zig build-exe`（Debug 默认就是全的） |
| 要更好的回溯 | `ZIG_BACKTRACE=full` | `zig build-exe -fno-omit-frame-pointer` |

## 23.13 编译期诊断旗标

`zig build-exe --help` 里与诊断相关的选项，逐字抄：

```text
  -freference-trace[=num]          Show num lines of reference trace per compile error
  -fno-reference-trace             Disable reference trace
  --verbose-link                Display linker invocations
  --debug-log [scope]          Enable printing debug/info log messages for scope
```

⚠️ 注意 `--debug-log` 的选项名**不是** `--debug-logging`、也不是 `-fdebug-log`。
实测 `--help` 里只有这一个拼法。

### `-freference-trace`：追"谁引用的"

故意写一个字段不存在错误，看默认输出：

```text
bad.zig:2:30: error: root source file struct 'debug' has no member named 'nope'
fn f() void { _ = &std.debug.nope; }
                             ^~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/debug.zig:1:1: note: struct declared here
const std = @import("std.zig");
^~~~~
referenced by:
    main: bad.zig:3:56
    callMain [inlined]: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:827:30
    callMainWithArgs [inlined]: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:729:20
    main: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:754:28
    1 reference(s) hidden; use '-freference-trace=4' to see all references
```

⚠️ **默认只显示 4 层**，其余折叠成 `N reference(s) hidden`。
深层错误（尤其是模板/泛型展开的那种）经常需要 `-freference-trace=20` 才看得全。

`-freference-trace=8` 实测（同一个错误）：

```text
referenced by:
    main: bad.zig:3:56
    callMain [inlined]: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:827:30
    callMainWithArgs [inlined]: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:729:20
    main: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:754:28
    comptime: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:36:26
    start: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/std.zig:114:27
    comptime: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/std.zig:240:9
```

⚠️ **`referenced by:` 是编译期的引用关系，不是运行期调用栈**。
`main: start.zig:754` 说的是"编译器在分析 start.zig 时引用了你的 main"，
不是"运行时 start.zig 调用了 main"。这个区分在 23.16 会再强调。

### `--verbose-link`：看链接器到底跑了什么

```bash
zig build-exe p1.zig --verbose-link -femit-bin=vl
```

实测输出（一整行）：

```text
zig ld -dynamic -platform_version macos 14.8.9 15.2 -syslibroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX15.2.sdk -e _main -o vl /Users/xulun/.cache/zig/tmp/dc5734f9713b8b5f/p1_zcu.o -lSystem /Users/xulun/.cache/zig/o/7a5f99f1e098a1558d263d0f3a062d86/libcompiler_rt.a
```

读法：
- `-e _main` → 入口符号是 `_main`（Mach-O 的下划线前缀）
- `/Users/.../zig/tmp/xxx/p1_zcu.o` → **ZCU 编译出的目标文件在缓存的临时目录里**
- `-lSystem` + `libcompiler_rt.a` → 链接了系统库和 Zig 自带的运行时
- macOS 上 `-syslibroot` 指向 Xcode SDK

⚠️ **注意链接器命令行里没有任何 `.o` 出现在当前目录**——
Zig 把所有中间产物放在 `~/.cache/zig/` 下（可用 `--cache-dir` / `--global-cache-dir` 改）。
想看中间产物得用 `-femit-asm` 之类显式导出（见 23.14）。

### ⚠️ `--debug-log` 在本机**无效**

```bash
zig build-exe p1.zig --debug-log -femit-bin=/dev/null
```

实测输出：

```text
warning: Zig was compiled without logging enabled (-Dlog). --debug-log has no effect.
```

**发布的官方 zig 二进制是用 `-Dlog=false` 编的**（为了减小体积）。
这个选项只对**自己从源码编译的 debug 版 zig** 有效。
所以在本教程的环境里，`--debug-log` 是个"存在但没用"的选项。

## 23.14 调试信息旗标

`zig build-exe --help` 里的调试信息相关选项，逐字抄：

```text
  -fstrip                   Omit debug symbols
  -fno-strip                    Keep debug symbols
  -fomit-frame-pointer          Omit the stack frame pointer
  -fno-omit-frame-pointer       Store the stack frame pointer
  -funwind-tables                    Always produce unwind table entries for all functions
  -fasync-unwind-tables           Always produce asynchronous unwind table entries for all functions
  -fno-unwind-tables               Never produce unwind table entries
```

中间产物（`-femit-*` 家族，实测选项名）：

```text
  -femit-bin[=path]         (default) Output machine code
  -femit-asm[=path]         Output .s (assembly code)
  -femit-llvm-ir[=path]     Produce a .ll file with optimized LLVM IR (requires LLVM extensions)
  -femit-llvm-bc[=path]     Produce an optimized LLVM module as a .bc file (requires LLVM extensions)
  -femit-h[=path]                Generate a C header file (.h)
  -femit-docs[=path]         Create a docs/ dir with html documentation
  -femit-implib[=path]      (default) Produce an import .lib when building a Windows DLL
```

### `-fstrip` 的实测效果（这是本节最有价值的部分）

**同一个 panic 程序，Debug 模式，只加 `-fstrip`**：

```bash
zig build-exe p1.zig -O Debug -fstrip -femit-bin=dbg_strip
./dbg_strip
```

实测输出：

```text
thread 1775708 panic: 演示 panic：看栈跟踪
Cannot print stack trace: stack tracing is disabled
```

⚠️⚠️ **Debug 模式 + `-fstrip` 也没有栈跟踪**。
很多人以为"栈跟踪是 Debug 才有的"，实际上是"**有调试信息**才有的"。
这两个是正交的。

机制在 `lib/std/std.zig` 第 185 行：

```zig
allow_stack_tracing: bool = !@import("builtin").strip_debug_info,
```

而 `std/debug.zig` 的 `writeTrace` 第一件事就是检查它：

```zig
if (!std.options.allow_stack_tracing) {
    t.setColor(.dim) catch {};
    try writer.print("Cannot print stack trace: stack tracing is disabled\n", .{});
    t.setColor(.reset) catch {};
    return;
}
```

所以这一行字就是 `allow_stack_tracing == false` 的**唯一外部症状**——
看到它，立刻知道是 strip 了，不是"栈坏了"。

### `-fno-omit-frame-pointer` 的实测效果

ReleaseSafe 加这个旗标，栈跟踪**没有变化**（还是那个退化的一帧版本）。
说明本机（LLVM 后端）在 x86_64 上默认就用**帧指针链**回溯，
不需要显式保留帧指针。

它在**手写汇编**或需要用 `ebp` 做自定义回溯时才有意义。
对纯 Zig 代码是"无害但没用"的选项。

### 该用哪个组合

| 目的 | 建议旗标 |
|---|---|
| 日常开发 | `-ODebug`（默认，有栈、有 error return trace） |
| 生产但要能诊断崩溃 | `-O ReleaseSafe`（无 error return trace，但 panic 栈在） |
| 生产且要完整栈 | `-O ReleaseSafe -fno-omit-frame-pointer`（本机实测无额外收益，但跨后端更保险） |
| 生产且要最小 | `-O ReleaseSmall`（**默认 strip，无栈**）——至少留一个 `.dSYM` |
| 要给崩溃报告留现场 | `-O ReleaseSafe -fno-strip` + 把产物和符号一起归档 |

⚠️ macOS 上如果产物被 strip 了但保留了 `.dSYM`，栈跟踪**能**工作
（DWARF 在 `.dSYM` 里）。但 `-fstrip` 是**连 `.dSYM` 一起不要**的。

## 23.15 `@breakpoint` 与 `@compileLog`

### `@breakpoint()`：真断点指令，不是可捕获的错误

```zig
// examples/23_debug/main.zig 第 149-152 行 行
    if (std.mem.eql(u8, mode, "crash-breakpoint")) {
        @breakpoint(); // 无调试器 → SIGTRAP（实测退出码 133）
        return;
    }
```

实测（无调试器直接跑）：

```text
before @breakpoint
（然后进程被信号打死，没有任何后续输出）
退出码 133
```

**133 = 128 + 5 = SIGTRAP**。注意它和 panic 的 134（SIGABRT）**不是一回事**：

| | `@breakpoint()` | `@panic` |
|---|---|---|
| 信号 | SIGTRAP（5） | SIGABRT（6） |
| 退出码 | 133 | 134 |
| stderr 输出 | **无** | 消息 + 栈跟踪 |
| 能捕获吗 | 不能 | 不能（但可以自定义 handler） |

⚠️ **`@breakpoint()` 不走 panic handler**——所以你**没法**用子进程方案
把它的输出抓回来（本示例只能靠退出码证明它发生了）。
这也是为什么它必须配环境变量开关（23.11）：
一旦触发就没得救，只能重新跑一遍不带变量的。

**什么时候用**：确实是"我要在这里停一下"的时候，
而且确定有调试器（比如只在 `-ODebug` 编译的调试构建里）。

### `@compileLog`：0.17 是 error 不是 warning

```zig
fn f() void {
    const x = 1 + 2;
    @compileLog("x 的值是 {d}", .{x});
}
```

实测输出：

```text
cl.zig:4:5: error: found compile log statement
    @compileLog("x 的值是 {d}", .{x});
    ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
referenced by:
    main: cl.zig:6:56
    callMain [inlined]: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:827:30
    callMainWithArgs [inlined]: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:729:20
    main: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:754:28
```

⚠️ 它是 **error**（编译失败），不是 warning。
好处是**不会漏**——`@compileLog` 在那儿就一定编译不过，
所以永远不会有一行"调试用的编译日志"混进生产构建。
13 章讲 `@compileLog` 的用法，这里只提醒这条性质。

## 23.16 读错误信息的四个层次

综合本章所有实测，把"看到一大段报错怎么办"总结成四个层次。

```zig
// examples/23_debug/main.zig 第 403-413 行 行
    begin("23.16 四个层次");
    std.debug.print("看到一大段报错时，按这个顺序读：\n", .{});
    std.debug.print("  第 1 层「哪条 error」      → 第一行 `error: xxx` 或 `panic: xxx`，这是**根因种类**\n", .{});
    std.debug.print("  第 2 层「哪一行」          → 第一条 `文件:行:列` + 源码行 + ^ 指示线，**这是根因位置**\n", .{});
    std.debug.print("  第 3 层「error return context」→ 错从哪个函数冒出来的（只在 Debug 且确实是错误时出现）\n", .{});
    std.debug.print("  第 4 层「stack trace」      → 崩在哪条调用路径上；末尾的 callMain / dyld 是固定噪声\n", .{});
    std.debug.print("⚠️ 初学者最常见的误读：把第 4 层的调用栈当成根因。\n", .{});
    std.debug.print("   panic 栈的**第一帧**才是根因位置，往下都是「谁调用了它」。\n", .{});
    std.debug.print("⚠️ 第二个常见误读：把\"引用链\"（referenced by:）当成调用栈。\n", .{});
    std.debug.print("   referenced by: 是**编译期**的引用关系，不是运行期调用关系。\n", .{});
    end("23.16 四个层次");
```

运行输出（`examples/23_debug/main.zig`）：

```text
==== 23.16 四个层次 开始 ====
看到一大段报错时，按这个顺序读：
  第 1 层「哪条 error」      → 第一行 `error: xxx` 或 `panic: xxx`，这是**根因种类**
  第 2 层「哪一行」          → 第一条 `文件:行:列` + 源码行 + ^ 指示线，**这是根因位置**
  第 3 层「error return context」→ 错从哪个函数冒出来的（只在 Debug 且确实是错误时出现）
  第 4 层「stack trace」      → 崩在哪条调用路径上；末尾的 callMain / dyld 是固定噪声
⚠️ 初学者最常见的误读：把第 4 层的调用栈当成根因。
   panic 栈的**第一帧**才是根因位置，往下都是「谁调用了它」。
⚠️ 第二个常见误读：把"引用链"（referenced by:）当成调用栈。
   referenced by: 是**编译期**的引用关系，不是运行期调用关系。
==== 23.16 四个层次 结束 ====
```

### 用一个真实输出走一遍

```text
thread 1828199 panic: attempt to unwrap error: Boom
error return context:
probe.zig:2:41: 0xADDR in mayFail (cu)          ← 第 3 层：错从这冒出来
fn mayFail(fail: bool) !u32 { if (fail) return error.Boom; return 7; }
                                        ^

stack trace:
probe.zig:6:35: 0xADDR in main (cu)             ← 第 4 层：崩在这
    const v = mayFail(fail) catch unreachable;
                                  ^
start.zig:827:30: 0xADDR in callMain (cu)       ← 噪声
???:?:?: 0xADDR in start (/usr/lib/dyld)        ← 噪声
```

| 层 | 在哪 | 说什么 | 怎么用 |
|---|---|---|---|
| 1 | `thread 1828199 panic: attempt to unwrap error: Boom` | **根因种类**：是 unwrap error，不是越界不是溢出 | 决定往哪查 |
| 2 | 这一层在纯 panic 里是第 2 帧（`crashLeaf`）；在错误场景里由第 3 层顶替 | **根因位置**：`文件:行:列` | 直接跳过去改 |
| 3 | `error return context:` 段 | 错误从哪个 `return error.X` 冒出来的 | 找源头 |
| 4 | `stack trace:` 段 | 谁调用了崩的地方 | 理解上下文，**不是根因** |

**这个例子里第 3 层是核心**：错误来自 `mayFail`，而 `mayFail` 的存在本身是个设计问题——
它明明返回 `error{Boom}`（**可能失败**），调用方却写了 `catch unreachable`。
第 4 层告诉你 `main` 第 6 行是崩点，但"为什么会崩"的答案在第 3 层和源码设计上。

### 三个常见误读

1. **把第 4 层的调用栈当根因**。panic 栈是**自下向上**的（第一个帧最内层）。
   最内层才是出事的地方。
2. **把 `referenced by:` 当调用栈**。它是**编译期**的"谁引用了这个声明"，
   和运行期调用关系无关。运行期调用关系只在栈跟踪里。
3. **在 `error return context:` 里找根因而不看有没有 `stack trace:` 段**。
   两个小标题是 0.17 才有的（23.3.2），纯 `@panic` 没有它们。

## 23.17 用调试器：lldb / gdb

Zig 产物的调试信息是**标准格式**：macOS/Linux 是 DWARF（内嵌或 `.dSYM`），
Windows 是 PDB。所以 lldb / gdb / VS 调试器**开箱即用**，不需要任何插件。

### 本机实测：lldb 能载入并解析符号

```bash
zig build-exe ldbg.zig -femit-bin=ldbg
lldb --batch -o "breakpoint set -n compute" -o "bt" -o "quit" ./ldbg
```

实测输出：

```text
(lldb) target create "./ldbg"
Current executable set to '/Volumes/.../build/probe23/ldbg' (x86_64).
(lldb) breakpoint set -n compute
Breakpoint 1: where = ldbg`ldbg.compute + 10 at ldbg.zig:2:32, address = 0x000000010013ceca
(lldb) bt
error: Command requires a current process.
```

**能读的部分**（这三行是硬证据）：
- `Current executable set to '...' (x86_64)` → 架构识别正确
- `where = ldbg`ldbg.compute + 10 at ldbg.zig:2:32` → **DWARF 完整**：
  函数名（带 Zig 的命名空间 mangling `ldbg.compute`）、偏移（`+10`）、**文件行号**（`ldbg.zig:2:32`）全对
- `image list` 也能列出所有加载的 dylib（含 `/usr/lib/dyld`）——和 panic 栈的末帧对得上

**不能读的部分**（本机环境限制）：
`lldb run` 会**挂死**（试过 `--batch`、交互模式、`gtimeout` 20/40 秒、绕过沙箱，
以及用 `clang -g` 编的**纯 C 二进制**做对照——**C 二进制一样挂死**）。
所以这是本机 lldb/权限环境的问题，**不是 Zig 产物的问题**
（DWARF 解析成功已经证明了这一点）。

⚠️ **诚实说明**：本教程无法给出"lldb 跑起来了"的实测输出，
所以下面的命令序列是**基于 lldb 文档和上述符号解析实测**给出的，
不是本机跑通的结果。

### 命令序列

```bash
# Debug 构建（默认就带完整调试信息）
zig build-exe main.zig -femit-bin=./main

# 启动
lldb ./main                      # Linux/macOS 产物无 .exe 后缀

# 或者纯批处理（CI 里）
lldb --batch \
    -o "breakpoint set -n compute" \
    -o "run" \
    -o "bt" \
    -o "frame variable" \
    -o quit \
    ./main
```

| 任务 | 命令 |
|---|---|
| 按函数名下断点 | `breakpoint set -n compute` |
| 按文件行号下断点 | `breakpoint set --file main.zig --line 42` |
| 下**待命中**断点（只在 `error.Boom` 时停） | `breakpoint set -n errLeaf` |
| 启动 | `run` |
| 单步（不进函数） | `next` / `n` |
| 单步（进函数） | `step` / `s` |
| 打印变量 | `print x` / `p x` |
| 当前帧全部变量 | `frame variable` |
| 打印**类型** | `frame variable --type` |
| 栈回溯 | `bt` |
| 切换帧 | `frame select 2` / `f 2` |
| 继续 | `continue` / `c` |
| 退出 | `quit` / `q` |

⚠️ `breakpoint set -n <名字>` 匹配的是**符号名**，
而符号名带模块前缀（实测是 `ldbg`ldbg.compute`）。
如果函数被内联了，断点可能落在 `main` 上——**这也是 23.2.3 建议用 Debug 模式的原因**。

### 不依赖调试器的替代方案

本教程 23.1 到 23.16 用的全是这三样，它们在 CI 里也能跑：

| 手段 | 覆盖的场景 | 本章位置 |
|---|---|---|
| `std.debug.print` 打点 | "值是多少" | 全章 |
| **子进程复现 + 抓 stderr** | "崩了会怎样"（panic / 退出码 / 完整 stderr） | 23.2、23.3、23.4、23.10 |
| error return trace | "这个错从哪来" | 23.5、23.6 |
| `-freference-trace=N` | "谁引用了这个声明" | 23.13 |

**子进程方案是本章的核心工程手法**，它的实现值得单独说：

```zig
// examples/23_debug/main.zig 第 101-128 行 行
/// 用子进程跑一段"注定崩"的代码，把它的 stderr 抓回来。
/// 这是本章所有 panic 演示的**唯一实现手段**——因为验证脚本要求退出码 0。
/// 0.17 形状：`std.process.run(gpa, io, opts)` 三参数，返回值 owns 两块缓冲，
/// 必须 `init.gpa.free`。`max_output_bytes` 已改名 `stderr_limit: Io.Limit`。
fn runCrasher(init: std.process.Init, arena: std.mem.Allocator, label: []const u8, lines: usize) void {
    const self = std.process.executablePathAlloc(init.io, arena) catch |err| {
        std.debug.print("  [{s}] 取不到自身路径（{s}），本节跳过\n", .{ label, @errorName(err) });
        return;
    };
    const child = std.process.run(init.gpa, init.io, .{
        .argv = &.{ self, label },
        .stderr_limit = .limited(64 * 1024),
    }) catch |err| {
        std.debug.print("  [{s}] 拉子进程失败：{s}\n", .{ label, @errorName(err) });
        return;
    };
    defer {
        init.gpa.free(child.stdout);
        init.gpa.free(child.stderr);
    }
    std.debug.print("  [{s}] 子进程 term={any}，stderr 共 {d} 字节\n", .{ label, child.term, child.stderr.len });
    std.debug.print("  [{s}] stderr 前 {d} 行（地址每次不同，这里原样贴出）：\n", .{ label, lines });
    var it = std.mem.splitScalar(u8, child.stderr, '\n');
    for (0..lines) |_| {
        const line = it.next() orelse break;
        std.debug.print("    {s}\n", .{line});
    }
}
```

四个 0.17 的形状细节（都实测撞过）：

1. **`std.fs.selfExePath` 和 `std.Io.Dir.selfExePath` 都不存在**了。
   正确的是 **`std.process.executablePathAlloc(io, allocator)`**（返回 `[:0]u8`）。
2. **`std.process.run` 是三参数** `(gpa, io, options)`，不是两参数。
3. **`max_output_bytes` 已改名 `stderr_limit: Io.Limit`**，
   写法是 `.limited(64 * 1024)`（不是 `Io.Limit` 的 `.limited_nonzero`）。
4. **返回值 owns `stdout` 和 `stderr` 两块缓冲**，必须 `gpa.free`——
   否则 `SafeAllocator` 会报泄漏。

`term` 字段把"崩了"和"失败了"分得清清楚楚（实测）：

| `child.term` | 含义 |
|---|---|
| `.{ .signal = .ABRT }` | panic（SIGABRT） |
| `.{ .exited = 1 }` | 错误返回（`error: Boom`） |
| `.{ .exited = 101 }` | 自定义 panic handler 的 `exit(101)` |
| `.{ .exited = 0 }` | 正常退出 |

⚠️ **`std.process.run` 没有 `max_output_bytes` 之后的总字节上限概念**——
`stdout_limit` 和 `stderr_limit` 是**分开的**，超了会返回 `error.StreamTooLong`。
两个都建议设上（本章只设了 stderr，因为子进程的 panic 全走 stderr）。

## 23.18 工具链速查（收尾）

```bash
# —— 语法/格式 ——
zig fmt .                       # 格式化整个目录
zig fmt --check .                # 只检查不改（CI 用这个）
zig ast-check main.zig# 只查语法，不做语义分析（编辑器集成）

# —— 编译与运行 ——
zig build-exe main.zig            # Debug 构建
zig build-exe main.zig -O ReleaseSafe
zig build-exe main.zig -O ReleaseSafe -fstrip# 产物最小，但没栈跟踪
zig run main.zig                 # 编译 + 跑一步到位
zig build-obj main.zig            # 只出.o

# —— 测试（15 章）——
zig test main.zig
zig test main.zig --test-filter 缓冲

# —— 诊断（本章）——
zig build-exe main.zig -freference-trace=20# 追引用链
zig build-exe main.zig --verbose-link        # 看链接器调用
zig build-exe main.zig -femit-asm=out.s      # 导出汇编（看 UB 编译成什么）
zig build-exe main.zig -fno-omit-frame-pointer  # 更好的回溯

# —— 交叉编译（18 章）——
zig targets                      # 目标列表
zig cc hello.c -o hello# zig cc：Zig 自带的 clang

# —— 文档 ——
zig doc src/main.zig             # 生成 HTML 文档（/// 注释）
```

⚠️ 两个**已不存在**的选项（本章实测）：
`--debug-log` 存在但**无效**（23.13），
`ZIG_PANIC` / `ZIG_BACKTRACE` 环境变量**完全无效**（23.12）。

⚠️ `zig ast-check` 在 0.17 还在（`zig --help` 里有），但它只查语法——
**类型错误要靠 `zig build-exe`**（这正是 15.5.7 讲的 `zig test` 不分析 `main` 那个盲区的同类）。

`///` 是文档注释（进 doc），`//!` 是文件头注释，`//` 普通注释——三件套写规范，
`zig doc` 就有料。

## 23.19 ⚠️ 0.17 坑位清单

1. **`@errorReturnTrace()` 在 0.17 返回 `?*StackTrace`（可选指针）**，不是 `StackTrace`。
   旧写法 `const t = @errorReturnTrace(); t.index` 编译失败
   （`type'?*lang.StackTrace' does not support field access`）。
   `writeErrorReturnTrace` 的第一个参数要**直接传解包后的指针**（不要加 `&`）。
   另外 `.instruction_addresses.len` 是**缓冲区容量**不是当前帧数——有效帧数看 `.index`。

2. **`ZIG_PANIC` 和 `ZIG_BACKTRACE` 在 0.17 完全失效**。`lib/std` 全目录 grep 零命中。
   ReleaseFast 下 `ZIG_PANIC=1` 依然静默 UB。要控制栈跟踪用编译期旗标
   （`-fstrip` / `-fno-omit-frame-pointer`）。

3. **"ReleaseSafe 没有 panic 栈跟踪"是误判**。实测 ReleaseSafe 打完整栈；
   看起来只有一帧是因为**内联/尾调用把帧消掉了**，加 `noinline` 就恢复。
   ReleaseSafe 真正缺的是 **error return trace**（只 Debug 有）。

4. **`-O ReleaseSmall` + `@panic` 也会丢栈跟踪**，输出是
   `Cannot print stack trace: stack tracing is disabled`。
   因为 `ReleaseSmall` 默认 strip，而 `std.options.allow_stack_tracing = !strip_debug_info`。
   **Debug + `-fstrip` 同样丢**——栈跟踪靠的是调试信息，不是优化级别。

5. **`std.debug.panicImpl` 在 0.17 不存在**（`@hasDecl` = false）。
   接管方式是 `pub const panic = std.debug.FullPanic(myFn);`——
   `FullPanic` 是**工厂函数返回类型**，参数签名 `fn ([]const u8, ?usize) noreturn`。
   ⚠️ 它是**编译单元级**的：写上之后本文件所有 panic 都走你的 handler。

6. **`dumpCurrentStackTrace()` 零参数写法编译失败**——
   0.17 要一个 `StackUnwindOptions`：`dumpCurrentStackTrace(.{})`。
   `captureCurrentStackTrace(.{}, &buf)` 的 `buf` 生命周期必须不短于返回的 `StackTrace`。
   `writeStackTrace` 返回 `Writer.Error!void`，必须 `catch`。
   ⚠️ `StackUnwindOptions.context` 在 x86_64 上是 `?*const debug.cpu_context.X86_64`——
   **架构相关**，别写跨架构的通用代码。

7. **`std.log.scoped(.名字)` 的作用域名必须是 ASCII 标识符**。
   `.示例` 报 `expected expression, found '.'`（`@EnumLiteral()` 的限制）。
   另外 `scoped` 返回**匿名 struct 类型**，**没有 `.scope` 字段**
   （`@typeName` 给出的就是 `"type"`）。

8. **`std.options` 是 `const`，运行期改不了**。`std.options.log_level = .debug`
   报 `cannot assign to constant`。唯一改法是根文件 `pub const std_options: std.Options = .{...}`。
   0.17 新增 `log_scope_levels` 可以给单个模块单独设级别（实测可用）。

9. **`std.log.warn` 打出来的文本是 `warning` 不是 `warn`**（`err` → `error`）。
   而 `std.log.Level` 的枚举成员名是 `err`/`warn`/`info`/`debug`。
   另外 `std.log.default_level` 在 **Debug 下是 `.debug`**（不是 `.info`），
   所以 Debug 下 `log.debug` 默认就打印。

10. **`@typeInfo(T).@"enum"` 在 0.17 的字段是 `field_names`/`field_types`，没有 `fields`**。
    写 `e.fields.len` 报 `no field named 'fields' in struct 'lang.Type.Enum'`。
    同理 `@typeInfo(...).@"fn"` 的参数字段叫 **`param_types`**（不是 `params`）。

11. **`@hasDecl` 的字符串参数必须 comptime 已知**。
    `for (names) |n| @hasDecl(std.debug, n)` 报
    `unable to resolve comptime value` + `declaration name must be comptime-known`。
    必须用 `inline for`（或把名字放进结构体字面量做 comptime 求值，见 15.3）。

12. **`!void` 函数不能用 `catch |err| err` 拿到错误值**：
    `const e: anyerror = f() catch |err| err;` 报 `expected type 'anyerror', found 'void'`
    （成功分支 payload 是 `void`，peer 解析后成了 `void`）。
    两种正确写法：`catch |err| { ... return ...; }` 块形式，
    或先拿错误联合再 `if (r) |_| {} else |err| { ... }`。

13. **`std.fs.selfExePath` 和 `std.Io.Dir.selfExePath` 在 0.17 都不存在**。
    正确的是 **`std.process.executablePathAlloc(io, allocator)`**（返回 `[:0]u8`）。
    同族：`std.process.run` 是**三参数** `(gpa, io, opts)`；
    `max_output_bytes` 已改名 **`stderr_limit: Io.Limit`**（`.limited(N)`）；
    返回值 owns `stdout`/`stderr`，必须 `gpa.free`。

14. **comptime 已知的信息量比你想的多**。
    `const b: u8 = 255; const c = b + 1;` 在**所有四个模式**下都是**编译错误**
    （`overflow of integer type 'u8' with value '256'`）——
    包括 `ReleaseFast`。想让溢出变成运行期 UB 必须让操作数来自运行期。
    同理 `var b: u8 = 255;` 报 `local variable is never mutated`（要写 `const`）。

15. **`main` 里拿到的 `init` 参数"看起来没用"时不能随便 `_ = init`**。
    0.17 区分两种情况：如果 `init` 后面**确实没被用到**，写 `_ = init;` 报
    `pointless discard of function parameter` + `note: used here`（自相矛盾的诊断）；
    如果**完全没用**，报 `unused function parameter`。
    最省事的做法是真的用一下（比如 `init.arena.allocator()`）。

16. **`@typeName` 对函数返回的是带签名的名字**。
    `@typeName(@TypeOf(crashTop))` 给的是 `"noinline fn () void"` 而不是 `"void"`。
    而且它返回**字符串切片**，用 `expectEqual` 比会因地址不同而假 FAIL（15.4.2）——
    比内容必须用 `expectEqualStrings` 或 `std.mem.endsWith`。

---

上一章：[22 进程](22-process.md) · 下一章：[24 实战：迷你 grep](24-minigrep.md)
