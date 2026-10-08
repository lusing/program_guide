//! 37 FileGuard：快照比对式文件完整性监护器（内容哈希 / inode 移动检测 / 双索引 / glob 过滤 / CLI）
//! 取材：Learning Zig 第 13 章 "Real-World Zig"（FileGuard 项目），按 0.17.0 实测重写：
//! 原书 8 文件压成单文件六节；fnmatch 换成纯 Zig 手写 glob（原书 @ptrCast 切片当 C
//! 字符串是 UB，且 fnmatch 是 POSIX 专属、Windows 没有）；zig-args 依赖换成手写解析。
//!
//! 与 28 章的分工：28 章是"监视器"（时间维度，轮询等事件，变更只有三类）；
//! 本章是"完整性台账"（空间维度，一次全量扫描出一份带哈希与 inode 的清册，
//! 两份清册求差能认出 moved——这是 28 章轮询核给不出的第四类变更）。
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ══════════════════════════════════════════════════════════════════
// 37.1 FileMetadata：一个文件的"身份证"
// ══════════════════════════════════════════════════════════════════

/// 单文件元数据。path 的内存**不归它管**——归 FileIndex 里那张 map 的 key 管
/// （36.7 的教训：谁拥有谁释放，全索引只 key 一份内存，Metadata.path 只是借用）。
const Metadata = struct {
    /// 相对扫描根的展示路径（借用 map key 的内存）。
    path: []const u8,
    size: u64,
    /// Io.Timestamp 的 i96 纳秒（28 章老熟人，取 .nanoseconds）。
    mtime_ns: i96,
    /// 移动检测的关键：rename 之后路径变了，inode 不变。0 是"无有效值"哨兵。
    /// 0.17 实测：stat.inode 是 i64（不是 u64）。
    inode: i64,
    /// 可选内容哈希（SHA-256 原始 32 字节；不开哈希就是 null）。
    checksum: ?[32]u8,

    fn sameIdentity(a: Metadata, b: Metadata) bool {
        return a.inode != 0 and a.inode == b.inode;
    }
};

/// 流式算 SHA-256：4KB 缓冲，多小的内存都能哈希多大的文件。
/// （原书动机：哈希 10GB 文件不能先读进内存。）
fn hashFile(dir: std.Io.Dir, io: std.Io, sub_path: []const u8) ![32]u8 {
    const f = try dir.openFile(io, sub_path, .{});
    defer f.close(io);
    var buf: [4096]u8 = undefined;
    var fr = f.reader(io, &buf);
    const r = &fr.interface;
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    while (true) {
        if (r.bufferedLen() > 0) {
            h.update(r.buffered());
            r.tossBuffered();
            continue;
        }
        r.fillMore() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
    }
    var out: [32]u8 = undefined;
    h.final(&out);
    return out;
}

// ══════════════════════════════════════════════════════════════════
// 37.2 手写 glob：`*` 与 `?`，对 basename 匹配
// ══════════════════════════════════════════════════════════════════

/// 递归 glob：`*` 匹配任意长（含空）字符序列，`?` 匹配恰好一个字符。
/// 原书用 C 的 fnmatch + `@ptrCast(pattern.ptr)`——切片不带 NUL 终止，
/// 当 C 字符串是 UB；fnmatch 又是 POSIX 专属。手写 20 行，三个问题一起消失。
fn globMatch(pattern: []const u8, name: []const u8) bool {
    if (pattern.len == 0) return name.len == 0;
    switch (pattern[0]) {
        '*' => {
            // 先试"匹配 0 个"，再逐个多吃一个字符
            var i: usize = 0;
            while (i <= name.len) : (i += 1) {
                if (globMatch(pattern[1..], name[i..])) return true;
            }
            return false;
        },
        '?' => return name.len > 0 and globMatch(pattern[1..], name[1..]),
        else => return name.len > 0 and pattern[0] == name[0] and
            globMatch(pattern[1..], name[1..]),
    }
}

/// exclude 优先（保镖先查黑名单），否则需命中任一 include。
fn shouldInclude(include: []const []const u8, exclude: []const []const u8, basename: []const u8) bool {
    for (exclude) |p| {
        if (globMatch(p, basename)) return false;
    }
    for (include) |p| {
        if (globMatch(p, basename)) return true;
    }
    return false;
}

// ══════════════════════════════════════════════════════════════════
// 37.3 FileIndex：path 索引 + inode 索引的双索引清册
// ══════════════════════════════════════════════════════════════════

/// 一轮全量扫描的产物。双索引各回答一个问题：
///   files  答"这条路径下的文件现在什么样"；
///   inodes 答"这个 inode 现在挂在哪条路径下"——moved 检测全靠它。
/// 内存纪律：path 字符串只存一份（files 的 key），Metadata.path 与
/// inodes 的 value 都借用这份内存；deinit 遍历 key 统一释放。
/// （原书为此专设第三张 path_storage 表当分配台账——单主 key 方案
/// 达到同一目的，少一张表；36.7 的 StringHashMap(void) 就是原书台账的写法。）
const FileIndex = struct {
    files: std.StringHashMap(Metadata),
    inodes: std.AutoHashMap(i64, []const u8),

    fn init(a: std.mem.Allocator) FileIndex {
        return .{
            .files = std.StringHashMap(Metadata).init(a),
            .inodes = std.AutoHashMap(i64, []const u8).init(a),
        };
    }

    /// 顺序即纪律：先拆柜子里东西的引用（inodes 借 key，先死），
    /// 再逐个释放 key，最后拆柜子。
    fn deinit(ix: *FileIndex, a: std.mem.Allocator) void {
        ix.inodes.deinit();
        var it = ix.files.keyIterator();
        while (it.next()) |k| a.free(k.*);
        ix.files.deinit();
    }

    /// 登记一个文件。path 在这里 dupe 成自有内存，是全部引用的唯一主人。
    fn add(ix: *FileIndex, a: std.mem.Allocator, path: []const u8, md: Metadata) !void {
        const owned = try a.dupe(u8, path);
        errdefer a.free(owned);
        var m = md;
        m.path = owned;
        try ix.files.put(owned, m);
        // inode==0 是哨兵：拿不到有效 inode 的文件不进 inode 索引
        if (md.inode != 0) try ix.inodes.put(md.inode, owned);
    }

    fn findByInode(ix: *const FileIndex, inode: i64) ?[]const u8 {
        if (inode == 0) return null;
        return ix.inodes.get(inode);
    }

    fn count(ix: *const FileIndex) u32 {
        return ix.files.count();
    }
};

// ══════════════════════════════════════════════════════════════════
// 37.4 遍历：配置 + 手写递归（max_depth 需要自己的递归，walk 不给这个旋钮）
// ══════════════════════════════════════════════════════════════════

const TraversalConfig = struct {
    max_depth: ?usize = null,
    include: []const []const u8 = &.{"*"},
    exclude: []const []const u8 = &.{},
    /// 内容哈希默认关：开了之后磁盘 I/O 成为主要代价，但能抓住
    /// "size 和 mtime 都没变"的暗改——速度 vs 彻底，交给用户选。
    hash_content: bool = false,
};

/// 把 root 下符合过滤条件的文件全部登记进 ix。
/// sub_path 是相对 root 的当前目录（"" 表示根本身）。
fn traverse(
    a: std.mem.Allocator,
    root: std.Io.Dir,
    io: std.Io,
    sub_path: []const u8,
    depth: usize,
    cfg: TraversalConfig,
    ix: *FileIndex,
) !void {
    if (cfg.max_depth) |md| {
        if (depth > md) return;
    }
    var d = if (sub_path.len == 0)
        try root.openDir(io, "", .{ .iterate = true })
    else
        try root.openDir(io, sub_path, .{ .iterate = true });
    defer d.close(io);

    var it = d.iterate();
    while (try it.next(io)) |entry| {
        // 27 章老坑：entry.name 活不过下一次 next()——本轮内必须用完或 dupe
        const rel = if (sub_path.len == 0)
            try a.dupe(u8, entry.name)
        else
            try std.fs.path.join(a, &.{ sub_path, entry.name });
        defer a.free(rel);

        switch (entry.kind) {
            .file => {
                if (!shouldInclude(cfg.include, cfg.exclude, entry.name)) continue;
                const st = try d.statFile(io, entry.name, .{});
                const sum: ?[32]u8 = if (cfg.hash_content)
                    try hashFile(d, io, entry.name)
                else
                    null;
                try ix.add(a, rel, .{
                    .path = "", // add 内部会换成自有 key
                    .size = st.size,
                    .mtime_ns = st.mtime.nanoseconds,
                    .inode = st.inode,
                    .checksum = sum,
                });
            },
            .directory => try traverse(a, root, io, rel, depth + 1, cfg, ix),
            // 符号链接默认不跟：成环（A→B→A）与重复入索引是两大已知危险，
            // 原书选择"可选跟随、接受重复"，本教程取更保守的默认。
            else => {},
        }
    }
}

// ══════════════════════════════════════════════════════════════════
// 37.5 变更检测：两遍扫描，moved 是一等公民
// ══════════════════════════════════════════════════════════════════

const ChangeKind = enum { created, deleted, modified, moved };

/// modified 的原因链：内容 > 尺寸 > mtime（命中即停，最硬的证据先说）。
const ModifiedReason = enum { content, size, mtime };

const FileChange = struct {
    kind: ChangeKind,
    /// created 时为 null；路径字符串全部自有（求差后旧索引就销毁，借就是悬空）。
    old_path: ?[]const u8,
    /// deleted 时为 null。
    new_path: ?[]const u8,
    reason: ?ModifiedReason = null,
};

const Journal = struct {
    changes: std.ArrayList(FileChange) = .empty,

    fn deinit(j: *Journal, a: std.mem.Allocator) void {
        for (j.changes.items) |c| {
            if (c.old_path) |p| a.free(p);
            if (c.new_path) |p| a.free(p);
        }
        j.changes.deinit(a);
    }

    fn add(j: *Journal, a: std.mem.Allocator, c: FileChange) !void {
        try j.changes.append(a, .{
            .kind = c.kind,
            .old_path = if (c.old_path) |p| try a.dupe(u8, p) else null,
            .new_path = if (c.new_path) |p| try a.dupe(u8, p) else null,
            .reason = c.reason,
        });
    }

    fn print(j: *const Journal) void {
        for (j.changes.items) |c| {
            switch (c.kind) {
                .created => std.debug.print("  [CREATED] {s}\n", .{c.new_path.?}),
                .deleted => std.debug.print("  [DELETED] {s}\n", .{c.old_path.?}),
                .moved => std.debug.print("  [MOVED]   {s} -> {s}\n", .{ c.old_path.?, c.new_path.? }),
                .modified => std.debug.print("  [MODIFIED] {s}（{s}）\n", .{
                    c.new_path.?,
                    @tagName(c.reason.?),
                }),
            }
        }
    }
};

/// 同路径两份元数据比对：先内容、再尺寸、最后 mtime（最弱信号：可能只是被 touch）。
fn modifiedReason(old: Metadata, new: Metadata) ?ModifiedReason {
    if (old.checksum != null and new.checksum != null and
        !std.mem.eql(u8, &old.checksum.?, &new.checksum.?)) return .content;
    if (old.size != new.size) return .size;
    if (old.mtime_ns != new.mtime_ns) return .mtime;
    return null;
}

/// 主算法：第一遍在 old 里找 deleted/moved，第二遍在 new 里找 created/modified。
fn detectChanges(a: std.mem.Allocator, old: *const FileIndex, new: *const FileIndex, j: *Journal) !void {
    // 第一遍：old 里消失的路径——同 inode 出现在 new 里就是 moved，否则 deleted
    var it = old.files.iterator();
    while (it.next()) |e| {
        const path = e.key_ptr.*;
        const md = e.value_ptr.*;
        if (new.files.contains(path)) continue;
        if (new.findByInode(md.inode)) |new_path| {
            try j.add(a, .{ .kind = .moved, .old_path = path, .new_path = new_path });
        } else {
            try j.add(a, .{ .kind = .deleted, .old_path = path, .new_path = null });
        }
    }
    // 第二遍：new 里的路径——老面孔查修改，新面孔查"是不是移动的目的地"，都不是才 created
    var it2 = new.files.iterator();
    while (it2.next()) |e| {
        const path = e.key_ptr.*;
        const md = e.value_ptr.*;
        if (old.files.get(path)) |old_md| {
            if (modifiedReason(old_md, md)) |reason| {
                try j.add(a, .{ .kind = .modified, .old_path = path, .new_path = path, .reason = reason });
            }
            continue;
        }
        // 第一遍已把"旧路径 → 这条路径"记成 moved，跳过
        if (old.findByInode(md.inode) != null) continue;
        try j.add(a, .{ .kind = .created, .old_path = null, .new_path = path });
    }
}

// ══════════════════════════════════════════════════════════════════
// 37.6 CLI：手写参数解析 + 单次扫描
// ══════════════════════════════════════════════════════════════════

const CliOptions = struct {
    path: []const u8 = ".",
    hash_content: bool = false,
    max_depth: ?usize = null,
    include: std.ArrayList([]const u8) = .empty,
    exclude: std.ArrayList([]const u8) = .empty,
    help: bool = false,
    /// 解析时是否真的见到过参数（Windows 上 args.vector 是整条命令行的
    /// WTF-16 缓冲、不是 argv 数组，0.17 实测——不能拿 vector.len 数参数）。
    seen_any: bool = false,

    fn deinit(o: *CliOptions, a: std.mem.Allocator) void {
        o.include.deinit(a);
        o.exclude.deinit(a);
    }
};

const usage =
    \\fileguard —— 快照式文件完整性监护（37 章示例）
    \\  用法: fileguard [选项] [目录=.]
    \\    --hash          开内容哈希（SHA-256，抓 size/mtime 不变的暗改；慢）
    \\    --max-depth=N   递归深度上限
    \\    --include=PAT   只收匹配 PAT 的文件名（可多次；默认 *）
    \\    --exclude=PAT   排除匹配 PAT 的文件名（可多次，优先于 include）
    \\    --help          显示本帮助
    \\  单次运行 = 建一份清册并打印统计；监护循环 = 周期性重建清册并与上份求差
    \\  （本示例的 main 演示的就是后者，见 37.6 自导自演）。
    \\
;

fn parseArgs(a: std.mem.Allocator, init: std.process.Init) !CliOptions {
    var opt: CliOptions = .{};
    // Windows 上必须 iterateAllocator（WTF-8 转码要缓冲），用完 deinit
    var args = try init.minimal.args.iterateAllocator(a);
    defer args.deinit();
    _ = args.next(); // 跳过 argv[0]
    while (args.next()) |arg| {
        opt.seen_any = true;
        const s: []const u8 = arg;
        if (std.mem.eql(u8, s, "--help")) {
            opt.help = true;
        } else if (std.mem.eql(u8, s, "--hash")) {
            opt.hash_content = true;
        } else if (std.mem.startsWith(u8, s, "--max-depth=")) {
            opt.max_depth = try std.fmt.parseInt(usize, s["--max-depth=".len..], 10);
        } else if (std.mem.startsWith(u8, s, "--include=")) {
            // ⚠️ 迭代器内部缓冲随 deinit 释放——落进 Options 的一律 dupe
            try opt.include.append(a, try a.dupe(u8, s["--include=".len..]));
        } else if (std.mem.startsWith(u8, s, "--exclude=")) {
            try opt.exclude.append(a, try a.dupe(u8, s["--exclude=".len..]));
        } else {
            opt.path = try a.dupe(u8, s);
        }
    }
    return opt;
}

/// CLI 模式：单次扫描，打印清册统计（监护循环的"建 baseline"那一半）。
fn runOnce(a: std.mem.Allocator, io: std.Io, opt: *const CliOptions) !void {
    const cwd = std.Io.Dir.cwd();
    var ix = FileIndex.init(a);
    defer ix.deinit(a);
    const include: []const []const u8 = if (opt.include.items.len > 0) opt.include.items else &.{"*"};
    try traverse(a, cwd, io, opt.path, 0, .{
        .max_depth = opt.max_depth,
        .include = include,
        .exclude = opt.exclude.items,
        .hash_content = opt.hash_content,
    }, &ix);
    var n_hashed: usize = 0;
    var it = ix.files.valueIterator();
    while (it.next()) |m| {
        if (m.checksum != null) n_hashed += 1;
    }
    std.debug.print("扫描 {s}：{d} 个文件入册（{d} 个带内容哈希）\n", .{
        opt.path, ix.count(), n_hashed,
    });
}

// ══════════════════════════════════════════════════════════════════
// main：无参 = 自导自演监护演示（沙盒内建 baseline → 搞破坏 → 求差）；
// 带参 = CLI 单次扫描。
// ══════════════════════════════════════════════════════════════════

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const a = init.arena.allocator();
    const cwd = std.Io.Dir.cwd();

    var opt = try parseArgs(a, init);
    defer opt.deinit(a);
    const has_args = opt.seen_any;
    if (opt.help) {
        std.debug.print("{s}", .{usage});
        return;
    }
    if (has_args) {
        try runOnce(a, io, &opt);
        return;
    }

    // ── 自导自演：/tmp 沙盒，输出可复现 ────────────────────────────
    begin("37.6 FileGuard 监护演示");
    const sbox = "/tmp/zig37_fileguard_demo";
    cwd.deleteTree(io, sbox) catch {};
    try cwd.createDirPath(io, sbox);
    defer cwd.deleteTree(io, sbox) catch {};

    // 布景：源码树一小片（writeFile 不会替你建中间目录）
    try cwd.createDirPath(io, sbox ++ "/src");
    try cwd.writeFile(io, .{ .sub_path = sbox ++ "/src/main.zig", .data = "pub fn main() void {}" });
    try cwd.writeFile(io, .{ .sub_path = sbox ++ "/src/util.zig", .data = "pub const x = 1;" });
    try cwd.writeFile(io, .{ .sub_path = sbox ++ "/README.md", .data = "# demo" });
    try cwd.writeFile(io, .{ .sub_path = sbox ++ "/build.log", .data = "noise" });

    const cfg: TraversalConfig = .{
        .include = &.{ "*.zig", "*.md" }, // build.log 被过滤
        .hash_content = true,
    };

    // 第 1 轮：建 baseline
    var baseline = FileIndex.init(a);
    try traverse(a, cwd, io, sbox, 0, cfg, &baseline);
    std.debug.print("baseline：{d} 个文件入册（build.log 已被 include 过滤）\n", .{baseline.count()});

    // ── 搞破坏：四种变更各来一份 ──
    // ① moved：util.zig 改名 lib.zig（inode 不变）
    try std.Io.Dir.rename(cwd, sbox ++ "/src/util.zig", cwd, sbox ++ "/src/lib.zig", io);
    // ② modified(content)：同长度换内容——size/mtime 都可能没变，只有哈希抓得到
    try cwd.writeFile(io, .{ .sub_path = sbox ++ "/README.md", .data = "# pwn!" });
    // ③ deleted
    try cwd.deleteFile(io, sbox ++ "/src/main.zig");
    // ④ created
    try cwd.writeFile(io, .{ .sub_path = sbox ++ "/docs.zig", .data = "// docs" });

    // 第 2 轮：扫新清册，求差
    var current = FileIndex.init(a);
    try traverse(a, cwd, io, sbox, 0, cfg, &current);
    var j: Journal = .{};
    try detectChanges(a, &baseline, &current, &j);
    std.debug.print("第二轮扫描检出 {d} 条变更：\n", .{j.changes.items.len});
    j.print();
    end("37.6 FileGuard 监护演示");

    // 收尾：换血（监护循环里 baseline = current），全部归还
    baseline.deinit(a);
    current.deinit(a);
    j.deinit(a);
    std.debug.print("自检通过\n", .{});
}

// ══════════════════════════════════════════════════════════════════
// 测试：tmpDir 造场景，每类变更一个 test
// ══════════════════════════════════════════════════════════════════

fn scanOnce(a: std.mem.Allocator, dir: std.Io.Dir, io: std.Io, cfg: TraversalConfig) !FileIndex {
    var ix = FileIndex.init(a);
    errdefer ix.deinit(a);
    try traverse(a, dir, io, "", 0, cfg, &ix);
    return ix;
}

test "37.2 glob 匹配" {
    try std.testing.expect(globMatch("*.zig", "main.zig"));
    try std.testing.expect(globMatch("*", "anything"));
    try std.testing.expect(globMatch("?.zig", "a.zig"));
    try std.testing.expect(globMatch("util.?ig", "util.zig"));
    try std.testing.expect(!globMatch("?.zig", "ab.zig"));
    try std.testing.expect(!globMatch("*.zig", "main.zig.bak"));
    try std.testing.expect(!globMatch("*.md", "main.zig"));
    // exclude 优先
    try std.testing.expect(!shouldInclude(&.{"*"}, &.{"*.log"}, "a.log"));
    try std.testing.expect(shouldInclude(&.{"*"}, &.{"*.log"}, "a.zig"));
    try std.testing.expect(!shouldInclude(&.{"*.zig"}, &.{}, "a.md"));
}

test "37.5 created / deleted" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "keep.txt", .data = "k" });

    var old = try scanOnce(a, tmp.dir, io, .{});
    defer old.deinit(a);
    try std.testing.expectEqual(@as(u32, 1), old.count());

    try tmp.dir.writeFile(io, .{ .sub_path = "new.txt", .data = "n" });
    try tmp.dir.deleteFile(io, "keep.txt");
    var new = try scanOnce(a, tmp.dir, io, .{});
    defer new.deinit(a);

    var j: Journal = .{};
    defer j.deinit(a);
    try detectChanges(a, &old, &new, &j);
    try std.testing.expectEqual(@as(usize, 2), j.changes.items.len);
    try std.testing.expectEqual(ChangeKind.deleted, j.changes.items[0].kind);
    try std.testing.expectEqualStrings("keep.txt", j.changes.items[0].old_path.?);
    try std.testing.expectEqual(ChangeKind.created, j.changes.items[1].kind);
    try std.testing.expectEqualStrings("new.txt", j.changes.items[1].new_path.?);
}

test "37.5 modified：size 与 mtime" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "a.txt", .data = "x" });

    var old = try scanOnce(a, tmp.dir, io, .{});
    defer old.deinit(a);
    try tmp.dir.writeFile(io, .{ .sub_path = "a.txt", .data = "xyz" }); // 变长
    var new = try scanOnce(a, tmp.dir, io, .{});
    defer new.deinit(a);

    var j: Journal = .{};
    defer j.deinit(a);
    try detectChanges(a, &old, &new, &j);
    try std.testing.expectEqual(@as(usize, 1), j.changes.items.len);
    try std.testing.expectEqual(ChangeKind.modified, j.changes.items[0].kind);
    try std.testing.expectEqual(ModifiedReason.size, j.changes.items[0].reason.?);
}

test "37.5 modified：同尺寸暗改只有哈希抓得到" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "a.txt", .data = "aaaa" });

    // 不开哈希 + 同长度重写：size 相同——mtime 若精度内撞车就完全隐形
    var plain_old = try scanOnce(a, tmp.dir, io, .{ .hash_content = false });
    defer plain_old.deinit(a);
    try std.testing.expect(plain_old.files.get("a.txt").?.checksum == null);

    // 开哈希：同长度换内容，检出 reason=content
    var old = try scanOnce(a, tmp.dir, io, .{ .hash_content = true });
    defer old.deinit(a);
    try tmp.dir.writeFile(io, .{ .sub_path = "a.txt", .data = "bbbb" });
    var new = try scanOnce(a, tmp.dir, io, .{ .hash_content = true });
    defer new.deinit(a);

    var j: Journal = .{};
    defer j.deinit(a);
    try detectChanges(a, &old, &new, &j);
    try std.testing.expectEqual(@as(usize, 1), j.changes.items.len);
    try std.testing.expectEqual(ModifiedReason.content, j.changes.items[0].reason.?);
}

test "37.5 moved：rename 检出 moved 而非 delete+create" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "before.txt", .data = "data" });

    var old = try scanOnce(a, tmp.dir, io, .{});
    defer old.deinit(a);
    try std.Io.Dir.rename(tmp.dir, "before.txt", tmp.dir, "after.txt", io);
    var new = try scanOnce(a, tmp.dir, io, .{});
    defer new.deinit(a);

    var j: Journal = .{};
    defer j.deinit(a);
    try detectChanges(a, &old, &new, &j);
    try std.testing.expectEqual(@as(usize, 1), j.changes.items.len);
    const c = j.changes.items[0];
    try std.testing.expectEqual(ChangeKind.moved, c.kind);
    try std.testing.expectEqualStrings("before.txt", c.old_path.?);
    try std.testing.expectEqualStrings("after.txt", c.new_path.?);
}

test "37.5 无变更就是零条" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "a.txt", .data = "x" });

    var old = try scanOnce(a, tmp.dir, io, .{});
    defer old.deinit(a);
    var new = try scanOnce(a, tmp.dir, io, .{});
    defer new.deinit(a);

    var j: Journal = .{};
    defer j.deinit(a);
    try detectChanges(a, &old, &new, &j);
    try std.testing.expectEqual(@as(usize, 0), j.changes.items.len);
}

test "37.4 遍历：max_depth 与 include 过滤" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.createDirPath(io, "d1/d2");
    try tmp.dir.writeFile(io, .{ .sub_path = "top.zig", .data = "t" });
    try tmp.dir.writeFile(io, .{ .sub_path = "d1/mid.zig", .data = "m" });
    try tmp.dir.writeFile(io, .{ .sub_path = "d1/d2/deep.zig", .data = "d" });
    try tmp.dir.writeFile(io, .{ .sub_path = "d1/skip.log", .data = "s" });

    var shallow = try scanOnce(a, tmp.dir, io, .{ .max_depth = 0 });
    defer shallow.deinit(a);
    try std.testing.expectEqual(@as(u32, 1), shallow.count()); // 只有 top.zig

    var zig_only = try scanOnce(a, tmp.dir, io, .{ .include = &.{"*.zig"} });
    defer zig_only.deinit(a);
    try std.testing.expectEqual(@as(u32, 3), zig_only.count()); // skip.log 被滤掉
}
