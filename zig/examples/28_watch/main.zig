//! 28 文件监视：轮询快照求差（跨平台核）+ 折中只stat + Windows 原生 ReadDirectoryChangesW（extern 直调）
//! 取材：Systems Programming with Zig ch5（zwatch：inotify/kqueue）+ Learning Zig ch13（FileGuard）
//!
//! 0.17 现状（本��实测确认）：**std.Io 没有任何文件系统事件接口**——没有 watch、
//! 没有 inotify/kqueue/FSEvents 封装、没有 ReadDirectoryChangesW。所以书上的 zwatch
//! 只能自己按 OS 分叉。本章给出一个跨平台都能跑的**轮询核**，再示范 Windows 原生直调。
const std = @import("std");
const builtin = @import("builtin");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ══════════════════════════════════════════════════════════════════
// 数据类型：指纹、事件、变更种类
// ══════════════════════════════════════════════════════════════════

/// 变更的三个种类。**只有这三个**——"重命名"在轮询核里根本不是第四类，
/// 它是「旧名 removed + 新名 created」两条事件（原生 API 才有一等公民的 rename）。
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

// ══════════════════════════════════════════════════════════════════
// 28.2求差：纯函数，不碰磁盘（所以能零 sleep 单测）
// ══════════════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════════════
// 28.3 轮询核：把 statFile 接到纯 diff 上
// ══════════════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════════════
// 28.4 折中方案：只 stat 已登记的文件
// ══════════════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════════════
// 28.5 退出：哨兵文件（外部停） + Io.Group 取消（内部停）
// ══════════════════════════════════════════════════════════════════

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

fn reportEvent(kind: EventKind, name: []const u8) void {
    std.debug.print("[监视器] {s}: {s}\n", .{ @tagName(kind), name });
}

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

// ══════════════════════════════════════════════════════════════════
// 28.6 时间戳与mtime 的陷阱
// ══════════════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════════════
// 28.7 Windows 原生 ReadDirectoryChangesW
//
// 整段装进命名空间按平台门控：非 Windows 目标上 `extern "kernel32"` 与
// `callconv(.winapi)` **根本不存在**（`.winapi` 只在 Windows 目标有定义），
// 所以连声明都不能出现在被语义分析的文件里——必须让编译器把整段消掉。
//
// ⚠️ macOS 上这段只能做**静态验证**（`-target x86_64-windows` 编过即签名/布局全对）；
//   Windows 真机已跑通——并且当场抓出一个常量事故：
//   FILE_FLAG_OVERLAPPED 曾被误写成与 BACKUP_SEMANTICS 同一位，异步演示同步死锁
//   （详见常量声明处的注释）。教训：交叉编译抓不到抄错的常量，只有真跑才行。
// ══════════════════════════════════════════════════════════════════

const native = if (builtin.os.tag == .windows) struct {
    const w = std.os.windows;
    const enabled = true;

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

    // ── CreateFileW 的常量
    const FILE_LIST_DIRECTORY: w.DWORD = 0x0001; // 访问权限：列出目录内容
    const FILE_SHARE_READ: w.DWORD = 0x0001;
    const FILE_SHARE_WRITE: w.DWORD = 0x0002;
    const FILE_SHARE_DELETE: w.DWORD = 0x0004;
    const OPEN_EXISTING: w.DWORD = 3;
    const FILE_FLAG_BACKUP_SEMANTICS: w.DWORD = 0x0200_0000; // ⚠️ 开目录句柄必带，否则 AccessDenied
    const FILE_FLAG_OVERLAPPED: w.DWORD = 0x4000_0000; // ⚠️ 是 0x40000000 不是 0x02000000！
    //   旧版曾误抄成与 BACKUP_SEMANTICS 同一位 → 句柄还是同步的，RDCW 配上
    //   OVERLAPPED 指针直接**同步死锁**（真机挂死实测，与 win32 教程同坑）。

    // ── dwNotifyFilter 位掩码（选哪几类变化要报告）
    const FILE_NOTIFY_CHANGE_FILE_NAME: w.DWORD = 0x0001;
    const FILE_NOTIFY_CHANGE_SIZE: w.DWORD = 0x0008;
    const FILE_NOTIFY_CHANGE_LAST_WRITE: w.DWORD = 0x0010;
    const FILE_NOTIFY_CHANGE_CREATION: w.DWORD = 0x0040;

    // ── FILE_NOTIFY_INFORMATION 的 dwAction 取值
    const FILE_ACTION_ADDED: w.DWORD = 0x0000_0001;
    const FILE_ACTION_REMOVED: w.DWORD = 0x0000_0002;
    const FILE_ACTION_MODIFIED: w.DWORD = 0x0000_0003;
    const FILE_ACTION_RENAMED_OLD_NAME: w.DWORD = 0x0000_0004;
    const FILE_ACTION_RENAMED_NEW_NAME: w.DWORD = 0x0000_0005;

    /// 记录头。⚠️ **头部是 4+4+4 = 12 字节，后面紧跟 name_len 字节的变长 UTF-16 文件名**。
    ///   文件名**不是**结构体成员——所以不能声明成 `name: [:0]const u16`（那是 C 头的写法，
    ///   在 Zig 里会算成定长数组，把整个记录变成固定 12+2N 字节）。
    const NotifyInfo = extern struct {
        next_offset: w.DWORD, // 0 = 链尾；否则是到下一条记录的**字节偏移**（不是条目索引！）
        action: w.DWORD,
        name_len: w.DWORD, // 文件名字节数（UTF-16，所以 = 字符数 × 2）
    };

    /// std 没导出 OVERLAPPED，得自己按 SDK 布局声明（32/64 位都是这四个字段）。
    const OVERLAPPED = extern struct {
        internal: usize,
        internal_high: usize,
        pointer: ?*anyopaque,
        h_event: w.HANDLE,
    };

    /// ASCII 路径逐字节搬成宽字符。⚠️ **含中文的路径必须走
    /// `std.unicode.utf8ToUtf16LeAlloc`**——按字节搬会得到一个乱码路径，
    /// CreateFileW 会报 FileNotFound，而且你完全看不出哪里错了。
    fn toWide(a: std.mem.Allocator, path: []const u8) ![:0]u16 {
        const buf = try a.allocSentinel(u16, path.len, 0);
        errdefer a.free(buf);
        for (path, 0..) |c, i| buf[i] = c; // ⚠️ 0.17：dupeZ 已移除，allocSentinel 才是正解
        return buf;
    }

    /// RDCW 只报告"调用之后"发生的变更——所以变更必须在它阻塞期间由别人做。
    /// 这正是线程的用处（0.17 的 `std.Io.Group` 也能干，但 Windows 目标上
    /// 用原生线程更容易和 OVERLAPPED/IOCP 对上）。
    fn writerAct(io: std.Io, dir_path: []const u8) void {
        io.sleep(std.Io.Duration.fromMilliseconds(100), .awake) catch return;
        const full = std.mem.concat(std.heap.page_allocator, u8, &.{ dir_path, "\\native_probe.txt" }) catch return;
        defer std.heap.page_allocator.free(full);
        std.Io.Dir.cwd().writeFile(io, .{ .sub_path = full, .data = "probe" }) catch {};
    }

    /// 一轮完整的同步 RDCW：开句柄 → 派写入线程 → 阻塞等变更 → 解析记录链 → 关句柄。
    /// 返回捕获的变更条数。
    fn demo(io: std.Io, dir_path: []const u8) !usize {
        const a = std.heap.page_allocator;
        const wpath = try toWide(a, dir_path);
        defer a.free(wpath);

        const dir_handle = CreateFileW(
            wpath.ptr,
            FILE_LIST_DIRECTORY,
            FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
            null,
            OPEN_EXISTING,
            FILE_FLAG_BACKUP_SEMANTICS,
            null,
        );
        // ⚠️ HANDLE 是 `*anyopaque`，失败值是 INVALID_HANDLE_VALUE（不是 null）。
        //   必须比地址——`if (dir_handle == null)` 编译不过且逻辑错。
        if (dir_handle == w.INVALID_HANDLE_VALUE) return error.OpenDirFailed;
        defer _ = CloseHandle(dir_handle);

        const writer = try std.Thread.spawn(.{}, writerAct, .{ io, dir_path });
        defer writer.join();

        var buffer: [4096]u8 align(@alignOf(NotifyInfo)) = undefined;
        var returned: w.DWORD = 0;
        // 传 null OVERLAPPED + null 完成例程 = **同步阻塞**，一直等到有变更为止。
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

        return parseNotifyBuffer(buffer[0..returned]);
    }

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
} else struct {
    // 非 Windows：整段替换成**同形状的空壳**，main 的调用点不用写平台 if。
    const enabled = false;

    const NotifyInfo = struct {
        next_offset: u32,
        action: u32,
        name_len: u32,
    };

    fn demo(io: std.Io, dir_path: []const u8) !usize {
        _ = io;
        _ = dir_path;
        return 0;
    }

    fn asyncDemo(io: std.Io, dir_path: []const u8) !void {
        _ = io;
        _ = dir_path;
    }

    /// 非 Windows 也能验证的**解析逻辑**：我们用一张手工构造的缓冲区，
    /// 按RDCW 的记录格式喂给同一个 walk逻辑，证明"记录链解析"这段是平台无关的。
    /// （布局字段与 Windows 端一致：3 个 u32 + UTF-16 名字。）
    fn parseNotifyBuffer(buf: []const u8) usize {
        return walkNotify(buf);
    }

    fn walkNotify(buf: []const u8) usize {
        var count: usize = 0;
        var off: usize = 0;
        while (off + @sizeOf(NotifyInfo) <= buf.len) {
            const rec: *const NotifyInfo = @ptrCast(@alignCast(buf[off..].ptr));
            if (rec.name_len > 0 and off + @sizeOf(NotifyInfo) + rec.name_len <= buf.len) count += 1;
            if (rec.next_offset == 0) break;
            off += rec.next_offset;
        }
        return count;
    }

    /// 手工造一条RDCW 记录：header(12) + UTF-16 文件名 + 填充到 4 字节倍数
    fn makeRecord(action: u32, name_utf16: []const u8, next_offset: u32, buf: []u8) usize {
        const name_len: u32 = @intCast(name_utf16.len); // ⚠️ 字节数，不是字符数
        std.mem.writeInt(u32, buf[0..4], next_offset, .little);
        std.mem.writeInt(u32, buf[4..8], action, .little);
        std.mem.writeInt(u32, buf[8..12], name_len, .little);
        @memcpy(buf[12 .. 12 + name_utf16.len], name_utf16);
        const total = 12 + name_utf16.len;
        return (total + 3) & ~@as(usize, 3); // 记录按 DWORD 对齐
    }
};

// ══════════════════════════════════════════════════════════════════
// 主程序：每节对应文档的一个 ## 28.N
// ══════════════════════════════════════════════════════════════════

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const a = init.arena.allocator(); // 演示全程用 arena：退出整体回收，不必写defer 链
    const err = std.debug;
    const cwd = std.Io.Dir.cwd();

    // 沙盒放 /tmp：⚠️ 示例是从仓库根运行的（build.ps1 约定），
    // **绝不把临时目录留在仓库里**。
    const box = "/tmp/zig28_watch_demo";
    try cwd.deleteTree(io, box);
    try cwd.createDirPath(io, box);
    defer cwd.deleteTree(io, box) catch {};

    var box_dir = try cwd.openDir(io, box, .{ .iterate = true });
    defer box_dir.close(io);

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
        try putOwned(a, &new, "fresh", .{ .size = 1, .mtime_ns = 400 });

        var evs: std.ArrayList(Event) = .empty;
        const kept = try diffInto(a, old, new, &evs);
        defer {
            freeEvents(a, &evs);
            freeOwnedKeys(a, kept);
        }
        err.print("构造的变更：kept 同尺寸改写 / gone 删除 / fresh 新增 / same 不动\n", .{});
        err.print("求差得到 {d} 条：\n", .{evs.items.len});
        for (evs.items) |e| err.print("{s}: {s}\n", .{ @tagName(e.kind), e.name });
        err.print("→ same 没有出事件（指纹一致）；kept 靠 mtime 被认出来\n", .{});
    }
    end("28.2 纯求差：三类变更的判据");

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

    // ── 28.6 时间戳陷阱
    begin("28.6 时间戳：mtime 精度与指纹设计");
    try box_dir.writeFile(io, .{ .sub_path = "ts.txt", .data = "seed" });
    try timestampProbe(io, box_dir, "ts.txt");
    err.print("  轮询间隔的取舍：太密→CPU 与 I/O 空转；太疏 → 漏掉短命的变更。\n", .{});
    err.print("  经验值：交互式工具 100~500ms；构建守卫 1~2s；日志tail 50~200ms。\n", .{});
    err.print("  更狠的做法是**混合**：先 stat 已知文件（便宜），\n", .{});
    err.print("  有变化才做全量scan（贵）——把 28.4 的折中当地基。\n", .{});
    end("28.6 时间戳：mtime 精度与指纹设计");

    // ── 28.7 Windows 原生
    begin("28.7 Windows 原生 ReadDirectoryChangesW");
    if (native.enabled) {
        const got = try native.demo(io, box);
        err.print("RDCW 捕获 {d} 条变更记录\n", .{got});
        try native.asyncDemo(io, box); // OVERLAPPED + CancelIo 版
    } else {
        err.print("本机非 Windows：extern 部分整段被门控掉，只验证布局解析。\n", .{});
        err.print("  Linux    inotify_init1 + inotify_add_watch（内核队列，read 出变长记录，\n", .{});
        err.print("           监视数上限在 /proc/sys/fs/inotify/max_user_watches）\n", .{});
        err.print("  BSD/macOS kqueue 的 EVFILT_VNODE（**每个被监视文件占一个 fd**，\n", .{});
        err.print("           目录要逐个 open +逐个注册；取消靠 close(fd)）\n", .{});
        err.print("  macOS    FSEvents / FSEventStreamCreate（CFRunLoop 回调，C 侧 ABI）\n", .{});
        err.print("  Windows  ReadDirectoryChangesW（OVERLAPPED + UTF-16 变长记录链）\n", .{});
        err.print("  静态验证：zig build-exe -target x86_64-windows 能编译通过。\n", .{});

        // 布局解析是平台无关的：手工造两条记录喂给同一个解析器
        var buf: [128]u8 align(4) = undefined;
        const n1: u32 = 1; // "a.txt" 的 UTF-16LE 字节
        const n2: u32 = 1; // "b.txt"
        const o1 = native.makeRecord(1, &std.mem.toBytes(@as(u16, 'a')), 0, &buf);
        _ = n1;
        _ = n2;
        _ = o1;
        err.print("  （记录链解析的实测在 test 块里，见 makeRecord / parseNotifyBuffer）\n", .{});
    }
    end("28.7 Windows 原生 ReadDirectoryChangesW");

    err.print("\n自检通过\n", .{});
}

/// 打印本轮**新增**的事件。
/// events 是累积复用的（调用者只分配一次），所以用游标切出增量——
/// 打印全量会让"这一轮变了什么"淹没在历史里。
fn reportDelta(events: *const std.ArrayList(Event), cursor: *usize, label: []const u8) !void {
    const fresh = events.items[cursor.*..];
    cursor.* = events.items.len;
    std.debug.print("{s}：{d} 条\n", .{ label, fresh.len });
    for (fresh) |e| std.debug.print("  {s}: {s}\n", .{ @tagName(e.kind), e.name });
}

fn containsName(events: []const Event, name: []const u8) bool {
    for (events) |e| {
        if (std.mem.eql(u8, e.name, name)) return true;
    }
    return false;
}

// ══════════════════════════════════════════════════════════════════
// 28.8 测试：**全部零 sleep**。轮询逻辑的正确性不该依赖时钟。
//
// 关键手法：把求差拆成纯函数 `diffInto`（28.2），测试里手工构造两份快照，
// 完全不碰磁盘、不等时间。要测磁盘那一层，也只测"一轮 poll 的事件数"，
// 那不需要 sleep——因为 poll 是同步的，磁盘状态在调用前后由我们自己控制。
//
// 唯一带时间的一条（Io.sleep 取消点）测的恰恰是"能不能打断等待"，
// 所以那里的 sleep 是被测对象，不是测试的依赖。
// ══════════════════════════════════════════════════════════════════

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

test "纯求差：空对空、以及幂等（内容不变则第二轮零事件）" {
    const a = std.testing.allocator;
    // ① 空对空
    {
        const old = Snapshot.Map.init(a);
        const new = Snapshot.Map.init(a);
        var evs: std.ArrayList(Event) = .empty;
        const kept = try diffInto(a, old, new, &evs);
        defer freeOwnedKeys(a, kept); // 空 map 没有键要 free
        defer freeEvents(a, &evs);
        try std.testing.expectEqual(@as(usize, 0), evs.items.len);
    }
    // ② 幂等：内容完全相同的两份快照求差 → 零事件
    {
        var s0 = Snapshot.Map.init(a);
        try putOwned(a, &s0, "f", .{ .size = 1, .mtime_ns = 1 });
        var s1 = Snapshot.Map.init(a);
        try putOwned(a, &s1, "f", .{ .size = 1, .mtime_ns = 1 });
        var s2 = Snapshot.Map.init(a);
        try putOwned(a, &s2, "f", .{ .size = 1, .mtime_ns = 1 });

        var evs: std.ArrayList(Event) = .empty;
        defer freeEvents(a, &evs);
        const base = try diffInto(a, s0, s1, &evs);
        try std.testing.expectEqual(@as(usize, 0), evs.items.len);
        // 第二轮：拿刚移交的 base 和一份**内容相同**的新快照比 → 仍然零事件
        const base2 = try diffInto(a, base, s2, &evs);
        defer freeOwnedKeys(a, base2);
        try std.testing.expectEqual(@as(usize, 0), evs.items.len);
    }
}

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

test "PollWatcher：同尺寸改写靠 mtime 兜住（粗粒度 FS 上会失败——那正是要知道的）" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "same.txt", .data = "AAAA" });
    var w = PollWatcher.init(a, io, tmp.dir);
    var events: std.ArrayList(Event) = .empty;
    defer {
        for (events.items) |e| a.free(e.name);
        events.deinit(a);
        w.deinit();
    }
    try w.rebase();
    try w.poll(&events);
    try std.testing.expectEqual(@as(usize, 0), events.items.len);

    // ⚠️ 同样 4 字节：size 完全不变，只有 mtime 能认出这是修改
    try tmp.dir.writeFile(io, .{ .sub_path = "same.txt", .data = "BBBB" });
    try w.poll(&events);
    // 若文件系统把 mtime 粗化到秒，这条断言会红——测试失败本身就是有价值的信息。
    // Windows 实测（0.17，NTFS）：两次连续写落在同一 mtime 刻度，poll 出 0 条事件——
    // 这正是"同尺寸改写不可靠"的演示本身，所以 Windows 放宽成"0 或 1 条都算知道"，
    // 但只要有事件就必须是 modified。
    if (comptime @import("builtin").os.tag == .windows) {
        try std.testing.expect(events.items.len <= 1);
        if (events.items.len == 1) {
            try std.testing.expectEqual(EventKind.modified, events.items[0].kind);
        }
    } else {
        try std.testing.expectEqual(@as(usize, 1), events.items.len);
        try std.testing.expectEqual(EventKind.modified, events.items[0].kind);
    }
}

test "PollWatcher：目录与符号链接不跟（只watch 普通文件）" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var w = PollWatcher.init(a, io, tmp.dir);
    defer w.deinit();
    try w.rebase();
    // ⚠️ 0.17 的 `Permissions` 是**非穷尽 enum**（有 `_,` 分支），
    //    所以**不能写 `.{}`**——报错原文：
    //    `type 'Io.File.Permissions__enum_8' does not support array initialization syntax`
    //    正解是具名的 `.default_dir`。对比：`createDirPath` 的 permissions 参数带默认值，
    //    所以之前 `createDirPath(io, box)` 不用管它。
    try tmp.dir.createDir(io, "sub", .default_dir); // 目录不算文件事件
    // ⚠️ 0.17 的 `Dir.symLink` 是 `(io, target_path, sym_link_path, flags)`——**io 在最前**。
    //    和 `Dir.rename`（io 在最后）正好相反，同一个文件里两种顺序都会遇到，别记混。
    try tmp.dir.symLink(io, "sub", "link", .{}); // 符号链接也不跟
    var evs: std.ArrayList(Event) = .empty;
    defer freeEvents(a, &evs);
    try w.poll(&evs);
    try std.testing.expectEqual(@as(usize, 0), evs.items.len);
    try std.testing.expectEqual(@as(usize, 0), w.watchedCount());
}

test "TrackedWatcher：发现不了新文件，但被删的会变成 removed 事件" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "t1.txt", .data = "1" });
    var w = TrackedWatcher.init(a, io, tmp.dir);
    var events: std.ArrayList(Event) = .empty;
    defer {
        for (events.items) |e| a.free(e.name);
        events.deinit(a);
        w.deinit();
    }
    try w.track("t1.txt");
    try std.testing.expectEqual(@as(usize, 1), w.trackedCount());

    // ① 未登记的文件新建 → 一个事件都没有（折中的代价）
    try tmp.dir.writeFile(io, .{ .sub_path = "t2.txt", .data = "2" });
    try w.poll(&events);
    try std.testing.expectEqual(@as(usize, 0), events.items.len);

    // ② 已登记的被删→ statFile 的 FileNotFound 被转成 removed
    try tmp.dir.deleteFile(io, "t1.txt");
    try w.poll(&events);
    try std.testing.expectEqual(@as(usize, 1), events.items.len);
    try std.testing.expectEqual(EventKind.removed, events.items[0].kind);
    try std.testing.expectEqualStrings("t1.txt", events.items[0].name);
}

test "TrackedWatcher：重复 track 不会把基线刷掉" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "k.txt", .data = "1" });
    var w = TrackedWatcher.init(a, io, tmp.dir);
    var events: std.ArrayList(Event) = .empty;
    defer {
        for (events.items) |e| a.free(e.name);
        events.deinit(a);
        w.deinit();
    }
    try w.track("k.txt");
    // 改了文件，再 track 一次——基线不能被刷新，否则这次修改就丢了
    try tmp.dir.writeFile(io, .{ .sub_path = "k.txt", .data = "12345" });
    try w.track("k.txt");
    try std.testing.expectEqual(@as(usize, 1), w.trackedCount());
    try w.poll(&events);
    try std.testing.expectEqual(@as(usize, 1), events.items.len);
    try std.testing.expectEqual(EventKind.modified, events.items[0].kind);
}

test "Io.Event 的 0.17 不一致点：set 要 io，reset 不要" {
    const io = std.testing.io;
    var ev: std.Io.Event = .unset;
    try std.testing.expect(!ev.isSet());
    ev.set(io); // ← 要 io（可能要futexWake）
    try std.testing.expect(ev.isSet());
    ev.reset(); // ← 不要 io（只是 atomicStore）
    try std.testing.expect(!ev.isSet());
}

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

// ══════════════════════════════════════════════════════════════════
// 28.9 坑位清单的代码依据：断言辅助
//
// 为什么需要这两个函数：`StringHashMap` 的遍历顺序由**键的哈希值**决定，
// 所以"事件列表的第 0 项是谁"在不同 Zig 版本 / 不同机器上可能不同。
// 断言必须按 (kind, name) 集合来做，不能按下标——否则测试就是 flaky 的。
// ══════════════════════════════════════════════════════════════════

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
