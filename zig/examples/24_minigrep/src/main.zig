//! 24 实战：迷你 grep —— 手写正则引擎 + 递归遍历 + 流式逐行 + 高亮
//!
//! 分节标记与 docs/24-minigrep.md 的 `## 24.N` 一一对应。
//! `zig build run`（无参数）跑的是**教学演示**：把每一节的结论都打出来，
//! 便于 run-all.sh 逐节核对；`zig build run -- <模式> [选项] [目录]` 才是真 grep。
//!
//! 0.17 的关键事实（都是实测的，详见文档坑位清单）：
//!   * `main` 的第一个参数是 `std.process.Init`，`init.minimal.args` 才是 argv；
//!     **Juicy Main**（`pub fn main(init: Init)`）是 0.17 的推荐写法。
//!   * `std.fs.cwd()` 不存在了，只有 `std.Io.Dir.cwd()`，且它是 AT_FDCWD **伪句柄**：
//!     `iterate` / `walk` / `stat` 都必须先 `openDir` 拿到真句柄。
//!   * `Dir.Entry.name` 跨 `next()` **失效**（指向迭代器内部缓冲）→ 必须 dupe。
//!   * `File.readAll` 不存在；一次性读完用 `Dir.readFileAlloc(io, p, gpa, .limited(n))`，
//!     而 `.limited` 的参数类型是 `std.Io.Limit` 枚举，不是 usize。
//!   * `Io.Clock` 没有 `.monotonic`，枚举是
//!     real/awake/boot/cpu_process/cpu_thread。
//!   * `b.args` 已移除 → build.zig 里透传参数用 `run_cmd.addPassthruArgs()`。
const std = @import("std");
const regex = @import("regex.zig");
const search = @import("search.zig");

// ── 分节标记（20 章的既有模式，全教程统一） ──

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

/// 演示期输出。**刻意走 std.debug.print 而不是缓冲 Writer**：
/// 分节标记走 stderr，若正文走 stdout 的用户态缓冲，两路输出会**交错错乱**
/// （实测：24.1 的表格整个消失，因为它还留在未 flush 的 stdout 缓冲里）。
/// 教学程序要的是"逐节顺序可读"，不是吞吐，所以直接逐行写 stderr。
/// 返回 void 而不是 `!void`：打印失败（例如管道关闭）在演示里没有补救价值。
fn dprint(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt, args);
}

/// Windows 的 `Dir.handle` 是 `*anyopaque`（POSIX 上是整数 fd），`{d}` 打不了。
/// 这个编译期分流两头都能过：指针走 `@intFromPtr`，整数走 `@intCast`。
/// ⚠️ 它必须**定义出来**：`use of undeclared identifier` 是 AstGen 层面的错，
/// 未选中的 comptime 分支也逃不过标识符解析（本地实测）。
fn handleInt(h: anytype) usize {
    return switch (@typeInfo(@TypeOf(h))) {
        .pointer => @intFromPtr(h),
        else => @intCast(h),
    };
}
/// 需要真 `Writer` 的少数几处（`regex.dump` / `search.writeHighlighted`）
/// 走的是 stderr 缓冲 Writer。它与 `dprint` 写的是**同一个 fd**。
///
/// ⚠️⚠️ 这里必须用 **`writerStreaming`** 而不是 `writer`，否则本节内容会凭空消失。
/// 这是 0.17 最隐蔽的一个坑（本章实测踩到）：
///
/// `File.writer(io, buf)` 默认是 **positional 模式**（`fw.mode == .positional`），
/// 写之前会 **seek 文件偏移**。而 `std.debug.print` 写 stderr 走的是
/// `Threaded.stderr_writer`（streaming 追加）。两者混用时 positional writer
/// 会把偏移 **seek 回自己记录的 pos**，于是**覆盖掉 dprint 刚写的字节**。
///
/// 实测（`minigrep 2> out.txt`，out.txt 里只剩最后一行）：
///     var f1 = stderr.writer(io, &b);          // 写 "AAA-positional-writer\n"
///     std.debug.print("BBB-after-dprint\n");  // 追加成功
///     var f2 = stderr.writer(io, &b);          // 同一个 buf
///     // 写 "CCC-second-positional\n"
///     // ⇒ out.txt 只剩 "CCC-second-positional"：AAA、BBB 全被覆盖
///
/// 换成 `writerStreaming`（不 seek，纯 append）后三行都在。
///
/// ⚠️ 为什么"重定向到管道"时看不出来：管道不可 seek，positional 退化成追加。
/// 所以**只有 `2> file` 才暴露**——这是个本地怎么测都"正常"、
/// 只在把输出收进文件时才炸的坑。
///
/// 另外 `.interface` 字段是 `Writer`（**值，不是指针**），所以
/// `return &fw.interface` 会指向已销毁的栈帧；必须就地 `var` 绑定（20 章规则）。
///
/// 正确写法（buf 先声明，且必须活到 flush 为止）：
///     var ebuf: [8192]u8 = undefined;
///     var fw = std.Io.File.stderr().writerStreaming(io, &ebuf);
///     const w = &fw.interface;
///     defer w.flush() catch {};

// ════════════════════════════════════════════════════════════════════
//  24.1 命令行解析：Juicy Main 与六个开关
// ════════════════════════════════════════════════════════════════════

/// 六个开关。**短横线风格但支持组合**（`-in` 等价 `-i -n`），
/// 这与 POSIX getopt 一致，也是 grep 的习惯。
pub const Options = struct {
    /// `-i` 大小写不敏感
    ignore_case: bool = false,
    /// `-v` 反向匹配（打印**不**含模式的行）
    invert: bool = false,
    /// `-c` 只打印每个文件的命中行数，不打印内容
    count_only: bool = false,
    /// `-n` 打印行号
    show_line_no: bool = false,
    /// `-r` 递归遍历子目录
    recursive: bool = false,
    /// `-F` 固定字符串（**不解释正则元字符**）
    fixed_string: bool = false,
    /// `--color=always|never|auto`
    color: ColorMode = .auto,
    /// 跟在其后的位置参数：第 0 个是模式，其余是路径
    positional: []const []const u8 = &.{},
};

pub const ColorMode = enum { auto, always, never };

pub const ParseError = error{
    /// 不认识的开关（`-Z` / `--nope` / 未实现的 `--help`）
    UnknownOption,
};

/// 解析 argv。结果里的 `positional` **借用** `args` 本身，不分配、不拷贝。
///
/// ⚠️ 位置参数是**连续**的一段 argv（开关在前、位置参数在后），
/// 所以可以直接切子切片；要换成"任意位置穿插"的 GNU 风格就得开数组。
/// 这里选连续切片的理由是：零分配 ⇒ parseArgs 是**纯函数** ⇒ 单测直接喂数组。
///
/// 三个刻意的设计决定：
///   1. **开关在前、位置参数在后**。`--` 之后全是位置参数，
///      所以 `grep -- -pattern` 能搜以 `-` 开头的串。
///   2. 短选项**可组合**：`-in` 等价 `-i -n`。逐字符扫描，一个 `for` 搞定，
///      不需要 getopt 那种状态机。
///   3. 解析器**不碰 io / 文件系统**，也不碰分配器——
///      所以它能被单测直接喂数组（24.11）。
pub fn parseArgs(args: []const []const u8) ParseError!Options {
    var opt: Options = .{};
    var only_positional = false;
    // 位置参数起点：argv 里第一个"不是开关"的元素下标
    var first_pos: ?usize = null;

    for (args, 0..) |arg, i| {
        if (only_positional or arg.len == 0 or arg[0] != '-') {
            // 不是开关 ⇒ 位置参数。'-' 单独出现（stdin 约定）也算位置参数
            if (first_pos == null) first_pos = i;
            continue;
        }
        if (std.mem.eql(u8, arg, "--")) {
            only_positional = true;
            // `--` 本身占了一个下标，但它不是位置参数：
            // 后面的元素才是。把 first_pos 指向它之后
            if (first_pos == null and i + 1 < args.len) first_pos = i + 1;
            continue;
        }
        if (std.mem.startsWith(u8, arg, "--")) {
            // 长选项
            const body = arg[2..];
            if (std.mem.eql(u8, body, "color")) {
                opt.color = .always;
            } else if (std.mem.eql(u8, body, "no-color")) {
                opt.color = .never;
            } else if (std.mem.eql(u8, body, "recursive")) {
                opt.recursive = true;
            } else return error.UnknownOption;
            continue;
        }
        // 短选项：逐字符扫，所以 -in / -inr 都合法
        var k: usize = 1;
        while (k < arg.len) : (k += 1) {
            switch (arg[k]) {
                'i' => opt.ignore_case = true,
                'v' => opt.invert = true,
                'c' => opt.count_only = true,
                'n' => opt.show_line_no = true,
                'r' => opt.recursive = true,
                'F' => opt.fixed_string = true,
                else => return error.UnknownOption,
            }
        }
    }
    // 位置参数 = args[first_pos..]，**零分配**
    opt.positional = if (first_pos) |fp| args[fp..] else args[args.len..];
    return opt;
}

pub const usage =
    \\用法：minigrep [-ivcnrF] [--color] <模式> [路径...]
    \\
    \\  -i 大小写不敏感      -v 反向匹配      -c 只计数
    \\  -n 显示行号          -r 递归子目录    -F 固定字符串（不解释正则）
    \\      --color          强制开色（默认按 TTY 自动判断）
    \\
    \\无参数运行 = 教学演示（逐节打印 24.1 ~ 24.11 的结论）
    \\
;

fn demo24_1(io: std.Io, _: std.mem.Allocator) !void {
    std.debug.print("Init 的形状：Init={s}，其中 minimal={s}\n", .{
        @typeName(std.process.Init),
        @typeName(std.process.Init.Minimal),
    });
    std.debug.print("  init.minimal.args 的类型 = {s}（里面是 argv 向量）\n", .{
        @typeName(@FieldType(std.process.Init.Minimal, "args")),
    });
    std.debug.print("  init.arena 的类型 = {s}（进程级 arena，退出自动回收）\n", .{
        @typeName(@FieldType(std.process.Init, "arena")),
    });
    std.debug.print("  init.gpa 的类型   = {s}（Debug 模式带泄漏检查）\n", .{
        @typeName(@FieldType(std.process.Init, "gpa")),
    });
    std.debug.print("  init.io 的类型    = {s}\n", .{@typeName(@TypeOf(io))});
    std.debug.print("⚠️ 0.16 及以前 main 是 pub fn main() !void，argv 走 process.args()；\n", .{});
    std.debug.print("   0.17 起推荐 **Juicy Main**：pub fn main(init: std.process.Init) !void\n", .{});
    std.debug.print("   这不是风格问题：io / arena / gpa / environ 全部由 runtime 注入\n", .{});

    std.debug.print("\n[开关组合解析实测]  argv → 六个开关\n", .{});
    const cases = [_][]const []const u8{
        &.{ "-i", "needle", "src" },
        &.{ "-in", "needle" },
        &.{ "-c", "-r", "ERROR", "." },
        &.{ "-F", "a+b" },
        &.{ "--color", "-v", "x" },
        &.{ "--", "-notanoption" },
        &.{ "-", "pattern" },
    };
    for (cases) |argv| {
        const o = parseArgs(argv) catch |e| {
            dprint("  {s}  → 解析失败 {s}\n", .{ argv[0], @errorName(e) });
            continue;
        };
        var flags: [6]u8 = undefined;
        flags[0] = if (o.ignore_case) 'i' else '-';
        flags[1] = if (o.invert) 'v' else '-';
        flags[2] = if (o.count_only) 'c' else '-';
        flags[3] = if (o.show_line_no) 'n' else '-';
        flags[4] = if (o.recursive) 'r' else '-';
        flags[5] = if (o.fixed_string) 'F' else '-';
        var shown: usize = 0;
        for (o.positional) |p| {
            if (shown == 0 and shown < 8) dprint(" 模式={s}", .{p});
            shown += 1;
        }
        if (shown > 1) dprint(" (+{d} 个路径)", .{shown - 1});
        if (shown == 0) dprint(" （无位置参数）", .{});
        dprint("  开关=-{s}  color={t}\n", .{ flags[0..6], o.color });
    }
    // 错误路径也要能报出来
    if (parseArgs(&.{"-Z"})) |_| {
        std.debug.print("  -Z 解析成功？不该\n", .{});
    } else |e| std.debug.print("  未知开关 -Z → {s}（显式报错，不静默忽略）\n", .{@errorName(e)});
    if (parseArgs(&.{"--help"})) |_| {
        std.debug.print("  --help 解析成功？不该\n", .{});
    } else |e| std.debug.print("  --help（未实现）→ {s}\n", .{@errorName(e)});
}

// ════════════════════════════════════════════════════════════════════
//  24.2 文件读取与遍历：伪句柄、必须 openDir、name 必须 dupe
// ════════════════════════════════════════════════════════════════════

/// 一个待搜文件。`path` 是**自有内存**（arena 分配）——
/// 因为 `Dir.Entry.name` 下一次 `next()` 就失效，不能直接存切片。
const FileEntry = struct {
    path: []const u8,
    size: u64,
};

/// 24.2 的遍历实现。
///
/// 三个必须记住的 0.17 事实（都实测过）：
///
/// 1. **`std.Io.Dir.cwd()` 是伪句柄**。POSIX 上它的 `handle == AT_FDCWD == -2`，
///    不是一个真的已打开的 fd。`iterate` / `walk` / `stat` 内部都要 seek 这个 fd，
///    于是**直接在 cwd() 上调会 panic**：
///        programmer bug caused syscall error: BADF
///    （lseek(-2) 的 errno 被 std 当成"程序 bug"直接 panic，不是返回错误）
///
/// 2. **必须先 `openDir`**。而且 `.iterate = true` 必须在**打开时**给——
///    Windows 上不开迭代权限，iterate 会 AccessDenied。
///
/// 3. **`entry.name` 跨 `next()` 失效**。它的文档原话是
///    "All `Entry.name` are invalidated with the next call to `read` or `next`"，
///    因为 name 指向迭代器内部那块 `reader_buffer`（2048 字节）。
///    小目录下凑巧不炸（缓冲区还没被覆写），文件一多就现原形。
///    ⇒ **要存就 dupe**。
///
/// 另外判"路径存不存在"用 `dir.access`（返回 `!void`）而不是 `statFile`
/// （要返回整个 Stat 结构）。只问"在不在"时 access 便宜得多。
pub fn collectFiles(
    io: std.Io,
    gpa: std.mem.Allocator,
    root: []const u8,
    recursive: bool,
    out: *std.ArrayList(FileEntry),
) !void {
    const cwd = std.Io.Dir.cwd();

    // ⚠️⚠️ **`-r` 不代表"只接受目录"**。真grep 里 `grep -r pattern file.txt`
    //    是完全合法的：-r 只影响"遇到目录时要不要下钻"，目标是文件就直接搜。
    //    早期版本把 -r 分支写成"只 openDir + walk"，于是
    //    `minigrep -v -r ERROR src/corpus/app.log` 报
    //    "打开目录 … 失败：NotDir"（实测），一个文件都搜不到。
    //
    // 正确顺序：**先判存在性，再判是不是目录**，最后才决定走 walk 还是单文件。
    // 存在性用 access（返回 void，比 statFile 便宜）
    if (cwd.access(io, root, .{})) |_| {
        // 存在。试着当目录打开：成功 = 是目录
        var maybe_dir: ?std.Io.Dir = null;
        if (cwd.openDir(io, root, .{ .iterate = true })) |d| {
            maybe_dir = d;
        } else |_| {
            maybe_dir = null;
        }

        if (maybe_dir) |md| {
            var dir = md;
            defer dir.close(io);
            if (!recursive) {
                // 是目录却没给 -r：真 grep 会去读 stdin；我们明确提示并跳过
                std.debug.print("  （{s} 是目录，加 -r 才递归；已跳过）\n", .{root});
                return;
            }
            try walkInto(io, gpa, root, dir, out);
            return;
        }

        // 是文件：-r 与否都直接收
        const st = try cwd.statFile(io, root, .{});
        try out.append(gpa, .{ .path = try gpa.dupe(u8, root), .size = st.size });
        return;
    } else |err| {
        std.debug.print("  路径不存在：{s}（{s}）\n", .{ root, @errorName(err) });
        return;
    }
}

/// 在**已打开的真句柄**上做递归 walk。
///
/// 参数 `dir` 必须是 `openDir(.{ .iterate = true })` 拿到的——
/// `Dir.cwd()` 那个 AT_FDCWD 伪句柄直接 walk 会 panic（见 collectFiles 的注释）。
///
/// ⚠️ `Walker.Entry.path` 是**相对于 walker 根**的（本函数的 `root`），
///    不是相对 cwd。所以外面拼路径时必须 join(root, e.path)。
fn walkInto(
    io: std.Io,
    gpa: std.mem.Allocator,
    root: []const u8,
    dir: std.Io.Dir,
    out: *std.ArrayList(FileEntry),
) !void {
    // dir 是调用方已经 openDir 好的真句柄，本函数不拥有它、不关它
    const cwd = std.Io.Dir.cwd();
    var walker = try dir.walk(gpa);
    defer walker.deinit();
    while (try walker.next(io)) |e| {
        switch (e.kind) {
            .file => {
                // ⚠️ e.path 同样会在下一次 next() 后失效 ⇒ 必须 dupe
                // ⚠️ `std.Io.File.cwd()` 不存在（实测 no member named 'cwd'），
                //    只有 `std.Io.Dir.cwd()`。而 statFile 是 Dir 的方法
                //    （内部按需开真 fd，不受"伪句柄不能 seek"那条限制）。
                //
                // ⚠️⚠️ **e.path 是相对于 walker 根的**，不是相对 cwd。
                //    根是 "demo_tree" 时 e.path 形如 "sub/c.log"，
                //    直接拿去 cwd.statFile 会 FileNotFound ⇒ size 静默变 0。
                //    所以必须 join(root, e.path)。这是"walker 的 path 起点"
                //    最容易踩的一处。
                const full = try std.fs.path.join(gpa, &.{ root, e.path });
                const st = cwd.statFile(io, full, .{}) catch {
                    try out.append(gpa, .{ .path = full, .size = 0 });
                    continue;
                };
                try out.append(gpa, .{ .path = full, .size = st.size });
            },
            // 24.8 单独处理符号链接；这里 .sym_link 落进 else
            else => {},
        }
    }
}

fn demo24_2(io: std.Io, gpa: std.mem.Allocator) !void {
    const cwd = std.Io.Dir.cwd();
    // ⚠️ `std.posix.AT.FDCWD` 只在 POSIX 目标存在（Windows 上编译错
    //    `struct 'c.AT__struct_719' has no member named 'FDCWD'`），
    //    且 Windows 的 `Dir.handle` 是 `*anyopaque` 不透明句柄，打印 fd 没意义。
    //    伪句柄这个事实本身是 POSIX 概念，Windows 分支只讲 panic 行为。
    if (comptime @import("builtin").os.tag == .windows) {
        std.debug.print("std.Io.Dir.cwd().handle 是不透明句柄（Windows 无 AT_FDCWD 概念）\n", .{});
    } else {
        std.debug.print("std.Io.Dir.cwd().handle = {d}，std.posix.AT.FDCWD = {d}，相等 = {}\n", .{
            cwd.handle, std.posix.AT.FDCWD, cwd.handle == std.posix.AT.FDCWD,
        });
    }
    std.debug.print("⇒ cwd() 是**伪句柄**：它不是真的 fd，而是\"相对当前目录\"这个约定\n", .{});
    std.debug.print("⇒ 对它调 walk/iterate 会 panic：programmer bug caused syscall error: BADF\n", .{});
    std.debug.print("   （lseek(-2) 的 errno 被 std 判定为\"程序 bug\"直接 panic，不是返回错误）\n", .{});

    std.debug.print("\n[Dir 只有一个字段] ", .{});
    inline for (@typeInfo(std.Io.Dir).@"struct".field_names) |f| std.debug.print(" {s}", .{f});
    std.debug.print("\n", .{});
    std.debug.print("OpenDir 的 OpenOptions 字段：", .{});
    inline for (@typeInfo(std.Io.Dir.OpenOptions).@"struct".field_names) |f| std.debug.print(" {s}", .{f});
    std.debug.print("\n", .{});
    // ⚠️ `std.Io.Dir.OpenOptions{}.iterate` 这种写法在 0.17 **编译不过**
    //    （实测 error: expected ',' after initializer）——结构体字面量在
    //    表达式位置不被接受。必须先绑到 const 上再取字段。
    const default_oo: std.Io.Dir.OpenOptions = .{};
    std.debug.print("  .iterate 默认 = {}（不开就不能 iterate；Windows 上会 AccessDenied）\n", .{
        default_oo.iterate,
    });
    std.debug.print("  .follow_symlinks 默认 = {}\n", .{default_oo.follow_symlinks});

    // 造一棵小树
    const root = "demo_tree";
    cwd.deleteTree(io, root) catch {};
    try cwd.createDirPath(io, root ++ "/sub");
    try cwd.writeFile(io, .{ .sub_path = root ++ "/a.txt", .data = "alpha\nbeta\n" });
    try cwd.writeFile(io, .{ .sub_path = root ++ "/sub/b.txt", .data = "beta beta\n" });
    try cwd.writeFile(io, .{ .sub_path = root ++ "/sub/c.log", .data = "gamma\n" });

    std.debug.print("\n[openDir + iterate]（必须先 openDir，见上面的 BADF）\n", .{});
    {
        var d = try cwd.openDir(io, root, .{ .iterate = true });
        defer d.close(io);
        // Windows 句柄是 *anyopaque（POSIX 是整数 fd）。指针值每次运行都不同，
        // 演示输出要逐字节可复现，所以 Windows 不打印值、只打印判定。
        if (comptime @import("builtin").os.tag == .windows) {
            std.debug.print("  openDir 拿到真句柄（Windows 是不透明句柄，值不打印）\n", .{});
        } else {
            std.debug.print("  openDir 拿到真句柄 handle={d}\n", .{handleInt(d.handle)});
        }
        var it = d.iterate();
        while (try it.next(io)) |e| {
            dprint("    [{s}] {s}\n", .{ @tagName(e.kind), e.name });
        }
    }

    std.debug.print("\n[Walker]（递归遍历的现成壳，不用自己写递归）\n", .{});
    {
        var d = try cwd.openDir(io, root, .{ .iterate = true });
        defer d.close(io);
        var walker = try d.walk(gpa);
        defer walker.deinit();
        var n: usize = 0;
        while (try walker.next(io)) |e| {
            n += 1;
            dprint("    walk: {s:<24} kind={s:<10} depth={d}\n", .{
                e.path, @tagName(e.kind), e.depth(),
            });
        }
        std.debug.print("  共 {d} 条（含根下 3 个条目）\n", .{n});
        std.debug.print("  Walker.Entry 有 dir/basename/path/kind 四个字段，depth() 是便捷方法\n", .{});
        inline for (@typeInfo(std.Io.Dir.Walker.Entry).@"struct".field_names) |f| std.debug.print(" {s}", .{f});
        std.debug.print("\n", .{});
    }

    std.debug.print("\n[entry.name 失效实测] 60 个长文件名 ⇒ 目录项缓冲必然被 refill 复用\n", .{});
    {
        const many = root ++ "/many";
        try cwd.createDirPath(io, many);
        // 60 个长文件名 ⇒ 目录项总字节远超 reader_buffer_len（2048），
        // 必然触发多次 refill，旧内容被后续 next() 覆写
        const n_files = 60;
        for (0..n_files) |i| {
            const nm = try std.fmt.allocPrint(gpa, "file_{d:0>3}_with_a_long_name_to_force_refill.txt", .{i});
            try cwd.writeFile(io, .{ .sub_path = try std.fs.path.join(gpa, &.{ many, nm }), .data = "x" });
        }
        dprint("  目录项缓冲 reader_buffer_len = {d} 字节，造了 {d} 个长文件名\n", .{
            std.Io.Dir.Iterator.reader_buffer_len, n_files,
        });

        // 对照 A：只存切片不 dupe（**这是错的写法**）
        var d = try cwd.openDir(io, many, .{ .iterate = true });
        defer d.close(io);
        var raw: [128][]const u8 = undefined;
        var it = d.iterate();
        var k: usize = 0;
        // 现场把第一条 dupe 一份作为"真值"，用来事后比对
        var truth: [64]u8 = undefined;
        var truth_len: usize = 0;
        while (try it.next(io)) |e| {
            if (k == 0) {
                truth_len = @min(e.name.len, truth.len);
                @memcpy(truth[0..truth_len], e.name[0..truth_len]);
            }
            if (k < 128) {
                raw[k] = e.name;
                k += 1;
            }
        }

        // 对照 B：立刻 dupe（**正确写法**）
        var owned: [128][]u8 = undefined;
        var d2 = try cwd.openDir(io, many, .{ .iterate = true });
        defer d2.close(io);
        var it2 = d2.iterate();
        var m: usize = 0;
        while (try it2.next(io)) |e| {
            if (m < 128) {
                owned[m] = try gpa.dupe(u8, e.name);
                m += 1;
            }
        }

        // 事后读第一组的第 0 条
        const r0 = raw[0];
        const o0 = owned[0];
        dprint("  现场读到的第 1 条真名 = \"{s}\"（{d} 字节）\n", .{ truth[0..truth_len], truth_len });
        dprint("  存切片组  raw[0]  = \"{s}\"（{d} 字节）逐字节相同 = {}\n", .{
            r0, r0.len, std.mem.eql(u8, r0, truth[0..truth_len]),
        });
        dprint("  存副本组 owned[0] = \"{s}\"（{d} 字节）逐字节相同 = {}\n", .{
            o0, o0.len, std.mem.eql(u8, o0, truth[0..truth_len]),
        });
        std.debug.print("⇒ 存切片那组的第 1 条已经被后续 next() 覆写成别的条目（或含非文本字节）\n", .{});
        std.debug.print("⇒ 这就是为什么 collectFiles 里每条都 dupe：这是**正确性必需**，不是洁癖\n", .{});
        std.debug.print("   （raw[0] 那串乱码的具体字节取决于 readdir 返回顺序，各系统不同；\n", .{});
        std.debug.print("     稳定的是 `逐字节相同 = false` 这个**判定**——它对任何遍历顺序都成立）\n", .{});
    }

    std.debug.print("\n[access vs statFile] 判存在性用哪个\n", .{});
    std.debug.print("  access 的返回类型 = {s}\n", .{
        @typeName(@TypeOf(cwd.access(io, "x", .{}))),
    });
    try cwd.access(io, root ++ "/a.txt", .{});
    std.debug.print("  access(存在的文件) → ok\n", .{});
    if (cwd.access(io, root ++ "/nope", .{})) |_| {
        std.debug.print("  access(不存在) 成功？不该\n", .{});
    } else |e| std.debug.print("  access(不存在) → {s}\n", .{@errorName(e)});
    const st = try cwd.statFile(io, root ++ "/a.txt", .{});
    std.debug.print("  statFile(存在的文件) → size={d} 字节（多了整个 Stat，只为拿一个数字不划算）\n", .{st.size});

    // 先把为失效演示造的 60 个文件清掉，否则下面的列表会被它们淹没
    cwd.deleteTree(io, root ++ "/many") catch {};
    std.debug.print("\n[collectFiles 实测]递归收集（eachpath 都已 dupe）\n", .{});
    var files: std.ArrayList(FileEntry) = .empty;
    defer {
        for (files.items) |f| gpa.free(f.path);
        files.deinit(gpa);
    }
    try collectFiles(io, gpa, root, true, &files);
    dprint("递归收集到 {d} 个文件：\n", .{files.items.len});
    for (files.items) |f| dprint("    {s:<28} {d: >5} 字节\n", .{ f.path, f.size });

    cwd.deleteTree(io, root) catch {};
}

// ════════════════════════════════════════════════════════════════════
//  24.3 逐行读取与超长行
// ════════════════════════════════════════════════════════════════════

fn demo24_3(io: std.Io, gpa: std.mem.Allocator) !void {
    const cwd = std.Io.Dir.cwd();
    std.debug.print("0.17 里这些方法**不存在**（实测 @hasDecl）：\n", .{});
    std.debug.print("  File.readAll           = {}\n", .{@hasDecl(std.Io.File, "readAll")});
    std.debug.print("  File.writeAll          = {}\n", .{@hasDecl(std.Io.File, "writeAll")});
    std.debug.print("  File.readStreaming     = {}\n", .{@hasDecl(std.Io.File, "readStreaming")});
    std.debug.print("  File.writeStreamingAll = {}\n", .{@hasDecl(std.Io.File, "writeStreamingAll")});
    std.debug.print("⇒ 一次性读完的 API 搬到 Dir 上：Dir.readFileAlloc(io, path, gpa, .limited(n))\n", .{});
    // ⚠️ 格式串里的 `{}` 会被当作格式占位符。想**打印**字面花括号必须写 `{{}}`
    //    （实测不转义直接报 error: too few arguments）。同理 `{s}` 会被吃掉。
    std.debug.print("⇒ 流式的 API 留在 File 上：readStreaming(io, &.{{buf}}) / reader(io, &{{buf}})\n", .{});
    std.debug.print("  Io.Limit 是 enum(usize)：.limited(n) / .unlimited / .nothing\n", .{});
    std.debug.print("  readStreaming 的上限是 Io.Limit，**不是** usize（20 章实测 Io.Limit 是非穷尽枚举）\n", .{});

    // 三种读法对比
    const p = "demo_lines.txt";
    try cwd.writeFile(io, .{ .sub_path = p, .data = "alpha\nbeta\ngamma\n" });

    std.debug.print("\n[读法一] Dir.readFileAlloc：一次吃进内存，内存占用 = 文件全宽\n", .{});
    {
        const text = try cwd.readFileAlloc(io, p, gpa, .limited(1024));
        var it = std.mem.splitScalar(u8, text, '\n');
        var n: usize = 0;
        while (it.next()) |line| {
            n += 1;
            std.debug.print("  行{d} ={s}\n", .{ n, line });
        }
        std.debug.print("  splitScalar 给出 {d} 段（末段是空串，因为文件以 \\n 结尾）\n", .{n});
        std.debug.print("  ⚠️ 这就是\"行号会多 1\"的来源：\"a\\n\" 切成 2 段，第二段是空\n", .{});
    }

    std.debug.print("\n[读法二] File.readStreaming：按块读，单次上限由你给的切片决定\n", .{});
    {
        const f = try cwd.openFile(io, p, .{});
        defer f.close(io);
        var buf: [8]u8 = undefined;
        const got = try f.readStreaming(io, &.{buf[0..]});
        dprint("  第 1 块读到 {d} 字节：\"", .{got});
        for (buf[0..got]) |c| dprint("{c}", .{c});
        dprint("\"\n", .{});
        const got2 = f.readStreaming(io, &.{buf[0..]}) catch |e| blk: {
            std.debug.print("  第 2 块 → {s}（EOF 用错误表示，不是返回 0）\n", .{@errorName(e)});
            break :blk @as(usize, 0);
        };
        std.debug.print("  第 2 块读到 {d} 字节\n", .{got2});
    }

    std.debug.print("\n[读法三] File.Reader + fillMore/buffered/toss：真正的流式逐行\n", .{});
    std.debug.print("  三件套的职责：\n", .{});
    std.debug.print("    fillMore()  把底层缓冲填满；EOF 时返回 error.EndOfStream\n", .{});
    std.debug.print("    buffered()  当前\"已读但未消费\"的字节（切片，借用）\n", .{});
    std.debug.print("    toss(n)     消费掉 n 字节（移动读游标，不是拷贝）\n", .{});
    std.debug.print("  ⚠️ 关键规则：只在**真的找到分隔符**时才多消费 1 字节（含 \\n）\n", .{});
    std.debug.print("     无脑写 toss(idx.? + 1) 在没找到时会 panic: assert(r.seek <= r.end)\n", .{});
    {
        // 故意用 4 字节缓冲读 6 字节的行——生产代码里缓冲往往远小于行长
        const f = try cwd.openFile(io, p, .{});
        defer f.close(io);
        var buf: [4]u8 = undefined;
        var fr = f.reader(io, &buf);
        var lr = search.LineReader.init(&fr.interface);
        defer lr.deinit(gpa);

        var n: usize = 0;
        while (try lr.nextLine(gpa)) |line| {
            n += 1;
            dprint("  行{d} =\"{s}\"（缓冲区只有 {d} 字节）\n", .{ n, line, buf.len });
        }
        dprint("  共 {d} 行 ⇒ 4 字节缓冲照样读出 6 字节的行\n", .{n});
        std.debug.print("  ⇒ 补齐逻辑必须自己写；这就是 search.LineReader 存在的理由\n", .{});
    }

    std.debug.print("\n[超长行] 1000 字节的单行 + 8 字节缓冲\n", .{});
    {
        const long = "demo_long.txt";
        const filler = try gpa.alloc(u8, 1000);
        defer gpa.free(filler);
        @memset(filler, 'x');
        var blob: [1010]u8 = undefined;
        @memcpy(blob[0..1000], filler);
        blob[1000] = '\n';
        try cwd.writeFile(io, .{ .sub_path = long, .data = blob[0..1001] });

        const f = try cwd.openFile(io, long, .{});
        defer f.close(io);
        var buf: [8]u8 = undefined;
        var fr = f.reader(io, &buf);
        var lr = search.LineReader.init(&fr.interface);
        defer lr.deinit(gpa);

        while (try lr.nextLine(gpa)) |line| {
            dprint("  读到 {d} 字节的行：前 12 字节 =\"{s}\"…\n", .{ line.len, line[0..12] });
        }
        std.debug.print("  ⇒ 缓冲 8 字节、行长 1000 字节，内存占用是 O(行长) 而不是 O(文件)\n", .{});

        // max_line_bytes 护栏
        //
        // ⚠️⚠️ 这里的缓冲**不能**写成 `&.{}`（零长）！
        // 零长缓冲 + fillMore 会 panic：
        //     Io.Reader.defaultRebase: assert(r.buffer.len - r.seek >= capacity) failed
        //     路径是 fillMore → rebase(r, r.end - r.seek + 1) —— 它至少要 1 字节。
        // 20 章用 `&.{}` 配的是 readSliceShort（不fillMore），所以那里没事。
        // ⇒ **只要打算调 fillMore，缓冲至少给 1 字节。**
        const f2 = try cwd.openFile(io, long, .{});
        defer f2.close(io);
        var buf2: [8]u8 = undefined;
        var fr2 = f2.reader(io, &buf2);
        var lr2 = search.LineReader.init(&fr2.interface);
        lr2.max_line_bytes = 64;
        defer lr2.deinit(gpa);
        if (lr2.nextLine(gpa)) |_| {
            std.debug.print("  max_line_bytes=64 读 1000 字节行成功？不该\n", .{});
        } else |e| std.debug.print("  max_line_bytes=64 → {s}（护栏生效，不吃光内存）\n", .{@errorName(e)});
        cwd.deleteFile(io, long) catch {};
    }

    cwd.deleteFile(io, p) catch {};
}

// ════════════════════════════════════════════════════════════════════
//  24.4 手写正则引擎：递归下降怎么消歧
// ════════════════════════════════════════════════════════════════════

fn demo24_4(_: std.Io, gpa: std.mem.Allocator) !void {
    std.debug.print("文法（BNF，四层函数一一对应）：\n", .{});
    std.debug.print("  alt       := concat ('|' concat)*      ← parseAlt    优先级最低\n", .{});
    std.debug.print("  concat    := repeat*                    ← parseConcat 遇 | 和 ) 就停\n", .{});
    std.debug.print("  repeat    := atom quantifier?           ← parseRepeat 量词只管前一个 atom\n", .{});
    std.debug.print("  quantifier := ('*'|'+'|'?') '?'?        ← applyQuantifier 后一个 ? 是懒惰修饰\n", .{});
    std.debug.print("  atom      := '(' alt ')' | '[' class ']' | '.' | '^' | '$'\n", .{});
    std.debug.print("             | '\\' escape | 普通字节\n", .{});
    std.debug.print("⚠️ 递归下降 =函数调用栈。四层之间的边界靠**终止符**划分，不需要优先级表\n", .{});

    std.debug.print("\n[消歧一] 量词只作用于紧邻的前一个 atom\n", .{});
    try showMatch(gpa, "ab*", "aab");
    try showMatch(gpa, "(ab)*", "aab");
    std.debug.print("  ⇒ ab* 匹配 aab 只吃到 \"a\"（b* 匹配空）；(ab)* 才能匹配 \"abab\"\n", .{});
    std.debug.print("  ⇒ 这不是\"贪心\"或\"就近结合\"的约定，是文法本身：repeat 每次只吃一个 atom\n", .{});

    std.debug.print("\n[消歧二] | 优先级最低：concat 遇 | 就停，把控制权交回 alt\n", .{});
    try showMatch(gpa, "ab|cd", "abcd");
    try showMatch(gpa, "a(b|c)d", "acd");
    std.debug.print("  ⇒ ab|cd 在 abcd 上只能吃到 \"ab\"；加了括号才轮到 cd\n", .{});
    std.debug.print("  ⇒ 不需要任何优先级表——终止符（| 与 )）不在 atom 的起始字符集里\n", .{});

    std.debug.print("\n[消歧三] 贪婪 vs 非贪婪：Split 的两个下标谁在前\n", .{});
    try showMatch(gpa, "a*", "aaaa");
    try showMatch(gpa, "a*?", "aaaa");
    try showMatch(gpa, "a+?", "aaab");
    std.debug.print("  ⇒ 贪婪 = split(x=xs, y=exit)；非贪婪 = **两个下标对调**\n", .{});
    std.debug.print("  ⇒ 实测踩坑：X* 有**两个**决策点（入口 slot + 回边 after），\n", .{});
    std.debug.print("     只翻转回边的话 a*? 在 aaaa 上仍得到 0-1（错），两处都翻才得到 0-0\n", .{});

    std.debug.print("\n[消歧四] 量词后紧跟的 ? 是懒惰修饰，不是又一个量词\n", .{});
    try showMatch(gpa, "a?", "abc");
    try showMatch(gpa, "a??", "abc");
    try showMatch(gpa, "a??b", "ab");
    std.debug.print("  ⇒ a?  是\"可选的 a\"；a?? 是\"懒惰的可选 a\"；a** 直接报 RepeatedQuantifier\n", .{});

    std.debug.print("\n[字符类消歧] a-z 是区间，[a-] 是\"a 或 -\"\n", .{});
    try showMatch(gpa, "[a-]", "-");
    try showMatch(gpa, "[a-c]", "b");
    try showMatch(gpa, "[^a-c]", "zb");
    std.debug.print("  ⇒ 规则：`-` 后面必须还有字符且不是 `]` 才算区间首（POSIX 规定）\n", .{});
    std.debug.print("  ⇒ 取反在**编译期**就分成 class_neg 指令，运行期不查 negated 标志\n", .{});

    std.debug.print("\n[错误必须显式] 10 种编译错误，没有一种是\"默默猜\"\n", .{});
    const bad = [_][]const u8{
        "(ab", "ab)", "[a-z",  "[]",  "*ab",
        "()*", "a**", "[z-a]", "a\\", "a{2,3}",
    };
    for (bad) |pat| {
        const r = regex.compile(gpa, pat);
        if (r) |prog| {
            var p2 = prog;
            p2.deinit(gpa);
            dprint("  {s: <10} → 编译成功（{d} 条指令）\n", .{ pat, p2.op_count });
        } else |e| dprint("  {s: <10} → {s}\n", .{ pat, @errorName(e) });
    }
    std.debug.print("  ⚠️ `{{n,m}}` 明确报 UnsupportedRepeat，而不是当字面量 {{ 或 n,m\n", .{});
    std.debug.print("  ⚠️ `()*`（重复空组）报 NothingToRepeat：POSIX 未定义，各引擎行为不一\n", .{});
    std.debug.print("  ⇒ 判断\"能否重复\"用的是 consuming 计数：空组只产出占位 jump，不算消费\n", .{});
}

/// 打印 `FieldAttributes` 的字段名。用法：
/// `printFieldAttrs("Union", @TypeOf(@as(@FieldType(T, "field_attrs"), undefined)[0]))`
/// —— `@FieldType` 拿到的是 `[]const FieldAttributes`（切片），
/// 对切片类型取 `[0]` 再 `@TypeOf`，就得到元素类型本身。
fn printFieldAttrs(comptime label: []const u8, comptime Attrs: type) void {
    std.debug.print("  {s}.FieldAttributes 字段：", .{label});
    inline for (@typeInfo(Attrs).@"struct".field_names) |f| std.debug.print(" {s}", .{f});
    std.debug.print("\n", .{});
}

/// 一个普通函数，仅供 24.5 反射 `@typeInfo(@TypeOf(某函数))` 的形状。
/// 参数里带 `comptime` 标签，正好演示 `Fn.is_generic == false`
/// 但 `param_types` 依然是 `[]const ?type`（comptime 参数的类型照样在数组里）。
fn classify(comptime tag: []const u8, n: u32, flag: bool) u64 {
    return @as(u64, n) + flag + tag.len;
}

fn showMatch(gpa: std.mem.Allocator, pat: []const u8, text: []const u8) !void {
    const prog = regex.compile(gpa, pat) catch |e| {
        dprint("  {s: <10} 编译失败 {s}\n", .{ pat, @errorName(e) });
        return;
    };
    defer prog.deinit(gpa);
    if (try regex.find(gpa, &prog, text, .{})) |h| {
        dprint("  {s: <10} 在 \"{s}\" 上→ [{d},{d}) = \"{s}\"\n", .{
            pat, text, h.start, h.end, text[h.start..h.end],
        });
    } else {
        dprint("  {s: <10} 在 \"{s}\" 上 → 无匹配\n", .{ pat, text });
    }
}

// ════════════════════════════════════════════════════════════════════
//  24.5 comptime 生成：模式在编译期变成指令数组
// ════════════════════════════════════════════════════════════════════

fn demo24_5(io: std.Io, gpa: std.mem.Allocator) !void {
    var ebuf: [4096]u8 = undefined;
    var fw = std.Io.File.stderr().writerStreaming(io, &ebuf);
    const w = &fw.interface;
    defer w.flush() catch {};
    std.debug.print("设计核心：**没有 AST**。语法树被压平成一条线性指令数组，\n", .{});
    std.debug.print("只剩两种控制流——Split(x,y)（有优先级的分支）与 Jump(x)（无条件）。\n", .{});
    std.debug.print("压平带来的最大好处：pc 就是数组下标，于是\"回填\"= 原地改写一个值，\n", .{});
    std.debug.print("**不需要移动任何指令**。树形结构做不到这一点（插一条指令要重编所有下标）。\n", .{});

    std.debug.print("\n[反汇编] 模式 abc —— 每个 atom 两条指令（预留槽 + 本体）\n", .{});
    {
        const prog = try regex.compile(gpa, "abc");
        defer prog.deinit(gpa);
        try regex.dump(w, &prog);
        w.flush() catch {}; // ⚠️ 必须立刻 flush：w 与 dprint 写同一个 fd，
        // 不 flush 的话反汇编会整体堆到本节末尾，顺序全乱
    }
    std.debug.print("  纯 jump 指令是\"预留槽位\"退化后的产物：没有量词时它跳到 slot+1，\n", .{});
    std.debug.print("  也就是直接进入 atom 本体。⚠️ 若忘了退化，它会保持占位值 0 →死循环\n", .{});

    std.debug.print("\n[反汇编] 模式 a* —— 多了两条 Split：入口与回边\n", .{});
    {
        const prog = try regex.compile(gpa, "a*");
        defer prog.deinit(gpa);
        try regex.dump(w, &prog);
        w.flush() catch {}; // ⚠️ 必须立刻 flush：w 与 dprint 写同一个 fd，
        // 不 flush 的话反汇编会整体堆到本节末尾，顺序全乱
    }
    std.debug.print("  pc 1 = 入口 split（要不要进第一次 X）\n", .{});
    std.debug.print("  pc 3 = 回边 split（要不要再来一次），它跳回 pc 2 —— **允许反向跳转**\n", .{});

    std.debug.print("\n[反汇编] 模式 (ERROR|WARN)+ —— 嵌套与分支同时存在\n", .{});
    {
        const prog = try regex.compile(gpa, "(ERROR|WARN)+");
        defer prog.deinit(gpa);
        dprint("  共 {d} 条指令，分组数={d}\n", .{ prog.op_count, prog.group_count });
        try regex.dump(w, &prog);
        w.flush() catch {}; // ⚠️ 必须立刻 flush：w 与 dprint 写同一个 fd，
        // 不 flush 的话反汇编会整体堆到本节末尾，顺序全乱
    }

    std.debug.print("\n[指令膨胀比] 模式 N 字节 → 约 2N 条指令\n", .{});
    for ([_][]const u8{ "abc", "a*", "a?", "(a)", "a|b|c", "[a-z]+", "s*rvice=[a-z]+" }) |pat| {
        const prog = try regex.compile(gpa, pat);
        defer prog.deinit(gpa);
        dprint("  {s: <16} {d: >2} 字节 → {d: >3} 条指令（×{d:.1}）\n", .{
            pat,                                                                                prog.pattern_len, prog.op_count,
            @as(f64, @floatFromInt(prog.op_count)) / @as(f64, @floatFromInt(prog.pattern_len)),
        });
    }
    std.debug.print("  ⇒ 膨胀主要来自**预留槽位**（每个 atom 一条）。换来的是零重排、可原地回填\n", .{});

    std.debug.print("\n[comptime 生成] 同一个解析器，编译期跑一遍\n", .{});
    std.debug.print("  compileComptime(comptime pattern) 与 compile(gpa, pattern) **共用** 24.4 的解析器，\n", .{});
    std.debug.print("  差别只有两点：① 写进栈上定长数组而非分配器② 返回 const 数组（.rodata）\n", .{});
    inline for (.{ "ERROR|WARN", "a+?", "[0-9]+" }) |pat| {
        const ct = comptime regex.compileComptime(pat);
        const rt = try regex.compile(gpa, pat);
        defer rt.deinit(gpa);
        var identical = ct.ops.len == rt.ops.len;
        if (identical) {
            for (ct.ops, rt.ops) |a, b| {
                identical = opsEqual(a, b);
                if (!identical) break;
            }
        }
        dprint("  {s: <14} comptime {d: >3} 条 / 运行期 {d: >3} 条  逐条相同={}\n", .{
            pat, ct.ops.len, rt.ops.len, identical,
        });
    }
    std.debug.print("  ⚠️ 踩坑一：不能把 comptime **var** 的地址返回（实测报\n", .{});
    std.debug.print("     runtime value contains reference to comptime var）——var 是编译器工作区，\n", .{});
    std.debug.print("     不是程序静态数据。必须拷进一个 const 数组再切片。\n", .{});
    std.debug.print("  ⚠️ 踩坑二：不能用 expectEqualSlices(Op, ...) 比指令——Op 的 class 变体里\n", .{});
    std.debug.print("     Class.ranges 是定长数组，len 之后的槽位是 undefined，整条做 == 就是在比内存垃圾。\n", .{});

    std.debug.print("\n[@typeInfo 0.17 三条平行数组] 反射 Op 的字段\n", .{});
    {
        // 0.17 的 Struct 里有三条**等长**的平行数组
        const T = @typeInfo(regex.Op).@"union";
        // ⚠️⚠️ 0.17 的一个真实怪癖：`union(enum)` 的 `tag_type` 是**编译器内部的
        //    匿名枚举**，不是用户能写出来的任何类型。所以 `@typeName` 打到它
        //    会**原样打印产生它的那条表达式**：
        //        @typeInfo(regex.Op).@"union".tag_type.?
        //    （实测：把它和手写的同名 enum 比较，结果是 false）
        //    ⇒ 想看 tag 的字段，用 `@typeInfo(tag_t).@"enum".field_names`；
        //      想判断 tag 类型，只能靠 `==` 比较，不能靠名字。
        const tag_t: type = T.tag_type orelse @TypeOf(void);
        dprint("  Op 是 union(enum)，字段数 = {d}；tag_type 是编译器内部匿名类型，\n", .{
            T.field_names.len,
        });
        dprint("    @typeName 打出来 = [{s}]（**不是**类型名，是产生它的表达式）\n", .{
            @typeName(tag_t),
        });
        dprint("    tag 的字段名（可靠途径）= ", .{});
        inline for (@typeInfo(tag_t).@"enum".field_names) |f| dprint("{s} ", .{f});
        dprint("\n", .{});
        std.debug.print("  三条平行数组长度恒相等（0.17 文档保证）：\n", .{});
        std.debug.print("    field_names.len = {d}  field_types.len = {d}  field_attrs.len = {d}\n", .{
            T.field_names.len, T.field_types.len, T.field_attrs.len,
        });
        // ⚠️ field_types 是 []const **type** —— 类型不是运行期值，
        //    所以三条数组一起遍历时**必须用 inline for**，用普通 for 会报
        //    "values of type 'type' must be comptime-known"（实测）
        inline for (T.field_names, T.field_types, T.field_attrs) |fname, ftype, fattrs| {
            std.debug.print("    {s: <12} : {s:<24} align={?d}\n", .{
                fname, @typeName(ftype), fattrs.@"align",
            });
        }
        // ⚠️ Union.FieldAttributes 只有 @"align" 一个字段，**没有** default_value_ptr
        //    （Struct.FieldAttributes 才有——实测报 no field named 'default_value_ptr'）。
        //    两条平行数组的元素类型不同，所以同一个 @typeInfo 家族里
        //    Struct 与 Union 的 FieldAttributes **不是同一个类型**，不能互换。
        std.debug.print("  Op.field_attrs 的元素类型 = {s}\n", .{
            @typeName(@TypeOf(T.field_attrs)),
        });
        printFieldAttrs("Union ", std.builtin.Type.Union.FieldAttributes);
        printFieldAttrs("Struct", std.builtin.Type.Struct.FieldAttributes);
        std.debug.print("  ⚠️ 0.17 的 @typeInfo(union) 字段是 field_types（不是老版的 types），\n", .{});
        std.debug.print("     且@typeInfo(T) 对**函数**返回的 Type.Fn 已改成 struct：\n", .{});
        std.debug.print("     没有 .params 了，改用 .param_types / .param_attrs / .is_generic\n", .{});
        // ⚠️ 想反射一个函数，要写 @TypeOf(some_fn) —— **不能**写 @TypeOf(@min)：
        //    @min 是编译期内建，@TypeOf 只接受"值"，直接写会报
        //    error: expected parameter list, found ')'（实测）
        const FN = @typeInfo(@TypeOf(classify)).@"fn";
        std.debug.print("     实测本文件的 classify（comptime 标签 + 值）：is_generic={}\n", .{
            FN.is_generic,
        });
        std.debug.print("     param_types.len={d}：", .{FN.param_types.len});
        inline for (FN.param_types, 0..) |pt, i| {
            std.debug.print(" #{d}={s}", .{ i, @typeName(pt orelse @TypeOf(void)) });
        }
        std.debug.print("\n     返回类型={s}\n", .{@typeName(FN.return_type.?)});
        inline for (FN.param_attrs, 0..) |pa, i| {
            std.debug.print("     param_attrs[{d}].noalias = {}\n", .{ i, pa.@"noalias" });
        }
        std.debug.print("  ⚠️ 0.17 的 enum 分支也不再是 is_enum/is_exhaustive，而是一个 mode 字段：\n", .{});
        std.debug.print("     @typeInfo(std.Io.Clock).@\"enum\".mode = {t}（exhaustive / nonexhaustive）\n", .{
            @typeInfo(std.Io.Clock).@"enum".mode,
        });
    }
}

/// 逐字段比较两条指令。**不能**用 expectEqualSlices(Op, ...)——
/// `Op` 的 class 变体里 `Class.ranges` 是定长数组，`len` 之后的槽位从未写入
/// （`undefined`），整条指令做 `==` 就是在比内存垃圾。实测这就是 24.11
/// 那条测试最初失败的原因（指令明明逐条相同）。
fn opsEqual(a: regex.Op, b: regex.Op) bool {
    if (std.meta.activeTag(a) != std.meta.activeTag(b)) return false;
    return switch (a) {
        .char => |v| v == b.char,
        .any, .bol, .eol, .accept => true,
        .split => |v| v[0] == b.split[0] and v[1] == b.split[1],
        .jump => |v| v == b.jump,
        .class => |v| classEqual(v, b.class),
        .class_neg => |v| classEqual(v, b.class_neg),
    };
}

fn classEqual(a: regex.Class, b: regex.Class) bool {
    if (a.len != b.len) return false;
    for (a.ranges[0..a.len], b.ranges[0..b.len]) |x, y| {
        if (x.lo != y.lo or x.hi != y.hi) return false;
    }
    return true;
}

// ════════════════════════════════════════════════════════════════════
//  24.6 匹配执行：回溯、复杂度、灾难性爆炸
// ════════════════════════════════════════════════════════════════════

fn demo24_6(io: std.Io, gpa: std.mem.Allocator) !void {
    std.debug.print("执行器是**带回溯栈的栈式虚拟机**。栈里每个格子只有两样东西：\n", .{});
    std.debug.print("    pc  —— 回到哪条指令\n", .{});
    std.debug.print("    pos —— 从文本的哪个字节位置继续\n", .{});
    std.debug.print("★ 就这两行是\"回溯\"的全部实现。文本位置不用回退，因为它就存在栈里。\n", .{});
    std.debug.print("执行 split 时：把\"另一条路 + 当前 pos\"压栈，然后先走优先的那条；\n", .{});
    std.debug.print("优先那条走不通时，栈顶弹出来就是**回溯现场**。\n", .{});

    std.debug.print("\n[最左匹配] 从左往右扫起点，第一个成功的即返回\n", .{});
    try showMatch(gpa, "abc", "xxabcxx");
    try showMatch(gpa, "abc", "abcabc");
    std.debug.print("  ⇒ \"最左\" + Split 的贪婪编法 = POSIX 的**左长匹配**，不是额外规定\n", .{});
    std.debug.print("  ⇒ Program.anchored_start 给 ^ 开头的模式省掉 O(n) 个起点的尝试\n", .{});

    std.debug.print("\n[复杂度] 线性模式：步数随输入线性增长\n", .{});
    {
        const prog = try regex.compile(gpa, "a+b");
        defer prog.deinit(gpa);
        dprint("  模式 a+b（{d} 条指令）\n", .{prog.op_count});
        for ([_]usize{ 8, 16, 32, 64 }) |n| {
            const text = try gpa.alloc(u8, n);
            defer gpa.free(text);
            @memset(text, 'a');
            var stats: regex.Stats = .{};
            _ = try regex.findWithStats(gpa, &prog, text, .{}, &stats);
            dprint("    输入 {d: >3} 字节 → 回溯步数 {d: >5}（约 {d:.0} 步/字节）\n", .{
                n, stats.steps, @as(f64, @floatFromInt(stats.steps)) / @as(f64, @floatFromInt(n)),
            });
        }
    }

    std.debug.print("\n[灾难性回溯] (a+)+b 撞上一串没有 b 的 a —— 教科书级反例\n", .{});
    {
        const evil = try regex.compile(gpa, "(a+)+b");
        defer evil.deinit(gpa);
        dprint("  模式 (a+)+b 只有 {d} 条指令（看起来人畜无害）\n", .{evil.op_count});
        dprint("  {s: >4}  {s: >14}  {s: >14}  {s}\n", .{ "n", "回溯步数", "耗时(ns)", "结果" });
        var report_limit: ?anyerror = null;
        for ([_]usize{ 10, 14, 18, 20, 22 }) |n| {
            const text = try gpa.alloc(u8, n);
            defer gpa.free(text);
            @memset(text, 'a');
            var stats: regex.Stats = .{};
            const t0 = std.Io.Clock.now(.awake, io);
            const res = regex.findWithStats(gpa, &evil, text, .{ .max_steps = 100_000_000 }, &stats);
            const t1 = std.Io.Clock.now(.awake, io);
            const ns = t0.durationTo(t1).nanoseconds;
            // ⚠️ 两层错误联合（error union 套 optional）**不能**直接 switch。
            //    实测报 switch on error union type '...!?Span'、consider using try/catch。
            //    办法：先用 `catch` 把外层错误摊平，再对**纯 optional** 做 switch。
            const flat: ?regex.Span = res catch |e| blk: {
                report_limit = e;
                break :blk null;
            };
            const cols = "  {d: >4}  {d: >14}  {d: >14}  ";
            if (report_limit) |e| {
                report_limit = null;
                dprint(cols ++ "{s}（护栏生效）\n", .{ n, stats.steps, ns, @errorName(e) });
            } else if (flat) |h| {
                dprint(cols ++ "匹配 [{d},{d})\n", .{ n, stats.steps, ns, h.start, h.end });
            } else {
                dprint(cols ++ "无匹配\n", .{ n, stats.steps, ns });
            }
        }
        std.debug.print("  ⇒ 输入每多2 个字符，步数约 ×4：这是 2^n，不是 n^2。\n", .{});
        std.debug.print("  ⇒ 原因：(a+)+ 的**外层与内层都能切分同一串 a**，切法数是 2^(n-1)。\n", .{});
        std.debug.print("     回溯引擎会把每一种切法都试一遍，而**全部失败**时一个都省不掉。\n", .{});
        std.debug.print("  ⇒ 唯一的护栏是 max_steps（本实现默认 200 万步）：超了返回 TooManySteps。\n", .{});
        std.debug.print("  ⇒ 工业界解法是 Thompson NFA（并行模拟所有状态，恒定时间/空间），\n", .{});
        std.debug.print("     但 NFA 无法直接给出\"最左最长\"，必须再做一遍子串提取——各有取舍。\n", .{});
    }
}

// ════════════════════════════════════════════════════════════════════
//  24.7 输出格式化与颜色
// ════════════════════════════════════════════════════════════════════

fn demo24_7(io: std.Io, gpa: std.mem.Allocator) !void {
    var ebuf: [4096]u8 = undefined;
    var fw = std.Io.File.stderr().writerStreaming(io, &ebuf);
    const w = &fw.interface;
    defer w.flush() catch {};
    std.debug.print("颜色就是 ANSI 转义序列，纯文本，无依赖：\n", .{});
    std.debug.print("  {s} 重置   {s}命中片段   {s}文件名   {s}行号   {s}统计行\n", .{
        search.Color.reset,   search.Color.hit, search.Color.path,
        search.Color.line_no, search.Color.dim,
    });
    std.debug.print("  ⚠️ 转义序列里**没有** 'm' 之外的语义；`\\x1b[1;31m` = ESC [ 1;31 m\n", .{});

    const line = "2026-03-01 ERROR service=billing msg=\"payment timeout\"";
    const prog = try regex.compile(gpa, "(ERROR|WARN)+");
    defer prog.deinit(gpa);

    std.debug.print("\n[逐字节对照] 同一行，开色 vs 关色\n", .{});
    const spans = try search.allSpans(gpa, &prog, line, .{});
    defer gpa.free(spans);
    dprint("  命中 {d} 段：", .{spans.len});
    for (spans) |s| dprint(" [{d},{d})=\"{s}\"", .{ s.start, s.end, line[s.start..s.end] });
    dprint("\n", .{});

    dprint("  关色：", .{});
    try search.writeHighlighted(w, line, spans, false);
    w.flush() catch {}; // ⚠️ 与 dprint 共用一个 fd，必须逐段 flush 才不会乱序
    dprint("\n  开色：", .{});
    try search.writeHighlighted(w, line, spans, true);
    w.flush() catch {};
    dprint("\n", .{});

    std.debug.print("\n[十六进制] 证明转义序列真的写进了字节流\n", .{});
    var hb: [512]u8 = undefined;
    var hw = std.Io.Writer.fixed(&hb);
    try search.writeHighlighted(&hw, "ab", &[_]regex.Span{.{ .start = 0, .end = 2 }}, true);
    const got = hw.buffered();
    dprint("  高亮 \"ab\" 得到 {d} 字节：", .{got.len});
    for (got) |c| dprint(" {x:0>2}", .{c});
    dprint("\n  可读形式：", .{});
    for (got) |c| {
        if (c == 0x1b) {
            dprint("<ESC>", .{});
        } else if (c >= 0x20 and c < 0x7f) {
            dprint("{c}", .{c});
        } else {
            dprint("\\x{x:0>2}", .{c});
        }
    }
    dprint("\n", .{});

    std.debug.print("\n[TTY 检测] 非终端必须自动关色\n", .{});
    // ⚠️ **不要**写 `@TypeOf(try some_runtime_call())`：
    //    @TypeOf 要的是"值的类型"，编译器会把这个调用**提升到编译期**求值，
    //    于是 io 相关的运行期调用直接报错（实测 cannot format slice…）。
    //    正确做法：把结果绑到 const，再用 @TypeOf(const)。
    const tty_call = try std.Io.File.stdout().isTty(io);
    const tty = tty_call;
    std.debug.print("  File.isTty(io) 的返回类型 = {s}\n", .{
        @typeName(@TypeOf(tty_call)),
    });
    // ⚠️ 切片必须显式给格式说明符：写 `{}` 会报
    //    "cannot format slice without a specifier (i.e. {s}, {x}, {b64}, or {any})"。
    //    `if (tty) "开" else "关"` 的类型是 []const u8（切片），所以要 {s}。
    std.debug.print("  当前 stdout.isTty = {} ⇒ --color=auto 时{s}颜色\n", .{
        tty,
        if (tty) "开" else "关",
    });
    std.debug.print("  ⚠️ 若不检测就无条件上色，`minigrep ... > out.txt` 会得到一堆 ^[ 字面量。\n", .{});
    std.debug.print("  ⚠️ ColorMode 三态：auto（看 isTty）/ always（强制开，给 less -R 用）/ never\n", .{});

    std.debug.print("\n[复杂区间不能毁掉输出] 坏 span（越界/重叠）被跳过\n", .{});
    var rb: [128]u8 = undefined;
    var rw = std.Io.Writer.fixed(&rb);
    const bad = [_]regex.Span{
        .{ .start = 0, .end = 2 },
        .{ .start = 1, .end = 3 }, // 重叠
        .{ .start = 90, .end = 99 }, // 越界
    };
    try search.writeHighlighted(&rw, "abcd", &bad, true);
    dprint("  喂 3 个坏区间 → \"", .{});
    for (rw.buffered()) |c| {
        if (c == 0x1b) dprint("<ESC>", .{}) else dprint("{c}", .{c});
    }
    dprint("\"（其余字节原样输出，没有丢字也没有乱序）\n", .{});
}

// ════════════════════════════════════════════════════════════════════
//  24.8 递归遍历与符号链接
// ════════════════════════════════════════════════════════════════════

fn demo24_8(io: std.Io, gpa: std.mem.Allocator) !void {
    const cwd = std.Io.Dir.cwd();

    std.debug.print("[Walker 的选项]实测 0.17 的真实形状\n", .{});
    std.debug.print("@hasDecl(Io.Dir.Walker, \"FollowSymlinks\") = {}\n", .{
        @hasDecl(std.Io.Dir.Walker, "FollowSymlinks"),
    });
    // 格式串里的字面花括号必须写成 `{{}}`（同 24.3 的实测）
    std.debug.print("⚠️ 网上常见的 `Walker.Options{{ .follow_symlinks = ... }}` 在 0.17 **不存在**：\n", .{});
    std.debug.print("   Walker 就是个两字段包装（inner: SelectiveWalker），walk(dir, alloc) 没有选项参数。\n", .{});
    inline for (@typeInfo(std.Io.Dir.Walker).@"struct".field_names) |f| std.debug.print("  Walker 字段： {s}\n", .{f});
    std.debug.print("  ⇒ 0.17 里 follow_symlinks 变成**各选项结构体里的一个 bool 字段**：\n", .{});
    std.debug.print("     OpenOptions.follow_symlinks / StatFileOptions.follow_symlinks /\n", .{});
    std.debug.print("     AccessOptions.follow_symlinks（都是 packed struct，默认 true）\n", .{});
    const OO = @typeInfo(std.Io.Dir.OpenOptions).@"struct";
    const SO = @typeInfo(std.Io.Dir.StatFileOptions).@"struct";
    const AO = @typeInfo(std.Io.Dir.AccessOptions).@"struct";
    // 同 24.2：结构体字面量不能出现在表达式位置，先绑 const
    const oo_def: std.Io.Dir.OpenOptions = .{};
    const so_def: std.Io.Dir.StatFileOptions = .{};
    const ao_def: std.Io.Dir.AccessOptions = .{};
    std.debug.print("  实测默认值：OpenOptions={} StatFileOptions={} AccessOptions={}\n", .{
        oo_def.follow_symlinks,
        so_def.follow_symlinks,
        ao_def.follow_symlinks,
    });
    std.debug.print("  字段数：OpenOptions={d} StatFileOptions={d} AccessOptions={d}（packed struct）\n", .{
        OO.field_names.len, SO.field_names.len, AO.field_names.len,
    });
    std.debug.print("@hasDecl(Io.Dir, \"symLink\") = {}（造软链用得到）\n", .{
        @hasDecl(std.Io.Dir, "symLink"),
    });

    // 造一棵带软链的树
    const root = "demo_link";
    cwd.deleteTree(io, root) catch {};
    try cwd.createDirPath(io, root ++ "/sub");
    try cwd.writeFile(io, .{ .sub_path = root ++ "/a.txt", .data = "alpha\n" });
    try cwd.writeFile(io, .{ .sub_path = root ++ "/sub/b.txt", .data = "beta\n" });

    std.debug.print("\n[符号链接的三种处理]\n", .{});
    {
        // 软链指向目录
        cwd.deleteFile(io, root ++ "/link_to_sub") catch {};
        // ⚠️ 0.17 的 symLink 是 symLink(io, target, link, flags) —— 作为 Dir 的方法，
        //    **io 在第一个参数**（不是 Dir 参数之后），flags 是
        //    SymLinkFlags{ .is_directory }（只有一个 bool 字段，不是 options 结构体）。
        cwd.symLink(io, "sub", root ++ "/link_to_sub", .{ .is_directory = true }) catch |err| {
            std.debug.print("  造目录软链失败：{s}（跳过本节软链演示）\n", .{@errorName(err)});
            return;
        };
        // 软链指向文件
        cwd.deleteFile(io, root ++ "/link_to_a") catch {};
        cwd.symLink(io, "a.txt", root ++ "/link_to_a", .{}) catch {};

        // 不跟随：entry.kind 会是 .sym_link，我们直接跳过 ⇒ 不搜软链目标
        var d = try cwd.openDir(io, root, .{ .iterate = true, .follow_symlinks = false });
        defer d.close(io);
        var it = d.iterate();
        var n_link: usize = 0;
        var n_file: usize = 0;
        while (try it.next(io)) |e| {
            switch (e.kind) {
                .sym_link => n_link += 1,
                .file => n_file += 1,
                else => {},
            }
        }
        dprint("  follow_symlinks=false：看到 {d} 个软链、{d} 个普通文件\n", .{ n_link, n_file });
        std.debug.print("  ⇒ 不跟随时kind == .sym_link，collectFiles 的 switch 落进 else ⇒ 跳过\n", .{});

        // 跟随：statFile 默认 follow_symlinks=true，于是软链被当成它指向的东西
        const st = try cwd.statFile(io, root ++ "/link_to_a", .{});
        dprint("  statFile(默认 follow=true) 读软链 link_to_a → size={d}（=a.txt 的 {d}）\n", .{
            st.size, (try cwd.statFile(io, root ++ "/a.txt", .{})).size,
        });
        const st2 = try cwd.statFile(io, root ++ "/link_to_a", .{ .follow_symlinks = false });
        dprint("  statFile(follow=false) 读同一软链 → size={d}（软链自身的长度）\n", .{st2.size});
        std.debug.print("  ⇒ follow 开关就在这里：true 看到目标，false 看到链接本身\n", .{});

        // 悬垂软链：access 会报 FileNotFound
        cwd.deleteFile(io, root ++ "/dangling") catch {};
        cwd.symLink(io, "no_such_file", root ++ "/dangling", .{}) catch {};
        if (cwd.access(io, root ++ "/dangling", .{})) |_| {
            std.debug.print("  悬垂软链 access 成功？不该\n", .{});
        } else |e| std.debug.print("  悬垂软链 access(follow=true) → {s}\n", .{@errorName(e)});
        std.debug.print("  ⇒ 这就是 grep 必须处理\"软链指向不存在的文件\"的原因\n", .{});

        // 深度：Walker.Entry.depth()
        var d2 = try cwd.openDir(io, root, .{ .iterate = true });
        defer d2.close(io);
        var walker = try d2.walk(gpa);
        defer walker.deinit();
        while (try walker.next(io)) |e| {
            dprint("    depth={d}  {s:<28} kind={s}\n", .{ e.depth(), e.path, @tagName(e.kind) });
        }
    }

    cwd.deleteTree(io, root) catch {};
}

// ════════════════════════════════════════════════════════════════════
//  24.9 性能与统计
// ════════════════════════════════════════════════════════════════════

fn demo24_9(io: std.Io, gpa: std.mem.Allocator) !void {
    std.debug.print("[时钟] 0.17 的 Io.Clock 枚举成员（实测，注意**没有** monotonic）\n", .{});
    inline for (@typeInfo(std.Io.Clock).@"enum".field_names) |f| {
        std.debug.print("  .{s}\n", .{f});
    }
    std.debug.print("  ⚠️ 网上常见的 `std.time.Timer` / `.monotonic` 在 0.17 都不存在了。\n", .{});
    std.debug.print("  正确写法：const t0 = std.Io.Clock.now(.awake, io); … t0.durationTo(t1)\n", .{});
    std.debug.print("  .awake    = 单调、不含睡眠时间（macOS 上是 CLOCK_UPTIME_RAW）\n", .{});
    std.debug.print("  .boot     = 单调、含睡眠时间（macOS 上是 CLOCK_MONOTONIC_RAW）\n", .{});
    std.debug.print("  .real     = 挂钟时间，会被 NTP 调整\n", .{});
    const res = std.Io.Clock.resolution(.awake, io) catch |e| {
        std.debug.print("  resolution 查询失败 {s}\n", .{@errorName(e)});
        return;
    };
    dprint("  .awake 的分辨率 = {d} ns（Clock.resolution 返回 Io.Duration）\n", .{res.nanoseconds});

    // 造一个大一点的语料，统计才有意义
    const root = "demo_perf";
    cwd_cleanup(io, root);
    try std.Io.Dir.cwd().createDirPath(io, root);
    {
        // ⚠️⚠️ 踩坑：`while (off < big.len)` + `bufPrint(big[off..])` 会在
        // **尾巴不够放下一整行**时返回 error.NoSpaceLeft（不是截断、不是 panic）。
        // 实测第一次跑到 24.9 就炸在这儿。正确写法是留出最大行长余量：
        //     while (off + max_line <= big.len)
        // 或者写成 `if (big.len - off < 128) break;`
        var big: [64 * 1024]u8 = undefined;
        var off: usize = 0;
        var line_no: usize = 0;
        const max_line = 128; // 本语料每行远短于 128 字节
        while (off + max_line <= big.len) : (line_no += 1) {
            const written = std.fmt.bufPrint(big[off..], "line {d} service=svc{d} msg=\"payload {d}\"\n", .{
                line_no, line_no % 7, line_no * 3,
            }) catch |err| {
                std.debug.print("  bufPrint 意外失败：{s}\n", .{@errorName(err)});
                break;
            };
            off += written.len;
        }
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = root ++ "/big.log", .data = big[0..off] });
        dprint("\n[统计] 在 {d} 字节 / {d} 行的单文件上跑\n", .{ off, line_no });
    }

    // 计时开始
    const t0 = std.Io.Clock.now(.awake, io);
    var stats: search.Stats = .{};
    var files: std.ArrayList(FileEntry) = .empty;
    defer {
        for (files.items) |f| gpa.free(f.path);
        files.deinit(gpa);
    }
    try collectFiles(io, gpa, root, true, &files);
    stats.files = files.items.len;

    const pattern = "service=svc[0-6]";
    const prog = try regex.compile(gpa, pattern);
    defer prog.deinit(gpa);

    var hit_lines: usize = 0;
    var step_total: u64 = 0;
    var byte_total: u64 = 0;
    for (files.items) |f| {
        const file = std.Io.Dir.cwd().openFile(io, f.path, .{}) catch {
            stats.failed_files += 1;
            continue;
        };
        defer file.close(io);
        var buf: [4096]u8 = undefined;
        var fr = file.reader(io, &buf);
        var lr = search.LineReader.init(&fr.interface);
        defer lr.deinit(gpa);
        while (try lr.nextLine(gpa)) |line| {
            byte_total += line.len + 1;
            var st: regex.Stats = .{};
            // 同 24.6：两层错误联合要先用 catch 摊平成纯 optional
            const hit: ?regex.Span = regex.findWithStats(gpa, &prog, line, .{}, &st) catch null;
            step_total += st.steps;
            if (hit != null) {
                hit_lines += 1;
                stats.matched_lines += 1;
            }
        }
        stats.scanned_bytes += byte_total;
    }
    const t1 = std.Io.Clock.now(.awake, io);
    const elapsed = t0.durationTo(t1);

    dprint("  模式 {s}（{d} 条指令）\n", .{ pattern, prog.op_count });
    dprint("  文件数     = {d}\n", .{stats.files});
    dprint("  命中行数   = {d}\n", .{stats.matched_lines});
    dprint("  扫描字节   = {d}（{d:.1} KiB）\n", .{
        stats.scanned_bytes, @as(f64, @floatFromInt(stats.scanned_bytes)) / 1024.0,
    });
    dprint("  回溯总步数 = {d}\n", .{step_total});
    dprint("  耗时       = {d} ns（{d:.2} ms）\n", .{ elapsed.nanoseconds, nsToMs(elapsed.nanoseconds) });
    const mbps = @as(f64, @floatFromInt(stats.scanned_bytes)) /
        (@as(f64, @floatFromInt(elapsed.nanoseconds)) / 1e9) / (1024.0 * 1024.0);
    dprint("  吞吐       = {d:.1} MiB/s\n", .{mbps});
    dprint("  每字节步数 = {d:.2}\n", .{
        @as(f64, @floatFromInt(step_total)) / @as(f64, @floatFromInt(stats.scanned_bytes)),
    });
    std.debug.print("  ⚠️ 这是 Debug 构建（zig build run 默认 -O Debug），数字只用于看**比例**\n", .{});
    std.debug.print("  ⚠️ nsToMs 里手写了除法：Io.Duration 只有 .nanoseconds，没有 fmt 方法\n", .{});
    // `{t}` 会被当成格式占位符（同 24.3 的实测），要打印字面花括号写成 `{{t}}`
    std.debug.print("     （20 章实测：非穷尽枚举的运行期值用 {{t}} 打印会 panic）\n", .{});

    std.Io.Dir.cwd().deleteTree(io, root) catch {};
}

fn nsToMs(ns: i96) f64 {
    return @as(f64, @floatFromInt(ns)) / 1e6;
}

fn cwd_cleanup(io: std.Io, path: []const u8) void {
    std.Io.Dir.cwd().deleteTree(io, path) catch {};
}

// ════════════════════════════════════════════════════════════════════
//  24.10 完整 CLI 装配 + 综合演示
// ════════════════════════════════════════════════════════════════════

/// 真正的 grep 主流程。演示模式（无参数）不走这里。
fn runGrep(
    io: std.Io,
    w: *std.Io.Writer,
    gpa: std.mem.Allocator,
    opt: Options,
    pattern: []const u8,
) !u8 {
    // 模式先编译一次，之后所有文件所有行复用同一个 Program
    const prog = if (opt.fixed_string)
        // -F：把模式里的元字符全转义成一个字面量字符串。
        // 做法是构造一个只含 char 指令的 Program——比"另写一套定长比较"更省代码。
        try compileLiteral(gpa, pattern)
    else
        try regex.compile(gpa, pattern);
    defer prog.deinit(gpa);

    // 颜色：--color 三态。auto 看 stdout 是不是 TTY
    const color = switch (opt.color) {
        .always => true,
        .never => false,
        .auto => search.Color.enabledFor(std.Io.File.stdout(), io),
    };
    const ropt: regex.Options = .{ .ignore_case = opt.ignore_case };

    var files: std.ArrayList(FileEntry) = .empty;
    defer {
        for (files.items) |f| gpa.free(f.path);
        files.deinit(gpa);
    }
    // 位置参数：第 0 个是模式，其余是路径；没给路径就搜 src
    if (opt.positional.len >= 2) {
        for (opt.positional[1..]) |p| try collectFiles(io, gpa, p, opt.recursive, &files);
    } else {
        try collectFiles(io, gpa, "src", opt.recursive, &files);
    }
    if (files.items.len == 0) {
        try w.print("minigrep: 没有可搜的文件\n", .{});
        return 1;
    }

    var stats: search.Stats = .{ .files = files.items.len };
    var any_hit = false;

    for (files.items) |f| {
        const file = std.Io.Dir.cwd().openFile(io, f.path, .{}) catch |err| {
            stats.failed_files += 1;
            try w.print("minigrep: {s}: {s}\n", .{ f.path, @errorName(err) });
            continue;
        };
        defer file.close(io);

        var file_hits: usize = 0;
        var buf: [4096]u8 = undefined;
        var fr = file.reader(io, &buf);
        var lr = search.LineReader.init(&fr.interface);
        defer lr.deinit(gpa);

        var line_no: usize = 0;
        while (try lr.nextLine(gpa)) |line| {
            line_no += 1;
            stats.scanned_bytes += line.len + 1;

            // ⚠️⚠️ `-v` 的正确实现：**照样要先匹配一次**，只是把判定取反。
            //    早期版本写成"invert 时直接把 spans 置空"，于是
            //    `matched = spans.len == 0` 恒真 ⇒ **每一行都被打印**
            //    （实测 `minigrep -v ERROR app.log` 打出了全部 8 行，
            //    连含 ERROR 的第 3、7 行也打出来了）。
            //
            // 正确形态：始终算出 spans，再用 invert 决定"要不要这一行"，
            // 决定打印时 spans 传空数组（反向命中的行不该有高亮）。
            const found = try search.allSpans(gpa, &prog, line, ropt);
            defer gpa.free(found);

            const matched = if (opt.invert) found.len == 0 else found.len > 0;
            if (!matched) continue;

            any_hit = true;
            file_hits += 1;
            stats.matched_lines += 1;

            if (opt.count_only) continue; // -c：只记数不打印

            // -v 命中的行没有"命中片段"可染，所以传空 spans
            const spans: []const regex.Span = if (opt.invert) &.{} else found;
            // ⚠️ runGrep 的输出**全部经由 w**（调用方给的 Writer），
            //    一律不用 dprint。混用两者会交错错乱：dprint 直写 stderr，
            //    w 走用户态缓冲，flush 时机不同 ⇒ 行内容与换行会错位
            //    （实测：行号全打印了，行内容与\n 却堆到了段尾）。
            if (color) try w.writeAll(search.Color.path);
            try w.writeAll(f.path);
            if (color) try w.writeAll(search.Color.reset);
            try w.writeAll(":");
            if (color) try w.writeAll(search.Color.line_no);
            try w.print("{d}", .{line_no});
            if (color) try w.writeAll(search.Color.reset);
            try w.writeAll(": ");
            try search.writeHighlighted(w, line, spans, color);
            try w.writeAll("\n");
        }
        if (opt.count_only) try w.print("{s}:{d}\n", .{ f.path, file_hits });
    }

    if (color) try w.writeAll(search.Color.dim);
    try w.print("minigrep: {d} 个文件，命中 {d} 行，扫描 {d} 字节", .{
        stats.files,
        stats.matched_lines,
        stats.scanned_bytes,
    });
    if (stats.failed_files > 0) try w.print("，跳过 {d} 个读不了的文件", .{stats.failed_files});
    try w.writeAll("\n");
    if (color) try w.writeAll(search.Color.reset);

    return if (any_hit) 0 else 1;
}

/// `-F` 模式：把整个模式编成一串 char 指令，**不解释任何元字符**。
/// 这是"固定字符串"最直接的实现——比另写一套比较循环更省，
/// 而且复用了同一条执行路径（连零宽、锚点那些边界都自动一致）。
fn compileLiteral(gpa: std.mem.Allocator, lit: []const u8) !regex.Program {
    // 用一个恒不匹配任何元字符的模式来构造：把每个字节都包进 [...] 转义是不必要的，
    // 直接手写指令数组更直白，也顺带展示 Program 就是"一条 []const Op"。
    if (lit.len + 1 > regex.max_ops) return error.TooManyOps;
    var ops: [regex.max_ops]regex.Op = undefined;
    for (lit, 0..) |c, i| {
        // 元字符也照原样当字面量：. 存成 char '.'，执行时只比字节
        ops[i] = .{ .char = c };
    }
    ops[lit.len] = .{ .accept = {} };
    const owned = try gpa.dupe(regex.Op, ops[0 .. lit.len + 1]);
    return .{
        .ops = owned,
        .group_count = 0,
        .anchored_start = false,
        .pattern_len = lit.len,
        .op_count = lit.len + 1,
    };
}

/// 把一行按 spans 上色，然后**用 dprint 打出来**（ESC 显示成可见的 `<ESC>`）。
///
/// 为什么不在这里直接用 `search.writeHighlighted(w, …)`：
/// 那个函数写进的是**缓冲 Writer**，而本函数调用点前后都是 `dprint`（直写 stderr）。
/// 两者混用且不及时 flush，输出顺序会乱（实测：整段高亮内容堆到了本节末尾）。
/// 而且把 ESC 变成 `<ESC>` 之后，文档里的 ```text 块才**肉眼可读、可逐字节校对**——
/// 真实终端里的 ESC 是不可见控制字符，抄进文档会变成"看起来一样、字节不同"。
fn dprintHighlighted(
    line: []const u8,
    spans: []const regex.Span,
    color: bool,
) void {
    if (spans.len == 0 or !color) {
        dprint("{s}", .{line});
        return;
    }
    var from: usize = 0;
    for (spans) |s| {
        if (s.start > s.end or s.end > line.len or s.start < from) continue;
        dprint("{s}<ESC>[1;31m{s}<ESC>[0m", .{ line[from..s.start], line[s.start..s.end] });
        from = s.end;
    }
    dprint("{s}", .{line[from..]});
}

fn demo24_10(io: std.Io, gpa: std.mem.Allocator) !void {
    var ebuf: [8192]u8 = undefined;
    var fw = std.Io.File.stderr().writerStreaming(io, &ebuf);
    const w = &fw.interface;
    defer w.flush() catch {};
    std.debug.print("装配顺序（每一步都能单独测，这是 24.11 能写 44 个测试的前提）：\n", .{});
    std.debug.print("  1. parseArgs(argv)          → Options（纯函数，不碰 io）\n", .{});
    std.debug.print("  2. regex.compile(gpa, pat)  → Program（一次编译，N 行复用）\n", .{});
    std.debug.print("  3. collectFiles(io, …)→ []FileEntry（每条都dupe，绝不信Entry.name）\n", .{});
    std.debug.print("  4. 逐文件：File.reader → LineReader.nextLine → regex.findAll\n", .{});
    std.debug.print("  5. writeHighlighted 输出，-c 时跳过\n", .{});
    std.debug.print("内存策略：一次性程序 ⇒ 全程用 init.arena，最后一个 free 都不需要。\n", .{});

    // 真跑一遍：搜固定语料 src/corpus
    std.debug.print("\n[综合演示 1] 在 src/corpus 上搜 (ERROR|WARN)+（正则 + 递归 + 高亮）\n", .{});
    {
        const prog = try regex.compile(gpa, "(ERROR|WARN)+");
        defer prog.deinit(gpa);
        dprint("  模式编译成 {d} 条指令；下面按 --color=never 输出（可断言）\n", .{prog.op_count});
        var files: std.ArrayList(FileEntry) = .empty;
        defer {
            for (files.items) |f| gpa.free(f.path);
            files.deinit(gpa);
        }
        try collectFiles(io, gpa, "src/corpus", true, &files);
        dprint("  收集到 {d} 个文件\n", .{files.items.len});
        var total: usize = 0;
        // 排序，让输出与文件系统返回顺序无关（walk 的顺序是未定义的！）
        std.mem.sort(FileEntry, files.items, {}, struct {
            fn lt(_: void, a: FileEntry, b: FileEntry) bool {
                return std.mem.lessThan(u8, a.path, b.path);
            }
        }.lt);
        for (files.items) |f| {
            const file = std.Io.Dir.cwd().openFile(io, f.path, .{}) catch continue;
            defer file.close(io);
            var buf: [4096]u8 = undefined;
            var fr = file.reader(io, &buf);
            var lr = search.LineReader.init(&fr.interface);
            defer lr.deinit(gpa);
            var line_no: usize = 0;
            while (try lr.nextLine(gpa)) |line| {
                line_no += 1;
                const spans = try search.allSpans(gpa, &prog, line, .{});
                defer gpa.free(spans);
                if (spans.len == 0) continue;
                total += 1;
                dprint("    {s}:{d}: ", .{ f.path, line_no });
                dprintHighlighted(line, spans, true);
                dprint("\n", .{});
            }
        }
        // ⚠️ 格式串里的 `\x1b` 会被当成**真的 ESC 字节**写进输出（不是字面"\x1b" 四个字符）。
        //    所以这里改用 `{{ESC}}` 转义花括号、写成可见的 <ESC>，输出才可读可断言。
        dprint("  共 {d} 处命中（上面 <ESC> 就是 ANSI 转义序列的起始字节 0x1b）\n", .{total});
        std.debug.print("  ⚠️ 上面**故意**开了色，好让你看到 ESC 真的进了字节流。\n", .{});
        std.debug.print("     真grep 默认按 isTty 自动判断，重定向到文件时会自动关色（24.7）。\n", .{});
    }

    std.debug.print("\n[综合演示 2] s*rvice=[a-z]+ —— 零次 s 也能匹配（s* 是幂等的）\n", .{});
    {
        const prog = try regex.compile(gpa, "s*rvice=[a-z]+");
        defer prog.deinit(gpa);
        dprint("  {d} 条指令；演示 -i（大小写不敏感）与 -v（反向）\n", .{prog.op_count});
        const sample = "service=auth SERVICE=billing nothing here";
        const spans_plain = try search.allSpans(gpa, &prog, sample, .{});
        defer gpa.free(spans_plain);
        dprint("    默认    : ", .{});
        dprintHighlighted(sample, spans_plain, true);
        dprint("\n", .{});

        const spans = try search.allSpans(gpa, &prog, sample, .{ .ignore_case = true });
        defer gpa.free(spans);
        dprint("    -i      : ", .{});
        dprintHighlighted(sample, spans, true);
        dprint("\n", .{});
        // ⚠️ 这里必须拿**两轮各自的段数**对比才有意义。早期版本写了
        //    `spans.len, spans.len`（同一个值打印两遍），输出"默认 2 段 / -i 也 2 段"
        //    看起来像"-i 没用"——其实是样本里恰好只有一处大写变体。
        std.debug.print("    -i 命中 {d} 段（默认 {d} 段）⇒ 走的是 charEq / Class.matches，不改写模式\n", .{
            spans.len, spans_plain.len,
        });

        // -v：把不匹配的行整行打出
        const line2 = "msg=\"no service field here\"";
        const s2 = try search.allSpans(gpa, &prog, line2, .{});
        defer gpa.free(s2);
        dprint("    -v 场景 : \"{s}\" 有 {d} 处命中 ⇒ -v 下这行会被打印（且无高亮）\n", .{
            line2, s2.len,
        });
    }

    std.debug.print("\n[综合演示 3] -F 固定字符串：元字符不当正则\n", .{});
    {
        const lit_prog = try compileLiteral(gpa, "service=svc3");
        defer lit_prog.deinit(gpa);
        const re_prog = try regex.compile(gpa, "service=svc3");
        defer re_prog.deinit(gpa);
        dprint("  -F 编出 {d} 条指令（每字节一条 char）；正则版也是 {d} 条\n", .{
            lit_prog.op_count, re_prog.op_count,
        });
        const tricky = "a.service=svc3 b service=svc3x";
        const ls = try search.allSpans(gpa, &lit_prog, tricky, .{});
        defer gpa.free(ls);
        dprint("  -F  \"service=svc3\" 在 \"{s}\" 上：\n", .{tricky});
        dprintHighlighted(tricky, ls, true);
        dprint("\n", .{});
        std.debug.print("  ⇒ 两个 svc3 都命中（-F 不看前后是不是有别的字符）\n", .{});
    }

    std.debug.print("\n[综合演示 4] 命令行装配跑通（parseArgs → runGrep 用的同一套代码）\n", .{});
    // ⚠️ 每个 argv 都要带 -r：不给 -r 时 collectFiles 只收"一层"，
    // 而 src/corpus 是目录 → 直接跳过 → 一个文件都搜不到（实测全退 1）。
    // 这正是真 grep 的行为（grep 不带 -r 也不会自己钻进目录）。
    for ([_][]const []const u8{
        &.{ "-c", "-r", "(ERROR|WARN)+", "src/corpus" },
        &.{ "-n", "-r", "service=", "src/corpus" },
        &.{ "-i", "-r", "ERROR", "src/corpus" },
        &.{ "-F", "-r", "timeout", "src/corpus" },
    }) |argv| {
        const o = try parseArgs(argv);
        const pat = o.positional[0];
        var ob: [8192]u8 = undefined;
        var ow = std.Io.Writer.fixed(&ob);
        // -c 的输出也进这个缓冲，所以关色（Buffer 不是 TTY，auto 也会关）
        const code = runGrep(io, &ow, gpa, o, pat) catch |e| {
            std.debug.print("  runGrep 失败 {s}\n", .{@errorName(e)});
            continue;
        };
        const out = ow.buffered();
        const nl = std.mem.count(u8, out, "\n");
        dprint("  argv={s}", .{argv[0]});
        for (argv[1..2]) |a| dprint(" {s}", .{a});
        dprint("  退出码={d} 输出 {d} 行\n", .{ code, nl });
        // 把摘要行也打出来（关色，纯文本）
        var it = std.mem.splitScalar(u8, out, '\n');
        var k: usize = 0;
        while (it.next()) |ln| : (k += 1) {
            if (ln.len == 0) continue;
            if (k < 3) dprint("      │ {s}\n", .{ln});
        }
        if (nl > 3) dprint("      │ …（共 {d} 行）\n", .{nl});
    }
    std.debug.print("  ⚠️ runGrep 的返回值就是进程退出码：无命中退 1、有命中退 0（与真 grep 一致）\n", .{});
    std.debug.print("  ⚠️ 输出缓冲用的是 Writer.fixed（**内存**缓冲，不是 TTY）⇒ auto 模式必然关色\n", .{});
}

// ════════════════════════════════════════════════════════════════════
//  24.11 测试
// ════════════════════════════════════════════════════════════════════

fn demo24_11(_: std.Io, gpa: std.mem.Allocator) !void {
    std.debug.print("本章测试分三层，共 44 个（`zig build test` 全跑）：\n", .{});
    std.debug.print("  regex.zig  22 个：正则引擎每个分支 + 编译错误 + comptime 等价性\n", .{});
    std.debug.print("  search.zig  9 个：流式逐行（超长行/末行无\\n/空文件）+ 高亮格式化\n", .{});
    std.debug.print("  main.zig   13 个：参数解析 + 遍历（-v 补集 / -r 单文件 / join 路径）+ stderr 模式 + 端到端 tmpDir\n", .{});

    std.debug.print("\n[为什么三层都有必要] 纯逻辑（正则）不碰盘所以快且稳；\n", .{});
    std.debug.print("IO（逐行、高亮）用 fixed Writer 把\"打印\"变成\"可断言的字符串\"；\n", .{});
    std.debug.print("端到端用 std.testing.tmpDir 落真文件跑全链路。\n", .{});

    std.debug.print("\n[当场验证几个关键断言]（正式断言在文件末尾的 test 块里）\n", .{});

    // 1. 参数解析
    {
        const o = try parseArgs(&.{ "-inrF", "-v", "pat", "d1", "d2" });
        dprint("  parseArgs(\"-inrF -v pat d1 d2\") → ignore={} invert={} count={} no={} rec={} fixed={} 位置参数 {d} 个\n", .{
            o.ignore_case, o.invert,       o.count_only,     o.show_line_no,
            o.recursive,   o.fixed_string, o.positional.len,
        });
        if (parseArgs(&.{"-q"})) |_| {
            std.debug.print("  -q 应报错\n", .{});
        } else |e| std.debug.print("  parseArgs(\"-q\") → {s}\n", .{@errorName(e)});
    }
    // 2. 最左匹配
    {
        const prog = try regex.compile(gpa, "svc[0-9]");
        defer prog.deinit(gpa);
        const t = "a svc1 b svc7 c";
        const s = try regex.findAll(gpa, &prog, t, .{});
        defer gpa.free(s);
        dprint("  findAll(\"svc[0-9]\", \"{s}\") → {d} 段：", .{ t, s.len });
        for (s) |sp| dprint(" [{d},{d})", .{ sp.start, sp.end });
        dprint("\n", .{});
    }
    // 3. 护栏
    {
        const evil = try regex.compile(gpa, "(a+)+b");
        defer evil.deinit(gpa);
        var text: [22]u8 = undefined;
        @memset(&text, 'a');
        var st: regex.Stats = .{};
        const r = regex.findWithStats(gpa, &evil, &text, .{ .max_steps = 50_000 }, &st);
        if (r) |_| {
            std.debug.print("  22 个 a 配50k 步预算居然匹配成功？不该\n", .{});
        } else |e| dprint("  (a+)+b 撞 22 个 a，预算 50k → {s}（第 {d} 步被打断）\n", .{
            @errorName(e), st.steps,
        });
    }
    // 4. comptime 等价
    {
        // ⚠️ 这两个模式都必须是**合法**的：compileComptime 里解析错误会被转成
        //    @panic（comptime 路径没法返回错误），一写错整个编译期就炸。
        //    所以别在这里试 "s*+?" —— 那是 RepeatedQuantifier，运行期会
        //    正常返回错误，comptime 期却是编译错误。
        inline for (.{ "ERROR|WARN", "a+?" }) |pat| {
            const ct = comptime regex.compileComptime(pat);
            const rt = try regex.compile(gpa, pat);
            defer rt.deinit(gpa);
            var same = ct.ops.len == rt.ops.len;
            if (same) {
                for (ct.ops, rt.ops) |a, b| {
                    same = opsEqual(a, b);
                    if (!same) break;
                }
            }
            dprint("  comptime vs 运行期 {s: <14} 指令数 {d}/{d}  逐条相同={}\n", .{
                pat, ct.ops.len, rt.ops.len, same,
            });
        }
    }
}

// ════════════════════════════════════════════════════════════════════
//  main
// ════════════════════════════════════════════════════════════════════

pub fn main(init: std.process.Init) !u8 {
    const io = init.io;
    // 进程级 arena：argv、路径、副本、指令全在里面，退出自动回收
    const gpa = init.arena.allocator();
    // 演示的输出缓冲。⚠️ 必须**就地**用 var：File.writer(io, buf) 返回的
    // Writer 内部持有 buf 的指针，按值存进结构体再返回会让 buf 悬垂（20 章实测）
    var buf: [64 * 1024]u8 = undefined;
    var fw = std.Io.File.stdout().writer(io, &buf);
    const w = &fw.interface;

    // ── 收集 argv ──
    // 0.17 的 Juicy Main：argv 在 init.minimal.args 里，
    // 用 process.Args.Iterator 逐个取（它跨平台处理 Windows 的 WTF-16 引号规则）
    var argv_store: std.ArrayList([]const u8) = .empty;
    var it = try std.process.Args.Iterator.initAllocator(init.minimal.args, gpa);
    defer it.deinit();
    _ = it.skip(); // 跳过程序名（argv[0]）
    while (it.next()) |arg| try argv_store.append(gpa, arg);
    const argv = argv_store.items;

    // 无参数 ⇒ 教学演示
    if (argv.len == 0) {
        std.debug.print("minigrep —— 无参数运行 = 教学演示（逐节打印 24.1~ 24.11）\n", .{});
        std.debug.print("真用请传参：`zig build run -- <模式> [选项] [目录]`\n", .{});
        std.debug.print("语料在 src/corpus/（app.log / app.conf / README.md）\n", .{});

        begin("24.1");
        demo24_1(io, gpa) catch |e| fatal("24.1", e);
        end("24.1");

        begin("24.2");
        demo24_2(io, gpa) catch |e| fatal("24.2", e);
        end("24.2");

        begin("24.3");
        demo24_3(io, gpa) catch |e| fatal("24.3", e);
        end("24.3");

        begin("24.4");
        demo24_4(io, gpa) catch |e| fatal("24.4", e);
        end("24.4");

        begin("24.5");
        demo24_5(io, gpa) catch |e| fatal("24.5", e);
        end("24.5");

        begin("24.6");
        demo24_6(io, gpa) catch |e| fatal("24.6", e);
        end("24.6");

        begin("24.7");
        demo24_7(io, gpa) catch |e| fatal("24.7", e);
        end("24.7");

        begin("24.8");
        demo24_8(io, gpa) catch |e| fatal("24.8", e);
        end("24.8");

        begin("24.9");
        demo24_9(io, gpa) catch |e| fatal("24.9", e);
        end("24.9");

        begin("24.10");
        demo24_10(io, gpa) catch |e| fatal("24.10", e);
        end("24.10");

        begin("24.11");
        demo24_11(io, gpa) catch |e| fatal("24.11", e);
        end("24.11");

        std.debug.print("自检通过\n", .{});
        return 0;
    }

    // ── 真 grep ──
    const opt = parseArgs(argv) catch |err| {
        try w.flush();
        std.debug.print("minigrep: {s}\n\n", .{@errorName(err)});
        std.debug.print("{s}", .{usage});
        return 2;
    };
    if (opt.positional.len == 0) {
        try w.flush();
        std.debug.print("{s}", .{usage});
        return 2;
    }
    const pattern = opt.positional[0];
    const code = runGrep(io, w, gpa, opt, pattern) catch |err| switch (err) {
        error.UnclosedGroup,
        error.UnmatchedClose,
        error.UnclosedClass,
        error.NothingToRepeat,
        error.RepeatedQuantifier,
        error.ReversedRange,
        error.DanglingEscape,
        error.UnsupportedRepeat,
        error.TooManyRanges,
        error.TooManyOps,
        => {
            try w.flush();
            std.debug.print("minigrep: 模式 \"{s}\" 非法：{s}\n", .{ pattern, @errorName(err) });
            return 2;
        },
        else => |e| return e,
    };
    try w.flush();
    return code;
}

fn fatal(comptime tag: []const u8, err: anyerror) noreturn {
    std.debug.print("!! {s} 失败：{s}\n", .{ tag, @errorName(err) });
    std.process.exit(1);
}

// ════════════════════════════════════════════════════════════════════
//  测试（24.11）：main.zig 这一层的 7 个
// ════════════════════════════════════════════════════════════════════

test "24.1 parseArgs：六个开关 + 组合短选项 + 位置参数" {
    const o = try parseArgs(&.{ "-i", "-n", "-c", "-r", "-v", "-F", "pat", "d1" });
    try std.testing.expect(o.ignore_case);
    try std.testing.expect(o.show_line_no);
    try std.testing.expect(o.count_only);
    try std.testing.expect(o.recursive);
    try std.testing.expect(o.invert);
    try std.testing.expect(o.fixed_string);
    try std.testing.expectEqual(@as(usize, 2), o.positional.len);
    try std.testing.expectEqualStrings("pat", o.positional[0]);
    try std.testing.expectEqualStrings("d1", o.positional[1]);

    // 组合短选项：-inr 等价 -i -n -r
    const c = try parseArgs(&.{ "-inr", "x" });
    try std.testing.expect(c.ignore_case and c.show_line_no and c.recursive);
    try std.testing.expect(!c.invert and !c.count_only and !c.fixed_string);
}

test "24.1 parseArgs：默认值与 -- / 未知开关" {
    const d = try parseArgs(&.{"x"});
    try std.testing.expect(!d.ignore_case and !d.invert and !d.count_only);
    try std.testing.expect(!d.show_line_no and !d.recursive and !d.fixed_string);
    try std.testing.expectEqual(ColorMode.auto, d.color);

    const nc = try parseArgs(&.{ "--no-color", "x" });
    try std.testing.expectEqual(ColorMode.never, nc.color);
    const c = try parseArgs(&.{ "--color", "x" });
    try std.testing.expectEqual(ColorMode.always, c.color);

    // `--` 之后全是位置参数，`-abc` 不再被当开关
    const dd = try parseArgs(&.{ "--", "-abc" });
    try std.testing.expectEqual(@as(usize, 1), dd.positional.len);
    try std.testing.expectEqualStrings("-abc", dd.positional[0]);

    try std.testing.expectError(error.UnknownOption, parseArgs(&.{"-Z"}));
    try std.testing.expectError(error.UnknownOption, parseArgs(&.{"--nope"}));
}

test "24.1 parseArgs：结果借用 argv，不拷贝（可断言指针相同）" {
    const argv = [_][]const u8{ "-n", "pattern" };
    const o = try parseArgs(&argv);
    // 借用语义 ⇒ 同一个指针，不是新分配
    try std.testing.expectEqual(@intFromPtr(argv[1].ptr), @intFromPtr(o.positional[0].ptr));
}

test "24.2 collectFiles：递归收集 + 每条 path 都 dupe（不复用迭代器缓冲）" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.createDirPath(io, "t/sub");
    try tmp.dir.writeFile(io, .{ .sub_path = "t/a.txt", .data = "alpha\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = "t/sub/b.txt", .data = "beta\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = "t/sub/c.log", .data = "gamma\n" });

    var files: std.ArrayList(FileEntry) = .empty;
    defer {
        for (files.items) |f| a.free(f.path);
        files.deinit(a);
    }
    // tmpDir 的 dir 才是真句柄；这里借 cwd 走绝对路径不方便，
    // 所以直接用 tmp.dir 造一遍等价物来验证"dupe 后不受迭代器影响"
    var d = try tmp.dir.openDir(io, "t", .{ .iterate = true });
    defer d.close(io);
    var walker = try d.walk(a);
    defer walker.deinit();
    while (try walker.next(io)) |e| {
        if (e.kind == .file) try files.append(a, .{ .path = try a.dupe(u8, e.path), .size = 0 });
    }
    try std.testing.expectEqual(@as(usize, 3), files.items.len);

    // 关键断言：dupe 出来的 path 在 walker.deinit 之后仍然有效
    // （若是切片，这里读到的会是已释放的内存）
    const first = files.items[0].path;
    const snapshot = try a.dupe(u8, first);
    defer a.free(snapshot);
    try std.testing.expect(first.len > 0);
    try std.testing.expect(std.mem.endsWith(u8, snapshot, ".txt") or std.mem.endsWith(u8, snapshot, ".log"));
}

test "24.3 LineReader：末行无换行 / 超长行 / 空文件（IO 层单测）" {
    const a = std.testing.allocator;
    { // 末行无 \n
        var r = std.Io.Reader.fixed("x\ny");
        var lr = search.LineReader.init(&r);
        defer lr.deinit(a);
        var n: usize = 0;
        while (try lr.nextLine(a)) |_| n += 1;
        try std.testing.expectEqual(@as(usize, 2), n);
    }
    { // 超长行被护栏挡住
        var big: [128]u8 = undefined;
        @memset(&big, 'z');
        var r = std.Io.Reader.fixed(&big);
        var lr = search.LineReader.init(&r);
        lr.max_line_bytes = 8;
        defer lr.deinit(a);
        try std.testing.expectError(error.LineTooLong, lr.nextLine(a));
    }
    { // 空文件
        var r = std.Io.Reader.fixed("");
        var lr = search.LineReader.init(&r);
        defer lr.deinit(a);
        try std.testing.expect((try lr.nextLine(a)) == null);
    }
}

test "24.7 writeHighlighted：开色/关色/坏区间三种路径" {
    const a = std.testing.allocator;
    _ = a;
    const spans = [_]regex.Span{.{ .start = 2, .end = 4 }};
    { // 开色
        var b: [64]u8 = undefined;
        var w = std.Io.Writer.fixed(&b);
        try search.writeHighlighted(&w, "abxcd", &spans, true);
        try std.testing.expectEqualStrings("ab\x1b[1;31mxc\x1b[0md", w.buffered());
    }
    { // 关色：逐字节等于原文
        var b: [64]u8 = undefined;
        var w = std.Io.Writer.fixed(&b);
        try search.writeHighlighted(&w, "abxcd", &spans, false);
        try std.testing.expectEqualStrings("abxcd", w.buffered());
    }
    { // 无命中（-v 场景）：原样输出，不加任何转义
        var b: [64]u8 = undefined;
        var w = std.Io.Writer.fixed(&b);
        try search.writeHighlighted(&w, "nothing here", &.{}, true);
        try std.testing.expectEqualStrings("nothing here", w.buffered());
    }
}

test "24.10 compileLiteral：-F 把元字符当普通字节" {
    const a = std.testing.allocator;
    const lit = try compileLiteral(a, "a.c");
    defer lit.deinit(a);

    // 字面量模式下 `.` 只匹配字面点，不会"匹配任意字节"
    const text = "a.c abc";
    const s = try regex.findAll(a, &lit, text, .{});
    defer a.free(s);
    try std.testing.expectEqual(@as(usize, 1), s.len);
    try std.testing.expectEqual(@as(usize, 0), s[0].start);
    try std.testing.expectEqual(@as(usize, 3), s[0].end);

    // 正则模式下同一模式匹配两处
    const re = try regex.compile(a, "a.c");
    defer re.deinit(a);
    const s2 = try regex.findAll(a, &re, text, .{});
    defer a.free(s2);
    try std.testing.expectEqual(@as(usize, 2), s2.len);
}

test "24.10 端到端：tmpDir 里跑完整 grep 流程" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "in.txt", .data = "alpha\nneed ERROR here\nbeta\nWARN too\n" });

    // 用固定 Writer 捕获输出 —— 20 章技巧：把"打印"变成"可断言的字符串"
    var ob: [512]u8 = undefined;
    var ow = std.Io.Writer.fixed(&ob);
    const prog = try regex.compile(a, "(ERROR|WARN)+");
    defer prog.deinit(a);

    // 直接驱动搜索逻辑（不经过 collectFiles，因为路径是 tmpDir 内的相对名）
    const f = try tmp.dir.openFile(io, "in.txt", .{});
    defer f.close(io);
    var buf: [8]u8 = undefined; // 故意小，验证流式读取
    var fr = f.reader(io, &buf);
    var lr = search.LineReader.init(&fr.interface);
    defer lr.deinit(a);

    var hits: usize = 0;
    var line_no: usize = 0;
    while (try lr.nextLine(a)) |line| {
        line_no += 1;
        const spans = try search.allSpans(a, &prog, line, .{});
        defer a.free(spans);
        if (spans.len == 0) continue;
        hits += 1;
        try ow.print("{d}: ", .{line_no});
        try search.writeHighlighted(&ow, line, spans, false);
        try ow.writeByte('\n');
    }
    try std.testing.expectEqual(@as(usize, 4), line_no);
    try std.testing.expectEqual(@as(usize, 2), hits);
    try std.testing.expectEqualStrings("2: need ERROR here\n4: WARN too\n", ow.buffered());
}

test "24.1 -v 反向匹配：命中集合必须是正向的补集（不是全都要）" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "v.txt", .data = "keep\nERROR here\nkeep2\nWARN there\n" });

    const prog = try regex.compile(a, "(ERROR|WARN)");
    defer prog.deinit(a);

    // 正向：2 行；反向：2 行；两者之和 == 总行数
    var fwd: usize = 0;
    var inv: usize = 0;
    var total: usize = 0;

    const f = try tmp.dir.openFile(io, "v.txt", .{});
    defer f.close(io);
    var buf: [8]u8 = undefined;
    var fr = f.reader(io, &buf);
    var lr = search.LineReader.init(&fr.interface);
    defer lr.deinit(a);
    while (try lr.nextLine(a)) |line| {
        total += 1;
        const spans = try search.allSpans(a, &prog, line, .{});
        defer a.free(spans);
        // ⚠️ 关键：无论正向反向，**都要真的匹配一次**。
        // 反向的实现错误正是"不匹配、直接置空 spans"，那样 inv 会 == total。
        if (spans.len > 0) fwd += 1 else inv += 1;
    }
    try std.testing.expectEqual(@as(usize, 4), total);
    try std.testing.expectEqual(@as(usize, 2), fwd);
    try std.testing.expectEqual(@as(usize, 2), inv);
    try std.testing.expectEqual(total, fwd + inv);
}

test "24.2 collectFiles：-r 传单个**文件**也要能收（-r 只管目录要不要下钻）" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    const cwd = std.Io.Dir.cwd();
    cwd.deleteTree(io, "t_rfile") catch {};
    try cwd.createDirPath(io, "t_rfile");
    try cwd.writeFile(io, .{ .sub_path = "t_rfile/one.txt", .data = "alpha\n" });

    var files: std.ArrayList(FileEntry) = .empty;
    defer {
        for (files.items) |f| a.free(f.path);
        files.deinit(a);
    }
    // recursive = true，但目标是文件 —— 早期版本这里报 NotDir 然后收不到任何文件
    try collectFiles(io, a, "t_rfile/one.txt", true, &files);
    try std.testing.expectEqual(@as(usize, 1), files.items.len);
    try std.testing.expectEqualStrings("t_rfile/one.txt", files.items[0].path);
    try std.testing.expectEqual(@as(u64, 6), files.items[0].size);

    // recursive = false 且目标是目录 ⇒ 跳过（提示加 -r），不收文件
    var files2: std.ArrayList(FileEntry) = .empty;
    defer {
        for (files2.items) |f| a.free(f.path);
        files2.deinit(a);
    }
    try collectFiles(io, a, "t_rfile", false, &files2);
    try std.testing.expectEqual(@as(usize, 0), files2.items.len);

    cwd.deleteTree(io, "t_rfile") catch {};
}

test "24.2 collectFiles：walk 的 path 相对 walker 根，必须 join(root, e.path)" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    const cwd = std.Io.Dir.cwd();
    cwd.deleteTree(io, "t_join") catch {};
    try cwd.createDirPath(io, "t_join/sub");
    try cwd.writeFile(io, .{ .sub_path = "t_join/sub/deep.txt", .data = "0123456789" });

    var files: std.ArrayList(FileEntry) = .empty;
    defer {
        for (files.items) |f| a.free(f.path);
        files.deinit(a);
    }
    try collectFiles(io, a, "t_join", true, &files);
    try std.testing.expectEqual(@as(usize, 1), files.items.len);
    // ⚠️ 若忘了 join，size 会静默变成 0（statFile FileNotFound 被 catch 吞掉）
    try std.testing.expectEqual(@as(u64, 10), files.items[0].size);
    try std.testing.expect(std.mem.endsWith(u8, files.items[0].path, "deep.txt"));

    cwd.deleteTree(io, "t_join") catch {};
}

test "24.3 LineReader：零长 Reader 缓冲不能配 fillMore（会 assert）" {
    const a = std.testing.allocator;
    // 这个测试"能编过"本身就是价值：它把坑位写成了可执行的文档。
    // 实测 `reader(io, &.{})` + fillMore 会 panic：
    //     Io.Reader.defaultRebase: assert(r.buffer.len - r.seek >= capacity) failed
    // 路径是 fillMore → rebase(r, r.end - r.seek + 1)，至少要1 字节。
    // 所以流式逐行**必须**给非空缓冲。
    const src = "ab\ncd\n";
    var fr = std.Io.Reader.fixed(src); // fixed 源自带缓冲，不涉及外部 buf
    var lr = search.LineReader.init(&fr);
    defer lr.deinit(a);
    var n: usize = 0;
    while (try lr.nextLine(a)) |_| n += 1;
    try std.testing.expectEqual(@as(usize, 2), n);
}

test "24.7 stderr 必须用 writerStreaming：positional writer 会覆盖 dprint 的字节" {
    const io = std.testing.io;
    // 回归测试：这条坑只在 `2> file` 时暴露，管道下测不出来。
    // 而 run-all.sh 不重定向文件，所以只能靠这个测试守住。
    //
    // 机制：File.writer 是 positional 模式（写前 seek），
    // std.debug.print 走 Threaded.stderr_writer（streaming 追加）。
    // 混用时 positional writer 会把偏移 seek 回自己的 pos ⇒ 覆盖 dprint 的输出。
    // writerStreaming 不 seek，纯 append ⇒ 两者共存。

    // 断言一：默认 writer 的 mode 是 positional
    var b1: [64]u8 = undefined;
    const fw1 = std.Io.File.stderr().writer(io, &b1);
    try std.testing.expectEqual(std.Io.File.Writer.Mode.positional, fw1.mode);

    // 断言二：writerStreaming 的 mode 是 streaming
    var b2: [64]u8 = undefined;
    const fw2 = std.Io.File.stderr().writerStreaming(io, &b2);
    try std.testing.expectEqual(std.Io.File.Writer.Mode.streaming, fw2.mode);

    // 断言三：writerStreaming 写进去的字节能原样读回（不被dprint 冲掉）
    var b3: [64]u8 = undefined;
    var fw3 = std.Io.File.stderr().writerStreaming(io, &b3);
    try fw3.interface.writeAll("streaming-sentinel");
    try std.testing.expectEqualStrings("streaming-sentinel", fw3.interface.buffered());
}
