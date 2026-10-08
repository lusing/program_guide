# 27 · 目录遍历与文件树

> 对应示例：`examples/27_tree/main.zig`（1365 行，14 个 test）
>
> 20 章讲了"怎么读写一个文件"，本章讲"怎么把一棵目录树走完"。0.17 把
> `std.fs.Dir` 并进了 `std.Io`，于是 20 章那张签名表里跟遍历有关的那几行
> **全部要重新实测**：本章把 `openDir` / `iterate` / `walk` / `walkSelectively` /
> `Dir.Reader` / `statFile` 逐个编译验证，做成 27.1.3 的实测签名表。
>
> 本章有**六条结论会推翻你可能听过的说法**：
>
> 1. **`entry.name` 活不过下一次 `next()`**。实测 60 个条目的目录里，不 `dupe`
>    收集出来的 60 个切片**内容有重复**、拿去 `access` **有的直接 FileNotFound**。
>    小目录一次读完看起来"没事"，那才是真正的陷阱。
> 2. **`if (errUnion) |x|` 在 0.17 只解包错误层**。`if (it.next(io)) |x|` 里的
>    `x` 实测类型仍是 `?Io.Dir.Entry`，直接 `x.name` 编译报
>    `optional type '?Io.Dir.Entry' does not support field access`。
>    正确写法是 `while (try it.next(io)) |entry|`（一次解两层）或 `if (try …) |e|`。
> 3. **`follow_symlinks` 的类型是 `bool`，不是联合字面量**。grep 整个标准库，
>    `follow_symlinks` 一律是 `bool`，没有任何 `{ true: ..., false: ... }` 版本。
> 4. **⚠️ `cwd()` 是伪句柄（`AT_FDCWD` = -2）**。`cwd().walk(gpa)` **不报错**，
>    但第一次 `next(io)` 直接 panic：`programmer bug caused syscall error: BADF`。
>    `walk` / `stat` / `iterate` / `close` 全都必须先 `openDir`。
> 5. **`walk` 天生不跟符号链接**（源码里只有 `kind == .directory` 才 `enter`），
>    所以 `walk` **天然防环**；但**手写递归**写成"lstat 是目录就进"就会无限套娃。
> 6. **`Dir.Reader` 的缓冲必须 `align(@alignOf(usize))`**。普通 `[N]u8` 传不进去：
>    `expected type '[]align(8) u8', found '*[1048]u8'`。
>
> 本章示例的所有输出都来自 `main` 自己建的一棵**确定小树**（建在系统临时目录
> `/tmp/zig27_tree_demo`，退出前 `deleteTree` 回收），所以**逐字节可复现**——
> 连跑两次 `diff` 为空。仓库里不留任何临时目录。
>
> ⚠️ **运行输出的平台口径**：正文里的运行输出大多采集自 macOS/POSIX（`handle=-2`、
> `nlink=2`、一次 `read` 拿 11 个……）。示例现在在 Windows 上也全绿，凡 Windows
> 行为不同的地方（伪句柄数值、hardLink、`Permissions.fromMode`、Reader 批量大小、
> 路径分隔符）都有 `comptime` 分平台 + 坑位清单第 19-21 条的专门说明。

---

## 27.0 先把沙盒搭起来：让输出可复现

讲目录遍历最容易犯的错是"示例遍历了真实目录"，于是输出里全是路径、时间戳、
inode、字节数——文档里的运行输出永远对不上。27 章的做法是：**自己造一棵形状固定的树**。

```zig
// examples/27_tree/main.zig 第 254-271 行
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
```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.0 开始 ====
沙盒 /tmp/zig27_tree_demo：4 个文件 + 3 个目录（empty 是空的）=7 个条目
⚠️ 27 章所有输出都来自这棵自建树 ⇒ 逐字节确定，不受仓库内容影响
⚠️ 建在系统临时目录而不是 cwd：示例从仓库根运行（run-all.sh 的约定）
==== 27.0 结束 ====
```

三个设计决定值得抄：

1. **建在 `/tmp` 而不是 `cwd`**。`run-all.sh` / `build.ps1` 的约定是**从仓库根运行 exe**
   （20 章坑位 5 提过），所以 `cwd` 里有 `docs/` `examples/` `build/` 等一堆既有目录。
   在 `cwd` 里造沙盒要么撞名，要么污染仓库。
2. **先 `deleteTree` 再建**（第 256 行）。程序上次崩溃会留残留，这次启动撞同名会
   `error.PathAlreadyExists`。这条只适合单实例；并发运行请用 20.13.2 说的随机名。
3. **`defer deleteTree`**（第 257 行）。清理失败不该让程序失败，所以 `catch {}`——
   这是 20 章坑位 16 说的"清理路径可以静默"的唯一合法场景。

**注意 `/tmp` 也不是绝对安全的**：多用户系统上 `/tmp/zig27_tree_demo` 可能被别人
抢先创建。生产代码要用 `std.testing.tmpDir` 的随机 16 字符名（20.13.1）；
示例里用固定名是为了让文档输出可复现——**这两个目标冲突，示例选了可复现**。

## 27.1 四种遍历方式与实测签名表

### 27.1.1 先建立选择依据

```zig
// examples/27_tree/main.zig 第 274-281 行
    begin("27.1");
    std.debug.print("方式一 iterate()          只管当前一层，递归自己写（可控、可剪枝、要管 fd）\n", .{});
    std.debug.print("方式二 walk()             库写好的递归，返回带完整相对路径的条目（省心，要 gpa）\n", .{});
    std.debug.print("方式三 walkSelectively()  像 walk，但进哪一层由你逐个决定（enter / leave）\n", .{});
    std.debug.print("方式四 Dir.Reader         批量 read()，自己给缓冲，系统调用最少\n", .{});
    std.debug.print("前三种的 next 都要 io；只有 walk / walkSelectively 的**第一个参数是 gpa（不是 io）**\n", .{});
    std.debug.print("iterate() 不带 io（纯计算，造个 Iterator 结构体），next(io) 才带 —— 不对称设计\n", .{});
    end("27.1");
```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.1 开始 ====
方式一 iterate()          只管当前一层，递归自己写（可控、可剪枝、要管 fd）
方式二 walk()             库写好的递归，返回带完整相对路径的条目（省心，要 gpa）
方式三 walkSelectively()  像 walk，但进哪一层由你逐个决定（enter / leave）
方式四 Dir.Reader         批量 read()，自己给缓冲，系统调用最少
前三种的 next 都要 io；只有 walk / walkSelectively 的**第一个参数是 gpa（不是 io）**
iterate() 不带 io（纯计算，造个 Iterator 结构体），next(io) 才带 —— 不对称设计
==== 27.1 结束 ====
```

选择表：

```text
| 你要什么 | 用哪个 | 代价 |
|---|---|---|
| 当前一层的条目 | `iterate()` | 自己管 fd 和递归 |
| 整棵子树，不要剪枝 | `walk(gpa)` | 分配 name_buffer；顺序未定义 |
| 整棵子树，但要跳过某些分支（node_modules/.git） | `walkSelectively(gpa)` | 自己判断 enter/leave |
| 上万条目，要压系统调用 | `Dir.Reader` | 自己给对齐缓冲 |
| 只要一个汇总数字（du/ 找最大/ 数文件） | `walk` 流式 | **不要建树**，见 27.13 |
```

**`iterate()` 不带 `io` 但 `next(io)` 带**，这是 0.17 的不对称设计（20 章坑位 12 已记）：
`iterate` 纯计算（造个 `Iterator` 结构体），`next` 才真正读目录。所以你会看到
`var it = d.iterate();`（**没有 `try`**）然后 `try it.next(io)`。

### 27.1.2 一次 `openDir` 的完整三步

```zig
// examples/27_tree/main.zig 第 391-394 行
            var d = try cwd.openDir(io, sbox, .{ .iterate = true });
            defer d.close(io);
            var w = try d.walk(a);
            defer w.deinit();
```text
| 行 | 为什么 |
|---|---|
| `openDir(io, path, .{ .iterate = true })` | `.iterate` 必须在**打开时**开；Windows 上不开会在**迭代时**才报 AccessDenied |
| `defer d.close(io)` | `Dir` 是 fd，不 close 就是泄漏 |
| `try d.walk(a)` | `walk` 要分配器（`Allocator.Error!Walker`），不是 io |
| `defer w.deinit()` | `Walker` 的栈上压着若干 `openDir` 出来的 `Dir`，不 deinit 全部泄漏 |
```

### 27.1.3 ⚠️ 全部遍历相关签名实测表（0.17.0）

这张表是本章的**核心资产**，全部来自 `lib/std/Io/Dir.zig` 源码 + 探针编译验证。

```text
| 方法 | 签名 | `io` 在第几参 | `gpa` 在第几参 |
|---|---|---|---|
| `cwd` | `cwd() Dir` | 无（纯计算，handle = -2 = AT_FDCWD） | — |
| `openDir` | `(io: Io, sub_path: []const u8, options: OpenOptions) OpenError!Dir` | **1** | — |
| `close` | `(io: Io) void` | 1 | — |
| `iterate` | `iterate(dir: Dir) Iterator` | **无** | — |
| `iterateAssumeFirstIteration` | `(dir: Dir) Iterator` | 无 | — |
| `Iterator.next` | `(it: *Iterator, io: Io) Error!?Entry` | 1 | — |
| **`walk`** | `(dir: Dir, allocator: Allocator) Allocator.Error!Walker` | **无** | **1** ⚠️ |
| `walkSelectively` | `(dir: Dir, allocator: Allocator) !SelectiveWalker` | 无 | 1 |
| `Walker.next` | `(self: *Walker, io: Io) !?Walker.Entry` | 1 | — |
| `Walker.leave` | `(self: *Walker, io: Io) void` | 1 | — |
| `SelectiveWalker.next` | `(self: *SelectiveWalker, io: Io) Error!?Walker.Entry` | 1 | — |
| `SelectiveWalker.enter` | `(self: *SelectiveWalker, io: Io, entry: Walker.Entry) !void` | 1 | — |
| `SelectiveWalker.leave` | `(self: *SelectiveWalker, io: Io) void` | 1 | — |
| `Walker.deinit` / `SelectiveWalker.deinit` | `() void` | 无 | — |
| `Dir.Reader.init` | `(dir: Dir, buffer: []align(usize) u8) Reader` | 无 | — |
| `Dir.Reader.read` | `(r: *Reader, io: Io, buffer: []Entry) Error!usize` | 1 | — |
| `Dir.Reader.next` | `(r: *Reader, io: Io) Error!?Entry` | 1 | — |
| `Dir.Reader.reset` | `(r: *Reader) void` | 无 | — |
| `stat` | `(dir: Dir, io: Io) StatError!Stat`（⚠️ 对 `cwd()` panic，见 27.9） | 1 | — |
| `statFile` | `(dir: Dir, io: Io, sub_path, options: StatFileOptions) StatFileError!Stat` | 1 | — |
| `createDir` | `(dir, io, sub_path, permissions: Permissions) CreateDirError!void`（单层） | 1 | — |
| `createDirPath` | `(dir, io, sub_path) CreateDirPathError!void`（递归，旧名 `makePath`） | 1 | — |
| `createDirPathStatus` | `(dir, io, sub_path, permissions) CreateDirPathError!CreatePathStatus` | 1 | — |
| `createDirPathOpen` | `(dir, io, sub_path, options: CreateDirPathOpenOptions) CreateDirPathOpenError!Dir` | 1 | — |
| `deleteFile` | `(dir, io, sub_path) DeleteFileError!void` | 1 | — |
| `deleteDir` | `(dir, io, sub_path) DeleteDirError!void`（非空报 `DirNotEmpty`） | 1 | — |
| `deleteTree` | `(dir, io, sub_path) DeleteTreeError!void`（递归） | 1 | — |
| `deleteTreeMinStackSize` | `(dir, io, sub_path) DeleteTreeError!void`（深目录省栈） | 1 | — |
| `access` | `(dir, io, sub_path, options: AccessOptions) AccessError!void` | 1 | — |
| `readLink` | `(dir, io, sub_path, buffer: []u8) ReadLinkError!usize` | 1 | — |
| `setFilePermissions` | `(dir, io, sub_path, new_permissions, options)` | 1 | — |
| **`rename`** | `(old_sub_path, new_dir: Dir, new_sub_path, io: Io)` | **4** ⚠️ | — |
| **`copyFile`** | `(source_path, dest_dir, dest_path, io: Io, options: CopyFileOptions)` | **5** ⚠️ | — |
| **`hardLink`** | `(old_sub_path, new_dir, new_sub_path, io, options: HardLinkOptions)` | **5** ⚠️ | — |
| **`symLink`** | `(io, target_path, sym_link_path, flags: SymLinkFlags)` | **1** | — |
| `symLinkAtomic` | `(io, target_path, sym_link_path, flags)` | **1**（例外） | — |
| **`updateFile`** | `(io, source_path, dest_dir, dest_path, options) PrevStatus` | **1**（例外） | — |
```

⚠️ **规律只有一条，而且有例外**：**单 `Dir` 的方法 `io` 在第 1 位；
跨两个 `Dir` 的方法 `io` 靠后（第 4/5 位）**。但 `symLinkAtomic` 和 `updateFile`
虽然也跨 `Dir`，`io` 却在第 1 位。**没有规律可循，只能查这张表。**

搞错了报的是（实测，`copyFile` 少传一个参数）：

```text
main.zig:692:21: error: member function expected 5 argument(s), found 6
        try cwd.copyFile(cwd, root ++ "/b.txt", cwd, root ++ "/b_copy.txt", io, .{});
             ~~~^~~~~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Dir.zig:1813:5: note: function declared here
pub fn copyFile(
```

（`copyFile` 是**方法**，接收者就是源 `Dir`，所以不用传第一个 `source_dir`。）

数据类型形状（全部 `@typeInfo` 实测）：

```text
| 类型 | 形状 |
|---|---|
| `Io.Dir.Entry` | `struct { name: []const u8, kind: File.Kind, inode: u64 }` —— **只有 3 个字段** |
| `Io.File.Kind` | `enum(u4)`，**11 个成员**（见 27.2） |
| `Io.Dir.Walker.Entry` | `struct { dir: Dir, basename: [:0]const u8, path: [:0]const u8, kind: File.Kind }` |
| `Io.File.Stat` | `struct { inode, nlink, size, permissions, kind, atime, mtime, ctime, block_size }` —— 9 个字段 |
| `Io.Dir.OpenOptions` | `struct { access_sub_paths, iterate, follow_symlinks }` |
| `Io.Dir.StatFileOptions` | `struct { follow_symlinks: bool = true }` —— **只有 1 个字段** |
| `Io.Dir.AccessOptions` | **`packed struct`** `{ follow_symlinks, read, write, execute }` |
| `Io.Dir.Iterator` | `struct { reader: Reader, reader_buffer: [2048]u8 align(usize) }` |
| `Io.Dir.Reader` | `struct { dir, state, buffer, index, end }`，`state: enum { reset, reading, finished }` |
| `Io.Dir.Reader.min_buffer_len` | macOS 上 = **1048** 字节（编译期常量） |
| `Io.Dir.Iterator.reader_buffer_len` | **2048** 字节（编译期常量） |

## 27.2 Dir / File / Entry 三层模型

20 章 20.1.2 已经立过这个模型：Dir 是工厂、File 是句柄。遍历多了一层 **Entry**：

```zig
// examples/27_tree/main.zig 第 284-297 行
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
```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.2 开始 ====
Io.Dir.Entry 只有 3 个字段： name kind inode
  name : []const u8
  kind : Io.File.Kind
  inode : u64
entry.kind 的字段类型是 Io.File.Kind（**不是** Io.Dir.Entry.Kind —— 后者不存在）
  它的编译期基整型是 u4（11 个成员⇒4 位够了），但**打印/比较一律用 {t}**
File.Kind 全部 11 个成员： block_device character_device directory named_pipe sym_link file unix_domain_socket whiteout door event_port unknown
Dir 是工厂：openDir 出来的是**真 fd**（handle >= 0）；Dir.cwd().handle=-2 是伪句柄（AT_FDCWD=-2）
Entry 是遍历产物：只有 {name, kind, inode}，**没有大小、没有时间**（要 statFile）
  [file] README.md
  [directory] empty
  [file] main.zig
  [directory] src
  顶层 4 个条目（上面已排序；**原始顺序由文件系统决定** ⇒ 想确定输出必须自己排）
  inode 字段实测是 u64（macOS/Linux 的 ino_t）⇒ 够当"已访问"集合的 key（27.11 防环用）
==== 27.2 结束 ====
```

三层的职责：

```text
| 层 | 类型 | 是什么 | 生命周期 |
|---|---|---|---|
| 工厂 | `Dir` | 一个"从某目录出发"的定位器。`Dir.cwd()` 是伪句柄（-2） | 值语义，不持资源（除了 openDir 的结果） |
| 句柄 | `File` | 一个**已打开的** fd | 必须 `close(io)` |
| 产物 | `Entry` | 遍历时的一条记录：`{name, kind, inode}` | **借来的**（name 指向内部缓冲，见 27.5） |
```

**`Entry` 没有大小、没有时间。** 这是本章最该记住的一句话：想拿大小就得
`statFile`，而 `statFile` 是**一次系统调用**。所以"列出目录 + 显示大小"
的成本是 N+1 次系统调用，不是 N 次。

`kind` 的 11 个成员（实测）：

```text
| 成员 | 什么时候出现 | 遍历时怎么处理 |
|---|---|---|
| `.file` | 普通文件 | 计入大小 |
| `.directory` | 目录 | **递归进去** |
| `.sym_link` | 符号链接 | **默认不跟**（27.11） |
| `.unknown` | 网络/FUSE 文件系统填不满 `d_type` | **不能假设它是文件**（要 `statFile`） |
| `.block_device` / `.character_device` | `/dev/null` 这类 | 跳过 |
| `.named_pipe` | FIFO | 跳过（**别 openFile**，会阻塞！） |
| `.unix_domain_socket` | socket 文件 | 跳过 |
| `.whiteout` | macOS 的删除标记 | 跳过 |
| `.door` / `.event_port` | Plan 9 遗留 | 跳过 |
```

⚠️ **`.named_pipe` 是个真陷阱**：`openFile` 一个 FIFO 的**读端会阻塞到有写端**。
在遍历器里对未知类型一律 `openFile` 是不安全的。

⚠️ **`.unknown` 意味着 `kind != .file` 不等于"是目录"**。网络文件系统可能填不准确，
要确定就 `statFile`。20 章坑位 10 记过这一条，本章它变成了一个实际决策点：
**遍历时该信任 `kind` 还是 `stat`？** 27.11 会给出答案（`walk` 信任 `kind`，
所以不跟链接；手写递归可以自己选）。

对应的测试把形状守成了断言：

```zig
// examples/27_tree/main.zig 第 906-924 行
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
```

## 27.3 `next()` 的正确用法：双层解包

`Iterator.next` 的返回类型是 **`Error!?Entry`**——错误和可选**两层**。这是 0.17
最反直觉的一处，实测三种写法的行为完全不同。

```zig
// examples/27_tree/main.zig 第 320-342 行
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
```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.3 开始 ====
next 的返回类型是 `Error!?Entry`（错误 + 可选，两层）
✅ `while (try it.next(io)) |entry|` —— 一次解两层，写法最短
  while 解包 [file] app.zig
  while 解包 [directory] deep
  while 解包 [file] util.zig
  src 下 3 个条目
⚠️ `if (it.next(io)) |x|` 里的 x **仍是 ?Entry**（只解了错误层）
  实测 x 的类型 = ?Io.Dir.Entry ⇒ 还得再解一层才拿得到 name
  第二层解包后 [file] app.zig
  写错成 |entry| 直接用 entry.name → error: optional type '?Io.Dir.Entry' does not support field access
同一个 Dir 第二次 iterate() → 3 个（iterate() 内部状态是 .reset，会 lseek 回 0）
iterateAssumeFirstIteration() → 0 个（接着上次读完的位置，不 reset ⇒ 通常是 0）
==== 27.3 结束 ====
```

### 27.3.1 三种写法的实测对照

我用一个返回 `!?u8` 的假函数把语义测清楚了：

```text
| 写法 | 绑定到的类型 | null 时 | 错误时 |
|---|---|---|---|
| `while (try f()) |v|` | **`u8`**（解两层） | 提前 return | 循环结束 |
| `if (f()) |v|` | **`?u8`**（只解错误层） | 走 `else \|e\|` | 走 `else \|e\|` |
| `if (try f()) |v|` | **`u8`**（先 try 再解可选） | `v == null` | 提前 return |
```

```zig
// 三种写法的实测（探针 build/probe27/api.zig）
f: maybe=7（类型 ?u8）
g: maybe=null
h err → Boom
while 解包成功 v=7
先 try 后 if → v=7（类型 u8）
```

⚠️ **`if (errUnion) |x|` 只解包错误层**——这是最容易踩的一条。`x` 的类型实测
是 `?Io.Dir.Entry`，直接 `x.name` 编译报：

```text
main.zig:34:83: error: optional type '?Io.Dir.Entry' does not support field access
                std.debug.print("  000 目录 openDir+iterate 成功？{s}\n", .{e.name});
                                                                                 ^~~~~~
main.zig:34:83: note: consider using '.?', 'orelse', or 'if'
```

**所以遍历的标准写法只有两种**：

```zig
// ✅ 全量遍历：while 一次解两层
while (try it.next(io)) |entry| { ... }

// ✅ 只想看第一个：先 try 再解可选
if (try it.next(io)) |entry| { ... }

// ⚠️ 想区分"空目录"和"读错了"：必须两层 if
if (it.next(io)) |maybe| {          // 第一层：区分错误
    if (maybe) |entry| { ... }      // 第二层：区分 null
} else |err| { ... }
```

### 27.3.2 同一个 `Dir` 能 iterate 两遍吗

```zig
// examples/27_tree/main.zig 第 344-351 行
        // 同一个 Dir 能iterate 两遍吗
        var n1: usize = 0;
        var it3 = d2.iterate();
        while (try it3.next(io)) |_| n1 += 1;
        std.debug.print("同一个 Dir 第二次 iterate() → {d} 个（iterate() 内部状态是 .reset，会 lseek 回 0）\n", .{n1});
        var n2: usize = 0;
        var it4 = d2.iterateAssumeFirstIteration();
        while (try it4.next(io)) |_| n2 += 1;
```text
同一个 Dir 第二次 iterate() → 3 个（iterate() 内部状态是 .reset，会 lseek 回 0）
iterateAssumeFirstIteration() → 0 个（接着上次读完的位置，不 reset ⇒ 通常是 0）
```

**能**。因为 `iterate()` 造出来的 `Iterator` 状态是 `.reset`（源码 `Dir.zig:212`：
`return .init(dir, .reset)`），`Reader.read` 看到 `.reset` 会先 `lseek` 回 0 再读。
而 `iterateAssumeFirstIteration()` 用 `.reading` 状态，**接着上次读完的位置**——
所以上次的 3 个已经读完了，这次 0 个。

`walkSelectively` 内部就用 `iterateAssumeFirstIteration`（源码 `Dir.zig:293`），
因为它自己管着每层的 `Iterator` 状态，不需要每层都复位。

对应的测试同时守住了"能两遍"和"空目录返回 null"：

```zig
// examples/27_tree/main.zig 第 926-951 行
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
```

## 27.4 `next()` 的错误处理：`AccessDenied` 要不要终止整趟

遍历错误分两类，处理方式**完全相反**：

```text
| 错误 | 谁报的 | 该怎么办 |
|---|---|---|
| 目录**进不去**（`AccessDenied` / `PermissionDenied`） | `openDir` 或 `next` | **跳过**，继续遍历别的（否则一个受限目录让整趟失败） |
| 目录**进得去但读错**（`SystemResources` / `InputOutput`） | `next` | 上抛（这是真故障，不是权限问题） |
| 路径**不存在**（`FileNotFound`） | `statFile` / `openFile` | 看业务（可能是"刚被别人删了"） |
| 路径**太长**（`NameTooLong`） | `openDir` | 跳过并**告警**（说明有超长路径，要处理） |
```

先看实测：`000` 权限的目录在 macOS 上连句柄都拿不到。

```zig
// examples/27_tree/main.zig 第 359-379 行
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
```

运行输出（`examples/27_tree/main.zig`）：
```text
```text
Iterator.Error 的 @typeInfo tag = error_set（是错误集，不是别的）
  自己声明的成员： Canceled SystemResources AccessDenied Unexpected PermissionDenied
000 目录 openDir → AccessDenied（实测：连目录句柄都拿不到）
  access(execute) 于 000 目录 → AccessDenied
```

`Iterator.Error` 是 `Reader.Error` 的别名（`Dir.zig:190`），它自己只声明了
**4 个**成员（`Canceled` / `SystemResources` / `AccessDenied` / `Unexpected` /
`PermissionDenied`——反射出来 5 个，其中 `Canceled`/`Unexpected` 来自 `Io` 家族）。
**权限相关的只有 `AccessDenied` 和 `PermissionDenied` 两个**——所以判据就这两个。

### 27.4.1 手写递归的"跳过"策略

```zig
// examples/27_tree/main.zig 第 147-184 行
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
```zig
// examples/27_tree/main.zig 第 389-409 行
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
```text
策略 A（openDir 失败就跳过）：收集 5 个文件，跳过 1 个目录
  /tmp/zig27_tree_demo/README.md
  /tmp/zig27_tree_demo/main.zig
  /tmp/zig27_tree_demo/src/app.zig
  /tmp/zig27_tree_demo/src/deep/leaf.txt
  /tmp/zig27_tree_demo/src/util.zig
策略 B 的 walk 版本：
  walk next → AccessDenied（实测：这个错误**可恢复**，再调next 能接着走）
  empty [directory]
  main.zig [file]
  README.md [file]
  src [directory]
  src/app.zig [file]
  src/deep [directory]
  src/deep/leaf.txt [file]
  src/util.zig [file]
  walk 正常结束
⇒ walk 的 next 出错后**可以继续调用**（源码会把出错的目录弹栈）⇒ 循环里 catch 后能接着走
⇒ 手写递归的 openDir 出错只能 return：所以要**在递归里就地 catch 成跳过**
⇒ 27 章选A：**目录级错误降级成"跳过"，其它错误原样上抛**
```

**`walk` 的 `next` 出错后还能继续用**——源码里有明确设计（`Dir.zig:241-250`）：

```zig
// lib/std/Io/Dir.zig 第 240-251 行（节选）
            if (top.iter.next(io) catch |err| {
                // If we get an error, then we want the user to be able to continue
                // walking if they want, which means that we need to pop the directory
                // that errored from the stack. Otherwise, all future `next` calls would
                // likely just fail with the same error.
                var item = self.stack.pop().?;
                if (self.stack.items.len != 0) {
                    item.iter.reader.dir.close(io);
                }
                return err;
            }) |entry| {
```

注释写得很清楚：**出错时把那个目录从栈上弹掉**，所以后续 `next` 会继续遍历
**上一层剩下的兄弟目录**。这就是"跳过"的实现。

⇒ **两种写法的对比**：

```text
| 写法 | 代码 | 出错后 |
|---|---|---|
| 手写递归 | `openDir` 在递归体内 | 只能 `return`，**必须就地 catch 成跳过** |
| `walk` | 库管栈 | `catch` 后可以 `continue`，库已经帮你弹栈了 |
| `walkSelectively` | 你自己 `enter` | `enter` 失败会返回错误，你可以选择跳过 |
```

对应的测试守住了"跳过之后其余条目照样统计到"：

```zig
// examples/27_tree/main.zig 第 1336-1365 行
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
```

⚠️ 注意最后那个 `setFilePermissions(0o755)`：**不恢复权限的话 `tmp.cleanup()`
会清不掉这个目录**（`deleteTree` 也需要 `execute` 权限）。这是"造受限目录"
这类测试的通用收尾。

## 27.5 ⚠️ `entry.name` 活不过下一次 `next()`

这是本章第一坑，也是 20 章坑位 12 的延伸。源码里写得很明确：

```zig
// lib/std/Io/Dir.zig 第 155-156 行
    /// `Entry.name` is invalidated with the next call to `read` or `next`.
    pub fn next(r: *Reader, io: Io) Error!?Entry {
```

而 `Iterator` 有 **2048 字节的内嵌缓冲**（`Iterator.reader_buffer_len = 2048`），
`Reader.buffer` 指向它。所以 `entry.name` 是**指向这块栈上/结构体内缓冲的借用切片**。

### 27.5.1 实测：小目录"看起来没事"，大目录原形毕露

```zig
// examples/27_tree/main.zig 第 418-432 行
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
```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.5 开始 ====
Io.Dir.Iterator 有 2048 字节的内嵌缓冲（Iterator.reader_buffer_len）
源码文档原话：All `Entry.name` are invalidated with the next call to `read` or `next`
⇒ 跨 next() 收集名字**必须 dupe**，否则拿到的是同一块缓冲里的旧内容
另造 many/ 目录放 60 个条目（名字 13 字节 ⇒ 2048 字节缓冲要 fillMany 次）
  ❌ 不dupe：60 个切片的内容里有重复吗？true（true = 多个切片指向同一块缓冲）
     用这些名字 access 目录：有失效的吗？true（true = 有名字指向不存在的条目）
     ⚠️ **具体几个失效取决于实现细节**（缓冲多大、一次填多少）——不要去数个数
        真正的教训是：小目录一次读完，看起来"完全没事"，这才是陷阱
  ✅ dupe 后 60 个，60 个全部有效；排序后首尾：file_000.txt … file_059.txt
⇒ 内存纪律：entry.name 是**借来的**，要活过 next() 就 dupe（或当场用完就扔）
==== 27.5 结束 ====
```

三个观察：

1. **不 dupe 时切片内容有重复**——因为多个 `name` 指向同一块缓冲的同一位置。
2. **拿这些名字 `access` 会失败**——内容已被覆盖成别的文件名了。
3. **具体几个失效是实现细节**（macOS 上 9 个，Linux 上可能不同），**不要去数个数**，
   也**不要写"小目录就安全"的代码**。

### 27.5.2 我第一次写这个示例时踩的现场

我最初的 `printTree` 是这样的（**错的**）：

```zig
// ❌ 错误版本：收集 name 但不 dupe
var names: std.ArrayList([]const u8) = .empty;
var it = d.iterate();
while (try it.next(io)) |entry| try names.append(a, entry.name); // 借来的！
std.mem.sort([]const u8, names.items, {}, lessStr);
for (names.items) |name| {
    const st = try d.statFile(io, name, .{});   // ← 这里报 FileNotFound
```

症状是"排序输出和真实目录对不上"，而且 `statFile` 随机报 `FileNotFound`。
**一个根因**：`entry.name` 全指向同一块缓冲。

正确版本（27.12 的 `buildTree` 就是这么写的）：

```zig
// ✅ 正确版本：立刻 dupe
var names: std.ArrayList([]const u8) = .empty;
var it = d.iterate();
while (try it.next(io)) |e| try names.append(gpa, try gpa.dupe(u8, e.name));
```

⚠️ **`Dir.Iterator` 同理不能按值拷贝**（20 章坑位 12）：它有 2048 字节内嵌缓冲，
按值拷贝后 `Reader.buffer` 仍指向**原 struct** 的那块。所以必须
`var it = d.iterate();` 然后用指针，**不要**写 `const it2 = it;`。

对应的测试用了 200 个长名字（确保多次 `fillMore`），并用两个判据：

```zig
// examples/27_tree/main.zig 第 953-994 行
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
```

## 27.6 `walk()`：库写好的递归

`walk` 是本章最省心的选择：库把递归写好了，你只要 `while (try w.next(io)) |e|`。

```zig
// examples/27_tree/main.zig 第 489-500 行
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

```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.6 开始 ====
实测签名：dir.walk(allocator: Allocator) Allocator.Error!Walker —— **第一个参数是 gpa**
Walker.Entry 有 4 个字段： dir basename path kind
  dir : Io.Dir
  basename : [:0]const u8
  path : [:0]const u8
  kind : Io.File.Kind
  path / basename 都是 [:0]const u8（**带哨兵**，可直接给 C API）；dir 是所在目录的句柄
  entry.depth() 是自己算的：数路径里的分隔符 + 1（根的直接子节点 depth=1）
  depth=1 kind=directory path=locked
  depth=2 kind=file path=locked/secret.txt
  depth=1 kind=directory path=empty
  depth=1 kind=file path=main.zig
  depth=1 kind=file path=README.md
  depth=1 kind=directory path=src
  depth=2 kind=file path=src/app.zig
  depth=2 kind=directory path=src/deep
  depth=3 kind=file path=src/deep/leaf.txt
  depth=2 kind=file path=src/util.zig
  排序后同样 10 条，顺序确定：
    README.md  depth=1
    empty  depth=1
    locked  depth=1
    locked/secret.txt  depth=2
    main.zig  depth=1
    src  depth=1
    src/app.zig  depth=2
    src/deep  depth=2
    src/deep/leaf.txt  depth=3
    src/util.zig  depth=2
⇒ 排序只是为了输出确定；walk 本身的顺序文档明说 undefined
⇒ 用 e.dir + e.basename 定位，省掉拼长路径 ⇒ 深层目录不会撞error.NameTooLong
==== 27.6 结束 ====
```

### 27.6.1 `Walker.Entry` 的三个非 obvious 设计

**① `path` 和 `basename` 都是 `[:0]const u8`（带哨兵）**。这不是随手加的——
`Dir.Reader.read` 往 `name_buffer` 末尾 `appendAssumeCapacity(0)`（源码
`Dir.zig:259`），所以路径天然带哨兵，可以直接给 `open`/`stat` 这类 C API。

**② `dir` 字段是"条目所在目录"的句柄**。这一条价值极大：

```zig
// ✅ 用 e.dir + e.basename 定位，不用拼长路径
const st = try e.dir.statFile(io, e.basename, .{});   // 不会 NameTooLong
```

深层目录（比如 3000 层）拼出来的路径会超出 `PATH_MAX`，报 `error.NameTooLong`；
而 `e.dir` + `e.basename` 是"相对某个已打开的目录"，**长度只有一个文件名**。
这是 `Walker.Entry` 文档里那句 "avoiding `error.NameTooLong` for deeply nested
paths" 的意思。

**③ `depth()` 是自己算的**，不是库的字段：

```zig
// lib/std/Io/Dir.zig 第 357-359 行
        pub fn depth(self: Walker.Entry) usize {
            return std.mem.countScalar(u8, self.path, path.sep) + 1;
        }
```

**根目录的直接子节点 `depth() == 1`**（路径 `src` 里 0 个分隔符 +1）。
而**根目录本身不在结果里**——`walk` 只产出"根目录里的东西"。

⚠️ `depth()` 数的是 `path.sep`（本平台的分隔符）。在 Windows 上路径是
`src\app.zig`，所以它数 `\`。跨平台代码用 `depth()` 就好，**不要自己数 `/`**。

### 27.6.2 `walk` 的顺序是 undefined

文档明说（源码 `Dir.zig:393`）：`The order of returned file system entries is undefined.`

所以**任何依赖 walk 顺序的输出都是不可复现的**。示例的做法是：先收集到
`ArrayList`，`std.mem.sort`，再打印。

⚠️ **这里有一个和 27.5 同源的坑**：我第一次写排序时把 `depth` 用
`std.fmt.bufPrint(&db, ...)` 打进一个**栈上缓冲**再存进数组，结果 10 条全是
`depth=2`（全是最后一次的值）：

```zig
// ❌ 错：db 是循环内的栈变量，每轮都被复用
var db: [16]u8 = undefined;
try rows.append(a, .{ try a.dupe(u8, e.path), try std.fmt.bufPrint(&db, "depth={d}", .{e.depth()}) });
```

正确写法（**存进 `ArrayList` 的每个字符串都要拥有自己的内存**）：

```zig
// examples/27_tree/main.zig 第 504-516 行
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
```zig
// examples/27_tree/main.zig 第 1012-1047 行
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
```

## 27.7 `walk` 的提前终止

"找到第一个叫 `x` 的文件就停"是最常见的遍历需求。`walk` 怎么做？

```zig
// examples/27_tree/main.zig 第 523-557 行
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
```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.7 开始 ====
整棵树全量 10 个条目；命中 src/deep/leaf.txt 时 break 前只访问了 9 个
⚠️ break 只退出你的循环；**Walker 的栈上还压着若干 openDir 出来的 Dir**
   ⇒必须 `defer w.deinit()`：它关掉栈上的目录 + 释放 name_buffer 和 stack
   deinit() **不会**关掉你最初 openDir 的那个 d（文档：dir will not be closed）
⇒ 实测：deinit 之后原来的 d 还能再 iterate 一遍 ⇒ 这是设计，不是漏关
  deinit 后 d 重新 iterate → 5 个条目
==== 27.7 结束 ====
```

### 27.7.1 break 的语义

**`break` 就是跳出 `while` 循环**——没有"提前终止遍历"的额外机制，也不需要。
`Walker` 的内部状态（栈上压了哪些目录）由 **`deinit()`** 负责清理：

```zig
// lib/std/Io/Dir.zig 第 373-375 行
    pub fn deinit(self: *Walker) void {
        self.inner.deinit();
    }
// lib/std/Io/Dir.zig 第 298-301 行
    pub fn deinit(self: *SelectiveWalker) void {
        self.name_buffer.deinit(self.allocator);
        self.stack.deinit(self.allocator);
    }
```

⚠️ 注意 `SelectiveWalker.deinit` **只释放内存**，不关 `stack` 里的 `Dir`！
——因为 `SelectiveWalker.next` / `leave` 在弹栈时已经 `item.iter.reader.dir.close(io)`
了（源码 `Dir.zig:269-271`、`Dir.zig:309-311`）。**只有 `break` 出来的路径
会留下没关的 `Dir`**，因为它没走弹栈逻辑。

⇒ 所以 `defer w.deinit()` 是**必须的**，而且要在 `walk` 之后立刻写。
`std.testing` 的泄漏检测会抓到遗漏（20 章坑位 15）。

⚠️ **`deinit()` 不会关掉你最初 `openDir` 的那个 `d`**——文档明说
（源码 `Dir.zig:393`）：`dir will not be closed after walking it.`。
实测印证了：`deinit` 之后 `d` 还能重新 `iterate` 出 5 个条目。

对应的测试两件事一起验：

```zig
// examples/27_tree/main.zig 第 1049-1073 行
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
```

## 27.8 `walkSelectively`：剪枝

`walk` 会自动进**每一个** `.directory`。但真实目录里有 `node_modules`、
`.git`、`target`、`__pycache__`——**跟进它们就是浪费**。`walkSelectively`
让你自己决定。

```zig
// examples/27_tree/main.zig 第 560-587 行
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
```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.8 开始 ====
walkSelectively 的 next **不自动进子目录**（walk 会自动 enter）
  locked（depth=1）
  empty（depth=1）
  main.zig（depth=1）
  README.md（depth=1）
  src（depth=1）→ enter(src)
  src/app.zig（depth=2）
  src/deep（depth=2）→ leave()
  enter 1 次 / leave 1 次 ⇒ src/deep 及以下一个都没访问
  leave(io) 无返回值也不报 error：它就是弹栈（源码 self.stack.pop().?）
⚠️ leave 的语义是"离开当前目录"，不是"跳过这个条目"⇒ 后面同层的兄弟目录会继续出现
⚠️ enter 只对 kind==.directory 有效（源码第一行就 if (entry.kind != .directory) return）
==== 27.8 结束 ====
```

### 27.8.1 `enter` / `leave` 的语义（两个都要实测）

**`enter(io, entry)`**：

```zig
// lib/std/Io/Dir.zig 第 278-296 行（节选）
    pub fn enter(self: *SelectiveWalker, io: Io, entry: Walker.Entry) !void {
        if (entry.kind != .directory) {
            @branchHint(.cold);
            return;                        // ← 非目录直接返回，不是错误
        }
        var new_dir = entry.dir.openDir(io, entry.basename, .{ .iterate = true }) catch |err| {
            switch (err) {
                error.NameTooLong => unreachable,   // ← 这个错误被断言为不可能
                else => |e| return e,
            }
        };
        errdefer new_dir.close(io);
        try self.stack.append(self.allocator, .{
            .iter = new_dir.iterateAssumeFirstIteration(),
            .dirname_len = self.name_buffer.items.len - 1,
        });
    }
```

三点：

1. **对非目录 `enter` 是 no-op**（不报错）。所以你可以无脑
   `if (e.kind == .directory) try w.enter(io, e);`
2. **`openDir` 失败会返回错误**（比如权限不足）。所以 `enter` 也要 `try` /
   `catch`——这就是"剪枝"的另一个用途：**故意不 enter 就等于跳过整个子树**。
3. **`error.NameTooLong => unreachable`**：它用 `entry.dir` + `entry.basename`
   而不是拼长路径，所以路径超长在理论上不可能发生（27.6.1 说的那个设计）。

**`leave(io)`**：

```zig
// lib/std/Io/Dir.zig 第 303-312 行
    pub fn leave(self: *SelectiveWalker, io: Io) void {
        var item = self.stack.pop().?;
        if (self.stack.items.len != 0) {
            item.iter.reader.dir.close(io);
        }
    }
```

⚠️ **`leave` 弹的是"栈顶那个目录"，不是"刚看到的那个条目"**。这是最容易搞混的一点：

```text
栈（简化）        你看到 e        调 leave 后
[根]              src/deep       弹掉**栈顶** = src ⇒ 回到根层
[src]
```

也就是说，如果你的循环是"看到 depth>=2 的目录就 `leave`"，而你刚 `enter` 过 `src`，
那 `leave` 弹的是 `src`——**`src` 里剩下的条目（`util.zig`）就看不到了**。

**正确的剪枝写法**（也是 27 章 `main` 之外最常用的形态）：

```zig
// ✅ 剪掉黑名单目录：看到就不 enter，什么都不用做
const skip_dirs = [_][]const u8{ ".git", "node_modules", "target" };
while (try w.next(io)) |e| {
    if (e.kind == .directory) {
        var skip = false;
        for (skip_dirs) |s| {
            if (std.mem.eql(u8, e.basename, s)) skip = true;
        }
        if (!skip) try w.enter(io, e);   // 白名单式：不 skip 才进
        // 被 skip 的目录：它的内容自然不会出现在后面——**不需要 leave**
    }
    process(e);
}
```

**`leave` 真正的用途是"提前放弃当前目录"**（比如发现这个目录太大、
或者已经找到想要的东西）。这就是 27.7 的 `break` 的精细版。

对应的测试守住了"leave 之后该子树的内容一个都没访问"：

```zig
// examples/27_tree/main.zig 第 1075-1110 行
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
```

⚠️ 注意断言是 `"x/y/c.txt"` **没出现**，而不是 `"x/y"` 没出现——
`y` 本身作为条目**是被报告的**（它出现在 `seen` 里），只是没被 `enter`。
这是"报告"和"跟进"的区别，27.11 会再强调一次。

## 27.9 ⚠️ 为什么不能对 `cwd()` 直接 `walk`

这是本章最关键的坑，也是 20 章 20.8.3 记过的那条——本章把它讲透。

```zig
// examples/27_tree/main.zig 第 590-607 行
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
```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.9 开始 ====
std.Io.Dir.cwd().handle = -2，而 AT.FDCWD = -2 ⇒ 它**不是真正的 fd**
源码文档原话：It is not opened with iteration capability.
             Iterating over the result is illegal behavior.
             Closing the returned `Dir` is checked illegal behavior.
实测：cwd().walk(a) **不报错**（只是造个 Walker），但第一次 next(io) 直接 panic：
  thread N panic: programmer bug caused syscall error: BADF
  Threaded.zig:10512 in posixSeekTo: .BADF => |err| return errnoBug(err)
  Threaded.zig:5692 in dirReadDarwin: posixSeekTo(dr.dir.handle, 0) catch ...
  Dir.zig:152 in read → Dir.zig:159 in next → Iterator.next:207 → SelectiveWalker.next:241
原因：Darwin 上读目录要 lseek 复位，对 AT_FDCWD 做 lseek 就是 EBADF
⇒ 规律：cwd() 只能做**按路径**的操作（openFile / statFile / createDirPath …）
   凡是需要真实 fd 的（walk / stat / iterate / close）必须先 openDir
   cwd().stat(io) 同样 panic 同因；cwd().close(io) 是 checked illegal behavior
✅ 正解：var d = try cwd.openDir(io, 路径, .{ .iterate = true }); 然后在 d 上 walk
==== 27.9 结束 ====
```

### 27.9.1 为什么是 BADF 而不是别的错误

完整的 panic 栈（实测）：

```text
thread 2057560 panic: programmer bug caused syscall error: BADF
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:14443:34: 0x10b68561b in errnoBug
    if (is_debug) std.debug.panic("programmer bug caused syscall error: {t}", .{err});
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:10512:51: 0x10b6b1662 in posixSeekTo
                    .BADF => |err| return errnoBug(err), // File descriptor used after closed.
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:5692:28: 0x10b6c05a1 in dirReadDarwin
                posixSeekTo(dr.dir.handle, 0) catch |err| switch (err) {
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Dir.zig:152:33: 0x10b701570 in read
        return io.vtable.dirRead(io.userdata, r, buffer);
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Dir.zig:159:31: 0x10b700f7d in next
            const n = try read(r, io, &buffer);
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Dir.zig:207:30: 0x10b700e0c in next
        return it.reader.next(io);
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Dir.zig:241:30: 0x10b6ff1b3 in next
            if (top.iter.next(io) catch |err| {
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Dir.zig:366:42: 0x10b6f3e75 in next
        const entry = try self.inner.next(io);
p2.zig:75:38: 0x10b6f5555 in main
            const maybe = try w2.next(io);
```

链条很清晰：

1. `cwd().handle == -2`（`AT.FDCWD`），它不是一个真正的 fd，而是"每次操作都相对当前目录解析"的意思。
2. `Dir.Reader` 在 Darwin 上要 `lseek` 复位目录流（`dirReadDarwin` 里
   `posixSeekTo(dr.dir.handle, 0)`）。
3. 对 `-2` 做 `lseek` 就是 `EBADF`。
4. `posixSeekTo` 把 `BADF` 当成"**程序员错误**"（注释：`File descriptor used
   after closed.`），所以 `errnoBug` → `panic`（Release 模式下是 `unreachable`）。

⚠️ **这是 `panic` 不是返回错误**——意味着**你 catch 不住**。在 Debug 和 Safe
模式下都会炸（`if (is_debug) panic(...)` / `unreachable` 两条分支都是死路）。

### 27.9.2 完整的 `cwd()` 能力表

```text
| 操作 | 需要真实 fd？ | 对 `cwd()` 能用吗 |
|---|---|---|
| `openFile` / `createFile` | 否（按路径 openat） | ✅ |
| `statFile` | 否（按路径 fstatat） | ✅ |
| `createDirPath` / `deleteTree` / `rename` / `copyFile` | 否 | ✅ |
| `access` | 否 | ✅ |
| `openDir` | 否（返回**新** fd） | ✅ |
| **`iterate`** | **是** | ❌ illegal behavior |
| **`walk` / `walkSelectively`** | **是** | ❌ panic (BADF) |
| **`stat`** | **是** | ❌ panic (BADF) |
| **`close`** | — | ❌ checked illegal behavior |
```

**规律一句话**：`cwd()` 只能做**按路径**的操作（内部用 `*at()` 系统调用，
路径相对于 `AT_FDCWD` 解析）；**凡是需要真实 fd 的都必须先 `openDir`**。

⚠️ **`cwd().close(io)` 是 checked illegal behavior**——它不会 panic，
但 Zig 会标记你的程序"做了非法事"（Release 下可能被优化掉）。

⚠️ 顺便：`Dir.cwd()` 在 POSIX 上是 **comptime 可调用**的（源码 `Dir.zig:85`），
所以能写 `const cwd = std.Io.Dir.cwd();` 在编译期。它还被
`std.Options.cwd` 覆盖——所以嵌入式/沙箱环境可以换掉"当前目录"的含义。

对应的测试（20 章那个）守住了这一点，27 章的 14 个 test 全部走 `tmp.dir.openDir`：

```zig
// examples/20_files/main.zig 第 840-857 行（20 章的测试，27 章沿用同一模式）
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
```

## 27.10 `statFile` 的 lstat 语义

```zig
// examples/27_tree/main.zig 第 610-617 行
    begin("27.10");
    {
        const SO = @typeInfo(std.Io.Dir.StatFileOptions).@"struct";
        std.debug.print("StatFileOptions 只有 {d} 个字段：", .{SO.field_names.len});
        inline for (SO.field_names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});
        inline for (SO.field_types, 0..) |t, i| std.debug.print("  {s} : {s}\n", .{ SO.field_names[i][0..SO.field_names[i].len], @typeName(t) });
        std.debug.print("⚠️ follow_symlinks 的类型实测就是 **bool**（默认 true）\n", .{});

```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.10 开始 ====
StatFileOptions 只有 1 个字段： follow_symlinks
  follow_symlinks : bool
⚠️ follow_symlinks 的类型实测就是 **bool**（默认 true）
   不是 { .file, .sym_link } / { true: ..., false: ... } 这种联合字面量
   （grep 全标准库：follow_symlinks 一律是 bool，没有 union 版本）
Stat 的 9 个字段： inode nlink size permissions kind atime mtime ctime block_size
  inode : u64
  nlink : u16
  size : u64
  permissions : Io.File.Permissions__enum_8
  kind : Io.File.Kind
  atime : ?Io.Timestamp
  mtime : Io.Timestamp
  ctime : Io.Timestamp
  block_size : u32
  atime 是**可选**的 ?Io.Timestamp（有些 FS 拒绝报告访问时间）
  mtime / ctime 是 Io.Timestamp（纳秒，相对 UTC 1970-01-01）
lstat(link) kind=sym_link  size=9 nlink=1
stat (link) kind=file      size=6 nlink=1   ← 穿透到目标（6 B 的 README.md）
⇒ 判"这是不是链接"必须 follow_symlinks=false；判"这个路径指向什么"用默认 true
readLink → README.md（9 字节；这是唯一能拿到链接目标字符串的办法）
悬空链接 lstat → kind=sym_link size=12（能看见链接本身）
悬空链接 stat → FileNotFound（穿透到不存在的目标）
⇒ 悬空链接的 kind 是 .sym_link **不是** .file ⇒ 按 *.txt 过滤时天然被排除
⇒ 但 readLink 仍能读出目标字符串 =no_such_file（12 字节）——那是它自己写的那一串
==== 27.10 结束 ====
```

### 27.10.1 ⚠️ `follow_symlinks` 是 `bool`，不是联合字面量

这一点值得单列，因为"实测"和"想当然"会给出不同答案。我 grep 了整个标准库：

```text
$ grep -rn "follow_symlinks:" lib/std/          # 全部命中都是 bool
lib/std/Io/Dir.zig:426:    follow_symlinks: bool = true,      # AccessOptions (packed)
lib/std/Io/Dir.zig:473:    follow_symlinks: bool = true,      # OpenOptions
lib/std/Io/Dir.zig:554:    follow_symlinks: bool = true,      # OpenFileOptions
lib/std/Io/Dir.zig:887:    follow_symlinks: bool = true,      # StatFileOptions
lib/std/Io/Dir.zig:1959:    follow_symlinks: bool = true,     # SetFilePermissionsOptions
lib/std/Io/Dir.zig:1989:    follow_symlinks: bool = true,     # SetFileOwnerOptions
lib/std/Io/Dir.zig:2007:    follow_symlinks: bool = true,     # SetTimestampsOptions
lib/std/Io/File.zig:714:    follow_symlinks: bool = false,    # HardLinkOptions
lib/std/Io/Threaded.zig:19839:    follow_symlinks: bool = true, # Dispatch 内部
```

**`{@TypeOf(@as(StatFileOptions, undefined).follow_symlinks) == bool` 实测 `true`。**
没有 `{ true: file, false: sym_link }` 这种形状——那不是 Zig 0.17 的 API。

### 27.10.2 `lstat` vs `stat` 的三个实测差异

用同一个符号链接（`link_readme` → `README.md`）对比：

```text
| | lstat（follow_symlinks = false） | stat（默认 true） |
|---|---|---|
| `kind` | `sym_link` | `file` |
| `size` | **9**（链接串 `"README.md"` 的长度） | **6**（目标文件大小） |
| `nlink` | 1 | 1 |
| `inode` | 与目标的**不同**（见下） | 目标的 inode |
```

⚠️ **`lstat.inode != stat.inode`**——我最初的测试断言它们相等，实测差了 1：

```text
main.zig:1111:5: error: expected 1349175, found 1349174
    try std.testing.expectEqual(lst.inode, stt.inode);
```

macOS/APFS 给符号链接**自己分配 inode**。所以"lstat 和 stat 的 inode 相等"
这种假设**在 macOS 上是错的**（Linux 上也不保证）。想通过 inode 判断"是不是同一个东西"
必须先确认 `kind`。

### 27.10.3 悬空链接：lstat 能看见，stat 报 FileNotFound

指向不存在目标的链接（dangling link）：

```text
悬空链接 lstat → kind=sym_link size=12（能看见链接本身）
悬空链接 stat → FileNotFound（穿透到不存在的目标）
⇒ 但 readLink 仍能读出目标字符串 =no_such_file（12 字节）——那是它自己写的那一串
```

**遍历时怎么处理悬空链接**：

```text
| 需求 | 做法 |
|---|---|
| 列出目录（不管死活） | `statFile(follow_symlinks = false)`，看 `kind == .sym_link` |
| 只统计有效文件的大小 | `statFile(follow_symlinks = true)`，它会报 `FileNotFound` ⇒ catch 成"跳过" |
| 想知道链接指向哪 | `readLink(io, path, buf)` —— **唯一办法**（`stat` 只会给你目标的存在性） |
| 判断"这个路径存在吗"（含悬空链接） | `access(io, path, .{})`（默认 `follow_symlinks = true`）⇒ 悬空链接**不存在** |
```

⚠️ **悬空链接的 `kind` 是 `.sym_link` 不是 `.file`**，所以按 `*.txt` 过滤时
天然被排除——这是好事，不需要额外处理。但如果你的过滤器是 `kind != .directory`
就当文件处理，那就会把悬空链接当成 0 字节文件。

对应的测试把这三条全断言了：

```zig
// examples/27_tree/main.zig 第 1112-1143 行
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
    // lstat 的 size：POSIX 报**链接串的长度**（"target.txt".len=10）；
    // Windows 实测报 0（符号链接元数据不含目标串）
    if (comptime @import("builtin").os.tag == .windows) {
        try std.testing.expectEqual(@as(u64, 0), lst.size);
    } else {
        try std.testing.expectEqual(lst.size, @as(u64, @intCast("target.txt".len)));
    }

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
```

## 27.11 符号链接与环：`walk` 天然防环

先造一个经典的环：在 `src/` 里放一个指向 `src` 自己的符号链接。

```zig
// examples/27_tree/main.zig 第 655-680 行
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
```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.11 开始 ====
  walk: depth=1 kind=directory path=locked
  walk: depth=2 kind=file      path=locked/secret.txt
  walk: depth=1 kind=directory path=empty
  walk: depth=1 kind=sym_link  path=link_dead
  walk: depth=1 kind=file      path=main.zig
  walk: depth=1 kind=file      path=README.md
  walk: depth=1 kind=sym_link  path=link_readme
  walk: depth=1 kind=directory path=src
  walk: depth=2 kind=file      path=src/app.zig
  walk: depth=2 kind=directory path=src/deep
  walk: depth=3 kind=file      path=src/deep/leaf.txt
  walk: depth=2 kind=file      path=src/util.zig
  walk: depth=2 kind=sym_link  path=src/loop
walk 共 13 条（含 loop 与 link_readme / link_dead 两个链接条目）：
    README.md
    empty
    link_dead
    link_readme
    locked
    locked/secret.txt
    main.zig
    src
    src/app.zig
    src/deep
    src/deep/leaf.txt
    src/loop
    src/util.zig
⇒ walk 靠 entry.kind 决定要不要进（源码 Walker.next：if kind == .directory 则 enter）
   符号链接的 kind 是 .sym_link ⇒ **walk 天生不跟链接，天然防环**
⚠️ 但**手写递归**若写成"lstat 是目录就进"就完了：环会无限套娃直到爆栈
   两种防环手段：① 限制 max_depth（示例 collectFiles 的 max_depth 参数）
   ② 记录已访问的 (dev, inode)，撞上就跳过——Entry.inode 是 u64，够当 key
   （nlink 也有用：>1 说明有硬链接，同一 inode 不止一个名字）
⇒ 想跟链接必须**显式**做：statFile(follow=true) 判目标是不是目录 + visited 集合
   这正是 rsync -L / cp -r -L 的代价：成环时它们会报 too many levels of symbolic links
==== 27.11 结束 ====
```

### 27.11.1 为什么 `walk` 天然防环

`Walker.next` 的全部逻辑（源码 `Dir.zig:365-371`）：

```zig
    pub fn next(self: *Walker, io: Io) !?Walker.Entry {
        const entry = try self.inner.next(io);
        if (entry != null and entry.?.kind == .directory) {
            try self.inner.enter(io, entry.?);      // ← 只有 .directory 才进
        }
        return entry;
    }
```

`src/loop` 的 `kind` 是 `.sym_link`（因为 `readdir` 返回的是 `lstat` 语义的
`d_type`/`d_type`），所以**不会被 `enter`**。这就是 `walk` 天然防环的全部原因。

⚠️ 注意"**报告但不跟进**"这个区别：`loop` **出现在 13 条里**（它是个条目），
但它**下面什么都没有**（没有 `loop/xxx`）。27.8 的测试断言的正是这一点。

### 27.11.2 手写递归的防环：两种手段

**手段 ① 限制深度**（示例 `collectFiles` 的 `max_depth` 参数）：

```zig
// examples/27_tree/main.zig 第 157 行
    if (depth > max_depth) return;
```

简单，但**会漏**：一个合法的 40 层深目录会被截断。真实工具应该
**报错或告警**，而不是静默截断（示例为了输出简洁选了静默，生产代码别这样）。

**手段 ② 记录已访问的 inode**（更彻底）：

```zig
// ✅ 跟链接的正确写法（示例没写，这是补充）
fn walkFollowing(io: std.Io, gpa: std.mem.Allocator, dir: std.Io.Dir, path: []const u8) !void {
    var visited: std.AutoHashMapUnmanaged(u64, void) = .empty;
    defer visited.deinit(gpa);
    try walkFollowingInner(io, gpa, dir, path, &visited);
}

fn walkFollowingInner(
    io: std.Io, gpa: std.mem.Allocator, dir: std.Io.Dir, path: []const u8,
    visited: *std.AutoHashMapUnmanaged(u64, void),
) !void {
    var d = try dir.openDir(io, path, .{ .iterate = true });
    defer d.close(io);
    var it = d.iterate();
    while (try it.next(io)) |e| {
        var buf: [4096]u8 = undefined;
        const child = std.fmt.bufPrint(&buf, "{f}", .{std.fs.path.fmtJoin(&.{ path, e.name })}) catch continue;
        // 关键：用 statFile(follow_symlinks = false) 拿**链接自己**的 inode
        const lst = dir.statFile(io, child, .{ .follow_symlinks = false }) catch continue;
        if (visited.contains(lst.inode)) continue;      // ← 撞上就跳过
        try visited.put(gpa, lst.inode, {});
        if (lst.kind == .sym_link) {
            // 链接：解析目标，只在目标是目录时继续
            const stt = dir.statFile(io, child, .{}) catch continue;  // 悬空链接报 FileNotFound
            if (stt.kind == .directory) try walkFollowingInner(io, gpa, dir, child, visited);
        } else if (lst.kind == .directory) {
            try walkFollowingInner(io, gpa, dir, child, visited);
        }
    }
}
```

⚠️ **`visited` 必须用 `follow_symlinks = false` 的 inode**——如果用
`follow = true`，那链接和目标共用一个 inode，链接本身就被当成"已访问"，
第一次遇到就跳过了（等于没跟）。

⚠️ **只按 inode 去重在跨文件系统时会误判**：`(dev, inode)` 才是全局唯一的
组合。`Dir.Stat` 里**只有 `inode` 没有 `dev`**（实测 9 个字段里没有 dev），
所以严格的做法是拿 `inode` + `openDir` 得到的 `Dir` 的 `stat`（`dir.stat(io)`
有 dev？——实测也没有）。**Zig 的 `Dir` API 不给你 `dev`**，
所以纯 Zig 代码只能靠 inode（同一 `Dir` 树内够用）。

⚠️ **另一种防环：跟随链接时数层数**。POSIX 的 `openat` 有
`AT_BENEATH` / `RESOLVE_BENEATH`（对应 `OpenFileOptions.resolve_beneath`），
能防"逃出目录树"，但**不防环**。`deleteTree` 的错误集里有 `SymLinkLoop`
（实测 `DeleteTreeError` 含它），说明标准库自己也要处理这个问题。

对应的测试断言了"没有任何条目以 `loop/` 开头"：

```zig
// examples/27_tree/main.zig 第 1145-1174 行
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
```

## 27.12 树形数据结构

把文件系统变成内存里的树，是"要多次查询"时的标准做法（比如文件浏览器、
磁盘分析器、构建系统的依赖图）。

```zig
// examples/27_tree/main.zig 第 20-60 行（节选：结构定义与三个查询）
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
```

### 27.12.1 四个字段的设计决定

```text
| 字段 | 类型 | 为什么 |
|---|---|---|
| `name` | `[]const u8`（**dupe 来的**） | basename；⚠️ 不 dupe 的话建完树就全是垃圾（27.5） |
| `path` | `[]const u8`（dupe） | 相对树根的完整路径。**建树时算一次**，比每次现场拼便宜得多 |
| `kind` | `Io.File.Kind` | 决定要不要递归、算不算大小 |
| `size` | `u64` | **建树时 `statFile` 一次**存下来；否则每次显示都要重新 stat |
| `depth` | `usize` | 省掉"数分隔符"的重复计算 |
| `children` | `std.ArrayList(*Node)` | 指针（不是值）：值会把整个子树深拷贝，而且递归返回值拷贝代价高 |
```

⚠️ **`children` 用 `*Node` 不用 `Node`**：值语义下 `append` 要把整个子树
（含所有子孙的 `ArrayList`）搬一次，O(子树大小)。用指针只是拷 8 字节。

⚠️ **`path` 字段是"预计算"的思路**：27.13 的"最深路径"查询，如果不存 `path`
就要在递归里 `std.mem.concat` 拼路径——O(depth²)。存下来就 O(1)。

建树：

```zig
// examples/27_tree/main.zig 第 190-246 行
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
```

**四个关键点**：

1. **`follow_symlinks = false`**（第 217 行）：**建树时用 lstat**，
   这样符号链接**不会**被当成目录递归进去（27.11 的环就断了）。
   如果用 `follow = true`，`src/loop` 的 `st.kind` 是 `.directory` ⇒ 无限递归。
2. **递归传 `child_rel_copy`**（第 220 行）：`child_rel` 指向**栈上**的 `rbuf`，
   下一轮循环就被覆盖了。**必须 dupe**（同 27.5 的教训）。
3. **名字所有权在 `append` 时移交**（第 194 行的注释）：所以 `defer` 里
   **只 `deinit` 不 `free`**。这是"谁分配谁释放"在递归里的标准处理。
4. **两层排序**：先按名字排 `names`（为了 `child_rel` 的构造顺序确定），
   再按 `lessNode` 排 `children`（目录在前）。**后者才是打印顺序的关键**。

### 27.12.2 树形打印：两个真实踩过的坑

```zig
// examples/27_tree/main.zig 第 683-699 行
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
```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.12 开始 ====
把文件系统变成内存里的树：Node{name, path, kind, size, depth, children}
多一个 path 字段（相对树根的完整路径，建树时算好）⇒ 打印/查询都不用现场拼
建树完成：14 个节点 = 6 个文件 + 5 个目录 + 3 个符号链接（根节点是目录）
树形输出（目录在前、同层按名字排序 ⇒ 确定）：
└── zig27_tree_demo/
├── empty/
├── locked/
│   └── secret.txt  6 B
├── src/
│   ├── deep/
│   │   └── leaf.txt  6 B
│   ├── app.zig  3 B
│   ├── loop -> zig27_tree_demo/src/loop（3 B 是链接串长度，不是目标大小）
│   └── util.zig  2 B
├── README.md  6 B
├── link_dead -> zig27_tree_demo/link_dead（12 B 是链接串长度，不是目标大小）
├── link_readme -> zig27_tree_demo/link_readme（9 B 是链接串长度，不是目标大小）
└── main.zig  10 B
⚠️ Node.name / Node.path **必须 dupe**：不dupe 的话树建完就全是垃圾
   （每层的 openDir/iterate 都是局部的，缓冲复用后名字就废了——同 27.5）
⇒ children 用 ArrayList(*Node) + arena：建树 O(节点数) 内存，退出自动整体回收
⇒ print 的缩进前缀用**每层一份的缓冲数组**：不能 prefix ++ inner（编译不过）
   也不能把同一个 buf 往下传（bufPrint 的源和目标重叠 ⇒ panic: @memcpy arguments alias）
==== 27.12 结束 ====
```

⚠️ **坑 ①：`prefix ++ inner` 编译不过**。我最自然的写法是：

```zig
// ❌ 编译错误
fn print(self: *const Node, prefix: []const u8, last: bool) void {
    ...
    const inner = if (last) "    " else "│   ";
    for (self.children.items, 0..) |c, i| {
        c.print(prefix ++ inner, i == self.children.items.len - 1);   // ← 这里
    }
}
```

报错：

```text
main.zig:71:21: error: unable to resolve comptime value
            c.print(prefix ++ inner, i == self.children.items.len - 1);
                    ^~~~~~
main.zig:71:21: note: slice being concatenated must be comptime-known
```

`++` 要求**两侧的长度编译期已知**（它是"拼 comptime 前缀"的操作）。
`prefix` 是运行期切片 ⇒ 报错。

⚠️ **坑 ②：把同一个 buf 往下传会 panic**。改成 `bufPrint` 后：

```zig
// ❌ panic: @memcpy arguments alias
fn print(self: *const Node, prefix: []const u8, buf: []u8, last: bool) void {
    ...
    var child_prefix: [512]u8 = undefined;
    const joined = std.fmt.bufPrint(&child_prefix, "{s}{s}", .{ prefix, inner }) catch prefix;
    for (self.children.items, 0..) |c, i| {
        c.print(joined, buf, i == ...);       // ← 把同一个 buf 传给子节点
    }
}
```

实测栈：

```text
thread 2146822 panic: @memcpy arguments alias
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Writer.zig:611:34: 0x10ba55f9b in write (main)
        @memcpy(w.buffer[w.end..][0..bytes.len], bytes);
                                 ^^^^^^^^^^^^^^
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Writer.zig:627:51: 0x10bb0a24c in writeAll (main)
    while (index < bytes.len) index += try w.write(bytes[index..]);
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Writer.zig:1122:26: 0x10ba517c9 in alignBuffer (main)
        return w.writeAll(buffer);
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Writer.zig:1144:25: 0x10ba5163c in alignBufferOptions (main)
    return w.alignBuffer(buffer, options.width orelse buffer.len, options.alignment, options.fill);
/Volumes/mac004/code/programming/zig/examples/27_tree/main.zig:74:40: 0x10bba83c2 in print (main)
        const joined = std.fmt.bufPrint(buf, "{s}{s}", .{ prefix, inner }) catch prefix;
                                       ^^^^
```

`prefix` 指向 `buf` 自己（因为它就是上一层的 `bufPrint` 结果），
所以 `write` 发现源和目标重叠 ⇒ 直接 panic。

✅ **正解：每层一份缓冲**。

```zig
// examples/27_tree/main.zig 第 5-8 行
/// 27.12：打印树形时"每层一份"的缩进前缀缓冲：够 33 层深、每层 256 字节。
/// `bufs[i][0..lens[i]]` 才是第 i 层的前缀（`undefined` 的部分不能打印）。
const print_max_depth = 32;
const prefix_len = 256;
```

```zig
// examples/27_tree/main.zig 第 62-95 行
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
```

- 根层：前缀是空串；
- 最后一个孩子：后面接 4 个空格（"    "）——**没有竖线**，因为后面没内容了；
- 非最后一个：后面接 `│` + 3 空格（"│   "）——竖线表示"这一层还有兄弟"。

⚠️ **`bufs` 的深度上限（32 层）**：更深的树就打印不出来（`return` 剪掉）。
真实工具要么动态分配（按最大深度），要么就用 arena 现分配。
示例用固定 33×256 = 8.5 KB 栈空间，换来零分配。

⚠️ **`lens` 数组不能省**：`bufs[i]` 是 `[256]u8`，直接 `bufs[i][0..]` 会打印
256 字节的垃圾（`undefined`）。第一次写我漏了 `lens`，输出是一长串空格。

## 27.13 树的三个查询 vs 流式遍历

```zig
// examples/27_tree/main.zig 第 702-742 行
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
```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.13 开始 ====
树上递归：整棵树 33 字节 / 6 个文件
最深节点 = leaf.txt（depth=3，path=zig27_tree_demo/src/deep/leaf.txt）
⇒ 这三个查询都是**树上递归**，不再走文件系统 ⇒ O(节点数) 且零系统调用
⇒ deepest 比的是 path 里的分隔符数（等价于 Walker.Entry.depth() 的算法）
流式版：6 文件 / 4 目录 / 33 字节 / 最深 src/deep/leaf.txt（depth=3）
⇒ 两种口径一致：文件数 6 == 6，字节数 33 == 33（都只数.kind==.file）
⇒ 符号链接两边都不计入字节（它的 size 是链接串的长度，不是目标大小）
⇒ 只要汇总数字 → 流式（内存 O(1)）；要多次查询 / 要排序 / 要 GUI 展示 → 先建树
⇒ 上万条目的目录**别把整棵树读进内存**：walk 的栈是堆分配的，但 name_buffer 也一样
   真要"大树小内存"就用流式 + 外部排序（把路径写临时文件再 sort）
==== 27.13 结束 ====
```

### 27.13.1 两种口径的成本对照

```text
| | 建树 + 树上查询 | walk 流式 |
|---|---|---|
| 内存 | O(节点数) —— 每个节点一个 Node + 一个 dupe 的 name + 一个 path | **O(1)**（只有 Walker 的栈，深度几十层） |
| 系统调用 | 1 次 readdir/目录 + **1 次 statFile/条目**（建树时） | 1 次 readdir/目录 + **1 次 statFile/文件**（查询大小时） |
| 多次查询 | **零系统调用**（都在内存里算） | 每次查询都要重走一遍 |
| 排序 | 内存里 `std.mem.sort` | 要外部排序（写临时文件） |
| 适用 | 文件浏览器、磁盘分析器、GUI | du / 找最大文件 / 数文件数 / 编译输入列表 |
```

**实测数字**：沙盒 14 个节点，两种口径都是 **33 字节 / 6 个文件**——一致。
（符号链接两边都不计入，因为它的 `size` 是链接串长度而不是目标大小。）

### 27.13.2 "大树小内存"的做法

如果你既要处理 100 万个文件，又不想占 200 MB 内存：

```text
1. walk 流式收集，但**只收集路径字符串**（不建Node）
2. 收集到固定大小的分块（比如每 10 万条一块），写临时文件
3. 每块内部 sort，然后再做多路归并
4. 或者：直接用外部排序命令的思路（Zig 标准库没有）
```

⚠️ **`walk` 自己的内存也不小**：`name_buffer` 存的是**当前路径**（不是所有路径），
所以是 O(深度 × 名字长度)；`stack` 是 O(深度) 个 `Iterator`。
**`Iterator` 每个 2048+ 字节**（内嵌缓冲）——所以 1000 层深的目录，
`walk` 的 stack 就是 2 MB。这是"深目录用 `deleteTreeMinStackSize` 省栈"
的同一个原因（20 章 20.9）。

⚠️ **`SelectorIterator` 的 `iterateAssumeFirstIteration` 省掉了复位**：
每层都 `lseek` 回 0 会是 O(目录数) 次额外系统调用，跳过它更快
（源码 `Dir.zig:293`）。

## 27.14 glob 模式匹配：0.17 没有内建

先说结论：**0.17 没有任何内建 glob**。

```zig
// examples/27_tree/main.zig 第 745-753 行
    begin("27.14");
    {
        std.debug.print("@hasDecl(std, \"glob\")={} @hasDecl(std.fs, \"glob\")={} @hasDecl(std.fs.path, \"glob\")={}\n", .{
            @hasDecl(std, "glob"),
            @hasDecl(std.fs, "glob"),
            @hasDecl(std.fs.path, "glob"),
        });
        std.debug.print("⇒ 0.17 **没有任何内建 glob**；std.fs.path 只有 join/basename/extension 这类纯字符串函数\n", .{});
        std.debug.print("示例自带一个回溯版 globMatch：`*` 不跨分隔符、`?` 单字符、`**` 跨任意层\n", .{});
```
==== 27.14 开始 ====
@hasDecl(std, "glob")=false @hasDecl(std.fs, "glob")=false @hasDecl(std.fs.path, "glob")=false
⇒ 0.17 **没有任何内建 glob**；std.fs.path 只有 join/basename/extension 这类纯字符串函数
示例自带一个回溯版 globMatch：`*` 不跨分隔符、`?` 单字符、`**` 跨任意层
```

（20 章 20.10 已经实测过：`std.fs.path` 里的 `join` / `joinZ` / `fmtJoin` /
`dirname` / `basename` / `extension` / `stem` / `isAbsolute` / `resolve` /
`relative` / `componentIterator` **都还在老位置**，因为 `std.fs` 只搬走了
`File` / `Dir`。）

### 27.14.1 自己写一个：回溯实现

```zig
// examples/27_tree/main.zig 第 97-128 行
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
```

**四个通配符的语义**（示例采用的，和 `.gitignore` 基本一致）：

```text
| 模式 | 含义 | 例 |
|---|---|---|
| `*` | 任意串，**不跨 `/`** | `*.txt` 匹配 `a.txt`，**不**匹配 `sub/a.txt` |
| `?` | **恰好一个**字符，不跨 `/` | `?.txt` 匹配 `b.txt`，不匹配 `bb.txt`、不匹配 `ac` |
| `**` | 跨任意层目录 | `**/*.txt` 匹配 `x.txt`（`**/` 的斜杠可省）和 `a/b/x.txt` |
| 字面量 | 其他字符按 `==` 比 | — |
```

14 个用例的实测结果：

```text
  v globMatch(a.md                   , *.md      ) = true
  v globMatch(c.txt                , *.txt     ) = true
  v globMatch(d.log                  , *.txt      ) = false
  v globMatch(b.txt                 , ?.txt    ) = true
  v globMatch(bb.txt               , ?.txt    ) = false
  v globMatch(.gitignore         , .*      ) = true
  v globMatch(empty.txt         , *       ) = true
  v globMatch(src/deep/leaf.txt , src/*.txt ) = false
  v globMatch(src/deep/leaf.txt , **/*.txt   ) = true
  v globMatch(leaf.txt              , **/*.txt   ) = true
  v globMatch(a/b/c.txt           , a/**/c.txt  ) = true
  v globMatch(a/c.txt             , a/**/c.txt  ) = true
  v globMatch(a/b/c.txt           , a/*/c.txt ) = true
  v globMatch(a/b/d/c.txt         , a/*/c.txt ) = false
  14 个用例，失败 0 个
⚠️ 回溯写法两个坑（都实测撞过）：
   (1) `*` 的循环里 i 可以等于 name.len（匹配空串那一支）
       先取 name[i] 再判i==len ⇒ panic: index out of bounds: index 5, len 5
   (2) 必须**先递归再判 '/'**；反过来写 "a/*/c.txt" vs "a/b/c.txt" 会判成 false
⇒ 真实工具（fd / rg / gitignore）用的是正则或状态机：O(n·m) 而回溯最坏指数级
   自己写 glob 时要记住：回溯是**为了讲清原理**，不是**为了快**
```

### 27.14.2 ⚠️ 两个实测踩到的坑

**坑 ①：`i == name.len` 的越界**。`*` 要能匹配空串，所以循环条件是
`i <= name.len`。如果先取 `name[i]` 再判 `i == name.len`：

```zig
// ❌ 越界
var i: usize = 0;
while (i <= name.len) : (i += 1) {
    if (name[i] == '/') break;              // ← i == name.len 时越界
    if (globMatch(name[i..], pattern[1..])) return true;
}
```

实测：

```text
thread 2092463 panic: index out of bounds: index 5, len 5
/tmp/z27probe/p8.zig:129:21: 0x104224e56 in globMatch
            if (name[i] == '/') break; // 单 * 不跨分隔符
                    ^~~~~~~~~~
/tmp/z27probe/p8.zig:32:30: 0x104210fad in main
        const got = globMatch(c.name, c.pat);
```

**坑 ②：判 `'/'` 和递归的顺序反了**。我第一版的 `*` 是：

```zig
// ❌ 顺序错
while (i <= name.len) : (i += 1) {
    if (name[i] == '/') break;
    if (globMatch(name[i..], pattern[1..])) return true;
}
```

结果 `"a/*/c.txt"` vs `"a/b/c.txt"` 判成 **false**——因为 `*` 吃掉 `"b"` 之后
剩下的 pattern 是 `"/c.txt"`，而 name 剩下的是 `"/c.txt"`，**应该匹配**。
但循环走到 `i == 1`（`name[1] == '/'`）时**先 break 了**，没试 `i == 1`
这个位置。正确顺序是**先递归再判界**：

```zig
// ✅ 顺序对
while (i <= name.len) : (i += 1) {
    if (globMatch(name[i..], pattern[1..])) return true;   // 先试
    if (i == name.len) break;
    if (name[i] == '/') break;                              // 再判界
}
```

**这个 bug 只在 14 个用例里的 1 个上出现**（`"a/*/c.txt"` vs `"a/b/c.txt"`），
而且**测试用例少一个就发现不了**。这是"glob 手写最容易漏的边界"清单：

```text
| 必测用例 | 为什么 |
|---|---|
| `*` 匹配空串（`globMatch("x", "*")`）| 触发 `i == name.len` 那一支 |
| `*` 不跨 `/`（`src/*.txt` vs `src/a/b.txt`）| 保证 break 逻辑对 |
| `**` 匹配零层（`**/*.txt` vs `x.txt`）| 保证 `**/` 的斜杠处理对 |
| `**` 匹配多层 | 主体逻辑 |
| `?` 恰好一个（`?.txt` vs `bb.txt`）| `?` 不能当 `*` 用 |
| 字面量前缀（`a*c` vs `abc`、`a*d`）| 不能无脑返回 true |
```

⚠️ **回溯法最坏是指数级**。真实工具的做法：

```text
| 工具 | 做法 |
|---|---|
| `fd` | 编译成正则（`glob` crate 把 `*` 转成 `[^/]*`、`**` 转成 `.*`）|
| `rg` / `.gitignore` | `globset` crate：先转正则，再交给正则引擎（DFA/NFA，线性）|
| `git ls-files` | wildmatch：手写状态机 |
```

**所以自己写 glob 时要记住：回溯是为了讲清原理，不是为了快。**
真要用就把模式转成正则（`std.Uri` 不含正则，但 `std.regex` 存在——
或者直接 `std.process.Child` 调外部工具）。

### 27.14.3 glob 和 walk 组合：最常见的组合技

```zig
// examples/27_tree/main.zig 第 1247-1276 行
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
```

**为什么是 `**/*.txt` 而不是 `*.txt`**：`walk` 给的 `path` 是**相对根的完整路径**，
`sub/c.txt` 用 `*.txt` 匹配不到（`*` 不跨 `/`）。所以对"整棵子树"过滤时
要用 `**/` 前缀——或者只用 `basename` 配 `*.txt`（各有取舍，见下）。

```text
| 写法 | 匹配对象 | 例：命中 `sub/c.txt` |
|---|---|---|
| `globMatch(e.path, "**/*.txt")` | 相对根的完整路径 | ✅ |
| `globMatch(e.basename, "*.txt")` | 只有文件名 | ✅ 但 `a/x.txt` 和 `b/x.txt` 无法区分 |
| `globMatch(e.path, "src/*.txt")` | 相对根、限定一层 | ✅（27.14 用例 8） |
```

## 27.15 目录的建 / 删 / 改：签名与 `io` 的位置

20 章 20.7 讲过建/删/查，本章补齐**遍历相关的**那部分，重点是 `io` 参数的位置。

```zig
// examples/27_tree/main.zig 第 791-829 行
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
        // ⚠️ std 0.17 的 dirHardLink 在 Windows 上直接返 OperationUnsupported，
        // 硬链接演示只能在 POSIX 跑
        if (comptime @import("builtin").os.tag == .windows) {
            std.debug.print("hardLink(old, new_dir, new_path, io, opts) —— io 第 5；⚠️ Windows 上 std 返 OperationUnsupported，跳过演示\n", .{});
        } else {
            try cwd.hardLink(sbox ++ "/main2.zig", cwd, sbox ++ "/main2_hard.zig", io, .{}); // io 第 5
            const s1 = try cwd.statFile(io, sbox ++ "/main2.zig", .{});
            const s2 = try cwd.statFile(io, sbox ++ "/main2_hard.zig", .{});
            std.debug.print("hardLink(old, new_dir, new_path, io, opts) —— io 第 5；inode 相同={} nlink={d}\n", .{ s1.inode == s2.inode, s2.nlink });
        }
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
```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.15 开始 ====
建：createDir(io, path, perms) 建一层 / createDirPath(io, path) 递归
    createDirPathStatus(io, path, perms) 返回 .existed 或 .created
    createDirPathOpen(io, path, opts) 建+开一步，opts 里**套一层** .open_options
删：deleteFile(io, path) / deleteDir(io, path)（非空 → DirNotEmpty）
    deleteTree(io, path) 递归删整棵子树
    deleteTreeMinStackSize(io, path) 同上但省栈（上千层目录用）
查：access(io, path, opts) 存在性/权限（opts 是 **packed struct**）
    stat(io) 对已打开的 Dir 取元数据 / statFile(io, path, opts) 按路径
rename(old, new_dir, new_path, io) —— **io 在第 4 位**（不是第 1 位）
hardLink(old, new_dir, new_path, io, opts) —— io 第 5；inode 相同=true nlink=2
copyFile(src, dst_dir, dst_path, io, opts) —— io 第 5；副本 10 字节
symLinkAtomic(io, target, link, flags) —— **io 在第 1 位**（例外！）
updateFile(io, src, dst_dir, dst, opts) —— io 第 1；两次 = stale / fresh
⇒ 规律：**跨两个 Dir 的方法 io 多半靠后，但 symLinkAtomic / updateFile 是例外**
   搞错了报 member function expected 4 argument(s), found 3 —— 逐个查，别照上一个补io
deleteDir(src) 非空 → DirNotEmpty（保护不是限制：递归删要显式 deleteTree）
access(不存在) → FileNotFound（比 statFile 便宜，但有 TOCTOU）
⚠️ access 说存在 != 下一句 openFile 成功（TOCTOU）；真判断必须在 openFile 的错误上做
==== 27.15 结束 ====
```

**`hardLink` 让 `nlink` 从 1 变 2**（POSIX 实测），`inode` 不变——这就是硬链接的定义。
对比符号链接：符号链接是**新 inode**（27.10.2 实测差 1），硬链接是**同 inode 多名字**。

⚠️ **Windows 实测（0.17）**：`std.Io.Dir.hardLink` 在 Windows 目标上**直接返
`error.OperationUnsupported`**——0.17 std 的 `Io/Threaded.zig` 里 `dirHardLink`
第一行就是 `if (is_windows) return error.OperationUnsupported;`。所以示例里
硬链接演示是 `comptime` 分平台：Windows 只打印说明、跳过调用（测试同理）。
27.15 的其余四个方法（rename / copyFile / symLinkAtomic / updateFile）Windows 都能跑。

⚠️ **TOCTOU**（Time-Of-Check-Time-Of-Use）的老问题在遍历场景特别突出：

```zig
// ❌ 有竞态的写法
if (dir.access(io, path, .{})) |_| {
    const f = try dir.openFile(io, path, .{});   // ← 另一个进程可能刚删了
    ...
} else |_| { /* 不存在 */ }
```

`access` 说存在，下一句 `openFile` 仍可能失败。**真正的判断必须在 `openFile`
的错误上做**（20 章 12.2 说过）。遍历时更要注意：**`Entry` 出来之后、
`statFile` 之前，文件可能已经被别人删了**——所以 `statFile` 的错误也要处理。

对应的测试把四个方法的 `io` 位置和语义都断言了：

```zig
// examples/27_tree/main.zig 第 1305-1334 行
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
```

## 27.16 `Dir.Reader`：第四种方式，批量读

`Iterator` 是"一次一个条目"地要（文档原话：`It is movable by only requesting
one `Entry` at a time`），系统调用次数 = 条目数（虽然有缓冲）。`Dir.Reader`
是"批量 `read`"，系统调用次数 = `ceil(条目数 / 每次读到的个数)`。

```zig
// examples/27_tree/main.zig 第 832-863 行
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
```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.16 开始 ====
Dir.Reader 字段： dir state buffer index end
  state: reset / reading / finished；reset() 回到 reset（等价 lseek 回 0）
  ⚠️ @hasDecl(Dir, "reader") = false—— 没有这个方法，要自己 Dir.Reader.init
  ⚠️ 缓冲必须是 align(@alignOf(usize)) 的：普通 [N]u8 传不进去
     实测报错：expected type '[]align(8) u8', found '*[1048]u8'
               pointer alignment '1' cannot cast into pointer alignment '8'
  read 一次拿到 11 个条目（min_buffer_len=1048 字节，一次系统调用读全）
  读到 11 个（Iterator 一次只要一个条目，Reader 才是批量的）
  reset() 后再 read → 11 个（同一目录能重扫）
⇒ 上万条目的目录用 Reader 能把系统调用次数降一个量级
   但 name 依旧指向那块缓冲 ⇒ 跨 read 收集还是得 dupe（同 27.5）
==== 27.16 结束 ====
```

### 27.16.1 ⚠️ 三个实测的坑

**坑 ①：`Dir` 没有 `reader()` 方法**。`@hasDecl(std.Io.Dir, "reader")` 实测 `false`。
要自己造：`std.Io.Dir.Reader.init(dir, &buf)`。

**坑 ②：缓冲必须 `align(@alignOf(usize))`**。源码签名：

```zig
// lib/std/Io/Dir.zig 第 138 行
    pub fn init(dir: Dir, buffer: []align(@alignOf(usize)) u8) Reader {
```

普通 `[1048]u8` 的对齐是 1，参数要 8：

```text
api.zig:54:41: error: expected type '[]align(8) u8', found '*[1048]u8'
api.zig:54:41: note: pointer alignment '1' cannot cast into pointer alignment '8'
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Dir.zig:138:35: note: parameter type declared here
    pub fn init(dir: Dir, buffer: []align(@alignOf(usize)) u8) Reader {
```

正确写法：

```zig
var rbuf: [std.Io.Dir.Reader.min_buffer_len]u8 align(@alignOf(usize)) = undefined;
var rdr = std.Io.Dir.Reader.init(d, &rbuf);
```

（`Iterator` 的内嵌缓冲就是这么声明的：`reader_buffer: [reader_buffer_len]u8
align(@alignOf(usize))`。）

**坑 ③：`read` 返回 `usize` 不是可选**。`Reader.read(io, &buffer)` 返回
`Error!usize`，读到末尾返回 **0**（不是 `null`）：

```zig
// ✅ 正确的循环
while (true) {
    const n = try rdr.read(io, &batch);
    if (n == 0) break;
    ...
}
```

而 `Reader.next(io)` 返回 `Error!?Entry`（**返回 `null`**，可以直接 `while (try …)`）。
**`read` 和 `next` 的结束语义不一样**——这是 0.17 的一个小不一致。

⚠️ **`read` 也会让 `Entry.name` 失效**（文档：`Entry.name is invalidated with
the next call to read or next`）。所以跨 `read` 收集还是得 `dupe`——**同 27.5**。

⚠️ **`Reader` 也需要 `Dir` 是 `openDir(.{ .iterate = true })` 出来的**吗？
**需要**。`openDir` 的 `iterate` 选项是"这个 Dir 可以被扫描"的总开关，
`Reader.read` 也算扫描。

对应的测试：

```zig
// examples/27_tree/main.zig（Windows 实测后改成了"循环排空"版）
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
    // ⚠️ reset 后**也要循环排空**：Windows 实测单次 read 最多吐 3 条
    // （min 缓冲下 Windows 目录条目更大：UTF-16 名字 + 属性），POSIX 一把 5 条。
    // reset 的语义是"从头再来"，不是"再来一把就是全部"。
    var again_total: usize = 0;
    while (true) {
        const again = try rdr.read(io, &batch);
        if (again == 0) break;
        again_total += again;
    }
    try std.testing.expectEqual(@as(usize, 5), again_total);
    try std.testing.expect(!@hasDecl(std.Io.Dir, "reader")); // 没有 reader 方法
}
```

⚠️ **Windows 实测补充（0.17）**：`reset()` 本身两平台行为一致（3+2+0 = 5 复现），
但**单次 `read` 的批量大小**不一样——macOS min 缓冲一把读完 11 条 / POSIX 测试目录
一把 5 条，Windows 单次最多 3 条（Windows 目录条目带 UTF-16 名字和属性，
同样 1048 字节装得少）。想断言"reset 后读到全部"，必须**循环排空**而不是单次 read。

## 27.17 跨平台差异

```zig
// examples/27_tree/main.zig 第 866-888 行
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
```

运行输出（`examples/27_tree/main.zig`）：
```text
==== 27.17 开始 ====
当前平台 = macos；path.sep = '/'（Windows 上是反斜杠）
⚠️ 大小写敏感性**不是编译期常量**：macOS 默认 APFS 不敏感、Linux ext4 敏感、Windows 不敏感
   Zig 不会替你问文件系统 ⇒ 跨平台代码只能：① 用 openFile 成功与否当判据
   ② 或者两种大小写都试一遍 ③ 或者在UI 上让用户自己输入
   能做的只是**字符串层面**的排序：'A'=='a' 是 false；std.mem.order("A","a") = lt
   ⇒ std.mem.order 是**字节序**（永远大小写敏感），别拿它当"文件名相等"的判据
⇒ Windows 上 .iterate 必须**在 openDir 时**开，否则**迭代时**才报 AccessDenied
   错误时机在迭代处而不是打开处，极具迷惑性；POSIX 不验证这一项（实测能遍历）
⇒ Windows 不许删"正在使用"的目录：openDir 着的目录 deleteTree 会失败
   POSIX 允许 unlink 已打开的文件 ⇒ Linux 上"边遍历边删"能跑，Windows 不能
⇒ Windows 创建符号链接要管理员或开发者模式 ⇒ 依赖链接的代码必须有降级分支
⇒ kind = .unknown 会出现在网络/FUSE 文件系统上 ⇒ 不能把 kind != .file 当"是目录"
⇒ symLink 的 SymLinkFlags.is_directory **只在 Windows 上有意义**（其它平台忽略）
⇒ macOS 上 readdir 返回的名字是**UTF-8 分解形式**（NFD），Linux 上是 NFC
   ⇒ 比对非ASCII 文件名时 memcmp 会莫名失败；要先 std.unicode.normalize
==== 27.17 结束 ====
```

### 27.17.1 七条实测/文档确认的跨平台差异

| # | 差异 | 影响 | 怎么写 |
|---|---|---|---|
| 1 | **路径分隔符** | `join` 出来的是 `\`（Windows）不是 `/` | 用 `std.fs.path.join` / `fmtJoin`，别手拼 `"/"` |
| 2 | **大小写敏感性** | `memcmp("A.txt", "a.txt")` 在 macOS/Windows 上不等于"文件不存在" | 用 `openFile` 成功与否当判据（见下） |
| 3 | **`.iterate` 的验证时机** | Windows 上不开就在**迭代时**报 AccessDenied | 无条件在 `openDir` 时开 |
| 4 | **删除正在使用的目录** | Windows 失败、POSIX 允许 | 遍历前先关掉所有 `Dir` |
| 5 | **符号链接权限** | Windows 要管理员/开发者模式 | `symLink` 的错误要能降级成"复制文件" |
| 6 | **`kind == .unknown`** | 网络/FUSE 文件系统 | 别假设 `kind` 一定填对了 |
| 7 | **Unicode 规范化** | macOS 是 NFD，Linux 是 NFC | 比对前 `std.unicode.normalize` |

**第 2 条的三个实测数字**：

```text
| 表达式 | macOS 实测 |
|---|---|
| `@as(u8, 'A') == @as(u8, 'a')` | `false` |
| `std.mem.order(u8, "A", "a")` | `.lt` |
| `path.sep` | `'/'` |
```

⚠️ **`std.mem.order` 永远大小写敏感**（它是**字节序**），
所以 `sort` 出来的顺序在 macOS 上是 `"A.txt" < "a.txt"`（大写在前），
而 Finder 显示的是 `"a.txt"` 在前。**"排序结果和用户预期不一致"是个真 bug**，
但根因是文件系统的排序规则，不是你的代码。

⚠️ **第 4 条有一个实测的连带后果**：`27.4` 的测试里我 `openDir` 了 `locked`
目录并 `defer d.close(io)`，然后在 `defer` 之前恢复了权限。如果我在 Windows 上
写"遍历时删文件"，就会因为**目录还开着**而失败。POSIX 上能跑（实测 27.5 的
`many` 目录是先建后遍历再删）。

⚠️ **`SymLinkFlags.is_directory` 在非 Windows 平台被忽略**（文档：
`This value is ignored on all hosts except Windows`）。所以写
`symLink(io, target, link, .{ .is_directory = true })` 在 macOS/Linux 上
**是安全的**（不会报错），只是没实际作用。

## 27.18 坑位清单

1. **⚠️ `entry.name` 活不过下一次 `next()`**（27.5）。实测 60 个条目的目录里，
   不 `dupe` 收集的切片**内容有重复**、拿去 `access` **有的报 FileNotFound**。
   小目录一次读完看起来"没事"才是真正的陷阱。跨 `next()` 收集必须 `dupe`。
   同样的坑在 `Dir.Reader.read` 上也有。

2. **⚠️ `if (errorUnion) |x|` 在 0.17 只解包错误层**（27.3）。
   `if (it.next(io)) |x|` 里的 `x` 实测类型是 `?Io.Dir.Entry`，
   直接 `x.name` 报
   `optional type '?Io.Dir.Entry' does not support field access`。
   正确写法：`while (try it.next(io)) |entry|`（解两层）或 `if (try …) |e|`。

3. **⚠️ `cwd()` 是伪句柄（`handle = -2` = `AT_FDCWD`）**（27.9）。
   `cwd().walk(gpa)` **不报错**，但第一次 `next(io)` 直接
   `panic: programmer bug caused syscall error: BADF`——**catch 不住**。
   根因是 Darwin 上 `dirReadDarwin` 要 `lseek` 复位，对 `AT_FDCWD` 做
   `lseek` 就是 `EBADF`。**凡是需要真实 fd 的（`walk`/`stat`/`iterate`/`close`）
   必须先 `openDir`。**

4. **`follow_symlinks` 的类型是 `bool`，不是联合字面量**（27.10）。
   grep 全标准库确认：`follow_symlinks` 一律是 `bool`，没有任何
   `{ true: file, false: sym_link }` 形状的联合类型。

5. **`walk` 的第一个参数是 `Allocator` 不是 `Io`**（27.6）。
   `dir.walk(gpa) Allocator.Error!Walker`——不传 `io`。
   而且 `iterate()` **不带** `io` 但 `next(io)` **带**（不对称设计）。

6. **`walk` 的顺序是 undefined，必须自己排序**（27.6）。
   要可复现的输出就 `ArrayList` + `std.mem.sort`。
   ⚠️ 存进 `ArrayList` 的字符串必须 `dupe`——存 `bufPrint` 到栈缓冲的切片，
   每轮循环都被复用（实测 10 条全变成同一个值）。

7. **`walk` 的 `next` 出错后可以继续调用**（27.4）。源码会把出错的目录**弹栈**
   （注释：`Otherwise, all future next calls would likely just fail with the same
   error`），所以 `catch` 后 `continue` 就能继续遍历上一层剩下的兄弟目录。
   但**手写递归的 `openDir` 出错只能 `return`**——必须在递归体内就地
   `catch` 成"跳过"，否则一个受限目录让整趟遍历失败。

8. **`Walker` 必须 `deinit`，否则栈上的 `Dir` 泄漏**（27.7）。
   `break` 出来时栈上还压着若干 `openDir` 出来的 `Dir`。
   `deinit()` **不会**关掉你最初 `openDir` 的那个 `d`（文档：
   `dir will not be closed after walking it`）——这是设计，不是漏关。

9. **`walk` 天生不跟符号链接（防环），手写递归不会**（27.11）。
   `Walker.next` 只在 `kind == .directory` 时 `enter`，而链接的 `kind` 是
   `.sym_link` ⇒ `walk` 天然防环。**手写递归若用 `follow_symlinks = true`
   建树就会无限递归**（环）。要么 `follow_symlinks = false`，
   要么限制 `max_depth`，要么记visited inode。

10. **`lstat.inode != stat.inode`（macOS/APFS）**（27.10.2）。
    符号链接有自己独立的 inode（实测差 1），**不是**和目标共用。
    "lstat 和 stat 的 inode 相等"这种假设在 macOS 上是错的。

11. **`leave(io)` 弹的是"栈顶目录"不是"刚看到的条目"**（27.8）。
    搞混会导致"以为跳过了 y，实际弹掉了 x"。
    真正的剪枝写法是**白名单式 `enter`**（不 skip 才进），根本不需要 `leave`。

12. **⚠️ `Dir.Reader` 的缓冲必须 `align(@alignOf(usize))`**（27.16）。
    普通 `[N]u8` 报 `expected type '[]align(8) u8', found '*[1048]u8'`。
    而且 `Dir` **没有 `reader()` 方法**（`@hasDecl` 实测 `false`），
    要自己 `Dir.Reader.init(dir, &buf)`。
    ⚠️ `read` 返回 `usize`（末尾是 **0**），`next` 返回 `!?Entry`（末尾是 **null**）——
    **结束语义不一样**。

13. **⚠️ 运行期切片不能用 `++` 拼接**（27.12）。
    `prefix ++ inner` 报
    `error: unable to resolve comptime value / slice being concatenated must be
    comptime-known`。要拼就用 `std.fmt.bufPrint`。
    ⚠️ 而且**不能把同一个 buf 往下传**：`bufPrint(buf, "{s}", .{prefix})` 里
    `prefix` 指向 `buf` 自己 ⇒ `panic: @memcpy arguments alias`。
    正解是**每层一份缓冲**（`[max_depth+1][256]u8` + 一个长度数组）。

14. **glob 的 `*` 循环：`i` 可以等于 `name.len`**（27.14）。
    先取 `name[i]` 再判 `i == name.len` 会
    `panic: index out of bounds: index 5, len 5`。
    而且必须**先递归再判 `'/'`**——反过来写会把
    `"a/*/c.txt"` vs `"a/b/c.txt"` 判成 `false`（实测 14 个用例里就错这 1 个）。

15. **`io` 参数的位置没有统一规律**（27.15）。
    跨两个 `Dir` 的方法（`rename` / `copyFile` / `hardLink`）把 `io` 排在
    **第 4/5 位**；单 `Dir` 的方法排在**第 1 位**；
    而 `updateFile` / `symLink` / `symLinkAtomic` 是"跨 Dir 但 io 在第 1 位"的
    **三个例外**。搞错了报 `member function expected 4 argument(s), found 3`。
    **只能查 27.1.3 的表。**

16. **`.iterate = true` 必须在 `openDir` 时开**（27.1.2、27.17）。
    Windows 上不开会在**迭代时**才报 `error.AccessDenied`（错误时机在迭代处
    而不是打开处，极具迷惑性）。POSIX 不验证这一项——**实测不开也能遍历**，
    所以你的代码在 macOS 上跑通了不代表 Windows 上能跑。

17. **遍历中要防 TOCTOU**（27.15）。`Entry` 出来之后、`statFile` 之前，
    文件可能已被别人删。`access` 说存在也不保证下一句 `openFile` 成功
    （Unix 编程的经典纪律，Zig 不例外）。

18. **别把整棵树读进内存**（27.13）。只要汇总数字就用 `walk` 流式（O(1) 内存）；
    要多次查询/排序/GUI 才建树。而且 `walk` 自己的 stack 也不小——
    每个 `Iterator` 有 2048 字节内嵌缓冲，1000 层深的目录就是 2 MB。

19. **⚠️ Windows 三连（0.17 实测，全量回归抓出来的）**：
    ① `std.posix.AT.FDCWD` 在 Windows 目标**编译期不存在**
    （`struct 'c.AT__struct_731' has no member named 'FDCWD'`），且 `Dir.handle`
    是 `*anyopaque` 不透明句柄——`cwd()` 伪句柄的数值展示只能 `comptime` 分平台。
    ② `Io.File.Permissions` 在 Windows 目标是 `FILE_ATTRIBUTE` 枚举，
    **`fromMode` 是 POSIX 分支才有的方法**，引用即编译错
    `no member named 'fromMode'`；"000 权限目录"在 Windows 上也要 ACL 才造得出来
    ⇒ 锁目录演示只能 POSIX 跑。
    ③ `std.Io.Dir.hardLink` 的 std 实现在 Windows 上**第一行就返
    `error.OperationUnsupported`**（`Io/Threaded.zig` 的 `dirHardLink`）。
    20. **`Walker` 的路径用本机分隔符**：Windows 上是 `sub\b.txt` 不是 `sub/b.txt`。
    断言和 glob 模式都按 `/` 写的话，把 dupe 出来的路径**就地归一成 `/`** 再比
    （本章测试的 `normalizeToSlashInPlace`）。
    21. **`Dir.Reader` 单次 `read` 的批量大小随平台变**：macOS min 缓冲一把 11 条、
    Windows 单次最多 3 条（Windows 条目带 UTF-16 名字 + 属性，同样 1048 字节装得少）。
    断言"reset 后读到全部"必须**循环排空**，不能单次 read。
    22. **`use of undeclared identifier` 是 AstGen 层的错，未选中的 comptime 分支
    也逃不过**——平台分叉里引用的辅助函数必须真实定义出来（见 24 章坑 32）。

---

上一章：[26 编码与流处理](26-encoding.md) · 下一章：[28 文件监视](28-watch.md)
