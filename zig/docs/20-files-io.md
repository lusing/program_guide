# 20 · 文件与 IO

> 对应示例：`examples/20_files/main.zig`（871 行，16 个 test）
>
> 0.16 是一次 breaking 大迁移：`std.fs.File` / `std.fs.Dir` **并入 `std.Io`**，
> 而且**几乎全部方法第一个参数变成了 `io`**。抄旧代码会一路报
> `no field named 'io'`、`expected 2 arguments, found 1`。
>
> 本章把 0.17.0 上 `std.Io.Dir` / `std.Io.File` 的**每一个方法签名逐个实测**，
> 写成一张表（20.1.3 节），然后按"读 / 写 / 目录 / 遍历 / 路径 / JSON / 错误 / 哲学"
> 八条线展开。所有输出都是在 `/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/zig`（0.17.0）上跑出来的。
>
> 本章有**五条结论会推翻你可能听过的说法**：
>
> 1. **`std.Io.File` 没有 `writeAll`、也没有 `readAll`。** 写全部是
>    `writeStreamingAll(io, bytes)`，读是 `readStreaming(io, &.{buf})`
>    （`@hasDecl` 实测两个都是 `false`）。旧教程里的 `file.writeAll(io, x)`
>    编译不过。
> 2. **0.17 的 `takeDelimiterExclusive` 是阻塞式的**（它内部会 `fillMore`）。
>    网上流传的"0.17 里 `takeDelimiterExclusive` 不阻塞、手上没分隔符就返回空片"
>    **在0.17.0 上不成立**：实测它会一路 fill 到找到分隔符，
>    找不到就 `error.StreamTooLong`。
> 3. **`writeFile` 的 `flags.truncate = false` 不等于追加。** 它只是"别截断"，
>    写指针还在 0，所以照样覆盖。实测两次 `writeFile` 后文件是 `"BBB"` 不是 `"AAABBB"`。
> 4. **对 `std.Io.Dir.cwd()` 直接 `walk` 会 panic**
>    （`programmer bug caused syscall error: BADF`）——`cwd()` 在 POSIX 上是
>    `AT_FDCWD` 这个"伪句柄"，而 `walk` 要 seek 它。必须先 `openDir`。
> 5. **`{t}` 打印运行期的 `std.Io.Limit` 会 panic**（`invalid enum value`），
>    因为它是非穷尽枚举（`enum(usize)` 带 `_`）。要打 `@backingInt`。

---

## 20.1 为什么每个方法都要传 io

### 20.1.1 `std.fs` 搬家了，但 `std.fs.path` 没搬

0.16 的大迁移把文件相关的类型从 `std.fs` 挪进了 `std.Io`。实测四个 `@hasDecl` 探针：

```zig
// examples/20_files/main.zig 第 47-49 行
    std.debug.print("std.fs.cwd 在 0.17 **不存在**了（@hasDecl = {}）\n", .{@hasDecl(std.fs, "cwd")});
    std.debug.print("取当前目录的新名字：std.Io.Dir.cwd() → handle={d}（AT_FDCWD={d}）\n", .{ cwd.handle, std.posix.AT.FDCWD });
    std.debug.print("main 拿到的 io 类型 = {s}，来自 init.io（不是全局变量）\n", .{@typeName(@TypeOf(init.io))});
```

运行输出（`examples/20_files/main.zig`）：


```text
std.fs.cwd 在 0.17 **不存在**了（@hasDecl = false）
取当前目录的新名字：std.Io.Dir.cwd() → handle=-2（AT_FDCWD=-2）
main 拿到的 io 类型 = Io，来自 init.io（不是全局变量）
Dir 是**工厂**（凭路径造File），File 是**句柄**（一个已打开的 fd）
⇒ 换掉 io 就换掉了整个 I/O 后端：测试传 std.testing.io，生产传 init.io
⇒ 这是 02 章 init.io 设计的回报，和 15 章的 testing.io 是同一件事
stdio 三件套（0.17 也在 Io 下）：stdin=0 stdout=1 stderr=2
File.stdin() / stdout() / stderr() 都**不带参数**（它们是常量句柄）
==== 20.1 结束 
```

**`handle=-2` 就是 `AT.FDCWD`**，这个数字本身就是个信号：`cwd()` 返回的**不是一个真正的 fd**，而是"每次操作都相对当前目录解析"的意思。20.8 节会看到这一点带来的一个 panic。

四探针的完整结果（实测）：

```text
| 名字 | 存在？ |
|---|---|
| `std.fs.cwd` | ❌ |
| `std.fs.File` | ❌ |
| `std.fs.Dir` | ❌ |
| `std.fs.path` | ✅ |
```

也就是说**`std.fs` 这个命名空间里只剩路径工具和文件系统常量了**。`std.Io.Dir.path` 是个别名，指向同一个类型（`@TypeOf(std.Io.Dir.path) == @TypeOf(std.fs.path)` 实测 `true`），两个名字都能写。

### 20.1.2 Dir 是工厂，File 是句柄

这是本章最该先建立的模型：

- **`Dir` 是工厂**：它不持有资源，是一个"从某个目录出发"的定位器。所有**按路径**的操作
  （`openFile` / `createFile` / `writeFile` / `readFileAlloc` / `createDirPath` /
  `statFile` / `deleteTree` …）都挂在 `Dir` 上。`Dir.cwd()` 不需要 `io`（它纯计算），
  但**其他每一个方法都要 `io`**。
- **`File` 是句柄**：它是一个**已经打开的** fd。所有**按位置**的操作
  （`readStreaming` / `writeStreaming` / `seek` / `stat` / `setLength` / `close`）
  都挂在 `File` 上。`File` 必须 `close(io)`，不 close 就是 fd 泄漏。

```zig
// examples/20_files/main.zig 第 50-56 行
    std.debug.print("Dir 是**工厂**（凭路径造File），File 是**句柄**（一个已打开的 fd）\n", .{});
    std.debug.print("⇒ 换掉 io 就换掉了整个 I/O 后端：测试传 std.testing.io，生产传 init.io\n", .{});
    std.debug.print("⇒ 这是 02 章 init.io 设计的回报，和 15 章的 testing.io 是同一件事\n", .{});
    std.debug.print("stdio 三件套（0.17 也在 Io 下）：stdin={d} stdout={d} stderr={d}\n", .{
        std.Io.File.stdin().handle,
        std.Io.File.stdout().handle,
        std.Io.File.stderr().handle,
```

运行输出（`examples/20_files/main.zig`）：


```text
Dir 是**工厂**（凭路径造File），File 是**句柄**（一个已打开的 fd）
⇒ 换掉 io 就换掉了整个 I/O 后端：测试传 std.testing.io，生产传 init.io
⇒ 这是 02 章 init.io 设计的回报，和 15 章的 testing.io 是同一件事
stdio 三件套（0.17 也在 Io 下）：stdin=0 stdout=1 stderr=2
File.stdin() / stdout() / stderr() 都**不带参数**（它们是常量句柄）
```

注意 `File.stdin()` / `stdout()` / `stderr()` **不带 `io`**——它们返回的是编译期常量（fd 0/1/2），没有任何 I/O 发生。**凡是需要真正做 I/O 的方法，第一个参数才是 `io`。**
这是判断"这个方法做不做 I/O"的最快办法。

### 20.1.3 ⚠️ 全部签名实测表（0.17.0）

这张表是本章的**核心资产**，全部来自 `lib/std/Io/Dir.zig` / `lib/std/Io/File.zig` 的源码 + 探针编译验证。**记这张表比读十遍文档有用**。

`std.Io.Dir` 的方法（`dir` 是方法接收者，即 `dir.xxx(...)`）：

```text
| 方法 | 签名 | `io` 在第几参 |
|---|---|---|
| `cwd` | `cwd() Dir` | 无（纯计算） |
| `openDir` | `(io: Io, sub_path: []const u8, options: OpenOptions) OpenError!Dir` | **1** |
| `close` | `(io: Io) void` | 1 |
| `createFile` | `(io: Io, sub_path, flags: CreateFileOptions) File.OpenError!File` | **1** |
| `openFile` | `(io: Io, sub_path, options: OpenFileOptions) File.OpenError!File` | **1** |
| `writeFile` | `(io: Io, options: WriteFileOptions) WriteFileError!void` | **1** |
| `readFileAlloc` | `(io: Io, sub_path, gpa: Allocator, limit: Io.Limit) ReadFileAllocError![]u8` | **1** |
| `readFileAllocOptions` | `(io, sub_path, gpa, limit, comptime alignment, comptime sentinel)` | 1 |
| `readFile` | `(io, file_path, buffer: []u8) ReadFileError![]u8`（预分配缓冲版） | 1 |
| `statFile` | `(io: Io, sub_path, options: StatFileOptions) StatFileError!Stat` | **1** |
| `stat` | `(io: Io) StatError!Stat`（⚠️ 对 `cwd()` 会 panic，见 20.8） | 1 |
| `createDir` | `(io, sub_path, permissions: Permissions) CreateDirError!void`（单层） | 1 |
| `createDirPath` | `(io: Io, sub_path) CreateDirPathError!void`（递归，旧名 `makePath`） | **1** |
| `createDirPathStatus` | `(io, sub_path, permissions) CreateDirPathError!CreatePathStatus` | 1 |
| `createDirPathOpen` | `(io, sub_path, options: CreateDirPathOpenOptions) Dir`（建+开一步） | 1 |
| `deleteFile` | `(io, sub_path) DeleteFileError!void` | 1 |
| `deleteDir` | `(io, sub_path) DeleteDirError!void`（单层，非空报 `DirNotEmpty`） | 1 |
| `deleteTree` | `(io, sub_path) DeleteTreeError!void`（**递归**） | 1 |
| `deleteTreeMinStackSize` | `(io, sub_path) DeleteTreeError!void`（深目录省栈） | 1 |
| `access` | `(io, sub_path, options: AccessOptions) AccessError!void` | 1 |
| `iterate` | `iterate(dir: Dir) Iterator` | 无（`next` 才有） |
| `walk` | `(allocator: Allocator) Allocator.Error!Walker` | 无 |
| `walkSelectively` | `(allocator: Allocator) !SelectiveWalker` | 无 |
| **`rename`** | `(old_sub_path, new_dir: Dir, new_sub_path, io: Io) RenameError!void` | **4** ⚠️ |
| **`copyFile`** | `(source_path, dest_dir: Dir, dest_path, io: Io, options: CopyFileOptions)` | **4** ⚠️ |
| **`updateFile`** | `(io: Io, source_path, dest_dir: Dir, dest_path, options: CopyFileOptions) !PrevStatus` | **1** ⚠️ |
| **`hardLink`** | `(old_sub_path, new_dir, new_sub_path, io, options: HardLinkOptions)` | **4** ⚠️ |
| `symLink` | `(io: Io, target_path, sym_link_path, flags: SymLinkFlags)` | **1** |
| `symLinkAtomic` | `(io, target_path, sym_link_path, flags)` | 1 |
| `readLink` | `(io, sub_path, buffer: []u8) ReadLinkError!usize` | 1 |
| `realPathFile` | `(io, sub_path, out_buffer: []u8) RealPathFileError!usize` | 1 |
| `realPathFileAlloc` | `(io, sub_path, allocator) ![:0]u8` | 1 |
| `setPermissions` | `(io, new_permissions: File.Permissions)` | 1 |
| `setFilePermissions` | `(io, sub_path, permissions, options)` | 1 |
| `setTimestamps` | `(io, sub_path, options: SetTimestampsOptions)` | 1 |
| `createFileAtomic` | `(io, sub_path, options: CreateFileAtomicOptions) File.Atomic` | 1 |
| `openFileAbsolute` / `createFileAbsolute` / `deleteFileAbsolute` / … | `(io, absolute_path, …)` | 1 |
```

**⚠️ 最重要的一条规律**：**凡是"源和目标分属两个 `Dir`"的方法（`rename` / `copyFile` /
`hardLink` / `symLinkAtomic`），`io` 被排到了参数列表的末尾**；而单 `Dir` 的方法
`io` 在第一个。`updateFile` 是个例外（`io` 在第 1 位）。所以抄写时**不能靠"照着上一个
方法补个 io"**，必须逐个查表。搞错了报的是：

```text
main.zig:72:12: error: member function expected 4 argument(s), found 5
    try cwd.rename("r1.txt", cwd, "r2.txt", io);
        ~~~^~~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Dir.zig:1096:5: note: function declared here
pub fn rename(
```

`std.Io.File` 的方法：

```text
| 方法 | 签名 | 备注 |
|---|---|---|
| `stdin` / `stdout` / `stderr` | `() File` | **无参数**，常量句柄 |
| `close` | `(io: Io) void` | |
| `stat` | `(io: Io) StatError!Stat` | |
| `readStreaming` | `(io, buffer: []const []u8) ReadStreamingError!usize` | **可能返回 0**，`EndOfStream` 表示结束 |
| `readPositional` | `(io, buffer: []const []u8, offset: u64) ReadPositionalError!usize` | 不动全局 seek 位置，线程安全 |
| `readPositionalAll` | `(io, buffer: []u8, offset: u64) ReadPositionalError!usize` | 填满或 EOF |
| `writeStreaming` | `(io, header, data: []const []const u8, splat: usize) Writer.Error!usize` | 低层 |
| **`writeStreamingAll`** | `(io: Io, bytes: []const u8) Writer.Error!void` | ✅ **这才是"写全部"** |
| `writePositional` | `(io, buffer, offset) WritePositionalError!usize` | |
| `writePositionalAll` | `(io, bytes, offset) WritePositionalError!void` | |
| `reader` | `(io, buffer: []u8) Reader` | 默认 positional，回退 streaming |
| `readerStreaming` | `(io, buffer: []u8) Reader` | |
| `writer` | `(io, buffer: []u8) Writer` | 同上 |
| `writerStreaming` | `(io, buffer: []u8) Writer` | |
| `setLength` | `(io, new_length: u64) SetLengthError!void` | **截断就是 `setLength(0)`** |
| `length` | `(io) LengthError!u64` | |
| `sync` | `(io) SyncError!void` | |
| `isTty` | `(io) Io.Cancelable!bool` | |
| `lock` / `unlock` / `tryLock` / `downgradeLock` | `(io, l: Lock)` / `(io)` | |
| `hardLink` | `(io, new_dir, new_sub_path, options)` | |
| `realPath` | `(io, out_buffer: []u8) RealPathError!usize` | |
| `createMemoryMap` | `(io, options: MemoryMap.CreateOptions) MemoryMap` | mmap |
| ❌ `writeAll` | **不存在** | `@hasDecl` 实测 `false` |
| ❌ `readAll` | **不存在** | `@hasDecl` 实测 `false` |
| ❌ `getPos` | **不存在** | 用 `File.Reader.logicalPos()` |
```

`Io.Limit`（20.3 节详述）：

```text
| 名字 | 值 |
|---|---|
| `Io.Limit` | `enum(usize)`，**非穷尽**（有 `_`），成员 `nothing` / `unlimited` |
| `.limited(n: usize)` | `@fromBackingInt(@intCast(n))` |
| `.limited64(n: u64)` | 超过 `maxInt(usize)` 归为 `.unlimited` |
```

三个选项结构体的字段（`@typeInfo` 实测）：

```text
OpenFileOptions:  mode allow_directory path_only lock lock_nonblocking allow_ctty follow_symlinks resolve_beneath
CreateFileOptions: read truncate exclusive lock lock_nonblocking permissions resolve_beneath
OpenOptions(目录):  access_sub_paths iterate follow_symlinks
StatFileOptions:    follow_symlinks
AccessOptions:      follow_symlinks read write execute
CopyFileOptions:    permissions make_path replace
CreateDirPathOpenOptions: open_options permissions
```

## 20.2 打开与创建：两组 flags 完全不同

0.17 把"打开已有文件"和"创建文件"分成了**两个结构体**，它们的字段风格都不一样：
`OpenFileOptions` 用**枚举** `mode`，`CreateFileOptions` 用**布尔** `truncate` / `exclusive`。

```zig
// examples/20_files/main.zig 第 66-76 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
其中 mode 是枚举 u2：.read_only / .write_only / .read_write
CreateFileOptions 字段： read truncate exclusive lock lock_nonblocking permissions resolve_beneath
  truncate 默认 true（覆盖写）；exclusive=true 表示“必须新建”
  exclusive 第二次 → PathAlreadyExists（实测）
  openFile 目录默认允许 → 成功
  allow_directory=false → IsDir（实测）
==== 20.2 结束 ====
```

`Mode` 编译期挑的基整型是 **`u2`**（2 位就够装 3 个成员）——这是 3.9 节那条
"不写基整型时编译器挑最小的"规则的又一例。

`CreateFileOptions` 那一侧：

```zig
// examples/20_files/main.zig 第 81-92 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
CreateFileOptions 字段： read truncate exclusive lock lock_nonblocking permissions resolve_beneath
  truncate 默认 true（覆盖写）；exclusive=true 表示“必须新建”
  exclusive 第二次 → PathAlreadyExists（实测）
```

`exclusive` 是"**必须新建**"语义（O_EXCL）：文件已存在就失败。这是"创建锁文件"
（`.lock` / `.pid`）的标准做法——避免两个进程都以为自己拿到了锁。

### `allow_directory`：打开目录的开关

```zig
// examples/20_files/main.zig 第 97-104 行
        if (cwd.openFile(io, ".", .{})) |f| {
            f.close(io);
            std.debug.print("  openFile 目录默认允许 → 成功\n", .{});
        } else |err| std.debug.print("  openFile(“.”) → {s}\n", .{@errorName(err)});
        if (cwd.openFile(io, ".", .{ .allow_directory = false })) |f| {
            f.close(io);
            std.debug.print("  allow_directory=false 仍成功？不该\n", .{});
        } else |err| std.debug.print("  allow_directory=false → {s}（实测）\n", .{@errorName(err)});
```

运行输出（`examples/20_files/main.zig`）：


```text
  openFile 目录默认允许 → 成功
  allow_directory=false → IsDir（实测）
```

**默认 `allow_directory = true`**：POSIX 上 `open(".", O_RDONLY)` 合法，
所以 `f` 是个能 `stat` 但不能 `read` 的句柄（读它报 `IsDir`）。设成 `false` 之后，
`openFile` 这一步就直接报 `error.IsDir`——**错误提前到了打开时**，而不是让你在
几百行之后读文件时才发现。源码注释说这个选项在 Windows 上零成本实现，
其它平台要多一次 `fstat`。

## 20.3 读文件：`readFileAlloc` 的上限是 `Io.Limit`

一次读全文件，是"读小文件"的默认选择：

```zig
// examples/20_files/main.zig 第 111-118 行
        const text = try cwd.readFileAlloc(io, "demo_conf.txt", mem, .limited(1024 * 1024));
        std.debug.print("readFileAlloc 读到 {d} 字节：{s}", .{ text.len, text });
        // 上限参数的类型就是 std.Io.Limit（不是 usize！），这是 0.17 的关键变化
        const LT = @typeInfo(std.Io.Limit);
        std.debug.print("  第 4 参类型 = {s}，是 enum(usize)（基整型 {s}）\n", .{
            @typeName(std.Io.Limit),
            @typeName(LT.@"enum".tag_type),
        });
```

运行输出（`examples/20_files/main.zig`）：


```text
readFileAlloc 读到 19 字节：name=zig
retries=3
  第 4 参类型 = Io.Limit，是 enum(usize)（基整型 usize）
```

**第四个参数的类型在 0.17 是 `std.Io.Limit`，不是 `usize`。** 旧代码写
`readFileAlloc(io, path, gpa, 1024 * 1024)` 会报类型不匹配。构造方式：

```zig
// examples/20_files/main.zig 第 119-124 行
        std.debug.print("  .limited(64) 的 backing={d}；.unlimited 的 backing={d}；.nothing={d}\n", .{
            @backingInt(std.Io.Limit.limited(64)),
            @backingInt(std.Io.Limit.unlimited),
            @backingInt(std.Io.Limit.nothing),
        });
        std.debug.print("  ⚠️ Io.Limit 是**非穷尽枚举**，运行期值用 {{t}} 打印会 panic\n", .{});
```

运行输出（`examples/20_files/main.zig`）：


```text
.limited(64) 的 backing=64；.unlimited 的 backing=18446744073709551615；.nothing=0
  ⚠️ Io.Limit 是**非穷尽枚举**，运行期值用 {t} 打印会 panic
     （实测 panic: invalid enum value，见坑位清单）
```

`.limited(64)` 造出来的是一个**没有对应枚举成员**的值（`backing=64`，
成员表里只有 `nothing=0` 和 `unlimited=maxInt`）。所以：

- `@tagName` 不能用（没有名字）；
- `{t}` 格式化会 panic，因为 `printValue` 的 `.@"enum"` 分支要 `@tagName(value)`
  ——而这对非穷尽枚举的运行期值会 `unreachable`。实测栈：

```text
thread 1388528 panic: invalid enum value
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Writer.zig:1298:83: 0x10b341416 in printValue__func_925 (sem2)
                .@"enum", .enum_literal, .@"union" => return w.alignBufferOptions(@tagName(value), options),
                                                                                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

**要打印就打 `@backingInt(x)`**（本教程全章都这么写）。

### 上限的作用：把"内存抽干"变成错误

```zig
// examples/20_files/main.zig 第 129-131 行
        if (cwd.readFileAlloc(io, "demo_conf.txt", mem, .limited(4))) |_| {
            std.debug.print("  limit=4 读 17 字节成功？不该\n", .{});
        } else |err| std.debug.print("  limit=4 读 19 字节文件 → {s}（实测）\n", .{@errorName(err)});
```

运行输出（`examples/20_files/main.zig`）：


```text
  limit=4 读 19 字节文件 → StreamTooLong（实测）
```

`error.StreamTooLong` 是 `ReadFileAllocError` 独有的成员（源码 `Dir.zig` 第 1316-1319 行）：

```zig
pub const ReadFileAllocError = File.OpenError || File.Reader.Error || Allocator.Error || error{
    /// File size reached or exceeded the provided limit.
    StreamTooLong,
};
```

**没有上限参数会怎样**：一个 8 GB 的日志文件会把进程内存吃光然后被 OOM killer 干掉
（`error.OutOfMemory` 甚至来不及返回）。有了上限，它是一个**可处理的错误**。
这就是 20.3 的全部意义：**上限不是防御性冗余，是把不可恢复的崩溃降级成可 catch 的分支**。

对应的测试：

```zig
// examples/20_files/main.zig 第 561-576 行
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
```

⚠️ 注意 `expectError` 那两行**故意不 free 返回值**——但它们返回的是错误，
没有缓冲区产生，所以不泄漏。而第一行的 `got` 必须 `defer a.free(got)`，
否则 15.8 节的泄漏检测会让整个 `zig test` 判失败。

## 20.4 缓冲 Reader：三件套与一个必须纠正的传言

### 20.4.1 ⚠️ `takeDelimiterExclusive` 在 0.17 是阻塞式的

这是本章最重要的一条纠正。网上（包括本教程的某些中间版本）流传着
"0.17 里 `takeDelimiterExclusive` 不阻塞，手上没有分隔符就立刻返回空片"——
**0.17.0 上不成立**。

源码路径很清晰：`takeDelimiterExclusive` → `peekDelimiterExclusive`
（`Reader.zig` 第 948 行）→ `peekDelimiterInclusive`（第 841 行），
后者是一个 `while (true) {{ try fillMore(r); ... }}` 的循环。
**它会一路 `fillMore` 直到找到分隔符。**

实测：4 字节缓冲读 6 字节的行，直接 `error.StreamTooLong`：

```zig
// examples/20_files/main.zig 第 140-141 行
        const f = try cwd.openFile(io, "demo_lines.txt", .{});
        defer f.close(io);
```

运行输出（`examples/20_files/main.zig`）：


```text
  4 字节缓冲 takeDelimiterExclusive → StreamTooLong（实测）
  ⚠️ 0.17 的 takeDelimiterExclusive **会** fillMore（即：它是阻塞式的）
     它的限制是“分隔符必须在 Reader 缓冲容量内”，超了报 StreamTooLong
  
```

我用一个"每次 `stream` 只吐 1 字节"的假 `Io.Reader` 交叉验证过：源是 `"ab\ncd\nef"`，
读第一行 `"ab"` 时底层 `stream` 被调了 **3 次**——它确实在反复取数据。

**真正的限制**是文档注释里那句：`If the delimiter is not found within a number
of bytes matching the capacity of this Reader, error.StreamTooLong is returned`。
也就是说**行的长度不能超过 Reader 的缓冲容量**。这不是"阻塞"问题，是"缓冲不够"问题。

```text
| 你想要的 | 0.17 的正确写法 |
|---|---|
| 分隔符短（CSV、日志行），且保证 ≤ 缓冲 | `try r.takeDelimiterExclusive('\n')`，循环到 `error.EndOfStream` |
| 分隔符长度可能超过缓冲（长行、迷你 CSV） | 手工三件套（20.4.2） |
| 只要一个"可能有数据也可能没有"的单片 | `readSliceShort`（20.4.4） |
```

### 20.4.2 正确姿势：`fillMore` + `indexOfScalarPos` + `toss`

三件套的语义（`Reader.zig`）：

```text
| 方法 | 签名 | 作用 |
|---|---|---|
| `fillMore` | `(r: *Reader) Error!void` | 至少再取一批数据进缓冲；**EOF 时返回 `error.EndOfStream`** |
| `buffered` | `(r: *Reader) []u8` | 返回 `[seek..end]` 的未消费切片（**不拷贝**） |
| `toss` | `(r: *Reader, n: usize) void` | 丢弃前 n 字节（`seek += n`） |
```

```zig
// examples/20_files/main.zig 第 152-185 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
第 1 行 =alpha
  第 2 行 =beta
  第 3 行 =gamma
  共 3 行 ⇒ 4 字节缓冲照样读出 6 字节的行（补齐逻辑要自己写）
  readSliceShort(16字节缓冲) 于 19 字节文件 → 16 字节（填满，没报 EOF）
  ⚠️ 它是“填满或 EOF”语义：当单次 read 用会多读/报 EndOfStream
  File.Reader 字段：io file err mode pos size interface（@hasDecl(interface)=false，它是字段不是函数）
  初始 logicalPos=0，pos=0，size=null，mode=positional
  seekTo(5) 后读 =zig
，logicalPos=9
  seekBy(-2) 后 logicalPos=7
  ⚠️ 没有 getPos()：用 logicalPos()（已消费逻辑位置，跨 rebase 也准）
```

**4 个字节的缓冲读出了 6 字节的行**——因为 `toss` 之后 Reader 会 rebase 缓冲，
下一次 `fillMore` 填进来的数据接在后面，而**行内容的组装由你负责**。
这是本节真正的结论：**`Reader` 只保证"缓冲里有这些字节"，它不保证"这些字节构成一行"。**

三个必须记住的细节：

1. **`fillMore` 在 EOF 时返回 `error.EndOfStream`，不是 `void`**。所以不能写
   `try r.fillMore()` 了事——必须在 `catch` 里处理。而且 EOF 那一刻
   `buffered()` **可能还有零头**（没有末尾换行的最后一行）。
2. **`toss` 的 n 不能超过 `end - seek`**，否则 `assert(r.seek <= r.end)` 直接 panic。
   写法必须是 `toss(if (idx) |k| k + 1 else avail.len)`——
   没找到分隔符时 `idx orelse avail.len` 等于 `avail.len`，再 `+1` 就越界了。
   我第一次写 `r.toss(idx + 1)`（`idx` 是 `?usize`，`null + 1 = 1`）就撞上了：

```text
thread 1366534 panic: reached unreachable code
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/debug.zig:442:14: 0x104bdefad in assert
    if (!ok) unreachable; // assertion failure
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Reader.zig:556:11: 0x104be05a8 in toss
    assert(r.seek <= r.end);
```

3. **`buffered()` 返回的切片在下一次 `fillMore` 后就失效**（rebase 会移动数据）。
   要留存就 `@memcpy` 出来。

对应的测试把这个模式守成了断言——4 字节缓冲读 3 个 5 字母的行，拼起来必须是 `"alphabetagamma"`：

```zig
// examples/20_files/main.zig 第 576-607 行
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
```

### 20.4.3 `File.Reader` 的字段与 seek

```zig
// examples/20_files/main.zig 第 191-202 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
  File.Reader 字段：io file err mode pos size interface（@hasDecl(interface)=false，它是字段不是函数）
  初始 logicalPos=0，pos=0，size=null，mode=positional
  seekTo(5) 后读 =zig
，logicalPos=9
  seekBy(-2) 后 logicalPos=7
  ⚠️ 没有 getPos()：用 logicalPos()（已消费逻辑位置，跨 rebase 也准）
```

三点：

- **`interface` 是字段不是函数**。`f.reader(io, buf)` 返回 `File.Reader`，
  它的 `.interface` 字段是 `std.Io.Reader`——**这才是那些 `fillMore`/`buffered`/`toss`
  方法的宿主**。所以调用写法是 `fr.interface.fillMore()`。
  `@hasDecl(std.Io.File.Reader, "interface")` 实测 `false`（`@hasDecl` 只查 `pub fn`/`pub const`，
  字段不在其中）。
- **`pos` 和 `logicalPos()` 不是一回事**。`pos` 是文件里的真实偏移，
  `logicalPos()` 是"你已经消费了多少字节"。后者才是"我现在读到哪了"的答案。
- **`size` 初始是 `null`**，第一次需要时才 `stat`（`getSize()` 会触发）。
  默认 `mode` 是 `.positional`——**用 pread/pwrite，不动全局 seek 位置，所以线程安全**。
  这也是 0.17 的默认值，比老 `readerStreaming` 安全。

### 20.4.4 ⚠️ `readSliceShort` 是"填满或 EOF"

它的语义**不是"读一次"**，而是"尽力把 buffer 填满，或者读到 EOF"：

```zig
// examples/20_files/main.zig 第 201-207 行
        const f = try cwd.openFile(io, "demo_conf.txt", .{});
        defer f.close(io);
        var fr = f.reader(io, &.{});
        std.debug.print("  File.Reader 字段：io file err mode pos size interface（@hasDecl(interface)={}，它是字段不是函数）\n", .{@hasDecl(std.Io.File.Reader, "interface")});
        std.debug.print("  初始 logicalPos={d}，pos={d}，size={?d}，mode={t}\n", .{ fr.logicalPos(), fr.pos, fr.size, fr.mode });
        try fr.seekTo(5);
        var tb: [4]u8 = undefined;
```

运行输出（`examples/20_files/main.zig`）：


```text
  readSliceShort(16字节缓冲) 于 19 字节文件 → 16 字节（填满，没报 EOF）
  ⚠️ 它是“填满或 EOF”语义：当单次 read 用会多读/报 EndOfStream
```

我第一次用它读 socket 式的"来一段"数据，拿到的是**尽可能多**的 16 字节而不是"来多少要多少"。
返回短于 `buffer.len` **只发生在 EOF**。要真正的"读多少算多少"，用 `take(n)`；
要"必须填满"用 `readSliceAll`（源短于 buf 时报 `error.EndOfStream`）。

对比表（实测，两个都在下面的 test 里）：

```text
| 调用 | 源 8 字节 / buf 3 | 源 2 字节 / buf 8 |
|---|---|---|
| `readSliceShort(&buf)` | 返回 **3** | 返回 **2** |
| `readSliceAll(&buf)` | 返回 3，buf 填满 | **`error.EndOfStream`** |
```

```zig
// examples/20_files/main.zig 第 606-615 行
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
```

## 20.5 写文件：`writeStreamingAll` 与 flush 契约

### 20.5.1 ⚠️ `File.writeAll` 不存在

```zig
// examples/20_files/main.zig 第 218-222 行
    std.debug.print("@hasDecl(Io.File, “writeAll”) = {}（0.17 **没有**这个方法）\n", .{@hasDecl(std.Io.File, "writeAll")});
    std.debug.print("@hasDecl(Io.File, “writeStreamingAll”) = {} ← 这才是“写全部”\n", .{@hasDecl(std.Io.File, "writeStreamingAll")});
    std.debug.print("@hasDecl(Io.File, “readAll”) = {}；@hasDecl(Io.File, “readStreaming”) = {}\n", .{
        @hasDecl(std.Io.File, "readAll"),
        @hasDecl(std.Io.File, "readStreaming"),
```

运行输出（`examples/20_files/main.zig`）：


```text
@hasDecl(Io.File, “writeAll”) = false（0.17 **没有**这个方法）
@hasDecl(Io.File, “writeStreamingAll”) = true← 这才是“写全部”
@hasDecl(Io.File, “readAll”) = false；@hasDecl(Io.File, “readStreaming”) = true
```

**改名对照**（旧 → 0.17）：

```text
| 旧教程写法 | 0.17 正确写法 |
|---|---|
| `file.writeAll(io, bytes)` | `file.writeStreamingAll(io, bytes)` |
| `file.readAll(io, buf)` | `file.readStreaming(io, &.{buf})`（返回 `usize`，**可能 0**） |
| `file.getPos()` | `reader.logicalPos()` |
| `file.seekTo(offset)` | `File.Reader/Writer.seekTo`（**挂 Reader/Writer 上，不挂 File**） |
```

`writeStreamingAll` 的实现（`File.zig` 第 620-625 行）就是一层薄封装，
**它没有缓冲**（不走 `Io.Writer`），直接循环调 `writeStreaming` 直到写完：

```zig
/// Equivalent to creating a streaming writer, writing `bytes`, and then flushing.
pub fn writeStreamingAll(file: File, io: Io, bytes: []const u8) Writer.Error!void {
    var index: usize = 0;
    while (index < bytes.len) {
        index += try writeStreaming(file, io, &.{}, &.{bytes[index..]}, 1);
    }
}
```

所以 `writeStreamingAll` **不需要 flush**（它没有中间缓冲）。要 flush 的是
`file.writer(io, buf)` 这条路。

### 20.5.2 ⚠️ 忘 flush → 文件 0 字节

文件 Writer **有真正的用户态中间暂存**，忘 flush 内容全丢：

```zig
// examples/20_files/main.zig 第 227-238 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
  忘 flush 后文件大小 = 0 字节 ⇒ 缓冲 Writer 的内容全丢（实测）
```

**18 个字节的内容写进去，文件是 0 字节。** 文件被创建了、也 close 了，
就是没 flush。`f.close(io)` **不会**替你 flush——因为 `File.close` 是
`io.vtable.fileClose`，它跟 `Io.Writer` 的缓冲毫无关系。

flush 之后：

```zig
// examples/20_files/main.zig 第 238-245 行
        const f = try cwd.createFile(io, "demo_flush.txt", .{});
        var b: [64]u8 = undefined;
        var fw = f.writer(io, &b);
        try fw.interface.print("flush 过的内容", .{});
        std.debug.print("    写完还没 flush：logicalPos={d}，缓冲里 {d} 字节\n", .{ fw.logicalPos(), fw.interface.buffered().len });
        try fw.interface.flush();
        std.debug.print("  flush 之后：缓冲里 {d} 字节（已交给内核）\n", .{fw.interface.buffered().len});
        f.close(io);
```

运行输出（`examples/20_files/main.zig`）：


```text
  写完还没 flush：logicalPos=18，缓冲里 18 字节
  flush 之后：缓冲里 0 字节（已交给内核）
  flush 后文件大小 = 18 字节（flush 过的内容）
```

**`buffered()` 归零就是"数据交给内核了"的证据**。这个观察被守成了测试：
flush 前后 `logicalPos` 不变（flush 只提交，不改逻辑位置），
只有 `buffered().len` 从 10 变 0。

### 20.5.3 `write` / `writeAll` / `end` 的区别

这三个都在 **`Io.Writer`** 上（不是 `File`）：

```text
| 方法 | 返回 | 语义 |
|---|---|---|
| `write(bytes)` | `!usize` | **可能短写**（写了几字节） |
| `writeAll(bytes)` | `!void` | 循环直到写完 |
| `print(fmt, args)` | `!void` | 格式化后 `writeAll` |
| `flush()` | `!void` | 把用户态缓冲交给内核 |
| `end()` | `EndError!void` | `flush` + 按 `logicalPos` 截断/补齐（文件专用） |
```

```zig
// examples/20_files/main.zig 第 252-260 行
        const f = try cwd.createFile(io, "demo_writeall.txt", .{});
        var b: [64]u8 = undefined;
        var fw = f.writer(io, &b);
        const n = try fw.interface.write("12345");
        std.debug.print("  Io.Writer.write 返回 {d}（可能短写）；writeAll 保证写完\n", .{n});
        try fw.interface.writeAll("67890");
        try fw.end(); // end = flush + 按 logicalPos 截断/补齐
        f.close(io);
        std.debug.print("  write+writeAll+end() 后文件大小 = {d}（实测）\n", .{(try cwd.statFile(io, "demo_writeall.txt", .{})).size});
```

运行输出（`examples/20_files/main.zig`）：


```text
  Io.Writer.write 返回 5（可能短写）；writeAll 保证写完
  write+writeAll+end() 后文件大小 = 10（实测）
```

**`end()` 是 `File.Writer` 独有的**（`Writer.zig` 第 237 行），普通 `Io.Writer` 没有。
它的额外价值：如果你 seek 过（比如覆写文件中间），`end()` 会把文件**截到
`logicalPos`**，不会留下尾巴。要"**打开就截断**"的效果，`createFile` 的
`.truncate = true`（默认值）更直接。

## 20.6 追加与截断：`truncate = false` 不是 append

### 20.6.1 ⚠️ 最容易误会的一条

`writeFile` 的 `flags` 里**有** `truncate`，设成 `false` 只是"别截断"，
**但写指针还在 0**——所以照样覆盖：

```zig
// examples/20_files/main.zig 第 267-276 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
truncate=false 再 writeFile → BBB（3 字节）⇒ **没有追加，是覆盖**
⚠️ writeFile 从不从 O_APPEND 位置写；要追加得自己 createFile + seekTo(end)
  createFile(truncate=false)+seekTo(末尾)+写 → BBBBBB（6 字节）
  setLength(0) 后长度 = 0
  截断后写入 → new
```

`writeFile` 的实现（`Dir.zig` 第 661-665 行）压根没有 seek，就是
"createFile → writeStreamingAll(全部) → close"：

```zig
pub fn writeFile(dir: Dir, io: Io, options: WriteFileOptions) WriteFileError!void {
    var file = try dir.createFile(io, options.sub_path, options.flags);
    defer file.close(io);
    try file.writeStreamingAll(io, options.data);
}
```

**它没有 `O_APPEND`，也没有 `f.seekTo(0, .end)`。** 所以语义永远是"从 0 写"。

### 20.6.2 真正的追加：三个步骤

```zig
// examples/20_files/main.zig 第 277-286 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
  createFile(truncate=false)+seekTo(末尾)+写 → BBBBBB（6 字节）
```

**"BBB" + "BBB" = "BBBBBB"**——追加成功（注意起点是 3，因为前一步已经把它覆盖成 "BBB" 了；
如果是原始的 "AAA" 则得到 "AAABBB"）。三步缺一不可：

1. `createFile(..., .{ .truncate = false })` —— 不清空；
2. `setLength(io, 原长度)` **或** `seekTo(原长度)` —— 定位到末尾；
3. 写 + **flush**。

`seekTo` 挂在 **`File.Writer`** 上（不是 `File`），因为"定位"是 Writer 的概念。
配合 `Writer.logicalPos()` 你可以先把当前末尾位置读出来再写。

### 20.6.3 截断：`setLength(0)` + 覆盖写

```zig
// examples/20_files/main.zig 第 290-299 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
  setLength(0) 后长度 = 0
  截断后写入 → new
```

**注意必须用 `openFile(.{ .mode = .read_write })`**——`createFile` 的默认 flags
没有"读写"这个选项（只有 `read` 一个 bool，而且它和 `truncate` 联动）。
要"原地改写一个已存在的文件"，`openFile` + `mode = .read_write` 是唯一入口。

**"打开并截断"其实不需要两步**：`createFile` 的 `truncate` 默认就是 `true`。
`setLength` 的价值在**中间的"截短"**（保留前 N 字节）和**"延长"**（补零）。

## 20.7 目录：建 / 开 / 存在性 / 重命名

### 20.7.1 建目录的三种粒度

```text
| 方法 | 建几层 | 存在时 |
|---|---|---|
| `createDir(sub_path, permissions)` | **1 层** | `error.PathAlreadyExists` |
| `createDirPath(sub_path)` | **递归**（旧名 `makePath`） | **静默成功** |
| `createDirPathStatus(sub_path, perms)` | **递归** | 返回 `.existed` |
| `createDirPathOpen(sub_path, opts)` | **递归 + 打开** | 直接拿到 `Dir` |
```

```zig
// examples/20_files/main.zig 第 306-313 行
    try cwd.createDirPath(io, "demo_dir/sub"); // 递归建（旧名 makePath）
    {
        const st1 = try cwd.createDirPathStatus(io, "demo_dir/sub", .default_dir);
        std.debug.print("  createDirPathStatus 已存在 → {t}\n", .{st1});
        const st2 = try cwd.createDirPathStatus(io, "demo_dir/other", .default_dir);
        std.debug.print("  新建 → {t}（.existed / .created）\n", .{st2});
        cwd.deleteTree(io, "demo_dir/other") catch {};
    }
```

运行输出（`examples/20_files/main.zig`）：


```text
  createDirPathStatus 已存在 → existed
  新建 → created（.existed / .created）
```

`createDirPathStatus` 的返回类型是 `enum { existed, created }`。
**"目录建好了吗"是个程序逻辑问题**（比如安装器要幂等），所以库把这个信息返回给你，
而不是像 `createDirPath` 那样默默吃掉。

`createDirPathOpen` 的一步式（选项里**套**一个 `open_options`）：

```zig
// examples/20_files/main.zig 第 342-348 行
        var d = try cwd.createDirPathOpen(io, "demo_dir/sub2/deep", .{ .open_options = .{ .iterate = true } });
        defer d.close(io);
        var it = d.iterate();
        var cnt: usize = 0;
        while (try it.next(io)) |_| cnt += 1;
        std.debug.print("createDirPathOpen 一步拿到可遍历 Dir，条目数={d}（空目录）\n", .{cnt});
    }
```

运行输出（`examples/20_files/main.zig`）：


```text
createDirPathOpen 一步拿到可遍历 Dir，条目数=0（空目录）
```

⚠️ 注意选项的形状是 `.{ .open_options = .{ .iterate = true } }`——
**多包了一层**。写成 `.{ .iterate = true }` 报：

```text
api.zig:143:58: error: no field named 'iterate' in struct 'Io.Dir.CreateDirPathOpenOptions'
```

### 20.7.2 `access`：比 `statFile` 便宜的存在性检查

```zig
// examples/20_files/main.zig 第 316-328 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
access 存在文件 → ok
access 不存在 → FileNotFound
access execute（非可执行）→ AccessDenied
  AccessOptions 字段： follow_symlinks read write execute
```

**`AccessError` 只有四个成员**（`Dir.zig` 第 411 行）：`FileNotFound`、
`AccessDenied`、`PermissionDenied`、`SystemResources`。这是个刻意收窄的错误集——
它只回答"能不能"，不回答别的。所以"文件在不在"用 `access`，
"文件多大/什么时候改的"用 `statFile`。

⚠️ **TOCTOU**：`access` 说存在，下一句 `openFile` 仍可能失败（另一个进程刚删了）。
`access` 只能用来做**优化**（比如"不存在就走创建分支"），
**真正的判断必须在 `openFile` 的错误上做**。这是 Unix 编程的经典纪律，Zig 不例外。

### 20.7.3 ⚠️ `rename` 的 `io` 在最后

```zig
// examples/20_files/main.zig 第 332-338 行
        try cwd.rename("demo_dir/f.txt", cwd, "demo_dir/g.txt", io);
        if (cwd.statFile(io, "demo_dir/f.txt", .{})) |_| {
            std.debug.print("  rename 后旧名仍存在？\n", .{});
        } else |err| std.debug.print("rename f→g：旧名 statFile → {s}，新名 {d} 字节\n", .{
            @errorName(err),
            (try cwd.statFile(io, "demo_dir/g.txt", .{})).size,
        });
```

运行输出（`examples/20_files/main.zig`）：


```text
rename f→g：旧名 statFile → FileNotFound，新名 1 字节
```

签名是 `rename(old_sub_path, new_dir, new_sub_path, io)`——**`io` 在第 4 位**，
和 `openFile` 那种"第 1 位"完全不同。这条规律在 20.1.3 的表里：
**跨 `Dir` 的方法，`io` 靠后**。

同一族的还有 `copyFile`（`(source_path, dest_dir, dest_path, io, options)`）、
`hardLink`、`symLinkAtomic`。而 `symLink` / `updateFile` 是例外（`io` 在第 1 位）。
**没有规律可循，只能查表。**

`updateFile` 的返回值是 `enum { stale, fresh }`——"这次真复制了"还是"源和目标一样，跳过了"。
用它实现增量构建：

```zig
var src = try cwd.openDir(io, "p_dir", .{});
defer src.close(io);
const st1 = try src.updateFile(io, "a.txt", cwd, "p_dir/a_upd.txt", .{});
std.debug.print("updateFile 第一次 = {t}（.stale = 刚复制过）\n", .{st1});
const st2 = try src.updateFile(io, "a.txt", cwd, "p_dir/a_upd.txt", .{});
std.debug.print("updateFile 第二次 = {t}（.fresh = 没变，跳过复制）\n", .{st2});
```

实测输出（探针 `build/probe20/api.zig`）：

```text
updateFile 第一次 = stale（.stale = 刚复制过）
updateFile 第二次 = fresh（.fresh = 没变，跳过复制）
```

它的判定依据是源码里那三行：`src_stat.size == dest_stat.size and
`src_stat.mtime.nanoseconds == dest_stat.mtime.nanoseconds and
`actual_permissions == dest_stat.permissions`。**注意 `updateFile` 的 `io` 在第 1 位**
（和 `copyFile` 反着来）——同一个类型里两种风格。

## 20.8 遍历：`openDir(.iterate = true)` + `iterate()` + `next(io)`

### 20.8.1 三步走，缺一不可

```zig
// examples/20_files/main.zig 第 354-358 行
        const O = @typeInfo(std.Io.Dir.OpenOptions).@"struct";
        std.debug.print("  OpenDir 的 OpenOptions 字段：", .{});
        inline for (O.field_names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});
        std.debug.print("  .iterate 必须在**打开时**开（Windows 下不开迭代直接 AccessDenied）\n", .{});
```

运行输出（`examples/20_files/main.zig`）：


```text
  OpenDir 的 OpenOptions 字段： access_sub_paths iterate follow_symlinks
  .iterate 必须在**打开时**开（Windows 下不开迭代直接 AccessDenied）
```

```zig
// examples/20_files/main.zig 第 363-368 行
        var d = try cwd.openDir(io, "demo_dir", .{ .iterate = true });
        defer d.close(io);
        var it = d.iterate();
        while (try it.next(io)) |e| {
            std.debug.print("  [{s}] {s}\n", .{ @tagName(e.kind), e.name });
        }
```

运行输出（`examples/20_files/main.zig`）：


```text
  [directory] sub
  [file] g.txt
  [directory] sub2
```

**三个容易踩的点**：

1. **`iterate()` 不带 `io`，但 `next(io)` 带。** 这是 0.17 的一个不对称设计：
   `iterate` 纯计算（造个 `Iterator` 结构体），`next` 才真正读目录。
   所以你会看到 `var it = d.iterate();`（不是 `try`）然后 `try it.next(io)`。
2. **`.iterate = true` 必须在 `openDir` 时开**。POSIX 上不开也能迭代，
   **Windows 上底层打开标志不同**，迭代时直接 `error.AccessDenied`——
   错误出现在**迭代时**而不是打开时，极具迷惑性。
3. **`Iterator` 里有 2048 字节的内嵌缓冲**（`Iterator.reader_buffer_len = 2048`）。
   所以 `iterate()` 返回的东西**不能拷贝**（按值拷贝会把缓冲也拷一份，
   而 `Reader.buffer` 指向的是原 struct 里的那块）——**必须 `var it = ...` 然后用指针**。
   这是 20.14 节讲的那类悬垂问题的另一个来源。

### 20.8.2 `Entry` 只有 3 个字段，`kind` 的类型名有个坑

```zig
// examples/20_files/main.zig 第 372-377 行
        const E = @typeInfo(std.Io.Dir.Entry).@"struct";
        std.debug.print("Entry 字段数={d}：", .{E.field_names.len});
        inline for (E.field_names) |n| std.debug.print(" {s}", .{n[0..n.len]});
        std.debug.print("\n", .{});
        std.debug.print("  entry.kind 的类型 = {s}\n", .{@typeName(@FieldType(std.Io.Dir.Entry, "kind"))});
        std.debug.print("  ⚠️ 写 Io.Dir.Entry.Kind 报 no member named 'Kind'（实测，要用 Io.File.Kind）\n", .{});
```

运行输出（`examples/20_files/main.zig`）：


```text
Entry 字段数=3： name kind inode
  entry.kind 的类型 = Io.File.Kind
  ⚠️ 写 Io.Dir.Entry.Kind 报 no member named 'Kind'（实测，要用 Io.File.Kind）
```

**`Io.Dir.Entry` 只有 `name` / `kind` / `inode` 三个字段**（源码 `Dir.zig` 第 72-76 行）。
没有大小、没有时间（那些要 `statFile`）。

**⚠️ `kind` 的类型是 `std.Io.File.Kind`，不是 `std.Io.Dir.Entry.Kind`**——后者**不存在**：

```text
refl.zig:70:42: error: struct 'Io.Dir.Entry' has no member named 'Kind'
refl.zig:70:42: note: struct declared here
pub const Entry = struct {
```

`Io.File.Kind` 的 11 个成员（实测）：

```text
block_device character_device directory named_pipe sym_link file
unix_domain_socket whiteout door event_port unknown
```

比 `std.fs.File.Kind` 多了 `door` 和 `event_port`（Plan 9 的遗留），
比 POSIX 的 `DT_*` 少了一些（比如没有 `regular`——普通文件就叫 `file`）。

⚠️ **`kind` 在某些文件系统上是 `unknown`**。网络文件系统（FUSE/NFS）
可能填不准确，**不能把 `kind != .file` 当成"是目录"**。要确定就 `statFile`。

### 20.8.3 ⚠️ `walk` 不能对 `cwd()` 用

这是本章新踩到的最有意思的坑。递归遍历的现成壳是 `Dir.walk`：

```zig
// examples/20_files/main.zig 第 383-395 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
walk: sub
  
```

**我最初写的是 `cwd.walk(mem)`，直接 panic**：

```text
thread 1403081 panic: programmer bug caused syscall error: BADF
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:14443:34: 0x10b66c61b in errnoBug (main)
    if (is_debug) std.debug.panic("programmer bug caused syscall error: {t}", .{err});
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:10512:51: 0x10b698662 in posixSeekTo (main)
                    .BADF => |err| return errnoBug(err), // File descriptor used after closed.
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:5692:28: 0x10b6a75a1 in dirReadDarwin (main)
                posixSeekTo(dr.dir.handle, 0) catch |err| switch (err) {
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Dir.zig:152:33: 0x10b72fff0 in read (main)
```

原因在 20.1.1 已经埋好伏笔：**`Dir.cwd()` 的 handle 是 `-2`（`AT_FDCWD`），
它不是一个真正的 fd**。`Dir.Reader` 在 Darwin 上要 `lseek` 目录流来复位，
对 `AT_FDCWD` 做 `lseek` 就是 `EBADF`。同一个原因，`Dir.stat(io)` 对 `cwd()`
也会 panic（实测同样报 BADF）。

**规律**：`cwd()` 只能做**按路径**的操作（`openFile` / `statFile` / `createDirPath` …），
**凡是需要真实 fd 的操作（`walk` / `stat` / `iterate`）都必须先 `openDir`。**

`Walker` 结构体只有一个字段 `inner`（它包了一个栈，显式实现了递归，不用堆分配）。
`walkSelectively` 是它的可剪枝版本（27 章）。

对应的测试守住了这一点：

```zig
// examples/20_files/main.zig 第 840-857 行
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

## 20.9 清理：`deleteTree` 递归删

```zig
// examples/20_files/main.zig 第 400-410 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
deleteDir 非空 → DirNotEmpty（实测）
deleteTree 后 statFile → FileNotFound ⇒ 整棵子树递归删掉了
```

```text
| 方法 | 删什么 | 非空时 |
|---|---|---|
| `deleteFile` | 一个文件 | — |
| `deleteDir` | **一个空目录** | `error.DirNotEmpty` |
| `deleteTree` | **整棵子树** | 逐层递归 |
```

⚠️ **`deleteDir` 对非空目录报 `error.DirNotEmpty` 而不是递归删**——
这是**保护**不是限制（防止 `rm -rf` 手滑）。要递归必须显式写 `deleteTree`，
让"删一棵子树"这个意图在代码里可见。

深目录（比如 node_modules 那种上千层）递归 `deleteTree` 可能爆栈，
这时候用 `deleteTreeMinStackSize`（第 1604 行）——它用显式栈把递归改成迭代。

对应的测试建了 4 层目录树，验证 `deleteDir` 报 `DirNotEmpty`、
`deleteTree` 一次删完：

```zig
// examples/20_files/main.zig 第 859-871 行
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
```

## 20.10 路径：`std.fs.path` 还在老位置

```zig
// examples/20_files/main.zig 第 413-431 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
join = dir/sub/a.txt
basename = a.txt
dirname  = dir/sub（返回 ?[]const u8，根路径时是 null）
extension= .txt
  isAbsolute 相对路径=false，绝对路径=true
Io.Dir.path 就是 std.fs.path（@TypeOf 相等 = true）→ 两个名字都能用
⚠️ std.fs 搬家了但 std.fs.path **没搬** —— @hasDecl(std.fs, "File")=false，"path"=true
```

**在 macOS 上 `join` 用 `/`**（Windows 上会是 `\`）。这不是 bug——
`std.fs.path` 按 `native_os` 编译，`join` 出来的是**本平台**能用的路径。

三个必须知道的签名细节（都实测撞过）：

1. **`dirname` 返回 `?[]const u8`**，不是 `[]const u8`。根路径（`dirname("/")`）
   没有父目录，返回 `null`。直接 `print("{s}", .{std.fs.path.dirname(p)})` 编译不过：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Writer.zig:1935:5: error: invalid format string 's' for type '?[]const u8'
    @compileError("invalid format string '" ++ fmt ++ "' for type '" ++ @typeName(@TypeOf(value)) ++ "'");
```

2. **`join` 的第一个参数是 `Allocator`**，输出是分配出来的内存。
   写法是 `try std.fs.path.join(gpa, &.{ "a", "b" })`。
   旧版的 `joinPosix(buf, a, b)`（写进调用方缓冲）**在 0.17 里不存在**：

```text
api2.zig:101:30: error: root source file struct 'fs.path' has no member named 'joinPosix'
```

   要"不分配"的版本，用 `std.fs.path` 里的 `Buffer` 系列（`joinBuffer` 之类）或
   自己拼（本教程的 `Dir` 方法全用**相对路径**，根本不需要 `join`）。
3. **`extension` 返回 `[]const u8`**（**不是**可选），没有扩展名时返回空切片。
   而且它**带点**（`.txt` 而不是 `txt`）。

对应的测试把这三条都断言了：

```zig
// examples/20_files/main.zig 第 744-755 行
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
```

## 20.11 `std.json`：0.17 的真实形状

### 20.11.1 序列化

```zig
// examples/20_files/main.zig 第 437-448 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
Stringify.value → {"name":"zig","retries":3}
带 .whitespace=.indent_2 →
{
  "name": "zig",
  "retries": 3
}
```

**`std.Io.Writer.fixed(&buf)` 是内存缓冲 Writer**——20 章最实用的一个技巧。
它不需要 `io`（纯内存），`buffered()` 取结果。因为 `std.json` 接受**任何**
`std.Io.Writer`，所以"序列化到字符串"和"序列化到文件/网络"是**同一份代码**：

```zig
var jbuf: [4096]u8 = undefined;
var jw = std.Io.Writer.fixed(&jbuf);
try std.json.Stringify.value(cfg, .{}, &jw);
// 要写文件就把 jw 换成 f.writer(io, &buf).interface，代码其余部分一模一样
```

### 20.11.2 反序列化与 `Parsed(T)` 的所有权

```zig
// examples/20_files/main.zig 第 449-455 行
        const back = try std.json.parseFromSlice(ConfigJson, mem, jw.buffered(), .{});
        std.debug.print("parseFromSlice → Parsed，name={s} retries={d}\n", .{ back.value.name, back.value.retries });
        std.debug.print("  Parsed(T) 类型 = {s}\n", .{@typeName(std.json.Parsed(ConfigJson))});

        // parseFromSliceLeaky：直接给 T，无 Parsed 包装（省一次 deinit）
        const leaky = try std.json.parseFromSliceLeaky(ConfigJson, mem, jw.buffered(), .{});
        std.debug.print("  parseFromSliceLeaky 直接给 ConfigJson（retries={d}）\n", .{leaky.retries});
```

运行输出（`examples/20_files/main.zig`）：


```text
parseFromSlice → Parsed，name=zig retries=3
  Parsed(T) 类型 = json.static.Parsed(main.ConfigJson)
  parseFromSliceLeaky 直接给 ConfigJson（retries=3）
```

**`parseFromSlice` 返回 `std.json.Parsed(T)`**——一个**持有分配器并在 `deinit` 里释放一切**的包装。
所以：

- **必须 `defer back.deinit()`**，否则泄漏（15.8 节的检测会抓到）。
- **`back.value` 里的 `[]const u8` 字段指向 `Parsed` 内部的缓冲**（或者是它从
  `gpa` 分配的内存），**`deinit` 之后全部悬空**。要长期持有就 `dupe` 一份。
- `parseFromSliceLeaky` **直接返回 `T`**，不包装 ——适合"解析完立刻用完"的场景，
  省掉 `deinit` 的心智负担（代价是它内部也用 `gpa` 分配，你得保证 `gpa` 活得够久）。

四个反序列化入口（`std/json.zig` 第 81-92 行）：

```text
| 函数 | 返回 | 什么时候用 |
|---|---|---|
| `parseFromSlice(T, gpa, bytes, opts)` | `Parsed(T)` | 通用，**记得 deinit** |
| `parseFromSliceLeaky(T, gpa, bytes, opts)` | `T` | 用完即弃 |
| `parseFromTokenSource(...)` | `Parsed(T)` | 从**流**（`Scanner.Reader`）解析，不是一次性字节 |
| `parseFromValue(...)` / `parseFromValueLeaky(...)` | — | 从已经解析好的 `Value` 树再转成 `T` |
```

### 20.11.3 两个错误：`SyntaxError` 和 `MissingField`

```zig
// examples/20_files/main.zig 第 459-464 行
        if (std.json.parseFromSlice(ConfigJson, mem, "{bad", .{})) |_| {
            std.debug.print("  坏 JSON 成功？不该\n", .{});
        } else |err| std.debug.print("  坏 JSON → {s}\n", .{@errorName(err)});
        if (std.json.parseFromSlice(ConfigJson, mem, "{\"name\":\"x\"}", .{})) |_| {
            std.debug.print("  缺字段成功？不该\n", .{});
        } else |err| std.debug.print("  缺字段 → {s}\n", .{@errorName(err)});
```

运行输出（`examples/20_files/main.zig`）：


```text
  坏 JSON → SyntaxError
  缺字段 → MissingField
```

`ParseError` 是穷尽错误集，成员：`SyntaxError` / `UnexpectedToken` /
`InvalidNumber` / `Overflow` / `MissingField` / `UnknownField` / `WrongType`。
**注意 `MissingField` 的语义是"必填字段没有"**——
`parseFromSlice` 要求 `T` 的每个字段都在 JSON 里出现。想允许缺省值，
字段类型写成 `?T`（`null` 也算"出现"）或者用 `parseFromSliceLeaky` + 自定义默认值逻辑。

⚠️ **默认是拒绝未知字段吗**：不是——`ParseOptions.ignore_unknown_fields` 默认是
**`true`**（宽松）。所以 `{"name":"x","retries":3,"额外":1}` 会**静默丢掉**"额外"。
想要严格校验就写 `.{ .ignore_unknown_fields = false }`。

### 20.11.4 动态 JSON：`std.json.Value` 是 `union(enum)`

结构事先不知道（配置文件、透传 API）时用 `std.json.Value`：

```zig
// examples/20_files/main.zig 第 471-478 行
        const o = dyn.value.object;
        std.debug.print("动态 Value：object 有 {d} 个键\n", .{o.count()});
        std.debug.print("  .integer tag = {s}，.string = {s}，.bool = {}\n", .{
            @tagName(o.get("n").?),
            o.get("s").?.string,
            o.get("b").?.bool,
        });
        std.debug.print("  .array.items.len = {d}；nil 键存在但值是 null={}\n", .{
```

运行输出（`examples/20_files/main.zig`）：


```text
动态 Value：object 有 5 个键
  .integer tag = integer，.string = x，.bool = true
  .array.items.len = 2；nil 键存在但值是 null=true
  ⚠️ Value 是 union(enum)，{s} 打印**编译不过**（invalid format string）
     要先 .? 解包 union 再取字段，或用 @tagName 打印 tag
```

`Value` 的定义（`json/dynamic.zig` 第 20-28 行）是 **`union(enum)`**：

```zig
pub const Value = union(enum) {
    null,
    bool: bool,
    integer: i64,
    float: f64,
    number_string: []const u8,
    string: []const u8,
    array: Array,
    object: ObjectMap,
```

三个必须知道的点：

1. **`ObjectMap.get(key)` 返回 `?Value`**（不是 `Value`）。要用得先 `.?` 或 `orelse`。
2. **`{s}` 打印 `Value` 编译不过**——`printValue` 没有 `union(enum)` 的格式化分支：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Writer.zig:1935:5: error: invalid format string 's' for type '?[]const u8'
```

   要么 `@tagName(v)` 打 tag，要么解包 union 后打具体字段。
3. **`number_string` 是个额外的 tag**：当数字太大/太怪（超出 `i64`/`f64` 或
   `NaN`/`Inf`）时，`Value` 保留**原始文本**而不是丢数据。所以
   **`switch (v) { .integer => ..., .float => ..., .number_string => ... }`**
   才算完整处理一个 JSON number——只写前两个会漏。

对应的测试守住了序列化字符串的**逐字节精确**：

```zig
// examples/20_files/main.zig 第 757-773 行
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
```

## 20.12 错误处理：区分"文件不存在"和"别的错"

文件 I/O 的错误处理有一个特殊困难：**"文件不存在"通常不是错误**。
没有配置文件是正常状态，不是异常。所以你要把 `FileNotFound` 从错误流里**摘出来**：

```zig
// examples/20_files/main.zig 第 30-38 行
fn readConfig(io: std.Io, dir: std.Io.Dir, gpa: std.mem.Allocator, path: []const u8) !?[]u8 {
    return dir.readFileAlloc(io, path, gpa, .limited(64 * 1024)) catch |err| switch (err) {
        error.FileNotFound => null, // 没这个文件不是错误，返回"没有配置"
        error.AccessDenied, error.PermissionDenied => return err, // 权限问题是真错误，往上抛
        else => |e| return e,
    };
}

pub fn main(init: std.process.Init) !void {
```

**三段式结构**是本章最该抄走的模式：

1. **一个错误 → 一个语义值**（`FileNotFound` → `null`）；
2. **另一些错误 → 原样上抛**（权限问题不是"没配置"，是"出错了"）；
3. **其余 → `else => |e| return e`** 兜底（**不要写 `catch {}`**——
   那会把磁盘满、IO 错误一起吞掉）。

调用方就干净了：

```zig
// examples/20_files/main.zig 第 493-507 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
readConfig(存在的文件) → 19 字节
readConfig(不存在的文件) → null（null = 没配置，不是错误）
  openFile 不存在 → FileNotFound（这是要 catch 的那个）
错误处理范式：FileNotFound → 业务上的“没有”，其它 → 往上抛
  常见可 catch 的错误：FileNotFound / AccessDenied / PathAlreadyExists / IsDir / DirNotEmpty / StreamTooLong
```

### 本章实测到的错误名与含义

```text
| 错误 | 谁报的 | 含义 | 典型处理 |
|---|---|---|---|
| `FileNotFound` | 几乎所有 | 路径不存在 | **业务上的"没有"**（本节） |
| `AccessDenied` | `openFile`/`access` | 权限/类型不符（开目录、查 execute） | 上抛 |
| `PermissionDenied` | `createFile`/`createDir` | 目录不可写 | 上抛 |
| `PathAlreadyExists` | `createFile(.exclusive)` / `createDir` | 已存在且要求新建 | 视业务 |
| `IsDir` | `openFile(.allow_directory=false)` / `read` | 是目录不是文件 | 换路径 |
| `DirNotEmpty` | `deleteDir` | 目录非空 | 改用 `deleteTree` |
| `StreamTooLong` | `readFileAlloc` / 行读取 | 超上限 | 调大上限或改流式 |
| `NoSpaceLeft` | 写 | 磁盘满 | 上抛 |
| `BrokenPipe` | 写 | 对端关了（socket/管道） | 上抛 |
```

⚠️ **`catch {}` 在文件代码里是反模式**。它会让"磁盘满"和"权限错"和
"文件不存在"走同一条路，全部变成"用默认值继续"。本教程所有示例在
**明确知道后果**的地方才用 `catch {}`（比如 20.9 的 `deleteTree(io, path) catch {}`
——清理失败不该让程序失败）。

对应的测试验证两条路径：

```zig
// examples/20_files/main.zig 第 773-789 行
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
```

## 20.13 临时目录

### 20.13.1 测试里：`std.testing.tmpDir`

15 章已经讲过 `tmpDir` 的三个字段（`.dir` / `.parent_dir` / `.sub_path`）。
本章的 16 个测试全部用它，每个测试一个独立的、名字随机的、退出自动删的目录：

```zig
// examples/20_files/main.zig 第 561-568 行
test "20.3 readFileAlloc：Io.Limit 上限与StreamTooLong" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "a.txt", .data = "0123456789" });
    const got = try tmp.dir.readFileAlloc(io, "a.txt", a, .limited(64));
```

四个必须同时出现的东西：

```text
| 行 | 为什么 |
|---|---|
| `const io = std.testing.io` | `tmp.dir` 的所有方法都要 `io` |
| `const a = std.testing.allocator` | `readFileAlloc` 要分配器（泄漏检测） |
| `var tmp = std.testing.tmpDir(.{})` | **必须是 `var`**（`cleanup` 要改它） |
| `defer tmp.cleanup()` | 递归删整棵子树 |
```

⚠️ **`tmpDir` 在 `main` 里调用会编译失败**（15 章坑位 12）：
它有 `comptime assert(builtin.is_test)`，`zig build-exe` 下变成 `unreachable`：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/testing.zig:607:20: note: called at comptime here
    comptime assert(builtin.is_test);
referenced by:
    main: m.zig:3:33
```

### 20.13.2 生产代码里：自己造名 + `defer deleteTree`

`tmpDir` 不可用，那就手写等价物。三步：**造唯一名 → 递归建 → `defer` 递归删**。

```zig
// examples/20_files/main.zig 第 515-526 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
std.testing.tmpDir 只在 zig test 下能用（带 comptime assert(builtin.is_test)）
生产代码的等价物：自己造名 + createDirPath + defer deleteTree
临时目录里写了 临时（6 字节），退出时 deleteTree 回收
⚠️ 名字必须唯一：生产代码常用 pid + 时间戳，测试用 tmpDir 的随机 16 字符名
```

**"先清残留"这一步是本节的重点**。程序上次崩溃会留下目录，
这次启动如果撞上同名就会 `error.PathAlreadyExists`。三条路：

1. **名字带随机性**（`tmpDir` 的做法：16 字符 base64）——推荐；
2. **先 `deleteTree` 再建**（本示例的做法）——简单，但**并发运行时会互删**；
3. **用系统临时目录**：`std.fs` 的 `getEnvMap` 拿 `TMPDIR`（POSIX）/
   `TEMP`（Windows），拼一个唯一子目录名。

⚠️ `defer ... catch {}` 里的 `catch {}` 是**故意的**：清理失败（比如文件被别的进程占用）
不该让程序失败。但**这会静默吞掉错误**——真要严格就记日志：

```zig
defer cwd.deleteTree(io, tmp_name) catch |err| {
    std.log.warn("清理临时目录 {s} 失败：{s}", .{ tmp_name, @errorName(err) });
};
```

（记得 15 章坑位 11：日志里的 `err` 级会让 `zig test` 退出码非零，
所以测试代码里别这么写。）

## 20.14 为什么 Zig 要求你显式选 io

### 20.14.1 哲学：让"依赖"看得见

```zig
// examples/20_files/main.zig 第 528-532 行
    std.debug.print("显式传 io 的三个收益：\n", .{});
    std.debug.print("  1. 可替换：main 传 init.io，test 传 std.testing.io（15 章）\n", .{});
    std.debug.print("  2. 可测试：io 是参数 → 能塞假实现、能在测试里换掉整个后端\n", .{});
    std.debug.print("  3. 可异步：同一份代码能在阻塞 io 和事件驱动 io 上跑\n", .{});
    std.debug.print("⚠️ 代价：每个方法都要写 io。这不是啰嗦，是让“依赖”看得见\n", .{});
```

运行输出（`examples/20_files/main.zig`）：


```text
显式传 io 的三个收益：
  1. 可替换：main 传 init.io，test 传 std.testing.io（15 章）
  2. 可测试：io 是参数 → 能塞假实现、能在测试里换掉整个后端
  3. 可异步：同一份代码能在阻塞 io 和事件驱动 io 上跑
⚠️ 代价：每个方法都要写 io。这不是啰嗦，是让“依赖”看得见
```

把这三条对照其它语言：

```text
| 语言 | I/O 从哪来 | 后果 |
|---|---|---|
| **C** | 全局（`stdin`/`stdout`/`errno`） | 多线程要小心全局 errno；测试要重定向 fd |
| **Go** | `*os.File` 显式传，但 `os.Stdout` 是全局 | `os.Stdout` 可被替换（`io.Writer` 接口） |
| **Rust** | `impl Read` / `AsRef<Path>`，泛型注入 | 换实现要改类型（`dyn` 可以但啰嗦） |
| **Python** | 全局 `open()`，靠 monkeypatch 换 | 测试要 `monkeypatch.setattr("builtins.open", ...)` |
| **Zig 0.17** | **`io: Io` 显式在签名里** | 换实现 = 换一个参数值；编译器保证不漏 |
```

关键差别在最后一行：Python 的 `open` 能被换是因为**它是全局查找**，
而全局查找是**隐式依赖**——你读一个函数签名看不出它会碰磁盘。
Zig 的 `readFileAlloc(io, path, gpa, limit)` **一眼就能看出**"这个函数会做 I/O，
而且需要一个 `Io`"。

这也解释了为什么 `Dir.cwd()` / `File.stdin()` **不带 `io`**：
它们**不做 I/O**（只是造一个句柄值）。**"第一个参数是不是 `io`"就是
"这个函数做不做 I/O"的编译期标记。**

### 20.14.2 代价：悬垂指针的形状也变了

```zig
// examples/20_files/main.zig 第 18-21 行
const Config = struct {
    name: []const u8,
    retries: u32,
};
```

```zig
// examples/20_files/main.zig 第 533-550 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
悬垂指针实测：把 file.writer(io, buf) 的返回值按值存进结构体 → buf 悬垂
  就地写+flush → XY23456789（正确）
  反例：struct 里存 File.Writer 字段，buf 在栈上 → 返回即悬垂
  ⇒ 规则：Writer/Reader 不进结构体；必须存就存 File + buf，绑的时候再 writer(io, buf)
```

**为什么这是个真问题**：`file.writer(io, &buf)` 返回的 `File.Writer` 内部
有一个 `interface: Io.Writer` 字段，它的 `buffer` 切片**指向 `buf`**。
如果你把这个 `Writer` **按值存进一个结构体然后返回**，那个结构体里的
`Writer.buffer` 仍指向**已经销毁的栈帧**。

对比老 API：`std.fs.File.writer()` 同样返回 `File.Writer`，
所以这个问题不是 0.16 引入的——但 0.16 之后 `Writer` 的存在感更强了
（`writeStreamingAll` 之外的一切都走它），**踩到的概率更高**。

**规则三条**：

1. **`Writer`/`Reader` 只在栈帧内用**，不跨函数返回、不进结构体、不进数组。
2. **要持有就存"原料"**（`File` + `[]u8` 缓冲），**用的时候再 `writer(io, buf)` 绑一次**。
3. **`var` + 就地使用**（不要 `const fw = ...` 然后到处传）。

同样的道理适用于 20.8.1 说的 `Dir.Iterator`（它有 2048 字节内嵌缓冲，
按值拷贝会让 `Reader.buffer` 指向旧位置）。

### 20.14.3 测试替身：同一份代码，两个 `io`

```zig
// examples/20_files/main.zig 第 789-798 行
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
```

运行输出（`examples/20_files/main.zig`）：


```text
1/16 main.test.20.3 readFileAlloc：Io.Limit 上限与StreamTooLong...OK
2/16 main.test.20.4 手工行读取：fillMore + indexOfScalarPos + toss（缓冲小于行长）...OK
3/16 main.test.20.4 readSliceShort 是填满或EOF，不是单次 read...OK
4/16 main.test.20.5 缓冲 Writer 必须flush：忘 flush 丢全部内容...OK
5/16 main.test.20.5 writeStreamingAll 是 File 上的”写全部”，writeAll 不存在...OK
6/16 main.test.20.6 追加要自己 seek；truncate=false 不等于 append...OK
7/16 main.test.20.7 目录：createDirPath / access / rename / createDirPathOpen...OK
8/16 main.test.20.8 遍历：Entry 形状与 openDir(.iterate=true)...OK
9/16 main.test.20.10 std.fs.path：dirname 返回可选...OK
10/16 main.test.20.11 std.json 回环：Stringify.value + parseFromSlice...OK
11/16 main.test.20.12 readConfig：区分”没有配置”和”真错误”...OK
12/16 main.test.20.14 显式 io：同一份代码在测试里换后端...OK
13/16 main.test.20.2 flags：exclusive / allow_directory 两组选项的行为...OK
14/16 main.test.20.5 缓冲 Writer 的 buffered() 长度在 flush 前后归零...OK
15/16 main.test.20.8 walk：必须在 openDir 出来的 Dir 上跑（cwd() 会BADF）...OK
16/16 main.test.20.9 deleteTree 递归删整棵子树...OK
All 16 tests passed.
```

注意：**16 个测试全部用 `std.testing.io`**，而 `main` 用 `init.io`。
`readConfig` 这个函数在两个地方被调用，**签名里那个 `io` 参数就是全部的秘密**——
它不关心调用方是生产还是测试。

## 20.15 本章示例的完整测试清单

上面 20.14.3 已经贴了完整的 16 行测试输出。三层验证：

```text
[Toolchain] /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/zig (0.17.0)
[Example] 20_files
[Done] 20_files 验证通过。
All 16 tests passed.
自检通过
```

示例的 `main` 结尾会把本节演示留下的 `demo_conf.txt` / `demo_lines.txt` 删掉，
所以 `build.ps1` / `run-all.sh` 重复跑**不残留**——这也是 20.9 说的
"清理路径的 `catch {}` 是安全的"的一个实际例子。

示例的 `main` 覆盖 20.1-20.14 十四节（每节一个 `begin("20.N")` … `end("20.N")`），
末尾 16 个 `test` 块覆盖：Io.Limit 上限（20.3）、手工行读取与 `readSliceShort`（20.4）、
flush 与 `writeStreamingAll`（20.5）、追加（20.6）、目录三连（20.7）、遍历（20.8）、
`deleteTree`（20.9）、`std.fs.path`（20.10）、`std.json` 回环（20.11）、
错误区分（20.12）、显式 `io`（20.14）。

## 20.16 坑位清单

1. **`std.Io.File` 没有 `writeAll` 也没有 `readAll`**。实测
   `@hasDecl(std.Io.File, "writeAll") = false`、
   `@hasDecl(std.Io.File, "readAll") = false`。写全部是
   **`writeStreamingAll(io, bytes)`**，读是 `readStreaming(io, &.{buf})`
   （返回 `usize`，**可能 0**，结束是 `error.EndOfStream`）。
   同样没有 `getPos()`——用 `File.Reader.logicalPos()`。
   `seekTo`/`seekBy` 挂在 `File.Reader` / `File.Writer` 上，**不挂 `File`**。

2. **⚠️ 0.17 的 `takeDelimiterExclusive` 是阻塞式的**（网上流传的"不阻塞"是错的）。
   它内部走 `peekDelimiterExclusive` → `peekDelimiterInclusive`，后者是
   `while (true) { try fillMore(r); ... }`。**限制是"分隔符必须在 Reader
   缓冲容量内"**，超了报 `error.StreamTooLong`——实测 4 字节缓冲读 6 字节的行
   直接 `StreamTooLong`。行长可能超过缓冲时用
   `fillMore` + `indexOfScalarPos` + `toss` 三件套。

3. **`toss(n)` 不能超过 `end - seek`**，否则
   `panic: reached unreachable code` / `assert(r.seek <= r.end)` in `toss`。
   常见错法是 `r.toss(idx + 1)` 而 `idx` 是 `?usize`（`null + 1 = 1`）。
   正确写法：`r.toss(if (idx) |k| k + 1 else avail.len)`。
   同样 `fillMore` 在 EOF 时返回 **`error.EndOfStream` 不是 void**，
   而且那一刻 `buffered()` 可能还有零头（末尾没换行的最后一行）。

4. **`readSliceShort` 是"填满或 EOF"语义，不是"读一次"**。
   实测源 8 字节 / buf 3 字节 → 返回 **3**；源 2 字节 / buf 8 字节 → 返回 **2**
   （不报错）。要"读多少算多少"用 `take(n)`；要"必须填满"用 `readSliceAll`
   （源短于 buf 时报 `error.EndOfStream`）。

5. **⚠️ `writeFile` 的 `flags.truncate = false` 不等于追加**。实测两次
   `writeFile`（第二次 `truncate=false`）后文件是 `"BBB"` 不是 `"AAABBB"`——
   `writeFile` 的实现是"createFile → writeStreamingAll(全部) → close"，
   **既没有 `O_APPEND` 也没有 seek**。真追加要三步：
   `createFile(.{ .truncate = false })` + `seekTo(原长度)` + 写 + **flush**。

6. **缓冲 Writer 必须 flush，`File.close` 不会替你 flush**。
   实测：18 字节 `print` 之后直接 `close`，文件是 **0 字节**。
   `flush` 的证据是 `interface.buffered().len` 从 18 变 0，
   而 `logicalPos()` 不变（flush 只提交，不改逻辑位置）。
   `File.Writer` 还有个 `end()` = flush + 按 `logicalPos` 截断/补齐，普通 `Io.Writer` 没有。

7. **⚠️ 对 `std.Io.Dir.cwd()` 直接 `walk` 会 panic**：
   `programmer bug caused syscall error: BADF`。
   原因：`cwd()` 的 handle 是 `-2`（`AT_FDCWD`），**不是真正的 fd**，
   而 `Dir.Reader` 在 Darwin 上要 `lseek` 目录流复位。
   `Dir.stat(io)` 对 `cwd()` 同样 panic。
   **规律：`cwd()` 只能做按路径的操作；凡是需要真实 fd 的
   （`walk` / `stat` / `iterate`）必须先 `openDir`。**

8. **⚠️ `io` 参数的位置没有统一规律**。跨两个 `Dir` 的方法
   （`rename` / `copyFile` / `hardLink` / `symLinkAtomic`）把 `io` 排在
   **最后**；单 `Dir` 的方法排在**第 1 位**；而 `updateFile` / `symLink`
   是"跨 Dir 但 io 在第 1 位"的例外。**只能查 20.1.3 的表**。
   搞错了报 `member function expected 4 argument(s), found 5`。

9. **`std.fs.path.dirname` 返回 `?[]const u8`**（根路径时 `null`），
   直接 `{s}` 打印编译不过：
   `error: invalid format string 's' for type '?[]const u8'`。
   而 `basename` / `extension` 返回 `[]const u8`（`extension` **带点**）。
   `join` 第一个参数是 `Allocator`；旧版的 `joinPosix(buf, a, b)`
   **在 0.17 不存在**（`root source file struct 'fs.path' has no member named 'joinPosix'`）。

10. **`std.Io.Dir.Entry` 只有 3 个字段**（`name` / `kind` / `inode`），
    **没有大小和时间**（要 `statFile`）。
    写 `std.Io.Dir.Entry.Kind` 报 `struct 'Io.Dir.Entry' has no member named 'Kind'`——
    **`kind` 的类型是 `std.Io.File.Kind`**。
    而且某些文件系统（网络/FUSE）会把 `kind` 填成 `unknown`，
    **不能把 `kind != .file` 当成"是目录"**。

11. **⚠️ `std.Io.Limit` 是非穷尽枚举，`{t}` 打印运行期值会 panic**
    （`panic: invalid enum value`，因为 `printValue` 的 `.@"enum"` 分支要
    `@tagName(value)`）。要打印就用 **`@backingInt(x)`**。
    `readFileAlloc` 的**第四个参数类型是 `Io.Limit` 不是 `usize`**——
    旧代码 `readFileAlloc(io, path, gpa, 1024)` 编译不过。

12. **`Dir.iterate()` 不带 `io` 但 `Iterator.next(io)` 带**（不对称设计）。
    而且 `Iterator` 有 **2048 字节内嵌缓冲**（`reader_buffer_len = 2048`），
    **必须 `var it = d.iterate()` 就地用**，按值拷贝会让 `Reader.buffer` 指向旧位置。
    `.iterate = true` 必须在 **`openDir` 时**开——
    Windows 上不开会在**迭代时**才报 `error.AccessDenied`（错误时机极具迷惑性）。

13. **`std.Io.File.Reader` / `File.Writer` 的 `interface` / `err` / `file` 是
    字段不是函数**。`@hasDecl(std.Io.File.Reader, "interface")` 实测 `false`
    （`@hasDecl` 只查 `pub fn` / `pub const`）。所以调用是
    `fr.interface.fillMore()` 而不是 `Reader.fillMore(fr)`。
    字段全集：`Reader{ io, file, err, mode, pos, size, interface }`。

14. **`Writer` / `Reader` 不能按值存进结构体**。`f.writer(io, &buf)` 返回的
    `File.Writer` 内部 `interface.buffer` **指向 `buf`**，把 Writer 存进结构体
    再返回就悬垂。**规则：只存"原料"（`File` + `[]u8`），用的时候再
    `writer(io, buf)` 懒绑定。** `Dir.Iterator` 同理。

15. **⚠️ `std.testing.io` / `std.testing.allocator` / `std.testing.tmpDir` 在
    非测试编译下是 `@compileError("not testing")` / `unreachable`**。
    所以 `main` 里**不能**引用它们——本章 main 里凡是要讲 tmpDir 的地方
    都只**反射类型形状**或**手写等价物**。
    而且 `readFileAlloc` 返回的缓冲区**归调用方所有**，
    测试里必须 `defer a.free(got)`（本教程第一个漏掉时整个 `zig test`
    报了 `1 tests leaked memory.`）。

16. **`catch {}` 在文件代码里是反模式**。它会把"磁盘满""权限错""文件损坏"
    一起吞成"用默认值继续"。正确模式是三段式
    （`error.FileNotFound => null` + 若干 `=> return err` + `else => |e| return e`）。
    **例外**：清理路径（`defer deleteTree(...) catch {}`）可以静默，
    但要至少记一条 `warn` 日志（且**别用 `err` 级**——15 章坑位 11：
    `log.err` 在 test 块里会让退出码非零）。

---

上一章：[19 并发](19-threads.md) · 下一章：[21 内联汇编](21-asm.md)
