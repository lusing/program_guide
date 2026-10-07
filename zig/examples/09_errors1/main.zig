//! 09 可选与错误 I：?T 的语义与解包、error set 与错误联合 E!T、try/catch、错误集组合与 @errorCast
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ═══ 9.1 ?T 的类型材料 ═══

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

/// 9.1/9.2 节共用：把任意可选的字节布局摊开看
fn dumpOptBytes(comptime label: []const u8, comptime T: type, v: T) void {
    // @sizeOf 只对"编译期已知类型"有意义，所以 T 是 comptime 形参
    const bytes = std.mem.asBytes(&v);
    std.debug.print("  {s: <12} @sizeOf={d:2}字节  字节 = {any}\n", .{ label, @sizeOf(T), bytes.* });
}

/// 9.1 节：可选的"零开销"到底零在哪
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
}

// ═══ 9.2 解包三件套 ═══

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

// ═══ 9.3 可选与"0 表示没有"的区别 ═══

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

// ═══ 9.4 错误集：编译期的错误名字集合 ═══

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

/// 打印一个错误联合类型的 payload 与错误集成员
fn dumpErrUnion(comptime label: []const u8, comptime EU: type) void {
    const eu = @typeInfo(EU).error_union;
    std.debug.print("  {s}：payload={s}，错误集 =", .{ label, @typeName(eu.payload) });
    if (@typeInfo(eu.error_set).error_set.error_names) |ns| {
        for (ns) |n| std.debug.print(" {s}", .{n});
    } else {
        std.debug.print(" anyerror");
    }
    std.debug.print("\n", .{});
}

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
    // ⚠️ 反方向不行：anyerror 的值装不进小集合
    //   const bad: ParseError = any_val;  → error: expected type 'error{Empty,NotDigit,TooLong}', found 'anyerror'
    //   note: global error set cannot cast into a smaller set
    std.debug.print("  错误没有 payload：不能写 error.NotDigit{{ pos = 3 }}\n", .{});
}

// ═══ 9.5 错误联合E!T ═══

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

// ═══ 9.6 try：向上传播 ═══

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

// ═══ 9.7 catch：就地消化 ═══

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

// ═══ 9.8 if/else |err| 与 while ... else |err| ═══

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

// ═══ 9.9 错误集的组合与强制转换 ═══

const NetworkError = error{ConnectionLost};
const GeneralError = error{ NotFound, PermissionDenied, DiskFull, ConnectionLost };

fn connectToServer(fail: bool) NetworkError!void {
    if (fail) return error.ConnectionLost;
}

fn performTask(fail: bool) GeneralError!void {
    try connectToServer(fail); // NetworkError 自动 coerce 成 GeneralError（子集 → 超集）
}

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
    std.debug.print("  ⚠️ 反方向（超集 → 子集）不行：\n", .{});
    std.debug.print("     fn f() NetworkError!void {{ try g() }}  // g 返回 GeneralError!void\n", .{});
    std.debug.print("     → error: expected type 'error{{ConnectionLost}}!void', found 'error{{...}}'\n", .{});
    std.debug.print("       note: 'error.NotFound' not a member of destination error set\n", .{});
    std.debug.print("  ⚠️ 0.17 的 `E || Payload` 造错误联合的写法已废：\n", .{});
    std.debug.print("     const X = E || Value;  → error: expected error set type, found 'main.Value'\n", .{});
    std.debug.print("     造错误联合用 E!T\n", .{});
}

// ═══ 9.10 @errorCast：把大集合窄化成小集合 ═══

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

fn errorCastDemo() void {
    std.debug.print("  小集合的值装进 anyerror 再取回来：", .{});
    _ = narrowWithErrorCast(true) catch |err| {
        std.debug.print("{s}\n", .{@errorName(err)});
    };
    std.debug.print("  anyerror 上运行时窄化：", .{});
    _ = narrowAnyToNarrow(true) catch |err| {
        std.debug.print("{s}\n", .{@errorName(err)});
    };
    std.debug.print("  窄化失败时不是错误，是 panic：thread ... panic: unexpected error code, found error.SomeoneElsesError\n", .{});
    std.debug.print("     （所以上面只在 flag=true 时调用 narrowAnyToNarrow；flag=false 会真的炸）\n", .{});
    std.debug.print("  ⚠️ 值在编译期已知时，@errorCast 越界是**编译错**：\n", .{});
    std.debug.print("     const small: NarrowError = @errorCast(error.SomeoneElsesError);\n", .{});
    std.debug.print("     → error: 'error.SomeoneElsesError' not a member of error set 'error{{X}}'\n", .{});
    std.debug.print("  ⚠️ catch 表达式里 @errorCast 没有结果类型：\n", .{});
    std.debug.print("     catch |err| @errorCast(err)  → error: @errorCast must have a known result type\n", .{});
    std.debug.print("       note: use @as to provide explicit result type\n", .{});
}

// ═══ 9.11 defer / errdefer 预览（10 章展开） ═══

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

// ═══ 9.12 ?T 与 !T 的分工与组合 ═══

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
    // orelse / catch 不能互换
    std.debug.print("  orelse 只能解可选（f() orelse 0 → expected optional type, found 'error{{...}}!u8'）\n", .{});
    std.debug.print("  catch 只能解错误联合（a catch 7 → expected error union type, found '?u8'）\n", .{});
}

pub fn main() !void {
    // ═══ 9.1 ?T：可能缺席的值与它的宽度 ═══
    begin("9.1 ?T");
    const hit = findFirst("zig-lang", '-');
    std.debug.print("  findFirst 返回类型 {s}（值域 = usize 全部值 ∪ {{null}}）\n", .{
        @typeName(@TypeOf(hit)),
    });
    std.debug.print("  findFirst(\"zig-lang\",'-') = {?}\n", .{hit});
    std.debug.print("  findFirst(\"zig\",'-')      = {?}\n", .{findFirst("zig", '-')});
    optionalWidthReport();
    std.debug.print("  ?T 的 child（0.17 改名了：@typeInfo(?T).optional.**child**，不是 .payload）= {s}\n", .{
        @typeName(@typeInfo(?u16).optional.child),
    });
    end("9.1 ?T");

    // ═══ 9.2 解包三件套：if 捕获 / orelse / .? ═══
    begin("9.2 解包三件套");
    if (findFirst("zig-lang", '-')) |i| {
        std.debug.print("  ① if 捕获：有值，'-' 在下标 {d}\n", .{i});
    } else {
        std.debug.print("  ① if 捕获：没找到\n", .{});
    }
    if (findFirst("zig", '-')) |i| {
        std.debug.print("  ① if 捕获：有值，'-' 在下标 {d}\n", .{i});
    } else {
        std.debug.print("  ① if 捕获：没找到（走了 else 分支）\n", .{});
    }
    orelseBlockDemo();
    unwrapDemo();
    std.debug.print("  ⚠️ 0.17 **没有可选链 `?.`**：o.a?.len 报error: expected ';' after statement\n", .{});
    std.debug.print("     （`?.` 是 0.14 引入的实验性语法，0.17 已移除；多层可选请逐层 orelse / if 捕获）\n", .{});
    end("9.2 解包三件套");

    // ═══ 9.3 可选 vs "0 表示没有" ═══
    begin("9.3 可选与 0");
    zeroVersusNullDemo();
    end("9.3 可选与 0");

    // ═══ 9.4 错误集：编译期的名字集合 ═══
    begin("9.4 错误集");
    errorSetBasics();
    end("9.4 错误集");

    // ═══ 9.5 错误联合 E!T ═══
    begin("9.5 错误联合");
    errorUnionBasics();
    end("9.5 错误联合");

    // ═══ 9.6 try 传播链 ═══
    begin("9.6 try");
    tryDemo();
    end("9.6 try");

    // ═══ 9.7 catch就地消化 ═══
    begin("9.7 catch");
    catchDemo();
    diagnoseDemo();
    end("9.7 catch");

    // ═══ 9.8 if/else |err| 与 while ... else |err| ═══
    begin("9.8 if/while 双分支");
    ifElseOnErrorUnion();
    whileElseDemo();
    end("9.8 if/while 双分支");

    // ═══ 9.9 错误集组合与强制转换 ═══
    begin("9.9 错误集组合");
    errorSetCombination();
    end("9.9 错误集组合");

    // ═══ 9.10 @errorCast ═══
    begin("9.10 @errorCast");
    errorCastDemo();
    end("9.10 @errorCast");

    // ═══ 9.11 defer / errdefer ═══
    begin("9.11 defer/errdefer");
    try deferDemo();
    end("9.11 defer/errdefer");

    // ═══ 9.12 ?T 与 !T 的分工 ═══
    begin("9.12 分工与组合");
    std.debug.print("  ?T：'没有'是正常业务（字典里没这个键）\n", .{});
    std.debug.print("  !T：'失败'是异常路径（文件打不开、格式不对）\n", .{});
    divisionAndCombination();
    end("9.12 分工与组合");

    std.debug.print("自检通过\n", .{});
}

test "9.1 ?T 的值域与宽度" {
    try std.testing.expectEqual(@as(?usize, 3), findFirst("zig-lang", '-'));
    try std.testing.expectEqual(@as(?usize, null), findFirst("zig", '-'));
    try std.testing.expectEqual(@as(?usize, 0), findFirst("zig", 'z'));
    // 指针族：零开销
    try std.testing.expectEqual(@sizeOf(*u8), @sizeOf(?*u8));
    try std.testing.expectEqual(@sizeOf([]const u8), @sizeOf(?[]const u8));
    // 标量族：要加标记字节
    try std.testing.expect(@sizeOf(?u8) > @sizeOf(u8));
    try std.testing.expectEqual(@sizeOf(u8) + 1, @sizeOf(?u8));
    try std.testing.expectEqual(@sizeOf(u64) + @sizeOf(u64), @sizeOf(?u64));
    // 0.17：@typeInfo(?T).optional.child（老教程写 .optional.payload）
    try std.testing.expectEqualStrings("u16", @typeName(@typeInfo(?u16).optional.child));
}

test "9.2 解包三件套" {
    try std.testing.expectEqual(@as(usize, 999), findFirst("zig", '-') orelse 999);
    try std.testing.expectEqual(@as(usize, 0), findFirst("zig", 'z').?);
    // if 捕获两个分支都要走到
    var seen_value = false;
    if (findFirst("zig", 'g')) |i| {
        seen_value = (i == 2);
    }
    try std.testing.expect(seen_value);
    var seen_null = false;
    if (findFirst("zig", 'q')) |_| {
        seen_null = false;
    } else {
        seen_null = true;
    }
    try std.testing.expect(seen_null);
    // 常量折叠：.? 在编译期就能定值
    const folded = comptime findFirst("Zig", 'Z').?;
    try std.testing.expectEqual(@as(usize, 0), folded);
}

test "9.3 null 不等于 0" {
    const nul: ?u8 = null;
    const zero: ?u8 = 0;
    try std.testing.expect(nul != zero);
    try std.testing.expect(zero == 0);
    try std.testing.expect(!(zero == null));
    // 命中首字节（下标 0）与没找到是两件事
    try std.testing.expectEqual(@as(?u8, 0), lookupKey("Zig", 'Z'));
    try std.testing.expectEqual(@as(?u8, null), lookupKey("zig", 'Q'));
    // 哨兵写法：调用方得自己记住 -1
    try std.testing.expectEqual(@as(i64, -1), indexOrMinusOne("zig", 'q'));
    try std.testing.expectEqual(@as(i64, 0), indexOrMinusOne("zig", 'z'));
}

test "9.4 错误集反射（0.17 的 error_names）" {
    // 元素**本身就是名字**（0.16 是 { name, value } 结构体）
    const info = @typeInfo(ParseError).error_set;
    const names = info.error_names.?; // 可空，得先if 或 .?
    try std.testing.expectEqual(@as(usize, 3), names.len);
    try std.testing.expectEqualStrings("Empty", names[0]);
    try std.testing.expectEqualStrings("NotDigit", names[1]);
    try std.testing.expectEqualStrings("TooLong", names[2]);
    // 空错误集是**空切片**（error_names = {}），不是 null
    try std.testing.expectEqual(@as(usize, 0), @typeInfo(error{}).error_set.error_names.?.len);
    // anyerror 才是 null
    try std.testing.expect(@typeInfo(anyerror).error_set.error_names == null);
    // 错误值 = 全局编号 + 名字
    try std.testing.expectEqualStrings("NotDigit", @errorName(error.NotDigit));
    try std.testing.expect(@intFromError(error.NotDigit) != @intFromError(error.Empty));
    // 小集合的值可以装进 anyerror，反方向不行
    const any: anyerror = error.NotDigit;
    try std.testing.expectEqualStrings("NotDigit", @errorName(any));
}

test "9.5 推断错误集会传染" {
    // parseLen 推断出的集合包含 ParseError 的全部三个成员
    const inferred = @typeInfo(@typeInfo(@TypeOf(parseLen)).@"fn".return_type.?).error_union.error_set;
    const names = @typeInfo(inferred).error_set.error_names.?;
    try std.testing.expectEqual(@as(usize, 3), names.len);
    var found_all = true;
    for ([_][:0]const u8{ "Empty", "NotDigit", "TooLong" }) |want| {
        var hit = false;
        for (names) |n| {
            if (std.mem.eql(u8, n, want)) hit = true;
        }
        if (!hit) found_all = false;
    }
    try std.testing.expect(found_all);
    // 推断集合会一路传染：parseLenTwice 的集合与 parseLen 相同
    const deeper = @typeInfo(@typeInfo(@TypeOf(parseLenTwice)).@"fn".return_type.?).error_union.error_set;
    try std.testing.expectEqual(
        @typeInfo(inferred).error_set.error_names.?.len,
        @typeInfo(deeper).error_set.error_names.?.len,
    );
}

test "9.6 try 传播" {
    try std.testing.expectEqual(@as(u8, 88), try parseScore("88"));
    try std.testing.expectError(error.Empty, parseScore(""));
    try std.testing.expectError(error.NotDigit, parseScore("8x"));
    try std.testing.expectError(error.TooLong, parseScore("1234"));
    // try 把错误原样往上带（不改名、不包装）
    try std.testing.expectError(error.NotDigit, reportScore("95x"));
    try std.testing.expectError(error.TooLong, reportScore("1234"));
}

test "9.7 catch 三形态与错误映射" {
    // ① 值形态
    try std.testing.expectEqual(@as(u8, 88), parseScore("88") catch 0);
    try std.testing.expectEqual(@as(u8, 0), parseScore("8x8") catch 0);
    // ② |err| 形态：后备值由错误算出
    const graded = parseScore("") catch |err| switch (err) {
        error.Empty => 60,
        error.NotDigit => 0,
        error.TooLong => 100,
    };
    try std.testing.expectEqual(@as(u8, 60), graded);
    // ③ catch unreachable：真失败就panic，所以这里必须成功
    try std.testing.expectEqual(@as(u8, 42), parseScore("42") catch unreachable);
    // 应用层映射：退出码
    try std.testing.expectEqual(@as(u8, 2), diagnose(error.Empty).code);
    try std.testing.expectEqual(@as(u8, 4), diagnose(error.TooLong).code);
    try std.testing.expectEqualStrings("请输入分数，不能留空", diagnose(error.Empty).msg);
    // 0.17 字符串拼接是 ++
    try std.testing.expectEqualStrings("分数已记录", "分数" ++ "已记录");
}

test "9.8 while ... else |err| 与 switch 的禁区" {
    // 错误终止循环，且能报出"已经处理了多少"
    var r: ChunkReader = .{ .data = &[_]u32{ 10, 20, 0, 40 } };
    var sum: u32 = 0;
    var terminated: ChunkError = error.Truncated;
    while (r.next()) |chunk| {
        sum += chunk;
    } else |err| {
        terminated = err;
    }
    try std.testing.expectEqual(error.ChecksumMismatch, terminated);
    try std.testing.expectEqual(@as(u32, 30), sum);
    try std.testing.expectEqual(@as(usize, 3), r.pos); // 出错那个也读了位置
    // 正常耗尽
    var r2: ChunkReader = .{ .data = &[_]u32{ 1, 2, 3 } };
    var n: usize = 0;
    while (r2.next()) |_| {
        n += 1;
    } else |err| {
        try std.testing.expectEqual(error.Truncated, err);
    }
    try std.testing.expectEqual(@as(usize, 3), n);
    // if/else |err| 同构
    if (parseScore("")) |v| {
        _ = v;
        return error.TestUnexpectedResult;
    } else |err| {
        try std.testing.expectEqual(error.Empty, err);
    }
}

test "9.9 错误集并集与强制转换" {
    // 子集 → 超集：try 直接过
    try performTask(false);
    try std.testing.expectError(error.ConnectionLost, performTask(true));
    // `||` 在 0.17 是错误集并集
    const Mixed = ParseError || error{Boom};
    const ns = @typeInfo(Mixed).error_set.error_names.?;
    try std.testing.expectEqual(@as(usize, 4), ns.len);
    // 并集里每个成员都能返回，两边都能装
    try std.testing.expectError(error.Boom, @as(Mixed!void, error.Boom));
    try std.testing.expectError(error.NotDigit, @as(Mixed!void, error.NotDigit));
    try std.testing.expectError(error.TooLong, @as(Mixed!void, error.TooLong));
}

test "9.10 @errorCast 窄化" {
    try std.testing.expectError(error.X, narrowWithErrorCast(true));
    // 运行时窄化成功的情况
    try std.testing.expectError(error.X, narrowAnyToNarrow(true));
    // 小集合 → anyerror → 拿回来，名字不变
    const any: anyerror = error.X;
    try std.testing.expectEqual(error.X, @as(NarrowError, @errorCast(any)));
}

test "9.11 defer 与 errdefer" {
    var ok_run: TxnTrace = .{ .defer_ = false, .errd = false };
    try std.testing.expectEqual(@as(u8, 7), try transact(false, &ok_run));
    try std.testing.expect(ok_run.defer_); // 成功：defer 跑了
    try std.testing.expect(!ok_run.errd); // 成功：errdefer 没跑
    var bad_run: TxnTrace = .{ .defer_ = false, .errd = false };
    try std.testing.expectError(error.Rejected, transact(true, &bad_run));
    try std.testing.expect(bad_run.defer_); // 失败：defer 也跑
    try std.testing.expect(bad_run.errd); // 失败：errdefer 才跑
}

test "9.12 ?E!T 三态组合" {
    const E = ParseError;
    const samples = [_]?E!u8{
        null,
        @as(E!u8, error.NotDigit),
        @as(E!u8, 5),
    };
    try std.testing.expectEqual(@as(usize, 3), samples.len);
    // ① 缺席
    try std.testing.expectEqual(@as(?E!u8, null), samples[0]);
    // ② 错误：orelse 解完还是错误联合，交给 catch
    try std.testing.expectError(error.NotDigit, samples[1].?);
    // ③ 值
    try std.testing.expectEqual(@as(u8, 5), samples[2].?);
    // 大小：? 在外、! 在内，都比裸u8 大
    try std.testing.expect(@sizeOf(?E!u8) > @sizeOf(u8));
}
