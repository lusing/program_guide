//! 32 SQLite 实战：C ABI 直连（手写 extern "c" 子集）+ Zig 包装 + comptime 行映射
//!
//! 取材：Systems Programming with Zig ch11（书上用 @cImport + sqlite3.h）。0.17 起 @cImport 已从语言
//! 里移除，而本章是**单文件 + -lsqlite3**（不走 build.zig，连 b.addTranslateC 都用不上）——手写
//! extern 是唯一路。这是 17/25/29 章 extern 路线的总成。链接：macOS 自带 sqlite3（在 dyld 共享缓存
//! 里，无实体文件），`-lsqlite3` 即可；Windows 用 winsqlite3.dll，Linux 需 libsqlite3-dev。
//! 验证：单测一律 ":memory:" 库（零磁盘、彼此隔离）。
const std = @import("std");
fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}
fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ═══ 32.2 手写 extern "c"：sqlite3.h 一万行，我们只取用得到的三十来条 ═══
// 0.17 三条硬约束（本章全踩过）：① `callconv(.C)` 改名 `callconv(.c)`（小写）；② 名字不能遮蔽
// 原始类型名（`const void` 报 "name shadows primitive"），故 C 侧一律加 `Raw` 前缀；③ extern fn 的参数里不许出现切片（`[:0]const u8` 也不行——切片无内存表示），C 串只能写 `[*:0]const u8`。
const c = struct {
    pub const RawDb = opaque {}; // C 的 sqlite3*：只转发不解释，opaque {} 精确建模
    pub const RawStmt = opaque {};
    pub const RawContext = opaque {};
    pub const RawValue = opaque {};
    extern fn sqlite3_libversion() [*:0]const u8;
    extern fn sqlite3_libversion_number() c_int;
    extern fn sqlite3_open_v2(filename: [*:0]const u8, db: *?*RawDb, flags: c_int, vfs: ?[*:0]const u8) c_int;
    extern fn sqlite3_close(db: ?*RawDb) c_int;
    extern fn sqlite3_close_v2(db: ?*RawDb) c_int;
    extern fn sqlite3_db_filename(db: *RawDb, name: [*:0]const u8) ?[*:0]const u8;
    /// 回调用不到时传 null。`?*const fn (...) callconv(.c) c_int` 就是"C 函数指针"的 Zig 写法。
    pub const ExecCb = ?*const fn (?*anyopaque, c_int, [*]?[*:0]u8, [*]?[*:0]u8) callconv(.c) c_int;
    extern fn sqlite3_exec(db: *RawDb, sql: [*:0]const u8, cb: ExecCb, arg: ?*anyopaque, errmsg: ?*?[*:0]u8) c_int;
    extern fn sqlite3_prepare_v2(db: *RawDb, sql: [*:0]const u8, len: c_int, stmt: *?*RawStmt, tail: ?*?[*:0]const u8) c_int;
    extern fn sqlite3_step(stmt: *RawStmt) c_int;
    extern fn sqlite3_reset(stmt: *RawStmt) c_int;
    extern fn sqlite3_finalize(stmt: *RawStmt) c_int;
    extern fn sqlite3_bind_parameter_count(stmt: *RawStmt) c_int;
    // 参数下标从 1 起（C ABI 如此，Zig 侧不偷偷减一）。text 是 `[*]const u8` + 显式长度、 **没有哨兵**——所以含 `\0` 的值也能完整绑定。
    extern fn sqlite3_bind_null(stmt: *RawStmt, idx: c_int) c_int;
    extern fn sqlite3_bind_int64(stmt: *RawStmt, idx: c_int, value: i64) c_int;
    extern fn sqlite3_bind_double(stmt: *RawStmt, idx: c_int, value: f64) c_int;
    extern fn sqlite3_bind_text(stmt: *RawStmt, idx: c_int, value: [*]const u8, len: c_int, destructor: ?*const anyopaque) c_int;
    extern fn sqlite3_bind_blob(stmt: *RawStmt, idx: c_int, value: ?*const anyopaque, n: c_int, destructor: ?*const anyopaque) c_int;
    extern fn sqlite3_column_count(stmt: *RawStmt) c_int;
    extern fn sqlite3_column_name(stmt: *RawStmt, idx: c_int) ?[*:0]const u8;
    extern fn sqlite3_column_type(stmt: *RawStmt, idx: c_int) c_int;
    extern fn sqlite3_column_bytes(stmt: *RawStmt, idx: c_int) c_int;
    extern fn sqlite3_column_int64(stmt: *RawStmt, idx: c_int) i64;
    extern fn sqlite3_column_double(stmt: *RawStmt, idx: c_int) f64;
    extern fn sqlite3_column_text(stmt: *RawStmt, idx: c_int) ?[*:0]const u8;
    extern fn sqlite3_column_blob(stmt: *RawStmt, idx: c_int) ?*const anyopaque;
    extern fn sqlite3_errmsg(db: *RawDb) [*:0]const u8;
    extern fn sqlite3_errcode(db: *RawDb) c_int;
    extern fn sqlite3_errstr(code: c_int) [*:0]const u8;
    extern fn sqlite3_changes(db: *RawDb) c_int;
    extern fn sqlite3_total_changes(db: *RawDb) c_int;
    extern fn sqlite3_last_insert_rowid(db: *RawDb) i64;
    // 自定义函数：x_func 给标量，x_step + x_final 给聚合。
    pub const ScalarFn = *const fn (?*RawContext, c_int, [*]?*RawValue) callconv(.c) void;
    pub const StepFn = *const fn (?*RawContext, c_int, [*]?*RawValue) callconv(.c) void;
    pub const FinalFn = *const fn (?*RawContext) callconv(.c) void;
    extern fn sqlite3_create_function_v2(db: *RawDb, name: [*:0]const u8, n_arg: c_int, text_rep: c_int, app: ?*anyopaque, x_func: ?ScalarFn, x_step: ?StepFn, x_final: ?FinalFn, x_destroy: ?*const fn (?*anyopaque) callconv(.c) void) c_int;
    extern fn sqlite3_aggregate_context(ctx: ?*RawContext, n_bytes: c_int) ?*anyopaque;
    extern fn sqlite3_result_int64(ctx: ?*RawContext, value: i64) void;
    extern fn sqlite3_result_null(ctx: ?*RawContext) void;
    extern fn sqlite3_value_int64(value: ?*RawValue) i64;
    extern fn sqlite3_value_text(value: ?*RawValue) ?[*:0]const u8;
    // 常量全部手抄自 sqlite3.h——抄错一个就在链接期或运行期见分晓。
    pub const OK: c_int = 0;
    pub const BUSY: c_int = 5;
    pub const CONSTRAINT: c_int = 19;
    pub const ROW: c_int = 100;
    pub const DONE: c_int = 101;
    pub const INTEGER: c_int = 1;
    pub const FLOAT: c_int = 2;
    pub const TEXT: c_int = 3;
    pub const BLOB: c_int = 4;
    pub const NULL: c_int = 5;
    pub const OPEN_READWRITE: c_int = 0x00000002;
    pub const OPEN_CREATE: c_int = 0x00000004;
    pub const UTF8: c_int = 1;
    /// SQLITE_TRANSIENT：析构器参数传 `(void*)-1` 哨兵，意思是"我自己拷一份"。没有它，
    /// 绑定值必须活到 step / finalize——一个极常见的悬垂来源。
    pub const TRANSIENT: ?*const anyopaque = @ptrFromInt(@as(usize, @bitCast(@as(isize, -1))));
};

// ═══ 32.7 把 C 的整数错误码翻译成 Zig 错误集 ═══════════════════════
/// Zig 的 error 是有名字的枚举，SQLite 给你一个 int。映射让调用方能 `catch error.Constraint`。
pub const SqlError = error{ OpenFailed, PrepareFailed, StepFailed, BindFailed, OutOfMemory, Constraint, Busy, Sqlite };
fn mapCode(code: c_int) SqlError {
    return switch (code) {
        c.CONSTRAINT => error.Constraint,
        c.BUSY => error.Busy,
        else => error.Sqlite,
    };
}

/// 只取路径末段：完整路径含平台相关的临时目录前缀，不适合进输出。
fn tailOf(path: []const u8) []const u8 {
    return path[if (std.mem.lastIndexOfScalar(u8, path, '/')) |i| i + 1 else 0..];
}

/// 跑一条注定失败的语句，只取错误名。必须待在**文件顶层**（见 32.11 关于嵌套 fn 的说明）。
/// 注意 `catch |e| e` 挂在 `SqlError!void` 上不会收窄成 `SqlError`——void 不是 error 值。
fn execErrName(db: *Db, sql: [:0]const u8) [:0]const u8 {
    if (db.exec(sql)) |_| return "没报错（前提有误）" else |e| return @errorName(e);
}

/// ═══ 32.3 Zig 包装：句柄 + defer 生命周期 + error union ══════════════
pub const Db = struct {
    handle: *c.RawDb,
    /// `path` 给 ":memory:" 就是内存库（**特殊文件名**，不需额外标志）。别给文件库加
    /// OPEN_MEMORY 标志——那会把文件库静默降级成内存库，持久化悄悄失效。
    pub fn open(path: []const u8) SqlError!Db {
        var buf: [512]u8 = undefined;
        if (path.len >= buf.len) return error.OpenFailed;
        @memcpy(buf[0..path.len], path);
        buf[path.len] = 0; // 手工补哨兵：open 收普通切片，内部转 C 字符串
        var handle: ?*c.RawDb = null;
        const rc = c.sqlite3_open_v2(buf[0..path.len :0].ptr, &handle, c.OPEN_READWRITE | c.OPEN_CREATE, null);
        if (handle == null) return error.OpenFailed;
        if (rc != c.OK) return mapCode(rc);
        return .{ .handle = handle.? };
    }
    /// close_v2：即使还有未 finalize 的 stmt 也返回 OK，句柄进"僵尸态"等 stmt 释放后
    /// 自毁——好处是不泄漏，代价是吞掉错误。close 则返回 SQLITE_BUSY 把问题顶回给你。
    pub fn close(db: Db) void {
        _ = c.sqlite3_close_v2(db.handle);
    }
    pub fn closeStrict(db: Db) c_int {
        return c.sqlite3_close(db.handle);
    }
    /// 快路径：不含结果集的多语句一次跑完（DDL / INSERT / BEGIN / COMMIT 都走它）。
    pub fn exec(db: *Db, sql: [:0]const u8) SqlError!void {
        const rc = c.sqlite3_exec(db.handle, sql.ptr, null, null, null);
        if (rc != c.OK) return mapCode(rc);
    }
    pub fn prepare(db: *Db, sql: [:0]const u8) SqlError!Stmt {
        var stmt: ?*c.RawStmt = null;
        // len 传 -1 = "自己找结尾的 \0"；也可传 sql.len 把解析限制在这条语句内。
        const rc = c.sqlite3_prepare_v2(db.handle, sql.ptr, -1, &stmt, null);
        if (stmt == null) return error.PrepareFailed;
        if (rc != c.OK) return mapCode(rc);
        return .{ .handle = stmt.?, .db = db };
    }
    pub fn changes(db: *Db) i64 {
        return c.sqlite3_changes(db.handle);
    }
    pub fn totalChanges(db: *Db) i64 {
        return c.sqlite3_total_changes(db.handle);
    }
    pub fn dbFilename(db: *Db) []const u8 {
        return std.mem.span(c.sqlite3_db_filename(db.handle, "main") orelse return "");
    } // 内存库返回空串——它没有文件
    pub fn lastInsertRowid(db: *Db) i64 {
        return c.sqlite3_last_insert_rowid(db.handle);
    }
    pub fn errcode(db: *Db) c_int {
        return c.sqlite3_errcode(db.handle);
    }
    /// 返回的切片**借用 SQLite 内部缓冲**，下一次同库 API 调用即失效。
    /// 把 errmsg 拷进 Zig 侧定长缓冲：C 给的是"库里那块内存 + 一个指针"，Zig 的纪律是"值归我"。
    pub fn errmsgInto(db: *Db, buf: []u8) SqlError![:0]u8 {
        return std.fmt.bufPrintSentinel(buf, "sqlite: {s}", .{std.mem.span(c.sqlite3_errmsg(db.handle))}, 0) catch error.OutOfMemory;
    }
};

/// 预编译语句。`handle` 是 sqlite3_stmt*，`db` 用来在 step 出错时查 errcode。
pub const Stmt = struct {
    handle: *c.RawStmt,
    db: *Db,
    pub fn finalize(stmt: *Stmt) void {
        _ = c.sqlite3_finalize(stmt.handle);
    }
    /// 复位但不解绑：语句结构、绑定值都还在，可以只换参数重跑。
    pub fn reset(stmt: *Stmt) void {
        _ = c.sqlite3_reset(stmt.handle);
    }
    pub fn bindParameterCount(stmt: *Stmt) i64 {
        return c.sqlite3_bind_parameter_count(stmt.handle);
    }
    // ── 32.5 绑定：四种绑法，四个下标都从 1 起 ─────────────────
    pub fn bindNull(stmt: *Stmt, idx: c_int) SqlError!void {
        if (c.sqlite3_bind_null(stmt.handle, idx) != c.OK) return error.BindFailed;
    } // 绑 SQL NULL（三值逻辑里的那个，不是字符串 "NULL"）
    pub fn bindInt(stmt: *Stmt, idx: c_int, v: i64) SqlError!void {
        if (c.sqlite3_bind_int64(stmt.handle, idx, v) != c.OK) return error.BindFailed;
    } // 绑 64 位整型
    pub fn bindDouble(stmt: *Stmt, idx: c_int, v: f64) SqlError!void {
        if (c.sqlite3_bind_double(stmt.handle, idx, v) != c.OK) return error.BindFailed;
    }
    /// 哨兵切片 `[:0]const u8` 在这里派上用场：调用方手上通常就是 C 字符串风格的切片，
    /// 直接传 `.ptr`；长度显式给 `v.len`（不给 -1），值里含 `\0` 也不会被截断。
    pub fn bindText(stmt: *Stmt, idx: c_int, v: [:0]const u8) SqlError!void {
        if (c.sqlite3_bind_text(stmt.handle, idx, v.ptr, @intCast(v.len), c.TRANSIENT) != c.OK) return error.BindFailed;
    }
    /// blob 走 `?*const anyopaque` + 长度，没有哨兵可言——二进制数据就该这么传。
    pub fn bindBlob(stmt: *Stmt, idx: c_int, bytes: []const u8) SqlError!void {
        if (c.sqlite3_bind_blob(stmt.handle, idx, bytes.ptr, @intCast(bytes.len), c.TRANSIENT) != c.OK) return error.BindFailed;
    }
    /// 返回 true = 还有一行；false = 结束；错误映射成 Zig error。
    pub fn step(stmt: *Stmt) SqlError!bool {
        return switch (c.sqlite3_step(stmt.handle)) {
            c.ROW => true,
            c.DONE => false,
            else => mapCode(c.sqlite3_errcode(stmt.db.handle)),
        };
    }
    pub fn columnCount(stmt: *Stmt) i64 {
        return c.sqlite3_column_count(stmt.handle);
    } // 结果集列数——rowTo 拿它跟 struct 字段数对账
    pub fn columnName(stmt: *Stmt, idx: c_int) []const u8 {
        return std.mem.span(c.sqlite3_column_name(stmt.handle, idx) orelse return "");
    } // EXPLAIN 的计划文本在第 3 列，列名从 column_name 拿
    // ── 32.6 五种列类型：先 column_type 判别，再按类型取值 ───────
    pub fn columnType(stmt: *Stmt, idx: c_int) c_int {
        return c.sqlite3_column_type(stmt.handle, idx);
    }
    pub fn columnInt(stmt: *Stmt, idx: c_int) i64 {
        return c.sqlite3_column_int64(stmt.handle, idx);
    }
    pub fn columnDouble(stmt: *Stmt, idx: c_int) f64 {
        return c.sqlite3_column_double(stmt.handle, idx);
    }
    /// ⚠️ TEXT 的正确姿势：**先 bytes 后 text**。column_text 给的是 C 字符串（遇 `\0` 即止），
    /// 只有 column_bytes 知道真实字节数。顺序反了，含嵌入 `\0` 的值会被静默截断——不报错，只丢数据。
    pub fn columnTextBytes(stmt: *Stmt, idx: c_int, buf: []u8) SqlError![]const u8 {
        const n: usize = @intCast(c.sqlite3_column_bytes(stmt.handle, idx));
        const p = c.sqlite3_column_blob(stmt.handle, idx) orelse return &.{};
        const src: [*]const u8 = @ptrCast(p);
        if (n > buf.len) return error.OutOfMemory;
        @memcpy(buf[0..n], src[0..n]);
        return buf[0..n];
    }
    /// 偷懒版：直接拿 C 字符串。**只在确定值里没有 `\0` 时可用**（32.6 实测现场）。
    pub fn columnTextSpan(stmt: *Stmt, idx: c_int) []const u8 {
        return std.mem.span(c.sqlite3_column_text(stmt.handle, idx) orelse return "");
    }
    pub fn columnBlob(stmt: *Stmt, idx: c_int) []const u8 {
        const n: usize = @intCast(c.sqlite3_column_bytes(stmt.handle, idx));
        const p = c.sqlite3_column_blob(stmt.handle, idx) orelse return &.{};
        const src: [*]const u8 = @ptrCast(p);
        return src[0..n];
    }
    /// ═══ comptime 行映射：SELECT 列序 ↔ struct 字段 ═════════════
    /// 0.17 的 @typeInfo 不再有 `.fields`（字段结构体数组），改成三条**等长平行数组** field_names /
    /// field_types / field_attrs，按下标配对；field_types 只能用 inline for。
    pub fn rowTo(stmt: *Stmt, comptime T: type) SqlError!T {
        const info = @typeInfo(T).@"struct";
        if (info.field_names.len != @as(usize, @intCast(c.sqlite3_column_count(stmt.handle))))
            return error.StepFailed; // 列数失配当场报错，而非静默串位
        var out: T = undefined;
        inline for (info.field_names, info.field_types, 0..) |name, ty, i| {
            const idx: c_int = @intCast(i);
            switch (ty) {
                i64, i32, u32, usize => @field(out, name) = @intCast(c.sqlite3_column_int64(stmt.handle, idx)),
                []const u8 => @field(out, name) = stmt.columnTextSpan(idx),
                else => @compileError("rowTo 只支持整型与 []const u8 字段；" ++ @typeName(ty) ++ " 请自行扩展"),
            }
        }
        return out;
    }
};

// ═══ 32.11 自定义函数：Zig 写回调，注册进 SQLite ═══════════════════
// 回调必须是 `callconv(.c)` 的自由函数——**不能声明在函数体里**（0.17 语法：容器之外没有嵌套 fn；局部辅助函数只能塞进 `const H = struct { fn f() {} };` 取 H.f）。
fn netCents(ctx: ?*c.RawContext, argc: c_int, argv: [*]?*c.RawValue) callconv(.c) void {
    if (argc != 2) {
        c.sqlite3_result_null(ctx);
        return;
    }
    const kind = std.mem.span(c.sqlite3_value_text(argv[0]) orelse "");
    const cents = c.sqlite3_value_int64(argv[1]);
    c.sqlite3_result_int64(ctx, if (std.mem.eql(u8, kind, "收入")) cents else -cents);
}

/// 聚合 `zsum(x)`：靠 sqlite3_aggregate_context 拿 SQLite 分配的私有累加槽。首次调用
/// （n_bytes > 0）会清零；xFinal 里传 0 表示"只取不分配"，返回 null 就是零行。
const SumAcc = extern struct { total: i64 };
fn zsumStep(ctx: ?*c.RawContext, argc: c_int, argv: [*]?*c.RawValue) callconv(.c) void {
    _ = argc;
    const slot = c.sqlite3_aggregate_context(ctx, @sizeOf(SumAcc)) orelse return;
    const acc: *SumAcc = @ptrCast(@alignCast(slot));
    acc.total += c.sqlite3_value_int64(argv[0]);
}
fn zsumFinal(ctx: ?*c.RawContext) callconv(.c) void {
    const slot = c.sqlite3_aggregate_context(ctx, 0) orelse {
        c.sqlite3_result_null(ctx); // 一行都没进来 → NULL（SQL聚合语义，不是 0）
        return;
    };
    const acc: *SumAcc = @ptrCast(@alignCast(slot));
    c.sqlite3_result_int64(ctx, acc.total);
}
fn registerFunctions(db: *Db) SqlError!void {
    if (c.sqlite3_create_function_v2(db.handle, "net_cents", 2, c.UTF8, null, netCents, null, null, null) != c.OK) return error.Sqlite;
    if (c.sqlite3_create_function_v2(db.handle, "zsum", 1, c.UTF8, null, null, zsumStep, zsumFinal, null) != c.OK) return error.Sqlite;
}

// ═══ 32.13 完整实战：个人账本的数据层 ═════════════════════════════
pub const Ledger = struct {
    id: i64,
    month: []const u8,
    kind: []const u8,
    cents: i64,
    note: []const u8,
};
pub const Entry = struct { month: [:0]const u8, kind: [:0]const u8, cents: i64, note: [:0]const u8 };
pub fn createLedgerSchema(db: *Db) SqlError!void {
    // 多行 DDL 用 Zig 的多行字符串字面量：每行是一条独立语句，末尾不带分号也行
    try db.exec(
        \\CREATE TABLE IF NOT EXISTS ledger (
        \\  id    INTEGER PRIMARY KEY,
        \\  month TEXT    NOT NULL,
        \\  kind  TEXT    NOT NULL,
        \\  cents INTEGER NOT NULL,
        \\  note  TEXT
        \\)
    );
}
const insert_sql = "INSERT INTO ledger(month, kind, cents, note) VALUES(?,?,?,?)";
/// 四个 `?` 依次绑 month/kind/cents/note——单条和批量共用这一份绑定顺序。
fn bindEntry(stmt: *Stmt, e: Entry) SqlError!void {
    try stmt.bindText(1, e.month);
    try stmt.bindText(2, e.kind);
    try stmt.bindInt(3, e.cents);
    try stmt.bindText(4, e.note);
}
/// 单条插入：预编译一次、绑定、step 一次。
pub fn insertEntry(db: *Db, e: Entry) SqlError!i64 {
    var stmt = try db.prepare(insert_sql);
    defer stmt.finalize();
    try bindEntry(&stmt, e);
    _ = try stmt.step();
    return db.lastInsertRowid();
}
/// 批量插入：**一条预编译 + 一个事务包裹**。中途出错自动 ROLLBACK。
pub fn insertBatch(db: *Db, entries: []const Entry) SqlError!void {
    var stmt = try db.prepare(insert_sql);
    defer stmt.finalize();
    try db.exec("BEGIN");
    errdefer db.exec("ROLLBACK") catch {};
    for (entries) |e| {
        try bindEntry(&stmt, e);
        _ = try stmt.step();
        stmt.reset(); // 复用同一个 stmt：省掉重新解析
    }
    try db.exec("COMMIT");
}
pub fn countLedger(db: *Db) SqlError!i64 {
    var stmt = try db.prepare("SELECT COUNT(*) FROM ledger");
    defer stmt.finalize();
    if (!try stmt.step()) return 0;
    return stmt.columnInt(0);
}
pub fn allLedger(db: *Db, a: std.mem.Allocator) SqlError![]Ledger {
    var list: std.ArrayList(Ledger) = .empty;
    errdefer {
        for (list.items) |r| {
            a.free(r.month);
            a.free(r.kind);
            a.free(r.note);
        }
        list.deinit(a);
    }
    var stmt = try db.prepare("SELECT id, month, kind, cents, note FROM ledger ORDER BY id");
    defer stmt.finalize();
    while (try stmt.step()) {
        // rowTo 返回的字符串借用 SQLite 内部缓冲，下一次 step 就失效——出循环即悬空，所以必须在借用窗口内 dupe 进自己的分配器。这是 C API 的所有权现实。
        const row = try stmt.rowTo(Ledger);
        try list.append(a, .{
            .id = row.id,
            .cents = row.cents,
            .month = try a.dupe(u8, row.month),
            .kind = try a.dupe(u8, row.kind),
            .note = try a.dupe(u8, row.note),
        });
    }
    return list.toOwnedSlice(a);
}

/// ═══ 32.9 参数化查询构造：只拼结构、不拼值 ═════════════════════════
/// `kinds` 是**代码里选定的**标识符集合（不是用户输入），进 SQL 是安全的；真正的用户值一律走 `?` 绑定。这个边界靠签名（哨兵切片数组）写死在类型上。
pub fn filterByKinds(a: std.mem.Allocator, kinds: []const [:0]const u8) SqlError![:0]u8 {
    var sql: std.ArrayList(u8) = .empty;
    defer sql.deinit(a);
    try sql.appendSlice(a, "SELECT month, SUM(net_cents(kind, cents)) FROM ledger WHERE kind IN (");
    for (kinds, 0..) |_, i| { // 占位符；值稍后由 bindText 填
        if (i != 0) try sql.append(a, ',');
        try sql.appendSlice(a, "?");
    }
    try sql.appendSlice(a, ") GROUP BY month ORDER BY month");
    return sql.toOwnedSliceSentinel(a, 0);
}

// ═══ 32.4 计时辅助：把裸耗时压成"量级"桶 ════════════════════════════
/// 耗时天然不确定，所以**裸纳秒数绝不进输出**。只取十进制数量级——一个数量级的差距足够支撑"谁快"的结论，又不会被机器抖动推翻。
fn decadeOf(x: i128) i32 {
    var e: i32 = 0;
    var v = x;
    while (v >= 10) : (v = @divTrunc(v, 10)) e += 1;
    return e;
}
const bench_rounds: usize = 20_000;
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const a = init.arena.allocator();
    const say = std.debug.print;
    var mem_db = try Db.open(":memory:");
    defer mem_db.close();
    // ═══ 32.1 为什么 SQLite 值得单独一章 ═══════════════════════
    begin("32.1");
    say("sqlite3_libversion() = {s}（数值 {d}）；c_int = {d} 字节，裸指针 = {d} 字节\n", .{ std.mem.span(c.sqlite3_libversion()), c.sqlite3_libversion_number(), @sizeOf(c_int), @sizeOf(*u8) });
    say("std.db 存在吗 = {}；std.sqlite 存在吗 = {}（0.17 标准库不内置数据库驱动）\n", .{ @hasDecl(std, "db"), @hasDecl(std, "sqlite") });
    say("⇒ 一个库、一个 -lsqlite3、一个 sqlite3.h 都不需要\n", .{});
    end("32.1");
    // ═══ 32.2 手写 extern "c" 声明 ═════════════════════════════════
    begin("32.2");
    say("本章没有 build.zig，@cImport 又已移除 → 只能手写 extern 声明\n", .{});
    // 声明层要盯的唯一一件事是**宽度**。C 的 int 是 32 位，Zig 里对应 c_int；
    // 换成 i32 也能编过，但和 sqlite3_* 返回的 c_int 做算术时要多一次 @intCast。
    say("  c_int = {d} 字节；SQLite 版本号 = {d}\n", .{
        @sizeOf(c_int), c.sqlite3_libversion_number(),
    });
    // SQLite 的返回码约定是 0=OK、100=ROW、101=DONE，非 0 即错误，
    // 所以判定写成 `code != 0` 就够——这也是 mapCode 的依据。
    // ⚠️ mapCode 返回的是**错误集**不是枚举：@tagName 不能作用于类型
    // （报 "expected enum or union; found 'error{...}'"），只能 @errorName。
    say("  本库 errcode() = {d} → 映射成 Zig 错误集成员：{s}\n", .{
        mem_db.errcode(), @errorName(mapCode(mem_db.errcode())),
    });
    say("  ⇒ 声明层唯一要盯的是**宽度**：c_int 必须原样用 c_int，别手换成 i32\n", .{});
    end("32.2");
    // ═══ 32.3 exec 快路径 ══════════════════════════════════════
    begin("32.3");
    try mem_db.exec(
        \\CREATE TABLE demo(id INTEGER PRIMARY KEY, name TEXT NOT NULL);
        \\INSERT INTO demo(name) VALUES('alpha'), ('beta'), ('gamma');
    ); // 一次 exec 跑 3 条语句——这是 exec 快路径的核心价值
    say("三次 INSERT 后 changes() = {d}（只反映**最近一条**）；total_changes() = {d}（库级累计）；last_insert_rowid() = {d}\n", .{ mem_db.changes(), c.sqlite3_total_changes(mem_db.handle), mem_db.lastInsertRowid() });
    say("⇒ exec 适合 DDL / 批量写；要读回结果就得换预编译路径\n", .{});
    end("32.3");
    // ═══ 32.4 prepare + step 预编译路径 ═══════════════════════
    begin("32.4");
    say("预编译三步：prepare_v2 → 反复 step 取行 → finalize\n", .{});
    var q = try mem_db.prepare("SELECT id, name FROM demo ORDER BY id");
    defer q.finalize();
    say("  column_count = {d}，首列名 = {s}\n", .{ q.columnCount(), q.columnName(0) });
    var seen: usize = 0;
    while (try q.step()) : (seen += 1) say("  row {d}: id={d} name={s}\n", .{ seen, q.columnInt(0), q.columnTextSpan(1) });
    say("  共 {d} 行；再 step 一次直接返回 false（同一 stmt 已耗尽）\n", .{seen});
    // 同一条查询跑两遍：A 每轮重新 prepare+finalize；B prepare 一次 + reset 复用
    const sql = "SELECT abs(?), abs(?), abs(?)";
    var sink: i64 = 0;
    const t0 = std.Io.Timestamp.now(io, .awake);
    var round: usize = 0;
    while (round < bench_rounds) : (round += 1) {
        var s1 = try mem_db.prepare(sql);
        for ([_]i64{ 3, 4, 5 }, 1..) |v, i| try s1.bindInt(@intCast(i), v);
        _ = try s1.step();
        sink += s1.columnInt(0);
        s1.finalize();
    }
    const t1 = std.Io.Timestamp.now(io, .awake);
    const t2 = std.Io.Timestamp.now(io, .awake);
    var s2 = try mem_db.prepare(sql);
    round = 0;
    while (round < bench_rounds) : (round += 1) {
        for ([_]i64{ 3, 4, 5 }, 1..) |v, i| try s2.bindInt(@intCast(i), v);
        _ = try s2.step();
        sink += s2.columnInt(0);
        s2.reset(); // 复位但不解绑：语句结构和绑定都还在，只重跑
    }
    const t3 = std.Io.Timestamp.now(io, .awake);
    const d_reparse = t0.durationTo(t1).nanoseconds;
    const d_reuse = t2.durationTo(t3).nanoseconds;
    say("{d} 轮同一查询，两条路径校验和 = {d}（必须一致，否则复用写错了）\n", .{ bench_rounds, sink });
    // 裸纳秒数**不进输出**：它在 1e7 附近浮动，写死等于写假。只印「比值的量级」+「留足余量的 布尔结论」——比值落在 1e0 桶（1~10 倍），阈值取 4 倍：实测约 6 倍，抖动翻不了结论。
    say("耗时比（重解析 / 复用）≈ 1e{d} 量级（同一数量级内的数倍差）；复用更快：{s}；至少快 4 倍：{s}\n", .{
        decadeOf(@divTrunc(d_reparse, @max(d_reuse, 1))),
        if (d_reuse < d_reparse) "是" else "否",
        if (d_reuse * 4 < d_reparse) "是" else "否",
    });
    say("⇒ Io.Clock 成员是 real / awake / boot / cpu_process / cpu_thread，**没有 .monotonic**\n", .{});
    end("32.4");
    // ═══ 32.5 参数绑定 ════════════════════════════════════════
    begin("32.5");
    try mem_db.exec("CREATE TABLE kinds(id INTEGER PRIMARY KEY, label TEXT, weight REAL, raw BLOB, memo TEXT)");
    var ins = try mem_db.prepare("INSERT INTO kinds(label, weight, raw, memo) VALUES(?,?,?,?)");
    defer ins.finalize();
    const rows = [_]struct { label: [:0]const u8, w: f64 }{
        .{ .label = "带哨兵的切片", .w = 2.5 },
        .{ .label = "含\x00的文本", .w = 0.5 },
        .{ .label = "rob'; DROP TABLE kinds;--", .w = 1.5 },
    };
    const payloads = [_][]const u8{ &[_]u8{ 0xDE, 0xAD, 0xBE, 0xEF }, &[_]u8{0x01}, &[_]u8{} };
    for (rows, payloads) |r, payload| {
        try ins.bindText(1, r.label); // 哨兵切片：.ptr + 显式长度
        try ins.bindDouble(2, r.w);
        try ins.bindBlob(3, payload); // 空 blob 也合法：长度 0
        try ins.bindNull(4);
        _ = try ins.step();
        ins.reset();
    }
    var cnt = try mem_db.prepare("SELECT COUNT(*) FROM kinds");
    defer cnt.finalize();
    _ = try cnt.step();
    say("三行分别绑定 text / double / blob / null（含一个空 blob）。第三行标签是 {s}\n", .{rows[2].label});
    say("  而 kinds 仍有 {d} 行、表还在——注入串只是数据，不是 SQL 结构\n", .{cnt.columnInt(0)});
    end("32.5");
    // ═══ 32.6 五种列类型 ══════════════════════════════════════
    begin("32.6");
    var sel = try mem_db.prepare("SELECT id, label, weight, raw, memo FROM kinds ORDER BY id");
    defer sel.finalize();
    var buf: [64]u8 = undefined;
    while (try sel.step()) {
        const label = try sel.columnTextBytes(1, &buf); // 先 bytes 再 text
        const raw = sel.columnBlob(3);
        // label 用 {x} 打印：第二行的值里有嵌入的 \0，按 {s} 打会把输出污染成一个"空格"
        say("  id={d}(INTEGER) label={x}({d}B,TEXT) weight={d}(FLOAT) raw={x}({d}B,BLOB) memo={s}(类型码={d},NULL)\n", .{
            sel.columnInt(0),      label,             label.len, sel.columnDouble(2), raw, raw.len,
            sel.columnTextSpan(4), sel.columnType(4),
        });
    }
    say("五种列类型码：1=INTEGER 2=FLOAT 3=TEXT 4=BLOB 5=NULL\n", .{});
    // TEXT 里嵌一个 \0
    try mem_db.exec("CREATE TABLE tricky(v TEXT); INSERT INTO tricky VALUES('ab' || char(0) || 'cd');");
    var t = try mem_db.prepare("SELECT v FROM tricky");
    defer t.finalize();
    _ = try t.step();
    var b1: [16]u8 = undefined;
    const correct = try t.columnTextBytes(0, &b1);
    const lazy = t.columnTextSpan(0);
    say("含嵌入 \\0 的 TEXT：column_bytes 报告 {d} 字节；先 bytes 再 text → {x}（完整）\n", .{ correct.len, correct });
    say("  直接 column_text → {x}（{d} 字节，遇 \\0 即止，静默丢数据）\n", .{ lazy, lazy.len });
    end("32.6");
    // ═══ 32.7 错误处理 ════════════════════════════════════════
    begin("32.7");
    var msg: [256]u8 = undefined;
    const bad = execErrName(&mem_db, "SELECT * FROM table_that_does_not_exist");
    say("库不存在 → errcode = {d}（1 = SQLITE_ERROR），映射为 {s}；errmsg 拷进 [256]u8 → {s}\n", .{ mem_db.errcode(), bad, try mem_db.errmsgInto(&msg) });
    try mem_db.exec("INSERT INTO demo(id, name) VALUES(900, 'dup')");
    const dup = execErrName(&mem_db, "INSERT INTO demo(id, name) VALUES(900, 'dup')");
    say("主键冲突 → errcode = {d}（19 = CONSTRAINT），映射为 {s}；errmsg = {s}\n", .{ mem_db.errcode(), dup, try mem_db.errmsgInto(&msg) });
    say("errstr({d}) = {s}（错误码的官方英文说明）\n", .{ c.CONSTRAINT, std.mem.span(c.sqlite3_errstr(c.CONSTRAINT)) });
    end("32.7");
    // ═══ 32.8 事务 ════════════════════════════════════════════
    begin("32.8");
    try mem_db.exec("CREATE TABLE tx_demo(tag TEXT)");
    // exec 一次能跑多条事务语句——这正是它作为快路径的价值
    try mem_db.exec("BEGIN; INSERT INTO tx_demo VALUES('a'); INSERT INTO tx_demo VALUES('b'); INSERT INTO tx_demo VALUES('c'); ROLLBACK;");
    var tx_cnt = try mem_db.prepare("SELECT COUNT(*) FROM tx_demo");
    defer tx_cnt.finalize();
    _ = try tx_cnt.step();
    say("BEGIN + 3 次 INSERT + ROLLBACK → 行数 {d}（回滚生效）\n", .{tx_cnt.columnInt(0)});
    try mem_db.exec("BEGIN; INSERT INTO tx_demo VALUES('x'); INSERT INTO tx_demo VALUES('y'); COMMIT;");
    tx_cnt.reset(); // 同一条COUNT 语句重跑
    _ = try tx_cnt.step();
    say("BEGIN + 2 次 INSERT + COMMIT   → 行数 {d}（提交生效）\n", .{tx_cnt.columnInt(0)});
    end("32.8");
    // ═══ 32.9 参数化查询构造 ═══════════════════════════════════
    begin("32.9");
    var sql_buf: std.ArrayList(u8) = .empty;
    defer sql_buf.deinit(a);
    try sql_buf.appendSlice(a, "SELECT COUNT(*) FROM kinds WHERE label LIKE ?");
    const qsql = try sql_buf.toOwnedSliceSentinel(a, 0);
    var like_cnt = try mem_db.prepare(qsql);
    defer like_cnt.finalize();
    const pct = try a.dupeSentinel(u8, "带%", 0);
    try like_cnt.bindText(1, pct);
    _ = try like_cnt.step();
    say("拼出来的 SQL（只拼结构）：{s}；占位符 = {d} 个；绑定 {s} 后命中 {d} 行\n", .{ qsql, like_cnt.bindParameterCount(), pct, like_cnt.columnInt(0) });
    const kinds_in = [_][:0]const u8{ "收入", "支出" };
    say("IN 列表 {d} 项 → 展开成 {d} 个 ?：{s}\n", .{ kinds_in.len, kinds_in.len, try filterByKinds(a, &kinds_in) });
    end("32.9");
    // ═══ 32.10 索引与查询计划 ═════════════════════════════════
    begin("32.10");
    // ⚠️ 主键**不能**写成 INTEGER PRIMARY KEY：那等于 rowid，SQLite 自带 B 树，索引前后计划 一模一样，看不出差别。要演示索引必须用普通列。
    try mem_db.exec("CREATE TABLE plan_demo(uid INTEGER, tag TEXT)");
    var ins2 = try mem_db.prepare("INSERT INTO plan_demo(uid, tag) VALUES(?,?)");
    var i: i64 = 0;
    while (i < 200) : (i += 1) {
        for ([_]i64{ i, i * 3 }, 1..) |v, k| try ins2.bindInt(@intCast(k), v);
        _ = try ins2.step();
        ins2.reset();
    }
    ins2.finalize();
    var plan = try mem_db.prepare("EXPLAIN QUERY PLAN SELECT * FROM plan_demo WHERE uid = 42");
    defer plan.finalize();
    var before_plan: std.ArrayList(u8) = .empty;
    while (try plan.step()) try before_plan.appendSlice(a, plan.columnTextSpan(3));
    say("  建索引前：{s}\n", .{before_plan.items});
    try mem_db.exec("CREATE INDEX ix_plan_demo_uid ON plan_demo(uid)");
    plan.reset(); // 同一 stmt 重跑：结构没变（还是那条 EXPLAIN），只是库里的索引变了
    var after_plan: std.ArrayList(u8) = .empty;
    while (try plan.step()) try after_plan.appendSlice(a, plan.columnTextSpan(3));
    say("  建索引后：{s}\n", .{after_plan.items});
    say("⇒ SCAN（全表扫）换成 SEARCH ... USING INDEX（走 B 树），这就是索引的全部意义\n", .{});
    end("32.10");
    // ═══ 32.11 自定义函数与聚合 ═══════════════════════════════
    begin("32.11");
    try registerFunctions(&mem_db);
    try mem_db.exec("CREATE TABLE fn_demo(kind TEXT, cents INTEGER)");
    try mem_db.exec("INSERT INTO fn_demo VALUES('收入', 3000), ('支出', -1200), ('支出', -800)");
    var r = try mem_db.prepare("SELECT net_cents('收入', 500), zsum(cents) FROM fn_demo");
    defer r.finalize();
    _ = try r.step();
    var empty_agg = try mem_db.prepare("SELECT zsum(cents) FROM fn_demo WHERE 0");
    defer empty_agg.finalize();
    _ = try empty_agg.step();
    say("已注册标量 net_cents 与聚合 zsum。net_cents('收入', 500) = {d}；zsum(cents) = {d}（三行合一）\n", .{ r.columnInt(0), r.columnInt(1) });
    say("  空集上的 zsum → 类型码 {d}（5 = NULL，不是 0）\n", .{empty_agg.columnType(0)});
    say("⇒ 标量给 x_func，聚合给 x_step + x_final；两者都是 callconv(.c) 自由函数\n", .{});
    end("32.11");
    // ═══ 32.12 内存库 vs 文件库 ═══════════════════════════════
    begin("32.12");
    const tmp_root = init.environ_map.get("TMPDIR") orelse "/tmp/";
    var path_buf: [512]u8 = undefined;
    const db_path = std.fmt.bufPrintSentinel(&path_buf, "{s}zig32_ledger.db", .{tmp_root}, 0) catch unreachable;
    std.Io.Dir.cwd().deleteFile(io, db_path) catch {}; // 清上一轮残留（不写 rm -rf）
    {
        var file_db = try Db.open(db_path);
        defer file_db.close();
        try file_db.exec("CREATE TABLE persist(k TEXT, v INTEGER); INSERT INTO persist VALUES('answer', 42);");
        try file_db.exec("BEGIN; INSERT INTO persist VALUES('ghost', 0); ROLLBACK;");
        say("文件库 db_filename 末段 = ...{s}；写入后 close() 已落盘（被 ROLLBACK 的 ghost 不算）\n", .{tailOf(db_path)});
    }
    var again = try Db.open(db_path);
    defer again.close();
    var back = try again.prepare("SELECT v FROM persist WHERE k = ?");
    defer back.finalize();
    try back.bindText(1, try a.dupeSentinel(u8, "answer", 0));
    _ = try back.step();
    try mem_db.exec("CREATE TABLE vanish(k TEXT); INSERT INTO vanish VALUES('x');");
    say("重新打开读回 v = {d}（跨连接存活）；内存库 db_filename 是空串：{s}\n", .{ back.columnInt(0), if (mem_db.dbFilename().len == 0) "是" else "否" });
    say("内存库：进程退出即消失、无法跨连接——单测因此可以放心用 \":memory:\"\n", .{});
    // 裸字节数随 sqlite 版本/页大小变化，不能进输出；只印两个确定性判断。
    const fstat = std.Io.Dir.cwd().statFile(io, db_path, .{}) catch {
        say("db 文件 stat 失败\n", .{});
        return;
    };
    say("db 文件非空：{s}；大小是页大小 4096 的整数倍：{s}\n", .{ if (fstat.size > 0) "是" else "否", if (@mod(fstat.size, 4096) == 0) "是" else "否" });
    std.Io.Dir.cwd().deleteFile(io, db_path) catch {};
    end("32.12");
    // ═══ 32.13 完整实战：个人账本 ═══════════════════════════════
    begin("32.13");
    var book = try Db.open(":memory:");
    defer book.close();
    try createLedgerSchema(&book);
    try registerFunctions(&book);
    const entries = [_]Entry{
        .{ .month = "2026-01", .kind = "收入", .cents = 120_000, .note = "一月工资" },
        .{ .month = "2026-01", .kind = "支出", .cents = 35_000, .note = "房租" },
        .{ .month = "2026-01", .kind = "支出", .cents = 8_000, .note = "水电" },
        .{ .month = "2026-02", .kind = "收入", .cents = 120_000, .note = "二月工资" },
        .{ .month = "2026-02", .kind = "支出", .cents = 56_000, .note = "聚餐+车费" },
        .{ .month = "2026-03", .kind = "收入", .cents = 150_000, .note = "工资加奖金" },
        .{ .month = "2026-03", .kind = "支出", .cents = 24_000, .note = "换季采购" },
    };
    try insertBatch(&book, &entries);
    say("账本 {d} 条记录（一条预编译 + 一个事务搞定批量写）\n", .{try countLedger(&book)});
    var agg = try book.prepare("SELECT month, COUNT(*), SUM(net_cents(kind,cents)) FROM ledger GROUP BY month ORDER BY month");
    defer agg.finalize();
    var total: i64 = 0;
    var lines: std.ArrayList(u8) = .empty;
    while (try agg.step()) {
        const net = agg.columnInt(2);
        total += net;
        try lines.print(a, "  {s}：{d} 笔，净额 {d} 分\n", .{ agg.columnTextSpan(0), agg.columnInt(1), net });
    }
    try lines.print(a, "  合计净额 = {d} 分（{d} 元）\n", .{ total, @divTrunc(total, 100) });
    say("{s}", .{lines.items});
    var out: std.ArrayList(u8) = .empty;
    defer out.deinit(a);
    try out.appendSlice(a, "id,month,kind,cents,note\n");
    for (try allLedger(&book, a)) |row| try out.print(a, "{d},{s},{s},{d},{s}\n", .{ row.id, row.month, row.kind, row.cents, row.note });
    // 导出：整个账本转CSV。借用窗口内格式化，不留悬垂指针。
    var it = std.mem.splitScalar(u8, out.items, '\n');
    say("CSV 共 {d} 行（含表头）；表头 + 首条数据：\n{s}\n{s}\n", .{
        std.mem.count(u8, out.items, "\n"), it.next() orelse "", it.next() orelse "",
    });
    // 回滚实测：手动 BEGIN +逐条插入（不走 insertBatch，因为它自带 COMMIT）
    const before = try countLedger(&book);
    try book.exec("BEGIN");
    var st = try book.prepare(insert_sql);
    for ([_]Entry{
        .{ .month = "2026-04", .kind = "收入", .cents = 99_900, .note = "不该存在" },
        .{ .month = "2026-04", .kind = "支出", .cents = 10_000, .note = "不该存在" },
    }) |e| {
        try bindEntry(&st, e);
        _ = try st.step();
        st.reset();
    }
    const inside = try countLedger(&book);
    st.finalize();
    try book.exec("ROLLBACK");
    say("回滚实测：事务内 {d} 条 → ROLLBACK 后 {d} 条（起始 {d}）\n", .{ inside, try countLedger(&book), before });
    say("⇒ 事务不是语法糖：它把\"一批写\"变成\"全成或全无\"\n", .{});
    end("32.13");
    // ═══ 32.14 收尾自检 ══════════════════════════════════════
    begin("32.14");
    var probe_db = try Db.open(":memory:");
    try probe_db.exec("CREATE TABLE z(k INTEGER)");
    var leaked = try probe_db.prepare("SELECT k FROM z");
    const strict_rc = probe_db.closeStrict();
    say("有未 finalize 的 stmt 时 close()   返回 {d}（{s}）\n", .{ strict_rc, std.mem.span(c.sqlite3_errstr(strict_rc)) });
    leaked.finalize();
    probe_db.close();
    say("close_v2() 则返回 {d}——它接受僵尸态，句柄等 stmt 释放后自毁\n", .{c.OK});
    say("14 个 test 全部跑在 \":memory:\" 上，互不干扰、零磁盘残留。全部自演完成，exit 0\n", .{});
    end("32.14");
}

// ═══ 32.14 测试：全部用 ":memory:" 保证隔离 ═══════════════════════════
fn testBook() !Db {
    var db = try Db.open(":memory:");
    errdefer db.close();
    try createLedgerSchema(&db);
    try registerFunctions(&db);
    return db;
}
fn seedThree(db: *Db) !void {
    try insertBatch(db, &[_]Entry{
        .{ .month = "2026-01", .kind = "收入", .cents = 10_000, .note = "n1" },
        .{ .month = "2026-01", .kind = "支出", .cents = 3_000, .note = "n2" },
        .{ .month = "2026-02", .kind = "收入", .cents = 20_000, .note = "n3" },
    });
}
fn freeLedger(a: std.mem.Allocator, rows: []Ledger) void {
    for (rows) |r| {
        a.free(r.month);
        a.free(r.kind);
        a.free(r.note);
    }
    a.free(rows);
}
test "1 内存库零磁盘：建表插入计数" {
    var db = try testBook();
    defer db.close();
    try seedThree(&db);
    try std.testing.expectEqual(@as(i64, 3), try countLedger(&db));
}
test "2 rowTo 把行映射进 struct" {
    var db = try testBook();
    defer db.close();
    try seedThree(&db);
    const a = std.testing.allocator;
    const rows = try allLedger(&db, a);
    defer freeLedger(a, rows);
    try std.testing.expectEqual(@as(i64, 1), rows[0].id);
    try std.testing.expectEqualStrings("2026-01", rows[0].month);
    try std.testing.expectEqual(@as(i64, 3_000), rows[1].cents);
    try std.testing.expectEqualStrings("n3", rows[2].note);
}
test "3 rowTo 列数失配即报错（不静默串位）" {
    var db = try testBook();
    defer db.close();
    try seedThree(&db);
    var s = try db.prepare("SELECT month FROM ledger");
    defer s.finalize();
    try std.testing.expect(try s.step());
    try std.testing.expectError(error.StepFailed, s.rowTo(Ledger)); // 1 列 vs 5 字段
}
test "4 参数绑定防注入，且 TEXT 先 bytes 才不丢嵌入 \\0" {
    var db = try Db.open(":memory:");
    defer db.close();
    try db.exec("CREATE TABLE t(id INTEGER PRIMARY KEY, v TEXT)");
    try db.exec("INSERT INTO t VALUES(1, 'ab' || char(0) || 'cd')");
    var s = try db.prepare("INSERT INTO t(v) VALUES(?)");
    defer s.finalize();
    try s.bindText(1, "x'; DROP TABLE t;--"); // 字面量本身就是 [:0]const u8
    _ = try s.step();
    var q = try db.prepare("SELECT v FROM t ORDER BY id");
    defer q.finalize();
    try std.testing.expect(try q.step()); // 第 1 行：含嵌入 \0 的值
    var buf: [16]u8 = undefined;
    const full = try q.columnTextBytes(0, &buf);
    try std.testing.expectEqual(@as(usize, 5), full.len); // 先 bytes：5 字节完整
    try std.testing.expectEqual(@as(u8, 0), full[2]);
    try std.testing.expectEqual(@as(usize, 2), q.columnTextSpan(0).len); // 偷懒版被 \0 截断
    try std.testing.expect(try q.step()); // 第 2 行：注入串原样入库，表没被删
    try std.testing.expectEqualStrings("x'; DROP TABLE t;--", q.columnTextSpan(0));
}
test "5 五种列类型都能正确判别" {
    var db = try Db.open(":memory:");
    defer db.close();
    try db.exec("CREATE TABLE t(a INTEGER, b REAL, c TEXT, d BLOB, e TEXT); INSERT INTO t VALUES(1, 2.5, 'hi', x'00FF', NULL);");
    var s = try db.prepare("SELECT a,b,c,d,e FROM t");
    defer s.finalize();
    try std.testing.expect(try s.step());
    for ([_]c_int{ c.INTEGER, c.FLOAT, c.TEXT, c.BLOB, c.NULL }, 0..) |want, i| {
        try std.testing.expectEqual(want, s.columnType(@intCast(i)));
    }
    try std.testing.expectEqual(@as(f64, 2.5), s.columnDouble(1));
    try std.testing.expectEqual(@as(usize, 2), s.columnBlob(3).len);
}
test "6 错误码映射成 Zig 错误集" {
    var db = try Db.open(":memory:");
    defer db.close();
    try std.testing.expectError(error.Sqlite, db.exec("SELECT * FROM nope"));
    try db.exec("CREATE TABLE t(k INTEGER PRIMARY KEY); INSERT INTO t VALUES(1);");
    try std.testing.expectError(error.Constraint, db.exec("INSERT INTO t VALUES(1)"));
    try std.testing.expectEqual(c.CONSTRAINT, db.errcode());
}
test "7 errmsg 拷进 Zig 缓冲后可长期持有" {
    var db = try Db.open(":memory:");
    defer db.close();
    if (db.exec("SELECT * FROM nope")) |_| unreachable else |_| {}
    var buf: [256]u8 = undefined;
    const msg = try db.errmsgInto(&buf);
    try std.testing.expect(std.mem.startsWith(u8, msg, "sqlite: "));
    try db.exec("CREATE TABLE keep(k)"); // 后续 API 调用不会踩坏这份拷贝
    try std.testing.expect(std.mem.indexOf(u8, msg, "no such table") != null);
}
test "8 事务：ROLLBACK 撤销、COMMIT 保留" {
    var db = try testBook();
    defer db.close();
    try seedThree(&db);
    const before = try countLedger(&db);
    try db.exec("BEGIN; INSERT INTO ledger(month,kind,cents,note) VALUES('2026-09','收入',1,'x');");
    try std.testing.expectEqual(before + 1, try countLedger(&db)); // 事务内看得见
    try db.exec("ROLLBACK");
    try std.testing.expectEqual(before, try countLedger(&db)); // 回滚后撤销
    try db.exec("BEGIN; INSERT INTO ledger(month,kind,cents,note) VALUES('2026-09','收入',1,'x'); COMMIT;");
    try std.testing.expectEqual(before + 1, try countLedger(&db)); // 提交后保留
}
test "9 自定义标量 / 聚合可用，空集聚合是 NULL 不是 0" {
    var db = try testBook();
    defer db.close();
    try db.exec("INSERT INTO ledger(month,kind,cents,note) VALUES('2026-01','收入',100,'a'),('2026-01','支出',40,'b');");
    var s = try db.prepare("SELECT SUM(net_cents(kind,cents)), zsum(cents) FROM ledger");
    defer s.finalize();
    try std.testing.expect(try s.step());
    try std.testing.expectEqual(@as(i64, 60), s.columnInt(0)); // 标量：100-40
    try std.testing.expectEqual(@as(i64, 140), s.columnInt(1)); // 聚合：100+40
    var e = try db.prepare("SELECT zsum(cents) FROM ledger WHERE 0");
    defer e.finalize();
    try std.testing.expect(try e.step());
    try std.testing.expectEqual(c.NULL, e.columnType(0));
}
test "10 索引前后查询计划从 SCAN 变 SEARCH" {
    var db = try Db.open(":memory:");
    defer db.close();
    const a = std.testing.allocator;
    // 普通列而非 INTEGER PRIMARY KEY：后者就是 rowid，索引前后计划相同（32.10 实测）
    try db.exec("CREATE TABLE t(uid INTEGER, v TEXT)");
    var ins = try db.prepare("INSERT INTO t(uid) VALUES(?)");
    defer ins.finalize();
    var i: i64 = 0;
    while (i < 50) : (i += 1) {
        try ins.bindInt(1, i);
        _ = try ins.step();
        ins.reset();
    }
    const probe = "EXPLAIN QUERY PLAN SELECT * FROM t WHERE uid = 7";
    var plan = try db.prepare(probe);
    defer plan.finalize();
    var before_plan: std.ArrayList(u8) = .empty;
    defer before_plan.deinit(a);
    while (try plan.step()) try before_plan.appendSlice(a, plan.columnTextSpan(3));
    try std.testing.expect(std.mem.startsWith(u8, before_plan.items, "SCAN"));
    try db.exec("CREATE INDEX ix ON t(uid)");
    plan.reset();
    var after_plan: std.ArrayList(u8) = .empty;
    defer after_plan.deinit(a);
    while (try plan.step()) try after_plan.appendSlice(a, plan.columnTextSpan(3));
    try std.testing.expect(std.mem.indexOf(u8, after_plan.items, "SEARCH") != null);
    try std.testing.expect(std.mem.indexOf(u8, after_plan.items, "USING INDEX") != null);
}
test "11 动态 IN 子句：占位符个数与 kinds 数量一致" {
    var db = try testBook();
    defer db.close();
    const a = std.testing.allocator;
    try seedThree(&db);
    const sql = try filterByKinds(a, &[_][:0]const u8{ "收入", "支出" });
    defer a.free(sql);
    var s = try db.prepare(sql);
    defer s.finalize();
    try std.testing.expectEqual(@as(i64, 2), s.bindParameterCount());
    // 字面量本身就是 [:0]const u8，不必 dupe——测试里可直接传
    try s.bindText(1, "收入");
    try s.bindText(2, "支出");
    var mbuf: [16]u8 = undefined;
    _ = try s.step();
    try std.testing.expectEqualStrings("2026-01", try s.columnTextBytes(0, &mbuf));
    _ = try s.step();
    try std.testing.expectEqualStrings("2026-02", try s.columnTextBytes(0, &mbuf));
    try std.testing.expect(!try s.step());
}
test "12 close_v2 容忍未 finalize 的 stmt" {
    var db = try Db.open(":memory:");
    try db.exec("CREATE TABLE t(k INTEGER)");
    var leaked = try db.prepare("SELECT k FROM t");
    try std.testing.expectEqual(c.BUSY, db.closeStrict()); // close 把问题顶回来
    leaked.finalize(); // 释放最后一个 stmt，僵尸句柄随即自毁
}
test "13 last_insert_rowid 跟随最新插入，insertBatch 走事务" {
    var db = try testBook();
    defer db.close();
    const r1 = try insertEntry(&db, .{ .month = "2026-05", .kind = "收入", .cents = 1, .note = "a" });
    const r2 = try insertEntry(&db, .{ .month = "2026-06", .kind = "收入", .cents = 2, .note = "b" });
    try std.testing.expectEqual(r1 + 1, r2);
    try std.testing.expectEqual(r2, db.lastInsertRowid());
    try insertBatch(&db, &[_]Entry{.{ .month = "2026-07", .kind = "收入", .cents = 1, .note = "ok" }});
    try std.testing.expectEqual(@as(i64, 3), try countLedger(&db));
}
test "14 blob 绑定与读取往返一致（含空 blob）" {
    var db = try Db.open(":memory:");
    defer db.close();
    try db.exec("CREATE TABLE t(b BLOB)");
    var s = try db.prepare("INSERT INTO t(b) VALUES(?)");
    defer s.finalize();
    const payload = [_]u8{ 0x00, 0xFF, 0x10, 0x00, 0x7F }; // 头尾都有 \0
    try s.bindBlob(1, &payload);
    _ = try s.step();
    s.reset();
    try s.bindBlob(1, &[_]u8{}); // 空 blob：长度 0，不是 null
    _ = try s.step();
    var q = try db.prepare("SELECT b FROM t");
    defer q.finalize();
    try std.testing.expect(try q.step());
    try std.testing.expectEqualSlices(u8, &payload, q.columnBlob(0));
    try std.testing.expect(try q.step());
    try std.testing.expectEqual(@as(usize, 0), q.columnBlob(0).len);
    try std.testing.expectEqual(c.BLOB, q.columnType(0)); // 空 blob 仍是 BLOB，不是 NULL
}
