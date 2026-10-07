//! 34 实战：内存 KV 缓存服务器 zcache——LRU 淘汰 + TCP 行协议 + 并发访问
//!
//! 取材 Systems Programming with Zig ch10（zcache：LRU = HashMap + 双向链表，
//! 为什么两个结构都要）。运输层沿用 29/30 章：`std.Io.net` 的
//! `IpAddress.listen / connect` → `Server` / `Stream`，收发走 Reader/Writer，
//! 每个方法第一个参数都是 `io`。
//!
//! **稳定性纪律（本章第一原则）**：网络 + 并发示例的输出极易漂移。四条对策：
//!   1) 标记区间里**不出现任何裸耗时/吞吐数字**——只印确定性结论
//!      （命中率、校验和、淘汰次数、字节账）。
//!   2) 基准测试不比耗时，比 **work（基本操作计数）**：同一份负载下 work 的
//!      量级差异 = 复杂度的量级差异，而 work 是整数，连跑一万次也不变。
//!   3) 端口用 `listen(0)` 拿内核分配的 ephemeral 端口，且**只印「非 0：是」**。
//!   4) 并发段用「差值断言」（STAT 前后相减）+「按槽位汇总的校验和」，
//!      两者都与线程交错无关；尾部用 `DebugAllocator.deinit() == .ok` 反证零泄漏。
//!
//! 29/30 章已实测、本章直接复用的结论：`Stream.read(io, [][]u8)` 在 0.17.0
//! 标准库自身编译不过（Io/net.zig:1286）；`readSliceShort` 是「填满或 EOF」
//! 语义不能当 recv；`takeDelimiterExclusive` 不吃掉分隔符；`Stream.close`
//! 不幂等（二次 close 报 BADF panic）。
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

fn p(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt, args);
}

/// 表格分隔线。写成普通字面量而非 `"-"** 74` 数组重复，两个原因：
/// ① 0.17 的 `std.mem` 没有 `repeat`（@hasDecl 实测 = false）；
/// ② `**` 的空格规则很怪：`a** b` / `a**b` 可以，`a ** b` 会被判成
/// 「binary operator '*' has whitespace on one side, but not the other」，
/// 而字符串字面量 `"-"** 74` 又会解析成「expected type 'type', found 'comptime_int'」。
const sep_wide = "----------------------------------------------------------------------";
const sep_narrow = "--------------------------------------------";

// ═══════════════════════════════════════════════════════════════════════════
// 运输层：把 std.Io.net.Stream 包成「按行读、按行写」的连接对象
//
// 坑① **自引用结构体不能按值拷贝**：`stream.reader(io, buf)` 返回的 Reader
//     内部持有 buf 的指针。在 init() 里就地绑定，绑的是 init 的栈帧；一旦
//     `return self` 发生值拷贝，Reader 就指向已销毁的临时。正解是**懒绑定**。
// 坑② **close 不幂等**：close(fd) 之后既不把句柄置为无效也不报错，二次 close
//     命中 `.BADF => recoverableOsBugDetected()`，Debug 下 `unreachable` → panic。
//     纪律：一条连接只 close 一次，要么全 defer，要么全显式。
// 坑③ **`takeDelimiterExclusive` 在 0.17.0 有 std bug**：它只 `toss(result.len)`
//     而 result 不含分隔符 → 分隔符留在缓冲里，第二次起永远返回空片。
//     正解：fillMore + buffered + indexOfScalarPos + toss(含分隔符)。
// ═══════════════════════════════════════════════════════════════════════════

const Conn = struct {
    io: std.Io,
    stream: std.Io.net.Stream,
    rbuf: [4096]u8 = undefined,
    r: std.Io.net.Stream.Reader,
    wbuf: [4096]u8 = undefined,
    w: std.Io.net.Stream.Writer,
    bound: bool = false,

    /// ⚠️ 这里**不能**顺手写 `r = stream.reader(io, &rbuf)`——见坑①。
    fn init(io: std.Io, stream: std.Io.net.Stream) Conn {
        return .{ .io = io, .stream = stream, .r = undefined, .w = undefined };
    }

    fn ensureBound(self: *Conn) void {
        if (self.bound) return;
        self.r = self.stream.reader(self.io, &self.rbuf);
        self.w = self.stream.writer(self.io, &self.wbuf);
        self.bound = true;
    }

    fn close(self: *Conn) void {
        self.stream.close(self.io);
    }

    fn sendLine(self: *Conn, s: []const u8) !void {
        self.ensureBound();
        try self.w.interface.writeAll(s);
        try self.w.interface.writeAll("\n");
        try self.w.interface.flush();
    }

    /// 读一行（不含 '\n'），**拷进调用方缓冲 out** 再返回。
    ///
    /// 为什么必须拷？`return buffered()[0..at]` 是指向内部缓冲的切片，
    /// 下一次 fillMore / toss 立刻让它失效。拷贝后所有权归调用方。
    ///
    /// 为什么会 LineTooLong？协议给行开了闸门（out.len）：恶意对端发一个
    /// 1MB 请求行，没有这道闸就是一次 OOM。
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

    /// 把「超长行的残余」吃到 '\n' 为止。
    ///
    /// 为什么必须有它：recvLine 撞闸门时**故意不消费任何字节**，缓冲里还留着
    /// 那条超长行的后半截。不清干净的话下一次 recvLine 会把残余当成新命令解析
    /// ——「拒绝了一条超长行之后，后面所有命令全乱」。这是「报错但不伤连接」
    /// 与「报错即断连」的分界线。
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

    /// 已缓冲但尚未消费的字节数。用来验证 drainLine 真把残余吃干净了。
    fn pending(self: *Conn) usize {
        self.ensureBound();
        return self.r.interface.buffered().len;
    }
};

// ═══════════════════════════════════════════════════════════════════════════
// 34.2 的四种 LRU 实现：数组线性查找 / 手写哨兵链表 / std 链表 / 哈希表+链表
//
// 四者语义**完全相同**（同一个 LRU 契约：命中提新、超容量淘汰最旧），
// 所以同一份工作负载跑下来 hits/misses/evictions 必须逐个相等——这是本章
// 最省事的交叉验证：三份独立代码算出同一个答案。唯一会不同的是 work。
//
// work 的口径（四个实现必须用同一把尺子）：
//   · 一次键比较算 1
//   · 一次数组元素搬移算 1
//   · 一次链表**指针写**算 1（B 与 C 的 remove 各改 2 个指针、prepend 各改 3 个）
//   · 一次哈希表查找算 1（它内部是 O(1) 的常数级工作量）
//   · **空闲链的出入一律按 0 计**——B 用下标、C 用 std.DoublyLinkedList，
//     实现不同但都不计入，才可比。
// 这套口径是对齐过的。第一版 B 按「指针写次数」算、C 只按「操作次数」算，
// 于是 B=2086 / C=1736，差额恰好 = 35 次淘汰 × 2 次漏算的指针写。
// 拿两把不同的尺子去论证「std 不改变复杂度」，那个论证本身就不成立。
// ═══════════════════════════════════════════════════════════════════════════

const bench_keys = [_][]const u8{ "k0", "k1", "k2", "k3", "k4", "k5", "k6", "k7" };
const bench_capacity: usize = 4;
const bench_ops: usize = 200;

const BenchResult = struct { hits: usize, misses: usize, evictions: usize, work: usize };

/// 固定种子的 LCG。**不用 std.Random**——它可能随版本换算法，
/// 而本章要的是「连跑一万次逐字节一致」的工作负载，必须钉死。
fn benchRng(state: *u64) u64 {
    state.* = state.* *% 6364136223846793005 +% 1442695040888963407;
    return state.*;
}

/// 跑一份工作负载，返回统计。`work` 由各实现自己累加。
///
/// ⚠️ 用 `var c: Impl = undefined; c.init(...)` 而不是 `var c = Impl.init(...)`。
/// 原因和上面坑①**完全一样**：init 返回值时发生值拷贝，若 init 内部把指针
/// 写进了 init 的栈帧（StdListLru 的空闲链就是这样），拷贝之后那些指针全指向
/// 已销毁的临时 → 实测直接 Segmentation fault。铁律：init 只做纯赋值。
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
/// get O(n) 扫描；提新要把元素搬到数组头，搬 n 个元素也是 O(n)；
/// 淘汰要在数组里找 seq 最小的，再 swapRemove 搬移——三处 O(n)。
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
///
/// 哨兵（sentinel）是一个不装数据的空节点，**待在结构体字段里**，地址永远稳定。
/// 链表成环：sentinel.next 是最新、sentinel.prev 是最旧。好处是「摘队首」
/// 「挂队尾」「判空」都不需要 null 分支——没有哨兵的话每个方向都得写两套代码。
///
/// 节点用下标（u8）而不是指针：整张表在一个定长数组里，无堆分配、无悬垂风险。
/// 0 号固定是哨兵；空闲槽位也用一条链表串起来（`next` 字段复用）。
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
/// 结论会很有意思：**复杂度一模一样，代码少一大截**——这正是 std 存在的意义。
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

// ═══════════════════════════════════════════════════════════════════════════
// 生产 LRU 核：std.StringHashMap(*Entry) + std.DoublyLinkedList
//
//   map   —— O(1) 按键定位条目
//   order —— O(1) 记新旧序（first = 最新，last = 淘汰候选）
//
// 两个结构缺一不可：单用 HashMap，找得到但不知谁最旧；单用链表，知新旧
// 但找不快。合体后 get 命中即 touch（摘下重挂队首），淘汰就是摘链表尾巴。
//
// ⚠️ 键的生命周期：`StringHashMap` 的 put **只存切片本身、不复制内容**
//    （所以 put 一个栈上缓冲的切片，缓冲一被改写键就变了）。
//    本实现因此**先 dupe 再 put**——map 里的键和 entry.key 是同一份自有内存，
//    deinit 时沿链表走一遍释放，map.deinit() 只放表不放键。
//    0.17 的 StringHashMap **没有 putOwned**（@hasDecl 实测 = false），
//    dupe + put 就是 0.17 的唯一写法。
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

// ═══════════════════════════════════════════════════════════════════════════
// 协议与服务器
//
// 请求（行协议，一行一条，行尾 '\n'）：
//   GET <key>          → VALUE <value> | MISS
//   PUT <key> <value>  → OK
//   DEL <key>          → OK | MISS
//   STAT               → STAT hits=.. misses=.. evictions=.. entries=.. bytes=..
//   PING               → PONG
// 错误一律 `ERR <原因>`，原因集合是闭集（见 34.11）。
//
// 为什么不用 HTTP（30 章已完整实现过）：自定义协议更短、能精确测字节级行为。
// HTTP 一行最少要带版本号和 Host 头，行缓冲和 CRLF 处理会把「LRU 对不对」
// 这个真正要验的东西埋掉；本章要断言的就是「第 7 条命令之后淘汰了谁」，
// 协议越薄，断言越锋利。
// ═══════════════════════════════════════════════════════════════════════════

const max_line = 1024; // 行闸门：超长即拒，防单连接 OOM
const max_value = 256; // 值闸门
const max_key = 64;
const max_conn_threads = 32; // accept 线程池槽位上限；本章并发峰值 5

const Stat = struct { hits: usize = 0, misses: usize = 0, evictions: usize = 0, entries: usize = 0, bytes: usize = 0 };

/// 解析 `STAT k=v k=v …`。
/// ⚠️ 首 token **必须**字面等于 "STAT"：第一版只 `it.next() orelse return null`，
/// 于是 `parseStat("garbage")` 也返回一份全 0 的 Stat，单测当场失败。
/// 「静默返回一个默认值」的解析函数比报错难查得多。
fn parseStat(line: []const u8) ?Stat {
    var s = Stat{};
    var it = std.mem.tokenizeScalar(u8, line, ' ');
    const head = it.next() orelse return null;
    if (!std.mem.eql(u8, head, "STAT")) return null;
    while (it.next()) |tok| {
        const eq = std.mem.indexOfScalar(u8, tok, '=') orelse continue;
        const name = tok[0..eq];
        const val = std.fmt.parseInt(usize, tok[eq + 1 ..], 10) catch continue;
        if (std.mem.eql(u8, name, "hits")) s.hits = val;
        if (std.mem.eql(u8, name, "misses")) s.misses = val;
        if (std.mem.eql(u8, name, "evictions")) s.evictions = val;
        if (std.mem.eql(u8, name, "entries")) s.entries = val;
        if (std.mem.eql(u8, name, "bytes")) s.bytes = val;
    }
    return s;
}

const Ctx = struct {
    io: std.Io,
    lru: *Lru,
    lock: std.Io.Mutex = .init,
    failed: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    served: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
    stop: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

    /// 一条命令的执行体。锁只罩住「读改写 LRU」这三步——
    /// 网络收发**不进锁**，否则一个慢客户端能把整台服务器卡住。
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
};

/// 一条连接的完整生命周期：读到 EOF 为止。
/// ⚠️ close 用**显式 close、不写 defer**（坑②）：一旦同时存在显式 close 和
/// `defer close()`，第二次 close 必然 BADF panic。本文件一条连接只 close 一次。
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

/// accept 循环：一直服务到 `ctx.stop` 被置位为止。
///
/// `*Server` 是 accept 类方法的接收者（`const` 也不收），所以 srv 必须是
/// 可寻址的局部变量；连接处理**每条一个线程**——`Server` 本身不线程安全，
/// 但 accept 之后再 fork 各服务各的，互不干扰。
///
/// ⚠️ **关停协议**：accept 是阻塞的，没有「从外部唤醒它」的办法。这里用
/// 「置 stop 标志 + 再连一次」把 accept 叫醒：主线程跑完所有章节 →
/// `stop = true` → 建一条**立刻关掉**的连接 → 服务端 accept 返回、看到 stop、
/// 关掉它、跳出循环 → 主线程 join。
/// 比「预先数好连接条数」的预算式关停稳得多：本章第一版就按预算写的
/// （注释写 14 条），加了 34.6 / 34.12 两个并发段后实际要 18 条，
/// 结果预算耗尽、主线程 connect 拿到 `error.ConnectionRefused` 直接失败。
/// **「连接条数」是个会随代码演进而漂的量，不该出现在关停逻辑里。**
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
// ═══════════════════════════════════════════════════════════════════════════

fn connect(io: std.Io, port: u16) !Conn {
    const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", port);
    return Conn.init(io, try addr.connect(io, .{ .mode = .stream }));
}

/// 关停握手用的一条空连接：建了就立刻关，只为让服务端 accept 返回一次。
fn stopServer(io: std.Io, port: u16) void {
    var c = connect(io, port) catch return;
    c.close();
}

/// 发一条、收一条，字字比对。失配直接让整个程序失败——网络章节的断言不该
/// 「打印一行然后继续」，那样错误会滚到后面被淹没。
fn expect(conn: *Conn, buf: []u8, cmd: []const u8, want: []const u8) !void {
    try conn.sendLine(cmd);
    const got = try conn.recvLine(buf);
    if (!std.mem.eql(u8, got, want)) {
        p("  ✗ 协议失配：{s} → 期望 [{s}] 实得 [{s}]\n", .{ cmd, want, got });
        return error.ProtocolMismatch;
    }
}

fn readStat(conn: *Conn, buf: []u8) !Stat {
    try conn.sendLine("STAT");
    return parseStat(try conn.recvLine(buf)) orelse return error.BadStat;
}

/// 差值断言：并发章节里全局累计值取决于交错，**不能**硬编码绝对数字；
/// 但「这一段脚本自己制造了多少 hit」是确定的——比 STAT 前后差值即可。
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

fn bar(n: usize, max: usize, width: usize) void {
    const filled = if (max == 0) 0 else @min(width, n * width / max);
    var i: usize = 0;
    while (i < filled) : (i += 1) p("#", .{});
    i = filled;
    while (i < width) : (i += 1) p(".", .{});
}

/// 34.3 演示用的宿主结构：`id` 是业务数据，`link` 是侵入式链表节点。
const DllItem = struct { id: u32, link: std.DoublyLinkedList.Node = .{} };

/// 打印链表内容（first→last = 最新→最旧）。
/// ⚠️ 裸 `{` / `}` **不能**直接进格式串——std 的格式化器会把它当占位符开始符，
/// 于是报 "missing opening {" / "missing closing {"。要印就写 `{{` / `}}` 转义。
fn printDllList(l: *const std.DoublyLinkedList) void {
    var it = l.first;
    var first = true;
    p("{{", .{});
    while (it) |node| : (it = node.next) {
        if (!first) p(" ", .{});
        first = false;
        const item: *DllItem = @fieldParentPtr("link", node);
        p("{d}", .{item.id});
    }
    p("}}", .{});
}

/// 打印 LRU 的淘汰序：最旧 → ... → 最新。
fn printOrder(l: *const Lru) void {
    var buf: [16][]const u8 = undefined;
    const n = l.keysNewestFirst(&buf);
    var i: usize = n;
    while (i > 0) {
        i -= 1;
        p("{s}", .{buf[i]});
        if (i > 0) p(" < ", .{});
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// 34.1 项目总览与协议定义
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
// 34.2 四种 LRU 实现对比
// ═══════════════════════════════════════════════════════════════════════════

const Row = struct { name: []const u8, complexity: []const u8, r: BenchResult };

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

// ═══════════════════════════════════════════════════════════════════════════
// 34.3 std.DoublyLinkedList 的真实 API
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
// 34.4 键的生命周期
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
// 34.5 容量淘汰与统计
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
// 34.6 / 34.12 的并发客户端
// ═══════════════════════════════════════════════════════════════════════════

const ClientArg = struct {
    ctx: *Ctx,
    io: std.Io,
    port: u16,
    tag: []const u8,
    checksum: *u64,
};

/// 写自己的键空间、读自己的键空间，把校验和写进**自己那个槽位**——
/// 主线程按槽位顺序汇总，于是无论线程怎么交错，主线程印出来的数字都是确定的。
/// 键空间 4×16=64 < 容量 → 一个都不会被别人挤掉 → 每轮 GET 必然命中。
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

const PoolResult = struct { total: u64, sums: [4]u64 };

/// 4 客户端 × 250 轮，返回汇总校验和与每客户端的槽位值。
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

fn snapshot(io: std.Io, port: u16) !Stat {
    var c = try connect(io, port);
    defer c.close();
    return readStat(&c, &buf0);
}

// ═══════════════════════════════════════════════════════════════════════════

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    // 全程用 DebugAllocator：34.13 用它的 deinit() 反证零泄漏，尾部再整体校验。
    var dbg: std.heap.DebugAllocator(.{}) = .init;
    const a = dbg.allocator();

    sectionOverview();
    try sectionImplementations(a);
    sectionDoublyList();
    try sectionKeyLifetime(a);
    try sectionEviction(a);

    // ── 34.6 起进入网络。容量给足（4096），让并发段键空间互不干扰 ──────────
    var lru: Lru = undefined;
    lru.init(a, 4096);
    var ctx = Ctx{ .io = io, .lru = &lru };
    var port = std.atomic.Value(u16).init(0);
    const th = try std.Thread.spawn(.{}, serve, .{ &ctx, &port });
    while (port.load(.acquire) == 0) std.Thread.yield() catch {};
    const prt = port.load(.acquire);

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
    end("34.6 网络层与并发接入");

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
    end("34.7 行协议解析");

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
    end("34.8 超长行与缓冲区上限");

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
    end("34.9 连接生命周期");

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
    end("34.10 压力测试");

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
    end("34.11 边界情况");

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
    end("34.12 并发压力");

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
    end("34.13 内存与释放");

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
    end("34.14 综合实战");

    // ── 关停：置标志 + 建一条空连接把 accept 叫醒（见 serve 的注释）──
    ctx.stop.store(true, .release);
    stopServer(io, prt);
    th.join();
    if (ctx.failed.load(.acquire)) return error.ServerFailed;
    p("  服务端共接入 {d} 条连接，全部处理线程 join 完成，关停握手成功\n", .{
        ctx.served.load(.acquire),
    });

    // ═══ 34.15 测试 ═══
    begin("34.15 测试");
    p("  本节断言在 `zig test` 下运行（main 里不跑，它们要独享 allocator）\n", .{});
    p("  覆盖：LRU 各操作 / 淘汰边界 / 命中率 / 协议解析 / 错误路径 / 键生命周期\n", .{});
    end("34.15 测试");

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
}

// ═══════════════════════════════════════════════════════════════════════════
// 34.15 测试：LRU 核的确定性（不碰网络）
// ═══════════════════════════════════════════════════════════════════════════

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
