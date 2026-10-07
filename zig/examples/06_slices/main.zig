//! 06 数组、切片与字符串：[N]T 的长度进类型、[]T胖指针、哨兵 [:0]、UTF-8 字节语义、指针三兄弟
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

/// 6.2 节的 `repeat()`：0.17 起 `**` 运算符已被移除（`"ab" ** 3` 现在被解析成两个 `*`，
/// 直接编译错；`[_]T{x} ** n` 重复填充语法也没了，改用 `@splat(x)`）。
/// 这个函数是替代方案之一，也是 comptime 最典型的用法：参数全comptime、函数体被编译器
/// 真正执行一遍、结果烘进二进制——运行期没有一行代码。
fn repeat(comptime T: type, comptime n: usize, v: T) [n]T {
    var out: [n]T = undefined;
    for (&out) |*e| e.* = v;
    return out;
}

/// 6.2 节的 `repeatStr()`：字符串重复版，返回 `*const [N:0]u8`（哨兵数组指针）。
///
/// ⚠️ 两个实测出来的关键点（0.17.0/x86_64-macos）：
/// 1. 局部 `const buf` 的地址要return 出去，必须让整个初始化块在**编译期**求值
///    （写 `comptime blk: { ... }`）。只写普通 `blk:` 时，`buf` 是运行期栈变量，
///    函数返回后地址悬空——编译器**不报错**，实测打印出乱码。
/// 2. 哨兵槽（第 `n*s.len` 字节）必须真的是 0。用 `@splat(0)` 初始化最省事；
///    若用 `undefined` 再靠循环填，前`n*s.len` 个字节对了、哨兵槽是脏的。
fn repeatStr(comptime n: usize, comptime s: []const u8) *const [n * s.len:0]u8 {
    const buf: [n * s.len:0]u8 = comptime blk: {
        var b: [n * s.len:0]u8 = @splat(0); // 0.17 替代 `[_]u8{0} ** n`
        var k: usize = 0;
        while (k < n * s.len) : (k += 1) b[k] = s[k % s.len];
        break :blk b;
    };
    return &buf;
}

/// 6.9 节：函数参数默认收切片。`[]const T` 同时接受数组、切片、哨兵切片。
fn sum(items: []const i32) i32 {
    var total: i32 = 0;
    for (items) |v| total += v;
    return total;
}

/// 6.9 节：只想"读一个元素"时用单项指针，语义最明确（调用方必须保证它指向一个合法元素）。
fn first(items: []const i32) i32 {
    return items[0];
}

/// 6.10 节：统计 UTF-8 字符数——必须走 std.unicode，不能用 `s.len`。
fn codepointCount(s: []const u8) !usize {
    const view = try std.unicode.Utf8View.init(s);
    var it = view.iterator();
    var n: usize = 0;
    while (it.nextCodepoint()) |_| n += 1;
    return n;
}

pub fn main(init: std.process.Init) !void {
    // ═══ 6.1 数组 [N]T：长度是类型的一部分 ═══
    begin("6.1");
    const arr = [_]i32{ 10, 20, 30, 40, 50 }; // [_] 让编译器数个数，等价 [5]i32
    var copy = arr; // 数组是**值**：赋值 = 整块拷贝
    copy[0] = -1;
    std.debug.print("arr={any}  copy={any}  （改 copy 不影响 arr）\n", .{ arr, copy });
    std.debug.print("arr.len={d}  @sizeOf={d}  类型={s}\n", .{
        arr.len, @sizeOf(@TypeOf(arr)), @typeName(@TypeOf(arr)),
    });
    // [5]i32 与 [6]i32 是**两个不同的类型**，不能互换、不能传同一个函数
    const six = [_]i32{ 1, 2, 3, 4, 5, 6 };
    std.debug.print("arr 与 six 同类型？{}（长度进类型，必然false）\n", .{
        @TypeOf(arr) == @TypeOf(six),
    });
    // 数组不能直接传给收[]const T 的函数：sum(arr) 编译错（length comptime 6 doesn't match）
    // ——但 &arr / arr[0..] 可以。数组 → 数组指针 → 切片是自动的两步。
    const as_slice: []const i32 = &arr;
    std.debug.print("&arr 退化成切片后类型={s} len={d} sum={d}\n", .{
        @typeName(@TypeOf(as_slice)), as_slice.len, sum(as_slice),
    });
    // 嵌套数组：数组的数组，仍然是一块连续内存
    const mat = [2][3]i32{ .{ 1, 2, 3 }, .{ 4, 5, 6 } };
    std.debug.print("mat[1][2]={d}  @sizeOf={d}（[2][3]i32 是 24 字节连续块）\n", .{
        mat[1][2], @sizeOf(@TypeOf(mat)),
    });
    end("6.1");

    // ═══ 6.2 编译期数组：++ 拼接、repeat 重复、@splat、多维 ═══
    begin("6.2");
    const part_one = [_]i32{ 1, 2, 3, 4 };
    const part_two = [_]i32{ 5, 6, 7, 8 };
    const all = part_one ++ part_two; // 编译期拼接（0.17 保留 ++）
    std.debug.print("part_one ++ part_two = {any}  类型={s}\n", .{ all, @typeName(@TypeOf(all)) });
    // ⚠️ 0.17 移除了 `**`："ab" ** 3 会报 binary operator '*' has whitespace on one side。
    const pattern = "ab" ++ "ab" ++ "ab"; // 等价替代
    const sp: [4]u8 = @splat(7); // 数组重复填充：0.17 替代 [_]u8{0} ** 4
    std.debug.print("\"ab\"++\"ab\"++\"ab\" = {s}（类型 {s}）\n", .{ pattern, @typeName(@TypeOf(pattern)) });
    std.debug.print("@splat(7) : [4]u8 = {any}\n", .{sp});
    const zeroes = repeat(u16, 4, 0); // 自己写的 comptime 重复
    std.debug.print("repeat(u16, 4, 0) = {any}  类型={s}\n", .{ zeroes, @typeName(@TypeOf(zeroes)) });
    const ruled = repeatStr(3, "ab"); // 字符串重复版
    std.debug.print("repeatStr(3, \"ab\") = {s}  类型={s}\n", .{ ruled, @typeName(@TypeOf(ruled)) });
    const zh2 = repeatStr(2, "中"); // 多字节字符重复也正确（按字节切，s.len 已是字节数）
    std.debug.print("repeatStr(2, \"中\") = {s}  .len={d}（字节数，不是字符数）\n", .{ zh2, zh2.len });
    end("6.2");

    // ═══ 6.3 哨兵数组 [N:0]T 与哨兵切片 [:0]T ═══
    begin("6.3");
    const sent = [_:0]u8{ 1, 2, 3, 4 }; // 声明 4 个元素 + 1 个哨兵槽
    std.debug.print("哨兵数组 类型={s}  len={d}  但 @sizeOf={d}（N+1 个槽）\n", .{
        @typeName(@TypeOf(sent)), sent.len, @sizeOf(@TypeOf(sent)),
    });
    std.debug.print("sent[3]={d}  sent[4]={d}（len 处的哨兵，可以安全读）\n", .{ sent[3], sent[4] });
    // 字面量天生就是哨兵数组指针
    const lit = "Zig";
    std.debug.print("字面量 类型={s}  @sizeOf={d}（3 字节 + 1 哨兵，末尾对齐到 4）\n", .{
        @typeName(@TypeOf(lit)), @sizeOf(@TypeOf(lit)),
    });
    std.debug.print("lit.len={d}  lit[3]={d}\n", .{ lit.len, lit[3] });
    //哨兵切片：长度在运行期，末尾哨兵由类型保证
    const cs: [:0]const u8 = "Elixir";
    std.debug.print("哨兵切片 类型={s}  len={d}  cs[6]={d}\n", .{
        @typeName(@TypeOf(cs)), cs.len, cs[cs.len],
    });
    // 运行时构造：切一个带哨兵的子切片`s[a..b :c]`
    var buf = [_]u8{ 'h', 'e', 'l', 'l', 'o', 0, 0 };
    const sub: [:0]u8 = buf[0..5 :0]; // 第 5 字节确实是 0，才允许这么切
    std.debug.print("buf[0..5 :0] = {s}  len={d}  sub[5]={d}\n", .{ sub, sub.len, sub[sub.len] });
    // ⚠️ 声称的哨兵位置不是 0 会被抓住：
    //   buf[0..3 :0]                  → error: value in memory does not match slice sentinel
    //                                   note: expected '0', found '108'
    std.debug.print("buf[3]={d}不是0，所以 buf[0..3 :0] 编译期就被拒绝\n", .{buf[3]});
    // 哨兵切片 → 哨兵数组指针（长度必须编译期已知）
    const sap = sub[0..5 :0];
    std.debug.print("哨兵切片再取地址 类型={s}（与哨兵切片不是一回事）\n", .{
        @typeName(@TypeOf(sap)),
    });
    end("6.3");

    // ═══ 6.4 切片 = 胖指针（指针 + 长度）═══
    begin("6.4");
    std.debug.print("@sizeOf: *u8={d}  [*]u8={d}  []u8={d}  [:0]u8={d}  [5]u8={d}  usize={d}\n", .{
        @sizeOf(*u8), @sizeOf([*]u8), @sizeOf([]u8), @sizeOf([:0]u8), @sizeOf([5]u8), @sizeOf(usize),
    });
    std.debug.print("→ 切片 {d} 字节 = 指针({d}) + 长度({d})，64 位机器上正好两个机器字\n", .{
        @sizeOf([]u8), @sizeOf(usize), @sizeOf(usize),
    });
    var stones = [_]u16{ 42, 17, 93, 58, 11, 99 };
    const full: []u16 = &stones; // 数组整体退化成切片（不拷贝）
    // 不打印 full.ptr 的绝对地址（每次运行都不同，ASLR）——只打印可复现的关系
    std.debug.print("full.len={d}  full.ptr 与 &stones 同一地址？{}（切片不拷贝内存）\n", .{
        full.len, full.ptr == &stones,
    });
    full[0] = 43; // 通过切片改数组
    std.debug.print("full[0]=43 后 stones[0]={d}（同一块内存）\n", .{stones[0]});
    // 切片只是"视图"：它自己不能被索引到长度之外，也不管底层活多久
    const mid = full[1..3];
    std.debug.print("full[1..3] = {any}  len={d}  类型={s}\n", .{
        mid, mid.len, @typeName(@TypeOf(mid)),
    });
    std.debug.print("mid.ptr 偏移量 = {d} 字节（相对 full.ptr）\n", .{
        @intFromPtr(mid.ptr) - @intFromPtr(full.ptr),
    });
    end("6.4");

    // ═══ 6.5 子切片：编译期边界 vs 运行期边界 ═══
    begin("6.5");
    const stones2 = [_]u16{ 42, 17, 93, 58, 11, 99 };
    // 三种写法
    const left = stones2[0..2]; // s[a..b]：左闭右开
    const right = stones2[4..]; // s[a..]：从a 到尾
    const all_of_it = stones2[0..]; // s[a..] 里 a=0
    std.debug.print("stones2[0..2] = {any}  类型={s}（编译期已知 → **数组指针**）\n", .{
        left, @typeName(@TypeOf(left)),
    });
    std.debug.print("stones2[4..]  = {any}  类型={s}（长度 = 6-4 编译期可知，也是数组指针）\n", .{
        right, @typeName(@TypeOf(right)),
    });
    std.debug.print("stones2[0..]  = {any}  类型={s}\n", .{ all_of_it, @typeName(@TypeOf(all_of_it)) });
    // ⚠️ 这是本节最容易踩的坑：边界是编译期字面量时，结果**不是切片而是数组指针**。
    //好处是长度进类型、能当定长缓冲区用；坏处是有时不能直接传 []const T。
    std.debug.print("注意类型差别：{s} vs {s}\n", .{
        @typeName(@TypeOf(left)), @typeName(@TypeOf(full)),
    });
    // 运行期边界 → 真切片
    var arr_rt = [_]u8{ 10, 20, 30, 40, 50 };
    var lo: usize = 1;
    var hi: usize = 4;
    _ = &lo; // 告诉编译器"我假装不知道这个值"
    _ = &hi;
    const rt = arr_rt[lo..hi];
    std.debug.print("运行期 arr_rt[lo..hi] = {any}  len={d}  类型={s}\n", .{
        rt, rt.len, @typeName(@TypeOf(rt)),
    });
    // 想在运行期切、但想要数组指针：长度必须写死
    const fixed3 = arr_rt[1..4];
    std.debug.print("arr_rt[1..4] = {any}  类型={s}\n", .{ fixed3, @typeName(@TypeOf(fixed3)) });
    // 越界是运行期 panic，不是静默越界
    std.debug.print("rt.len={d}，写 rt[{d}] 会 panic（index out of bounds）——本例不触发\n", .{
        rt.len, rt.len,
    });
    end("6.5");

    // ═══ 6.6 切片 ↔ 数组 ↔ 数组指针 互转 ═══
    begin("6.6");
    var nums = [_]i32{ 1, 2, 3, 4, 5, 6 };
    // 数组 → 数组指针
    const ap: *[6]i32 = &nums;
    // 数组指针 → 切片（长度从指针类型里来，自动）
    const ap_to_slice: []i32 = ap;
    std.debug.print("&nums : *[6]i32（{d} 字节）→ 切片 []i32（{d} 字节），len={d}\n", .{
        @sizeOf(@TypeOf(ap)), @sizeOf([]i32), ap_to_slice.len,
    });
    // 数组指针切出更小的数组指针（长度编译期已知）
    const head3: *[3]i32 = ap[0..3];
    std.debug.print("ap[0..3] = {any}  类型={s}\n", .{ head3.*, @typeName(@TypeOf(head3)) });
    // 切片 → 数组指针：长度必须对得上
    const back: *[3]i32 = ap_to_slice[0..3];
    std.debug.print("切片也能拿回数组指针：{any}\n", .{back.*});
    // 数组 → 切片（一步到位，不需要先取地址）
    const direct: []const i32 = &nums;
    std.debug.print("直接 &nums 给切片：len={d} sum={d}\n", .{ direct.len, sum(direct) });
    // const 数组也能取切片（只读）
    const carr = [_]i32{ 9, 8, 7 };
    const csl: []const i32 = &carr;
    std.debug.print("const 数组 → []const i32：len={d} sum={d}\n", .{ csl.len, sum(csl) });
    // 多维数组不能一步摊平成 []u8：内层元素是 [3]u8 不是 u8
    //   const flat: []const u8 = &mat;  → error: pointer type child '[3]u8' cannot cast into 'u8'
    const mat2 = [2][3]u8{ .{ 1, 2, 3 }, .{ 4, 5, 6 } };
    const row = mat2[0]; // 先取内层，得到 [3]u8（值拷贝）
    const row_slice: []const u8 = &mat2[0]; // 或直接 &mat2[0]
    std.debug.print("mat2[0] 类型={s} len={d}；&mat2[0] 切片 len={d} {any}\n", .{
        @typeName(@TypeOf(row)), row.len, row_slice.len, row_slice,
    });
    std.debug.print("整块按字节看：std.mem.sliceAsBytes(&mat2).len={d}\n", .{
        std.mem.sliceAsBytes(&mat2).len,
    });
    end("6.6");

    // ═══ 6.7 指针三兄弟 *T / [*]T / []T ═══
    begin("6.7");
    var x: u32 = 42;
    const single: *u32 = &x; // 单项指针：天生指向 1 个元素
    single.* += 1; // 解引用写回
    std.debug.print("*T：single.*={d}（改了 x，x={d}）\n", .{ single.*, x });
    // 多项指针：只有起点，没有长度
    var quad = [_]u32{ 10, 20, 30, 40 };
    const many: [*]u32 = &quad;
    std.debug.print("[*]T：many[3]={d}  @sizeOf={d}（只有一个地址，长度全靠你记）\n", .{
        many[3], @sizeOf(@TypeOf(many)),
    });
    std.debug.print("[*]T 能做指针算术：(many+2)[0]={d}\n", .{(many + 2)[0]});
    // ⚠️ 单项指针与切片都**不允许**指针算术：
    //   const bad = single + 1;  → error: pointer arithmetic not allowed on single-item pointers
    //   const bad2 = slice + 1;  → error: pointer arithmetic not allowed on slice
    std.debug.print("只有 [*]T 允许 + / -；*T 和 []T 都不允许（编译器直接拒绝）\n", .{});
    // 哨兵多项指针：靠末尾 0 找尾，就是C 的 char*
    var zbuf: [4:0]u8 = .{ 1, 2, 0, 0 };
    const cptr: [*:0]u8 = &zbuf;
    std.debug.print("[*:0]u8：std.mem.len={d}  std.mem.span 读到={d} 个字节\n", .{
        std.mem.len(cptr), std.mem.span(cptr).len,
    });
    // ⚠️ std.mem.span 只吃**哨兵指针**，不吃哨兵切片：
    //   std.mem.span(cs)   → error: invalid type given to std.mem.span: [:0]const u8
    // 要写 std.mem.span(cs.ptr)。
    std.debug.print("span 的参数必须是哨兵**指针**（切片要写 .ptr）\n", .{});
    end("6.7");

    // ═══ 6.8 字符串的真相：没有 string 类型 ═══
    begin("6.8");
    const msg = "你好，Zig";
    std.debug.print("字面量 类型={s}  @sizeOf={d}\n", .{
        @typeName(@TypeOf(msg)), @sizeOf(@TypeOf(msg)),
    });
    const s: []const u8 = msg; // 退化成普通切片
    std.debug.print("退化后 类型={s}  len={d}（**字节数**：你好 6 字节 + 逗号 3 + Zig 3 = 12）\n", .{
        @typeName(@TypeOf(s)), s.len,
    });
    std.debug.print("std.unicode 数出来的字符数 = {d}\n", .{try codepointCount(s)});
    // 逐字节看 UTF-8
    std.debug.print("字节展开：", .{});
    for (s) |b| std.debug.print("{x:0>2} ", .{b});
    std.debug.print("\n", .{});
    // {s} 与 {any} 的分工
    std.debug.print("{{s}}（当字符串直出）= {s}\n", .{s});
    std.debug.print("{{any}}（当字节序列打印）= {any}\n", .{s});
    // 纯 ASCII 的"巧合"：字节数 == 字符数
    const en = "hello";
    std.debug.print("纯 ASCII \"hello\"：len={d}，字符数也是 {d}，第 0 字节是 '{c}'\n", .{
        en.len, try codepointCount(en), en[0],
    });
    // Zig 字符串**没有** NUL 终止概念
    std.debug.print("en.len={d}，读 en[5] 是越界访问（不是读到 0）——本例不触发\n", .{en.len});
    // 字符串字面量是只读的
    std.debug.print("msg 的元素类型是 const u8：写 msg[0]='x' 编译错（cannot assign to constant）\n", .{});
    end("6.8");

    // ═══ 6.9 UTF-8 边界：不要按字节切断多字节字符 ═══
    begin("6.9");
    const zh = "中文abc";
    std.debug.print("zh=\"{s}\"  .len={d}  字符数={d}\n", .{ zh, zh.len, try codepointCount(zh) });
    //按字节随便切，会切出半个汉字
    const cut4 = zh[0..4]; // "中" 是 3 字节，"文" 是 3 字节 —— 第 4 字节是"文"的第 1 字节
    std.debug.print("zh[0..4] 切在多字节字符中间，合法吗={}\n", .{std.unicode.utf8ValidateSlice(cut4)});
    const cut6 = zh[0..6]; // 正好两个完整汉字
    std.debug.print("zh[0..6] 切在字符边界上，合法吗={} 内容=\"{s}\"\n", .{
        std.unicode.utf8ValidateSlice(cut6), cut6,
    });
    // ⚠️ 打印非法 UTF-8 不会 panic，但会输出替换字符 U+FFFD——静默的数据损坏
    std.debug.print("直接打印切坏的字节：\"{s}\"（非法字节被替换成 U+FFFD，不报错）\n", .{cut4});
    // 正确做法 1：按码点迭代
    const view = try std.unicode.Utf8View.init(zh);
    var it = view.iterator();
    std.debug.print("按码点迭代：", .{});
    while (it.nextCodepoint()) |cp| {
        std.debug.print("[U+{X:0>4} {d}字节] ", .{ cp, std.unicode.utf8CodepointSequenceLength(cp) catch 1 });
    }
    std.debug.print("\n", .{});
    // 正确做法 2：单个码点的字节长度由首字节决定（同一段字节，两个不同切法）
    const mixed = "中a"; // 3 字节 + 1 字节
    const lead_cn = mixed[0];
    const lead_ascii = mixed[3];
    std.debug.print("mixed=\"{s}\"：首字节 0x{x:0>2} → {d} 字节；0x{x:0>2} → {d} 字节\n", .{
        mixed,      lead_cn,                                            try std.unicode.utf8ByteSequenceLength(lead_cn),
        lead_ascii, try std.unicode.utf8ByteSequenceLength(lead_ascii),
    });
    // 正确做法 3：解码单个码点
    const you = try std.unicode.utf8Decode("你");
    std.debug.print("utf8Decode(\"你\") = U+{X:0>4}（占 {d} 字节）\n", .{ you, try std.unicode.utf8CodepointSequenceLength(you) });
    end("6.9");

    // ═══ 6.10 可变 vs 只读：[]T vs []const T ═══
    begin("6.10");
    var letters = [_]u8{ 'a', 'b', 'c', 'd' };
    const mutable: []u8 = letters[0..]; // 可写
    mutable[0] = 'A';
    const readonly: []const u8 = mutable; // 只读视图（free，随时可要）
    std.debug.print("改 mutable[0]='A' 后 letters={any}；readonly={s}（同一个内存）\n", .{ letters, readonly });
    // readonly 视图不能写
    //   readonly[1] = 'X';  → error: cannot store into const slice
    std.debug.print("readonly[1]='X' 编译错（cannot store into const slice）\n", .{});
    // const 切片变量 ≠ 元素只读：const 修饰的是**绑定**，不是元素
    const still_mutable: []u8 = letters[0..];
    still_mutable[1] = 'B'; // 合法：元素类型是 u8，没有 const
    std.debug.print("const 绑定的切片仍能改元素：letters={any}\n", .{letters});
    // 可变切片可以隐式转只读切片（[]u8 → []const u8 是宽化，放行）
    const as_ro: []const u8 = letters[0..];
    std.debug.print("[]u8 隐式转 []const u8：len={d} 首字节='{c}'\n", .{ as_ro.len, as_ro[0] });
    // 遍历：值拷贝 vs 指针捕获
    var walk = [_]i32{ 1, 2, 3 };
    for (walk) |v| std.debug.print("{d} ", .{v}); // v 是拷贝
    std.debug.print("（值拷贝）\n", .{});
    // ⚠️ 对**数组**用 |*v| 要先取地址：for (walk) |*v| → error: pointer capture of non pointer type '[3]i32'
    for (&walk) |*p| p.* *= 100;
    std.debug.print("for (&walk) |*p| p.* *= 100 后 walk={any}\n", .{walk});
    // 对**切片**可以直接指针捕获
    for (walk[0..]) |*p| p.* += 1;
    std.debug.print("for (walk[0..]) |*p| p.* += 1 后 walk={any}\n", .{walk});
    end("6.10");

    // ═══ 6.11 切片作为函数参数 + std.mem 常用工具 ═══
    begin("6.11");
    std.debug.print("规则：参数默认收 []const T；跨 C 边界才用 [*]T / [*:0]const T\n", .{});
    // ⚠️ 必须写 &nums：数组**不能**直接传给收 []const T 的函数
    //   sum(nums)→ error: array literal requires address-of operator (&)
    std.debug.print("nums={any}\n", .{nums});
    std.debug.print("sum(&nums) = {d}   first(&nums) = {d}\n", .{ sum(&nums), first(&nums) });
    // std.mem：字符串处理的工具箱
    const csv = "zig,python,rust,go";
    var it_csv = std.mem.splitScalar(u8, csv, ',');
    std.debug.print("splitScalar: ", .{});
    while (it_csv.next()) |part| std.debug.print("[{s}] ", .{part});
    std.debug.print("\n", .{});
    var it_tok = std.mem.tokenizeScalar(u8, "  a   bbccc  ", ' ');
    std.debug.print("tokenizeScalar（跳过空字段）: ", .{});
    while (it_tok.next()) |tok| std.debug.print("<{s}> ", .{tok});
    std.debug.print("\n", .{});
    var it_seq = std.mem.splitSequence(u8, "a::b::c", "::");
    std.debug.print("splitSequence（多字符分隔符）: ", .{});
    while (it_seq.next()) |part| std.debug.print("[{s}] ", .{part});
    std.debug.print("\n", .{});
    std.debug.print("find(u8,\"hello zig\",\"zig\") = {?}  findScalar(u8,\"hello\",'l') = {?}\n", .{
        std.mem.find(u8, "hello zig", "zig"),
        std.mem.findScalar(u8, "hello", 'l'),
    });
    if (std.mem.cut(u8, "key=value", "=")) |kv| { // 一刀两断
        std.debug.print("cut: 左=\"{s}\" 右=\"{s}\"\n", .{ kv[0], kv[1] });
    }
    std.debug.print("trim=\"{s}\"  startsWith={}  endsWith={}  eql={}\n", .{
        std.mem.trim(u8, "  pad  ", " "),
        std.mem.startsWith(u8, "foobar", "foo"),
        std.mem.endsWith(u8, "foobar", "bar"),
        std.mem.eql(u8, "zig", "zig"),
    });
    // 固定缓冲格式化：不分配堆内存（`{s}` 与 `{any}` 的选择见 6.8）
    var fbuf: [64]u8 = undefined;
    const formatted = try std.fmt.bufPrint(&fbuf, "{s}={d}", .{ "n", 42 });
    std.debug.print("bufPrint 无分配：\"{s}\" len={d}（缓冲在栈上）\n", .{ formatted, formatted.len });
    end("6.11");

    // ═══ 6.12 命令行参数：真实的 []const u8 ═══
    begin("6.12");
    var args = init.minimal.args.iterate();
    const argv0 = args.next(); // [:0]const u8 —— 哨兵切片
    if (argv0) |a0| {
        // argv[0] 是可执行文件路径（长度随安装位置变化），所以只演示类型与哨兵性质
        std.debug.print("argv[0] 类型={s} 末字节={d}（哨兵保证；.len 是路径长度，不固定）\n", .{
            @typeName(@TypeOf(a0)), a0[a0.len],
        });
    }
    var arg_no: usize = 1;
    while (args.next()) |arg| : (arg_no += 1) {
        // 参数是 [:0]const u8，能直接传给收 []const u8 的函数
        std.debug.print("argv[{d}] 类型={s} len={d} 字符数={d} 首字节=0x{x:0>2}\n", .{
            arg_no, @typeName(@TypeOf(arg)), arg.len, try codepointCount(arg), arg[0],
        });
    }
    std.debug.print("（本例没传额外参数，所以只有 argv[0]）\n", .{});
    end("6.12");

    std.debug.print("\n自检通过\n", .{});
}

test "数组是值类型：赋值与传参都是整块拷贝" {
    const a = [_]i32{ 1, 2, 3 };
    var b = a;
    b[0] = 99;
    try std.testing.expectEqual(@as(i32, 1), a[0]); // 原数组不变
    try std.testing.expectEqual(@as(i32, 99), b[0]);
    // 长度进类型：[3]i32 与 [4]i32 不是同一个类型
    try std.testing.expect(@TypeOf(a) != @TypeOf([_]i32{ 1, 2, 3, 4 }));
    // 切片是视图：改的是同一块内存
    var c = a;
    const view: []i32 = &c;
    view[0] = 99;
    try std.testing.expectEqual(@as(i32, 99), c[0]);
    // 传数组给收切片的函数要写 &a
    try std.testing.expectEqual(@as(i32, 6), sum(&a));
}

test "0.17 没有 **：++ 拼接与 repeat 重复" {
    // 编译期拼接
    const all = [_]i32{ 1, 2 } ++ [_]i32{3};
    try std.testing.expectEqual(@as(usize, 3), all.len);
    try std.testing.expectEqual(@as(i32, 3), all[2]);
    // 字符串拼接
    const pat = "ab" ++ "ab";
    try std.testing.expectEqualStrings("abab", pat);
    try std.testing.expectEqualStrings("ababab", repeatStr(3, "ab"));
    try std.testing.expectEqual(@as(usize, 6), repeatStr(2, "中").len); // 字节数
    // 数组重复（comptime 函数）
    const z = repeat(u16, 3, 0);
    try std.testing.expectEqual(@as(usize, 3), z.len);
    try std.testing.expectEqual(@as(u16, 0), z[2]);
    const sevens = repeat(u8, 4, 7);
    try std.testing.expectEqualSlices(u8, &.{ 7, 7, 7, 7 }, &sevens);
    // @splat 是数组重复填充的 0.17 写法
    const spl: [3]u16 = @splat(9);
    try std.testing.expectEqualSlices(u16, &.{ 9, 9, 9 }, &spl);
}

test "哨兵数组与哨兵切片：len 处可以安全读" {
    const a = [_:0]u8{ 1, 2, 3, 4 };
    try std.testing.expectEqual([4:0]u8, @TypeOf(a));
    try std.testing.expectEqual(@as(usize, 4), a.len);
    try std.testing.expectEqual(@as(u8, 0), a[4]); // 哨兵槽
    try std.testing.expectEqual(@as(usize, 5), @sizeOf(@TypeOf(a))); // N+1 个槽
    // 字面量是哨兵数组指针
    try std.testing.expectEqualStrings("Zig", "Zig");
    try std.testing.expectEqual(@as(usize, 3), "Zig".len);
    try std.testing.expectEqual(@as(u8, 0), "Zig"[3]);
    // 哨兵切片
    const cs: [:0]const u8 = "Elixir";
    try std.testing.expectEqual(@as(usize, 6), cs.len);
    try std.testing.expectEqual(@as(u8, 0), cs[6]);
}

test "切片是胖指针：两个机器字" {
    try std.testing.expectEqual(@sizeOf(usize) * 2, @sizeOf([]u8));
    try std.testing.expectEqual(@sizeOf(usize) * 2, @sizeOf([:0]u8));
    try std.testing.expectEqual(@sizeOf(usize), @sizeOf([*]u8)); // 多项指针只有一个地址
    try std.testing.expectEqual(@sizeOf(usize), @sizeOf(*u8)); // 单项指针也只有一个地址
    // 子切片的 ptr 偏移
    var a = [_]u16{ 1, 2, 3, 4 };
    const full: []u16 = &a;
    const sub = full[1..3];
    try std.testing.expectEqual(@as(usize, @sizeOf(u16)), @intFromPtr(sub.ptr) - @intFromPtr(full.ptr));
    try std.testing.expectEqual(@as(usize, 2), sub.len);
}

test "编译期边界得数组指针，运行期边界得切片" {
    const stones = [_]u16{ 42, 17, 93, 58, 11, 99 };
    // 编译期字面量边界 → *[N]u16
    const ct = stones[0..2];
    try std.testing.expectEqual(@as(usize, 2), ct.len);
    try std.testing.expectEqual(*const [2]u16, @TypeOf(ct));
    // 哨兵子切片：得自己造一个带 0 字节的缓冲（"Elixir" 里没有 0）
    var zbuf2 = [_]u8{ 'E', 'l', 0, 0 };
    const zcs: [:0]u8 = zbuf2[0..2 :0];
    const sub = zcs[0..2 :0]; // 长度编译期已知 → 哨兵数组指针 *const [2:0]u8
    try std.testing.expectEqualStrings("El", sub[0..sub.len]);
    try std.testing.expectEqual(@as(u8, 0), sub[2]);
    try std.testing.expectEqual(*[2:0]u8, @TypeOf(sub));
    // 运行期边界 → []u16
    var a = [_]u16{ 1, 2, 3, 4, 5 };
    var lo: usize = 1;
    _ = &lo;
    const rt = a[lo..4];
    try std.testing.expectEqual([]u16, @TypeOf(rt));
    try std.testing.expectEqualSlices(u16, &.{ 2, 3, 4 }, rt);
}

test "切片与数组指针互相转" {
    var nums = [_]i32{ 1, 2, 3, 4, 5, 6 };
    const ap: *[6]i32 = &nums; // 数组 → 数组指针
    const sl: []i32 = ap; // 数组指针 → 切片（长度自动）
    try std.testing.expectEqual(@as(usize, 6), sl.len);
    const head: *[3]i32 = ap[0..3]; // 切出更小的数组指针
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, &head.*);
    const back: *[3]i32 = sl[0..3]; // 切片 → 数组指针（长度要对得上）
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, &back.*);
    // const 数组也能取只读切片
    const carr = [_]i32{ 9, 8, 7 };
    const csl: []const i32 = &carr;
    try std.testing.expectEqual(@as(i32, 24), sum(csl));
}

test "字符串没有 string 类型：len 是字节数" {
    const msg = "你好，Zig";
    try std.testing.expectEqualStrings("你好，Zig", msg);
    try std.testing.expectEqual(@as(usize, 12), msg.len); // 12 字节，不是 6 个字符
    const s: []const u8 = msg;
    try std.testing.expectEqual(@as(usize, 6), try codepointCount(s)); // 6 个码点
    // 纯 ASCII 时字节数恰好等于字符数
    try std.testing.expectEqual(@as(usize, 5), "hello".len);
    try std.testing.expectEqual(@as(usize, 5), try codepointCount("hello"));
    // 逐字节是原始 UTF-8 字节
    // "你" = U+4F60 = UTF-8 e4 bd a0；"好" = U+597D = e5 a5 bd
    try std.testing.expectEqual(@as(u8, 0xE4), s[0]);
    try std.testing.expectEqual(@as(u8, 0xBD), s[1]);
    try std.testing.expectEqual(@as(u8, 0xA0), s[2]);
    try std.testing.expectEqual(@as(u8, 0xE5), s[3]);
    try std.testing.expectEqual(@as(u8, 0xA5), s[4]);
    try std.testing.expectEqual(@as(u8, 0xBD), s[5]);
}

test "UTF-8 边界：按字节切会切坏多字节字符" {
    const zh = "中文abc";
    try std.testing.expectEqual(@as(usize, 9), zh.len); // 3+3+3 字节
    try std.testing.expectEqual(@as(usize, 5), try codepointCount(zh));
    // 切在字符边界上 → 合法 UTF-8
    try std.testing.expect(std.unicode.utf8ValidateSlice(zh[0..6]));
    try std.testing.expectEqualStrings("中文", zh[0..6]);
    // 切在多字节字符中间 → 非法 UTF-8（但 {s} 打印不报错，只替换成 U+FFFD）
    try std.testing.expect(!std.unicode.utf8ValidateSlice(zh[0..4]));
    // 单个码点的字节长度由首字节决定
    try std.testing.expectEqual(@as(u3, 3), try std.unicode.utf8ByteSequenceLength(0xE4));
    try std.testing.expectEqual(@as(u3, 1), try std.unicode.utf8ByteSequenceLength('a'));
    try std.testing.expectEqual(@as(u21, 0x4F60), try std.unicode.utf8Decode("你"));
}

test "可变切片与只读切片" {
    var buf = [_]u8{ 'a', 'b', 'c', 'd' };
    const m: []u8 = buf[0..];
    m[0] = 'A';
    try std.testing.expectEqual(@as(u8, 'A'), buf[0]);
    // []u8 隐式转 []const u8
    const ro: []const u8 = m;
    try std.testing.expectEqualStrings("Abcd", ro);
    // const 修饰的是绑定，元素可变性看元素类型有没有 const
    const still: []u8 = buf[0..];
    still[1] = 'B';
    try std.testing.expectEqual(@as(u8, 'B'), buf[1]);
    // 遍历：指针捕获能改到原数组
    var walk = [_]i32{ 1, 2, 3 };
    for (&walk) |*p| p.* *= 10;
    try std.testing.expectEqualSlices(i32, &.{ 10, 20, 30 }, &walk);
    for (walk[0..]) |*p| p.* += 1;
    try std.testing.expectEqualSlices(i32, &.{ 11, 21, 31 }, &walk);
}

test "std.mem 字符串工具" {
    try std.testing.expectEqual(@as(?usize, 6), std.mem.find(u8, "hello zig", "zig"));
    try std.testing.expectEqual(@as(?usize, 2), std.mem.findScalar(u8, "hello", 'l'));
    try std.testing.expect(std.mem.eql(u8, "zig", "zig"));
    try std.testing.expect(!std.mem.eql(u8, "zig", "zig!"));
    try std.testing.expect(std.mem.startsWith(u8, "foobar", "foo"));
    try std.testing.expect(std.mem.endsWith(u8, "foobar", "bar"));
    try std.testing.expectEqualStrings("pad", std.mem.trim(u8, "  pad  ", " "));
    // splitScalar 保留空字段，tokenizeScalar 跳过
    var parts: usize = 0;
    var it = std.mem.splitScalar(u8, "a,b,c", ',');
    while (it.next()) |_| parts += 1;
    try std.testing.expectEqual(@as(usize, 3), parts);
    var toks: usize = 0;
    var it2 = std.mem.tokenizeScalar(u8, "a  b   c", ' ');
    while (it2.next()) |_| toks += 1;
    try std.testing.expectEqual(@as(usize, 3), toks);
    // cut 一刀两断
    const kv = std.mem.cut(u8, "key=value", "=").?;
    try std.testing.expectEqualStrings("key", kv[0]);
    try std.testing.expectEqualStrings("value", kv[1]);
}

test "std.mem.span 只吃哨兵指针" {
    // [*:0]const u8 是 C 眼里的 const char*
    const cstr: [*:0]const u8 = "hello";
    try std.testing.expectEqual(@as(usize, 5), std.mem.len(cstr));
    try std.testing.expectEqualStrings("hello", std.mem.span(cstr));
    // 哨兵切片要写 .ptr 才能给 span
    const cs: [:0]const u8 = "world";
    try std.testing.expectEqualStrings("world", std.mem.span(cs.ptr));
}
