# 34 · 实战：LRU 缓存服务器 zcache


> 对应示例：`examples/34_zcache/main.zig`（1785 行，18 个测试）
>
> 收官工程：内存 KV 缓存——LRU 淘汰核 + TCP 行协议 + 并发访问。取材 Tsoukalos
> ch10（zcache 的核心问题："为什么哈希表和双向链表两个都要"）。
> 运输层沿用 29 章的 `std.Io.net`，协议解析沿用 30 章的行缓冲思路但**不**用 CRLF。
>
> 本章有 **7 条实测结论会推翻你可能听过的说法**，其中前 5 条是本章亲手踩出来的：
>
> 1. **`takeDelimiterExclusive` 不能直接用来读行**。0.17.0 的 std 有 bug：它只
>    `toss(result.len)` 而 `result` 不含分隔符 → 分隔符留在缓冲里，**第二次起永远
>    返回空片**。纯内存 `Reader.fixed` 就能复现，与网络无关（34.7 / 34.15 有最小复现测试）。
> 2. **`Stream.close` 不能随便调**。它 close(fd) 之后**既不把句柄置为无效、也不
>    报错**，二次 close 同一 fd 命中 `EBADF` → `recoverableOsBugDetected()` →
>    Debug 下 `unreachable` → panic。纪律：一条连接只 close 一次（34.9）。
> 3. **0.17 的 `StringHashMap` 没有 `putOwned`**。`@hasDecl` 实测 = `false`，
>    `getOrPutOwned` 同样没有。键内存归调用方，**唯一正确写法是先 `dupe` 再 `put`**（34.4）。
> 4. **`std.DoublyLinkedList` 在 0.17 里没有 `init()`、没有 `iterator()`、也没有
>    `fetchNode()`**。声明用 `= .{}`，遍历一律手写 `first`/`next` 循环（34.3）。
> 5. **`insertBefore` / `insertAfter` 不检查「已经相邻」**。把一个本来就紧挨着
>    `existing_node` 的节点再插一次，会写出 `a.prev = a` 的自环 → 遍历**永不终止**。
>    本章第一版演示就是这么写的，实测把程序打成死循环（34.3 第 5 条）。
> 6. **两个常用 API 在 0.17 里消失了**：`std.time.Timer` 整个类型不存在
>    （`std.time` 只剩 `ns_per_ms` 这类除数常量），`std.heap.GeneralPurposeAllocator`
>    改名 `std.heap.DebugAllocator(.{}) = .init`。前者正好帮了本章——**语言层面
>    逼你把裸耗时从标记区间里拿掉**；后者是 34.13 的主角。
> 7. **自引用结构体（含侵入式链表的空闲链）不能在 `init()` 里就地绑定指针**。
>    `return self` 一拷贝，init 栈帧就没了。34.2 的 `StdListLru` 实测直接
>    **Segmentation fault**（34.4 讲同一坑在运输层的表现）。
>
> 另外三条是语言/工具链层面的，写代码时天天遇到：
> `**` 的空格规则很怪（`a ** b` 编译报错、`"x"** 1900` 解析成 "expected type 'type'"）、
> 切片赋值 `s = v` 在 0.17 已被移除、`std.mem` 没有 `repeat`。
>
> **节号对应**：34.1–34.15 是示例 `main` 里的运行时小节（`begin("34.N …") …
> end("34.N")`，运行输出里能看到 `==== 34.N … 开始 ====`）；**34.16（坑位清单）与
> 34.17（验证方式）不在 `main` 里**，它们是本文档自己的两节。
>
> **稳定性纪律（本章第一原则）**：网络 + 并发示例的输出极易漂移。本章的四条对策：
> 1) 标记区间里**不出现任何裸耗时/吞吐数字**——只印确定性结论；
> 2) 基准测试不比耗时，比 **work（基本操作计数）**；
> 3) 端口用 `listen(0)` 拿内核分配的 ephemeral 端口，且**只印「非 0：是」**；
> 4) 并发段用**差值断言**（STAT 前后相减）+ **按槽位汇总的校验和**。
>
> **本章服务端与客户端在同一进程**（`std.Thread.spawn` + 端口原子公布）。
> 关停用「置 stop 标志 + 建一条空连接把阻塞的 `accept` 叫醒」，主线程 `join()` 即同步
> ——所以 `./run-all.sh 34_zcache` 不可能挂死。
>
> 尾部用 `std.heap.DebugAllocator.deinit() == .ok` 反证**整场零泄漏**（含 34.2 的四套
> 实现、服务器 LRU 的 4095 个条目、34.13 的 500 轮 churn）。

---

## 34.1 项目总览与协议定义

zcache 是个**内存 KV 缓存**：客户端用一行文本说「给我 `k`」或者「把 `k` 设成 `v`」，
服务端维护一个容量固定的 LRU 表。这三件事——**协议、淘汰、并发**——凑在一起才是
一个真实服务端的最小完备集。本章把它们按依赖顺序拆成 15 节。

### 34.1.1 协议：为什么是 5 个命令而不是 HTTP

30 章完整实现过一遍 HTTP。这一章**故意不用**它，理由有三条，每条都不是「嫌麻烦」：

1. **字节数**。`GET k` 一行 9 字节；HTTP 光一行请求加 `Host` 头就 40+ 字节。
2. **断言锋利度**。本章要验证的是「第 7 条命令之后淘汰了谁」。协议越薄，
   断言就越能对准 LRU 本身——HTTP 的 CRLF 处理、头部折叠、分片重组会把
   「淘汰对不对」这个真正要验的东西整个埋掉。
3. **错误集合是闭集**。`ERR` 的原因只有 6 种（见 34.11），每一种都能写一条单测。
   HTTP 的错误面（状态码 + 头部 + 体）不是闭集，写不完。

于是协议长这样：

| 请求 | 应答 | 说明 |
|---|---|---|
| `GET <key>` | `VALUE <value>` 或 `MISS` | 命中即提新（更新 LRU 序） |
| `PUT <key> <value>` | `OK` | 值是「其余全部 token」，**可含空格** |
| `DEL <key>` | `OK` 或 `MISS` | 二次删返回 `MISS` |
| `STAT` | `STAT hits=.. misses=.. evictions=.. entries=.. bytes=..` | 五元组 |
| `PING` | `PONG` | 存活探测，也用来对齐读写节奏 |

三个闸门（**超限一律 `ERR`，且不断连**）：行长 ≤ 1024、值 ≤ 256、键 ≤ 64。

### 34.1.2 行尾只认 `'\n'`

30 章 HTTP 的行尾是 CRLF，`'\r'` 和 `'\n'` 可能分片到达，示例为此专门写了
「先吃 `'\r'`、补一次读再吃 `'\n'`」的分支。本章协议自己定义，**只用 `'\n'`**——
少一个字节就少一次 `fillMore`，示例不必处理分片。

这不是偷懒，是**协议设计时该主动砍掉的东西**：能让对端只用一种行尾，就别给他
两种。30 章那个分片分支是 HTTP 历史的包袱，不是好示范。

### 34.1.3 分节函数

```zig
// examples/34_zcache/main.zig 第 897-918 行
fn sectionOverview() void {
    begin("34.1 协议定义");
    p("  zcache = LRU 淘汰核 + TCP 行协议 + 多线程接入\n", .{});
    p("  ── 请求 ────────────────────────────  ── 应答 ────────────────────────────────\n", .{});
    p("  GET <key>                          →  VALUE <value> | MISS\n", .{});
    p("  PUT <key> <value>                  →  OK\n", .{});
    p("  DEL <key>                          →  OK | MISS\n", .{});
    p("  STAT                               →  STAT hits=.. misses=.. evictions=.. entries=.. bytes=..\n", .{});
    p("  PING                               →  PONG\n", .{});
    p("  <未知命令>                          →  ERR unknown\n", .{});
    p("  ── 闸门 ──────────────────────────────────────────────────────────────────────\n", .{});
    p("  行长 ≤ {d} 字节；值 ≤ {d} 字节；键 ≤ {d} 字节（超限一律 ERR，且**不断连**）\n", .{
        max_line, max_value, max_key,
    });
    p("  行尾只认 '\\n'。注意这与 30 章 HTTP 的 CRLF 不同——本章协议自己定义，\n", .{});
    p("  少一个字节就少一次 fillMore，示例不必处理「'\\r' 已到、'\\n' 未到」的分片。\n", .{});
    p("  ── 为什么不用 HTTP（30 章已完整实现过一遍）──\n", .{});
    p("  1) 更短：GET 一行 9 字节 vs HTTP 的一行请求 + Host 头 40+ 字节\n", .{});
    p("  2) 能精确测字节级行为：本章要断言「第 7 条命令后淘汰了谁」，协议越薄断言越锋利\n", .{});
    p("  3) 错误集合是闭集：ERR 的原因只有 6 种，每种都能单测\n", .{});
    end("34.1 协议定义");
}
```

运行输出（`examples/34_zcache/main.zig`）：

```text
  zcache = LRU 淘汰核 + TCP 行协议 + 多线程接入
  ── 请求 ────────────────────────────  ── 应答 ────────────────────────────────
  GET <key>                          →  VALUE <value> | MISS
  PUT <key> <value>                  →  OK
  DEL <key>                          →  OK | MISS
  STAT                               →  STAT hits=.. misses=.. evictions=.. entries=.. bytes=..
  PING                               →  PONG
  <未知命令>                          →  ERR unknown
  ── 闸门 ──────────────────────────────────────────────────────────────────────
  行长 ≤ 1024 字节；值 ≤ 256 字节；键 ≤ 64 字节（超限一律 ERR，且**不断连**）
  行尾只认 '\n'。注意这与 30 章 HTTP 的 CRLF 不同——本章协议自己定义，
  少一个字节就少一次 fillMore，示例不必处理「'\r' 已到、'\n' 未到」的分片。
  ── 为什么不用 HTTP（30 章已完整实现过一遍）──
  1) 更短：GET 一行 9 字节 vs HTTP 的一行请求 + Host 头 40+ 字节
  2) 能精确测字节级行为：本章要断言「第 7 条命令后淘汰了谁」，协议越薄断言越锋利
  3) 错误集合是闭集：ERR 的原因只有 6 种，每种都能单测
```

## 34.2 LRU 数据结构的四种实现对比

这是本章信息密度最高的一节。我们把 LRU **同一份语义**用四种数据结构各写一遍，
喂**同一份工作负载**，然后比两件事：

- **语义**：四者的 hits / misses / evictions 必须**逐个相等**。
- **代价**：用 **work（基本操作计数）**衡量，不用耗时。

### 34.2.1 为什么不比耗时

耗时有两个问题：一是**天然不确定**，进不了标记区间（本章硬性要求）；
二是**尺子不统一就没法横向比**——A 用 Zig 写、B 用 C 写，纳秒数没有可比性。

`work` 是另一个东西：**基本操作计数**。口径必须四个实现完全一致：

| 操作 | work 计数 |
|---|---|
| 一次键比较（`memcmp` / 逐字节） | 1 |
| 一次数组元素搬移 | 1 |
| 一次链表**指针写** | 1（B 与 C 的 `remove` 各改 2 个指针、`prepend` 各改 3 个） |
| 一次哈希表查找 | 1（它内部是 O(1) 的常数级工作量） |
| 空闲链的出入 | **0**（B 用下标、C 用 `DoublyLinkedList`，实现不同但都不计入） |

最后两条是**对齐的关键**。本章第一版 B 按「指针写次数」算、C 只按「操作次数」算，
结果 B=2086 / C=1736，差额恰好 = 35 次淘汰 × 2 次漏算的指针写。
**拿两把不同的尺子去论证「std 不改变复杂度」，那个论证本身就不成立。**
对齐之后 B == C == 2086，这才有资格下结论。

### 34.2.2 工作负载：固定种子 LCG，不用 std.Random

`std.Random` 可能随版本换算法。本章要的是「连跑一万次逐字节一致」的工作负载，
必须钉死，所以手写一个 LCG（`benchRng`）：乘法 + 加法 + 取模，全整数、无状态依赖。

负载是 200 次操作，键在 `k0`..`k7`（8 个）里循环，容量 4——**必然触发淘汰**。
`r % 3 == 0` 时 PUT，否则 GET。

```zig
// examples/34_zcache/main.zig 第 188-202 行
fn benchRun(comptime Impl: type, a: std.mem.Allocator) !BenchResult {
    var c: Impl = undefined;
    c.init(a, bench_capacity);
    defer c.deinit();
    var state: u64 = 0x1234_5678_9abc_def0;
    var i: usize = 0;
    while (i < bench_ops) : (i += 1) {
        const r = benchRng(&state);
        const key = bench_keys[r % bench_keys.len];
        if (r % 3 == 0) try c.put(key, "v") else _ = c.get(key);
    }
    return .{ .hits = c.hits, .misses = c.misses, .evictions = c.evictions, .work = c.work };
}

/// 实现 A：动态数组 + 线性查找。
```

### 34.2.3 实现 A：数组 + 线性查找

三处 O(n)：`get` 扫一遍；提新要把元素搬到数组头，搬 n 个；淘汰要在数组里找
`seq` 最小的再 `swapRemove`。

```zig
// examples/34_zcache/main.zig 第 205-277 行
const ArrayLru = struct {
    const Item = struct { key: []const u8, value: []const u8, seq: u64 };

    gpa: std.mem.Allocator,
    cap: usize,
    items: std.ArrayList(Item) = .empty,
    seq: u64 = 0,
    hits: usize = 0,
    misses: usize = 0,
    evictions: usize = 0,
    work: usize = 0,

    fn init(l: *ArrayLru, gpa: std.mem.Allocator, cap: usize) void {
        l.* = .{ .gpa = gpa, .cap = cap };
    }

    fn deinit(l: *ArrayLru) void {
        // 基准实现借用字面量（不复制键值），所以只放数组本身。
        l.items.deinit(l.gpa);
    }

    fn find(l: *ArrayLru, key: []const u8) ?usize {
        for (l.items.items, 0..) |it, i| {
            l.work += 1; // 一次键比较
            if (std.mem.eql(u8, it.key, key)) return i;
        }
        return null;
    }

    /// 提新：swapRemove 到末尾再插回下标 0。后面每个元素都要往左挪一格，
    /// 这就是数组方案的 O(n) 提新。
    fn promote(l: *ArrayLru, at: usize) void {
        const item = l.items.swapRemove(at);
        l.work += l.items.items.len - at;
        l.items.insert(l.gpa, 0, item) catch unreachable;
    }

    fn get(l: *ArrayLru, key: []const u8) ?[]const u8 {
        const at = l.find(key) orelse {
            l.misses += 1;
            return null;
        };
        l.hits += 1;
        l.seq += 1;
        l.items.items[at].seq = l.seq;
        l.promote(at);
        return l.items.items[0].value;
    }

    fn put(l: *ArrayLru, key: []const u8, value: []const u8) !void {
        if (l.find(key)) |at| { // 已存在：只换值 + 提新
            l.items.items[at].value = value;
            l.seq += 1;
            l.items.items[at].seq = l.seq;
            l.promote(at);
            return;
        }
        l.seq += 1;
        try l.items.append(l.gpa, .{ .key = key, .value = value, .seq = l.seq });
        while (l.items.items.len > l.cap) {
            var victim: usize = 0;
            for (l.items.items, 0..) |it, i| {
                l.work += 1; // 一次序号比较
                if (it.seq < l.items.items[victim].seq) victim = i;
            }
            _ = l.items.swapRemove(victim);
            l.work += l.items.items.len - victim;
            l.evictions += 1;
        }
    }
};

/// 实现 B：手写双向链表 + **哨兵节点**。
```

### 34.2.4 实现 B：手写双向链表 + 哨兵节点

哨兵（sentinel）是一个**不装数据的空节点，待在结构体字段里**，地址永远稳定。
链表成环：`sentinel.next` 是最新、`sentinel.prev` 是最旧。

哨兵的价值是**「摘队首」「挂队尾」「判空」三处都不需要 null 分支**。没有哨兵的话，
`insert`/`remove` 每个方向都得写两套代码（头一个、尾一个），分支一多就必错。

节点用**下标（u8）**而不是指针：整张表在一个定长数组里，无堆分配、无悬垂风险。
0 号固定是哨兵。空闲槽位用一条链表串起来（复用 `next` 字段）——

> **「淘汰下来的槽位还给谁」是个真问题。** 手写一遍才记得住：只写 `alloc`
> 不写 `release`，节点池会在几百次操作后耗尽（本章第一版实测报
> `error.NodeTableFull`）。这正是 34.4 的生产核用 `DoublyLinkedList` 的原因之一。

```zig
// examples/34_zcache/main.zig 第 285-391 行
const SentinelListLru = struct {
    const max_nodes = 16;
    const Node = struct {
        key: []const u8 = "",
        value: []const u8 = "",
        prev: u8 = 0,
        next: u8 = 0,
        live: bool = false,
    };

    cap: usize,
    nodes: [max_nodes]Node = @splat(.{}),
    free_head: u8 = 1, // 空闲链表的头（0 表示没有空闲槽位）
    live_count: usize = 0,
    hits: usize = 0,
    misses: usize = 0,
    evictions: usize = 0,
    work: usize = 0,

    fn init(l: *SentinelListLru, _: std.mem.Allocator, cap: usize) void {
        l.* = .{ .cap = cap };
        l.nodes[0].next = 0; // 哨兵自环 = 空链表
        l.nodes[0].prev = 0;
        var i: u8 = 1; // 把 1..max_nodes-1 串成一条空闲链
        while (i < max_nodes - 1) : (i += 1) l.nodes[i].next = i + 1;
        l.nodes[max_nodes - 1].next = 0;
    }

    fn deinit(_: *SentinelListLru) void {}

    fn alloc(l: *SentinelListLru) !u8 {
        const idx = l.free_head;
        if (idx == 0) return error.NodeTableFull; // 空闲链空了
        l.free_head = l.nodes[idx].next;
        l.nodes[idx] = .{ .live = true };
        return idx;
    }

    fn release(l: *SentinelListLru, idx: u8) void {
        l.nodes[idx].live = false;
        l.nodes[idx].key = "";
        l.nodes[idx].value = "";
        l.nodes[idx].next = l.free_head; // 归还到空闲链头
        l.free_head = idx;
    }

    /// 摘链：两个方向各改一个指针。**O(1)**，这正是双向链表的意义。
    fn unlink(l: *SentinelListLru, idx: u8) void {
        const prev = l.nodes[idx].prev;
        const next = l.nodes[idx].next;
        l.nodes[prev].next = next;
        l.nodes[next].prev = prev;
        l.work += 2;
    }

    /// 挂到哨兵之后 = 队首 = 最新。因为哨兵是环的一部分，没有 null 分支。
    fn pushFront(l: *SentinelListLru, idx: u8) void {
        const first = l.nodes[0].next;
        l.nodes[idx].next = first;
        l.nodes[idx].prev = 0;
        l.nodes[first].prev = idx;
        l.nodes[0].next = idx;
        l.work += 3;
    }

    fn get(l: *SentinelListLru, key: []const u8) ?[]const u8 {
        var i = l.nodes[0].next;
        while (i != 0) : (i = l.nodes[i].next) {
            l.work += 2; // 一次跳转 + 一次键比较
            if (std.mem.eql(u8, l.nodes[i].key, key)) {
                l.hits += 1;
                l.unlink(i);
                l.pushFront(i);
                return l.nodes[i].value;
            }
        }
        l.misses += 1;
        return null;
    }

    fn put(l: *SentinelListLru, key: []const u8, value: []const u8) !void {
        var i = l.nodes[0].next;
        while (i != 0) : (i = l.nodes[i].next) {
            l.work += 2;
            if (std.mem.eql(u8, l.nodes[i].key, key)) {
                l.nodes[i].value = value;
                l.unlink(i);
                l.pushFront(i);
                return;
            }
        }
        const idx = try l.alloc();
        l.nodes[idx].key = key;
        l.nodes[idx].value = value;
        l.pushFront(idx);
        l.live_count += 1;
        while (l.live_count > l.cap) {
            const victim = l.nodes[0].prev; // 队尾 = 最旧 = 淘汰候选，O(1) 拿到
            l.unlink(victim);
            l.release(victim);
            l.live_count -= 1;
            l.evictions += 1;
        }
    }
};

/// 实现 C：把 B 的手写链表换成 `std.DoublyLinkedList`。
```

### 34.2.5 实现 C：把 B 的链表换成 std

语义与 work 口径和 B **完全一致**。结论会很有意思：**复杂度一模一样，代码少一大截**。

```zig
// examples/34_zcache/main.zig 第 393-476 行
const StdListLru = struct {
    const Entry = struct {
        key: []const u8,
        value: []const u8,
        link: std.DoublyLinkedList.Node = .{},
    };

    cap: usize,
    order: std.DoublyLinkedList = .{},
    live_count: usize = 0,
    pool: [SentinelListLru.max_nodes]Entry = @splat(.{ .key = "", .value = "" }),
    /// 空闲槽位也用一条 std.DoublyLinkedList 管——**这正是生产核用它的原因**：
    /// 「淘汰下来的槽位还给谁」是个真问题，手写一遍才记得住。
    free: std.DoublyLinkedList = .{},
    hits: usize = 0,
    misses: usize = 0,
    evictions: usize = 0,
    work: usize = 0,

    fn init(l: *StdListLru, _: std.mem.Allocator, cap: usize) void {
        l.* = .{ .cap = cap };
        // 这里往链表里塞的是 `l.pool` 的地址——**必须**在最终那份字段上做，
        // 写成 `return .{...}` 让调用方拿拷贝，空闲链就全指向已销毁的临时了。
        for (l.pool[1..]) |*e| {
            e.* = .{ .key = "", .value = "" };
            l.free.append(&e.link);
        }
    }

    fn deinit(_: *StdListLru) void {}

    /// 提新 = 摘链 + 挂队首。计数口径必须和 B 版**逐笔对齐**：
    /// remove 改两个指针（2 写）+ prepend 改三个（3 写）= 5。
    fn touch(l: *StdListLru, e: *Entry) void {
        l.order.remove(&e.link);
        l.order.prepend(&e.link);
        l.work += 5; // = B 版 unlink(2) + pushFront(3)
    }

    fn get(l: *StdListLru, key: []const u8) ?[]const u8 {
        var it = l.order.first;
        while (it) |node| : (it = node.next) {
            const e: *Entry = @fieldParentPtr("link", node);
            l.work += 2;
            if (std.mem.eql(u8, e.key, key)) {
                l.hits += 1;
                l.touch(e);
                return e.value;
            }
        }
        l.misses += 1;
        return null;
    }

    fn put(l: *StdListLru, key: []const u8, value: []const u8) !void {
        var it = l.order.first;
        while (it) |node| : (it = node.next) {
            const e: *Entry = @fieldParentPtr("link", node);
            l.work += 2;
            if (std.mem.eql(u8, e.key, key)) {
                e.value = value;
                l.touch(e);
                return;
            }
        }
        const node = l.free.popFirst() orelse return error.NodeTableFull;
        const e: *Entry = @fieldParentPtr("link", node);
        e.key = key;
        e.value = value;
        l.order.prepend(&e.link);
        l.work += 3; // prepend 的三次指针写，与 B 版 pushFront 同口径
        l.live_count += 1;
        while (l.live_count > l.cap) {
            const victim_node = l.order.popLast() orelse unreachable; // 队尾 O(1)
            const victim: *Entry = @fieldParentPtr("link", victim_node);
            l.work += 2; // popLast 内部的 remove，与 B 版 unlink 同口径
            victim.key = "";
            victim.value = "";
            l.free.append(&victim.link); // 槽位归还空闲链，O(1)
            l.live_count -= 1;
            l.evictions += 1;
        }
    }
};
```

### 34.2.6 复杂度对照表

| 实现 | 定位键 | 提新（touch） | 淘汰 | 空间 | 代码量 | 本章实测 work |
|---|---|---|---|---|---|---|
| A 数组线性查找 | O(n) | O(n)（搬移） | O(n)（扫 seq） | 连续数组 | ~70 行 | 1022 |
| B 手写哨兵链表 | O(n) | O(1) | O(1) | 碎片 + 空闲链 | ~105 行 | 2086 |
| C `std.DoublyLinkedList` | O(n) | O(1) | O(1) | 碎片 + 空闲链表 | ~85 行 | 2086 |
| D 哈希表 + 链表 | **O(1)** | O(1) | O(1) | 哈希桶 + 碎片 | ~120 行 | **134** |

两个容易被误读的结论：

- **D 的 work（134）比 A（1022）少 87%**，比 B/C（2086）少 94%。这不是「D 快 15 倍」，
  是「D 的 work 里根本不含遍历」。哈希表把定位键的那部分从 O(n) 拍成常数。
- **B 的 work（2086）比 A（1022）还大一倍**，尽管 B 的提新和淘汰都是 O(1)。
  原因：B 每次扫描要「跳一次 + 比一次」= 2 个 work，而 A 的扫描只算 1 个比较
  （数组是连续的，比较是硬件指令；链表要解引用，是访存）。**work 数的量级 ≠
  实测耗时的量级**——这正是我们不拿 work 当性能指标、只当复杂度指标的原因。

### 34.2.7 语义一致性：本章最省事的一种交叉验证

四份**独立代码**算同一个 LRU 问题，答案必须逐个相同。这比写四条断言更有价值：
一旦某一份的语义偏了（比如淘汰序搞反），三个数字里至少有一个会不一样。

```zig
// examples/34_zcache/main.zig 第 926-977 行
fn sectionImplementations(a: std.mem.Allocator) !void {
    begin("34.2 四种实现对比");
    p("  工作负载：固定种子 LCG，{d} 次操作，{d} 个键循环，容量 {d}（必然发生淘汰）\n", .{
        bench_ops, bench_keys.len, bench_capacity,
    });
    p("  ⚠️ 本节**不比耗时**，比「基本操作计数」work——它是编译期就确定的整数。\n", .{});
    p("     耗时天然不确定，进不了标记区间；work 则是复杂度的可测量化身。\n", .{});
    p("\n", .{});

    var rows: [4]Row = undefined;
    rows[0] = .{ .name = "A 数组线性查找", .complexity = "get O(n) 提新 O(n) 淘汰 O(n)", .r = try benchRun(ArrayLru, a) };
    rows[1] = .{ .name = "B 手写哨兵链表", .complexity = "get O(n) 提新 O(1) 淘汰 O(1)", .r = try benchRun(SentinelListLru, a) };
    rows[2] = .{ .name = "C std 链表", .complexity = "get O(n) 提新 O(1) 淘汰 O(1)", .r = try benchRun(StdListLru, a) };
    rows[3] = .{ .name = "D 哈希表+链表", .complexity = "get O(1) 提新 O(1) 淘汰 O(1)", .r = try benchRun(Lru, a) };

    p("  {s:<18} {s:<28} {s:>6} {s:>7} {s:>5} {s:>7}\n", .{ "实现", "复杂度", "hits", "misses", "evict", "work" });
    p("  {s}\n", .{sep_wide});
    for (rows) |row| {
        p("  {s:<18} {s:<28} {d:>6} {d:>7} {d:>5} {d:>7}\n", .{
            row.name, row.complexity, row.r.hits, row.r.misses, row.r.evictions, row.r.work,
        });
    }
    p("\n", .{});

    // 语义一致性：四份独立代码必须算出同一个 hit/miss/evict。
    const base = rows[0].r;
    for (rows[1..]) |row| {
        if (row.r.hits != base.hits or row.r.misses != base.misses or row.r.evictions != base.evictions) {
            p("  ✗ 语义分叉：{s} 的 hits/misses/evictions 与 A 不一致\n", .{row.name});
            return error.SemanticDivergence;
        }
    }
    p("  ✓ 语义一致：四份独立实现的 hits={d} misses={d} evictions={d} 逐个相同\n", .{
        base.hits, base.misses, base.evictions,
    });

    var max_work: usize = 0;
    for (rows) |row| max_work = @max(max_work, row.r.work);
    p("\n", .{});
    p("  work 条形图（每格 = 1/{d} 的 max）：\n", .{if (max_work > 0) max_work / 40 else 1});
    for (rows) |row| {
        p("  {s:<18} ", .{row.name});
        bar(row.r.work, max_work, 40);
        p(" {d}\n", .{row.r.work});
    }
    const ratio = if (base.work == 0) 0 else rows[3].r.work * 100 / base.work;
    p("\n", .{});
    p("  D 的 work 是 A 的 {d}%（越小越省；D 之所以是 D，就是这一行）\n", .{ratio});
    p("  B 与 C 的 work 相同 → 手写 60 行和调 std 一行，复杂度一模一样。\n", .{});
    p("  std 省掉的是**代码量**，不是**复杂度**——这是选型时真正该记住的一句。\n", .{});
    end("34.2 四种实现对比");
}
```

运行输出（`examples/34_zcache/main.zig`）：

```text
  工作负载：固定种子 LCG，200 次操作，8 个键循环，容量 4（必然发生淘汰）
  ⚠️ 本节**不比耗时**，比「基本操作计数」work——它是编译期就确定的整数。
     耗时天然不确定，进不了标记区间；work 则是复杂度的可测量化身。

  实现             复杂度                      hits  misses evict    work
  ----------------------------------------------------------------------
  A 数组线性查找 get O(n) 提新 O(n) 淘汰 O(n)     42      92    35    1022
  B 手写哨兵链表 get O(n) 提新 O(1) 淘汰 O(1)     42      92    35    2086
  C std 链表       get O(n) 提新 O(1) 淘汰 O(1)     42      92    35    2086
  D 哈希表+链表 get O(1) 提新 O(1) 淘汰 O(1)     42      92    35     134

  ✓ 语义一致：四份独立实现的 hits=42 misses=92 evictions=35 逐个相同

  work 条形图（每格 = 1/52 的 max）：
  A 数组线性查找 ###################..................... 1022
  B 手写哨兵链表 ######################################## 2086
  C std 链表       ######################################## 2086
  D 哈希表+链表 ##...................................... 134

  D 的 work 是 A 的 13%（越小越省；D 之所以是 D，就是这一行）
  B 与 C 的 work 相同 → 手写 60 行和调 std 一行，复杂度一模一样。
  std 省掉的是**代码量**，不是**复杂度**——这是选型时真正该记住的一句。
```

## 34.3 std.DoublyLinkedList 的真实 API

0.17 的 `std.DoublyLinkedList` 只有 12 个声明，而且**和大多数人的记忆不一样**。
先实测 `lib/std/DoublyLinkedList.zig`（全文 286 行）：

```zig
// lib/std/DoublyLinkedList.zig 第 24-27 行
pub const Node = struct {
    prev: ?*Node = null,
    next: ?*Node = null,
};
```

`Node` 里**只有两个指针，没有数据载荷**——它是**侵入式**的，要塞进自己的结构体，
再用 `@fieldParentPtr` 反查宿主。这是 7 章字段父指针的实战回收。

### 34.3.1 六个「不存在」和一个「别名」

| 你可能以为有 | 0.17 实测 | 说明 |
|---|---|---|
| `DoublyLinkedList.init()` | **不存在** | 声明用 `var l: std.DoublyLinkedList = .{}` |
| `DoublyLinkedList.iterator()` | **不存在** | 遍历手写 `while (it) |node| : (it = node.next)` |
| `DoublyLinkedList.fetchNode()` | **不存在** | 没有按条件找节点的现成方法 |
| `list.items` | **不存在** | 那是 `ArrayList` 的；链表只能从 `first`/`last` 走 |
| 哨兵节点 | **不存在** | `first`/`last` 都是 `?*Node`，空表是 `null` |
| `list.pop()` | ⚠️ 存在但是**废弃别名** | 源码第 138 行 `pub const pop = popLast;` |
| `list.len()` | ⚠️ 存在但 O(n) | 源码注释：「Consider tracking the length separately」 |

**没有哨兵**这一条要特别注意：34.2 的 B 版哨兵是**我们自己加的**。std 选择了
`null` 语义，代价是每个方向的操作都要判空。

### 34.3.2 insertBefore 不检查「已经相邻」——本章第一版的死循环

这是本节最值钱的一条。源码第 43-55 行：

```zig
// lib/std/DoublyLinkedList.zig 第 43-55 行
pub fn insertBefore(list: *DoublyLinkedList, existing_node: *Node, new_node: *Node) void {
    new_node.next = existing_node;
    if (existing_node.prev) |prev_node| {
        new_node.prev = prev_node;   // ← prev_node 可能就是 new_node 自己
        prev_node.next = new_node;
    } else {
        new_node.prev = null;
        list.first = new_node;
    }
    existing_node.prev = new_node;
}
```

`new_node.prev = prev_node` 这一行**没有判 `prev_node != new_node`**。把一个
**本来就紧挨着** `existing_node` 的节点再插一次（比如 `a` 已经在 `c` 前面，
还去 `insertBefore(&c, &a)`），此时 `a.prev` 就是 `a` 自己 → **自环** →
`while (it) |node| : (it = node.next)` **永不终止**。

本章第一版的 34.3 演示就是这么写的，实测把程序打成死循环（输出了 4 MB 才被 kill）。
正确用法：**`insert` 只用于新节点，或先 `remove` 再 `insert`**。

### 34.3.3 remove 要求节点确实在链表里

源码第 112 行的文档注释写得很清楚：`/// Assumes the node is in the list.`
对一个**已经被 `popLast` 摘掉**的节点调 `remove`，它会按残留的 `prev`/`next`
去改邻居，把链表写坏——而遍历时**看起来什么都没变**。

本章第一版 34.3 的最后一步写的就是 `remove(&c.link)`，而 `c` 刚被 `popLast()`
摘掉，结果两行输出完全一样（`{5 1 4}` → `{5 1 4}`），像 `remove` 没生效。
改成摘一个**仍在链表里**的节点（`d`）才看得出变化。

### 34.3.4 演示：五个节点走一遍双向遍历

```zig
// examples/34_zcache/main.zig 第 983-1048 行
fn sectionDoublyList() void {
    begin("34.3 std.DoublyLinkedList 的真实 API");
    const R = std.DoublyLinkedList;
    p("  ① 0.17 没有 init()：声明 `var l: std.DoublyLinkedList = .{{}}` 即可\n", .{});
    p("  ② 0.17 没有 iterator()、也没有 fetchNode()：遍历一律手写 first/next 循环\n", .{});
    p("     实测 @hasDecl：init={} iterator={} fetchNode={} pop={} popLast={}\n", .{
        @hasDecl(R, "init"), @hasDecl(R, "iterator"), @hasDecl(R, "fetchNode"),
        @hasDecl(R, "pop"),  @hasDecl(R, "popLast"),
    });
    p("  ③ pop 是 popLast 的**废弃别名**（源码里 `pub const pop = popLast`），新代码用 popLast\n", .{});
    p("  ④ 没有哨兵节点：first / last 都是 `?*Node`，空表是 null。\n", .{});
    p("     34.2 的 B 版哨兵是**我们自己加的**；哨兵的价值在于「摘头/挂尾/判空」\n", .{});
    p("     三处都不需要 null 分支。\n", .{});
    p("  ⑤ ⚠️⚠️ **insertBefore / insertAfter 不检查「已经相邻」**。把一个本来就紧挨着\n", .{});
    p("     existing_node 的节点再插一次，会写出 `a.prev = a`（源码里\n", .{});
    p("     `if (existing_node.prev) |prev_node| {{ new_node.prev = prev_node; ... }}`，\n", .{});
    p("     prev_node 就是 new_node 自己）→ 自环 → first/next 遍历**永不终止**。\n", .{});
    p("     本章第一版演示就是这么写的，实测把程序打成死循环。\n", .{});
    p("     正确用法：insert 只用于**新节点**，或先 remove 再 insert。\n", .{});

    var a: DllItem = .{ .id = 1 };
    var b: DllItem = .{ .id = 2 };
    var c: DllItem = .{ .id = 3 };
    var d: DllItem = .{ .id = 4 };
    var e: DllItem = .{ .id = 5 };
    var l: R = .{};
    l.append(&a.link); // {1}
    l.append(&c.link); // {1,3}
    l.prepend(&b.link); // {2,1,3}
    l.insertBefore(&c.link, &d.link); // {2,1,4,3}
    l.insertAfter(&b.link, &e.link); // {2,5,1,4,3}
    p("\n", .{});
    p("  演示：append(1) append(3) prepend(2) insertBefore(3,4) insertAfter(2,5) → ", .{});
    printDllList(&l);
    p("\n", .{});
    p("  first→last = 最新→最旧；last→first 可反向走（双向的另一半价值）：", .{});
    var it = l.last;
    var rev: [8]u32 = undefined;
    var n: usize = 0;
    while (it) |node| : (it = node.prev) {
        const item: *DllItem = @fieldParentPtr("link", node);
        rev[n] = item.id;
        n += 1;
    }
    for (rev[0..n]) |id| p("{d} ", .{id});
    p("\n", .{});

    _ = l.popFirst(); // 摘最新
    p("  popFirst() 摘掉最新 → ", .{});
    printDllList(&l);
    p("\n", .{});
    _ = l.popLast(); // 摘最旧
    p("  popLast()  摘掉最旧 → ", .{});
    printDllList(&l);
    p("\n", .{});
    // ⚠️ 必须 remove 一个**仍在链表里**的节点。写 &c.link（c 刚被 popLast 摘掉）
    // 会让 remove 按残留的 prev/next 去改邻居，链表被写坏而 printDllList 仍
    // 「看起来没变」——第一版就踩了：两行输出完全一样，像 remove 没生效。
    // 它的 remove 文档写得很清楚：「Assumes the node is in the list」。
    l.remove(&d.link);
    p("  remove(&d.link)（d 仍在链表里）→ ", .{});
    printDllList(&l);
    p("\n", .{});
    p("  len() = {d}（O(n)，源码注释明确建议「自己另记一个计数」而不是调它）\n", .{l.len()});
    end("34.3 std.DoublyLinkedList 的真实 API");
}
```

运行输出（`examples/34_zcache/main.zig`）：

```text
  ① 0.17 没有 init()：声明 `var l: std.DoublyLinkedList = .{}` 即可
  ② 0.17 没有 iterator()、也没有 fetchNode()：遍历一律手写 first/next 循环
     实测 @hasDecl：init=false iterator=false fetchNode=false pop=true popLast=true
  ③ pop 是 popLast 的**废弃别名**（源码里 `pub const pop = popLast`），新代码用 popLast
  ④ 没有哨兵节点：first / last 都是 `?*Node`，空表是 null。
     34.2 的 B 版哨兵是**我们自己加的**；哨兵的价值在于「摘头/挂尾/判空」
     三处都不需要 null 分支。
  ⑤ ⚠️⚠️ **insertBefore / insertAfter 不检查「已经相邻」**。把一个本来就紧挨着
     existing_node 的节点再插一次，会写出 `a.prev = a`（源码里
     `if (existing_node.prev) |prev_node| { new_node.prev = prev_node; ... }`，
     prev_node 就是 new_node 自己）→ 自环 → first/next 遍历**永不终止**。
     本章第一版演示就是这么写的，实测把程序打成死循环。
     正确用法：insert 只用于**新节点**，或先 remove 再 insert。

  演示：append(1) append(3) prepend(2) insertBefore(3,4) insertAfter(2,5) → {2 5 1 4 3}
  first→last = 最新→最旧；last→first 可反向走（双向的另一半价值）：3 4 1 5 2 
  popFirst() 摘掉最新 → {5 1 4 3}
  popLast()  摘掉最旧 → {5 1 4}
  remove(&d.link)（d 仍在链表里）→ {5 1}
  len() = 2（O(n)，源码注释明确建议「自己另记一个计数」而不是调它）
```

## 34.4 LRU 缓存核心：HashMap + 双向链表，键的生命周期

### 34.4.1 两个结构，各司其职

| 结构               | 职责              | 复杂度 |
|--------------------|-------------------|--------|
| StringHashMap      | 按键 O(1) 定位条目 | O(1)   |
| DoublyLinkedList   | O(1) 记新旧序     | O(1)   |

**缺一不可**：单用 HashMap，找得到但**不知谁最旧**（淘汰就得全表扫，变 O(n)）；
单用链表，知新旧但**找不快**（定位键变 O(n)）。合体后：

- `get` 命中即 `touch`——摘下重挂队首，O(1)；
- 淘汰就是摘链表尾巴（`popLast`），**完全不用扫描**，O(1)。

至此**全部操作都是 O(1)**。这就是 34.2 表格里 D 那一行的由来。

### 34.4.2 put 不复制键——本章亲手实测的后果

`std.StringHashMap` 的 `put` **只存切片本身**（`ptr` + `len`），不复制内容。
源码注释说得很清楚：

```zig
// lib/std/hash_map.zig 第 60-66 行
/// Builtin hashmap for strings as keys.
/// Key memory is managed by the caller.  Keys and values
/// will not automatically be freed.
pub fn StringHashMap(comptime V: type) type {
    return HashMap([]const u8, V, StringContext, default_max_load_percentage);
}
```

实测后果（34.4 的运行输出）：把一个**栈上缓冲**的切片 `put` 进去，再改写那个缓冲，
**键的内容随之改变**。此时哈希值已经算过、桶位已经定好，于是：

- `get("KEY")` → `null`（内容变了）
- `get("ZZZ")` → `null`（桶位是按旧哈希算的，新内容找不到任何桶）
- `count()` → `1`（条目一直都在，只是「是谁」已经说不清了）

**这是最难查的一类 bug**：不崩溃、不报错、数据还在，只是查不到。

### 34.4.3 0.17 没有 putOwned

这是 0.17 与网上多数说法不同的一条。运行输出里印的那行：

```text
  ⚠️ 0.17 的 StringHashMap **没有 putOwned**（@hasDecl 实测 = false）
  → 0.17 的唯一正确写法就是本章生产核用的：**先 dupe 再 put**。
  这样 map 的键与 entry.key 指向同一份自有内存，deinit 沿链表释放一次即可，
  map.deinit() 只放桶数组、不碰键（源码注释：Key memory is managed by the caller）。
```

`std.StringHashMap` 在 0.17 **没有 `putOwned`，也没有 `getOrPutOwned`**。
所以 0.17 的**唯一**正确写法就是本章生产核用的：**先 `dupe` 再 `put`**：

```zig
// examples/34_zcache/main.zig 第 510-514 行
    fn init(l: *Lru, a: std.mem.Allocator, capacity: usize) void {
        l.* = .{ .a = a, .capacity = capacity, .map = std.StringHashMap(*Entry).init(a) };
    }

    fn deinit(l: *Lru) void {
```

这样做还顺带解决了一个所有权问题：`map` 的键和 `entry.key` **指向同一份内存**，
`deinit` 沿链表走一遍释放一次即可，而 `map.deinit()` 只放桶数组、不碰键。
如果 `put` 的是调用方的缓冲，`deinit` 就**没法**释放它（那是别人的内存），
也**不敢**释放（万一已经被改写）。

### 34.4.4 自引用结构体不能在 init 里就地绑定

这条在 34.2 的 `StdListLru` 上实测炸过（**Segmentation fault**），在 34.6 的
`Conn` 上是同一个坑的另一种表现。

`StdListLru.init` 会往 `l.pool` 的地址上挂链表节点。如果它写成
`fn init(...) StdListLru { var l = StdListLru{...}; ...; return l; }`，
那么 `return l` 发生值拷贝，链表里的指针**全部指向 init 的栈帧**——函数一返回
就是悬垂指针。实测段错误。

铁律：**`init` 只做纯赋值**。要往自己的字段里写指针，就用
`fn init(self: *T, ...)` 原地初始化：

```zig
// examples/34_zcache/main.zig 第 493-616 行
pub const Lru = struct {
    const Entry = struct {
        key: []u8, // 自有（map 的键也指向这份）
        value: []u8, // 自有
        link: std.DoublyLinkedList.Node = .{}, // 侵入式链表节点
    };

    a: std.mem.Allocator,
    capacity: usize,
    map: std.StringHashMap(*Entry),
    order: std.DoublyLinkedList = .{},
    hits: usize = 0,
    misses: usize = 0,
    evictions: usize = 0,
    bytes: usize = 0, // 键 + 值总字节（自有部分）
    work: usize = 0, // 基本操作计数：哈希查找次数

    fn init(l: *Lru, a: std.mem.Allocator, capacity: usize) void {
        l.* = .{ .a = a, .capacity = capacity, .map = std.StringHashMap(*Entry).init(a) };
    }

    fn deinit(l: *Lru) void {
        var node = l.order.first;
        while (node) |n| {
            const next = n.next; // 先存 next：下面要 free 掉宿主
            const entry: *Entry = @fieldParentPtr("link", n);
            l.a.free(entry.key);
            l.a.free(entry.value);
            l.a.destroy(entry);
            node = next;
        }
        l.map.deinit(); // 只放表，不放键（键的内存归 Entry）
    }

    fn get(l: *Lru, key: []const u8) ?[]const u8 {
        l.work += 1;
        const entry = l.map.get(key) orelse {
            l.misses += 1;
            return null;
        };
        l.hits += 1;
        l.order.remove(&entry.link);
        l.order.prepend(&entry.link);
        return entry.value;
    }

    fn put(l: *Lru, key: []const u8, value: []const u8) !void {
        if (l.map.get(key)) |entry| { // 更新已有键：换值 + 提新，不占新位
            const nv = try l.a.dupe(u8, value);
            l.bytes -= entry.value.len;
            l.bytes += nv.len;
            l.a.free(entry.value);
            entry.value = nv;
            l.order.remove(&entry.link);
            l.order.prepend(&entry.link);
            return;
        }
        const entry = try l.a.create(Entry);
        errdefer l.a.destroy(entry);
        entry.* = .{
            .key = try l.a.dupe(u8, key), // ⚠️ 必须 dupe：map 不复制键
            .value = try l.a.dupe(u8, value),
        };
        errdefer {
            l.a.free(entry.key);
            l.a.free(entry.value);
        }
        l.bytes += entry.key.len + entry.value.len;
        try l.map.put(entry.key, entry); // 键与 entry.key 同一份内存
        l.order.prepend(&entry.link);

        // 淘汰时机在**插入之后**：先插再 while 超容量摘尾。先删后插会在
        // 「恰好满容量」时误删一个活键。
        while (l.map.count() > l.capacity) {
            const victim_node = l.order.popLast() orelse unreachable;
            const victim: *Entry = @fieldParentPtr("link", victim_node);
            _ = l.map.remove(victim.key); // 用 key 摘表（此刻键还没 free）
            l.a.free(victim.key);
            l.a.free(victim.value);
            l.bytes -= victim.key.len + victim.value.len;
            l.a.destroy(victim);
            l.evictions += 1;
        }
    }

    fn del(l: *Lru, key: []const u8) bool {
        const entry = l.map.get(key) orelse return false;
        _ = l.map.remove(key);
        l.order.remove(&entry.link);
        l.bytes -= entry.key.len + entry.value.len;
        l.a.free(entry.key);
        l.a.free(entry.value);
        l.a.destroy(entry);
        return true;
    }

    fn entries(l: *Lru) usize {
        return l.map.count();
    }

    /// 从队首（最新）到队尾（最旧）遍历。
    /// ⚠️ 名字是 keysNewestFirst 不是 keysOldestFirst：第一版叫后者，
    /// 测试照着名字断言 buf[0] == "b"（最旧），实得 "a"（最新）当场炸——
    /// 一个和实现方向相反的函数名，比没有名字更危险。
    fn keysNewestFirst(l: *const Lru, out: [][]const u8) usize {
        var n: usize = 0;
        var node = l.order.first;
        while (node) |x| {
            const e: *Entry = @fieldParentPtr("link", x);
            if (n < out.len) out[n] = e.key;
            n += 1;
            node = x.next;
        }
        return n;
    }

    /// 命中率（整数百分比）。hits + misses 为 0 时返回 0——**不是**除零 panic，
    /// 也不是 100：空窗口的命中率在语义上就是「无可命中」，报 0 最不容易误导。
    fn hitRatePercent(l: *const Lru) usize {
        const total = l.hits + l.misses;
        if (total == 0) return 0;
        return l.hits * 100 / total;
    }
};
```

```zig
// examples/34_zcache/main.zig 第 1054-1090 行
fn sectionKeyLifetime(a: std.mem.Allocator) !void {
    begin("34.4 键的生命周期：put 不复制键");
    p("  `StringHashMap` 的 put **只存切片本身**（ptr + len），不复制内容。\n", .{});
    p("  实测后果：把栈上缓冲的切片 put 进去再改写那个缓冲，**键的内容随之改变**——\n", .{});
    p("  哈希已经算过了，桶还在老位置，于是查找全部落空。\n", .{});
    p("\n", .{});

    var m = std.StringHashMap(u32).init(a);
    defer m.deinit();
    var scratch = [_]u8{ 'K', 'E', 'Y', 'A', 'A', 'A', 'A', 'A' };
    try m.put(scratch[0..3], 7);
    p("  put(scratch[0..3]=\"KEY\") 之后：get(\"KEY\") = {?d}  ← 此刻还是对的\n", .{m.get("KEY")});
    @memcpy(scratch[0..3], "ZZZ");
    p("  改写 scratch 为 \"ZZZ\" 之后：\n", .{});
    p("    get(\"KEY\") = {?d}   ← 键的内容被就地改了，老键查不到\n", .{m.get("KEY")});
    p("    get(\"ZZZ\") = {?d}  ← 新内容也查不到：桶位是按旧哈希算的\n", .{m.get("ZZZ")});
    p("    count() = {d}       ← 条目一直都在，只是「谁」已经说不清了\n", .{m.count()});
    p("\n", .{});
    p("  ⚠️ 0.17 的 StringHashMap **没有 putOwned**（@hasDecl 实测 = {}）\n", .{
        @hasDecl(std.StringHashMap(u32), "putOwned"),
    });
    p("  → 0.17 的唯一正确写法就是本章生产核用的：**先 dupe 再 put**。\n", .{});
    p("  这样 map 的键与 entry.key 指向同一份自有内存，deinit 沿链表释放一次即可，\n", .{});
    p("  map.deinit() 只放桶数组、不碰键（源码注释：Key memory is managed by the caller）。\n", .{});
    p("\n", .{});

    // 正面验证：dupe 之后改写原缓冲，键不受影响
    var m2 = std.StringHashMap(u32).init(a);
    defer m2.deinit();
    var scratch2 = [_]u8{ 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H' };
    const owned = try a.dupe(u8, scratch2[0..3]);
    defer a.free(owned);
    try m2.put(owned, 9);
    @memcpy(scratch2[0..3], "QQQ");
    p("  对照组：dupe 之后再 put，改写原缓冲 → get(\"ABC\") = {?d}（键安然无恙）\n", .{m2.get("ABC")});
    end("34.4 键的生命周期：put 不复制键");
}
```

运行输出（`examples/34_zcache/main.zig`）：

```text
  `StringHashMap` 的 put **只存切片本身**（ptr + len），不复制内容。
  实测后果：把栈上缓冲的切片 put 进去再改写那个缓冲，**键的内容随之改变**——
  哈希已经算过了，桶还在老位置，于是查找全部落空。

  put(scratch[0..3]="KEY") 之后：get("KEY") = 7  ← 此刻还是对的
  改写 scratch 为 "ZZZ" 之后：
    get("KEY") = null   ← 键的内容被就地改了，老键查不到
    get("ZZZ") = null  ← 新内容也查不到：桶位是按旧哈希算的
    count() = 1       ← 条目一直都在，只是「谁」已经说不清了

  ⚠️ 0.17 的 StringHashMap **没有 putOwned**（@hasDecl 实测 = false）
  → 0.17 的唯一正确写法就是本章生产核用的：**先 dupe 再 put**。
  这样 map 的键与 entry.key 指向同一份自有内存，deinit 沿链表释放一次即可，
  map.deinit() 只放桶数组、不碰键（源码注释：Key memory is managed by the caller）。

  对照组：dupe 之后再 put，改写原缓冲 → get("ABC") = 9（键安然无恙）
```

## 34.5 容量淘汰与统计

### 34.5.1 淘汰时机必须在插入之后

```zig
try l.map.put(entry.key, entry);
l.order.prepend(&entry.link);

// 先插再 while 超容量摘尾
while (l.map.count() > l.capacity) { /* 摘 popLast() */ }
```

先删后插会在「**恰好满容量**」时误删一个活键：比如容量 3、已有 a/b/c，
现在要 PUT 一个**新键** d——先删就会先砍掉一个还没被淘汰的键。

### 34.5.2 三个计数器和一个字节账

| 字段 | 含义 | 谁维护 |
|---|---|---|
| `hits` / `misses` | 命中/未中次数 | `get` |
| `evictions` | 累计淘汰次数 | `put` 的 while 循环 |
| `entries` | 当前条目数 | `map.count()` |
| `bytes` | 键 + 值总字节（自有部分） | `put`/`del`/eviction 三处 |

`bytes` 是**长跑缓存**的关键指标：`entries` 只告诉你「有几个键」，
`bytes` 告诉你「占多少内存」。两者不匹配（键很短值很长）时，只有 `bytes` 能看出问题。

### 34.5.3 命中率的空窗口返回 0，不返回 100

```zig
fn hitRatePercent(l: *const Lru) usize {
    const total = l.hits + l.misses;
    if (total == 0) return 0;          // 不是除零 panic，也不是 100
    return l.hits * 100 / total;
}
```

`hits + misses == 0` 时返回 **0** 而不是 100：空窗口的命中率在语义上就是
「无可命中」。报 100 会让监控图上出现一个假的满分峰值，比报 0 危险得多。

### 34.5.4 整数百分比会截断

`hits=1, misses=2` → `1*100/3 = 33`。这是**向下截断**，不是四舍五入。
文档和断言里都按截断写（单测 `命中率 = 33%`）。要四舍五入就写
`(hits * 100 + total / 2) / total`——但那会让边界值更难断言，本章选截断。

```zig
// examples/34_zcache/main.zig 第 1096-1144 行
fn sectionEviction(a: std.mem.Allocator) !void {
    begin("34.5 容量淘汰与统计");
    var lru: Lru = undefined;
    lru.init(a, 3);
    defer lru.deinit();

    try lru.put("a", "1");
    try lru.put("b", "2");
    try lru.put("c", "3");
    p("  容量 3：PUT a b c → 条目 {d}，字节 {d}\n", .{ lru.entries(), lru.bytes });
    p("  淘汰序（最旧→最新）：", .{});
    printOrder(&lru);
    p("\n", .{});

    _ = lru.get("a"); // a 提新 → b 变成最旧
    p("  GET a（命中，a 提新）→ 淘汰序：", .{});
    printOrder(&lru);
    p("\n", .{});

    try lru.put("d", "4"); // 超容量 → 淘汰 b，不是 a
    p("  PUT d（超容量）→ 淘汰次数 {d}，条目 {d}\n", .{ lru.evictions, lru.entries() });
    p("  淘汰序（最旧→最新）：", .{});
    printOrder(&lru);
    p("\n", .{});
    // ⚠️ 打印可选切片要写 `{?}`（不是 `{?d}`）——`?d` 是给可选**整数**用的格式，
    // 切片没有 d 格式，编译器报 "invalid format string 'd' for type '[]const u8'"。
    const vb = lru.get("b");
    const va = lru.get("a");
    p("  GET b = {?s}（空切片=已被淘汰）  GET a = {?s}（被访问过所以活着）\n", .{ vb, va });

    p("\n", .{});
    p("  hits={d} misses={d} → 命中率 {d}%\n", .{ lru.hits, lru.misses, lru.hitRatePercent() });
    var empty: Lru = undefined;
    empty.init(a, 1);
    defer empty.deinit();
    p("  空窗口（hits=misses=0）→ 命中率 {d}%（不 panic、不报 100，报 0 最不误导）\n", .{
        empty.hitRatePercent(),
    });

    const before_bytes = lru.bytes;
    _ = lru.del("a");
    p("\n", .{});
    p("  DEL a：字节 {d} → {d}（{d} = len(\"a\") + len(\"1\")）\n", .{
        before_bytes, lru.bytes, before_bytes - lru.bytes,
    });
    _ = lru.del("nope");
    p("  DEL 不存在的键：返回 false，字节仍是 {d}（不误改计数）\n", .{lru.bytes});
    end("34.5 容量淘汰与统计");
}
```

运行输出（`examples/34_zcache/main.zig`）：

```text
  容量 3：PUT a b c → 条目 3，字节 6
  淘汰序（最旧→最新）：a < b < c
  GET a（命中，a 提新）→ 淘汰序：b < c < a
  PUT d（超容量）→ 淘汰次数 1，条目 3
  淘汰序（最旧→最新）：c < a < d
  GET b = null（空切片=已被淘汰）  GET a = 1（被访问过所以活着）

  hits=2 misses=1 → 命中率 66%
  空窗口（hits=misses=0）→ 命中率 0%（不 panic、不报 100，报 0 最不误导）

  DEL a：字节 6 → 4（2 = len("a") + len("1")）
  DEL 不存在的键：返回 false，字节仍是 4（不误改计数）
```

## 34.6 网络层：多线程 accept 与 io 调度

### 34.6.1 listen(0) 与 0.17 的 ephemeral 端口

0.17 的 `Socket` 结构体多了一个 `address` 字段，注释写得很清楚：

```zig
// lib/std/Io/net.zig 第 1055-1059 行
pub const Socket = struct {
    handle: Handle,
    /// Contains the resolved ephemeral port number if requested.
    address: IpAddress,
};
```

于是 `listen(0)` 之后 `srv.socket.address.getPort()` 直接可读。0.16 时代
「绑 0 拿临时端口」行不通，本书原来写的是「固定端口 + 向上扫 20 个」的笨办法
（`while (p < base + 20)`）。本章用新写法，并且**只印「非 0：是」**——
端口号本身是内核按序分配的，会漂。

### 34.6.2 accept 要 *Server，const 也不收

```zig
// lib/std/Io/net.zig 第 1590-1593 行
/// Blocks until a client connects to the server.
pub fn accept(s: *Server, io: Io) AcceptError!Stream {
    return .{ .socket = try io.vtable.netAccept(io.userdata, s.socket.handle, s.options) };
}
```

接收者是 `*Server`（不是 `*const Server`），所以 `srv` 必须是**可寻址的局部变量**。
`deinit` 同理（`pub fn deinit(s: *Server, io: Io) void`）。

### 34.6.3 关停协议：accept 是阻塞的，没有「从外部唤醒」的办法

这是本章第一版栽得最狠的地方。原设计是**预算式关停**：注释里写
「连接预算：34.6(4) + 34.7(1) + ... + 34.14(1) = 14」，服务器 accept 够 14 条就退出。
后来加了 34.6 / 34.12 两个并发段（每个 4 条 + 2 条 STAT 快照），实际要 **18** 条——
预算耗尽，主线程 `connect` 直接拿到 `error.ConnectionRefused`，程序失败。

**「连接条数」是个会随代码演进而漂的量，不该出现在关停逻辑里。**
现在的做法是「置 stop 标志 + 建一条空连接把 accept 叫醒」：

1. 主线程跑完所有章节 → `ctx.stop.store(true)`；
2. 建一条**立刻关掉**的连接 → 服务端 `accept` 返回；
3. 服务端看到 `stop`，关掉这条连接，跳出循环；
4. 主线程 `join()` 返回。

这样无论将来加多少连接，代码都不用改。

```zig
// examples/34_zcache/main.zig 第 766-810 行
fn serve(ctx: *Ctx, port: *std.atomic.Value(u16)) void {
    const addr = std.Io.net.IpAddress.parseIp4("127.0.0.1", 0) catch {
        ctx.failed.store(true, .release);
        return;
    };
    var srv = addr.listen(ctx.io, .{ .reuse_address = true }) catch {
        ctx.failed.store(true, .release);
        return;
    };
    // ⚠️ 端口 0 = 让内核分配。0.17 的 `Socket.address` 带回了绑定后的真实端口，
    // `getPort()` 直接可读——0.16 时代「绑 0 拿临时端口」行不通，逼得所有人
    // 写「固定端口 + 向上扫 20 个」的笨办法。
    const real_port = srv.socket.address.getPort();
    port.store(real_port, .release);

    var threads: [max_conn_threads]std.Thread = undefined;
    var n: usize = 0;
    while (true) {
        const stream = srv.accept(ctx.io) catch {
            ctx.failed.store(true, .release);
            break;
        };
        if (ctx.stop.load(.acquire)) { // 关停握手：这条连接只用来把 accept 叫醒
            stream.close(ctx.io);
            break;
        }
        if (n == threads.len) { // 槽满：先收最早那条（本章并发 ≤ 5，走不到）
            threads[0].join();
            std.mem.copyForwards(std.Thread, threads[0 .. threads.len - 1], threads[1..]);
            n -= 1;
        }
        threads[n] = std.Thread.spawn(.{}, handleConn, .{ ctx, stream }) catch {
            stream.close(ctx.io);
            ctx.failed.store(true, .release);
            break;
        };
        _ = ctx.served.fetchAdd(1, .release);
        n += 1;
    }
    for (threads[0..n]) |t| t.join();
    srv.deinit(ctx.io);
}

// ═══════════════════════════════════════════════════════════════════════════
// 客户端助手
```

### 34.6.4 每条连接一个线程

`Server` 本身不是线程安全的，但 **accept 之后再 fork，各服务各的，互不干扰**。
本章的槽位上限是 32（`max_conn_threads`），并发峰值 5，走不到「槽满回收最早那条」
那条路径——它是留给将来把本章改成常驻服务时的保险。

### 34.6.5 锁只罩住「读改写 LRU」

`Ctx.dispatch` 里每条命令都是「上锁 → 读改写 LRU → 解锁 → 才发应答」。
**网络收发不进锁**——否则一个慢客户端（不发数据只占着连接）能把整台服务器卡住。

```zig
```zig
// examples/34_zcache/main.zig 第 674-728 行
    fn dispatch(self: *Ctx, conn: *Conn, line: []const u8) !void {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const cmd = it.next() orelse return conn.sendLine("ERR empty");

        if (std.mem.eql(u8, cmd, "PING")) {
            if (it.next() != null) return conn.sendLine("ERR usage PING");
            return conn.sendLine("PONG");
        }
        if (std.mem.eql(u8, cmd, "STAT")) {
            if (it.next() != null) return conn.sendLine("ERR usage STAT");
            var buf: [160]u8 = undefined;
            self.lock.lockUncancelable(self.io);
            const resp = std.fmt.bufPrint(&buf, "STAT hits={d} misses={d} evictions={d} entries={d} bytes={d}", .{
                self.lru.hits, self.lru.misses, self.lru.evictions, self.lru.entries(), self.lru.bytes,
            }) catch unreachable;
            self.lock.unlock(self.io);
            return conn.sendLine(resp);
        }
        if (std.mem.eql(u8, cmd, "GET")) {
            const key = it.next() orelse return conn.sendLine("ERR usage GET <key>");
            if (it.next() != null) return conn.sendLine("ERR usage GET <key>");
            if (key.len > max_key) return conn.sendLine("ERR key too long");
            self.lock.lockUncancelable(self.io);
            const v = self.lru.get(key);
            self.lock.unlock(self.io);
            if (v) |val| {
                var buf: [max_line]u8 = undefined;
                const resp = std.fmt.bufPrint(&buf, "VALUE {s}", .{val}) catch return conn.sendLine("ERR value too long");
                return conn.sendLine(resp);
            }
            return conn.sendLine("MISS");
        }
        if (std.mem.eql(u8, cmd, "PUT")) {
            const key = it.next() orelse return conn.sendLine("ERR usage PUT <key> <value>");
            const val = it.rest(); // rest 天然支持「值里含空格」
            if (key.len > max_key) return conn.sendLine("ERR key too long");
            if (val.len == 0) return conn.sendLine("ERR usage PUT <key> <value>");
            if (val.len > max_value) return conn.sendLine("ERR value too long");
            self.lock.lockUncancelable(self.io);
            const r = self.lru.put(key, val);
            self.lock.unlock(self.io);
            r catch return conn.sendLine("ERR oom");
            return conn.sendLine("OK");
        }
        if (std.mem.eql(u8, cmd, "DEL")) {
            const key = it.next() orelse return conn.sendLine("ERR usage DEL <key>");
            if (it.next() != null) return conn.sendLine("ERR usage DEL <key>");
            if (key.len > max_key) return conn.sendLine("ERR key too long");
            self.lock.lockUncancelable(self.io);
            const removed = self.lru.del(key);
            self.lock.unlock(self.io);
            return conn.sendLine(if (removed) "OK" else "MISS");
        }
        return conn.sendLine("ERR unknown");
    }
```

### 34.6.6 4 客户端并发：断言形状不断言内容

每个客户端写**自己**的键空间（`p0_0`..`p0_15`），读自己的键，
校验和写进**自己那个槽位**。主线程按槽位顺序汇总——
**无论线程怎么交错，主线程印出来的数字都是确定的**。

这是并发测试的通用心法：**按固定下标写结果，不按完成顺序汇总**。

```zig
// examples/34_zcache/main.zig 第 1161-1201 行
fn concurrentWorker(arg: ClientArg) void {
    var conn = connect(arg.io, arg.port) catch {
        arg.ctx.failed.store(true, .release);
        return;
    };
    defer conn.close();
    var sbuf: [128]u8 = undefined;
    var rbuf: [max_line]u8 = undefined;
    var i: usize = 0;
    while (i < 250) : (i += 1) {
        var keybuf: [32]u8 = undefined;
        const key = std.fmt.bufPrint(&keybuf, "{s}_{d}", .{ arg.tag, i % 16 }) catch return;
        const put = std.fmt.bufPrint(&sbuf, "PUT {s} v{d}", .{ key, i }) catch return;
        conn.sendLine(put) catch {
            arg.ctx.failed.store(true, .release);
            return;
        };
        if (!std.mem.eql(u8, conn.recvLine(&rbuf) catch return, "OK")) {
            arg.ctx.failed.store(true, .release);
            return;
        }
        const get = std.fmt.bufPrint(&sbuf, "GET {s}", .{key}) catch return;
        conn.sendLine(get) catch {
            arg.ctx.failed.store(true, .release);
            return;
        };
        const reply = conn.recvLine(&rbuf) catch {
            arg.ctx.failed.store(true, .release);
            return;
        };
        // 形状必须对：VALUE <key> v<i>
        if (!std.mem.startsWith(u8, reply, "VALUE ")) {
            arg.ctx.failed.store(true, .release);
            return;
        }
        arg.checksum.* +%= std.hash.Wyhash.hash(0, reply);
    }
}

var buf0: [max_line]u8 = undefined;

```

```zig
// examples/34_zcache/main.zig 第 1205-1218 行
fn runWorkers(io: std.Io, ctx: *Ctx, port: u16, tags: []const []const u8) !PoolResult {
    var sums = [4]u64{ 0, 0, 0, 0 };
    var workers: [4]std.Thread = undefined;
    for (&workers, 0..) |*w, i| {
        w.* = try std.Thread.spawn(.{}, concurrentWorker, .{
            ClientArg{ .ctx = ctx, .io = io, .port = port, .tag = tags[i], .checksum = &sums[i] },
        });
    }
    for (workers) |w| w.join();
    var total: u64 = 0;
    for (sums) |s| total +%= s;
    return .{ .total = total, .sums = sums };
}

```

```zig
// examples/34_zcache/main.zig 第 1248-1267 行
    // ═══ 34.6 网络层：多线程 accept ═══
    begin("34.6 网络层与并发接入");
    p("  listen(0) 拿到的端口 > 0：{s}（端口号本身不印，内核按序分配会漂）\n", .{
        if (prt != 0) "是" else "否",
    });
    p("  ⚠️ 0.17 的 Socket.address 带回了绑定后的真实端口（getPort 直接可读）\n", .{});
    p("  accept 要 *Server（const 也不收）→ srv 是可寻址局部变量；每接一条 spawn 一个线程\n", .{});
    {
        const before = try snapshot(io, prt);
        const tags = [_][]const u8{ "p0", "p1", "p2", "p3" };
        const res = try runWorkers(io, &ctx, prt, &tags);
        const after = try snapshot(io, prt);
        if (ctx.failed.load(.acquire)) return error.ConcurrentClientFailed;
        try expectDelta(before, after, 1000, 0, 0);
        p("  ✓ 4 条连接并发接入，各 250 轮 PUT+GET（共 {d} 条命令）全部成功\n", .{2000});
        p("    STAT 增量 hits+{d} misses+{d} evictions+{d}（键空间 64 < 容量 → 零淘汰）\n", .{
            after.hits - before.hits, after.misses - before.misses, after.evictions - before.evictions,
        });
        p("    4 客户端汇总校验和 = {d}（按槽位汇总，与完成顺序无关 → 确定）\n", .{res.total});
    }
```

运行输出（`examples/34_zcache/main.zig`）：

```text
  listen(0) 拿到的端口 > 0：是（端口号本身不印，内核按序分配会漂）
  ⚠️ 0.17 的 Socket.address 带回了绑定后的真实端口（getPort 直接可读）
  accept 要 *Server（const 也不收）→ srv 是可寻址局部变量；每接一条 spawn 一个线程
  ✓ 4 条连接并发接入，各 250 轮 PUT+GET（共 2000 条命令）全部成功
    STAT 增量 hits+1000 misses+0 evictions+0（键空间 64 < 容量 → 零淘汰）
    4 客户端汇总校验和 = 3571497112617551328（按槽位汇总，与完成顺序无关 → 确定）
```

## 34.7 行协议解析：fillMore + buffered + indexOfScalarPos + toss

### 34.7.1 为什么不能用 takeDelimiterExclusive

0.17.0 的 std 有 bug。看源码（`lib/std/Io/Reader.zig` 第 894-898 行）：

```zig
pub fn takeDelimiterExclusive(r: *Reader, delimiter: u8) DelimiterError![]u8 {
    const result = try r.peekDelimiterExclusive(delimiter);
    r.toss(result.len);        // ← result 不含分隔符！
    return result;
}
```

`peekDelimiterExclusive` 返回**不含分隔符**的切片，于是只 `toss(result.len)`
会把分隔符**留在缓冲里**。第一次调用看起来正常（因为它返回的正是想要的），
第二次起 `peekDelimiterInclusive` 立刻看到那个残留的 `'\n'` → 返回长度为 0 的切片。

**最小复现（不需要网络）**，本章单测里就有：

```zig
const src = "ab\ncd\n";
var r: std.Io.Reader = .fixed(src);
const first = try r.takeDelimiterExclusive('\n');   // "ab"  ← 对
const second = try r.takeDelimiterExclusive('\n');  // ""    ← 应为 "cd"
```

> 顺带一个 0.17 的语法坑：`second.?len` 写不出来——`second` 是 error union，
> `.?` 不适用；而且 Zig 的 tokenizer 会把 `.?len` 解析成「参数后缺逗号」
> 的语法错误（`expected ',' after argument`）。必须先 `const got = try second;`。

### 34.7.2 正确写法：四步缺一不可

| 步骤 | 做什么 | 不做会怎样 |
|---|---|---|
| `fillMore()` | 做一次底层读，把字节拉进内部缓冲 | 手上没数据 |
| `buffered()` | 看**此刻已就绪**的字节（≠ socket 里的全部） | 无从下手 |
| `indexOfScalarPos(.., '\n')` | 在就绪字节里定位分隔符 | 分片到达就漏判 |
| `toss(at + 1)` | 丢弃已取走的部分，**含分隔符本身** | 残留 `'\n'` 被当成空行 |

`scanned` 变量是**跨轮次**的游标：第一轮扫过前半段没找到 `'\n'`，
把 `scanned` 记成 `avail.len`，下一轮从那里继续找——**不重复扫**。

```zig
// examples/34_zcache/main.zig 第 96-119 行
    fn recvLine(self: *Conn, out: []u8) ![]u8 {
        self.ensureBound();
        const r = &self.r.interface;
        var scanned: usize = 0; // 已扫过但不属于本行的字节数（下一轮跳过）
        while (true) {
            const avail = r.buffered();
            if (std.mem.indexOfScalarPos(u8, avail, scanned, '\n')) |at| {
                // ⚠️ 长度检查必须在 toss **之前**：抛 LineTooLong 时必须
                // 「一个字节都不消费」，否则调用方无法把残余行清干净。
                if (at - scanned > out.len) return error.LineTooLong;
                const line = avail[scanned..at];
                r.toss(at + 1); // 连 '\n' 一起吃掉
                @memcpy(out[0..line.len], line);
                return out[0..line.len];
            }
            scanned = avail.len;
            if (scanned > out.len) return error.LineTooLong; // 整段没 '\n'：闸门触发
            r.fillMore() catch |err| switch (err) {
                error.EndOfStream => return error.ConnectionClosed,
                error.ReadFailed => return error.ReadFailed,
            };
        }
    }

```

### 34.7.3 一次写 4 条命令，读 4 条应答

这是对分片处理最直接的验证：客户端连续 `sendLine` 四次，TCP 可能把它们
合并成**一次** `fillMore`（也可能分成四次）。无论哪种，服务端都要正确地
切出 4 行、读干净缓冲。运行输出末尾的「未消费字节数 = 0」证明没有残留。

```zig
// examples/34_zcache/main.zig 第 1270-1292 行
    // ═══ 34.7 行协议解析 ═══
    begin("34.7 行协议解析");
    {
        var conn = try connect(io, prt);
        var buf: [max_line]u8 = undefined;
        // ⚠️ 格式串里要印字符 '\n' 必须写 `\\n`（两个反斜杠）：写 `\n` 会被
        // 格式化器当成真换行，输出里就断成两行了。
        p("  fillMore() → buffered() → indexOfScalarPos('\\n') → toss(at+1)，四步缺一不可\n", .{});
        p("  ⚠️ 不能用 takeDelimiterExclusive：0.17 std bug，只 toss(result.len) 而\n", .{});
        p("     result 不含分隔符 → 分隔符留在缓冲里，第二次起永远返回空片\n", .{});
        try conn.sendLine("PUT lp 1");
        try conn.sendLine("PUT lq 2");
        try conn.sendLine("GET lp");
        try conn.sendLine("PING");
        p("  一次写 4 条命令（TCP 可能合并成一次 fillMore），逐条读回应：\n", .{});
        for ([_][]const u8{ "OK", "OK", "VALUE 1", "PONG" }) |want| {
            const got = try conn.recvLine(&buf);
            p("    {s:<10} {s}\n", .{ got, if (std.mem.eql(u8, got, want)) "✓" else "✗" });
            if (!std.mem.eql(u8, got, want)) return error.ProtocolMismatch;
        }
        p("  未消费字节数 = {d}（4 条命令全部消费干净）\n", .{conn.pending()});
        conn.close();
    }
```

运行输出（`examples/34_zcache/main.zig`）：

```text
  fillMore() → buffered() → indexOfScalarPos('\n') → toss(at+1)，四步缺一不可
  ⚠️ 不能用 takeDelimiterExclusive：0.17 std bug，只 toss(result.len) 而
     result 不含分隔符 → 分隔符留在缓冲里，第二次起永远返回空片
  一次写 4 条命令（TCP 可能合并成一次 fillMore），逐条读回应：
    OK         ✓
    OK         ✓
    VALUE 1    ✓
    PONG       ✓
  未消费字节数 = 0（4 条命令全部消费干净）
```

## 34.8 超长行与缓冲区上限

### 34.8.1 闸门：恶意对端发 1MB 请求行

没有行长闸门，一个 `PUT k <1MB>` 就能让服务端一次分配 1MB——
一条连接就能打爆内存。闸门就是 `recvLine` 的 `out` 参数（本节 1024）。

### 34.8.2 ⚠️ 长度检查必须在 toss 之前

这是本节最关键的一行代码。`recvLine` 抛 `LineTooLong` 时必须
**一个字节都不消费**：

```zig
if (std.mem.indexOfScalarPos(u8, avail, scanned, '\n')) |at| {
    if (at - scanned > out.len) return error.LineTooLong;   // ← 在 toss 之前
    const line = avail[scanned..at];
    r.toss(at + 1);
```

如果先 `toss` 再判长度，超长行的前半截就被消费掉了，缓冲里只剩下半截残渣——
服务端已经「拒绝」了这条命令，但那半截残渣还在流里。

### 34.8.3 drainLine：报错但不伤连接

既然 `recvLine` 不消费残渣，就必须有人负责把它清掉。这就是 `drainLine`：

```zig
// examples/34_zcache/main.zig 第 126-142 行
    fn drainLine(self: *Conn) !void {
        self.ensureBound();
        const r = &self.r.interface;
        while (true) {
            const avail = r.buffered();
            if (std.mem.indexOfScalar(u8, avail, '\n')) |at| {
                r.toss(at + 1);
                return;
            }
            if (avail.len > 0) r.toss(avail.len);
            r.fillMore() catch |err| switch (err) {
                error.EndOfStream => return error.ConnectionClosed,
                error.ReadFailed => return error.ReadFailed,
            };
        }
    }

```

服务端 `handleConn` 的分工于是很清楚：

```zig
// examples/34_zcache/main.zig 第 734-751 行
fn handleConn(ctx: *Ctx, stream: std.Io.net.Stream) void {
    var conn = Conn.init(ctx.io, stream);
    var buf: [max_line]u8 = undefined;
    while (true) {
        const line = conn.recvLine(&buf) catch |err| switch (err) {
            // 超长行：拒掉这一条，但**把残余吃干净**，连接继续服务。
            error.LineTooLong => {
                conn.sendLine("ERR line too long") catch break;
                conn.drainLine() catch break;
                continue;
            },
            error.ConnectionClosed, error.ReadFailed => break,
        };
        ctx.dispatch(&conn, line) catch break;
    }
    conn.close();
}

```

### 34.8.4 实测：拒掉一条 1912 字节的行，连接继续服务

本节的验证脚本是：发一条 1912 字节的行 → 期望 `ERR line too long` →
**紧接着在同一连接上发 3 条正常命令，全部要正确应答**。
这一步是本章「报错但不伤连接」与「报错即断连」的分界线。

> 拼这条长行用 `@memset` 而不是 `"x"** 1900` 字面量：`"x"** 1900` 在 0.17
> 会解析成 `expected type 'type', found 'comptime_int'`（见 34.16 第 18 条）。

```zig
// examples/34_zcache/main.zig 第 1295-1318 行
    // ═══ 34.8 超长行与缓冲区上限 ═══
    begin("34.8 超长行与缓冲区上限");
    {
        var conn = try connect(io, prt);
        var buf: [max_line]u8 = undefined;
        // 1911 字节的行（"PUT toolong " 11 + 1900 个 x），闸门 1024 → 必被拒。
        // ⚠️ 运行时 @memset 拼而不是 `"x"** 1900` 字面量：后者解析成
        // 「expected type 'type', found 'comptime_int'」，std.mem 又没有 repeat。
        var line_buf: [2048]u8 = undefined;
        const prefix = "PUT toolong ";
        @memcpy(line_buf[0..prefix.len], prefix);
        @memset(line_buf[prefix.len..line_buf.len], 'x');
        const line = line_buf[0 .. prefix.len + 1900];
        try conn.sendLine(line);
        const r1 = try conn.recvLine(&buf);
        p("  发送 {d} 字节的行（闸门 {d}）→ {s}\n", .{ line.len, max_line, r1 });
        if (!std.mem.eql(u8, r1, "ERR line too long")) return error.ProtocolMismatch;
        p("  drainLine() 把残余吃到 '\\n'，未消费字节数 = {d}\n", .{conn.pending()});
        try expect(&conn, &buf, "PING", "PONG");
        try expect(&conn, &buf, "PUT after ok1", "OK");
        try expect(&conn, &buf, "GET after", "VALUE ok1");
        p("  ✓ 连接未断：拒绝超长行之后的 3 条命令全部正常应答（drainLine 的意义）\n", .{});
        conn.close();
    }
```

运行输出（`examples/34_zcache/main.zig`）：

```text
  发送 1912 字节的行（闸门 1024）→ ERR line too long
  drainLine() 把残余吃到 '\n'，未消费字节数 = 0
  ✓ 连接未断：拒绝超长行之后的 3 条命令全部正常应答（drainLine 的意义）
```

## 34.9 连接生命周期与 close 的幂等性

### 34.9.1 ⚠️ close 不幂等，而且是「静默」的

0.17 的 close 链路：`Stream.close` → `io.vtable.netClose` → `closeFd`。
看 `lib/std/Io/Threaded.zig` 第 19954-19966 行：

```zig
pub fn closeFd(fd: posix.fd_t) void {
    ... else switch (posix.errno(posix.system.close(fd))) {
        .SUCCESS, .INTR => {}, // INTR still a success
        .BADF => recoverableOsBugDetected(), // use after free
        else => recoverableOsBugDetected(),
    };
}
```

两个要点：

1. **它不把句柄置为无效**。`close(fd)` 之后 `socket.handle` 还是那个数字，
   所以「close 过了」这件事**从对象上看不出来**。本章 34.9 打印的就是这个：
   close 前后句柄同值。
2. **二次 close 命中 `.BADF`** → `recoverableOsBugDetected()`，而它是
   `if (is_debug) unreachable;` —— **Debug 下直接 panic**。

### 34.9.2 纪律：一条连接只 close 一次

要么全 `defer close()`，要么全显式 `close()`。**混用必炸**：

```zig
// ✗ 错误：显式 close 想让服务端进下一条连接，外层又 defer 了一次
try expect(&conn, &buf, "GET a", "VALUE 1");
conn.close();
defer conn.close();   // ← 第二次 close 同一个 fd → BADF → panic
```

本章选**全显式**：

- 客户端 `Conn`：需要「发完最后一条就关」的语义，`defer` 做不到；
- 服务端 `handleConn`：只有一条 close 路径，就在那儿显式调。

### 34.9.3 半关闭（shutdown）本章用不到，但要知道

本章协议没有请求体，所以**永远不需要 `shutdown`**：客户端发完就 `close`，
服务端的 `recvLine` 读到 EOF 退出。

但 30 章的 body 场景**必须显式 `shutdown`**——否则客户端只是不发数据、
连接还开着，服务端的 `recv` 永远等不到 EOF，线程挂死。这是 30 章的实测结论。

```zig
// examples/34_zcache/main.zig 第 1321-1334 行
    // ═══ 34.9 连接生命周期 ═══
    begin("34.9 连接生命周期");
    {
        var conn = try connect(io, prt);
        var buf: [max_line]u8 = undefined;
        const hb = conn.stream.socket.handle;
        try expect(&conn, &buf, "PING", "PONG");
        conn.close();
        p("  close 前后句柄同值：{s} → close **不幂等**：二次 close 同 fd → EBADF →\n", .{
            if (hb == conn.stream.socket.handle) "是" else "否",
        });
        p("  recoverableOsBugDetected() → Debug 下 panic。纪律：一条连接只 close 一次\n", .{});
        p("  服务端已接入连接数 = {d}（实测值，不是预算）\n", .{ctx.served.load(.acquire)});
    }
```

运行输出（`examples/34_zcache/main.zig`）：

```text
  close 前后句柄同值：是 → close **不幂等**：二次 close 同 fd → EBADF →
  recoverableOsBugDetected() → Debug 下 panic。纪律：一条连接只 close 一次
  服务端已接入连接数 = 9（实测值，不是预算）
```

## 34.10 压力测试：只印确定性指标

### 34.10.1 本章为什么不印耗时

单连接 20000 条命令的往返，在 macOS 回环上大约几十到几百毫秒——**每次都不一样**。
一个会漂的数字进不了标记区间，也就不能进文档的 `text` 块。

本章的替代方案：**印操作数、校验和、淘汰次数、字节账**。
需要真实性能数据时，用外部基准（`hyperfine` / `wrk`）跑同一个二进制，
把计时留给工具，示例只负责证明**功能正确**。

### 34.10.2 校验和：把 20000 个应答压成一个确定的整数

```zig
checksum +%= std.hash.Wyhash.hash(0, try conn.recvLine(&buf));
```

它对「哪一次应答是什么」极其敏感：任何一次丢包、串包、错序都会让这个数偏离。
它对时序**不**敏感：所以它是确定性的。这正是我们要的判据。

### 34.10.3 顺便做一次确定性淘汰演示

填满 4096 个键（容量就是 4096），再 PUT 第 4097 个 → 必然淘汰一个。
**单连接串行**时，被淘汰的一定是最旧的 `f0000`，所以可以硬断言：

```zig
try expect(&conn, &buf, "PUT f9999 x", "OK"); // 第 4097 个键 → 挤掉 f0000
const s2 = try readStat(&conn, &buf);
try expectDelta(s1, s2, 0, 0, 1);               // evictions 恰好 +1
try expect(&conn, &buf, "GET f0000", "MISS"); // 正是它被淘汰
```

**并发下这个断言就不成立**——4 个线程同时插键，淘汰对象取决于交错。
34.12 正是用这一点做对照。

```zig
// examples/34_zcache/main.zig 第 1337-1373 行
    // ═══ 34.10 压力测试 ═══
    begin("34.10 压力测试");
    {
        var conn = try connect(io, prt);
        var buf: [max_line]u8 = undefined;
        var sbuf: [64]u8 = undefined;
        const ops = 10000; // 10000 轮 PUT+GET = 20000 条命令
        var checksum: u64 = 0;
        var i: usize = 0;
        while (i < ops) : (i += 1) {
            try conn.sendLine(std.fmt.bufPrint(&sbuf, "PUT k{d} v{d}", .{ i % 16, i % 16 }) catch unreachable);
            _ = try conn.recvLine(&buf);
            try conn.sendLine("GET k0");
            checksum +%= std.hash.Wyhash.hash(0, try conn.recvLine(&buf));
        }
        p("  单连接 {d} 轮 PUT+GET = {d} 条命令全部完成，响应校验和 = {d}\n", .{ ops, ops * 2, checksum });
        p("  ⚠️ 本节**不印耗时也不印吞吐**——网络章节最易漂的就是这两个数\n", .{});
        const fill = 4096;
        i = 0;
        while (i < fill) : (i += 1) {
            try conn.sendLine(std.fmt.bufPrint(&sbuf, "PUT f{d:0>4} x", .{i}) catch unreachable);
            _ = try conn.recvLine(&buf);
        }
        const s1 = try readStat(&conn, &buf);
        try expect(&conn, &buf, "PUT f9999 x", "OK"); // 第 4097 个键 → 挤掉 f0000
        const s2 = try readStat(&conn, &buf);
        try expectDelta(s1, s2, 0, 0, 1);
        try expect(&conn, &buf, "GET f0000", "MISS");
        try expect(&conn, &buf, "GET f9999", "VALUE x");
        p("  填满 {d} 键后再 PUT 第 {d} 个：evictions 增量 = {d}，GET f0000 = MISS\n", .{
            fill, fill + 1, s2.evictions - s1.evictions,
        });
        p("  entries = {d} = 容量；bytes = {d}（每键 6 字节 × {d} = {d}）\n", .{
            s2.entries, s2.bytes, fill, fill * 6,
        });
        conn.close();
    }
```

运行输出（`examples/34_zcache/main.zig`）：

```text
  单连接 10000 轮 PUT+GET = 20000 条命令全部完成，响应校验和 = 6036334265674300736
  ⚠️ 本节**不印耗时也不印吞吐**——网络章节最易漂的就是这两个数
  填满 4096 键后再 PUT 第 4097 个：evictions 增量 = 1，GET f0000 = MISS
  entries = 4096 = 容量；bytes = 24576（每键 6 字节 × 4096 = 24576）
```

## 34.11 边界情况：ERR 的闭集

### 34.11.1 「键含空格」在协议层根本无法表达

任务清单里有一条要求「键含空格（明确拒绝）」。这里要讲清楚**它是怎么被拒绝的**：

服务器的解析是 `std.mem.tokenizeScalar(u8, line, ' ')`：

- **键** = 第一个 token（第一个空格之前）；
- **值** = `it.rest()`（其余全部，**可含空格**）；
- **多余 token** → `ERR usage`。

所以 `GET a b` 是**两个** token，服务器明确拒绝它，
而不是把它当成一个叫 `"a b"` 的键。这就是「明确拒绝」的准确含义——
**协议层面不存在这种键**，而不是「存在但报错」。

对照：`PUT spaced a b c` → `OK`，`GET spaced` → `VALUE a b c`。
**值含空格允许，键含空格不可能**，两条规则不矛盾。

### 34.11.2 命令大小写敏感

`get a` → `ERR unknown`。协议里只有大写命令。这不是缺陷——
**让非法输入走同一条错误路径**，比给每个大小写变体单独写分支好测得多。

### 34.11.3 六个错误原因，一个闭集

| 原因 | 触发条件 |
|---|---|
| `ERR empty` | 空行 / 全空格行（tokenizer 直接返回 null） |
| `ERR unknown` | 未知命令，或命令大小写不对 |
| `ERR usage GET <key>` | GET 缺 key / 多余 token |
| `ERR usage PUT <key> <value>` | PUT 缺 key 或缺 value |
| `ERR usage DEL <key>` | DEL 缺 key / 多余 token |
| `ERR value too long` | 值 > 256 字节 |

**闭集的价值**：每一种都能写一条单测，不会有「漏测的边角」。

### 34.11.4 ⚠️ 本节的键必须自己先建

本节第一版直接 `GET k0` → `VALUE v15`，结果拿到 `MISS`——
因为 34.10 已经把 4096 个键填满，`k0`..`k15` 早就被淘汰了。

**这个 `MISS` 是对的**，但看起来像 bug。教训：跨节复用的键要先确认它还在，
或者干脆自己建一个（`PUT probe vprobe`）。本章现在这么做。

### 34.11.5 全部错误路径之后连接仍健康

最后一条 `PING` → `PONG`：14 条错误输入没有一条打断连接。这是「错误处理做对了」
最直接的判据——比逐条检查应答内容还强。

```zig
// examples/34_zcache/main.zig 第 1376-1420 行
    // ═══ 34.11 边界情况 ═══
    begin("34.11 边界情况");
    {
        var conn = try connect(io, prt);
        var buf: [max_line]u8 = undefined;
        var sbuf: [max_value * 2]u8 = undefined;
        const cases = [_]struct { cmd: []const u8, want: []const u8 }{
            .{ .cmd = "", .want = "ERR empty" },
            .{ .cmd = "   ", .want = "ERR empty" },
            .{ .cmd = "BOGUS x", .want = "ERR unknown" },
            .{ .cmd = "get a", .want = "ERR unknown" }, // 命令大小写敏感
            .{ .cmd = "GET", .want = "ERR usage GET <key>" },
            .{ .cmd = "GET probe", .want = "VALUE vprobe" },
            .{ .cmd = "GET probe extra", .want = "ERR usage GET <key>" }, // 键含空格 → 拒绝
            .{ .cmd = "GET a b c", .want = "ERR usage GET <key>" },
            .{ .cmd = "PUT", .want = "ERR usage PUT <key> <value>" },
            .{ .cmd = "PUT lonely", .want = "ERR usage PUT <key> <value>" },
            .{ .cmd = "DEL", .want = "ERR usage DEL <key>" },
            .{ .cmd = "DEL ghost", .want = "MISS" },
            .{ .cmd = "STAT extra", .want = "ERR usage STAT" },
            .{ .cmd = "PING extra", .want = "ERR usage PING" },
        };
        p("  {s:<16} → {s}\n", .{ "请求", "应答" });
        p("  {s}\n", .{sep_narrow});
        // 本节的键自己先建：34.10 已塞满容量，k0..k15 早被淘汰，
        // 拿旧键断言会得到一个「看着像 bug 其实是对的」MISS。
        try expect(&conn, &buf, "PUT probe vprobe", "OK");
        for (cases) |c| {
            try expect(&conn, &buf, c.cmd, c.want);
            const shown = if (c.cmd.len == 0) "(空行)" else if (std.mem.allEqual(u8, c.cmd, ' ')) "(全空格)" else c.cmd;
            p("  {s:<16} → {s}\n", .{ shown, c.want });
        }
        var bigval_buf: [max_value + 2]u8 = undefined;
        @memset(&bigval_buf, 'v');
        const bigval = bigval_buf[0 .. max_value + 1];
        try conn.sendLine(try std.fmt.bufPrint(&sbuf, "PUT bigkey {s}", .{bigval}));
        const bigresp = try conn.recvLine(&buf);
        if (!std.mem.eql(u8, bigresp, "ERR value too long")) return error.ProtocolMismatch;
        p("  {s:<16} → {s}（值 {d} > 闸门 {d}）\n", .{ "PUT bigkey v…", bigresp, bigval.len, max_value });
        try expect(&conn, &buf, "PUT spaced a b c", "OK");
        try expect(&conn, &buf, "GET spaced", "VALUE a b c");
        p("  {s:<16} → OK + VALUE a b c（值含空格**允许**：PUT 用 rest 语义）\n", .{"PUT spaced a b c"});
        try expect(&conn, &buf, "PING", "PONG"); // 全部错误路径之后连接仍健康
        conn.close();
    }
```

运行输出（`examples/34_zcache/main.zig`）：

```text
  请求           → 应答
  --------------------------------------------
  (空行)         → ERR empty
  (全空格)      → ERR empty
  BOGUS x          → ERR unknown
  get a            → ERR unknown
  GET              → ERR usage GET <key>
  GET probe        → VALUE vprobe
  GET probe extra  → ERR usage GET <key>
  GET a b c        → ERR usage GET <key>
  PUT              → ERR usage PUT <key> <value>
  PUT lonely       → ERR usage PUT <key> <value>
  DEL              → ERR usage DEL <key>
  DEL ghost        → MISS
  STAT extra       → ERR usage STAT
  PING extra       → ERR usage PING
  PUT bigkey v…  → ERR value too long（值 257 > 闸门 256）
  PUT spaced a b c → OK + VALUE a b c（值含空格**允许**：PUT 用 rest 语义）
```

## 34.12 并发压力：用校验和反证数据损坏

### 34.12.1 为什么并发段的统计要用「差值」

全局累计值取决于线程交错，**不能**硬编码绝对数字。
但「这一段脚本自己制造了多少 hit」是确定的——比 STAT 前后差值即可：

```zig
// examples/34_zcache/main.zig 第 842-853 行
fn expectDelta(before: Stat, after: Stat, dh: usize, dm: usize, de: usize) !void {
    if (after.hits - before.hits != dh or after.misses - before.misses != dm or
        after.evictions - before.evictions != de)
    {
        p("  ✗ 统计增量失配：期望 hits+{d} misses+{d} evict+{d}，实得 +{d}/+{d}/+{d}\n", .{
            dh,                                 dm, de, after.hits - before.hits, after.misses - before.misses,
            after.evictions - before.evictions,
        });
        return error.StatMismatch;
    }
}

```

### 34.12.2 hits +1000 是怎么变成确定数的

4 个客户端各 250 轮，每轮 `PUT c{i}_{j%16}` 然后 `GET` 同一个键。要让
「每轮 GET 都命中自己刚写的键」必然成立，需要两个条件：

1. **键空间互不重叠**：客户端 i 只碰 `c{i}_*`，共 4×16 = 64 个键；
2. **64 < 容量 4096**：任何一个键都不会被别人挤掉。

于是 1000 次 GET **必然**全命中，`hits + 1000` 与交错无关。
这不是「碰巧稳定」，是把变量设计成了确定的。

### 34.12.3 evictions +64 也是确定的

进节前缓存是**满的**（34.10 填到 4096，34.11 又添了 `probe`/`spaced` 两个键，
每添一个淘汰一个，条目数仍是 4096）。本节插入 64 个**新键** → 64 次淘汰。

淘汰**对象**不确定（取决于交错），但淘汰**次数**确定：
它只取决于「新键个数」和「容量」。这是本章里唯一一个「不确定对象 + 确定计数」
的例子，值得单独记住。

### 34.12.4 校验和为什么四个客户端一样

运行输出里 c0..c3 的校验和**完全相同**（5504560296581775736），这不是 bug：
每个客户端的负载模式完全一样（同样 250 轮、同样 16 个键、同样 `v{i}` 序列），
所以它们的应答序列逐字节相同 → Wyhash 结果相同。

**这恰恰是最强的判据**：四个独立的连接、四个独立的线程、
在同一份共享 LRU 上并发读写，如果有任何一处丢更新或串包，
四个校验和里至少有一个会不一样。四个全等 ⇒ 无损坏。

```zig
// examples/34_zcache/main.zig 第 1423-1443 行
    // ═══ 34.12 并发压力 ═══
    begin("34.12 并发压力");
    {
        const before = try snapshot(io, prt);
        const tags = [_][]const u8{ "c0", "c1", "c2", "c3" };
        const res = try runWorkers(io, &ctx, prt, &tags);
        const after = try snapshot(io, prt);
        if (ctx.failed.load(.acquire)) return error.ConcurrentClientFailed;
        for (res.sums, 0..) |sum, i| {
            p("  客户端 {s}：250 轮 × (PUT+GET) 完成，校验和 = {d}\n", .{ tags[i], sum });
        }
        p("  4 客户端汇总校验和 = {d}（按槽位汇总，与完成顺序无关 → 确定）\n", .{res.total});
        // 缓存此刻是满的（34.10 填到 4096，34.11 添 2 键各淘汰 1）→ 64 新键 = 64 淘汰。
        // 这不是不确定数：新键数固定 = 64，满容量下每插一个新键必淘汰一个。
        try expectDelta(before, after, 1000, 0, 64);
        p("  STAT 增量 hits+{d} misses+{d} evictions+{d}（进节前 entries={d} 已满）\n", .{
            after.hits - before.hits,           after.misses - before.misses,
            after.evictions - before.evictions, after.entries,
        });
        p("  ✓ 4×250 PUT 全 OK、4×250 GET 全 VALUE —— 判据是**校验和反证**\n", .{});
    }
```

运行输出（`examples/34_zcache/main.zig`）：

```text
  客户端 c0：250 轮 × (PUT+GET) 完成，校验和 = 5504560296581775736
  客户端 c1：250 轮 × (PUT+GET) 完成，校验和 = 5504560296581775736
  客户端 c2：250 轮 × (PUT+GET) 完成，校验和 = 5504560296581775736
  客户端 c3：250 轮 × (PUT+GET) 完成，校验和 = 5504560296581775736
  4 客户端汇总校验和 = 3571497112617551328（按槽位汇总，与完成顺序无关 → 确定）
  STAT 增量 hits+1000 misses+0 evictions+64（进节前 entries=4096 已满）
  ✓ 4×250 PUT 全 OK、4×250 GET 全 VALUE —— 判据是**校验和反证**
```

## 34.13 内存与释放：让长跑服务不泄漏

### 34.13.1 为什么不用 std.testing.allocator

`std.testing.allocator` 在**非测试编译下直接 `@compileError("not testing")`**——
它就是个 `test` 块专用的哨兵。而本章要在 `main`（`build-exe` 产物）里演示泄漏检测。

替代方案是 `std.heap.DebugAllocator`：

```zig
// lib/std/heap/debug_allocator.zig 第 163-169 行（节选）
pub fn DebugAllocator(comptime config: Config) type {
    return struct {
        ...,
        total_requested_bytes: @TypeOf(total_requested_bytes_init) = total_requested_bytes_init,
    };
}
```

它比老的 `GeneralPurposeAllocator` 更严：**永不复用内存地址**（这样 Zig 能把
「用已释放内存」变成确定的未定义值），双重 free 会同时打印 alloc 和 free 两条栈。

⚠️ 0.17 里 `std.heap.GeneralPurposeAllocator` **已经不存在**——
写 `GeneralPurposeAllocator(.{}){}` 报 `root source file struct 'heap' has no member`；
正确写法是 `var dbg: std.heap.DebugAllocator(.{}) = .init;`。

### 34.13.2 长跑服务的三条防泄漏纪律

| # | 纪律 | 违反后果 |
|---|---|---|
| 1 | 条目内存**必须自有**：`put` 时 `dupe` 键和值 | 借用调用方缓冲 → 键被就地改写（34.4 实测） |
| 2 | 三条释放路径**互不重叠**：`deinit` 走链表 / eviction 摘队尾 / `del` 摘指定项 | 漏掉一条 = 泄漏；重叠 = double free |
| 3 | `map` 与链表是**同一批 Entry 的两个视图**，只能沿一条路释放 | 走两遍 = double free |

第 3 条最容易踩：`l.map` 和 `l.order` 引用的是**同一批** `Entry`。
直觉上「两个结构都要清理」，于是两边各清一遍——那就 double free 了。
正确做法是**只沿链表走一遍**（链表是唯一持有 `Entry` 指针的容器），
然后 `map.deinit()` 只放桶数组（它本来就不管键）。

### 34.13.3 arena 为什么不适合这里

`ArenaAllocator.free` 是 **no-op**。对「一次算完整体丢弃」的解析器（33 章的 AST）
这是优点：不用管谁先谁后，全丢即可。

但 LRU 的淘汰要**精确 free 单个条目**——arena 做不到，长跑必然把内存吃到爆。
**选 allocator 的第一问是：释放是「整体丢弃」还是「精确归还单个」？**

### 34.13.4 实测：500 轮 churn + 全程 deinit 反证

```zig
// examples/34_zcache/main.zig 第 1446-1480 行
    // ═══ 34.13 内存与释放 ═══
    begin("34.13 内存与释放");
    {
        // 用 DebugAllocator（不是 std.testing.allocator——它在非测试编译下
        // 直接 @compileError("not testing")）跑一轮 churn，看泄漏块数。
        var probe: std.heap.DebugAllocator(.{}) = .init;
        {
            const pa = probe.allocator();
            var l: Lru = undefined;
            l.init(pa, 16);
            defer l.deinit();
            var i: usize = 0;
            while (i < 500) : (i += 1) {
                var kb: [16]u8 = undefined;
                const key = std.fmt.bufPrint(&kb, "key{d}", .{i % 40}) catch unreachable;
                try l.put(key, "value");
                _ = l.get(key);
                if (i % 3 == 0) _ = l.del(key);
            }
            p("  churn 500 轮（PUT+GET+DEL）后：条目 {d}，字节 {d}，淘汰 {d}\n", .{
                l.entries(), l.bytes, l.evictions,
            });
        } // l.deinit() 在这里跑
        const verdict = probe.deinit();
        p("  DebugAllocator.deinit() = {s}（.ok = 零泄漏；.leak 会打印每块两条栈）\n", .{
            @tagName(verdict),
        });
        if (verdict != .ok) return error.LeakDetected;
        p("\n", .{});
        p("  长跑防泄漏三条纪律：\n", .{});
        p("   1) 条目内存**必须自有**：put 时 dupe 键值，绝不借用调用方缓冲\n", .{});
        p("   2) 三条释放路径**互不重叠**：deinit 走链表 / eviction 摘队尾 / del 摘指定项\n", .{});
        p("   3) map 与链表是**同一批 Entry 的两个视图**，只能沿一条路释放（两遍=双重释放）\n", .{});
        p("  arena 不适合这里：淘汰要**精确 free 单条目**，arena 的 free 是 no-op → 吃到爆\n", .{});
    }
```

运行输出（`examples/34_zcache/main.zig`）：

```text
  churn 500 轮（PUT+GET+DEL）后：条目 16，字节 154，淘汰 317
  DebugAllocator.deinit() = ok（.ok = 零泄漏；.leak 会打印每块两条栈）

  长跑防泄漏三条纪律：
   1) 条目内存**必须自有**：put 时 dupe 键值，绝不借用调用方缓冲
   2) 三条释放路径**互不重叠**：deinit 走链表 / eviction 摘队尾 / del 摘指定项
   3) map 与链表是**同一批 Entry 的两个视图**，只能沿一条路释放（两遍=双重释放）
  arena 不适合这里：淘汰要**精确 free 单条目**，arena 的 free 是 no-op → 吃到爆
```

## 34.14 综合实战：一次完整会话

### 34.14.1 会话脚本

把协议、淘汰、统计、错误处理串成一次真实会话。下面是逐字节的实测输出
（`main.zig` 第 1483-1520 行跑的是 10 条命令，含 2 次 `STAT`）：

```text
==== 34.14 综合实战 开始 ====
  一次完整会话 10 条命令（含 2 次 STAT）全部按预期应答
  增量 hits+2 misses+2 evictions+1 entries Δ-1 bytes Δ-6
  bytes 账：淘汰 -6（fNNNN 键 5 + 值 x 1）+ 新建 +12（session 7 + alpha 5）
          + 改值 -1（alpha 5 → beta 4）+ DEL 归还 -11（session 7 + beta 4）= -6
==== 34.14 综合实战 结束 ====
```

### 34.14.2 增量必须逐条数得清

| 操作 | hits | misses | evictions | 累计 entries | 累计 bytes |
|---|---|---|---|---|---|
| `PUT session alpha`（新键） | | | **+1** | +1 | -6 + 7 + 5 |
| `GET session` | +1 | | | | |
| `PUT session beta`（换值） | | | 0 | | -5 + 4 |
| `GET session` | +1 | | | | |
| `GET nosuchkey` | | +1 | | | |
| `DEL session` | | | | -1 | -7 - 4 |
| `GET session` | | +1 | | | |
| `DEL session`（二次删） | | 0（走 `del` 不走 `get`） | | 0 | 0 |
| **合计** | **+2** | **+2** | **+1** | **-1** | **-6** |

三个容易数错的点：

1. **二次 `DEL` 不计 miss**——`del` 走 `lru.del`，而 `del` 不碰 `misses`；
2. **`PUT` 换已有键不淘汰**——它不进 `while (count > capacity)` 那个循环；
3. **bytes 的 -6 来自淘汰**，不是来自删 session——被淘汰的是一个 `fNNNN` 老键。

本章第一版把期望写成 `hits+3 misses+3 evictions+0`，当场被 `expectDelta` 抓出来
（实得 +2/+2/+1）。**把期望值逐条数清楚再写**，比写完再调数字可靠得多。

```zig
// examples/34_zcache/main.zig 第 1483-1512 行
    // ═══ 34.14 综合实战 ═══
    begin("34.14 综合实战");
    {
        var conn = try connect(io, prt);
        defer conn.close();
        var buf: [max_line]u8 = undefined;
        const s0 = try readStat(&conn, &buf);
        try expect(&conn, &buf, "PING", "PONG");
        try expect(&conn, &buf, "PUT session alpha", "OK");
        try expect(&conn, &buf, "GET session", "VALUE alpha");
        try expect(&conn, &buf, "PUT session beta", "OK");
        try expect(&conn, &buf, "GET session", "VALUE beta");
        try expect(&conn, &buf, "GET nosuchkey", "MISS");
        try expect(&conn, &buf, "DEL session", "OK");
        try expect(&conn, &buf, "GET session", "MISS");
        try expect(&conn, &buf, "DEL session", "MISS");
        const s1 = try readStat(&conn, &buf);
        // 增量逐条数得清：GET session ×2 → hits+2；GET nosuchkey 与 DEL 后的
        // GET → misses+2；PUT alpha 是新键且缓存已满 → evictions+1；
        // PUT beta 键已存在只是换值 → 不淘汰；二次 DEL MISS 走 del 不计 miss。
        try expectDelta(s0, s1, 2, 2, 1);
        p("  一次完整会话 10 条命令（含 2 次 STAT）全部按预期应答\n", .{});
        p("  增量 hits+{d} misses+{d} evictions+{d} entries Δ{d} bytes Δ{d}\n", .{
            s1.hits - s0.hits,                                               s1.misses - s0.misses,
            s1.evictions - s0.evictions,                                     @as(isize, @intCast(s1.entries)) - @as(isize, @intCast(s0.entries)),
            @as(isize, @intCast(s1.bytes)) - @as(isize, @intCast(s0.bytes)),
        });
        p("  bytes 账：淘汰 -6（fNNNN 键 5 + 值 x 1）+ 新建 +12（session 7 + alpha 5）\n", .{});
        p("          + 改值 -1（alpha 5 → beta 4）+ DEL 归还 -11（session 7 + beta 4）= -6\n", .{});
    }
```

运行输出（`examples/34_zcache/main.zig`）：

```text
  一次完整会话 10 条命令（含 2 次 STAT）全部按预期应答
  增量 hits+2 misses+2 evictions+1 entries Δ-1 bytes Δ-6
  bytes 账：淘汰 -6（fNNNN 键 5 + 值 x 1）+ 新建 +12（session 7 + alpha 5）
          + 改值 -1（alpha 5 → beta 4）+ DEL 归还 -11（session 7 + beta 4）= -6
```

### 34.14.3 关停与最终清算

会话结束后：置 stop 标志 → 建空连接叫醒 `accept` → `join()`。
然后**必须显式 `lru.deinit()`**——此时服务线程已 join、没人再碰它，
但 4095 个条目还在堆上。不放这一行，最后的 `dbg.deinit()` 会报 `.leak`
并打印上万行分配栈。

```zig
// examples/34_zcache/main.zig 第 1515-1523 行
    // ── 关停：置标志 + 建一条空连接把 accept 叫醒（见 serve 的注释）──
    ctx.stop.store(true, .release);
    stopServer(io, prt);
    th.join();
    if (ctx.failed.load(.acquire)) return error.ServerFailed;
    p("  服务端共接入 {d} 条连接，全部处理线程 join 完成，关停握手成功\n", .{
        ctx.served.load(.acquire),
    });

```

```text
  服务端共接入 18 条连接，全部处理线程 join 完成，关停握手成功

  关停时服务器 LRU 仍有 4095 个条目 / 24732 字节自有内存 → 显式 deinit 归还
  全程 DebugAllocator.deinit() = ok（含 34.2 四套实现 + 服务器 LRU + churn）
自检通过
```

这一段**不在任何标记区间内**（它在 `end("34.15 测试")` 之后），
但同样是确定性输出——`18` 和 `4095` 都是固定流程算出来的，不是测出来的。

## 34.15 测试

18 个 test，全部**不碰网络**——网络章节的正确性靠 34.6–34.14 的自演脚本，
单元测试只测 LRU 核与协议解析这种纯确定性逻辑。

| # | 测试名 | 覆盖点 |
|---|---|---|
| 1 | LRU 淘汰序：最久未用先走 | 访问 a 提新 → 淘汰 b 而非 a |
| 2 | LRU 淘汰序可从链表读出 | `keysNewestFirst` 下标 0 = 最新，buf[2] = 最旧 |
| 3 | LRU 更新已有键不扩容 | 换值不占新位，evictions 不增 |
| 4 | 命中未中计数与命中率 | hits=1 misses=2 → 33%（向下截断） |
| 5 | 空窗口命中率返回 0 | 不 panic、不报 100 |
| 6 | 删除后可重插 | 二次 `del` 返回 false |
| 7 | 字节计数随 put/del/淘汰增减 | 4 → 8 → 8（淘汰 aa）→ 4；误删不改计数 |
| 8 | put 不复制键：改写源缓冲后键仍在 | 34.4 结论的反向断言 |
| 9 | 更新已有键会释放旧值 | 旧值没 free 的话 testing.allocator 在 deinit 报错 |
| 10 | 容量为 1 时只留最新 | 边界容量 |
| 11 | 容量恰满不淘汰 | **先删后插会误删活键**的反向断言 |
| 12 | 四种实现语义一致 | 四份独立代码 hits/misses/evictions 逐个相等 + work(D) < work(A) |
| 13 | 手写哨兵链表与 std 链表 work 相同 | 34.2 那个「尺子对齐」的结论固化下来 |
| 14 | DoublyLinkedList 无哨兵 | 空表 first/last 为 null |
| 15 | DoublyLinkedList popFirst/popLast 摘两端 | 两端各摘一个 |
| 16 | takeDelimiterExclusive 不吃分隔符 | **0.17 std bug 的最小复现**（34.7） |
| 17 | STAT 解析与差值 | 解析五元组 + `expectDelta` 正反两例 |
| 18 | 行闸门常量自洽 | `max_line > max_value > max_key` |

### 34.15.1 三条 test 值得单独说

**第 8 条（put 不复制键）**是 34.4 的反向断言：把一个栈上切片 `put` 进 `Lru`，
再 `@memcpy` 改写那个栈缓冲，`get("abc")` 仍然必须返回值。
它通过 ⇒ Lru 确实 `dupe` 了 ⇒ 34.4 的坑被封住了。

**第 11 条（容量恰满不淘汰）**是「先删后插会误删活键」的反向断言：
容量 3、已有 a/b/c，插 d 之前 `evictions` 必须是 0。
如果有人把 `put` 改成「先删后插」，这条 test 会立刻红。

**第 16 条（takeDelimiterExclusive）**记录的是**已知 std bug 的复现路径**，
不是本示例的依赖。等哪天 Zig 修了这个 bug，这条 test 会失败——
**那正是它该做的**：提醒你回来把 34.7 的 `recvLine` 换成 `takeDelimiterExclusive`
（那时能少写 20 行）。

```zig
// examples/34_zcache/main.zig 第 1552-1785 行
test "LRU 淘汰序：最久未用先走" {
    const a = std.testing.allocator;
    var lru: Lru = undefined;
    lru.init(a, 3);
    defer lru.deinit();
    try lru.put("a", "1");
    try lru.put("b", "2");
    try lru.put("c", "3");
    try std.testing.expectEqualStrings("1", lru.get("a").?); // 访问 a：b 变最旧
    try lru.put("d", "4"); // 淘汰 b（不是 a）
    try std.testing.expect(lru.get("b") == null);
    try std.testing.expectEqualStrings("1", lru.get("a").?);
    try std.testing.expectEqualStrings("4", lru.get("d").?);
    try std.testing.expectEqual(@as(usize, 1), lru.evictions);
    try std.testing.expectEqual(@as(usize, 3), lru.entries());
}

test "LRU 淘汰序可从链表读出" {
    const a = std.testing.allocator;
    var lru: Lru = undefined;
    lru.init(a, 3);
    defer lru.deinit();
    try lru.put("a", "1");
    try lru.put("b", "2");
    try lru.put("c", "3");
    _ = lru.get("a"); // b 最旧
    var buf: [4][]const u8 = undefined;
    const n = lru.keysNewestFirst(&buf);
    try std.testing.expectEqual(@as(usize, 3), n);
    // keysNewestFirst 下标 0 = **最新**（= order.first）；淘汰序要倒着读。
    try std.testing.expectEqualStrings("a", buf[0]); // 最新（刚被 GET 提新）
    try std.testing.expectEqualStrings("c", buf[1]);
    try std.testing.expectEqualStrings("b", buf[2]); // 最旧（下一个淘汰）
}

test "LRU 更新已有键不扩容" {
    const a = std.testing.allocator;
    var lru: Lru = undefined;
    lru.init(a, 2);
    defer lru.deinit();
    try lru.put("k", "old");
    try lru.put("k", "new");
    try lru.put("x", "1");
    try std.testing.expectEqualStrings("new", lru.get("k").?); // 更新不占新位
    try std.testing.expectEqual(@as(usize, 0), lru.evictions);
    try std.testing.expectEqual(@as(usize, 2), lru.entries());
}

test "命中未中计数与命中率" {
    const a = std.testing.allocator;
    var lru: Lru = undefined;
    lru.init(a, 4);
    defer lru.deinit();
    _ = lru.get("nothing");
    try lru.put("a", "1");
    _ = lru.get("a");
    _ = lru.get("b");
    try std.testing.expectEqual(@as(usize, 1), lru.hits);
    try std.testing.expectEqual(@as(usize, 2), lru.misses);
    try std.testing.expectEqual(@as(usize, 33), lru.hitRatePercent()); // 1/3 → 33
}

test "空窗口命中率返回 0" {
    const a = std.testing.allocator;
    var lru: Lru = undefined;
    lru.init(a, 1);
    defer lru.deinit();
    try std.testing.expectEqual(@as(usize, 0), lru.hitRatePercent());
}

test "删除后可重插" {
    const a = std.testing.allocator;
    var lru: Lru = undefined;
    lru.init(a, 2);
    defer lru.deinit();
    try lru.put("a", "1");
    try std.testing.expect(lru.del("a"));
    try std.testing.expect(!lru.del("a")); // 二次删：MISS
    try lru.put("a", "2");
    try std.testing.expectEqualStrings("2", lru.get("a").?);
}

test "字节计数随 put/del/淘汰增减" {
    const a = std.testing.allocator;
    var lru: Lru = undefined;
    lru.init(a, 2);
    defer lru.deinit();
    try lru.put("aa", "11"); // 4
    try std.testing.expectEqual(@as(usize, 4), lru.bytes);
    try lru.put("bb", "22"); // 8
    try std.testing.expectEqual(@as(usize, 8), lru.bytes);
    try lru.put("cc", "33"); // 超容量 → 淘汰 aa，字节仍 8
    try std.testing.expectEqual(@as(usize, 8), lru.bytes);
    _ = lru.del("bb");
    try std.testing.expectEqual(@as(usize, 4), lru.bytes);
    _ = lru.del("ghost");
    try std.testing.expectEqual(@as(usize, 4), lru.bytes); // 不误改
}

test "put 不复制键：改写源缓冲后键仍在" {
    const a = std.testing.allocator;
    var lru: Lru = undefined;
    lru.init(a, 4);
    defer lru.deinit();
    var scratch = [_]u8{ 'a', 'b', 'c', 'd' };
    try lru.put(scratch[0..3], "v");
    @memcpy(scratch[0..3], "zzz"); // 若 put 借用不复制，这里就会查不到
    try std.testing.expectEqualStrings("v", lru.get("abc").?);
}

test "更新已有键会释放旧值" {
    const a = std.testing.allocator;
    var lru: Lru = undefined;
    lru.init(a, 2);
    defer lru.deinit();
    try lru.put("k", "old");
    try lru.put("k", "new");
    // testing.allocator 在 deinit 时零容忍：旧值没 free 就会在这里报错
    try std.testing.expectEqualStrings("new", lru.get("k").?);
}

test "容量为 1 时只留最新" {
    const a = std.testing.allocator;
    var lru: Lru = undefined;
    lru.init(a, 1);
    defer lru.deinit();
    try lru.put("a", "1");
    try lru.put("b", "2");
    try std.testing.expect(lru.get("a") == null);
    try std.testing.expectEqualStrings("2", lru.get("b").?);
    try std.testing.expectEqual(@as(usize, 1), lru.evictions);
}

test "容量恰满不淘汰" {
    const a = std.testing.allocator;
    var lru: Lru = undefined;
    lru.init(a, 3);
    defer lru.deinit();
    try lru.put("a", "1");
    try lru.put("b", "2");
    try lru.put("c", "3");
    try std.testing.expectEqual(@as(usize, 0), lru.evictions);
    try std.testing.expectEqual(@as(usize, 3), lru.entries());
    try std.testing.expectEqualStrings("1", lru.get("a").?);
    try std.testing.expectEqualStrings("2", lru.get("b").?);
    try std.testing.expectEqualStrings("3", lru.get("c").?);
}

test "四种实现语义一致" {
    const a = std.testing.allocator;
    const ra = try benchRun(ArrayLru, a);
    const rb = try benchRun(SentinelListLru, a);
    const rc = try benchRun(StdListLru, a);
    const rd = try benchRun(Lru, a);
    try std.testing.expectEqual(ra.hits, rb.hits);
    try std.testing.expectEqual(ra.misses, rb.misses);
    try std.testing.expectEqual(ra.evictions, rb.evictions);
    try std.testing.expectEqual(ra.hits, rc.hits);
    try std.testing.expectEqual(ra.misses, rc.misses);
    try std.testing.expectEqual(ra.evictions, rc.evictions);
    try std.testing.expectEqual(ra.hits, rd.hits);
    try std.testing.expectEqual(ra.misses, rd.misses);
    try std.testing.expectEqual(ra.evictions, rd.evictions);
    // 哈希表版本的 work 必须严格小于数组版本——这是 O(1) 的可测量证据
    try std.testing.expect(rd.work < ra.work);
    try std.testing.expect(ra.evictions > 0); // 负载确实触发了淘汰
}

test "手写哨兵链表与 std 链表 work 相同" {
    const a = std.testing.allocator;
    const rb = try benchRun(SentinelListLru, a);
    const rc = try benchRun(StdListLru, a);
    try std.testing.expectEqual(rb.work, rc.work);
}

test "DoublyLinkedList 无哨兵：空表 first/last 为 null" {
    var l: std.DoublyLinkedList = .{};
    try std.testing.expect(l.first == null);
    try std.testing.expect(l.last == null);
    try std.testing.expectEqual(@as(usize, 0), l.len());
}

test "DoublyLinkedList popFirst/popLast 摘两端" {
    var a1: DllItem = .{ .id = 1 };
    var a2: DllItem = .{ .id = 2 };
    var a3: DllItem = .{ .id = 3 };
    var l: std.DoublyLinkedList = .{};
    l.append(&a1.link);
    l.append(&a2.link);
    l.append(&a3.link);
    const pf: *DllItem = @fieldParentPtr("link", l.popFirst().?);
    try std.testing.expectEqual(@as(u32, 1), pf.id);
    const pl: *DllItem = @fieldParentPtr("link", l.popLast().?);
    try std.testing.expectEqual(@as(u32, 3), pl.id);
    try std.testing.expectEqual(@as(usize, 1), l.len());
}

test "takeDelimiterExclusive 不吃分隔符（0.17 std bug 的最小复现）" {
    // 这条 test 记录的是**已知 std bug 的复现路径**，不是本示例的依赖。
    const src = "ab\ncd\n";
    var r: std.Io.Reader = .fixed(src);
    try std.testing.expectEqualStrings("ab", try r.takeDelimiterExclusive('\n'));
    // 第二次调用返回空片——因为分隔符还留在缓冲里。应为 "cd"，实得空。
    // ⚠️ 不能写 `second.?len`：那是 error union，`.?` 不适用；而且 Zig 的
    // tokenizer 会把 `.?len` 解析成「参数后缺逗号」的语法错误。
    const second = try r.takeDelimiterExclusive('\n');
    try std.testing.expectEqual(@as(usize, 0), second.len);
}

test "STAT 解析与差值" {
    const s = parseStat("STAT hits=10 misses=4 evictions=2 entries=3 bytes=42") orelse return error.BadStat;
    try std.testing.expectEqual(@as(usize, 10), s.hits);
    try std.testing.expectEqual(@as(usize, 4), s.misses);
    try std.testing.expectEqual(@as(usize, 2), s.evictions);
    try std.testing.expectEqual(@as(usize, 3), s.entries);
    try std.testing.expectEqual(@as(usize, 42), s.bytes);
    try std.testing.expect(parseStat("garbage") == null);
    try expectDelta(
        Stat{ .hits = 5, .misses = 1, .evictions = 0 },
        Stat{ .hits = 8, .misses = 2, .evictions = 1 },
        3,
        1,
        1,
    );
    // 故意写错的差值必须被抓出来
    try std.testing.expectError(error.StatMismatch, expectDelta(Stat{}, Stat{ .hits = 1 }, 2, 0, 0));
}

test "行闸门常量自洽" {
    try std.testing.expect(max_line > max_value);
    try std.testing.expect(max_value > max_key);
    try std.testing.expect(max_line >= 1024); // 超长行测试依赖它
}

```

验证入口：

```bash
cd /Volumes/mac004/code/programming/zig
ZIG=/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/zig ./run-all.sh 34_zcache
```

跑完应看到（逐字节抄自实测）：

```text
[Toolchain] /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/zig (0.17.0)

[Example] 34_zcache
1/18 main.test.LRU 淘汰序：最久未用先走...OK
2/18 main.test.LRU 淘汰序可从链表读出...OK
3/18 main.test.LRU 更新已有键不扩容...OK
4/18 main.test.命中未中计数与命中率...OK
5/18 main.test.空窗口命中率返回 0...OK
6/18 main.test.删除后可重插...OK
7/18 main.test.字节计数随 put/del/淘汰增减...OK
8/18 main.test.put 不复制键：改写源缓冲后键仍在...OK
9/18 main.test.更新已有键会释放旧值...OK
10/18 main.test.容量为 1 时只留最新...OK
11/18 main.test.容量恰满不淘汰...OK
12/18 main.test.四种实现语义一致...OK
13/18 main.test.手写哨兵链表与 std 链表 work 相同...OK
14/18 main.test.DoublyLinkedList 无哨兵：空表 first/last 为 null...OK
15/18 main.test.DoublyLinkedList popFirst/popLast 摘两端...OK
16/18 main.test.takeDelimiterExclusive 不吃分隔符（0.17 std bug 的最小复现）...OK
17/18 main.test.STAT 解析与差值...  ✗ 统计增量失配：期望 hits+2 misses+0 evict+0，实得 +1/+0/+0
18/18 main.test.行闸门常量自洽...OK
All 18 tests passed.
```


### 三层测试怎么分的

本章 18 个 test 不是随手堆的，按「碰不碰外部资源」分三档，各档用不同的失败模型：

| 档 | 覆盖什么 | 手段 | 为什么这样分 |
|---|---|---|---|
| 纯内存 | LRU 淘汰序、命中率算术、四种实现语义一致 | 直接构造 + 断言 | 不碰分配器之外的东西，Debug 下必跑 |
| 带分配器 | `put` 后改写源缓冲、删除后重插、字节计数增减 | `std.testing.allocator` | 需要验证"谁 owns 键"，分配器是唯一能反证的工具 |
| 端到端 | 行协议解析、超长行、STAT 差值、行闸门自洽 | `std.testing.tmpDir` + `Reader.fixed` | 要走真实 Reader 缓冲，才能抓出 34.7 那条 std bug |

先看第 17 号那个 test 的输出，它可能是全章最容易被误读的一行：

```text
17/18 main.test.STAT 解析与差值...  ✗ 统计增量失配：期望 hits+2 misses+0 evict+0，实得 +1/+0/+0
All 18 tests passed.
```

**印了 `✗` 却仍然 `All 18 tests passed.`**——这不是矛盾，是这个 test
**故意**触发一次失配来演示诊断信息的格式（源码见 `main.zig` 第 1777 行
的 `expectError(error.StatMismatch, expectDelta(Stat{}, ...))`）：
`expectDelta` 自己把失配详情打出来，然后**按契约返回
`error.StatMismatch`**，而 `expectError` 正是**期待**这个错误。
所以这条 `✗` 是被断言的失败，不是测试失败。

这带出一条本章反复用到的纪律：**`zig test` 里"打印了错误信息"与
"测试失败"是两件事**。判测试成败只能看进程退出码与末尾的
`All N tests passed.`，不能靠 grep 输出里有没有 `✗`——
本章 34.13、34.15 都演示了同样的模式。
反过来也成立：一条会**主动打印**异常消息做演示的示例，
不能被「输出里出现了 `✗`」的判据当成崩溃（见 34.16 第 27 条）。

```zig
// examples/34_zcache/main.zig 第 1749-1759 行
test "takeDelimiterExclusive 不吃分隔符（0.17 std bug 的最小复现）" {
    const src = "ab\ncd\n";
    var r: std.Io.Reader = .fixed(src);
    try std.testing.expectEqualStrings("ab", try r.takeDelimiterExclusive('\n'));
    // 第二次调用返回空片——因为分隔符还留在缓冲里。应为 "cd"，实得空。
    // ⚠️ 不能写 `second.?len`：那是 error union，`.?` 不适用；而且 Zig 的
    // tokenizer 会把 `.?len` 解析成「参数后缺逗号」的语法错误。
    const second = try r.takeDelimiterExclusive('\n');
    try std.testing.expectEqual(@as(usize, 0), second.len);
}
```

注意这个 test **故意断言空片**：它测的是「bug 现在确实存在」，不是
「zcache 读对了行」。等哪天上游修了，这个 test 会**失败**——
那时就该把这行改成 `expectEqualStrings("cd", second)` 并删掉整条坑位。

这个 test 的价值不在「验证 zcache 对」，而在**把 std 的 bug 钉死成一个不依赖本项目的最小用例**。以后升级 Zig 版本，只需跑这一个 test 就知道上游修没修。

---

## 34.16 坑位清单

按「会不会让程序悄悄算错」排序。前 8 条是会产出**错误结果**的，不是编译期能拦住的。

### 一、会静默算错的（最危险）

1. **`takeDelimiterExclusive('\n')` 在 0.17.0 不消费分隔符**。
   源码级证据在 `lib/std/Io/Reader.zig` 第 894-898 行：

   ```zig
   pub fn takeDelimiterExclusive(r: *Reader, delimiter: u8) DelimiterError![]u8 {
       const result = try r.peekDelimiterExclusive(delimiter);
       r.toss(result.len);        // ← 丢的是"正文长度"，不含分隔符
       return result;
   }
   ```

   而 `peekDelimiterExclusive`（第 948-958 行）是这么算的：

   ```zig
   pub fn peekDelimiterExclusive(r: *Reader, delimiter: u8) DelimiterError![]u8 {
       const result = try r.peekDelimiterInclusive(delimiter);
       //Inclusive 含分隔符，这里砍掉**最后 1 字节**（分隔符）
       return result[0 .. result.len - 1];
   }
   ```

   拼起来看：`result.len` 已经**不含**分隔符，`toss(result.len)` 只丢正文，
   **分隔符原地不动留在缓冲里**。后果：第二次调用从同一偏移又在同一位置
   找到同一个 `\n`，`result[0..0]` 返回**长度为 0 的空片** → 死循环刷空行。
   正确写法（三选一）：

   ```zig
   // A. 返回 ?[]u8，EOF 给 null（最省事）
   const line = try reader.takeDelimiter('\n');

   // B. 含分隔符，自己截
   const chunk = try reader.takeDelimiterInclusive('\n');
   const line = chunk[0 .. chunk.len - 1];

   // C. 手工三步（本章 34.7 用的就是这个，能精确控制"丢几个字节"）
   const avail = reader.buffered();
   if (std.mem.indexOfScalarPos(u8, avail, scanned, '\n')) |at| {
       const line = avail[scanned..at];
       reader.toss(at + 1);
       // ...
   }
   ```

   注意 `toss(at + 1)` 里的 `+1`：**漏掉它就是原 bug 的手动复刻**。

2. **`Stream.close` 不幂等，二次 close 直接 panic**。
   它 `close(fd)` 之后**既不把句柄置为无效、也不返回错误**，二次 close 同一 fd
   命中 `EBADF`，走进 `recoverableOsBugDetected()`，而后者是
   `if (is_debug) unreachable;` —— **Debug 下直接 panic**。
   真实触发方式（本章 34.9 演示）：

   ```zig
   defer conn.close();      // 第一次
   conn.close();             // 第二次 → BADF → panic
   ```

   纪律：**一条连接要么全 `defer`，要么全显式 close，不能混**。

3. **`insertBefore` / `insertAfter` 不检查「已经相邻」**。
   把一个本来就紧挨着 `existing_node` 的节点再插一次，会写出 `a.prev = a`
   的自环，遍历**永不终止**。本章第一版的 `StdListLru` 演示就是这么写的，
   实测把程序打成死循环。插入后**必须**能反证链表长度没变
   （`len()` 前后对比，或走一遍数节点）。

4. **`std.DoublyLinkedList` 在 0.17 是非泛型、侵入式的**。
   这是本章最容易踩的一条——网上绝大多数写法是 `std.DoublyLinkedList(T)`，
   实测直接报：

   最小复现（`/tmp/t.zig` 用 0.17.0 编译，报错原文逐字节）：

   ```plain
   error: type 'type' not a function
       const L = std.DoublyLinkedList(u32);
                 ~~~^~~~~~~~~~~~~~~~~
   ```

   0.17 的真实形态（`lib/std/DoublyLinkedList.zig`）是**一个 `@This()` 的
   非泛型 struct**，只有两个字段 `first` / `last`，`Node` 只含
   `prev` / `next` 两个指针、**不带数据**：

   ```zig
   pub const Node = struct {
       prev: ?*Node = null,
       next: ?*Node = null,
   };
   ```

   用法变成「把 `Node` 塞进自己的结构体，再用 `@fieldParentPtr` 取回数据」。
   本章生产核 `Lru` 的真实做法（`link` 字段就是那个 `Node`）：

   ```zig
   // examples/34_zcache/main.zig 第 494-498 行
       const Entry = struct {
           key: []u8, // 自有（map 的键也指向这份）
           value: []u8, // 自有
           link: std.DoublyLinkedList.Node = .{}, // 侵入式链表节点
       };
   ```

   ```zig
   // examples/34_zcache/main.zig 第 515-523 行
           var node = l.order.first;
           while (node) |n| {
               const next = n.next; // 先存 next：下面要 free 掉宿主
               const entry: *Entry = @fieldParentPtr("link", n);
               l.a.free(entry.key);
               l.a.free(entry.value);
               l.a.destroy(entry);
               node = next;
           }
   ```

   注意 `first` 出现在 `l.order.first` 的**字段**位置——
   它是字段不是方法。写 `l.order.first()` 实测报：

   最小复现（`/tmp/t.zig` 用 0.17.0 编译，报错原文逐字节）：

   ```plain
   error: type '?*DoublyLinkedList.Node' not a function
       _ = l.first();
   ```

   而且**它没有 `init()`、没有 `iterator()`、没有 `fetchNode()`、
   没有 `first()`/`last()`/`insert()`**（实测 `@hasDecl` 全 `false`，
   只有 `pop`/`popLast`/`insertAfter`/`insertBefore`/`remove`/`len` 为 `true`）。
   声明用 `order: std.DoublyLinkedList = .{}`（见 34.4），
   遍历一律手写 `first` / `.next` 循环——**「没有 `iterator()`」的实测后果**：
   你没法用 `for (list)` 或 `while (it.next())` 写。

5. **`@hasDecl` 会骗你：存在 ≠ 可用**。
   `DoublyLinkedList.len` 是 `true` 但签名是 `len(list: DoublyLinkedList) usize`
   （**按值**收），而 `popLast` 是 `popLast(list: *DoublyLinkedList) ?*Node`
   （**按指针**收）。同一容器里一半按值一半按指针，写的时候得逐个看签名。

6. **`std.StringHashMap` 在 0.17 没有 `putOwned`**（实测 `@hasDecl` = `false`，
   `getOrPutOwned` 同样没有）。这与网上「0.11 加了 `putOwned`」的说法矛盾。
   0.17 的键内存**归调用方**，唯一正确写法是**先 `dupe` 再 `put`**：

   ```zig
   // 错：put 之后 gpa.free(k) 就是悬垂键
   try map.put(gpa, key, value);
   // 对：先拿到自己的一份
   const owned = try gpa.dupe(u8, key);
   errdefer gpa.free(owned);
   try map.put(gpa, owned, value);
   ```

   同批实测为 `false` 的还有 `fetchSwapRemove`、`orderedRemove`
   （0.17 只剩 `remove`）。本章 34.4 用「改写源缓冲后键仍在」这个 test
   反证了 `dupe` 的必要性。

7. **自引用结构体不能在 `init()` 里就地绑定指针**。
   `return self` 发生值拷贝后，init 的栈帧就没了，绑好的指针指向已销毁的帧。
   本章两处实测炸：34.2 的 `StdListLru`（含侵入式链表的空闲链）
   直接 **Segmentation fault**，34.6 的 `Conn.reader` 同理。
   正确做法是**懒绑定**（本章 `Conn` 的 `ensureBound`）。

8. **`std.time.Timer` 整个类型不存在**（`@hasDecl(std.time, "Timer")` = `false`；
   0.17 的 `lib/std/time.zig` 只剩 `ns_per_ms` 这类除数常量，零函数）。
   时间测量归 `std.Io.Clock` / `std.Io.Timestamp`。
   这条在本章**反而是好事**——语言层面逼你把裸耗时从标记区间里拿掉，
   逼你比 `work` 而不是比秒数。

### 二、API 改名 / 挪窝

9. **`std.heap.GeneralPurposeAllocator` 已改名 `std.heap.DebugAllocator`**。
   实测 `@hasDecl(std.heap, "GeneralPurposeAllocator")` = `false`，
   `DebugAllocator` = `true`。`.{}` 字面量仍能编过，也可用 `.init`。
   34.13 用它的 `deinit() == .ok` 反证整场零泄漏。

10. **`std.Thread.WaitGroup` / `Mutex` / `Condition` / `Semaphore` /
    `ResetEvent` / `RwLock` / `Futex` / `sleep` 全部已移除**（实测
    `std.Thread.WaitGroup` = `false`；0.17 的 `lib/std/Thread.zig` 顶层只剩
    `Id` / `Handle` / `SpawnConfig` / `spawn` / `join` / `detach` / `yield`
    等十来项）。同步原语全部搬到 `std.Io.*`，详见 19 章。
    本章的多线程关停因此用「置 stop 标志 + `join()`」，不是 `WaitGroup`。

11. **`std.Io.Semaphore` 叫 `wait` / `post`，不叫 `acquire` / `release`**
    （`@hasDecl(std.Io.Semaphore, "acquire")` = `false`）。

12. **`std.Io.Mutex` 没有 `isLocked`**（实测 `false`；0.16 时代有过，0.17 移除）。
    想知道「是否已锁」只能自己维护一个 `std.atomic.Value(bool)` 影子标志。

13. **`std.mem.repeat` 不存在**（实测报
    `root source file struct 'mem' has no member named 'repeat'`）。
    要重复用 `@splat`（等长）或运行时 `@memset`（不等长），
    要拼接切片用 `++`。

14. **`callconv(.C)` 已改名 `callconv(.c)`**（0.17 里 `.c` 是指向
    `cCallingConvention()` 的别名）。

15. **注意区分「数组」和「切片」**：`var s: [8]u8` 是**数组**，
    `s = v`（整个数组赋值）**编译通过**；但 `var s: []u8` 是**切片**，
    0.17 已移除 `s = v` 这种写法，只能 `s.* = v` 或 `memcpy`。
    旧教程里「切片不能赋值」的结论在 0.17 要改成
    「**数组可以、切片不行**」——写成泛泛的「切片赋值被移除」会误导。

16. **`"x" ** 1900` 的报错是「空格规则」而不是「运算符不存在」**。实测：

    最小复现（`/tmp/t.zig` 用 0.17.0 编译，报错原文逐字节）：

    ```plain
    error: binary operator '*' has whitespace on one side, but not the other
    ```

    `**` 已被彻底移除，留下的 `*` 是指针解引用；写 `**` 时那个双星号
    先被词法分析拆开，于是报的是**空格不对称**这种看不出真相的错。
    本章 34.8 构造超长行时因此必须用运行时 `@memset`：

    ```zig
    // examples/34_zcache/main.zig 第 1300-1307 行
            // 1911 字节的行（"PUT toolong " 11 + 1900 个 x），闸门 1024 → 必被拒。
            // ⚠️ 运行时 @memset 拼而不是 `"x"** 1900` 字面量：后者解析成
            // 「expected type 'type', found 'comptime_int'」，std.mem 又没有 repeat。
            var line_buf: [2048]u8 = undefined;
            const prefix = "PUT toolong ";
            @memcpy(line_buf[0..prefix.len], prefix);
            @memset(line_buf[prefix.len..line_buf.len], 'x');
            const line = line_buf[0 .. prefix.len + 1900];
    ```

17. **`std.Io.Reader.fixed` 是单参数**（`fixed(buffer)`），旧的双参写法报
    `expected 1 argument(s), found 2`。

18. **`takeDelimiter` 返回 `?[]u8`（EOF 给 `null`）而不是 `[]u8`**，
    `takeDelimiterInclusive` 才是含分隔符的版本。选错了 EOF 语义就反了。

### 三、int / 精度 / 格式

19. **切片没有 `d` 格式**。写 `{d}` 编译报
    `invalid format string 'd' for type '[]const u8'`。

20. **格式串里的字面 `{` 要写 `{{`**。本章打印协议示例时
    `.{ .}` 被当成占位符，报 `too few arguments`。
    顺带一条同族的：`std.debug.print` / `print` **固定两参数**
    （格式串 + `.{}`），第三个参数会被当成「太多参数」。
    再一条同源的：**要印字符 `'\n'` 必须写 `"\\n"`**——
    写 `"\n"` 会被格式化器当成真换行，输出里就断成两行（34.7 有演示）。

21. **`bytes` 用 `usize`，不要想当然改 `u64`**。本章 `Lru.bytes` 与
    `Stat.bytes` 都是 `usize`（见 `main.zig` 第 507、640 行），
    因为键 + 值总字节被 `max_value`（1 KiB 级）× `capacity`（4096）
    双重限死在 `usize` 范围内。**换成 `u64` 只会让每处加法多一个
    `@intCast`，并不会更安全**——真正的防护是那条闸门常量。

22. **算术结果永不宽化**。`usize + u32` 还是 `usize`；
    想避免 32/64 位混算的截断，必须在**每一处**显式 `@intCast` 并配
    `try`，而不是指望编译器帮你提升。反过来，**做校验和时反而要用
    环绕加 `+%=`**（见 `main.zig` 第 1215 行 `total +%= s`）——
    校验和的语义本就是"模 2⁶⁴ 的和"，`+%` 让它**永远不溢出 panic**，
    这正是把并发正确性表达成一个整数的关键。

### 四、构建与验证纪律

23. **网络 + 并发示例的输出必须自检**。本章服务端的关停靠
    「置 stop 标志 + 建一条空连接把阻塞的 `accept` 叫醒」，主线程 `join()`
    即同步——**没有这条，`./run-all.sh 34_zcache` 必然挂死**，
    而不是「跑得慢」。

24. **端口用 `listen(0)` 拿内核分配的 ephemeral 端口，且只印「非 0：是」**。
    打印真实端口号等于把一个每台机器都不同的数字写进期望输出，
    跨机器/跨次运行必挂。0.17 的 `Socket.address` 会带回绑定后的真实端口，
    拿它来做非空断言正好。

25. **基准测试不比耗时，比 work**。34.2 那种"四种实现对比"如果比纳秒，
    会被机器负载、J-Tier、温度全部污染；本章改成比
    **基本操作计数（work）**——那是整数、确定、可断言。

26. **并发段用差值断言 + 按槽位汇总的校验和**。34.12 要证明
    "4 客户端并发无数据损坏"，靠的是「各客户端把成功计数加到
    `stats[slot]`，最后 `stats` 的总和 == 预期」——
    **任何一次丢更新或串槽，总和立刻不等**。
    这比「打印每个客户端的日志」强得多：后者在交错下无法逐字节比对，
    前者永远是一个整数。

27. **`test` 块数 ≠ 覆盖的代码路径**。0.17 的 `zig test` **不分析
    `pub fn main`**，所以「18 个 test 全过」完全不代表 `main` 里那些
    网络/并发代码被编译过。本章三层验证（`fmt --check` → `test` →
    `build-exe` + 运行）**第三层不能跳**；本章 34.15 的运行时小节
    只有跑 `main` 才被编译到。

28. **示例输出走 `stderr`**（`std.debug.print` 就是 stderr），
    所以「stderr 空」这条判据在本项目的含义是
    **「没有 panic / traceback / unreachable 痕迹」**，不是「没有任何输出」。
    判「溃逃痕迹」要写成**组合**：匹配 panic 横幅行
    （`panic:` / `thread ... panicked` / `Unable to dump stack trace`）
    **并要求紧邻的下一行是分隔线**——单行判据会把本章主动打印的
    错误消息演示误报成崩溃。

29. **`DebugAllocator.deinit()` 返回 `std.heap.Check` 枚举**（实测
    `@typeName` = `heap.Check`，值 `ok` / `leak`），**不是 `void` 也不是
    泄漏字节数**。所以 `defer gpa.deinit();` 编译不过（返回值被丢弃）；
    正确写法是接住它再判：

    ```zig
    const check = dbg.deinit();
    if (check != .ok) return error.LeakDetected;
    ```

    注意别和 `std.testing.allocator` 搞混——**那个的 `deinit()` 返回
    `usize` 泄漏块数**（要写 `_ = a.deinit();`）。两个都叫 `deinit`、
    返回类型不同，是本章最容易被旧教程带偏的一处。

    它的好处是**把泄漏变成硬失败**：`.ok` 之外的值让 `main` 提前
    `return error`，末尾那句「自检通过」也就打不出来（见 34.17）。

---

## 34.17 本章的验证方式

三层，与全项目一致（见 2.8 节）：

```bash
cd examples/34_zcache
zig fmt --check .                                    # 第 1 层：格式 + 语法
zig test main.zig                                    # 第 2 层：18 个 test
zig build-exe main.zig -femit-bin=/tmp/zcache        # 第 3 层：main 也要能编
/tmp/zcache                                           # 第 3 层：真跑一遍
```

第 3 层不可省：`zig test` 不看 `main`，而本章最要紧的 15 个运行时小节
**全在 `main` 里**。实测本章开发过程中出现过多次「18 个 test 全绿、
`build-exe` 才报 `main` 的错」的情况（33 章 agent 也独立踩到同一类）。

跑完应看到（逐字节抄自实测）：

```text
[Toolchain] /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/zig (0.17.0)

[Example] 34_zcache
1/18 main.test.LRU 淘汰序：最久未用先走...OK
2/18 main.test.LRU 淘汰序可从链表读出...OK
3/18 main.test.LRU 更新已有键不扩容...OK
4/18 main.test.命中未中计数与命中率...OK
5/18 main.test.空窗口命中率返回 0...OK
6/18 main.test.删除后可重插...OK
7/18 main.test.字节计数随 put/del/淘汰增减...OK
8/18 main.test.put 不复制键：改写源缓冲后键仍在...OK
9/18 main.test.更新已有键会释放旧值...OK
10/18 main.test.容量为 1 时只留最新...OK
11/18 main.test.容量恰满不淘汰...OK
12/18 main.test.四种实现语义一致...OK
13/18 main.test.手写哨兵链表与 std 链表 work 相同...OK
14/18 main.test.DoublyLinkedList 无哨兵：空表 first/last 为 null...OK
15/18 main.test.DoublyLinkedList popFirst/popLast 摘两端...OK
16/18 main.test.takeDelimiterExclusive 不吃分隔符（0.17 std bug 的最小复现）...OK
17/18 main.test.STAT 解析与差值...  ✗ 统计增量失配：期望 hits+2 misses+0 evict+0，实得 +1/+0/+0
18/18 main.test.行闸门常量自洽...OK
All 18 tests passed.
```

因为含网络与并发，本章额外做**连跑 5 次逐字节比对**。五条对策
（不印裸耗时、比 work 不比秒、ephemeral 端口只印非零断言、差值断言、
校验和反证）就是为这条服务的——实测 5 次 `diff` 无差异。

**泄漏检测**由 `main` 末尾的 `DebugAllocator.deinit()` 兜底：

```zig
// examples/34_zcache/main.zig 第 1530-1545 行
    // 服务器 LRU 的 4096 个条目此刻还在（服务线程已 join，没人再碰它），必须
    // 显式 deinit——**这正是 34.13 那三条纪律在 LRU 上的应用**。不放这一行，
    // 下面 dbg.deinit() 会报 .leak 并打印上万行分配栈。
    const n_entries = lru.entries();
    const n_bytes = lru.bytes;
    lru.deinit();
    const check = dbg.deinit();
    p("\n", .{});
    p("  关停时服务器 LRU 仍有 {d} 个条目 / {d} 字节自有内存 → 显式 deinit 归还\n", .{
        n_entries, n_bytes,
    });
    p("  全程 DebugAllocator.deinit() = {s}（含 34.2 四套实现 + 服务器 LRU + churn）\n", .{
        @tagName(check),
    });
    if (check != .ok) return error.LeakDetected;
    p("自检通过\n", .{});
```

`deinit()` 返回一个 `std.heap.Check` 枚举，这里用 `@tagName` 打成 `.ok` / `.leak`。
**不 `.ok` 就 `return error.LeakDetected`** ——末尾那句「自检通过」也就打不出来。
本章 `main` 里跑过的东西包括：四套 LRU 实现各跑一遍、
服务器 LRU 填 4096 个条目、34.13 的 500 轮 churn、
以及 4 客户端并发压测——**全过一遍 `deinit()` 仍须返回 `.ok`**。

注意那行显式 `lru.deinit()`：服务线程 `join()` 之后 **4096 个条目还在**，
不放这一行，后面 `dbg.deinit()` 会报 `.leak` 并打印上万行分配栈。
「先 join、再显式释放、最后校验」这条顺序比「用 RAII 自动释放」在
Zig 里更实际——`join()` 是同步点，之后才能安全地断言没人再碰它。

---

上一章：[33 表达式解释器](33-zcalc.md) · 下一章：[35 ZLS 与编辑器工具链](35-zls.md)
