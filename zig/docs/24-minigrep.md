# 24 · 实战：迷你 grep

> 对应示例：`examples/24_minigrep/`（build.zig 工程）
>
> - `build.zig` **33 行**（exe + run + test 三个 step）
> - `build.zig.zon` **11 行**
> - `src/main.zig` **2135 行**（24.1–24.11 分节演示 + 13 个测试）
> - `src/regex.zig` **1132 行**（手写正则引擎 + 22 个测试）
> - `src/search.zig` **305 行**（流式逐行 + 高亮格式化 + 9 个测试）
> - `src/corpus/` 固定语料 3 个文件（app.log 8 行 / app.conf 9 行 / README.md 13 行）
>
> 合计 **44 个 test**（`zig build test` 全跑），`zig build run` 逐节打印 24.1–24.11 的结论。

---

## 导读：这一章要推翻四个说法

前面 23 章每章都在推翻一个"看起来当然如此"的说法，这一章也一样，而且推得更狠。

**说法一："grep 就是逐行 `find` 子串。"**
错。`grep "ERROR|WARN"` 里的 `|` 是或，`e*` 能匹配零次，`[a-z]+` 是一整个字符类，`^`/`$` 是锚点。这些都不是子串查找能表达的。本章从零写一个**递归下降 + 回溯**的正则引擎（`src/regex.zig`，1132 行），支持字面量、`.`、`*`、`+`、`?`、`[]`、`^`/`$`、`|`、`()`。写完你会发现：正则的本质是**一棵语法树压平成一条指令数组**，而不是"一个更聪明的 find"。

**说法二："一次把文件读进内存，逐行 split 就行。"**
对 100 MB 的日志这是自杀。grep 的内存占用应该是 **O(行长)**，不是 O(文件)。本章用 `File.Reader` 的 `fillMore/buffered/toss` 三件套做真正的流式逐行，并用 **4 字节缓冲读出 6 字节的行**、**8 字节缓冲读出 1000 字节的行**两组实测证明它成立（24.3）。

**说法三："目录遍历就是 `for (path) |p|` 递归一下。"**
在 0.17 上这么写会 **panic**。`std.Io.Dir.cwd()` 是 `AT_FDCWD` **伪句柄**，对它调 `walk`/`iterate` 会 `lseek(-2)` 失败，std 判定为"程序 bug"直接 panic（不是返回错误）。而且 `entry.name` 跨 `next()` **失效**，存切片就等于存了一堆会被覆写的字节（24.2 有实测对照）。

**说法四（最隐蔽的一条）："`File.writer(io, buf)` 就是写文件。"**
它默认是 **positional 模式**（写前 seek）。如果你同时用 `std.debug.print` 往 stderr 写，那么 **positional writer 会覆盖掉 debug.print 刚写的字节**——而且只在 `2> file` 时暴露，重定向到管道时完全正常。本章为此专门写了回归测试（24.7）。

本章的语料是 `src/corpus/`，内容定稿后不再改动，因为文档里所有运行输出都是逐字节抄自实测的。

---

## 24.1 命令行解析：Juicy Main 与六个开关

0.17 的 `main` 第一个参数是 `std.process.Init`，argv 藏在 `init.minimal.args` 里。这不是风格问题：`io` / `arena` / `gpa` / `environ` 全部由 runtime 注入，测试里换成 `std.testing.io` 整套 I/O 就换掉了（15 章）。

`parseArgs` 的三个设计决定值得单独说：

```zig
// examples/24_minigrep/src/main.zig 第 104-124 行
/// 解析 argv。结果里的 `positional` **借用** `args` 本身，不分配、不拷贝。
///
/// ⚠️ 位置参数是**连续**的一段 argv（开关在前、位置参数在后），
/// 所以可以直接切子切片；要换成"任意位置穿插"的 GNU 风格就得开数组。
/// 这里选连续切片的理由是：零分配 ⇒ parseArgs 是**纯函数** ⇒ 单测直接喂数组。
///
/// 三个刻意的设计决定：
///   1. **开关在前、位置参数在后**。`--` 之后全是位置参数，
///      所以 `grep -- -pattern` 能搜以 `-` 开头的串。
///   2. 短选项**可组合**：`-in` 等价 `-i -n`。逐字符扫描，一个 `for` 搞定，
///      不需要 getopt 那种状态机。
///   3. 解析器**不碰 io / 文件系统**，也不碰分配器——
///      所以它能被单测直接喂数组（24.11）。
pub fn parseArgs(args: []const []const u8) ParseError!Options {
    var opt: Options = .{};
    var only_positional = false;
    // 位置参数起点：argv 里第一个"不是开关"的元素下标
    var first_pos: ?usize = null;

    for (args, 0..) |arg, i| {
        if (only_positional or arg.len == 0 or arg[0] != '-') {
            // 不是开关 ⇒ 位置参数。'-' 单独出现（stdin 约定）也算位置参数
            if (first_pos == null) first_pos = i;
            continue;
        }
        if (std.mem.eql(u8, arg, "--")) {
            only_positional = true;
            // `--` 本身占了一个下标，但它不是位置参数：
            // 后面元素才是。把 first_pos 指向它之后
            if (first_pos == null and i + 1 < args.len) first_pos = i + 1;
            continue;
        }
```

第三点是**测试性的直接来源**：因为 `positional` 是 `args[first_pos..]` 这样的子切片、零分配，`parseArgs` 成了纯函数，测试可以直接断言指针相同（`@intFromPtr(argv[1].ptr) == @intFromPtr(o.positional[0].ptr)`）。

六个开关的实现（`Options` 结构体，第 42–55 行）就是六个 bool 字段加一个 `ColorMode` 枚举。短选项逐字符扫描，所以 `-inr` 一次顶三个。

运行输出（`zig build run`）：

```text
Init 的形状：Init=process.Init，其中 minimal=process.Init.Minimal
  init.minimal.args 的类型 = process.Args（里面是 argv 向量）
  init.arena 的类型 = *heap.ArenaAllocator（进程级 arena，退出自动回收）
  init.gpa 的类型   = mem.Allocator（Debug 模式带泄漏检查）
  init.io 的类型    = Io
⚠️ 0.16 及以前 main 是 pub fn main() !void，argv 走 process.args()；
   0.17 起推荐 **Juicy Main**：pub fn main(init: std.process.Init) !void
   这不是风格问题：io / arena / gpa / environ 全部由 runtime 注入

[开关组合解析实测]  argv → 六个开关
 模式=needle (+1 个路径)  开关=-i-----  color=auto
 模式=needle  开关=-i--n--  color=auto
 模式=ERROR (+1 个路径)  开关=---c-r-  color=auto
 模式=a+b  开关=------F  color=auto
 模式=x  开关=--v----  color=always
 模式=-notanoption  开关=-------  color=auto
 模式=pattern  开关=-------  color=auto
  未知开关 -Z → UnknownOption（显式报错，不静默忽略）
  --help（未实现）→ UnknownOption
```

注意 `-i needle src` 和 `-in needle` 的开关位完全一样（`-i-----` vs `-i--n--`，前者少了 `-n`）——组合短选项确实生效了。`--` 那一行演示 `-notanoption` 被当成位置参数而不是未知开关。

真用时（不是无参数演示）：

```bash
cd examples/24_minigrep
zig build run -- -n -r "service=" src/corpus   # 带行号递归搜
zig build run -- -i -r "error" src/corpus       # 大小写不敏感
zig build run -- -v "ERROR" src/corpus/app.log  # 反向：打印**不含** ERROR 的行
zig build run -- -c -r "timeout" src/corpus     # 只计数
zig build run -- -F -r "svc[0-9]" src/corpus    # 固定字符串，[] 不当正则
```

---

## 24.2 文件读取与遍历：伪句柄、必须 openDir、name 必须 dupe

这一节的三条 0.17 事实，每一条都是"不照做就出错"的级别。

**第一条：`std.Io.Dir.cwd()` 是伪句柄。** POSIX 上它的 `handle == AT_FDCWD == -2`，不是真的已打开 fd。`iterate` / `walk` / `stat` 内部都要 seek 这个 fd，于是**直接在 `cwd()` 上调会 panic**：

```text
thread 2746548 panic: programmer bug caused syscall error: BADF
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:14443:34: 0x109d0c68b in errnoBug (err1)
    if (is_debug) std.debug.panic("programmer bug caused syscall error: {t}", .{err});
                                 ^
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:10512:51: 0x109d386d2 in posixSeekTo (err1)
                    .BADF => |err| return errnoBug(err), // File descriptor used after closed.
                                                  ^
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:5692:28: 0x109d47611 in dirReadDarwin (err1)
                posixSeekTo(dr.dir.handle, 0) catch |err| switch (err) {
                           ^
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Dir.zig:152:33: 0x109d7c330 in read (err1)
        return io.vtable.dirRead(io.userdata, r, buffer);
                                ^
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Dir.zig:159:31: 0x109d7c08d in next (err1)
```

关键在 `errnoBug` 这个名字：std 把 `lseek(-2)` 的 `BADF` 判定为**程序员写错了**，于是直接 panic，**不返回错误**。所以"加个 `catch` 兜住"这条路根本不存在——必须先 `openDir`。

**第二条：`.iterate = true` 必须在打开时给。** `Dir.Iterator` 只有一个 `reader_buffer: [2048]u8` 字段 + 一个 `reader`，`iterate(dir)` 只是把这个结构体填上；不开迭代权限就调 `next`，Windows 上直接 AccessDenied。

**第三条：`entry.name` 跨 `next()` 失效。** 文档原话是"All `Entry.name` are invalidated with the next call to `read` or `next`"，因为 name 指向迭代器内部那块 2048 字节缓冲。小目录下凑巧不炸，文件一多就现原形。

`collectFiles` 的正确顺序是：**先 access 判存在性 → 再 openDir 试是不是目录 → 最后才决定走 walk 还是当单文件收**：

```zig
// examples/24_minigrep/src/main.zig 第 269-283 行
    // ⚠️⚠️ **`-r` 不代表"只接受目录"**。真grep 里 `grep -r pattern file.txt`
    //    是完全合法的：-r 只影响"遇到目录时要不要下钻"，目标是文件就直接搜。
    //    早期版本把 -r 分支写成"只 openDir + walk"，于是
    //    `minigrep -v -r ERROR src/corpus/app.log` 报
    //    "打开目录 … 失败：NotDir"（实测），一个文件都搜不到。
    //
    // 正确顺序：**先判存在性，再判是不是目录**，最后才决定走 walk 还是单文件。
    // 存在性用 access（返回 void，比 statFile 便宜）
    if (cwd.access(io, root, .{})) |_| {
        // 存在。试着当目录打开：成功 = 是目录
        var maybe_dir: ?std.Io.Dir = null;
        if (cwd.openDir(io, root, .{ .iterate = true })) |d| {
            maybe_dir = d;
        } else |_| {
            maybe_dir = null;
        }

        if (maybe_dir) |md| {
            var dir = md;
            defer dir.close(io);
            if (!recursive) {
                // 是目录却没给 -r：真 grep 会去读 stdin；我们明确提示并跳过
                std.debug.print("  （{s} 是目录，加 -r 才递归；已跳过）\n", .{root});
                return;
            }
            try walkInto(io, gpa, root, dir, out);
            return;
        }

        // 是文件：-r 与否都直接收
        const st = try cwd.statFile(io, root, .{});
        try out.append(gpa, .{ .path = try gpa.dupe(u8, root), .size = st.size });
        return;
    } else |err| {
        std.debug.print("  路径不存在：{s}（{s}）\n", .{ root, @errorName(err) });
        return;
    }
```

这里 `access` 与 `statFile` 的选择也是有讲究的：`access` 返回 `!void`，而 `statFile` 要返回整个 `File.Stat`。只问"在不在"时 access 便宜得多——实测两者的返回类型：

```text
[access vs statFile] 判存在性用哪个
  access 的返回类型 = error{AccessDenied,BadPathName,Canceled,FileBusy,FileNotFound,InputOutput,NameTooLong,PermissionDenied,ReadOnlyFileSystem,SymLinkLoop,SystemResources,Unexpected}!void
  access(存在的文件) → ok
  access(不存在) → FileNotFound
  statFile(存在的文件) → size=11 字节（多了整个 Stat，只为拿一个数字不划算）
```

`walkInto` 里还有一个容易漏的细节：**`Walker.Entry.path` 是相对于 walker 根的，不是相对 cwd**。根是 `demo_tree` 时 `e.path` 形如 `sub/c.log`，直接拿去 `cwd.statFile` 会 FileNotFound，而 `size` 被 `catch` 吞掉后**静默变成 0**：

```zig
// examples/24_minigrep/src/main.zig 第 330-348 行
                // ⚠️ e.path 同样会在下一次 next() 后失效 ⇒ 必须 dupe
                // ⚠️ `std.Io.File.cwd()` 不存在（实测 no member named 'cwd'），
                //    只有 `std.Io.Dir.cwd()`。而 statFile 是 Dir 的方法
                //    （内部按需开真 fd，不受"伪句柄不能 seek"那条限制）。
                //
                // ⚠️⚠️ **e.path 是相对于 walker 根的**，不是相对 cwd。
                //    根是 "demo_tree" 时 e.path 形如 "sub/c.log"，
                //    直接拿去 cwd.statFile 会 FileNotFound ⇒ size 静默变 0。
                //    所以必须 join(root, e.path)。这是"walker 的 path 起点"
                //    最容易踩的一处。
                const full = try std.fs.path.join(gpa, &.{ root, e.path });
                const st = cwd.statFile(io, full, .{}) catch {
                    try out.append(gpa, .{ .path = full, .size = 0 });
                    continue;
                };
                try out.append(gpa, .{ .path = full, .size = st.size });
```

运行输出（POSIX 上，`zig build run`）：

```text
std.Io.Dir.cwd().handle = -2，std.posix.AT.FDCWD = -2，相等 = true
⇒ cwd() 是**伪句柄**：它不是真的 fd，而是"相对当前目录"这个约定
⇒ 对它调 walk/iterate 会 panic：programmer bug caused syscall error: BADF
   （lseek(-2) 的 errno 被 std 判定为"程序 bug"直接 panic，不是返回错误）
```

⚠️ 这段在 Windows 上有平台分叉（示例里是 `comptime` 分支）：
`std.posix.AT.FDCWD` 只在 POSIX 目标存在，Windows 上引用它直接编译错
`struct 'c.AT__struct_719' has no member named 'FDCWD'`；而且 Windows 的
`Dir.handle` 是 `*anyopaque` 不透明句柄，打印 fd 数字没有意义。
Windows 分支只打印不透明句柄的说明，panic 行为两平台一致：

```text
std.Io.Dir.cwd().handle 是不透明句柄（Windows 无 AT_FDCWD 概念）
⇒ cwd() 是**伪句柄**：它不是真的 fd，而是"相对当前目录"这个约定
⇒ 对它调 walk/iterate 会 panic：programmer bug caused syscall error: BADF
   （lseek(-2) 的 errno 被 std 判定为"程序 bug"直接 panic，不是返回错误）

[Dir 只有一个字段]  handle
OpenDir 的 OpenOptions 字段： access_sub_paths iterate follow_symlinks
  .iterate 默认 = false（不开就不能 iterate；Windows 上会 AccessDenied）
  .follow_symlinks 默认 = true

[openDir + iterate]（必须先 openDir，见上面的 BADF）
  openDir 拿到真句柄 handle=5
  （Windows 上这行是 `openDir 拿到真句柄（Windows 是不透明句柄，值不打印）`——
   `*anyopaque` 句柄值每次运行都变，演示输出要逐字节可复现就不打印值）
    [directory] sub
    [file] a.txt

[Walker]（递归遍历的现成壳，不用自己写递归）
    walk: sub                      kind=directory  depth=1
    walk: sub/c.log                kind=file       depth=2
    walk: sub/b.txt                kind=file       depth=2
    walk: a.txt                    kind=file       depth=1
  共 4 条（含根下 3 个条目）
  Walker.Entry 有 dir/basename/path/kind 四个字段，depth() 是便捷方法
 dir basename path kind
```

注意 `Dir` 结构体**只有一个字段** `handle`——它就是个 fd 包装，没有任何缓冲；缓冲在 `Iterator` 里（那 2048 字节）。

`entry.name` 失效的实测对照（造 60 个长文件名，让目录项总字节远超 2048，必然触发 refill）：

```text
[entry.name 失效实测] 60 个长文件名 ⇒ 目录项缓冲必然被 refill 复用
  目录项缓冲 reader_buffer_len = 2048 字节，造了 60 个长文件名
  现场读到的第 1 条真名 = "file_021_with_a_long_name_to_force_refill.txt"（45 字节）
  存切片组  raw[0]  = "   H - file_054_with_a_long_name_to_force_re"（45 字节）逐字节相同 = false
  存副本组 owned[0] = "file_021_with_a_long_name_to_force_refill.txt"（45 字节）逐字节相同 = true
⇒ 存切片那组的第 1 条已经被后续 next() 覆写成别的条目（或含非文本字节）
⇒ 这就是为什么 collectFiles 里每条都 dupe：这是**正确性必需**，不是洁癖
   （raw[0] 那串乱码的具体字节取决于 readdir 返回顺序，各系统不同；
     稳定的是 `逐字节相同 = false` 这个**判定**——它对任何遍历顺序都成立）
```

"存切片组"那行的前 5 个字节在终端里是**不可见控制字符**（`H -` 前面），因为覆盖它的是另一个 `dirent` 的二进制头部。这里最值得记的不是那串乱码，而是**两条判定**：`raw[0] 逐字节相同 = false`（切片已被覆写）、`owned[0] 逐字节相同 = true`（副本安全）。这个判定在任何 readdir 顺序下都成立，所以可以放心写进文档和测试。

> ⚠️ 上面的 `raw[0]` 那行里，`<ESC>` 之类的不可见字节在真实终端/重定向文件里是**原始字节**。这里显示成 ` H - ` 是因为终端渲染。文档里之所以能这么写，是因为程序本身打印的是**原始字节**——你复制这段文本去做比对时要注意这一点。

---

## 24.3 逐行读取与正确处理超长行

先看 0.17 到底有哪些方法（实测 `@hasDecl`）：

```zig
// examples/24_minigrep/src/main.zig 第 511-519 行
    std.debug.print("0.17 里这些方法**不存在**（实测 @hasDecl）：\n", .{});
    std.debug.print("  File.readAll           = {}\n", .{@hasDecl(std.Io.File, "readAll")});
    std.debug.print("  File.writeAll          = {}\n", .{@hasDecl(std.Io.File, "writeAll")});
    std.debug.print("  File.readStreaming     = {}\n", .{@hasDecl(std.Io.File, "readStreaming")});
    std.debug.print("  File.writeStreamingAll = {}\n", .{@hasDecl(std.Io.File, "writeStreamingAll")});
    std.debug.print("⇒ 一次性读完的 API 搬到 Dir 上：Dir.readFileAlloc(io, path, gpa, .limited(n))\n", .{});
    std.debug.print("⇒ 流式的 API 留在 File 上：readStreaming(io, &.{buf}) / reader(io, &buf)\n", .{});
    std.debug.print("  Io.Limit 是 enum(usize)：.limited(n) / .unlimited / .nothing\n", .{});
    std.debug.print("  readStreaming 的上限是 Io.Limit，**不是** usize（20 章实测 Io.Limit 是非穷尽枚举）\n", .{});
```

（实际文件里 `{buf}` 写成 `{{buf}}`——格式串里的字面花括号必须转义，否则被当成格式占位符，实测报 `error: too few arguments`。）

`File.readAll` 和 `File.writeAll` **都不存在**。一次性读完的 API 搬到 `Dir` 上叫 `readFileAlloc`，而且第 4 个参数是 `std.Io.Limit` **枚举**不是 `usize`。

三种读法的实测对比：

```text
0.17 里这些方法**不存在**（实测 @hasDecl）：
  File.readAll           = false
  File.writeAll          = false
  File.readStreaming     = true
  File.writeStreamingAll = true
⇒ 一次性读完的 API 搬到 Dir 上：Dir.readFileAlloc(io, path, gpa, .limited(n))
⇒ 流式的 API 留在 File 上：readStreaming(io, &.{buf}) / reader(io, &buf)
  Io.Limit 是 enum(usize)：.limited(n) / .unlimited / .nothing
  readStreaming 的上限是 Io.Limit，**不是** usize（20 章实测 Io.Limit 是非穷尽枚举）

[读法一] Dir.readFileAlloc：一次吃进内存，内存占用 = 文件全宽
  行1 =alpha
  行2 =beta
  行3 =gamma
  行4 =
  splitScalar 给出 4 段（末段是空串，因为文件以 \n 结尾）
  ⚠️ 这就是"行号会多 1"的来源："a\n" 切成 2 段，第二段是空

[读法二] File.readStreaming：按块读，单次上限由你给的切片决定
  第 1 块读到 8 字节："alpha
be"
  第 2 块读到 8 字节

[读法三] File.Reader + fillMore/buffered/toss：真正的流式逐行
  三件套的职责：
    fillMore()  把底层缓冲填满；EOF 时返回 error.EndOfStream
    buffered()  当前"已读但未消费"的字节（切片，借用）
    toss(n)     消费掉 n 字节（移动读游标，不是拷贝）
  ⚠️ 关键规则：只在**真的找到分隔符**时才多消费 1 字节（含 \n）
     无脑写 toss(idx.? + 1) 在没找到时会 panic: assert(r.seek <= r.end)
  行1 ="alpha"（缓冲区只有 4 字节）
  行2 ="beta"（缓冲区只有 4 字节）
  行3 ="gamma"（缓冲区只有 4 字节）
  共 3 行 ⇒ 4 字节缓冲照样读出 6 字节的行
  ⇒ 补齐逻辑必须自己写；这就是 search.LineReader 存在的理由

[超长行] 1000 字节的单行 + 8 字节缓冲
  读到 1000 字节的行：前 12 字节 ="xxxxxxxxxxxx"…
  ⇒ 缓冲 8 字节、行长 1000 字节，内存占用是 O(行长) 而不是 O(文件)
  max_line_bytes=64 → LineTooLong（护栏生效，不吃光内存）
```

三个要点：

1. **读法一**的"行4 =空"不是 bug，是 `splitScalar` 的语义：`"alpha\nbeta\ngamma\n"` 切成 4 段，最后一段是空串。用它算行号会多 1——这是 grep 类工具最常见的 off-by-one。
2. **读法二**的 `readStreaming` 返回 `usize`（读了多少），EOF 用 `error.EndOfStream` 表示，**不是返回 0**。
3. **读法三**是唯一正确的逐行方式。关键规则是 `toss` 的调用时机：只在 `idx != null`（真的找到 `\n`）时才 `toss(idx+1)`，否则 `toss(avail.len)`。无脑写 `toss(idx.? + 1)` 会在没找到分隔符时 panic `assert(r.seek <= r.end)`。

`LineReader` 的完整实现（`src/search.zig` 第 48–113 行）在生产代码里补了三件事：**行超长自动扩容**（`std.ArrayList`，上限 `max_line_bytes`）、**文件末尾无换行时的收尾**（最后一行也要算）、**零宽行处理**（空行也是行）。

```zig
// examples/24_minigrep/src/search.zig 第 78-108 行
            // ② 在**当前可用字节**里找行尾
            const idx = std.mem.indexOfScalarPos(u8, avail, 0, '\n');
            const cut = idx orelse avail.len;
            try self.appendChecked(gpa, avail[0..cut]);

            // ③ 只在**真的找到分隔符**时才多消费 1 字节（含那个 \n）。
            //    无脑写 toss(idx.? + 1) 是 0.17 的经典 panic：
            //    assert(r.seek <= r.end) failed（20 章实测）
            self.reader.toss(if (idx) |k| k + 1 else avail.len);

            if (idx != null) return self.line.items;
            // 没找到换行 ⇒ 这一段只是行的一部分，回到 ① 继续读
```

> ⚠️ **零长 Reader 缓冲不能配 `fillMore`**。`f.reader(io, &.{})` 看起来最省内存，但一调 `fillMore` 就 panic：`Io.Reader.defaultRebase: assert(r.buffer.len - r.seek >= capacity) failed`——因为 `fillMore` 会 `rebase(r, r.end - r.seek + 1)`，至少要 1 字节。20 章用 `&.{}` 配的是 `readSliceShort`（不 `fillMore`），所以那里没事。**要调 `fillMore`，缓冲至少给 1 字节。**（这条已写成回归测试，见 24.11。）

---

## 24.4 手写正则引擎（一）：递归下降怎么消歧

正则引擎分三层，这一节讲第一层（语法）。文法用 BNF 写清楚，四层函数一一对应：

```zig
// examples/24_minigrep/src/regex.zig 第 234-252 行
//  文法（Backus-Naur 形式，24.4.0 给出全文）：
//
//      alt       := concat ('|' concat)*
//      concat    := repeat*
//      repeat    := atom quantifier?
//      quantifier := ('*' | '+' | '?') '?'?
//      atom      := '(' alt ')' | '[' class ']'
//                 | '.' | '^' | '$' | '\' escape | 普通字节
//
//  每个 parseXxx 都往 `out`（指令数组）**追加**指令。指令下标就是数组下标，
//  所以"回填"只是改写某个下标上的值——**一个字节都不用挪**。
//  这是把树压平之后最大的好处：没有重排，全是原地打补丁。
```

**消歧一：量词只作用于紧邻的前一个 atom。** 所以 `ab*` 是 `a` 后跟 `b*`，不是 `(ab)*`。这不是靠"贪心"或"就近结合"这类约定，靠的是文法本身——`parseRepeat` 每次只吃一个 atom，然后立刻吃掉它后面所有连续量词。

**消歧二：`|` 优先级最低。** `parseConcat` 遇到 `|` 和 `)` 就停，把控制权交还 `parseAlt`。终止符不在任何 atom 的起始字符集里，所以**不需要任何优先级表**。

**消歧三：贪婪 vs 非贪婪 = `Split` 的两个下标谁在前。** 这里有本章最容易写错的一处：

```zig
// examples/24_minigrep/src/regex.zig 第 356-386 行
///     X*   ⇒  slot:  Split(xs, after)         贪婪：先跑一遍 X 再问要不要停
///             xs:    <X>
///             after: Split(xs, done)          跑完还能再来一次
///             done:
///
///     X*?  ⇒  slot:  Split(after, xs)         **入口就倒过来**：能停就停
///             xs:    <X>
///             after: Split(done, xs)          回边也倒过来
///             done:
///
///     X+   ⇒  xs:    <X>                      至少先匹配一个（顺序执行保证）
///             after: Split(xs, done)          之后等价于 X*
///             done:
///
///     X+?  ⇒  after 的下标对调
///
/// ⚠️ **惰性要改两处，不是一处**。这是本章最容易写错的地方：
/// `X*` 有两个决策点——"要不要进第一次 X"（slot）和"要不要再来一次"（after）。
/// 只倒转 after 的话，`a*?` 匹配 "aaaa" 仍会先吃掉一个 a（实测得到 0-1 而不是 0-0）。
/// 两处都倒转，`a*?` 才真的"能停就停"（实测 0-0）。
fn applyQuantifier(p: *Parser, slot: u32, q: u8, lazy: bool) CompileError!void {
    const xs = slot + 1;
    const atom_end: u32 = @intCast(p.em.n.*);

    switch (q) {
        '?' => {
            // 0 或 1 次：分支的两条路分别是"进 X"和"跳过 X"
            p.set(slot, if (lazy)
                .{ .split = .{ atom_end, xs } }
            else
                .{ .split = .{ xs, atom_end } });
        },
        '*' => {
            // 回边放在原子**之后**（而不是之前）：跑完 X 再问"再来一次？"
            // 这与"进循环前先问"的语义等价，但不需要移动任何指令。
            const after = try p.put(.{ .split = .{ xs, atom_end + 1 } });
            const done = after + 1;
            p.set(after, if (lazy)
                .{ .split = .{ done, xs } }
            else
                .{ .split = .{ xs, done } });
            // 入口也要按贪婪性翻转（惰性的第一处，见上面的警告）
            p.set(slot, if (lazy)
                .{ .split = .{ after, xs } }
            else
                .{ .split = .{ xs, after } });
        },
```

`X*` 的回边放在原子**之后**（而不是之前）是个小技巧：这样"跑完 X 再问要不要再来"的语义与"进循环前先问"完全等价，却**不需要移动任何指令**——因为压平之后 pc 就是数组下标，往前插一条指令要重编所有下标。

**消歧四：量词后紧跟的 `?` 是懒惰修饰，不是又一个量词。** `a?` 是"可选的 a"，`a??` 是"懒惰的可选 a"。靠"吃掉量词后再看一个字符"区分。连写量词（`a**`）直接报 `RepeatedQuantifier`——POSIX 也禁止，这里显式拒绝而不是猜。

**字符类的区间消歧**：`[a-]` 是"a 或 -"，不是区间；只有 `-` 后面确实还有字符且不是 `]` 才算区间首。这是 POSIX 的规则，实测成立。

运行输出（`zig build run`）：

```text
文法（BNF，四层函数一一对应）：
  alt       := concat ('|' concat)*      ← parseAlt    优先级最低
  concat    := repeat*                    ← parseConcat 遇 | 和 ) 就停
  repeat    := atom quantifier?           ← parseRepeat 量词只管前一个 atom
  quantifier := ('*'|'+'|'?') '?'?        ← applyQuantifier 后一个 ? 是懒惰修饰
  atom      := '(' alt ')' | '[' class ']' | '.' | '^' | '$'
             | '\' escape | 普通字节
⚠️ 递归下降 =函数调用栈。四层之间的边界靠**终止符**划分，不需要优先级表

[消歧一] 量词只作用于紧邻的前一个 atom
  ab*        在 "aab" 上→ [0,1) = "a"
  (ab)*      在 "aab" 上→ [0,0) = ""
  ⇒ ab* 匹配 aab 只吃到 "a"（b* 匹配空）；(ab)* 才能匹配 "abab"
  ⇒ 这不是"贪心"或"就近结合"的约定，是文法本身：repeat 每次只吃一个 atom

[消歧二] | 优先级最低：concat 遇 | 就停，把控制权交回 alt
  ab|cd      在 "abcd" 上→ [0,2) = "ab"
  a(b|c)d    在 "acd" 上→ [0,3) = "acd"
  ⇒ ab|cd 在 abcd 上只能吃到 "ab"；加了括号才轮到 cd
  ⇒ 不需要任何优先级表——终止符（| 与 )）不在 atom 的起始字符集里

[消歧三] 贪婪 vs 非贪婪：Split 的两个下标谁在前
  a*         在 "aaaa" 上→ [0,4) = "aaaa"
  a*?        在 "aaaa" 上→ [0,0) = ""
  a+?        在 "aaab" 上→ [0,1) = "a"
  ⇒ 贪婪 = split(x=xs, y=exit)；非贪婪 = **两个下标对调**
  ⇒ 实测踩坑：X* 有**两个**决策点（入口 slot + 回边 after），
     只翻转回边的话 a*? 在 aaaa 上仍得到 0-1（错），两处都翻才得到 0-0

[消歧四] 量词后紧跟的 ? 是懒惰修饰，不是又一个量词
  a?         在 "abc" 上→ [0,1) = "a"
  a??        在 "abc" 上→ [0,0) = ""
  a??b       在 "ab" 上→ [0,2) = "ab"
  ⇒ a?  是"可选的 a"；a?? 是"懒惰的可选 a"；a** 直接报 RepeatedQuantifier

[字符类消歧] a-z 是区间，[a-] 是"a 或 -"
  [a-]       在 "-" 上→ [0,1) = "-"
  [a-c]      在 "b" 上→ [0,1) = "b"
  [^a-c]     在 "zb" 上→ [0,1) = "z"
  ⇒ 规则：`-` 后面必须还有字符且不是 `]` 才算区间首（POSIX 规定）
  ⇒ 取反在**编译期**就分成 class_neg 指令，运行期不查 negated 标志

[错误必须显式] 10 种编译错误，没有一种是"默默猜"
  (ab        → UnclosedGroup
  ab)        → UnmatchedClose
  [a-z       → UnclosedClass
  []         → UnclosedClass
  *ab        → NothingToRepeat
  ()*        → NothingToRepeat
  a**        → RepeatedQuantifier
  [z-a]      → ReversedRange
  a\         → DanglingEscape
  a{2,3}     → UnsupportedRepeat
  ⚠️ `{n,m}` 明确报 UnsupportedRepeat，而不是当字面量 { 或 n,m
  ⚠️ `()*`（重复空组）报 NothingToRepeat：POSIX 未定义，各引擎行为不一
  ⇒ 判断"能否重复"用的是 consuming 计数：空组只产出占位 jump，不算消费
```

最后那 10 种错误值得单独强调：**`a{2,3}` 报 `UnsupportedRepeat` 而不是当字面量**，因为后者会静默产生一个用户绝对意料之外的结果。`()` 的判定更微妙——它只产出两条占位 `jump`，**不消费任何输入**，所以要靠 `Parser.consuming` 计数才能发现"这个原子什么都没匹配"。

---

## 24.5 正则的 comptime 生成：模式在编译期变成指令数组

这一节讲第二层（指令层）的设计决策：**没有 AST**。语法树被压平成一条线性指令数组，只剩两种控制流：

```zig
// examples/24_minigrep/src/regex.zig 第 56-95 行
pub const Program = struct {
    ops: []const Op,
    /// 模式串里 `()` 的个数
    group_count: usize = 0,
    /// 模式以 `^` 开头：只需从位置 0 起试（省一个 O(n) 因子）
    anchored_start: bool = false,
    /// 编译诊断：模式多长、编出多少条指令（"指令膨胀比"）
    pattern_len: usize = 0,
    op_count: usize = 0,

    pub fn deinit(self: Program, gpa: std.mem.Allocator) void {
        gpa.free(self.ops);
    }
};

/// 一条指令。用 `union(enum)` 而非"enum + payload 数组"，因为各变体载荷
/// 差异极大（char 只要 1 字节，class 要整张区间表），塞进 union 最省内存。
///
/// 载荷里的 `u32` 是**指令下标（pc）**，指向 ops 数组内的位置。
/// pc 0 是第一条指令——执行器的初始 pc 恒为 0。
pub const Op = union(enum) {
    /// 匹配一个字面字节
    char: u8,
    /// 匹配任意字节，但**不含换行**（正则默认语义：`.` 不跨行）
    any: void,
    /// 匹配字符类（正向）
    class: Class,
    /// 匹配字符类（取反，即 `[^...]`）
    class_neg: Class,
    /// 分支：先试 `pc[0]`，失败则回溯走 `pc[1]`。
    /// **谁在 pc[0] 谁就是贪婪**——非贪婪就是把两个下标对调（24.4.3）。
    split: [2]u32,
    /// 无条件跳转。**允许往回跳**，`X*` 的回边就靠它
    jump: u32,
    /// `^`：只在文本位置 0 处成功
    bol: void,
    /// `$`：只在文本末尾处成功
    eol: void,
    /// 匹配终点。指令数组的**最后一条**必须是它
    accept: void,
```

**压平带来的最大好处：pc 就是数组下标，于是"回填"= 原地改写一个值，一个字节都不用挪。** 树形结构做不到这一点——在树中间插一条指令，所有下标都要重编。

代价是"预留槽位"：每个 atom 先占一条 `jump`，真正的原子指令追加在它后面，于是量词能把分支指令放在原子**前面**时，只要改写槽位即可。上面那句"每个 atom 两条指令"说的就是这个。

三个短模式的反汇编（`regex.dump` 的真实输出）：

```text
[反汇编] 模式 abc —— 每个 atom 两条指令（预留槽 + 本体）
  0  jump    → 1
  1  jump    → 2
  2  char    'a'  (0x61)
  3  jump    → 4
  4  char    'b'  (0x62)
  5  jump    → 6
  6  char    'c'  (0x63)
  7  accept  匹配终点
  纯 jump 指令是"预留槽位"退化后的产物：没有量词时它跳到 slot+1，
  也就是直接进入 atom 本体。⚠️ 若忘了退化，它会保持占位值 0 →死循环

[反汇编] 模式 a* —— 多了两条 Split：入口与回边
  0  jump    → 1
  1  split   x=2 y=3
  2  char    'a'  (0x61)
  3  split   x=2 y=4
  4  accept  匹配终点
  pc 1 = 入口 split（要不要进第一次 X）
  pc 3 = 回边 split（要不要再来一次），它跳回 pc 2 —— **允许反向跳转**

[反汇编] 模式 (ERROR|WARN)+ —— 嵌套与分支同时存在
  共 25 条指令，分组数=1
```

`abc` 里的 6 条 `jump` 就是预留槽退化的结果（跳到 `slot+1`，也就是直接进 atom 本体）。**如果忘了退化**，槽位会保持 `put` 时写入的占位值 0，执行器从 pc=0 跳回 pc=0 —— 死循环，表现形式是 `TooManySteps` 而不是 hang，所以不容易发现。

`a*` 里 `pc 3` 跳回 `pc 2`，这是**反向跳转**——NFA 里做不到这一点（见 24.6）。

指令膨胀比（N 字节模式编出约 2N 条指令）：

```text
[指令膨胀比] 模式 N 字节 → 约 2N 条指令
  abc               3 字节 →   8 条指令（×2.7）
  a*                2 字节 →   5 条指令（×2.5）
  a?                2 字节 →   4 条指令（×2.0）
  (a)               3 字节 →   6 条指令（×2.0）
  a|b|c             5 字节 →  12 条指令（×2.4）
  [a-z]+            6 字节 →   5 条指令（×0.8）
  s*rvice=[a-z]+   14 字节 →  20 条指令（×1.4）
  ⇒ 膨胀主要来自**预留槽位**（每个 atom 一条）。换来的是零重排、可原地回填
```

`[a-z]+` 的 ×0.8 是因为字符类 6 字节只编出 1 条 `class` 指令——**字符类是指令最密的地方**，这也是为什么工业级引擎会用预编译 DFA 来处理它。

### comptime 版：同一个解析器，编译期跑一遍

`compileComptime(comptime pattern)` **复用 24.4 的同一个解析器**，差别只有两点：写进栈上定长数组而非分配器、返回 `const` 数组（进 `.rodata`）。这里有个刻意的设计决定：**不为 comptime 重写第二遍解析器**——重复一遍 = 两处逻辑可能不同步 = 一类极难查的 bug。

```zig
// examples/24_minigrep/src/regex.zig 第 601-632 行
pub fn compileComptime(comptime pattern: []const u8) Program {
    // 关键技巧：指令数组必须是 **const**（编译期常量，进 .rodata），
    // 不能是 `comptime var`。Zig 明令禁止把 `comptime var` 的地址泄漏到运行期
    // （实测报错：runtime value contains reference to comptime var）——
    // 因为 comptime var 是"编译器工作区里的临时量"，不是程序的静态数据。
    //
    // 所以这里在 comptime 块里解析到一个局部 scratch，最后
    // `const frozen = scratch[0..n]` **拷贝**成常量数组再返回。
    // 拷贝只发生在编译期，运行期零成本。
    const Result = struct { ops: []const Op, groups: usize, n: usize };
    const r: Result = outer: {
        @setEvalBranchQuota(20_000);
        var scratch: [max_ops]Op = undefined;
        var cnt: usize = 0;
        var em: Emitter = .{ .buf = &scratch, .n = &cnt };
        var p: Parser = .{ .pat = pattern, .em = &em };
        parseAlt(&p) catch @panic("compileComptime: 模式串非法");
        if (p.pos != pattern.len) @panic("compileComptime: 模式串有多余的 )");
        _ = em.put(.{ .accept = {} }) catch @panic("compileComptime: 指令太多");
        // 必须拷进一个**匿名 const 数组**再切片——只切 scratch 的话
        // 返回的指针仍然指向那个 comptime var，逃逸到运行期会被拒绝
        const frozen: [cnt]Op = scratch[0..cnt].*;
        break :outer .{ .ops = frozen[0..], .groups = p.group_count, .n = cnt };
    };
```

两处 `.*` / 拷贝都带着注释，因为它们都不是"显然该这么写"的代码：
- `scratch[0..cnt].*`——`scratch` 是数组，切片得到的是 `*[cnt]Op`，要 `.deref` 成 `[cnt]Op` 才能赋给 `const frozen`。
- `.ops = frozen[0..]`——这才是指向静态数据的指针。

运行输出证明 comptime 版与运行期版**逐条相同**：

```text
[comptime 生成] 同一个解析器，编译期跑一遍
  compileComptime(comptime pattern) 与 compile(gpa, pattern) **共用** 24.4 的解析器，
  差别只有两点：① 写进栈上定长数组而非分配器② 返回 const 数组（.rodata）
  ERROR|WARN     comptime  22 条 / 运行期  22 条  逐条相同=true
  a+?            comptime   5 条 / 运行期   5 条  逐条相同=true
  [0-9]+         comptime   5 条 / 运行期   5 条  逐条相同=true
  ⚠️ 踩坑一：不能把 comptime **var** 的地址返回（实测报
     runtime value contains reference to comptime var）——var 是编译器工作区，
     不是程序静态数据。必须拷进一个 const 数组再切片。
  ⚠️ 踩坑二：不能用 expectEqualSlices(Op, ...) 比指令——Op 的 class 变体里
     Class.ranges 是定长数组，len 之后的槽位是 undefined，整条做 == 就是在比内存垃圾。
```

**踩坑二**是这一节最实用的一条：`Op` 的 `class` 变体里 `Class.ranges` 是定长数组 `[16]Range`，`len` 之后的槽位从未写入（`undefined`）。整条指令做 `==` / `meta.eql` 就是在比内存垃圾。必须逐字段比：

```zig
// examples/24_minigrep/src/main.zig 第 840-856 行
fn opsEqual(a: regex.Op, b: regex.Op) bool {
    if (std.meta.activeTag(a) != std.meta.activeTag(b)) return false;
    return switch (a) {
        .char => |v| v == b.char,
        .any, .bol, .eol, .accept => true,
        .split => |v| v[0] == b.split[0] and v[1] == b.split[1],
        .jump => |v| v == b.jump,
        .class => |v| classEqual(v, b.class),
        .class_neg => |v| classEqual(v, b.class_neg),
    };
}
```

### @typeInfo 的三条平行数组（0.17 的形状）

0.17 的 `@typeInfo` 对 struct/union 给出**三条等长的平行数组**：`field_names` / `field_types` / `field_attrs`。

```text
[@typeInfo 0.17 三条平行数组] 反射 Op 的字段
  Op 是 union(enum)，字段数 = 9；tag_type 是编译器内部匿名类型，
    @typeName 打出来 = [@typeInfo(regex.Op).@"union".tag_type.?]（**不是**类型名，是产生它的表达式）
    tag 的字段名（可靠途径）= char any class class_neg split jump bol eol accept 
  三条平行数组长度恒相等（0.17 文档保证）：
    field_names.len = 9  field_types.len = 9  field_attrs.len = 9
    char         : u8                       align=null
    any          : void                     align=null
    class        : regex.Class              align=null
    class_neg    : regex.Class              align=null
    split        : [2]u32                   align=null
    jump         : u32                      align=null
    bol          : void                     align=null
    eol          : void                     align=null
    accept       : void                     align=null
  Op.field_attrs 的元素类型 = []const lang.Type.Union.FieldAttributes
  Union .FieldAttributes 字段： align
  Struct.FieldAttributes 字段： comptime align default_value_ptr
  ⚠️ 0.17 的 @typeInfo(union) 字段是 field_types（不是老版的 types），
     且@typeInfo(T) 对**函数**返回的 Type.Fn 已改成 struct：
     没有 .params 了，改用 .param_types / .param_attrs / .is_generic
     实测本文件的 classify（comptime 标签 + 值）：is_generic=true
     param_types.len=3： #0=[]const u8 #1=u32 #2=bool
     返回类型=u64
     param_attrs[0].noalias = false
     param_attrs[1].noalias = false
     param_attrs[2].noalias = false
  ⚠️ 0.17 的 enum 分支也不再是 is_enum/is_exhaustive，而是一个 mode 字段：
     @typeInfo(std.Io.Clock).@"enum".mode = exhaustive（exhaustive / nonexhaustive）
```

这段输出里有**五个**独立的 0.17 变化，每一个都是照抄老代码会踩的：

1. **`field_types` 是 `[]const type`——类型不是运行期值。** 三条数组一起遍历时**必须用 `inline for`**，用普通 `for` 会报 `values of type 'type' must be comptime-known, but index value is runtime-known`。
2. **对函数用 `@typeInfo` 时不能直接写 `@TypeOf(std.Build.addModule)`**（实测报 `expected type 'type', found 'fn (...)'`），要先 `@TypeOf` 包一层变成函数类型再 `@typeInfo`。
3. **`Type.Fn` 从 union 改成了 struct**：没有 `.params` / `.return_type` 了，改用 `.return_type: ?type` / `.param_types: []const ?type` / `.param_attrs` / `.is_generic`。
4. **`Type.Enum` 的 `is_enum` / `is_exhaustive` 合并成一个 `mode: Mode`**（`Mode` 是 `enum { exhaustive, nonexhaustive }`）。照抄 `if (ti.@"enum".is_exhaustive)` 会报 `no field named 'is_exhaustive'`。
5. **`Union.FieldAttributes` 与 `Struct.FieldAttributes` 是两个不同类型**：前者只有 `align`，后者还有 `comptime` 和 `default_value_ptr`。想用 `default_value_ptr` 得先确认自己在 struct 分支。

还有一个**真正的怪癖**值得单说（实测）：`union(enum)` 的 `tag_type` 是**编译器内部的匿名枚举**，不是用户能写出来的任何类型。所以 `@typeName` 打到它会**原样打印产生它的那条表达式**（`@typeInfo(regex.Op).@"union".tag_type.?`），而不是一个类型名；把它和手写的同名 enum 比较结果是 `false`。想看 tag 的字段，只能走 `@typeInfo(tag_t).@"enum".field_names`。

> ⚠️ 反射一个**函数**时要写 `@TypeOf(some_fn)`，**不能**写 `@TypeOf(@min)`——`@min` 是编译期内建，`@TypeOf` 只接受"值"，直接写会报 `expected parameter list, found ')'`（实测）。

---

## 24.6 匹配执行：回溯、复杂度、与灾难性爆炸

第三层是带回溯栈的栈式虚拟机。**回溯的全部实现就是两行**：

```zig
// examples/24_minigrep/src/regex.zig 第 664-745 行（节选）
/// 从 `start_pos` 起找第一个匹配，返回它的**结束位置**（`null` = 没匹配上）。
///
/// 返回 `end` 而不是 `Span` 是刻意的：调用方本来就知道 `start_pos`，
/// 省掉一次结构体传递。
fn matchFrom(
    gpa: std.mem.Allocator,
    prog: *const Program,
    text: []const u8,
    start_pos: usize,
    opt: Options,
    stack: *std.ArrayList(Frame),
    stats: *Stats,
) ExecError!?usize {
    stack.clearRetainingCapacity();
    try stack.append(gpa, .{ .pc = 0, .pos = start_pos });

    // 外层 while 弹栈（回溯），内层 while 顺序执行指令（前进）
    while (stack.pop()) |fr| {
        var pc = fr.pc;
        var pos = fr.pos;
        while (true) {
            stats.steps += 1;
            if (stats.steps > opt.max_steps) return error.TooManySteps;

            switch (prog.ops[pc]) {
                // ... char / any / class / class_neg / bol / eol ...
                .split => |t| {
                    // ★ 回溯的全部秘密就在这一行 ★
                    // 把"另一条路 + 当前文本位置"压栈，然后先走优先的那条。
                    // 优先那条走不通时，栈顶弹出来就是**回溯现场**：
                    // 文本位置一步都不用回退（因为它就存在栈里）。
                    try stack.append(gpa, .{ .pc = t[1], .pos = pos });
                    pc = t[0];
                },
                .jump => |t| pc = t,
                .accept => return pos,
            }
        }
    }
    return null;
}
```

`Frame` 只有两个字段：`pc`（回到哪条指令）和 `pos`（从文本的哪个字节位置继续）。**没有"匹配了哪些子表达式"**——因为本引擎不捕获分组。文本位置不用回退，因为它就存在栈帧里。

外层 `while` 是**弹栈**（回溯），内层 `while` 是**顺序执行指令**（前进）。这个双层结构就是整个执行器。

**"最左匹配"是 grep 的语义**：从左往右扫每个起始位置，第一个成功的即返回。但注意，由于 `Split` 的贪婪编法，每个起点内部拿到的自然是**最长**的那个——"最左" + "最长"合起来正是 POSIX 的**左长匹配**规则，它不是额外规定，而是这个执行器结构的自然结果。

### 线性模式的步数（基线数据）

```text
[最左匹配] 从左往右扫起点，第一个成功的即返回
  abc        在 "xxabcxx" 上→ [2,5) = "abc"
  abc        在 "abcabc" 上→ [0,3) = "abc"
  ⇒ "最左" + Split 的贪婪编法 = POSIX 的**左长匹配**，不是额外规定
  ⇒ Program.anchored_start 给 ^ 开头的模式省掉 O(n) 个起点的尝试

[复杂度] 线性模式：步数随输入线性增长
  模式 a+b（7 条指令）
    输入   8 字节 → 回溯步数   171（约 21 步/字节）
    输入  16 字节 → 回溯步数   595（约 37 步/字节）
    输入  32 字节 → 回溯步数  2211（约 69 步/字节）
    输入  64 字节 → 回溯步数  8515（约 133 步/字节）
```

注意 a+b 的"步/字节"是**增长的**（21 → 133），不是常数——因为每个起点都要从头试一遍，起点数随 n 增长。这正是"最左匹配"的固有代价：`O(n × 匹配尝试成本)`。

### 灾难性回溯：`(a+)+b` 撞一串没有 `b` 的 `a`

这是教科书级的反例，模式本身只有 10 条指令：

```text
[灾难性回溯] (a+)+b 撞上一串没有 b 的 a —— 教科书级反例
  模式 (a+)+b 只有 10 条指令（看起来人畜无害）
     n    回溯步数      耗时(ns)  结果
    10           16343         +437645  无匹配
    14          262091        +7015195  无匹配
    18         4194239      +152735387  无匹配
    20        16777145      +454706640  无匹配
    22        67108787     +1722476602  无匹配
  ⇒ 输入每多2 个字符，步数约 ×4：这是 2^n，不是 n^2。
  ⇒ 原因：(a+)+ 的**外层与内层都能切分同一串 a**，切法数是 2^(n-1)。
     回溯引擎会把每一种切法都试一遍，而**全部失败**时一个都省不掉。
  ⇒ 唯一的护栏是 max_steps（本实现默认 200 万步）：超了返回 TooManySteps。
  ⇒ 工业界解法是 Thompson NFA（并行模拟所有状态，恒定时间/空间），
     但 NFA 无法直接给出"最左最长"，必须再做一遍子串提取——各有取舍。
```

**步数序列是这一节最有说服力的部分**：16343 → 262091 → 4194239 → 16777145 → 67108787。输入从 10 涨到 22（12 个字符），步数涨了 4100 倍——每多 2 个字符**精确 ×4**，这是 2^(n-1) 的签名。20 个字符就已经 1677 万步，22 个字符 6710 万步（约 1.7 秒）。

（步数是**完全确定的**——同一台机器连跑两遍，步数列逐字节相同，只有耗时列会变。这是 `Stats.steps` 存在的意义：把复杂度量化成一个可回归的整数。）

**为什么**：(a+)+ 里外层和内层**都能切分同一串 a**。"aaaa" 可以切成 a|aaa、aa|aa、aaa|a、a|a|a|a……共 2^(n-1) 种。回溯引擎会把每一种都试一遍，而**全部失败**时（末尾没有 b）一个都省不掉。

**护栏**：`Options.max_steps`（默认 200 万步）是最小可行的自保手段。超了返回 `error.TooManySteps` 而不是把机器卡死。24.11 里有一条测试专门断言这个护栏生效（`(a+)+b` 撞 22 个 a、预算 5 万步，第 50001 步被打断）。

**工业界的解法**是 Thompson NFA：**并行**模拟所有可能状态，一次扫描，时间与空间都是 O(n)。代价是它给出的是"哪些位置可能结束"，要拿到"最左最长"必须再做一遍子串提取（Rust regex  crate 就是这么做的）。所以两种引擎各有适用场景：NFA 适合长文本海量匹配，回溯适合"模式短、文本短、要求最左最长"。

### 两种状态机对比

本章叫"递归下降 + 状态机"，现在可以明确两者的分工：

| | 语法层（24.4） | 指令执行（24.6） |
|---|---|---|
| 机制 | 递归下降（函数调用栈） | 栈式状态机（显式 `Frame` 栈） |
| 驱动 | 模式串长度 | 文本长度 |
| 状态 | 函数调用栈（隐式） | `[]Frame`（显式，可算步数） |
| 歧义消解 | 文法终止符 + 优先级表 | `Split` 两个下标的顺序 |
| 复杂度 | O(模式长度) | 最坏 O(2^n)，护栏 `max_steps` |

用显式栈而不是函数递归做执行，唯一的理由是**能数步数**——递归实现的回溯藏在调用栈深度里，你没法在运行期给它加预算。

---

## 24.7 输出格式化与颜色

颜色就是 ANSI 转义序列，纯文本无依赖。五个常量集中在一个地方（`src/search.zig` 第 116–140 行），这样"哪些字节会被写进终端"一眼能看全：

```zig
// examples/24_minigrep/src/search.zig 第 116-140 行
pub const Color = struct {
    /// 重置
    pub const reset = "\x1b[0m";
    /// 红色加粗——命中片段
    pub const hit = "\x1b[1;31m";
    /// 黄色——文件名
    pub const path = "\x1b[1;33m";
    /// 青色——行号
    pub const line_no = "\x1b[36m";
    /// 灰色加粗——统计行
    pub const dim = "\x1b[2m";

    /// 终端是否支持颜色。**非 TTY 时必须关色**——
    /// 否则重定向到文件时会留下一堆 ^[ 字面量（本章坑位清单第 3 条）。
    pub fn enabledFor(f: std.Io.File, io: std.Io) bool {
        return f.isTty(io) catch false;
    }
};
```

`ColorMode` 是**三态**而不是 bool：`auto`（看 `isTty`）/ `always`（强制开，给 `less -R` 用）/ `never`。只有两态的话，"重定向到文件自动关色"和"我明确要求开色"就没法同时表达。

高亮函数用**游标式推进**而不是"每段都从头 `indexOf`"：每段只处理 `[from, to)` 之间的字节，写完把 `from` 推到 `to`。复杂度是 **O(行宽)**，与命中段数无关。

```zig
// examples/24_minigrep/src/search.zig 第 142-170 行
pub fn writeHighlighted(
    w: *std.Io.Writer,
    line: []const u8,
    spans: []const regex.Span,
    color: bool,
) !void {
    if (spans.len == 0 or !color) {
        try w.writeAll(line);
        return;
    }
    var from: usize = 0;
    for (spans) |s| {
        // 防御：越界或逆序的区间直接跳过，不让一个坏 span 毁掉整行输出
        if (s.start > s.end or s.end > line.len) continue;
        if (s.start < from) continue; // 重叠区间：跳过（findAll 已保证不重叠）
        try w.writeAll(line[from..s.start]);
        try w.writeAll(Color.hit);
        try w.writeAll(line[s.start..s.end]);
        try w.writeAll(Color.reset);
        from = s.end;
    }
    try w.writeAll(line[from..]);
}
```

那个"防御"分支不是洁癖：`-v`（反向匹配）时整行打印但**没有命中片段可染**，传进来的 `spans` 是空数组——如果去掉 `spans.len == 0` 那个早退分支，`line[0..0]` 加两段转义序列，会得到"整行被染色但一个字符都没命中"的荒谬输出。坏区间（越界/重叠）的防御同理：它们不该存在，但一个 grep 工具因为一个坏 span 就毁掉整行输出是没道理的。

运行输出（`zig build run`）：

```text
颜色就是 ANSI 转义序列，纯文本，无依赖：
   重置   命中片段   文件名   行号   统计行
  ⚠️ 转义序列里**没有** 'm' 之外的语义；`\x1b[1;31m` = ESC [ 1;31 m

[逐字节对照] 同一行，开色 vs 关色
  命中 1 段： [11,16)="ERROR"
  关色：2026-03-01 ERROR service=billing msg="payment timeout"
  开色：2026-03-01 ERROR service=billing msg="payment timeout"

[十六进制] 证明转义序列真的写进了字节流
  高亮 "ab" 得到 13 字节： 1b 5b 31 3b 33 31 6d 61 62 1b 5b 5b 30 6d
  可读形式：<ESC>[1;31mab<ESC>[0m

[TTY 检测] 非终端必须自动关色
  File.isTty(io) 的返回类型 = bool
  当前 stdout.isTty = false ⇒ --color=auto 时关颜色
  ⚠️ 若不检测就无条件上色，`minigrep ... > out.txt` 会得到一堆 ^[ 字面量。
  ⚠️ ColorMode 三态：auto（看 isTty）/ always（强制开，给 less -R 用）/ never

[复杂区间不能毁掉输出] 坏 span（越界/重叠）被跳过
  喂 3 个坏区间 → "<ESC>[1;31mab<ESC>[0mcd"（其余字节原样输出，没有丢字也没有乱序）
```

> ⚠️ "关色"和"开色"两行在终端里看起来**完全一样**——因为本节故意用 `writerStreaming` 写 stderr，而 `zig build run` 的 stderr 在脚本里不是 TTY，所以 `\x1b[1;31m` 被自动去色了。要看到真颜色，请直接 `./zig-out/bin/minigrep`（stderr 连终端），或者用 `--color=always`。下一行的十六进制输出才是"转义序列真的进了字节流"的证据。

十六进制那行是最硬的证据：`1b 5b 31 3b 33 31 6d` 就是 `ESC [ 1 ; 3 1 m`，`61 62` 是 "ab"，`1b 5b 30 6d` 是 `ESC [ 0 m`。共 13 字节 = 7 + 2 + 4。

### ⚠️⚠️ 本章最隐蔽的坑：`writer` vs `writerStreaming`

这条值得单开一个小节，因为它是**本章唯一"本地怎么测都正常、只在校验脚本里才炸"**的 bug。

`File.writer(io, buf)` 默认是 **positional 模式**（写之前会 seek 文件偏移），而 `std.debug.print` 写 stderr 走的是 `Threaded.stderr_writer`（streaming 追加）。两者混用时，positional writer 会把偏移 **seek 回自己记录的 pos**，于是**覆盖掉 `std.debug.print` 刚写的字节**。

最小复现（实测）：

```zig
var b: [256]u8 = undefined;
var f1 = std.Io.File.stderr().writer(io, &b);
try f1.interface.writeAll("AAA-positional-writer\n");
f1.interface.flush() catch {};
std.debug.print("BBB-after-dprint\n", .{});   // 追加成功
var f2 = std.Io.File.stderr().writer(io, &b);
try f2.interface.writeAll("CCC-second-positional\n");
f2.interface.flush() catch {};
```

```bash
./minigrep 2> out.txt   # 实测 out.txt 里只剩一行：
                        # CCC-second-positional
                        # AAA 与 BBB 全被覆盖了
./minigrep 2>&1 | cat   # 管道下三行都在，完全正常
```

**为什么管道下看不出来**：管道不可 seek，positional 模式退化成追加。所以这个 bug **只在 `2> file` 时暴露**。而 `run-all.sh` 不重定向文件，所以本地跑 `zig build run` 永远是"正常"的。

换成 `writerStreaming`（不 seek，纯 append）后三行都在。所以本文件所有 stderr Writer 都用 `writerStreaming`：

```zig
// examples/24_minigrep/src/main.zig 第 44-72 行
/// 需要真 `Writer` 的少数几处（`regex.dump` / `search.writeHighlighted`）
/// 走的是 stderr 缓冲 Writer。它与 `dprint` 写的是**同一个 fd**。
///
/// ⚠️⚠️ 这里必须用 **`writerStreaming`** 而不是 `writer`，否则本节内容会凭空消失。
/// 这是 0.17 最隐蔽的一个坑（本章实测踩到）：
///
/// `File.writer(io, buf)` 默认是 **positional 模式**（`fw.mode == .positional`），
/// 写之前会 **seek 文件偏移**。而 `std.debug.print` 写 stderr 走的是
/// `Threaded.stderr_writer`（streaming 追加）。两者混用时 positional writer
/// 会把偏移 **seek 回自己记录的 pos**，于是**覆盖掉 dprint 刚写的字节**。
///
/// 实测（`minigrep 2> out.txt`，out.txt 里只剩最后一行）：
///     var f1 = stderr.writer(io, &b);          // 写 "AAA-positional-writer\n"
///     std.debug.print("BBB-after-dprint\n");  // 追加成功
///     var f2 = stderr.writer(io, &b);          // 同一个 buf
///     // 写 "CCC-second-positional\n"
///     // ⇒ out.txt 只剩 "CCC-second-positional"：AAA、BBB 全被覆盖
///
/// 换成 `writerStreaming`（不 seek，纯 append）后三行都在。
///
/// ⚠️ 为什么"重定向到管道"时看不出来：管道不可 seek，positional 退化成追加。
/// 所以**只有 `2> file` 才暴露**——这是个本地怎么测都"正常"、
/// 只在把输出收进文件时才炸的坑。
```

另外 `.interface` 字段是 `Writer`（**值，不是指针**），所以 `return &fw.interface` 会指向已销毁的栈帧（实测报 `expected type 'Io.Writer', found pointer` + `cast discards const qualifier`）。必须就地 `var` 绑定并把 `&fw.interface` 交给**同作用域**的使用者——这就是 20 章"Writer 不进结构体、必须就地绑定"那条规则的精确形态。

顺带一个格式串的坑：切片必须显式给格式说明符。写 `{}` 会报 `cannot format slice without a specifier (i.e. {s}, {x}, {b64}, or {any})`——因为 `if (tty) "开" else "关"` 的类型是 `[]const u8`（切片），必须用 `{s}`。

---

## 24.8 递归遍历与符号链接

先纠正一个关于 0.17 的**过时说法**：网上常见的 `Walker.Options { .follow_symlinks = ... }` **不存在**。

```text
[Walker 的选项]实测 0.17 的真实形状
@hasDecl(Io.Dir.Walker, "FollowSymlinks") = false
⚠️ 网上常见的 `Walker.Options{ .follow_symlinks = ... }` 在 0.17 **不存在**：
   Walker 就是个两字段包装（inner: SelectiveWalker），walk(dir, alloc) 没有选项参数。
  Walker 字段： inner
  ⇒ 0.17 里 follow_symlinks 变成**各选项结构体里的一个 bool 字段**：
     OpenOptions.follow_symlinks / StatFileOptions.follow_symlinks /
     AccessOptions.follow_symlinks（都是 packed struct，默认 true）
  实测默认值：OpenOptions=true StatFileOptions=true AccessOptions=true
  字段数：OpenOptions=3 StatFileOptions=1 AccessOptions=4（packed struct）
@hasDecl(Io.Dir, "symLink") = true（造软链用得到）
```

`Dir.Walker` 只有**一个字段** `inner: SelectiveWalker`，`walk(dir, alloc)` 也**没有选项参数**。0.17 里 `follow_symlinks` 下沉成了各选项结构体里的一个 `bool` 字段，三个结构体默认都是 `true`。（`Walker` 的注释里说自己是"两字段包装"是文档措辞不准，实测只有 `inner` 一个字段。）

符号链接有三种处理，取决于你在哪个 API 上打开 `follow_symlinks`：

```text
[符号链接的三种处理]
  follow_symlinks=false：看到 2 个软链、1 个普通文件
  ⇒ 不跟随时kind == .sym_link，collectFiles 的 switch 落进 else ⇒ 跳过
  statFile(默认 follow=true) 读软链 link_to_a → size=6（=a.txt 的 6）
  statFile(follow=false) 读同一软链 → size=5（软链自身的长度）
  ⇒ follow 开关就在这里：true 看到目标，false 看到链接本身
  悬垂软链 access(follow=true) → FileNotFound
  ⇒ 这就是 grep 必须处理"软链指向不存在的文件"的原因
    depth=1  link_to_sub                  kind=sym_link
    depth=1  dangling                     kind=sym_link
    depth=1  sub                          kind=directory
    depth=2  sub/b.txt                    kind=file
    depth=1  a.txt                        kind=file
    depth=1  link_to_a                    kind=sym_link
```

三行关键数据：

- `openDir(.{ .follow_symlinks = false })` 时，`entry.kind` 是 `.sym_link`——`collectFiles` 的 `switch` 落进 `else` 分支，于是**不搜软链目标**。这是 grep 的 `-P` 默认行为之外的保守选择。
- `statFile` 默认 `follow_symlinks = true`，所以读 `link_to_a` 拿到的是 `a.txt` 的大小 6；关掉之后拿到的是**软链自身路径字符串的长度** 5。
- **悬垂软链**（指向不存在的文件）在 `follow = true` 时 `access` 直接返回 `FileNotFound`。所以 grep 必须能处理"软链指向不存在的文件"——这是真实世界里最常见的软链问题（比如 `/etc/local/bin` 指向已卸载的卷）。

`dir.symLink` 的签名在 0.17 也变了：`symLink(io, target, link, flags)`——**io 在第一个参数**，flags 是 `SymLinkFlags { is_directory: bool }`（只有一个 bool 字段，不是 options 结构体）。

---

## 24.9 性能与统计：时钟、吞吐、每字节步数

先纠正一个过时说法：`std.Io.Clock` **没有** `.monotonic`。

```zig
// examples/24_minigrep/src/main.zig 第 1183-1200 行
    inline for (@typeInfo(std.Io.Clock).@"enum".field_names) |f| {
        std.debug.print("  .{s}\n", .{f});
    }
    std.debug.print("  ⚠️ 网上常见的 `std.time.Timer` / `.monotonic` 在 0.17 都不存在了。\n", .{});
    std.debug.print("  正确写法：const t0 = std.Io.Clock.now(.awake, io); … t0.durationTo(t1)\n", .{});
    std.debug.print("  .awake    = 单调、不含睡眠时间（macOS 上是 CLOCK_UPTIME_RAW）\n", .{});
    std.debug.print("  .boot     = 单调、含睡眠时间（macOS 上是 CLOCK_MONOTONIC_RAW）\n", .{});
    std.debug.print("  .real     = 挂钟时间，会被 NTP 调整\n", .{});
```

实测的枚举成员是 `real` / `awake` / `boot` / `cpu_process` / `cpu_thread` 五个。选 `.awake` 而不是 `.real` 是因为测耗时时**必须用单调时钟**——`.real` 会被 NTP 调整，测出一个负数耗时是常事。

`Clock.now(clock, io)` 的第一个参数是 clock、**第二个是 io**（注意和 `File.writer(file, io, buf)` 的参数顺序一致，都是 io 在后/中）。返回值是 `Io.Timestamp`（只有一个 `nanoseconds: i96` 字段），差值用 `t0.durationTo(t1)` 得到 `Io.Duration`。

```text
[时钟] 0.17 的 Io.Clock 枚举成员（实测，注意**没有** monotonic）
  .real
  .awake
  .boot
  .cpu_process
  .cpu_thread
  ⚠️ 网上常见的 `std.time.Timer` / `.monotonic` 在 0.17 都不存在了。
  正确写法：const t0 = std.Io.Clock.now(.awake, io); … t0.durationTo(t1)
  .awake    = 单调、不含睡眠时间（macOS 上是 CLOCK_UPTIME_RAW）
  .boot     = 单调、含睡眠时间（macOS 上是 CLOCK_MONOTONIC_RAW）
  .real     = 挂钟时间，会被 NTP 调整
  .awake 的分辨率 = 1 ns（Clock.resolution 返回 Io.Duration）
```

`Io.Duration` **只有 `.nanoseconds` 一个字段，没有任何格式化方法**——所以 `nsToMs` 得手写除法：

```zig
// examples/24_minigrep/src/main.zig 第 1290-1292 行
fn nsToMs(ns: i96) f64 {
    return @as(f64, @floatFromInt(ns)) / 1e6;
}
```

在真实统计里，四个数比"耗时"本身更有用：

```text
[统计] 在 65424 字节 / 1593 行的单文件上跑
  模式 service=svc[0-6]（26 条指令）
  文件数     = 1
  命中行数   = 1593
  扫描字节   = 65424（63.9 KiB）
  回溯总步数 = 85878
  耗时       = 7429354 ns（7.43 ms）
  吞吐       = 8.4 MiB/s
  每字节步数 = 1.31
  ⚠️ 这是 Debug 构建（zig build run 默认 -O Debug），数字只用于看**比例**
  ⚠️ nsToMs 里手写了除法：Io.Duration 只有 .nanoseconds，没有 fmt 方法
     （20 章实测：非穷尽枚举的运行期值用 {t} 打印会 panic）
```

**"每字节步数 = 1.31"** 是这一节最值得记住的数字。它意味着这个模式**基本没有回溯**——每读一个字节平均只走 1.31 条指令，因为 `service=svc[0-6]` 在这个语料上几乎总是直接匹配成功。对比 24.6 里 `(a+)+b` 的每字节步数是天文数字，就知道"回溯引擎在正常输入上其实很快，坏输入上才会爆"。

`回溯总步数 = 85878` 也是**完全确定的**（同一台机器连跑两遍逐字节相同），只有 `耗时` / `吞吐` 会变。所以要回归测试引擎性能，应该断言步数而不是耗时。

> ⚠️ 这里踩到一个 `bufPrint` 的坑：`while (off < big.len)` + `bufPrint(big[off..], …)` 会在**尾巴不够放下一整行**时返回 `error.NoSpaceLeft`（不是截断、不是 panic），第一次跑 24.9 就炸在这儿。正确写法是留出最大行长余量 `while (off + max_line <= big.len)`。

---

## 24.10 完整 CLI 装配与综合演示

装配顺序刻意设计成**每一步都能单独测**，这是 24.11 能写 44 个测试的前提：

```text
装配顺序（每一步都能单独测，这是 24.11 能写 44 个测试的前提）：
  1. parseArgs(argv)          → Options（纯函数，不碰 io）
  2. regex.compile(gpa, pat)  → Program（一次编译，N 行复用）
  3. collectFiles(io, …)→ []FileEntry（每条都dupe，绝不信Entry.name）
  4. 逐文件：File.reader → LineReader.nextLine → regex.findAll
  5. writeHighlighted 输出，-c 时跳过
内存策略：一次性程序 ⇒ 全程用 init.arena，最后一个 free 都不需要。
```

第 2 步的"一次编译、N 行复用"值得强调：模式只在 `runGrep` 开头编译一次，之后**所有文件的所有行都跑同一个 `Program`**。对一个 10 万行的文件，这是 10 万次 `findAll` 共享 1 次 `compile`。

`-F` 的实现很省事——不另写一套比较循环，而是把模式编成一串 `char` 指令，复用同一条执行路径：

```zig
// examples/24_minigrep/src/main.zig 第 1447-1480 行
/// `-F` 模式：把整个模式编成一串 char 指令，**不解释任何元字符**。
/// 这是"固定字符串"最直接的实现——比另写一套比较循环更省，
/// 而且复用了同一条执行路径（连零宽、锚点那些边界都自动一致）。
fn compileLiteral(gpa: std.mem.Allocator, lit: []const u8) !regex.Program {
    // 用一个恒不匹配任何元字符的模式来构造：把每个字节都包进 [...] 转义是不必要的，
    // 直接手写指令数组更直白，也顺带展示 Program 就是"一条 []const Op"。
    if (lit.len + 1 > regex.max_ops) return error.TooManyOps;
    var ops: [regex.max_ops]regex.Op = undefined;
    for (lit, 0..) |c, i| {
        // 元字符也照原样当字面量：. 存成 char '.'，执行时只比字节
        ops[i] = .{ .char = c };
    }
    ops[lit.len] = .{ .accept = {} };
    const owned = try gpa.dupe(regex.Op, ops[0 .. lit.len + 1]);
    return .{
        .ops = owned,
        .group_count = 0,
        .anchored_start = false,
        .pattern_len = lit.len,
        .op_count = lit.len + 1,
    };
}
```

`runGrep` 里有两个必须写对的细节。

**第一个是 `-v` 的正确实现**——必须**照样先匹配一次**，只是把判定取反：

```zig
// examples/24_minigrep/src/main.zig 第 1382-1400 行
            // ⚠️⚠️ `-v` 的正确实现：**照样要先匹配一次**，只是把判定取反。
            //    早期版本写成"invert 时直接把 spans 置空"，于是
            //    `matched = spans.len == 0` 恒真 ⇒ **每一行都被打印**
            //    （实测 `minigrep -v ERROR app.log` 打出了全部 8 行，
            //    连含 ERROR 的第 3、7 行也打出来了）。
            //
            // 正确形态：始终算出 spans，再用 invert 决定"要不要这一行"，
            // 决定打印时 spans 传空数组（反向命中的行不该有高亮）。
            const found = try search.allSpans(gpa, &prog, line, ropt);
            defer gpa.free(found);

            const matched = if (opt.invert) found.len == 0 else found.len > 0;
            if (!matched) continue;

            any_hit = true;
            file_hits += 1;
            stats.matched_lines += 1;

            if (opt.count_only) continue; // -c：只记数不打印

            // -v 命中的行没有"命中片段"可染，所以传空 spans
            const spans: []const regex.Span = if (opt.invert) &.{} else found;
```

**第二个是输出通道必须统一**。`runGrep` 的所有输出都经由调用方给的 `Writer`，一律不用 `dprint`——混用会交错错乱（`dprint` 直写 stderr，`w` 走用户态缓冲，flush 时机不同，实测行号全打印了而行内容与 `\n` 却堆到了段尾）。

真跑一遍固定语料（`(ERROR|WARN)+`，正则 + 递归 + 高亮）：

```text
[综合演示 1] 在 src/corpus 上搜 (ERROR|WARN)+（正则 + 递归 + 高亮）
  模式编译成 25 条指令；下面按 --color=never 输出（可断言）
  收集到 3 个文件
    src/corpus/app.log:2: 2026-03-01 <ESC>[1;31mWARN<ESC>[0m  service=auth  msg="retry limit" user=bob tries=3
    src/corpus/app.log:3: 2026-03-01 <ESC>[1;31mERROR<ESC>[0m service=billing msg="payment timeout" order=A-1001
    src/corpus/app.log:7: 2026-03-02 <ESC>[1;31mERROR<ESC>[0m service=search msg="query timeout" ms=30000
    src/corpus/app.log:8: 2026-03-03 <ESC>[1;31mWARN<ESC>[0m  service=storage msg="disk usage 91%" mount=/var/lib
  共 4 处命中（上面 <ESC> 就是 ANSI 转义序列的起始字节 0x1b）
  ⚠️ 上面**故意**开了色，好让你看到 ESC 真的进了字节流。
     真grep 默认按 isTty 自动判断，重定向到文件时会自动关色（24.7）。
```

输出用 `<ESC>` 这个**可见记号**代替真的 ESC 字节，这是刻意的：`dprintHighlighted` 把 0x1b 渲染成 `<ESC>` 文本。因为不可见控制字符抄进 Markdown 后"看起来一样、字节不同"，没法逐字节校对。真正的字节证据在 24.7 的十六进制那一行。

注意文件顺序是**排过序的**（`std.mem.sort`）——因为 `Walker` 的返回顺序在文档里明确写着 "The order of returned file system entries is undefined"。不排序的话输出会随文件系统变化。

`app.conf` 和 `README.md` 都在语料里但没命中，`app.log` 命中 4 行——这正是"递归收齐 3 个文件、逐个搜索、各自报告"的效果。

`s*rvice=[a-z]+` 演示 `-i` 的真实效果：

```text
[综合演示 2] s*rvice=[a-z]+ —— 零次 s 也能匹配（s* 是幂等的）
  20 条指令；演示 -i（大小写不敏感）与 -v（反向）
    默认    : se<ESC>[1;31mrvice=auth<ESC>[0m SERVICE=billing nothing here
    -i      : se<ESC>[1;31mrvice=auth<ESC>[0m SE<ESC>[1;31mRVICE=billing<ESC>[0m nothing here
    -i 命中 2 段（默认 1 段）⇒ 走的是 charEq / Class.matches，不改写模式
    -v 场景 : "msg="no service field here"" 有 0 处命中 ⇒ -v 下这行会被打印（且无高亮）
```

这里有两个观察点：

1. **默认情况下 `SERVICE=billing` 没被匹配**——因为 `[a-z]+` 不含大写。开了 `-i` 之后**两段都命中**（1 段 → 2 段）。`-i` 的实现是**不改写模式**，而是在 `Class.matches` / `charEq` 里多做一次大小写比较。
2. **`s*` 匹配了零个 `s`**——命中从 `se` 的第 3 个字节开始（`se` 没被染色）。这是 `*` 能匹配零次的直接体现。

`-F` 固定字符串：元字符不当正则。

```text
[综合演示 3] -F 固定字符串：元字符不当正则
  -F 编出 13 条指令（每字节一条 char）；正则版也是 26 条
  -F  "service=svc3" 在 "a.service=svc3 b service=svc3x" 上：
a.<ESC>[1;31mservice=svc3<ESC>[0m b <ESC>[1;31mservice=svc3<ESC>[0mx
  ⇒ 两个 svc3 都命中（-F 不看前后是不是有别的字符）
```

`-F` 编出 13 条（12 字节模式 + 1 条 accept），正则版 26 条——同一个模式串，`-F` 省了一半指令，因为不需要处理量词和分支。

最后是完整装配跑通（`parseArgs` → `runGrep` 用的是同一套代码，输出进内存缓冲）：

```text
[综合演示 4] 命令行装配跑通（parseArgs → runGrep 用的同一套代码）
  argv=-c -r  退出码=0 输出 4 行
      │ src/corpus/app.conf:0
      │ src/corpus/README.md:0
      │ src/corpus/app.log:4
      │ …（共 4 行）
  argv=-n -r  退出码=0 输出 9 行
      │ src/corpus/app.log:1: 2026-03-01 INFO  service=auth  msg="login ok" user=alice
      │ src/corpus/app.log:2: 2026-03-01 WARN  service=auth  msg="retry limit" user=bob tries=3
      │ src/corpus/app.log:3: 2026-03-01 ERROR service=billing msg="payment timeout" order=A-1001
      │ …（共 9 行）
  argv=-i -r  退出码=0 输出 3 行
      │ src/corpus/app.log:3: 2026-03-01 ERROR service=billing msg="payment timeout" order=A-1001
      │ src/corpus/app.log:7: 2026-03-02 ERROR service=search msg="query timeout" ms=30000
      │ minigrep: 3 个文件，命中 2 行，扫描 833 字节
  argv=-F -r  退出码=0 输出 4 行
      │ src/corpus/app.conf:4: timeout_ms = 30000
      │ src/corpus/app.log:3: 2026-03-01 ERROR service=billing msg="payment timeout" order=A-1001
      │ src/corpus/app.log:7: 2026-03-02 ERROR service=search msg="query timeout" ms=30000
      │ …（共 4 行）
  ⚠️ runGrep 的返回值就是进程退出码：无命中退 1、有命中退 0（与真 grep 一致）
  ⚠️ 输出缓冲用的是 Writer.fixed（**内存**缓冲，不是 TTY）⇒ auto 模式必然关色
```

四个用例覆盖了 `-c` / `-n` / `-i` / `-F` 四条不同代码路径（`-c` 跳过打印只计数、`-i` 多一次大小写比较、`-F` 换编译路径）。注意每个 argv 都带 `-r`——不给 `-r` 时 `src/corpus` 是目录会被跳过，一个文件都搜不到。

**退出码语义**与真 grep 一致：有命中退 0、无命中退 1、用法错误退 2。所以 `minigrep x foo && echo found` 这种 shell 惯用法能工作。

---

## 24.11 测试：三层 44 个

本章的测试分三层，这是"可测试性设计"的最小示范：

| 层 | 文件 | 数量 | 测什么 | 特点 |
|---|---|---|---|---|
| 纯逻辑 | `src/regex.zig` | 22 | 正则引擎每个分支 + 10 种编译错误 + comptime 等价性 | 不碰盘，快且稳 |
| IO | `src/search.zig` | 9 | 流式逐行（超长行 / 末行无 `\n` / 空文件）+ 高亮格式化 | 用 fixed Writer 把"打印"变成"可断言的字符串" |
| 编排 | `src/main.zig` | 13 | 参数解析 + 遍历（`-v` 补集 / `-r` 单文件 / join 路径）+ stderr 模式 + 端到端 | tmpDir 落真文件跑全链路 |

```bash
cd examples/24_minigrep
zig build test        # 44 个全跑
```

```text
本章测试分三层，共 44 个（`zig build test` 全跑）：
  regex.zig  22 个：正则引擎每个分支 + 编译错误 + comptime 等价性
  search.zig  9 个：流式逐行（超长行/末行无\n/空文件）+ 高亮格式化
  main.zig   13 个：参数解析 + 遍历（-v 补集 / -r 单文件 / join 路径）+ stderr 模式 + 端到端 tmpDir
```

分层的理由和 20 章一致：**纯逻辑（正则）不碰盘所以快且稳**；IO 层用 `std.Io.Writer.fixed` 把"打印"变成"可断言的字符串"；端到端用 `std.testing.tmpDir` 落真文件跑全链路。每一层都有**它独有的 bug 类别**，缺一层就漏一类。

### 三个最值得学的测试

**第一个：`comptime 生成：与运行期编译逐指令相同`。** 这是全章最重要的测试——它保证 `compileComptime` **不是另一套实现**。如果哪天有人给 comptime 路径单独写了个简化版，这个测试立刻红：

```zig
// examples/24_minigrep/src/regex.zig 第 1017-1044 行（节选）
test "comptime 生成：与运行期编译逐指令相同（24.5 的核心断言）" {
    // 这一条是全章最重要的测试：它保证 comptime 版**不是另一套实现**。
    // 如果哪天有人给 comptime 路径单独写了个简化版，这个测试立刻红。
    const gpa = std.testing.allocator;
    inline for (.{
        "abc", "a*", "a+?", "a??", "^x", "[a-z]+", "(ab|cd)*", "s*rvice=[a-z]+",
        "(ERROR|WARN)+", "a(b|c)d", "\\.", "[^a-c]",
    }) |pat| {
        const ct = comptime compileComptime(pat);
        const rt = try compile(gpa, pat);
        defer rt.deinit(gpa);
        try std.testing.expectEqual(rt.op_count, ct.op_count);
        try std.testing.expectEqual(ct.ops.len, rt.ops.len);
        for (ct.ops, rt.ops) |a, b| {
            try std.testing.expect(opsEqual(a, b));
        }
        try std.testing.expectEqual(ct.group_count, rt.group_count);
        try std.testing.expectEqual(ct.anchored_start, rt.anchored_start);
        try std.testing.expectEqual(ct.pattern_len, rt.pattern_len);
    }
}
```

`inline for` 是必须的（12 个模式逐个 comptime 求值）。比较用 `opsEqual` 逐字段比而不是 `expectEqualSlices(Op, …)`——原因见 24.5 的"踩坑二"。

**第二个：`max_steps 护栏：灾难性回溯被挡住而不是把机器卡死`。** 它同时断言了错误**和步数**：

```zig
// examples/24_minigrep/src/regex.zig 第 1069-1082 行
test "max_steps 护栏：灾难性回溯被挡住而不是把机器卡死（24.6）" {
    const gpa = std.testing.allocator;
    // (a+)+b 撞上 "aaaa...a"（无 b）是教科书级的灾难性回溯输入
    const evil = try compile(gpa, "(a+)+b");
    defer evil.deinit(gpa);
    var text: [24]u8 = undefined;
    @memset(&text, 'a');

    var stats: Stats = .{};
    const res = findWithStats(gpa, &evil, &text, .{ .max_steps = 50_000 }, &stats);
    try std.testing.expectError(error.TooManySteps, res);
    // 步数确实被打到预算上限附近（而不是碰巧很快）
    try std.testing.expect(stats.steps > 40_000);
}
```

第二个断言（`steps > 40_000`）是精髓：只断言"报了 TooManySteps"的话，一个**永远失败**的 pattern 也能过（比如某个 bug 让它第一步就报错）。断言步数接近预算，才能证明它**真的跑了几万步才被拦下**。

**第三个：`-v 反向匹配：命中集合必须是正向的补集`。** 这条测试是为一个真实 bug 写的：

```zig
// examples/24_minigrep/src/main.zig 第 2021-2055 行（节选）
test "24.1 -v 反向匹配：命中集合必须是正向的补集（不是全都要）" {
    // ... tmpDir 里写 "keep\nERROR here\nkeep2\nWARN there\n" ...
    while (try lr.nextLine(a)) |line| {
        total += 1;
        const spans = try search.allSpans(a, &prog, line, .{});
        defer a.free(spans);
        // ⚠️ 关键：无论正向反向，**都要真的匹配一次**。
        // 反向的实现错误正是"不匹配、直接置空 spans"，那样 inv 会 == total。
        if (spans.len > 0) fwd += 1 else inv += 1;
    }
    try std.testing.expectEqual(@as(usize, 4), total);
    try std.testing.expectEqual(@as(usize, 2), fwd);
    try std.testing.expectEqual(@as(usize, 2), inv);
    try std.testing.expectEqual(total, fwd + inv);
}
```

最后那行 `expectEqual(total, fwd + inv)` 是这条测试的灵魂：**正向 + 反向 == 总行数**。这个恒等式一旦破坏，就说明 `-v` 的实现漏了匹配或者重复计数。

### 其余测试覆盖的分支

`regex.zig` 的 22 个测试逐条对应引擎分支：字面量最左匹配、`.` 不跨行、字符类区间/单点/取反、`[a-]` 非区间、`*` 贪婪与零宽、`*?` 非贪婪（入口+回边两处）、`+` 不匹配空串、`?` 可选与懒惰、量词只作用于紧邻 atom、`|` 左右分支、分组改优先级边界、`^`/`$` 锚点、`(ab)+` 量词作用于分组、`findAll` 全不重叠匹配、`findAll` 零宽不死循环、`ignore_case` 走 `charEq`/`Class.matches`、10 种编译错误、转义（`\n` `\xHH` `\.` 元字符自转义）、指令膨胀比、comptime 等价、comptime 程序真能跑、回溯步数基线、`max_steps` 护栏。

`search.zig` 的 9 个：4 字节缓冲读 6 字节的行、末行无 `\n` 也要算一行、单行超长报错、空文件与纯换行、命中段包转义、一行多处按顺序上色、关色时逐字节等于原文、坏区间（越界/重叠）被跳过、`allSpans` 委托给 `findAll`。

`main.zig` 的 13 个：六个开关 + 组合短选项、默认值与 `--` / 未知开关、借用语义（断言指针相同）、递归收集 + path 都 dupe、`-v` 补集、`-r` 传单个文件、`walk` 的 path 要 join、`LineReader` 三种边界、`writeHighlighted` 三条路径、`compileLiteral` 把元字符当字节、端到端 tmpDir、stderr 必须用 `writerStreaming`。

`zig build run` 会当场复算几个关键断言（正式断言在文件的 test 块里）：

```text
[为什么三层都有必要] 纯逻辑（正则）不碰盘所以快且稳；
IO（逐行、高亮）用 fixed Writer 把"打印"变成"可断言的字符串"；
端到端用 std.testing.tmpDir 落真文件跑全链路。

[当场验证几个关键断言]（正式断言在文件末尾的 test 块里）
  parseArgs("-inrF -v pat d1 d2") → ignore=true invert=true count=false no=true rec=true fixed=true 位置参数 3 个
  parseArgs("-q") → UnknownOption
  findAll("svc[0-9]", "a svc1 b svc7 c") → 2 段： [2,6) [9,13)
  (a+)+b 撞 22 个 a，预算 50k → TooManySteps（第 50001 步被打断）
  comptime vs 运行期 ERROR|WARN     指令数 22/22  逐条相同=true
  comptime vs 运行期 a+?            指令数 5/5  逐条相同=true
```

---

## 24.12 build.zig 逐行讲解

本章的 `build.zig` 只有 33 行，但它覆盖了 0.17 构建系统里**所有会踩坑的 API**。完整迁移对照见 [16 章](16-build.md)。

```zig
// examples/24_minigrep/build.zig 第 1-33 行
const std = @import("std");

// 24 实战 minigrep 的构建：exe + run（透传参数）+ test
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "minigrep",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs(); // 0.17：b.args 已移除；zig build run -- <参数> 照旧可用
    const run_step = b.step("run", "Run minigrep");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(unit_tests).step);
}
```

### 逐个 API 的实测形状

下面每一行都是**在 0.17.0 上实测**的（用 `@hasDecl` / `@typeInfo` 在 build.zig 里做编译期断言——API 一变，这个文件就编译不过）：

```text
=== 存在 ===
  Build.standardTargetOptions    = true
  Build.standardOptimizeOption   = true
  Build.addExecutable            = true
  Build.addTest                  = true
  Build.installArtifact          = true
  Build.getInstallStep           = true
  Build.addRunArtifact           = true
  Build.step                     = true
  Build.createModule             = true
  Build.addModule                = true
  Build.addLibrary               = true
=== 已移除 ===
  Build.addStaticLibrary             = false
  Build.addSharedLibrary             = false
  Build.standardReleaseOptions       = false
  Build.standardTargetOptionsReleaseFast = false
  Build.args                         = false
```

**`b.createModule` vs `b.addModule`**：前者创建**私有**模块（只给本包用），后者创建**公开**模块并注册进包的模块集合（其他依赖本包的包能 `addModule(name)` 引用它）。返回都是 `*Build.Module`。本项目只需要前者。

**`addExecutable` 的 options 字段**（实测）：

```text
=== ExecutableOptions 字段 ===
  name
  root_module
  version
  linkage
  max_rss
  use_llvm
  use_lld
  zig_lib_dir
  win32_manifest
```

注意 0.17 用的是 **`root_module`**（一个 `*Module`），0.16 及以前是 `root_source_file` + 一堆散装字段直接挂在 options 上。

**`addTest` 的 options 字段**：

```text
=== TestOptions 字段 ===
  name
  root_module
  max_rss
  filters
  test_runner
  use_llvm
  use_lld
  zig_lib_dir
  emit_object
```

`filters` 就是 `zig build test -- <filter>` 能传的东西。`emit_object = true` 时只发射 `.o` 不链接（配合自定义 `test_runner` 用）。

**`addLibrary` 是三合一**：

```text
=== LibraryOptions 字段（addLibrary 三合一）===
  linkage
  name
  root_module
  version
  max_rss
  use_llvm
  use_lld
  zig_lib_dir
  win32_manifest
  win32_module_definition
```

`addStaticLibrary` / `addSharedLibrary` / `addDynamicLibrary` **全部被移除**，合并成一个 `addLibrary(.{ .linkage = .static | .dynamic })`。写 `_ = std.Build.addStaticLibrary` 会编译报错：

```text
build.zig:79:18: error: root source file struct 'Build' has no member named 'addStaticLibrary'
    _ = std.Build.addStaticLibrary;
        ~~~~~^^^^^^^^^^^^^^^^^^^
note: struct declared here
const Build = @This();
```

`standardReleaseOptions()` 也一起移除了（它返回一组预置的 step，0.17 里改为自己用 `addExecutable` + `optimize` 组合）。

**函数签名**（0.17 的 `Type.Fn` 是 struct，用 `param_types` 而不是 `.params`）：

```text
=== 签名（Type.Fn 是 struct，用 param_types）===
    Build.addModule       : is_generic=false 参数数=3 返回类型=*Build.Module
    Build.addTest         : is_generic=false 参数数=2 返回类型=*Build.Step.Compile
    Build.addExecutable   : is_generic=false 参数数=2 返回类型=*Build.Step.Compile
    Build.step            : is_generic=false 参数数=3 返回类型=*Build.Step
    Build.installArtifact : is_generic=false 参数数=2 返回类型=void
```

`installArtifact` 返回 **`void`**（不是 step），所以调完就没了，别试图拿它的返回值。`b.step(...)` 返回 `*Step`，**必须用**——不能当语句丢弃：

```text
build.zig:83:11: error: value of type '*Build.Step' ignored
    b.step("discarded", "返回值被丢弃");
    ~~~~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~~~~
note: all non-void values must be used
note: to discard the value, assign it to '_'
```

这是 Zig 的通用规则（所有返回非 void 的调用都必须消费其结果），但 `b.step` 特别容易踩，因为直觉上"我只是注册一个 step"感觉像语句。

**`b.args` 已被移除**，所以 run step 透传参数必须用 `run_cmd.addPassthruArgs()`：

```text
=== Step.Run 方法 ===
  Step.Run.addArgs            = true
  Step.Run.addPassthruArgs    = true
  Step.Run.addArtifactArg     = true
  Step.Run.addFileArg         = true
```

漏掉 `addPassthruArgs()` 的后果不是报错，而是 **`zig build run -- -i -r pattern` 静默丢掉所有参数**——最难查的一类 bug（16 章专门讲过）。

### `build.zig.zon` 的指纹

```zig
// examples/24_minigrep/build.zig.zon 第 1-11 行
.{
    .name = .minigrep,
    .version = "0.1.0",
    .fingerprint = 0x2f358579e884428a,
    .minimum_zig_version = "0.16.0",
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
    },
}
```

`.fingerprint` 是包的唯一标识（0.14 起从包名派生）。`zig build` 报错说 fingerprint 不匹配时，`zig build --fetch` 或删掉对应的 `.zig-cache` 里的 hash 目录即可。`.minimum_zig_version` 这里写的 0.16.0 是**下限**；实际本章所有 API 都要求 0.17，所以照抄这份 zon 到新项目时要改成 `"0.17.0"`。

---

## 24.13 坑位清单

以下每一条都是本章**实际踩到或实测确认**的 0.17 行为，按"报错难度"从易到难排列。

### 编译期就报错的（改一眼就好）

1. **`std.Io.Dir.cwd().handle` 是 `AT_FDCWD == -2`（伪句柄）**，对它调 `iterate` / `walk` 会 **panic** `programmer bug caused syscall error: BADF`，**不是**返回错误。必须先 `openDir` 拿到真句柄——而且 `.iterate = true` 必须在**打开时**给（Windows 上不开就 AccessDenied）。
   另一个平台坑：**`std.posix.AT.FDCWD` 只在 POSIX 目标存在**，Windows 上引用它编译错 `struct 'c.AT__struct_719' has no member named 'FDCWD'`；且 Windows 的 `Dir.handle` 是 `*anyopaque` 不透明句柄，打印 fd 没意义——demo24.2 的对账打印只能 `comptime` 分平台。

2. **`Dir.Entry.name` 跨 `next()` 失效**（文档原话 "All `Entry.name` are invalidated with the next call to `read` or `next`"）。要存就 `dupe`。小目录下凑巧不炸，文件一多就现原形——本章用 60 个长文件名让 2048 字节的 `reader_buffer` 必然 refill，实测 `raw[0]` 已被覆写而 `owned[0]` 完好。

3. **`std.Io.File.cwd()` 不存在**（实测 `no member named 'cwd'`）。只有 `std.Io.Dir.cwd()`。

4. **`File.readAll` / `File.writeAll` 都不存在**（实测 `@hasDecl = false`）。一次性读完用 `Dir.readFileAlloc(io, path, gpa, .limited(n))`，注意第 4 参是 `std.Io.Limit` **枚举**不是 `usize`。

5. **`std.Build.addStaticLibrary` / `addSharedLibrary` / `standardReleaseOptions` 已移除**，`addLibrary(.{ .linkage = … })` 三合一。照抄 0.16 的 build.zig 编译不过。

6. **`b.args` 已移除** → run step 必须 `run_cmd.addPassthruArgs()`。漏掉不报错，只是**静默丢掉所有命令行参数**。

7. **`b.step(...)` 的返回值不能当语句丢弃**（`error: value of type '*Build.Step' ignored`）。所有返回非 void 的调用都必须消费结果。

8. **`std.Io.Clock` 没有 `.monotonic`**，枚举是 `real` / `awake` / `boot` / `cpu_process` / `cpu_thread`。正确写法 `std.Io.Clock.now(.awake, io)` + `t0.durationTo(t1)`。`std.time.Timer` 也没了。`Io.Duration` 只有 `.nanoseconds` 一个字段，**没有任何格式化方法**。

9. **格式串里的字面花括号必须转义**：`{}` 会被当格式占位符。想打印字面 `{` / `}` / `{s}` / `{t}` 写成 `{{` / `}}` / `{{s}}` / `{{t}}`。不转义实测报 `error: too few arguments`（本章在 `readStreaming(io, &.{buf})` 和 `{n,m}` 两处都踩到）。

10. **切片必须显式给格式说明符**。`if (tty) "开" else "关"` 的类型是 `[]const u8`，用 `{}` 报 `cannot format slice without a specifier (i.e. {s}, {x}, {b64}, or {any})`。

11. **结构体字面量不能出现在表达式位置**：`std.Io.Dir.OpenOptions{}.iterate` 编译不过（`error: expected ',' after initializer`）。必须先 `const x: T = .{};` 再取字段。

12. **`@typeInfo` 的三条平行数组必须用 `inline for` 遍历**。`field_types` 是 `[]const type`——类型不是运行期值，普通 `for` 报 `values of type 'type' must be comptime-known, but index value is runtime-known`。

13. **反射一个函数要写 `@TypeOf(some_fn)`**，不能写 `@TypeOf(@min)`（编译期内建，`@TypeOf` 只接受"值"，实测 `expected parameter list, found ')'`），也不能写 `@typeInfo(std.Build.addModule)`（实测 `expected type 'type', found 'fn (...)'`）。

14. **`comptime var` 的地址不能返回**（实测 `runtime value contains reference to comptime var`）。它是编译器工作区里的临时量，不是程序静态数据。要返回就拷进一个 `const` 数组再切片（注意 `scratch[0..n]` 是 `*[n]Op`，要 `.deref`）。

15. **`const slot = try p.put(.{ .jump = slot })` 编译不过**（`use of undeclared identifier 'slot'`）——变量不在自己的初始化器里。要先写占位值 0，之后回填。

16. **`comptime` 块里 `std.debug.print` 不能用**（会一路 `unable to resolve comptime value` 一路报到 `Io.swapCancelProtection`）。而且 `comptime { }` 里的 `inline for` 报 `redundant inline keyword`。

### 运行时才暴露的（最难查）

17. **`File.writer(io, buf)` 默认是 positional 模式（写前 seek），与 `std.debug.print` 混用会覆盖输出。** 本章最隐蔽的一条：`minigrep 2> out.txt` 时 out.txt 里只剩最后一行，前面的内容全被 positional writer seek 回去覆盖了。**只有 `2> file` 才暴露，管道下完全正常**（管道不可 seek，positional 退化成追加）。修法：stderr 一律用 `writerStreaming`。

18. **两层错误联合（error union 套 optional）不能直接 `switch`**（实测 `switch on error union type 'error{OutOfMemory,TooManySteps}!?Span'` + `consider using 'try', 'catch', or 'if'`）。先用 `catch` 把外层摊平，再对纯 optional 做 `switch`。本章在 24.6 和 24.9 各踩一次。

19. **零长 Reader 缓冲 + `fillMore` 会 assert**：`f.reader(io, &.{})` 看起来最省内存，但 `fillMore` → `rebase(r, r.end - r.seek + 1)` 至少要 1 字节，实测 panic `Io.Reader.defaultRebase: assert(r.buffer.len - r.seek >= capacity) failed`。20 章用 `&.{}` 配的是 `readSliceShort`（不 `fillMore`），所以那里没事。

20. **`bufPrint` 在剩余空间不够放下一整行时返回 `error.NoSpaceLeft`**（不是截断、不是 panic）。`while (off < buf.len)` + `bufPrint(buf[off..], …)` 必然踩到。要留最大行长余量。

21. **格式串里的 `\x1b` 会被当成真的 ESC 字节写进输出**，不是字面 `\x1b` 四个字符。想输出可见形式必须自己渲染成 `<ESC>` 文本——这也是本章所有文本块都能"逐字节校对"的前提。

22. **`Walker.Entry.path` 是相对于 walker 根的**，不是相对 cwd。直接拿去 `cwd.statFile` 会 FileNotFound，而 `catch` 之后 `size` **静默变成 0**（不报错）。必须 `join(root, e.path)`。

23. **`-r` 不等于"只接受目录"**。真 grep 里 `grep -r pattern file.txt` 完全合法。把 `-r` 分支写成"只 openDir + walk"会让 `minigrep -r pattern file.txt` 报 `NotDir` 且搜不到任何文件。正确顺序：access 判存在 → openDir 试是不是目录 → 是文件就当单文件收。

24. **`-v` 必须照样先匹配一次**，只是把判定取反。写成"invert 时直接把 spans 置空"会让 `matched = spans.len == 0` 恒真，**每一行都被打印**（实测打出了全部 8 行，连含 ERROR 的行也在内）。

25. **`expectEqualSlices(Op, …)` 不能用来比指令**。`Op` 的 `class` 变体里 `Class.ranges` 是定长数组，`len` 之后的槽位是 `undefined`，整条做 `==` / `meta.eql` 就是在比内存垃圾。必须逐字段比。

26. **`Dir.deleteTree` 的错误 union 不能 `try`**。`try cwd.deleteTree(io, "x") catch {}` 报 `expected error union type, found 'void'`——`try` 已经解包了一层，后面不能再 `catch`。正确写法是 `cwd.deleteTree(io, "x") catch {}`。

27. **`union(enum)` 的 `tag_type` 打不出类型名**。它是编译器内部的匿名枚举，`@typeName` 会**原样打印产生它的那条表达式**（`@typeInfo(regex.Op).@"union".tag_type.?`），跟手写的同名 enum 比较结果是 `false`。想看 tag 字段只能走 `@typeInfo(tag_t).@"enum".field_names`。

28. **`Union.FieldAttributes` 与 `Struct.FieldAttributes` 是两个不同类型**。前者只有 `align`，后者还有 `comptime` 和 `default_value_ptr`。想用 `default_value_ptr` 会报 `no field named 'default_value_ptr'`。

29. **同名的局部变量不能 `inline for` 的捕获**（`error: local variable 'i' shadows capture from outer scope`）。演示代码里循环变量要起不同的名字（`i` 与 `k`）。

30. **混用 `dprint`（直写 stderr）与缓冲 `Writer` 会输出乱序**。`dprint` 立即写、`w` 攒在用户态缓冲，两者 flush 时机不同。本章实测过三种错位：整段表格消失（还在 stdout 缓冲里没 flush）、反汇编堆到节末、行号全打印而行内容与 `\n` 堆到段尾。**一个函数里的输出要么全走 `w`，要么全走 `dprint`，不能混。**

31. **`@typeInfo(T)` 对 `T.@"enum"` 不再有 `is_enum` / `is_exhaustive`**，合并成 `mode: Mode`（`Mode` 是 `enum { exhaustive, nonexhaustive }`）。照抄 `ti.@"enum".is_exhaustive` 报 `no field named 'is_exhaustive'`。

32. **⚠️ `use of undeclared identifier` 是 AstGen 层面的错，未选中的 comptime 分支也逃不过**。把平台分叉写成 `if (comptime windows) ... else ... handleInt(h) ...` 时，如果 `handleInt` 整个函数没定义，编译器照样报 `undeclared identifier`——标识符解析是全模块词法的，发生在 comptime 求值之前（本地实测）。所以平台分叉里引用的辅助函数必须**真实定义出来**，不能只存在于"被选中的那个平台"里。

---

## 扩展练习

1. **反向引用**（`\1`）：需要在指令层加捕获组 + 回溯时记录组位置。想清楚为什么"回溯引擎天然支持捕获，而 NFA 不支持"。
2. **非贪婪的 `-F`**：给 `compileLiteral` 加一个"最短匹配"模式（找到第一个就停），对比两种策略的输出差异。
3. **多线程**：把 `runGrep` 的文件循环改成 19 章的"原子游标抢任务"模式（`std.atomic.Value(usize).fetchAdd`），注意每个线程要各自 `File.reader` 与 `LineReader`，结果收集要上锁。
4. **`--include` glob**：用 `std.mem.indexOf` 或手写 `*`/`?` 匹配过滤文件名（复用 24.4 的引擎思路）。
5. **二进制文件跳过**：前 1 KB 出现 `\x00` 即判二进制并跳过（真 grep 的行为）。
6. **`{n,m}` 重复计数**：在 `parseRepeat` 里加一个数字解析分支，展开成 `X` 重复 n 次 + 量词。注意指令膨胀（`a{1,1000}` 会爆 `max_ops`）。
7. **预编译 DFA**：把回溯引擎的指令数组编译成 DFA 转移表，对比"编译一次、扫描 O(n)"与"编译一次、匹配 O(2^n)"的实测差距（24.6 已经给出回溯侧的数据）。

---

上一章：[23 调试与工具](23-debugging.md) · 下一章：[25 二进制数据与内存布局](25-binary.md)

