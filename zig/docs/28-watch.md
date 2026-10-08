# 28 · 文件监视

> 对应示例：`examples/28_watch/main.zig`（1193 行，11 个测试）
>
> 轮询快照求差（跨平台核）、只 stat 已知文件的折中方案、优雅退出的两种语义、
> Windows 原生 `ReadDirectoryChangesW` 的 extern 直调——文件监视的三条路，
> 外加一个 0.17 的实测结论：**`std.Io` 没有任何文件系统事件接口**。
> 取材 Systems Programming with Zig ch5（zwatch：inotify/kqueue 分叉）与
> Rios《Learning Zig》ch13（FileGuard 的监视设计）。
>
> 本章有四个结论会**推翻你可能听过的说法**，全部是 0.17.0 上实测的：
>
> 1. **`std.Io.Dir` 上没有 `watch`**（也没有 `Io.File.Event`）。文件监视在 0.17
>    **完全没有标准库支持**——不是"藏在别处"，是压根没做。书上的 zwatch 只能自己
>    按 OS 分叉 inotify/kqueue/FSEvents/ReadDirectoryChangesW。
> 2. **`Clock` 枚举没有 `.monotonic`**。0.17 的五个成员是
>    `real / awake / boot / cpu_process / cpu_thread`。你想要"单调时钟"就写 `.awake`
>    （macOS 上是 `CLOCK_UPTIME_RAW`，Linux 上是 `CLOCK_MONOTONIC`）。
> 3. **`std.Io` 的 `Event` 不是文件系统事件**，它是个三态原子布尔量
>    （`unset / waiting / is_set`），用于任务/线程间的手动同步。
>    而且 0.17 有一个真实的不一致点：**`set(io)` 要 io，`reset()` 不要**。
> 4. **`std.HashMap.put` 不复制键**。实测把字符串字面量直接 `put` 进去、
>    然后 `free` 它 → `Bus error at address 0x...`。想自己拥有键，
>    **必须先 dupe 再 put**。这是本章 28.2 求差核最大的一个内存地雷。
>
> 另外本章有一条**方法论**值得单独拎出来：轮询逻辑的正确性测试**一个 sleep 都不需要**。
> 手法是把"扫描"和"求差"拆开，让求差变成纯函数，然后手工构造两份快照直接对拍
> （28.2）。这比"起个线程、sleep 200ms、等文件出现"又快又稳——后者在 CI 上
> 永远是 flaky 的来源。
>
> **节号对应**：28.1–28.7 是示例 `main` 里的运行时小节
> （`begin("28.N…") … end("28.N")`，运行输出里能看到 `==== 28.N … ====`）；
> **28.8（测试）与 28.9（坑位清单）对应示例末尾的源码分节**
> （`// 28.8 测试：…` 与 `// 28.9 坑位清单的代码依据：…`）——
> 它们不在 `main` 里，所以没有对应的运行输出。

---

## 28.1 std.Io 的文件事件接口：实测不存在

先说结论，免得后面找不存在的东西。两个探针在 0.17.0 上的真实报错：

```text
root source file struct 'Io.Dir' has no member named 'watch'
root source file struct 'Io.File' has no member named 'Event'
```

对应的探针源码就是两行 `_ = std.Io.Dir.watch;` 和 `_ = std.Io.File.Event;`。
`Io.zig` 顶部的注释列了它抽象的全部能力——"file system / networking / processes /
time and sleeping / randomness / async, await, concurrent, and cancel / concurrent
queues / wait groups and select / mutexes, futexes, events, conditions / memory mapped
files"——**没有一项是文件事件**。这里说的 "events" 是 `Io.Event`（28.5 讲的那个
三态布尔量），不是文件系统事件。

为什么没做？**不是写不出来，是写出来要付四份抽象的代价**：

| 平台 | API | 监视粒度 | 事件模型 | 怎么取消 |
|---|---|---|---|---|
| Linux | `inotify_init1` + `inotify_add_watch` | 内核队列（默认 8192 项上限，在 `/proc/sys/fs/inotify/max_user_watches`） | 边沿触发，`read()` 出变长记录 | `inotify_rm_watch` / 关 fd |
| BSD / macOS | `kqueue` 的 `EVFILT_VNODE` | **每个被监视文件占一个 fd** | 电平触发（`NOTE_WRITE` 等） | `close(fd)` |
| macOS | `FSEvents` / `FSEventStreamCreate` | 目录树，延迟合并 | 回调 + `CFRunLoop` | `FSEventStreamStop` |
| Windows | `ReadDirectoryChangesW` | 单目录或子树 | `OVERLAPPED` + UTF-16 变长记录链 | `CancelIo` |

要在 `std.Io` 上统一它们，得先回答四个问题，每一个的答案在不同平台上都不一样：

1. **事件模型怎么统一**。inotify 是边沿触发（"我告诉你发生过一次"），kqueue 是电平触发
   （"现在这个文件是可写状态"）。前者会丢中间态，后者要自己去抖。Zig 的 `Io` 里
   `Operation` 是为**一问一答**设计的语义，不是为"持续推送"设计的。
2. **取消怎么统一**。`Io` 的取消模型是 `error.Canceled` 从取消点冒出来。
   inotify 可以用 `poll` + 一对自管道做取消点；kqueue 得靠关 fd（那不是取消，是销毁）；
   FSEvents 得在别的线程调 `FSEventStreamStop`；RDCW 得 `CancelIo`。
   这四者没法映射到同一个 `Io` 原语上。
3. **句柄语义怎么统一**。`Io` 的 `Dir`/`File` 是一次性 RAII 资源，
   而监视句柄是**长期存在且需要能被取消的**——这是两种不同的生命周期。
4. **可移植性测试怎么做**。这才是最要命的：inotify 在 Linux CI 上能测，
   RDCW 在 Windows CI 上能测，**同一个测试跨不过两者**。Zig 的 CI 不可能同时跑四个平台
   的事件语义（尤其 FSEvents 需要 CFRunLoop，Windows 需要真实文件系统）。

所以 Zig 的选择是**先不做**，把"零抽象代价"的轮询方案留给用户自己搭。这不是偷懒——
**轮询在很多场景下就是够的**：一个目录几百个文件、200ms 一轮，代价是每秒 5 次
`getdents`，谁也感受不到。

于是本章给出**三条路**，并说清各自的边界：

| 路 | 代价 | 能发现新文件 | 跨平台 | 本机可测 |
|---|---|---|---|---|
| ① 轮询快照求差（28.2 / 28.3） | O(目录项数) 每轮 | ✅ | ✅ | ✅ |
| ② OS 原生事件（28.7 + 各平台原理） | 最低 | ✅ | ❌ 四套 | ❌ |
| ③ 只 stat 已知文件（28.4） | O(关注文件数) 每轮 | ❌ | ✅ | ✅ |

**本章实现 ① 和 ③，② 只做 Windows 的示范**——因为 RDCW 的 `extern` 声明可以靠
`zig build-exe -target x86_64-windows` 静态验证，而 inotify/kqueue 的代码量大、
本机完全跑不了，写出来只是"看起来像那么回事"。与其贴一堆不可验证的代码，
不如把四个平台的**原理和坑**讲清楚，让你在真需要时知道该查哪个手册。

顺便把 0.17 的时间接口实测签名钉在这里（后面几节都要用）：

```zig
// examples/28_watch/main.zig 第 662-679 行
    // ── 28.1 std.Io 有没有文件事件接口？没有
    begin("28.1 std.Io 的文件事件接口：实测不存在");
    err.print("Clock 枚举成员：", .{});
    inline for (.{
        std.Io.Clock.real,
        std.Io.Clock.awake,
        std.Io.Clock.boot,
        std.Io.Clock.cpu_process,
        std.Io.Clock.cpu_thread,
    }) |c| err.print(" {s}", .{@tagName(c)});
    err.print("\n  → 没有 .monotonic（0.17 已改名 .awake / .boot）\n", .{});
    err.print("Io.sleep 的 duration 参数是 Io.Duration（i96 纳秒），", .{});
    err.print("只能 fromMilliseconds 这类函数构造——没有 {{f}} 字段简写\n", .{});
    // 三条路的取舍（详见文档 28.1）
    err.print("三条路：① 轮询快照求差（本机可测，跨平台）", .{});
    err.print(" ② OS 原生事件（四个平台四套 API，std 未封）", .{});
    err.print(" ③ 折中：只 stat 已知文件\n", .{});
    end("28.1 std.Io 的文件事件接口：实测不存在");
```

运行输出（`examples/28_watch/main.zig`）

```text
==== 28.1 std.Io 的文件事件接口：实测不存在 开始 ====
Clock 枚举成员： real awake boot cpu_process cpu_thread
  → 没有 .monotonic（0.17 已改名 .awake / .boot）
Io.sleep 的 duration 参数是 Io.Duration（i96 纳秒），只能 fromMilliseconds 这类函数构造——没有 {f} 字段简写
三条路：① 轮询快照求差（本机可测，跨平台） ② OS 原生事件（四个平台四套 API，std 未封） ③ 折中：只 stat 已知文件
==== 28.1 std.Io 的文件事件接口：实测不存在 结束 ====
```

注意倒数第二行末尾那个 **`{f}`**：源码里写的是 `{{f}}`（转义后的字面花括号），
输出出来就是 `{f}`——因为 `{f}` 在格式串里本来是"打印一个 `f64`"的占位符。
这正是坑位清单第 17 条：**格式串里的字面 `{` 必须写 `{{`**。

四个 sleep 相关的签名，逐个实测过（都能编译、都能跑）：

```zig
// 三个等价写法，任选其一
try io.sleep(std.Io.Duration.fromMilliseconds(200), .awake);          // 最常用
try std.Io.Clock.Duration{ .raw = ..., .clock = .awake }.sleep(io);   // ⚠️ 字面量后调方法要加括号或先绑到变量
try std.Io.Timeout{ .duration = .{ .raw = ..., .clock = .awake } }.sleep(io); // 同样是三参
```

`Clock.Duration` 是个**包装**：`{ raw: Io.Duration, clock: Clock }`。多这一层是为了让
超时和绝对截止时间（`Clock.Timestamp`）在类型层面区分开——`Timeout` 是个
`union(enum)`，三个分支 `none / duration / deadline`，`none` 表示"永远等"。

⚠️ 一个 0.17 的**签名地雷**：结构体字面量后面直接跟方法调用，
`Foo{...}.sleep(io)` 编译不过，报 `expected ';' after statement`。Zig 的解析器在
`}` 后面就认为语句结束了。**先绑到 `const` 再调**：

```zig
// ✘ 编译错：expected ';' after statement
try std.Io.Clock.Duration{ .raw = d, .clock = .awake }.sleep(io);
// ✔ 这样写
const cd: std.Io.Clock.Duration = .{ .raw = d, .clock = .awake };
try cd.sleep(io);
```

---

## 28.2 纯求差：三类变更的判据

**本章的核心，也是全章最值得学的 40 行。** 关键设计决策只有一个：
**把"扫描磁盘"和"比较两份快照"彻底分开**，让比较变成一个纯函数。

为什么这个拆分值钱？因为纯函数可以直接单测——不需要真的往磁盘上写文件、
不需要 sleep、不需要任何时序假设（28.8 展开讲）。而"扫描"那一层薄到没有逻辑可测。

先看三个数据类型：

```zig
// examples/28_watch/main.zig 第 24-42 行
const EventKind = enum {
    created,
    modified,
    removed,
};

/// 指纹 = size + mtime。两个字段都要有，理由见 28.6。
const Fingerprint = struct {
    size: u64,
    /// mtime 是 `Io.Timestamp`（i96纳秒），不是整数——必须写 `.nanoseconds` 取值。
    mtime_ns: i96,
};

const Event = struct {
    kind: EventKind,
    /// 事件名。**独立dupe，与快照 map 的键不共享内存**（基线随时换血，借键就是悬空）。
    name: []const u8,
};
```

`EventKind` **只有三个成员**，这是轮询核的一个必然结论：**重命名不是第四类事件**。
在原生 API 上（inotify 有 `IN_MOVED_FROM/TO`、RDCW 有 `FILE_ACTION_RENAMED_*`）
重命名是一等公民；在轮询核里，它只能是「旧名 removed + 新名 created」两条——
因为轮询核**根本不知道**这两个名字之间有关系，它只看到"少了一项、多了一项"。
这个信息损失是轮询方案的固有代价，28.3 的实测输出里能直接看到。

`Snapshot` 是个薄包装，加上内存管理辅助函数。**这一段全是 0.17 的坑位集中区**：

```zig
// examples/28_watch/main.zig 第 43-65 行
/// 快照：文件名→ 指纹。
/// ⚠️ key 必须是**自己 dupe 的**——`Dir.Entry.name` 活不过下一次 `next()`（27 章老坑）。
const Snapshot = struct {
    map: std.StringHashMap(Fingerprint),

    const Map = std.StringHashMap(Fingerprint);

    fn init(a: std.mem.Allocator) Snapshot {
        return .{ .map = Map.init(a) };
    }

    /// 释放整张表。0.17 的 `HashMap` **不拥有键**——键是调用方 dupe 出来的，
    /// 所以这里需逐个 free，分配器就是建表时传进去的那个 `a`。
    fn deinit(s: *Snapshot, a: std.mem.Allocator) void {
        var it = s.map.keyIterator();
        while (it.next()) |k| a.free(k.*);
        s.map.deinit();
    }

    fn count(s: *const Snapshot) usize {
        return s.map.count();
    }

};
```

⚠️ **`HashMap.put` 不 dupe 键**——这是本章最大的地雷。真相在
`std/hash_map.zig` 第 1102-1107 行：

```zig
pub fn getOrPutContext(self: *Self, allocator: Allocator, key: K, ctx: Context) Allocator.Error!GetOrPutResult {
    const gop = try self.getOrPutContextAdapted(allocator, key, ctx, ctx);
    if (!gop.found_existing) {
        gop.key_ptr.* = key;   // ← 键切片被原样搬进表里，没有任何 copy
    }
    return gop;
}
```

实测复现（把字面量 put 进去再 free）：

```text
1/1 pk2.test.put 不 dupe key：free 字面量会被抓住...Bus error at address 0x10f225593
        @as(*align(1) T, @ptrCast(d)).* = splatted;
        while (kit.next()) |k| t.free(k.*);
```

注意崩在 `compiler_rt.zig` 的 `memsetSmallPowerOf2` 里——**不是一个友好的
"you freed a non-heap pointer"**。因为 `free` 里的记账逻辑往一个只读的
`.rodata` 段写去了。所以这个 bug 在小测试里可能表现为莫名其妙的 Bus error，
而不是清晰的断言失败。这就是为什么值得单列一条坑位。

所以示例里所有"往 map 里登记"的代码都走这一个函数：

```zig
// examples/28_watch/main.zig 第 67-78 行
/// 登记一个键**为自己所有**的条目。
/// ⚠️⚠️ 0.17 的 `HashMap.put` **不复制键**——`putContext` 里只有一句
///`gop.key_ptr.* = key`，键切片被原样存进表里。所以想自己拥有键，
///    必须**先 dupe 再 put**。实测：把字符串字面量直接 put 进去、然后 free 它
///    → `Bus error at address 0x...`（不是友好的报错）。
/// ⚠️ 已存在则**不覆盖**——防止重复登记把基线刷掉、从而丢掉一次真实变更。
fn putOwned(a: std.mem.Allocator, m: *Snapshot.Map, name: []const u8, fp: Fingerprint) !void {
    if (m.contains(name)) return;
    const owned = try a.dupe(u8, name);
    errdefer a.free(owned);
    try m.put(owned, fp);
}
```

那么"借用键"的 map 怎么释放？另一个函数：

```zig
// examples/28_watch/main.zig 第 128-151 行
/// 释放一张**键为自己所有**的快照（键是 dupe 出来的）。
/// ⚠️ 签名刻意按**值**接收：0.17 的 `deinit(self: *Self)` 只吃可变指针，
/// 而很多场合手里拿的是 `const` map（函数返回值、`const` 局部变量）。
/// 按值收进来再复制成一份可变局部变量，就不必把调用方的变量全改成 var。
fn freeOwnedKeys(a: std.mem.Allocator, m: Snapshot.Map) void {
    var doomed = m;
    var kit = doomed.keyIterator();
    while (kit.next()) |k| a.free(k.*);
    doomed.deinit();
}

/// 释放一张**键为借用**的快照（键是字符串字面量、调用方的栈缓冲区、
/// 或别处拥有的一块内存）。**只清表，不碰键**——
/// 对借来的键调free 就是非堆内存释放，实测直接 Bus error。
fn deinitBorrowedKeys(m: Snapshot.Map) void {
    var doomed = m;
    doomed.deinit();
}

/// 释放累积的事件列表（事件的name 都是独立 dupe，必须逐条还）
fn freeEvents(a: std.mem.Allocator, evs: *std.ArrayList(Event)) void {
    for (evs.items) |e| a.free(e.name);
    evs.deinit(a);
}
```

**两个释放函数，按键的所有权分派**——这是本章唯一一处"自己造的抽象"，但它消掉了一整类
Bug。`deinitBorrowedKeys` 在示例里其实没有调用点（所有实际路径的键都是自有的），
我把它留着是因为它把"这两种 map 释放方式不同"这件事写成了可执行的文档。

按值收 `freeOwnedKeys` 也是有理由的：0.17 的 `HashMap.deinit` 签名是
`pub fn deinit(self: *Self) void`——**只吃可变指针**。而 `diffInto` 的返回值、
`try` 表达式的结果这些都是 `const`。按值收进来、复制成局部变量再 `deinit`，
调用方就不必为了释放而把变量声明成 `var`。

现在看正主：

```zig
// examples/28_watch/main.zig 第 83-126 行
/// **本章的核心函数**。纯逻辑：old 基线 vs new 当前，产出事件，并把 new 移交给调用方。
///
/// 三类变更的判据：
///   new 有 old 无 → created
///   new 有 old 有，指纹不同 → modified
///   old 有 new 无 → removed（只能靠"扫描结果里少了一项"反推出来）
///
/// ⚠️ **前置条件：`old` 的键必须是自有的（dupe 出来的）**。
///    因为函数末尾要把 old 的键全部 free 掉。如果 old 是拿字面量直接 `put` 进去的，
///    这里就是一次非堆内存释放——实测 Bus error，不是一个友好的报错。
///    返回的新快照 `new` 的所有权（**包括它的键**）移交调用方。
fn diffInto(
    a: std.mem.Allocator,
    old: Snapshot.Map,
    new: Snapshot.Map,
    out: *std.ArrayList(Event),
) !Snapshot.Map {
    // ① new 侧遍历：created 与 modified
    var it = new.iterator();
    while (it.next()) |e| {
        const kind: EventKind = blk: {
            const prev = old.get(e.key_ptr.*) orelse break :blk .created;
            if (prev.size != e.value_ptr.size or prev.mtime_ns != e.value_ptr.mtime_ns) break :blk .modified;
            continue; // 指纹一致 → 这一项没变化，不出事件
        };
        // ⚠️ 事件名必须 dupe 快照的键：事件要活得比这张快照更久
        try out.append(a, .{ .kind = kind, .name = try a.dupe(u8, e.key_ptr.*) });
    }
    // ② old 侧遍历：removed
    var oit = old.iterator();
    while (oit.next()) |e| {
        if (!new.contains(e.key_ptr.*)) {
            try out.append(a, .{ .kind = .removed, .name = try a.dupe(u8, e.key_ptr.*) });
        }
    }
    // ③ 释放 old 的键——它们不会被移交。**必须先出完事件再 free**，
    //    顺序反了，事件里的 name 就指向刚被 free 的内存。
    // ⚠️ 这一步会真的把 old 的键全部 free 掉——所以**必须排在出完事件之后**。
    //    顺序反了，事件里的 name 就指向刚被释放的内存（SafeAllocator 会当场报错）。
    freeOwnedKeys(a, old);

    return new; // new 的键连同 map 一起移交
}
```

**四个设计要点，逐个说清为什么这样写**：

**① 事件名必须 `dupe`，不能借 map 的键。** 这是本章最核心的所有权纪律。
事件列表的生命周期比这张快照长——快照在 `diffInto` 返回时就被整体替换掉了。
如果事件里存的是 `e.key_ptr.*`（指向 map 内部的键缓冲），那批内存要么被 free
（下一轮 `diffInto` 里 `freeOwnedKeys(a, old)`），要么被复用（map 扩容时重排）。
两种情况都是 use-after-free。**dupe 一次，每轮多一份拷贝，换来的是事件可以安全地
排队、传给别的线程、存进日志**。这是正确的取舍方向：拷贝很便宜，悬空很贵。

**② `continue` 在 `while` 里跳过 `out.append`。** 指纹一致意味着"这个文件这一轮没变"，
不产生事件。`continue` 在这里跳过的是 `while` 的下一次迭代，也就是
"这一项处理完了，换下一个"——这是 `blk:` 块表达式的一个便利用法：
块里可以用 `break :blk value` 提前返回，也可以像普通 `continue` 那样直接跳。

**③ 释放旧键的时机在最后。** 如果把 `freeOwnedKeys(a, old)` 挪到两个循环之前，
事件里的 `name` 全部悬空。这个顺序是**测试能抓到的**——`std.testing.allocator`
的真身是 `SafeAllocator`，对 use-after-free 有检测（但对 free 非堆内存是 Bus error，
见前面那段）。

**④ `new` 的所有权通过返回值移交，而不是通过出参。** Zig 没有移动语义，
但"返回值 = 所有权转移"是个足够强的约定。写成 `diffInto(a, old, &new, out)` 让调用方
自己改 `new`，反而要处理"中途失败时 new 归谁"的问题。

`main` 里这节的演示就是手工造两份快照，然后直接对拍：

```zig
// examples/28_watch/main.zig 第 681-693 行（节选）
    // ── 28.2 纯求差函数（零 I/O，可以精确构造）
    begin("28.2 纯求差：三类变更的判据");
    {
        // 手工造两份快照：这一步完全不碰磁盘，所以测试里也能这么干
        var old = Snapshot.Map.init(a); // ⚠️ 必须 var：0.17 的 put/deinit 都收 *Self
        var new = Snapshot.Map.init(a);
        // old: kept（同尺寸改写）、gone（将被删）、same（不动）
        try putOwned(a, &old, "kept", .{ .size = 4, .mtime_ns = 100 });
        try putOwned(a, &old, "gone", .{ .size = 5, .mtime_ns = 200 });
        try putOwned(a, &old, "same", .{ .size = 6, .mtime_ns = 300 });
        // new: kept 改了、same 不变、fresh 是新增
        try putOwned(a, &new, "kept", .{ .size = 4, .mtime_ns = 999 }); // ⚠️ size 一样，只有 mtime 变
        try putOwned(a, &new, "same", .{ .size = 6, .mtime_ns = 300 });
```

⚠️ 这里 `old`/`new` 必须是 `var` 而不是 `const`——0.17 的 `put` 和 `deinit`
**都收 `*Self`**（`pub fn put(self: *Self, key: K, value: V)`）。
`const old = Map.init(a); old.put(...)` 报
`expected type '*T', found '*const T'`。

运行输出（`examples/28_watch/main.zig`）

```text
==== 28.2 纯求差：三类变更的判据 开始 ====
构造的变更：kept 同尺寸改写 / gone 删除 / fresh 新增 / same 不动
求差得到 3 条：
created: fresh
modified: kept
removed: gone
→ same 没有出事件（指纹一致）；kept 靠 mtime 被认出来
==== 28.2 纯求差：三类变更的判据 结束 ====
```

**注意 `kept` 的 size 是 4、没变，只有 mtime 从 100 变成 999——它照样被认成
`modified`。** 这就是为什么指纹要两个字段（28.6 展开）。
`created/removed` 的输出顺序取决于哈希桶顺序，`same` 完全不出现。

---

## 28.3 轮询核：快照 → 求差 → 换血

`diffInto` 是纯函数，把"扫磁盘"接上去的就是 `PollWatcher`：

```zig
// examples/28_watch/main.zig 第 157-217 行
/// 轮询核。持有快照（基线）+ 一个已打开的目录句柄。
/// 根目录以Dir 句柄注入而非写死 cwd——main传自己开的沙盒，测试传 tmpDir。
const PollWatcher = struct {
    io: std.Io,
    a: std.mem.Allocator,
    root: std.Io.Dir, // 必须带 .iterate = true 打开
    base: Snapshot.Map,

    fn init(a: std.mem.Allocator, io: std.Io, root: std.Io.Dir) PollWatcher {
        return .{ .io = io, .a = a, .root = root, .base = Snapshot.Map.init(a) };
    }

    fn deinit(w: *PollWatcher) void {
        freeOwnedKeys(w.a, w.base);
    }

    fn watchedCount(w: *const PollWatcher) usize {
        return w.base.count();
    }

    /// 扫一遍 root下的普通文件，产出当前快照。**只增不减**——
    /// "少了什么"是求差时对比出来的，不是扫描时知道的。
    fn scan(w: *const PollWatcher) !Snapshot.Map {
        var now = Snapshot.Map.init(w.a);
        errdefer freeOwnedKeys(w.a, now);
        // ⚠️ cwd() 是伪句柄（POSIX 上就是 AT.FDCWD），不能 iterate——必须先 openDir。
        var d = try w.root.openDir(w.io, ".", .{ .iterate = true });
        defer d.close(w.io);
        var it = d.iterate();
        while (try it.next(w.io)) |entry| {
            if (entry.kind != .file) continue; // 目录/符号链接的变更本章不跟
            // ⚠️ 必须先 dupe：entry.name 指向迭代器内部缓冲，活不过下一次 next()
            //    （27 章老坑，本章 scan 又踩了一次）。
            const name = try w.a.dupe(u8, entry.name);
            errdefer w.a.free(name);
            const st = try d.statFile(w.io, entry.name, .{}); // 27章：statFile
            const gop = try now.getOrPut(name);
            if (gop.found_existing) {
                w.a.free(name); // 同名重复项，多的这份还回去
            } else {
                gop.key_ptr.* = name;
            }
            gop.value_ptr.* = .{ .size = st.size, .mtime_ns = st.mtime.nanoseconds };
        }
        return now;
    }

    /// 建基线。**事件从下一次 poll 开始计**——建基线那一刻磁盘上已有的东西不算事件。
    fn rebase(w: *PollWatcher) !void {
        const fresh = try w.scan();
        freeOwnedKeys(w.a, w.base);
        w.base = fresh;
    }

    /// 与基线求差，产出事件到 out，并换血基线。
    /// out 是**累积**的（调用者复用同一个列表），要只取本轮增量就自己记游标。
    fn poll(w: *PollWatcher, out: *std.ArrayList(Event)) !void {
        const now = try w.scan();
        w.base = try diffInto(w.a, w.base, now, out);
    }
};
```

**`scan` 里那段 `getOrPut` + `found_existing` 的写法值得单独说。** `getOrPut`
返回的 `key_ptr` 指向 map **内部**的键缓冲。如果已经有同名项了，`gop.key_ptr.* = name`
就是**用一个 `w.a` 分配的内存覆盖一个可能不是 `w.a` 分配的指针**——将来
`freeOwnedKeys` 去 free 它就会炸。所以这里必须：

- `found_existing` → `free` 掉刚 dupe 的那份，用已有的键；
- 否则 → 把刚 dupe 的那份写进 `key_ptr`。

这就是 `getOrPut` 配合**手动管理键**时的唯一安全姿势。
（对比：`put` 因为不 dupe 键，所以没有这个问题——代价是键的生命周期完全归调用方，
见 28.2。）

⚠️ 顺便：`poll` 里 `const now = try w.scan();` 然后 `w.base = try diffInto(...)`。
如果 `diffInto` 失败（比如事件列表分配失败），`now` 就泄漏了。这是示例为了紧凑
接受的取舍——**生产代码应该用 `errdefer freeOwnedKeys(w.a, now);`**。
我把这个取舍写在这里，是因为"示例里省掉的 errdefer"和"设计上不需要的 errdefer"
是两回事：前者是省略，后者是没有。

`rebase` 里 `const fresh = try w.scan();` 之后再释放 `w.base`——**顺序同样是先拿新的
再放旧的**。反过来写就等于先 free 掉基线、再试图扫描，如果扫描失败，监视器就彻底废了
（没有基线的监视器会把磁盘上所有文件都报成 `created`）。

`main` 里的演示覆盖了五个场景，每个场景对应一类真实变化：

```zig
// examples/28_watch/main.zig 第 709-751 行
    // ── 28.3 轮询核
    begin("28.3 轮询核：快照 → 求差 → 换血");
    var w = PollWatcher.init(a, io, box_dir);
    var events: std.ArrayList(Event) = .empty;
    defer {
        freeEvents(a, &events);
        w.deinit();
    }
    try w.rebase(); // 基线：此刻磁盘上已有的东西不算事件
    err.print("基线建好，监视 {d} 个文件\n", .{w.watchedCount()});

    var cursor: usize = 0; // 打印游标：只报本轮新增
    // 场景 1：新建两个文件 → created ×2
    try box_dir.writeFile(io, .{ .sub_path = "a.txt", .data = "one" });
    try box_dir.writeFile(io, .{ .sub_path = "b.txt", .data = "two" });
    try w.poll(&events);
    try reportDelta(&events, &cursor, "新建 a.txt / b.txt");

    // 场景 2：改 a.txt（size 变）+ 删 b.txt → modified + removed
    try box_dir.writeFile(io, .{ .sub_path = "a.txt", .data = "one-two-three" });
    try box_dir.deleteFile(io, "b.txt");
    try w.poll(&events);
    try reportDelta(&events, &cursor, "改 a.txt / 删 b.txt");

    // 场景 3：什么都不做 → 零事件。**幂等**是轮询核的基本素养
    try w.poll(&events);
    try reportDelta(&events, &cursor, "什么都不做");

    // 场景 4：同尺寸改写→ 只靠 size 认不出，靠 mtime 兜住
    try box_dir.writeFile(io, .{ .sub_path = "c.txt", .data = "1234" });
    try w.poll(&events);
    try reportDelta(&events, &cursor, "新建 c.txt");
    try box_dir.writeFile(io, .{ .sub_path = "c.txt", .data = "5678" }); // ⚠️ 长度与上面相同
    try w.poll(&events);
    try reportDelta(&events, &cursor, "同尺寸改写 c.txt");

    // 场景 5：重命名在轮询核里是**两条**事件，不是一类
    // ⚠️ 0.17 的 `Dir.rename` 签名是 `(old_sub_path, new_dir, new_sub_path, io)`——
    //    **io 在最后**（直觉上应该在最前）。写成成员调用时 receiver 顶掉 old_dir，所以是 4 个参数。
    try box_dir.rename("c.txt", box_dir, "d.txt", io);
    try w.poll(&events);
    try reportDelta(&events, &cursor, "重命名 c.txt → d.txt");
    end("28.3 轮询核：快照 → 求差 → 换血");
```

`reportDelta` 用一个游标切出增量。**为什么不直接打印 `events.items` 全量？**
因为事件列表是累积复用的（调用者只分配一次，避免每轮 malloc），打印全量会让
"这一轮变了什么"淹没在历史里。这是示例第一版的真实样子，很难读：

```text
  建a.txt / b.txt：累计 2 条
    created: a.txt
    created: b.txt
  改 a.txt / 删 b.txt：累计 4 条      ← 这轮只发生了 2 件事，但打印了 4 条
    created: a.txt                   ← 历史
    created: b.txt                   ← 历史
    modified: a.txt
    removed: b.txt
```

游标版：

```zig
// examples/28_watch/main.zig 第 855-863 行
/// 打印本轮**新增**的事件。
/// events 是累积复用的（调用者只分配一次），所以用游标切出增量——
/// 打印全量会让"这一轮变了什么"淹没在历史里。
fn reportDelta(events: *const std.ArrayList(Event), cursor: *usize, label: []const u8) !void {
    const fresh = events.items[cursor.*..];
    cursor.* = events.items.len;
    std.debug.print("{s}：{d} 条\n", .{ label, fresh.len });
    for (fresh) |e| std.debug.print("  {s}: {s}\n", .{ @tagName(e.kind), e.name });
}
```

运行输出（`examples/28_watch/main.zig`）

```text
==== 28.3 轮询核：快照 → 求差 → 换血 开始 ====
基线建好，监视 0 个文件
新建 a.txt / b.txt：2 条
  created: a.txt
  created: b.txt
改 a.txt / 删 b.txt：2 条
  modified: a.txt
  removed: b.txt
什么都不做：0 条
新建 c.txt：1 条
  created: c.txt
同尺寸改写 c.txt：1 条
  modified: c.txt
重命名 c.txt → d.txt：2 条
  created: d.txt
  removed: c.txt
==== 28.3 轮询核：快照 → 求差 → 换血 结束 ====
```

**"基线建好，监视 0 个文件"** 是对的：沙盒 `/tmp/zig28_watch_demo` 是空的，
`rebase()` 建的是一个空快照。**"什么都不做：0 条"** 验证了幂等——
这是轮询核最重要的性质。如果不幂等，监视器会在每轮都把整个目录重报一遍。

**"重命名 c.txt → d.txt：2 条"** 是 `EventKind` 只有三个成员的直接后果。
原生 API 会给你一条 `RENAMED_OLD_NAME` + 一条 `RENAMED_NEW_NAME`（或者一条带新旧名的
rename 事件）；轮询核只能给你两条互不知情的 `removed` / `created`。
**如果你的应用需要知道"这是同一个文件的改名"（比如编辑器要保留光标位置），
轮询方案给不了，只能上原生 API。**

---

## 28.4 折中：只 stat 已登记的文件

当目录很大但你只关心 handful 文件（比如配置目录里那三个 `.conf`），
`scan` 里那个"遍历全目录"就是纯浪费。折中方案：**不扫目录，只 stat 已登记的文件**。

```zig
// examples/28_watch/main.zig 第 223-270 行
/// 折中：不扫目录，只 stat handful 个已知文件。
/// 代价 O(目录项数) → O(关注文件数)；**代价是发现不了新文件**。
const TrackedWatcher = struct {
    io: std.Io,
    a: std.mem.Allocator,
    dir: std.Io.Dir,
    watched: Snapshot.Map,

    fn init(a: std.mem.Allocator, io: std.Io, dir: std.Io.Dir) TrackedWatcher {
        return .{ .io = io, .a = a, .dir = dir, .watched = Snapshot.Map.init(a) };
    }

    fn deinit(w: *TrackedWatcher) void {
        freeOwnedKeys(w.a, w.watched);
    }

    fn trackedCount(w: *const TrackedWatcher) usize {
        return w.watched.count();
    }

    /// 纳入监视，用当前磁盘状态当基线。
    /// ⚠️ 已登记的**不刷新**基线——否则每次 track 都会把上一次的变更"抹掉"。
    fn track(w: *TrackedWatcher, name: []const u8) !void {
        if (w.watched.contains(name)) return; // ⚠️ 不刷新基线，否则会吞掉一次真实变更
        const st = try w.dir.statFile(w.io, name, .{});
        // putOwned 内部先 dupe 再 put —— 因为 HashMap.put 不复制键
        try putOwned(w.a, &w.watched, name, .{ .size = st.size, .mtime_ns = st.mtime.nanoseconds });
    }

    /// 逐个 stat 已登记的文件。产出 modified / removed。
    /// ⚠️ 文件被删 → statFile 报 FileNotFound → **错误本身就是事件源**，转成 removed。
    fn poll(w: *TrackedWatcher, out: *std.ArrayList(Event)) !void {
        var it = w.watched.iterator();
        while (it.next()) |e| {
            const st = w.dir.statFile(w.io, e.key_ptr.*, .{}) catch |err| switch (err) {
                error.FileNotFound => {
                    try out.append(w.a, .{ .kind = .removed, .name = try w.a.dupe(u8, e.key_ptr.*) });
                    continue; // 键还留在 watched 里——删了也不再监视，但也不该在这里 free
                },
                else => return err, // 权限之类真故障：往上抛
            };
            const fresh: Fingerprint = .{ .size = st.size, .mtime_ns = st.mtime.nanoseconds };
            if (fresh.size == e.value_ptr.size and fresh.mtime_ns == e.value_ptr.mtime_ns) continue;
            e.value_ptr.* = fresh; // 就地更新基线
            try out.append(w.a, .{ .kind = .modified, .name = try w.a.dupe(u8, e.key_ptr.*) });
        }
    }
};
```

**"错误也是事件源"是这一节最值得带走的一句。** `statFile` 对一个不存在的文件报
`error.FileNotFound`——在别的场景这是异常要处理，在这里**它就是 `removed` 事件的
信号**。同一份错误信息，在"读一个已知存在的文件"的语境里是故障，
在"监视一个可能被别人删掉的文件"的语境里是数据。**语义由调用场景决定，不是由
错误类型决定。**

和 `PollWatcher` 的三处结构差异：

| | `PollWatcher.poll` | `TrackedWatcher.poll` |
|---|---|---|
| 基线更新 | **整体换血**（旧表全部释放，新表移交） | **就地更新**（`e.value_ptr.* = fresh`） |
| 复杂度 | O(目录项数) | O(关注文件数) |
| 能发现新文件 | ✅ | ❌ |
| `removed` 怎么来 | 新快照里少了这一项 | `statFile` 报 FileNotFound |

`TrackedWatcher` 用**就地更新**而不是换血，因为它不拥有"完整目录视图"——
它只有一份手工登记的名单，就地改一个值最自然。这也是为什么它的 `deinit` 只是
把键释放掉，而 `PollWatcher` 的换血要处理两代表的交接。

⚠️ 被删的文件**不从 `watched` 里移除**（`continue` 那一行上面有注释说明）。
这是有意的：如果用户重建了同名文件，我们还能继续监视它。代价是每轮都对
一个不存在的文件做一次注定失败的 `stat`——如果你的设计是"删了就注销"，
在 `removed` 事件产出后顺手 `remove` 掉即可（但要注意迭代中删除的坑，
先收集名字、下一轮再删）。

`main` 里的演示直接把这个方案的边界打在脸上：

```zig
// examples/28_watch/main.zig 第 753-777 行
    // ── 28.4 折中方案
    begin("28.4 折中：只 stat 已登记的文件");
    var tw = TrackedWatcher.init(a, io, box_dir);
    defer tw.deinit();
    try tw.track("a.txt");
    try tw.track("d.txt");
    err.print("已登记 {d} 个文件（不扫目录，只 stat）\n", .{tw.trackedCount()});

    var tev: std.ArrayList(Event) = .empty;
    defer freeEvents(a, &tev);
    var tcur: usize = 0;
    try box_dir.writeFile(io, .{ .sub_path = "a.txt", .data = "one-two-three-four" });
    try box_dir.writeFile(io, .{ .sub_path = "brand_new.txt", .data = "?" }); // 折中方案看不见
    try tw.poll(&tev);
    try reportDelta(&tev, &tcur, "改 a.txt / 新建 brand_new.txt");
    err.print("brand_new.txt 被发现了吗？{s}\n", .{
        if (containsName(tev.items, "brand_new.txt")) "发现了（不对）" else "没有——这正是折中的边界",
    });

    // 删掉被跟踪的文件：statFile 的 FileNotFound 就是 removed 事件
    try box_dir.deleteFile(io, "d.txt");
    try tw.poll(&tev);
    try reportDelta(&tev, &tcur, "删 d.txt");
    err.print("→ statFile 报FileNotFound，被转成 removed；错误也是事件源\n", .{});
    end("28.4 折中：只 stat 已登记的文件");
```

运行输出（`examples/28_watch/main.zig`）

```text
==== 28.4 折中：只 stat 已登记的文件 开始 ====
已登记 2 个文件（不扫目录，只 stat）
改 a.txt / 新建 brand_new.txt：1 条
  modified: a.txt
brand_new.txt 被发现了吗？没有——这正是折中的边界
删 d.txt：1 条
  removed: d.txt
→ statFile 报FileNotFound，被转成 removed；错误也是事件源
==== 28.4 折中：只 stat 已登记的文件 结束 ====
```

**一次 `poll` 发生了两件事（改 a.txt、新建 brand_new.txt），只报出 1 条。**
这不是 bug，是折中方案的**定义**。选折中方案之前必须接受这个前提：
**它只对你已经 `track` 过的文件有效**。如果你需要"目录里任何东西动了都要知道"，
那就必须回到 `PollWatcher`（或者原生 API）。

**选型决策表**：

| 你的需求 | 选谁 |
|---|---|
| 目录几百项，全都要盯 | `PollWatcher`，间隔 200~500ms |
| 目录几万项，只盯 3 个已知文件 | `TrackedWatcher`，间隔 50~100ms |
| 需要识别重命名 | 原生 API（轮询给不了） |
| 目录在网络文件系统上（NFS/SMB） | `TrackedWatcher`，或干脆别做监视 |
| 需要亚百毫秒延迟 | 原生 API |

---

## 28.5 退出：哨兵文件与 Group 取消

**一个监视器最难的不是"怎么发现变更"，而是"怎么停下来"。** 两种"停"的语义要分开：

|谁要停 | 手段 | 为什么需要它 |
|---|---|---|
| **外部**（另一个进程、用户、CI 脚本） | 哨兵文件：出现 `STOP` 文件就收工 | 进程之间没有别的通信渠道；文件是最低公分母 |
| **内部**（用户 Ctrl-C、上层决定收工） | `Io.Group.cancel(io)` | 立刻唤醒阻塞中的等待，不用等当前这轮睡完 |

关键是搞清楚**在 0.17 里"等待"是怎么被取消的**。答案是：**`Io.sleep` 是取消点
（cancelation point）**。`Group.cancel` 会让阻塞中的 `sleep` 立刻返回
`error.Canceled`。**不是给循环加标志位，而是让等待本身可取消**——这是本章
最值得带走的一句设计原则。

```zig
// examples/28_watch/main.zig 第 276-330 行
/// 一个后台监视任务。签名刻意做成 `Cancelable!void` 兼容：
/// `Group.async` 要求回调能被coerce 到 `Cancelable!void`。
///
/// 两种"停"各管一种语义：
///   哨兵文件出现 = **外部**请求停（另一个进程 / 用户放的）
///   Group.cancel = **内部**请求停（用户 Ctrl-C / 上层决定收工）
///
/// 关键机制：**`Io.sleep` 是取消点**。`Group.cancel` 让阻塞中的 sleep 立刻返回
/// `error.Canceled`——不用等这一轮睡完。这就是"轮询循环怎么做到可中断"的答案：
/// 不是给循环加标志位，而是**让等待本身可取消**。
fn watchLoop(
    io: std.Io,
    dir: std.Io.Dir,
    stop_name: []const u8,
    interval_ms: i64,
    max_rounds: usize,
    on_event: *const fn (kind: EventKind, name: []const u8) void,
) void {
    const a = std.heap.page_allocator;
    var w = PollWatcher.init(a, io, dir);
    defer w.deinit();
    w.rebase() catch return;

    var events: std.ArrayList(Event) = .empty;
    defer freeEvents(a, &events);

    var round: usize = 0;
    while (round < max_rounds) : (round += 1) {
        // ① 等待一段间隔。**这一行是取消点**：Group.cancel 会让它返回 error.Canceled。
        io.sleep(std.Io.Duration.fromMilliseconds(interval_ms), .awake) catch |err| switch (err) {
            error.Canceled => {
                std.debug.print("[监视器] 收到取消，第 {d} 轮中途收工\n", .{round + 1});
                return;
            },
            else => return,
        };
        // ② 哨兵检查。⚠️ 用 `access` 而不是 `statFile`——
        //    statFile 成功时返回 `Io.File.Stat` 值类型，
        //    `catch |err| switch (err)` 会撞上 "incompatible types: 'Io.File.Stat' and 'void'"。
        //    access 的错误集含 FileNotFound——"文件不在"正是答案，不是故障。
        if (dir.access(io, stop_name, .{})) |_| {
            std.debug.print("[监视器] 哨兵 {s} 出现，第 {d} 轮收工\n", .{ stop_name, round + 1 });
            return;
        } else |err| switch (err) {
            error.FileNotFound => {}, // 继续监视
            else => return,
        }

        // ③ 扫描求差
        const before = events.items.len;
        w.poll(&events) catch return;
        for (events.items[before..]) |e| on_event(e.kind, e.name);
    }
    std.debug.print("[监视器] 跑满 {d} 轮，正常结束\n", .{max_rounds});
}
```

⚠️ **哨兵检查用 `access` 而不是 `statFile`——这不是风格问题，是编译不过。**
`statFile` 成功时返回 `Io.File.Stat`（一个值类型），而 `catch |err| switch (err)`
的 switch 主体类型必须是 `void`（`catch` 的成功分支返回 `statFile` 的结果）。
报错原文：

```text
error: incompatible types: 'Io.File.Stat' and 'void'
note: type 'Io.File.Stat' here
note: type 'void' here
```

`dir.access(io, path, .{})` 的成功分支是 `void`，所以 `if (dir.access(...)) |_|`
正好合适：成功分支 `|_|`（值被丢弃）、`else |err|` 处理 `error.FileNotFound`。
**"这个文件在不在"是个布尔问题，就该用返回 `void` 的谓词 API，
不要用返回元数据的 API。**

`Group` 的两个方法对比：

```zig
// examples/28_watch/main.zig 第 336-349 行
/// 优雅退出的**同步**版：等监视器自然结束（正常跑满或看到哨兵）。
/// 与`Group.cancel` 的区别：await 等它自己停，cancel 强制它停。
fn runUntilStop(
    io: std.Io,
    dir: std.Io.Dir,
    stop_name: []const u8,
    interval_ms: i64,
    max_rounds: usize,
    on_event: *const fn (kind: EventKind, name: []const u8) void,
) !void {
    var g: std.Io.Group = .init;
    g.async(io, watchLoop, .{ io, dir, stop_name, interval_ms, max_rounds, on_event });
    try g.await(io);
}
```

`Group` 有三个关键性质（源码 `Io.zig` 第 1338-1435 行的注释里写得很清楚）：

1. **`Group.async(io, fn, args)` 把任务挂到这个 group 上**，函数必须能 coerce 到
   `Cancelable!void`。`watchLoop` 返回 `void`，`void` 能 coerce 到 `Cancelable!void`
   （错误集合是空的），所以直接可用。
2. **`Group.await(io)` 阻塞到所有任务跑完**。而且注释明确写：
   *"After this function returns, all tasks of the `Group` ... are guaranteed to have run."*
   ——**"跑完"不是"发出信号"，是真的执行完了**。这对资源清理至关重要。
3. **`Group.cancel(io)` 先请求取消，再等所有任务跑完**。所以 `cancel` 返回之后，
   监视器的 `defer`（`w.deinit()`、`freeEvents`）**已经执行完毕**。
   主任务继续往下走时，不会看到一个半死不活的监视器。

`main` 里三种退出姿势各演示一遍：

```zig
// examples/28_watch/main.zig 第 779-812 行
    // ── 28.5 优雅退出
    begin("28.5 退出：哨兵文件与 Group 取消");
    // 另开一个非 iterate 句柄专用于写/删哨兵（监视器那份必须 .iterate）
    var ctl_dir = try cwd.openDir(io, box, .{});
    defer ctl_dir.close(io);

    err.print("① 哨兵文件（外部请求停）+ 并行主任务\n", .{});
    // 监视器每轮 30ms、最多 10 轮；主任务 80ms 后放哨兵。
    // 两者在同一个 Group 里并行——主任务在"等待监视器"的同时还能做点事（这里就是放哨兵）。
    // ⚠️ 这才是哨兵模式的正确姿势：`Group.await` 是**阻塞**的，
    //    如果像`runUntilStop` 那样把监视器和放哨兵分成先后两段，哨兵永远来不及放。
    {
        var g: std.Io.Group = .init;
        g.async(io, watchLoop, .{ io, box_dir, "STOP", 30, 10, reportEvent });
        try io.sleep(std.Io.Duration.fromMilliseconds(80), .awake);
        ctl_dir.writeFile(io, .{ .sub_path = "STOP", .data = "" }) catch {};
        try g.await(io); // 监视器看到哨兵 → 自行 return → await 立即返回
        ctl_dir.deleteFile(io, "STOP") catch {};
    }

    err.print("② Group.cancel（内部请求停）\n", .{});
    {
        var g: std.Io.Group = .init;
        g.async(io, watchLoop, .{ io, box_dir, "NEVER_EXISTS", 50, 100, reportEvent });
        try io.sleep(std.Io.Duration.fromMilliseconds(60), .awake);
        err.print("   主任务喊停\n", .{});
        g.cancel(io); // 监视器的 io.sleep 立刻 error.Canceled，不必等这 50ms 睡完
        // cancel 返回后 Group 保证所有任务已真正跑完（不是"发个信号"就返回）
    }
    err.print("   监视器已收工，主任务继续往下走\n", .{});

    err.print("③ 跑满上限自然结束（什么都不干预）\n", .{});
    try runUntilStop(io, box_dir, "NEVER_EXISTS", 10, 3, reportEvent);
    end("28.5 退出：哨兵文件与 Group 取消");
```

⚠️ **哨兵模式的正确姿势是"并行"，不是"先后"。** 示例的第一版写的是：

```zig
// ✘ 错误示范：第一版就是这么写的
err.print("① 哨兵文件（外部请求停）\n", .{});
try runUntilStop(io, box_dir, "STOP", 30, 5, reportEvent);   // await 阻塞到监视器结束
err.print("   （上面这轮没看到哨兵是正常的：runUntilStop 是 await，主任务没机会放哨兵）\n", .{});
```

`runUntilStop` 是**阻塞**的——它 `await` 到监视器自然结束。主任务在
`await` 期间什么都做不了，所以**根本没有机会去放哨兵**，监视器只能跑满 5 轮。
正确做法是把"放哨兵"也塞进同一个 `Group`（或至少在 `await` 之前做掉）。
这个错误在运行时输出里表现为"没看到预期的收工消息"，很值得记住。

运行输出（`examples/28_watch/main.zig`）

```text
==== 28.5 退出：哨兵文件与 Group 取消 开始 ====
① 哨兵文件（外部请求停）+ 并行主任务
[监视器] 哨兵 STOP 出现，第 3 轮收工
② Group.cancel（内部请求停）
   主任务喊停
[监视器] 收到取消，第 2 轮中途收工
   监视器已收工，主任务继续往下走
③ 跑满上限自然结束（什么都不干预）
[监视器] 跑满 3 轮，正常结束
==== 28.5 退出：哨兵文件与 Group 取消 结束 ====
```

三种结局对应三种语义：**哨兵收工**（外部喊停）、**取消收工**（内部喊停，
而且是从 `sleep` 中途被拽出来的）、**跑满上限**（没人干预）。

最后讲一下 `Io.Event`——它和文件监视没关系，但既然 28.1 提到了，就钉清楚
**它到底是什么**，以及 0.17 那个真实的不一致点：

```zig
// examples/28_watch/main.zig 第 1117-1125 行
test "Io.Event 的 0.17 不一致点：set 要 io，reset 不要" {
    const io = std.testing.io;
    var ev: std.Io.Event = .unset;
    try std.testing.expect(!ev.isSet());
    ev.set(io); // ← 要 io（可能要futexWake）
    try std.testing.expect(ev.isSet());
    ev.reset(); // ← 不要 io（只是 atomicStore）
    try std.testing.expect(!ev.isSet());
}
```

`Io.Event` 是 `enum(u32) { unset, waiting, is_set }`。语义是"**一个可阻塞等待的
布尔量**"，用途是任务/线程间的手动同步（"这边准备好了"）：

- `wait(io)`：阻塞到 `is_set`。内部是 `@cmpxchgStrong` 把 `unset` 换成 `waiting`
  再 `futexWait`。
- `set(io)`：置 `is_set`；如果当前是 `waiting`，要 `futexWake` 叫醒所有等待者。
- `isSet()`：非阻塞读。
- `reset()`：置回 `unset`。

**为什么 `set` 要 io 而 `reset` 不要**——因为 `set` 可能需要执行 `futexWake`
（一个系统调用，需要 `Io` 实例），而 `reset` 只是
`@atomicStore(Event, e, .unset, .monotonic)`，纯 CPU 指令。源码注释
（`Io.zig` 第 2064-2069 行）还补了一句：`reset` **假定没有 pending 的
`wait`/`waitUncancelable`**——它不管在等的人。所以如果你在有 waiter 的时候调 `reset`，
那些 waiter 醒来会看到 `.unset` 然后继续等（源码里那一行 `.unset => unreachable`
只在"reset 在 wait 返回前被调用"这个竞态下是 unreachable）。

这是一个**合理的但不对称的设计**：能唤醒人的操作需要系统调用，能改内存的操作不需要。
旧版本的 std 里 `Event.set` 还要多一个 `wake` 布尔参数（`set(io, true)`），
0.17 把它去掉了——现在 `set` 总是唤醒。

⚠️ 别把它当"文件系统事件"用。它监视不了任何东西，只能被人显式 `set`/`reset`。

---

## 28.6 时间戳：mtime 精度与指纹设计

这一节回答"为什么指纹要 `size` + `mtime` 两个字段"。先看 `statFile` 到底返回什么：

```zig
// lib/std/Io/File.zig 第 57-89 行（节选）
pub const Stat = struct {
    inode: INode,
    nlink: NLink,
    size: u64,
    permissions: Permissions,
    kind: Kind,
    /// Last access time in nanoseconds, relative to UTC 1970-01-01.
    /// Some systems report stale values, and some systems explicitly refuse to
    /// report this value. The latter case is handled by `null`.
    atime: ?Io.Timestamp,
    /// Last modification time in nanoseconds, relative to UTC 1970-01-01.
    mtime: Io.Timestamp,
    /// Last status/metadata change time in nanoseconds, relative to UTC 1970-01-01.
    ctime: Io.Timestamp,
    /// Smallest chunk length in bytes appropriate for optimal I/O. This will be
    /// set to `1` for operating systems or file systems that do not
    /// recognize this concept. Not always a power of two.
    block_size: BlockSize,
};
```

几个实测确认的点：

- **`mtime` 的类型是 `Io.Timestamp`**，不是整数。`Io.Timestamp` 是个
  `struct { nanoseconds: i96 }`。所以取值必须写 `st.mtime.nanoseconds`，
  直接 `st.mtime` 拿到的是结构体，和 `i96` 比较会编译错。
- **`atime` 是 `?Io.Timestamp`**（可选）。有些文件系统明确拒绝提供访问时间
  （源码注释点名了某些系统），那时候是 `null`。所以读 atime 必须处理 `null`。
- **`ctime` 存在且不是可选项**——它是 inode 变更时间（POSIX 语义），
  文件大小/权限/链接数变了就更新。在 Windows 上它映射到
  `FILE_BASIC_INFO.ChangeTime`（元数据变更），语义和 POSIX 略有差异。
- **精度是纳秒，但"纳秒"是单位不是保证。** `Io.Timestamp.nanoseconds` 是 `i96`
  纳秒，但**底层文件系统的时间戳精度由FS 和 OS 决定**。

`timestampProbe` 把这件事在运行时钉出来：

```zig
// examples/28_watch/main.zig 第 355-383 行
/// 打印"本机时间戳到底能分辨多细"——这是设计轮询间隔与指纹字段的依据。
/// **不同文件系统差别巨大**：APFS/ ext4 是纳秒，FAT32 是 2 秒，HFS+ 是 1 秒。
/// 所以指纹必须同时带 size：同秒内的同尺寸改写，mtime 在粗粒度文件系统上会漏。
fn timestampProbe(io: std.Io, dir: std.Io.Dir, name: []const u8) !void {
    const err = std.debug;
    // 0.17 没有 .monotonic 成员了。实测五个成员是：
    //   real / awake / boot / cpu_process / cpu_thread
    //   .awake   ≈ CLOCK_UPTIME_RAW（macOS）/ CLOCK_MONOTONIC（Linux）——单调、不含睡眠
    //   .boot    ≈ CLOCK_MONOTONIC_RAW / CLOCK_BOOTTIME——单调、含睡眠
    // 想"量一段真实流逝"用 .awake；想"跨睡眠也算进去"用 .boot。
    const res = try std.Io.Clock.awake.resolution(io);
    err.print("  Clock.awake 分辨率={f}\n", .{res});

    const st = try dir.statFile(io, name, .{});
    err.print("  {s}: size={d}字节 mtime={d}ns ctime={d}ns\n", .{
        name, st.size, st.mtime.nanoseconds, st.ctime.nanoseconds,
    });
    err.print("  atime 是 ?Io.Timestamp ={}（有些 FS 拒绝提供）\n", .{st.atime != null});

    // 连续两次改写，看 mtime 的最小可分辨增量
    const p = try std.heap.page_allocator.dupe(u8, name);
    defer std.heap.page_allocator.free(p);
    try dir.writeFile(io, .{ .sub_path = p, .data = "AAAA" });
    const t1 = (try dir.statFile(io, p, .{})).mtime.nanoseconds;
    try dir.writeFile(io, .{ .sub_path = p, .data = "BBBB" }); // ⚠️ 同样长度
    const t2 = (try dir.statFile(io, p, .{})).mtime.nanoseconds;
    err.print("  同尺寸连续改写：mtime 变了={} 增量={d}ns\n", .{ t1 != t2, t2 - t1 });
    err.print("  → 本机是纳秒级；FAT32 上这个增量会是 0，所以指纹必须同时比 size\n", .{});
}
```

运行输出（`examples/28_watch/main.zig`）

```text
==== 28.6 时间戳：mtime 精度与指纹设计 开始 ====
  Clock.awake 分辨率=1ns
  ts.txt: size=4字节 mtime=<纳秒时间戳>ns ctime=<纳秒时间戳>ns
  atime 是 ?Io.Timestamp =true（有些 FS 拒绝提供）
  同尺寸连续改写：mtime 变了=true 增量=<十几万纳秒量级>ns
  → 本机是纳秒级；FAT32 上这个增量会是 0，所以指纹必须同时比 size
  轮询间隔的取舍：太密→CPU 与 I/O 空转；太疏 → 漏掉短命的变更。
  经验值：交互式工具 100~500ms；构建守卫 1~2s；日志tail 50~200ms。
  更狠的做法是**混合**：先 stat 已知文件（便宜），
  有变化才做全量scan（贵）——把 28.4 的折中当地基。
==== 28.6 时间戳：mtime 精度与指纹设计 结束 ====
```

（两处按"耗时 / 原始值不抄"的规则做了占位：`mtime`/`ctime` 的绝对纳秒值每轮都不同；
那个 `增量` 是**两次 `writeFile` 之间的真实耗时**，连跑三次分别是 221095 /
161095 / 147938 纳秒——**它证明的是"本机分辨率远细于毫秒"这个量级结论**，
而不是某个具体数字。`size=4字节` 和 `分辨率=1ns` 是确定性信息，保留原样。）

⚠️ **Windows 实测（0.17，NTFS，回归机上）**：这段输出是
`同尺寸连续改写：mtime 变了=false 增量=0ns`、`Clock.awake 分辨率=100ns`——
两次紧邻的写落在同一个时间戳刻度上。所以"同尺寸改写靠 mtime 兜住"那条测试
在 Windows 上放宽成了"0 或 1 条事件都算知道"（只要有事件就必须是 modified），
这正好是把**轮询监视器的固有盲区**摆在台面上：mtime+size 都抓不住的同刻度
同尺寸改写，只能靠内容哈希（37 章 FileGuard 的 `checksum` 字段干的就是这个）。

⚠️ **这里要诚实地说明一件事**：本机（macOS APFS）测出来**mtime 是纳秒级的**——
同尺寸连续改写的最小可分辨增量在**十几万纳秒（0.1~0.2 毫秒）**量级，
所以 28.3 场景 4 的"同尺寸改写"能被检测到。

**但这不能推广。** 常见文件系统的 mtime 精度差异：

| 文件系统 | mtime 精度 | 后果 |
|---|---|---|
| ext4 / XFS / Btrfs | 纳秒（实际是时钟源精度） | 任何轮询间隔都能分辨 |
| **APFS** | **纳秒**（本机实测） | 同上 |
| NTFS | 100ns（Windows 8 之后） | 同上 |
| HFS+（旧 macOS） | **1 秒** | 同秒内的同尺寸改写检测不到 |
| **FAT32** | **2 秒** | 两秒内的所有修改都检测不到（同尺寸） |
| NFS（v3） | 依赖服务端，可能是 1 秒 | 更糟 |
| WebDAV / 部分 FUSE | 可能只有秒级，甚至不更新 | 轮询方案直接失效 |

所以**"指纹只比 size 够不够"这个问题的答案是"看文件系统"**：
在本机的 APFS 上够（size + mtime 双保险当然更稳），在 FAT32 上**光靠 size 和 mtime
都可能漏**。如果你必须监视 FAT32 卷上的同尺寸快速改写，**只能用原生 API 的
`FILE_NOTIFY_CHANGE_LAST_WRITE`**——它由文件系统驱动在写入时推送，不依赖你轮询时
读到的 mtime 精度。

**这就是"轮询 vs 原生"的一个真实分界线**，值得单独记住：
**轮询方案的分辨率上限就是你 `statFile` 能读到的分辨率。**

顺带把时钟枚举的语义讲清（0.17 的实测，`Io.zig` 第 836-896 行的文档注释）：

| Clock | macOS 对应 | Linux 对应 | 单调？ | 含睡眠？ |
|---|---|---|---|---|
| `.real` | `gettimeofday` | `CLOCK_REALTIME` | ❌ | ✅ |
| `.awake` | `CLOCK_UPTIME_RAW` | `CLOCK_MONOTONIC` | ✅ | **❌** |
| `.boot` | `CLOCK_MONOTONIC_RAW` | `CLOCK_BOOTTIME` | ✅ | ✅（意图上） |
| `.cpu_process` | 进程 CPU 时间 | 同 | — | — |
| `.cpu_thread` | 线程 CPU 时间 | 同 | — | — |

**轮询间隔的 sleep 必须用 `.awake` 或 `.boot`，绝不能用 `.real`。**
`.real` 会被 NTP 校时和用户手动改时间影响——一个往回跳的时钟会让你的
`sleep` 睡出预期之外的时长（甚至睡成负数）。`Io.sleep` 的注释里没有强制这一点，
但源码里 `.awake` 和 `.boot` 的文档都强调了"Monotonic: Guarantees that the time
returned by consecutive calls will not go backwards"。

⚠️ `.awake` 的文档注释里还有一句很诚实的话：
*"This clock expresses intent to **exclude time that the system is suspended**.
However, implementations may be unable to satisfy this, and may include that time."*
——意图是排除休眠时间，但实现不一定做得到（macOS 上 `CLOCK_UPTIME_RAW` 在某些
唤醒场景下确实会计入休眠）。如果你要"跨休眠精确 5 分钟"，`.boot` 更可靠。

**轮询间隔的取舍，一张表**：

| 场景 | 建议间隔 | 理由 |
|---|---|---|
| 交互式工具（用户等着看响应） | 100~300ms | 感知延迟 < 300ms；每秒 3~10 次 `getdents` 无感 |
| 日志 tail | 50~200ms | 更跟手；目录通常很小 |
| 构建守卫（watch 源码触发重编译） | 500ms~1s | 编辑器保存有防抖；省 CPU |
| 备份 / 同步 | 1~5s | 延迟无所谓 |
| 大目录（>5000 项） | 1~5s，或改用 `TrackedWatcher` | 每轮 5000 次 `stat` 不便宜 |

**更优的第三种做法（示例里提了）**：**混合**——每轮先 stat 已知的少数文件（便宜），
**只有发现变化时才做全量 scan**（贵）。这把"每轮成本"从 O(目录项数) 降到
O(已知文件数)，同时保留了"能发现新文件"的能力。代价是逻辑复杂一点：
你最关心的新文件本身不在"已知文件"里，所以**全量 scan 还是要定期做**
（比如每 10 轮强制一次），否则一个全新的文件会一直不被发现。

---

## 28.7 Windows 原生 ReadDirectoryChangesW

前面六节讲的都是"怎么绕开 std 的缺失"。这一节正面上一套原生调用——
它的价值不在于"本章的示例能在 Windows 上跑"（本机是 macOS，跑不了），
而在于**它是 extern 声明、结构体布局、调用约定、句柄语义的完整范例**，
而这四样正是 17 章（C 互操作）里没讲透的细节。

⚠️ **本节代码只做了静态验证**：用 `zig build-exe -target x86_64-windows`
确认能编译。**运行期行为没有在本机验证过**（本机是 macOS，没有
`ReadDirectoryChangesW`）。下面凡是行为描述，都是基于 API 文档和记录链布局的推演。

先说**为什么必须按平台门控**：

```zig
// examples/28_watch/main.zig 第 385-398 行
// ══════════════════════════════════════════════════════════════════
// 28.7 Windows 原生 ReadDirectoryChangesW
//
// 整段装进命名空间按平台门控：非 Windows 目标上 `extern "kernel32"` 与
// `callconv(.winapi)` **根本不存在**（`.winapi` 只在 Windows 目标有定义），
// 所以连声明都不能出现在被语义分析的文件里——必须让编译器把整段消掉。
//
// ⚠️ 本机是 macOS，这段只能做**静态验证**：`zig build-exe -target x86_64-windows`
// 能过就说明 extern 签名、结构体布局、枚举比较全对。运行期行为无法在本机验证。
// ══════════════════════════════════════════════════════════════════

const native = if (builtin.os.tag == .windows) struct {
    const w = std.os.windows;
    const enabled = true;
```

这个 `if (builtin.os.tag == .windows) struct { ... } else struct { ... }`
是 Zig 里**平台门控的标准姿势**。关键点：`builtin.os.tag` 是编译期已知的，
所以被选中的分支是唯一被语义分析的分支——**另一分支里的代码在非 Windows 目标上
根本不存在**。这不是运行时 `if`，是编译期消掉一个分支。

如果不用这个门控（比如直接写 `extern "kernel32" fn ...` 在文件顶层），
在 macOS 上编译时会报
`unable to find extern function` 或者
`error: callconv enum 'winapi' not available in the current target`。
所以**门控不是"为了整洁"，是编译能不能过的问题**。

四个 extern 声明：

```zig
// examples/28_watch/main.zig 第 400-427 行
    // ⚠️ 0.17 的调用约定名是 `.winapi`，不是老版本的 `.win64`。
    //   （x64 上 winapi 与 win64 恰好同 ABI，但名字变了；写 `.win64` 编译不过。）
    extern "kernel32" fn CreateFileW(
        lpFileName: [*]const u16,
        dwDesiredAccess: w.DWORD,
        dwShareMode: w.DWORD,
        lpSecurityAttributes: ?*anyopaque,
        dwCreationDisposition: w.DWORD,
        dwFlagsAndAttributes: w.DWORD,
        hTemplateFile: ?w.HANDLE,
    ) callconv(.winapi) w.HANDLE;

    extern "kernel32" fn ReadDirectoryChangesW(
        hDirectory: w.HANDLE,
        lpBuffer: [*]u8,
        nBufferLength: w.DWORD,
        bWatchSubtree: w.BOOL,
        dwNotifyFilter: w.DWORD,
        lpBytesReturned: *w.DWORD,
        lpOverlapped: ?*anyopaque,
        lpCompletionRoutine: ?*const anyopaque,
    ) callconv(.winapi) w.BOOL;

    // CancelIo 是"取消点"的对偶：它让阻塞中的 ReadDirectoryChangesW 立刻返回
    // ERROR_OPERATION_ABORTED。没有它，异步模式下的监视器无法优雅退出。
    extern "kernel32" fn CancelIo(hFile: w.HANDLE) callconv(.winapi) w.BOOL;

    extern "kernel32" fn CloseHandle(hObject: w.HANDLE) callconv(.winapi) w.BOOL;
```

四个坑，逐个说：

**⚠️ 坑 1：`callconv(.winapi)`，不是 `.win64`。** 0.17 把调用约定改名了。
`CallConv` 枚举在 0.17 里有 `.winapi`（统一的 Windows ABI），
没有 `.win64` 也没有 `.win32`。历史上 x86 上 `.win32`（stdcall）和 x64 上
`.win64`（微软 x64 约定）不同，但 x64 上"忽略参数个数"这个特性让两者 ABI 一样，
所以 0.17 统一成 `.winapi`。

**⚠️ 坑 2：`lpFileName: [*]const u16` 不是 `[*:0]const u16`。**
`CreateFileW` 需要**以 NUL 结尾**的宽字符串。`[*]const u16` 是"裸指针"，
编译器不保证你 NUL 结尾了。示例里手工做了这件事：

```zig
// examples/28_watch/main.zig 第 468-476 行
    /// ASCII 路径逐字节搬成宽字符。⚠️ **含中文的路径必须走
    /// `std.unicode.utf8ToUtf16LeAlloc`**——按字节搬会得到一个乱码路径，
    /// CreateFileW 会报 FileNotFound，而且你完全看不出哪里错了。
    fn toWide(a: std.mem.Allocator, path: []const u8) ![:0]u16 {
        const buf = try a.allocSentinel(u16, path.len, 0);
        errdefer a.free(buf);
        for (path, 0..) |c, i| buf[i] = c; // ⚠️ 0.17：dupeZ 已移除，allocSentinel 才是正解
        return buf;
    }
```

两点值得注意：

- **`allocSentinel` 而不是 `alloc` + 手工写 `buf[len] = 0`**。
  用哨兵切片类型 `[:0]u16` 让"这个字符串一定 NUL 结尾"变成**类型系统的事实**，
  下游用 `@as([*:0]const u16, buf.ptr)` 转换时编译器才肯收。
- **`dupeZ` 在 0.17 已移除**，替代品就是 `allocSentinel(T, n, sentinel)`。
  这是本教程系列的通用迁移点（见 26 章坑位清单同批）。

⚠️ **逐字节搬只对 ASCII 正确**。中文路径必须走
`std.unicode.utf8ToUtf16LeAlloc`——按字节搬得到的是乱码路径，
`CreateFileW` 报 `FileNotFound`，而你从错误信息里完全看不出真实原因。

**⚠️ 坑 3：`HANDLE` 是 `*anyopaque`，失败值是 `INVALID_HANDLE_VALUE`。**

```zig
// lib/std/os/windows.zig 第 4031 行 / 4153 行
pub const HANDLE = *anyopaque;
pub const INVALID_HANDLE_VALUE: HANDLE = @ptrFromInt(maxInt(usize));
```

所以句柄检查是**比地址**，不是比null：

```zig
// examples/28_watch/main.zig 第 504-508 行
        // ⚠️ HANDLE 是 `*anyopaque`，失败值是 INVALID_HANDLE_VALUE（不是 null）。
        //   必须比地址——`if (dir_handle == null)` 编译不过且逻辑错。
        if (dir_handle == w.INVALID_HANDLE_VALUE) return error.OpenDirFailed;
        defer _ = CloseHandle(dir_handle);
```

⚠️ 而且 **`std.os.windows` 里没有 `TRUE`/`FALSE` 常量**（实测报错
`root source file struct 'os.windows' has no member named 'TRUE'`）。
`w.BOOL` 的两个成员是 `.FALSE`（backing 0）和 `.TRUE`——而 `.TRUE` 定义在
**`Bool()` 返回的那个类型里面**，所以要写**`w.BOOL.TRUE`**，不是 `w.TRUE`：

```zig
// lib/std/os/windows.zig 第 4025 行 / 4131-4151 行
pub const BOOL = Bool(c_int);

fn Bool(comptime BackingInteger: type) type {
    return enum(Backing) {
        /// false
        FALSE = 0,
        /// true
        _,                    // ← 非穷尽！任何非 0 值都"是真"

        pub const TRUE: @This() = @fromBackingInt(@intCast(1));
        pub const Backing = BackingInteger;
        pub fn toBool(b: @This()) bool { return b != .FALSE; }
        pub fn fromBool(b: bool) @This() { return @fromBackingInt(@intCast(@intFromBool(b))); }
    };
}
```

**注意 `enum(Backing) { FALSE = 0, _, ... }` 这个形状：它只有一个具名成员 `FALSE`
和一个 `_` 兜底。** 这就是为什么比较必须写 `.FALSE`：

```zig
// examples/28_watch/main.zig 第 526-528 行
        // ⚠️ BOOL 是**枚举**（`Bool(c_int)`，成员 `FALSE = 0` 与 `_`），不是 i32。
        //    `ok == .FALSE` 才对；`ok == 0` 编译不过。
        if (ok == .FALSE) return error.ReadChangesFailed;
```

`ok == 0` 编译不过，因为 `w.BOOL` 是枚举类型，不能和整数字面量直接比较。
**这是本章唯一一个"BOOL 是枚举"的实际验证点**——`std.os.windows.BOOL` 不是
C 的 `int`，而是 Zig 自己定义的枚举。

**⚠️ 坑 4：`bWatchSubtree` 和 `dwNotifyFilter` 也是 `BOOL`/`DWORD`，不是布尔。**

```zig
// examples/28_watch/main.zig 第 515-528 行
        const ok = ReadDirectoryChangesW(
            dir_handle,
            &buffer,
            buffer.len,
            .FALSE, // ⚠️ bWatchSubtree：只看本层目录；.TRUE 递归
            FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_SIZE |
                FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_CREATION,
            &returned,
            null,
            null,
        );
        // ⚠️ BOOL 是**枚举**（`Bool(c_int)`，成员 `FALSE = 0` 与 `_`），不是 i32。
        //    `ok == .FALSE` 才对；`ok == 0` 编译不过。
        if (ok == .FALSE) return error.ReadChangesFailed;
```

第 4 个参数 `bWatchSubtree` 传 `.FALSE`（不递归）还是 `.TRUE`（递归监视子树）。
**这直接对应轮询核的一个能力差异**：`PollWatcher.scan` 只扫一层
（`entry.kind != .file` 就 `continue`），所以 `TrackedWatcher` 那层也不递归。
想要递归，原生这边只要把 `.FALSE` 改成 `.TRUE`——**这是原生 API 明显强于轮询的地方**。

`dwNotifyFilter` 是位掩码，声明在 `examples/28_watch/main.zig` 第 429-449 行。
每一位选一类变化——**这也是原生 API 的强项**：轮询核只能通过
"size/mtime 变了"间接推断"变了"，而这里可以只关心
`FILE_NOTIFY_CHANGE_FILE_NAME`（增删改名）而不关心 `FILE_NOTIFY_CHANGE_SIZE`，
从源头减少事件量。

现在讲**记录链解析**，这是 RDCW 的全部难点：

```zig
// examples/28_watch/main.zig 第 451-458 行
    /// 记录头。⚠️ **头部是 4+4+4 = 12 字节，后面紧跟 name_len 字节的变长 UTF-16 文件名**。
    ///   文件名**不是**结构体成员——所以不能声明成 `name: [:0]const u16`（那是 C 头的写法，
    ///   在 Zig 里会算成定长数组，把整个记录变成固定 12+2N 字节）。
    const NotifyInfo = extern struct {
        next_offset: w.DWORD, // 0 = 链尾；否则是到下一条记录的**字节偏移**（不是条目索引！）
        action: w.DWORD,
        name_len: w.DWORD, // 文件名字节数（UTF-16，所以 = 字符数 × 2）
    };
```

**`FILE_NOTIFY_INFORMATION` 是一个"变长记录"**，C 头的写法是：

```c
typedef struct _FILE_NOTIFY_INFORMATION {
  DWORD NextEntryOffset;
  DWORD Action;
  DWORD FileNameLength;
  WCHAR FileName[1];      // ← 占位，实际是变长的
} FILE_NOTIFY_INFORMATION;
```

C 里用 `FileName[1]` 占位 + `NextEntryOffset` 串成链表。**Zig 里绝不能这么写**——
`FileName[1]` 会变成一个定长 2 字节的数组，`@sizeOf` 算出来是 14 而不是 12，
而且更致命的是你没法知道下一条记录从哪开始（`NextEntryOffset` 是相对当前记录
起点的字节偏移，而记录起点又是变长的）。

正确做法就是示例里这样：**只声明 3 个 DWORD 的固定头**，文件名单独按
`name_len` 去索引原始字节：

```zig
// examples/28_watch/main.zig 第 533-548 行
    /// 解析变长记录链——RDCW 的全部难点：缓冲区里是**一串不定长记录**，
    /// 每条三个 DWORD 头+ name_len 字节的 UTF-16 文件名，靠 next_offset 串起来。
    fn parseNotifyBuffer(buf: []const u8) usize {
        var count: usize = 0;
        var off: usize = 0;
        while (off + @sizeOf(NotifyInfo) <= buf.len) {
            // ⚠️ 缓冲区按 extern struct 的自然对齐（4）走，不是 1。
            //    少了 @alignCast 会在 debug 模式 panic（unaligned pointer）。
            const rec: *const NotifyInfo = @ptrCast(@alignCast(buf[off..].ptr));
            // 文件名在 [off+12, off+12+name_len)
            if (rec.name_len > 0 and off + @sizeOf(NotifyInfo) + rec.name_len <= buf.len) count += 1;
            if (rec.next_offset == 0) break; // 0 = 链尾
            off += rec.next_offset; // ⚠️ 字节偏移：直接 += ，不是 ++ 也不是 ×12
        }
        return count;
    }
```

四个必须注意的地方：

1. **`@sizeOf(NotifyInfo)` 就是 12**（3 个 `w.DWORD` = 3×4，无填充）。
   用 `extern struct` 而不是 `struct` 很重要——`extern struct` 的字段布局严格按
   C ABI，不会有 `struct` 的自动重排和填充差异。
2. **`off += rec.next_offset`**：`next_offset` 是**到下一条记录的字节偏移**，
   不是"下一条记录索引"。写 `++` 或 `off += 12` 全是错的。而且它是**相对当前记录
   起点的**，所以直接累加到 `off` 上就行。
3. **`next_offset == 0` 是链尾标记**，不是"偏移 0"（那会死循环）。
4. **`@alignCast` 不能省**。`buf` 是 `[]const u8`（对齐 1），
   `buf[off..].ptr` 在 `off` 不是 4 的倍数时可能是未对齐的地址。
   `@ptrCast` 到 `*const NotifyInfo`（对齐 4）需要 `@alignCast` 显式声明对齐。
   在 debug 模式下少了它会 panic（`attempt to cast unaligned pointer`）。

⚠️ 顺带：**缓冲区本身也要按 `@alignOf(NotifyInfo)` 对齐声明**——
`var buffer: [4096]u8 align(@alignOf(NotifyInfo)) = undefined;`。
虽然 cast 处有 `@alignCast` 兜底，但底层 buffer 真的对齐了才不会依赖运行时检查。

**同步版 demo 的完整流程**（`examples/28_watch/main.zig` 第 490-531 行）：

1. `toWide` 把路径转成 NUL 结尾的 UTF-16。
2. `CreateFileW` 开目录句柄。**关键是 `dwFlagsAndAttributes` 必须带
   `FILE_FLAG_BACKUP_SEMANTICS`（0x02000000）**——不加这个，
   `CreateFileW` 打开目录会报 `AccessDenied`（Windows 7 之后的行为）。
   这个标志的语义是"我是一个备份程序，允许在没有读权限时打开目录"。
3. `std.Thread.spawn` 派一个写入线程——**RDCW 只报告"调用之后"发生的变更**，
   所以变更必须在它阻塞期间由别人做。
4. `ReadDirectoryChangesW` 传 `null` OVERLAPPED + `null` 完成例程 = **同步阻塞**，
   一直等到有变更为止。
5. 解析返回的缓冲区（`buffer[0..returned]`——`returned` 是实际填充的字节数，
   **不是**缓冲区容量）。
6. `CloseHandle` 收工（`defer` 保证即使解析失败也会关）。

**`dwShareMode` 要给足**（示例给了
`FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE`）。
只给 `FILE_SHARE_READ` 的话，你的句柄会把目录锁住，其他进程**无法在里面创建/删除文件**
——一个监视器把被监视目录锁死，这是很容易踩的坑。

异步版（`OVERLAPPED` + `CancelIo`）：

```zig
// examples/28_watch/main.zig 第 460-466 行
    /// std 没导出 OVERLAPPED，得自己按 SDK 布局声明（32/64 位都是这四个字段）。
    const OVERLAPPED = extern struct {
        internal: usize,
        internal_high: usize,
        pointer: ?*anyopaque,
        h_event: w.HANDLE,
    };
```

```zig
// examples/28_watch/main.zig 第 550-589 行
    /// 异步模式 + 取消：OVERLAPPED 版的退出姿势。仅编译验证（本机 macOS 跑不了），
    /// 但它示范了两件事：
    ///   ① OVERLAPPED 必须活得比挂起的 RDCW 调用久（栈变量的生命周期陷阱）
    ///   ② CancelIo 让挂起的调用立刻作废——异步模式下的"哨兵文件"等价物
    fn asyncDemo(io: std.Io, dir_path: []const u8) !void {
        const a = std.heap.page_allocator;
        const wpath = try toWide(a, dir_path);
        defer a.free(wpath);

        const dir_handle = CreateFileW(
            wpath.ptr,
            FILE_LIST_DIRECTORY,
            FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
            null,
            OPEN_EXISTING,
            FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED,
            null,
        );
        if (dir_handle == w.INVALID_HANDLE_VALUE) return error.OpenDirFailed;
        defer _ = CloseHandle(dir_handle);

        var ov = std.mem.zeroes(OVERLAPPED); // ⚠️ 必须 zero-init，且必须活到 I/O 收尾
        var buffer: [4096]u8 align(@alignOf(NotifyInfo)) = undefined;
        var returned: w.DWORD = 0;
        _ = ReadDirectoryChangesW(
            dir_handle,
            &buffer,
            buffer.len,
            .FALSE,
            FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_LAST_WRITE,
            &returned,
            @ptrCast(&ov), // 异步：传 OVERLAPPED
            null,
        );
        // 此刻调用已挂起返回。用 CancelIo 撤销它（≈哨兵文件 / Ctrl-C）。
        _ = CancelIo(dir_handle);
        // ⚠️ 真实程序这里要 GetOverlappedResult(..., TRUE) 等 I/O 真正收尾，
        //    否则关句柄时还有未决 I/O。示范到此为止。
        _ = io;
    }
```

⚠️ **`OVERLAPPED` 的生命周期陷阱**：`ov` 是 `asyncDemo` 的**栈变量**。
异步 I/O 挂起期间，Windows 会持有这个结构体的**指针**。如果 `asyncDemo`
在 I/O 完成前返回（栈内存被复用），Windows 就会往一个已被覆写的地址写完成状态——
**栈溢出式破坏，极难调试**。正确做法是把 `OVERLAPPED` 放在**比 I/O 生命周期更长的地方**
（堆分配、或者保证在 `GetOverlappedResult` 返回后才离开作用域）。
这是 Windows 异步 I/O 的头号陷阱，示例用注释标了出来。

⚠️ **必须 `std.mem.zeroes(OVERLAPPED)`**：Windows 用 `Internal` 和
`InternalHigh` 两个字段存状态（`Internal` 存 `PendingReturned` 之类），
未初始化的垃圾值会让 `CancelIo` / `GetOverlappedResult` 行为未定义。

⚠️ **`CancelIo` 之后还差一步**：示例注释里明确写了——
真实程序要调 `GetOverlappedResult(handle, &ov, &n, TRUE)` 等 I/O **真正收尾**，
否则关句柄时还有未决 I/O（`CloseHandle` 会让那些 I/O 全部失败，
表现为莫名其妙的错误码）。这是异步 I/O 的"取消也要收尾"原则——
和 `Io.Group.cancel` 之后"保证所有任务已跑完"是同一种设计哲学。

⚠️ **常量已修正，但这段历史值得留下**：旧版示例把 `FILE_FLAG_OVERLAPPED`
误写成 `0x0200_0000`（与 `FILE_FLAG_BACKUP_SEMANTICS` 同一位），文档最初还
以为"这行没被实际调用，交叉编译抓不到就算了吧"。**Windows 真机一跑立刻现形**：
句柄其实是同步的，RDCW 配上 `OVERLAPPED` 指针照样**同步阻塞等变更**，
演示主程序直接挂死（挂了 12 分钟以上才被强杀）。
正确值是 **`0x4000_0000`**——示例现在是改过的，所以
`FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED` 两个位都在、语义互不覆盖。
教训：**"只编译不运行"的代码也会在某台真机上成为炸弹**，常量抄错这种错
只有真跑才抓得住。

**四个平台的原理速查**（示例的非 Windows 分支也打印了这段，见 `main` 第 826-849 行）：

- **Linux inotify**：`inotify_init1(IN_NONBLOCK)` 拿到一个 fd，
  `inotify_add_watch(fd, path, mask)` 挂上 fd（**一个 fd 可以监视多个路径**），
  `read(fd, buf, len)` 出变长记录（每条
  `struct inotify_event { wd, mask, len, char name[] }`，
  `name` 是 NUL 结尾且 `len` 是**对齐后**的长度）。事件队列有上限，
  满了会返回 `IN_Q_OVERFLOW`，**必须处理**（否则你会静默丢事件）。
  取消：`inotify_rm_watch(fd, wd)` 或关 fd。
- **BSD/macOS kqueue**：`kqueue()` 拿到一个"控制 fd"，
  对**每个要监视的文件** `open()` 出 fd，再
  `EV_SET(&kev, fd, EVFILT_VNODE, EV_ADD, NOTE_WRITE, ...)`。
  **每个文件占一个 fd**——监视 1000 个文件就是 1000 个 fd，
  撞上 `RLIMIT_NOFILE`。而且目录要逐个 `open` + 逐个注册。
  取消：`close(fd)` 或者 `EV_DELETE`。
  **这是 kqueue 和 inotify 最大的结构差异，也是它没被 std 封装的原因之一。**
- **macOS FSEvents**：`FSEventStreamCreate` 传一个 C 回调，
  然后 `FSEventStreamStart` 挂到 `CFRunLoop` 上跑。语义是
  **"目录树在 30 秒左右窗口内的变化合并成一批"**——延迟高，但极省资源。
  适合"备份软件发现变化"，不适合"编辑器要立刻响应"。
  取消：`FSEventStreamStop` + `FSEventStreamInvalidate` + `CFRunLoopRemoveSource`。
- **Windows RDCW**：本节详述。

**静态验证**（这是本节唯一能在本机做的验证）：

```bash
zig build-exe examples/28_watch/main.zig -target x86_64-windows -femit-bin=/tmp/w28.exe
```

实测**编译通过，零输出零错误**。这说明：

- `callconv(.winapi)` 在 0.17 有效；
- `extern "kernel32"` 的四个声明签名与 std 里的 `w.BOOL`/`w.DWORD`/`w.HANDLE` 兼容；
- `FILE_FLAG_*` / `FILE_NOTIFY_CHANGE_*` 常量都是 `w.DWORD`；
- `if (ok == .FALSE)` 的枚举比较成立；
- `extern struct` 的 `NotifyInfo` 和 `OVERLAPPED` 布局能被编译器接受；
- `@ptrCast` / `@alignCast` 的类型链路正确。

**但它证明不了**：返回值语义、`next_offset` 的实际取值、UTF-16 名字的对齐规则、
`CancelIo` 的时序。要验这些必须在 Windows 上跑。

非 Windows 分支除了打印这段说明，还提供了**一个平台无关的解析逻辑**：

```zig
// examples/28_watch/main.zig 第 590-599 行（节选）
} else struct {
    // 非 Windows：整段替换成**同形状的空壳**，main 的调用点不用写平台 if。
    const enabled = false;

    const NotifyInfo = struct {
        next_offset: u32,
        action: u32,
        name_len: u32,
    };
```

`makeRecord` 按 RDCW 的格式手工造一条记录（`examples/28_watch/main.zig`
第 629-639 行），**在 macOS 上喂给同一个 `parseNotifyBuffer`**，
这样"记录链遍历"这段逻辑就被本机测试覆盖了（28.8 的第 11 个测试）。
`parseNotifyBuffer` 本身在 Windows 分支和非 Windows 分支里各写了一遍
（Windows 版用 `w.DWORD`，非 Windows 版用 `u32`），逻辑逐字相同——
**这不是重复代码，是"平台相关的类型 + 平台无关的算法"的分离**。

`makeRecord` 里的 `(total + 3) & ~@as(usize, 3)` 也是真实的 Windows 规则：
`NextEntryOffset` 总是 4 的倍数（记录头 12 字节 + UTF-16 名字按 2 字节对齐，
总长度向上取整到 4）。

---

## 28.8 测试：一个 sleep 都不需要

**轮询逻辑的正确性测试不该依赖时钟。** 这是本章最值得带走的方法论。

"起个线程 → sleep 200ms → 主线程写文件 → 再 sleep 200ms → 检查事件"这种测法：
在本地能过、在 CI 上偶尔超时、慢 10 倍、而且**测不出"到底哪一步错了"**——
事件没出来？是线程没启动？是 sleep 不够？还是求差逻辑本身有 bug？
全都表现为"期望 1 条，实际 0 条"。

本章的测试分三层，**没有一条 sleep**（唯一那条例外是专门验证取消机制的）：

| 层 | 测什么 | 怎么测 | 用时 |
|---|---|---|---|
| 纯函数（28.2） | 三类判据、幂等、空输入 | 手工造两份 `Snapshot.Map` 直接对拍 | 微秒 |
| 磁盘同步（28.3） | `PollWatcher` 的事件序列 | `std.testing.tmpDir` + 同步 `poll()`，磁盘状态自己控制 | 毫秒 |
| 平台逻辑（28.7） | RDCW 记录链解析 | `makeRecord` 造缓冲区喂解析器 | 微秒 |

核心手法在第一个测试里：

```zig
// examples/28_watch/main.zig 第 883-911 行
test "纯求差：created / modified / removed 三类，一个都不少一个都不多" {
    const a = std.testing.allocator;
    var old = Snapshot.Map.init(a); // ⚠️ var 不是 const：put/deinit 都收 *Self
    var new = Snapshot.Map.init(a);
    try putOwned(a, &old, "same", .{ .size = 6, .mtime_ns = 300 });
    try putOwned(a, &old, "gone", .{ .size = 5, .mtime_ns = 200 });
    try putOwned(a, &old, "kept", .{ .size = 4, .mtime_ns = 100 });
    try putOwned(a, &new, "same", .{ .size = 6, .mtime_ns = 300 }); // 完全不动
    try putOwned(a, &new, "kept", .{ .size = 4, .mtime_ns = 999 }); // ⚠️ size 相同，只有 mtime 变
    try putOwned(a, &new, "fresh", .{ .size = 1, .mtime_ns = 400 });

    var evs: std.ArrayList(Event) = .empty;
    var kept = try diffInto(a, old, new, &evs);
    defer {
        for (evs.items) |e| a.free(e.name);
        evs.deinit(a);
        var kit = kept.keyIterator();
        while (kit.next()) |k| a.free(k.*);
        kept.deinit();
    }

    try std.testing.expectEqual(@as(usize, 3), evs.items.len); // same 不出事件
    try std.testing.expect(countKind(evs.items, .modified) == 1);
    try std.testing.expect(countKind(evs.items, .created) == 1);
    try std.testing.expect(countKind(evs.items, .removed) == 1);
    try std.testing.expect(hasEvent(evs.items, .modified, "kept"));
    try std.testing.expect(hasEvent(evs.items, .created, "fresh"));
    try std.testing.expect(hasEvent(evs.items, .removed, "gone"));
}
```

**六个数据点，三条事件，一个"不该出现"的（`same`）。** 没有文件系统、
没有线程、没有时间。整个测试跑在微秒级，而且是**确定性的**——
不存在"CI 上偶发失败"。

⚠️ **断言不能依赖事件顺序。** 下面这个断言在第一版里就红了：

```zig
// ✘ 会红：HashMap 的遍历顺序取决于哈希桶位置
try std.testing.expectEqualStrings("x", evs.items[0].name);
try std.testing.expectEqualStrings("y", evs.items[1].name);
// → expected this output: x␃
//   instead found this: y␃
```

`std.StringHashMap` 的遍历顺序由**键的哈希值**决定（Wyhash），
而"x"和"y"的哈希值在不同的 Zig 版本 / 不同的种子策略下可能落到不同的桶。
**所以测试必须按 (kind, name) 集合断言，不能按下标**：

```zig
// examples/28_watch/main.zig 第 959-966 行
    try std.testing.expectEqual(@as(usize, 2), evs.items.len); // created y + removed x
    // 事件名必须仍可读。如果它借了 old 的键，此刻已是悬空内存——
    // 在 SafeAllocator（std.testing.allocator 的真身）下会被当场抓住。
    // ⚠️ 断言**不能依赖顺序**：`StringHashMap` 的遍历顺序由键的哈希值决定，
    //    换个 Zig 版本、换台机器就可能变。要按 (kind, name) 集合断言。
    try std.testing.expect(hasEvent(evs.items, .created, "y"));
    try std.testing.expect(hasEvent(evs.items, .removed, "x"));
}
```

两个辅助函数就是这个思路的产物（源码在 28.9 的分节里）：

```zig
// examples/28_watch/main.zig 第 1180-1193 行
fn countKind(events: []const Event, kind: EventKind) usize {
    var n: usize = 0;
    for (events) |e| {
        if (e.kind == kind) n += 1;
    }
    return n;
}

fn hasEvent(events: []const Event, kind: EventKind, name: []const u8) bool {
    for (events) |e| {
        if (e.kind == kind and std.mem.eql(u8, e.name, name)) return true;
    }
    return false;
}
```

**这个坑不只在本章。** 你在 12 章（集合）里写过
`for (map.iterator())` 的任何代码，只要配套的测试按下标断言，就都有同样的 flaky 风险。

第二个测试是"内存纪律"的守卫：

```zig
// examples/28_watch/main.zig 第 945-967 行
test "事件名与快照键不共享内存（换血释放了旧键，事件名仍可读）" {
    const a = std.testing.allocator;
    var old = Snapshot.Map.init(a);
    try putOwned(a, &old, "x", .{ .size = 1, .mtime_ns = 1 });
    // new 只有一个**不同的**名字 → 换血时 old 的键 "x" 真的会被free
    var new = Snapshot.Map.init(a);
    try putOwned(a, &new, "y", .{ .size = 1, .mtime_ns = 1 });
    var evs: std.ArrayList(Event) = .empty;
    const kept = try diffInto(a, old, new, &evs);
    defer {
        freeEvents(a, &evs);
        freeOwnedKeys(a, kept);
    }
    try std.testing.expectEqual(@as(usize, 2), evs.items.len); // created y + removed x
    // 事件名必须仍可读。如果它借了 old 的键，此刻已是悬空内存——
    // 在 SafeAllocator（std.testing.allocator 的真身）下会被当场抓住。
    // ⚠️ 断言**不能依赖顺序**：`StringHashMap` 的遍历顺序由键的哈希值决定，
    //    换个 Zig 版本、换台机器就可能变。要按 (kind, name) 集合断言。
    try std.testing.expect(hasEvent(evs.items, .created, "y"));
    try std.testing.expect(hasEvent(evs.items, .removed, "x"));
}
```

**这个测试在 28.2 那段"事件名必须 dupe"没写对的时候会红。**
如果事件名借了 `old` 的键，`diffInto` 末尾的 `freeOwnedKeys(a, old)` 就把它 free 了，
后面读 `evs.items[0].name` 就是 use-after-free——`SafeAllocator` 会当场报出来。
**这就是"内存纪律值得单列一个测试"的理由**：它测的不是功能，是**所有权约定**。

第三个测试（磁盘层）用了 `std.testing.tmpDir`：

```zig
// examples/28_watch/main.zig 第 968-1010 行
test "PollWatcher：tmpDir 上的完整事件序列（同步 poll，无需 sleep）" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var w = PollWatcher.init(a, io, tmp.dir);
    var events: std.ArrayList(Event) = .empty;
    defer {
        for (events.items) |e| a.free(e.name);
        events.deinit(a);
        w.deinit();
    }
    try w.rebase();

    // ① 空目录对基线 → 零事件
    try w.poll(&events);
    try std.testing.expectEqual(@as(usize, 0), events.items.len);

    // ② 新建两个 → created ×2
    try tmp.dir.writeFile(io, .{ .sub_path = "n1.txt", .data = "11" });
    try tmp.dir.writeFile(io, .{ .sub_path = "n2.txt", .data = "22" });
    try w.poll(&events);
    try std.testing.expectEqual(@as(usize, 2), events.items.len);
    try std.testing.expectEqual(@as(usize, 2), countKind(events.items, .created));
    // ⚠️ 同样不能依赖顺序：created 的两条按名字断言
    try std.testing.expect(hasEvent(events.items, .created, "n1.txt"));
    try std.testing.expect(hasEvent(events.items, .created, "n2.txt"));

    // ③ 改n1 + 删 n2 → modified + removed
    try tmp.dir.writeFile(io, .{ .sub_path = "n1.txt", .data = "1" }); // 11 → 1，size 变
    try tmp.dir.deleteFile(io, "n2.txt");
    try w.poll(&events);
    try std.testing.expectEqual(@as(usize, 4), events.items.len);
    try std.testing.expect(hasEvent(events.items, .modified, "n1.txt"));
    try std.testing.expect(hasEvent(events.items, .removed, "n2.txt"));

    // ④ 再poll 一次 → 零新增（幂等）
    try w.poll(&events);
    try std.testing.expectEqual(@as(usize, 4), events.items.len);
    // 只剩 n1.txt（n2 已删）——快照数量本身就是"删除事件已被吃进基线"的证据
    try std.testing.expectEqual(@as(usize, 1), w.watchedCount());
}
```

**为什么磁盘层也不需要 sleep**——因为 `poll()` 是**同步**的：
它扫完、算完、返回。而磁盘状态在 `writeFile` 返回之后就已经确定，
`poll()` 一定能看到。**时序依赖只存在于"另一个线程在两个 poll 之间写文件"，
而这个测试里写文件的就是同一个线程。** 顺序是确定的。

`std.testing.tmpDir` 是这个测试的关键：**它给每个测试一个独立的真实目录**，
`cleanup()` 会连目录带内容一起删掉。用它而不是固定路径（比如 `/tmp/test_watch`）
有两个好处：**测试之间不会互相污染**（上一个测试留下的文件会让下一个的红），
以及**并行跑测试时不会打架**（`std.testing.tmpDir` 内部用原子计数器生成唯一名字）。

⚠️ 主程序 `main` 里**不用** `tmpDir`（那是 test-only 的 API），
而是自己 `createDirPath` + `defer deleteTree` 造沙盒。
示例还刻意把沙盒放在 `/tmp/zig28_watch_demo` 而不是仓库里——
**因为示例是从仓库根运行的**（`build.ps1` 约定），在仓库里造目录会污染 `git status`。
这是 27 章就定下的规矩。

唯一带时间的一条测试专门验证取消机制，因为它**测的就是"能不能打断等待"**：

```zig
// examples/28_watch/main.zig 第 1127-1146 行
test "Io.sleep 是取消点：Group.cancel 能中断一个睡很久的任务" {
    const io = std.testing.io;
    var g: std.Io.Group = .init;
    // ⚠️ `std.Io.Threaded.sleep` **不是 pub**（拿不到 Io 实例也没法选 clock），
    //    所以取消演示必须把 `io` 传进任务里，用 `io.sleep(...)`。
    g.async(io, longSleeper, .{io});
    // 让它真的进入 sleep 再取消
    io.sleep(std.Io.Duration.fromMilliseconds(20), .awake) catch {};
    g.cancel(io);
    // Group.cancel 返回后保证所有任务已跑完——所以下面这个标志一定是 true
    try std.testing.expect(sleeper_finished.load(.acquire));
}

var sleeper_finished = std.atomic.Value(bool).init(false);

fn longSleeper(io: std.Io) void {
    defer sleeper_finished.store(true, .release);
    // 睡一小时：只有取消能提前唤醒它。error.Canceled 在这里被吞掉，任务正常收工。
    io.sleep(std.Io.Duration.fromSeconds(3600), .awake) catch {};
}
```

**这个测试的正确性依赖一个 0.17 的强保证**：`Group.cancel` 返回后，
所有任务**已经真正跑完**（`Io.zig` 第 1424-1428 行："After this function returns,
all tasks of the `Group` ... are guaranteed to have run"）。
所以 `cancel` 之后读 `sleeper_finished` **不需要额外的同步原语**——
`cancel` 本身的"等待所有任务结束"就是同步屏障。

那为什么还要 `std.atomic.Value(bool)`？因为任务在**另一个线程**上跑（`Group.async`
把任务派到 Io 的线程池），`cancel` 的"等待"是通过 futex 实现的，
但从**语言层面**讲，你读一个别的线程写的普通变量是未定义行为。
用 `atomic.Value` + `acquire/release` 是正确写法（这也是本章唯一需要原子操作的地方）。

⚠️ **`std.Io.Threaded.sleep` 不是 pub**（实测报错
`'sleep' is not marked 'pub'`）。它是 `Threaded` 的 vtable 实现函数，
签名是 `fn sleep(userdata: ?*anyopaque, timeout: Io.Timeout) Io.Cancelable!void`——
拿不到 `Io` 实例，所以也不该被直接调用。**任务里要用 `io.sleep(...)`。**

最后一个测试覆盖平台逻辑：

```zig
// examples/28_watch/main.zig 第 1148-1170 行
test "RDCW 记录链解析：手工构造的缓冲区（布局解析是平台无关的）" {
    if (builtin.os.tag == .windows) {
        // Windows 上没有 makeRecord（它在非 Windows 空壳里），这段跳过
        return error.SkipZigTest;
    }
    // 造两条记录：第1 条 next_offset 指向第 2 条，第 2 条 next_offset = 0 是链尾
    var buf: [128]u8 align(4) = undefined;
    const a1 = std.mem.toBytes(@as(u16, 'a')); // "a" 的 UTF-16LE
    const b1 = std.mem.toBytes(@as(u16, 'b')); // "b" 的 UTF-16LE
    const r1 = native.makeRecord(1, &a1, 0, buf[0..]); // 占位，下面重填 next_offset
    const r2 = native.makeRecord(3, &b1, 0, buf[r1..]);
    // 回填第1 条的 next_offset = 第 2 条的起始偏移
    std.mem.writeInt(u32, buf[0..4], @intCast(r1), .little);

    try std.testing.expectEqual(@as(usize, 2), native.parseNotifyBuffer(buf[0 .. r1 + r2]));

    // 链尾next_offset = 0：只解析出第 1 条
    std.mem.writeInt(u32, buf[0..4], 0, .little);
    try std.testing.expectEqual(@as(usize, 1), native.parseNotifyBuffer(buf[0 .. r1 + r2]));

    // 截断的缓冲区：不能越界读，也不能 panic
    try std.testing.expectEqual(@as(usize, 0), native.parseNotifyBuffer(buf[0..4]));
}
```

三个断言：**两条记录的链能走完**、**`next_offset = 0` 是链尾**、
**截断缓冲区不越界**。最后那个特别重要——RDCW 传回来的 `returned` 字节数
**可能不足以凑出一条完整记录**（缓冲区满了、或者记录被截断），
解析器必须靠 `while (off + @sizeOf(NotifyInfo) <= buf.len)` 这个条件停下来，
而不是读越界。**这是解析外部变长数据结构的必备防线。**

⚠️ `return error.SkipZigTest` 是 0.17 里跳过测试的方式（26 章提过
`SkipZigTest` 的变化）。Windows 上跳过是因为 `makeRecord` 定义在
`else` 分支（非 Windows 空壳）里。

---

## 28.9 坑位清单

本章实测踩到的坑，按"踩到时的迷惑程度"排序。

1. ⚠️⚠️⚠️ **`std.HashMap.put` 不复制键**。`getOrPutContext`（`hash_map.zig`
   第 1102-1107 行）里只有一句 `gop.key_ptr.* = key`，键切片被**原样**存进表里。
   把字符串字面量 `put` 进去、再 `free` 它 → `Bus error at address 0x...`，
   崩在 `compiler_rt.zig:601` 的 `memsetSmallPowerOf2` 里，**完全不像内存错误**。
   想拥有键必须**先 `dupe` 再 `put`**。本章的 `putOwned`（`main.zig` 第 67-78 行）
   就是这个坑的解法，`freeOwnedKeys` / `deinitBorrowedKeys` 按所有权分派。

2. ⚠️⚠️⚠️ **0.17 的 `std.Io` 没有任何文件系统事件接口**。`_ = std.Io.Dir.watch;`
   报 `root source file struct 'Io.Dir' has no member named 'watch'`。
   `Io.Event` **不是**文件系统事件（它是个 `enum(u32){unset, waiting, is_set}`
   的可阻塞布尔量）。文件监视在 0.17 **完全没有标准库支持**，
   必须自己按平台分叉。

3. ⚠️⚠️ **`Clock` 枚举没有 `.monotonic`**。0.17 的五个成员是
   `real / awake / boot / cpu_process / cpu_thread`。要"单调"用 `.awake`
   （不含系统睡眠）或 `.boot`（意图上含）。**轮询间隔的 sleep 绝不能用 `.real`**——
   NTP 校时会让它睡出预期外的时长。

4. ⚠️⚠️ **`Io.Event.set(io)` 要 io，`.reset()` 不要**。`set` 可能要执行
   `futexWake`（系统调用，需要 `Io`），`reset` 只是
   `@atomicStore(..., .monotonic)`。这不是笔误，是设计——**能唤醒人的操作要系统调用，
   能改内存的操作不要**。旧版本还要多一个 `wake: bool` 参数，0.17 去掉了。

5. ⚠️⚠️ **`Io.sleep` 的 duration 参数必须用函数构造**。它是 `Io.Duration`
   （`struct { nanoseconds: i96 }`），没有 `.milliseconds` 之类的字段简写，
   只能 `std.Io.Duration.fromMilliseconds(200)`。而且
   `std.Io.Clock.Duration{...}.sleep(io)` 这种**结构体字面量后直接调方法会编译错**
   （`expected ';' after statement`）——必须先绑到 `const` 变量。

6. ⚠️⚠️ **`std.os.windows.BOOL` 是枚举，且没有 `w.TRUE`**。它是
   `Bool(c_int)`，成员是 `FALSE = 0` 和 `_`（非穷尽）。
   所以：比较要写 `.FALSE` 而不是 `== 0`；取真值要写**`w.BOOL.TRUE`** 而不是
   `w.TRUE`（后者报 `root source file struct 'os.windows' has no member named 'TRUE'`）。
   `HANDLE` 是 `*anyopaque`，失败值是 `INVALID_HANDLE_VALUE`（比地址，不是比 null）。

7. ⚠️⚠️ **`HashMap.put` / `deinit` 都收 `*Self`**。所以 `const old = Map.init(a)`
   之后调 `old.put(...)` 报 `expected type '*T', found '*const T'`。
   连锁反应：`diffInto` 的返回值、`try` 表达式的结果都是 `const`，
   要释放它们就不能传 `*Snapshot.Map` 进去。本章的 `freeOwnedKeys` **按值接收**
   正是为了绕开这一点（收进来复制成局部变量再 `deinit`）。

8. ⚠️ **Windows 分支必须整段平台门控**。`callconv(.winapi)` 只在 Windows 目标有定义，
   写在文件顶层的 `extern "kernel32" fn` 在 macOS 上编译不过。
   必须 `if (builtin.os.tag == .windows) struct { ... } else struct { ... }`。
   而且 0.17 的调用约定名是 **`.winapi`，不是 `.win64`**。

9. ⚠️ **`FILE_NOTIFY_INFORMATION` 是变长记录，不能声明成定长**。C 头用
   `WCHAR FileName[1]` 占位，Zig 里这么写会让 `@sizeOf` 变成 14 且无法遍历。
   正确做法：只声明三个 DWORD 的固定头，文件名按 `name_len` 单独索引。
   遍历时 **`off += rec.next_offset`（字节偏移）**，不是 `++`，也不是 `×12`；
   `next_offset == 0` 是链尾。少了 `@alignCast` 会在 debug 模式 panic。

10. ⚠️ **`statFile` 成功时返回 `Io.File.Stat` 值类型，
    不能 `catch |err| switch (err)`**。报
    `incompatible types: 'Io.File.Stat' and 'void'`。
    判断"文件在不在"要用**返回 `void` 的 `dir.access(io, path, .{})`**——
    它的错误集含 `FileNotFound`，而"文件不在"正是答案不是故障。

11. ⚠️ **`Dir.rename` 的 `io` 在最后，`Dir.symLink` 的 `io` 在最前**。
    `box_dir.rename("c.txt", box_dir, "d.txt", io)` ✅ /
    `box_dir.rename(box_dir, "c.txt", box_dir, "d.txt", io)` ❌（说 4 个参数给了 5 个）。
    但 `tmp.dir.symLink(io, "sub", "link", .{})` ✅——同一个文件里两种顺序都会遇到，
    **别记混**。

12. ⚠️ **`Io.File.Permissions` 是非穷尽 enum，不能写 `.{}`**。
    `tmp.dir.createDir(io, "sub", .{})` 报
    `type 'Io.File.Permissions__enum_8' does not support array initialization syntax`。
    正解是具名的 `.default_dir`。（`createDirPath` 的该参数带默认值，所以不用管。）

13. ⚠️ **`statFile` 的 `mtime` 是 `Io.Timestamp` 不是整数**。要写
    `st.mtime.nanoseconds`，直接 `st.mtime` 拿到的是结构体。
    `atime` 是**可选的** `?Io.Timestamp`（有些 FS 拒绝提供），
    读它必须处理 `null`。

14. ⚠️ **同一秒内的同尺寸改写，`mtime` 可能检测不到**——**取决于文件系统**。
    本机 APFS 实测是纳秒级（同尺寸改写的 mtime 增量在 0.1~0.2ms 量级），
    但 HFS+ 是 1 秒、FAT32 是 2 秒。所以指纹必须**同时**带 `size` 和 `mtime`，
    而且要知道：**轮询方案的分辨率上限就是你 `statFile` 能读到的分辨率**。
    FAT32 上的快速同尺寸改写只能用原生 API。

15. ⚠️ **`StringHashMap` 的遍历顺序由哈希值决定，测试不能按下标断言**。
    第一版测试写 `expectEqualStrings("x", evs.items[0].name)` 就是红的
    （`expected x / found y`）。必须按 (kind, name) 集合断言——
    这条对**任何**遍历 map 的测试都成立，不只是本章。

16. ⚠️ **`std.Io.Threaded.sleep` 不是 `pub`**。它是 vtable 实现，
    签名 `fn sleep(userdata, timeout: Io.Timeout)`，拿不到 `Io` 实例。
    取消演示必须把 `io` 传进任务用 `io.sleep(...)`。

17. ⚠️ **格式串里的字面 `{` 要写 `{{`**。示例里那句
    `"只能 fromMilliseconds 这类函数构造——没有 {{f}} 字段简写"` 里有个
    字面 `{f}`（源码里写的是 `{{f}}`），**去掉一层转义就编译不过**。
    报错是 `invalid format string 'f' for type 'bool'`。
    （另：0.17 的 `print` **固定两参数**，没有占位符也要写 `.{}`。）

18. ⚠️ **`OVERLAPPED` 的生命周期必须长于挂起的 I/O**。它是栈变量的话，
    函数返回后 Windows 还持有它的指针——栈内存被复用就是破坏。
    必须堆分配，或保证在 `GetOverlappedResult` 返回后才离开作用域。
    而且必须 `std.mem.zeroes` 初始化（Windows 用 `Internal` 存状态）。
    `CancelIo` 之后还要 `GetOverlappedResult(..., TRUE)` 等 I/O 真正收尾。
    （连带事故：旧版示例把 `FILE_FLAG_OVERLAPPED` 写成 `0x0200_0000`
    （与 `FILE_FLAG_BACKUP_SEMANTICS` 同一位），Windows 真机上句柄其实是同步的，
    RDCW 配 OVERLAPPED 直接**挂死演示主程序**——已修正为 `0x4000_0000`。
    与 win32 教程"RDCW 须 FILE_FLAG_OVERLAPPED 否则同步死锁"同坑。）

19. ⚠️ **`FILE_FLAG_BACKUP_SEMANTICS` 不加，`CreateFileW` 开目录报 AccessDenied**。
    而且 `dwShareMode` 要给足
    （`FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE`）——
    只给 `READ` 会把目录锁住，其他进程无法在里面创建/删除文件。
    **一个监视器把被监视目录锁死**，这是很容易踩的坑。

20. ⚠️ **非 ASCII 路径不能逐字节搬成 UTF-16**。`toWide` 里的
    `for (path, 0..) |c, i| buf[i] = c;` 只对 ASCII 正确。
    含中文的路径必须走 `std.unicode.utf8ToUtf16LeAlloc`，
    否则 `CreateFileW` 报 `FileNotFound` 而你完全看不出真实原因。

21. ⚠️ **哨兵模式和 `Group.await` 不能先后**。`await` 是阻塞的，
    主任务在 `await` 期间没法放哨兵——哨兵永远来不及放。
    正确姿势：把"放哨兵"塞进同一个 `Group`，或在 `await` 之前做掉。
    这个错误在运行时表现为"没看到预期的收工消息"。

22. ⚠️ **沙盒不要留在仓库里**。示例从仓库根运行（`build.ps1` 约定），
    在仓库里造目录会污染 `git status`。本章用 `/tmp/zig28_watch_demo`
    + `defer deleteTree`。

---

上一章：[27 目录遍历与文件树](27-tree.md) · 下一章：[29 TCP 与 UDP](29-networking.md)