//! 28 文件监视：轮询快照求差（跨平台核）+ Windows 原生 ReadDirectoryChangesW（extern 直调）
//! 取材：Systems Programming with Zig ch5（zwatch：inotify/kqueue）+ Learning Zig ch13（FileGuard）
//! 0.16 现状：std 没有跨平台 watch——轮询核（上半）保底，Windows 原生 RDCW（下半）示范 extern 进阶
const std = @import("std");
const builtin = @import("builtin");

const EventKind = enum { created, modified, removed };

const Event = struct {
    kind: EventKind,
    path: []const u8, // 由 PollWatcher 的分配器 dupe，事件数组只借不走
};

/// 轮询核：path → (size, mtime) 快照；两次扫描求差即事件流
/// 根目录以 Dir 句柄注入（main 传 cwd，测试传 tmpDir——不写死 cwd 才可测）
const PollWatcher = struct {
    io: std.Io,
    a: std.mem.Allocator, // 快照键与事件路径的 owner
    root: std.Io.Dir,
    state: std.StringHashMap(Entry),

    const Entry = struct { size: u64, mtime: i96 };

    fn init(a: std.mem.Allocator, io: std.Io, root: std.Io.Dir) PollWatcher {
        return .{ .io = io, .a = a, .root = root, .state = std.StringHashMap(Entry).init(a) };
    }

    fn deinit(w: *PollWatcher) void {
        var it = w.state.keyIterator();
        while (it.next()) |k| w.a.free(k.*);
        w.state.deinit();
    }

    /// 扫描 root 下的普通文件到 out（键的所有权归 out 背后的分配器）
    fn scanInto(io: std.Io, a: std.mem.Allocator, root: std.Io.Dir, out: *std.StringHashMap(Entry)) !void {
        var d = try root.openDir(io, ".", .{ .iterate = true });
        defer d.close(io);
        var it = d.iterate();
        while (try it.next(io)) |entry| {
            if (entry.kind != .file) continue;
            const name = try a.dupe(u8, entry.name); // entry.name 活不过下一次 next()
            errdefer a.free(name);
            const st = try d.statFile(io, entry.name, .{});
            const gop = try out.getOrPut(name);
            if (gop.found_existing) {
                a.free(name);
            } else {
                gop.key_ptr.* = name;
            }
            gop.value_ptr.* = .{ .size = st.size, .mtime = st.mtime.nanoseconds };
        }
    }

    /// 建基线；事件从下一次 poll 开始计
    fn baseline(w: *PollWatcher) !void {
        try scanInto(w.io, w.a, w.root, &w.state);
    }

    /// 与基线求差产出事件并整体换血基线。事件 path 一律 dupe（w.a），调用方负责逐条释放——
    /// 不与 map 键共享（基线随时换血，借键就是悬空雷）。
    fn poll(w: *PollWatcher, events: *std.ArrayList(Event)) !void {
        var now = std.StringHashMap(Entry).init(w.a);
        errdefer {
            var it = now.keyIterator();
            while (it.next()) |k| w.a.free(k.*);
            now.deinit();
        }
        try scanInto(w.io, w.a, w.root, &now);

        var it = now.iterator();
        while (it.next()) |e| {
            const kind: EventKind = blk: {
                if (w.state.get(e.key_ptr.*)) |old| {
                    if (old.size != e.value_ptr.size or old.mtime != e.value_ptr.mtime) break :blk .modified;
                    continue;
                }
                break :blk .created;
            };
            try events.append(w.a, .{ .kind = kind, .path = try w.a.dupe(u8, e.key_ptr.*) });
        }
        var oit = w.state.iterator();
        while (oit.next()) |e| {
            if (!now.contains(e.key_ptr.*)) {
                try events.append(w.a, .{ .kind = .removed, .path = try w.a.dupe(u8, e.key_ptr.*) });
            }
        }

        // 换血：旧键全数释放，now 的键随 map 移交为下一轮基线
        var old = w.state;
        w.state = now;
        var old_it = old.keyIterator();
        while (old_it.next()) |k| w.a.free(k.*);
        old.deinit();
    }
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const a = init.arena.allocator();
    const err = std.debug;
    const cwd = std.Io.Dir.cwd();

    // ═══ 28.1 轮询核：手动驱动（确定性——什么时候 poll 你说了算）
    const box = "watch_demo";
    try cwd.deleteTree(io, box);
    try cwd.createDirPath(io, box);
    const box_dir = try cwd.openDir(io, box, .{});

    var w = PollWatcher.init(a, io, box_dir);
    defer w.deinit();
    try w.baseline();

    var events: std.ArrayList(Event) = .empty;
    defer events.deinit(a);

    try cwd.writeFile(io, .{ .sub_path = box ++ "/a.txt", .data = "one" });
    try cwd.writeFile(io, .{ .sub_path = box ++ "/b.txt", .data = "two" });
    try w.poll(&events);
    err.print("第一轮事件 {d} 条：\n", .{events.items.len});
    for (events.items) |e| err.print("  {s}: {s}\n", .{ @tagName(e.kind), std.fs.path.basename(e.path) });

    try cwd.writeFile(io, .{ .sub_path = box ++ "/a.txt", .data = "one-two" }); // 内容变了
    try cwd.deleteFile(io, box ++ "/b.txt");
    try w.poll(&events);
    err.print("第二轮累计 {d} 条（新增：）\n", .{events.items.len});
    for (events.items[2..]) |e| err.print("  {s}: {s}\n", .{ @tagName(e.kind), std.fs.path.basename(e.path) });

    // ═══ 28.2 平台取舍：Linux 用 inotify、BSD/macOS 用 kqueue（书 zwatch 原案）；
    // Windows 对应物 ReadDirectoryChangesW——std 没封，extern 直调（17 章姿势的进阶）
    if (native.enabled) {
        const got = try native.demo(io, a, box);
        err.print("原生 RDCW：捕获 {d} 条变更事件\n", .{got});
    } else {
        err.print("本机非 Windows：原生一节跳过（Linux 读 inotify，BSD/macOS 读 kqueue）\n", .{});
    }

    try cwd.deleteTree(io, box);
    err.print("自检通过\n", .{});
}

// ═══ 28.3 Windows 原生 ReadDirectoryChangesW——整段装进命名空间按平台门控，
// 非 Windows 编译成空壳（extern "kernel32" 与 callconv(.winapi) 只在真目标上存在）
const native = if (builtin.os.tag == .windows) struct {
    const w = std.os.windows;
    const enabled = true;

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

    extern "kernel32" fn CloseHandle(hObject: w.HANDLE) callconv(.winapi) w.BOOL;

    const FILE_LIST_DIRECTORY: w.DWORD = 0x0001;
    const OPEN_EXISTING: w.DWORD = 3;
    const FILE_FLAG_BACKUP_SEMANTICS: w.DWORD = 0x0200_0000; // 开目录句柄必带
    const FILE_NOTIFY_CHANGE_FILE_NAME: w.DWORD = 0x0001;
    const FILE_NOTIFY_CHANGE_SIZE: w.DWORD = 0x0008;
    const FILE_NOTIFY_CHANGE_LAST_WRITE: w.DWORD = 0x0010;
    const FILE_ADDED: w.DWORD = 0x0000_0001;
    const FILE_MODIFIED: w.DWORD = 0x0000_0003;

    const NotifyInfo = extern struct {
        next_offset: w.DWORD,
        action: w.DWORD,
        name_len: w.DWORD,
        // 紧随 name_len 字节的 UTF-16 文件名（不定长记录链表，按字节推进）
    };

    /// 写入线程：100ms 后在被监视目录里建一个文件（RDCW 只报告"调用之后"的变更，
    /// 所以写入必须发生在 ReadDirectoryChangesW 阻塞期间——这正是线程的用处）
    fn writerAct(io: std.Io, path: []const u8) void {
        io.sleep(std.Io.Duration.fromMilliseconds(100), .awake) catch {};
        const full = std.mem.concat(std.heap.page_allocator, u8, &.{ path, "\\native_probe.txt" }) catch return;
        defer std.heap.page_allocator.free(full);
        std.Io.Dir.cwd().writeFile(io, .{ .sub_path = full, .data = "probe" }) catch {};
    }

    /// 开目录句柄 → 派写入线程 → 阻塞等变更 → 解析记录链 → 关句柄。返回捕获的事件数。
    fn demo(io: std.Io, a: std.mem.Allocator, dir_path: []const u8) !usize {
        const wpath = try a.alloc(u16, dir_path.len + 1); // ASCII 演示路径；中文路径须 utf8ToUtf16LeAlloc
        defer a.free(wpath);
        for (dir_path, 0..) |c, i| wpath[i] = c;
        wpath[dir_path.len] = 0;

        const dir_handle = CreateFileW(
            wpath.ptr,
            FILE_LIST_DIRECTORY,
            0x1 | 0x2 | 0x4,
            null,
            OPEN_EXISTING,
            FILE_FLAG_BACKUP_SEMANTICS,
            null,
        );
        if (dir_handle == w.INVALID_HANDLE_VALUE) return error.OpenDirFailed;
        defer _ = CloseHandle(dir_handle);

        const writer = try std.Thread.spawn(.{}, writerAct, .{ io, dir_path });
        defer writer.join();

        var buffer: [4096]u8 align(@alignOf(NotifyInfo)) = undefined;
        var returned: w.DWORD = 0;
        const ok = ReadDirectoryChangesW(
            dir_handle,
            &buffer,
            buffer.len,
            .FALSE, // 只看本目录；.TRUE 则递归
            FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_SIZE | FILE_NOTIFY_CHANGE_LAST_WRITE,
            &returned,
            null, // 无 OVERLAPPED：同步阻塞到有事件为止
            null,
        );
        if (ok == .FALSE) return error.ReadChangesFailed;

        var count: usize = 0;
        var off: usize = 0;
        while (off + @sizeOf(NotifyInfo) <= returned) {
            const rec: *const NotifyInfo = @ptrCast(@alignCast(buffer[off..].ptr));
            if (rec.action == FILE_ADDED or rec.action == FILE_MODIFIED) count += 1;
            if (rec.next_offset == 0) break;
            off += rec.next_offset;
        }
        return count;
    }
} else struct {
    const enabled = false;
    fn demo(io: std.Io, a: std.mem.Allocator, dir_path: []const u8) !usize {
        _ = io;
        _ = a;
        _ = dir_path;
        return 0;
    }
};

// ═══ 28.4 测试：轮询核全事件序列（手动驱动，零计时依赖）
test "轮询核：created/modified/removed 全序列" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "seed.txt", .data = "x" });

    var w = PollWatcher.init(a, io, tmp.dir);
    defer w.deinit();
    try w.baseline();

    var events: std.ArrayList(Event) = .empty;
    defer {
        for (events.items) |e| a.free(e.path); // 事件路径是 dupe，逐条归还
        events.deinit(a);
    }

    try w.poll(&events); // 无变化 → 无事件
    try std.testing.expectEqual(@as(usize, 0), events.items.len);

    try tmp.dir.writeFile(io, .{ .sub_path = "n1.txt", .data = "11" });
    try tmp.dir.writeFile(io, .{ .sub_path = "n2.txt", .data = "22" });
    try w.poll(&events);
    try std.testing.expectEqual(@as(usize, 2), events.items.len);
    try std.testing.expectEqual(EventKind.created, events.items[0].kind);
    try std.testing.expectEqual(EventKind.created, events.items[1].kind);

    try tmp.dir.writeFile(io, .{ .sub_path = "n1.txt", .data = "1" });
    try tmp.dir.deleteFile(io, "n2.txt");
    try w.poll(&events);
    try std.testing.expectEqual(@as(usize, 4), events.items.len);
    try std.testing.expectEqual(EventKind.modified, events.items[2].kind);
    try std.testing.expectEqual(EventKind.removed, events.items[3].kind);
    try std.testing.expectEqualStrings("n1.txt", std.fs.path.basename(events.items[2].path));
    try std.testing.expectEqualStrings("n2.txt", std.fs.path.basename(events.items[3].path));

    try w.poll(&events); // 幂等：不动就无事件
    try std.testing.expectEqual(@as(usize, 4), events.items.len);
}
