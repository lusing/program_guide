//! 27 目录遍历与文件元数据：statFile、递归走查、通配符、du 汇总、ztree 树形输出
//! 取材：Systems Programming with Zig ch5（ztree）+ Learning Zig ch13（FileGuard 遍历/过滤）
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const a = init.arena.allocator();
    const err = std.debug;
    const cwd = std.Io.Dir.cwd();

    // ═══ 27.1 元数据：statFile（follow_symlinks=false 是 lstat 语义——能"看见"链接本身）
    const self_meta = try cwd.statFile(io, "main.zig", .{ .follow_symlinks = false });
    err.print("main.zig：{d} 字节，kind={s}\n", .{ self_meta.size, @tagName(self_meta.kind) });
    // mtime 是纳秒时间戳：Io.Timestamp

    // ═══ 27.2 演示沙盒：搭一棵有层次的树（确定性：名字即内容）
    const sandbox = "tree_demo";
    try cwd.deleteTree(io, sandbox); // 幂等重来
    try cwd.createDirPath(io, sandbox);
    try cwd.writeFile(io, .{ .sub_path = sandbox ++ "/b.txt", .data = "BB" });
    try cwd.writeFile(io, .{ .sub_path = sandbox ++ "/a.md", .data = "AAAA" });
    try cwd.createDirPath(io, sandbox ++ "/sub");
    try cwd.writeFile(io, .{ .sub_path = sandbox ++ "/sub/c.txt", .data = "CCCCCC" });
    try cwd.writeFile(io, .{ .sub_path = sandbox ++ "/sub/d.log", .data = "D" });

    // ═══ 27.3 通配符：极简 glob（只支持 * 与 ?，够用且可测）
    std.debug.assert(matchGlob("a.md", "*.md"));
    std.debug.assert(matchGlob("c.txt", "*.txt"));
    std.debug.assert(!matchGlob("d.log", "*.txt"));
    std.debug.assert(matchGlob("b.txt", "?.txt"));

    // ═══ 27.4 递归遍历 + 收集：walk 返回排序后的完整路径（确定性输出）
    var files: std.ArrayList([]const u8) = .empty;
    try walk(io, a, cwd, sandbox, 0, &files);
    std.mem.sort([]const u8, files.items, {}, lessThanStr);
    for (files.items) |p| err.print("  {s}\n", .{p});

    // ═══ 27.5 过滤版走查 + du 汇总：只统计 *.txt 的字节数
    var total: u64 = 0;
    var n_txt: usize = 0;
    for (files.items) |p| {
        if (!matchGlob(std.fs.path.basename(p), "*.txt")) continue;
        const st = try cwd.statFile(io, p, .{});
        total += st.size;
        n_txt += 1;
    }
    err.print("du(*.txt)：{d} 个文件共 {d} 字节\n", .{ n_txt, total });

    // ═══ 27.6 ztree 树形输出（├──/└── 缩进语法）
    try printTree(io, a, cwd, sandbox, "");

    // ═══ 27.7 收拾沙盒
    try cwd.deleteTree(io, sandbox);
    err.print("自检通过\n", .{});
}

/// 递归走查：收集相对根的完整路径（深度防失控 max_depth）
fn walk(io: std.Io, a: std.mem.Allocator, dir: std.Io.Dir, path: []const u8, depth: usize, out: *std.ArrayList([]const u8)) !void {
    if (depth > 16) return; // 套娃防线（真实工具应报错而不是静默截断——见坑位）
    var d = try dir.openDir(io, path, .{ .iterate = true }); // Windows 不给 .iterate 会 AccessDenied
    defer d.close(io);
    var it = d.iterate();
    while (try it.next(io)) |entry| {
        const child = try std.fs.path.join(a, &.{ path, entry.name });
        switch (entry.kind) {
            .directory => {
                try walk(io, a, dir, child, depth + 1, out);
                a.free(child); // 目录路径只是递归的脚手架，所有权留在调用方
            },
            .file => try out.append(a, child), // 文件路径的所有权移交 out
            else => {}, // 符号链接/设备等：默认不跟（防环），需要时用 readLink 解析
        }
    }
}

/// 极简 glob：* 任意串、? 单字符；递归回溯，无依赖
pub fn matchGlob(name: []const u8, pattern: []const u8) bool {
    if (pattern.len == 0) return name.len == 0;
    if (pattern[0] == '*') {
        // "*x" 匹配任何以 x 结尾（含空）的后缀
        var i: usize = 0;
        while (i <= name.len) : (i += 1) {
            if (matchGlob(name[i..], pattern[1..])) return true;
        }
        return false;
    }
    if (name.len == 0) return false;
    if (pattern[0] == '?' or pattern[0] == name[0]) return matchGlob(name[1..], pattern[1..]);
    return false;
}

fn lessThanStr(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.order(u8, a, b) == .lt;
}

/// 目录大小汇总（du 语义：文件字节数之和，目录不另计）
fn dirSize(io: std.Io, a: std.mem.Allocator, dir: std.Io.Dir, path: []const u8) !u64 {
    var d = try dir.openDir(io, path, .{ .iterate = true });
    defer d.close(io);
    var total: u64 = 0;
    var it = d.iterate();
    while (try it.next(io)) |entry| {
        const st = try d.statFile(io, entry.name, .{});
        if (entry.kind == .directory) {
            const child = try std.fs.path.join(a, &.{ path, entry.name });
            total += try dirSize(io, a, dir, child);
            a.free(child);
        } else {
            total += st.size;
        }
    }
    return total;
}

/// 树形打印：先列目录（递归），文件排序后缀 └── 收尾
fn printTree(io: std.Io, a: std.mem.Allocator, dir: std.Io.Dir, path: []const u8, prefix: []const u8) !void {
    const err = std.debug;
    var d = try dir.openDir(io, path, .{ .iterate = true });
    defer d.close(io);
    var names: std.ArrayList([]const u8) = .empty;
    defer {
        for (names.items) |n| a.free(n); // entry.name 指向迭代器内部缓冲，必须 dupe 后才能跨 next 存
        names.deinit(a);
    }
    var it = d.iterate();
    while (try it.next(io)) |entry| try names.append(a, try a.dupe(u8, entry.name));
    std.mem.sort([]const u8, names.items, {}, lessThanStr);
    for (names.items, 0..) |name, i| {
        const last = i == names.items.len - 1;
        const branch = if (last) "└── " else "├── ";
        const st = try d.statFile(io, name, .{});
        if (st.kind == .directory) {
            err.print("{s}{s}{s}/\n", .{ prefix, branch, name });
            const child_prefix = try std.mem.concat(a, u8, &.{ prefix, if (last) "    " else "│   " });
            const child = try std.fs.path.join(a, &.{ path, name });
            try printTree(io, a, dir, child, child_prefix);
        } else {
            err.print("{s}{s}{s}  ({d} B)\n", .{ prefix, branch, name, st.size });
        }
    }
}

// ═══ 27.8 测试：沙盒里走查/过滤/汇总全断言
test "走查收集 + glob + du" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    // 造树：/a.txt /sub/b.txt /sub/c.md
    try tmp.dir.writeFile(io, .{ .sub_path = "a.txt", .data = "12345" });
    try tmp.dir.createDirPath(io, "sub");
    try tmp.dir.writeFile(io, .{ .sub_path = "sub/b.txt", .data = "12" });
    try tmp.dir.writeFile(io, .{ .sub_path = "sub/c.md", .data = "1" });

    var files: std.ArrayList([]const u8) = .empty;
    defer {
        for (files.items) |p| a.free(p);
        files.deinit(a);
    }
    try walk(io, a, tmp.dir, ".", 0, &files);
    std.mem.sort([]const u8, files.items, {}, lessThanStr);
    // Windows 下 join 出 ".\\a.txt"——断言用 basename 避开分隔符差异
    try std.testing.expectEqual(@as(usize, 3), files.items.len);
    try std.testing.expectEqualStrings("a.txt", std.fs.path.basename(files.items[0]));
    try std.testing.expectEqualStrings("b.txt", std.fs.path.basename(files.items[1]));
    try std.testing.expectEqualStrings("c.md", std.fs.path.basename(files.items[2]));

    var total: u64 = 0;
    for (files.items) |p| {
        if (!matchGlob(std.fs.path.basename(p), "*.txt")) continue;
        const st = try tmp.dir.statFile(io, p, .{});
        total += st.size;
    }
    try std.testing.expectEqual(@as(u64, 7), total); // 5 + 2
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    try std.testing.expectEqual(@as(u64, 8), try dirSize(io, arena_state.allocator(), tmp.dir, "."));

    // tmpDir 里的符号链接默认不跟：walk 只该看到三个文件（Linux 上有 symlink 权限时另测）
}

test "glob 边界" {
    try std.testing.expect(matchGlob("", "*"));
    try std.testing.expect(matchGlob("abc", "a*c"));
    try std.testing.expect(!matchGlob("abc", "a*d"));
    try std.testing.expect(matchGlob("abc", "a?c"));
    try std.testing.expect(!matchGlob("ac", "a?c"));
    try std.testing.expect(matchGlob(".gitignore", ".*"));
}
