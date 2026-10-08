# 22 · 进程

> 对应示例：`examples/22_process/main.zig`（779 行，15 个小节，15 个 test）
>
> 本章把 0.17.0 上"进程相关的每一个 API"逐个实测一遍：`std.process.Init` 的字段、
> 命令行参数、环境变量、`std.process.run` / `spawn` / `Child.kill`、退出码、
> 以及被搬进 `std.Io` 的时间与睡眠。
>
> **本章有五条结论会推翻你从旧书/旧代码里搬来的写法**：
>
> 1. **`std.process` 里没有任何全局状态**。`argsAlloc` / `args` / `getEnvMap` /
>    `getEnvVarOwned` 全部**已移除**（实测 `has no member named 'argsAlloc'`），
>    参数走 `init.minimal.args`，环境走 `init.environ_map`。
> 2. **`init.minimal.args` 只有一个字段 `.vector`**，没有 `.len`、没有 `.argv`、没有 `.next()`。
>    必须 `iterate()` / `iterateAllocator()` 拿迭代器。
> 3. **`std.process.exit` 不收 `io`**（实测 `expected 1 argument(s), found 2`）。
>    这一点和本章其它所有 API 都反着来。
> 4. **`std.time` 在 0.17 只剩单位换算常量**——`Timer` / `Instant` / `nanoTimestamp` /
>    `now` / `sleep` 全部不存在。计时走 `std.Io.Clock.now(.awake, io)`。
> 5. **往子进程 stdin 写完必须 `close` 之后把字段置 `null`**，否则 `wait` 内部
>    二次 close 触发 `unreachable`（实测 panic，含完整栈）。
>
> 另外两条是本章**实测撞到的新坑**，旧文档里没有：
> `std.Io.Duration` 有 `format` 但**没有** `formatNumber`（`{d}` 打印它编译失败），
> 以及 `std.Io.Limit` 是**非穷尽 enum**（`@tagName` 直接 panic）。

---

## 22.1 为什么"进程"在 Zig 里没有全局状态

Zig 里读参数、读环境、读时间、拿分配器、拿事件循环，**全部**从 `main` 的第一个参数来。
这不是风格偏好，是 0.16 起的硬设计：`std.process.Init` 是一个普通结构体，编译器
不知道它的值从哪来，所以任何函数想用这些东西，都必须由调用方显式传参。

```zig
// examples/22_process/main.zig 第 39-57 行
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;
    const arena = init.arena.allocator();

    // ═══ 22.1 没有全局状态：进程的一切都是 main 的第一个参数 ═══
    begin("22.1 进程：没有全局状态，一切从main 的参数来");
    std.debug.print("main 的参数类型 = {s}（0.16 起的显式依赖注入）\n", .{@typeName(std.process.Init)});
    const IT = @typeInfo(std.process.Init).@"struct";
    inline for (IT.field_names, IT.field_types) |fname, ftype| {
        std.debug.print("  .{s:<12}: {s}\n", .{ fname[0..fname.len], @typeName(ftype) });
    }
    const MT = @typeInfo(std.process.Init.Minimal).@"struct";
    inline for (MT.field_names, MT.field_types) |fname, ftype| {
        std.debug.print("  minimal.{s:<8}: {s}\n", .{ fname[0..fname.len], @typeName(ftype) });
    }
    std.debug.print("对比：C 的 main(argc, argv) 是全局；Rust 的 std::env::args() 是全局\n", .{});
    std.debug.print("⇒ Zig 里想读参数/环境/时间，**必须**从 init 拿，编译器强制你把它传下去\n", .{});
    end("22.1");
```

运行输出（`examples/22_process/main.zig`）：

```text
==== 22.1 进程：没有全局状态，一切从main 的参数来 开始 ====
main 的参数类型 = process.Init（0.16 起的显式依赖注入）
  .minimal     : process.Init.Minimal
  .arena       : *heap.ArenaAllocator
  .gpa         : mem.Allocator
  .io          : Io
  .environ_map : *process.Environ.Map
  .preopens    : process.Preopens
  minimal.environ : process.Environ
  minimal.args    : process.Args
对比：C 的 main(argc, argv) 是全局；Rust 的 std::env::args() 是全局
⇒ Zig 里想读参数/环境/时间，**必须**从 init 拿，编译器强制你把它传下去
==== 22.1 结束 ====
```

六个字段，逐个对照：

| 字段 | 类型 | 用途 | 备注 |
|---|---|---|---|
| `.minimal` | `process.Init.Minimal` | 参数 + 原始环境块 | 想要更少依赖就接 `Init.Minimal` 当 main 参数 |
| `.arena` | `*heap.ArenaAllocator` | 进程全生命周期的分配 | 退出时自动释放，**线程安全** |
| `.gpa` | `mem.Allocator` | 临时堆分配 | Debug 下带泄漏检测，**线程安全** |
| `.io` | `Io` | 事件循环 / 计时 / 文件 / 子进程 | 几乎所有系统 API 的第一个参数 |
| `.environ_map` | `*process.Environ.Map` | 已解析好的环境变量 map | 启动时建好，**非线程安全** |
| `.preopens` | `process.Preopens` | 父进程递进来的文件 | 主要给 WASI 用 |

`Init.Minimal` 只有两个字段（`.environ` / `.args`）——**不含** io、gpa、arena。
本教程 15 章的测试 runner 的 `main` 就是 `Init.Minimal`（因为它要自己造 `io`），
写测试替身时这一点很关键。

**这条设计的回报在 22.10 和 22.14 会再出现两次**：因为 io 是参数，所以子进程能换成
`std.testing.io`；因为时钟挂在 io 上，所以时间也能被测试替换。15.11 讲的就是这个回报。

## 22.2 读命令行参数：`Args` 与 `Args.Iterator`

`init.minimal.args` 的类型是 `std.process.Args`。它是一个**极简**结构体——
实测只有一个字段 `.vector`，**没有** `.len`、**没有** `.argv`、**没有** `.next()`：

```zig
// examples/22_process/main.zig 第 60-91 行
    begin("22.2 命令行参数：Args 与 Args.Iterator");
    std.debug.print("init.minimal.args 的类型 = {s}\n", .{@typeName(@TypeOf(init.minimal.args))});
    std.debug.print("它只有一个字段 .vector，类型 = {s}\n", .{@typeName(@TypeOf(init.minimal.args.vector))});
    std.debug.print("⚠️ 没有 .len、没有 .argv、没有 .next()：实测报no field named 'len' in struct 'process.Args'\n", .{});
    std.debug.print("正确入口是 iterate() / iterateAllocator()，返回 {s}\n", .{@typeName(std.process.Args.Iterator)});
    // 迭代器本体：initAllocator 拿可分配版本（Windows 侧要转码缓冲）
    var it = try init.minimal.args.iterateAllocator(arena);
    defer it.deinit(); // Windows/WASI 上有内部缓冲；POSIX 上是空操作
    std.debug.print("迭代器类型 = {s}\n", .{@typeName(@TypeOf(it))});
    var argc: usize = 0;
    while (it.next()) |arg| {
        std.debug.print("  argv[{d}] = {s}\n", .{ argc, arg });
        argc += 1;
    }
    std.debug.print("共 {d} 个参数（argv[0] 是程序自己的路径）\n", .{argc});
    // skip()：不取值只跳过。解析子命令时省掉 argv[0] 就靠它
    var it2 = init.minimal.args.iterate();
    std.debug.print("skip() 第一次 = {}（跳掉 argv[0]）\n", .{it2.skip()});
    var rest: usize = 0;
    while (it2.next()) |_| rest += 1;
    std.debug.print("skip 之后还剩 {d} 个\n", .{rest});
    // toSlice：一次性拿全部（结果可能引用多个分配，所以**必须**传 arena 型分配器）
    const all = try init.minimal.args.toSlice(arena);
    std.debug.print("toSlice(arena) 的类型 = {s}，共 {d} 个（源码注释：must use arena-style allocator）\n", .{ @typeName(@TypeOf(all)), all.len });
    // 0.17 移除的旧 API，逐个实测确认
    std.debug.print("已移除：argsAlloc={} args={} getEnvMap={} getEnvVarOwned={}\n", .{
        @hasDecl(std.process, "argsAlloc"),
        @hasDecl(std.process, "args"),
        @hasDecl(std.process, "getEnvMap"),
        @hasDecl(std.process, "getEnvVarOwned"),
    });
    end("22.2");
```

运行输出（`examples/22_process/main.zig`，带两个参数 `alpha "带 空格"`）：

```text
==== 22.2 命令行参数：Args 与 Args.Iterator 开始 ====
init.minimal.args 的类型 = process.Args
它只有一个字段 .vector，类型 = []const [*:0]const u8
⚠️ 没有 .len、没有 .argv、没有 .next()：实测报no field named 'len' in struct 'process.Args'
正确入口是 iterate() / iterateAllocator()，返回 process.Args.Iterator
迭代器类型 = process.Args.Iterator
  argv[0] = ./build/22_process
  argv[1] = alpha
  argv[2] = 带 空格
共 3 个参数（argv[0] 是程序自己的路径）
skip() 第一次 = true（跳掉 argv[0]）
skip 之后还剩 2 个
toSlice(arena) 的类型 = []const [:0]const u8，共 3 个（源码注释：must use arena-style allocator）
已移除：argsAlloc=false args=false getEnvMap=false getEnvVarOwned=false
==== 22.2 结束 ====
```

`Args` 上的三个入口（本机实测签名）：

| 写法 | 返回 | 什么时候用 |
|---|---|---|
| `args.iterate()` | `Iterator`（**无错误**） | 非 Windows / 非无 libc 的 WASI |
| `args.iterateAllocator(gpa)` | `Iterator.InitError!Iterator` | **跨平台代码**（Windows 要转码缓冲） |
| `args.toSlice(arena)` | `ToSliceError![]const [:0]const u8` | 要把参数当数组用（转发给子进程、切片比较） |

`Iterator` 的方法只有五个：`init` / `initAllocator` / `next` / `skip` / `deinit`。
`next()` 返回 `?[:0]const u8`——**带哨兵**的可选值，`null` 表示读完。
`skip()` 返回 `bool`（`true` = 确实跳掉了一个，`false` = 已在末尾）。

⚠️ **`toSlice` 的分配器必须是 arena 型**。源码注释写得很直白
（`lib/std/process/Args.zig` 第 466-478 行）：

> Returned value may reference several allocations and may point into `a`. Thefore, an arena-style allocator must be used.

因为 Windows 上它要把所有参数**摊平**进一块新分配的连续内存，返回的每个切片都指向那块内存的**不同偏移**——你没法用一个普通分配器分别管理它们。本示例直接传 `init.arena.allocator()`。

### 已移除的旧 API（逐个实测）

| 旧写法 | 0.17 实测报错 |
|---|---|
| `std.process.argsAlloc(alloc)` | `error: root source file struct 'process' has no member named 'argsAlloc'` |
| `std.process.args` | `error: root source file struct 'process' has no member named 'args'` |
| `std.process.getEnvMap(alloc)` | `error: root source file struct 'process' has no member named 'getEnvMap'` |
| `std.process.getEnvVarOwned(alloc, k)` | `error: root source file struct 'process' has no member named 'getEnvVarOwned'` |
| `init.minimal.args.len` | `error: no field named 'len' in struct 'process.Args'` |
| `init.minimal.args.argv` | `error: no field named 'argv' in struct 'process.Args'` |
| `std.process.Child.run(.{})` | `error: root source file struct 'process.Child' has no member named 'run'` |

这七条本教程的最后一个 test 块（`0.17 的进程 API 存在性`，第 752-778 行）在运行时
用 `@hasDecl` 逐个断言，所以下次升级 Zig 时它会**第一个**告诉你哪儿变了。

## 22.3 Windows 的 UTF-16：为什么必须有迭代器

`Args.Vector` 是一个**平台相关的编译期 switch**（`Args.zig` 第 15-23 行）：

```zig
pub const Vector = switch (native_os) {
    .windows => []const u16, // WTF-16 encoded
    .wasi => switch (builtin.link_libc) {
        false => void,
        true => []const [*:0]const u8,
    },
    .freestanding, .other => void,
    else => []const [*:0]const u8,
};
```

**Windows 上根本没有"argv 数组"这个概念**。操作系统的 `GetCommandLineW()` 只给你
**一条**以 NUL 结尾的 WTF-16 字符串 `"prog" "a b" c\d tail"`。谁想拿到参数数组，
谁就得负责按规则把它切开——这就是 `Iterator.Windows` 存在的原因。

POSIX 相反：内核在 `execve` 时已经把 argv 准备好了，类型是 `[]const [*:0]const u8`，
**每个元素都自带 NUL**。切分工作内核做完了。

```zig
// examples/22_process/main.zig 第 94-117 行
    begin("22.3 Windows 的 UTF-16 与 Windows 命令行解析算法");
    std.debug.print("Args.Vector 是平台相关的编译期 switch：\n", .{});
    std.debug.print("  Windows → []const u16（WTF-16，整条命令行一个串）\n", .{});
    std.debug.print("  POSIX   → []const [*:0]const u8（内核已经切好的指针数组）\n", .{});
    std.debug.print("本机(.{s}) 实测 Args.Vector = {s}\n", .{ @tagName(builtin.os.tag), @typeName(@TypeOf(init.minimal.args.vector)) });
    std.debug.print("⇒ Windows 上**没有**现成的 argv 数组，只有一条命令行字符串\n", .{});
    std.debug.print("⇒ 必须有人按 MSVC 规则把它切开并把 WTF-16 转成 UTF-8，那就是 Iterator.Windows\n", .{});
    // 这一段在 macOS 上也能真跑：Iterator.Windows 是纯函数，给它一条 WTF-16-LE 就行
    // 这条命令行用了三种切分手法，一次看清 MSVC 规则：
    //   "a b"      引号分组 → 空格不再是分隔符，引号本身消失
    //   c\\"d"     **2 个**反斜杠 + 引号 → 偶数，反斜杠减半成1 个、引号当分组符（消失）
    //   \xF0\x9F\x97\xBF  一个 UTF-8 字符（🗿）原样穿过（Windows 内部其实是代理对 → WTF-8）
    const cmdline = "foo.exe \"a b\" c\\\\\"d\" \xF0\x9F\x97\xBF tail";
    const wide = try std.unicode.wtf8ToWtf16LeAllocZ(gpa, cmdline);
    defer gpa.free(wide);
    var wit = try std.process.Args.Iterator.Windows.init(gpa, wide);
    defer wit.deinit();
    std.debug.print("把这条命令行按 Windows 规则切开：\n  {s}\n", .{cmdline});
    var wi: usize = 0;
    while (wit.next()) |arg| : (wi += 1) {
        std.debug.print("  win_argv[{d}] = {s}\n", .{ wi, arg });
    }
    std.debug.print("⚠️ 结果编码是 **WTF-8**（不是 UTF-8）：落单的代理项能编进去，合法 UTF-8 编不出来\n", .{});
    end("22.3");
```

运行输出（`examples/22_process/main.zig`）：

```text
==== 22.3 Windows 的 UTF-16 与 Windows 命令行解析算法 开始 ====
Args.Vector 是平台相关的编译期 switch：
  Windows → []const u16（WTF-16，整条命令行一个串）
  POSIX   → []const [*:0]const u8（内核已经切好的指针数组）
本机(.macos) 实测 Args.Vector = []const [*:0]const u8
⇒ Windows 上**没有**现成的 argv 数组，只有一条命令行字符串
⇒ 必须有人按 MSVC 规则把它切开并把 WTF-16 转成 UTF-8，那就是 Iterator.Windows
把这条命令行按 Windows 规则切开：
  foo.exe "a b" c\\"d" 🗿 tail
  win_argv[0] = foo.exe
  win_argv[1] = a b
  win_argv[2] = c\d
  win_argv[3] = 🗿
  win_argv[4] = tail
⚠️ 结果编码是 **WTF-8**（不是 UTF-8）：落单的代理项能编进去，合法 UTF-8 编不出来
==== 22.3 结束 ====
```

这段在 macOS 上是**真跑**的：`Iterator.Windows` 是纯函数，你给它一条 WTF-16-LE 字节串
它就按 MSVC 规则切，不需要真的在 Windows 上。

### MSVC 切分规则（全部本机实测）

本示例第 484-520 行的 test 块用 8 组命令行覆盖了规则。实测结果：

| 命令行（Zig 源里的写法） | 切出的参数 |
|---|---|
| `foo.exe "abc" d e` | `foo.exe` `abc` `d` `e` |
| `foo.exe a\b d"e f"g h` | `foo.exe` `a\b` `de fg` `h` |
| `foo.exe a"b"" c d` | `foo.exe` `ab" c d` |
| `foo.exe a\"b c d`（1 个反斜杠 + 引号） | `foo.exe` `a"b` `c` `d` |
| `foo.exe a\\"b c" d e`（2 个反斜杠 + 引号） | `foo.exe` `a\b c` `d` `e` |
| `  aa  bb  ` | ``（空）`aa` `bb` |
| `\t\t` | ``（一个空参数，**不是零个**） |
| `aa\nbb` | `aa\nbb`（**换行不是分隔符**） |

三条最反直觉的：

1. **奇数个反斜杠 + 引号 = 转义引号**。`a\"b` 里的反斜杠被**吃掉**，引号**保留**在参数里，
   结果是 `a"b`。
2. **偶数个反斜杠 + 引号 = 引号当分组符**。`a\\"b c"` 里两个反斜杠减半成一个，
   引号**消失**（起分组作用），结果是 `a\b c`。
3. **换行（`\n`）和回车（`\r`）不是分隔符**，只有空格和 tab 是。所以
   `Args.zig` 自己的 test 里有 `try t("aa\nbb\ncc", &.{"aa\nbb\ncc"})`——
   整条就是一个参数。

⚠️ **分隔符只有 `' '` 和 `'\t'`**（`nextWithStrategy` 里的 `switch` 只列这两个），
这和 POSIX `sh` 的规则不一样（sh 里 `\n` 也是分隔符）。

⚠️ **结尾的空格不产生尾部空参数**：`"  aa  bb  "` 切出 3 个（`""` `aa` `bb`）而不是 4 个。
开头的空格**会**产生一个空参数（因为第一个参数用单独的解析规则，见源码第 237-271 行）。

⚠️ **空命令行返回零个参数**（不是一空串）。源码第 239-243 行明说了这一点，
并且注释里特别指出它和 C 运行时的**差异**：

> if the command-line string is empty, the iterator will immediately complete without returning any arguments (whereas the C runtime will return a single argument representing the name of the current executable).

### 为什么是 WTF-8 而不是 UTF-8

`Iterator.Windows.next()` 的文档注释（`Args.zig` 第 57-61 行）说结果编码是
[WTF-8](https://wtf-8.codeberg.page/)。原因在 `emitCharacter`（第 166-205 行）：

Windows 命令行里的代理对（`0xD801 0xDC37`）如果**孤立**地出现，是无法表示成合法
UTF-8 的。Zig 的做法是：

- **成对**的代理项 → 合成码点，按 UTF-8 输出（`0xF0 0x90 0x90 0xB7`，即 `𐐷`）；
- **落单**的代理项 → 按 WTF-8 规则输出成 3 字节的保留序列（`0xED 0xA0 0x81`）。

所以**你的代码不能假设 `next()` 的结果一定是合法 UTF-8**。要判合法性别用
`std.unicode.utf8ValidateSlice`，或者接受 WTF-8 的存在（它对合法 UTF-8 是超集，
所以 UTF-8 解码器看到 WTF-8 里那类序列时会报错而不是静默通过）。

## 22.4 读环境变量：`environ_map` 与 `Environ`

0.17 给了**两条**读环境的路，各有取舍：

| 入口 | 形状 | 取值代价 | 适合 |
|---|---|---|---|
| `init.environ_map` | `*process.Environ.Map` | **O(1) 零分配** | 反复查、要改、要遍历 |
| `init.minimal.environ` | `process.Environ` | 每次查询**重新线性扫**原始 block | 查一两次就走、编译期 key |

```zig
// examples/22_process/main.zig 第 120-161 行
    begin("22.4 环境变量：environ_map 与 Environ");
    std.debug.print("init.environ_map 的类型 = {s}（**指针**，启动时已解析好）\n", .{@typeName(@TypeOf(init.environ_map))});
    const EMT = @typeInfo(std.process.Environ.Map).@"struct";
    inline for (EMT.field_names, EMT.field_types) |fname, ftype| {
        std.debug.print("  Map.{s:<16}: {s}\n", .{ fname[0..fname.len], @typeName(ftype) });
    }
    // get：查一个，返回 map 自己那份拷贝（不分配）
    if (init.environ_map.get("PATH")) |p| {
        std.debug.print("PATH 存在，长度 {d} 字节（本节不抄内容：逐机器不同）\n", .{p.len});
    } else {
        std.debug.print("PATH 不存在\n", .{});
    }
    // get 一个绝对不存在的 key → null（不是错误）
    std.debug.print("get(\"ZZZ_NOT_SET_22\") = {any}（不存在返回 null，不报错）\n", .{init.environ_map.get("ZZZ_NOT_SET_22")});
    // put：改map（子进程可以继承改后的环境）
    try init.environ_map.put("ZZZ_FROM_22", "hello-env");
    std.debug.print("put 后 get = {s}，count = {d}\n", .{ init.environ_map.get("ZZZ_FROM_22").?, init.environ_map.count() });
    // 遍历
    var env_it = init.environ_map.iterator();
    var env_n: usize = 0;
    var with_eq: usize = 0;
    while (env_it.next()) |entry| {
        env_n += 1;
        if (std.mem.indexOfScalar(u8, entry.key_ptr.*, '=') != null) with_eq += 1;
    }
    std.debug.print("遍历到 {d} 个变量迭代器，count() = {d}（两者应相等）\n", .{ env_n, init.environ_map.count() });
    std.debug.print("key 里带 '=' 的个数 = {d} ⇒ Map 把 key/value 拆开存了，key 本身不含 '='\n", .{with_eq});
    // Environ：不建 Map 的直查路径（底层是 OS 给的原始 block）
    std.debug.print("init.minimal.environ 的类型 = {s}，.block = {s}\n", .{
        @typeName(@TypeOf(init.minimal.environ)),
        @typeName(@TypeOf(init.minimal.environ.block)),
    });
    std.debug.print("Environ.getPosix(\"PATH\") != null = {}\n", .{init.minimal.environ.getPosix("PATH") != null});
    std.debug.print("Environ.containsConstant(\"PATH\") = {}（编译期 key，零分配，comptime 展开）\n", .{init.minimal.environ.containsConstant("PATH")});
    if (init.minimal.environ.getAlloc(gpa, "ZZZ_NOT_SET_22")) |v| {
        gpa.free(v);
    } else |e| {
        std.debug.print("Environ.getAlloc 不存在的 key → error.{s}（Map.get 返回 null，Environ.getAlloc 返回错误）\n", .{@errorName(e)});
    }
    std.debug.print("⚠️ std.posix.getenv 在 0.17 **不存在**（@hasDecl = {}）→ 跨平台代码别指望它\n", .{@hasDecl(std.posix, "getenv")});
    std.debug.print("⚠️ Windows 环境变量名**不区分大小写**：Map 的哈希与比较都走 toUpperWtf16/eqlIgnoreCaseWtf8\n", .{});
    end("22.4");
```

运行输出（`examples/22_process/main.zig`）：

```text
==== 22.4 环境变量：environ_map 与 Environ 开始 ====
init.environ_map 的类型 = *process.Environ.Map（**指针**，启动时已解析好）
  Map.array_hash_map  : array_hash_map.Custom([]const u8,[]const u8,process.Environ.Map.EnvNameHashContext,false)
  Map.allocator       : mem.Allocator
PATH 存在，长度 1684 字节（本节不抄内容：逐机器不同）
get("ZZZ_NOT_SET_22") = null（不存在返回 null，不报错）
put 后 get = hello-env，count = 174
遍历到 174 个变量迭代器，count() = 174（两者应相等）
key 里带 '=' 的个数 = 0 ⇒ Map 把 key/value 拆开存了，key 本身不含 '='
init.minimal.environ 的类型 = process.Environ，.block = process.Environ.PosixBlock
Environ.getPosix("PATH") != null = true
Environ.containsConstant("PATH") = true（编译期 key，零分配，comptime 展开）
Environ.getAlloc 不存在的 key → error.EnvironmentVariableMissing（Map.get 返回 null，Environ.getAlloc 返回错误）
⚠️ std.posix.getenv 在 0.17 **不存在**（@hasDecl = false）→ 跨平台代码别指望它
⚠️ Windows 环境变量名**不区分大小写**：Map 的哈希与比较都走 toUpperWtf16/eqlIgnoreCaseWtf8
==== 22.4 结束 ====
```

> `PATH 的长度 1684` 和 `count = 174` 这两个数字**逐机器不同**（取决于装了多少包），
> 本教程按本机实测抄，实际跑你的机器会变。

### `Environ.Map` 的完整方法表（源码实测）

| 方法 | 签名 | 说明 |
|---|---|---|
| `init(gpa)` | `Map` | 建空 map |
| `deinit()` | `void` | 释放所有 key/value + 底层表 |
| `get(key)` | `?[]const u8` | **零分配**，返回 map 自己那份 |
| `getPtr(key)` | `?*[]const u8` | 拿可改的指针 |
| `contains(key)` | `bool` | 在 Windows 上会 assert key 是合法 WTF-8 |
| `put(key, value)` | `Allocator.Error!void` | **复制**进 map |
| `putMove(key, value)` | `Allocator.Error!void` | 所有权转移给 map |
| `swapRemove(key)` | `bool` | O(1) 删（拿末位补洞，**打乱顺序**） |
| `orderedRemove(key)` | `bool` | O(n) 删（保持顺序） |
| `count()` | `Size`（= `usize`） | 元素个数 |
| `iterator()` | `ArrayHashMap.Iterator` | 遍历，元素有 `.key_ptr` / `.value_ptr` |
| `keys()` / `values()` | `[][]const u8` | 两个平行切片 |
| `clone(gpa)` | `Allocator.Error!Map` | 深拷贝 |
| `putAll(other)` | `Allocator.Error!void` | 批量合并 |
| `createPosixBlock(gpa, opts)` | `Allocator.Error!PosixBlock` | **反方向**：map → POSIX block（给子进程用） |

`get` 返回 `null` 而不是错误，是它和 `Environ.getAlloc` 最大的差别：

```zig
// Map 风格：不存在 → null
init.environ_map.get("NOPE")            // ?[]const u8 = null
// Environ 风格：不存在 → error.EnvironmentVariableMissing
init.minimal.environ.getAlloc(gpa, "NOPE")  // []u8 = error.EnvironmentVariableMissing
```

### `Environ` 侧的方法

| 方法 | 是否分配 | 平台可用性 |
|---|---|---|
| `getPosix(key)` | **零分配** | **仅 POSIX**（Windows 上不存在这个函数） |
| `getWindows(key: [*:0]const u16)` | **零分配** | **仅 Windows**，key 是 WTF-16 |
| `getAlloc(gpa, key)` | 分配 | 两边都有，返回 `[]u8` |
| `contains(gpa, key)` | 分配（内部建临时 map） | 两边都有 |
| `containsConstant(key)` | **零分配** | 两边都有，key 是 `comptime`（源码里 `pub inline fn`） |
| `containsUnempty(gpa, key)` | 分配 | 存在且非空字符串才为真 |
| `containsUnemptyConstant(key)` | **零分配** | 同上 |
| `createMap(gpa)` | 分配 | 反方向：Environ → Map |
| `createPosixBlock(gpa, opts)` | 分配 | Environ → POSIX block |

⚠️ **`getPosix` 在 Windows 上没有**。它是 `pub fn`（不是 `inline`），源码里
连 `if (native_os == .windows) return .null;` 这样的兜底都没有——直接引用就编译失败
（`has no member`）。跨平台代码用 `getAlloc` 或 `init.environ_map.get`。

⚠️ **Windows 上环境变量名不区分大小写**。`Map.EnvNameHashContext.hash` 走
`toUpperWtf16` 逐码点大写后再哈希，`eqlKeys` 走 `eqlIgnoreCaseWtf8`——所以
Windows 上 `get("path")` 和 `get("PATH")` 是同一个键。POSIX 上**区分**。
`Environ.zig` 自己的 test 里有这个对照（第 913-918 行）：

```zig
    if (native_os == .windows) {
        try testing.expectEqualStrings("1", env.get("something_New_aNd_LONGER").?);
    } else {
        try testing.expect(null == env.get("something_New_aNd_LONGER"));
    }
```

⚠️ **`put` 的 key 有约束**（`validateKeyForPut`，第 145-153 行）：
不能为空、不能含 `NUL`、不能含 `=`（Windows 上**首字符**可以是 `=`，因为
Windows 有 `=C:` 这类隐藏变量）。违反约束是 `assert` 失败（panic），不是返回错误。

⚠️ **改 `init.environ_map` 会影响子进程**。`SpawnOptions.environ_map` 默认是 `null`
（= 继承父进程），如果你把 `init.environ_map` 改了再 spawn，孩子看到的是**改后**的。
本示例 22.4 往 map 里 put 了 `ZZZ_FROM_22`，22.7 之后 spawn 的子进程都能看到它。

### `std.posix.getenv` 在 0.17 不存在

实测 `@hasDecl(std.posix, "getenv")` = **false**。这条对从旧代码搬过来的人很重要：
POSIX 上 `getenv(3)` 是 libc 的函数，Zig 从来不通过 `std.posix` 暴露它
（因为 Zig 自己不依赖 libc）。0.17 的等价物就是上面的 `Environ.getPosix` / `Environ.Map.get`。

## 22.5 为什么 `argv` 是切片数组而不是命令行字符串

`RunOptions.argv` 的类型是 `[]const []const u8`——**字符串切片数组**，
不是一整条需要解析的命令行。这个决定直接消灭了一整类漏洞。

```zig
// examples/22_process/main.zig 第 164-196 行
    begin("22.5 argv 是切片数组：不用shell 就不会被注入");
    // ⚠️ 0.17 的语法坑：`@TypeOf(Struct.field)` 不成立（TypeOf 只吃表达式），
    //    而`@FieldTypeOf` 在 0.17 **已被移除**（实测 invalid builtin function: '@FieldTypeOf'）。
    //    正解：走 @typeInfo(...).@"struct".field_types，按下标取（下面 22.7 会把整张表打出来）。
    const ROPT_T = @typeInfo(std.process.RunOptions).@"struct";
    std.debug.print("RunOptions.argv 的类型 = {s}（**字符串切片数组**，不是一整条命令行）\n", .{@typeName(ROPT_T.field_types[1])});
    std.debug.print("所以：每个参数**原样**交给 execve/CreateProcess，Zig 不做任何拆分\n", .{});
    // 活证明：把带空格和分号的整串当成 printf 的 argv[2]（格式串 argv[1] 是字面量 "%s"），
    // printf 会**原样**吐出 argv[2]—— 如果 argv 被拆分过，这里就会缺字或多字。
    // ⚠️ 不能用 `cat`：cat 会把参数当**文件名**去打开，不是回显。
    var pr_argv = [_][]const u8{ "printf", "%s", "" };
    pr_argv[2] = injection_probe;
    const r = try std.process.run(gpa, io, .{ .argv = &pr_argv });
    defer {
        gpa.free(r.stdout);
        gpa.free(r.stderr);
    }
    std.debug.print("把这个字符串作为 printf 的 argv[2]（单个参数），它原样吐回：{s}\n", .{r.stdout});
    // 用 shell 的写法演示对比：同样内容拼进命令行就会被拆开
    const sh = try std.process.run(gpa, io, .{ .argv = try shellArgv(arena, "printf '%s' 'a b; echo INJECTED'") });
    defer {
        gpa.free(sh.stdout);
        gpa.free(sh.stderr);
    }
    std.debug.print("对比：同样内容拼进 sh -c 的命令行（这次 %s 在单引号里没被展开）→ {s}\n", .{sh.stdout});
    const sh2 = try std.process.run(gpa, io, .{ .argv = try shellArgv(arena, "printf '%s' a b; echo INJECTED") });
    defer {
        gpa.free(sh2.stdout);
        gpa.free(sh2.stderr);
    }
    std.debug.print("     去掉引号后，分号变成 shell 的语句分隔符 → {s}\n", .{sh2.stdout});
    std.debug.print("⇒ argv 数组 = 无注入面（Zig 不解释 % ; | 这类字符）；shell 命令串 = 注入面（你自己承担）\n", .{});
    end("22.5");
```

运行输出（`examples/22_process/main.zig`）：

```text
==== 22.5 argv 是切片数组：不用shell 就不会被注入 开始 ====
RunOptions.argv 的类型 = []const []const u8（**字符串切片数组**，不是一整条命令行）
所以：每个参数**原样**交给 execve/CreateProcess，Zig 不做任何拆分
把这个字符串作为 printf 的 argv[2]（单个参数），它原样吐回：a b; echo INJECTED
对比：同样内容拼进 sh -c 的命令行（这次 %s 在单引号里没被展开）→ a b; echo INJECTED
     去掉引号后，分号变成 shell 的语句分隔符 → abINJECTED

⇒ argv 数组 = 无注入面（Zig 不解释 % ; | 这类字符）；shell 命令串 = 注入面（你自己承担）
==== 22.5 结束 ====
```

三行输出就是全部论证。被测的字符串是 `injection_probe = "a b; echo INJECTED"`
（源码第 37 行），它同时包含**空格**和**分号**——两种最容易被误解释的字符：

- **走 argv 数组**：`printf` 的 `%s` 拿到完整的 `"a b; echo INJECTED"`，原样输出。
  空格没被拆、分号没被执行。
- **走 `sh -c`（带引号）**：shell 认得单引号，输出一样。
- **走 `sh -c`（不带引号）**：`printf '%s' a b` 打印 `ab`（两个参数各给一个格式串
  之外的被忽略），然后 `;` 变成语句分隔符，`echo INJECTED` **被执行了**——
  输出变成 `abINJECTED`。这就是注入。

**所以规则很硬**：能用 argv 数组就用 argv 数组。实在需要 shell 特性（22.6）
时，命令串里**每个变量都必须自己转义**——Zig 标准库不替你做这件事，也没有一个
"安全的 shell 拼接"函数可调。

⚠️ 顺带一个实测到的坑：`@TypeOf(std.process.RunOptions.argv)` **不成立**
（`@TypeOf` 只吃表达式，不吃"类型.字段"这种类型查询），而 0.17 想当然的替代品
`@FieldTypeOf` **已经被移除了**：

```text
main.zig:157:128: error: invalid builtin function: '@FieldTypeOf'
```

正确做法是走 `@typeInfo(...).@"struct".field_types` 按下标取
（`ROPT_T.field_types[1]` 就是 `argv`）——但**按下标取很脆**：字段顺序变了就错。
本示例在 22.7 把整张字段表打了出来，读的时候对着看。

## 22.6 要 shell 特性就显式套 shell

管道（`|`）、通配符（*）、重定向（`1>&2`）、内建命令（`echo` / `cd` / `trap`）——
这些**都不是操作系统提供的**，是 shell 提供的。`std.process.spawn` 直接调
`execve`/`CreateProcessW`，不经过任何 shell，所以这些字符在 argv 里就是普通字符。

要它们，就**显式**把 shell 当成子进程来跑：

```zig
// examples/22_process/main.zig 第 17-30 行
/// 22.6 / 22.7：要shell 特性（管道、通配符、内建命令、重定向）时**显式**套一层 shell。
/// 返回的 argv 第 0 个元素是 shell 自己，后面才是 `-c` 和命令串。
/// ⚠️ 一旦这么写，注入风险就回到你手上——命令串是拼接出来的就必须自己转义。
fn shellArgv(arena: std.mem.Allocator, command: []const u8) std.mem.Allocator.Error![]const []const u8 {
    // ⚠️ 不能写成 `fn f(...) []const []const u8 { return &.{ "sh", "-c", cmd }; }`——
    //    返回类型是**无长度切片**，指针指向的临时数组出了函数就没了，
    //    spawn 里dupeSentinel 会读到 0x0（实测 Segmentation fault at address 0x0）。
    //    正解：外层数组从 arena 分配（内层字符串直接借用调用方的 command，不用 dupe）。
    const out = try arena.alloc([]const u8, 3);
    out[0] = if (builtin.os.tag == .windows) "cmd" else "sh";
    out[1] = if (builtin.os.tag == .windows) "/c" else "-c";
    out[2] = command;
    return out;
}
```

```zig
// examples/22_process/main.zig 第 199-216 行
    begin("22.6 要 shell 特性：显式 sh -c / cmd /c");
    std.debug.print("echo 是 shell **内建命令**，不是 /bin/echo → 直接传 {{\"echo\"}} 在很多系统上会 FileNotFound\n", .{});
    const shell_cmd = "echo out; echo err 1>&2; echo piped | tr a-z A-Z";
    const argv = try shellArgv(arena, shell_cmd);
    std.debug.print("要跑这串（分号 + 重定向 + 管道），本平台 argv =", .{});
    for (argv, 0..) |a, i| {
        std.debug.print(" [{d}]={s}", .{ i, a });
    }
    std.debug.print("\n", .{});
    const sr = try std.process.run(gpa, io, .{ .argv = argv });
    defer {
        gpa.free(sr.stdout);
        gpa.free(sr.stderr);
    }
    std.debug.print("--- stdout ---\n{s}--- stderr ---\n{s}", .{ sr.stdout, sr.stderr });
    std.debug.print("⚠️ 套shell 之后，命令串是**拼接**出来的就必须自己转义，否则就是注入漏洞\n", .{});
    std.debug.print("   本示例的命令串全是字面量，所以安全；换成用户输入就不安全\n", .{});
    end("22.6");
```

运行输出（`examples/22_process/main.zig`）：

```text
==== 22.6 要 shell 特性：显式 sh -c / cmd /c 开始 ====
echo 是 shell **内建命令**，不是 /bin/echo → 直接传 {"echo"} 在很多系统上会 FileNotFound
要跑这串（分号 + 重定向 + 管道），本平台 argv = [0]=sh [1]=-c [2]=echo out; echo err 1>&2; echo piped | tr a-z A-Z
--- stdout ---
out
PIPED
--- stderr ---
err
⚠️ 套shell 之后，命令串是**拼接**出来的就必须自己转义，否则就是注入漏洞
   本示例的命令串全是字面量，所以安全；换成用户输入就不安全
==== 22.6 结束 ====
```

三个 shell 变体（本机实测）：

| 平台 | argv |
|---|---|
| POSIX（Linux/macOS/BSD） | `{"sh", "-c", command}` |
| Windows | `{"cmd", "/c", command}` |

> Windows 上如果命令串比较长（> 8191 字符）要用 `cmd /s /c`；
> 如果要跑 `.bat`/`.cmd` 文件本身，`cmd /c` 是唯一选择（`CreateProcess` 不直接执行批处理）。
> 这也是 `SpawnError` 里有 `InvalidBatchScriptArg` 这个错误的原因——NUL/LF/CR
> 在 `.bat`/`.cmd` 参数里是**不允许**的（LF 表示参数结束、CR 会被 `cmd.exe` 剥掉）。

⚠️ **绝不要把用户输入直接拼进 `command`**。本示例的命令串全是编译期字面量，
所以安全。真实代码里如果你要拼，**必须**自己按目标 shell 的规则转义
（POSIX sh 用单引号包裹并把内层 `'` 写成 `'\''`；cmd 的规则完全不同——
`%`、`^`、`&`、`|` 都有特殊含义，且 `cmd.exe` 的解析有两层）。

⚠️ **`shellArgv` 为什么不能返回 `&.{...}` 字面量**（本教程新踩的坑）：
返回类型写成 `[]const []const u8`（**无长度切片**）时，
`return &.{ "sh", "-c", cmd };` 返回的指针指向函数里的**临时数组**——
函数一返回它就没了。`spawn` 里的 `dupeSentinel` 会读悬垂指针。实测：

```text
Segmentation fault at address 0x0
compiler_rt/memcpy.zig:67:22: 0x103b1c8d8 in copyLessThan16 (compiler_rt)
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/mem/Allocator.zig:494:20: 0x103c20c31 in dupeSentinel__func_618 (main)
    @memcpy(new_buf[0..m.len], m);
                   ^
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:15882:75: 0x103c0c56b in processSpawnDarwin (main)
    for (options.argv, 0..) |arg, i| argv_buf[i] = (try arena.dupeSentinel(u8, arg, 0)).ptr;
                                                                          ^
```

正解是像上面那样**显式从分配器拿外层数组**。注意内层的三个字符串**不用** dupe——
`"sh"` / `"-c"` 是编译期常量，`command` 由调用方保证活到 `run` 返回。

⚠️ 如果你把返回类型写成 `*const [3][]const u8`（**有**长度的指针），
`return &.{ "sh", "-c", cmd };` 是合法的——因为指针把长度和地址一起带走了。
本示例用 arena 是因为想统一"运行期拼 argv"的写法。

## 22.7 `std.process.run`：一步式跑完并收输出

`run(gpa, io, options)` 是"跑完、收干净、返回"的一步式：它内部就是
`spawn` + `MultiReader` 收集 stdout/stderr + `wait`。

```zig
// examples/22_process/main.zig 第 219-236 行
    begin("22.7 std.process.run：一步式跑完并收输出");
    std.debug.print("run 的返回类型 = {s}\n", .{@typeName(@TypeOf(std.process.run))});
    const ROPT = @typeInfo(std.process.RunOptions).@"struct";
    std.debug.print("RunOptions 共 {d} 个字段：", .{ROPT.field_names.len});
    inline for (ROPT.field_names, ROPT.field_types) |fname, ftype| {
        std.debug.print("\n  .{s:<16}: {s}", .{ fname[0..fname.len], @typeName(ftype) });
    }
    std.debug.print("\n", .{});
    const res = try std.process.run(gpa, io, .{ .argv = &.{ "echo", "hello from child" } });
    std.debug.print("RunResult 的类型 = {s}（.term / .stdout / .stderr）\n", .{@typeName(std.process.RunResult)});
    std.debug.print("stdout = {s}", .{res.stdout});
    std.debug.print("stderr 长度 = {d}\n", .{res.stderr.len});
    std.debug.print("term = {f}（success() = {}）\n", .{ res.term, res.term.success() });
    gpa.free(res.stdout);
    gpa.free(res.stderr);
    std.debug.print("⚠️ run 内部 spawn 时把 stdin 设成 .ignore、stdout/stderr 设成 .pipe：拿不到交互能力\n", .{});
    std.debug.print("⚠️ **调用者 owns result.stdout / result.stderr**：用 gpa 就必须 free（见上）\n", .{});
    end("22.7");
```

运行输出（`examples/22_process/main.zig`）：

```text
==== 22.7 std.process.run：一步式跑完并收输出 开始 ====
run 的返回类型 = fn (mem.Allocator, Io, process.RunOptions) error{AccessDenied,AntivirusInterference,BadPathName,Canceled,ConcurrencyUnavailable,ConnectionResetByPeer,DeviceBusy,FileBusy,FileLocksUnsupported,FileNotFound,FileSystem,FileTooBig,InputOutput,InvalidBatchScriptArg,InvalidExe,InvalidName,InvalidProcessGroupId,InvalidUserId,InvalidWtf8,IsDir,LockViolation,NameTooLong,NetworkNotFound,NoDevice,NoSpaceLeft,NotDir,NotOpenForReading,OperationUnsupported,OutOfMemory,PathAlreadyExists,PermissionDenied,PipeBusy,ProcessAlreadyExec,ProcessFdQuotaExceeded,ReadOnlyFileSystem,ResourceLimitReached,SocketUnconnected,StreamTooLong,SymLinkLoop,SystemFdQuotaExceeded,SystemResources,Timeout,Unexpected,UnrecognizedVolume,WouldBlock}!process.RunResult
RunOptions 共 11 个字段：
  .exe             : process.ReplaceOptions.Exe
  .argv            : []const []const u8
  .stderr_limit    : Io.Limit
  .stdout_limit    : Io.Limit
  .reserve_amount  : usize
  .cwd             : process.Child.Cwd
  .environ_map     : ?*const process.Environ.Map
  .expand_arg0     : process.ArgExpansion
  .progress_node   : Progress.Node
  .create_no_window: bool
  .timeout         : Io.Timeout
RunResult 的类型 = process.RunResult（.term / .stdout / .stderr）
stdout = hello from child
stderr 长度 = 0
term = exited with code 0（success() = true）
⚠️ run 内部 spawn 时把 stdin 设成 .ignore、stdout/stderr 设成 .pipe：拿不到交互能力
⚠️ **调用者 owns result.stdout / result.stderr**：用 gpa 就必须 free（见上）
==== 22.7 结束 ====
```

### `RunOptions` 逐字段（本机实测）

| 字段 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `.exe` | `process.ReplaceOptions.Exe` | `.detect` | `.detect` 从 argv[0] 推；也可 `.path` / `.zig` |
| `.argv` | `[]const []const u8` | **必填** | 字符串切片数组 |
| `.stderr_limit` | `Io.Limit` | `.unlimited` | 超过就 `error.StreamTooLong` |
| `.stdout_limit` | `Io.Limit` | `.unlimited` | 同上 |
| `.reserve_amount` | `usize` | `64` | 初始分配多少字节（`MultiReader.fill` 用） |
| `.cwd` | `process.Child.Cwd` | `.inherit` | `.inherit` / `.dir(Io.Dir)` / `.path([]const u8)` |
| `.environ_map` | `?*const Environ.Map` | `null` | `null` = 继承父进程 |
| `.expand_arg0` | `process.ArgExpansion` | `.no_expand` | `.expand` 才让 argv[0] 里的 `%VAR%` 之类展开 |
| `.progress_node` | `std.Progress.Node` | `.none` | 进度树接子进程（`ZIG_PROGRESS` 环境变量） |
| `.create_no_window` | `bool` | **`true`** | 仅 Windows：`CREATE_NO_WINDOW` 标志 |
| `.timeout` | `Io.Timeout` | `.none` | 见 22.9 |

⚠️ **`RunOptions` 里没有 `max_output_bytes`**（旧文档写过这个名字）——
0.17 改成了 `stdout_limit` / `stderr_limit`，**两个独立**的 `Io.Limit`，
而且是 `Io.Limit` 类型（不是字节数）。

⚠️ **`create_no_window` 在 `RunOptions` 里默认 `true`**，但在 `SpawnOptions` 里默认 `false`。
两个结构体默认值不同，别以为它们一样。

⚠️ **`.exe = .detect` 时 argv[0] 会被当路径解析**。`.environ_map` 里的 PATH
**不参与**这个解析（源码注释：`The PATH value from here is not used to resolve argv[0];
that resolution always uses parent environment`）。

### `RunResult`

```zig
pub const RunResult = struct {
    term: Child.Term,
    stdout: []u8,
    stderr: []u8,
};
```

三个字段，都是**调用者 owns**。用 `init.gpa` 就必须 `free` 两个切片；
用 `init.arena` 可以不 free（退出时一起释放）。

### `RunError` 的成员（实测全展开）

`RunError = error{StreamTooLong} || SpawnError || Io.File.MultiReader.UnendingError || Io.Timeout.Error`
（`process.zig` 第 466-468 行）。展开后是 44 个错误名，本机实测：

```text
AccessDenied, AntivirusInterference, BadPathName, Canceled, ConcurrencyUnavailable,
ConnectionResetByPeer, DeviceBusy, FileBusy, FileLocksUnsupported, FileNotFound,
FileSystem, FileTooBig, InputOutput, InvalidBatchScriptArg, InvalidExe, InvalidName,
InvalidProcessGroupId, InvalidUserId, InvalidWtf8, IsDir, LockViolation, NameTooLong,
NetworkNotFound, NoDevice, NoSpaceLeft, NotDir, NotOpenForReading,
OperationUnsupported, OutOfMemory, PathAlreadyExists, PermissionDenied, PipeBusy,
ProcessAlreadyExec, ProcessFdQuotaExceeded, ReadOnlyFileSystem, ResourceLimitReached,
SocketUnconnected, StreamTooLong, SymLinkLoop, SystemFdQuotaExceeded, SystemResources,
Timeout, Unexpected, UnrecognizedVolume, WouldBlock
```

只有三个是 `RunError` 自己加的：`StreamTooLong`（输出超限）、
`Timeout`（`Io.Timeout.Error`）、`Canceled`（`Io.Cancelable`，io 被取消）。
其余全是 `SpawnError` 的传播。**实用子集**就五个：
`FileNotFound`（程序不存在）、`AccessDenied`（没权限执行）、
`OutOfMemory`、`StreamTooLong`、`Timeout`。

### `run` vs `spawn`：什么时候用哪个

| | `run` | `spawn` |
|---|---|---|
| 返回 | `RunResult`（值） | `Child`（值，**不是指针**） |
| stdin | 固定 `.ignore`（`/dev/null`） | 可选 `.inherit`/`.file`/`.ignore`/`.pipe`/`.close` |
| stdout/stderr | 固定 `.pipe`，**全量收集进内存** | 可选，同上 |
| 结束 | 内部已 `wait` 过 | 你自己 `wait(io)` / `kill(io)` |
| 内存 | 分配 `stdout`+`stderr` 两块 | 只分配你请求的 |
| 适合 | git status、跑个 linter、拿版本号 | 交互式（vim、ssh）、流式处理（tail -f）、大数据 |

选 `run`：**一次性**拿到全部输出、内容不大（几 MB 以内）、不需要喂 stdin。
选 `spawn`：其它所有情况。尤其是"输出可能很大"或"要边跑边读"——
`run` 会把整个输出**读进内存**，一个失控的子进程能把你 OOM 掉
（用 `stdout_limit` 可以兜住，但那就是 `spawn` 的活了）。

## 22.8 `term`：怎么判定子进程的结局

`Child.Term` 是四个成员的联合（实测）：

```zig
// examples/22_process/main.zig 第 239-276 行
    begin("22.8 term：正常退出 / 非零退出 / 被信号杀死");
    const TINFO = @typeInfo(std.process.Child.Term).@"union";
    std.debug.print("Child.Term = {s}，{d} 个成员：", .{ @typeName(std.process.Child.Term), TINFO.field_names.len });
    inline for (TINFO.field_names) |fname| std.debug.print(" .{s}", .{fname[0..fname.len]});
    std.debug.print("\n", .{});
    // 正常退出 0
    const ok0 = try std.process.run(gpa, io, .{ .argv = &.{ "sh", "-c", "exit 0" } });
    defer {
        gpa.free(ok0.stdout);
        gpa.free(ok0.stderr);
    }
    std.debug.print("exit 0         → {f}；success() = {}\n", .{ ok0.term, ok0.term.success() });
    // 非零退出
    const bad3 = try std.process.run(gpa, io, .{ .argv = &.{ "sh", "-c", "exit 3" } });
    defer {
        gpa.free(bad3.stdout);
        gpa.free(bad3.stderr);
    }
    std.debug.print("exit 3         → {f}；success() = {}；.exited = {d}\n", .{ bad3.term, bad3.term.success(), bad3.term.exited });
    // 被信号杀死
    const sig9 = try std.process.run(gpa, io, .{ .argv = &.{ "sh", "-c", "kill -9 $$" } });
    defer {
        gpa.free(sig9.stdout);
        gpa.free(sig9.stderr);
    }
    std.debug.print("kill -9 $$     → {f}；success() = {}\n", .{ sig9.term, sig9.term.success() });
    switch (sig9.term) {
        .signal => |sig| std.debug.print("  .signal 载荷 = {d}（{t}）\n", .{ @backingInt(sig), sig }),
        else => {},
    }
    // 启动失败：不是 term，是错误
    if (std.process.run(gpa, io, .{ .argv = &.{"no-such-binary-zz-22"} })) |_| {
        std.debug.print("?? 不该成功\n", .{});
    } else |e| {
        std.debug.print("程序不存在     → error.{s}（**spawn 阶段**就失败，没有 term 可言）\n", .{@errorName(e)});
    }
    std.debug.print("⚠️ term.success() 只在 .exited 且 code == 0 时为真；被信号杀死算失败\n", .{});
    end("22.8");
```

运行输出（`examples/22_process/main.zig`）：

```text
==== 22.8 term：正常退出 / 非零退出 / 被信号杀死 开始 ====
Child.Term = process.Child.Term，4 个成员： .exited .signal .stopped .unknown
exit 0         → exited with code 0；success() = true
exit 3         → exited with code 3；success() = false；.exited = 3
kill -9 $$     → terminated with signal KILL；success() = false
  .signal 载荷 = 9（KILL）
程序不存在     → error.FileNotFound（**spawn 阶段**就失败，没有 term 可言）
⚠️ term.success() 只在 .exited 且 code == 0 时为真；被信号杀死算失败
==== 22.8 结束 ====
```

四个成员（源码 `Child.zig` 第 94-115 行）：

| 成员 | 载荷 | `{f}` 打印 | 含义 |
|---|---|---|---|
| `.exited` | `u8` | `exited with code 3` | 正常退出，载荷是退出码 |
| `.signal` | `std.posix.SIG` | `terminated with signal KILL` | 被信号杀死 |
| `.stopped` | `std.posix.SIG` | `stopped with signal TSTP` | 被信号**暂停**（`SIGSTOP`/`SIGTSTP`） |
| `.unknown` | `u32` | `terminated unexpectedly` | 平台给不出解释 |

`success()` 的实现只有一行（`Child.zig` 第 100-105 行）：

```zig
pub fn success(t: Term) bool {
    return switch (t) {
        .exited => |code| code == 0,
        else => false,
    };
}
```

**只有 `.exited` 且 code == 0 才算成功**。被信号杀死（哪怕只是 `SIGTERM`）
算失败——这个判断是对的，因为"被信号杀死"意味着你的程序没干完它该干的事。

⚠️ **"启动失败"和"跑失败"是两件事**：
- 程序不存在 / 没权限 → `run` **返回错误**（`error.FileNotFound` / `error.AccessDenied`），
  压根没有 `term`。
- 程序起来了但退出码非零 → `run` **成功返回**，退出码在 `term.exited` 里。

这个区分很重要：CI 里判断"测试是否通过"要同时看两者。
只看 `term.success()` 会漏掉"编译器根本没跑起来"。

⚠️ `.stopped` 只会出现在**你自己发过停止信号**的情况下（`SpawnOptions` 没有这个选项，
所以要用 `std.posix.kill(pid, .SIGSTOP)`）。`wait` 在 POSIX 上不带 `WUNTRACED`
时不会返回 `.stopped`——所以这个成员在实践中基本用不到，写代码时留个 `else =>` 分支就行。

## 22.9 超时与输出上限

`RunOptions.timeout` 的类型是 `Io.Timeout`——**不是数字**。
`Io.Timeout` 本身是三个成员的联合（实测）：

```zig
// examples/22_process/main.zig 第 279-311 行
    begin("22.9 timeout 与 stdout_limit / stderr_limit");
    std.debug.print("RunOptions.timeout 的类型 = {s}（不是数字，是 Io.Timeout）\n", .{@typeName(@typeInfo(std.process.RunOptions).@"struct".field_types[10])});
    const TTI = @typeInfo(std.Io.Timeout).@"union";
    std.debug.print("Io.Timeout 的成员：", .{});
    inline for (TTI.field_names) |fname| std.debug.print(" .{s}", .{fname[0..fname.len]});
    std.debug.print("\n", .{});
    // 超时：睡 5 秒但只给 80ms
    // ⚠️ 0.17 的坑：无名结构体字面量 `.{{ ... }}` 推不出目标类型时要**显式标注**
    const to: std.Io.Timeout = .{ .duration = .{ .raw = std.Io.Duration.fromMilliseconds(80), .clock = .awake } };
    if (std.process.run(gpa, io, .{ .argv = &.{ "sleep", "5" }, .timeout = to })) |v| {
        std.debug.print("?? 超时没触发：{f}\n", .{v.term});
        gpa.free(v.stdout);
        gpa.free(v.stderr);
    } else |e| {
        std.debug.print("sleep 5 但 timeout=80ms → error.{s}（run 内部 defer child.kill(io)）\n", .{@errorName(e)});
    }
    // stdout_limit：输出超过上限就报错，而不是无限吃内存
    const lim = std.process.run(gpa, io, .{
        .argv = try shellArgv(arena, "printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'"),
        .stdout_limit = .limited(8),
    });
    if (lim) |v| {
        std.debug.print("?? 上限没触发\n", .{});
        gpa.free(v.stdout);
        gpa.free(v.stderr);
    } else |e| {
        std.debug.print("输出 30 字节但 stdout_limit = .limited(8) → error.{s}\n", .{@errorName(e)});
    }
    std.debug.print("Io.Limit = {s}：.nothing=0 .unlimited=maxInt(usize) 还有 _.（**非穷尽** enum）\n", .{@typeName(std.Io.Limit)});
    std.debug.print("  .limited(8) 的 backingInt = {d}，toInt() = {any}（unlimited 时 toInt() 返回 null）\n", .{ @backingInt(std.Io.Limit.limited(8)), std.Io.Limit.limited(8).toInt() });
    std.debug.print("⚠️ @tagName(Io.Limit.limited(8)) 会 panic: invalid enum value（非穷尽 enum 不能取 tagName）\n", .{});
    std.debug.print("⚠️ RunError = error{{StreamTooLong}} || SpawnError || ... || Io.Timeout.Error\n", .{});
    end("22.9");
```

运行输出（`examples/22_process/main.zig`）：

```text
==== 22.9 timeout 与 stdout_limit / stderr_limit 开始 ====
RunOptions.timeout 的类型 = Io.Timeout（不是数字，是 Io.Timeout）
Io.Timeout 的成员： .none .duration .deadline
sleep 5 但 timeout=80ms → error.Timeout（run 内部 defer child.kill(io)）
输出 30 字节但 stdout_limit = .limited(8) → error.StreamTooLong
Io.Limit = Io.Limit：.nothing=0 .unlimited=maxInt(usize) 还有 _.（**非穷尽** enum）
  .limited(8) 的 backingInt = 8，toInt() = 8（unlimited 时 toInt() 返回 null）
⚠️ @tagName(Io.Limit.limited(8)) 会 panic: invalid enum value（非穷尽 enum 不能取 tagName）
⚠️ RunError = error{StreamTooLong} || SpawnError || ... || Io.Timeout.Error
==== 22.9 结束 ====
```

### `Io.Timeout` 的三种形态

| 写法 | 含义 |
|---|---|
| `.none` | **永远等**（默认值） |
| `.{ .duration = .{ .raw = Io.Duration, .clock = Clock } }` | 从**现在起**等这么久 |
| `.{ .deadline = Clock.Timestamp }` | 等到**绝对时刻** |

第二个成员是 `Clock.Duration`（不是 `Io.Duration`）——它多了 `.clock` 字段，
因为"等 80 毫秒"得说明是按哪个钟量的（`Clock.Duration.sleep` 收的就是它）。
写成 `Io.Duration` 会报类型不匹配。

⚠️ **超时时 `run` 会 `kill` 掉子进程**。源码第 521 行是 `defer child.kill(io);`——
`run` 内部**任何**提前返回的路径（超时、`StreamTooLong`、`checkAnyError` 失败）
都会触发这个 `kill`。所以超时之后不会留下孤儿进程。

### `Io.Limit` 是非穷尽 enum（本章新踩的坑）

```zig
pub const Limit = enum(usize) {
    nothing = 0,
    unlimited = math.maxInt(usize),
    _,                          // ← 非穷尽

    pub fn limited(n: usize) Limit { return @fromBackingInt(@intCast(n)); }
    // ...
    pub fn toInt(l: Limit) ?usize { ... }   // unlimited 时返回 null
};
```

因为有 `_,`（非穷尽），`.limited(8)` 造出来的值**不在枚举的已知成员表里**。
后果有两个，都实测撞到：

**后果一：`@tagName` 直接 panic**。

```text
thread 1624957 panic: invalid enum value
/tmp/p22/p8.zig:11:48: 0x102e64e42 in main (p8)
    std.debug.print("  .limited(8) = {s}\n", .{@tagName(std.Io.Limit.limited(8))});
                                               ^
```

**后果二：枚举值当函数实参时不能写 `.limited(8)`**——解析器把 `.limited` 当成
枚举字面量的 tag，然后发现它是函数：

```text
main.zig:704:90: error: type '@EnumLiteral()' not a function
    try std.testing.expectEqual(std.Io.Limit.max(std.Io.Limit.limited(4), .limited(8)), .limited(8));
                                                                                        ^~^^^^^^
```

所以 `Io.Limit` 的正确用法只有两种：写全 `std.Io.Limit.limited(8)`，
或者用 `@backingInt` / `.toInt()` 读值。本示例两个坑都在注释里标了。

`Io.Limit` 的完整方法（源码第 730-790 行）：
`limited(usize)` / `limited64(u64)` / `countVec([][]const u8)` / `min` / `max` /
`minInt` / `minInt64` / `slice` / `sliceConst` / `toInt`。

## 22.10 `std.process.spawn`：流式交互

`spawn(io, options)` 返回一个 `Child` **值**（不是指针），
你自己管它的三个流和它的生命周期。

```zig
// examples/22_process/main.zig 第 314-351 行
    begin("22.10 std.process.spawn：流式交互");
    std.debug.print("spawn 的返回类型 = {s}（注意是 **Child 值**，不是指针）\n", .{@typeName(@TypeOf(std.process.spawn))});
    const SOPT = @typeInfo(std.process.SpawnOptions).@"struct";
    std.debug.print("SpawnOptions 共 {d} 个字段，比 RunOptions 多的是流三件套：\n", .{SOPT.field_names.len});
    inline for (SOPT.field_names, SOPT.field_types) |fname, ftype| {
        const is_stream = std.mem.eql(u8, fname, "stdin") or
            std.mem.eql(u8, fname, "stdout") or std.mem.eql(u8, fname, "stderr");
        if (is_stream) std.debug.print("  .{s:<8}: {s}\n", .{ fname[0..fname.len], @typeName(ftype) });
    }
    std.debug.print("  StdIo 的成员：.inherit / .file / .ignore / .pipe / .close\n", .{});
    const CT = @typeInfo(std.process.Child).@"struct";
    std.debug.print("Child 的字段：", .{});
    inline for (CT.field_names) |fname| std.debug.print(" .{s}", .{fname[0..fname.len]});
    std.debug.print("\n", .{});
    // 往子进程 stdin 写，边跑边读 stdout，最后 wait
    var child = try std.process.spawn(io, .{
        .argv = &echo_argv,
        .stdin = .pipe,
        .stdout = .pipe,
        .stderr = .inherit,
    });
    var wbuf: [64]u8 = undefined;
    var fw = child.stdin.?.writer(io, &wbuf);
    try fw.interface.print("ping\n", .{});
    try fw.interface.flush();
    // ⚠️ 关键：close 之后必须把字段置 null。wait 内部的 childCleanupPosix 会再关一次，
    //    二次 close 触发 unreachable（实测 panic: reached unreachable code ← closeFd .BADF）
    child.stdin.?.close(io);
    child.stdin = null;
    var rbuf: [256]u8 = undefined;
    var fr = child.stdout.?.reader(io, &rbuf);
    var outbuf: [256]u8 = undefined;
    var ow = std.Io.Writer.fixed(&outbuf);
    _ = try fr.interface.streamRemaining(&ow);
    const cterm = try child.wait(io);
    std.debug.print("写进去 5 字节，读回来 = {s}（term = {f}）\n", .{ ow.buffered(), cterm });
    std.debug.print("wait 之后 child.id = {any}（被 wait 置空了，不能再 kill/wait）\n", .{child.id});
    end("22.10");
```

运行输出（`examples/22_process/main.zig`）：

```text
==== 22.10 std.process.spawn：流式交互 开始 ====
spawn 的返回类型 = fn (Io, process.SpawnOptions) error{AccessDenied,AntivirusInterference,BadPathName,Canceled,DeviceBusy,FileBusy,FileLocksUnsupported,FileNotFound,FileSystem,FileTooBig,InputOutput,InvalidBatchScriptArg,InvalidExe,InvalidName,InvalidProcessGroupId,InvalidUserId,InvalidWtf8,IsDir,NameTooLong,NetworkNotFound,NoDevice,NoSpaceLeft,NotDir,OperationUnsupported,OutOfMemory,PathAlreadyExists,PermissionDenied,PipeBusy,ProcessAlreadyExec,ProcessFdQuotaExceeded,ReadOnlyFileSystem,ResourceLimitReached,SymLinkLoop,SystemFdQuotaExceeded,SystemResources,Unexpected,UnrecognizedVolume,WouldBlock}!process.Child（注意是 **Child 值**，不是指针）
SpawnOptions 共 17 个字段，比 RunOptions 多的是流三件套：
  .stdin   : process.SpawnOptions.StdIo
  .stdout  : process.SpawnOptions.StdIo
  .stderr  : process.SpawnOptions.StdIo
  StdIo 的成员：.inherit / .file / .ignore / .pipe / .close
Child 的字段： .id .thread_handle .stdin .stdout .stderr .resource_usage_statistics .request_resource_usage_statistics
写进去 5 字节，读回来 = ping
（term = exited with code 0）
wait 之后 child.id = null（被 wait 置空了，不能再 kill/wait）
==== 22.10 结束 ====
```

### `SpawnOptions` 逐字段（本机实测）

17 个字段。`RunOptions` 那 11 个里它保留了 `exe` / `argv` / `cwd` / `environ_map` /
`expand_arg0` / `progress_node` / `create_no_window`（**默认值不同**，见 22.7），
去掉了 `stderr_limit` / `stdout_limit` / `reserve_amount` / `timeout`
（因为你自己读，自己管超时），**加上了**这些：

| 字段 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `.stdin` | `StdIo` | `.inherit` | 子进程的 stdin |
| `.stdout` | `StdIo` | `.inherit` | 子进程的 stdout |
| `.stderr` | `StdIo` | `.inherit` | 子进程的 stderr |
| `.inherit_dirs` | `[]const Io.Dir` | `&.{}` | 传给子进程继承的目录 fd（给 WASI / 沙箱用） |
| `.inherit_files` | `[]const Io.File` | `&.{}` | 同上，文件 |
| `.request_resource_usage_statistics` | `bool` | `false` | `wait` 后填 `resource_usage_statistics`（Linux/Darwin 走 `wait4`） |
| `.uid` | `?posix.uid_t` | `null` | POSIX only |
| `.gid` | `?posix.gid_t` | `null` | POSIX only |
| `.pgid` | `?posix.pid_t` | `null` | 进程组 id |
| `.start_suspended` | `bool` | `false` | 起来先 SIGSTOP（POSIX） |

`ResourceUsageStatistics.getMaxRss()` 也有个平台差异（`Child.zig` 第 45-71 行）：
Linux/BSD 乘 1024（因为报的是 KB），**Darwin 直接就是字节**（源码注释：
`Darwin oddly reports in bytes instead of kilobytes`），Windows 是 `PeakWorkingSetSize`。

### `StdIo` 的五个成员（实测）

| 成员 | 效果 | 之后 `child.<流>` |
|---|---|---|
| `.inherit` | 继承父进程的同一个流 | `null` |
| `.file` | 传一个已打开的 `Io.File` | `null` |
| `.ignore` | 接到 `/dev/null`（Windows 是 `NUL`） | `null` |
| `.pipe` | **新建管道** | `?Io.File`（读端或写端） |
| `.close` | 流**不存在**（子进程用这流会 EBADF） | `null` |

选 `.pipe` 时，`Child` 对应字段被**赋值**成一个 `Io.File`。
拿它 `.writer(io, &buf)` / `.reader(io, &buf)` 就得到流式读写
（和 20 章的 `Io.File` 用法完全一样）。

⚠️ `.close` 与 `StdIo.ignore` 的区别：`.ignore` 给的是 `/dev/null`（读得到 EOF、
写得到丢弃），`.close` 是**这 fd 不存在**。只有确定子进程不会碰它时才用 `.close`；
三个流里只关一个的话，剩下的会**错位**（源码注释里明确警告了：
`if only one stream is closed, it will result in them getting mixed up`）。

⚠️ `.inherit` 在 Debug 构建下有代价：子进程直接写你的终端，
它的输出和你的 `std.debug.print` 会交错，调试时很难看。
`run` 之所以用 `.pipe` 而不是 `.inherit` 就是这个原因。

### `Child` 的字段（本机实测，macOS）

| 字段 | 类型 | 说明 |
|---|---|---|
| `.id` | `?i32` | POSIX 是 pid；**`wait`/`kill` 之后变 `null`** |
| `.thread_handle` | `void` | 仅 Windows 有（`HANDLE`） |
| `.stdin` | `?Io.File` | `.pipe` 时的**写**端 |
| `.stdout` | `?Io.File` | `.pipe` 时的**读**端 |
| `.stderr` | `?Io.File` | `.pipe` 时的**读**端 |
| `.resource_usage_statistics` | `process.Child.ResourceUsageStatistics` | `wait` 后有效 |
| `.request_resource_usage_statistics` | `bool` | 你传进去的标志（回显） |

`Child.Id` 是平台别名：POSIX = `std.posix.pid_t`（`i32`），
Windows = `HANDLE`，WASI = `void`。

### ⚠️⚠️ 写完 stdin 必须 close **并置 null**

这是本章最狠的一个坑，我第一次写就踩了。规则：

```zig
// ✓ 对
child.stdin.?.close(io);
child.stdin = null;          // ← 千万别漏
```

只 `close` 不置 `null` 的实测报错（完整栈，含内存地址故不逐字节抄地址）：

```text
thread 1681807 panic: reached unreachable code
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:14472:19: 0x1007e8268 in recoverableOsBugDetected (dbl)
    if (is_debug) unreachable;
                  ^
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:19963:42: 0x1007e6eac in closeFd (dbl)
        .BADF => recoverableOsBugDetected(), // use after free
                                         ^
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:15790:16: 0x1007ee5b5 in childCleanupPosix (dbl)
        closeFd(stdin.handle);
               ^
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:15666:28: 0x1007ef548 in childWaitPosix (dbl)
    defer childCleanupPosix(child);
                           ^
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:15559:38: 0x1007eee2d in childWait (dbl)
    else => return childWaitPosix(child),
                                     ^
```

**机制**（`Io/Threaded.zig` 第 15787-15800 行）：`wait` 里有一句
`defer childCleanupPosix(child)`，它对每个非 null 的流字段调 `closeFd`。
你手动 `close` 过之后 fd 已经失效，于是 `closeFd` 收到 `EBADF`，
走 `recoverableOsBugDetected()`——Debug 模式下那里是 `unreachable`，直接 panic。
（源码在 `.BADF` 后面还加了注释 `// use after free`。）

**规则归纳**：

| 场景 | 做法 |
|---|---|
| 要给子进程发 EOF（结束它的输入） | `close(io)` **然后** 字段置 `null` |
| 只是想让 `wait` 统一清理 | **不要** close，直接 `wait` |
| 还没读完就想丢弃 | 字段置 `null`（不 close，让 `wait` 关） |

### `wait` 会清空 `id`

`wait` 之后 `child.id` 变 `null`（实测输出倒数第二行）。之后再调 `wait`
或 `kill` 会撞 `assert(child.id != null)`。
这也是判断"是否已经收过尸"的可靠标志。

### 流式交互的完整形状

真正的"边跑边读"（一边写 stdin 一边读 stdout）需要两个并发任务：
`io.async` / `io.concurrent` 一个在写、一个在读。
本教程 31 章（并发）会展开那套机制。这里演示的是**顺序版**：
写完 → 关闭 stdin（子进程此时看到 EOF）→ 读到 stdout 结束 → `wait`。
对于"喂一串输入、拿一串输出"的批处理场景（最常见的那种），这个形状够用，
而且**没有并发就没有死锁风险**。

⚠️ 注意 `Io.Reader.stream` / `Io.Writer.print` 的 0.17 签名：
`stream` 的第二个参数是 `Io.Limit` 不是字节数（`stream(w, .limited(64))`），
`streamRemaining(w)` 返回 `usize`（不是可选），
`print` **固定两个参数**（格式串没占位符也要传 `.{}`，
写 `print("x")` 报 `expected 2 argument(s), found 1`）。

## 22.11 `Child.kill`：不等它自己结束

```zig
// examples/22_process/main.zig 第 354-362 行
    begin("22.11 Child.kill：不等它自己结束");
    std.debug.print("kill 的类型 = {s}（注意：**不收 signal 参数**，语义就是\"终止\"）\n", .{@typeName(@TypeOf(std.process.Child.kill))});
    std.debug.print("wait 的类型 = {s}\n", .{@typeName(@TypeOf(std.process.Child.wait))});
    var victim = try std.process.spawn(io, .{ .argv = &.{ "sleep", "30" } });
    std.debug.print("kill 前 child.id != null = {}\n", .{victim.id != null});
    victim.kill(io);
    std.debug.print("kill 后 child.id == null = {}（kill 内部清理并置空，且**幂等**）\n", .{victim.id == null});
    std.debug.print("⚠️ 没有 killById，kill 也不收信号：要发别的信号得自己走 std.posix.kill(pid, sig)\n", .{});
    end("22.11");
```

运行输出（`examples/22_process/main.zig`）：

```text
==== 22.11 Child.kill：不等它自己结束 开始 ====
kill 的类型 = fn (*process.Child, Io) void（注意：**不收 signal 参数**，语义就是"终止"）
wait 的类型 = fn (*process.Child, Io) error{AccessDenied,Canceled,Unexpected}!process.Child.Term
kill 前 child.id != null = true
kill 后 child.id == null = true（kill 内部清理并置空，且**幂等**）
⚠️ 没有 killById，kill 也不收信号：要发别的信号得自己走 std.posix.kill(pid, sig)
==== 22.11 结束 ====
```

| 方法 | 签名 | 说明 |
|---|---|---|
| `kill` | `fn (*Child, Io) void` | 强制终止 + 等它真死 + 清所有资源。**幂等** |
| `wait` | `fn (*Child, Io) error{AccessDenied,Canceled,Unexpected}!Term` | 阻塞到子进程结束 |

`kill` 的文档注释（`Child.zig` 第 128-133 行）：

> Requests for the operating system to forcibly terminate the child process, then blocks until it terminates, then cleans up all resources.
> Idempotent and does nothing after `wait` returns.
> Uncancelable. Ignores unexpected errors from the operating system.

四条性质：**幂等**（调两次不崩）、`wait` 之后变 no-op、**不可取消**（没有 `error.Canceled`）、
**忽略意外错误**（返回 `void`，不给你错误处理的余地）。

⚠️ **没有 `killById`**，也**没有 `kill(io, signal)`**。想发特定信号（比如 `SIGTERM`
让程序优雅退出、`SIGSTOP` 暂停）得自己走：

```zig
const pid = child.id orelse return;
try std.posix.kill(pid, .SIGTERM);   // 自己发，然后自己 child.wait(io)
```

⚠️ `kill` 是 `void` 而不是 `!void`——**你不知道它有没有成功**。
如果子进程处于 D 状态（不可中断的磁盘 I/O），`kill` 会一直阻塞。
需要超时就得用 `spawn` + `std.posix.kill(pid, .SIGKILL)` + 自己管超时。

⚠️ `kill` 之后 `child.id` 变 `null`，**不能**再 `wait`（`assert` 会炸）。
所以"kill 然后 wait 拿 term"这个组合是**不成立的**——你拿不到 term，
只知道"我把它杀了"。想要 term 就别 kill，让它自己结束。

## 22.12 `init.preopens`：父进程递进来的文件

`preopens` 是六个 `Init` 字段里最冷门的一个，但它是 WASI 的核心机制。

```zig
// examples/22_process/main.zig 第 365-381 行
    begin("22.12 init.preopens：父进程递给我们的文件");
    std.debug.print("init.preopens 的类型 = {s}\n", .{@typeName(@TypeOf(init.preopens))});
    const PT = @typeInfo(std.process.Preopens).@"struct";
    inline for (PT.field_names, PT.field_types) |fname, ftype| {
        std.debug.print("  .{s:<6}: {s}\n", .{ fname[0..fname.len], @typeName(ftype) });
    }
    std.debug.print("get(name) 返回 ?Resource，Resource = union(enum){{ .file: Io.File, .dir: Io.Dir }}\n", .{});
    for ([_][]const u8{ "stdin", "stdout", "stderr", "anything-else" }) |nm| {
        if (init.preopens.get(nm)) |pres| {
            std.debug.print("  get(\"{s}\") = .{s}\n", .{ nm, @tagName(pres) });
        } else {
            std.debug.print("  get(\"{s}\") = null\n", .{nm});
        }
    }
    std.debug.print("本机 Preopens.Map = {s}（非 WASI 是 void；WASI 上是按 fd 索引的 String(void)）\n", .{@typeName(std.process.Preopens.Map)});
    std.debug.print("⇒ 非 WASI 上它就是 stdin/stdout/stderr 三个名字的查表，别的名字一律 null\n", .{});
    end("22.12");
```

运行输出（`examples/22_process/main.zig`）：

```text
==== 22.12 init.preopens：父进程递给我们的文件 开始 ====
init.preopens 的类型 = process.Preopens
  .map   : void
get(name) 返回 ?Resource，Resource = union(enum){ .file: Io.File, .dir: Io.Dir }
  get("stdin") = .file
  get("stdout") = .file
  get("stderr") = .file
  get("anything-else") = null
本机 Preopens.Map = void（非 WASI 是 void；WASI 上是按 fd 索引的 String(void)）
⇒ 非 WASI 上它就是 stdin/stdout/stderr 三个名字的查表，别的名字一律 null
==== 22.12 结束 ====
```

`Preopens` 的结构（源码 `Preopens.zig`）：

| 平台 | `Preopens.Map` | `get(name)` 的行为 |
|---|---|---|
| **WASI** | `std.array_hash_map.String(void)`（**按 fd 编号索引**） | fd ≤ 2 返回 `.file`，> 2 返回 `.dir` |
| 其他所有 | `void` | 名字是 `"stdin"`/`"stdout"`/`"stderr"` 就返回对应 `Io.File`，**其它一律 null** |

`Init.preopens` 的文档注释（`process.zig` 第 46-49 行）说得很准：

> Named files that have been provided by the parent process. This is mainly useful on WASI, but can be used on other systems to mimic the behavior with respect to stdio.

**它的真正价值在 WASI 上**：`wasm32-wasi` 目标没有"文件系统"，
所有能力都是父进程以"预打开 fd"的形式递进来的。`preopens` 就是那份清单
（`Preopens.init(arena)` 扫 `fd_prestat_get` 把它建出来）。
写 WASI 程序时你要的文件句柄全从这里来。

**非 WASI 上它就是个三名字查表**——写跨平台代码时，
"能不能重定向 stdin"这种问题可以统一用 `preopens.get("stdin")` 问，
而不用按平台分支。返回的是 `?Resource`（`union(enum){ file: Io.File, dir: Io.Dir }`），
所以要先 `@tagName` 判一下是文件还是目录。

## 22.13 退出码：三种写法

```zig
// examples/22_process/main.zig 第 384-390 行
    begin("22.13 退出码：三种写法");
    std.debug.print("写法一：pub fn main(init: std.process.Init) !void —— 正常返回 = 0，错误冒泡 = 1\n", .{});
    std.debug.print("写法二：pub fn main() u8 —— 直接把 u8 当退出码（实测 return 3 → $? = 3）\n", .{});
    std.debug.print("写法三：std.process.exit({s}) —— 签名**不收 io**（实测传 io 报 expected 1 argument(s), found 2）\n", .{@typeName(@TypeOf(std.process.exit))});
    std.debug.print("子进程退出码怎么读：run 的 res.term 是 .exited 时 .exited 就是那个 u8（见 22.8）\n", .{});
    std.debug.print("⚠️ exit 是 noreturn：它**不做** defer 清理、不flush、不释放 arena\n", .{});
    end("22.13");
```

运行输出（`examples/22_process/main.zig`）：

```text
==== 22.13 退出码：三种写法 开始 ====
写法一：pub fn main(init: std.process.Init) !void —— 正常返回 = 0，错误冒泡 = 1
写法二：pub fn main() u8 —— 直接把 u8 当退出码（实测 return 3 → $? = 3）
写法三：std.process.exit(fn (u8) noreturn) —— 签名**不收 io**（实测传 io 报 expected 1 argument(s), found 2）
子进程退出码怎么读：run 的 res.term 是 .exited 时 .exited 就是那个 u8（见 22.8）
⚠️ exit 是 noreturn：它**不做** defer 清理、不flush、不释放 arena
==== 22.13 结束 ====
```

三种写法的实测行为：

```zig
// 写法一
pub fn main(init: std.process.Init) !void { ... }   // 正常返回 → $? = 0
// 写法二
pub fn main() u8 { return 3; }                        // $? = 3
// 写法三
pub fn main(init: std.process.Init) !void { std.process.exit(7); }   // $? = 7
```

错误冒泡的情况（写法一）实测（stderr）：

```text
error: Boom
/private/tmp/p22/e3.zig:2:23: 0x101021ba8 in main (e3)
pub fn main() !void { return error.Boom; }
                      ^
```
退出码 **1**。

⚠️ **`std.process.exit(status: u8)` 不收 `io`**。实测：

```text
q.zig:2:66: error: expected 1 argument(s), found 2
q.zig:2:66: note: function declared here
pub fn exit(status: u8) noreturn {
```

这和本章**所有其它 API** 都反着来：`run` / `spawn` / `wait` / `kill` /
`currentPath` / `setCurrentPath` / `lockMemory` 全部第一个参数是 `io`，
只有 `exit` 不是（`abort()` 不收，`fatal(fmt, args)` 不收，
`cleanExit(io)` 收——三个各不相同）。写习惯成自然写 `exit(io, 1)` 就会撞这条。

⚠️ **`exit` 是 `noreturn`，不做清理**。它直接走到 `start.zig` 的 `_exit`，所以：
- `defer` 不跑
- 缓冲**不 flush**（`std.debug.print` 自己是 unbuffered 的所以没事，
  但 `std.Io.File.stdout().writer(io, &buf)` 这类就有风险）
- `init.arena` 不释放

所以**优先用 `return`（写法一）**，它会正常走完所有 `defer`。
只在"要立刻退出、返回路径太长"时才用 `exit`。

⚠️ **写法二（`main() u8`）不能配合 `std.process.Init`**。两个都写会报 main 签名冲突。
要自定义退出码又想要 `init` 的写法是：记一个 code，正常返回，在 `defer` 里
`std.process.exit(code)`。不过一般不需要——CI 里的失败应该用**错误冒泡**
（退出码 1 + stderr 带错误返回跟踪）而不是裸的 3。

### 怎么读子进程的退出码

就是 22.8 那个：`run` 的 `res.term` 是 `.exited` 时载荷就是退出码。

```zig
const res = try std.process.run(gpa, io, .{ .argv = argv });
defer { gpa.free(res.stdout); gpa.free(res.stderr); }
switch (res.term) {
    .exited => |code| if (code != 0) { /* 失败 */ },
    .signal => |sig| { /* 被信号杀 */ },
    .stopped, .unknown => {},
}
```

shell 里的 `$?` 就是这个 `u8`。管道 `a | b` 的 `$?` 是**最后一个**命令的
（`a` 的退出码在 `PIPESTATUS[0]`，bash/zsh 才有）。

## 22.14 时间与睡眠：时间也归 `Io`

0.16 把 `std.time` 的计时函数**全部收编进 `std.Io`**。现在没有全局时钟了——
`Clock.now(clock, io)` 的第一个参数是"哪个钟"，第二个是"从哪个 io 拿"。

```zig
// examples/22_process/main.zig 第 393-426 行
    begin("22.14 时间与睡眠：std.Io.Clock");
    std.debug.print("Io.Clock 的成员（本机实测共 {d} 个，**没有 .monotonic**）：", .{@typeInfo(std.Io.Clock).@"enum".field_names.len});
    inline for (@typeInfo(std.Io.Clock).@"enum".field_names) |fname| std.debug.print(" .{s}", .{fname[0..fname.len]});
    std.debug.print("\n", .{});
    std.debug.print("⚠️ 写 .monotonic 实测报 enum 'Io.Clock' has no member named 'monotonic'\n", .{});
    // now
    const t0 = std.Io.Clock.now(.awake, io);
    std.debug.print("Clock.now(.awake, io) 返回 {s}，字段 .nanoseconds 的类型 = {s}\n", .{ @typeName(@TypeOf(t0)), @typeName(@TypeOf(t0.nanoseconds)) });
    // sleep：两条等价路径
    try std.Io.sleep(io, std.Io.Duration.fromMilliseconds(2), .awake);
    const t1 = std.Io.Clock.now(.awake, io);
    const via_io_sleep = t0.durationTo(t1).nanoseconds;
    const t2 = std.Io.Clock.now(.awake, io);
    try (std.Io.Clock.Duration{ .raw = std.Io.Duration.fromMilliseconds(2), .clock = .awake }).sleep(io);
    const t3 = std.Io.Clock.now(.awake, io);
    const via_clock_sleep = t2.durationTo(t3).nanoseconds;
    std.debug.print("睡 2ms 两次：Io.sleep 路径 {d} ns，Clock.Duration.sleep 路径 {d} ns\n", .{ via_io_sleep, via_clock_sleep });
    std.debug.print("（两次都是**正数**但每次运行都不同 —— ns 数不可复现，别断言具体值）\n", .{});
    // 三种 Duration 别搞混
    const d = std.Io.Duration.fromNanoseconds(1_500_000);
    std.debug.print("Io.Duration = {s}（只有 .nanoseconds 字段，纯时长）\n", .{@typeName(std.Io.Duration)});
    std.debug.print("Clock.Duration = {s}（.raw + .clock，sleep 要用这个）\n", .{@typeName(std.Io.Clock.Duration)});
    std.debug.print("Clock.Timestamp = {s}（.raw + .clock）\n", .{@typeName(std.Io.Clock.Timestamp)});
    std.debug.print("d 用 {{f}} 打印 = {f}；toMilliseconds() = {d}；toSeconds() = {d}\n", .{ d, d.toMilliseconds(), d.toSeconds() });
    std.debug.print("⚠️ Io.Duration 有 format（走 {{f}}）但**没有** formatNumber：{{d}} 打印它会编译失败\n", .{});
    std.debug.print("实测报 no field or member function named 'formatNumber' in 'Io.Duration'\n", .{});
    // 墙钟 vs 单调钟
    const wall = std.Io.Clock.now(.real, io);
    const awake = std.Io.Clock.now(.awake, io);
    std.debug.print(".real 是墙钟（Unix 纪元纳秒，会被 NTP 跳变）；.awake 是单调钟（测耗时用它）\n", .{});
    std.debug.print("  .real 纳秒位数 = {d}（约 {d} 年纪元），.awake 纳秒 = {d}（开机时长量级）\n", .{ wall.nanoseconds, @divTrunc(wall.nanoseconds, 31_557_600_000_000_000), awake.nanoseconds });
    const res_awake = std.Io.Clock.awake.resolution(io) catch std.Io.Duration.fromNanoseconds(0);
    std.debug.print("  .awake 的分辨率 = {d} ns（resolution(io) 返回 Io.Duration，不是整数）\n", .{res_awake.nanoseconds});
    end("22.14");
```

运行输出（`examples/22_process/main.zig`）：

```text
==== 22.14 时间与睡眠：std.Io.Clock 开始 ====
Io.Clock 的成员（本机实测共 5 个，**没有 .monotonic**）： .real .awake .boot .cpu_process .cpu_thread
⚠️ 写 .monotonic 实测报 enum 'Io.Clock' has no member named 'monotonic'
Clock.now(.awake, io) 返回 Io.Timestamp，字段 .nanoseconds 的类型 = i96
睡 2ms 两次：Io.sleep 路径 2380000 ns，Clock.Duration.sleep 路径 2134027 ns
（两次都是**正数**但每次运行都不同 —— ns 数不可复现，别断言具体值）
Io.Duration = Io.Duration（只有 .nanoseconds 字段，纯时长）
Clock.Duration = Io.Clock.Duration（.raw + .clock，sleep 要用这个）
Clock.Timestamp = Io.Clock.Timestamp（.raw + .clock）
d 用 {f} 打印 = 1.5ms；toMilliseconds() = 1；toSeconds() = 0
⚠️ Io.Duration 有 format（走 {f}）但**没有** formatNumber：{d} 打印它会编译失败
实测报 no field or member function named 'formatNumber' in 'Io.Duration'
.real 是墙钟（Unix 纪元纳秒，会被 NTP 跳变）；.awake 是单调钟（测耗时用它）
  .real 纳秒位数 = 1791342232665720000（约 56 年纪元），.awake 纳秒 = 33585227122630（开机时长量级）
  .awake 的分辨率 = 1 ns（resolution(io) 返回 Io.Duration，不是整数）
==== 22.14 结束 ====
```

> **不可复现的三处**：两个 sleep 的 ns 数（实测在 200 万 ~ 300 万之间波动，
> 取决于系统调度）、`.real` 的纪元纳秒（随时钟走）、`.awake` 的开机时长。
> 示例的 test 块只断言"耗时为正"这个事实，不锁死数字。

### 五个时钟（本机实测）

| `Clock` | 语义 | 平台对应 | 用途 |
|---|---|---|---|
| `.real` | 墙钟，**会跳变**（NTP / 管理员改） | Unix 纪元纳秒 | 显示时间、日志时间戳、文件 mtime 比较 |
| `.awake` | 单调，**不含**休眠时间 | macOS: `CLOCK_UPTIME_RAW`<br>Linux: `CLOCK_MONOTONIC` | **测耗时**（默认选它） |
| `.boot` | 单调，**含**休眠时间 | macOS: `CLOCK_MONOTONIC_RAW`<br>Linux: `CLOCK_BOOTTIME` | 埋点、跨休眠的间隔 |
| `.cpu_process` | 本进程用掉的 CPU 时间 | — | 算用户态耗时 |
| `.cpu_thread` | 本线程用掉的 CPU 时间 | — | 算线程耗时 |

⚠️ **没有 `.monotonic`**。实测：

```text
q.zig:2:78: error: enum 'Io.Clock' has no member named 'monotonic'
q.zig:2:78: note: enum declared here
pub const Clock = enum {
                        ^
```

旧代码里的 `.monotonic` 要改成 `.awake`（或按语义选 `.boot`）。
`.awake` 和 `.boot` 的区别就是**休眠算不算**——源码注释明说了
（`Io.zig` 第 854-878 行）：`.awake` "expresses intent to **exclude** time that the
system is suspended"，`.boot` 是 "identical to `awake` except it expresses intent to
**include** time that the system is suspended"。

**测耗时永远用 `.awake`**：墙钟被 NTP 调整会测出负数或巨大的跳变。

### 三种时长/时刻类型（最容易搞混的地方）

| 类型 | 字段 | 干什么 | 本章示例 |
|---|---|---|---|
| `Io.Duration` | `.nanoseconds: i96` | **纯时长**，无归属 | `Io.Duration.fromMilliseconds(2)` |
| `Io.Clock.Duration` | `.raw: Io.Duration` + `.clock: Clock` | 挂在某个钟上的时长 | `Clock.Duration{ .raw = ..., .clock = .awake }` |
| `Io.Clock.Timestamp` | `.raw: Io.Timestamp` + `.clock: Clock` | 挂在某个钟上的时刻 | `Clock.Timestamp.now(io, .awake)` |

`Clock.now(clock, io)` 返回的是**裸** `Io.Timestamp`（只有 `.nanoseconds`，
**不带** `.clock`）——想知道"这个数字是哪个钟来的"得用 `Clock.Timestamp.now(io, clock)`
或 `.withClock()`。

`Io.sleep(io, duration, clock)` 三个参数是**最省事**的写法；
`Clock.Duration.sleep(io)` 是"我已经有一个 Clock.Duration 了"的写法。两者等价，
本示例两条都演示了。`Io.Timeout.sleep(io)` 是第三种（22.9 用过）。

`Clock.Timestamp` 上还有 `wait(io)`（睡到那个时刻）、`fromNow(io, dur)`、
`untilNow(io)`、`durationFromNow(io)`、`toClock(io, clock)`（换钟）、
`compare(op, rhs)`。`Clock.Duration` 上只有 `sleep(io)`。

### `Io.Timestamp` / `Io.Duration` 的方法（实测）

| 方法 | `Timestamp` | `Duration` | 返回类型 |
|---|---|---|---|
| `now(io, clock)` | ✅ | — | `Io.Timestamp` |
| `zero` / `max` | `.zero` | `.zero` / `.max` | 常量 |
| `durationTo(other)` | ✅ | — | `Duration` |
| `addDuration` / `subDuration` | ✅ | — | `Timestamp` |
| `fromNanoseconds(x)` | ✅ | ✅ | 自身 |
| `fromMicroseconds` / `fromMilliseconds` / `fromSeconds` | — | ✅ | 自身 |
| `toNanoseconds()` | ✅ | ✅ | **`i96`** |
| `toMicroseconds()` / `toMilliseconds()` / `toSeconds()` | ✅ | ✅ | **`i64`** |
| `format` | — | ✅ | `{f}` 用 |
| `formatNumber` | ✅ | ❌ | `{d}` 用 |
| `untilNow` / `durationFromNow` | ✅ | — | 需要 `io` + `clock` |

⚠️ **`toNanoseconds()` 返回 `i96`，不是 `i64` 也不是 `u64`**（实测）。
`i96` 是**有符号** 128 位——纳秒数用它是因为 Unix 纪元纳秒（1.79e18）
在某些平台上 `i64` 不够宽，而差值可能为负（`durationTo` 的结果）。

⚠️ **有符号整数除法必须写 `@divTrunc`**。这是 15.13 节记过的坑，这里再确认一次：
`.toMilliseconds()` 内部用 `@divTrunc`（所以 1.5ms 截断成 1，不是四舍五入成 2）。
你自己拿 `.nanoseconds` 算就必须：

```zig
// ✘ 编译错：division with 'i96' and 'comptime_int': signed integers must use @divTrunc
// const ms = ns / std.time.ns_per_ms;
// ✓ 对
const ms: i64 = @intCast(@divTrunc(ns, std.time.ns_per_ms));
```

### ⚠️ `Io.Duration` 不能用 `{d}` 打印

`Io.Writer.printValue` 的 `'d'` 分支对结构体调 `value.formatNumber`（`Writer.zig`
第 1185 行）。`Io.Timestamp` **有** `formatNumber`，`Io.Duration` **没有**——
所以 `{d}` 打印 `Io.Duration` 编译失败：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Writer.zig:1185:43: error: no field or member function named 'formatNumber' in 'Io.Duration'
                .@"struct" => return value.formatNumber(w, options.toNumber(.decimal, .lower)),
                                     ^~~~~^~~~~~~~~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io.zig:1087:22: note: struct declared here
pub const Duration = struct {
                     ^~~~~~~~~~~~~
```

`Io.Duration` 走的是 `'f'` 分支（`return value.format(w)`），
它的 `format` 实现会输出 `1.5ms` / `1.234s` / `2h30m` 这种**人类可读**的形式
（`Io.zig` 第 1127-1160 行：`[#y][#w][#d][#h][#m]#[.###][n|u|m]s`）。

所以：`Io.Duration` 用 `{f}`，要数字就自己 `.nanoseconds` 配 `{d}`。

## 22.15 `std.time` 在 0.17 还剩什么

一句话：**只剩单位换算常量**，所有计时函数都搬到了 `std.Io`。

```zig
// examples/22_process/main.zig 第 429-456 行
    begin("22.15 std.time 在 0.17 还剩什么");
    const names = [_]struct { n: []const u8, note: []const u8, has: bool }{
        .{ .n = "ns_per_us", .note = "常量 1000", .has = @hasDecl(std.time, "ns_per_us") },
        .{ .n = "ns_per_ms", .note = "常量", .has = @hasDecl(std.time, "ns_per_ms") },
        .{ .n = "ns_per_s", .note = "常量", .has = @hasDecl(std.time, "ns_per_s") },
        .{ .n = "ns_per_min", .note = "常量", .has = @hasDecl(std.time, "ns_per_min") },
        .{ .n = "ns_per_hour", .note = "常量", .has = @hasDecl(std.time, "ns_per_hour") },
        .{ .n = "ns_per_day", .note = "常量", .has = @hasDecl(std.time, "ns_per_day") },
        .{ .n = "ns_per_week", .note = "常量", .has = @hasDecl(std.time, "ns_per_week") },
        .{ .n = "us_per_ms", .note = "常量（还有 us_per_s）", .has = @hasDecl(std.time, "us_per_ms") },
        .{ .n = "s_per_min", .note = "常量（还有 s_per_s/day/week）", .has = @hasDecl(std.time, "s_per_min") },
        .{ .n = "epoch", .note = "日历换算（time/epoch.zig）", .has = @hasDecl(std.time, "epoch") },
        .{ .n = "Timer", .note = "0.16 已移除 → Io.Clock.now", .has = @hasDecl(std.time, "Timer") },
        .{ .n = "Instant", .note = "0.16 已移除 → Io.Timestamp", .has = @hasDecl(std.time, "Instant") },
        .{ .n = "nanoTimestamp", .note = "0.16 已移除 → Io.Clock.now(.real)", .has = @hasDecl(std.time, "nanoTimestamp") },
        .{ .n = "now", .note = "0.16 已移除 → Io.Clock.now", .has = @hasDecl(std.time, "now") },
        .{ .n = "sleep", .note = "0.16 已移除 → Io.sleep / Clock.Duration.sleep", .has = @hasDecl(std.time, "sleep") },
    };
    var exist: usize = 0;
    var missing: usize = 0;
    for (names) |entry| {
        std.debug.print("  std.time.{s:<16} {s}  {s}\n", .{ entry.n, if (entry.has) "存在  " else "不存在", entry.note });
        if (entry.has) exist += 1 else missing += 1;
    }
    std.debug.print("小计：{d} 个存在（全是常量 + epoch），{d} 个不存在（全是函数/类型）\n", .{ exist, missing });
    std.debug.print("⇒ 一句话：0.17 的 std.time **只剩单位换算常量**，所有计时函数都在 std.Io.Clock 上\n", .{});
    std.debug.print("⇒ 因为时间也要可被测试替换：测试里传个假 Io 就能控制\"现在几点\"\n", .{});
    end("22.15");
```

运行输出（`examples/22_process/main.zig`）：

```text
==== 22.15 std.time 在 0.17 还剩什么 开始 ====
  std.time.ns_per_us        存在    常量 1000
  std.time.ns_per_ms        存在    常量
  std.time.ns_per_s         存在    常量
  std.time.ns_per_min       存在    常量
  std.time.ns_per_hour      存在    常量
  std.time.ns_per_day       存在    常量
  std.time.ns_per_week      存在    常量
  std.time.us_per_ms        存在    常量（还有 us_per_s）
  std.time.s_per_min        存在    常量（还有 s_per_s/day/week）
  std.time.epoch            存在    日历换算（time/epoch.zig）
  std.time.Timer            不存在  0.16 已移除 → Io.Clock.now
  std.time.Instant          不存在  0.16 已移除 → Io.Timestamp
  std.time.nanoTimestamp    不存在  0.16 已移除 → Io.Clock.now(.real)
  std.time.now              不存在  0.16 已移除 → Io.Clock.now
  std.time.sleep            不存在  0.16 已移除 → Io.sleep / Clock.Duration.sleep
小计：10 个存在（全是常量 + epoch），5 个不存在（全是函数/类型）
⇒ 一句话：0.17 的 std.time **只剩单位换算常量**，所有计时函数都在 std.Io.Clock 上
⇒ 因为时间也要可被测试替换：测试里传个假 Io 就能控制"现在几点"
==== 22.15 结束 ====
```

`std.time` 的**全部**内容（`lib/std/time.zig`，**34 行**）：

| 类别 | 成员 |
|---|---|
| 纳秒除数 | `ns_per_us` `ns_per_ms` `ns_per_s` `ns_per_min` `ns_per_hour` `ns_per_day` `ns_per_week` |
| 微秒除数 | `us_per_ms` `us_per_s` `us_per_min` `us_per_hour` `us_per_day` `us_per_week` |
| 毫秒除数 | `ms_per_s` `ms_per_min` `ms_per_hour` `ms_per_day` `ms_per_week` |
| 秒除数 | `s_per_min` `s_per_hour` `s_per_day` `s_per_week` |
| 其它 | `epoch`（`pub const epoch = @import("time/epoch.zig")`，日历换算） |

**一个函数都没有**。文件的末尾只有一个 `test { _ = epoch; }`。

迁移对照表：

| 旧（≤0.15） | 新（0.16/0.17） |
|---|---|
| `std.time.Timer.start()` / `.read()` | `std.Io.Clock.now(.awake, io)` + `t0.durationTo(t1)` |
| `std.time.Instant.now()` | `std.Io.Clock.now(.real, io)`（墙钟）或 `.awake`（单调） |
| `std.time.nanoTimestamp()` | `std.Io.Clock.now(.real, io).nanoseconds` |
| `std.time.sleep(3 * std.time.ns_per_s)` | `std.Io.sleep(io, .fromSeconds(3), .awake)` |
| `std.time.milliTimestamp()` | `std.Io.Clock.now(.real, io).toMilliseconds()` |

**为什么时间也要归 `Io`**：和 22.1 是同一条设计哲学。既然参数、环境、文件、子进程
都从参数来，时间没理由例外。好处是测试里可以传一个假 `Io`（或者用
`std.testing.io`）来控制"现在几点"——比如测试一段"30 秒后重试"的逻辑时，
不必真的等 30 秒。15.13 节的手写基准就是这条的直接受益者。

## 22.x 坑位清单

1. **`std.process` 里没有任何全局状态**。`argsAlloc` / `args` / `getEnvMap` / `getEnvVarOwned` 全部移除（实测 `root source file struct 'process' has no member named 'argsAlloc'`）。参数走 `init.minimal.args`，环境走 `init.environ_map`。

2. **`init.minimal.args` 只有一个字段 `.vector`**。没有 `.len`（实测 `no field named 'len' in struct 'process.Args'`）、没有 `.argv`、没有 `.next()`。必须 `iterate()` / `iterateAllocator()` / `toSlice(arena)`。跨平台代码一律用 `iterateAllocator`。

3. **`toSlice` 必须配 arena 型分配器**。源码注释：`an arena-style allocator must be used`——Windows 上它把参数摊平进一块连续内存，返回的每个切片指向不同偏移，普通分配器管不了。

4. **Windows 的 `Args.Vector` 是 `[]const u16`（WTF-16），不是 argv 数组**。`Iterator.Windows` 是纯函数，给它一条 WTF-16-LE 就能在任何平台跑（本示例 22.3 在 macOS 上实测）。**分隔符只有空格和 tab**——换行和回车不是分隔符。

5. **`next()` 的结果是 WTF-8 不是 UTF-8**。落单的代理项编不进合法 UTF-8，Zig 用 WTF-8 的保留序列表示。不要假设能直接 `utf8ValidateSlice` 通过。

6. **`std.posix.getenv` 在 0.17 不存在**（实测 `@hasDecl` = false）。跨平台读环境用 `init.environ_map.get` 或 `Environ.getAlloc`。另外 ⚠️ **0.17.0 std bug：`Environ.getPosix` 在 Windows 上是 std 内部的编译错误**——它的实现走 `block.view()`，而 Windows 的 `GlobalBlock` 没有 `view()`（实测报错点在 `std/process/Environ.zig:632`，不是你的代码）。Windows 查环境走 `environ_map` 或 `getWindows`（WTF-16 key，且 `block.use_global` 为假时一律返回 null）。

7. **`argv` 是切片数组不是命令行字符串——这是安全边界，不要自己拆掉**。本示例 22.5 用 `printf` 实测：同一个含空格和分号的字符串，走 argv 数组原样穿过，走 `sh -c` 不加引号就会被分号切开并执行后半段。套 shell 之后转义责任完全在你。

8. **返回 `&.{...}` 字面量的函数不能声明 `[]const T` 返回类型**。指针指向临时数组，函数一返回就悬垂——`spawn` 里的 `dupeSentinel` 会读它。实测 `Segmentation fault at address 0x0`。正解：用分配器拿外层数组，或把返回类型写成 `*const [N]T`。

9. **`std.process.exit(status: u8)` 不收 `io`**（实测 `expected 1 argument(s), found 2`）。本章其它所有 API（`run`/`spawn`/`wait`/`kill`/`currentPath`/`setCurrentPath`）第一个参数都是 `io`，只有 `exit` 不是。

10. **`exit` 是 `noreturn` 不做清理**：`defer` 不跑、缓冲不 flush、arena 不释放。优先 `return`。

11. **往子进程 stdin 写完必须 `close(io)` 之后把字段置 `null`**。`wait` 内部的 `childCleanupPosix` 会 `closeFd` 每个非 null 字段，二次 close 收到 `EBADF` → `recoverableOsBugDetected` → Debug 下 `unreachable` panic。实测完整栈见 22.10。

12. **`RunOptions` 里没有 `max_output_bytes`**，是 `stdout_limit` / `stderr_limit` 两个独立的 `Io.Limit`。`Io.Limit` 是**非穷尽 enum**（有 `_`）——`@tagName(.limited(8))` 直接 panic，枚举值当函数实参也不能写 `.limited(8)`（报 `type '@EnumLiteral()' not a function`）。只能用 `@backingInt` / `.toInt()` / 写全 `std.Io.Limit.limited(8)`。

13. **`create_no_window` 在 `RunOptions` 默认 `true`、在 `SpawnOptions` 默认 `false`**。两个结构体不是同一份默认值。

14. **"启动失败"与"跑失败"是两件事**。程序不存在 → `run` 返回 `error.FileNotFound`（压根没 term）；退出码非零 → `run` 成功返回，码在 `term.exited`。`term.success()` 只在 `.exited && code == 0` 时为真。

15. **`Io.Clock` 没有 `.monotonic`**（实测 `enum 'Io.Clock' has no member named 'monotonic'`）。测耗时用 `.awake`（不含休眠），要含休眠用 `.boot`，要墙钟用 `.real`。`std.time` 在 0.17 **只剩常量 + epoch**，一个函数都没有。

16. **`Io.Duration` 有 `format` 但没有 `formatNumber`**，所以 `{d}` 打印它**编译失败**（实测 `no field or member function named 'formatNumber' in 'Io.Duration'`）。用 `{f}`（输出 `1.5ms` 这种）或自己拿 `.nanoseconds`。另外 `toNanoseconds()` 返回 **`i96`**（不是 i64/u64），有符号除法必须 `@divTrunc`。

17. **`@TypeOf(Struct.field)` 不成立、`@FieldTypeOf` 在 0.17 已移除**（实测 `invalid builtin function: '@FieldTypeOf'`）。查字段类型要走 `@typeInfo(T).@"struct".field_types[i]`——按下标取很脆，读的时候把字段表打出来对着看。

18. **union 字面量后要调方法必须加括号**：`(std.process.Child.Term{ .exited = 0 }).success()` 才编译得过，写 `Term{ .exited = 0 }.success()` 报 `expected ',' after argument`。写全类型名或用 `const T = ...` 别名都一样。

19. **无名结构体字面量推不出目标类型时要显式标注**：`.timeout = .{ .duration = ... }` 报 `expected type 'Io.Timeout', found 'main.main__struct_971'`——因为匿名结构体字面量**跨函数是不同类型**（3.10 节记过）。写成 `const to: std.Io.Timeout = .{ ... };` 再传。

20. **`std.debug.print` 固定两个参数**（格式串没占位符也要传 `.{}`），`Io.Writer.print` 同理。写 `print("x")` 报 `expected 2 argument(s), found 1`。另外 **`Io.Reader.stream` 的 limit 参数是 `Io.Limit` 不是字节数**：`stream(w, .limited(64))`；`streamRemaining(w)` 返回 `usize`（不是可选）。

---

上一章：[21 内联汇编](21-asm.md) · 下一章：[23 调试与工具](23-debugging.md)
