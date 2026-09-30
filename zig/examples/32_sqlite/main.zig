//! 32 SQLite 实战：C ABI 直连（extern 子集）+ Zig 风格包装 + comptime 行映射 + znote CLI
//! 取材：Systems Programming with Zig ch11（书上用 @cImport + sqlite3.h；本例改手写 extern——
//! 只需 DLL 不需头文件，且把 C ABI 摊开看得一清二楚，是 17/25/29 章 extern 路线的总成）。
//! 链接：Windows 直链 winsqlite3.dll（System32 常驻，实测 3.51.1）；构建时把 DLL 路径当对象文件传给 zig。
//! 验证说明：单测用 :memory: 数据库（零磁盘依赖）；main 无参时跑脚本化自演。
const std = @import("std");

// ═══ 32.1 extern 声明：只挑用得到的（sqlite3.h 三千行，我们七十二条里取十条）
const c = struct {
    pub const RawDb = opaque {};
    pub const RawStmt = opaque {};
    pub const ExecCb = ?*const fn (?*anyopaque, i32, [*]?[*:0]u8, [*]?[*:0]u8) callconv(.c) i32;

    extern fn sqlite3_libversion() [*:0]const u8;
    extern fn sqlite3_open_v2(filename: [*:0]const u8, db: *?*RawDb, flags: i32, vfs: ?[*:0]const u8) i32;
    extern fn sqlite3_close_v2(db: ?*RawDb) i32;
    extern fn sqlite3_exec(db: *RawDb, sql: [*:0]const u8, cb: ExecCb, arg: ?*anyopaque, errmsg: ?*?[*:0]u8) i32;
    extern fn sqlite3_prepare_v2(db: *RawDb, sql: [*:0]const u8, len: i32, stmt: *?*RawStmt, tail: ?*?[*:0]const u8) i32;
    extern fn sqlite3_finalize(stmt: *RawStmt) i32;
    extern fn sqlite3_step(stmt: *RawStmt) i32;
    extern fn sqlite3_reset(stmt: *RawStmt) i32;
    extern fn sqlite3_bind_int(stmt: *RawStmt, idx: i32, value: i64) i32;
    extern fn sqlite3_bind_text(stmt: *RawStmt, idx: i32, value: [*]const u8, len: i32, destructor: ?*const anyopaque) i32;
    extern fn sqlite3_column_count(stmt: *RawStmt) i32;
    extern fn sqlite3_column_int(stmt: *RawStmt, idx: i32) i64;
    extern fn sqlite3_column_text(stmt: *RawStmt, idx: i32) ?[*:0]const u8;
    extern fn sqlite3_errmsg(db: *RawDb) [*:0]const u8;

    pub const OK: i32 = 0;
    pub const ROW: i32 = 100;
    pub const DONE: i32 = 101;
    pub const OPEN_READWRITE: i32 = 0x00000002;
    pub const OPEN_CREATE: i32 = 0x00000004;
    pub const OPEN_MEMORY: i32 = 0x00000080;

    /// SQLITE_TRANSIENT：让 sqlite 自己拷贝绑定值（析构器指针的 -1 哨兵——C 的奇技，Zig 原样照抄）
    pub const TRANSIENT: ?*const anyopaque = @ptrFromInt(@as(usize, @bitCast(@as(isize, -1))));
};

pub const SqlError = error{ OpenFailed, PrepareFailed, StepFailed, ExecFailed, BindFailed, OutOfMemory };

fn checkOk(code: i32) SqlError!void {
    if (code != c.OK) return error.ExecFailed;
}

// ═══ 32.2 Zig 包装：句柄 + defer 生命周期 + error union
pub const Db = struct {
    handle: *c.RawDb,

    /// flags 读写|建库；文件名给 ":memory:" 即内存库（特殊文件名，不需要 OPEN_MEMORY 标志——
    /// 那个标志会把任何文件库也静默变成内存库，是新手大坑）
    pub fn open(path: []const u8) SqlError!Db {
        var buf: [512]u8 = undefined;
        if (path.len >= buf.len) return error.OpenFailed;
        @memcpy(buf[0..path.len], path);
        buf[path.len] = 0;
        var handle: ?*c.RawDb = null;
        const rc = c.sqlite3_open_v2(buf[0..path.len :0].ptr, &handle, c.OPEN_READWRITE | c.OPEN_CREATE, null);
        if (rc != c.OK or handle == null) return error.OpenFailed;
        return .{ .handle = handle.? };
    }

    pub fn close(db: Db) void {
        _ = c.sqlite3_close_v2(db.handle);
    }

    /// 执行无结果语句（DDL/INSERT/DELETE 直接跑）
    pub fn exec(db: *Db, sql: [:0]const u8) SqlError!void {
        try checkOk(c.sqlite3_exec(db.handle, sql.ptr, null, null, null));
    }

    pub fn prepare(db: *Db, sql: [:0]const u8) SqlError!Stmt {
        var stmt: ?*c.RawStmt = null;
        const rc = c.sqlite3_prepare_v2(db.handle, sql.ptr, @intCast(sql.len + 1), &stmt, null);
        if (rc != c.OK or stmt == null) return error.PrepareFailed;
        return .{ .handle = stmt.?, .db = db };
    }

    pub fn errmsg(db: *Db) []const u8 {
        return std.mem.span(c.sqlite3_errmsg(db.handle));
    }
};

pub const Stmt = struct {
    handle: *c.RawStmt,
    db: *Db,

    pub fn finalize(stmt: *Stmt) void {
        _ = c.sqlite3_finalize(stmt.handle);
    }

    /// 参数下标从 1 起（C ABI 如此，Zig 侧不藏着）
    pub fn bindInt(stmt: *Stmt, idx: i32, v: i64) SqlError!void {
        if (c.sqlite3_bind_int(stmt.handle, idx, v) != c.OK) return error.BindFailed;
    }

    /// TRANSIENT 让 sqlite 拷贝一份——绑定值不必活到 step（稳妥；明示拷贝代价）
    pub fn bindText(stmt: *Stmt, idx: i32, v: []const u8) SqlError!void {
        if (c.sqlite3_bind_text(stmt.handle, idx, v.ptr, @intCast(v.len), c.TRANSIENT) != c.OK) return error.BindFailed;
    }

    /// 返回 true = 还有一行（调用方循环），false = 结束
    pub fn step(stmt: *Stmt) SqlError!bool {
        return switch (c.sqlite3_step(stmt.handle)) {
            c.ROW => true,
            c.DONE => false,
            else => error.StepFailed,
        };
    }

    pub fn reset(stmt: *Stmt) void {
        _ = c.sqlite3_reset(stmt.handle);
    }

    // ═══ 32.3 comptime 行映射：SELECT 列序 ↔ struct 字段（书 ch11 的"高级 comptime"）
    /// 当前行读进 T：整型字段走 column_int，[]const u8 字段走 column_text（借用，活到下一次 step）。
    /// comptime 断言列数 = 字段数——SQL 与 struct 对不上当场编译期/运行期报错，不静默串位。
    pub fn rowTo(stmt: *Stmt, comptime T: type) SqlError!T {
        const fields = @typeInfo(T).@"struct".fields;
        if (fields.len != @as(usize, @intCast(c.sqlite3_column_count(stmt.handle))))
            return error.StepFailed; // 列数不匹配：SQL 与 struct 失配
        var result: T = undefined;
        inline for (fields, 0..) |f, i| {
            const idx: i32 = @intCast(i);
            switch (f.type) {
                i64, i32, u32, usize => {
                    @field(result, f.name) = @intCast(c.sqlite3_column_int(stmt.handle, idx));
                },
                []const u8 => {
                    const txt = c.sqlite3_column_text(stmt.handle, idx) orelse "";
                    @field(result, f.name) = std.mem.span(txt);
                },
                else => @compileError("rowTo 支持整型与 []const u8 字段，" ++ @typeName(f.type) ++ " 请自行扩展"),
            }
        }
        return result;
    }
};

// ═══ 32.4 znote：笔记 CLI 的数据层
pub const Note = struct {
    id: i64,
    title: []const u8,
    body: []const u8,
};

pub fn createSchema(db: *Db) SqlError!void {
    try db.exec(
        \\CREATE TABLE IF NOT EXISTS notes (
        \\  id INTEGER PRIMARY KEY AUTOINCREMENT,
        \\  title TEXT NOT NULL,
        \\  body TEXT NOT NULL
        \\);
    );
}

pub fn addNote(db: *Db, title: []const u8, body: []const u8) SqlError!i64 {
    var stmt = try db.prepare("INSERT INTO notes(title, body) VALUES(?, ?)");
    defer stmt.finalize();
    try stmt.bindText(1, title);
    try stmt.bindText(2, body);
    _ = try stmt.step();
    return 0; // 简化：不追 last_insert_rowid（练习题）
}

/// 返回的 Note.title/body 借用 sqlite 内部缓冲——只在紧接着的使用窗口内有效（教学取舍，见正文）
pub fn allNotes(a: std.mem.Allocator, db: *Db) SqlError![]Note {
    var list: std.ArrayList(Note) = .empty;
    errdefer {
        for (list.items) |n| {
            a.free(n.title);
            a.free(n.body);
        }
        list.deinit(a);
    }
    var stmt = try db.prepare("SELECT id, title, body FROM notes ORDER BY id");
    defer stmt.finalize();
    while (try stmt.step()) {
        const row = try stmt.rowTo(Note);
        // 立刻 dupe：出循环即悬空（step 会复用缓冲）——这是 C API 的所有权现实
        try list.append(a, .{
            .id = row.id,
            .title = try a.dupe(u8, row.title),
            .body = try a.dupe(u8, row.body),
        });
    }
    return list.toOwnedSlice(a);
}

pub fn deleteNote(db: *Db, id: i64) SqlError!void {
    var stmt = try db.prepare("DELETE FROM notes WHERE id = ?");
    defer stmt.finalize();
    try stmt.bindInt(1, id);
    _ = try stmt.step();
}

// ═══ 32.5 自演：脚本化全流程（无参数时执行，exit 0）
pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();
    const err = std.debug.print;
    err("SQLite 版本：{s}\n", .{std.mem.span(c.sqlite3_libversion())});

    var db = Db.open(":memory:") catch |e| {
        err("打开失败：{s}\n", .{@errorName(e)});
        return e;
    };
    defer db.close();

    try createSchema(&db);
    _ = try addNote(&db, "第一篇", "Zig 直连 SQLite：extern 十条足矣");
    _ = try addNote(&db, "第二篇", "comptime 把行映射成 struct");
    _ = try addNote(&db, "第三篇", "winsqlite3.dll 在 System32 白嫖");

    const notes = try allNotes(a, &db);
    for (notes) |n| err("  #{d} {s}：{s}\n", .{ n.id, n.title, n.body });
    std.debug.assert(notes.len == 3);

    try deleteNote(&db, 2);
    const after = try allNotes(a, &db);
    err("删除 #2 后剩 {d} 条\n", .{after.len});
    std.debug.assert(after.len == 2 and after[1].id == 3);
    err("自检通过\n", .{});
}

// ═══ 32.6 测试：:memory: 全流程 + 参数绑定
test "增查删全流程（:memory:）" {
    var db = try Db.open(":memory:");
    defer db.close();
    try createSchema(&db);

    _ = try addNote(&db, "t1", "b1");
    _ = try addNote(&db, "t2", "b2");
    const a = std.testing.allocator;
    const notes = try allNotes(a, &db);
    defer {
        for (notes) |n| {
            a.free(n.title);
            a.free(n.body);
        }
        a.free(notes);
    }
    try std.testing.expectEqual(@as(usize, 2), notes.len);
    try std.testing.expectEqualStrings("t1", notes[0].title);
    try std.testing.expectEqualStrings("b2", notes[1].body);

    try deleteNote(&db, 1);
    const rest = try allNotes(a, &db);
    defer {
        for (rest) |n| {
            a.free(n.title);
            a.free(n.body);
        }
        a.free(rest);
    }
    try std.testing.expectEqual(@as(usize, 1), rest.len);
}

test "绑定参数防注入形状" {
    var db = try Db.open(":memory:");
    defer db.close();
    try createSchema(&db);
    // 恶意输入只是数据：参数绑定天生防注入（拼接 SQL 才会翻车）
    _ = try addNote(&db, "rob'; DROP TABLE notes;--", "值里带分号也没事");
    var stmt = try db.prepare("SELECT COUNT(*) FROM notes");
    defer stmt.finalize();
    try std.testing.expect(try stmt.step());
    const n = c.sqlite3_column_int(stmt.handle, 0);
    try std.testing.expectEqual(@as(i64, 1), n);
}

test "rowTo 列数失配即报错" {
    var db = try Db.open(":memory:");
    defer db.close();
    try createSchema(&db);
    _ = try addNote(&db, "a", "b");
    var stmt = try db.prepare("SELECT id, title FROM notes");
    defer stmt.finalize();
    try std.testing.expect(try stmt.step());
    try std.testing.expectError(error.StepFailed, stmt.rowTo(Note)); // Note 三字段 vs 两列
}
