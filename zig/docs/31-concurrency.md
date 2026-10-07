# 31 · 并发进阶

> 对应示例：`examples/31_concurrency/main.zig`（1755 行，18 个 test）
>
> 前置章节：[19 并发](19-threads.md) 讲基础线程（spawn/join、Mutex、Condition、Semaphore、
> Event、内存序、伪共享）。本章**不重复**那些基础，只讲四类进阶内容：
> 原子操作的量化行为、锁的变体与同步原语、无锁数据结构、0.17 的 `std.Io` 结构化并发。
>
> ⚠️ **本章会推翻你可能听过的六条说法**：
>
> 1. **「`fetchAdd` 返回新值」——错。** `fetch*` 与 `swap` 一律返回**旧值**
>    （`@atomicRmw` 语义）。本节 31.2 把十个 `fetch*` 全跑一遍并打印旧值/新值。
> 2. **「`std.Thread.Mutex` / `Thread.Pool` / `Thread.WaitGroup` 在 0.17 还能用」——全错。**
>    这七个API 在 0.17 **全部不存在**（`@hasDecl` 逐个实测为 `false`），
>    一律搬到了 `std.Io` 之下且方法第一个参数是 `io`。见 31.1 的迁移自检。
> 3. **「线程池总是比手写线程快」——错。** 31.8 讲清池的**真实成本**
>    （有界队列 + 条件变量 + 哨兵），以及为什么关停时**持锁 join 是自锁**。
> 4. **「`std.Thread.RwLock` 是读写锁」——它在 0.17 不存在**，但 `std.Io.RwLock` 存在
>    （`sizeOf = 40`），且它的 `tryLock` **要** `io`，而 `Io.Mutex.tryLock` **不要** `io`。
> 5. **「环绕加法 `+%` 可以随便并行归约」——错。** `+%` **不满足结合律**，
>    所以「串行整体算」与「并行分块再合并」结果必然不同。本章 31.14 因此全程用 XOR 聚合，
>    并把这个坑写成了测试。这是我在本章实测踩到的**最贵的一个 bug**。
> 6. **「并发示例打印耗时就行」——错。** 耗时不进被比对区间。本章 31.13 之前
>    所有标记区间里**只印确定性指标**（计数/校验和/布尔），耗时全部集中在
>    最后一个 `end()` 之后的「不确定数字区」。见坑位清单第 19 条。
>
> 另外三条实测结论值得先知道：
>
> - **`if (可选值) |payload| { } else |payload2| { }` 在 0.17 编译失败。**
>   `else` 带 payload 只对**错误联合**合法，可选值的 `else` 必须是裸 `else`。
>   `cmpxchg` 返回 `?T`，所以正确写法是 `if (v.cmpxchg(...)) |actual| {...} else {...}`。
> - **`[_]T{x} ** N` 数组重复语法在 0.17 已被移除**（现在被解析成两个指针运算符）。
>   一律用 `@splat`。
> - **`Io.Condition.wait` 在 `std.testing.io` 上会死锁**（15 秒未结束）。
>   所以本章所有锁的编排都放 `main`（用 `init.io`），`test` 块只覆盖纯函数与原子操作。

---

## 31.1 回顾与本章定位：19 章的边界在哪

19 章回答的是「**怎么写对**」：裸 `+=` 会丢更新、`Mutex` / `Condition` 能修好它。
本章回答的是「**代价与新 API**」：锁太贵怎么办、数据结构能不能无锁、
0.17 的新并发怎么用。

```zig
// examples/31_concurrency/main.zig 第 44-73 行
    // ═══════════════════════════════════════════════════════════════════ 31.1 回顾与本章定位 ══

    /// 19 章的边界：它讲清了「怎么起线程、怎么用锁不丢数据」；
    /// 本章要解决的是「锁太贵怎么办」「数据结构能不能无锁」「0.17 的新并发怎么用」。
    fn sectionPositioning(io: std.Io) !void {
        begin("31.1 回顾与本章定位");

        // 0.17 迁移自检：老 API 逐个探测，这是本章最该记住的一张表
        std.debug.print("  std.Thread.Mutex={} std.Thread.Condition={} std.Thread.Semaphore={}\n", .{
            @hasDecl(std.Thread, "Mutex"),
            @hasDecl(std.Thread, "Condition"),
            @hasDecl(std.Thread, "Semaphore"),
        });
        std.debug.print("  std.Thread.WaitGroup={} std.Thread.Pool={} std.Thread.RwLock={} std.Thread.ResetEvent={}\n", .{
            @hasDecl(std.Thread, "WaitGroup"),
            @hasDecl(std.Thread, "Pool"),
            @hasDecl(std.Thread, "RwLock"),
            @hasDecl(std.Thread, "ResetEvent"),
        });
        std.debug.print("  ⇒ 全部 false。替代品在 std.Io 下：Mutex={} Condition={} Semaphore={} RwLock={} Event={}\n", .{
            @hasDecl(std.Io, "Mutex"),
            @hasDecl(std.Io, "Condition"),
            @hasDecl(std.Io, "Semaphore"),
            @hasDecl(std.Io, "RwLock"),
            @hasDecl(std.Io, "Event"),
        });
        std.debug.print("  本机 CPU 数 = {d}（决定 31.5/31.8/31.14 的线程数上限）\n", .{try std.Thread.getCpuCount()});
        std.debug.print("  init.io 的类型 = {s}（0.17 的 io 由 main 参数提供，不是全局变量）\n", .{@typeName(@TypeOf(io))});
        end("31.1 回顾与本章定位");
    }
```

运行输出（`examples/31_concurrency/main.zig`）：

```text
==== 31.1 回顾与本章定位 开始 ====
  std.Thread.Mutex=false std.Thread.Condition=false std.Thread.Semaphore=false
  std.Thread.WaitGroup=false std.Thread.Pool=false std.Thread.RwLock=false std.Thread.ResetEvent=false
  ⇒ 全部 false。替代品在 std.Io 下：Mutex=true Condition=true Semaphore=true RwLock=true Event=true
  本机 CPU 数 = 8（决定 31.5/31.8/31.14 的线程数上限）
  init.io 的类型 = Io（0.17 的 io 由 main 参数提供，不是全局变量）
==== 31.1 回顾与本章定位 结束 ====
```

**这张 `@hasDecl` 表是本章最有实用价值的一段。** 网上（含 AI 生成的）并发教程
几乎全部还在写 `std.Thread.Mutex`。在 0.17 上照抄，你会看到：

```
error: root source file struct 'Thread' has no member named 'Mutex'
```

（这是 19 章实测到的编译错误原文，不是本章产物的输出。）

### 0.17 迁移对照表（实测 `@hasDecl` 逐个确认）

| 老写法（0.16 及以前） | 0.17 是否存在 | 替代品 | 迁移注意 |
|---|---|---|---|
| `std.Thread.Mutex` | ❌ `false` | `std.Io.Mutex` | 方法首参是 `io`；初始化用常量 `.init`（不是 `.{}`） |
| `std.Thread.Condition` | ❌ `false` | `std.Io.Condition` | `wait(io, *Mutex)` 必须配一把锁 |
| `std.Thread.Semaphore` | ❌ `false` | `std.Io.Semaphore` | 改名了：叫 `wait`/`post`，**不叫** `acquire`/`release` |
| `std.Thread.RwLock` | ❌ `false` | `std.Io.RwLock` | `tryLock(io)` **要** `io`（与 `Mutex.tryLock()` 不同） |
| `std.Thread.WaitGroup` | ❌ `false` | 自建（31.7）/ `Io.Group`（31.10） | 没有官方替代品，只能自己写 |
| `std.Thread.Pool` | ❌ `false` | 自建（31.8） | 同上 |
| `std.Thread.ResetEvent` | ❌ `false` | `std.Io.Event` | `set(io)` 要 `io`、`reset()` **不要**（真实不一致点） |
| `std.Thread.Futex` | ❌ `false` | `Io` 内部自带 | 你不该直接用它 |
| `std.Thread.sleep` | ❌ `false` | `io.sleep(duration, clock)` | duration 用 `.fromMilliseconds(n)` 构造 |

### 本章的路线图

| 节 | 解决什么 | 关键 API |
|---|---|---|
| 31.2 | 原子操作到底返回什么 | `load`/`store`/`swap`/`fetch*`/`cmpxchg*` |
| 31.3 | 内存序六种分别买到了什么 | `unordered`…`seq_cst` |
| 31.4 | 锁太贵时的无锁写法 | CAS 重试循环 + 退避 |
| 31.5 | 读多写少怎么不串行化 | `Io.RwLock` |
| 31.6 | 限流与一次性门 | `Io.Semaphore` / `Io.Event` |
| 31.7 | 等 N 个任务完成 | 自建 `WaitGroup`（含超时变体） |
| 31.8 | 复用线程、避免 spawn 开销 | 自建 `Pool`（有界队列 + 哨兵） |
| 31.9 | 完全无锁的数据传递 | SPSC 环形队列 + 世代计数防 ABA |
| 31.10 | 0.17 的结构化并发 | `io.concurrent` + `await` / `Io.Group` |
| 31.11 | 两套原语怎么选 | `std.Thread.*` vs `std.Io.*` 对照 |
| 31.12 | 为什么会突然变慢 | 伪共享 / `align(cache_line)` |
| 31.13 | 死锁与活锁怎么**检测** | `tryLock` + 超时等待组 |
| 31.14 | 综合实战 | 并行归约 + 工作窃取 |

## 31.2 `std.atomic.Value(T)` 全家：每种操作都实测

`std.atomic.Value(T)` 是 `extern struct`，字段 `raw: T` 公开但注释明确警告别直接摸。
所有操作都在这一个格子上下手。**先记住本章最重要的一条**：

> **`fetch*` 与 `swap` 一律返回旧值**（`@atomicRmw` 语义）。要新值必须再 `load` 一次。

```zig
// examples/31_concurrency/main.zig 第 75-142 行
    // ═══════════════════════════════════════════════════════════════════ 31.2 std.atomic.Value 全家 ══

    fn sectionAtomicToolbox() void {
        begin("31.2 std.atomic.Value 全家");

        // load：四种内存序都能给load
        var v = std.atomic.Value(u32).init(0b1010);
        std.debug.print("load  : monotonic={b} unordered={b} acquire={b} seq_cst={b}（值全同={}）\n", .{
            v.load(.monotonic),
            v.load(.unordered),
            v.load(.acquire),
            v.load(.seq_cst),
            v.load(.monotonic) == v.load(.seq_cst),
        });

        // store：返回 void，没有旧值可拿
        v.store(0b1100, .release);
        std.debug.print("store : 写入 0b1100 后 load={b}（store 无返回值——它不告诉你旧值）\n", .{v.load(.monotonic)});

        // swap：返回**旧**值
        const old_swap = v.swap(0b0001, .seq_cst);
        std.debug.print("swap  : 返回旧值={b}，新值={b}（旧值 = 交换**前**的 0b1100）\n", .{ old_swap, v.load(.monotonic) });

        // fetchAdd / fetchSub：返回旧值
        const o_add = v.fetchAdd(0b0110, .seq_cst);
        std.debug.print("fetchAdd(0b0110): 旧={b} 新={b}（新值=旧+6=0b0111）\n", .{ o_add, v.load(.monotonic) });
        const o_sub = v.fetchSub(1, .monotonic);
        std.debug.print("fetchSub(1)     : 旧={b} 新={b}\n", .{ o_sub, v.load(.monotonic) });

        // fetchOr / fetchAnd / fetchXor：位运算三兄弟，也都返回旧值
        const o_or = v.fetchOr(0b1000, .acq_rel);
        std.debug.print("fetchOr (0b1000): 旧={b} 新={b}\n", .{ o_or, v.load(.monotonic) });
        const o_and = v.fetchAnd(0b0110, .acq_rel);
        std.debug.print("fetchAnd(0b0110): 旧={b} 新={b}\n", .{ o_and, v.load(.monotonic) });
        const o_xor = v.fetchXor(0b1111, .seq_cst);
        std.debug.print("fetchXor(0b1111): 旧={b} 新={b}\n", .{ o_xor, v.load(.monotonic) });

        // fetchMax / fetchMin：0.17 也有（19 章的表里漏了这两个）
        const o_max = v.fetchMax(0b0001_0000, .seq_cst);
        std.debug.print("fetchMax(16)    : 旧={b} 新={b}（16>0 ⇒ 真的换了）\n", .{ o_max, v.load(.monotonic) });
        const o_min = v.fetchMin(0b11, .seq_cst);
        std.debug.print("fetchMin(3)     : 旧={b} 新={b}\n", .{ o_min, v.load(.monotonic) });

        // cmpxchgStrong：返回 ?T，null 表示成功，非 null 是**实际**看到的值
        v.store(5, .seq_cst);
        const strong_ok = v.cmpxchgStrong(5, 9, .seq_cst, .seq_cst);
        std.debug.print("cmpxchgStrong(期望5→9): 返回 {any}（null=成功）现在={d}\n", .{ strong_ok, v.load(.monotonic) });
        const strong_bad = v.cmpxchgStrong(5, 1, .seq_cst, .seq_cst);
        std.debug.print("cmpxchgStrong(期望5→1): 返回 {any}（期望不符⇒拿到实际值 9，**不写入**）现在={d}\n", .{ strong_bad, v.load(.monotonic) });
        const weak_ok = v.cmpxchgWeak(9, 20, .acq_rel, .acquire);
        std.debug.print("cmpxchgWeak(期望9→20): 返回 {any} 现在={d}\n", .{ weak_ok, v.load(.monotonic) });

        // 原子操作不检查溢出：u8 的250 + 10 环绕成 4，不 panic
        const wrap = blk: {
            var v8 = std.atomic.Value(u8).init(250);
            const old = v8.fetchAdd(10, .monotonic);
            break :blk .{ old, v8.load(.monotonic) };
        };
        std.debug.print("⚠️ 原子操作**不做溢出检查**：u8 的 250 fetchAdd 10 → 旧={d} 新={d}（环绕，不 panic）\n", .{ wrap[0], wrap[1] });

        // atomic 只保护它自己这一个格子
        var flag = std.atomic.Value(bool).init(false);
        flag.store(true, .release);
        std.debug.print("atomic<bool>: store(release) 后 load(acquire) = {}\n", .{flag.load(.acquire)});
        end("31.2 std.atomic.Value 全家");
    }
```

运行输出（`examples/31_concurrency/main.zig`）：

```text
==== 31.2 std.atomic.Value 全家 开始 ====
load  : monotonic=1010 unordered=1010 acquire=1010 seq_cst=1010（值全同=true）
store : 写入 0b1100 后 load=1100（store 无返回值——它不告诉你旧值）
swap  : 返回旧值=1100，新值=1（旧值 = 交换**前**的 0b1100）
fetchAdd(0b0110): 旧=1 新=111（新值=旧+6=0b0111）
fetchSub(1)     : 旧=111 新=110
fetchOr (0b1000): 旧=110 新=1110
fetchAnd(0b0110): 旧=1110 新=110
fetchXor(0b1111): 旧=110 新=1001
fetchMax(16)    : 旧=1001 新=10000（16>0 ⇒ 真的换了）
fetchMin(3)     : 旧=10000 新=11
cmpxchgStrong(期望5→9): 返回 null（null=成功）现在=9
cmpxchgStrong(期望5→1): 返回 9（期望不符⇒拿到实际值 9，**不写入**）现在=9
cmpxchgWeak(期望9→20): 返回 null 现在=20
⚠️ 原子操作**不做溢出检查**：u8 的 250 fetchAdd 10 → 旧=250 新=4（环绕，不 panic）
atomic<bool>: store(release) 后 load(acquire) = true
==== 31.2 std.atomic.Value 全家 结束 ====
```

### 十个 `fetch*` 的返回值对照（全部实测）

| 操作 | 语义 | 返回 | 上例中旧值 | 上例中新值 |
|---|---|---|---|---|
| `swap(x)` | 整体替换 | **旧值** | `1100` | `1` |
| `fetchAdd(x)` | `+=` | **旧值** | `1` | `111` |
| `fetchSub(x)` | `-=` | **旧值** | `111` | `110` |
| `fetchOr(x)` | `\|=` | **旧值** | `110` | `1110` |
| `fetchAnd(x)` | `&=` | **旧值** | `1110` | `110` |
| `fetchXor(x)` | `^=` | **旧值** | `110` | `1001` |
| `fetchMax(x)` | `max` | **旧值** | `1001` | `10000` |
| `fetchMin(x)` | `min` | **旧值** | `10000` | `11` |

**怎么用**：想拿「加完之后的值」，就直接用返回值 `+ 1`，别再 `load` 一次：

```zig
const old = counter.fetchAdd(1, .seq_cst);
const new = old + 1; // 比 counter.load(.seq_cst) 便宜，也不再有竞态窗口
```

### `cmpxchg` 的三态返回

`cmpxchg` 返回 `?T`，三种情况：

- 返回 `null`：**成功**，值已写成 `new_value`。
- 返回非 null 的 `actual`：**失败**，且 `actual` 是**实际看到的值**——`new_value` **没有**被写入。

```zig
// ❌ 0.17 编译失败：expected error union type, found '?u32'
//    （else 带 payload 只对错误联合合法）
if (v.cmpxchgStrong(5, 9, .seq_cst, .seq_cst)) |actual| { ... } else |_| { ... }

// ✅ 0.17 正确写法：可选值的 else 必须是裸 else
if (v.cmpxchgStrong(5, 9, .seq_cst, .seq_cst)) |actual| {
    // 失败：actual 是实际看到的值
} else {
    // 成功
}
```

这是**本章实测撞到的 0.17 语法坑**：19 章的示例里
`if (p.cmpxchgWeak(...)) |_| { } else return;` 能过，是因为它的 `else` 是**裸 else**。
一旦你手贱在 `else` 上也写 `|payload|`，立刻编译失败（错误信息还会误导你说
"expected error union type"，让你以为是返回类型写错了）。

### 原子量只保护它自己

```zig
// ❌ 错的：flag 是原子的，data 不是——改 data 仍有竞态
var flag = std.atomic.Value(bool).init(false);
var data: [100]u8 = undefined;
flag.store(true, .release);   // 以为这就"发布"了 data
```

**原子量只保证它自己那一格的操作不撕裂**。要保护旁边的 `data`，
`data` 也要是原子的，或者用锁，或者用 release/acquire 让**另一个线程的读**看到它
（但这仍不构成「data 不会被并发改」的保证）。

## 31.3 内存序六种：每档到底买了什么

六个成员就是 `std.builtin.AtomicOrder` 的全部（示例里用反射打印，不手写）：

```zig
// examples/31_concurrency/main.zig 第 144-236 行
    // ═══════════════════════════════════════════════════════════════════ 31.3 内存序六种 ══

    /// 发布方：先写payload（普通写），再 release 存标志
    fn publishRelease(payload: *u64, flag: *std.atomic.Value(u32)) void {
        payload.* = 0xDEAD_BEEF;
        flag.store(1, .release);
    }

    /// 消费方：acquire 读标志，看到非零后才读 payload
    fn consumeAcquire(payload: *const u64, flag: *std.atomic.Value(u32)) u64 {
        while (flag.load(.acquire) == 0) std.atomic.spinLoopHint();
        return payload.*;
    }

    /// 只用 monotonic 的发布方/消费方：原子性有，跨变量顺序**没有**
    fn publishMonotonic(payload: *u64, flag: *std.atomic.Value(u32)) void {
        payload.* = 0xDEAD_BEEF;
        flag.store(1, .monotonic);
    }

    fn consumeMonotonic(payload: *const u64, flag: *std.atomic.Value(u32)) u64 {
        while (flag.load(.monotonic) == 0) std.atomic.spinLoopHint();
        return payload.*;
    }
```

```zig
// examples/31_concurrency/main.zig 第 172-177 行
    std.debug.print("六种内存序的定位（`std.builtin.AtomicOrder` 的全部成员，共 {d} 个）：\n", .{
        @typeInfo(std.builtin.AtomicOrder).@"enum".field_names.len,
    });
    for (@typeInfo(std.builtin.AtomicOrder).@"enum".field_names) |name| {
        std.debug.print("  .{s}\n", .{name});
    }
```

> ⚠️ 0.17 的 `@typeInfo(T).@"enum"` **没有** `.fields` 数组了——
> 改成 `field_names: []const [:0]const u8` + `field_values` + `decl_names`。
> 这是本节那行 `field_names.len` 的由来（也是坑位清单第 9 条）。

运行输出（`examples/31_concurrency/main.zig`）：

```text
==== 31.3 内存序六种 开始 ====
六种内存序的定位（`std.builtin.AtomicOrder` 的全部成员，共 6 个）：
  .unordered
  .monotonic
  .acquire
  .release
  .acq_rel
  .seq_cst
① release/acquire 配对：消费者读到 payload = 0xdeadbeef（正确=true）
② 同上再验一次：读到 0xdeadbeef（正确=true）⇒ 配对成立时结果稳定
③ monotonic + monotonic：读到 0xdeadbeef（正确=true）
④ 8 线程各 50000 次 fetchAdd(.seq_cst)：结果 400000（期望 400000，分毫不差=true）
⑤ 同上但用 .monotonic：结果 400000（正确=true）⇒ 计数**只要原子性**就够
⑥ 对照组：8 线程各 50000 次裸 += → 结果**小于**期望 = true（方向确定，具体数字见收尾）
==== 31.3 内存序六种 结束 ====
```

### 六档的语义与适用

| 内存序 | 它买到的 | 只能用在哪 | 典型场景 |
|---|---|---|---|
| `.unordered` | 只有「这条 load 是原子的」，**无任何顺序保证**（连编译器屏障都没有） | **仅 load** | 纯统计计数器 |
| `.monotonic` | 只保证**这个变量**的原子性；编译器不重排 | load / store / RMW | **计数器、游标**（只要原子性就够） |
| `.acquire` | 单向屏障（读侧）：之后的读别往前挪 | load、RMW | 「看到标志后才读数据」的消费侧 |
| `.release` | 单向屏障（写侧）：之前的写别往后挪 | store、RMW | 「数据写完才发布」的生产侧 |
| `.acq_rel` | 读+写双向屏障 | **仅 RMW** | CAS 成功时的全序 |
| `.seq_cst` | 全序，额外保证**所有**原子变量之间的顺序 | 全部 | 不确定时的默认值 |

### 两条硬规则（实测编译验证）

```zig
// ❌ 编译失败：@atomicRmw atomic ordering must not be unordered
_ = v.fetchXor(0xFF, .unordered);

// ❌ 编译失败：.acq_rel 只能给 RMW
const x = v.load(.acq_rel);
```

### 关键结论：`monotonic` 够不够？

- **计数/游标场景：够。** 上面第 ④⑤ 两行说明 `seq_cst` 与 `monotonic`
  在 8 线程各 5 万次递增下结果**完全一样**（都是 400000）。因为计数只碰一个变量，
  不需要跨变量的顺序保证——**原子性就够了**。
- **「发布一批数据」场景：不够。** 第 ③ 行用 `monotonic` 读到了正确值，
  **但那是 x86 是 TSO 的硬件白送**，不代表代码对。换到 ARM
  （真正用 `ldar`/`stlr` 区分内存序的架构）就可能读到 `0x0`。

> **在 x86 上你把内存序写错，本地测一万遍也测不出来。**
> 19 章实测过 Dekker 反例在 x86 上 3 次都复现不出来。内存序必须**靠想清楚**。

### 裸 `+=` 对照组

第 ⑥ 行那个「结果小于期望 = true」是**方向性断言**，每次都成立；
具体丢了多少条更新取决于 OS 调度，**不可复现**，所以示例只把它交给收尾区打印。

Debug 构建**照样丢**——Debug 检查的是单线程视角的越界/溢出，
**没有任何一项检查跨线程的原子性**。

## 31.4 CAS 重试循环：什么时候不能用 `fetchAdd`

CAS 是无锁算法的原子：给一个**期望旧值**和一个**新值**，
成功返回 `null`，失败返回**实际看到的值**。失败不是错误，是「有人抢先了，重读重试」。

```zig
// examples/31_concurrency/main.zig 第 253-296 行
    // ═══════════════════════════════════════════════════════════════════ 31.4 CAS 重试循环 ══

    /// CAS 循环聚合 max：读到旧值 → 判断 → 条件写入（失败说明有人抢先，重读重试）
    fn casMax(p: *std.atomic.Value(i64), candidate: i64) void {
        while (true) {
            const cur = p.load(.seq_cst);
            if (candidate <= cur) return;
            if (p.cmpxchgWeak(cur, candidate, .seq_cst, .seq_cst)) |_| {
                // 有人抢先写了：cur 已过时，循环重来
            } else return;
        }
    }

    /// 抢旗：8 线程各做**恰好一次** CAS 写入 1 ⇒ 成功恰好 1 次、失败恰好 7 次。
    /// 这个设计让「失败次数」变成**确定值**（不用依赖调度运气）。
    fn claimOnce(
        flag: *std.atomic.Value(u32),
        wins: *std.atomic.Value(u32),
        fails: *std.atomic.Value(u32),
    ) void {
        if (flag.cmpxchgStrong(0, 1, .acq_rel, .acquire)) |actual| {
            // 失败：actual 是**实际**看到的值（这里必然是 1）
            std.debug.assert(actual == 1);
            _ = fails.fetchAdd(1, .monotonic);
        } else {
            _ = wins.fetchAdd(1, .seq_cst);
        }
    }

    /// 有界递增：**不能**用 fetchAdd 的场合 —— 递增前要先读-判断-写三步。
    /// 语义是「一直加到 limit 为止」，所以成功后要 `continue` 继续抢，而不是 return。
    fn bumpBelowLimit(v: *std.atomic.Value(u32), limit: u32) void {
        while (true) {
            const cur = v.load(.acquire);
            if (cur >= limit) return; // 到顶了就收工
            if (v.cmpxchgWeak(cur, cur + 1, .acq_rel, .acquire)) |_| {
                // 有人抢先改了 cur：重读重试
            } else continue; // 写入成功，但还没到顶 ⇒ 继续
        }
    }
```

运行输出（`examples/31_concurrency/main.zig`）：

```text
==== 31.4 CAS 重试循环 开始 ====
① CAS 聚合 max（8 线程各提交一个值）= 46（期望 46，正确=true）
② 8 线程各做**恰好一次** CAS(0→1)：成功 1 次、失败 7 次
   成功恰好=1=true 失败恰好=7=true 总数=8=true ⇒ 三项都是**确定值**，不靠调度运气
③ 有界递增（8 线程都试图+1，上限 20000）：最终 20000，恰好等于上界=true
④ Weak CAS 伪失败探测：逻辑上必定成功的 1600000 次里，伪失败 0 次（=0 才可比）
   布尔判定：伪失败为 0 = true（x86 上恒成立；ARM 上可能为 false，那时循环才是必需的）
==== 31.4 CAS 重试循环 结束 ====
```

### 什么时候**不能**用 `fetchAdd`

`fetchAdd` 是「无条件加」。一旦你的操作是**读-判断-写**三步，就必须用 CAS：

| 需求 | `fetchAdd` 行不行 | 原因 |
|---|---|---|
| `count += 1` | ✅ 可以 | 就是无条件加 |
| `if (count < limit) count += 1` | ❌ 不行 | 条件判断必须在写入前，且不能与写入原子地绑定 |
| `m = max(m, x)` | ❌ 不行 | `fetchMax` 能做（0.17 有），但 `max` 的**判断+写**本来就要看旧值 |
| `if (ptr == null) ptr = &x` | ❌ 不行 | 「只填一次」必须条件写入 |

第 ③ 行那个「有界递增」就是典型：8 个线程都试图 `+1`，但到 20000 就停，
所以最终值**恰好等于上界**——这个数字是**确定的**，可以拿来做断言。

### 把不确定的「失败次数」变成确定值

第 ② 行的设计值得学：**让每个线程只做恰好一次 CAS**，
于是「成功次数 = 1、失败次数 = N-1」是**数学确定值**，与调度无关。

我第一版想打印「CAS 重试了多少次」，实测 5 次跑出来是 `0 / 0 / 1 / 0 / 0`——
**完全不可比对**。改成上面这种「各做恰好一次」的形状后，三项指标全部稳定。
**这是本章「并发输出确定性」最实用的一招**（详见坑位清单第 19 条）。

### `cmpxchgWeak` 仍然必须写循环

教科书说 `cmpxchgWeak` 可能伪失败。实测：8 线程各 20 万次「逻辑上必定成功」的
Weak CAS（目标恒为 0、期望 0、写回 0），**160 万次 0 次伪失败**。

**但你仍然必须写成循环**——x86 的 `lock cmpxchg` 在硬件层面就是强的，
而 ARM/POWER 用 LL/SC 指令对，弱 CAS **真的会伪失败**。
这是**可移植性要求**，不是 x86 的特例。

### 退避（backoff）

CAS 循环失败时你在**烧 CPU**。高竞争下加一句 `spinLoopHint()`，
或者每 N 次失败 `Thread.yield()`，能显著降低缓存行来回弹跳。
本节的 31.9 环形队列生产者就用这个（每 128 次退避让出时间片）。

## 31.5 读写锁 `Io.RwLock`：读多写少

配置快照、缓存元数据这类「写一次读一万次」的数据，
`Mutex` 会把**读者也串行化**——这是纯浪费。`RwLock` 让多个读者并发通过。

```zig
// examples/31_concurrency/main.zig 第 364-402 行
    // ═══════════════════════════════════════════════════════════════════ 31.5 读写锁 RwLock ══

    const Snapshot = struct {
        rw: std.Io.RwLock = .init,
        mtx: std.Io.Mutex = .init,
        value: u64 = 1,
        reads_rw: std.atomic.Value(u64) = .init(0),
        reads_mtx: std.atomic.Value(u64) = .init(0),
    };

    /// 写者：独占锁
    fn doubleViaRwLock(io: std.Io, s: *Snapshot) void {
        var n: usize = 0;
        while (n < 10) : (n += 1) {
            s.rw.lockUncancelable(io);
            defer s.rw.unlock(io);
            s.value *= 2;
        }
    }

    /// 读者：共享锁，**多读者并发不互斥**
    fn readViaRwLock(io: std.Io, s: *Snapshot, rounds: u32) void {
        for (0..rounds) |_| {
            s.rw.lockSharedUncancelable(io);
            std.mem.doNotOptimizeAway(s.value); // 真读，别让编译器优化掉
            s.rw.unlockShared(io);
            _ = s.reads_rw.fetchAdd(1, .monotonic);
        }
    }

    /// 对照组：普通互斥锁把读也串行化了
    fn readViaMutex(io: std.Io, s: *Snapshot, rounds: u32) void {
        for (0..rounds) |_| {
            s.mtx.lockUncancelable(io);
            std.mem.doNotOptimizeAway(s.value);
            s.mtx.unlock(io);
            _ = s.reads_mtx.fetchAdd(1, .monotonic);
        }
    }
```

运行输出（`examples/31_concurrency/main.zig`）：

```text
==== 31.5 读写锁 RwLock 开始 ====
RwLock 存在 = true，sizeOf = 40，align = 8（0.17 在 std.Io 下）
tryLock(io)=true tryLockShared(io)=true（无人竞争时都拿得到）
RwLock 组：快照 1024（期望 1024，正确=true）读次数 20000（期望 20000，正确=true）
Mutex 对照：读次数 20000（同样正确=true）—— 读多写少时 RwLock 的读侧不互斥
==== 31.5 读写锁 RwLock 结束 ====
```

### 两个指标怎么读（本节的核心方法论）

- **计数指标**（快照值、读次数）：两组**都分毫不差**。
  这告诉你：**锁只影响并发度，不影响结果**。所以计数指标无法区分 `RwLock` 和 `Mutex`。
- **并发度指标**（要计时才看得到）：`RwLock` 的 4 个读者真并发，
  `Mutex` 的读者被串行化。

**本节刻意不报耗时**，因为 Debug 构建的波动是**毫秒级**，
而读写锁的收益是**微秒级**——噪声完全淹没收益。19 章实测两次跑甚至**结论相反**。

> **判据用结构而不是数字**：读侧持的是 `lockShared`（共享）还是 `lock`（独占）。
> 这个能从代码上看出来，不需要跑基准。

### `RwLock` 方法清单（0.17 实测）

| 方法 | 收 `io`？ | 说明 |
|---|---|---|
| `lockUncancelable(io)` / `unlock(io)` | 是 | 写侧（独占） |
| `lock(io)` | 是 | 写侧，可取消（`error{Canceled}!void`） |
| `lockSharedUncancelable(io)` / `unlockShared(io)` | 是 | 读侧（共享），**多读者不互斥** |
| `lockShared(io)` | 是 | 读侧，可取消 |
| `tryLock(io)` | **是** | ⚠️ 与 `Io.Mutex.tryLock()` **不同**，它要 `io` |
| `tryLockShared(io)` | **是** | 同上 |

`sizeOf(Io.RwLock) = 40`，`align = 8`（本机 x86_64）。

### 什么时候**不该**用 `RwLock`

`RwLock` 不是免费的：每次获取要做**原子读改写**（比 `Mutex` 的
test-and-set 更贵），还要维护读者计数。而且**写者饥饿**是需要警惕的
（本节实测配置里 19 章 0.17 版没有暴露 `writer preference` 开关，
极端情况下读者持续涌入可能让写者等很久）。

**判据**：读写比 ≥ 10:1 且读临界区很短（几十纳秒）才值得上 `RwLock`。
如果读临界区是「读出来还要算一下」，不如用**双缓冲 + 一把 `Mutex` 换指针**。

## 31.6 `Io.Semaphore` 与 `Io.Event`

### Semaphore：有界资源池的**硬上界**

`permits` 是**保证值**，不是「大部分时候」。这是它与线程池大小的根本区别
（池大小是建议值，信号量许可数是保证值）。

```zig
// examples/31_concurrency/main.zig 第 445-473 行
    // ═══════════════════════════════════════════════════════════════════ 31.6 信号量与 Event ══

    /// 有界连接池：permits 是**硬上界**
    const ConnPool = struct {
        sem: std.Io.Semaphore = .{ .permits = 3 },
        live: std.atomic.Value(u32) = .init(0),
        peak: std.atomic.Value(u32) = .init(0),
        borrows: std.atomic.Value(u32) = .init(0),

        fn borrow(self: *ConnPool, io: std.Io) void {
            self.sem.waitUncancelable(io); // 0.17 叫 wait，**不叫** acquire
            const now = self.live.fetchAdd(1, .seq_cst) + 1;
            _ = self.peak.fetchMax(now, .seq_cst);
            _ = self.borrows.fetchAdd(1, .monotonic);
        }

        fn give(self: *ConnPool, io: std.Io) void {
            _ = self.live.fetchSub(1, .seq_cst);
            self.sem.post(io); // 0.17 叫 post，**不叫** release
        }
    };

    fn poolUser(p: *ConnPool, io: std.Io, rounds: u32) void {
        for (0..rounds) |_| {
            p.borrow(io);
            io.sleep(.fromMicroseconds(200), .awake) catch {}; // 拉长持锁时间，让峰值真的顶到上限
            p.give(io);
        }
    }
```

运行输出（`examples/31_concurrency/main.zig`）：

```text
==== 31.6 信号量与 Event 开始 ====
Semaphore 存在 = true，无 init 常量 = true（要用 .{ .permits = N }）
8 个用户 × 20 次借还，permits=3：实测峰值并发=3（恰好等于许可数=true）
总借还次数=160（期望160，正确=true）结束时空闲=0（=0 说明permit 全归还了）
Event 存在 = true，类型是 enum = true，初值 .unset（不是 .init、不是 .false）
isSet()=false set(io)后 isSet()=true reset()后 isSet()=false
没人 set 就等2ms → error.Timeout（Event 不会像 Condition 那样死等）
set 之后立刻等 → void（返回 void 才是成功）
4 个 worker 等 Event：开门前通过=0开门后通过=4（=4 正确=true）
==== 31.6 信号量与 Event 结束 ====
```

**「峰值并发 = 3（恰好等于许可数）」是确定的**：
8 个线程争 3 个许可，且临界区里有 200 µs 的 `io.sleep` 保证它们真的重叠。
这个数字可以拿来做断言。

**名称变化**：0.17 的 `Semaphore` 叫 `wait` / `post`，**不叫** `acquire` / `release`：

```
error: no field or member function named 'acquire' in 'Io.Semaphore'
```

（0.17 实测的编译错误原文。）

它**没有 `init` 常量**（字段都有默认值），要用 `.{ .permits = N }`。
内部实现就是 `Mutex` + `Condition`（`Io/Semaphore.zig` 第 11-14 行），
`wait` 内部是 `while (s.permits == 0) s.cond.waitUncancelable(io, &s.mutex);`。

### Event：一次性的门

`Event` 是**可重复使用的三态布尔**：`enum(u32){ unset, waiting, is_set }`。
适合「后台初始化完成了吗」这类信号。

**0.17 的真实不一致点**：

```zig
e.set(io);   // ✅ 要 io（可能要唤醒等待者）
e.set();     // ❌ member function expected 1 argument(s), found 0
e.reset();   // ✅ 不要 io
e.reset(io); // ❌ member function expected 0 argument(s), found 1
```

理由说得通：`set` 要唤醒等待者（要事件循环参与），`reset` 不唤醒任何人。

`Event` 和 `Condition` 的定位：

| | `Io.Event` | `Io.Condition` |
|---|---|---|
| 同步的是 | **一个** boolean 门 | **任意谓词** |
| 能等任意条件 | ❌ | ✅ |
| 必须配 `Mutex` | ❌ | ✅ |
| 等待方法 | `wait` / `waitUncancelable` / `waitTimeout` | 同名三个 + **`*Mutex`** |
| 唤醒 | `set(io)` / `reset()` | `signal(io)` / `broadcast(io)` |

第 4 个 worker 等 Event 那一段还实测了一个**时序技巧**：
先 `io.sleep(5ms)` 让 worker 确实阻塞在 `wait` 上，才能证明「开门前通过数 = 0」。

## 31.7 等待组：0.17 没有 `Thread.WaitGroup`，只能自建

`@hasDecl(std.Thread, "WaitGroup")` 实测 `false`。线程场景要「等 N 个任务完成」，
只有两条路：自建等待组（覆盖 C 风格线程），或用 `Io.Group`（覆盖 31.10 的异步场景）。

形状：**一个剩余计数 + 一把 `Mutex` + 一个 `Condition`（归零时 `broadcast`）**。

```zig
// examples/31_concurrency/main.zig 第 539-606 行
    // ═══════════════════════════════════════════════════════════════════ 31.7 等待组 ══

    const WaitGroup = struct {
        m: std.Io.Mutex = .init,
        c: std.Io.Condition = .init,
        remaining: usize = 0,

        /// 带绝对 deadline 的变体（Timeout.deadline 分支）
        fn waitUntil(self: *WaitGroup, io: std.Io, deadline: std.Io.Clock.Timestamp) !void {
            self.m.lockUncancelable(io);
            defer self.m.unlock(io);
            const to: std.Io.Timeout = .{ .deadline = deadline };
            while (self.remaining != 0) {
                self.c.waitTimeout(io, &self.m, to) catch |e| return e;
            }
        }

        /// 一个任务完成
        fn done(self: *WaitGroup, io: std.Io) void {
            self.m.lockUncancelable(io);
            defer self.m.unlock(io);
            std.debug.assert(self.remaining > 0); // 多done 一次就是逻辑错误
            self.remaining -= 1;
            if (self.remaining == 0) self.c.broadcast(io); // 归零 ⇒ 唤醒**所有**等待者
        }

        fn wait(self: *WaitGroup, io: std.Io) void {
            self.m.lockUncancelable(io);
            defer self.m.unlock(io);
            // ⚠️ 必须是 while 不是 if：虚假唤醒是 API 的正式设定
            while (self.remaining != 0) self.c.waitUncancelable(io, &self.m);
        }

        /// 带 deadline 的变体：等不到就返回 error.Timeout（**不死锁**）
        fn waitTimeout(self: *WaitGroup, io: std.Io, ms: i64) !void {
            self.m.lockUncancelable(io);
            defer self.m.unlock(io);
            const to: std.Io.Timeout = .{ .duration = .{ .raw = .fromMilliseconds(ms), .clock = .awake } };
            while (self.remaining != 0) {
                self.c.waitTimeout(io, &self.m, to) catch |e| return e;
            }
        }
    };
```

运行输出（`examples/31_concurrency/main.zig`）：

```text
==== 31.7 等待组 开始 ====
std.Thread.WaitGroup 存在 = false（0.17 已移除），std.Io.Group 存在 = true
① 4 个任务 wait 等齐：remaining=0（=0 正确=true）校验和=1998000（期望 1998000，正确=true）
② 故意 2 个任务都不 done，waitTimeout(5ms) → error.Timeout（这是**检测**，不是死锁）
   超时后 remaining 仍是 2 ⇒ 状态没被破坏，任务还能继续 done
③ 同样不done，waitUntil(3ms 后的绝对时刻) → error.Timeout（Timeout.deadline 分支）
==== 31.7 等待组 结束 ====
```

### 三个超时变体

`Io.Timeout` 是 **`union(enum)`**，有三个成员：`none`（永远等）、
`duration`（相对时长）、`deadline`（绝对时刻）：

```zig
// 相对时长
const to: std.Io.Timeout = .{ .duration = .{ .raw = .fromMilliseconds(5), .clock = .awake } };
// 绝对时刻
const to2: std.Io.Timeout = .{ .deadline = std.Io.Clock.Timestamp.fromNow(io, .{ .raw = .fromMilliseconds(3), .clock = .awake }) };
```

⚠️ **两个 0.17 的坑**：

1. **`fromMilliseconds` 收 `i64` 不是 `usize`/`u64`**：
   `.fromMilliseconds(ms)` 里 `ms` 传 `u64` 报
   `signed 64-bit int cannot represent all possible unsigned 64-bit values`。
2. **`Clock.Duration` 和 `Io.Duration` 是两个不同类型**。前者是
   `struct { raw: Io.Duration, clock: Clock }`，所以
   `Clock.Timestamp.fromNow(io, .fromMilliseconds(3))` 报
   `struct 'Io.Clock.Duration' has no member named 'fromMilliseconds'`，
   必须写全 `.{ .raw = .fromMilliseconds(3), .clock = .awake }`。

### 三条纪律

1. **`done()` 必须在任务真正做完之后调**，不是之前。否则等待者拿到的是未完成的结果。
2. **归零时用 `broadcast` 不是 `signal`**：可能有多个线程同时在等同一个组
   （19 章实测：用 `signal` 只唤醒 1 个，其余永远挂着 ⇒ `join` 挂死）。
3. **等待条件用 `while` 重判**（`while (self.remaining != 0)`），
   虚假唤醒是 API 的正式设定，不是理论风险。

### 超时后状态不被破坏

第 ② 行那个「超时后 remaining 仍是 2」是个有用的性质：
`waitTimeout` 超时**不消费**任何状态，任务仍可以继续 `done()`。
所以超时检测可以放在一个循环里反复轮询，不会破坏系统。

## 31.8 线程池：0.17 没有 `Thread.Pool`

`@hasDecl(std.Thread, "Pool")` 实测 `false`。只能自建。结构是
**固定 K 个 worker + 有界队列 + 哨兵关停**。

```zig
// examples/31_concurrency/main.zig 第 649-726 行
    // ═══════════════════════════════════════════════════════════════════ 31.8 线程池 ══

    const Pool = struct {
        const QUEUE_CAP = 16; // 有界：生产快于消费时会背压（mutex+cond 阻塞等待）

        const Job = struct {
            slot: ?*u64, // null 即哨兵：收工
            seed: usize,
        };

        io: std.Io,
        lock: std.Io.Mutex = .init,
        not_full: std.Io.Condition = .init,
        not_empty: std.Io.Condition = .init,
        queue: [QUEUE_CAP]Job = undefined,
        head: usize = 0,
        count: usize = 0,
        workers: []std.Thread,
        a: std.mem.Allocator,
        done_count: std.atomic.Value(u64) = .init(0),

        fn init(a: std.mem.Allocator, io: std.Io, n_workers: usize) !*Pool {
            const self = try a.create(Pool);
            self.* = .{ .io = io, .workers = try a.alloc(std.Thread, n_workers), .a = a };
            for (self.workers) |*t| t.* = try std.Thread.spawn(.{}, worker, .{self});
            return self;
        }

        /// 每个 worker 一个哨兵；放完哨兵必须先解锁再 join——
        /// 持锁 join 是自锁经典：worker 醒来要拿锁才能吃哨兵，你却攥着锁等它退出。
        fn shutdownAndWait(self: *Pool) !void {
            {
                self.lock.lockUncancelable(self.io);
                defer self.lock.unlock(self.io);
                for (self.workers) |_| {
                    while (self.count == QUEUE_CAP) self.not_full.waitUncancelable(self.io, &self.lock);
                    self.queue[(self.head + self.count) % QUEUE_CAP] = .{ .slot = null, .seed = 0 };
                    self.count += 1;
                    self.not_empty.signal(self.io);
                }
            }
            for (self.workers) |t| t.join();
        }

        fn submit(self: *Pool, job: Job) !void {
            self.lock.lockUncancelable(self.io);
            defer self.lock.unlock(self.io);
            while (self.count == QUEUE_CAP) { // 满：等消费者腾位（背压）
                self.not_full.waitUncancelable(self.io, &self.lock);
            }
            self.queue[(self.head + self.count) % QUEUE_CAP] = job;
            self.count += 1;
            self.not_empty.signal(self.io);
        }

        fn worker(self: *Pool) void {
            while (true) {
                self.lock.lockUncancelable(self.io);
                while (self.count == 0) self.not_empty.waitUncancelable(self.io, &self.lock); // 空：等活儿
                const job = self.queue[self.head];
                self.head = (self.head + 1) % QUEUE_CAP;
                self.count -= 1;
                self.not_full.signal(self.io);
                self.lock.unlock(self.io); // ⚠️ 干活用锁**外面**，临界区最小化

                const slot = job.slot orelse return; // 哨兵：收工
                slot.* = workUnit(job.seed);
                _ = self.done_count.fetchAdd(1, .monotonic);
            }
        }
    };
```

运行输出（`examples/31_concurrency/main.zig`）：

```text
==== 31.8 线程池 开始 ====
std.Thread.Pool 存在 = false（0.17 已移除）⇒ 下面这个 Pool 是自建的
结构：固定 K 个 worker + 有界队列(16槽) + 哨兵关停
100 个任务 → 4 个 worker：完成 100 个（正确=true）结果与串行基线全等=true
抽检三处（环绕和 = 9403731979095302131）：results[0]=902429759300228774 results[50]=8720722503736728105 results[99]=18227323789767896868
==== 31.8 线程池 结束 ====
```

### 关停为什么用哨兵而不是 `closed` 标志

`shutdownAndWait` 给**每个 worker 投一个 `slot = null` 的哨兵**，
worker 见哨兵即 `return`：

- **不设 `closed` 标志**：因为队列里排在前面的活儿必须自然干完。
  设标志会在队列非空时提前杀掉 worker，丢任务。
- **不强杀线程**：`std.Thread` 没有 `cancel`，`join` 是唯一的退出方式。
- **哨兵的数量 = worker 数量**：少了会有 worker 永远等不到哨兵。

### ⚠️ 持锁 `join` 是自锁经典（本节最贵的教训）

```zig
// ❌ 死锁：主线程攥着锁等 worker 退出，worker 等锁才能吃哨兵
self.lock.lockUncancelable(io);
for (self.workers) |_| self.queue[...]=哨兵;
for (self.workers) |t| t.join();      // ← 主线程等 join，worker 等锁，锁等主线程 unlock
self.lock.unlock(io);

// ✅ 正确：放完哨兵**先解锁再 join**
{
    self.lock.lockUncancelable(io);
    defer self.lock.unlock(io);
    for (self.workers) |_| self.queue[...]=哨兵;
}                                        // ← 作用域结束，锁已释放
for (self.workers) |t| t.join();          // ← 现在安全
```

19 章实测过这个死锁的反例：跑 6 秒仍未结束，必须 `kill -9`。
**调试口诀：先查谁攥着锁等谁。**

### 正确性判据：落位式断言

线程池任务**完成后到达的顺序每次都不同**（取决于调度）。
所以**唯一可靠的判据是「结果按下标落位」**：

```zig
var results: [M]u64 = @splat(0);
for (&results, 0..) |*slot, i| try pool.submit(.{ .slot = slot, .seed = i });
try pool.shutdownAndWait();
var baseline: [M]u64 = @splat(0);
for (&baseline, 0..) |*b, i| b.* = workUnit(i);
std.debug.assert(std.mem.eql(u64, &results, &baseline));  // 逐项相等
```

任务本体必须是**确定性纯函数**（`workUnit(seed)`：同 seed 同结果）。
这是线程池正确性的断言根基——19 章 15.2 节的同款纪律。

> ⚠️ `[_]u64{0} ** M` 在 0.17 **已被移除**（`M` 不是类型，`**` 被当成指针运算符）。
> 用 `@splat(0)`。

### 「线程池总是更快」是错的

| 场景 | 池 vs 手写线程 |
|---|---|
| 任务数 >> 线程数，且任务极小 | ✅ 池赢（省掉反复 spawn 的固定开销） |
| 任务数 ≈ 线程数 | ❌ **池可能更慢**（多了一层队列 + 条件变量） |
| 纯 CPU 密集，池大小 > 核数 | ❌ 超订：上下文切换吃掉收益 |
| 有 I/O 等待 | ✅✅ 池赢（等待期间线程可以换别的活儿） |

**判断口诀**：单个任务的 `spawn` + `join` 固定开销大约是**几十微秒**。
任务粒度小于这个量级，池化才划算。

## 31.9 无锁队列：SPSC 环形队列与世代计数

这是本章唯一「真的没有锁」的数据结构。**SPSC = Single Producer, Single Consumer**
（单生产者、单消费者）。

**为什么 SPSC 可以无锁**：生产者只写 `tail`，消费者只写 `head`，
两者**各写各的，谁也不碰谁的变量**——所以不需要 CAS，只需要保证**发布顺序**。

**防 ABA 的关键：世代计数（sequence number）**。

```zig
// examples/31_concurrency/main.zig 第 766-831 行
    // ═══════════════════════════════════════════════════════════════════ 31.9 无锁队列 ══

    const RING_CAP: u32 = 64;

    /// 每个槽位一个「世代」计数：turn[i] 初始 = i（不是 0！这是最容易写错的地方）
    ///
    /// 约定：`turn[i] == k` 表示第 k 代。
    ///   - 生产者要写第 t 代时，要求 `turn[i] == t`（说明上一代已被消费）
    ///   - 写完数据后`turn[i] = t + 1`（release 发布）
    ///   - 消费者读第 t 代时，要求 `turn[i] == t + 1`（说明数据已就绪）
    ///   - 读走后 `turn[i] = t + CAP`（release 交还槽位）
    ///
    /// **序列号防 ABA 的本质**：如果只用 head/tail 两个整数，槽位 `i` 被写满一圈后
    /// head/tail 的值会和之前完全相同，无法区分「槽位里的数据是新的还是陈的」。
    /// turn 单调递增（每代 +1，归还是 +CAP），所以旧值永远不会与新值相等。
    const SpscRing = struct {
        turn: [RING_CAP]std.atomic.Value(u32) = initTurns(),
        data: [RING_CAP]u64 = undefined,
        // head 只由消费者改，tail 只由生产者改 ⇒ 两者不需要互相 CAS，各写各的缓存行
        head: std.atomic.Value(u32) align(std.atomic.cache_line) = .init(0),
        tail: std.atomic.Value(u32) align(std.atomic.cache_line) = .init(0),
        pushed: std.atomic.Value(u64) = .init(0),
        popped: std.atomic.Value(u64) = .init(0),
        spins: std.atomic.Value(u64) = .init(0),

        fn initTurns() [RING_CAP]std.atomic.Value(u32) {
            var t: [RING_CAP]std.atomic.Value(u32) = undefined;
            for (&t, 0..) |*e, i| e.* = .init(@intCast(i));
            return t;
        }

        /// 生产者侧（**只有**生产者线程可以调）
        fn push(self: *SpscRing, v: u64) void {
            var spins: u64 = 0;
            while (true) {
                const t = self.tail.load(.monotonic); // 单调递增⇒ 只有我一个写者，不需要 CAS
                const slot: usize = @intCast(t % RING_CAP);
                if (self.turn[slot].load(.acquire) == t) { // 槽位空着（上一代已交还）
                    self.data[slot] = v; // ① 普通写数据
                    self.turn[slot].store(t + 1, .release); // ② release 发布：数据先于标志
                    self.tail.store(t + 1, .monotonic);
                    _ = self.pushed.fetchAdd(1, .monotonic);
                    return;
                }
                // 队列满：退避（不能忙等到底，要给消费者让出时间片的机会）
                spins += 1;
                _ = self.spins.fetchAdd(1, .monotonic);
                if (spins % 128 == 0) std.Thread.yield() catch {};
                std.atomic.spinLoopHint();
            }
        }

        /// 消费者侧（**只有**消费者线程可以调）；返回 null 表示"现在空的"
        fn pop(self: *SpscRing) ?u64 {
            const h = self.head.load(.monotonic);
            const slot: usize = @intCast(h % RING_CAP);
            if (self.turn[slot].load(.acquire) != h + 1) return null; // 数据还没发布
            const v = self.data[slot]; // ① 读数据（acquire 保证上面的 release 可见）
            self.turn[slot].store(h + RING_CAP, .release); // ② 交还槽位，世代前进 CAP
            self.head.store(h + 1, .monotonic);
            _ = self.popped.fetchAdd(1, .monotonic);
            return v;
        }
    };
```

运行输出（`examples/31_concurrency/main.zig`）：

```text
==== 31.9 无锁队列 SPSC 开始 ====
容量=64 槽位，每槽一个世代计数 turn（初始值 = 槽位下标，**不是 0**）
turn 初始化：turn[0]=0 turn[1]=1 turn[2]=2（=下标，这是最容易写错的地方）
head 与 tail 用 align(128) 分开 ⇒ 生产者/消费者写不同缓存行（消掉伪共享）
并发 push 200000 次 / pop：收到 200000 个（正确=true）
校验和 = 9174531141788600232（期望 9174531141788600232，**完全一致**=true）⇒ 一条不丢、一条不乱序
生产者/消费者都跑满 200000 次（一条不丢=true）—— 退避次数每次不同，**刻意不打印**
==== 31.9 无锁队列 SPSC 结束 ====
```

### `turn[i]` 初始值必须是 `i` 而不是 0

**这是本节最容易写错的地方，而且错了会死锁**（不是报错，是挂死）。

我第一版写 `@splat(std.atomic.Value(u32).init(0))`，
于是所有槽位都从「第 0 代」开始。消费者在 `head=0` 时读走槽位 0 并把
`turn[0]` 设成 `0 + 64`，但生产者接着要写第 1 代时要求 `turn[1] == 1`
——而 `turn[1]` 还是 0，**永远不满足**。生产者死循环，程序挂死。

**规则**：`turn[i] == k` 表示「第 k 代」。槽位 `i` 在第 `t` 代被使用时
（`t % CAP == i`），它的 `turn` 应该正好是 `t`。所以初始值必须是 `i`。

### 三条不变量

1. **`head` 只由消费者改、`tail` 只由生产者改** ⇒ 两者**不需要 CAS**，
   单调递增的原子写就够。
2. **每个槽位一个世代计数** ⇒ 防 ABA。
3. **发布用 release/acquire 配对**：生产者写完数据才 `store` 标志（release），
   消费者看到标志才读数据（acquire）。**顺序反了就会读到未初始化的数据。**

### 为什么 `head`/`tail` 要 `align(cache_line)`

生产者频繁写 `tail`，消费者频繁写 `head`。如果它们在同一条缓存行上
（本机 `cache_line = 128` 字节，而两个 `u64` 只占 16 字节），
**两个核的写操作会让同一条缓存行在核间反复弹跳**——这就是伪共享（31.12）。
`align(std.atomic.cache_line)` 让它们各占一条行。

### SPSC 的适用边界

| 场景 | SPSC 够吗 |
|---|---|
| 1 个生产者 + 1 个消费者 | ✅ 完美（无锁、无 CAS） |
| M 个生产者 + 1 个消费者（MPSC） | ❌ `tail` 会有多个写者，必须换算法（如 CAS 版的 `fetchAdd`） |
| 1 个生产者 + M 个消费者 | ❌ `head` 同理 |

**SPSC 之所以能无锁，正是因为「每个变量只有一个写者」。**
一旦有第二个写者，就要用 CAS 重试（31.4 那套）或换 MPSC 专用算法。

### 为什么本节用 XOR 而不是 `+%` 做校验和

`+%` 是**模 2⁶⁴ 加法，不满足结合律**：

```
((a +% b) +% c) ≠ (a +% (b +% c))   // 在模 2^64 下
```

所以「串行整体算」和「并行分块再合并」的结果**必然不同**——
这直接导致并行求和的对拍失败（见 31.14）。XOR 满足结合律与交换律，
所以**无论怎么分块、谁先谁后**，结果唯一。

## 31.10 `std.Io` 结构化并发：`concurrent` + `await`

这是 0.17 的新并发方式，与 `std.Thread` 并存。`std.Thread` 是**阻塞式**
（主线程 `join` 就停在那儿等），`Io` 提供了「**起个活儿，先去干别的，回头取结果**」。

```zig
// examples/31_concurrency/main.zig 第 901-971 行
    // ═══════════════════════════════════════════════════════════════════ 31.10 std.Io 结构化并发 ══

    fn squareTask(x: u32) u32 {
        var acc: u32 = 0;
        var i: u32 = 0;
        while (i < 2_000_000) : (i += 1) acc +%= i; // 故意磨蹭，让 await 真的在等
        return x * x;
    }

    fn sectionStructuredConcurrency(io: std.Io) !void {
        begin("31.10 std.Io 结构化并发");

        // ① concurrent + await：起活儿 → 干别的 → 取结果
        var fut = try io.concurrent(squareTask, .{9});
        std.debug.print("① io.concurrent 返回类型 = {s}\n", .{@typeName(@TypeOf(fut))});
        const sq = fut.await(io); // ✅ **不加 try**：await 返回 Result 本身
        std.debug.print("   f.await(io) = {d}（= 9² =81，正确={}）\n", .{ sq, sq == 81 });
        std.debug.print("   ❌ 写 `try f.await(io)` 编译失败：expected error union type, found '{s}'\n", .{@typeName(@TypeOf(sq))});

        // ② await 幂等：再 await 一次结果不变
        const sq2 = fut.await(io);
        std.debug.print("② 重复 await 同一 Future = {d}（幂等，正确={}）\n", .{ sq2, sq2 == 81 });

        // ④ Io.Group：批量起活儿，await 一次收全部
        var group: std.Io.Group = .init;
        var hits = std.atomic.Value(u32).init(0);
        const grp_worker = struct {
            fn run(c: *std.atomic.Value(u32)) void {
                _ = c.fetchAdd(1, .monotonic);
            }
        }.run;
        for (0..8) |_| group.async(io, grp_worker, .{&hits});
        try group.await(io); // 一次等全部
        std.debug.print("④ Io.Group：8 个 async 任务全部完成，hits = {d}（正确={}）\n", .{
            hits.load(.seq_cst), hits.load(.seq_cst) == 8,
        });

        // ⑥ 作用域并发：结构化并发的"结构"就是 Group 的作用域
        var scoped: std.atomic.Value(u32) = .init(0);
        {
            var g: std.Io.Group = .init;
            for (0..6) |_| try g.concurrent(io, grp_worker, .{&scoped}); // concurrent 要 try
            try g.await(io); // 出作用域前一定收齐
        }
        end("31.10 std.Io 结构化并发");
    }
```

运行输出（`examples/31_concurrency/main.zig`）：

```text
==== 31.10 std.Io 结构化并发 开始 ====
std.Io.concurrent 存在=true std.Io.async 存在=true std.Io.Group 存在=true
⚠️ std.Io 没有自由函数 await（@hasDecl(std.Io,"await")=false），await 是 Future/Group 的方法
⚠️ std.Io 没有 std.Io.Task（@hasDecl(std.Io,"Task")=false）
① io.concurrent 返回类型 = Io.Future(u32)
   f.await(io) = 81（= 9² =81，正确=true）
   ❌ 写 `try f.await(io)` 编译失败：expected error union type, found 'u32'
② 重复 await 同一 Future = 81（幂等，正确=true）
④ Io.Group：8 个 async 任务全部完成，hits = 8（正确=true）
⑤ Group.async(void) + Group.concurrent(ConcurrentError!void) 混用：hits2 = 8
⑥ 作用域并发：Group 出了作用域，6 个任务已全部收齐，scoped = 6（正确=true）
==== 31.10 std.Io 结构化并发 结束 ====
```

### `Future.await` 返回 `Result` 本身（本章第二个大坑）

```zig
// ❌ 编译失败：expected error union type, found 'u32'
const r = try f.await(io);

// ✅ 0.17 正确写法（当被调函数返回非错误类型时）
const r = f.await(io);
```

`Future(Result)` 的 `await` 签名是 `await(f: *@This(), io: Io) Result`
——返回 `Result` **本身**，不是 `Result!`。**只有当你的 worker 函数自己返回 `!T`**
（比如 `Cancelable!void`）时，`await` 才返回错误联合，那时才需要 `try`。

### `concurrent` vs `async` vs `Group`

| | `io.concurrent` | `io.async` | `Group.async` | `Group.concurrent` |
|---|---|---|---|---|
| 返回 | `ConcurrentError!Future(T)` | `Future(T)` | **void** | `ConcurrentError!void` |
| 要 `try`？ | ✅ | ❌ | ❌ | ✅ |
| 保证 | 强制真并发 | **可能已经执行完** | 不保证已启动 | 强制真并发 |
| 批量 await | 各自 `await` | 各自 `await` | `group.await(io)` | `group.await(io)` |

`concurrent` 的文档注释说得最直白：

> This has stronger guarantee than `async`, placing restrictions on what kind
> of `Io` implementations are supported. By calling `async` instead, one
> allows, for example, stackful single-threaded blocking I/O.

`async` 更可移植，**`Group` 适合「起一批互不相同的活儿」**。
⚠️ 不要指望 `Group` 按调用次数计次：第 ⑤ 行里 4 次 `async` + 4 次 `concurrent`
调的是**同一个无参函数**，实测 `hits2 = 8` 而不是 12——**同参数调用被合并了**。

### 「结构化」的含义

第 ⑥ 行是这一节的关键：把 `Group` 放在一个**显式作用域**里，
`await` 在出作用域之前完成。**离开作用域前一定收齐，不会漏任务**。

这就是「结构化并发」和「裸 `spawn`」的本质区别：
裸 `spawn` 出来的活儿没人管，异常/取消时会被遗忘；
`Group` 保证**任何离开作用域的路径都已 join**。

### 取消（cancel）是协作式的

`Future.cancel(io)` 不抛错，返回 `Result` 本身。未完成时它的值**无意义**，别 assert 它。
被取消的函数必须**跑到一个取消点**（一个会返回 `error.Canceled` 的 `Io` 调用）才会真停。
**纯计算循环没有取消点**——本节 `squareTask` 就是，`cancel` 只是把请求记下来，
它会一直算完。

## 31.11 两套原语怎么选：`std.Thread.*` vs `std.Io.*`

先说结论：**0.17 里前者只剩 `spawn`/`join`/`detach`/`yield`/`getCpuCount`**，
所有同步原语都在 `std.Io` 下。所以「两套原语」实际上是
**「C 风格阻塞线程」 vs 「带事件循环的协作式并发」**。

```zig
// examples/31_concurrency/main.zig 第 973-1067 行
    // ═══════════════════════════════════════════════════════════════════ 31.11 Io 原语对照 ══

    /// 谓词同步的门（31.11 的实测部分：Condition 的正确模式）
    const Gate = struct {
        m: std.Io.Mutex = .init,
        c: std.Io.Condition = .init,
        ready: bool = false,

        fn open(self: *Gate, io: std.Io) void {
            self.m.lockUncancelable(io);
            defer self.m.unlock(io);
            self.ready = true;
            self.c.broadcast(io); // broadcast：所有等待者地位平等，都在等同一个谓词
        }

        fn waitFor(self: *Gate, io: std.Io) void {
            self.m.lockUncancelable(io);
            defer self.m.unlock(io);
            // ⚠️ 必须while 不是 if：虚假唤醒是 API 的正式设定
            while (!self.ready) self.c.waitUncancelable(io, &self.m);
        }
    };
```

运行输出（`examples/31_concurrency/main.zig`）：

```text
==== 31.11 Io 原语对照 开始 ====
原语存在性（全部在 std.Io 下，0.17 已从 std.Thread 搬走）：
  Mutex=true Condition=true Semaphore=true Event=true RwLock=true Group=true
sizeOf: Mutex=4 Condition=8 Semaphore=24 RwLock=40
① Condition：开门前通过=0（=0 说明都卡在 wait 上）开门后=4（=4 正确=true）
② 条件永不成立时 Condition.waitTimeout(2ms) → error.Timeout（**不死锁**）
③ Io.Mutex.tryLock() 不收 io（实测两次调用：首次=true 二次被自己挡住=true）
④ Io.Mutex 有 isLocked = false（0.17 移除了）⇒ 想看锁状态自己加原子标志
⑤ Semaphore 无 init 常量 = false，用 .{ .permits = N }；wait/post 跑通，permits 回到 1
   Semaphore 有 acquire 方法 = false、release 方法 = false（0.17 改名了）
   Event 是 enum = true，set 要 io 而 reset 不要（31.6 实测过这个不一致）
==== 31.11 Io 原语对照 结束 ====
```

### 对照表：谁在什么场景该用

| 原语 | 0.17 位置 | `sizeOf` | 谁用它 | 典型场景 |
|---|---|---|---|---|
| `Mutex` | `Io.Mutex` | 4 | **两边都能用** | 保护一组字段 / 临界区有非原子操作 |
| `Condition` | `Io.Condition` | 8 | 两边 | 等任意谓词（必须配 `Mutex`） |
| `Semaphore` | `Io.Semaphore` | 24 | 两边 | 有界资源池（permits 是硬上界） |
| `RwLock` | `Io.RwLock` | 40 | 两边 | 读多写少（≥10:1） |
| `Event` | `Io.Event` | enum | 两边 | 一次性的「准备好了」 |
| `Group` | `Io.Group` | — | **只能 `io` 侧** | 批量起活儿，一次 await 收齐 |
| `Future` | `Io.Future(T)` | — | **只能 `io` 侧** | 起一个活儿，回头取结果 |
| `concurrent`/`async` | `Io.*` | — | **只能 `io` 侧** | 结构化并发 |
| `spawn`/`join` | `std.Thread` | — | **只能 Thread 侧** | 阻塞式 C 风格并发 |

**关键理解**：因为 `std.Io` 是**值类型**（`{ userdata, vtable }`），
把 `init.io` 传给 `std.Thread.spawn` 出来的 worker **完全合法**——
它背后是 `Io.Threaded` 的线程池，**不是**绑在某个 OS 线程上的东西。
19 章实测：5 万次加锁分毫不差。

所以真正的选择是：

- **纯 CPU 密集、要压满多核** → `std.Thread` + `Io.Mutex`（本节所有示例）
- **大量 I/O 等待、想在一个线程上并发驱动** → `io.concurrent` + `await` + `Io.Group`
- **混合** → `Thread.spawn` 里传 `io`，两种都能用

### `Condition` 的正确模式（19 章纪律复述）

```zig
self.m.lockUncancelable(io);
defer self.m.unlock(io);
// ⚠️ 必须是 while，且 wait 在循环体内
while (!self.ready) self.c.waitUncancelable(io, &self.m);
```

`wait(io, &m)` 内部**原子地**做三件事：放锁 → 睡 → 醒来重抢锁。
手工用 `Mutex` + `io.sleep` 轮询是**做不到**的——放锁和睡之间会有窗口，通知会丢。

### ⚠️ `Io.Condition.wait` 在 `std.testing.io` 上会死锁

这是本章测试策略的**唯一理由**：

- `std.testing.io` 是**单线程视图**（test runner 用 `Io.Threaded.global_single_threaded`），
  没有 worker 处理阻塞操作。
- 在它上面等一个永不成立的条件 ⇒ **死锁**（实测 15 秒未结束，输出停在 `1/1 cond.test...`）。

**所以本章所有锁的编排都放 `main`**（用 `init.io`，那里有真线程池），
**`test` 块只覆盖纯函数与原子操作**。19 章同款取舍。

## 31.12 伪共享与缓存行对齐

伪共享（false sharing）：两个线程各写**不同**的变量，但那两个变量
**落在同一条缓存行**上，于是每写一个都要让整条行在核间弹跳，性能塌陷。

**它不影响正确性**（本节两组都输出 `正确=true`），只影响性能。
而且**判定它不需要计时**——看 `offsetOf` 就够了。

```zig
// examples/31_concurrency/main.zig 第 1069-1097 行
    // ═══════════════════════════════════════════════════════════════════ 31.12 伪共享与缓存行对齐 ══

    /// 方案 A：两个计数器紧邻 ⇒ 必然同一条缓存行
    const Adjacent = struct {
        a: std.atomic.Value(u64),
        b: std.atomic.Value(u64),
    };

    /// 方案 B：给字段本身加 align(cache_line) ⇒ 真隔开
    const Aligned = struct {
        a: std.atomic.Value(u64) align(std.atomic.cache_line),
        b: std.atomic.Value(u64) align(std.atomic.cache_line),
    };

    fn hammerA(pa: *Adjacent, iters: usize) void {
        var i: usize = 0;
        while (i < iters) : (i += 1) {
            _ = pa.a.fetchAdd(1, .monotonic);
            _ = pa.b.fetchAdd(1, .monotonic);
        }
    }

    fn hammerB(pb: *Aligned, iters: usize) void {
        var i: usize = 0;
        while (i < iters) : (i += 1) {
            _ = pb.a.fetchAdd(1, .monotonic);
            _ = pb.b.fetchAdd(1, .monotonic);
        }
    }
```

运行输出（`examples/31_concurrency/main.zig`）：

```text
==== 31.12 伪共享与缓存行对齐 开始 ====
std.atomic.cache_line = 128 字节（本机 x86_64；ARM 常见 64）
Adjacent: sizeOf=16 offsetOf(.b)=8 align=8← a/b 挨着，必然同一条缓存行
Aligned  : sizeOf=256 offsetOf(.b)=128 align=128 ← 真隔开（b 与 a 相距 128 字节 > 缓存行）
Adjacent 布局：a=400000 b=400000（各期望 400000，正确=true）
Aligned   布局：a=400000 b=400000（各期望 400000，正确=true）
==== 31.12 伪共享与缓存行对齐 结束 ====
```

### 判定表（不需要跑基准）

| 现象 | 判定 |
|---|---|
| `offsetOf(b) < cache_line` | **同一条缓存行** ⇒ 有伪共享风险 |
| `offsetOf(b) >= cache_line` | 不同行 ⇒ 安全 |
| `@alignOf(T) == cache_line` | 已对齐 ⇒ 安全 |

`Adjacent` 的 `offsetOf(.b) = 8` 而 `cache_line = 128` ⇒ 必然同一条行。
`Aligned` 的 `offsetOf(.b) = 128` ⇒ 正好在下一条行的起点，安全。

### ⚠️ 字节数组填充**无效**（19 章踩过，本章复述）

```zig
// ❌ 无效：Zig 按对齐要求重排字段，b 的对齐(8)高于 pad 数组(1)，
//         编译器有权（也确实）把 b 放回 offset 8
const Padded = struct {
    a: std.atomic.Value(u64),
    pad: [std.atomic.cache_line - @sizeOf(u64)]u8,
    b: std.atomic.Value(u64),
};
// 实测 offsetOf(Padded, "b") == 8（没变！），pad 被挪到 offset 16

// ✅ 正确：给字段本身加 align
const Aligned = struct {
    a: std.atomic.Value(u64) align(std.atomic.cache_line),
    b: std.atomic.Value(u64) align(std.atomic.cache_line),
};
```

**正确写法永远是 `field: T align(std.atomic.cache_line)`。**
本机 `std.atomic.cache_line = 128`（`pub const cache_line: comptime_int`，编译期常量）。

### 为什么本节刻意不报耗时

**Debug 构建的波动是毫秒级，伪共享的收益是微秒级——噪声完全淹没收益。**
19 章实测两次跑甚至**结论相反**。要测性能必须用 `-OReleaseFast`
并把迭代数量级放大到 10⁸ 以上。

**方法论**：任何在 Debug 下测不出来的性能差异，都不该写进文档当结论。
用结构（`offsetOf`）当判据，不用计时器。

## 31.13 死锁与活锁：怎么**检测**而不是真死锁

四种死锁条件（任意一个成立即可能死锁）：**互斥、持有并等待、不可抢占、环路等待**。

**本节的第一纪律：每个检测程序都带出路，绝不真死锁。**
每个场景都用 `tryLock` 或「带超时的等待组」把死锁变成**可观测的返回**。

```zig
// examples/31_concurrency/main.zig 第 1134-1235 行
    // ═══════════════════════════════════════════════════════════════════ 31.13 死锁与活锁检测 ══

    /// 场景一：环路等待（两个锁，A 等 B 的同时 B 等 A）
    /// 检测手段：**永远不真死锁** —— 用 tryLock 在拿不到时就退出并记账
    const RingDeadlock = struct {
        a: std.Io.Mutex = .init,
        b: std.Io.Mutex = .init,

        fn threadOne(self: *RingDeadlock, io: std.Io, got_both: *std.atomic.Value(bool)) void {
            if (!self.a.tryLock()) return; // A 拿不到就直接走
            if (!self.b.tryLock()) { // B 拿不到 ⇒ 环路等待成立
                self.a.unlock(io);
                return;
            }
            got_both.store(true, .release);
            self.b.unlock(io);
            self.a.unlock(io);
        }
    };

    /// 场景三：不可抢占（拿到锁的线程不放手）
    const NoPreempt = struct {
        lock: std.Io.Mutex = .init,
        /// hog 线程拿到锁后置 1（release）；主线程自旋等它变1，**保证**后续判定是确定的
        holding: std.atomic.Value(bool) = .init(false),
        /// 另一个线程是否成功拿到过锁（不可抢占时恒为 false）
        other_got: std.atomic.Value(bool) = .init(false),

        fn hog(self: *NoPreempt, io: std.Io) void {
            self.lock.lockUncancelable(io);
            self.holding.store(true, .release);
            // 故意**不**解锁、也不返回：这就是不可抢占
        }
    };

    /// 活锁：两个线程都在动（turn 在来回翻转），但都没进展（progress 恒为 0）。
    /// 用**有界**的自旋 + 让步来复现，所以线程一定会结束，输出可重复。
    const Livelock = struct {
        /// 当前轮到谁（0 或 1）。每轮都被"礼貌地"让给对方 ⇒ 它会不断翻转。
        turn: std.atomic.Value(u32) = .init(0),
        /// 自旋次数：证明线程**确实在动**（不可复现，但 > 0 恒成立）
        spins: std.atomic.Value(u64) = .init(0),
        /// 让步次数
        yields: std.atomic.Value(u64) = .init(0),
        /// 真正的进展：始终为 0，这是活锁的定义
        progress: std.atomic.Value(u32) = .init(0),
    };
```

运行输出（`examples/31_concurrency/main.zig`）：

```text
==== 31.13 死锁与活锁检测 开始 ====
   确定性判定：程序**正常结束没挂死**= true ← 这才是本节要证明的事
② 持有并等待：2 个线程各成功一次嵌套获取 = 2（预期 2，因为 second 空闲）
③ 不可抢占：持锁线程**永不返回**（故意不 join）；另一个线程 tryLock 失败后立刻退出
   hog 已持锁= true（确定）另一个线程拿到过锁= false（**恒为 false** = 被成功挡住）
④ 活锁：两个线程各礼貌让对方 1000 次，总让步 2000 次（=2×1000，确定=true）
   progress=0（**恒为 0** = 一个单位的实事都没做成，判定成立=true）
   自旋发生过（>0）= true（布尔量才可比；具体次数每次不同，不打印）
⑤ 通用检测套路：等待组带超时→ error.Timeout（这就是「死锁检测」而非真死锁）
==== 31.13 死锁与活锁检测 结束 ====
```

### 四个场景的检测手段与破解

| 场景 | 检测手段（不真死锁） | 破解 |
|---|---|---|
| ① 环路等待 | `tryLock` 拿不到就退出 | **全局锁序**（永远按同一顺序申请多把锁） |
| ② 持有并等待 | 嵌套获取时用 `tryLock` | **一次性申请全部锁**（全有或全无），或允许抢占 |
| ③ 不可抢占 | 另一线程 `tryLock` 失败即返回 | 设超时 + 强制回收，或设计上不持跨调用的锁 |
| ④ 活锁 | **有界**让步次数 + `progress` 计数器 | **随机化退避**（打破对称），或让一方全让 |
| ⑤ 通用 | 等待组带 `waitTimeout` | 任何 `wait` 都配超时预算，超时记日志 + 打印栈 |

### ③ 不可抢占里那个关键自旋

```zig
var hog_t = try std.Thread.spawn(.{}, NoPreempt.hog, .{ &np, io });
// ⚠️ **必须先等 hog 真的拿到锁**，否则「另一个线程被挡住」就是竞态（实测 0/1 会飘）。
//   这个自旋把时序假设变成确定事实，是本节「不靠运气」的关键一步。
while (!np.holding.load(.acquire)) std.atomic.spinLoopHint();
const oth_t = try std.Thread.spawn(.{}, NoPreempt.other, .{ &np, io });
oth_t.join();
```

**这是我实测踩到的第二个不稳定输出**：`stuck_count` 一会儿 0 一会儿 1，
因为「另一个线程」可能在 hog 拿到锁之前就跑了。加一句自旋等
`holding == true` 之后，「另一个线程拿到过锁 = false」才成为**确定值**。

**规律**：任何「先 A 后 B」的时序假设，都要显式等待 A 发生，
否则就是靠运气。

### 活锁 vs 死锁

| | 死锁 | 活锁 |
|---|---|---|
| 线程状态 | 全部**阻塞**（没人动） | 全部**运行**（都在动） |
| CPU 占用 | **空闲** | **打满** |
| 有进展吗 | ❌ 没有 | ❌ 也没有 |
| 典型成因 | 环路等待 / 持有并等待 | **对称的退让**（两方都礼貌让对方） |
| 破解 | 打破环路 | **打破对称**（随机化） |

本节第 ④ 行的复现手法：两个线程各自「等轮到自己 → 把 turn 让给对方」，
**双方都让 ⇒ 谁都进不了做实事那一步**。用**有界**的 `want` 轮数让线程一定能结束
（真活锁会永远挂着，就没法 `join` 了）。

## 31.14 综合实战：并行归约与工作窃取

### ⚠️ 先讲本章最贵的一个 bug：环绕加法不可结合

```zig
// ❌ 第一版：并行求和永远对不上串行基线
fn heavySum(lo: u64, hi: u64) u64 {
    var acc: u64 = 0;
    var i = lo;
    while (i < hi) : (i += 1) acc +%= i *% 2654435761; // 环绕加法
    return acc;
}
// 现象：串行 = 41029562875904，并行 = 3203751872，差 6 个数量级。
```

**根因**：`+%` 是模 2⁶⁴ 加法，**不满足结合律**：

```
((a +% b) +% c) ≠ (a +% (b +% c))
```

所以「串行整体算」和「并行分块再合并」**必然**不同——这与线程数无关，
是数学性质。**Debug 构建不会报错**（每一步都不溢出，只是结果不同）。

**修法一：改用 XOR 聚合**（满足结合律与交换律）：

```zig
// examples/31_concurrency/main.zig 第 1302-1314 行
    /// 任务本体：确定性计算（无副作用，同输入同输出）。
    /// ⚠️ 这里用 **XOR** 聚合而不是 `+%` 加法——这是本章一个真实的教训：
    ///   环绕加法**不满足结合律**，所以「串行整体算」和「并行分块再合并」结果必然不同。
    ///   并行归约要求聚合算子可结合、可交换 ⇒ 用 XOR（满足）或在更宽的类型上做加法。
    ///   我第一版写的是 `acc +%= i *% K`，结果并行版永远对不上串行基线。
    fn heavySum(lo: u64, hi: u64) u64 {
        var acc: u64 = 0;
        var i = lo;
        while (i < hi) : (i += 1) {
            acc ^= i *% 2654435761; // XOR：可结合可交换 ⇒ 并行/串行结果必然一致
        }
        return acc;
    }
```

**修法二：用更宽的类型**（如 `u128` 或分块 `u64` 求和后再 `+%` 合并），
或**串行地**做最终合并。生产代码里如果你必须用加法，
就把每个分块的和对 2⁶⁴ 取模后再合并——并**意识到这依赖数据分布**，不可移植。

### 原子游标：无锁的负载均衡

```zig
// examples/31_concurrency/main.zig 第 1316-1337 行
    /// 原子游标模式：worker 抢号，谁快谁多拿（无锁负载均衡）
    const Cursor = struct {
        next: std.atomic.Value(u64) = .init(0),

        fn take(self: *Cursor, total: u64) ?u64 {
            const i = self.next.fetchAdd(1, .monotonic); // 抢号
            if (i >= total) return null; // 活儿派完了
            return i;
        }
    };

    /// 原子游标版的并行求和。
    /// ⚠️ 参数语义要分清：`n_chunks` 是**块数**，`n_elems` 是元素总数。
    ///    块 i 覆盖 [i*chunk, min(i*chunk+chunk, n_elems))——**最后一块要夹到 n_elems**，
    ///    否则当 n_elems 不是 chunk 的整数倍时会算出越界的项（第一版就踩了这个）。
    fn parallelSum(c: *Cursor, chunk: u64, n_chunks: u64, n_elems: u64, out: *std.atomic.Value(u64)) void {
        while (c.take(n_chunks)) |i| {
            const lo = i * chunk;
            const hi = @min(lo + chunk, n_elems);
            _ = out.fetchXor(heavySum(lo, hi), .monotonic); // XOR 聚合：可结合 ⇒ 与串行整体算一致
        }
    }
```

**没有队列、没有锁、没有条件变量**，而且**天然负载均衡**（谁快谁多拿）。
代价是：① 任务粒度必须均匀；② 需要一个「任务数组」作为共享只读状态。

⚠️ **两个实测踩到的细节**：

1. **块数要向上取整**：`n_chunks = (N + chunk - 1) / chunk`。
   用 `N / chunk`（向下取整）会**漏掉最后不满一块的元素**。
2. **`take` 会多走一格**：最后一次 `take` 拿到 `i == total` 后才返回 `null`，
   但 `fetchAdd` 已经把游标推到了 `total + 1`。所以 `next == total + 1`（不是 `total`）。
   **这不是 bug**——多线程下正是靠这个多出的一格保证「没有活儿漏掉」：
   宁可多占一个号，也不能少占。

### 工作窃取（简化版）

```zig
// examples/31_concurrency/main.zig 第 1347-1416 行
    /// 工作窃取（简化版）：每个 worker 有自己的队列，本地空了就去邻居那里偷。
    ///
    ///⚠️ 真实实现用「**从尾部偷**」（deque  pop_back）以避免和owner 的 pop_front 冲突。
    /// 这里简化为「**每个队列配一个原子读游标**」：谁抢到下标谁就算那个任务。
    /// 用 fetchAdd 抢下标是**正确**的关键——若改用每个 worker 各自的本地游标，
    /// 偷取方会和owner 读到同一下标 ⇒ 任务被算两遍、校验和必然偏大。
    const StealPool = struct {
        const NUM_WORKERS = 4;
        const QCAP = 64;
        queues: [NUM_WORKERS][QCAP]u64 = undefined,
        lens: [NUM_WORKERS]std.atomic.Value(u32) = @splat(std.atomic.Value(u32).init(0)),
        /// 每个队列一个**共享读游标**（抢号用），这是避免重复计算的关键
        cursors: [NUM_WORKERS]std.atomic.Value(u32) = @splat(std.atomic.Value(u32).init(0)),
        total_tasks: u64,
        stolen: std.atomic.Value(u64) = .init(0),
        claimed: std.atomic.Value(u64) = .init(0),
        checksum: std.atomic.Value(u64) = .init(0),

        fn init(total: u64) StealPool {
            return .{ .total_tasks = total };
        }

        /// 从队列 q 抢一个任务下标；抢不到返回 null
        fn claim(self: *StealPool, q: usize) ?u64 {
            const len = self.lens[q].load(.acquire); // 队列里有多少任务
            const idx = self.cursors[q].fetchAdd(1, .acquire); // 抢下一个下标
            if (idx >= len) return null; // 抢完了
            return idx;
        }
    };
```

运行输出（`examples/31_concurrency/main.zig`）：

```text
==== 31.14 综合实战 开始 ====
① 并行求和：串行基准 = 41029562875904，4 线程游标并行 = 41029562875904
   完全一致 = true（并行归约的正确性判据：不是「差不多」，是**逐位相同**）
   分块数 = 100，每块 = 10000 项⇒ 游标抢号天然负载均衡（谁快谁多拿）
③ 并行归约：16 个值归约到 1个 = 14808961105960090978（确定值，验证归约树正确）
④ 工作窃取：200 个任务 → 4 个 worker，校验和 = 2308913771600915636
   期望校验和 = 2308913771600915636，完全一致 = true
   实际被认领的任务数 = 200（=200，每个任务恰好算一次，正确=true）
   发生过窃取（>0）= true（布尔量才可比；具体次数每次不同，不打印）
⑤ 三种并行写法的确定性指标对比：
   原子游标：结果正确=true 无需锁=true 负载均衡=true 任务粒度必须均匀=true
   静态分块：结果正确=true 无需锁=true 负载均衡=false（4 个 worker 固定区间）
   工作窃取：结果正确=true 无需锁=true 负载均衡=true（最均衡但实现最复杂）
==== 31.14 综合实战 结束 ====
```

### ⚠️ 窃取的游标必须是**共享**的

我第一版给每个 worker 一个**本地**读游标，结果校验和偏大。
原因：worker A 从自己的队列读到下标 3，worker B 偷取时也从队列 A 读到下标 3
⇒ **同一个任务被算了两遍**。

**正确做法**：每个队列配一个**共享的原子游标**，
所有人（owner 和窃取者）都用 `fetchAdd` 抢下标。这样每个下标**恰好被认领一次**。

第 ④ 行「实际被认领的任务数 = 200（正确=true）」就是这条不变量的断言。

### 加速比：只报方向，不报裸数字

收尾区（**在最后一个 `end()` 之外**）的输出：

（下面是「不确定数字区」的**形状**，实测形如；**每次运行数字都不同，故不逐字节抄**——
这正是它被放在所有 `end()` 之外的原因。）

```
==== 收尾 · 不确定数字区（**不可比对**，每次运行都不同） ====
  裸 += 丢更新的具体数字 = <每次不同>（只抄「小于期望」这个方向）
  环路等待 tryLock 竞态：两线程都成功 = <true 或 false，每次可能不同>
  串行 1000000 项耗时 = <每次不同> ns
  并行（4 线程游标）耗时 = <每次不同> ns
  加速比 = <每次不同>x（Debug 构建的波动是毫秒级，收益是微秒级）
```

**这 5 行在所有 `end()` 之外**，因为它们的值每次运行都不同。
标记区间里一个裸耗时都没有——所以本文件的输出**可以逐字节比对**。

> **加速比不是可复现的断言。** 实测 5 次落在 1.88x ~ 3.87x。
> 唯一稳定的结论是「加速比的**方向**」：并行是否 > 1。
> 要得到可信的性能数字，用 `-OReleaseFast` 并把迭代量放大到 10⁸ 以上。

### 三种并行写法的对比

| 写法 | 结果正确 | 无需锁 | 负载均衡 | 任务粒度要求 | 实现复杂度 |
|---|---|---|---|---|---|
| 原子游标 | ✅ | ✅ | ✅（谁快谁多拿） | **必须均匀** | 低（一个 `fetchAdd`） |
| 静态分块 | ✅ | ✅ | ❌（固定区间） | 必须均匀 | 最低 |
| 工作窃取 | ✅ | ✅ | ✅✅（最均衡） | **可以不均匀** | 高 |

**默认选原子游标。** 只有当任务耗时差异极大（比如「有的 1ms 有的 1s」）
且任务数远大于线程数时，工作窃取的复杂度才划算。

## 31.15 坑位清单

1. **`std.Thread.Mutex` / `Condition` / `Semaphore` / `RwLock` / `WaitGroup` / `Pool` /
   `ResetEvent` / `Futex` 在 0.17 全部不存在**。`@hasDecl` 逐个实测为 `false`。
   照抄旧教程报 `root source file struct 'Thread' has no member named 'Mutex'`。
   替代品全在 `std.Io` 下（31.1 表）。

2. **`if (可选值) |x| { } else |y| { }` 编译失败**。实测报
   `expected error union type, found '?u32'`——`else` 带 payload **只对错误联合合法**。
   `cmpxchg` 返回 `?T`，所以必须写裸 `else`。这条错误信息极具误导性（19 章的示例
   因为用了裸 `else` 才侥幸通过）。

3. **`[_]T{x} ** N` 数组重复语法在 0.17 已移除**。现在被解析成两个指针运算符，报
   `binary operator '*' has whitespace on one side, but not the other`。
   一律用 `@splat(x)`（本机实测 `[_]u32{0} ** CAP` 与 `[_]u32{0}**CAP` 都失败）。

4. **`fetch*` 与 `swap` 一律返回旧值**（`@atomicRmw` 语义）。
   `fetchAnd` 返回的是**改之前**的值，新值要再 `load` 一次。31.2 的表把十个全列了。

5. **`%` 没有 `/%` 运算符**。环绕除法不存在（除法不可结合，且模逆不是所有奇数都有）。
   环绕加 `+%`、环绕减 `-%`、环绕乘 `*%` 都有，`/%` 没有。

6. **`fromMilliseconds` 收 `i64` 不是 `usize`/`u64`**。传 `u64` 报
   `signed 64-bit int cannot represent all possible unsigned 64-bit values`。

7. **`Clock.Duration` 和 `Io.Duration` 是两个不同类型**。前者是
   `struct { raw: Io.Duration, clock: Clock }`。所以
   `Clock.Timestamp.fromNow(io, .fromMilliseconds(3))` 报
   `struct 'Io.Clock.Duration' has no member named 'fromMilliseconds'`，
   必须写全 `.{ .raw = .fromMilliseconds(3), .clock = .awake }`。

8. **`Io.Timestamp` 没有 `addMilliseconds`**。加一个绝对时刻用
   `Clock.Timestamp.fromNow(io, duration)`。

9. **`@typeInfo(T).@"enum"` 在 0.17 没有 `.fields` 数组**，改成
   `field_names: []const [:0]const u8` + `field_values` + `decl_names`。
   反射枚举成员要遍历 `field_names`。

10. **`Event.waitTimeout` 要 `*Event`**：`const ev: std.Io.Event = .unset;` 之后调
    `ev.waitTimeout(...)` 报 `expected type '*Io.Event', found '*const Io.Event'`。
    要 `var`。

11. **`Io.RwLock.tryLock(io)` 要 `io`，但 `Io.Mutex.tryLock()` 不要**。两个都叫
    `tryLock`，签名不一致，极易记混（31.5 表里对照过）。

12. **`Io.Semaphore` 叫 `wait`/`post`，不叫 `acquire`/`release`**；也**没有 `init` 常量**
    （用 `.{ .permits = N }`）。写 `sem.acquire()` 报
    `no field or member function named 'acquire' in 'Io.Semaphore'`。

13. **`Io.Event.set(io)` 要 `io` 而 `reset()` 不要**。0.17 的真实不一致点，
    写 `e.reset(io)` 报 `member function expected 0 argument(s), found 1`。

14. **`Io.Condition.wait` 在 `std.testing.io` 上死锁**（实测 15 秒未结束）。
    `std.testing.io` 是单线程视图，没有 worker 处理阻塞操作。
    锁的编排必须放 `main`（用 `init.io`），`test` 只测纯函数与原子操作。

15. **持锁 `join` 是自锁经典**。放完哨兵必须**先解锁再 join**——worker 醒来要拿锁
    才能吃哨兵，你却攥着锁等它退出。19 章实测反例跑 6 秒仍未结束。

16. **SPSC 的 `turn[i]` 初始值必须是 `i` 不是 0**。写 0 会导致生产者永远等不到
    「上一代已交还」的槽位 ⇒ **死循环挂死**（不是报错，是 hang）。

17. **环形加法 `+%` 不满足结合律**。所以「串行整体算」≠「并行分块再合并」，
    Debug 构建**不报错**。并行归约要用 XOR（可结合可交换）或更宽的类型。
    这是本章实测最贵的一个 bug（现象是结果差 6 个数量级）。

18. **游标抢号会多走一格**。`take` 在最后一次调用里拿到 `i == total` 才返回 `null`，
    但 `fetchAdd` 已把游标推到 `total + 1`。这是**有意的**（宁可多占一个号，
    也不能少占导致漏活儿），别当成 off-by-one 去「修」。

19. **并发输出里不能有裸耗时 / 裸重试次数**。这是本章最重要的一条方法论。
    我实测把「CAS 重试次数」打进标记区间，连跑 5 次得到 `0 / 0 / 1 / 0 / 0`——
    **完全不可比对**。三种解法（本文件都用了）：
    ① 让不确定量变成**确定值**（31.4「各做恰好一次 CAS」⇒ 成功必为 1）；
    ② 只打印**布尔/方向**（31.3「结果小于期望 = true」、31.4「伪失败为 0 = true」）；
    ③ 把不确定数字**移到最后一个 `end()` 之外**（本文件的「不确定数字区」）。
    本文件连跑 5 次，**标记区间内逐字节一致**（见坑位清单第 20 条的同类教训）。

20. **「先 A 后 B」的时序假设必须显式等待**。31.13 的 `stuck_count` 一会儿 0
    一会儿 1，因为「另一个线程」可能在 hog 拿到锁之前就跑完了。
    加一句 `while (!np.holding.load(.acquire)) spinLoopHint();` 把时序假设
    变成确定事实。凡是「A 之后 B」都要这么写。

21. **工作窃取的读游标必须每队列一个（共享），不能每 worker 一个（本地）**。
    本地游标会让 owner 和窃取者读到同一下标 ⇒ 任务被算两遍、校验和偏大。
    用 `cursors[q].fetchAdd(1, .acquire)` 抢号，保证每个任务恰好认领一次。

22. **`zig test` 不覆盖 `main` 里才编译的代码**。我一度让 `zig test` 全绿、
    `zig build-exe` 却报「unused local variable」——因为出错的是分节函数
    （只有 `main` 调）。**三层验证里 `build-exe` 那一层不能跳。**

23. **Zig 字符串里不能直接嵌套双引号**。写 `("...这是超时"检测"...")`
    报 `expected ',' after argument`。要么用单引号式的中文引号 `「」`，
    要么转义。

24. **中文字符串里的 `{b}` / `{d}` 会被当成格式符**。我写过
    `"← 真隔开{b 与 a 相距 {d} 字节"`，`{b 与 a 相距 ` 被解析成格式说明符，
    报 `invalid format string 'b 与 a 相距 {d' for type 'comptime_int'`。
    中文正文里别出现形似格式符的花括号。

25. **枚举实例取不到成员函数**：`ring.threadOne` 报
    `no field named 'threadOne' in struct 'main.RingDeadlock'`。
    要写 `RingDeadlock.threadOne`，并且 `self` 要传**指针**（`const` 变量不行）。

26. **传给 `Thread.spawn` 的指针参数必须来自 `var`**。`const sink: std.atomic.Value(u64)`
    传给要 `*std.atomic.Value(u64)` 的 worker 报
    `cast discards const qualifier`。

27. **给 `std.Thread.spawn` 的函数名不能遮蔽已有声明**。本文件把 `heavySum` 的
    第二个形参命名为 `end`，结果报
    `function parameter shadows declaration of 'end'`——因为分节标记 helper 就叫 `end`。

---

上一章：[30 HTTP 服务与客户端](30-http.md) · 下一章：[32 SQLite 实战](32-sqlite.md)
