# 00 · 从 0.16 迁移到 0.17（完整对照）

> 本章是**迁移手册**，不是教程正文。0.17 移除了相当多的语法和标准库 API，
> 你在网上（乃至旧版本的本教程）读到的 0.16 代码**大概率编译不过**。
> 本章把每一处变化列清楚，并给出 0.17 里该怎么写 —— 每条都附实测证据。
>
> 阅读顺序：第一次用本教程不必读本章，直接从 [01 全景](01-overview.md) 开始；
> 从 0.16 过来、或手上有一堆 0.16 代码时，先扫一遍本章。

---

## 0.1 先说结论：0.17 变了什么

0.17 不是一个"小版本"。它动了三层东西：

| 层 | 变化性质 | 代表 |
|---|---|---|
| **语言** | 直接移除、无法兼容 | `**` 运算符、`void{}` 字面量 |
| **内建函数** | 改名 / 收紧 | `@intFromEnum` → `@backingInt`、`@cImport` 移除、`@bitCast` 拒绝裸结构体 |
| **标准库 / 构建** | 重构 | `@typeInfo` 结构重写、`std.Io` 接口统一、`std.Io.net` 取代裸 socket、Juicy Main |

一个总的判断标准：**0.17 更强调"显式"**。
`@bitCast` 不再帮你猜布局，`@typeInfo` 不再给你一个混杂的结构体数组，
`main` 不再从全局拿参数——凡是需要"解释一下这是什么"的地方，都要求你先说明。

---

## 0.2 语言层：被移除的语法

### 0.2.1 `**` 运算符已移除

0.16 之前，`**` 是"编译期重复"运算符：

```zig
const a = [_]u32{ 1, 2, 3 } ** 2;   // 0.16：[6 个元素]
const s = "ab" ** 3;               // 0.16：编译期算出的 6 长度字符串
```

0.17 里它**没了**。而且报错信息极具误导性：

```
error: binary operator '*' has whitespace on one side, but not the other
```

因为 `**` 现在被**词法分析**成两个 `*`，于是报的是"空格位置不对"。
看到这条错误，第一反应应该是"我是不是写了 `**`"。

替代方案有两个：

```zig
// (a) 数组重复 → @splat（但它要求元素相同）
var buf: [100]u64 = @splat(0);

// (b) 需要「把某个值重复 n 份」→ 写个 comptime 函数，这是更通用的路子
fn repeat(comptime T: type, comptime n: usize, v: T) [n]T {
    var out: [n]T = undefined;
    for (&out) |*e| e.* = v;
    return out;
}
const s = repeat(u8, 6, 'x');    // [6]u8
const s2 = "ab" ++ "ab" ++ "ab"; // 拼接还在，`++` 没被移除
```

`++` 在 0.17 里**仍然可用**（数组/切片拼接），只有 `**` 走了。
所以"把 3 个 16 字节块拼成一个头"这种场景可以照旧写。

### 0.2.2 `void{}` 已移除

```zig
const b = void{};        // 0.16
const b: void = {};      // 0.17：类型标注必须写出来
```

`void` 在 0.17 不再支持数组初始化语法，所以编译器无法从 `{}` 推断出
你指的是 `void`。写上类型标注就行。

### 0.2.3 枚举转换改了三处名

这是 0.17 里最容易"编译过但结论错"的一类变化——`zig fmt` 会**自动改写**，
你的文件能过 `fmt --check`，但如果没跑 fmt 就会撞上错误信息：

| 0.16 | 0.17 |
|---|---|
| `@intFromEnum(x)` | `@backingInt(x)` |
| `@enumFromInt(n)` | `@fromBackingInt(@intCast(n))` |
| `@intToEnum(x)` | `@enumFromInt(x)` ← 名字被**回收**给了旧功能的对偶 |

注意最后一行：`@enumFromInt` 这个名字在 0.17 里换了含义，
所以照抄旧代码时最容易出现的错误是「用了 `@enumFromInt` 却以为是老写法」——
它现在是**合法**的，但语义不同。

实测：对 0.16 的文件直接跑 `zig fmt`，它会把这三处自动迁移掉：

```console
$ zig fmt main.zig
$ git diff main.zig
-    const lv: Level = @enumFromInt(50);
+    const lv: Level = @fromBackingInt(@intCast(50));
```

所以**迁移的第一步可以直接是 `zig fmt .`**，先让工具改掉机械改名，
剩下的才是真需要动脑的地方。

### 0.2.4 `Optimize` 枚举改名

```zig
builtin.mode == .Debug        // 0.16
builtin.mode == .debug        // 0.17
```

一并改名的还有 `.ReleaseSafe` → `.safe`、`.ReleaseFast` → `.fast`、
`.ReleaseSmall` → `.small`。`zig fmt` **不会**改这个（它是取值不是函数名），
必须手改。02 章就踩过这一条，测试直接报
`no field named 'Debug' in enum 'lang.Optimize'`。

---

## 0.3 内建函数：移除与收紧

### 0.3.1 `@cImport` 已移除 → `b.addTranslateC`

这是 0.17 里**影响面最大**的一条。0.16 的写法是在源码里直接翻译头文件：

```zig
const c = @cImport({
    @cInclude("stdio.h");
});
pub fn main() void {
    _ = c.printf("hello\n", .{});
}
```

0.17 里 `@cImport` 不存在了。头文件翻译改由**构建系统**发起：

```zig
// build.zig
const tc = b.addTranslateC(.{
    .root_source_file = b.path("include/ci.h"),
    .target = target,
    .optimize = optimize,
    .link_libc = true,
});
const ci_module = tc.createModule();          // 私有模块：只给本工程用

const main_mod = b.createModule(.{
    .root_source_file = b.path("src/main.zig"),
    .target = target, .optimize = optimize, .link_libc = true,
    .imports = &.{ .{ .name = "ci", .module = ci_module } },
});
// Zig 要调 C → 把 C 源码也挂进来
main_mod.addCSourceFiles(.{
    .root = b.path("csrc"), .files = &.{"ci.c"}, .flags = &.{ "-I", "include" },
});
```

```zig
// src/main.zig
const ci = @import("ci");                       // 翻译产物当普通模块 import
extern fn ci_strlen(s: [*:0]const u8) callconv(.c) usize;
```

三个连带变化，一并记住：

1. **`callconv(.C)` 改名 `callconv(.c)`**（小写）。旧写法报
   `union 'lang.CallingConvention' has no member named 'C'`。
2. **`b.args` 已移除**。以前 `b.addRunArtifact(exe)` 会自动透传命令行参数，
   现在必须显式：`run_cmd.addPassthruArgs();`
3. **`build.zig.zon` 要写 `.minimum_zig_version = "0.17.0"`**。

完整可运行的工程见 [17 章](17-c-interop.md)。

### 0.3.2 `@bitCast` 不再接受裸结构体

```zig
const Pair = extern struct { a: u32, b: u32 };
const v = @as(u64, @bitCast(p));   // 0.17 编译不过
// error: cannot @bitCast from 'main.Pair'
```

**连 `extern struct` 也不行**——0.17 的原则是"布局要有定义，且由你说明"。

正确写法是显式走字节，顺便把端序也写出来（这本来就是二进制协议该做的事）：

```zig
const raw = std.mem.asBytes(&p);                          // *[8]u8，长度 = sizeof(Pair)
const v = std.mem.readInt(u64, raw[0..8], .little);
```

注意 `asBytes` 给的是**指针**，长度就是 `sizeof(T)`，不能再往右切。
（想切右边就得先把整个结构体按值取地址后用 `@sizeOf` 算清楚。）

### 0.3.3 `@typeInfo` 结构重写

0.16 里反射一个结构体：

```zig
const fields = @typeInfo(T).@"struct".fields;   // 0.16：[]StructField
for (fields) |f| std.debug.print("{s}\n", .{f.name});
```

0.17 改成**三条平行数组**：

```zig
const s = @typeInfo(T).@"struct";
// field_names: []const [:0]const u8
// field_types: []const Type
// field_attrs: []const StructFieldAttr  —— 长度保证一致，按下标配对
inline for (s.field_names, s.field_types) |name, ty| {
    std.debug.print("  {s}: {s}\n", .{ name, @typeName(ty) });
}
```

错误集也改了名字和元素类型：

```zig
// 0.16：[]const { name: [:0]const u8, value: anyerror }
const names = @typeInfo(MyError).error_set.?.names;
// 0.17：[]const [:0]const u8 —— 元素本身就是名字
const names = @typeInfo(MyError).error_set.error_names;
for (names) |n| std.debug.print(" {s}", .{n});   // 注意不是 n.name
```

这条改动很容易被忽略，因为它只在"拿错误集名字做反射"时才触发，
编译期一路绿灯，运行起来才崩或行为异常。14 章和 09 章都做了完整演示。

### 0.3.4 `std.meta` 已废弃

```zig
std.meta.fields(T)   // 0.17 → @compileError("deprecated in favor of @typeInfo")
```

替代就是上一节的 `@typeInfo(T).@"struct".field_names`。
25 章里那句 comptime 布局断言就是从 `std.meta.fields` 迁过来的。

---

## 0.4 标准库重构

### 0.4.1 `std.heap.stackFallback` → `BufferFirstAllocator`

```zig
// 0.16
const a = std.heap.stackFallback(allocator, &stack_buf);
// 0.17
var fb = std.heap.BufferFirstAllocator.init(&stack_buf, fallback_allocator);
const a = fb.allocator();
```

语义完全一致：先试栈上缓冲，容纳不下自动落到底层分配器。
只是从"返回一个接口值"变成了"返回一个持有者结构体"。

### 0.4.2 Juicy Main：`main` 现在能拿到参数和 Io

0.17 的入口签名可以带一个初始化结构体：

```zig
pub fn main(init: std.process.Init) !void {
    const io = init.io;                  // I/O 事件循环（下面所有 API 都要传它）
    const gpa = init.gpa;                // 通用分配器
    const arena = init.arena.allocator(); // 一次性的区域分配器
    const args = init.minimal.args;      // argv
    const env = init.environ_map;        // 环境变量
}
```

这是 0.17 最漂亮的一处设计：**分配器和事件循环从全局变成了显式参数**。
以前 `std.debug.print`、`std.fs` 那些"到处都能用"的全局状态，
现在都要你先拿到 `init.io` 再传下去。

它和"无隐藏全局状态"的哲学是一脉相承的：以前是**藏在 std 里**，
现在是**显式握在你手里**，并且能被测试替换。

---

## 0.5 `std.Io.net`：网络接口整体换血

0.16 里 TCP/UDP 仍要手写 socket 逻辑（或绕到平台 API）。
0.17 里网络正式进入 `std.Io` 体系：

```zig
// 服务端
const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 8080);
const server = try addr.listen(io, .{ .reuse_address = true });
const stream = try server.accept(io);

// 客户端
const stream = try addr.connect(io, .{ .mode = .stream });

// 收发：一律走 Reader / Writer，缓冲由调用方提供
var rbuf: [4096]u8 = undefined;
var r = stream.reader(io, &rbuf);
var wbuf: [4096]u8 = undefined;
var w = stream.writer(io, &wbuf);
```

### 0.5.1 三个实测坑（都写进了 29/30/34 章）

**坑一：0.17.0 标准库自己有个编译不过的地方。**

```zig
const r = try stream.read(io, &bufs);   // 类型 Io.net.Stream.ReadResult
// 0.17.0 实测：lib/std/Io/net.zig:1286
// error: type 'Io.net.Stream.ReadResult' cannot be destructured
```

这不是你写错了，是发行版里的标准库有 bug。绕开它：用
`stream.reader(io, buf)` + 下面的 `fillMore` 组合。

**坑二：`readSliceShort` 不是 recv。**

它的语义是"**填满缓冲或读到 EOF**"，拿它当单次 recv 会让服务端
在等满缓冲区时挂死。正确姿势是三件套：

```zig
r.interface.fillMore() catch |err| switch (err) {
    error.EndOfStream => return 0,      // 对端关闭
    error.ReadFailed  => return 0,
};
const avail = r.interface.buffered();   // 已就绪的字节
const n = @min(buf.len, avail.len);
@memcpy(buf[0..n], avail[0..n]);
r.interface.toss(n);                     // 丢弃已取走的部分
```

**坑三：`takeDelimiterExclusive` 不阻塞。**

写行协议时最自然会想到它，但：

```zig
const line = try r.interface.takeDelimiterExclusive('\n');
```

它只查**已经缓冲在手里的字节**；手上没有 `'\n'` 就**立刻返回空片**、
不做底层读。症状是服务端陷入「读到空行 → 写 OK → 再读到空行」的死循环，
日志里 `serve got:` 后面刷屏一片空行。

行协议要自己写：

```zig
pub fn recvLine(self: *Conn, buf: []u8) ![]u8 {
    var scanned: usize = 0;              // 已扫过但不属于本行的字节数
    while (true) {
        const avail = self.r.interface.buffered();
        if (std.mem.indexOfScalarPos(u8, avail, scanned, '\n')) |at| {
            const line = avail[scanned..at];
            self.r.interface.toss(at + 1); // 连 '\n' 一起吃掉
            if (line.len > buf.len) return error.LineTooLong;
            @memcpy(buf[0..line.len], line);
            return buf[0..line.len];
        }
        scanned = avail.len;
        if (scanned > buf.len) return error.LineTooLong;
        self.r.interface.fillMore() catch |err| switch (err) {
            error.EndOfStream => return error.ConnectionClosed,
            error.ReadFailed  => return error.ReadFailed,
        };
    }
}
```

### 0.5.2 自引用结构体不能按值拷贝（三个坑叠在一起）

把 Reader/Writer 和它们的缓冲放同一个结构体里，很自然：

```zig
pub const Conn = struct {
    rbuf: [4096]u8 = undefined,
    r: std.Io.net.Stream.Reader,
    wbuf: [4096]u8 = undefined,
    w: std.Io.net.Stream.Writer,

    pub fn init(io: std.Io, stream: std.Io.net.Stream) Conn {
        var self = Conn{ .stream = stream, /* ... */ };
        self.r = stream.reader(io, &self.rbuf);   // ⚠️ 绑到的是 init 的栈帧！
        self.w = stream.writer(io, &self.wbuf);
        return self;                              // ⚠️ 值拷贝，Reader 变悬垂
    }
};
```

**这段代码编译通过、小报文也能跑**，但 `self.r` 里的缓冲区指针
指向的是 `init` 函数栈帧上的那个临时 `self`。`return self` 一拷贝，
那个帧就没了——症状是「小包偶尔对、缓冲区一大就乱序或直接读到脏数据」，
极其难查。

34 章最初就是死在这里：第一幕第一轮对、第二轮读到空行。
正确写法是**懒绑定**，值拷贝多少次都指向最终那份字段：

```zig
    bound: bool = false,

    fn ensureBound(self: *Conn) void {
        if (self.bound) return;
        self.r = self.stream.reader(self.io, &self.rbuf);
        self.w = self.stream.writer(self.io, &self.wbuf);
        self.bound = true;
    },

    pub fn recvSome(self: *Conn, buf: []u8) !usize {
        self.ensureBound();
        // ...
    }
```

配套的还有一条：**`Stream.close` 不是幂等的**。
显式 `close()` 之后又 `defer conn.close()`，第二次会报
`BADF` panic（`Threaded.zig` 里是 `recoverableOsBugDetected`）。
要么全用 `defer`，要么全显式关闭。

### 0.5.3 传给线程的参数不能是 `const`

```zig
var srv = try addr.listen(io, .{});
const th = try std.Thread.spawn(.{}, serve, .{ io, srv });
// error: expected type '*Io.net.Server', found '*const Io.net.Server'
```

`Server.accept` 的接收者是 `*Server`（非 const）。
线程参数**按值传递**不会自动变指针，要手动传 `&srv`，
并把被调函数形参也改成 `*std.Io.net.Server`。

---

## 0.6 迁移检查清单

按这个顺序做，效率最高：

1. **`zig fmt .`** —— 自动改掉 `@intFromEnum`/`@enumFromInt`/`@intToEnum` 三处改名。
2. **全局搜 `Optimize.Debug` / `.ReleaseSafe`** —— 这几个**不会**被自动改。
3. **搜 `**` 作为运算符用**（不是 `**` 出现在注释或 markdown 里）。
   看到报错 `binary operator '*' has whitespace on one side` 就是它。
4. **搜 `void{}`** → 改成 `const x: void = {};`
5. **搜 `@cImport`** → 整章改造成 build.zig 工程（见 17 章）。
6. **搜 `std.meta.`** → 换 `@typeInfo(T).@"struct".field_names`。
7. **搜 `stackFallback`** → 换 `BufferFirstAllocator`。
8. **搜 `b.args`** → 换 `run_cmd.addPassthruArgs()`。
9. **搜 `callconv(.C)`** → 换 `callconv(.c)`。
10. **搜 `@bitCast(...结构体...)`** → 换 `asBytes` + `readInt`。
11. **`main` 改成 `pub fn main(init: std.process.Init) !void`**，
    里面原来用 `std.fs` / 网络的地方逐个补 `init.io` 参数。
12. **`zig build.zig.zon` 加 `.minimum_zig_version = "0.17.0"`**。
13. **最后跑一遍完整验证**：`./run-all.sh`（Linux/macOS）
    或 `pwsh -Command '& ./build.ps1 -All'`（Windows）。
    三层验证（fmt + test + 运行）能兜住绝大多数迁移遗漏。

---

## 0.7 坑位清单

1. `**` 运算符已移除，报错信息却是 `binary operator '*' has whitespace on one side`
   ——词法分析把 `**` 拆成两个 `*`，别被误导去查空格。
2. 数组重复用 `@splat`；需要"重复任意值"必须自己写 comptime 函数。`++` 拼接**没有**被移除。
3. `void{}` 编译不过，必须写类型标注 `const b: void = {};`。
4. `@intFromEnum` → `@backingInt`；`@enumFromInt` → `@fromBackingInt(@intCast(n))`；
   `@intToEnum` → `@enumFromInt`（**名字被回收，语义不同**）。前两者 `zig fmt` 会自动改。
5. `builtin.mode == .Debug` 不会被 fmt 改，要手写 `.debug`；`.ReleaseSafe` → `.safe`。
6. `@cImport` 已移除，`@cInclude` 也随之失去意义；头文件翻译必须走 `b.addTranslateC`，
   且翻译产物要用 `tc.createModule()` + `module.imports` 接进来。
7. `callconv(.C)` 改名成小写 `.c`。
8. `b.args` 已移除，run artifact 要显式 `addPassthruArgs()`。
9. `@bitCast` 拒绝裸结构体，**`extern struct` 也不行**；改用 `asBytes` + `readInt`，
   并显式写端序。`asBytes` 返回 `*[N]u8`，长度就是 `sizeof(T)`，切不出 `[8..16]`。
10. `@typeInfo(T).@"struct".fields` 没了，改成 `field_names`/`field_types`/`field_attrs`
    三条平行数组；`.error_set` 改 `.error_names`，元素从结构体变成字符串。
11. `std.meta.fields` 直接 `@compileError`，全走 `@typeInfo`。
12. `std.heap.stackFallback` → `BufferFirstAllocator.init(&buf, fallback).allocator()`。
13. `main` 的新签名 `pub fn main(init: std.process.Init) !void` 提供
    `init.io`/`init.gpa`/`init.arena`/`init.minimal.args`/`init.environ_map`。
14. `std.Io.net`：`IpAddress.listen(io,opts)` / `connect(io,opts)`；收发走
    `stream.reader(io,buf)` / `writer(io,buf)`。
15. **0.17.0 标准库自身有 bug**：`Stream.read(io, [][]u8)` 在 `Io/net.zig:1286` 编译不过
    （`ReadResult` 无法解构），绕开它。
16. `readSliceShort` 是"填满或 EOF"语义，当 recv 用会让服务端挂死；
    用 `fillMore()` + `buffered()` + `toss()`。
17. **`takeDelimiterExclusive` 不阻塞**：手上没分隔符就立刻返回空片，
    行协议死循环刷空行。必须自己 `fillMore()` + `indexOfScalarPos` + `toss()`。
18. 自引用结构体（Reader 指向自己的缓冲字段）**不能按值拷贝**：
    在 `init` 里绑定 `stream.reader(io,&self.rbuf)` 会产生悬垂指针，
    症状是"小包偶尔对、大包就乱"。改懒绑定。
19. `Stream.close` **不是幂等的**：显式 close 后再 `defer close` 会 `BADF` panic。
20. `Server.accept` 接收者是 `*Server`，传给 `std.Thread.spawn` 的参数要写 `&srv`，
    被调函数形参也必须是 `*std.Io.net.Server`（`const` 不收）。

---

**上一章**：[无](#)（本教程的迁移附录，从 [01 全景](01-overview.md) 开始）
**下一章**：[01 · 全景：Zig 的设计哲学与工具链](01-overview.md)