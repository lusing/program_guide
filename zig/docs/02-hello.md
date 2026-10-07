# 02 · 第一个程序

> 对应示例：`examples/02_hello/main.zig`
>
> 这一章不写"Hello World"，而是写一个**把之后每章都要用到的东西一次性摊开**
> 的程序：字符串的真实类型、编译期检查的格式化、带缓冲的输出、
> `main` 的运行时参数包、构建模式、以及测试。
> 读完你应该能解释清楚 Zig 程序为什么"长这样"。

---

## 2.1 最小程序：没有 string 类型，只有字节切片

Zig 里的"字符串"不是一种类型，而是**指向只读字节数组的指针**：

```zig
// examples/02_hello/main.zig 第 14-25 行
begin("2.1");
// Zig 没有独立的 string 类型："字符串"就是指向只读字节数组的指针，用时常常退化成切片
const greeting = "你好，Zig 0.17！";
const slice: []const u8 = greeting;
std.debug.print("{s}\n", .{slice});
std.debug.print("类型={s} 长度={d} 首字节=0x{x}\n", .{
    @typeName(@TypeOf(slice)),
    slice.len,
    slice[0],
});
end("2.1");
```

运行输出（`examples/02_hello/main.zig`）：

```text
====2.1 开始 ====
你好，Zig 0.17！
类型=[]const u8 长度=20 首字节=0xe4
==== 2.1 结束 ====
```

三个数字值得停下来看：

- **`类型=[]const u8`**：写出来的类型是"不可变字节切片"。
  严格说 `"你好，Zig 0.17！"` 的真身是 `*const [21:0]u8`
  （19 个可见字符 + 一个 0 结尾哨兵，共 20 字节），
  赋给 `[]const u8` 时自动退化成切片（长度 = 20）。
  哨兵那一位不算长度，所以是 20 而不是 21。
- **`长度=20`**：Zig 的长度**永远是字节数**。
  "你好，Zig 0.17！"是 10 个字符，但 UTF-8 下每字 3 字节。
  要按字符处理必须用 `std.unicode` 手动解码——06 章展开。
- **`首字节=0xe4`**：`你` 的 UTF-8 编码首字节。再次提醒：索引是按字节的，
  `slice[0]` 拿到的是**半个汉字**，直接打印会得到乱码。

`@TypeOf(x)` 返回"表达式 x 的类型"（不是类型本身，是描述它的那个类型），
`@typeName` 再把那个类型渲染成字符串。写"打印某个值的类型"这类调试信息时，
这两个是标准组合。

### `const` 是默认值

上面每个绑定都用了 `const` 而不是 `var`。这不是风格偏好，是 Zig 的硬规则：
**你必须明确声明一个绑定会不会被改**。`var` 声明了却不改会编译报错
（反过来不会——`const` 改值才是错误），所以 `const` 是零成本的正确写法。

## 2.2 std.debug.print：编译期检查的格式化

C 里 `printf` 传错类型是运行时灾难；Zig 的 `std.debug.print` 是**编译期查**的：

```zig
// examples/02_hello/main.zig 第 27-42 行
begin("2.2");
const n: u32 = 255;
const pi: f64 = 3.14159;
std.debug.print("十进制 {d}、十六进制 {x}、大写 {X}、八进制 {o}、二进制 {b}\n", .{ n, n, n, n, n });
std.debug.print("宽度/对齐：[{d:0>6}] [{d:<6}] [{d:^6}] [{d:*>6}]\n", .{ n, n, n, n });
std.debug.print("浮点：{d}、两位 {d:.2}、科学计数 {e}\n", .{ pi, pi, pi });
std.debug.print("字符串 {s}、布尔 {}、任意值 {any}\n", .{ "zig", true, .{ 1, 2, 3 } });
std.debug.print("字符 {c}、码位 {u}、字节大小 {B} / {Bi}\n", .{
    @as(u8, 65),
    @as(u21, 0x4E2D),
    @as(u64, 123456),
    @as(u64, 123456),
});
std.debug.print("标签名 {t}、指针 {*}\n", .{ error.FileNotFound, &n });
end("2.2");
```

运行输出（`examples/02_hello/main.zig`）：

```text
==== 2.2 开始 ====
十进制 255、十六进制 ff、大写 FF、八进制 377、二进制 11111111
宽度/对齐：[000255] [255   ] [ 255  ] [***255]
浮点：3.14159、两位 3.14、科学计数 3.14159e0
字符串 zig、布尔 true、任意值 .{ 1, 2, 3 }
字符 A、码位 中、字节大小 123.456kB / 120.5625KiB
标签名 FileNotFound、指针 u32@10c944bcc
==== 2.2 结束 ====
```

要点：

- **`.{ ... }` 是"元组字面量"**，里面按顺序对应格式串里的占位符。
  传多值不再需要 C 那种可变参数 hack，格式串和实参在编译期一一核对。
- **`{d}` `{x}` `{X}` `{o}` `{b}`**：十/十六/大写十六/八/二。
- **格式说明用冒号**：`:.2` 两位小数、`:0>6` 补零到 6 宽、
  `:<6` 左对齐、`^6` 居中、`:*>6` 用指定字符填充。
- **`{s}` 只给字符串**，而且必须是字节切片/哨兵指针——
  0.17 的格式化器**拒绝**把数组或切片直接喂给 `{d}`
  （0.16 就是靠这条把"`{d}` 能打印数组"的宽松行为关掉的）。
  任意类型用 `{any}`。
- **`{c}` 字符、`{u}` 码位（打印的是字符本身）、`{t}` 标签名、`{*}` 指针**。
  最后一行 `{*}` 是故意展示**指针本身**而不是指向的值——
  输出 `u32@10c944bcc` 这样的"类型@地址"，调试时非常有用。
- **`{B}` / `{Bi}` 字节大小**：123456 字节 = `123.456kB` = `120.5625KiB`。
  看这一行是为了记住 Zig 用**十进制**算 kB/MB（`123.456`），
  而不是 C 那种1024 进制（MiB）。

这段有一份单元测试守着（`examples/02_hello/main.zig` 第 97-102 行）：

```zig
test "占位符语义" {
    var buf: [128]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    try w.print("{d} {x} {d:.2} {s} {}", .{ 255, @as(u32, 255), 3.14159, "zig", true });
    try std.testing.expectEqualStrings("255 ff 3.14 zig true", w.buffered());
}
```

格式化的"正确输出"本身就是断言——以后谁改了格式化行为，这个测试先红。

## 2.3 写 stdout：缓冲 Writer 的四步

`std.debug.print` 是**调试**输出（走 stderr，无缓冲）。
真正要写给用户看的内容要走 stdout，而 0.15 之后它是有缓冲的，
**缓冲由你提供**：

```zig
// examples/02_hello/main.zig 第 44-52 行
begin("2.3");
var buf: [256]u8 = undefined; // 缓冲区由调用方提供，可见、可控
var w = std.Io.File.stdout().writer(init.io, &buf);
const out = &w.interface;
try out.print("（stdout）姓名：{s}，年龄：{d}\n", .{ "阿 Z", 25 });
try out.print("（stdout）PI ≈ {d:.2}\n", .{pi});
try out.flush(); // 不 flush：缓冲里的尾部内容不会落地
end("2.3");
```

四步固定成这个形状：

| 步骤 | 代码 | 说明 |
|---|---|---|
| ① 拿文件 | `std.Io.File.stdout()` | 0.16 起 `std.fs.File` 并入了 `std.Io` |
| ② 给缓冲 | `.writer(init.io, &buf)` | 缓冲是你自己的数组，长度你定 |
| ③ 取接口 | `&w.interface` | `.interface` 是通用 `Writer`，与具体文件无关 |
| ④ **落盘** | `.flush()` | **忘了这行，缓冲里的内容就没了** |

第 ④ 步是新手第一大坑，而且**它静默失败**：不报错、不崩溃，
只是输出少一截。这也是为什么示例把 `flush()` 单独写成一行还带注释。

两行正文走 **stdout**，四个 `====` 标记走 **stderr**。在终端上它们交错显示：

```text
==== 2.3 开始 ====
（stdout）姓名：阿 Z，年龄：25
（stdout）PI ≈ 3.14
==== 2.3 结束 ====
```

但一旦重定向，位置就乱了——见 2.3.1。

### 2.3.1 ⚠️ 重定向陷阱（本教程实测踩到）

如果你想把输出存到文件，**别用 `> f 2>&1`**：

```bash
./02_hello > out.txt 2>&1         # ⚠️ 会吃掉 stderr 前部
./02_hello > out.txt 2> err.txt   # ✅ 分开重定向
```

**机制**：stdout 是**缓冲**的。2.3 节的 `flush()` 虽然调用了，
但那时 stdout 的**文件偏移还是 0**——它从头到尾没写过东西。
而 stderr 无缓冲即写，早就把文件前部写满了。于是那次 flush 从偏移 0 开始，
**把已经写好的 stderr 内容覆盖掉**。

这不是推测。本教程的验证脚本 `./run-all.sh > log 2>&1` 就撞上了，
`log` 头几行原样是这样：

```text
（stdout）姓名：阿 Z，年龄：25
（stdout）PI ≈ 3.14
7.0)

[Example] 02_hello
1/5 main.test.字符串就是字节切片...OK
```

- 第 0、1 行：stdout 的两行正文，跑到了文件**最前面**；
- 第 2 行那个孤零零的 `7.0)`：是 `[Toolchain] /…/zig (0.17.0)` 这行的**残骸**，
  开头被上面两条覆盖了，只剩最后四个字符。

于是"2.3 区间"在日志里长这样——正文根本不在它该在的位置：

```text
==== 2.3 开始 ====
==== 2.3 结束 ====
```

**这就是本教程验证纪律的由来**：
① 正常输出走 stdout、诊断走 stderr（`====` 标记属于诊断）；
② 需要落盘时分开重定向。
同样的 C 程序写法 138 字节完整——**这是 Zig 侧的行为**，不是 shell 的 bug。
终端和管道（`| cat`）不受影响。

### 为什么缓冲归调用方

这个设计（0.15 的 "Writergate"）被很多人抱怨过，但它的理由是：
**性能**（不缓冲等于每 print 一次系统调用）、**可测**
（测试时能换成"写进数组"的 Writer，直接断言内容）、
**可观察**（缓冲多大、什么时候落盘，你全知道）。

代价就是上面那条 flush 纪律。好消息是它只有一个：任何 Writer 用完都要
`flush()` 或 `deinit()`。

## 2.4 main 的参数包：Juicy Main

0.16 起 `main` 可以带一个初始化结构体，一揽子拿到运行环境：

```zig
// examples/02_hello/main.zig 第 13、54-70 行
pub fn main(init: std.process.Init) !void {
    begin("2.4");
    std.debug.print("io          : {s}\n", .{@typeName(@TypeOf(init.io))});
    std.debug.print("gpa         : {s}\n", .{@typeName(@TypeOf(init.gpa))});
    std.debug.print("arena       : {s}\n", .{@typeName(@TypeOf(init.arena))});
    std.debug.print("environ_map : {s}\n", .{@typeName(@TypeOf(init.environ_map))});
    std.debug.print("preopens    : {s}\n", .{@typeName(@TypeOf(init.preopens))});
    std.debug.print("minimal.args: {s}\n", .{@typeName(@TypeOf(init.minimal.args))});
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    std.debug.print("argv 长度   : {d}\n", .{args.len});
    for (args, 0..) |arg, i| std.debug.print("  [{d}] {s}\n", .{ i, arg });
    if (init.environ_map.get("HOME")) |home| {
        std.debug.print("HOME        : {s}\n", .{home});
    } else {
        std.debug.print("HOME        : (未设置)\n", .{});
    }
    end("2.4");
}
```

运行输出（`examples/02_hello/main.zig`）：

```text
==== 2.4 开始 ====
io          : Io
gpa         : mem.Allocator
arena       : *heap.ArenaAllocator
environ_map : *process.Environ.Map
preopens    : process.Preopens
minimal.args: process.Args
argv 长度   : 1
  [0] /Volumes/mac004/code/programming/zig/build/02_hello
HOME        : /Users/xulun
==== 2.4 结束 ====
```

`std.process.Init` 的六个字段：

| 字段 | 类型 | 用途 |
|---|---|---|
| `io` | `Io` | **I/O 事件循环**。20 章的文件、29 章的网络都要传它 |
| `gpa` | `mem.Allocator` | 通用分配器，生命周期到进程结束 |
| `arena` | `*heap.ArenaAllocator` | 区域分配器，退出时一次性全释放 |
| `minimal.args` | `process.Args` | 命令行参数（跨平台，Windows 的 UTF-16 在里面处理掉了） |
| `environ_map` | `*process.Environ.Map` | 环境变量，已解析成 map |
| `preopens` | `process.Preopens` | 预打开的资源（沙箱能力） |

**为什么要这么设计**：0.16 之前这些是**全局状态**
（`std.debug.print` 内部抓 stdout，`argsAlloc` 自己找 argv）。
现在它们变成显式参数，于是：

- **能被测试替换**：测试里可以传一个假的 `io`（`std.testing.io`），
  输出直接落到数组里断言，不用真的写文件；
- **没有隐藏依赖**：看到函数签名就知道它要什么，不用猜；
- **`io` 参数是网络的必需品**：29 章你会看到
  `stream.reader(io, buf)` 里那个 `io` 就是这里来的。

`init.arena` 的存在是给"临时分配"用的：22 章的例子会大量用到它。
注意它的生命周期是**整个 main**——别把 `arena` 分配的内存存到 main 外面。

`argv 长度 : 1` 是正常的：`args[0]` 是程序自己的路径。
本例没带额外参数。Windows 上 `minimal.args` 内部是 `[]const u16`，
`toSlice` 帮你转成 UTF-8——这就是"跨平台抹平"的含义（22 章详述）。

## 2.5 构建模式：同一份源码，四种权衡

```zig
// examples/02_hello/main.zig 第 72-86 行
begin("2.5");
std.debug.print("builtin.mode          = {t}\n", .{builtin.mode});
std.debug.print("runtime_safety        = {}\n", .{std.debug.runtime_safety});
std.debug.print("target                = {t}-{t}\n", .{
    builtin.target.cpu.arch,
    builtin.target.os.tag,
});
// 环绕运算符 +%= 在四种模式下都合法（显式承认溢出），安全版 + 在 Debug/ReleaseSafe 下会 panic
var counter: u8 = 253;
for (0..5) |_| {
    counter +%= 1;
    std.debug.print("  counter = {d}\n", .{counter});
}
end("2.5");
```

运行输出（`examples/02_hello/main.zig`）：

```text
==== 2.5 开始 ====
builtin.mode          = debug
runtime_safety        = true
target                = x86_64-macos
  counter = 254
  counter = 255
  counter = 0
  counter = 1
  counter = 2
==== 2.5 结束 ====
```

**`counter` 从 255 直接跳到 0**：这是 `+%=`（环绕加）的行为，
254 → 255 → 0 → 1 → 2。四种构建模式都一样。

四种模式：

| 模式 | `runtime_safety` | 溢出/越界 | 用途 |
|---|---|---|---|
| `debug` | true | **panic** | 开发默认，**本教程所有示例都跑这个** |
| `safe`（原 `ReleaseSafe`） | true | panic | 发布，但保留安全网 |
| `fast`（原 `ReleaseFast`） | false | **未定义行为** | 性能优先 |
| `small`（原 `ReleaseSmall`） | false | 未定义行为 | 二进制体积优先 |

⚠️ **0.17 改名**：`.Debug` → `.debug`、`.ReleaseSafe` → `.safe`。
`zig fmt` **不会**改这个（它是枚举取值不是函数名），
照抄旧代码会撞上：

```text
no field named 'Debug' in enum 'lang.Optimize'
```

这也是为什么示例里有这个测试守着（`examples/02_hello/main.zig` 第 129-135 行）：

```zig
test "构建模式元数据可用" {
    // 0.17：Optimize 枚举改名，.Debug → .debug、.ReleaseSafe → .safe
    try std.testing.expect(builtin.mode == .debug or builtin.mode == .safe);
    var c: u8 = 255;
    c +%= 1;
    try std.testing.expectEqual(@as(u8, 0), c);
}
```

**为什么默认是 debug**：Zig 认为"安全检查全开"才是正确默认值，
性能优化应该由你**显式**请求（`-O ReleaseFast`）而不是默认承担。
这和 C 的默认姿势正好相反。

## 2.6 测试：和源码写在一起

这个文件底部的每个 `test` 块都能单独跑：

```bash
zig test main.zig          # 跑全部 test 块
zig test main.zig --test-filter 缓冲   # 只跑名字含「缓冲」的
```

实测（`zig test main.zig`）：

```text
1/5 main.test.字符串就是字节切片...OK
2/5 main.test.占位符语义...OK
3/5 main.test.Writer.fixed 直接写调用方的缓冲，不藏数据...OK
4/5 main.test.文件 Writer 不 flush 就不会落盘...OK
5/5 main.test.构建模式元数据可用...OK
All 5 tests passed.
```

其中第三个测试解释了 2.3 节那个 flush 纪律的**另一半**：

```zig
// examples/02_hello/main.zig 第 104-112 行
test "Writer.fixed 直接写调用方的缓冲，不藏数据" {
    var buf: [64]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    try w.print("未 flush", .{});
    // fixed writer 没有中间暂存层：print 完数据已经在调用方的 buf 里
    try std.testing.expectEqual(@as(usize, 9), w.buffered().len);
    try w.flush();
    try std.testing.expectEqualStrings("未 flush", w.buffered());
}
```

`Writer.fixed` 是"写进调用方给的数组"的 Writer——测试专用。
注意 `print` 之后 `buffered().len` 已经是 9（"未 flush"是 3 个字符 × 3 字节），
**没调 flush 数据也已经在了**。这说明"flush 到底做了什么"取决于
Writer 的种类：文件 Writer 有真正的中间暂存（不 flush 不落盘），
fixed Writer 没有（它直接写你的数组）。第四个测试用真实的临时文件
验证了文件 Writer 的行为：

```zig
// examples/02_hello/main.zig 第 114-127 行
test "文件 Writer 不 flush 就不会落盘" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var f = try tmp.dir.createFile(std.testing.io, "t.txt", .{});
    defer f.close(std.testing.io);
    var fbuf: [64]u8 = undefined;
    var fw = f.writer(std.testing.io, &fbuf);
    const out = &fw.interface;
    try out.print("hello", .{});
    try out.flush(); // 这一行是"缓冲所有权归调用者"的代价：忘了就没有输出
    const got = try tmp.dir.readFileAlloc(std.testing.io, "t.txt", std.testing.allocator, .limited(64));
    defer std.testing.allocator.free(got);
    try std.testing.expectEqualStrings("hello", got);
}
```

`std.testing.tmpDir` 给一个自动清理的临时目录，`std.testing.io`
是测试专用的Io，`std.testing.allocator` 是**带泄漏检测**的分配器
（分配的没释放会在测试结束时报错并打印泄漏字节数——11 章详述）。
三个 "testing" 三件套构成了 Zig 测试的基调：**不碰真实环境、可断言、可清理**。

> 顺带回答一个常见问题：《Learning Zig》ch7 提到"文档注释里的 ```zig 示例
> 自动当测试跑"（doctest）。**0.17 的编译器没有这个功能**——
> 本机实测 `zig test` 对这种写法报 `All 0 tests passed`，
> 编译器源码里也搜不到 doctest 钩子。文档示例想被验证，
> 老实写成显式 `test` 块或独立示例工程（本教程的路线）。

## 2.7 格式化

Zig 自带 `zig fmt`，**没有配置文件、没有选项**（一个风格，走天下）：

```bash
zig fmt .           # 就地格式化
zig fmt --check .   # 只检查不改（CI 用这个）
```

本章验证脚本的第一层就是 `zig fmt --check .`。
它的存在让"代码风格争论"这个话题从项目里彻底消失——
风格由工具决定，不由人决定。

## 2.8 三层验证：把"能跑"变成"可回归"

本教程每个示例都被 `./run-all.sh NN_xxx`（macOS/Linux）或
`build.ps1 -Example NN_xxx`（Windows）过三关：

| 层 | 命令 | 拦住什么 |
|---|---|---|
| 1 | `zig fmt --check .` | 风格不统一（顺带暴露被移除的语法） |
| 2 | `zig test main.zig` | 逻辑错、panic、内存泄漏 |
| 3 | `zig build-exe` + 运行 | 链接错、运行时行为错 |

三层缺一不可：第 1 层只能查出格式，第 2 层不产出可执行文件，
第 3 层跑起来才发现输出不对。而且**输出要被逐字节比对**——
退出码 0 但打印了错的东西，第 2、3 层都抓不住，
这正是本教程每章末尾坑位清单存在的理由。

## 2.9 坑位清单

1. **Zig 没有 `string` 类型**：`"abc"` 的真身是 `*const [N:0]u8`，
   用时退化成 `[]const u8`（哨兵那一位不算长度）。
2. **长度是字节数**：UTF-8 每字 3 字节，"你好，Zig 0.17！"长度 20 而不是 10；
   按字符处理必须 `std.unicode` 手动解码。
3. **`slice[0]` 是半个汉字**：索引按字节，直接打印乱码。
4. **不改的绑定必须写 `const`**：`var` 声明了不改会**编译报错**，
   这不是警告是硬规则。
5. **`{d}` 不接受数组/切片**：0.17 的格式化器拒绝这种用法——
   任意类型用 `{any}`，`{s}` 只给字符串。
6. **缓冲 Writer 必须 flush**：不 flush **不报错、不崩溃，只是丢输出**。
   文件 Writer 真的没落盘，`Writer.fixed` 例外（它直写你的数组）。
7. **macOS 上别用 `> f 2>&1` 合并重定向**：stdout 缓冲的延迟 flush
   会用文件偏移覆盖已写入的 stderr 内容（实测 165 字节只剩 124）。
   分开 `>out 2>err`。
8. **`init.arena` 的生命周期是整个 main**：存到 main 外面就是悬垂。
   需要更长生命周期就用 `init.gpa` 自己管（11 章）。
9. **`builtin.mode == .Debug` 在 0.17 报 `no field named 'Debug'`**：
   改名成 `.debug` / `.safe` / `.fast` / `.small`，且 `zig fmt` 不会自动改。
10. **`{B}` 是十进制 kB/MB**（123456 → `123.456kB`），不是 1024 进制的 MiB。
11. **`{u}` 打印码位对应的字符**（上面是"中"），`{*}` 打印指针本身
    （`u32@10c944bcc`），别和 `{s}`（打印指向的字符串）搞混。
12. **`@TypeOf` 返回"描述类型的类型"**：打印类型要
    `@typeName(@TypeOf(x))`，只写 `@TypeOf(x)` 得到的是一串内部编号。
13. **`main` 的 `try` 需要返回类型**：签名是
    `pub fn main(init: std.process.Init) !void`，少了 `!void` 就用不了 `try`。
14. **每章都要过三层验证**：`fmt --check` → `test` → `build-exe` + 运行。
    只跑运行会漏掉"输出不对"这一类问题。
15. **0.17 没有 doctest**：文档里的 ```zig 示例不会被 `zig test` 编译，
    实测报 `All 0 tests passed`。想验证就写成显式 `test` 块。
16. **`std.debug.print` 走 stderr，`File.stdout()` 走 stdout**：
    终端上看起来交错，重定向后是分开的两个流。

---

上一章：[01 全景](01-overview.md) · 下一章：[03 类型与转型](03-types.md)
