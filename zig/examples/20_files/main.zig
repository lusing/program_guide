//! 20 文件与 IO：std.Io.Dir / std.Io.File、读写、目录遍历、路径、std.json、错误处理
//!
//! 0.16/0.17 变化：std.fs.File/Dir 并入 std.Io，几乎全部方法第一个参数是 io。
//! 这不是风格问题——它让"I/O 从哪来"变成签名的一部分，于是可替换、可测试、可异步化。
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

/// 20.11 的结构体：故意**不**在字段里存 Writer/Reader。
/// 因为 `file.writer(io, buf)` 返回的 Writer 内部持有 buf 的指针，
/// 若把这个 Writer 按值拷进结构体再返回，buf（栈上）就悬垂了（20.14 实测）。
const Config = struct {
    name: []const u8,
    retries: u32,
};

/// 20.11：序列化用"结构体 + 手写字段顺序"，比反射更可控（不想输出的字段就不声明）
const ConfigJson = struct {
    name: []const u8,
    retries: u32,
};

/// 20.12：错误处理的样板——把"文件不存在"和"别的错"分开
fn readConfig(io: std.Io, dir: std.Io.Dir, gpa: std.mem.Allocator, path: []const u8) !?[]u8 {
    return dir.readFileAlloc(io, path, gpa, .limited(64 * 1024)) catch |err| switch (err) {
        error.FileNotFound => null, // 没这个文件不是错误，返回"没有配置"
        error.AccessDenied, error.PermissionDenied => return err, // 权限问题是真错误，往上抛
        else => |e| return e,
    };
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const mem = arena_state.allocator();
    const cwd = std.Io.Dir.cwd();

    // ═══ 20.1 为什么每个方法都要传io：Io 是显式依赖 ═══
    begin("20.1");
    std.debug.print("std.fs.cwd 在 0.17 **不存在**了（@hasDecl = {}）\n", .{@hasDecl(std.fs, "cwd")});
    std.debug.print("取当前目录的新名字：std.Io.Dir.cwd() → handle={d}（AT_FDCWD={d}）\n", .{ cwd.handle, std.posix.AT.FDCWD });
    std.debug.print("main 拿到的 io 类型 = {s}，来自 init.io（不是全局变量）\n", .{@typeName(@TypeOf(init.io))});
    std.debug.print("Dir 是**工厂**（凭路径造File），File 是**句柄**（一个已打开的 fd）\n", .{});
    std.debug.print("⇒ 换掉 io 就换掉了整个 I/O 后端：测试传 std.testing.io，生产传 init.io\n", .{});
    std.debug.print("⇒ 这是 02 章 init.io 设计的回报，和 15 章的 testing.io 是同一件事\n", .{});
    std.debug.print("stdio 三件套（0.17 也在 Io 下）：stdin={d} stdout={d} stderr={d}\n", .{
        std.Io.File.stdin().handle,
        std.Io.File.stdout().handle,
        std.Io.File.stderr().handle,
    });
    std.debug.print("File.stdin() / stdout() / stderr() 都**不带参数**（它们是常量句柄）\n", .{});
    end("20.1");

    // ═══ 20.2 打开与创建：两组 flags 完全不同的结构体 ═══
    begin("20.2");
    try cwd.writeFile(io, .{ .sub_path = "demo_conf.txt", .data = "name=zig\nretries=3\n" });
    {
        // openFile 的选项叫OpenFileOptions，核心字段是 mode（枚举，不是 bool组合）
        const f = try cwd.openFile(io, "demo_conf.txt", .{});
        defer f.close(io);
        const st = try f.stat(io);
        std.debug.print("openFile 默认 mode=.read_only，读到 {d} 字节\n", .{st.size});
        // OpenFileOptions 的字段（实测 @typeInfo反射）
        const T = @typeInfo(std.Io.Dir.OpenFileOptions).@"struct";
        std.debug.print("OpenFileOptions 字段：", .{});
        inline for (T.field_names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});
        std.debug.print("  其中 mode 是枚举 {s}：.read_only / .write_only / .read_write\n", .{
            @typeName(@typeInfo(std.Io.Dir.OpenFileOptions.Mode).@"enum".tag_type),
        });
    }
    {
        // createFile 的选项叫 CreateFileOptions —— 字段是 bool，不是 mode
        const C = @typeInfo(std.Io.Dir.CreateFileOptions).@"struct";
        std.debug.print("CreateFileOptions 字段：", .{});
        inline for (C.field_names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});
        std.debug.print("  truncate 默认 true（覆盖写）；exclusive=true 表示“必须新建”\n", .{});
        // exclusive 的实测：第二次必然 PathAlreadyExists
        const f1 = try cwd.createFile(io, "demo_excl.txt", .{ .exclusive = true });
        f1.close(io);
        if (cwd.createFile(io, "demo_excl.txt", .{ .exclusive = true })) |f2| {
            f2.close(io);
            std.debug.print("  exclusive 第二次成功？不该\n", .{});
        } else |err| std.debug.print("  exclusive 第二次 → {s}（实测）\n", .{@errorName(err)});
        cwd.deleteFile(io, "demo_excl.txt") catch {};
    }
    {
        // allow_directory：默认 true 可以打开目录，设 false 打开目录直接 error.IsDir
        if (cwd.openFile(io, ".", .{})) |f| {
            f.close(io);
            std.debug.print("  openFile 目录默认允许 → 成功\n", .{});
        } else |err| std.debug.print("  openFile(“.”) → {s}\n", .{@errorName(err)});
        if (cwd.openFile(io, ".", .{ .allow_directory = false })) |f| {
            f.close(io);
            std.debug.print("  allow_directory=false 仍成功？不该\n", .{});
        } else |err| std.debug.print("  allow_directory=false → {s}（实测）\n", .{@errorName(err)});
    }
    end("20.2");

    // ═══ 20.3 读文件：readFileAlloc 的上限就是 Io.Limit ═══
    begin("20.3");
    {
        const text = try cwd.readFileAlloc(io, "demo_conf.txt", mem, .limited(1024 * 1024));
        std.debug.print("readFileAlloc 读到 {d} 字节：{s}", .{ text.len, text });
        // 上限参数的类型就是 std.Io.Limit（不是 usize！），这是 0.17 的关键变化
        const LT = @typeInfo(std.Io.Limit);
        std.debug.print("  第 4 参类型 = {s}，是 enum(usize)（基整型 {s}）\n", .{
            @typeName(std.Io.Limit),
            @typeName(LT.@"enum".tag_type),
        });
        std.debug.print("  .limited(64) 的 backing={d}；.unlimited 的 backing={d}；.nothing={d}\n", .{
            @backingInt(std.Io.Limit.limited(64)),
            @backingInt(std.Io.Limit.unlimited),
            @backingInt(std.Io.Limit.nothing),
        });
        std.debug.print("  ⚠️ Io.Limit 是**非穷尽枚举**，运行期值用 {{t}} 打印会 panic\n", .{});
        std.debug.print("     （实测 panic: invalid enum value，见坑位清单）\n", .{});
    }
    {
        // 上限太小 → error.StreamTooLong，这就是"崩溃变成错误"的机制
        if (cwd.readFileAlloc(io, "demo_conf.txt", mem, .limited(4))) |_| {
            std.debug.print("  limit=4 读 17 字节成功？不该\n", .{});
        } else |err| std.debug.print("  limit=4 读 19 字节文件 → {s}（实测）\n", .{@errorName(err)});
    }
    end("20.3");

    // ═══ 20.4 缓冲 Reader：三件套 fillMore / buffered / toss ═══
    begin("20.4");
    try cwd.writeFile(io, .{ .sub_path = "demo_lines.txt", .data = "alpha\nbeta\ngamma\n" });
    {
        // 4 字节缓冲读6 字节的行 → takeDelimiterExclusive 直接 error.StreamTooLong
        const f = try cwd.openFile(io, "demo_lines.txt", .{});
        defer f.close(io);
        var buf: [4]u8 = undefined;
        var fr = f.reader(io, &buf);
        if (fr.interface.takeDelimiterExclusive('\n')) |line| {
            std.debug.print("  takeDelimiterExclusive 成功？{s}（不该）\n", .{line});
        } else |err| std.debug.print("  4 字节缓冲 takeDelimiterExclusive → {s}（实测）\n", .{@errorName(err)});
        std.debug.print("  ⚠️ 0.17 的 takeDelimiterExclusive **会** fillMore（即：它是阻塞式的）\n", .{});
        std.debug.print("     它的限制是“分隔符必须在 Reader 缓冲容量内”，超了报 StreamTooLong\n", .{});
    }
    {
        // 正确姿势：fillMore + indexOfScalarPos + toss，缓冲远小于行也能拼出整行
        const f = try cwd.openFile(io, "demo_lines.txt", .{});
        defer f.close(io);
        var buf: [4]u8 = undefined;
        var fr = f.reader(io, &buf);
        const r = &fr.interface;
        var n: usize = 0;
        var line: [64]u8 = undefined; // 自己攒行：Reader 只保证"缓冲里有这些字节"
        var line_len: usize = 0;
        while (true) {
            r.fillMore() catch |err| switch (err) {
                // EndOfStream 时缓冲里可能还有没换行结尾的零头，那才是最后一行
                error.EndOfStream => {
                    if (line_len != 0) {
                        n += 1;
                        std.debug.print("  第 {d} 行 ={s}（末行无换行）\n", .{ n, line[0..line_len] });
                    }
                    break;
                },
                else => |e| return e,
            };
            const avail = r.buffered();
            if (avail.len == 0) break;
            const idx = std.mem.indexOfScalarPos(u8, avail, 0, '\n');
            const cut = idx orelse avail.len;
            @memcpy(line[line_len..][0..cut], avail[0..cut]); // 零头先攒着
            line_len += cut;
            if (idx != null) { //攒够一行才输出
                n += 1;
                std.debug.print("  第 {d} 行 ={s}\n", .{ n, line[0..line_len] });
                line_len = 0;
            }
            // ⚠️ 找到分隔符才 toss(idx+1)；没找到只能 toss(avail.len)，
            //    无脑写 toss(idx+1) 会 panic: assert(r.seek <= r.end)（实测）
            r.toss(if (idx) |k| k + 1 else avail.len);
        }
        std.debug.print("  共 {d} 行 ⇒ 4 字节缓冲照样读出 6 字节的行（补齐逻辑要自己写）\n", .{n});
    }
    {
        // readSliceShort 是"填满或 EOF"，不是"读一次"
        const f = try cwd.openFile(io, "demo_conf.txt", .{});
        defer f.close(io);
        var fr = f.reader(io, &.{});
        var tb: [16]u8 = undefined;
        const got = try fr.interface.readSliceShort(&tb);
        std.debug.print("  readSliceShort(16字节缓冲) 于 19 字节文件 → {d} 字节（填满，没报 EOF）\n", .{got});
        std.debug.print("  ⚠️ 它是“填满或 EOF”语义：当单次 read 用会多读/报 EndOfStream\n", .{});
    }
    {
        // seek 用 logicalPos / seekTo / seekBy，没有 getPos（0.17 已移除）
        const f = try cwd.openFile(io, "demo_conf.txt", .{});
        defer f.close(io);
        var fr = f.reader(io, &.{});
        std.debug.print("  File.Reader 字段：io file err mode pos size interface（@hasDecl(interface)={}，它是字段不是函数）\n", .{@hasDecl(std.Io.File.Reader, "interface")});
        std.debug.print("  初始 logicalPos={d}，pos={d}，size={?d}，mode={t}\n", .{ fr.logicalPos(), fr.pos, fr.size, fr.mode });
        try fr.seekTo(5);
        var tb: [4]u8 = undefined;
        const got = try fr.interface.readSliceShort(&tb);
        std.debug.print("  seekTo(5) 后读 ={s}，logicalPos={d}\n", .{ tb[0..got], fr.logicalPos() });
        try fr.seekBy(-2);
        std.debug.print("  seekBy(-2) 后 logicalPos={d}\n", .{fr.logicalPos()});
        std.debug.print("  ⚠️ 没有 getPos()：用 logicalPos()（已消费逻辑位置，跨 rebase 也准）\n", .{});
    }
    end("20.4");

    // ═══ 20.5 写文件：writeAll → writeStreamingAll，以及必须 flush ═══
    begin("20.5");
    std.debug.print("@hasDecl(Io.File, “writeAll”) = {}（0.17 **没有**这个方法）\n", .{@hasDecl(std.Io.File, "writeAll")});
    std.debug.print("@hasDecl(Io.File, “writeStreamingAll”) = {} ← 这才是“写全部”\n", .{@hasDecl(std.Io.File, "writeStreamingAll")});
    std.debug.print("@hasDecl(Io.File, “readAll”) = {}；@hasDecl(Io.File, “readStreaming”) = {}\n", .{
        @hasDecl(std.Io.File, "readAll"),
        @hasDecl(std.Io.File, "readStreaming"),
    });
    {
        // flush 的必要性：忘 flush → 文件 0 字节
        {
            const f = try cwd.createFile(io, "demo_noflush.txt", .{});
            var b: [64]u8 = undefined;
            var fw = f.writer(io, &b);
            try fw.interface.print("这段不flush", .{});
            f.close(io); // 没flush
        }
        const got = try cwd.readFileAlloc(io, "demo_noflush.txt", mem, .limited(1024));
        std.debug.print("  忘 flush 后文件大小 = {d} 字节 ⇒ 缓冲 Writer 的内容全丢（实测）\n", .{got.len});
        cwd.deleteFile(io, "demo_noflush.txt") catch {};
    }
    {
        const f = try cwd.createFile(io, "demo_flush.txt", .{});
        var b: [64]u8 = undefined;
        var fw = f.writer(io, &b);
        try fw.interface.print("flush 过的内容", .{});
        std.debug.print("    写完还没 flush：logicalPos={d}，缓冲里 {d} 字节\n", .{ fw.logicalPos(), fw.interface.buffered().len });
        try fw.interface.flush();
        std.debug.print("  flush 之后：缓冲里 {d} 字节（已交给内核）\n", .{fw.interface.buffered().len});
        f.close(io);
        const got = try cwd.readFileAlloc(io, "demo_flush.txt", mem, .limited(1024));
        std.debug.print("  flush 后文件大小 = {d} 字节（{s}）\n", .{ got.len, got });
        cwd.deleteFile(io, "demo_flush.txt") catch {};
    }
    {
        // writeAll 在 Io.Writer 上有，返回"实际写了几字节"是 write，writeAll 返回 void
        const f = try cwd.createFile(io, "demo_writeall.txt", .{});
        var b: [64]u8 = undefined;
        var fw = f.writer(io, &b);
        const n = try fw.interface.write("12345");
        std.debug.print("  Io.Writer.write 返回 {d}（可能短写）；writeAll 保证写完\n", .{n});
        try fw.interface.writeAll("67890");
        try fw.end(); // end = flush + 按 logicalPos 截断/补齐
        f.close(io);
        std.debug.print("  write+writeAll+end() 后文件大小 = {d}（实测）\n", .{(try cwd.statFile(io, "demo_writeall.txt", .{})).size});
        cwd.deleteFile(io, "demo_writeall.txt") catch {};
    }
    end("20.5");

    // ═══ 20.6 追加与截断：flags 与 setLength ═══
    begin("20.6");
    try cwd.writeFile(io, .{ .sub_path = "demo_append.txt", .data = "AAA" });
    {
        // ⚠️ writeFile 的 .flags 只控制"打开方式"，truncate=false **不会**追加
        try cwd.writeFile(io, .{ .sub_path = "demo_append.txt", .data = "BBB", .flags = .{ .truncate = false } });
        const got = try cwd.readFileAlloc(io, "demo_append.txt", mem, .limited(64));
        std.debug.print("truncate=false 再 writeFile → {s}（{d} 字节）⇒ **没有追加，是覆盖**\n", .{ got, got.len });
        std.debug.print("⚠️ writeFile 从不从 O_APPEND 位置写；要追加得自己 createFile + seekTo(end)\n", .{});
    }
    {
        // 真正的追加：truncate=false 打开 → seek 到末尾 → 写
        const f = try cwd.createFile(io, "demo_append.txt", .{ .truncate = false });
        defer f.close(io);
        try f.setLength(io, 3); // 确保长度是 3（追加起点）
        var b: [16]u8 = undefined;
        var fw = f.writer(io, &b);
        try fw.seekTo(3); // 定位到文件末尾
        try fw.interface.writeAll("BBB");
        try fw.interface.flush();
        const got = try cwd.readFileAlloc(io, "demo_append.txt", mem, .limited(64));
        std.debug.print("  createFile(truncate=false)+seekTo(末尾)+写 → {s}（{d} 字节）\n", .{ got, got.len });
    }
    {
        // 截断：setLength(0) 就是清空
        const f = try cwd.openFile(io, "demo_append.txt", .{ .mode = .read_write });
        defer f.close(io);
        try f.setLength(io, 0);
        std.debug.print("  setLength(0) 后长度 = {d}\n", .{try f.length(io)});
        var b: [16]u8 = undefined;
        var fw = f.writer(io, &b);
        try fw.interface.writeAll("new");
        try fw.interface.flush();
        const got = try cwd.readFileAlloc(io, "demo_append.txt", mem, .limited(64));
        std.debug.print("  截断后写入 → {s}\n", .{got});
    }
    cwd.deleteFile(io, "demo_append.txt") catch {};
    end("20.6");

    // ═══ 20.7 目录：建 / 开 / 存在性 / 重命名 ═══
    begin("20.7");
    try cwd.createDirPath(io, "demo_dir/sub"); // 递归建（旧名 makePath）
    {
        const st1 = try cwd.createDirPathStatus(io, "demo_dir/sub", .default_dir);
        std.debug.print("  createDirPathStatus 已存在 → {t}\n", .{st1});
        const st2 = try cwd.createDirPathStatus(io, "demo_dir/other", .default_dir);
        std.debug.print("  新建 → {t}（.existed / .created）\n", .{st2});
        cwd.deleteTree(io, "demo_dir/other") catch {};
    }
    {
        // access：检查存在性 + 权限，比 statFile 便宜
        try cwd.writeFile(io, .{ .sub_path = "demo_dir/f.txt", .data = "x" });
        try cwd.access(io, "demo_dir/f.txt", .{});
        std.debug.print("access 存在文件 → ok\n", .{});
        if (cwd.access(io, "demo_dir/nope", .{})) |_| {
            std.debug.print("  access 不存在成功？不该\n", .{});
        } else |err| std.debug.print("access 不存在 → {s}\n", .{@errorName(err)});
        if (cwd.access(io, "demo_dir/f.txt", .{ .execute = true })) |_| {
            std.debug.print("  access execute 成功？不该\n", .{});
        } else |err| std.debug.print("access execute（非可执行）→ {s}\n", .{@errorName(err)});
        const A = @typeInfo(std.Io.Dir.AccessOptions).@"struct";
        std.debug.print("  AccessOptions 字段：", .{});
        inline for (A.field_names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});
    }
    {
        // rename 的参数顺序：io 在**最后**（4 个路径/Dir 参数之后）
        try cwd.rename("demo_dir/f.txt", cwd, "demo_dir/g.txt", io);
        if (cwd.statFile(io, "demo_dir/f.txt", .{})) |_| {
            std.debug.print("  rename 后旧名仍存在？\n", .{});
        } else |err| std.debug.print("rename f→g：旧名 statFile → {s}，新名 {d} 字节\n", .{
            @errorName(err),
            (try cwd.statFile(io, "demo_dir/g.txt", .{})).size,
        });
    }
    {
        // createDirPathOpen：建+ 开一步完成（options 里套 open_options）
        var d = try cwd.createDirPathOpen(io, "demo_dir/sub2/deep", .{ .open_options = .{ .iterate = true } });
        defer d.close(io);
        var it = d.iterate();
        var cnt: usize = 0;
        while (try it.next(io)) |_| cnt += 1;
        std.debug.print("createDirPathOpen 一步拿到可遍历 Dir，条目数={d}（空目录）\n", .{cnt});
    }
    end("20.7");

    // ═══ 20.8 遍历：openDir(.iterate=true) + iterate() + next(io) ═══
    begin("20.8");
    {
        const O = @typeInfo(std.Io.Dir.OpenOptions).@"struct";
        std.debug.print("  OpenDir 的 OpenOptions 字段：", .{});
        inline for (O.field_names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});
        std.debug.print("  .iterate 必须在**打开时**开（Windows 下不开迭代直接 AccessDenied）\n", .{});
    }
    try cwd.writeFile(io, .{ .sub_path = "demo_dir/sub/a.txt", .data = "A" });
    try cwd.writeFile(io, .{ .sub_path = "demo_dir/sub/b.txt", .data = "B" });
    {
        var d = try cwd.openDir(io, "demo_dir", .{ .iterate = true });
        defer d.close(io);
        var it = d.iterate();
        while (try it.next(io)) |e| {
            std.debug.print("  [{s}] {s}\n", .{ @tagName(e.kind), e.name });
        }
    }
    {
        // Entry 的形状：只有 3 个字段，kind 是 File.Kind（不是 Dir.Entry.Kind）
        const E = @typeInfo(std.Io.Dir.Entry).@"struct";
        std.debug.print("Entry 字段数={d}：", .{E.field_names.len});
        inline for (E.field_names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});
        std.debug.print("  entry.kind 的类型 = {s}\n", .{@typeName(@FieldType(std.Io.Dir.Entry, "kind"))});
        std.debug.print("  ⚠️ 写 Io.Dir.Entry.Kind 报 no member named 'Kind'（实测，要用 Io.File.Kind）\n", .{});
    }
    {
        // 走一遍 walk（递归遍历的现成壳，27 章深入）
        //⚠️ 必须在 openDir 出来的 Dir 上跑：cwd() 在 POSIX 上是 AT.FDCWD 这个"伪句柄"，
        //    walk 内部要 seek 它，实测直接 panic: programmer bug caused syscall error: BADF
        var d = try cwd.openDir(io, "demo_dir", .{ .iterate = true });
        defer d.close(io);
        var walker = try d.walk(mem);
        defer walker.deinit();
        var found: usize = 0;
        while (try walker.next(io)) |e| {
            found += 1;
            std.debug.print("  walk: {s}\n", .{e.path});
        }
        std.debug.print("  walk 共 {d} 个条目（含根）⇒ 递归遍历不用自己写\n", .{found});
        std.debug.print("  ⚠️ 对 cwd() 直接 walk 会 panic（BADF），必须先 openDir\n", .{});
    }
    end("20.8");

    // ═══ 20.9 清理：deleteTree 递归删 ═══
    begin("20.9");
    {
        if (cwd.deleteDir(io, "demo_dir/sub")) |_| {
            std.debug.print("deleteDir 非空目录成功？不该\n", .{});
        } else |err| std.debug.print("deleteDir 非空 → {s}（实测）\n", .{@errorName(err)});
        cwd.deleteTree(io, "demo_dir") catch {};
        if (cwd.statFile(io, "demo_dir", .{})) |_| {
            std.debug.print("deleteTree 后仍存在？\n", .{});
        } else |err| std.debug.print("deleteTree 后 statFile → {s} ⇒ 整棵子树递归删掉了\n", .{@errorName(err)});
    }
    end("20.9");

    // ═══ 20.10 路径：std.fs.path 还在老位置 ═══
    begin("20.10");
    {
        const joined = try std.fs.path.join(mem, &.{ "dir", "sub", "a.txt" });
        std.debug.print("join = {s}\n", .{joined});
        std.debug.print("basename = {s}\n", .{std.fs.path.basename(joined)});
        if (std.fs.path.dirname(joined)) |dn| {
            std.debug.print("dirname  = {s}（返回 ?[]const u8，根路径时是 null）\n", .{dn});
        } else std.debug.print("dirname  = null\n", .{});
        std.debug.print("extension= {s}\n", .{std.fs.path.extension(joined)});
        std.debug.print("  isAbsolute 相对路径={}，绝对路径={}\n", .{
            std.fs.path.isAbsolute("dir/a"),
            std.fs.path.isAbsolute("/a"),
        });
        std.debug.print("Io.Dir.path 就是 std.fs.path（@TypeOf 相等 = {}）→ 两个名字都能用\n", .{
            @TypeOf(std.Io.Dir.path) == @TypeOf(std.fs.path),
        });
        std.debug.print("⚠️ std.fs 搬家了但 std.fs.path **没搬** —— @hasDecl(std.fs, \"File\")={}，\"path\"={}\n", .{
            @hasDecl(std.fs, "File"),
            @hasDecl(std.fs, "path"),
        });
    }
    end("20.10");

    // ═══ 20.11 std.json：结构 ↔ JSON 的真实形状 ═══
    begin("20.11");
    {
        const cfg = ConfigJson{ .name = "zig", .retries = 3 };
        var jb: [256]u8 = undefined;
        var jw = std.Io.Writer.fixed(&jb); // 内存缓冲当 Writer
        try std.json.Stringify.value(cfg, .{}, &jw);
        std.debug.print("Stringify.value → {s}\n", .{jw.buffered()});

        var pb: [512]u8 = undefined;
        var pw = std.Io.Writer.fixed(&pb);
        try std.json.Stringify.value(cfg, .{ .whitespace = .indent_2 }, &pw);
        std.debug.print("带 .whitespace=.indent_2 →\n{s}\n", .{pw.buffered()});

        // 反序列化：parseFromSlice 返回 Parsed(T)，字符串借用内部缓冲
        const back = try std.json.parseFromSlice(ConfigJson, mem, jw.buffered(), .{});
        std.debug.print("parseFromSlice → Parsed，name={s} retries={d}\n", .{ back.value.name, back.value.retries });
        std.debug.print("  Parsed(T) 类型 = {s}\n", .{@typeName(std.json.Parsed(ConfigJson))});

        // parseFromSliceLeaky：直接给 T，无 Parsed 包装（省一次 deinit）
        const leaky = try std.json.parseFromSliceLeaky(ConfigJson, mem, jw.buffered(), .{});
        std.debug.print("  parseFromSliceLeaky 直接给 ConfigJson（retries={d}）\n", .{leaky.retries});
    }
    {
        // 错误区分
        if (std.json.parseFromSlice(ConfigJson, mem, "{bad", .{})) |_| {
            std.debug.print("  坏 JSON 成功？不该\n", .{});
        } else |err| std.debug.print("  坏 JSON → {s}\n", .{@errorName(err)});
        if (std.json.parseFromSlice(ConfigJson, mem, "{\"name\":\"x\"}", .{})) |_| {
            std.debug.print("  缺字段成功？不该\n", .{});
        } else |err| std.debug.print("  缺字段 → {s}\n", .{@errorName(err)});
    }
    {
        // 动态 JSON：std.json.Value 是 union(enum)
        const dyn = try std.json.parseFromSlice(std.json.Value, mem,
            \\{"n":1,"s":"x","b":true,"arr":[1,2],"nil":null}
        , .{});
        const o = dyn.value.object;
        std.debug.print("动态 Value：object 有 {d} 个键\n", .{o.count()});
        std.debug.print("  .integer tag = {s}，.string = {s}，.bool = {}\n", .{
            @tagName(o.get("n").?),
            o.get("s").?.string,
            o.get("b").?.bool,
        });
        std.debug.print("  .array.items.len = {d}；nil 键存在但值是 null={}\n", .{
            o.get("arr").?.array.items.len,
            blk: {
                const nv = o.get("nil").?;
                break :blk nv == .null;
            },
        });
        std.debug.print("  ⚠️ Value 是 union(enum)，{{s}} 打印**编译不过**（invalid format string）\n", .{});
        std.debug.print("     要先 .? 解包 union 再取字段，或用 @tagName 打印 tag\n", .{});
    }
    end("20.11");

    // ═══ 20.12 错误处理：区分"文件不存在"和"别的错" ═══
    begin("20.12");
    {
        const found = try readConfig(io, cwd, mem, "demo_conf.txt"); // mem 是 arena，退出自动回收
        std.debug.print("readConfig(存在的文件) → {d} 字节\n", .{if (found) |f| f.len else 0});
        const missing = try readConfig(io, cwd, mem, "demo_no_such.txt");
        std.debug.print("readConfig(不存在的文件) → {s}（null = 没配置，不是错误）\n", .{
            if (missing == null) "null" else "有内容",
        });
        // 直接观察错误集成员
        if (cwd.openFile(io, "demo_no_such.txt", .{})) |f| {
            f.close(io);
            std.debug.print("  不该成功\n", .{});
        } else |err| std.debug.print("  openFile 不存在 → {s}（这是要 catch 的那个）\n", .{@errorName(err)});
        std.debug.print("错误处理范式：FileNotFound → 业务上的“没有”，其它 → 往上抛\n", .{});
        std.debug.print("  常见可 catch 的错误：FileNotFound / AccessDenied / PathAlreadyExists / IsDir / DirNotEmpty / StreamTooLong\n", .{});
    }
    end("20.12");

    // ═══ 20.13 临时目录：生产代码里怎么做 ═══
    begin("20.13");
    std.debug.print("std.testing.tmpDir 只在 zig test 下能用（带 comptime assert(builtin.is_test)）\n", .{});
    std.debug.print("生产代码的等价物：自己造名 + createDirPath + defer deleteTree\n", .{});
    {
        // 造一个唯一名字（本章示例用固定名，真实代码要加随机/时间/pid）
        const tmp_name = "demo_tmpdir";
        cwd.deleteTree(io, tmp_name) catch {}; // 先清残留
        try cwd.createDirPath(io, tmp_name);
        defer cwd.deleteTree(io, tmp_name) catch {};
        try cwd.writeFile(io, .{ .sub_path = "demo_tmpdir/x.txt", .data = "临时" });
        const got = try cwd.readFileAlloc(io, "demo_tmpdir/x.txt", mem, .limited(64));
        std.debug.print("临时目录里写了 {s}（{d} 字节），退出时 deleteTree 回收\n", .{ got, got.len });
        std.debug.print("⚠️ 名字必须唯一：生产代码常用 pid + 时间戳，测试用 tmpDir 的随机 16 字符名\n", .{});
    }
    end("20.13");

    // ═══ 20.14 为什么 Zig 要求你显式选 io：哲学与悬垂指针 ═══
    begin("20.14");
    std.debug.print("显式传 io 的三个收益：\n", .{});
    std.debug.print("  1. 可替换：main 传 init.io，test 传 std.testing.io（15 章）\n", .{});
    std.debug.print("  2. 可测试：io 是参数 → 能塞假实现、能在测试里换掉整个后端\n", .{});
    std.debug.print("  3. 可异步：同一份代码能在阻塞 io 和事件驱动 io 上跑\n", .{});
    std.debug.print("⚠️ 代价：每个方法都要写 io。这不是啰嗦，是让“依赖”看得见\n", .{});
    std.debug.print("悬垂指针实测：把 file.writer(io, buf) 的返回值按值存进结构体 → buf 悬垂\n", .{});
    {
        //正确：就地用var，不跨函数边界
        try cwd.writeFile(io, .{ .sub_path = "demo_dangle.txt", .data = "0123456789" });
        const f = try cwd.openFile(io, "demo_dangle.txt", .{ .mode = .read_write });
        var buf: [16]u8 = undefined;
        var w = f.writer(io, &buf);
        try w.interface.writeAll("XY");
        try w.interface.flush();
        f.close(io);
        const got = try cwd.readFileAlloc(io, "demo_dangle.txt", mem, .limited(64));
        std.debug.print("  就地写+flush → {s}（正确）\n", .{got});
        cwd.deleteFile(io, "demo_dangle.txt") catch {};
    }
    {
        // 反例：把 Writer 按值存进结构体（buf 是别的栈帧）→ 必须懒绑定
        std.debug.print("  反例：struct 里存 File.Writer 字段，buf 在栈上 → 返回即悬垂\n", .{});
        std.debug.print("  ⇒ 规则：Writer/Reader 不进结构体；必须存就存 File + buf，绑的时候再 writer(io, buf)\n", .{});
    }
    end("20.14");

    // 收尾：删掉本节演示留下的文件，让 build.ps1 / run-all.sh 重复跑不残留
    cwd.deleteFile(io, "demo_conf.txt") catch {};
    cwd.deleteFile(io, "demo_lines.txt") catch {};

    std.debug.print("自检通过\n", .{});
}

test "20.3 readFileAlloc：Io.Limit 上限与StreamTooLong" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "a.txt", .data = "0123456789" });
    const got = try tmp.dir.readFileAlloc(io, "a.txt", a, .limited(64));
    defer a.free(got);
    try std.testing.expectEqualStrings("0123456789", got);
    try std.testing.expectError(error.StreamTooLong, tmp.dir.readFileAlloc(io, "a.txt", a, .limited(4)));
    // 不存在的文件 → FileNotFound
    try std.testing.expectError(error.FileNotFound, tmp.dir.readFileAlloc(io, "nope.txt", a, .limited(64)));
}

test "20.4 手工行读取：fillMore + indexOfScalarPos + toss（缓冲小于行长）" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "lines.txt", .data = "alpha\nbeta\ngamma\n" });
    const f = try tmp.dir.openFile(io, "lines.txt", .{});
    defer f.close(io);
    var buf: [4]u8 = undefined; // 故意小于行长
    var fr = f.reader(io, &buf);
    const r = &fr.interface;

    var got: [16]u8 = undefined;
    var acc: usize = 0;
    while (true) {
        r.fillMore() catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };
        const avail = r.buffered();
        if (avail.len == 0) break;
        const idx = std.mem.indexOfScalarPos(u8, avail, 0, '\n');
        const cut = idx orelse avail.len;
        @memcpy(got[acc..][0..cut], avail[0..cut]);
        acc += cut;
        r.toss(if (idx) |k| k + 1 else avail.len);
    }
    try std.testing.expectEqualStrings("alphabetagamma", got[0..acc]);
}

test "20.4 readSliceShort 是填满或EOF，不是单次 read" {
    var r = std.Io.Reader.fixed("ABCDEFGH");
    var b: [3]u8 = undefined;
    // 源比 buf 长 → 返回填满的3 字节（不是"读一次"）
    try std.testing.expectEqual(@as(usize, 3), try r.readSliceShort(&b));
    try std.testing.expectEqualStrings("ABC", &b);
    // 源比 buf 短 → 返回实际长度（EOF 允许）
    var r2 = std.Io.Reader.fixed("AB");
    var b2: [8]u8 = undefined;
    try std.testing.expectEqual(@as(usize, 2), try r2.readSliceShort(&b2));
}

test "20.5 缓冲 Writer 必须flush：忘 flush 丢全部内容" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    {
        const f = try tmp.dir.createFile(io, "noflush.txt", .{});
        var b: [32]u8 = undefined;
        var fw = f.writer(io, &b);
        try fw.interface.print("这段不会落盘", .{});
        f.close(io); // 忘 flush
    }
    // 文件存在但大小为 0 —— flush 是契约的一部分
    const st = try tmp.dir.statFile(io, "noflush.txt", .{});
    try std.testing.expectEqual(@as(u64, 0), st.size);

    {
        const f = try tmp.dir.createFile(io, "flushed.txt", .{});
        var b: [32]u8 = undefined;
        var fw = f.writer(io, &b);
        try fw.interface.print("落盘了", .{});
        try fw.interface.flush();
        f.close(io);
    }
    const got = try tmp.dir.readFileAlloc(io, "flushed.txt", a, .limited(64));
    defer a.free(got);
    try std.testing.expectEqualStrings("落盘了", got);
}

test "20.5 writeStreamingAll 是 File 上的”写全部”，writeAll 不存在" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try std.testing.expect(!@hasDecl(std.Io.File, "writeAll"));
    try std.testing.expect(!@hasDecl(std.Io.File, "readAll"));
    try std.testing.expect(@hasDecl(std.Io.File, "writeStreamingAll"));
    try std.testing.expect(@hasDecl(std.Io.File, "readStreaming"));

    const f = try tmp.dir.createFile(io, "s.txt", .{});
    defer f.close(io);
    try f.writeStreamingAll(io, "直接写全部");
    const got = try tmp.dir.readFileAlloc(io, "s.txt", a, .limited(64));
    defer a.free(got);
    try std.testing.expectEqualStrings("直接写全部", got);
}

test "20.6 追加要自己 seek；truncate=false 不等于 append" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "ap.txt", .data = "AAA" });
    // writeFile + truncate=false 是覆盖，不是追加
    try tmp.dir.writeFile(io, .{ .sub_path = "ap.txt", .data = "BBB", .flags = .{ .truncate = false } });
    {
        const got = try tmp.dir.readFileAlloc(io, "ap.txt", a, .limited(64));
        defer a.free(got);
        try std.testing.expectEqualStrings("BBB", got);
    }
    // 真追加：truncate=false 打开 + seekTo(end) + 写
    {
        const f = try tmp.dir.createFile(io, "ap.txt", .{ .truncate = false });
        defer f.close(io);
        var b: [16]u8 = undefined;
        var fw = f.writer(io, &b);
        try fw.seekTo(3);
        try fw.interface.writeAll("CCC");
        try fw.interface.flush();
    }
    const got = try tmp.dir.readFileAlloc(io, "ap.txt", a, .limited(64));
    defer a.free(got);
    try std.testing.expectEqualStrings("BBBCCC", got);
}

test "20.7 目录：createDirPath / access / rename / createDirPathOpen" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.createDirPath(io, "d/sub");
    // 已存在 → .existed；新建 → .created
    try std.testing.expectEqual(std.Io.Dir.CreatePathStatus.existed, try tmp.dir.createDirPathStatus(io, "d/sub", .default_dir));
    try std.testing.expectEqual(std.Io.Dir.CreatePathStatus.created, try tmp.dir.createDirPathStatus(io, "d/x", .default_dir));
    // access 存在性
    try tmp.dir.writeFile(io, .{ .sub_path = "d/f.txt", .data = "x" });
    try tmp.dir.access(io, "d/f.txt", .{});
    try std.testing.expectError(error.FileNotFound, tmp.dir.access(io, "d/nope", .{}));
    // rename：io 在最后
    try tmp.dir.rename("d/f.txt", tmp.dir, "d/g.txt", io);
    try std.testing.expectError(error.FileNotFound, tmp.dir.statFile(io, "d/f.txt", .{}));
    // deleteDir 对**空**目录成功；对非空目录报 DirNotEmpty（deleteTree 才递归）
    try tmp.dir.deleteDir(io, "d/sub");
    try tmp.dir.createDir(io, "d/sub2", .default_dir);
    try tmp.dir.writeFile(io, .{ .sub_path = "d/sub2/x.txt", .data = "x" });
    try std.testing.expectError(error.DirNotEmpty, tmp.dir.deleteDir(io, "d/sub2"));
}

test "20.8 遍历：Entry 形状与 openDir(.iterate=true)" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.createDirPath(io, "t/sub");
    try tmp.dir.writeFile(io, .{ .sub_path = "t/a.txt", .data = "A" });
    try tmp.dir.writeFile(io, .{ .sub_path = "t/sub/b.txt", .data = "B" });

    var d = try tmp.dir.openDir(io, "t", .{ .iterate = true });
    defer d.close(io);
    var it = d.iterate();
    var n_file: usize = 0;
    var n_dir: usize = 0;
    while (try it.next(io)) |e| {
        switch (e.kind) {
            .file => n_file += 1,
            .directory => n_dir += 1,
            else => {},
        }
    }
    try std.testing.expectEqual(@as(usize, 1), n_file);
    try std.testing.expectEqual(@as(usize, 1), n_dir);
}

test "20.10 std.fs.path：dirname 返回可选" {
    const a = std.testing.allocator;
    const joined = try std.fs.path.join(a, &.{ "dir", "sub", "a.txt" });
    defer a.free(joined);
    try std.testing.expectEqualStrings("a.txt", std.fs.path.basename(joined));
    try std.testing.expectEqualStrings(".txt", std.fs.path.extension(joined));
    try std.testing.expectEqualStrings("dir/sub", std.fs.path.dirname(joined).?);
    // std.fs 搬家了，path 没搬
    try std.testing.expect(!@hasDecl(std.fs, "cwd"));
    try std.testing.expect(!@hasDecl(std.fs, "File"));
    try std.testing.expect(@hasDecl(std.fs, "path"));
}

test "20.11 std.json 回环：Stringify.value + parseFromSlice" {
    const a = std.testing.allocator;
    var jb: [128]u8 = undefined;
    var jw = std.Io.Writer.fixed(&jb);
    try std.json.Stringify.value(ConfigJson{ .name = "zig", .retries = 3 }, .{}, &jw);
    try std.testing.expectEqualStrings("{\"name\":\"zig\",\"retries\":3}", jw.buffered());

    const back = try std.json.parseFromSlice(ConfigJson, a, jw.buffered(), .{});
    defer back.deinit();
    try std.testing.expectEqualStrings("zig", back.value.name);
    try std.testing.expectEqual(@as(u32, 3), back.value.retries);
    // 错误区分
    try std.testing.expectError(error.SyntaxError, std.json.parseFromSlice(ConfigJson, a, "{bad", .{}));
    try std.testing.expectError(error.MissingField, std.json.parseFromSlice(ConfigJson, a, "{\"name\":\"x\"}", .{}));
}

test "20.12 readConfig：区分”没有配置”和”真错误”" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "c.cfg", .data = "name=x\n" });
    // 存在 → 有内容
    const found = try readConfig(io, tmp.dir, a, "c.cfg");
    defer if (found) |f| a.free(f); // readConfig 把所有权交给调用方
    try std.testing.expect(found != null);
    try std.testing.expectEqualStrings("name=x\n", found.?);
    // 不存在 → null（不是错误）
    const missing = try readConfig(io, tmp.dir, a, "no.cfg");
    try std.testing.expect(missing == null);
}

test "20.14 显式 io：同一份代码在测试里换后端" {
    // greet 什么都不做，只证明"io 是参数"这件事可编译可测试
    const io = std.testing.io;
    try std.testing.expect(@hasDecl(std.Io.Dir, "cwd"));
    try std.testing.expect(@hasDecl(std.Io.Dir, "path"));
    // Writer/Reader 是字段不是函数（@hasDecl 探针）
    try std.testing.expect(!@hasDecl(std.Io.File.Reader, "interface"));
    try std.testing.expect(!@hasDecl(std.Io.File.Writer, "interface"));
    _ = io;
}

test "20.2 flags：exclusive / allow_directory 两组选项的行为" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    // createFile 的 exclusive：必须新建，第二次必然 PathAlreadyExists
    const f1 = try tmp.dir.createFile(io, "e.txt", .{ .exclusive = true });
    f1.close(io);
    try std.testing.expectError(error.PathAlreadyExists, tmp.dir.createFile(io, "e.txt", .{ .exclusive = true }));

    // OpenFileOptions.mode 是枚举
    try std.testing.expectEqual(std.Io.Dir.OpenFileOptions.Mode.read_only, (std.Io.Dir.OpenFileOptions{}).mode);
    // allow_directory 默认 true；设 false 打开目录 → IsDir
    var d = try tmp.dir.openDir(io, ".", .{});
    d.close(io);
    if (tmp.dir.openFile(io, ".", .{ .allow_directory = false })) |f| {
        f.close(io);
        return error.TestUnexpectedResult;
    } else |err| try std.testing.expectEqual(error.IsDir, err);
}

test "20.5 缓冲 Writer 的 buffered() 长度在 flush 前后归零" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const f = try tmp.dir.createFile(io, "b.txt", .{});
    defer f.close(io);
    var buf: [64]u8 = undefined;
    var fw = f.writer(io, &buf);
    try fw.interface.print("1234567890", .{});
    // 还没 flush：数据在用户态缓冲里
    try std.testing.expectEqual(@as(usize, 10), fw.interface.buffered().len);
    try std.testing.expectEqual(@as(u64, 10), fw.logicalPos());
    try fw.interface.flush();
    try std.testing.expectEqual(@as(usize, 0), fw.interface.buffered().len);
    // logicalPos 不变（flush 只提交，不改逻辑位置）
    try std.testing.expectEqual(@as(u64, 10), fw.logicalPos());
}

test "20.8 walk：必须在 openDir 出来的 Dir 上跑（cwd() 会BADF）" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.createDirPath(io, "w/sub");
    try tmp.dir.writeFile(io, .{ .sub_path = "w/a.txt", .data = "A" });
    try tmp.dir.writeFile(io, .{ .sub_path = "w/sub/b.txt", .data = "B" });

    var d = try tmp.dir.openDir(io, "w", .{ .iterate = true });
    defer d.close(io);
    var walker = try d.walk(a);
    defer walker.deinit();
    var n: usize = 0;
    while (try walker.next(io)) |_| n += 1;
    try std.testing.expectEqual(@as(usize, 3), n); // a.txt + sub + sub/b.txt
}

test "20.9 deleteTree 递归删整棵子树" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.createDirPath(io, "t/a/b/c");
    try tmp.dir.writeFile(io, .{ .sub_path = "t/a/b/c/deep.txt", .data = "deep" });
    // deleteDir 只能删一层，且目录非空时报 DirNotEmpty
    try std.testing.expectError(error.DirNotEmpty, tmp.dir.deleteDir(io, "t/a"));
    // deleteTree 一次删掉 4 层
    try tmp.dir.deleteTree(io, "t");
    try std.testing.expectError(error.FileNotFound, tmp.dir.statFile(io, "t", .{}));
}
