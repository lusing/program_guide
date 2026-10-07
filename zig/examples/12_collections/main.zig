//! 12 集合：unmanaged 之���、ArrayList、HashMap 族、MultiArrayList、排序与二分、定容替代、选型
//! 分节打印约定：每个小节用 ==== 12.N 开始 ==== / ==== 12.N 结束 ==== 圈出
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ══════════════════════════════════════════════════════════════════
// 支撑类型与函数（被后面各节反复调用）
// ══════════════════════════════════════════════════════════════════

/// 12.1 节的 unmanaged 容器持有者：容器里没有分配器字段，所有操作都要分配器。
/// 这正是unmanaged 的核心好处——它能按值塞进任何 struct，拷贝/移动都不牵扯"谁负责还内存"。
const Inventory = struct {
    // 两个容器都是"纯数据"：只有指针 + 长度 + 容量
    items: std.ArrayList([]const u8),
    // ⚠️ 键是字符串切片就不能用 Auto*（std.hash.autoHash 拒绝切片做键，实测报
    //    "std.hash.autoHash does not allow slices here ([]const u8) because the intent is unclear"）
    //    ——字符串键必须用 String 系列。
    prices: std.StringHashMapUnmanaged(u32),

    fn init() Inventory {
        return .{ .items = .empty, .prices = .empty };
    }

    /// 清理时才需要分配器——而且由调用方决定用哪个
    fn deinit(self: *Inventory, gpa: std.mem.Allocator) void {
        self.items.deinit(gpa);
        self.prices.deinit(gpa);
    }
};

/// 12.6 节的 MultiArrayList 元素类型：每个字段会被拆成一条独立的并行数组
const Item = struct {
    name: []const u8,
    hp: u32,
    price: u32,
};

/// 12.13 节的枚举键集合元素
const Flag = enum { a, b, c, d };

/// 12.12 节的定容集合手写替代：定长数组 + 计数（std.BoundedArray 在 0.17 已移除）
const FixedStack = struct {
    buf: [4]u8 = undefined,
    len: usize = 0,

    /// 返回 false = 满了（拒绝，既不覆盖也不扩容）
    fn push(self: *FixedStack, ch: u8) bool {
        if (self.len == self.buf.len) return false;
        self.buf[self.len] = ch;
        self.len += 1;
        return true;
    }
    fn items(self: *const FixedStack) []const u8 {
        return self.buf[0..self.len]; // 只暴露有效部分，不泄漏容量
    }
};

/// 12.8 节的排序比较函数。签名固定是 fn (ctx, lhs, rhs) bool——ctx 就是"外部状态"
fn lessThanU32(_: void, a: u32, b: u32) bool {
    return a < b;
}

fn greaterThanU32(_: void, a: u32, b: u32) bool {
    return a > b;
}

/// 12.9 节用 ctx 排序：ctx 是一段"按 id 查名字"的外部状态，比较函数本身保持无捕获
const NameTable = struct {
    names: []const []const u8,
    fn lessByName(self: NameTable, a: u32, b: u32) bool {
        return std.mem.lessThan(u8, self.names[a], self.names[b]);
    }
};

/// 12.10 节二分查找的比较函数：返回三态Order（.lt/.eq/.gt），不是 bool
fn orderU32(target: u32, item: u32) std.math.Order {
    return std.math.order(target, item);
}

pub fn main(init: std.process.Init) !void {
    // 本章统一用一个 arena 当"被传入的分配器"：它便宜，且让示例专注于集合语义本身。
    // unmanaged 容器只要求"整个生命周期用同一个分配器"，用哪个是调用方的自由。
    var arena_state = std.heap.ArenaAllocator.init(init.gpa);
    defer arena_state.deinit();
    const mem = arena_state.allocator();

    // ═══ 12.1 为什么集合要 unmanaged：分配器是参数，不是字段 ═══
    begin("12.1");
    // std.ArrayList(T) 就是 unmanaged 形态：=.empty 初始化，方法第一个参数收分配器。
    var list: std.ArrayList(u32) = .empty;
    defer list.deinit(mem);
    try list.append(mem, 5);
    try list.appendSlice(mem, &.{ 3, 9 });
    // std.ArrayListUnmanaged 这个名字在 0.17 **仍然存在**，但已是 Deprecated 别名：
    // `pub const ArrayListUnmanaged = ArrayList;`——它是个函数，不是独立类型。
    std.debug.print("ArrayList 与 ArrayListUnmanaged 是同一个类型？ {}\n", .{
        @typeName(std.ArrayList(u32)) == @typeName(std.ArrayListUnmanaged(u32)),
    });
    std.debug.print("std.ArrayList(u32) 的真实类型名 = {s}\n", .{@typeName(std.ArrayList(u32))});
    // managed 形态把分配器藏在自己内部，unmanaged 不藏——sizeOf 差16 字节（u32→u64 map）
    std.debug.print("sizeOf: ArrayList(u32)={d} AutoHashMap={d} AutoHashMapUnmanaged={d}\n", .{
        @sizeOf(std.ArrayList(u32)),
        @sizeOf(std.AutoHashMap(u32, u32)),
        @sizeOf(std.AutoHashMapUnmanaged(u32, u32)),
    });
    // unmanaged 的直接收益：容器能按值内嵌进自己的 struct
    var inv = Inventory.init();
    defer inv.deinit(mem);
    try inv.items.append(mem, "sword");
    try inv.prices.put(mem, "sword", 150);
    std.debug.print("unmanaged 容器内嵌 struct：items[0]={s} prices[\"sword\"]={d}\n", .{ inv.items.items[0], inv.prices.get("sword").? });
    // 反过来promote：unmanaged 用着不顺手可以转成 managed（所有权随之转移）
    var um: std.AutoHashMapUnmanaged(u32, u32) = .empty;
    try um.put(mem, 7, 70);
    var promoted = um.promote(mem); // 注意结果要 var：promote 返回值要交给 deinit
    std.debug.print("promote 后 managed.count={d} get(7)={d}；原 um.count={d}（所有权已转移，别再deinit um）\n", .{ promoted.count(), promoted.get(7).?, um.count() });
    promoted.deinit();
    end("12.1");

    // ═══ 12.2 ArrayList 的增删改：append / insert / orderedRemove vs swapRemove ═══
    begin("12.2");
    var l2: std.ArrayList(u32) = .empty;
    defer l2.deinit(mem);
    try l2.appendSlice(mem, &.{ 5, 3, 9, 1, 7 });
    try l2.insert(mem, 0, 100); // 下标 0 插入 → 后面的全部后移
    std.debug.print("insert(0,100) 后：{any}（len={d}）\n", .{ l2.items, l2.items.len });
    // pop 返回 ?T（不是 T）：空表返回 null
    const p = l2.pop();
    std.debug.print("pop() = {any}，类型 {s}，表里还剩 {any}\n", .{ p, @typeName(@TypeOf(p)), l2.items });
    // 空表 pop 的实测行为
    var empty_list: std.ArrayList(u32) = .empty;
    defer empty_list.deinit(mem);
    std.debug.print("空表 pop() = {any}（不是 panic）\n", .{empty_list.pop()});
    // orderedRemove：保序，O(n) 搬移
    const taken = l2.orderedRemove(0);
    std.debug.print("orderedRemove(0) 拿走 {d} → {any}（相对顺序保持）\n", .{ taken, l2.items });
    // swapRemove：O(1)，拿末尾元素补位→ 打乱顺序
    const swapped = l2.swapRemove(0);
    std.debug.print("swapRemove(0) 拿走 {d} → {any}（末尾补位，顺序乱了）\n", .{ swapped, l2.items });
    // appendNTimes / addOne：批量与"要指针"的场景
    try l2.appendNTimes(mem, 7, 3);
    const slot = try l2.addOne(mem); // 返回 *T，省一次 append 再下标
    slot.* = 99;
    std.debug.print("appendNTimes(7,3) + addOne()->99 → {any}\n", .{l2.items});
    // insertSlice / orderedRemoveMany：批量版
    try l2.insertSlice(mem, 1, &.{ 60, 70 });
    std.debug.print("insertSlice(1, 60/70) → {any}\n", .{l2.items});
    // resize 扩长：新元素是 undefined（实测堆上填 0xaa）
    try l2.resize(mem, l2.items.len + 2);
    std.debug.print("resize(+2) 后 len={d}（多出的两个是 undefined，别直接读）\n", .{l2.items.len});
    end("12.2");

    // ═══ 12.3 容量、摊还增长与 clearRetainingCapacity ═══
    begin("12.3");
    var l3: std.ArrayList(u32) = .empty;
    defer l3.deinit(mem);
    // append 时容量不够会自动扩容。源码 growCapacity：
    //   minimum + minimum/2 + init_capacity，init_capacity = cache_line / @sizeOf(T)
    // cache_line 在本机是 128 字节，u32 占 4 字节 → init_capacity = 32
    std.debug.print("cache_line={d}，init_capacity(u32)={d}\n", .{ std.atomic.cache_line, @max(1, std.atomic.cache_line / @sizeOf(u32)) });
    std.debug.print("growCapacity(1)={d}  growCapacity(34)={d}  growCapacity(84)={d}\n", .{
        std.ArrayList(u32).growCapacity(1),
        std.ArrayList(u32).growCapacity(34),
        std.ArrayList(u32).growCapacity(84),
    });
    // 打印真实的增长台阶
    var prev_cap: usize = 0;
    var step: usize = 0;
    while (step < 200) : (step += 1) {
        try l3.append(mem, @intCast(step));
        if (l3.capacity != prev_cap) {
            std.debug.print("  len={d:>3} → capacity={d}\n", .{ l3.items.len, l3.capacity });
            prev_cap = l3.capacity;
        }
    }
    // 摊还 O(1) 的含义：扩容次数是 O(log n)，总拷贝量O(n)
    std.debug.print("200 次 append 总共搬了 {d} 个元素（≈ n，一次半）\n", .{l3.items.len * 2});
    // 需要稳定指针时先 reserve
    try l3.ensureTotalCapacity(mem, 4096);
    std.debug.print("ensureTotalCapacity(4096) → capacity={d}（一次到位，不再搬）\n", .{l3.capacity});
    // clearRetainingCapacity：len 归零、容量留着（循环里反复清空时省分配）
    l3.clearRetainingCapacity();
    std.debug.print("clearRetainingCapacity 后 len={d} capacity={d}\n", .{ l3.items.len, l3.capacity });
    // clearAndFree：连容量一起还
    l3.clearAndFree(mem);
    std.debug.print("clearAndFree 后 len={d} capacity={d}\n", .{ l3.items.len, l3.capacity });
    end("12.3");

    // ═══ 12.4 toOwnedSlice：把堆所有权交出去 ═══
    begin("12.4");
    var src: std.ArrayList(u32) = .empty;
    try src.appendSlice(mem, &.{ 10, 20, 30 });
    const owned = try src.toOwnedSlice(mem); // 容器退场，数据留下
    std.debug.print("toOwnedSlice → owned={any}；容器本身 len={d} capacity={d}（被掏空了）\n", .{ owned, src.items.len, src.capacity });
    // 此时只剩一个裸切片，用 arena 时不用free；用别的分配器就得自己还
    // fromOwnedSlice 是反方向：零拷贝接管一段已有内存
    const raw = try mem.alloc(u32, 3);
    raw[0] = 7;
    raw[1] = 8;
    raw[2] = 9;
    var adopted: std.ArrayList(u32) = .fromOwnedSlice(raw); // 不拷贝，直接接管
    std.debug.print("fromOwnedSlice → {any} capacity={d}（指针就是 raw 那块，没有拷贝）\n", .{ adopted.items, adopted.capacity });
    adopted.deinit(mem);
    // toOwnedSliceSentinel：要C 字符串时用
    var text: std.ArrayList(u8) = .empty;
    defer text.deinit(mem);
    try text.appendSlice(mem, "hello");
    const zstr = try text.toOwnedSliceSentinel(mem, 0); // 结尾补一个 0 字节
    std.debug.print("toOwnedSliceSentinel(0) → {s} len={d}（末字节是 {d}，可直接给 C API）\n", .{ zstr, zstr.len, zstr[zstr.len] });
    end("12.4");

    // ═══ 12.5 HashMap 族（一）：AutoHashMap 与 unmanaged 对照 ═══
    begin("12.5");
    // HashMap 族在 0.17 **同时有 managed 和 unmanaged 两套**：
    //   managed:   AutoHashMap / AutoHashMapUnmanaged / HashMap
    //   unmanaged: std.AutoHashMap / std.AutoHashMapUnmanaged / std.HashMapUnmanaged
    // managed 用 .init(alloc)，之后每个方法都不带分配器。
    var map = std.AutoHashMap(u32, []const u8).init(mem);
    defer map.deinit();
    try map.put(1, "一");
    try map.put(2, "二");
    try map.put(3, "三");
    std.debug.print("AutoHashMap: count={d} capacity={d} get(2)={s} contains(9)={}\n", .{ map.count(), map.capacity(), map.get(2).?, map.contains(9) });
    // load factor：默认 80%，超过就 rehash 扩容
    std.debug.print("default_max_load_percentage={d}（超过 count/capacity 就扩）\n", .{std.hash_map.default_max_load_percentage});
    // unmanaged 版：每个方法收分配器，但容器本身纯数据
    var umap: std.AutoHashMapUnmanaged(u32, u32) = .empty;
    defer umap.deinit(mem);
    try umap.put(mem, 1, 10);
    try umap.put(mem, 2, 20);
    std.debug.print("AutoHashMapUnmanaged: count={d} get(2)={d}（方法都收mem）\n", .{ umap.count(), umap.get(2).? });
    // 预reserve 之后可以用 putAssumeCapacity（不检查容量，省一次分支）
    try umap.ensureTotalCapacity(mem, 8);
    umap.putAssumeCapacity(3, 30);
    std.debug.print("putAssumeCapacity 后 count={d} capacity={d}\n", .{ umap.count(), umap.capacity() });
    end("12.5");

    // ═══ 12.6 HashMap 族（二）：getOrPut 两用、fetchRemove 与原子性 ═══
    begin("12.6");
    // getOrPut：一次哈希完成"查或插"，返回的槽位让你自己决定填什么
    const gop = try map.getOrPut(10);
    if (!gop.found_existing) gop.value_ptr.* = "十";
    std.debug.print("getOrPut(10) found_existing={} → {s}；count={d}\n", .{ gop.found_existing, map.get(10).?, map.count() });
    // 再getOrPut 同一个key：不会重复插入
    const gop_again = try map.getOrPut(10);
    std.debug.print("getOrPut(10) 再来一次 found_existing={} → count 仍是 {d}\n", .{ gop_again.found_existing, map.count() });
    // 词频统计是getOrPut 的经典用法：两步合成一步
    var freq = std.StringHashMap(usize).init(mem);
    defer freq.deinit();
    const words = [_][]const u8{ "a", "b", "a", "c", "b", "a" };
    for (words) |w| {
        const entry = try freq.getOrPut(w);
        // 没查到时 value_ptr 是 undefined，必须自己初始化再累加
        if (!entry.found_existing) entry.value_ptr.* = 0;
        entry.value_ptr.* += 1;
    }
    std.debug.print("词频: a={any} b={any} c={any} count={d}\n", .{ freq.get("a"), freq.get("b"), freq.get("c"), freq.count() });
    // fetchRemove：一步完成"查 + 删 + 拿走键值对"，返回 ?KV
    if (map.fetchRemove(1)) |kv| {
        std.debug.print("fetchRemove(1) → key={d} value={s}；count={d}\n", .{ kv.key, kv.value, map.count() });
    } else {
        std.debug.print("fetchRemove(1) → null\n", .{});
    }
    // remove 只告诉你"删没删掉"，不拿走值
    std.debug.print("remove(2)={} remove(999)={}；count={d}\n", .{ map.remove(2), map.remove(999), map.count() });
    // getPtr：拿到值的指针直接改（比 get-改-put 少一次哈希）
    try map.put(5, "五");
    if (map.getPtr(5)) |v| v.* = "伍";
    std.debug.print("getPtr(5) 改值后 get(5)={s}\n", .{map.get(5).?});
    // fetchPut：拿走旧值再写入
    if (try map.fetchPut(5, "伍贰")) |kv| std.debug.print("fetchPut(5) 返回旧值 {s}\n", .{kv.value});
    // putNoClobber：只在 key 不存在时写。⚠️ 已存在会 panic（不是返回错误）——
    //    std 源码是 assert(!result.found_existing)，实测 panic: reached unreachable code
    var noc: std.AutoHashMapUnmanaged(u32, []const u8) = .empty;
    defer noc.deinit(mem);
    try noc.putNoClobber(mem, 1, "first");
    std.debug.print("putNoClobber 新key 成功 → {s}\n", .{noc.get(1).?});
    end("12.6");

    // ═══ 12.7 StringHashMap：key 按内容哈希，且**只借用不拷贝** ═══
    begin("12.7");
    var colors = std.StringHashMap(u32).init(mem);
    defer colors.deinit();
    try colors.put("red", 0xFF0000);
    try colors.put("blue", 0x0000FF);
    // 哈希函数是 Wyhash（实测值随内容变化），相等是 mem.eql 逐字节比
    std.debug.print("hashString(\"abc\")=0x{x}  hashString(\"abd\")=0x{x}  eqlString(\"abc\",\"abc\")={}\n", .{
        std.hash_map.hashString("abc"), std.hash_map.hashString("abd"), std.hash_map.eqlString("abc", "abc"),
    });
    // 按内容查找：另写一份内容相同的字面量照样命中
    const red_again = "re" ++ "d"; // 编译期拼接，运行时是新地址
    std.debug.print("另写一份 \"re\"++\"d\"（地址不同）get → {any}（内容相同即是同一个键）\n", .{colors.get(red_again)});
    // ⚠️⚠️ 本节最重要的实测：key 的所有权
    // put 只保存切片本身（16 字节的 ptr+len），**不拷贝内容**。
    var scratch: [8]u8 = .{ 'g', 'r', 'a', 'y', 0, 0, 0, 0 };
    try colors.put(scratch[0..4], 9); // 借用栈上 buffer
    std.debug.print("put(scratch[0..4]) 后 get(\"gray\")={any}（查得到）\n", .{colors.get("gray")});
    scratch[0] = 'X'; // 改写 buffer —— map 里那个键的内容跟着变了
    var borrowed_key: []const u8 = "";
    var kit_x = colors.keyIterator();
    while (kit_x.next()) |kp| {
        // ⚠️ keyIterator 给的是 *K；对 StringHashMap 来说 K = []const u8，
        //    所以要解**两层**：kp.* 才是那个切片。
        if (kp.*[0] == 'X') borrowed_key = kp.*;
    }
    std.debug.print("改写 scratch[0]='X' 后 get(\"gray\")={any}，但 keyIterator 里能看到 {s}\n", .{ colors.get("gray"), borrowed_key });
    std.debug.print("  → 结论：StringHashMap 的 key 是**借用**，必须保证内存活到 map 死（字面量安全、临时拼接要 dupe 进堆）\n", .{});
    // 正确姿势：自己 dupe 一份到堆
    var owned_keys = std.StringHashMap(u32).init(mem);
    defer owned_keys.deinit();
    try owned_keys.put(try mem.dupe(u8, "temporary"), 1);
    std.debug.print("先 mem.dupe 再 put → get(\"temporary\")={any}（arena 里整块一起活，map 安全）\n", .{owned_keys.get("temporary")});
    // 迭代器给指针：能改值，但迭代中修改结构会让迭代器失效
    var it = colors.iterator();
    var visited: usize = 0;
    while (it.next()) |entry| {
        // entry.key_ptr.* / entry.value_ptr.* 是map 内部存储的地址
        visited += entry.key_ptr.*.len;
    }
    std.debug.print("iterator 走了 {d} 个 Entry（key+value 字节数），每个 Entry 含 key_ptr / value_ptr 两个指针（改值可以，改结构会失效迭代器）\n", .{visited});
    // keyIterator / fetchRemove
    var kit2 = colors.keyIterator();
    std.debug.print("keyIterator 第一个 key={s}（长度 {d}）\n", .{ kit2.next().?.*, kit2.next().?.*.len });
    if (colors.fetchRemove("red")) |kv| std.debug.print("fetchRemove(\"red\") → {s} = 0x{x:0>6}\n", .{ kv.key, kv.value });
    // clearRetainingCapacity：清空但留桶
    const before = colors.capacity();
    colors.clearRetainingCapacity();
    std.debug.print("clearRetainingCapacity 后 count={d} capacity={d}（桶还在，扩容没白做）\n", .{ colors.count(), before });
    end("12.7");

    // ═══ 12.8 ArrayHashMap（std.array_hash_map.Auto / String）：保插入序 ═══
    begin("12.8");
    // ⚠️ 0.17 的重大改名：std.ArrayHashMap 和 std.AutoArrayHashMap **已被移除**。
    // 实测 `std.ArrayHashMap` → error: root source file struct 'std' has no member named 'ArrayHashMap'
    //新家在 std.array_hash_map 模块下，且**全部是 unmanaged**（.empty + 方法收分配器）。
    std.debug.print("std 有 ArrayHashMap 吗? {}  有 AutoArrayHashMap 吗? {}\n", .{ @hasDecl(std, "ArrayHashMap"), @hasDecl(std, "AutoArrayHashMap") });
    // 三个入口：Auto（自动配哈希）/ String（内容哈希）/ Custom（自定义上下文 + 存不存 hash）
    var ahm: std.array_hash_map.Auto(u32, []const u8) = .empty;
    defer ahm.deinit(mem);
    try ahm.put(mem, 30, "thirty");
    try ahm.put(mem, 10, "ten");
    try ahm.put(mem, 20, "twenty");
    // 核心差别：迭代顺序 == 插入顺序（内部就是两条 ArrayList + 一张索引表）
    std.debug.print("ArrayHashMap 插入序30,10,20 → 迭代序:", .{});
    var ahm_it = ahm.iterator();
    while (ahm_it.next()) |e| std.debug.print(" {d}={s}", .{ e.key_ptr.*, e.value_ptr.* });
    std.debug.print("\n", .{});
    // 对照：普通 HashMap 顺序不保证
    var hm2 = std.AutoHashMap(u32, u32).init(mem);
    defer hm2.deinit();
    try hm2.put(30, 1);
    try hm2.put(10, 2);
    try hm2.put(20, 3);
    std.debug.print("AutoHashMap  插入序 30,10,20 → 迭代序:", .{});
    var hm_it = hm2.iterator();
    while (hm_it.next()) |e| std.debug.print(" {d}", .{e.key_ptr.*});
    std.debug.print("（无保证）\n", .{});
    // 删除两兄弟：swapRemove 打乱顺序、orderedRemove 保序
    try ahm.put(mem, 40, "forty");
    std.debug.print("再put(40) → 序:", .{});
    ahm_it = ahm.iterator();
    while (ahm_it.next()) |e| std.debug.print(" {d}", .{e.key_ptr.*});
    std.debug.print("；swapRemove(10)={} → 序:", .{ahm.swapRemove(10)});
    ahm_it = ahm.iterator();
    while (ahm_it.next()) |e| std.debug.print(" {d}", .{e.key_ptr.*});
    std.debug.print("；orderedRemove(20)={} → 序:", .{ahm.orderedRemove(20)});
    ahm_it = ahm.iterator();
    while (ahm_it.next()) |e| std.debug.print(" {d}", .{e.key_ptr.*});
    std.debug.print("\n", .{});
    // ⚠️ ArrayHashMap **没有** fetchRemove / remove / valueIterator / toOwnedSlice
    // 删除只有 swapRemove(key) / orderedRemove(key)，返回 bool（不拿走值！）
    std.debug.print("ArrayHashMap 有 fetchRemove? {} 有 remove? {} 有 valueIterator? {}\n", .{
        @hasDecl(std.array_hash_map.Auto(u32, u32), "fetchRemove"),
        @hasDecl(std.array_hash_map.Auto(u32, u32), "remove"),
        @hasDecl(std.array_hash_map.Auto(u32, u32), "valueIterator"),
    });
    // 字符串版
    var sahm: std.array_hash_map.String(u32) = .empty;
    defer sahm.deinit(mem);
    try sahm.put(mem, "alpha", 1);
    try sahm.put(mem, "beta", 2);
    std.debug.print("array_hash_map.String: get(\"beta\")={d} count={d}\n", .{ sahm.get("beta").?, sahm.count() });
    end("12.8");

    // ═══ 12.9 MultiArrayList：真·结构体数组拆分与并行数组 ═══
    begin("12.9");
    var mal: std.MultiArrayList(Item) = .empty;
    defer mal.deinit(mem);
    // sizeOf：一个字段都不占的"索引"，所有字段数组的基址都藏在 bytes 里
    std.debug.print("sizeOf: Item={d}字节 MultiArrayList(Item)={d}字节（只有指针+len+cap）\n", .{ @sizeOf(Item), @sizeOf(std.MultiArrayList(Item)) });
    try mal.append(mem, .{ .name = "sword", .hp = 10, .price = 150 });
    try mal.append(mem, .{ .name = "shield", .hp = 25, .price = 80 });
    try mal.append(mem, .{ .name = "potion", .hp = 3, .price = 25 });
    std.debug.print("len={d} capacity={d}（第一个 append 就直接给 9）\n", .{ mal.len, mal.capacity });
    // 核心手法：items(.field) 拿到某个字段的**完整并行数组**
    const names = mal.items(.name);
    const hps = mal.items(.hp);
    for (names, hps) |n, h| std.debug.print("  {s:<7} hp={d}\n", .{ n, h });
    // 只扫一个字段（缓存友好），这是 MAL 存在的全部意义
    var total: u32 = 0;
    for (mal.items(.hp)) |h| total += h;
    std.debug.print("只扫 hp 字段求和 = {d}（内存连续，比结构体数组快）\n", .{total});
    // get(i) 拼出一个"临时结构体"（值，不是指针）；要改用 set
    const one = mal.get(1);
    std.debug.print("get(1) = {s} hp={d} price={d}\n", .{ one.name, one.hp, one.price });
    mal.set(1, .{ .name = "shield", .hp = 40, .price = 90 });
    std.debug.print("set(1, hp=40) 后 get(1).hp={d}\n", .{mal.get(1).hp});
    mal.items(.hp)[0] = 77; // 直接改并行数组也行
    std.debug.print("items(.hp)[0]=77 后 get(0).hp={d}\n", .{mal.get(0).hp});
    // 删除只有两个：swapRemove（O(1)，末尾补位）/ orderedRemove（O(n) 保序），都返回 void
    mal.swapRemove(0);
    std.debug.print("swapRemove(0) 后 len={d} name0={s}（void 返回，看不到被删的值）\n", .{ mal.len, mal.get(0).name });
    // slice()：不转移所有权的窗口；toOwnedSlice() 把整个 MAL 变成字段数组集合
    var win = mal.slice();
    std.debug.print("slice(): len={d} get(0).name={s}（借用，非拷贝）\n", .{ win.len, win.get(0).name });
    var owned_mal = mal.toOwnedSlice(); // 注意：**没有分配器参数**，也不返回 error
    std.debug.print("toOwnedSlice(): len={d}，每个字段一条数组：", .{owned_mal.len});
    for (owned_mal.items(.name)) |nm| std.debug.print(" {s}", .{nm});
    std.debug.print(" hp={any}\n", .{owned_mal.items(.hp)});
    owned_mal.deinit(mem);
    mal.clearAndFree(mem);
    // ⚠️⚠️ 0.17.0 的 std bug：MultiArrayList.sort / sortSpan / sortSpanUnstable **全部编译不过**
    //    实测报错（sort 与 sortSpan 都是这一条）：
    //      lib/std/multi_array_list.zig:609:36: error: cannot store runtime value in compile time variable
    //                 .slice = self.slice(),
    //      note: referenced by: sortInternal ... / multi_array_list.zig:624
    //    所以下面用手写"排序下标数组"的变通方案代替。
    var mal2: std.MultiArrayList(Item) = .empty;
    defer mal2.deinit(mem);
    try mal2.append(mem, .{ .name = "dagger", .hp = 7, .price = 40 });
    try mal2.append(mem, .{ .name = "bow", .hp = 5, .price = 90 });
    try mal2.append(mem, .{ .name = "club", .hp = 12, .price = 15 });
    var order = [_]usize{ 0, 1, 2 };
    // 把 hp 切片当 ctx 传给 std.mem.sort，排的是下标
    std.mem.sort(usize, &order, mal2.items(.hp), struct {
        fn byHp(hp_values: []const u32, a: usize, b: usize) bool {
            return hp_values[a] < hp_values[b];
        }
    }.byHp);
    std.debug.print("变通排序（排下标）按 hp 升序：", .{});
    for (order) |ix| std.debug.print(" {s}({d})", .{ mal2.items(.name)[ix], mal2.items(.hp)[ix] });
    std.debug.print("\n", .{});
    // 手写"并行数组"替代方案（不依赖 MAL 时可以用）
    const SoA = struct {
        snames: std.ArrayList([]const u8),
        shps: std.ArrayList(u32),
        sprices: std.ArrayList(u32),
    };
    var soa: SoA = .{ .snames = .empty, .shps = .empty, .sprices = .empty };
    defer soa.snames.deinit(mem);
    defer soa.shps.deinit(mem);
    defer soa.sprices.deinit(mem);
    try soa.snames.append(mem, "wand");
    try soa.shps.append(mem, 4);
    try soa.sprices.append(mem, 60);
    try soa.snames.append(mem, "spear");
    try soa.shps.append(mem, 15);
    try soa.sprices.append(mem, 70);
    std.debug.print("手写 SoA：names.len={d} hps.len={d} prices.len={d}（三者必须手动同步，MAL 就是替你同步）\n", .{ soa.snames.items.len, soa.shps.items.len, soa.sprices.items.len });
    end("12.9");

    // ═══ 12.10 排序：std.mem.sort 与 std.sort.* 的分工 ═══
    begin("12.10");
    var nums = [_]u32{ 42, 7, 19, 3, 88, 23 };
    // 统一签名：fn (ctx, lhs, rhs) bool。四个参数：元素类型、切片、上下文、比较函数
    std.mem.sort(u32, &nums, {}, lessThanU32);
    std.debug.print("std.mem.sort（稳定）        → {any}\n", .{nums});
    // 需要降序：换个比较函数即可（不改容器）
    std.mem.sort(u32, &nums, {}, greaterThanU32);
    std.debug.print("换成降序比较→ {any}\n", .{nums});
    // 内置比较器：std.sort.asc(T) / std.sort.desc(T)，省掉自己写函数
    std.mem.sort(u32, &nums, {}, std.sort.asc(u32));
    std.debug.print("std.sort.asc(u32)→ {any}\n", .{nums});
    // 六个底层算法都在 std.sort 里，签名与 mem.sort 一致
    var a1 = [_]u32{ 5, 2, 8, 1 };
    std.sort.insertion(u32, &a1, {}, lessThanU32); // 稳定，O(n²) 但常数小，适合小数组
    var a2 = [_]u32{ 5, 2, 8, 1 };
    std.sort.heap(u32, &a2, {}, lessThanU32); // 不稳定，O(n log n) 最坏
    var a3 = [_]u32{ 5, 2, 8, 1 };
    std.sort.pdq(u32, &a3, {}, lessThanU32); // 不稳定，pattern-defeating 快排
    var a4 = [_]u32{ 5, 2, 8, 1 };
    std.sort.block(u32, &a4, {}, lessThanU32); // 稳定，mem.sort 实际就调它
    std.debug.print("insertion={any} heap={any} pdq={any} block={any}\n", .{ a1, a2, a3, a4 });
    // mem.sortUnstable = pdq；mem.sort = block（稳定）
    var a5 = [_]u32{ 5, 2, 8, 1 };
    std.mem.sortUnstable(u32, &a5, {}, lessThanU32);
    std.debug.print("mem.sortUnstable（= pdq）  → {any}\n", .{a5});
    // ⚠️ ArrayList **没有** .sort 方法（实测 no field or member function named 'sort'），
    //    也没有 .swap。只能把 items 切片交给 std.mem.sort。
    var alist: std.ArrayList(u32) = .empty;
    defer alist.deinit(mem);
    try alist.appendSlice(mem, &.{ 9, 6, 3 });
    std.mem.sort(u32, alist.items, {}, std.sort.asc(u32));
    std.debug.print("排ArrayList：std.mem.sort(u32, list.items, ...) → {any}\n", .{alist.items});
    // ctx 的意义：比较函数无捕获，靠参数拿外部状态（14 章泛型会大量用这个模式）
    const table = NameTable{ .names = &.{ "bob", "alice", "carol" } };
    var ids = [_]u32{ 0, 1, 2 };
    std.mem.sort(u32, &ids, table, NameTable.lessByName);
    std.debug.print("按 ctx 里的名字排序 id：", .{});
    for (ids) |id| std.debug.print(" {d}={s}", .{ id, table.names[id] });
    std.debug.print("\n", .{});
    // ArrayList 也没有 swap，两个元素对调用 std.mem.swap
    std.mem.swap(u32, &alist.items[0], &alist.items[2]);
    std.debug.print("std.mem.swap 两个元素 → {any}\n", .{alist.items});
    end("12.10");

    // ═══ 12.11 二分查找：binarySearch / lowerBound / upperBound ═══
    begin("12.11");
    // 前提：**必须已排序**。四参数与排序同构，但比较函数返回三态 Order 而不是 bool。
    const sorted = [_]u32{ 1, 3, 5, 7, 9, 11 };
    // ⚠️⚠️ 0.17 的坑：context 参数写成裸字面量会编译失败——字面量是 comptime_int，
    //    而 compareFn 要的是 fn(u32, u32) Order：
    //      error: expected type 'fn (comptime_int, u32) math.Order', found 'fn (u32, u32) math.Order'
    //      note: non-generic function cannot cast into a generic function
    //    修法：给查找目标点名类型。
    const target7: u32 = 7;
    const target4: u32 = 4;
    const target6: u32 = 6;
    const hit = std.sort.binarySearch(u32, &sorted, target7, orderU32);
    std.debug.print("binarySearch(7) = {any}（命中下标）\n", .{hit});
    std.debug.print("binarySearch(4) = {any}（没命中返回 null，不是错误）\n", .{std.sort.binarySearch(u32, &sorted, target4, orderU32)});
    // lowerBound / upperBound：返回 usize 而不是 ?usize，是"插入位置"
    std.debug.print("lowerBound(4) = {d}（第一个 >= 4 的位置）\n", .{std.sort.lowerBound(u32, &sorted, target4, orderU32)});
    std.debug.print("upperBound(4) = {d}（第一个 > 4 的位置）\n", .{std.sort.upperBound(u32, &sorted, target4, orderU32)});
    // ⚠️ partitionPoint 是例外：它的第4 参是 **bool 谓词**不是 Order 比较函数
    const pp = std.sort.partitionPoint(u32, &sorted, target4, struct {
        fn isBelow(ctx: u32, item: u32) bool {
            return item < ctx;
        }
    }.isBelow);
    std.debug.print("partitionPoint(元素<4 的个数) = {d}（谓词签名，返回 bool）\n", .{pp});
    // 排序 + 二分 = 有序插入
    const pos = std.sort.lowerBound(u32, &sorted, target6, orderU32);
    std.debug.print("插入 6 应放在 sorted[{d}]={d} 之前（保持有序的唯一正确位置）\n", .{ pos, sorted[pos] });
    // equalRange：一次拿到相等区间两端
    const dup = [_]u32{ 1, 2, 2, 2, 5, 7 };
    const key2: u32 = 2;
    const range = std.sort.equalRange(u32, &dup, key2, orderU32);
    std.debug.print("equalRange(2) = [{}, {}) 共 {d} 个2\n", .{ range[0], range[1], range[1] - range[0] });
    // min/max/argMin/argMax/isSorted：⚠️ 0.17 里 min/max/argMin/argMax 返回**可选**
    //（空切片返回 null），而且格式化必须用 {any}——用 {d} 会报
    //    error: invalid format string 'd' for type '?u32'
    std.debug.print("min={any} max={any} argMin={any} argMax={any} isSorted={}\n", .{
        std.sort.min(u32, &sorted, {}, lessThanU32),
        std.sort.max(u32, &sorted, {}, lessThanU32),
        std.sort.argMin(u32, &sorted, {}, lessThanU32),
        std.sort.argMax(u32, &sorted, {}, lessThanU32),
        std.sort.isSorted(u32, &sorted, {}, lessThanU32),
    });
    std.debug.print("空切片的 min = {any}（返回 null，不是崩溃）\n", .{std.sort.min(u32, &[_]u32{}, {}, lessThanU32)});
    end("12.11");

    // ═══ 12.12 定容集合：BoundedArray 已移除，手写三件套 ═══
    begin("12.12");
    // ⚠️ std.BoundedArray 在 0.17 **不存在**（实测 error: root source file struct 'std'
    //    has no member named 'BoundedArray'）。0.14 起被"定长数组 + 计数"取代。
    std.debug.print("std 有 BoundedArray 吗? {}\n", .{@hasDecl(std, "BoundedArray")});
    // 三件套：栈上数组做存储、usize 记长度、写满就停
    var fixed: FixedStack = .{};
    for ("zig!") |ch| {
        if (!fixed.push(ch)) break;
    }
    std.debug.print("定容 4 槽装了 {d} 个字符：{s}（容量就是数组长度）\n", .{ fixed.len, fixed.items() });
    // 满了就拒绝——不是覆盖、不是扩容，这就是"定容"的意义
    std.debug.print("再 push 一个返回={}（拒绝而非覆盖，len 仍是 {d}）\n", .{ fixed.push('?'), fixed.len });
    // 动态版对照：同样内容放进 ArrayList
    var dynamic: std.ArrayList(u8) = .empty;
    defer dynamic.deinit(mem);
    try dynamic.appendSlice(mem, "zig");
    try dynamic.append(mem, '!');
    std.debug.print("同样内容放 ArrayList → {s}（len={d}，可以无限长）\n", .{ dynamic.items, dynamic.items.len });
    end("12.12");

    // ═══ 12.13 选型速查：什么时候用什么 ═══
    begin("12.13");
    // 决策顺序（按实测存在的类型列）：
    // 1. 长度编译期已知且小 → [N]T 栈数组（零分配、零间接）
    // 2. 长度编译期已知但要当参数传 → []const T 切片
    // 3. 长度要变、要放堆 → std.ArrayList(T)（unmanaged，本章 12.1-12.4）
    // 4. 长度要变但不许堆 → 12.12 的"数组 + len"三件套
    // 5. 键值查找 → std.AutoHashMap / std.StringHashMap（managed）
    //    键值查找 + 要保插入序 → std.array_hash_map.Auto（12.8）
    // 6. 元素是结构体、只扫部分字段 → std.MultiArrayList（12.9）
    // 7. 只是要个"枚举键的集合" → std.EnumSet（位域，零分配，见 08 章）
    var mask: std.EnumSet(Flag) = .{};
    mask.insert(.a);
    mask.insert(.c);
    std.debug.print("EnumSet(Flag)：sizeOf={d}字节 bitSize={d}位；含 a={} b={} c={} count={d}\n", .{
        @sizeOf(std.EnumSet(Flag)), @bitSizeOf(@TypeOf(mask.bits)),
        mask.contains(.a),          mask.contains(.b),
        mask.contains(.c),          mask.count(),
    });
    // 一句话总结
    std.debug.print("选型口诀：定长用数组、要变用 List、查键用 Map、要序用 array_hash_map、扫字段用 MultiArrayList、枚举集合用 EnumSet\n", .{});
    end("12.13");

    std.debug.print("自检通过\n", .{});
}

// ══════════════════════════════════════════════════════════════════
// 测试：用 std.testing.allocator 检查泄漏 + 钉住语义
// ══════════════════════════════════════════════════════════════════

test "12.1 unmanaged 容器可内嵌 struct，且 ArrayListUnmanaged 是同一类型" {
    try std.testing.expectEqual(
        @typeName(std.ArrayList(u32)),
        @typeName(std.ArrayListUnmanaged(u32)),
    );
    // unmanaged 的sizeOf 应该小于 managed（少一个 Allocator 字段）
    try std.testing.expect(@sizeOf(std.AutoHashMapUnmanaged(u32, u32)) < @sizeOf(std.AutoHashMap(u32, u32)));
    // 内嵌进 struct 后照常工作
    const gpa = std.testing.allocator;
    var inv = Inventory.init();
    defer inv.deinit(gpa);
    try inv.items.append(gpa, "potion");
    try inv.prices.put(gpa, "potion", 25);
    try std.testing.expectEqualStrings("potion", inv.items.items[0]);
    try std.testing.expectEqual(@as(u32, 25), inv.prices.get("potion").?);
}

test "12.2 append/insert/pop/orderedRemove/swapRemove 的语义" {
    const gpa = std.testing.allocator;
    var l: std.ArrayList(u32) = .empty;
    defer l.deinit(gpa);
    try l.appendSlice(gpa, &.{ 5, 3, 9, 1, 7 });
    try l.insert(gpa, 0, 100);
    try std.testing.expectEqualSlices(u32, &.{ 100, 5, 3, 9, 1, 7 }, l.items);
    // pop 返回 ?T
    try std.testing.expectEqual(@as(?u32, 7), l.pop());
    // 空表 pop 返回 null，不 panic
    var e: std.ArrayList(u32) = .empty;
    defer e.deinit(gpa);
    try std.testing.expectEqual(@as(?u32, null), e.pop());
    // orderedRemove 保序
    try std.testing.expectEqual(@as(u32, 100), l.orderedRemove(0));
    try std.testing.expectEqualSlices(u32, &.{ 5, 3, 9, 1 }, l.items);
    // swapRemove 打乱顺序：拿末位补位
    try std.testing.expectEqual(@as(u32, 5), l.swapRemove(0));
    try std.testing.expectEqualSlices(u32, &.{ 1, 3, 9 }, l.items);
}

test "12.3 容量增长、ensureTotalCapacity 与 clearRetainingCapacity" {
    const gpa = std.testing.allocator;
    // growCapacity 是纯函数，可以直接断言公式
    // minimum + minimum/2 + max(1, cache_line/@sizeOf(T))
    const init_cap: usize = @max(1, std.atomic.cache_line / @sizeOf(u32));
    try std.testing.expectEqual(@as(usize, 1 + 0 + init_cap), std.ArrayList(u32).growCapacity(1));
    try std.testing.expectEqual(@as(usize, 34 + 17 + init_cap), std.ArrayList(u32).growCapacity(34));
    // 增长是超线性的（≈1.5 倍 + 常数），不是每次 +1 也不是 2 倍
    try std.testing.expect(std.ArrayList(u32).growCapacity(200) > std.ArrayList(u32).growCapacity(100));
    try std.testing.expect(std.ArrayList(u32).growCapacity(400) > std.ArrayList(u32).growCapacity(200));
    // 精确值：200 + 100 + 32 = 332
    try std.testing.expectEqual(@as(usize, 200 + 100 + init_cap), std.ArrayList(u32).growCapacity(200));

    var l: std.ArrayList(u32) = .empty;
    defer l.deinit(gpa);
    try l.appendSlice(gpa, &.{ 1, 2, 3 });
    try l.ensureTotalCapacity(gpa, 4096);
    try std.testing.expect(l.capacity >= 4096);
    const cap_before = l.capacity;
    l.clearRetainingCapacity();
    try std.testing.expectEqual(@as(usize, 0), l.items.len);
    try std.testing.expectEqual(cap_before, l.capacity); // 容量原样留着
    l.clearAndFree(gpa);
    try std.testing.expectEqual(@as(usize, 0), l.capacity); // clearAndFree 把容量也还了
}

test "12.4 toOwnedSlice 掏空容器，fromOwnedSlice 零拷贝接管" {
    const gpa = std.testing.allocator;
    var l: std.ArrayList(u32) = .empty;
    try l.appendSlice(gpa, &.{ 10, 20, 30 });
    const owned = try l.toOwnedSlice(gpa);
    defer gpa.free(owned);
    try std.testing.expectEqualSlices(u32, &.{ 10, 20, 30 }, owned);
    // 容器被掏空：不需要再deinit（也不该deinit）
    try std.testing.expectEqual(@as(usize, 0), l.items.len);
    try std.testing.expectEqual(@as(usize, 0), l.capacity);

    // fromOwnedSlice：指针就是传进去那块
    const raw = try gpa.alloc(u32, 3);
    raw[0] = 7;
    raw[1] = 8;
    raw[2] = 9;
    var adopted: std.ArrayList(u32) = .fromOwnedSlice(raw);
    try std.testing.expectEqual(@intFromPtr(raw.ptr), @intFromPtr(adopted.items.ptr));
    try std.testing.expectEqualSlices(u32, &.{ 7, 8, 9 }, adopted.items);
    adopted.deinit(gpa);
}

test "12.5/12.6 HashMap：get / getOrPut / fetchRemove / remove / getPtr" {
    const gpa = std.testing.allocator;
    var m = std.AutoHashMap(u32, []const u8).init(gpa);
    defer m.deinit();
    try m.put(1, "one");
    try m.put(2, "two");
    try std.testing.expectEqualStrings("two", m.get(2).?);
    try std.testing.expect(!m.contains(99));

    // getOrPut 两用
    const gop = try m.getOrPut(3);
    try std.testing.expect(!gop.found_existing);
    gop.value_ptr.* = "three";
    try std.testing.expectEqual(@as(usize, 3), m.count());
    const again = try m.getOrPut(3);
    try std.testing.expect(again.found_existing); // 不会重复插入
    try std.testing.expectEqual(@as(usize, 3), m.count());

    // fetchRemove：一步拿走键值对
    const kv = m.fetchRemove(1).?;
    try std.testing.expectEqual(@as(u32, 1), kv.key);
    try std.testing.expectEqualStrings("one", kv.value);
    try std.testing.expectEqual(@as(usize, 2), m.count());
    try std.testing.expectEqual(@as(?std.hash_map.AutoHashMap(u32, []const u8).KV, null), m.fetchRemove(1));

    // remove只给bool
    try std.testing.expect(m.remove(2));
    try std.testing.expect(!m.remove(2));

    // getPtr 原地改值
    try m.put(5, "五");
    m.getPtr(5).?.* = "伍";
    try std.testing.expectEqualStrings("伍", m.get(5).?);
}

test "12.7 StringHashMap 按内容哈希，key 只是借用切片" {
    const gpa = std.testing.allocator;
    var sm: std.StringHashMapUnmanaged(u32) = .empty;
    defer sm.deinit(gpa);
    try sm.put(gpa, "red", 1);
    // 内容相同 → 同一个键（哪怕地址不同）
    const other = "r" ++ "ed";
    try std.testing.expectEqual(@as(u32, 1), sm.get(other).?);
    // hashString/eqlString 是公开的纯函数
    try std.testing.expect(std.hash_map.eqlString("abc", "abc"));
    try std.testing.expect(!std.hash_map.eqlString("abc", "abd"));
    try std.testing.expectEqual(std.hash_map.hashString("abc"), std.hash_map.hashString("abc"));

    // ⚠️ key 是借用：改写原buffer 后就查不到了
    var buf: [4]u8 = "gray".*;
    try sm.put(gpa, buf[0..], 9);
    try std.testing.expectEqual(@as(u32, 9), sm.get("gray").?);
    buf[0] = 'X';
    try std.testing.expectEqual(@as(?u32, null), sm.get("gray"));
    // map 里存的那个 key 现在是 "Xray"（keyIterator 给的是 *const []const u8，要解两层）
    var kit = sm.keyIterator();
    var found_xray = false;
    while (kit.next()) |kp| {
        if (std.mem.eql(u8, kp.*, "Xray")) found_xray = true;
    }
    try std.testing.expect(found_xray);
}

test "12.8 array_hash_map 保插入序，swapRemove/orderedRemove 语义不同" {
    const gpa = std.testing.allocator;
    var a: std.array_hash_map.Auto(u32, []const u8) = .empty;
    defer a.deinit(gpa);
    try a.put(gpa, 30, "thirty");
    try a.put(gpa, 10, "ten");
    try a.put(gpa, 20, "twenty");

    // 迭代顺序 == 插入顺序（这是与 AutoHashMap 的核心差别）
    var it = a.iterator();
    try std.testing.expectEqual(@as(u32, 30), it.next().?.key_ptr.*);
    try std.testing.expectEqual(@as(u32, 10), it.next().?.key_ptr.*);
    try std.testing.expectEqual(@as(u32, 20), it.next().?.key_ptr.*);
    try std.testing.expect(it.next() == null); // 迭代器耗尽返回 null

    // swapRemove 打乱顺序
    try a.put(gpa, 40, "forty");
    try std.testing.expect(a.swapRemove(10));
    // 原来顺序是 30,10,20,40；删掉 10 后末尾的 40 补到 10 的位置 → 30,40,20
    var it2 = a.iterator();
    const e1 = it2.next().?;
    try std.testing.expectEqual(@as(u32, 30), e1.key_ptr.*);
    try std.testing.expectEqualStrings("thirty", e1.value_ptr.*);
    try std.testing.expectEqual(@as(u32, 40), it2.next().?.key_ptr.*);
    try std.testing.expectEqual(@as(u32, 20), it2.next().?.key_ptr.*);
    try std.testing.expect(it2.next() == null);

    // orderedRemove 保序：后面的元素依次前移
    try std.testing.expect(a.orderedRemove(20));
    var it3 = a.iterator();
    try std.testing.expectEqual(@as(u32, 30), it3.next().?.key_ptr.*);
    try std.testing.expectEqual(@as(u32, 40), it3.next().?.key_ptr.*);
    try std.testing.expect(it3.next() == null);

    // 没有 fetchRemove / remove
    try std.testing.expect(!@hasDecl(std.array_hash_map.Auto(u32, u32), "fetchRemove"));
    try std.testing.expect(!@hasDecl(std.array_hash_map.Auto(u32, u32), "remove"));
}

test "12.9 MultiArrayList：字段拆成并行数组，get/set 与 swapRemove" {
    const gpa = std.testing.allocator;
    var mal: std.MultiArrayList(Item) = .empty;
    defer mal.deinit(gpa);
    try mal.append(gpa, .{ .name = "sword", .hp = 10, .price = 150 });
    try mal.append(gpa, .{ .name = "shield", .hp = 25, .price = 80 });
    try mal.append(gpa, .{ .name = "potion", .hp = 3, .price = 25 });
    try std.testing.expectEqual(@as(usize, 3), mal.len);

    // items(.field) 拿到该字段的并行数组
    const hps = mal.items(.hp);
    try std.testing.expectEqualSlices(u32, &.{ 10, 25, 3 }, hps);
    const names = mal.items(.name);
    try std.testing.expectEqualStrings("shield", names[1]);

    // get 返回值（不是指针），要改用 set
    try std.testing.expectEqual(@as(u32, 25), mal.get(1).hp);
    mal.set(1, .{ .name = "shield", .hp = 40, .price = 90 });
    try std.testing.expectEqual(@as(u32, 40), mal.get(1).hp);

    // swapRemove 返回 void，末尾补位
    mal.swapRemove(0);
    try std.testing.expectEqual(@as(usize, 2), mal.len);
    try std.testing.expectEqualStrings("potion", mal.get(0).name);

    // toOwnedSlice 没有分配器参数
    var mal2: std.MultiArrayList(Item) = .empty;
    try mal2.append(gpa, .{ .name = "x", .hp = 1, .price = 2 });
    var owned = mal2.toOwnedSlice();
    try std.testing.expectEqual(@as(usize, 1), owned.len);
    try std.testing.expectEqualStrings("x", owned.items(.name)[0]);
    owned.deinit(gpa);
}

test "12.10 排序：mem.sort 稳定 / sortUnstable 不稳定，ctx 传外部状态" {
    var a = [_]u32{ 42, 7, 19, 3, 88, 23 };
    std.mem.sort(u32, &a, {}, lessThanU32);
    try std.testing.expectEqualSlices(u32, &.{ 3, 7, 19, 23, 42, 88 }, &a);
    std.mem.sort(u32, &a, {}, greaterThanU32);
    try std.testing.expectEqualSlices(u32, &.{ 88, 42, 23, 19, 7, 3 }, &a);
    std.mem.sort(u32, &a, {}, std.sort.asc(u32));
    try std.testing.expectEqualSlices(u32, &.{ 3, 7, 19, 23, 42, 88 }, &a);
    std.mem.sortUnstable(u32, &a, {}, lessThanU32);
    try std.testing.expectEqualSlices(u32, &.{ 3, 7, 19, 23, 42, 88 }, &a);

    // 六个底层算法都对同一输入给同一结果
    var b1 = [_]u32{ 5, 2, 8, 1 };
    std.sort.insertion(u32, &b1, {}, lessThanU32);
    var b2 = [_]u32{ 5, 2, 8, 1 };
    std.sort.heap(u32, &b2, {}, lessThanU32);
    var b3 = [_]u32{ 5, 2, 8, 1 };
    std.sort.pdq(u32, &b3, {}, lessThanU32);
    var b4 = [_]u32{ 5, 2, 8, 1 };
    std.sort.block(u32, &b4, {}, lessThanU32);
    const want = [_]u32{ 1, 2, 5, 8 };
    try std.testing.expectEqualSlices(u32, &want, &b1);
    try std.testing.expectEqualSlices(u32, &want, &b2);
    try std.testing.expectEqualSlices(u32, &want, &b3);
    try std.testing.expectEqualSlices(u32, &want, &b4);

    // ctx：比较函数无捕获，外部状态从参数来
    const table = NameTable{ .names = &.{ "bob", "alice", "carol" } };
    var ids = [_]u32{ 0, 1, 2 };
    std.mem.sort(u32, &ids, table, NameTable.lessByName);
    try std.testing.expectEqualSlices(u32, &.{ 1, 0, 2 }, &ids);

    // ArrayList 没有 .sort / .swap
    try std.testing.expect(!@hasDecl(std.ArrayList(u32), "sort"));
    try std.testing.expect(!@hasDecl(std.ArrayList(u32), "swap"));
}

test "12.11 二分：binarySearch / lowerBound / upperBound / equalRange" {
    const sorted = [_]u32{ 1, 3, 5, 7, 9, 11 };
    const t7: u32 = 7;
    const t4: u32 = 4;
    const t6: u32 = 6;
    try std.testing.expectEqual(@as(?usize, 3), std.sort.binarySearch(u32, &sorted, t7, orderU32));
    try std.testing.expectEqual(@as(?usize, null), std.sort.binarySearch(u32, &sorted, t4, orderU32));
    try std.testing.expectEqual(@as(usize, 2), std.sort.lowerBound(u32, &sorted, t4, orderU32));
    try std.testing.expectEqual(@as(usize, 2), std.sort.upperBound(u32, &sorted, t4, orderU32));
    try std.testing.expectEqual(@as(usize, 3), std.sort.lowerBound(u32, &sorted, t6, orderU32));
    // partitionPoint 用 bool 谓词
    try std.testing.expectEqual(@as(usize, 2), std.sort.partitionPoint(u32, &sorted, t4, struct {
        fn isBelow(ctx: u32, item: u32) bool {
            return item < ctx;
        }
    }.isBelow));
    // equalRange
    const dup = [_]u32{ 1, 2, 2, 2, 5, 7 };
    const k2: u32 = 2;
    const range = std.sort.equalRange(u32, &dup, k2, orderU32);
    try std.testing.expectEqual(@as(usize, 1), range[0]);
    try std.testing.expectEqual(@as(usize, 4), range[1]);
    // min/max 返回可选（0.17 变化）
    try std.testing.expectEqual(@as(?u32, 1), std.sort.min(u32, &sorted, {}, lessThanU32));
    try std.testing.expectEqual(@as(?u32, 11), std.sort.max(u32, &sorted, {}, lessThanU32));
    try std.testing.expectEqual(@as(?usize, 0), std.sort.argMin(u32, &sorted, {}, lessThanU32));
    try std.testing.expectEqual(@as(?u32, null), std.sort.min(u32, &[_]u32{}, {}, lessThanU32));
    try std.testing.expect(std.sort.isSorted(u32, &sorted, {}, lessThanU32));
}

test "12.12 定容集合手写三件套：满了拒绝而非覆盖" {
    var f: FixedStack = .{};
    for ("zig!") |ch| try std.testing.expect(f.push(ch)); // 4 个字符正好塞满 4 槽
    try std.testing.expectEqual(@as(usize, 4), f.len);
    try std.testing.expectEqualStrings("zig!", f.items());
    try std.testing.expect(!f.push('?')); // 第 5 个被拒绝——不覆盖、不扩容
    try std.testing.expectEqual(@as(usize, 4), f.len); // 长度没变
    try std.testing.expectEqualStrings("zig!", f.items()); // 内容也没被覆盖
    // BoundedArray 确实不在 std 里
    try std.testing.expect(!@hasDecl(std, "BoundedArray"));
}

test "12.13 选型：ArrayListUnmanaged 同一性 + EnumSet 也是集合" {
    try std.testing.expectEqual(@typeName(std.ArrayList(u32)), @typeName(std.ArrayListUnmanaged(u32)));
    var mask: std.EnumSet(Flag) = .{};
    mask.insert(.a);
    mask.insert(.c);
    try std.testing.expect(mask.contains(.a));
    try std.testing.expect(!mask.contains(.b));
    try std.testing.expectEqual(@as(usize, 2), mask.count());
    // EnumSet 是位域：4 个成员只占 1 字节
    try std.testing.expectEqual(@as(usize, 1), @sizeOf(std.EnumSet(Flag)));
    // 0.17 移除的旧名
    try std.testing.expect(!@hasDecl(std, "ArrayHashMap"));
    try std.testing.expect(!@hasDecl(std, "AutoArrayHashMap"));
    try std.testing.expect(!@hasDecl(std, "BoundedArray"));
    // std 有 MultiArrayList（存在）
    try std.testing.expect(@hasDecl(std, "MultiArrayList"));
}
