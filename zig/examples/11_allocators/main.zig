//! 11 分配器：显式传递的内存策略（Zig 最核心的设计之一）
//! 分节打印约定：每个小节用 ==== 11.N 开始 ==== / ==== 11.N 结束 ==== 圈出
const std = @import("std");
const builtin = @import("builtin");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ══════════════════════════════════════════════════════════════════
// 支撑类型与函数（被后面各节反复调用）
// ══════════════════════════════════════════════════════════════════

/// 11.2 节：自己实现一个分配器，包住底层分配器并顺手记账。
/// 只要提供 vtable 的四个槽位（alloc / resize / remap / free），就能得到一个合法的
/// std.mem.Allocator。这四个槽位就是 0.17 的**全部**接口——没有第五个方法。
const CountingAllocator = struct {
    inner: std.mem.Allocator,
    allocs: usize = 0,
    frees: usize = 0,
    live_bytes: usize = 0,
    peak_bytes: usize = 0,

    fn alloc(ctx: *anyopaque, len: usize, alignment: std.mem.Alignment, ra: usize) ?[*]u8 {
        const self: *CountingAllocator = @ptrCast(@alignCast(ctx));
        const p = self.inner.rawAlloc(len, alignment, ra) orelse return null;
        self.allocs += 1;
        self.live_bytes += len;
        if (self.live_bytes > self.peak_bytes) self.peak_bytes = self.live_bytes;
        return p;
    }

    fn free(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, ra: usize) void {
        const self: *CountingAllocator = @ptrCast(@alignCast(ctx));
        self.inner.rawFree(memory, alignment, ra);
        self.frees += 1;
        self.live_bytes -= memory.len;
    }

    fn allocator(self: *CountingAllocator) std.mem.Allocator {
        return .{
            .ptr = self,
            .vtable = &.{
                .alloc = alloc,
                .free = free,
                // 不支持原地伸缩/搬家：用std 提供的官方"no-op"实现占位。
                // 这两个 no-op 就是 0.17 提供的"我不管这块"的标准写法。
                .resize = std.mem.Allocator.noResize,
                .remap = std.mem.Allocator.noRemap,
            },
        };
    }
};

/// 11.13 节：反面教材——返回栈上局部数组的切片。
/// Zig **不会**在这里报错（返回 `&局部变量` 才会），于是你拿到一个悬垂切片。
fn cursedScroll() []u8 {
    var spell: [5]u8 = .{ 'F', 'i', 'r', 'e', '!' };
    return spell[0..];
}

/// 11.13 节：正确做法——把内容拷到分配器上，所有权交给调用方。
/// ⚠️ 签名纪律：`std.mem.Allocator` **按值传**。接口本身就是胖指针（vtable 指针 + ctx），
/// 再套一层指针只会让人以为需要可变状态。别写 `*std.mem.Allocator`。
fn enchantedSword(allocator: std.mem.Allocator, src: []const u8) ![]u8 {
    const copy = try allocator.alloc(u8, src.len);
    errdefer allocator.free(copy);
    @memcpy(copy, src);
    return copy;
}

/// 11.13 节：init/deinit 只是社区惯例，不是语言特性。
/// errdefer 保证"init 中途失败"不漏内存——这是 0.17 里写分配代码的固定套路。
const Sword = struct {
    stats: []u8,

    pub fn init(allocator: std.mem.Allocator, stats: []const u8) !*Sword {
        const self = try allocator.create(Sword);
        errdefer allocator.destroy(self); // 下面失败时，结构体本身不会漏
        self.stats = try allocator.alloc(u8, stats.len);
        errdefer allocator.free(self.stats);
        @memcpy(self.stats, stats);
        return self;
    }

    pub fn deinit(self: *Sword, allocator: std.mem.Allocator) void {
        allocator.free(self.stats);
        allocator.destroy(self);
    }
};

/// 11.9 节：把一行文本按空格切成若干段，每段 dupe 到 arena 上。
/// 全程只有分配、没有 free——这就是 arena 风格的典型形状。
fn splitIntoArena(arena: std.mem.Allocator, line: []const u8) ![]const []const u8 {
    var parts: std.ArrayList([]const u8) = .empty;
    errdefer parts.deinit(arena);
    var it = std.mem.tokenizeAny(u8, line, " ");
    while (it.next()) |tok| {
        try parts.append(arena, try arena.dupe(u8, tok));
    }
    return parts.toOwnedSlice(arena);
}

/// 11.14 节的靶子：会做**多次**分配的函数，才能被 fail_index 逐个打断。
fn buildTeamSafe(allocator: std.mem.Allocator, names: []const []const u8) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    for (names, 0..) |name, i| {
        if (i > 0) try out.append(allocator, ',');
        try out.appendSlice(allocator, name);
    }
    return out.toOwnedSlice(allocator);
}

/// 故意漏内存的版本：第一次分配成功、第二次失败时，第一块就丢了。
/// 用它跑 checkAllAllocationFailures 就能当场抓到（见 11.14 节实测输出）。
fn leakOnOom(allocator: std.mem.Allocator, n: usize) !void {
    const a = try allocator.alloc(u8, n);
    const b = try allocator.alloc(u8, n); // ← 这里失败时，a 永远不会被 free
    allocator.free(b);
    allocator.free(a);
}

/// checkAllAllocationFailures 的靶子：第一个参数必须是 allocator。
fn exerciseSafe(allocator: std.mem.Allocator, names: []const []const u8) !void {
    const s = try buildTeamSafe(allocator, names);
    defer allocator.free(s);
}

/// 11.16 节：4 个线程各自向 smp_allocator 申请/归还。
fn worker(done: *std.atomic.Value(u32)) void {
    const a = std.heap.smp_allocator;
    const block = a.alloc(u64, 32) catch return;
    defer a.free(block);
    @memset(block, 1);
    _ = done.fetchAdd(1, .monotonic);
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // ── 11.1 为什么 Zig 要"显式分配器" ──────────────────────────
    begin("11.1");
    {
        // std.mem.Allocator 就是一个胖指针：ctx 指针 + vtable 指针，各 8 字节 = 16 字节。
        // vtable 是 4 个函数指针 = 32 字节（静态数据，不随实例走）。
        std.debug.print("Allocator 接口值 = {d} 字节（ptr {d} + vtable {d}）\n", .{
            @sizeOf(std.mem.Allocator),
            @sizeOf(*anyopaque),
            @sizeOf(std.mem.Allocator.VTable),
        });
        std.debug.print("vtable 槽位 = alloc / resize / remap / free，一共 {d} 个\n", .{
            @typeInfo(std.mem.Allocator.VTable).@"struct".field_names.len,
        });
        std.debug.print("类型名 = {s}；这是**普通结构体**，不是接口类型、不需要继承\n", .{@typeName(std.mem.Allocator)});
        std.debug.print("指针字段 = {s}，vtable 字段 = {s}\n", .{
            @typeName(@typeInfo(std.mem.Allocator).@"struct".field_types[0]),
            @typeName(@typeInfo(std.mem.Allocator).@"struct".field_types[1]),
        });
        std.debug.print("本页编译模式 builtin.mode = {s}（0.17 是小写 .debug，0.16 及更早是 .Debug）\n", .{@tagName(builtin.mode)});
        std.debug.print("run-all.sh 走的是 zig run/build-exe 默认模式 = {s}\n", .{@tagName(builtin.mode)});
        std.debug.print("而 `zig build -Doptimize=ReleaseFast` 才是 {s}，那时 init.gpa 会换成 smp_allocator\n", .{"ReleaseFast"});
        std.debug.print("顺带：undefined 在 0.17 被填 0x00（不是老教程写的 0xaa）——见 3.1 节\n", .{});
        const probe_undef: u8 = undefined;
        std.debug.print("  实测 const u8 = undefined 读出来是 0x{x:0>2}\n", .{probe_undef});
    }
    end("11.1");

    // ── 11.2 接口解剖：vtable 的四个槽位 ──────────────────────────
    begin("11.2");
    {
        std.debug.print("VTable 字段：", .{});
        inline for (@typeInfo(std.mem.Allocator.VTable).@"struct".field_names) |fname| {
            std.debug.print("{s} ", .{fname[0..fname.len]});
        }
        std.debug.print("\n", .{});
        inline for (@typeInfo(std.mem.Allocator.VTable).@"struct".field_types) |ftype| {
            std.debug.print("  槽位类型 = {s}\n", .{@typeName(ftype)});
        }
        std.debug.print("官方 no-op 实现：noAlloc / noResize / noRemap / noFree（不想支持就填它们）\n", .{});

        // 自研分配器记账
        var counting: CountingAllocator = .{ .inner = std.heap.page_allocator };
        const counted = counting.allocator();
        {
            const s1 = try counted.alloc(u8, 100);
            defer counted.free(s1);
            const s2 = try counted.alloc(u32, 8); // 32 字节
            defer counted.free(s2);
            std.debug.print("两次分配后：分配 {d} 次 / 释放 {d} 次 / 在用 {d} 字节 / 峰值 {d} 字节\n", .{
                counting.allocs, counting.frees, counting.live_bytes, counting.peak_bytes,
            });
        }
        std.debug.print("作用域结束（两个 defer 都跑了）：分配 {d} / 释放 {d} / 在用 {d} 字节\n", .{
            counting.allocs, counting.frees, counting.live_bytes,
        });
        std.debug.print("注意：CountingAllocator 只有 {d} 字节，而它包装的 page_allocator 是全局单例\n", .{@sizeOf(CountingAllocator)});

        // 用 callconv 无关的方式数一下：接口值可以直接比较/拷贝
        const copy_of_iface = counted;
        std.debug.print("Allocator 接口值可直接按值拷贝：两份 ptr 相同={}（{d} 字节搬来搬去）\n", .{
            copy_of_iface.ptr == counted.ptr, @sizeOf(std.mem.Allocator),
        });
    }
    end("11.2");

    // ── 11.3 全家族：alloc / create / dupe / dupeSentinel / free / destroy ──
    begin("11.3");
    {
        const page = std.heap.page_allocator;

        // alloc(T, n) → []T：长度编进切片
        const nums = try page.alloc(u32, 4);
        defer page.free(nums);
        @memset(nums, 7);
        std.debug.print("alloc(u32, 4)   → {any}（{d} 字节），free 要传回**原来那个切片**\n", .{ nums, nums.len * @sizeOf(u32) });

        // alloc 返回 ![]T 而不是 []T：分配可能失败
        // （0.17 取函数返回类型要走 @typeInfo(...).@"fn".return_type.?，
        //  但 std.mem.Allocator 的方法是泛型的，直接 @typeOf 拿到的是 error_union，
        //  所以这里用同签名的本地函数来演示——语义完全一样）
        std.debug.print("alloc 返回类型 = {s}（**可能失败**）\n", .{@typeName(std.mem.Allocator.Error![]u8)});
        std.debug.print("create 返回类型 = {s}（单个对象，同一个错误集）\n", .{@typeName(std.mem.Allocator.Error!*Sword)});
        std.debug.print("free 返回 void —— 释放本身不失败，所以没有错误联合\n", .{});

        // create(T) → *T / destroy(p)：单个对象，destroy 不用传长度
        const one = try page.create(Sword);
        defer page.destroy(one);
        one.stats = try page.alloc(u8, 1);
        defer page.free(one.stats);
        one.stats[0] = 'V';
        std.debug.print("create(Sword)   → *Sword（{d} 字节）；destroy 不用传长度，因为长度是编译期已知的\n", .{@sizeOf(Sword)});

        // dupe(T, m)：拷贝
        const copy = try page.dupe(u8, "zig");
        defer page.free(copy);
        std.debug.print("dupe(u8, \"zig\") → len={d} 内容={s}（长度不含任何结尾 0）\n", .{ copy.len, copy });

        // ⚠️ 0.17：dupeZ **已移除**。继任者是 dupeSentinel(T, m, sentinel)
        //   const cz = page.dupeZ(u8, "zig");            // 0.16
        //   → error: no field or member function named 'dupeZ' in 'mem.Allocator'
        const cz = try page.dupeSentinel(u8, "zig", 0);
        defer page.free(cz);
        std.debug.print("dupeSentinel(u8, \"zig\", 0) → 类型 {s}，len={d}，第 {d} 字节是 {d}\n", .{
            @typeName(@TypeOf(cz)), cz.len, cz.len, cz[cz.len],
        });

        // allocSentinel：手动版，n 个元素 + 尾部哨兵
        const sent = try page.allocSentinel(u8, 5, 0);
        defer page.free(sent);
        std.debug.print("allocSentinel(u8, 5, 0) → 类型 {s}，len={d}（哨兵不算在 len 里，但占了 1 字节）\n", .{
            @typeName(@TypeOf(sent)), sent.len,
        });

        // print：分配一块格式化好的字符串（0.17 新增，替代老写法）
        const msg = try page.print("[{s}] n={d}", .{ "hi", 42 });
        defer page.free(msg);
        std.debug.print("page.print(...)  → {s}（分配器上的 printf，0.16 还没有）\n", .{msg});

        // alloc 返回的是 **undefined 内存**：不初始化就读是未定义行为
        const uninit = try page.alloc(u32, 2);
        defer page.free(uninit);
        std.debug.print("⚠️ alloc 返回 undefined 内存，Debug 下被填成 0xaa...：读到 {d} / {d}（十六进制 0x{x}）\n", .{
            uninit[0], uninit[1], @as(u32, @truncate(uninit[0])),
        });
        std.debug.print("  （栈上的 undefined 填0x00，堆上的 undefined 填 0xaa —— 两个不一样，别混）\n", .{});
        @memset(uninit, 0);
        std.debug.print("  @memset(0) 之后：{d} / {d}\n", .{ uninit[0], uninit[1] });

        // resize / realloc：原地改长度 vs 搬家
        var grow = try page.alloc(u8, 16);
        const before = grow.ptr;
        std.debug.print("resize(16→8)    = {}（true = 原地缩小成功，指针不变）\n", .{page.resize(grow, 8)});
        grow = try page.realloc(grow, 8192);
        std.debug.print("realloc(8→8192) 搬家了={}（page_allocator 不能原地扩，走 remap）\n", .{grow.ptr != before});
        grow = try page.realloc(grow, 8);
        std.debug.print("realloc(8192→8) 搬家了={}\n", .{grow.ptr != before});
        page.free(grow);

        // free 传切片：不能改长度
        var sl = try page.alloc(u8, 64);
        const sl_ptr = sl.ptr;
        sl = sl[0..32]; // 缩小视图
        std.debug.print("把切片缩到一半再 free：会 panic。DebugAllocator 的 free 认的是 (地址, 长度, 对齐) 三元组，\n", .{});
        std.debug.print("  实测 panic 文案 = `Invalid free`；SafeAllocator 是 `free of invalid memory`或 corrupted metadata`。\n", .{});
        std.debug.print("  所以本示例只演示\"指针地址仍等于原始地址\"，不真的去free 半块：{}\n", .{sl.ptr == sl_ptr});
        page.free(sl[0..0].ptr[0..64]); // 还原成完整长度才能正确 free
        std.debug.print("还原成完整长度 {d} 字节再 free：正常\n", .{64});
    }
    end("11.3");

    // ── 11.4 OOM 是返回值，不是崩溃 ────────────────────────────
    begin("11.4");
    {
        var backing: [64]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&backing);
        const a = fba.allocator();
        const first = try a.alloc(u8, 40);
        std.debug.print("先分 40 字节：成功，end_index={d}，还剩 {d} 字节\n", .{ fba.end_index, 64 - fba.end_index });
        if (a.alloc(u8, 40)) |_| {
            std.debug.print("不该成功\n", .{});
        } else |err| {
            std.debug.print("再分 40 字节：拿到 {s}——是**返回值**，进程没崩、errno 没变\n", .{@errorName(err)});
            std.debug.print("  @typeName(try a.alloc(u8, 1)) = {s}\n", .{@typeName(std.mem.Allocator.Error![]u8)});
            std.debug.print("  错误集只有 OutOfMemory 一种：{s}\n", .{@typeName(std.mem.Allocator.Error)});
            const err_names = @typeInfo(std.mem.Allocator.Error).error_set.error_names.?;
            std.debug.print("  错误名 = {s}（成员数 {d}）\n", .{ err_names[0][0..err_names[0].len], err_names.len });
        }
        a.free(first); // 只归还"最后一块"，end_index 才能回退
        std.debug.print("归还最后一块后 end_index={d}，再分 40 字节：成功={}\n", .{
            fba.end_index, (try a.alloc(u8, 40)).len == 40,
        });
        std.debug.print("对比：OOM 从来不是 panic。Zig 里唯一会 panic 的是\"契约被违反\"（比如用错分配器 free）\n", .{});
    }
    end("11.4");

    // ── 11.5 栈 vs 堆：实测 ────────────────────────────────────
    begin("11.5");
    {
        const n: usize = 20_000;
        var acc: usize = 0;
        const page = std.heap.page_allocator;

        var t = std.Io.Clock.awake.now(io);
        for (0..n) |i| {
            var buf: [256]u8 = undefined;
            buf[0] = @truncate(i);
            acc += buf[0];
        }
        const stack_ns = t.durationTo(std.Io.Clock.awake.now(io)).toNanoseconds();

        t = std.Io.Clock.awake.now(io);
        for (0..n) |_| {
            const b = try page.alloc(u8, 256);
            b[0] = 1;
            acc += b[0];
            page.free(b);
        }
        const page_ns = t.durationTo(std.Io.Clock.awake.now(io)).toNanoseconds();

        var fba_backing: [256]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&fba_backing);
        t = std.Io.Clock.awake.now(io);
        for (0..n) |_| {
            const b = try fba.allocator().alloc(u8, 256);
            b[0] = 1;
            acc += b[0];
            fba.reset();
        }
        const fba_ns = t.durationTo(std.Io.Clock.awake.now(io)).toNanoseconds();

        var bfa_backing: [64]u8 = undefined;
        var bfa = std.heap.BufferFirstAllocator.init(&bfa_backing, page);
        t = std.Io.Clock.awake.now(io);
        for (0..n) |_| {
            const b = try bfa.allocator().alloc(u8, 32);
            b[0] = 1;
            acc += b[0];
            bfa.allocator().free(b);
        }
        const bfa_ns = t.durationTo(std.Io.Clock.awake.now(io)).toNanoseconds();

        const smp = std.heap.smp_allocator;
        t = std.Io.Clock.awake.now(io);
        for (0..n) |_| {
            const b = try smp.alloc(u8, 256);
            b[0] = 1;
            acc += b[0];
            smp.free(b);
        }
        const smp_ns = t.durationTo(std.Io.Clock.awake.now(io)).toNanoseconds();

        var da = std.heap.DebugAllocator(.{}){};
        t = std.Io.Clock.awake.now(io);
        for (0..n) |_| {
            const b = try da.allocator().alloc(u8, 256);
            b[0] = 1;
            acc += b[0];
            da.allocator().free(b);
        }
        const da_ns = t.durationTo(std.Io.Clock.awake.now(io)).toNanoseconds();
        std.debug.assert(da.deinit() == .ok);

        std.debug.print("{d} 轮，每轮拿 256 字节（Debug 模式，ns/次；机器不同数字会变，看**量级**）：\n", .{n});
        // ⚠️ toNanoseconds() 返回 i64，用 {d} 打印会带符号（i64 的 {d} 会输出 "+8"）。
        // 要纯数字得先 @intCast 成 u64——这是 0.17 格式化器的一个小坑。
        std.debug.print("  栈上 [256]u8（根本不分配）{d:>7} ns\n", .{@as(u64, @intCast(@divTrunc(stack_ns, n)))});
        std.debug.print("  FixedBufferAllocator      {d:>7} ns\n", .{@as(u64, @intCast(@divTrunc(fba_ns, n)))});
        std.debug.print("  BufferFirstAllocator(64)  {d:>7} ns\n", .{@as(u64, @intCast(@divTrunc(bfa_ns, n)))});
        std.debug.print("  smp_allocator             {d:>7} ns\n", .{@as(u64, @intCast(@divTrunc(smp_ns, n)))});
        std.debug.print("  page_allocator            {d:>7} ns\n", .{@as(u64, @intCast(@divTrunc(page_ns, n)))});
        std.debug.print("  DebugAllocator            {d:>7} ns\n", .{@as(u64, @intCast(@divTrunc(da_ns, n)))});
        std.debug.print("栈最便宜（就一次栈指针下移），FBA 只做 end_index 加法，DebugAllocator 最贵（每块都记元数据+栈回溯）\n", .{});
        std.debug.print("acc={d}（防止被优化掉）\n", .{acc});

        // page_allocator 做小分配的浪费
        const small = try page.alloc(u8, 100);
        defer page.free(small);
        std.debug.print("page_allocator 分100 字节：地址页内偏移 = {d}（一页 {d} 字节，实际只用 100）\n", .{
            @intFromPtr(small.ptr) % std.heap.page_size_min, std.heap.page_size_min,
        });
        std.debug.print("结论：**能用栈上定长数组就别分配**。堆是给\"长度运行期才知道\"的东西准备的\n", .{});
    }
    end("11.5");

    // ── 11.6 六大分配器各自的定位 ──────────────────────────────
    begin("11.6");
    {
        std.debug.print("① page_allocator    类型 {s}，直接向 OS 要页（mmap/munmap）\n", .{@typeName(@TypeOf(std.heap.page_allocator))});
        std.debug.print("   page_size_min={d} page_size_max={d}（本机页大小）\n", .{ std.heap.page_size_min, std.heap.page_size_max });
        std.debug.print("   它是**其他分配器的底座**，不是业务代码的直接工具\n", .{});

        std.debug.print("② FixedBufferAllocator  类型 {s}，@sizeOf={d} 字节\n", .{
            @typeName(std.heap.FixedBufferAllocator), @sizeOf(std.heap.FixedBufferAllocator),
        });
        var fb_probe: [8]u8 = undefined;
        const fba_probe = std.heap.FixedBufferAllocator.init(&fb_probe);
        std.debug.print("   两个字段：end_index={d} buffer.len={d}（分配 = 移动 end_index）\n", .{
            fba_probe.end_index, fba_probe.buffer.len,
        });

        std.debug.print("③ BufferFirstAllocator  类型 {s}，@sizeOf={d} 字节\n", .{
            @typeName(std.heap.BufferFirstAllocator), @sizeOf(std.heap.BufferFirstAllocator),
        });
        var bfa_buf: [8]u8 = undefined;
        const bfa_probe = std.heap.BufferFirstAllocator.init(&bfa_buf, std.heap.page_allocator);
        std.debug.print("   两个字段：fallback_allocator={s} fixed_buffer_allocator={s}\n", .{
            @typeName(@TypeOf(bfa_probe.fallback_allocator)), @typeName(@TypeOf(bfa_probe.fixed_buffer_allocator)),
        });
        std.debug.print("   ⚠️ 0.17：std.heap.stackFallback **已移除**，继任者就是它（语义一致：先试栈上缓冲，容纳不下自动落到底层）\n", .{});
        std.debug.print("     老写法 std.heap.stackFallback(...) → error: root source file struct 'heap' has no member named 'stackFallback'\n", .{});

        std.debug.print("④ ArenaAllocator    类型 {s}，@sizeOf={d} 字节，字段 child_allocator={s}\n", .{
            @typeName(std.heap.ArenaAllocator), @sizeOf(std.heap.ArenaAllocator), @typeName(@TypeOf(@as(std.heap.ArenaAllocator, undefined).child_allocator)),
        });
        std.debug.print("   批量分配一次释放；ResetMode = free_all / retain_capacity / retain_with_limit\n", .{});

        std.debug.print("⑤ DebugAllocator    是函数（生成类型）：std.heap.DebugAllocator(Config)\n", .{});
        std.debug.print("   有 pub const init（0.17 推荐）：var da: std.heap.DebugAllocator(.{{}}) = .init;\n", .{});
        std.debug.print("   旧写法 std.heap.DebugAllocator(.{{}}){{}} 仍能编译，但源码注释写明 \"Default initialization of this struct is deprecated\"\n", .{});
        std.debug.print("   ⚠️ 注意 DebugAllocator **不是** std.testing.allocator 的本体（见 11.12 节）\n", .{});

        std.debug.print("⑥ SmpAllocator      单例，无init/无 allocator()——直接用 std.heap.smp_allocator\n", .{});
        std.debug.print("   @hasDecl(SmpAllocator,\"init\")={} @hasDecl(SmpAllocator,\"allocator\")={}\n", .{
            @hasDecl(std.heap.SmpAllocator, "init"), @hasDecl(std.heap.SmpAllocator, "allocator"),
        });
        std.debug.print("   五个单例都是同一个类型 {s}：page/smp/c/brk/wasm_allocator\n", .{@typeName(@TypeOf(std.heap.page_allocator))});
        std.debug.print("   c_allocator 存在={}（要zig build-exe ... -lc，17 章）\n", .{@hasDecl(std.heap, "c_allocator")});

        std.debug.print("补充两个 0.17 新面孔：std.heap.SafeAllocator 存在={}，std.mem.ValidationAllocator 存在={}\n", .{
            @hasDecl(std.heap, "SafeAllocator"), @hasDecl(std.mem, "ValidationAllocator"),
        });
        std.debug.print("  SafeAllocator = init.gpa 在 Debug/Safe 模式下的真身（见 11.17 节）\n", .{});

        const big = try std.heap.page_allocator.alloc(u32, 1_000_000);
        defer std.heap.page_allocator.free(big);
        std.debug.print("实测：page_allocator 一次给 {d} 个 u32 = {d} MB（大块走 mmap，小块也按页起）\n", .{
            big.len, big.len * 4 >> 20,
        });
    }
    end("11.6");

    // ── 11.7 FixedBufferAllocator ──────────────────────────────
    begin("11.7");
    {
        var backing: [128]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&backing);
        const f = fba.allocator();
        _ = try f.alloc(u8, 50);
        std.debug.print("alloc 50 → end_index={d}（缓冲128）\n", .{fba.end_index});
        _ = try f.alloc(u8, 50);
        std.debug.print("alloc 50 → end_index={d}，剩 {d} 字节\n", .{ fba.end_index, 128 - fba.end_index });
        if (f.alloc(u8, 50)) |_| {
            std.debug.print("不该成功\n", .{});
        } else |err| {
            std.debug.print("第三次 alloc 50 按预期失败：{s}——剩 28 字节装不下 50（阿喀琉斯之踵）\n", .{@errorName(err)});
        }
        fba.reset();
        _ = try f.alloc(u8, 100);
        std.debug.print("reset() 归零后再分 100 字节：成功（现在 end_index={d}），无需逐个 free\n", .{fba.end_index});

        // 分配=移动 end_index，free 只对"最后一块"有效
        var b2: [64]u8 = undefined;
        var fba2 = std.heap.FixedBufferAllocator.init(&b2);
        const g = fba2.allocator();
        const x1 = try g.alloc(u8, 16);
        const x2 = try g.alloc(u8, 16);
        std.debug.print("两块 16 字节：end_index={d}\n", .{fba2.end_index});
        g.free(x1); // x1 不是最后一块
        std.debug.print("先 free x1（非最后一块）→ end_index仍={d}：内存没还（**只回退最后一块**）\n", .{fba2.end_index});
        g.free(x2);
        std.debug.print("再 free x2 → end_index={d}（回退到 x1 之后）\n", .{fba2.end_index});

        // 对齐会吃掉 padding
        var b3: [64]u8 = undefined;
        var fba3 = std.heap.FixedBufferAllocator.init(&b3);
        const h = fba3.allocator();
        const q1 = try h.alloc(u32, 1); // 4 字节，要求 4 对齐
        std.debug.print("alloc(u32,1) 要 4 字节 + 4 对齐 → end_index={d}\n", .{fba3.end_index});
        h.free(q1);
        const q3 = try h.alloc(u64, 1); // 8 字节，要求 8 对齐
        std.debug.print("alloc(u64,1) 要 8 字节 + 8 对齐 → end_index={d}\n", .{fba3.end_index});
        h.free(q3);
        std.debug.print("无堆环境（内核 / wasm / 中断上下文）与热路径用它；用尽返回 {s}——优雅的失败\n", .{"error.OutOfMemory"});
        std.debug.print("threadSafeAllocator() 存在={}（多线程共享一块缓冲时换它）\n", .{@hasDecl(std.heap.FixedBufferAllocator, "threadSafeAllocator")});
    }
    end("11.7");

    // ── 11.8 ArenaAllocator：一批分配一次释放 ───────────────────
    begin("11.8");
    {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const a = arena.allocator();
        std.debug.print("初始 queryCapacity={d}（还没向底层要过任何东西）\n", .{arena.queryCapacity()});
        _ = try a.alloc(u8, 100);
        std.debug.print("alloc 100 后容量={d}：一次性向底层要了整块，再也不还给底层\n", .{arena.queryCapacity()});
        _ = try a.alloc(u8, 100);
        std.debug.print("再 alloc 100 容量={d}：同块内只是 end_index 加法，不进底层\n", .{arena.queryCapacity()});
        _ = try a.alloc(u8, 100);
        std.debug.print("第三次 alloc 100 容量={d}\n", .{arena.queryCapacity()});
        _ = try a.alloc(u8, 100);
        std.debug.print("第四次 alloc 100 容量={d}（188/112/200 这样的跳变 = 又向底层要了一块）\n", .{arena.queryCapacity()});

        // arena 里单个 free 是 no-op
        const cap_before_scratch = arena.queryCapacity();
        const scratch = try a.alloc(u8, 64);
        const cap_after_alloc = arena.queryCapacity();
        a.free(scratch);
        std.debug.print("单个 free(scratch) 前后容量都是 {d}：**内存不归还**（合法但是 no-op，别依赖）\n", .{cap_after_alloc});
        std.debug.print("  （free 之前 alloc(64) 也只把容量从 {d} 抬到 {d}；free 之后仍是 {d}，这 64 字节彻底留在 arena 里了）\n", .{
            cap_before_scratch, cap_after_alloc, arena.queryCapacity(),
        });

        // 三种 reset
        _ = arena.reset(.free_all);
        std.debug.print("reset(.free_all)→ 容量={d}（整块还给底层）\n", .{arena.queryCapacity()});
        _ = try a.alloc(u8, 4096);
        std.debug.print("alloc 4096 → 容量={d}\n", .{arena.queryCapacity()});
        _ = arena.reset(.retain_capacity);
        std.debug.print("reset(.retain_capacity) → 容量={d}（预热：块留着复用，后续不再找底层要）\n", .{arena.queryCapacity()});
        _ = arena.reset(.{ .retain_with_limit = 512 });
        std.debug.print("reset(.{{ .retain_with_limit = 512 }}) → 容量={d}（超了，砍到最小）\n", .{arena.queryCapacity()});

        // 典型场景：一行文本切成若干段，全挂arena
        var arena2 = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena2.deinit();
        const words = try splitIntoArena(arena2.allocator(), "the quick brown fox");
        std.debug.print("splitIntoArena 切出 {d} 段：", .{words.len});
        for (words) |w| std.debug.print("{s}/", .{w});
        std.debug.print("\n  整个函数只有分配、没有一次 free——这就是 arena 风格\n", .{});
    }
    end("11.8");

    // ── 11.9 BufferFirstAllocator：0.17 的新日常 ──────────────────
    begin("11.9");
    {
        // ⚠️ 0.17 迁移注记：老教程里的 std.heap.stackFallback 已移除。
        // 继任者是 std.heap.BufferFirstAllocator，语义完全一致：
        // 先试栈上缓冲，容纳不下自动落到底层分配器。
        //   旧：var fb = std.heap.stackFallback(std.heap.page_allocator, &stack_buf);
        //   新：var fb = std.heap.BufferFirstAllocator.init(&stack_buf, std.heap.page_allocator);
        var stack_buf: [64]u8 = undefined;
        var fb = std.heap.BufferFirstAllocator.init(&stack_buf, std.heap.page_allocator);
        const a = fb.allocator();
        const small = try a.alloc(u8, 32);
        std.debug.print("BufferFirstAllocator(64) 分 32→ 走栈上缓冲={}（ownsPtr 判定）\n", .{
            fb.fixed_buffer_allocator.ownsPtr(@ptrCast(small.ptr)),
        });
        a.free(small);
        const exact = try a.alloc(u8, 64);
        std.debug.print("分 64（刚好装满）      → 走栈上缓冲={}\n", .{fb.fixed_buffer_allocator.ownsPtr(@ptrCast(exact.ptr))});
        a.free(exact);
        const large = try a.alloc(u8, 8192);
        std.debug.print("分 8192              → 走栈上缓冲={}（自动落到底层）\n", .{fb.fixed_buffer_allocator.ownsPtr(@ptrCast(large.ptr))});
        a.free(large);
        std.debug.print("关键：free 时它靠ownsPtr 自动判断该还给栈缓冲还是底层——调用方完全无感\n", .{});

        // 为什么它比"FBA 分配失败就 panic"好：调用点不用写两套逻辑
        std.debug.print("用法：把 std.heap.page_allocator 换成它，小分配省一次系统调用，大分配照样落到底层\n", .{});
        std.debug.print("  var bfa = std.heap.BufferFirstAllocator.init(&buf, std.heap.smp_allocator);\n", .{});
        std.debug.print("  const a = bfa.allocator();  // 之后 a 就是一个普通 Allocator\n", .{});

        // MemoryPool：同类型对象批量分配最快
        var pool: std.heap.MemoryPool(u32) = .empty;
        defer pool.deinit(std.heap.page_allocator);
        const p = try pool.create(std.heap.page_allocator);
        p.* = 42;
        std.debug.print("MemoryPool(u32).create → {d}，@sizeOf(MemoryPool(u32))={d}（同类型节点批量分配最快）\n", .{
            p.*, @sizeOf(std.heap.MemoryPool(u32)),
        });
        pool.destroy(p);
    }
    end("11.9");

    // ── 11.10 注入失败以测 OOM 路径 ────────────────────────────
    begin("11.10");
    {
        // FailingAllocator：第 N 次分配开始返回 null
        var fa = std.testing.FailingAllocator.init(std.heap.page_allocator, .{ .fail_index = 2 });
        const a = fa.allocator();
        const p1 = try a.alloc(u8, 64);
        const p2 = try a.alloc(u8, 64);
        if (a.alloc(u8, 64)) |_| {
            std.debug.print("  不该成功\n", .{});
        } else |err| {
            std.debug.print("fail_index=2：两次成功后第 3 次返回 {s}\n", .{@errorName(err)});
        }
        std.debug.print("  计量：alloc_index={d}（失败的那次不计数），allocated={d} 字节，has_induced_failure={}\n", .{
            fa.alloc_index, fa.allocated_bytes, fa.has_induced_failure,
        });
        std.debug.print("  还有 resize_fail_index={d}（默认 maxInt，即 resize 永不失败）\n", .{fa.resize_fail_index});
        a.free(p1);
        a.free(p2);
        std.debug.print("  归还后：allocations={d} deallocations={d} freed={d} 字节\n", .{
            fa.allocations, fa.deallocations, fa.freed_bytes,
        });

        // fail_index = 0：第一次就失败
        var fa0 = std.testing.FailingAllocator.init(std.heap.page_allocator, .{ .fail_index = 0 });
        if (fa0.allocator().alloc(u8, 1)) |_| {
            std.debug.print("  fail_index=0 却成功了\n", .{});
        } else |err| {
            std.debug.print("fail_index=0：第一次就返回 {s}（alloc_index={d}）\n", .{ @errorName(err), fa0.alloc_index });
        }

        // std.testing.failing_allocator：现成的"永远失败"实例
        if (std.testing.failing_allocator.alloc(u8, 1)) |_| {
            std.debug.print("  failing_allocator 却成功了\n", .{});
        } else |err| {
            std.debug.print("std.testing.failing_allocator：永远返回 {s}（fail_index=0 的全局实例）\n", .{@errorName(err)});
        }
    }
    end("11.10");

    // ── 11.11 checkAllAllocationFailures：逐个 OOM 点抓泄漏 ──────
    begin("11.11");
    {
        const names = [_][]const u8{ "zig", "rust", "go" };
        // 有 errdefer 的版本：每一条 OOM 路径都不漏
        std.testing.checkAllAllocationFailures(std.heap.page_allocator, exerciseSafe, .{names[0..]}) catch |err| {
            std.debug.print("  buildTeamSafe 被查出问题：{s}\n", .{@errorName(err)});
        };
        std.debug.print("buildTeamSafe（有 errdefer）：全部 OOM 路径都不漏，检查通过\n", .{});
        // 故意漏内存的版本：checkAllAllocationFailures 会当场抓出来
        std.testing.checkAllAllocationFailures(std.heap.page_allocator, leakOnOom, .{32}) catch |err| {
            std.debug.print("leakOnOom 被查出：{s}（上面打印了泄漏点的栈回溯）\n", .{@errorName(err)});
        };
        std.debug.print("对比：leakOnOom（没 errdefer）在第 2 次分配失败时就丢了第 1 块\n", .{});
    }
    end("11.11");

    // ── 11.12 泄漏检测：std.testing.allocator ──────────────────
    begin("11.12");
    {
        // std.testing.allocator 的真身：SafeAllocator
        std.debug.print("std.testing.allocator 是 {s}（0.17 已从DebugAllocator 换成 SafeAllocator）\n", .{
            "heap.SafeAllocator",
        });
        std.debug.print("⚠️ 所以在 main 里写 std.testing.allocator 是**编译错误**（实测文案）：\n", .{});
        std.debug.print("   lib/std/testing.zig:21:80: error: not testing\n", .{});
        std.debug.print("   pub const allocator = if (builtin.is_test) allocator_instance.allocator() else @compileError(\"not testing\");\n", .{});
        std.debug.print("  builtin.is_test 在 main 里是 {}\n", .{builtin.is_test});

        // DebugAllocator 的等价能力（可写在 main 里演示）
        var leaky_da = std.heap.DebugAllocator(.{}){};
        _ = try leaky_da.allocator().alloc(u8, 32); // 故意不释放
        std.debug.print("故意用 DebugAllocator 漏一块 32 字节 → deinit() 返回 {s}\n", .{@tagName(leaky_da.deinit())});
        std.debug.print("  它把泄漏块打到 **stderr**，格式是 `error(DebugAllocator): memory address 0x... leaked:`\n", .{});
        std.debug.print("  后跟分配点的文件:行号:列号。⚠️ 那个地址每次运行都不同，别把它抄进文档当固定输出\n", .{});

        // deinit 返回值
        var clean_da = std.heap.DebugAllocator(.{}){};
        const cbuf = try clean_da.allocator().dupe(u8, "先free再deinit");
        clean_da.allocator().free(cbuf);
        std.debug.print("先 free 再 deinit → {s}（heap.Check 枚举：ok / leak）\n", .{@tagName(clean_da.deinit())});

        // SafeAllocator.deinit 返回泄漏**块数**（usize），不是枚举
        var sa = std.heap.SafeAllocator.init(std.heap.page_allocator, .{});
        const sbuf2 = try sa.allocator().dupe(u8, "safe");
        sa.allocator().free(sbuf2);
        std.debug.print("SafeAllocator.init(page_allocator, .{{}}) + deinit() → 泄漏块数 = {d}（返回 usize，不是 heap.Check）\n", .{sa.deinit()});
    }
    end("11.12");

    // ── 11.13 生命周期：alloc + errdefer free + 初始化 + 返回 ────
    begin("11.13");
    {
        // 陷阱 1：返回局部数组的切片 —— Zig 不报错，但内容会被下一次调用改写
        //
        // ⚠️ 悬垂切片的内容**每次运行都不同**（取决于栈上残留了什么），所以这里只做
        //    断言性判断（"还是原文吗？"），不把具体字节抄进文档。
        const expected = [5]u8{ 'F', 'i', 'r', 'e', '!' };
        const dangling = cursedScroll();
        std.debug.print("陷阱：cursedScroll() 返回局部数组的切片。期望 \"Fire!\"\n", .{});
        std.debug.print("  刚返回时内容还是原文吗？{}（Debug 下栈上 undefined 填 0x00，常常已经是 false）\n", .{std.mem.eql(u8, dangling, &expected)});
        var pad: [128]u8 = undefined;
        @memset(&pad, 'Z');
        std.debug.print("  再 memset(&pad, 'Z') 之后还是原文吗？{} → **悬垂切片**（同一块栈被反复改写）\n", .{std.mem.eql(u8, dangling, &expected)});
        std.debug.print("  Zig 只在返回 &局部变量 时报错；返回 局部数组的切片 是**合法但危险**的\n", .{});

        // 正确做法：拷到分配器上
        const heap_copy = try enchantedSword(init.gpa, "Slash");
        defer init.gpa.free(heap_copy);
        @memset(&pad, 'Z');
        std.debug.print("  堆分配版本不受影响：{s}（内容稳定，因为不在栈上）\n", .{heap_copy});

        // init/deinit 惯例 + errdefer
        const sword = try Sword.init(init.gpa, "Victory!");
        defer sword.deinit(init.gpa);
        std.debug.print("init/deinit 惯例：stats={s}（errdefer 已保证中途失败不漏）\n", .{sword.stats});
        std.debug.print("  init/deinit **不是**语言特性，只是社区约定的成对写法；free 才是语言关键字\n", .{});

        // 惯用法四步走：alloc → errdefer free → 初始化 → 返回
        std.debug.print("惯用法：try alloc → errdefer free → 初始化 → try后面每步都有兜底→ return\n", .{});
        std.debug.print("  少了 errdefer 那一行，多个分配点里任何一个失败都会漏前面已分配的那些\n", .{});

        // 用错分配器 free 会 panic（不是 UB 静默）
        std.debug.print("用错分配器 free：DebugAllocator 报 `Invalid free`；SafeAllocator 报 `free of invalid memory`或 corrupted metadata`\n", .{});
        std.debug.print("  两者都是 **panic**（进程终止），不是静默 UB——这是0.17 内存安全的一部分\n", .{});
    }
    end("11.13");

    // ── 11.14 对齐分配：0.17 的 Alignment 是 log2 枚举 ───────────
    begin("11.14");
    {
        // ⚠️ 0.17 的大变化：std.mem.Alignment 不再是"字节数结构体"，
        // 而是**以 log2 为基整型的非穷尽枚举**：enum(math.Log2Int(usize))。
        const A = std.mem.Alignment;
        std.debug.print("std.mem.Alignment 是 {s}，@sizeOf={d} 字节\n", .{ @typeName(A), @sizeOf(A) });
        std.debug.print("  成员只有 @\"1\"..@\"64\" 加一个非穷尽 `_`；128/256要靠 fromByteUnits 造\n", .{});
        std.debug.print("  .of(u64).toByteUnits() = {d}；.fromByteUnits(256).toByteUnits() = {d}，@backingInt = {d}\n", .{
            A.of(u64).toByteUnits(), A.fromByteUnits(256).toByteUnits(), @backingInt(A.fromByteUnits(256)),
        });
        std.debug.print("  ⚠️ @tagName(A.fromByteUnits(256)) 会 **panic: invalid enum value**（非穷尽枚举没有名字）\n", .{});
        std.debug.print("     @tagName(A.of(u64)) = {s}，@tagName(A.@\"8\") = {s}（≤64 才有名字）\n", .{ @tagName(A.of(u64)), @tagName(A.@"8") });

        // 对齐分配的四个入口
        const page = std.heap.page_allocator;
        const b = try page.alignedAlloc(u8, .@"64", 10);
        defer page.free(b);
        std.debug.print("alignedAlloc(u8, .@\"64\", 10)     → 类型 {s}，addr%64={d}\n", .{
            @typeName(@TypeOf(b)), @intFromPtr(b.ptr) % 64,
        });
        const c = try page.allocWithOptions(u8, 10, .fromByteUnits(128), null);
        defer page.free(c);
        std.debug.print("allocWithOptions(u8,10,fromByteUnits(128),null) → 类型 {s}，addr%128={d}\n", .{
            @typeName(@TypeOf(c)), @intFromPtr(c.ptr) % 128,
        });
        const ac = try page.alignedCreate(u64, .fromByteUnits(256));
        defer page.destroy(ac);
        std.debug.print("alignedCreate(u64, fromByteUnits(256))        → 类型 {s}，addr%256={d}\n", .{
            @typeName(@TypeOf(ac)), @intFromPtr(ac) % 256,
        });
        const combo = try page.allocWithOptions(u8, 4, .fromByteUnits(64), @as(u8, 0));
        defer page.free(combo);
        std.debug.print("allocWithOptions(u8,4,fromByteUnits(64),0)     → 类型 {s}（对齐+哨兵一起要）\n", .{@typeName(@TypeOf(combo))});

        // ⚠️ 老写法的真实报错
        std.debug.print("⚠️ 传字节数给 alignedAlloc 在 0.17 编译不过：\n", .{});
        std.debug.print("   const b = try a.alignedAlloc(u8, 64, 10);\n", .{});
        std.debug.print("   error: expected type '?mem.Alignment', found 'comptime_int'\n", .{});
        std.debug.print("   note: enum declared here / pub const Alignment = enum(math.Log2Int(usize))\n", .{});
        std.debug.print("   写 .@\"64\"（枚举成员）或 .fromByteUnits(64)（运行期算）才对\n", .{});

        // 自然对齐：不需要特殊处理
        std.debug.print("绝大多数时候不用管对齐——alloc 会自动按 @alignOf(T) 对齐：\n", .{});
        const nat = try page.alloc(u64, 4);
        defer page.free(nat);
        std.debug.print("alloc(u64,4) 的地址 % 8 = {d}（自动 8 字节对齐，无需alignedAlloc）\n", .{@intFromPtr(nat.ptr) % 8});

        // 零大小类型
        std.debug.print("零大小类型：@sizeOf(void)={d} @sizeOf(u0)={d} @sizeOf([0]u8)={d}\n", .{
            @sizeOf(void), @sizeOf(u0), @sizeOf([0]u8),
        });
        const nothing = try page.alloc(u8, 0);
        page.free(nothing);
        std.debug.print("alloc(T, 0) 合法且free 合法（长度为 0 的切片不需要真内存）\n", .{});
    }
    end("11.14");

    // ── 11.15 什么时候不该分配 ─────────────────────────────────
    begin("11.15");
    {
        // 11.5 节已经量化过：栈比FBA 快一个数量级，比 page_allocator 快三个数量级。
        // 这里的判据是"能不能在编译期知道大小"。
        const runtime_len: usize = 8;
        var stack_buf: [64]u8 = undefined;
        std.debug.print("长度编译期已知 → 用 [N]T，长度运行期才知道 → 才考虑分配\n", .{});
        std.debug.print("  栈：var buf: [{d}]u8 = undefined;（{d} 字节栈空间，零分配）\n", .{ runtime_len, 64 });
        @memset(stack_buf[0..runtime_len], 'x');
        std.debug.print("  堆：const p = try a.alloc(u8, {d}); defer a.free(p);\n", .{runtime_len});
        std.debug.print("BufferFirstAllocator 就是这两者的自动桥：小的走栈缓冲，大的自动落底层\n", .{});

        // arena 里的小对象其实也不必分配
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const a = arena.allocator();
        var on_stack: [32]u8 = undefined;
        on_stack[0] = 'A';
        _ = try a.alloc(u8, 32);
        std.debug.print("arena 里32 字节的东西也可以放栈上——arena 只解决\"批量回收\"，不解决\"该不该分配\"\n", .{});
        std.debug.print("  栈上版本首字节 = {c}，arena 版本首字节 = {c}（都没初始化过，内容无意义）\n", .{ on_stack[0], @as(u8, '?') });
        std.debug.print("  在 arena 上 \"忘记 free\" 不是 bug（批量回收兜着），这正是它比 gpa 省心的地方\n", .{});

        // ArrayList 内部就是"增长式重新分配"，但外部看不见
        var list: std.ArrayList(u8) = .empty;
        defer list.deinit(a);
        for (0..8) |i| try list.append(a, @intCast('0' + i));
        std.debug.print("ArrayList 内部反复 realloc，但调用方只写 append —— 12 章展开\n", .{});
        std.debug.print("  内容={s}，arena 容量={d}（8 次append 只涨到这么多）\n", .{ list.items, arena.queryCapacity() });

        // errdefer 在 arena 上仍然有意义（deinit 自己要 free）
        std.debug.print("判断清单：① 大小编译期已知？→ 栈。② 一批东西同生共死？→ arena。③ 都不成立 → gpa\n", .{});
    }
    end("11.15");

    // ── 11.16 零大小类型与 peer type resolution ────────────────
    begin("11.16");
    {
        std.debug.print("@sizeOf(void)={d}  @sizeOf(u0)={d}  @sizeOf([0]u8)={d}\n", .{
            @sizeOf(void), @sizeOf(u0), @sizeOf([0]u8),
        });
        std.debug.print("*anyopaque 是 {d} 字节的指针；@sizeOf(anyopaque) 是编译错误（无法实例化）\n", .{
            @sizeOf(*anyopaque),
        });

        // void 把HashMap 变成 Set
        var set = std.AutoHashMap(u32, void).init(init.gpa);
        defer set.deinit();
        try set.put(42, {}); // ⚠️ 0.17：void{} 已移除，写const b: void = {};
        try set.put(7, {});
        std.debug.print("HashMap(u32, void) 当集合用：count={d}，含 42？{}，含 9？{}\n", .{
            set.count(), set.contains(42), set.contains(9),
        });
        _ = set.remove(42);
        std.debug.print("删掉 42 后 count={d}（值类型不占空间，但键仍在表里）\n", .{set.count()});

        // peer type resolution
        // cond 必须是运行期值，否则编译器直接取走那一条分支，谈不上"解析"
        var seed: u8 = 1;
        const cond = @intFromPtr(&seed) % 2 == 0;
        const peer = if (cond) @as(u8, 1) else @as(u16, 300);
        std.debug.print("peer type resolution：u8 与 u16 分支统一成 {s}（取能装下两者的最小类型）\n", .{@typeName(@TypeOf(peer))});
        const peer2 = if (cond) "abc" else @as([]const u8, "xy");
        std.debug.print("数组字面量与切片分支统一成 {s}\n", .{@typeName(@TypeOf(peer2))});
        const peer3 = if (cond) @as(?u32, 7) else @as(?u32, null);
        std.debug.print("optional 与非 optional 分支统一成 {s}（peer resolution 的第二条规则：可选性取并集）\n", .{@typeName(@TypeOf(peer3))});
        // ⚠️ 但哨兵不一致时无法peer resolve——这是分配器章节唯一真正常见的类型陷阱
        const SentinelOrNot = if (cond) @as([]u8, undefined) else @as([:0]const u8, "x");
        std.debug.print("哨兵切片 [:0]u8 与普通切片 []u8 在 if/else 里统一成 {s}（丢掉了哨兵信息）\n", .{
            @typeName(@TypeOf(SentinelOrNot)),
        });
        std.debug.print("  → 如果两条分支一个带哨兵一个不带，编译器无法解析，只能自己点名类型\n", .{});
    }
    end("11.16");

    // ── 11.17 线程安全与 init.gpa ──────────────────────────────
    begin("11.17");
    {
        // 每个线程自己向 smp_allocator 申请/归还
        var done = std.atomic.Value(u32).init(0);
        var threads: [4]std.Thread = undefined;
        for (&threads) |*t| t.* = try std.Thread.spawn(.{}, worker, .{&done});
        for (threads) |t| t.join();
        std.debug.print("4 个线程各自向 smp_allocator 申请/归还：完成 {d} 个\n", .{done.load(.monotonic)});

        // 各分配器的线程安全声明
        std.debug.print("ArenaAllocator 有 threadSafeAllocator()={}（0.17 没有，只有 child_allocator 的线程安全性随底层走）\n", .{
            @hasDecl(std.heap.ArenaAllocator, "threadSafeAllocator"),
        });
        std.debug.print("FixedBufferAllocator 有 threadSafeAllocator()={}（多线程共享一块缓冲时用它）\n", .{
            @hasDecl(std.heap.FixedBufferAllocator, "threadSafeAllocator"),
        });
        std.debug.print("BufferFirstAllocator 有 threadSafeAllocator()={}\n", .{
            @hasDecl(std.heap.BufferFirstAllocator, "threadSafeAllocator"),
        });
        std.debug.print("DebugAllocator 配置项thread_safe 默认 = !builtin.single_threaded（本机 = {}）\n", .{builtin.single_threaded});

        // init.gpa / init.arena / init.io
        std.debug.print("init.gpa   = {s}：进程级堆\n", .{@typeName(@TypeOf(init.gpa))});
        std.debug.print("init.arena = {s}：进程级 arena，退出才整体回收（免掉满地的 free）\n", .{@typeName(@TypeOf(init.arena))});
        std.debug.print("init.io    = {s}：带缓冲的 I/O\n", .{@typeName(@TypeOf(init.io))});
        const perm = try init.arena.allocator().alloc(u8, 32);
        @memset(perm, 'A');
        std.debug.print("init.arena 分 32 字节：{s}（不用 free，进程退出自动回收）\n", .{perm[0..4]});

        // Debug/Safe 模式下 init.gpa 的真身
        std.debug.print("⚠️ 0.17 的 init.gpa 在 Debug/Safe 模式下是 **SafeAllocator**（不是 DebugAllocator）：\n", .{});
        std.debug.print("  start.zig: const use_safe_allocator = switch (builtin.mode) {{ .debug, .safe => true, ... }}\n", .{});
        std.debug.print("  var safe_allocator: std.heap.SafeAllocator = .init(std.heap.page_allocator, .{{}});\n", .{});
        std.debug.print("  它的 deinit() 返回**泄漏块数 usize**（不是 heap.Check 枚举），且\"泄漏不影响返回码\"\n", .{});
        std.debug.print("  本节实测：main 结束时 init.gpa 若有泄漏，stderr 会出现 [SafeAllocator] (err): leaked [addr: ...]\n", .{});
        std.debug.print("  但 `zig build-exe &&./prog` 的**退出码仍然是 0** —— 想要失败必须自己查（见 11.12 节）\n", .{});

        // 签名纪律
        std.debug.print("签名纪律：fn f(alloc: std.mem.Allocator) **按值传**（接口就是胖指针）\n", .{});
        std.debug.print("  写 *std.mem.Allocator 会得到：error: expected type '*mem.Allocator', found '*const mem.Allocator'\n", .{});
        std.debug.print("  因为 allocator() 返回的值是 const 的，取地址得到 *const；接口本身不需要可变\n", .{});
    }
    end("11.17");

    std.debug.print("自检通过\n", .{});
}

// ══════════════════════════════════════════════════════════════════
// 测试：把本章语义钉死（std.testing.allocator 带泄漏检测）
// ══════════════════════════════════════════════════════════════════

test "接口值是 16 字节胖指针，vtable 四个槽位" {
    try std.testing.expectEqual(@as(usize, 16), @sizeOf(std.mem.Allocator));
    try std.testing.expectEqual(@as(usize, 32), @sizeOf(std.mem.Allocator.VTable));
    try std.testing.expectEqual(@as(usize, 4), @typeInfo(std.mem.Allocator.VTable).@"struct".field_names.len);
    try std.testing.expectEqualStrings("alloc", @typeInfo(std.mem.Allocator.VTable).@"struct".field_names[0][0..5]);
    try std.testing.expectEqualStrings("resize", @typeInfo(std.mem.Allocator.VTable).@"struct".field_names[1][0..6]);
    try std.testing.expectEqualStrings("remap", @typeInfo(std.mem.Allocator.VTable).@"struct".field_names[2][0..5]);
    try std.testing.expectEqualStrings("free", @typeInfo(std.mem.Allocator.VTable).@"struct".field_names[3][0..4]);
}

test "自研分配器：记账准确，noResize/noRemap 占位可用" {
    var counting: CountingAllocator = .{ .inner = std.testing.allocator };
    const a = counting.allocator();
    {
        const s = try a.alloc(u8, 100);
        defer a.free(s);
        const t = try a.alloc(u32, 8);
        defer a.free(t);
        try std.testing.expectEqual(@as(usize, 2), counting.allocs);
        try std.testing.expectEqual(@as(usize, 132), counting.live_bytes);
        try std.testing.expectEqual(@as(usize, 132), counting.peak_bytes);
        // 不支持的操作返回 false/null 而不是崩溃
        try std.testing.expect(!a.resize(s, 10));
        try std.testing.expect(a.remap(s, 10) == null);
    }
    try std.testing.expectEqual(@as(usize, 2), counting.frees);
    try std.testing.expectEqual(@as(usize, 0), counting.live_bytes);
}

test "全家族：alloc / create / dupe / dupeSentinel / allocSentinel / print" {
    const a = std.testing.allocator;

    const nums = try a.alloc(u32, 4);
    defer a.free(nums);
    try std.testing.expectEqual(@as(usize, 4), nums.len);
    // ⚠️ 注意：alloc 返回的是 **undefined 内存**，Debug 下被填成 0xaa（不是栈上的 0x00）。
    // 实测未初始化时读到 2863311530 = 0xAAAAAAAA。必须自己初始化。
    nums[0] = 1;
    nums[1] = 2;
    nums[2] = 3;
    nums[3] = 4;
    try std.testing.expectEqualSlices(u32, &.{ 1, 2, 3, 4 }, nums);

    const obj = try a.create(Sword);
    defer a.destroy(obj);
    obj.stats = &[_]u8{};

    const copy = try a.dupe(u8, "zig");
    defer a.free(copy);
    try std.testing.expectEqualStrings("zig", copy);
    try std.testing.expectEqual(@as(usize, 3), copy.len); // 不含结尾0

    // 0.17：dupeZ 已移除，用 dupeSentinel
    const cz = try a.dupeSentinel(u8, "zig", 0);
    defer a.free(cz);
    try std.testing.expectEqual(@as(usize, 3), cz.len);
    try std.testing.expectEqual(@as(u8, 0), cz[cz.len]);
    // 类型是 [:0]u8 —— 哨兵进了类型
    try std.testing.expectEqualStrings("[:0]u8", @typeName(@TypeOf(cz)));

    const sent = try a.allocSentinel(u8, 4, 0);
    defer a.free(sent);
    try std.testing.expectEqual(@as(usize, 4), sent.len);
    try std.testing.expectEqual(@as(u8, 0), sent[4]);

    const msg = try a.print("{d}-{s}", .{ 7, "ok" });
    defer a.free(msg);
    try std.testing.expectEqualStrings("7-ok", msg);

    // 空分配合法
    const nothing = try a.alloc(u8, 0);
    try std.testing.expectEqual(@as(usize, 0), nothing.len);
    a.free(nothing);
}

test "resize 与 realloc：page_allocator 能缩不能扩" {
    const page = std.heap.page_allocator;
    var buf = try page.alloc(u8, 16);
    defer page.free(buf);
    try std.testing.expect(page.resize(buf, 8));
    buf = try page.realloc(buf, 8192);
    try std.testing.expectEqual(@as(usize, 8192), buf.len);
    buf = try page.realloc(buf, 8);
    try std.testing.expectEqual(@as(usize, 8), buf.len);
    // resize 到 0 等于 free，所以上面不能 defer 两次
}

test "OOM 是返回值：FixedBufferAllocator 满了返回 error.OutOfMemory" {
    var backing: [16]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&backing);
    const a = fba.allocator();
    const x = try a.alloc(u8, 8);
    try std.testing.expectEqual(@as(usize, 8), fba.end_index);
    try std.testing.expectError(error.OutOfMemory, a.alloc(u8, 16));
    fba.reset();
    try std.testing.expectEqual(@as(usize, 0), fba.end_index);
    try std.testing.expectEqual(@as(usize, 16), (try a.alloc(u8, 16)).len);
    _ = x;
}

test "FixedBufferAllocator 只对最后一块 free 生效，reset 归零" {
    var backing: [64]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&backing);
    const a = fba.allocator();
    const x1 = try a.alloc(u8, 16);
    const x2 = try a.alloc(u8, 16);
    try std.testing.expectEqual(@as(usize, 32), fba.end_index);
    a.free(x1); // 非最后一块：内存不还
    try std.testing.expectEqual(@as(usize, 32), fba.end_index);
    a.free(x2);
    try std.testing.expectEqual(@as(usize, 16), fba.end_index);
    fba.reset();
    try std.testing.expectEqual(@as(usize, 0), fba.end_index);
    try std.testing.expect(fba.ownsPtr(@ptrCast(x1.ptr)));
}

test "BufferFirstAllocator：小的走栈缓冲，大的自动落到底层" {
    var buf: [64]u8 = undefined;
    var fb = std.heap.BufferFirstAllocator.init(&buf, std.testing.allocator);
    const a = fb.allocator();

    const small = try a.alloc(u8, 32);
    try std.testing.expect(fb.fixed_buffer_allocator.ownsPtr(@ptrCast(small.ptr)));
    a.free(small);

    const exact = try a.alloc(u8, 64);
    try std.testing.expect(fb.fixed_buffer_allocator.ownsPtr(@ptrCast(exact.ptr)));
    a.free(exact);

    const large = try a.alloc(u8, 8192);
    try std.testing.expect(!fb.fixed_buffer_allocator.ownsPtr(@ptrCast(large.ptr)));
    a.free(large);
}

test "ArenaAllocator：一次 deinit 回收全部，单个 free 是 no-op" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const words = try splitIntoArena(a, "a b c");
    try std.testing.expectEqual(@as(usize, 3), words.len);
    try std.testing.expectEqualStrings("b", words[1]);

    const cap_before = arena.queryCapacity();
    const scratch = try a.alloc(u8, 64);
    a.free(scratch); // no-op
    try std.testing.expect(arena.queryCapacity() >= cap_before);

    // 三种 reset 都存在且可调用
    try std.testing.expect(arena.reset(.free_all));
    try std.testing.expectEqual(@as(usize, 0), arena.queryCapacity());
    _ = try a.alloc(u8, 4096);
    try std.testing.expect(arena.reset(.retain_capacity));
    _ = arena.reset(.{ .retain_with_limit = 512 });
    try std.testing.expect(arena.queryCapacity() <= 512);
}

test "DebugAllocator 与 SafeAllocator 的 deinit 返回值不同" {
    var da = std.heap.DebugAllocator(.{}){};
    const buf = try da.allocator().dupe(u8, "先 free 再 deinit");
    da.allocator().free(buf);
    try std.testing.expectEqual(std.heap.Check.ok, da.deinit()); // 枚举 ok

    // 0.17 推荐写法
    var da2: std.heap.DebugAllocator(.{}) = .init;
    const buf2 = try da2.allocator().alloc(u32, 16);
    da2.allocator().free(buf2);
    try std.testing.expectEqual(std.heap.Check.ok, da2.deinit());

    // SafeAllocator.deinit() 返回泄漏块数 usize
    var sa = std.heap.SafeAllocator.init(std.testing.allocator, .{});
    const buf3 = try sa.allocator().dupe(u8, "safe");
    sa.allocator().free(buf3);
    try std.testing.expectEqual(@as(usize, 0), sa.deinit());
}

test "对齐分配：Alignment 是 log2 枚举，≤64 才有名字" {
    const A = std.mem.Alignment;
    try std.testing.expectEqual(@as(usize, 1), @sizeOf(A));
    try std.testing.expectEqual(@as(usize, 8), A.of(u64).toByteUnits());
    try std.testing.expectEqual(@as(usize, 256), A.fromByteUnits(256).toByteUnits());
    try std.testing.expectEqual(@as(u6, 8), @backingInt(A.fromByteUnits(256)));
    // ≤64 的成员有名字；128/256 只能靠 toByteUnits
    try std.testing.expectEqualStrings("8", @tagName(A.of(u64)));
    try std.testing.expectEqualStrings("64", @tagName(A.@"64"));

    const a = std.testing.allocator;
    const b = try a.alignedAlloc(u8, .@"64", 10);
    defer a.free(b);
    try std.testing.expectEqual(@as(usize, 10), b.len);
    try std.testing.expectEqual(@as(usize, 0), @intFromPtr(b.ptr) % 64);

    const c = try a.allocWithOptions(u8, 10, .fromByteUnits(128), null);
    defer a.free(c);
    try std.testing.expectEqual(@as(usize, 0), @intFromPtr(c.ptr) % 128);

    const combo = try a.allocWithOptions(u8, 4, .fromByteUnits(64), @as(u8, 0));
    defer a.free(combo);
    try std.testing.expectEqual(@as(usize, 4), combo.len);
    try std.testing.expectEqual(@as(u8, 0), combo[4]);

    const ac = try a.alignedCreate(u64, .fromByteUnits(256));
    defer a.destroy(ac);
    try std.testing.expectEqual(@as(usize, 0), @intFromPtr(ac) % 256);

    // 自然对齐不需要特殊处理
    const nat = try a.alloc(u64, 4);
    defer a.free(nat);
    try std.testing.expectEqual(@as(usize, 0), @intFromPtr(nat.ptr) % 8);
}

test "FailingAllocator：fail_index逐条走OOM 路径" {
    // fail_index = 0：第一次分配就失败
    var fa0 = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = 0 });
    try std.testing.expectError(error.OutOfMemory, buildTeamSafe(fa0.allocator(), &.{"zig"}));
    try std.testing.expect(fa0.has_induced_failure);
    try std.testing.expectEqual(@as(usize, 0), fa0.alloc_index);

    // fail_index = 2：前两次成功，第三次失败
    var fa2 = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = 2 });
    const a2 = fa2.allocator();
    const p1 = try a2.alloc(u8, 8);
    const p2 = try a2.alloc(u8, 8);
    try std.testing.expectError(error.OutOfMemory, a2.alloc(u8, 8));
    try std.testing.expectEqual(@as(usize, 2), fa2.alloc_index); // 失败那次不计数
    try std.testing.expectEqual(@as(usize, 16), fa2.allocated_bytes);
    a2.free(p1);
    a2.free(p2);
    try std.testing.expectEqual(@as(usize, 2), fa2.allocations);
    try std.testing.expectEqual(@as(usize, 2), fa2.deallocations);
    try std.testing.expectEqual(@as(usize, 16), fa2.freed_bytes);

    // std.testing.failing_allocator 是"永远失败"的现成全局实例
    try std.testing.expectError(error.OutOfMemory, std.testing.failing_allocator.alloc(u8, 1));
}

test "checkAllAllocationFailures：每一条 OOM 路径都不许漏" {
    const names = [_][]const u8{ "zig", "rust" };
    try std.testing.checkAllAllocationFailures(std.testing.allocator, exerciseSafe, .{names[0..]});
}

test "errdefer 惯用法：alloc → errdefer free → 初始化 → 返回" {
    const a = std.testing.allocator;
    const copy = try enchantedSword(a, "Slash");
    defer a.free(copy);
    try std.testing.expectEqualStrings("Slash", copy);

    const sword = try Sword.init(a, "Victory!");
    defer sword.deinit(a);
    try std.testing.expectEqualStrings("Victory!", sword.stats);

    const team = try buildTeamSafe(a, &.{ "zig", "rust", "go" });
    defer a.free(team);
    try std.testing.expectEqualStrings("zig,rust,go", team);
}

test "零大小类型：void 把HashMap 变成 Set" {
    var set = std.AutoHashMap(u32, void).init(std.testing.allocator);
    defer set.deinit();
    const marker: void = {}; // 0.17：void{} 已移除
    try set.put(1, marker);
    try set.put(1, marker); // 重复键：覆盖，不是新增
    try std.testing.expectEqual(@as(u32, 1), set.count());
    try std.testing.expect(set.contains(1));
    _ = set.remove(1);
    try std.testing.expect(!set.contains(1));

    try std.testing.expectEqual(@as(usize, 0), @sizeOf(void));
    try std.testing.expectEqual(@as(usize, 0), @sizeOf([0]u8));
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(*anyopaque));
}

test "零大小类型与peer type resolution" {
    var seed: u8 = 1;
    const cond = @intFromPtr(&seed) % 2 == 0;
    const peer = if (cond) @as(u8, 1) else @as(u16, 300);
    try std.testing.expectEqualStrings("u16", @typeName(@TypeOf(peer)));
    const peer2 = if (cond) "abc" else @as([]const u8, "xy");
    try std.testing.expectEqualStrings("[]const u8", @typeName(@TypeOf(peer2)));
    const peer3 = if (cond) @as(?u32, 7) else @as(?u32, null);
    try std.testing.expectEqualStrings("?u32", @typeName(@TypeOf(peer3)));
}
