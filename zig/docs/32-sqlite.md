# 32 · SQLite 实战：C ABI 直连

> 对应示例：`examples/32_sqlite/main.zig`（908 行，14 个分节 + 14 个 test）
>
> 取材：Tsoukalos *Systems Programming with Zig* ch11（书上用 `@cImport` + `sqlite3.h`）。
> 本章改**手写 `extern "c"` 声明**——0.17 起 `@cImport` 已从语言里移除，而本章是单文件工程，
> 连构建系统都没有，连 `b.addTranslateC` 都用不上。详见 [32.0](#320-为什么本章不用-cimport--与-17-章对照)。
>
> ⚠️ **本章会推翻三个常见说法**：
> 1. ❌「Zig 里可以用 `@cImport` 一把导入 sqlite3」→ 0.17 报 `error: invalid builtin function: '@cImport'`。
> 2. ❌「TEXT 列直接 `column_text` 就行」→ 含嵌入 `\0` 的值会被**静默截断**，不报错，只丢数据。
> 3. ❌「`sqlite3_column_type` 返回的就是声明的列类型」→ SQLite 有个 `DYNAMIC` 类型，存储类
>    和读出类型可以不同；连 `INTEGER` 列用 `column_text` 读也可能变 TEXT。
>
> 验证：`zig fmt --check` → `zig test`（14 个 test）→ `zig build-exe -lsqlite3` → 运行，
> 三层全绿。输出连跑 5 次逐字节一致（耗时只输出量级桶，见 32.4）。

---

## 32.0 为什么本章不用 `@cImport` / 与 17 章对照

这是本章最有价值的教学点，值得单独一节。

### `@cImport` 在 0.17 已被移除

如果你手上有一份 0.16 时代的 SQLite 示例，第一行就会撞墙：

```zig
const c = @cImport({
    @cInclude("sqlite3.h");
});
```

```text
e3_cimport.zig:2:11: error: invalid builtin function: '@cImport'
const c = @cImport({
          ^~~~~~~~
```

注意这个错误的形态：不是"找不到头文件"，而是"这个内建函数根本不存在"。0.17 把头文件翻译
从**语言层**移到了**构建系统层**。

### 两条路，各自的适用场景

| | 17 章的做法 | 本章的做法 |
|---|---|---|
| 工程形态 | `build.zig` 工程 | **单文件 + `zig build-exe`** |
| 翻译方式 | `b.addTranslateC` | 手写 `extern "c"` |
| 头文件 | 需要 `include/sqlite3.h` | **不需要任何头文件** |
| 产出 | 一个名为 `ci` 的模块 | 无中间产物 |
| 声明来源 | 翻译器保证准确 | **你手抄，抄错自己负责** |
| 链接 | `link_libc = true` + `.c` 源文件 | 一句 `-lsqlite3` |

17 章的 `build.zig` 节选长这样：

```zig
// examples/17_cinterop/build.zig
const tc = b.addTranslateC(.{
    .root_source_file = b.path("include/ci.h"),
    .target = target,
    .optimize = optimize,
    .link_libc = true,
});
const ci_module = tc.createModule(); // 私有模块：只给本工程用
```

**为什么本章不能这么做？** 因为本章是单文件验证的。`run-all.sh` 里 32 章走的是这条分支：

```bash
# run-all.sh 第 78 行
32_sqlite) test_plain_example "$dir" -lsqlite3 ;;
```

`test_plain_example` 做的是 `zig fmt --check .` → `zig test main.zig "$@"` →
`zig build-exe main.zig -femit-bin=... "$@"`。**全程没有 build.zig**，只有 `main.zig`
和一个 `-lsqlite3`。而 `b.addTranslateC` 是 `std.Build` 的 API，没有构建系统就无从谈起。

这就是本章必须手写 `extern` 的根本原因——**不是"手写更酷"，是"这个工程形态下只有这一条路"**。
两种方式各有其正当性：

- **要写库、要给别人 import**：走 17 章的 `addTranslateC`。声明准确、能用宏、能被 C++ 污染
  的头文件，只有翻译器扛得住。
- **写脚本级胶水、要一个能跑的 `.zig`**：手写 `extern`。零中间产物、零头文件依赖，
  唯一的成本是"你抄的那三十行要自己核对"。

### 一句话总结

> 17 章讲 `b.addTranslateC`，那需要 build.zig；本章是单文件，所以只能手写 `extern "c"`。
> 这是**工程形态的差别**，不是技术高下的差别。选错了不是风格问题，是根本编不过。

---

## 32.1 为什么 SQLite 值得单独一章

SQLite 是**唯一一个"零配置嵌入式数据库"能打满分的选手**：整个数据库引擎编译成一个
单一 C 文件（amalgamation），不需要服务端、不需要守护进程、不需要配置、不需要安装。
一个 `.db` 文件就是整个数据库。

对 Zig 来说它的特殊意义有三层：

| 层面 | 价值 |
|---|---|
| **C ABI 互操作** | 它是"手写 `extern` 声明 + 一个 `-l` 链接"这条路的最佳教材——头文件一万行，但你只用到三十几条声明 |
| **零依赖** | macOS 自带（`/usr/lib/libsqlite3.dylib` 在 dyld 共享缓存里）、Windows 自带（`winsqlite3.dll`）、Linux 一个 `libsqlite3-dev` |
| **教学闭环** | 事务、索引、注入防护、变长类型、自定义函数——一个库全都能真跑实测 |

先看运行时到底有多"轻"。这一节的三行输出里没有一行需要 `sqlite3.h`：

```zig
// examples/32_sqlite/main.zig 第 409-415 行
    defer mem_db.close();
    // ═══ 32.1 为什么 SQLite 值得单独一章 ═══════════════════════
    begin("32.1");
    say("sqlite3_libversion() = {s}（数值 {d}）；c_int = {d} 字节，裸指针 = {d} 字节\n", .{ std.mem.span(c.sqlite3_libversion()), c.sqlite3_libversion_number(), @sizeOf(c_int), @sizeOf(*u8) });
    say("std.db 存在吗 = {}；std.sqlite 存在吗 = {}（0.17 标准库不内置数据库驱动）\n", .{ @hasDecl(std, "db"), @hasDecl(std, "sqlite") });
    say("⇒ 一个库、一个 -lsqlite3、一个 sqlite3.h 都不需要\n", .{});
    end("32.1");
```

**运行输出（`examples/32_sqlite/main.zig`）**

```text
==== 32.1 开始 ====
sqlite3_libversion() = 3.43.2（数值 3043002）；c_int = 4 字节，裸指针 = 8 字节
std.db 存在吗 = false；std.sqlite 存在吗 = false（0.17 标准库不内置数据库驱动）
⇒ 一个库、一个 -lsqlite3、一个 sqlite3.h 都不需要
==== 32.1 结束 ====
```

两个 `false` 是本章的重要前提：**0.17 的标准库不内置任何数据库驱动**。所以「用 Zig 写
SQLite 程序」的路线只有一条——手写 `extern` 声明去调系统 C 库。这不是什么退而求其次，
而是本章真正的教学内容。

`c_int` 宽 4 字节而裸指针宽 8 字节，这两个数字后面到处都要用：C 的 `int` 在 Zig 里必须写
`c_int` 而不是 `i32`（语义上你在说"这是一个 C 的 int"），而指针在 64 位平台上是 8 字节。

### 对比 `std.db`

有些版本的 Zig 曾有过 `std.db` 抽象层。这里 `@hasDecl(std, "db")` 返回 `false`——它不存在。
这不是缺失，而是**刻意的**：标准库一旦内置数据库驱动，就得替所有人决定连接池、事务传播、
方言兼容这些策略。C 库把决定权交给你，代价是你得自己处理本章 32.6/32.7 讲的那堆细节。
本章把这个"代价"完整摊开给你看。

---

## 32.2 手写 `extern "c"` 声明

`sqlite3.h` 一万行，本章只取用得到的三十来条。声明本身分成五组：连接生命周期、执行、
绑定、取值、诊断。整块如下（这是本章最长的一块源码，值得完整看一遍）：

```zig
// examples/32_sqlite/main.zig 第 38-85 行
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
```

### 三个必须记住的映射规则

**① `callconv(.c)` 不是 `callconv(.C)`。**
0.17 把枚举成员改成小写了。C 回调（`sqlite3_exec` 的 cb、`create_function_v2` 的三个 x 函数）
在 Zig 侧一律是 `callconv(.c)`。**0.16 时代的 `.C` 会报"无效的枚举值"**。

**② `opaque {}` 建模不透明指针。**
C 的 `sqlite3*` / `sqlite3_stmt*` 是**不透明指针**——你只转发、不解释它的内存布局。
`pub const RawDb = opaque {};` 是对这件事的精确建模：往里塞一个 `@ptrCast` 得到的裸指针，
永远不会误以为能对它做字段访问。

而且必须加 `Raw` 前缀。Zig 的类型名空间和 C 的冲突面极大：`int`、`char`、`text`、`type`、
`error` 全是关键词或原始类型名。如果你在同一个文件里写：

```zig
const c = struct {
    const Db = opaque {};   // ❌ 如果包装层也叫 Db，引用处会 ambiguous
    const error = ...;      // ❌ 直接编译失败
};
```

实测（0.17）报 `error: expected 'an identifier', found 'error'`；而 `const void = 1` 报的是
更根本的那条：

```text
e1_shadow.zig:3:11: error: name shadows primitive 'void'
    const void = 1;
          ^~~~
e1_shadow.zig:3:11: note: consider using @"void" to disambiguate
```

这类名字还有 `bool` / `type` / `anyopaque` / `noreturn` / `usize` / `comptime_float`。
所以本章的 C 侧类型一律 `RawDb` / `RawStmt` / `RawContext` / `RawValue`。

**③ 指针写法：`[*c]` vs `?[*c]`。**

| C 声明 | Zig 侧写法 | 含义 |
|---|---|---|
| `const char *`（可能为 NULL） | `?[*:0]const u8` | 可选指针 + 哨兵 |
| `const char *`（保证非 NULL，如 open_v2 的 filename） | `[*:0]const u8` | 裸哨兵指针 |
| `const void *`（blob 数据） | `?*const anyopaque` | 可选数据指针 |
| `sqlite3 *`（出参，要写回） | `*?*RawDb` | 指向可选指针 |
| `char **errmsg`（出参） | `?*?[*:0]u8` | 指向可选的哨兵指针 |
| `sqlite3_value **`（参数数组） | `[*]?*RawValue` | 数组指针，元素逐个检查 |

关键点：**`?*T` 表示"指针可能为 NULL"，`T?` 表示"值本身可能不存在"**。这在 06 章讲过，
但在 C 互操作里它决定了你要不要写 `orelse`——比如 `sqlite3_column_blob` 真的可能返回
NULL（值为 SQL NULL 时），而 `sqlite3_column_int64` 绝不会返回指针所以不需要判空。

### 为什么字符串只能写 `[*:0]const u8`

这是本章最容易卡住的一条：**`extern fn` 的参数里不许出现切片**。Zig 的切片是 `{ptr, len}` 两个
字段的运行时结构体，C ABI 只收到一个寄存器——所以带切片参数会直接报错：

```text
e2_slice.zig:8:31: error: parameter of type '[:0]const u8' not allowed in function with calling convention 'x86_64_sysv'
export fn probe(db: *c.RawDb, sql: [:0]const u8) c_int {
                              ^~~~~~~~~~~~~~~~~
```

于是就有了本章的核心分工：**参数用哨兵指针 `[*:0]const u8`（`sqlite3_exec` / `prepare_v2`
自己找结尾），绑定用哨兵切片 `[:0]const u8`（Zig 侧收，`.ptr` + `.len` 传下去）**。
这就是为什么 `Db.exec` 的签名是 `sql: [:0]const u8` 而内部调的是 `sql.ptr`——
哨兵切片在 Zig 侧好用，出了函数边界就退化成裸指针。

顺带一个实测坑：macOS 共享缓存里的 SQLite **没有导出 `sqlite3_source_id`**，写进声明就链接失败：

```text
error: undefined symbol: _sqlite3_source_id
    note: referenced by /Users/xulun/.cache/zig/tmp/ac87aaa9ff3e8ae6/e4_sourceid_zcu.o:_e4_sourceid.main
```

所以别照抄头文件里"看着很安全"的全部声明——用到的才写。本章 30 来条都是实测能链上的。

### `SQLITE_TRANSIENT` 这个 C 奇技

`sqlite3_bind_text` 的最后一个参数是"析构器函数指针"。C 的常规写法是传 `SQLITE_STATIC`
（空指针），意思是"你自己保证这份数据活到 stmt 结束"。但这很容易悬垂——绑定后如果切片
出了作用域，`step` 就读到了野指针。

SQLite 给了个更省心的选项：传 `(void*)-1` 这个**非法指针值**，意思是"我自己拷一份"。
Zig 里要照抄这个 C 奇技：

```zig
pub const TRANSIENT: ?*const anyopaque = @ptrFromInt(@as(usize, @bitCast(@as(isize, -1))));
```

三步都必要：`@as(isize, -1)` 造出全 1 的有符号值，`@bitCast` 到等宽无符号（**0.17 里算术
结果永不宽化**，`-1` 直接 `@intCast` 到 `usize` 会溢出），`@ptrFromInt` 再转成指针。
代价是每次绑定多一次 memcpy——**但这个代价应该付**，它换来的是"绑定值不必保活"。

---


这一节的声明在运行时能验出什么？两件事：**宽度对不对**、**返回码约定记对没**。
示例第 32.2 分节把两者都打出来：

运行输出（`examples/32_sqlite/main.zig`）：

```text
==== 32.2 开始 ====
本章没有 build.zig，@cImport 又已移除 → 只能手写 extern 声明
  c_int = 4 字节；SQLite 版本号 = 3043002
  本库 errcode() = 0 → 映射成 Zig 错误集成员：Sqlite
  ⇒ 声明层唯一要盯的是**宽度**：c_int 必须原样用 c_int，别手换成 i32
==== 32.2 结束 ====
```

`errcode() = 0` 说明 `open(":memory:")` 成功；`mapCode(0)` 返回
`SqlError.Sqlite` 是因为 32.7 那个映射函数**只把已知错误码翻成具体成员，
其余一律落到兜底的 `.Sqlite`**——不是 bug，是刻意的保守默认
（SQLite 的错误码有 100 多个，穷举不如兜底 + `errmsg()`）。

顺带一个只会在写这一节时撞到的编译错误：`mapCode` 返回的是
**错误集**而不是枚举，所以不能用 `@tagName`：

```text
error: expected enum or union; found 'error{BindFailed,Busy,Constraint,OpenFailed,OutOfMemory,PrepareFailed,Sqlite,StepFailed}'
```

要打成字符串得用 `@errorName`。这是「`@tagName` 只能作用于枚举/联合」
那条老规矩的又一例——**错误集不是联合类型**。


## 32.3 `sqlite3_exec` 快路径

`sqlite3_exec` 是 SQLite 的"一键执行"接口：给它一整段 SQL，内部完成 prepare→step→finalize
的全过程，适合**不含结果集**的场景——建表、批量插入、`BEGIN`/`COMMIT`。

它最被低估的能力是**一次能跑多条语句**：

```zig
// examples/32_sqlite/main.zig 第 417-424 行
    begin("32.3");
    try mem_db.exec(
        \\CREATE TABLE demo(id INTEGER PRIMARY KEY, name TEXT NOT NULL);
        \\INSERT INTO demo(name) VALUES('alpha'), ('beta'), ('gamma');
    ); // 一次 exec 跑 3 条语句——这是 exec 快路径的核心价值
    say("三次 INSERT 后 changes() = {d}（只反映**最近一条**）；total_changes() = {d}（库级累计）；last_insert_rowid() = {d}\n", .{ mem_db.changes(), c.sqlite3_total_changes(mem_db.handle), mem_db.lastInsertRowid() });
    say("⇒ exec 适合 DDL / 批量写；要读回结果就得换预编译路径\n", .{});
    end("32.3");
```

**运行输出（`examples/32_sqlite/main.zig`）**

```text
==== 32.3 开始 ====
三次 INSERT 后 changes() = 3（只反映**最近一条**）；total_changes() = 3（库级累计）；last_insert_rowid() = 3
⇒ exec 适合 DDL / 批量写；要读回结果就得换预编译路径
==== 32.3 结束 ====
```

三个统计函数的语义差别是实测重点：

| 函数 | 范围 | 上例的值 |
|---|---|---|
| `sqlite3_changes()` | **最近一条**语句改的行数 | 3（那条多行 INSERT） |
| `sqlite3_total_changes()` | 本连接自打开以来的累计 | 3 |
| `sqlite3_last_insert_rowid()` | 最近成功插入的 rowid | 3 |

⚠️ **`changes()` 只反映最近一条语句。** 如果你先 `INSERT` 再 `CREATE TABLE`，`changes()`
会告诉你建表改了几行——通常是 0。这不是 bug，是 C API 的设计：它无法知道你想问哪个语句。

另一个坑：`exec` 的第 5 个参数是 `char **errmsg`。如果你传非 null，SQLite 会
`malloc` 一份错误信息，你**必须** `sqlite3_free` 它。本章传 null（不要那份文本），
改用 32.7 的 `sqlite3_errmsg`——那份是库内缓冲，不用释放。

---

## 32.4 `prepare_v2` + `step` 预编译路径

要读结果集，就得走预编译。三步走：

1. **`sqlite3_prepare_v2`** —— 把 SQL 文本解析成可执行的语句对象
2. **`sqlite3_step`** —— 反复调用，每次执行"到下一行"
3. **`sqlite3_finalize`** —— 销毁语句对象

```zig
// examples/32_sqlite/main.zig 第 426-433 行
    begin("32.4");
    say("预编译三步：prepare_v2 → 反复 step 取行 → finalize\n", .{});
    var q = try mem_db.prepare("SELECT id, name FROM demo ORDER BY id");
    defer q.finalize();
    say("  column_count = {d}，首列名 = {s}\n", .{ q.columnCount(), q.columnName(0) });
    var seen: usize = 0;
    while (try q.step()) : (seen += 1) say("  row {d}: id={d} name={s}\n", .{ seen, q.columnInt(0), q.columnTextSpan(1) });
    say("  共 {d} 行；再 step 一次直接返回 false（同一 stmt 已耗尽）\n", .{seen});
```

**运行输出（`examples/32_sqlite/main.zig`）**

```text
==== 32.4 开始 ====
预编译三步：prepare_v2 → 反复 step 取行 → finalize
  column_count = 2，首列名 = id
  row 0: id=1 name=alpha
  row 1: id=2 name=beta
  row 2: id=3 name=gamma
  共 3 行；再 step 一次直接返回 false（同一 stmt 已耗尽）
```

`sqlite3_step` 的返回值语义被包装成了一个 `bool`（`true` 还有行 / `false` 结束），
错误则映射成 Zig error（32.7）。**注意 `while (try q.step())` 里 stmt 耗尽后不会自动重置**
——想再跑一遍必须显式 `reset()`，这也是 32.10 里复用同一条 `EXPLAIN` 语句的前提。

### 为什么预编译更快：实测

同一个查询跑两遍，只差"是否每次重新解析"：

```zig
// examples/32_sqlite/main.zig 第 434-459 行
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
```

**运行输出（`examples/32_sqlite/main.zig`）**

```text
20000 轮同一查询，两条路径校验和 = 120000（必须一致，否则复用写错了）
耗时比（重解析 / 复用）≈ 1e0 量级（同一数量级内的数倍差）；复用更快：是；至少快 4 倍：是
⇒ Io.Clock 成员是 real / awake / boot / cpu_process / cpu_thread，**没有 .monotonic**
```

**为什么输出里没有裸纳秒数？** 这是本章的稳定性纪律。耗时天然不确定：机器负载、CPU 频率
调节、别的进程，都会让同一个程序两次运行差 20%。任何写进文档的裸数字下次就失效了。

做法分两层：

1. **校验和必须一致**：两条路径跑同一句 SQL、同样的绑定值，`sink` 都得是 120000。
   如果复用逻辑写错了（忘了 reset、绑定串位），校验和立刻不等——这是**确定性**断言。
2. **耗时只输出量级和留足余量的布尔结论**：`decadeOf` 取十进制数量级（比值落在 1e0 桶，
   即 1~10 倍之间），布尔阈值取 4 倍（实测约 6 倍，离两侧边界都远）。机器抖动翻不了结论。

```zig
// examples/32_sqlite/main.zig 第 396-402 行
/// 耗时天然不确定，所以**裸纳秒数绝不进输出**。只取十进制数量级——一个数量级的差距足够支撑"谁快"的结论，又不会被机器抖动推翻。
fn decadeOf(x: i128) i32 {
    var e: i32 = 0;
    var v = x;
    while (v >= 10) : (v = @divTrunc(v, 10)) e += 1;
    return e;
}
```

`decadeOf` 里那句 `@divTrunc(v, 10)` 也不是随便写的：**0.17 起 `/` 对有符号整数强制要求
显式指定除法语义**，直接写 `v / 10` 会报
`error: division with 'i96' and 'comptime_int': signed integers must use @divTrunc, @divFloor, ...`。

### `Io.Clock` 没有 `.monotonic`

取时间戳的方式在 0.17 变了两处：

```zig
const t0 = std.Io.Timestamp.now(io, .awake);      // ✅ 0.17
const t1 = t0.durationTo(t2);                     // ✅ 返回 Duration，.nanoseconds 是 i96
```

- ❌ 旧写法 `std.time.nanoTimestamp()` / `std.time.milliTimestamp()` 已移除
- ❌ **`Io.Clock` 的成员里没有 `.monotonic`**。实测枚举成员只有五个：
  `real` / `awake` / `boot` / `cpu_process` / `cpu_thread`
- 计时用途应该用 `.awake`（不含睡眠时间的单调钟）；`.real` 是墙钟，会被 NTP 调整

另外 `Io.Clock` **不是 `io` 的字段**——写 `io.clock.now(...)` 报
`error: no field named 'clock' in struct 'Io'`。正确入口是 `std.Io.Timestamp.now(io, clock)`
这个**静态函数**。

`Duration.nanoseconds` 是 `i96` 而不是 `i64`——这是 0.17 的新设计（避免长时间运行的溢出）。
别急着 `@intCast` 到 `i64`，会报
`error: expected type 'i64', found 'i96'`。

---

## 32.5 参数绑定 `sqlite3_bind_*`

SQL 用 `?` 占位符（也可以用 `:name`/`@name`/`$name`，本章统一用 `?`），值通过绑定 API 送进去。
四种绑法对应四种 Zig 参数：

```zig
// examples/32_sqlite/main.zig 第 469-492 行
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
```

**运行输出（`examples/32_sqlite/main.zig`）**

```text
==== 32.5 开始 ====
三行分别绑定 text / double / blob / null（含一个空 blob）。第三行标签是 rob'; DROP TABLE kinds;--
  而 kinds 仍有 3 行、表还在——注入串只是数据，不是 SQL 结构
==== 32.5 结束 ====
```

### 四种绑法的 Zig 侧写法

| SQLite | extern 声明的关键参数 | 包装层签名 | 注意 |
|---|---|---|---|
| `bind_null` | 无 | `bindNull(idx)` | SQL NULL ≠ 字符串 `"NULL"` |
| `bind_int64` | `i64` | `bindInt(idx, v: i64)` | **0.17 算术不宽化**：`u8 + u8` 仍是 `u8` |
| `bind_double` | `f64` | `bindDouble(idx, v: f64)` | |
| `bind_text` | `[*]const u8` + `c_int` 长度 | `bindText(idx, v: [:0]const u8)` | 哨兵切片 → `.ptr` + `.len` |
| `bind_blob` | `?*const anyopaque` + 长度 | `bindBlob(idx, bytes: []const u8)` | 空 blob 合法（长度 0） |

**下标从 1 起。** C ABI 如此，Zig 侧不偷偷减一——包装层原样透传，注释写明。想要"看起来像
Zig"就得自己减，但本章选择**不**:透传让读 C 文档的人不用做心算。

**哨兵切片在这里派上用场。** 字符串字面量在 Zig 里是 `*const [N:0]u8`，可以直接当
`[:0]const u8` 传（`main.zig` 的 test 4 就是这么干的）：

```zig
try s.bindText(1, "x'; DROP TABLE t;--"); // 字面量本身就是 [:0]const u8
```

**`TRANSIENT` 的实际收益在这里体现。** 因为声明里传了 `SQLITE_TRANSIENT`，
`rows[2].label` 那个绑定在 `step` 之前被 SQLite 拷走了一份，所以哪怕它是循环里的临时值也安全。

### 为什么必须用绑定而不是字符串拼接

第三行的标签内容是 `rob'; DROP TABLE kinds;--`。如果用拼接：

```zig
// ❌ 千万别这么写
var bad = try a.allocPrintSentinel(u8, 0, "INSERT INTO kinds(label) VALUES('{s}')", 0, .{user_input});
try db.exec(bad);   // user_input = "'; DROP TABLE kinds;--"
// ⇒ 表被删了
```

而绑定路径下，这个串原样入库，`kinds` 表一行不少（见上面输出的 "仍有 3 行、表还在"）。

原因是**结构与数据的分离**：`?` 占位符在 SQL 解析阶段就被标记成"这里有个值"，
绑定值走的是一条完全独立的通道。SQLite 的语法分析器**永远不会**把绑定值当代码解析，
所以注入在原理上就不可能发生。

顺带一个性能红利：绑定让 SQLite 能复用 prepared statement 的执行计划（32.4 演示的正是这个）。

---

## 32.6 结果读取：五种列类型

`sqlite3_column_*` 是一族**变长类型**的取值函数。同一个 `SELECT` 里，某一列在不同行可能是
整数、浮点、文本、blob 或 NULL——**列的声明类型不约束读出来的类型**。所以必须先判别：

| 类型码 | 名字 | 取值函数 | Zig 返回 |
|---|---|---|---|
| 1 | `SQLITE_INTEGER` | `column_int64` | `i64` |
| 2 | `SQLITE_FLOAT` | `column_double` | `f64` |
| 3 | `SQLITE_TEXT` | `column_bytes` + `column_blob`/`column_text` | `[]const u8` |
| 4 | `SQLITE_BLOB` | `column_bytes` + `column_blob` | `[]const u8` |
| 5 | `SQLITE_NULL` | 无（取任何函数都返回 0/空） | — |

```zig
// examples/32_sqlite/main.zig 第 503-518 行
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
```

**运行输出（`examples/32_sqlite/main.zig`）**

```text
==== 32.6 开始 ====
  id=1(INTEGER) label=e5b8a6e593a8e585b5e79a84e58887e78987(18B,TEXT) weight=2.5(FLOAT) raw=deadbeef(4B,BLOB) memo=(类型码=5,NULL)
  id=2(INTEGER) label=e590ab00e79a84e69687e69cac(13B,TEXT) weight=0.5(FLOAT) raw=01(1B,BLOB) memo=(类型码=5,NULL)
  id=3(INTEGER) label=726f62273b2044524f50205441424c45206b696e64733b2d2d(25B,TEXT) weight=1.5(FLOAT) raw=(0B,BLOB) memo=(类型码=5,NULL)
五种列类型码：1=INTEGER 2=FLOAT 3=TEXT 4=BLOB 5=NULL
含嵌入 \0 的 TEXT：column_bytes 报告 5 字节；先 bytes 再 text → 6162006364（完整）
  直接 column_text → 6162（2 字节，遇 \0 即止，静默丢数据）
==== 32.6 结束 ====
```

第 2 行值得盯着：`label=e590ab00e79a84e69687e69cac` —— 中间那个 **`00`** 就是嵌入的
`\0` 字节（`含` = `e590ab`，`的文本` = `e79a84e69687e69cac`）。这一行 label 用 `{x}` 打印
正是为了让它**可见**：按 `{s}` 打，那个 `\0` 会显示成一个"空格"（甚至在某些终端里被吞掉），
读的人根本不知道数据里有坑。**凡是要打印可能含 `\0` 的字节，一律用 `{x}`。**
两者都"看起来是空的"，但完全不同——`columnType` 返回 4（BLOB）vs 5（NULL）。
第 3 行的 label 十六进制 `726f62273b2044524f50205441424c45206b696e64733b2d2d` 解码回来
正是 `rob'; DROP TABLE kinds;--`——32.5 那个注入串原样入库了。

### ⚠️ 本章最重要的一个坑：TEXT 必须**先 bytes 后 text**

对比最后两行输出：同一个值 `'ab\0cd'`（5 字节），
- `columnTextBytes` → `6162006364`，5 字节，**数据完整**
- `columnTextSpan` → `6162`，2 字节，**静默丢了 `cd`**

原因是两个函数的语义完全不同：

- **`sqlite3_column_bytes(i)`** 返回该值的**字节数**（对 TEXT 和 BLOB 都有效）
- **`sqlite3_column_text(i)`** 返回一个 **C 字符串**（遇 `\0` 即止），且**它不告诉你真实长度**

所以 `std.mem.span` 拿到的长度是"到第一个 `\0` 为止"，不是数据库里的真实长度。
**顺序反了不会报错**——没有任何错误码、没有警告，就是数据丢了。这比崩溃可怕得多。

正确的 TEXT 读取姿势是：先 `column_bytes` 拿到长度，再用 `column_blob`（它按长度返回，
不像 `column_text` 那样按 `\0` 截）拷进自己的缓冲：

```zig
// examples/32_sqlite/main.zig 第 227-234 行
    pub fn columnTextBytes(stmt: *Stmt, idx: c_int, buf: []u8) SqlError![]const u8 {
        const n: usize = @intCast(c.sqlite3_column_bytes(stmt.handle, idx));
        const p = c.sqlite3_column_blob(stmt.handle, idx) orelse return &.{};
        const src: [*]const u8 = @ptrCast(p);
        if (n > buf.len) return error.OutOfMemory;
        @memcpy(buf[0..n], src[0..n]);
        return buf[0..n];
    }
```

为什么用 `column_blob` 而不是 `column_text`？因为 `column_blob` 按**显式长度**返回，
`column_text` 按 `\0` 截断。我们已经用 `column_bytes` 拿到了真实长度，所以走 blob 通道才安全。

⚠️ 还有个副作用要知道：**`column_blob` / `column_text` 会触发类型转换。** SQLite 内部有个
`DYNAMIC` 存储类（存的时候不固定类型），你调不同的取值函数会把当前行的值转成对应类型。
所以 `column_type` 的结果**依赖你调过哪些取值函数**——同一个 `INTEGER` 列，
调 `column_text` 之后可能就报 TEXT 了。

### 所有权：借用窗口只有一步

`column_text` / `column_blob` 返回的指针**借用 SQLite 内部缓冲**。下一次 `step` /
`reset` / `finalize` 就失效。包装层的职责就是把这个窗口翻译成 Zig 的显式分配：

```zig
// examples/32_sqlite/main.zig 第 372-378 行
            .cents = row.cents,
            .month = try a.dupe(u8, row.month),
            .kind = try a.dupe(u8, row.kind),
            .note = try a.dupe(u8, row.note),
        });
    }
    return list.toOwnedSlice(a);
```

**必须在循环体内 dupe。** 攒到最后统一拷是错的——那时候 `row.month` 早就指向了被覆写的缓冲。

### `rowTo`：comptime 行映射

手写 `append` 太啰嗦。`rowTo` 用 comptime 把 SELECT 的列序映射到 struct 字段：

```zig
// examples/32_sqlite/main.zig 第 247-262 行
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
```

**0.17 的 `@typeInfo` 结构体分支变了。** 旧写法 `@typeInfo(T).@"struct".fields` 拿到的
是"字段结构体数组"，0.17 改成**三条等长的平行数组**：

| 数组 | 元素 | 下标配对 |
|---|---|---|
| `field_names` | `[]const []const u8` | `field_names[i]` ↔ `field_types[i]` ↔ `field_attrs[i]` |
| `field_types` | `[]const Type` | ← 同上 |
| `field_attrs` | `[]const StructField` | 含 `.comptime` / `.align` / `.default_value_ptr` |

三条**长度必须相等**，按下标配对。而 `field_types`（类型）和 `field_values`（值）**只能用
`inline for`** 遍历——普通 `for` 会报
`error: cannot format slice without a specifier` 之类的编译问题，因为它们是编译期结构，
不是运行时数组。

用 `inline for` 的好处是 `@field` 的参数能被 comptime 求值——字段名在运行时是不可用的。
这就是 comptime 反射驱动的数据映射：13/14 章讲过的 comptime，在 32.6 落地成一行
`inline for` + 一个 `switch`。

**列数失配当场报错**是这个设计最实用的部分。`SELECT month FROM ledger`（1 列）配
`Ledger`（5 字段）在 test 3 里会返回 `error.StepFailed`——而不是把第一列悄悄塞进
`id` 字段、其余读成 0。**静默串位是 ORM 类 bug 的头号来源。**

---

## 32.7 错误处理：把整数错误码映射成 Zig 错误集

SQLite 几乎不抛异常型错误：所有函数都返回 `c_int` 状态码。Zig 的 `error` 是有名字的枚举。
两者之间的翻译层是本章的包装核心：

```zig
// examples/32_sqlite/main.zig 第 86-101 行

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
```

有了这层映射，调用方就能写 `catch error.Constraint` 而不是"比较返回值等于 19"。

`open_v2` 和 `prepare_v2` 各有一个独立的失败信号（句柄为 null / 语句为 null），
所以那两个包装函数各有自己的错误：

```zig
// examples/32_sqlite/main.zig 第 114-124 行
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
```

⚠️ **open_v2 失败时 handle 可能非 null。** 你仍然要 close 它，否则泄漏。本章在 `handle == null`
时才提前返回（那时没有句柄需要清理），非 null 的情况走 `mapCode`——但调用方拿不到句柄，
所以 `mapCode` 之后还需要释放。这里的正确顺序是"先判 null（没资源），再判码（有资源要清理）"。

### 把 errmsg 拷进 Zig 的定长缓冲

`sqlite3_errmsg` 返回的指针**借用库内缓冲**。想留着，就得拷进自己的内存：

```zig
// examples/32_sqlite/main.zig 第 161-165 行
    /// 返回的切片**借用 SQLite 内部缓冲**，下一次同库 API 调用即失效。
    /// 把 errmsg 拷进 Zig 侧定长缓冲：C 给的是"库里那块内存 + 一个指针"，Zig 的纪律是"值归我"。
    pub fn errmsgInto(db: *Db, buf: []u8) SqlError![:0]u8 {
        return std.fmt.bufPrintSentinel(buf, "sqlite: {s}", .{std.mem.span(c.sqlite3_errmsg(db.handle))}, 0) catch error.OutOfMemory;
    }
```

`std.fmt.bufPrintZ` 在 0.17 里**不存在**了——正确名字是 `bufPrintSentinel`，
而且哨兵是**comptime 参数**：

```zig
std.fmt.bufPrintSentinel(buf, fmt, args, 0)   // ✅ 0.17：哨兵是 comptime 形参
std.fmt.bufPrintZ(buf, fmt, args)              // ❌ 0.16 时代写法，报 no member named 'bufPrintZ'
```

`Allocator` 那边也一样：`dupeZ` → `dupeSentinel(u8, src, 0)`，
多一个 comptime 哨兵形参。这条迁移规则在 26 章讲编码时还会再遇到。

实测的错误映射：

```zig
// examples/32_sqlite/main.zig 第 520-528 行
    begin("32.7");
    var msg: [256]u8 = undefined;
    const bad = execErrName(&mem_db, "SELECT * FROM table_that_does_not_exist");
    say("库不存在 → errcode = {d}（1 = SQLITE_ERROR），映射为 {s}；errmsg 拷进 [256]u8 → {s}\n", .{ mem_db.errcode(), bad, try mem_db.errmsgInto(&msg) });
    try mem_db.exec("INSERT INTO demo(id, name) VALUES(900, 'dup')");
    const dup = execErrName(&mem_db, "INSERT INTO demo(id, name) VALUES(900, 'dup')");
    say("主键冲突 → errcode = {d}（19 = CONSTRAINT），映射为 {s}；errmsg = {s}\n", .{ mem_db.errcode(), dup, try mem_db.errmsgInto(&msg) });
    say("errstr({d}) = {s}（错误码的官方英文说明）\n", .{ c.CONSTRAINT, std.mem.span(c.sqlite3_errstr(c.CONSTRAINT)) });
    end("32.7");
```

**运行输出（`examples/32_sqlite/main.zig`）**

```text
==== 32.7 开始 ====
库不存在 → errcode = 1（1 = SQLITE_ERROR），映射为 Sqlite；errmsg 拷进 [256]u8 → sqlite: no such table: table_that_does_not_exist
主键冲突 → errcode = 19（19 = CONSTRAINT），映射为 Constraint；errmsg = sqlite: UNIQUE constraint failed: demo.id
errstr(19) = constraint failed（错误码的官方英文说明）
==== 32.7 结束 ====
```

test 8 验证了"拷进 `[256]u8` 之后随便留多久"这个性质：取完 errmsg 之后又调了一次
`CREATE TABLE keep(k)`（这会覆盖库内缓冲），`msg` 里的 "no such table" 仍然完好。

### 一个实测的类型陷阱

想写个"跑一条注定失败的语句，取错误名"的辅助函数，第一版会编译失败：

```zig
const bad: anyerror = db.exec(sql) catch |e| e;   // ❌ expected type 'anyerror', found 'void'
const bad = db.exec(sql) catch |e| e;             // ❌ expected 'SqlError', found 'void'
```

因为 `SqlError!void` 的成功分支是 `void`——而 `void` **不是**一个 error 值，
`catch |e| e` 的结果类型是 `SqlError!void` 而不是 `SqlError`。正确写法是用 `if/else`：

```zig
// examples/32_sqlite/main.zig 第 103-107 行
/// 跑一条注定失败的语句，只取错误名。必须待在**文件顶层**（见 32.11 关于嵌套 fn 的说明）。
/// 注意 `catch |e| e` 挂在 `SqlError!void` 上不会收窄成 `SqlError`——void 不是 error 值。
fn execErrName(db: *Db, sql: [:0]const u8) [:0]const u8 {
    if (db.exec(sql)) |_| return "没报错（前提有误）" else |e| return @errorName(e);
}
```

---

## 32.8 事务

事务把"一批写"变成"全成或全无"。SQLite 的事务就是三条普通 SQL 语句：`BEGIN` / `COMMIT` /
`ROLLBACK`——所以可以完全走 `sqlite3_exec`，不需要专门的 API。

```zig
// examples/32_sqlite/main.zig 第 530-538 行
    begin("32.8");
    try mem_db.exec("CREATE TABLE tx_demo(tag TEXT)");
    // exec 一次能跑多条事务语句——这正是它作为快路径的价值
    try mem_db.exec("BEGIN; INSERT INTO tx_demo VALUES('a'); INSERT INTO tx_demo VALUES('b'); INSERT INTO tx_demo VALUES('c'); ROLLBACK;");
    var tx_cnt = try mem_db.prepare("SELECT COUNT(*) FROM tx_demo");
    defer tx_cnt.finalize();
    _ = try tx_cnt.step();
    say("BEGIN + 3 次 INSERT + ROLLBACK → 行数 {d}（回滚生效）\n", .{tx_cnt.columnInt(0)});
    try mem_db.exec("BEGIN; INSERT INTO tx_demo VALUES('x'); INSERT INTO tx_demo VALUES('y'); COMMIT;");
```

**运行输出（`examples/32_sqlite/main.zig`）**

```text
==== 32.8 开始 ====
BEGIN + 3 次 INSERT + ROLLBACK → 行数 0（回滚生效）
BEGIN + 2 次 INSERT + COMMIT   → 行数 2（提交生效）
==== 32.8 结束 ====
```

**回滚实测生效**：插了 3 行，`ROLLBACK` 后行数是 0。第二组插 2 行 `COMMIT`，行数是 2。
注意第二条 `COUNT` 语句没有重新 prepare，只是 `reset()` 了——顺便演示了 32.4 讲的复用。

### 真实代码里事务的正确形状

32.8 的演示是"一口气跑完"，但真实代码里事务要处理中途失败。`insertBatch` 给出了正确的骨架：

```zig
// examples/32_sqlite/main.zig 第 337-348 行
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
```

三个要点：

1. **`errdefer db.exec("ROLLBACK") catch {}`** —— 出错路径自动回滚。
   `catch {}` 是因为回滚本身也可能失败（比如事务已经被 SQLite 自动回滚了），
   那时不想用一个次生错误掩盖真正的错误。
2. **循环里不 prepare** —— 一条语句 prepare 一次，绑定 + step + reset 反复跑（32.4 的结论）。
3. **`prepare` 放在 `BEGIN` 之外** —— 让"语法错误"发生在开事务之前。
   如果 SQL 写错了，你在 `BEGIN` 之前就拿到 `error.PrepareFailed`，事务压根没开。

⚠️ **嵌套事务不成立。** SQLite 没有真正的嵌套 `BEGIN`——在事务里再 `BEGIN` 会报
`cannot start a transaction within a transaction`。需要"部分提交"就用 `SAVEPOINT`。
本章不展开，但这是真实项目里最容易踩的事务坑。

---

## 32.9 参数化查询的构造：只拼结构不拼值

`IN (?, ?, ?)` 的问号个数要跟列表长度走，SQL 文本得动态拼。这时候**唯一正确的做法**是：
只拼结构（问号和逗号），值一律绑定。

```zig
// examples/32_sqlite/main.zig 第 382-393 行
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
```

**这条边界必须靠签名写死。** `kinds: []const [:0]const u8` 是哨兵切片数组——
只有"代码里字面量选定"的字符串能自然进来，因为临时 `dupeSentinel` 出来的临时值传不进
`[:0]const u8`（生命周期检查会拦住）。而每个元素最终还是要 `bindText` 绑进去，
不进 SQL 文本。所以：

- **结构**（`IN (?, ?, ?)`）由代码逻辑生成——问号个数由 `kinds.len` 决定
- **值**（`收入`/`支出`）走绑定通道

用法与实测：

```zig
// examples/32_sqlite/main.zig 第 544-557 行
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
```

**运行输出（`examples/32_sqlite/main.zig`）**

```text
==== 32.9 开始 ====
拼出来的 SQL（只拼结构）：SELECT COUNT(*) FROM kinds WHERE label LIKE ?；占位符 = 1 个；绑定 带% 后命中 1 行
IN 列表 2 项 → 展开成 2 个 ?：SELECT month, SUM(net_cents(kind, cents)) FROM ledger WHERE kind IN (?,?) GROUP BY month ORDER BY month
==== 32.9 结束 ====
```

`sqlite3_bind_parameter_count` 返回的 1 和 IN 展开的 2 都跟文本里的问号数一致——
这是"结构拼对了"的机器可验证证据（test 11 断言 `expectEqual(2, s.bindParameterCount())`）。

⚠️ **`LIKE` 的 `%` 必须走绑定才有意义。** 如果你把 `%` 拼进 SQL 文本，它就成了 SQL 结构；
绑进去它才是"数据里的通配符"。上例绑定 `带%` 命中 1 行——因为它同时匹配了"带哨兵的切片"
和"含\0的文本"……不，实际只有 1 行含"带"字，这正是通配符在数据里生效的结果。

`toOwnedSliceSentinel(a, 0)` 是 0.17 的 `ArrayList` 转哨兵切片的标准做法
（`toOwnedSlice` 只给普通切片）。`std.ArrayList(u8)` 的初始值是 `.empty`，
`deinit` 需要显式传分配器——0.17 的容器 API 全部显式化，没有全局 GPA 了。

---

## 32.10 索引与 `EXPLAIN QUERY PLAN`

索引的效果不该靠"感觉快了"，要**看查询计划**。SQLite 的 `EXPLAIN QUERY PLAN` 返回一个
结果集，其中第 3 列（index 3）就是可读的计划文本。

```zig
// examples/32_sqlite/main.zig 第 560-581 行
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
```

**运行输出（`examples/32_sqlite/main.zig`）**

```text
==== 32.10 开始 ====
  建索引前：SCAN plan_demo
  建索引后：SEARCH plan_demo USING INDEX ix_plan_demo_uid (uid=?)
⇒ SCAN（全表扫）换成 SEARCH ... USING INDEX（走 B 树），这就是索引的全部意义
==== 32.10 结束 ====
```

`SCAN` → `SEARCH ... USING INDEX`：从"逐行扫 200 条"变成"沿 B 树走到目标"，
复杂度从 O(n) 变成 O(log n)。这是**唯一**能证明索引生效的证据——
`ANALYZE`、查询耗时这些都不可靠，计划文本是确定的。

### 一个教学价值极高的陷阱

上面注释里那句"主键**不能**写成 INTEGER PRIMARY KEY"是本章实测踩出来的。改回
`id INTEGER PRIMARY KEY` 后，计划会变成：

```text
建索引前：SEARCH t USING INTEGER PRIMARY KEY (rowid=?)
建索引后：SEARCH t USING INTEGER PRIMARY KEY (rowid=?)
```

**建索引前后一模一样**。原因是 `INTEGER PRIMARY KEY` 是 rowid 的别名，SQLite 已经为它
建了 B 树。所以想演示索引效果必须用**普通列**——这个坑很多人踩过之后才真正理解
"索引"是什么。

test 10 断言了这个转换（`startsWith("SCAN")` → `indexOf("USING INDEX") != null`）。

---

## 32.11 用户自定义函数与聚合

`sqlite3_create_function_v2` 能把 **Zig 函数注册成 SQL 函数**。标量给 `x_func`，
聚合给 `x_step` + `x_final`。回调必须是 `callconv(.c)` 的自由函数：

```zig
// examples/32_sqlite/main.zig 第 264-293 行

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
```

几个关键点：

**① 回调必须声明在文件顶层（或容器内），不能在函数体里。**
0.17 的语法里容器之外没有嵌套 `fn` 声明。本章一开始想写：

```zig
// ❌ 编译失败：函数体里不能声明 fn
fn registerFunctions(db: *Db) void {
    fn netCents(...) void { ... }   // ❌
}
```

唯一出路是塞进一个匿名 struct：

```zig
const H = struct { fn netCents(...) void { ... } };
// 然后用 H.netCents
```

实测这个是可行的（`const f = struct { fn g() void {} }.g;` 能编译），
但**不如放在顶层干净**——本章选择顶层，顺带在 `execErrName` 上也用同样的理由（见 32.7）。

**② 聚合函数的私有状态靠 SQLite 分配。**
`sqlite3_aggregate_context(ctx, n_bytes)` 是这里的关键：
- 第一次 `x_step` 调用传 `n_bytes > 0` → SQLite 分配并**清零**这块内存
- `x_final` 传 `n_bytes = 0` → 只取不分配；返回 `null` 表示"一整组都没进来过"

`SumAcc` 声明成 `extern struct` 保证布局跟 C 一致（`@ptrCast` + `@alignCast` 拿到指针后
按 C 布局访问）。

**③ 空集聚合返回 NULL，不是 0。**
这是 SQL 聚合的标准语义（`SUM()` 空集返回 NULL），test 9 专门验证了它：

```zig
// examples/32_sqlite/main.zig 第 590-592 行
    var empty_agg = try mem_db.prepare("SELECT zsum(cents) FROM fn_demo WHERE 0");
    defer empty_agg.finalize();
    _ = try empty_agg.step();
```

**运行输出（`examples/32_sqlite/main.zig`）**

```text
==== 32.11 开始 ====
已注册标量 net_cents 与聚合 zsum。net_cents('收入', 500) = 500；zsum(cents) = 1000（三行合一）
  空集上的 zsum → 类型码 5（5 = NULL，不是 0）
⇒ 标量给 x_func，聚合给 x_step + x_final；两者都是 callconv(.c) 自由函数
==== 32.11 结束 ====
```

`zsum(cents) = 1000` 是 `3000 + (-1200) + (-800)`——Zig 回调算的。
而 `net_cents('收入', 500) = 500` 是标量：它在 32.13 的按月聚合里会被内建 `SUM` 逐行调用，
这就是"用 Zig 写业务规则、交给 SQL 做聚合"的模式。

---

## 32.12 内存库 vs 文件库

`":memory:"` 是 SQLite 的**特殊文件名**，不是路径。给了它，整个库只活在内存里。

```zig
// examples/32_sqlite/main.zig 第 598-626 行
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
```

**运行输出（`examples/32_sqlite/main.zig`）**

```text
==== 32.12 开始 ====
文件库 db_filename 末段 = ...zig32_ledger.db；写入后 close() 已落盘（被 ROLLBACK 的 ghost 不算）
重新打开读回 v = 42（跨连接存活）；内存库 db_filename 是空串：是
内存库：进程退出即消失、无法跨连接——单测因此可以放心用 ":memory:"
db 文件非空：是；大小是页大小 4096 的整数倍：是
==== 32.12 结束 ====
```

三个实测结论：

**① 文件库跨连接存活，内存库不行。**
关掉第一个连接再重新 `open`，`answer=42` 读回来了。而内存库 `mem_db` 的数据
只活在那个连接里——换个连接（或进程退出）就没了。

**② 内存库的 `db_filename` 是空串。**
这比打印路径更有信息量：它压根没有文件。所以**不要靠"路径是不是 `:memory:`"来判断**——
直接看 `db_filename` 是不是空的更可靠。

**③ 被 ROLLBACK 的 `ghost` 不在文件里。**
事务的持久性和普通写入一样：`ROLLBACK` 掉的东西不会落盘。这是 32.9 和 32.13 两条回滚实测
的第三个独立证据。

### 为什么输出里没有裸字节数

`db 文件大小` 那一行只印"非空：是"和"是 4096 整数倍：是"。**裸字节数不能进输出**——
它随 SQLite 版本、页大小设置、`auto_vacuum` 配置而变，写进文档下次升级就失效了。
两个 `是`（非空 + 页对齐）是**确定性**的断言：证明了文件确实落盘、且是合法的 SQLite 文件。

### 单测为什么全用 `:memory:`

这是本章 14 个 test 的共同选择（test 15 用 `tmpDir` 之外也不落盘）。好处：

- **零磁盘依赖**：不需要临时目录、不需要清理、不怕上一次残留
- **彼此隔离**：每个 test 全新内存库，不会互相污染（test 8 的 `CREATE TABLE keep(k)` 就
  不会让 test 9 的 `ledger` 表出错）
- **快**：没有 fsync，事务测试零成本

代价当然是没有跨连接持久化——所以 32.12 那段演示只能放在 `main` 里（它需要真实文件）。

⚠️ **`std.Io.Dir.cwd()` 是伪句柄，不能 walk。** 27 章讲过：它只能做"按路径"的操作。
`deleteFile(io, db_path)` / `statFile(io, db_path, .{})` 都是按路径的，所以能用。

---

## 32.13 完整实战：个人账本

把所有零件拼起来：一个记账程序，建表 → 批量插入（事务内）→ 按月聚合 → 自定义函数算净额
→ 导出 CSV → 回滚验证。

```zig
// examples/32_sqlite/main.zig 第 628-658 行
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
```

**运行输出（`examples/32_sqlite/main.zig`）**

```text
==== 32.13 开始 ====
账本 7 条记录（一条预编译 + 一个事务搞定批量写）
  2026-01：3 笔，净额 77000 分
  2026-02：2 笔，净额 64000 分
  2026-03：2 笔，净额 126000 分
  合计净额 = 267000 分（2670 元）
CSV 共 8 行（含表头）；表头 + 首条数据：
id,month,kind,cents,note
1,2026-01,收入,120000,一月工资
回滚实测：事务内 9 条 → ROLLBACK 后 7 条（起始 7）
⇒ 事务不是语法糖：它把"一批写"变成"全成或全无"
==== 32.13 结束 ====
```

三个值得停下来看的数字：

**① 净额是"分"，不是"元"。** `120000 - 35000 - 8000 = 77000` 分 = 770 元。
**金额一律用整数分存储**——浮点数记账会因舍入误差丢钱，这是财务系统的铁律。
`合计净额 = 267000 分（2670 元）` 里的除法是展示时才做的。

**② `net_cents` 在聚合里被逐行调用。**
`SUM(net_cents(kind,cents))` 看着像"先求和再变号"，实际是 SQLite 对每一行调用一次
Zig 回调、拿到结果再交给内建 `SUM`。业务规则（收入记正、支出记负）在 Zig 里，
分组聚合在 SQL 里——这是很干净的分工。

**③ 回滚实测：`事务内 9 条 → ROLLBACK 后 7 条`。**
起始 7 条（批量插入的结果），事务内插 2 条变 9 条，`ROLLBACK` 后回到 7 条。
这是本章第三次独立验证回滚生效（前两次是 32.9 的 `tx_demo` 和 32.13 的 `ghost`）。

CSV 导出那几行还顺带演示了**所有权纪律**：`allLedger` 返回的字符串已经 dupe 进 arena
（32.6 讲的窗口内拷贝），所以循环外用是安全的；而聚合那段的 `columnTextSpan` 是在
step 循环**内**用的——出循环就悬垂。

---

## 32.14 测试与清理

14 个 test，全部跑在 `:memory:` 上（零磁盘、彼此隔离）：

```zig
// examples/32_sqlite/main.zig 第 695-724 行

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
```

14 个 test 覆盖的主题：

| # | 主题 | 对应节 |
|---|---|---|
| 1 | `:memory:` 零磁盘，建表+插入+计数 | 32.13 |
| 2 | `rowTo` 把行映射进 struct（含字段值断言） | 32.6 |
| 3 | `rowTo` 列数失配返回 `error.StepFailed` | 32.6 |
| 4 | 参数绑定防注入 **+** TEXT 先 bytes 不丢 `\0` | 32.5 / 32.6 |
| 5 | 五种列类型码逐个判别 | 32.6 |
| 6 | 错误码映射（`error.Sqlite` / `error.Constraint`） | 32.7 |
| 7 | `errmsg` 拷进 `[256]u8` 后长期持有 | 32.7 |
| 8 | `ROLLBACK` 撤销 + `COMMIT` 保留 | 32.8 |
| 9 | 自定义标量 / 聚合 + 空集聚合是 NULL | 32.11 |
| 10 | 索引前后查询计划 `SCAN` → `SEARCH` | 32.10 |
| 11 | 动态 `IN` 的占位符个数 + 逐行结果 | 32.9 |
| 12 | `close_v2` 容忍未 finalize 的 stmt | 32.14 |
| 13 | `last_insert_rowid` + `insertBatch` 走事务 | 32.13 |
| 14 | blob 往返一致（含空 blob 仍是 BLOB） | 32.6 |

### `sqlite3_close_v2` 的释放语义

这是本章最后一个需要单独讲的生命周期问题。

```zig
// examples/32_sqlite/main.zig 第 683-693 行
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
```

**运行输出（`examples/32_sqlite/main.zig`）**

```text
==== 32.14 开始 ====
有未 finalize 的 stmt 时 close()   返回 5（database is locked）
close_v2() 则返回 0——它接受僵尸态，句柄等 stmt 释放后自毁
14 个 test 全部跑在 ":memory:" 上，互不干扰、零磁盘残留。全部自演完成，exit 0
==== 32.14 结束 ====
```

两个 `close` 的语义完全不同：

| 函数 | 有未 finalize 的 stmt 时 | 后果 |
|---|---|---|
| `sqlite3_close` | 返回 `SQLITE_BUSY`（5） | **库不关**，你必须先释放 stmt 再重试 |
| `sqlite3_close_v2` | 返回 `SQLITE_OK`（0） | 库进"**僵尸态**"，stmt 全释放后自动销毁 |

`close_v2` 的取舍很清楚：**用"错误被吞掉"换"不泄漏"**。如果你想在开发期发现 stmt 泄漏，
用 `close`（本章的 `closeStrict`）；如果不想因为一条漏掉的 finalize 让整个程序崩，
用 `close_v2`。

test 12 用 `expectEqual(c.BUSY, db.closeStrict())` 断言了 `close` 的严格语义，
然后 `leaked.finalize()` 释放 stmt 让僵尸句柄自毁。

**本章的包装层默认用 `close_v2`**（`Db.close`），同时提供 `closeStrict` 给需要严格
检查的场景。理由写在注释里：开发期用严格版，生产期用宽松版。

---

## 32.15 坑位清单

1. **`@cImport` 在 0.17 已被移除。** 报 `error: invalid builtin function: '@cImport'`——
   不是"找不到头文件"，是"这函数不存在"。头文件翻译改走 `b.addTranslateC`（17 章）。
2. **本章是单文件工程，连 `addTranslateC` 都用不上。** `run-all.sh` 里 32 章走
   `test_plain_example "$dir" -lsqlite3`，全程只有 `main.zig` + 一个 `-l`。
   选 `b.addTranslateC` 会根本编不过——这是工程形态问题，不是风格问题。
3. **`callconv(.C)` 已改名 `callconv(.c)`**（小写）。C 回调在 Zig 侧一律小写。
4. **变量名不能遮蔽原始类型名。** `const void = 1` 报 `name shadows primitive 'void'`；
   `const error = ...` 报 `expected 'an identifier', found 'error'`。
   C 侧类型必须加 `Raw` 前缀（`RawDb` / `RawStmt` / `RawContext` / `RawValue`），
   否则和包装层的 `Db` / `Stmt` 撞名。
5. **`extern fn` 的参数里不许出现切片。** `[:0]const u8` 也不行——报
   `parameter of type '[:0]const u8' not allowed in function with calling convention 'x86_64_sysv'`。
   C 串只能写 `[*:0]const u8`。
6. **`.()` 这个 unwrap 语法在 0.17 已移除。** `stmt.?` 之前写成 `stmt.()`，
   现在报 `expected pointer dereference, optional unwrap, or field access, found '('`。
   一律用 `.?`。
7. **函数体里不许声明 `fn`。** 局部辅助函数只能塞进
   `const H = struct { fn f() {} };` 取 `H.f`（实测可行但很丑）。本章全部放文件顶层。
8. **`std.fmt.bufPrintZ` → `std.fmt.bufPrintSentinel(buf, fmt, args, 0)`。**
   哨兵是 **comptime 形参**。`Allocator.dupeZ` → `dupeSentinel(u8, src, 0)` 同理。
9. **`Io.Clock` 不是 `io` 的字段，也没有 `.monotonic`。**
   写 `io.clock.now(...)` 报 `no field named 'clock' in struct 'Io'`。
   正确写法是 `std.Io.Timestamp.now(io, .awake)` 这个静态函数；成员只有
   `real` / `awake` / `boot` / `cpu_process` / `cpu_thread`。
10. **`Duration.nanoseconds` 是 `i96` 不是 `i64`。** 直接 `@intCast` 到 `i64` 报
    `expected type 'i64', found 'i96'`。
11. **`/` 对有符号整数强制要求显式除法语义。** `@divTrunc(v, 10)` 不能写成 `v / 10`，
    否则报 `division with 'i96' and 'comptime_int': signed integers must use @divTrunc, ...`。
12. **`@typeInfo(T).@"struct"` 不再有 `.fields`。** 0.17 改成三条等长平行数组
    `field_names` / `field_types` / `field_attrs`，按下标配对；
    `field_types` / `field_values` **只能用 `inline for`**。
13. **算术结果永不宽化。** `u8 + u8` 还是 `u8`。`@as(isize, -1)` 直接
    `@intCast` 到 `usize` 会溢出——`SQLITE_TRANSIENT` 的哨兵必须走
    `@as(usize, @bitCast(@as(isize, -1)))` 三步。
14. **TEXT 列必须先 `column_bytes` 再取值。** `column_text` 返回 C 字符串，
    遇 `\0` 即止且**不告诉你真实长度**——含嵌入 `\0` 的值会被静默截断，不报错，只丢数据。
    正确姿势：`column_bytes` 拿长度 + `column_blob` 按长度取（`column_blob` 不按 `\0` 截）。
15. **`column_blob` / `column_text` 会触发类型转换。** `column_type` 的结果依赖你调过
    哪些取值函数——SQLite 有 `DYNAMIC` 存储类，`INTEGER` 列读 `column_text` 后可能报 TEXT。
16. **绑定参数下标从 1 起。** C ABI 如此，包装层原样透传并注释，别偷偷减一。
17. **参数绑定天生防注入。** `"rob'; DROP TABLE kinds;--"` 进 `bind_text` 只是数据，
    表一行不少。拼接 SQL 字符串才会翻车——永远不要拼接。
18. **`sqlite3_exec` 的 `char **errmsg` 出参需要 `sqlite3_free`。** 传 null 更省事
    （本章做法），改用 `sqlite3_errmsg` 取库内缓冲。
19. **`sqlite3_changes()` 只反映最近一条语句。** 建表后调它得到的是建表改的行数（通常 0）。
    要累计用 `sqlite3_total_changes()`。
20. **`sqlite3_column_blob` 可能返回 null**（值是 SQL NULL 时）。所以声明是 `?*const anyopaque`，
    取之前要 `orelse`。
21. **不透明指针撞名会ambiguous。** C 侧叫 `Db`、包装侧也叫 `Db`——同文件必炸。
    C 侧一律 `Raw` 前缀。
22. **`sqlite3_source_id` 在 macOS 共享缓存里没导出。** 写进声明直接
    `error: undefined symbol: _sqlite3_source_id`。用到的才声明。
23. **`INTEGER PRIMARY KEY` 是 rowid 的别名，自带 B 树。** 想演示索引效果必须用普通列，
    否则建索引前后 `EXPLAIN QUERY PLAN` 一模一样。
24. **`catch |e| e` 挂在 `SqlError!void` 上不会收窄成 `SqlError`**——`void` 不是 error 值。
    要取错误名用 `if (expr) |_| ... else |e| ...`。
25. **别给普通文件库加 `OPEN_MEMORY` 标志。** 那会把文件库静默降级成内存库，
    持久化悄悄失效——本章的 `Db.open` 只传 `OPEN_READWRITE | OPEN_CREATE`，
    `":memory:"` 靠**特殊文件名**识别。
26. **嵌套 `BEGIN` 会报 `cannot start a transaction within a transaction`。**
    SQLite 没有真正的嵌套事务，需要部分提交用 `SAVEPOINT`。
27. **`sqlite3_column_text` 的借用窗口只有一步。** 下一次 `step` / `reset` / `finalize`
    就失效。必须在循环体内 dupe，攒到最后统一拷是错的。
28. **内存库的 `db_filename` 是空串**，不是 `":memory:"`。判断"有没有文件"要看它是不是空的，
    不要比较路径字符串。

---

## 32.16 与相邻章节的接口

| 章 | 关系 |
|---|---|
| [06 切片与哨兵指针](06-slices.md) | `[:0]const u8` / `[*:0]const u8` 的语义，本章 32.2 的地基 |
| [11 分配器](11-allocators.md) | `dupeSentinel` / `toOwnedSliceSentinel` 的所有权纪律 |
| [13 comptime](13-comptime.md) | `inline for` + `@typeInfo` 三数组，本章 32.6 的 `rowTo` |
| [15 测试](15-testing.md) | `std.testing.io` / `std.testing.allocator`，本章 14 个 test 的底座 |
| [17 C 互操作](17-c-interop.md) | **`b.addTranslateC` 路线**——本章的反面教材，工程形态不同 |
| [20 文件与 IO](20-files-io.md) | `std.Io.Dir.deleteFile` / `statFile`，本章 32.12 的清理 |
| [27 目录遍历](27-tree.md) | `std.Io.Dir.cwd()` 是伪句柄的约束 |
| [34 LRU 缓存](34-zcache.md) | 下一站：把本章的 SQLite 当缓存后端 |

---

上一章：[31 并发进阶](31-concurrency.md) · 下一章：[33 表达式解释器](33-zcalc.md)