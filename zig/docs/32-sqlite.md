# 32 · SQLite 实战：C ABI 直连

> 对应示例：`examples/32_sqlite/`
>
> 真实的 C 库、真实的持久化、真实的所有权纪律——17 章 C 互操作的总成。取材 Tsoukalos ch11（书上用 `@cImport` + sqlite3.h；本例改手写 extern，只要有 DLL 就能编译）。

## 32.1 链接：不装任何东西的白嫖路线

```text
zig build-exe main.zig C:\Windows\System32\winsqlite3.dll
```

Windows 自带 `winsqlite3.dll`（System32 常驻，实测 3.51.1），LLD 可以直接拿 DLL 当导入库。书上路线需要 sqlite3.h + `-lsqlite3`（Linux 的 libsqlite3-dev）；手写 extern 路线**零头文件、零安装**——两个约束换一个收益：签名你自己负责。build.ps1 里 32 章的特判就是把 DLL 路径当对象传参。

## 32.2 extern 声明：十条函数撑起一个数据库

```zig
const c = struct {
    pub const RawDb = opaque {};      // 不透明句柄：C 的 sqlite3* 我们只转不发
    extern fn sqlite3_open_v2(filename: [*:0]const u8, db: *?*RawDb, flags: i32, vfs: ?[*:0]const u8) i32;
    extern fn sqlite3_prepare_v2(db: *RawDb, sql: [*:0]const u8, len: i32, stmt: *?*RawStmt, tail: ?*?[*:0]const u8) i32;
    extern fn sqlite3_bind_text(stmt: *RawStmt, idx: i32, value: [*]const u8, len: i32, destructor: ?*const anyopaque) i32;
    // step/finalize/column_*/errmsg —— 十条封顶
};
```

三个细节：**opaque 类型**建模 C 的不透明指针；**返回码哲学**——SQLite 几乎不抛异常型错误，全部返回 `int` 状态码（OK=0 / ROW=100 / DONE=101），Zig 侧包成 error union；**SQLITE_TRANSIENT** 是"析构器指针传 -1"的 C 奇技，Zig 里 `@ptrFromInt(@bitCast(@as(isize, -1)))` 原样照抄——它让 SQLite 拷贝一份绑定值，调用方不必保活字符串。

## 32.3 Zig 包装：句柄 + defer + error union

```zig
var db = try Db.open(":memory:");      // 特殊文件名 = 内存库（测试零磁盘）
defer db.close();
var stmt = try db.prepare("SELECT id, title, body FROM notes ORDER BY id");
defer stmt.finalize();
while (try stmt.step()) { ... }
```

`:memory:` 是 SQLite 的特殊文件名——单测完全不碰盘。注意**别**给普通文件库加 `OPEN_MEMORY` 标志：那会把任何文件库静默降级成内存库（持久化悄悄失效，新手大坑）。

## 32.4 comptime 行映射：SELECT 列 ↔ struct 字段

```zig
pub fn rowTo(stmt: *Stmt, comptime T: type) SqlError!T {
    const fields = @typeInfo(T).@"struct".fields;
    inline for (fields, 0..) |f, i| {
        switch (f.type) {
            i64, i32, u32, usize => @field(result, f.name) = @intCast(c.sqlite3_column_int(stmt.handle, idx)),
            []const u8 => @field(result, f.name) = std.mem.span(c.sqlite3_column_text(stmt.handle, idx)),
            else => @compileError(...),
        }
    }
}
```

13/14 章 comptime 的落地场景：列序与字段序对齐，**列数失配当场报错**而不是静默串位。这就是书上"高级 comptime"一节的实用形态——反射驱动的数据映射。

## 32.5 所有权：column_text 的借用窗口

`sqlite3_column_text` 返回的指针**只在下一次 step/finalize 之前有效**——`allNotes` 里立刻 dupe 进自己的分配器，出循环再统一归还。C API 的字符串全是这种"短命借用"，包装层的职责就是把这些寿命规则翻译成 Zig 的显式分配。

## 32.6 坑位清单

1. **`extern "sqlite3"` 会触发自动 `-lsqlite3`**：没有导入库直接链接失败——去掉库名字符串、DLL 路径显式传参（本章实测现场）。
2. **绑定参数下标从 1 起**：C ABI 如此，Zig 包装里照实透传并注释——别偷偷减一。
3. **参数绑定天生防注入**：`"rob'; DROP TABLE notes;--"` 进 bind_text 只是数据；拼接 SQL 字符串才会翻车——永远不要拼接。
4. **`?*RawDb` 的 null 判定**：open_v2 失败时 handle 可能仍非 null（要 close），错误信息走 `sqlite3_errmsg`——包装层统一处理，别让调用方碰裸码。
5. **opaque 类型撞名**：C 侧叫 `Db`、包装侧也叫 `Db`——同文件必炸 ambiguous reference；C 侧一律 `Raw` 前缀（本章实测现场）。

---

上一章：[31 并发进阶](31-concurrency.md) · 下一章：[33 实战：表达式解释器](33-zcalc.md)
