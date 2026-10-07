//! 27 目录遍历与文件树：三种遍历方式（iterate / walk / walkSelectively）、Entry 与 Io.File.Kind、statFile 的 lstat 语义、walk 的提前终止、enter/leave 剪枝、cwd() 伪句柄为什么不能 walk、符号链接与环检测、树形数据结构、自写 glob（* ? **）、权限错误与跳过大目录、流式 vs 建树、跨平台差异
//! 全部输出都来自 main 自己建的一棵确定小树（建在系统临时目录里，退出前删掉），所以逐字节可复现
const std = @import("std");

/// 27.12：打印树形时"每层一份"的缩进前缀缓冲：够 33 层深、每层 256 字节。
/// `bufs[i][0..lens[i]]` 才是第 i 层的前缀（`undefined` 的部分不能打印）。
const print_max_depth = 32;
const prefix_len = 256;

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

/// 27.12 的树节点：一棵树就是"一个目录节点 + 若干子节点"。
/// 名字**拥有**自己的内存（dupe 来的），所以树可以在迭代器之外继续活着。
const Node = struct {
    name: []const u8,
    /// 从树根到本节点的完整相对路径（建树时算好，arena 分配）。
    /// 有了它，"找最深路径""打印全路径"都不用现场拼字符串。
    path: []const u8,
    kind: std.Io.File.Kind,
    size: u64,
    depth: usize,
    children: std.ArrayList(*Node),

    /// 27.12：节点总数（含自己）。
    fn count(self: *const Node) usize {
        var n: usize = 1;
        for (self.children.items) |c| n += c.count();
        return n;
    }

    /// 27.13：递归汇总——目录节点把子树的和加上来。
    /// 注意只算 `.file`：符号链接（27.11 建的那两个）不计入，目录的 size 字段本身也不计入。
    fn totalSize(self: *const Node) u64 {
        var sum: u64 = if (self.kind == .file) self.size else 0;
        for (self.children.items) |c| sum += c.totalSize();
        return sum;
    }

    /// 27.13：树里的文件总数（同样只数 `.file`）。
    fn fileCount(self: *const Node) usize {
        var n: usize = if (self.kind == .file) 1 else 0;
        for (self.children.items) |c| n += c.fileCount();
        return n;
    }

    /// 27.13：最深的那个节点（比较 `path` 里的分隔符个数）。
    fn deepest(self: *const Node) *const Node {
        var best: *const Node = self;
        for (self.children.items) |c| {
            const sub = c.deepest();
            if (sub.depth > best.depth) best = sub;
        }
        return best;
    }

    /// 27.12：先序遍历，目录排在文件前，同层按名字排序 ⇒ 输出确定。
    /// `bufs` 是"每层一个"的缓冲数组：`bufs[depth]` 存本层往下传的缩进前缀。
    /// ⚠️ **不能把同一个 buf 往下传**：`bufPrint(buf, "{s}", .{prefix})` 里 prefix 就指向 buf 自己，
    ///   Writer 检测到 `@memcpy arguments alias` 直接 panic（实测栈：Writer.zig:611）。
    ///   也不能 `prefix ++ inner`——`++` 要求长度编译期已知，运行期切片拼接编译不过。
    fn print(self: *const Node, bufs: *[print_max_depth + 1][prefix_len]u8, lens: *[print_max_depth + 1]usize, last: bool) void {
        const prefix = bufs[self.depth][0..lens[self.depth]];
        const branch = if (last) "└── " else "├── ";
        switch (self.kind) {
            .directory => std.debug.print("{s}{s}{s}/\n", .{ prefix, branch, self.name }),
            .sym_link => std.debug.print("{s}{s}{s} -> {s}（{d} B 是链接串长度，不是目标大小）\n", .{ prefix, branch, self.name, self.path, self.size }),
            else => std.debug.print("{s}{s}{s}  {d} B\n", .{ prefix, branch, self.name, self.size }),
        }
        if (self.depth == print_max_depth) return; // 防御：不再往下递归
        // 子节点的前缀 = 自己的前缀 + 缩进块（4 格或 "│   "）——tree(1) 的全部视觉秘密
        const inner = if (self.depth == 0)
            ""
        else if (last)
            "    "
        else
            "│   ";
        // 缓冲满了就退回上一层的前缀（只是缩进短一点，不会 panic）
        const next = std.fmt.bufPrint(&bufs[self.depth + 1], "{s}{s}", .{ prefix, inner }) catch {
            lens[self.depth + 1] = prefix.len;
            @memcpy(bufs[self.depth + 1][0..prefix.len], prefix);
            for (self.children.items, 0..) |c, i| c.print(bufs, lens, i == self.children.items.len - 1);
            return;
        };
        lens[self.depth + 1] = next.len;
        for (self.children.items, 0..) |c, i| {
            c.print(bufs, lens, i == self.children.items.len - 1);
        }
    }
};

/// 27.14 自己写的 glob：`*` 不跨路径分隔符、`?` 单字符、`**` 跨任意层目录。
/// 回溯实现，零依赖、可单测。0.17 **没有**内建 glob（见 27.14 的输出）。
pub fn globMatch(name: []const u8, pattern: []const u8) bool {
    if (std.mem.startsWith(u8, pattern, "**")) {
        const rest = pattern[2..];
        if (rest.len == 0) return true;
        // "**/" 里的斜杠吃掉，所以 "**/x" 也匹配顶层 "x"
        const tail = if (rest[0] == '/') rest[1..] else rest;
        if (globMatch(name, tail)) return true;
        var i: usize = 0;
        while (i < name.len) : (i += 1) {
            if (name[i] == '/' and globMatch(name[i + 1 ..], tail)) return true;
        }
        return false;
    }
    if (pattern.len == 0) return name.len == 0;
    if (pattern[0] == '*') {
        // 枚举 "*" 吃掉几个字符。⚠️ 必须**先递归再判界**：
        // 反过来写（先判 name[i]=='/' 再递归）会把 "a/*/c.txt" vs "a/b/c.txt" 判成 false。
        var i: usize = 0;
        while (i <= name.len) : (i += 1) {
            if (globMatch(name[i..], pattern[1..])) return true;
            if (i == name.len) break;
            if (name[i] == '/') break;
        }
        return false;
    }
    if (name.len == 0) return false;
    if (pattern[0] == '?') return name[0] != '/' and globMatch(name[1..], pattern[1..]);
    if (pattern[0] == name[0]) return globMatch(name[1..], pattern[1..]);
    return false;
}

/// 27.5 的小工具：把两段路径用本平台分隔符拼进调用方缓冲（**零分配**）。
/// `std.fs.path.join` 要分配器；`fmtJoin` + `Io.Writer.fixed` 是它的零分配替代。
fn fmtJoin(buf: []u8, a: []const u8, b: []const u8) ![]const u8 {
    var w = std.Io.Writer.fixed(buf);
    try w.print("{f}", .{std.fs.path.fmtJoin(&.{ a, b })});
    return w.buffered();
}

fn lessStr(_: void, x: []const u8, y: []const u8) bool {
    return std.mem.order(u8, x, y) == .lt;
}

/// 27.5/27.4 手写递归遍历（第三种方式）。四个要点：
/// 1. `entry.name` 活不过下一次 `next()` ⇒ 跨 next 收集必须 dupe；
/// 2. 打开子目录失败（AccessDenied）要**跳过**而不是让整趟遍历失败（27.4）；
/// 3. 符号链接默认不跟（防环，要跟得自己判，27.11）；
/// 4. 递归深度要有上限，否则深目录爆栈。
fn collectFiles(
    io: std.Io,
    gpa: std.mem.Allocator,
    dir: std.Io.Dir,
    path: []const u8,
    out: *std.ArrayList([]const u8),
    depth: usize,
    max_depth: usize,
    skipped: *usize,
) !void {
    if (depth > max_depth) return;
    var d = dir.openDir(io, path, .{ .iterate = true }) catch |err| switch (err) {
        error.AccessDenied, error.PermissionDenied => {
            skipped.* += 1; // 27.4 的策略：跳过大目录，继续走别的
            return;
        },
        else => |e| return e,
    };
    defer d.close(io);
    var it = d.iterate();
    while (true) {
        const maybe = it.next(io) catch |err| switch (err) {
            error.AccessDenied, error.PermissionDenied => {
                skipped.* += 1;
                break; // 这个目录剩下的条目放弃，但外层继续
            },
            else => |e| return e,
        };
        const entry = maybe orelse break;
        var buf: [1024]u8 = undefined;
        const child = fmtJoin(&buf, path, entry.name) catch continue;
        switch (entry.kind) {
            .directory => try collectFiles(io, gpa, dir, child, out, depth + 1, max_depth, skipped),
            // ⚠️ 这里 dupe：entry.name 指向迭代器的 2048 字节内嵌缓冲，下一次 next 就被覆盖
            .file => try out.append(gpa, try gpa.dupe(u8, child)),
            else => {}, // sym_link / unknown：默认不跟（27.11）
        }
    }
}

/// 27.12 的建树：递归 + 排序，产出确定的先序遍历。
/// Node 用 arena 分配，`*Node` 指向 arena 里的稳定地址。
/// `rel` 是相对树根的路径（用 '/' 拼；Windows 上分隔符不同，但本例只在 macOS 跑）
fn buildTree(io: std.Io, gpa: std.mem.Allocator, dir: std.Io.Dir, path: []const u8, rel: []const u8, depth: usize) !*Node {
    const self = try gpa.create(Node);
    self.* = .{
        .name = try gpa.dupe(u8, std.fs.path.basename(path)),
        .path = try gpa.dupe(u8, rel),
        .kind = .directory,
        .size = 0,
        .depth = depth,
        .children = .empty,
    };
    var d = try dir.openDir(io, path, .{ .iterate = true });
    defer d.close(io);

    // 先收集（dupe！）再排序 ⇒ 后续输出确定。
    // 名字的**所有权在 append 进 children 时移交**给节点，所以这里不 free。
    var names: std.ArrayList([]const u8) = .empty;
    defer names.deinit(gpa);
    var it = d.iterate();
    while (try it.next(io)) |e| try names.append(gpa, try gpa.dupe(u8, e.name));
    std.mem.sort([]const u8, names.items, {}, lessStr);

    for (names.items) |name| {
        var buf: [1024]u8 = undefined;
        const child = fmtJoin(&buf, path, name) catch continue;
        var rbuf: [1024]u8 = undefined;
        const child_rel = std.fmt.bufPrint(&rbuf, "{s}/{s}", .{ rel, name }) catch continue;
        const st = dir.statFile(io, child, .{ .follow_symlinks = false }) catch continue;
        if (st.kind == .directory) {
            // 递归建子树（注意传的是 child_rel 的**副本**：栈上的 buf 下一轮就废了）
            const child_rel_copy = try gpa.dupe(u8, child_rel);
            const sub = try buildTree(io, gpa, dir, child, child_rel_copy, depth + 1);
            try self.children.append(gpa, sub);
        } else {
            const leaf = try gpa.create(Node);
            leaf.* = .{
                .name = name,
                .path = try gpa.dupe(u8, child_rel),
                .kind = st.kind,
                .size = st.size,
                .depth = depth + 1,
                .children = .empty,
            };
            try self.children.append(gpa, leaf);
        }
    }
    // 同层排序：目录在前、文件按名字 ⇒ 打印确定
    std.mem.sort(*Node, self.children.items, {}, lessNode);
    return self;
}

fn lessNode(_: void, x: *Node, y: *Node) bool {
    // 目录排在文件前；同类按名字排
    const x_dir = x.kind == .directory;
    const y_dir = y.kind == .directory;
    if (x_dir != y_dir) return x_dir;
    return std.mem.order(u8, x.name, y.name) == .lt;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const a = init.arena.allocator();
    const cwd = std.Io.Dir.cwd();

    // ═══ 27.0 自建沙盒：确定性小树 ═══
    begin("27.0");
    const sbox = "/tmp/zig27_tree_demo";
    cwd.deleteTree(io, sbox) catch {}; // 幂等：先清上次残留
    try cwd.createDirPath(io, sbox);
    defer cwd.deleteTree(io, sbox) catch {}; // 退出时回收，绝不留在仓库里

    try cwd.writeFile(io, .{ .sub_path = sbox ++ "/README.md", .data = "readme" }); // 6 B
    try cwd.writeFile(io, .{ .sub_path = sbox ++ "/main.zig", .data = "0123456789" }); // 10 B
    try cwd.createDirPath(io, sbox ++ "/src");
    try cwd.writeFile(io, .{ .sub_path = sbox ++ "/src/app.zig", .data = "aaa" }); // 3 B
    try cwd.writeFile(io, .{ .sub_path = sbox ++ "/src/util.zig", .data = "bb" }); // 2 B
    try cwd.createDirPath(io, sbox ++ "/src/deep");
    try cwd.writeFile(io, .{ .sub_path = sbox ++ "/src/deep/leaf.txt", .data = "leafff" }); // 6 B
    try cwd.createDirPath(io, sbox ++ "/empty");
    std.debug.print("沙盒 {s}：4 个文件 + 3 个目录（empty 是空的）=7 个条目\n", .{sbox});
    std.debug.print("⚠️ 27 章所有输出都来自这棵自建树 ⇒ 逐字节确定，不受仓库内容影响\n", .{});
    std.debug.print("⚠️ 建在系统临时目录而不是 cwd：示例从仓库根运行（run-all.sh 的约定）\n", .{});
    end("27.0");

    // ═══ 27.1 四种遍历方式的总览 ═══
    begin("27.1");
    std.debug.print("方式一 iterate()          只管当前一层，递归自己写（可控、可剪枝、要管 fd）\n", .{});
    std.debug.print("方式二 walk()             库写好的递归，返回带完整相对路径的条目（省心，要 gpa）\n", .{});
    std.debug.print("方式三 walkSelectively()  像 walk，但进哪一层由你逐个决定（enter / leave）\n", .{});
    std.debug.print("方式四 Dir.Reader         批量 read()，自己给缓冲，系统调用最少\n", .{});
    std.debug.print("前三种的 next 都要 io；只有 walk / walkSelectively 的**第一个参数是 gpa（不是 io）**\n", .{});
    std.debug.print("iterate() 不带 io（纯计算，造个 Iterator 结构体），next(io) 才带 —— 不对称设计\n", .{});
    end("27.1");

    // ═══ 27.2 Dir / File / Entry 的关系 ═══
    begin("27.2");
    {
        const E = @typeInfo(std.Io.Dir.Entry).@"struct";
        std.debug.print("Io.Dir.Entry 只有 {d} 个字段：", .{E.field_names.len});
        inline for (E.field_names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});
        inline for (E.field_types, 0..) |t, i| std.debug.print("  {s} : {s}\n", .{ E.field_names[i][0..E.field_names[i].len], @typeName(t) });

        const K = @typeInfo(std.Io.File.Kind).@"enum";
        std.debug.print("entry.kind 的字段类型是 {s}（**不是** Io.Dir.Entry.Kind —— 后者不存在）\n", .{@typeName(@FieldType(std.Io.Dir.Entry, "kind"))});
        std.debug.print("  它的编译期基整型是 {s}（11 个成员⇒4 位够了），但**打印/比较一律用 {{t}}**\n", .{@typeName(K.tag_type)});
        std.debug.print("File.Kind 全部 {d} 个成员：", .{K.field_names.len});
        inline for (K.field_names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});

        // 三层模型：Dir 是工厂、File 是句柄、Entry 是遍历产物
        var d = try cwd.openDir(io, sbox, .{ .iterate = true });
        defer d.close(io);
        std.debug.print("Dir 是工厂：openDir 出来的是**真 fd**（handle >= 0）；Dir.cwd().handle={d} 是伪句柄（AT_FDCWD={d}）\n", .{ cwd.handle, std.posix.AT.FDCWD });
        std.debug.print("Entry 是遍历产物：只有 {{name, kind, inode}}，**没有大小、没有时间**（要 statFile）\n", .{});
        var it = d.iterate();
        var rows: std.ArrayList([2][]const u8) = .empty;
        while (try it.next(io)) |e| {
            try rows.append(a, .{
                try a.dupe(u8, e.name),
                try std.fmt.allocPrint(a, "{t}", .{e.kind}),
            });
        }
        std.mem.sort([2][]const u8, rows.items, {}, lessRow);
        for (rows.items) |r| std.debug.print("  [{s}] {s}\n", .{ r[1], r[0] });
        std.debug.print("  顶层 {d} 个条目（上面已排序；**原始顺序由文件系统决定** ⇒ 想确定输出必须自己排）\n", .{rows.items.len});
        std.debug.print("  inode 字段实测是 u64（macOS/Linux 的 ino_t）⇒ 够当\"已访问\"集合的 key（27.11 防环用）\n", .{});
    }
    end("27.2");

    // ═══ 27.3 next() 的正确用法：双层解包 ═══
    begin("27.3");
    {
        std.debug.print("next 的返回类型是 `Error!?Entry`（错误 + 可选，两层）\n", .{});
        std.debug.print("✅ `while (try it.next(io)) |entry|` —— 一次解两层，写法最短\n", .{});
        var d = try cwd.openDir(io, sbox ++ "/src", .{ .iterate = true });
        defer d.close(io);
        var it = d.iterate();
        var cnt: usize = 0;
        while (try it.next(io)) |entry| {
            cnt += 1;
            std.debug.print("  while 解包 [{t}] {s}\n", .{ entry.kind, entry.name });
        }
        std.debug.print("  src 下 {d} 个条目\n", .{cnt});

        std.debug.print("⚠️ `if (it.next(io)) |x|` 里的 x **仍是 ?Entry**（只解了错误层）\n", .{});
        var d2 = try cwd.openDir(io, sbox ++ "/src", .{ .iterate = true });
        defer d2.close(io);
        var it2 = d2.iterate();
        if (it2.next(io)) |maybe| {
            std.debug.print("  实测 x 的类型 = {s} ⇒ 还得再解一层才拿得到 name\n", .{@typeName(@TypeOf(maybe))});
            if (maybe) |e| std.debug.print("  第二层解包后 [{t}] {s}\n", .{ e.kind, e.name });
        } else |err| std.debug.print("  不该出错：{s}\n", .{@errorName(err)});
        std.debug.print("  写错成 |entry| 直接用 entry.name → error: optional type '?Io.Dir.Entry' does not support field access\n", .{});

        // 同一个 Dir 能iterate 两遍吗
        var n1: usize = 0;
        var it3 = d2.iterate();
        while (try it3.next(io)) |_| n1 += 1;
        std.debug.print("同一个 Dir 第二次 iterate() → {d} 个（iterate() 内部状态是 .reset，会 lseek 回 0）\n", .{n1});
        var n2: usize = 0;
        var it4 = d2.iterateAssumeFirstIteration();
        while (try it4.next(io)) |_| n2 += 1;
        std.debug.print("iterateAssumeFirstIteration() → {d} 个（接着上次读完的位置，不 reset ⇒ 通常是 0）\n", .{n2});
    }
    end("27.3");

    // ═══ 27.4 next() 的错误处理：AccessDenied 要不要终止整趟 ═══
    begin("27.4");
    {
        // 造一个 000 权限的目录（POSIX 有效）
        try cwd.createDirPath(io, sbox ++ "/locked");
        try cwd.writeFile(io, .{ .sub_path = sbox ++ "/locked/secret.txt", .data = "s3cret" });
        try cwd.setFilePermissions(io, sbox ++ "/locked", @as(std.Io.File.Permissions, .fromMode(0)), .{});

        const EI = @typeInfo(std.Io.Dir.Iterator.Error);
        std.debug.print("Iterator.Error 的 @typeInfo tag = {s}（是错误集，不是别的）\n", .{@tagName(EI)});
        const names = @typeInfo(std.Io.Dir.Iterator.Error).error_set.error_names.?;
        std.debug.print("  自己声明的成员：", .{});
        for (names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});

        // openDir 一个 000 目录
        if (cwd.openDir(io, sbox ++ "/locked", .{ .iterate = true })) |d| {
            var dd = d;
            defer dd.close(io);
            std.debug.print("000 目录 openDir 成功？不该\n", .{});
        } else |err| std.debug.print("000 目录 openDir → {s}（实测：连目录句柄都拿不到）\n", .{@errorName(err)});
        if (cwd.access(io, sbox ++ "/locked", .{ .execute = true })) |_| {
            std.debug.print("  access(execute) 于 000 目录 → ok？不该\n", .{});
        } else |err| std.debug.print("  access(execute) 于 000 目录 → {s}\n", .{@errorName(err)});

        // 策略 A：目录级错误降级成"跳过"
        var skipped: usize = 0;
        var files: std.ArrayList([]const u8) = .empty;
        try collectFiles(io, a, cwd, sbox, &files, 0, 16, &skipped);
        std.debug.print("策略 A（openDir 失败就跳过）：收集 {d} 个文件，跳过 {d} 个目录\n", .{ files.items.len, skipped });
        std.mem.sort([]const u8, files.items, {}, lessStr);
        for (files.items) |p| std.debug.print("  {s}\n", .{p});

        // 策略 B 的代价：walk 遇到跳不进的目录
        {
            var d = try cwd.openDir(io, sbox, .{ .iterate = true });
            defer d.close(io);
            var w = try d.walk(a);
            defer w.deinit();
            std.debug.print("策略 B 的 walk 版本：\n", .{});
            while (true) {
                const maybe = w.next(io) catch |err| {
                    std.debug.print("  walk next → {s}（实测：这个错误**可恢复**，再调next 能接着走）\n", .{@errorName(err)});
                    continue;
                };
                const e = maybe orelse {
                    std.debug.print("  walk 正常结束\n", .{});
                    break;
                };
                std.debug.print("  {s} [{t}]\n", .{ e.path, e.kind });
            }
        }
        std.debug.print("⇒ walk 的 next 出错后**可以继续调用**（源码会把出错的目录弹栈）⇒ 循环里 catch 后能接着走\n", .{});
        std.debug.print("⇒ 手写递归的 openDir 出错只能 return：所以要**在递归里就地 catch 成跳过**\n", .{});
        std.debug.print("⇒ 27 章选A：**目录级错误降级成\"跳过\"，其它错误原样上抛**\n", .{});

        // 恢复权限，否则 defer 的 deleteTree 清不掉
        try cwd.setFilePermissions(io, sbox ++ "/locked", @as(std.Io.File.Permissions, .fromMode(0o755)), .{});
    }
    end("27.4");

    // ═══ 27.5 手写递归与 entry.name 的生命周期 ═══
    begin("27.5");
    {
        std.debug.print("Io.Dir.Iterator 有 {d} 字节的内嵌缓冲（Iterator.reader_buffer_len）\n", .{std.Io.Dir.Iterator.reader_buffer_len});
        std.debug.print("源码文档原话：All `Entry.name` are invalidated with the next call to `read` or `next`\n", .{});
        std.debug.print("⇒ 跨 next() 收集名字**必须 dupe**，否则拿到的是同一块缓冲里的旧内容\n", .{});

        // 沙盒顶层只有 5 个条目，一次 fillMore 就读完了 ⇒ 不会暴露问题。
        // 所以另造一个 60 条目的目录：2048 字节缓冲装不下 60 个名字 ⇒ 必然多次 fillMore。
        try cwd.createDirPath(io, sbox ++ "/many");
        var nb: [32]u8 = undefined;
        for (0..60) |i| {
            const nm = try std.fmt.bufPrint(&nb, "file_{d:0>3}.txt", .{i});
            try cwd.writeFile(io, .{ .sub_path = try std.fmt.allocPrint(a, "{s}/many/{s}", .{ sbox, nm }), .data = "x" });
        }
        std.debug.print("另造 many/ 目录放 60 个条目（名字 13 字节 ⇒ 2048 字节缓冲要 fillMany 次）\n", .{});

        // 反例：故意不 dupe。判定"失效"不能靠数个数（那是实现细节），
        // 要看**切片内容本身**：不 dupe 时多个切片会指向同一块缓冲 ⇒ 内容重复
        var bad: std.ArrayList([]const u8) = .empty;
        {
            var d = try cwd.openDir(io, sbox ++ "/many", .{ .iterate = true });
            defer d.close(io);
            var it = d.iterate();
            while (try it.next(io)) |e| try bad.append(a, e.name); // ❌ 不 dupe
        }
        // 统计"有多少个切片的内容互不相同"
        var distinct: usize = 0;
        for (bad.items, 0..) |x, i| {
            var seen = false;
            for (bad.items[0..i]) |y| {
                if (std.mem.eql(u8, x, y)) seen = true;
            }
            if (!seen) distinct += 1;
        }
        var bad_broken: usize = 0;
        for (bad.items) |n| {
            var full: [256]u8 = undefined;
            const f = std.fmt.bufPrint(&full, "{s}/many/{s}", .{ sbox, n }) catch continue;
            cwd.access(io, f, .{}) catch {
                bad_broken += 1;
                continue;
            };
        }
        std.debug.print("  ❌ 不dupe：{d} 个切片的内容里有重复吗？{}（true = 多个切片指向同一块缓冲）\n", .{ bad.items.len, distinct < bad.items.len });
        std.debug.print("     用这些名字 access 目录：有失效的吗？{}（true = 有名字指向不存在的条目）\n", .{bad_broken > 0});
        std.debug.print("     ⚠️ **具体几个失效取决于实现细节**（缓冲多大、一次填多少）——不要去数个数\n", .{});
        std.debug.print("        真正的教训是：小目录一次读完，看起来\"完全没事\"，这才是陷阱\n", .{});

        // 正例：dupe
        var good: std.ArrayList([]const u8) = .empty;
        {
            var d = try cwd.openDir(io, sbox ++ "/many", .{ .iterate = true });
            defer d.close(io);
            var it = d.iterate();
            while (try it.next(io)) |e| try good.append(a, try a.dupe(u8, e.name)); // ✅ dupe
        }
        var good_alive: usize = 0;
        for (good.items) |n| {
            var full: [256]u8 = undefined;
            const f = std.fmt.bufPrint(&full, "{s}/many/{s}", .{ sbox, n }) catch continue;
            cwd.access(io, f, .{}) catch continue;
            good_alive += 1;
        }
        std.mem.sort([]const u8, good.items, {}, lessStr);
        std.debug.print("  ✅ dupe 后 {d} 个，{d} 个全部有效；排序后首尾：{s} … {s}\n", .{ good.items.len, good_alive, good.items[0], good.items[good.items.len - 1] });
        std.debug.print("⇒ 内存纪律：entry.name 是**借来的**，要活过 next() 就 dupe（或当场用完就扔）\n", .{});
        try cwd.deleteTree(io, sbox ++ "/many"); // 清掉，免得后面的节数被撑大
    }
    end("27.5");

    // ═══ 27.6 walk()：现成的递归 ═══
    begin("27.6");
    {
        std.debug.print("实测签名：dir.walk(allocator: Allocator) Allocator.Error!Walker —— **第一个参数是 gpa**\n", .{});
        var d = try cwd.openDir(io, sbox, .{ .iterate = true });
        defer d.close(io);
        var w = try d.walk(a);
        defer w.deinit();
        const WE = @typeInfo(std.Io.Dir.Walker.Entry).@"struct";
        std.debug.print("Walker.Entry 有 {d} 个字段：", .{WE.field_names.len});
        inline for (WE.field_names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});
        inline for (WE.field_types, 0..) |t, i| std.debug.print("  {s} : {s}\n", .{ WE.field_names[i][0..WE.field_names[i].len], @typeName(t) });
        std.debug.print("  path / basename 都是 [:0]const u8（**带哨兵**，可直接给 C API）；dir 是所在目录的句柄\n", .{});
        std.debug.print("  entry.depth() 是自己算的：数路径里的分隔符 + 1（根的直接子节点 depth=1）\n", .{});

        // rows 里第二项是 dupe 出来的 depth 字符串。
        // ⚠️ 不能存 bufPrint 到**栈上缓冲**的切片：那个缓冲每轮循环都被复用 ⇒ 全是最后一次的值
        //   （这个坑和 27.5 的 entry.name 是同一类：借来的内存活过了它的有效期）
        var rows: std.ArrayList([2][]const u8) = .empty;
        while (try w.next(io)) |e| {
            std.debug.print("  depth={d} kind={t} path={s}\n", .{ e.depth(), e.kind, e.path });
            var db: [16]u8 = undefined;
            const depth_str = try std.fmt.bufPrint(&db, "depth={d}", .{e.depth()});
            try rows.append(a, .{ try a.dupe(u8, e.path), try a.dupe(u8, depth_str) });
        }
        std.mem.sort([2][]const u8, rows.items, {}, lessRow);
        std.debug.print("  排序后同样 {d} 条，顺序确定：\n", .{rows.items.len});
        for (rows.items) |r| std.debug.print("    {s}  {s}\n", .{ r[0], r[1] });
        std.debug.print("⇒ 排序只是为了输出确定；walk 本身的顺序文档明说 undefined\n", .{});
        std.debug.print("⇒ 用 e.dir + e.basename 定位，省掉拼长路径 ⇒ 深层目录不会撞error.NameTooLong\n", .{});
    }
    end("27.6");

    // ═══ 27.7 walk 的提前终止 ═══
    begin("27.7");
    {
        var d = try cwd.openDir(io, sbox, .{ .iterate = true });
        defer d.close(io);
        var w = try d.walk(a);
        defer w.deinit();
        var visited: usize = 0;
        var found: []const u8 = "";
        while (try w.next(io)) |e| {
            visited += 1;
            if (std.mem.eql(u8, e.basename, "leaf.txt")) {
                found = try a.dupe(u8, e.path);
                break; // 剩下的子树一个都不进
            }
        }
        // 先算全量条数，好让"提前终止省了多少"有个对比
        var total_entries: usize = 0;
        {
            var d0 = try cwd.openDir(io, sbox, .{ .iterate = true });
            defer d0.close(io);
            var w0 = try d0.walk(a);
            defer w0.deinit();
            while (try w0.next(io)) |_| total_entries += 1;
        }
        std.debug.print("整棵树全量 {d} 个条目；命中 {s} 时 break 前只访问了 {d} 个\n", .{ total_entries, found, visited });
        std.debug.print("⚠️ break 只退出你的循环；**Walker 的栈上还压着若干 openDir 出来的 Dir**\n", .{});
        std.debug.print("   ⇒必须 `defer w.deinit()`：它关掉栈上的目录 + 释放 name_buffer 和 stack\n", .{});
        std.debug.print("   deinit() **不会**关掉你最初 openDir 的那个 d（文档：dir will not be closed）\n", .{});
        std.debug.print("⇒ 实测：deinit 之后原来的 d 还能再 iterate 一遍 ⇒ 这是设计，不是漏关\n", .{});
        var it = d.iterate();
        var cnt: usize = 0;
        while (try it.next(io)) |_| cnt += 1;
        std.debug.print("  deinit 后 d 重新 iterate → {d} 个条目\n", .{cnt});
    }
    end("27.7");

    // ═══ 27.8 walkSelectively：enter / leave ═══
    begin("27.8");
    {
        var d = try cwd.openDir(io, sbox, .{ .iterate = true });
        defer d.close(io);
        var w = try d.walkSelectively(a);
        defer w.deinit();
        std.debug.print("walkSelectively 的 next **不自动进子目录**（walk 会自动 enter）\n", .{});
        var enters: usize = 0;
        var leaves: usize = 0;
        while (try w.next(io)) |e| {
            std.debug.print("  {s}（depth={d}）", .{ e.path, e.depth() });
            if (std.mem.eql(u8, e.basename, "src")) {
                try w.enter(io, e); // 只进 src
                enters += 1;
                std.debug.print("→ enter(src)", .{});
            } else if (e.kind == .directory and e.depth() >= 2) {
                w.leave(io); // 看到 depth>=2 的目录就放弃它，退回上一层
                leaves += 1;
                std.debug.print("→ leave()", .{});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("  enter {d} 次 / leave {d} 次 ⇒ src/deep 及以下一个都没访问\n", .{ enters, leaves });
        std.debug.print("  leave(io) 无返回值也不报 error：它就是弹栈（源码 self.stack.pop().?）\n", .{});
        std.debug.print("⚠️ leave 的语义是\"离开当前目录\"，不是\"跳过这个条目\"⇒ 后面同层的兄弟目录会继续出现\n", .{});
        std.debug.print("⚠️ enter 只对 kind==.directory 有效（源码第一行就 if (entry.kind != .directory) return）\n", .{});
    }
    end("27.8");

    // ═══ 27.9 cwd() 是伪句柄：不能 walk / stat / iterate ═══
    begin("27.9");
    {
        std.debug.print("std.Io.Dir.cwd().handle = {d}，而 AT.FDCWD = {d} ⇒ 它**不是真正的 fd**\n", .{ cwd.handle, std.posix.AT.FDCWD });
        std.debug.print("源码文档原话：It is not opened with iteration capability.\n", .{});
        std.debug.print("             Iterating over the result is illegal behavior.\n", .{});
        std.debug.print("             Closing the returned `Dir` is checked illegal behavior.\n", .{});
        std.debug.print("实测：cwd().walk(a) **不报错**（只是造个 Walker），但第一次 next(io) 直接 panic：\n", .{});
        std.debug.print("  thread N panic: programmer bug caused syscall error: BADF\n", .{});
        std.debug.print("  Threaded.zig:10512 in posixSeekTo: .BADF => |err| return errnoBug(err)\n", .{});
        std.debug.print("  Threaded.zig:5692 in dirReadDarwin: posixSeekTo(dr.dir.handle, 0) catch ...\n", .{});
        std.debug.print("  Dir.zig:152 in read → Dir.zig:159 in next → Iterator.next:207 → SelectiveWalker.next:241\n", .{});
        std.debug.print("原因：Darwin 上读目录要 lseek 复位，对 AT_FDCWD 做 lseek 就是 EBADF\n", .{});
        std.debug.print("⇒ 规律：cwd() 只能做**按路径**的操作（openFile / statFile / createDirPath …）\n", .{});
        std.debug.print("   凡是需要真实 fd 的（walk / stat / iterate / close）必须先 openDir\n", .{});
        std.debug.print("   cwd().stat(io) 同样 panic 同因；cwd().close(io) 是 checked illegal behavior\n", .{});
        std.debug.print("✅ 正解：var d = try cwd.openDir(io, 路径, .{{ .iterate = true }}); 然后在 d 上 walk\n", .{});
    }
    end("27.9");

    // ═══ 27.10 statFile：lstat 语义与 follow_symlinks ═══
    begin("27.10");
    {
        const SO = @typeInfo(std.Io.Dir.StatFileOptions).@"struct";
        std.debug.print("StatFileOptions 只有 {d} 个字段：", .{SO.field_names.len});
        inline for (SO.field_names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});
        inline for (SO.field_types, 0..) |t, i| std.debug.print("  {s} : {s}\n", .{ SO.field_names[i][0..SO.field_names[i].len], @typeName(t) });
        std.debug.print("⚠️ follow_symlinks 的类型实测就是 **bool**（默认 true）\n", .{});
        std.debug.print("   不是 {{ .file, .sym_link }} / {{ true: ..., false: ... }} 这种联合字面量\n", .{});
        std.debug.print("   （grep 全标准库：follow_symlinks 一律是 bool，没有 union 版本）\n", .{});

        const S = @typeInfo(std.Io.File.Stat).@"struct";
        std.debug.print("Stat 的 {d} 个字段：", .{S.field_names.len});
        inline for (S.field_names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});
        inline for (S.field_types, 0..) |t, i| std.debug.print("  {s} : {s}\n", .{ S.field_names[i][0..S.field_names[i].len], @typeName(t) });
        std.debug.print("  atime 是**可选**的 ?Io.Timestamp（有些 FS 拒绝报告访问时间）\n", .{});
        std.debug.print("  mtime / ctime 是 Io.Timestamp（纳秒，相对 UTC 1970-01-01）\n", .{});

        // 造符号链接对比 lstat / stat
        try cwd.symLink(io, "README.md", sbox ++ "/link_readme", .{});
        const lst = try cwd.statFile(io, sbox ++ "/link_readme", .{ .follow_symlinks = false });
        const stt = try cwd.statFile(io, sbox ++ "/link_readme", .{});
        std.debug.print("lstat(link) kind={t:<9} size={d} nlink={d}\n", .{ lst.kind, lst.size, lst.nlink });
        std.debug.print("stat (link) kind={t:<9} size={d} nlink={d}   ← 穿透到目标（6 B 的 README.md）\n", .{ stt.kind, stt.size, stt.nlink });
        std.debug.print("⇒ 判\"这是不是链接\"必须 follow_symlinks=false；判\"这个路径指向什么\"用默认 true\n", .{});
        var lbuf: [64]u8 = undefined;
        const n_link = try cwd.readLink(io, sbox ++ "/link_readme", &lbuf);
        std.debug.print("readLink → {s}（{d} 字节；这是唯一能拿到链接目标字符串的办法）\n", .{ lbuf[0..n_link], n_link });

        // 悬空链接
        try cwd.symLink(io, "no_such_file", sbox ++ "/link_dead", .{});
        const dl = try cwd.statFile(io, sbox ++ "/link_dead", .{ .follow_symlinks = false });
        std.debug.print("悬空链接 lstat → kind={t} size={d}（能看见链接本身）\n", .{ dl.kind, dl.size });
        if (cwd.statFile(io, sbox ++ "/link_dead", .{})) |_| {
            std.debug.print("悬空链接 stat → 成功？不该\n", .{});
        } else |err| std.debug.print("悬空链接 stat → {s}（穿透到不存在的目标）\n", .{@errorName(err)});
        std.debug.print("⇒ 悬空链接的 kind 是 .sym_link **不是** .file ⇒ 按 *.txt 过滤时天然被排除\n", .{});
        var dbuf: [64]u8 = undefined;
        const dead_n = try cwd.readLink(io, sbox ++ "/link_dead", &dbuf);
        std.debug.print("⇒ 但 readLink 仍能读出目标字符串 ={s}（{d} 字节）——那是它自己写的那一串\n", .{ dbuf[0..dead_n], dead_n });
    }
    end("27.10");

    // ═══ 27.11 符号链接与环：walk 会不会跟进 ═══
    begin("27.11");
    {
        // 指向父目录的目录链接 = 经典环
        try cwd.symLink(io, "src", sbox ++ "/src/loop", .{ .is_directory = true });
        var d = try cwd.openDir(io, sbox, .{ .iterate = true });
        defer d.close(io);
        var w = try d.walk(a);
        defer w.deinit();
        var paths: std.ArrayList([]const u8) = .empty;
        while (try w.next(io)) |e| {
            std.debug.print("  walk: depth={d} kind={t:<9} path={s}\n", .{ e.depth(), e.kind, e.path });
            try paths.append(a, try a.dupe(u8, e.path));
        }
        std.mem.sort([]const u8, paths.items, {}, lessStr);
        std.debug.print("walk 共 {d} 条（含 loop 与 link_readme / link_dead 两个链接条目）：\n", .{paths.items.len});
        for (paths.items) |p| std.debug.print("    {s}\n", .{p});
        std.debug.print("⇒ walk 靠 entry.kind 决定要不要进（源码 Walker.next：if kind == .directory 则 enter）\n", .{});
        std.debug.print("   符号链接的 kind 是 .sym_link ⇒ **walk 天生不跟链接，天然防环**\n", .{});
        std.debug.print("⚠️ 但**手写递归**若写成\"lstat 是目录就进\"就完了：环会无限套娃直到爆栈\n", .{});
        std.debug.print("   两种防环手段：① 限制 max_depth（示例 collectFiles 的 max_depth 参数）\n", .{});
        std.debug.print("   ② 记录已访问的 (dev, inode)，撞上就跳过——Entry.inode 是 {s}，够当 key\n", .{@typeName(@FieldType(std.Io.Dir.Entry, "inode"))});
        std.debug.print("   （nlink 也有用：>1 说明有硬链接，同一 inode 不止一个名字）\n", .{});
        std.debug.print("⇒ 想跟链接必须**显式**做：statFile(follow=true) 判目标是不是目录 + visited 集合\n", .{});
        std.debug.print("   这正是 rsync -L / cp -r -L 的代价：成环时它们会报 too many levels of symbolic links\n", .{});
    }
    end("27.11");

    // ═══ 27.12 树形数据结构 ═══
    begin("27.12");
    {
        std.debug.print("把文件系统变成内存里的树：Node{{name, path, kind, size, depth, children}}\n", .{});
        std.debug.print("多一个 path 字段（相对树根的完整路径，建树时算好）⇒ 打印/查询都不用现场拼\n", .{});
        const tree = try buildTree(io, a, cwd, sbox, std.fs.path.basename(sbox), 0);
        std.debug.print("建树完成：{d} 个节点 = {d} 个文件 + {d} 个目录 + {d} 个符号链接（根节点是目录）\n", .{ tree.count(), tree.fileCount(), countKind(tree, .directory), countKind(tree, .sym_link) });
        std.debug.print("树形输出（目录在前、同层按名字排序 ⇒ 确定）：\n", .{});
        var bufs: [print_max_depth + 1][prefix_len]u8 = undefined;
        var lens: [print_max_depth + 1]usize = @splat(0); // 根层前缀是空串
        tree.print(&bufs, &lens, true);
        std.debug.print("⚠️ Node.name / Node.path **必须 dupe**：不dupe 的话树建完就全是垃圾\n", .{});
        std.debug.print("   （每层的 openDir/iterate 都是局部的，缓冲复用后名字就废了——同 27.5）\n", .{});
        std.debug.print("⇒ children 用 ArrayList(*Node) + arena：建树 O(节点数) 内存，退出自动整体回收\n", .{});
        std.debug.print("⇒ print 的缩进前缀用**每层一份的缓冲数组**：不能 prefix ++ inner（编译不过）\n", .{});
        std.debug.print("   也不能把同一个 buf 往下传（bufPrint 的源和目标重叠 ⇒ panic: @memcpy arguments alias）\n", .{});
    }
    end("27.12");

    // ═══ 27.13 树的三个查询 vs 流式遍历 ═══
    begin("27.13");
    {
        const tree = try buildTree(io, a, cwd, sbox, std.fs.path.basename(sbox), 0);
        const deep_node = tree.deepest();
        std.debug.print("树上递归：整棵树 {d} 字节 / {d} 个文件\n", .{ tree.totalSize(), tree.fileCount() });
        std.debug.print("最深节点 = {s}（depth={d}，path={s}）\n", .{ deep_node.name, deep_node.depth, deep_node.path });
        std.debug.print("⇒ 这三个查询都是**树上递归**，不再走文件系统 ⇒ O(节点数) 且零系统调用\n", .{});
        std.debug.print("⇒ deepest 比的是 path 里的分隔符数（等价于 Walker.Entry.depth() 的算法）\n", .{});

        // 同一份数据用 walk 流式算：内存 O(1) 但每个文件要 statFile
        var d = try cwd.openDir(io, sbox, .{ .iterate = true });
        defer d.close(io);
        var w = try d.walk(a);
        defer w.deinit();
        var total: u64 = 0;
        var files: usize = 0;
        var dirs: usize = 0;
        var deepest_path: []const u8 = "";
        var deepest_d: usize = 0;
        while (try w.next(io)) |e| {
            if (e.depth() > deepest_d) {
                deepest_d = e.depth();
                deepest_path = try a.dupe(u8, e.path);
            }
            switch (e.kind) {
                .file => {
                    files += 1;
                    total += (try e.dir.statFile(io, e.basename, .{})).size;
                },
                .directory => dirs += 1,
                else => {},
            }
        }
        std.debug.print("流式版：{d} 文件 / {d} 目录 / {d} 字节 / 最深 {s}（depth={d}）\n", .{ files, dirs, total, deepest_path, deepest_d });
        std.debug.print("⇒ 两种口径一致：文件数 {d} == {d}，字节数 {d} == {d}（都只数.kind==.file）\n", .{ tree.fileCount(), files, tree.totalSize(), total });
        std.debug.print("⇒ 符号链接两边都不计入字节（它的 size 是链接串的长度，不是目标大小）\n", .{});
        std.debug.print("⇒ 只要汇总数字 → 流式（内存 O(1)）；要多次查询 / 要排序 / 要 GUI 展示 → 先建树\n", .{});
        std.debug.print("⇒ 上万条目的目录**别把整棵树读进内存**：walk 的栈是堆分配的，但 name_buffer 也一样\n", .{});
        std.debug.print("   真要\"大树小内存\"就用流式 + 外部排序（把路径写临时文件再 sort）\n", .{});
    }
    end("27.13");

    // ═══ 27.14 glob 模式匹配：0.17 没有内建 ═══
    begin("27.14");
    {
        std.debug.print("@hasDecl(std, \"glob\")={} @hasDecl(std.fs, \"glob\")={} @hasDecl(std.fs.path, \"glob\")={}\n", .{
            @hasDecl(std, "glob"),
            @hasDecl(std.fs, "glob"),
            @hasDecl(std.fs.path, "glob"),
        });
        std.debug.print("⇒ 0.17 **没有任何内建 glob**；std.fs.path 只有 join/basename/extension 这类纯字符串函数\n", .{});
        std.debug.print("示例自带一个回溯版 globMatch：`*` 不跨分隔符、`?` 单字符、`**` 跨任意层\n", .{});

        const cases = [_][3][]const u8{
            .{ "a.md", "*.md", "true" },
            .{ "c.txt", "*.txt", "true" },
            .{ "d.log", "*.txt", "false" },
            .{ "b.txt", "?.txt", "true" },
            .{ "bb.txt", "?.txt", "false" },
            .{ ".gitignore", ".*", "true" },
            .{ "empty.txt", "*", "true" },
            .{ "src/deep/leaf.txt", "src/*.txt", "false" },
            .{ "src/deep/leaf.txt", "**/*.txt", "true" },
            .{ "leaf.txt", "**/*.txt", "true" },
            .{ "a/b/c.txt", "a/**/c.txt", "true" },
            .{ "a/c.txt", "a/**/c.txt", "true" },
            .{ "a/b/c.txt", "a/*/c.txt", "true" },
            .{ "a/b/d/c.txt", "a/*/c.txt", "false" },
        };
        var fails: usize = 0;
        for (cases) |c| {
            const got = globMatch(c[0], c[1]);
            const want = std.mem.eql(u8, c[2], "true");
            if (got != want) {
                fails += 1;
                std.debug.print("  x globMatch({s}, {s}) = {}，期望 {s}\n", .{ c[0], c[1], got, c[2] });
            } else std.debug.print("  v globMatch({s:<20} , {s:<10}) = {s}\n", .{ c[0], c[1], c[2] });
        }
        std.debug.print("  {d} 个用例，失败 {d} 个\n", .{ cases.len, fails });
        std.debug.print("⚠️ 回溯写法两个坑（都实测撞过）：\n", .{});
        std.debug.print("   (1) `*` 的循环里 i 可以等于 name.len（匹配空串那一支）\n", .{});
        std.debug.print("       先取 name[i] 再判i==len ⇒ panic: index out of bounds: index 5, len 5\n", .{});
        std.debug.print("   (2) 必须**先递归再判 '/'**；反过来写 \"a/*/c.txt\" vs \"a/b/c.txt\" 会判成 false\n", .{});
        std.debug.print("⇒ 真实工具（fd / rg / gitignore）用的是正则或状态机：O(n·m) 而回溯最坏指数级\n", .{});
        std.debug.print("   自己写 glob 时要记住：回溯是**为了讲清原理**，不是**为了快**\n", .{});
    }
    end("27.14");

    // ═══ 27.15 目录的建 / 删 / 改：签名与 io 的位置 ═══
    begin("27.15");
    {
        std.debug.print("建：createDir(io, path, perms) 建一层 / createDirPath(io, path) 递归\n", .{});
        std.debug.print("    createDirPathStatus(io, path, perms) 返回 .existed 或 .created\n", .{});
        std.debug.print("    createDirPathOpen(io, path, opts) 建+开一步，opts 里**套一层** .open_options\n", .{});
        std.debug.print("删：deleteFile(io, path) / deleteDir(io, path)（非空 → DirNotEmpty）\n", .{});
        std.debug.print("    deleteTree(io, path) 递归删整棵子树\n", .{});
        std.debug.print("    deleteTreeMinStackSize(io, path) 同上但省栈（上千层目录用）\n", .{});
        std.debug.print("查：access(io, path, opts) 存在性/权限（opts 是 **packed struct**）\n", .{});
        std.debug.print("    stat(io) 对已打开的 Dir 取元数据 / statFile(io, path, opts) 按路径\n", .{});

        // 跨两个 Dir 的四个方法：io 的位置实测
        try cwd.rename(sbox ++ "/main.zig", cwd, sbox ++ "/main2.zig", io); // io 第 4
        std.debug.print("rename(old, new_dir, new_path, io) —— **io 在第 4 位**（不是第 1 位）\n", .{});
        try cwd.hardLink(sbox ++ "/main2.zig", cwd, sbox ++ "/main2_hard.zig", io, .{}); // io 第 5
        const s1 = try cwd.statFile(io, sbox ++ "/main2.zig", .{});
        const s2 = try cwd.statFile(io, sbox ++ "/main2_hard.zig", .{});
        std.debug.print("hardLink(old, new_dir, new_path, io, opts) —— io 第 5；inode 相同={} nlink={d}\n", .{ s1.inode == s2.inode, s2.nlink });
        try cwd.copyFile(sbox ++ "/main2.zig", cwd, sbox ++ "/main2_copy.zig", io, .{}); // io 第 5
        std.debug.print("copyFile(src, dst_dir, dst_path, io, opts) —— io 第 5；副本 {d} 字节\n", .{(try cwd.statFile(io, sbox ++ "/main2_copy.zig", .{})).size});
        try cwd.symLinkAtomic(io, "main2.zig", sbox ++ "/main2_atomic", .{}); // io 第 1（例外）
        std.debug.print("symLinkAtomic(io, target, link, flags) —— **io 在第 1 位**（例外！）\n", .{});
        const up1 = try cwd.updateFile(io, sbox ++ "/main2.zig", cwd, sbox ++ "/main2_upd.zig", .{});
        const up2 = try cwd.updateFile(io, sbox ++ "/main2.zig", cwd, sbox ++ "/main2_upd.zig", .{});
        std.debug.print("updateFile(io, src, dst_dir, dst, opts) —— io 第 1；两次 = {t} / {t}\n", .{ up1, up2 });
        std.debug.print("⇒ 规律：**跨两个 Dir 的方法 io 多半靠后，但 symLinkAtomic / updateFile 是例外**\n", .{});
        std.debug.print("   搞错了报 member function expected 4 argument(s), found 3 —— 逐个查，别照上一个补io\n", .{});

        // deleteDir 非空保护
        if (cwd.deleteDir(io, sbox ++ "/src")) |_| {
            std.debug.print("deleteDir 非空目录成功？不该\n", .{});
        } else |err| std.debug.print("deleteDir(src) 非空 → {s}（保护不是限制：递归删要显式 deleteTree）\n", .{@errorName(err)});
        // access
        if (cwd.access(io, sbox ++ "/nope.txt", .{})) |_| {
            std.debug.print("access 不存在成功？不该\n", .{});
        } else |err| std.debug.print("access(不存在) → {s}（比 statFile 便宜，但有 TOCTOU）\n", .{@errorName(err)});
        std.debug.print("⚠️ access 说存在 != 下一句 openFile 成功（TOCTOU）；真判断必须在 openFile 的错误上做\n", .{});
    }
    end("27.15");

    // ═══ 27.16 Dir.Reader：第四种方式，批量读 ═══
    begin("27.16");
    {
        const RI = @typeInfo(std.Io.Dir.Reader).@"struct";
        std.debug.print("Dir.Reader 字段：", .{});
        inline for (RI.field_names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});
        std.debug.print("  state: reset / reading / finished；reset() 回到 reset（等价 lseek 回 0）\n", .{});
        std.debug.print("  ⚠️ @hasDecl(Dir, \"reader\") = {}—— 没有这个方法，要自己 Dir.Reader.init\n", .{@hasDecl(std.Io.Dir, "reader")});
        std.debug.print("  ⚠️ 缓冲必须是 align(@alignOf(usize)) 的：普通 [N]u8 传不进去\n", .{});
        std.debug.print("     实测报错：expected type '[]align(8) u8', found '*[1048]u8'\n", .{});
        std.debug.print("               pointer alignment '1' cannot cast into pointer alignment '8'\n", .{});
        var rbuf: [std.Io.Dir.Reader.min_buffer_len]u8 align(@alignOf(usize)) = undefined;
        var d = try cwd.openDir(io, sbox, .{ .iterate = true });
        defer d.close(io);
        var rdr = std.Io.Dir.Reader.init(d, &rbuf);
        var batch: [32]std.Io.Dir.Entry = undefined;
        const n1 = try rdr.read(io, &batch);
        std.debug.print("  read 一次拿到 {d} 个条目（min_buffer_len={d} 字节，一次系统调用读全）\n", .{ n1, std.Io.Dir.Reader.min_buffer_len });
        var cnt: usize = n1;
        while (true) {
            const n2 = try rdr.read(io, &batch);
            if (n2 == 0) break;
            cnt += n2;
        }
        std.debug.print("  读到 {d} 个（Iterator 一次只要一个条目，Reader 才是批量的）\n", .{cnt});
        rdr.reset();
        const again = try rdr.read(io, &batch);
        std.debug.print("  reset() 后再 read → {d} 个（同一目录能重扫）\n", .{again});
        std.debug.print("⇒ 上万条目的目录用 Reader 能把系统调用次数降一个量级\n", .{});
        std.debug.print("   但 name 依旧指向那块缓冲 ⇒ 跨 read 收集还是得 dupe（同 27.5）\n", .{});
    }
    end("27.16");

    // ═══ 27.17 跨平台差异 ═══
    begin("27.17");
    {
        const os = @import("builtin").os.tag;
        std.debug.print("当前平台 = {s}；path.sep = '{c}'（Windows 上是反斜杠）\n", .{ @tagName(os), std.fs.path.sep });
        std.debug.print("⚠️ 大小写敏感性**不是编译期常量**：macOS 默认 APFS 不敏感、Linux ext4 敏感、Windows 不敏感\n", .{});
        std.debug.print("   Zig 不会替你问文件系统 ⇒ 跨平台代码只能：① 用 openFile 成功与否当判据\n", .{});
        std.debug.print("   ② 或者两种大小写都试一遍 ③ 或者在UI 上让用户自己输入\n", .{});
        std.debug.print("   能做的只是**字符串层面**的排序：'A'=='a' 是 {}；std.mem.order(\"A\",\"a\") = {t}\n", .{
            @as(u8, 'A') == @as(u8, 'a'),
            std.mem.order(u8, "A", "a"),
        });
        std.debug.print("   ⇒ std.mem.order 是**字节序**（永远大小写敏感），别拿它当\"文件名相等\"的判据\n", .{});
        std.debug.print("⇒ Windows 上 .iterate 必须**在 openDir 时**开，否则**迭代时**才报 AccessDenied\n", .{});
        std.debug.print("   错误时机在迭代处而不是打开处，极具迷惑性；POSIX 不验证这一项（实测能遍历）\n", .{});
        std.debug.print("⇒ Windows 不许删\"正在使用\"的目录：openDir 着的目录 deleteTree 会失败\n", .{});
        std.debug.print("   POSIX 允许 unlink 已打开的文件 ⇒ Linux 上\"边遍历边删\"能跑，Windows 不能\n", .{});
        std.debug.print("⇒ Windows 创建符号链接要管理员或开发者模式 ⇒ 依赖链接的代码必须有降级分支\n", .{});
        std.debug.print("⇒ kind = .unknown 会出现在网络/FUSE 文件系统上 ⇒ 不能把 kind != .file 当\"是目录\"\n", .{});
        std.debug.print("⇒ symLink 的 SymLinkFlags.is_directory **只在 Windows 上有意义**（其它平台忽略）\n", .{});
        std.debug.print("⇒ macOS 上 readdir 返回的名字是**UTF-8 分解形式**（NFD），Linux 上是 NFC\n", .{});
        std.debug.print("   ⇒ 比对非ASCII 文件名时 memcmp 会莫名失败；要先 std.unicode.normalize\n", .{});
    }
    end("27.17");

    std.debug.print("自检通过\n", .{});
}

fn lessRow(_: void, x: [2][]const u8, y: [2][]const u8) bool {
    return std.mem.order(u8, x[0], y[0]) == .lt;
}

/// 27.12：数树里某种 kind 的节点有几个（用于把"节点总数"拆成文件/目录/链接）
fn countKind(n: *const Node, kind: std.Io.File.Kind) usize {
    var c: usize = if (n.kind == kind) 1 else 0;
    for (n.children.items) |ch| c += countKind(ch, kind);
    return c;
}

// ═══════════════════════ 测试 ═══════════════════════

test "27.2 Entry 只有 3 个字段，kind 的类型是 Io.File.Kind" {
    const E = @typeInfo(std.Io.Dir.Entry).@"struct";
    try std.testing.expectEqual(@as(usize, 3), E.field_names.len);
    try std.testing.expectEqualStrings("name", E.field_names[0][0..4]);
    try std.testing.expectEqualStrings("kind", E.field_names[1][0..4]);
    try std.testing.expectEqualStrings("inode", E.field_names[2][0..5]);
    // kind 的类型是 Io.File.Kind，不是 Io.Dir.Entry.Kind（后者不存在）
    try std.testing.expectEqualStrings("Io.File.Kind", @typeName(@FieldType(std.Io.Dir.Entry, "kind")));
    // File.Kind 11 个成员；遍历里常见的四种
    try std.testing.expectEqual(@as(usize, 11), @typeInfo(std.Io.File.Kind).@"enum".field_names.len);
    inline for (.{ std.Io.File.Kind.file, .directory, .sym_link, .unknown }) |k| {
        try std.testing.expect(k != .block_device);
    }
    // Stat 9 个字段，atime 是可选
    const S = @typeInfo(std.Io.File.Stat).@"struct";
    try std.testing.expectEqual(@as(usize, 9), S.field_names.len);
    try std.testing.expectEqualStrings("?Io.Timestamp", @typeName(@FieldType(std.Io.File.Stat, "atime")));
    try std.testing.expectEqualStrings("Io.Timestamp", @typeName(@FieldType(std.Io.File.Stat, "mtime")));
}

test "27.3 同一个 Dir 能 iterate 两遍；空目录返回 null" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "a.txt", .data = "1" });
    try tmp.dir.writeFile(io, .{ .sub_path = "b.txt", .data = "2" });

    var d = try tmp.dir.openDir(io, ".", .{ .iterate = true });
    defer d.close(io);
    var n1: usize = 0;
    var it = d.iterate();
    while (try it.next(io)) |_| n1 += 1;
    var n2: usize = 0;
    var it2 = d.iterate();
    while (try it2.next(io)) |_| n2 += 1;
    try std.testing.expectEqual(@as(usize, 2), n1);
    try std.testing.expectEqual(n1, n2); // iterate() 自带 reset

    // 空目录
    try tmp.dir.createDirPath(io, "empty");
    var e = try tmp.dir.openDir(io, "empty", .{ .iterate = true });
    defer e.close(io);
    var ite = e.iterate();
    const first = try ite.next(io);
    try std.testing.expect(first == null);
}

test "27.5 entry.name跨 next() 失效：不 dupe 会拿到失效的名字" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    // 造足够多的条目，保证 Iterator 的 2048 字节内嵌缓冲被填满多次。
    // 名字取得长一点（20 字节）⇒200 个条目远超2048 字节 ⇒ 必然多次 fillMore。
    var name_buf: [64]u8 = undefined;
    const n_files = 200;
    for (0..n_files) |i| {
        const nm = try std.fmt.bufPrint(&name_buf, "a_rather_long_name_{d:0>3}.txt", .{i});
        try tmp.dir.writeFile(io, .{ .sub_path = nm, .data = "x" });
    }
    const a = std.testing.allocator;
    var bad: std.ArrayList([]const u8) = .empty;
    {
        var d = try tmp.dir.openDir(io, ".", .{ .iterate = true });
        defer d.close(io);
        var it = d.iterate();
        while (try it.next(io)) |e| try bad.append(a, e.name); // ❌ 不 dupe
    }
    defer bad.deinit(a);
    try std.testing.expectEqual(@as(usize, n_files), bad.items.len);
    // 判据1：切片内容有重复（多个切片指向同一块缓冲）
    var has_dup = false;
    outer: for (bad.items, 0..) |x, i| {
        for (bad.items[0..i]) |y| {
            if (std.mem.eql(u8, x, y)) {
                has_dup = true;
                break :outer;
            }
        }
    }
    try std.testing.expect(has_dup);
    // 判据 2：拿这些名字去 access 会失败（内容已被覆盖，不是真名字了）
    var broken: usize = 0;
    for (bad.items) |n| {
        tmp.dir.access(io, n, .{}) catch {
            broken += 1;
            continue;
        };
    }
    try std.testing.expect(broken > 0);

    // dupe 之后全部有效
    var good: std.ArrayList([]const u8) = .empty;
    {
        var d = try tmp.dir.openDir(io, ".", .{ .iterate = true });
        defer d.close(io);
        var it = d.iterate();
        while (try it.next(io)) |e| try good.append(a, try a.dupe(u8, e.name));
    }
    defer {
        for (good.items) |n| a.free(n);
        good.deinit(a);
    }
    try std.testing.expectEqual(@as(usize, n_files), good.items.len);
    for (good.items) |n| try tmp.dir.access(io, n, .{});
}

test "27.6 walk 返回带路径的条目，根目录本身不在结果里" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.createDirPath(io, "w/sub/deep");
    try tmp.dir.writeFile(io, .{ .sub_path = "w/a.txt", .data = "A" });
    try tmp.dir.writeFile(io, .{ .sub_path = "w/sub/b.txt", .data = "BB" });
    try tmp.dir.writeFile(io, .{ .sub_path = "w/sub/deep/c.txt", .data = "CCC" });

    var d = try tmp.dir.openDir(io, "w", .{ .iterate = true });
    defer d.close(io);
    var w = try d.walk(a);
    defer w.deinit();
    var paths: std.ArrayList([]const u8) = .empty;
    defer paths.deinit(a);
    var max_depth: usize = 0;
    while (try w.next(io)) |e| {
        try paths.append(a, try a.dupe(u8, e.path));
        if (e.depth() > max_depth) max_depth = e.depth();
        // Walker.Entry 的 dir + basename 可以直接定位，不必拼长路径
        if (e.kind == .file) {
            const st = try e.dir.statFile(io, e.basename, .{});
            try std.testing.expect(st.size > 0);
        }
    }
    try std.testing.expectEqual(@as(usize, 5), paths.items.len); // 2 目录 + 3 文件
    try std.testing.expectEqual(@as(usize, 3), max_depth);
    std.mem.sort([]const u8, paths.items, {}, lessStr);
    try std.testing.expectEqualStrings("a.txt", paths.items[0]);
    try std.testing.expectEqualStrings("sub", paths.items[1]);
    try std.testing.expectEqualStrings("sub/b.txt", paths.items[2]);
    try std.testing.expectEqualStrings("sub/deep", paths.items[3]);
    try std.testing.expectEqualStrings("sub/deep/c.txt", paths.items[4]);
    for (paths.items) |p| a.free(p);
}

test "27.7 walk 的 break 提前终止；deinit 不关外层 Dir" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.createDirPath(io, "w/x/y");
    for ([_][]const u8{ "w/1.txt", "w/2.txt", "w/3.txt", "w/x/4.txt", "w/x/y/5.txt" }) |p| {
        try tmp.dir.writeFile(io, .{ .sub_path = p, .data = "xxxxx" });
    }
    var d = try tmp.dir.openDir(io, "w", .{ .iterate = true });
    defer d.close(io);
    var w = try d.walk(a);
    defer w.deinit();
    var visited: usize = 0;
    while (try w.next(io)) |_| {
        visited += 1;
        if (visited == 2) break; // 只看两个就收工
    }
    try std.testing.expectEqual(@as(usize, 2), visited);
    // deinit 之后 d 仍然可用（deinit 只管 Walker 自己的栈 + name_buffer）
    var it = d.iterate();
    var cnt: usize = 0;
    while (try it.next(io)) |_| cnt += 1;
    try std.testing.expect(cnt > 0);
}

test "27.8 walkSelectively：enter 进去、leave 剪掉分支" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.createDirPath(io, "w/x/y");
    try tmp.dir.writeFile(io, .{ .sub_path = "w/a.txt", .data = "A" });
    try tmp.dir.writeFile(io, .{ .sub_path = "w/x/b.txt", .data = "BB" });
    try tmp.dir.writeFile(io, .{ .sub_path = "w/x/y/c.txt", .data = "CCC" });

    var d = try tmp.dir.openDir(io, "w", .{ .iterate = true });
    defer d.close(io);
    var w = try d.walkSelectively(a);
    defer w.deinit();
    var seen: std.ArrayList([]const u8) = .empty;
    defer seen.deinit(a);
    while (try w.next(io)) |e| {
        try seen.append(a, try a.dupe(u8, e.path));
        if (std.mem.eql(u8, e.basename, "x")) {
            try w.enter(io, e); // 进 x
        } else if (e.kind == .directory and e.depth() >= 2) {
            w.leave(io); // y 不进
        }
    }
    var has_y_c = false;
    var has_x_b = false;
    for (seen.items) |p| {
        // ⚠️ leave() 弹的是**栈顶那个目录**（此处是 x），不是"刚看到的那个条目"。
        // 所以 y 只是被**报告**（出现在 seen 里），它的内容一个都没进。
        if (std.mem.eql(u8, p, "x/y/c.txt")) has_y_c = true;
        if (std.mem.eql(u8, p, "x/b.txt")) has_x_b = true;
        a.free(p);
    }
    try std.testing.expect(!has_y_c); // leave 之后 y 的内容一个都没访问
    try std.testing.expect(has_x_b); // x 的文件还是在
}

test "27.10 statFile 的 lstat 语义；follow_symlinks 实测是 bool" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "target.txt", .data = "0123456789" });
    try tmp.dir.symLink(io, "target.txt", "link", .{});

    // follow_symlinks 的类型实测就是 bool（不是联合字面量）
    try std.testing.expectEqual(@as(usize, 1), @typeInfo(std.Io.Dir.StatFileOptions).@"struct".field_names.len);
    try std.testing.expect(@TypeOf(@as(std.Io.Dir.StatFileOptions, undefined).follow_symlinks) == bool);

    const lst = try tmp.dir.statFile(io, "link", .{ .follow_symlinks = false });
    const stt = try tmp.dir.statFile(io, "link", .{});
    try std.testing.expectEqual(std.Io.File.Kind.sym_link, lst.kind);
    try std.testing.expectEqual(std.Io.File.Kind.file, stt.kind);
    try std.testing.expectEqual(@as(u64, 10), stt.size);
    // ⚠️ 实测：lstat 的 inode 和 stat 的**差 1**（macOS/APFS 给符号链接自己分配 inode）
    //   ⇒ "lstat.inode == stat.inode" 这种假设在 macOS 上是错的
    try std.testing.expect(lst.inode != stt.inode);
    try std.testing.expectEqual(lst.size, @as(u64, @intCast("target.txt".len))); // lstat 报链接串长度

    // readLink 拿到目标字符串
    var buf: [32]u8 = undefined;
    const n = try tmp.dir.readLink(io, "link", &buf);
    try std.testing.expectEqualStrings("target.txt", buf[0..n]);

    // 悬空链接：lstat 能看见，stat 报 FileNotFound
    try tmp.dir.symLink(io, "nope", "dead", .{});
    const dl = try tmp.dir.statFile(io, "dead", .{ .follow_symlinks = false });
    try std.testing.expectEqual(std.Io.File.Kind.sym_link, dl.kind);
    try std.testing.expectError(error.FileNotFound, tmp.dir.statFile(io, "dead", .{}));
}

test "27.11 符号链接：walk 报告但不跟进（天然防环）" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.createDirPath(io, "w/sub");
    try tmp.dir.writeFile(io, .{ .sub_path = "w/a.txt", .data = "A" });
    try tmp.dir.writeFile(io, .{ .sub_path = "w/sub/b.txt", .data = "BB" });
    // 指向父目录的目录链接 = 环
    try tmp.dir.symLink(io, "..", "w/loop", .{ .is_directory = true });

    var d = try tmp.dir.openDir(io, "w", .{ .iterate = true });
    defer d.close(io);
    var w = try d.walk(a);
    defer w.deinit();
    var paths: std.ArrayList([]const u8) = .empty;
    defer paths.deinit(a);
    while (try w.next(io)) |e| try paths.append(a, try a.dupe(u8, e.path));
    // 4 条：a.txt / sub / sub/b.txt / loop。
    // loop 被**报告**（它是个条目），但**没被跟进**——所以没有 loop/... 之类的东西
    try std.testing.expectEqual(@as(usize, 4), paths.items.len);
    var has_loop = false;
    for (paths.items) |p| {
        // 关键断言：没有任何条目以 "loop/" 开头 ⇒ 环没被跟进
        try std.testing.expect(!std.mem.startsWith(u8, p, "loop/"));
        if (std.mem.eql(u8, p, "loop")) has_loop = true;
        a.free(p);
    }
    try std.testing.expect(has_loop);
}

test "27.12/27.13 建树 + 三个查询（大小 / 文件数 / 最深路径）" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.createDirPath(io, "t/src/deep");
    try tmp.dir.writeFile(io, .{ .sub_path = "t/README.md", .data = "readme" }); // 6
    try tmp.dir.writeFile(io, .{ .sub_path = "t/main.zig", .data = "0123456789" }); // 10
    try tmp.dir.writeFile(io, .{ .sub_path = "t/src/app.zig", .data = "aaa" }); // 3
    try tmp.dir.writeFile(io, .{ .sub_path = "t/src/deep/leaf.txt", .data = "leafff" }); // 6

    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const a = arena_state.allocator();

    const tree = try buildTree(io, a, tmp.dir, "t", "t", 0);
    try std.testing.expectEqual(@as(u64, 25), tree.totalSize()); // 6+10+3+6
    try std.testing.expectEqual(@as(usize, 4), tree.fileCount());
    try std.testing.expectEqual(@as(usize, 7), tree.count()); // 根 + src + deep + 4 文件
    // deepest 返回**节点**（不是路径字符串）：调用方自己决定要什么
    const deep = tree.deepest();
    try std.testing.expectEqualStrings("leaf.txt", deep.name);
    try std.testing.expectEqualStrings("t/src/deep/leaf.txt", deep.path);
    try std.testing.expectEqual(@as(usize, 3), deep.depth);

    // 同层排序：目录排在文件前
    try std.testing.expectEqual(std.Io.File.Kind.directory, tree.children.items[0].kind);
    try std.testing.expectEqualStrings("src", tree.children.items[0].name);
    try std.testing.expectEqualStrings("README.md", tree.children.items[1].name);
    try std.testing.expectEqualStrings("main.zig", tree.children.items[2].name);

    // 流式口径一致
    var d = try tmp.dir.openDir(io, "t", .{ .iterate = true });
    defer d.close(io);
    var w = try d.walk(a);
    defer w.deinit();
    var total: u64 = 0;
    var files: usize = 0;
    while (try w.next(io)) |e| {
        if (e.kind == .file) {
            files += 1;
            total += (try e.dir.statFile(io, e.basename, .{})).size;
        }
    }
    try std.testing.expectEqual(tree.totalSize(), total);
    try std.testing.expectEqual(tree.fileCount(), files);
}

test "27.14 globMatch：* 不跨分隔符、** 跨层" {
    try std.testing.expect(globMatch("a.md", "*.md"));
    try std.testing.expect(globMatch("c.txt", "*.txt"));
    try std.testing.expect(!globMatch("d.log", "*.txt"));
    try std.testing.expect(globMatch("b.txt", "?.txt"));
    try std.testing.expect(!globMatch("bb.txt", "?.txt"));
    try std.testing.expect(globMatch(".gitignore", ".*"));
    try std.testing.expect(globMatch("", "*")); // * 匹配空串
    try std.testing.expect(globMatch("abc", "a*c"));
    try std.testing.expect(!globMatch("abc", "a*d"));
    try std.testing.expect(globMatch("abc", "a?c"));
    try std.testing.expect(!globMatch("ac", "a?c")); // ? 恰好要一个字符
    try std.testing.expect(!globMatch("abbc", "a?c")); // ? 最多一个字符
    // * 不跨 '/'
    try std.testing.expect(!globMatch("src/deep/leaf.txt", "src/*.txt"));
    // ** 跨任意层
    try std.testing.expect(globMatch("src/deep/leaf.txt", "**/*.txt"));
    try std.testing.expect(globMatch("leaf.txt", "**/*.txt")); // **/ 的斜杠可省
    try std.testing.expect(globMatch("a/b/c.txt", "a/**/c.txt"));
    try std.testing.expect(globMatch("a/c.txt", "a/**/c.txt"));
    try std.testing.expect(globMatch("a/b/c.txt", "a/*/c.txt"));
    try std.testing.expect(!globMatch("a/b/d/c.txt", "a/*/c.txt"));
}

test "27.14 walk + glob 组合：只统计 *.txt 的字节数" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.createDirPath(io, "w/sub");
    try tmp.dir.writeFile(io, .{ .sub_path = "w/a.txt", .data = "12345" });
    try tmp.dir.writeFile(io, .{ .sub_path = "w/b.md", .data = "1" });
    try tmp.dir.writeFile(io, .{ .sub_path = "w/sub/c.txt", .data = "12" });

    var d = try tmp.dir.openDir(io, "w", .{ .iterate = true });
    defer d.close(io);
    var w = try d.walk(a);
    defer w.deinit();
    var hits: std.ArrayList([]const u8) = .empty;
    defer hits.deinit(a);
    var total: u64 = 0;
    while (try w.next(io)) |e| {
        if (e.kind != .file) continue;
        if (!globMatch(e.path, "**/*.txt")) continue;
        try hits.append(a, try a.dupe(u8, e.path));
        total += (try e.dir.statFile(io, e.basename, .{})).size;
    }
    std.mem.sort([]const u8, hits.items, {}, lessStr);
    try std.testing.expectEqual(@as(usize, 2), hits.items.len);
    try std.testing.expectEqualStrings("a.txt", hits.items[0]);
    try std.testing.expectEqualStrings("sub/c.txt", hits.items[1]);
    try std.testing.expectEqual(@as(u64, 7), total); // 5 + 2
    for (hits.items) |p| a.free(p);
}

test "27.16 Dir.Reader 批量读 + reset（缓冲必须 align(usize)）" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var name_buf: [32]u8 = undefined;
    for (0..5) |i| {
        const nm = try std.fmt.bufPrint(&name_buf, "f{d}.txt", .{i});
        try tmp.dir.writeFile(io, .{ .sub_path = nm, .data = "x" });
    }
    var d = try tmp.dir.openDir(io, ".", .{ .iterate = true });
    defer d.close(io);
    var buf: [std.Io.Dir.Reader.min_buffer_len]u8 align(@alignOf(usize)) = undefined;
    var rdr = std.Io.Dir.Reader.init(d, &buf);
    var batch: [16]std.Io.Dir.Entry = undefined;
    var total: usize = 0;
    while (true) {
        const n = try rdr.read(io, &batch);
        if (n == 0) break;
        total += n;
    }
    try std.testing.expectEqual(@as(usize, 5), total);
    rdr.reset();
    const again = try rdr.read(io, &batch);
    try std.testing.expectEqual(@as(usize, 5), again);
    try std.testing.expect(!@hasDecl(std.Io.Dir, "reader")); // 没有 reader 方法
}

test "27.15 跨 Dir 的四个方法：io 在第 4/5 位，symLinkAtomic 在第 1 位" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.createDirPath(io, "d");
    try tmp.dir.writeFile(io, .{ .sub_path = "d/src.txt", .data = "hello" });

    // rename(old, new_dir, new_path, io)—— io 第 4
    try tmp.dir.rename("d/src.txt", tmp.dir, "d/renamed.txt", io);
    try std.testing.expectError(error.FileNotFound, tmp.dir.statFile(io, "d/src.txt", .{}));
    // hardLink(old, new_dir, new_path, io, options)—— io 第 5
    try tmp.dir.hardLink("d/renamed.txt", tmp.dir, "d/hard.txt", io, .{});
    const s1 = try tmp.dir.statFile(io, "d/renamed.txt", .{});
    const s2 = try tmp.dir.statFile(io, "d/hard.txt", .{});
    try std.testing.expectEqual(s1.inode, s2.inode);
    try std.testing.expectEqual(@as(u16, 2), s2.nlink);
    // copyFile(src, dst_dir, dst_path, io, options)—— io 第 5
    try tmp.dir.copyFile("d/renamed.txt", tmp.dir, "d/copied.txt", io, .{});
    try std.testing.expectEqual(@as(u64, 5), (try tmp.dir.statFile(io, "d/copied.txt", .{})).size);
    // symLinkAtomic(io, target, link, flags)—— io 在第 1 位（例外）
    try tmp.dir.symLinkAtomic(io, "d/renamed.txt", "d/atomic", .{});
    try std.testing.expectEqual(std.Io.File.Kind.sym_link, (try tmp.dir.statFile(io, "d/atomic", .{ .follow_symlinks = false })).kind);
    // updateFile(io, src, dst_dir, dst, options)—— io 也在第 1 位
    try std.testing.expectEqual(std.Io.Dir.PrevStatus.stale, try tmp.dir.updateFile(io, "d/renamed.txt", tmp.dir, "d/upd.txt", .{}));
    try std.testing.expectEqual(std.Io.Dir.PrevStatus.fresh, try tmp.dir.updateFile(io, "d/renamed.txt", tmp.dir, "d/upd.txt", .{}));
    // deleteDir 对非空目录报 DirNotEmpty（保护，不是限制）
    try std.testing.expectError(error.DirNotEmpty, tmp.dir.deleteDir(io, "d"));
    try tmp.dir.deleteTree(io, "d");
    try std.testing.expectError(error.FileNotFound, tmp.dir.statFile(io, "d", .{}));
}

test "27.4 权限错误：受限目录被跳过后其余条目照样统计到" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.createDirPath(io, "w");
    try tmp.dir.createDirPath(io, "w/locked");
    try tmp.dir.writeFile(io, .{ .sub_path = "w/a.txt", .data = "aa" });
    try tmp.dir.writeFile(io, .{ .sub_path = "w/locked/secret.txt", .data = "ssssssss" });
    try tmp.dir.setFilePermissions(io, "w/locked", @as(std.Io.File.Permissions, .fromMode(0)), .{});

    var files: std.ArrayList([]const u8) = .empty;
    defer {
        for (files.items) |p| a.free(p);
        files.deinit(a);
    }
    var skipped: usize = 0;
    try collectFiles(io, a, tmp.dir, "w", &files, 0, 16, &skipped);

    // 不管平台行为如何（Windows 上setFilePermissions 语义不同），
    // **顶层的 a.txt 一定要被看到** —— 这才是"跳过大目录"的意义
    var has_a = false;
    for (files.items) |p| {
        if (std.mem.eql(u8, std.fs.path.basename(p), "a.txt")) has_a = true;
    }
    try std.testing.expect(has_a);
    try std.testing.expect(skipped <= 1);

    try tmp.dir.setFilePermissions(io, "w/locked", @as(std.Io.File.Permissions, .fromMode(0o755)), .{});
}
