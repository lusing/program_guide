# 42 · 实战：JSON 系统监控服务

> **阅读位置**：第六篇 · 综合实战（7/10） ｜ **承前**：[20 文件](20-files-io.md)、[14 反射/JSON](14-generics.md)、[30 HTTP](30-http.md) ｜ **启后**：[45 Web 服务](45-websrv.md) 把 HTTP 往返扩成完整路由服务。
>
> 对应示例：`examples/42_memsrv/main.zig`（474 行，7 个测试）
>
> 取材 Tsoukalos ch6（memInfo + memServer/memClient：内存监控 + JSON HTTP 服务），
> 升级到 0.17。ch6 的代码跑在 Linux 上（读 `/proc/meminfo`），本章把它在 macOS 上
> 完整落地：解析层做成**纯函数**（跨平台可测），活体采样走 `sysctlbyname` +
> `getrusage`，HTTP 层用 0.17 的 `std.http.Server` / `std.http.Client` 在**同一进程**
> 内完成一次真实往返。
>
> 本章有 **6 条实测结论会推翻你可能听过的说法**：
>
> 1. **「监控系统一定要写平台相关代码」——半对半错。** 解析 `/proc/meminfo` 的
>    函数本身**一行平台代码都没有**：它是纯字符串函数，输入是 `[]const u8`，
>    输出是结构体。平台差异全部收敛到「谁把字符串喂给它」这一层
>    （Linux 读文件、macOS 调 sysctl，42.1）。
> 2. **「JSON 序列化就是调一个函数」——在 0.17 里连"调哪个函数"都要先查证。**
>    旧教程里的 `std.json.stringify` / `std.json.fmt` 在 0.17 的签名全变了：
>    现在是 `std.json.Stringify.value(value, options, writer)`，**writer 在最后**，
>    写错顺序的编译错是 `expected type 'json.Stringify.Options', found pointer`（42.2）。
> 3. **「HTTP 服务一定要框架」——错。** `std.http` 自带的 `Server` + `Client`
>    就够：服务端 20 行接住一条 GET、回一个 JSON，客户端 10 行 fetch 回来。
>    本章服务端与客户端跑在**同一个进程**的两个线程里，端口用原子变量公布（42.5）。
> 4. **`parseFromSlice` 返回的 `Parsed(T)` 拥有内存，必须 `defer parsed.deinit()`。**
>    它不是"解析完就完事"的返回值——内部持有一个 arena，不 deinit 就是泄漏
>    （42.3，测试里的泄漏检测立刻能抓到）。
> 5. **默认选项遇到未知字段直接 `error.UnknownField`**。服务端加字段、老客户端
>    还在跑，这是线上天天发生的事；`.ignore_unknown_fields = true` 是兼容性的
>    正确打开方式（42.3）。
> 6. **macOS 没有 `/proc`**。跨平台内存监控必须分支：Linux 读 `/proc/meminfo`、
>    macOS 用 `sysctlbyname("hw.memsize")` + `vm_stat`/`getrusage`、Windows 用
>    `GlobalMemoryStatusEx`。`std.posix` 在 0.17 **没有**封装 `sysctlbyname`，
>    但 `std.c` 里有 extern 声明可以直接调（42.1）。
>
> **节号对应**：42.1–42.5 是示例 `main` 里的运行时小节（`begin("42.N …") …
> end("42.N")`，运行输出里能看到 `==== 42.N … ====`）；**42.6（坑位清单）与
> 42.7（验证方式）不在 `main` 里**——42.6 在 `main` 末尾有同名小节，但文档的
> 42.6 是它的展开版；42.7 是本文档自己的一节。
>
> **确定性纪律**（沿用 31 章 / 34 章）：标记区间里**不出现任何裸耗时**，
> 采样数据用硬编码样本（`sampleStats()`），HTTP 端口从 48200 起扫、只印
> 「绑定成功」而不印具体端口——所以本章输出逐字节可复现。
>
> **前置章节**：[20 文件与 I/O](20-files-io.md)（`std.Io` 的读写模型）、
> [29 网络](29-networking.md)（`std.Io.net` 的 listen/accept）、
> [30 HTTP](30-http.md)（HTTP 报文结构）。本章不复读那些基础，只讲
> "监控数据 → JSON → HTTP"这条链路上新出现的东西。

---

## 42.0 导读：这一章要推翻 3 个说法

写系统监控服务之前，先把三个"想当然"摆出来，本章逐条拆掉：

**说法一：「监控系统一定要写平台相关代码」。**

听起来无可辩驳——`/proc/meminfo` 是 Linux 的，`sysctl` 是 BSD/macOS 的，
`GlobalMemoryStatusEx` 是 Windows 的。但"平台相关"和"业务逻辑"是两层东西：
**解析文本**和**采集文本**可以完全分开。本章的 `parseMeminfo()` 接受一个
`[]const u8`，返回一个 `RawMeminfo`——它不知道 `/proc` 是什么，不知道文件系统
是什么，测试用硬编码字符串驱动。平台代码被挤到边缘，只剩"字符串从哪来"这
一个问题。这就是 42.1 的全部内容。

**说法二：「JSON 序列化就是调一个函数」。**

在 0.17 之前，这句话大致是 `std.json.stringify(x, .{}, writer)`。0.17 里
`std.json` 的入口改成了 `std.json.Stringify.value(x, .{}, writer)`——
参数顺序没变，但**类型名变了**，而且 `writer` 必须是 `std.Io.Writer` 接口
（不是旧的 `std.io.AnyWriter`）。反序列化那边变化更大：`parseFromSlice`
返回的不是 `T` 而是 `Parsed(T)`，一个**拥有内存的所有权句柄**——忘记
`deinit` 就是泄漏。所以"调一个函数"之前，得先知道 0.17 里这个函数叫什么、
收什么参数、返回的东西归谁管。42.2 和 42.3 逐行讲。

**说法三：「HTTP 服务一定要框架」。**

Go 有 net/http、Python 有 Flask、Rust 有 axum——于是"手写 HTTP 服务"听起来
像自虐。但 Zig 的标准库已经把 HTTP **协议层**做完了：`std.http.Server` 负责
解析请求行和头部，`std.http.Client` 负责发请求、收响应体。你要写的只剩
**路由和业务**：收到 `GET /stats` 就回 JSON，否则 404。本章 42.5 用大约 50 行
（含客户端）完成一次进程内 HTTP 往返——没有框架、没有依赖、没有 `build.zig.zon`。

---

## 42.1 /proc/meminfo 解析：纯函数设计

### 42.1.1 /proc/meminfo 是什么

Linux 内核把系统内存统计以**文本文件**的形式暴露在 `/proc/meminfo`：

```text
MemTotal:       16384000 kB
MemFree:         2048000 kB
MemAvailable:    6144000 kB
Buffers:          512000 kB
Cached:          4096000 kB
...
```

每行一条，`Key: value kB` 格式，value 是十进制 kB 数。监控程序要做的就是：
读文件 → 找到 `MemTotal` 和 `MemAvailable` 两行 → 相减得到 used → 换算成 MB。

macOS 没有 `/proc`。等价的总内存查询是 `sysctlbyname("hw.memsize")`，
进程级内存用 `getrusage(2)` 的 `ru_maxrss`（峰值 RSS）。本章的跨平台策略：

| 平台 | 总内存 | 可用/已用 | 进程内存 |
|---|---|---|---|
| Linux | `/proc/meminfo` 的 MemTotal | MemAvailable | `/proc/self/status` 的 VmHWM |
| macOS | `sysctlbyname("hw.memsize")` | `vm_stat`（本章不展开） | `getrusage(RUSAGE_SELF).maxrss` |
| Windows | `GlobalMemoryStatusEx` | 同左 | `GetProcessMemoryInfo` |

注意**单位陷阱**：`/proc/meminfo` 是 kB，`hw.memsize` 是**字节**，
`ru_maxrss` 在 macOS 是**字节**、在 Linux 是 **kB**。跨平台代码里单位换算
是 bug 高发区（坑位清单第 1 条）。

### 42.1.2 数据模型

```zig
// examples/42_memsrv/main.zig 第 21-33 行
/// 内存统计快照。字段名用 snake_case —— std.json 默认按字段名序列化。
const MemStats = struct {
    total_mb: u64,
    available_mb: u64,
    used_percent: f64,
    timestamp_ms: i64,
};

/// /proc/meminfo 解析结果（原始字节 → MB 之前的中间态）。
const RawMeminfo = struct {
    total_kb: u64 = 0,
    available_kb: u64 = 0,
};
```

逐行讲：

- **第 22 行**：`MemStats` 是对外发布的结构——HTTP 接口吐出去的 JSON 就是它
  序列化的结果。四个字段：`total_mb`（总内存 MB）、`available_mb`（可用 MB）、
  `used_percent`（已用百分比）、`timestamp_ms`（采样时间戳，毫秒）。
- **第 23 行注释**：字段名用 snake_case 不是审美选择——`std.json` 默认按
  Zig 字段名原样写入 JSON 键。如果字段叫 `totalMb`，JSON 键就是 `totalMb`。
  想定制映射要用 `@field` 级别的 options（本章不用）。
- **第 30-33 行**：`RawMeminfo` 是**解析层的中间态**，保留 kB 单位、只存
  原始键值。它和 `MemStats` 分开的理由：解析（文本 → 数字）和换算
  （kB → MB、算百分比）是两种独立的可测逻辑，混在一起测试就得喂"看起来像
  /proc 输出"的输入，分开后各自都能用最小样本驱动。

### 42.1.3 parseMeminfo：纯函数

```zig
// examples/42_memsrv/main.zig 第 44-62 行
/// 解析 /proc/meminfo 格式的文本（Linux 理论 + 跨平台测试）。
///
/// 格式：`Key: value kB` 每行一条，value 是十进制 kB 数。
/// 用 tokenizeScalar + tokenizeAny 逐行切，找不到的键保持默认值 0。
/// 这是**纯函数**——不碰文件系统，测试用硬编码样本驱动。
fn parseMeminfo(content: []const u8) RawMeminfo {
    var result = RawMeminfo{};
    var lines = std.mem.tokenizeScalar(u8, content, '\n');
    while (lines.next()) |line| {
        // 行格式："MemTotal:       16384000 kB"
        // tokenizeAny 同时处理 ':' 和空白，切出 ["MemTotal", "16384000", "kB"]
        var toks = std.mem.tokenizeAny(u8, line, ": \t");
        const key = toks.next() orelse continue;
        const val_str = toks.next() orelse continue;
        const val = std.fmt.parseInt(u64, val_str, 10) catch continue;
        if (std.mem.eql(u8, key, "MemTotal")) {
            result.total_kb = val;
        } else if (std.mem.eql(u8, key, "MemAvailable")) {
            result.available_kb = val;
        }
        // 其它键（MemFree / Buffers / Cached…）本章不用，跳过
    }
    return result;
}
```

逐行讲：

- **第 46 行**：`std.mem.tokenizeScalar(u8, content, '\n')` 按换行切。
  用 `tokenize` 而不是 `split` 的理由：`tokenize` **折叠连续分隔符**——
  文件末尾的空行、`\r\n` 残留的 `\r` 都不会产生空 token。`split` 会把
  它们当成空行返回，后面就得额外判空。
- **第 47 行**：`while (lines.next()) |line|` 逐行处理。`tokenize` 的迭代器
  返回 `?[]const u8`，`while` 模式直接解包。
- **第 50 行**：`tokenizeAny(u8, line, ": \t")` 是这行的关键——**一次调用
  同时把冒号和所有空白字符都当分隔符**。`"MemTotal:       16384000 kB"`
  被切成 `["MemTotal", "16384000", "kB"]` 三个 token，冒号后那串任意长度的
  空格被自动折叠。如果用 `tokenizeScalar` 先切 `:` 再切空格，就得写两层循环。
- **第 51-52 行**：`orelse continue` 防御短行——文件里可能有空行或格式
  异常的行，切不出 key/value 就跳过。`tokenize` 已经保证不会有空 token，
  所以这两行实际触发条件很苛刻，但写上不亏。
- **第 53 行**：`parseInt(u64, val_str, 10) catch continue`——`catch continue`
  处理"value 不是十进制数字"的异常行。`/proc/meminfo` 的值理论上都是数字，
  但**解析器不该信任输入**，这是 24 章 minigrep 就立下的规矩。
- **第 54-58 行**：`std.mem.eql(u8, key, "MemTotal")` 精确匹配键名。
  只认 `MemTotal` 和 `MemAvailable` 两个键，其它（`MemFree`、`Buffers`、
  `Cached`……）全部走第 59 行的注释——跳过。这是**最小完备集**原则：
  监控服务只需要算 used%，而 used = total - available，两个键就够。
- **第 61 行**：返回 `result`。注意**找不到的键保持默认值 0**——`RawMeminfo`
  的字段声明里有 `= 0` 默认值（第 31-32 行），`var result = RawMeminfo{}`
  就把它们初始化为 0。空输入返回全 0，不是错误。

这个函数**没有 `try`、没有 allocator、没有 I/O**——输入输出都是值类型。
这就是"纯函数"的实操定义：同样的输入必然同样的输出，测试不需要文件系统、
不需要临时目录、不需要 mock。

### 42.1.4 计算百分比与单位换算

```zig
// examples/42_memsrv/main.zig 第 66-77 行
/// 从 RawMeminfo 计算 used_percent（纯函数，可测）。
/// used = total - available；percent = used / total * 100。
fn calcUsedPercent(raw: RawMeminfo) f64 {
    if (raw.total_kb == 0) return 0.0;
    const total = raw.total_kb;
    const avail = raw.available_kb;
    const used = total - avail;
    return @as(f64, @floatFromInt(used)) / @as(f64, @floatFromInt(total)) * 100.0;
}

/// 把 kB 转成 MB（整除，丢掉余数 —— 监控场景够用了）。
fn kbToMb(kb: u64) u64 {
    return kb / 1024;
}
```

逐行讲：

- **第 68 行**：`if (raw.total_kb == 0) return 0.0`——**防除零**。空输入、
  缺 `MemTotal` 的行、全零样本都会走到这里。返回 0.0 而不是报错，理由：
  "没有数据"在监控场景下等价于"使用率未知"，显示 0% 比让监控循环崩溃
  更符合运维直觉。
- **第 71 行**：`@as(f64, @floatFromInt(used))`——Zig 里整数转浮点必须显式
  `@floatFromInt`，浮点除法要求两边同类型，所以 `total` 也要转。
  整除 `/` 对浮点是真除法（62.5 不会变成 62）。
- **第 76 行**：`kb / 1024` 是**整除**，余数丢弃。16384000 kB / 1024 =
  16000 MB 整除；如果是 16384001 kB，结果就是 16000 MB 丢掉 1 kB。
  监控场景下 1 kB 的精度损失无关紧要——但如果你在做计费或容量规划，
  这里要换 `f64` 全程保精度（坑位清单第 2 条）。

### 42.1.5 macOS 活体采样：sysctlbyname 与 getrusage

```zig
// examples/42_memsrv/main.zig 第 82-97 行
/// macOS 活体采样：sysctlbyname("hw.memsize") 拿总内存（字节）。
/// ⚠️ std.posix 没有封装 sysctlbyname（0.17 实测），但 std.c 里有 extern 声明。
/// 返回字节数；失败时返回 null（调用方兜底）。
fn totalMemBytes() ?u64 {
    var size: u64 = 0;
    var len: usize = @sizeOf(u64);
    const rc = std.c.sysctlbyname("hw.memsize", &size, &len, null, 0);
    if (rc != 0) return null;
    return size;
}

/// 本进程峰值 RSS（resident set size），macOS 单位是**字节**。
/// Linux 的 /proc/self/status 里 VmHWM 单位是 kB —— 跨平台注意单位差。
fn selfPeakRssBytes() ?u64 {
    // RUSAGE_SELF = 0（POSIX 标准），0.17 的 std.posix 没有 RUSAGE 枚举
    const ru = std.posix.getrusage(0);
    const maxrss: u64 = @intCast(ru.maxrss);
    return maxrss;
}
```

逐行讲：

- **第 83-84 行**：`sysctlbyname` 的 C 签名是
  `int sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen)`。
  查询模式：`oldp` 指向接收缓冲区、`oldlenp` 传入缓冲区大小（这里
  `@sizeOf(u64)`）、`newp/newlen` 传 `null/0`（不写入）。
- **第 85 行**：`std.c.sysctlbyname`——0.17 的 `std.posix` **没有**封装
  `sysctlbyname`（`@hasDecl` 实测为 false），但 `std.c` 里有 extern 声明
  可以直接调。这是 17 章 C interop 的实战场景：标准库没包住的系统调用，
  自己声明 extern 一行的事。返回值 `rc != 0` 表示失败，返回 `null` 让
  调用方决定怎么办（本章选择打印一行提示，不中断）。
- **第 92 行注释**：`RUSAGE_SELF = 0` 是 POSIX 规定的常量。0.17 的
  `std.posix` 没有导出 `RUSAGE_SELF` 枚举，所以直接写字面量 0 并注释来源。
  这是读 0.17 标准库源码时常见的"常量存在但没有名字"的情况。
- **第 93 行**：`std.posix.getrusage(0)` 返回 `std.posix.rusage` 结构体，
  `ru.maxrss` 字段是峰值 RSS。macOS 上单位是**字节**，Linux 上是 **kB**——
  同一个 POSIX API 单位不同，这是跨平台监控的经典坑（坑位清单第 1 条）。
- **第 94 行**：`@intCast(ru.maxrss)`——`maxrss` 的 C 类型是 `c_long`，
  在 macOS 64 位下是 `i64`，转成 `u64` 需要显式 `@intCast`（Zig 不允许
  有符号到无符号的隐式转换）。

### 42.1.6 sampleStats：确定性样本

```zig
// examples/42_memsrv/main.zig 第 101-113 行
/// 用硬编码样本构造一个确定性的 MemStats（用于 JSON 演示和 HTTP 服务）。
/// 真实监控循环里换成活体采样。
fn sampleStats() MemStats {
    // 模拟 /proc/meminfo 的采样结果（16 GB 机器，用了约 62.5%）
    const raw = RawMeminfo{
        .total_kb = 16 * 1024 * 1024, // 16 GB = 16777216 kB
        .available_kb = 6 * 1024 * 1024, // 6 GB 可用
    };
    return .{
        .total_mb = kbToMb(raw.total_kb),
        .available_mb = kbToMb(raw.available_kb),
        .used_percent = calcUsedPercent(raw),
        .timestamp_ms = 1_700_000_000_000, // 固定时间戳 → 输出可复现
    };
}
```

逐行讲：

- **第 103-106 行**：硬编码一份"看起来像 /proc/meminfo 解析结果"的
  `RawMeminfo`——16 GB 总内存、6 GB 可用。注释里的换算是给读者验算的：
  16 GB = 16 × 1024 × 1024 kB = 16777216 kB。
- **第 111 行**：`timestamp_ms = 1_700_000_000_000`——**固定时间戳**。
  真实监控会用 `std.Io.Timestamp.now(io, .real)` 的当前毫秒数，但那样每次
  运行的输出都不同，文档里的运行输出就对不上了。这是 31 章立的
  **确定性纪律**：标记区间里只出现可复现的数字。
- **整体意图**：`sampleStats()` 是 42.2/42.3/42.4/42.5 共用的数据源。
  JSON 序列化、反序列化、监控循环、HTTP 服务——四节都围绕这同一份数据展开，
  读者可以专注于"JSON 怎么序列化"而不是"这次采样结果是什么"。

### 42.1.7 运行时输出

```zig
// examples/42_memsrv/main.zig 第 244-271 行
    begin("42.1 /proc/meminfo 解析（Linux 理论 + macOS 替代）");
    {
        // Linux 上的 /proc/meminfo 长这样（节选）：
        const sample =
            "MemTotal:       16384000 kB\n" ++
            "MemFree:         2048000 kB\n" ++
            "MemAvailable:    6144000 kB\n" ++
            "Buffers:          512000 kB\n" ++
            "Cached:          4096000 kB\n";
        const raw = parseMeminfo(sample);
        try w.print("  样本 MemTotal     = {d} kB → {d} MB\n", .{ raw.total_kb, kbToMb(raw.total_kb) });
        try w.print("  样本 MemAvailable = {d} kB → {d} MB\n", .{ raw.available_kb, kbToMb(raw.available_kb) });
        try w.print("  样本 used_percent = {d:.1}%\n", .{calcUsedPercent(raw)});

        // macOS 没有 /proc —— 用 sysctlbyname 拿总内存
        if (totalMemBytes()) |bytes| {
            try w.print("  本机总内存（sysctl hw.memsize）= {d} MB\n", .{bytes / (1024 * 1024)});
        } else {
            try w.print("  sysctl hw.memsize 失败\n", .{});
        }
        if (selfPeakRssBytes()) |bytes| {
            try w.print("  本进程峰值 RSS（getrusage）= {d} KB\n", .{bytes / 1024});
        }
```

运行输出（macOS 实测）：

```text
==== 42.1 /proc/meminfo 解析（Linux 理论 + macOS 替代） ====
  样本 MemTotal     = 16384000 kB → 16000 MB
  样本 MemAvailable = 6144000 kB → 6000 MB
  样本 used_percent = 62.5%
  本机总内存（sysctl hw.memsize）= 16384 MB
  本进程峰值 RSS（getrusage）= 2392 KB

  跨平台策略：Linux 读 /proc/meminfo，macOS 用 sysctl，Windows 用 GlobalMemoryStatusEx。
  parseMeminfo() 是纯函数 —— 不碰文件系统，测试用硬编码样本驱动。
```

逐行对输出：

- **样本三行**：`parseMeminfo` 从硬编码样本里切出 16384000/6144000，
  `kbToMb` 整除得 16000/6000，`calcUsedPercent` 算 (16384000-6144000)/
  16384000 × 100 = 62.5%。`{d:.1}` 保留一位小数。
- **本机总内存 16384 MB**：这台机器正好是 16 GB，`hw.memsize` 返回
  17179869184 字节，除以 1024² 得 16384 MB。样本的 16000 MB 和本机的
  16384 MB 差 384 MB——因为 `/proc/meminfo` 的 MemTotal 不包含内核保留
  内存，而 `hw.memsize` 是物理总量。这不是 bug，是两个口径的定义差。
- **峰值 RSS 2392 KB**：本进程自启动以来的最大常驻内存。这个数字每次
  运行会变（分配器行为、缓冲大小），所以**不进入任何断言**——只印出来
  给人看。这是确定性纪律的边界：可复现的进断言，不可复现的只展示。

---

## 42.2 JSON 序列化：std.json.Stringify.value

### 42.2.1 0.17 的序列化 API

0.17 之前（以及网上绝大多数教程），JSON 序列化的写法是：

```zig
// 旧写法（0.16 及之前）——0.17 编译不过
try std.json.stringify(value, .{}, writer);
// 或者格式化进字符串
std.fmt.allocPrint(a, "{f}", .{std.json.fmt(value, .{})});
```

0.17 里 `std.json` 的入口重构了：序列化走 `std.json.Stringify.value`，
反序列化走 `std.json.parseFromSlice`（这个没变）。`Stringify.value` 的签名：

```zig
pub fn value(
    input: anytype,           // 要序列化的值
    options: Stringify.Options, // 选项（缩进、字段过滤……）
    out_stream: *std.Io.Writer, // 输出目标 —— 在最后！
) error{OutOfMemory}!void
```

三个参数，**writer 在最后**。写错顺序（比如把 writer 放中间）的编译错：

```text
error: expected type 'json.Stringify.Options', found pointer
```

这个报错信息不算友好——它不会告诉你"writer 应该在哪"，只说"第二个参数
应该是 Options 但你给了个指针"。看到它，第一反应就是检查参数顺序。

### 42.2.2 statsToJson 完整实现

```zig
// examples/42_memsrv/main.zig 第 124-129 行
/// MemStats → JSON 字符串（调用方 owns 返回的切片，负责 free）。
/// ⚠️ 0.17 的签名是 `Stringify.value(value, options, writer)` —— **writer 在最后**。
/// 写错顺序的编译错："expected type 'json.Stringify.Options', found pointer"。
/// ⚠️ 用 `toOwnedSlice()` 把内部缓冲的所有权转移出来 —— `written()` 返回的是
/// 指向内部缓冲的切片，调用方不能 free（那是 Allocating 的所有权）。
fn statsToJson(a: std.mem.Allocator, stats: MemStats) ![]u8 {
    var jw = std.Io.Writer.Allocating.init(a);
    errdefer jw.deinit();
    try std.json.Stringify.value(stats, .{}, &jw.writer);
    return jw.toOwnedSlice();
}
```

逐行讲：

- **第 125 行**：`std.Io.Writer.Allocating.init(a)`——0.17 的惯用内存写入器。
  它内部维护一个 `ArrayList(u8)`，`write` 即追加。`std.Io.Writer` 是
  **接口类型**（20 章讲过 `std.Io.Writer` 的 `fixed` / `Allocating` 两个
  具体实现），`Allocating` 版本按需扩容。
- **第 126 行**：`errdefer jw.deinit()`——错误路径上释放 `jw` 的内部缓冲。
  成功路径不归这里管：`toOwnedSlice()`（第 128 行）会把内部缓冲的所有权
  转出去，那时 `jw` 内部是空壳，`deinit` 无事可做。这是 11 章 allocator
  纪律的延伸：**谁分配谁释放，但所有权可以转移，转移后原持有者不得再碰**。
- **第 127 行**：`std.json.Stringify.value(stats, .{}, &jw.writer)`——
  三个参数：值、空选项（默认紧凑输出、无缩进）、写入器接口的指针。
  `&jw.writer` 取的是 `Allocating` 内部的 `std.Io.Writer` 接口字段的地址——
  `Stringify.value` 要的是 `*std.Io.Writer`（指针），不是值。
- **第 128 行**：`jw.toOwnedSlice()`——把 `Allocating` 内部 `ArrayList`
  的底层切片**所有权**转移给调用方：内部 list 清零，返回的 `[]u8` 由
  调用方负责 `free`。对比 `jw.written()`：后者返回的是**借用**切片
  （指向内部缓冲，调用方不能 free）——42.5 的 HTTP 客户端会用到
  `written()`，因为响应体只在打印前有效。

### 42.2.3 运行时输出

```zig
// examples/42_memsrv/main.zig 第 274-282 行
    begin("42.2 JSON 序列化：std.json.Stringify.value");
    {
        const stats = sampleStats();
        const json_str = try statsToJson(gpa, stats);
        defer gpa.free(json_str);
        try w.print("  MemStats → JSON：{s}\n", .{json_str});
        try w.print("  ⚠️ 0.17 签名：Stringify.value(value, options, writer) —— writer 在**最后**\n", .{});
    }
    end("42.2");
```

运行输出：

```text
==== 42.2 JSON 序列化：std.json.Stringify.value ====
  MemStats → JSON：{"total_mb":16384,"available_mb":6144,"used_percent":62.5,"timestamp_ms":1700000000000}
  ⚠️ 0.17 签名：Stringify.value(value, options, writer) —— writer 在**最后**
```

输出解读：

- JSON 是**紧凑格式**（无空格无换行）——`.{}` 空选项的默认行为。生产环境
  的 API 响应就该紧凑：省带宽、省解析时间。调试时想好看可以加
  `.whitespace = .indent_2`。
- 键名就是 Zig 字段名原样（`total_mb` 不是 `totalMb`）——0.17 的
  `Stringify` 默认不做 camelCase 转换。
- `used_percent` 序列化成 `62.5` 不是 `62.500000`——`Stringify` 对浮点
  用最小表示，不补零。
- `timestamp_ms` 的 `1_700_000_000_000` 序列化成 `1700000000000`——
  JSON 数字不允许下划线分隔符（那是 Zig 源码字面量的语法糖）。

---

## 42.3 JSON 反序列化：parseFromSlice + ignore_unknown_fields

### 42.3.1 Parsed(T)：一个拥有内存的句柄

```zig
// examples/42_memsrv/main.zig 第 138-142 行
/// JSON 字符串 → MemStats。
/// ⚠️ `parseFromSlice` 返回 `Parsed(T)`，内部持有 arena —— **必须 `defer parsed.deinit()`**。
/// 否则泄漏检测（测试里的 SafeAllocator）会立刻抓到。
fn jsonToStats(a: std.mem.Allocator, json_str: []const u8) !MemStats {
    var parsed = try std.json.parseFromSlice(MemStats, a, json_str, .{});
    defer parsed.deinit();
    return parsed.value;
}
```

逐行讲：

- **第 139 行**：`std.json.parseFromSlice(MemStats, a, json_str, .{})`——
  四个参数：目标类型、allocator、JSON 文本、选项。返回类型是
  `std.json.Parsed(MemStats)`，**不是** `MemStats`。
- **`Parsed(T)` 为什么存在**：JSON 解析可能需要在堆上分配内存——比如
  字符串字段（要 dupe 出来）、嵌套数组。`Parsed(T)` 内部持有一个 arena，
  所有解析分配的内存都挂在它上面；`parsed.value` 是解析出的 `T` 值，
  它内部的切片**指向 arena 的内存**。所以 `parsed` 必须活得比 `value` 久——
  先 `return parsed.value` 再 `deinit` 的话，返回值里的切片就是悬空的。
- **第 140 行**：`defer parsed.deinit()`——释放整个 arena。一行搞定，
  但**不能省**。在测试里用 `std.testing.allocator`（SafeAllocator）时，
  漏掉这行立刻报 `error: memory leak` 并打印分配栈——这是好事，
  泄漏在开发期暴露，而不是上线后 OOM。
- **第 141 行**：`return parsed.value`——`parsed` 在这里析构（defer 触发），
  但 `MemStats` 的四个字段都是标量（u64/f64/i64），不持有切片，
  所以返回值不依赖 arena 的内存。如果结构体里有 `[]const u8` 字段，
  就不能这么写——得把字符串 dupe 到调用方的 allocator 上（坑位清单第 4 条）。

### 42.3.2 ignore_unknown_fields：演进的必需品

```zig
// examples/42_memsrv/main.zig 第 146-152 行
/// 带 `.ignore_unknown_fields = true` 的版本。
/// 服务端演进时老客户端收到新字段、或新客户端收到老字段 —— 不认识的键直接跳过。
fn jsonToStatsLenient(a: std.mem.Allocator, json_str: []const u8) !MemStats {
    var parsed = try std.json.parseFromSlice(MemStats, a, json_str, .{
        .ignore_unknown_fields = true,
    });
    defer parsed.deinit();
    return parsed.value;
}
```

和 `jsonToStats` 的唯一区别是选项里的 `.ignore_unknown_fields = true`。
它的语义：**JSON 里出现目标结构体没有的字段时，跳过而不是报错**。

默认行为是 `error.UnknownField`——这在开发期是优点（拼错字段名立刻暴露），
在生产环境是灾难：服务端 v2 加了 `hostname` 字段，所有 v1 客户端同时
开始报 `UnknownField`，监控全黑。`ignore_unknown_fields = true` 就是
"向前兼容"开关：认识的字段照常解析，不认识的无视。

### 42.3.3 运行时输出

```zig
// examples/42_memsrv/main.zig 第 285-309 行
    begin("42.3 JSON 反序列化：parseFromSlice + ignore_unknown_fields");
    {
        const stats = sampleStats();
        const json_str = try statsToJson(gpa, stats);
        defer gpa.free(json_str);

        // 往返：struct → string → struct
        const restored = try jsonToStats(gpa, json_str);
        try w.print("  往返 total_mb       = {d}（原 {d}）\n", .{ restored.total_mb, stats.total_mb });
        try w.print("  往返 available_mb   = {d}（原 {d}）\n", .{ restored.available_mb, stats.available_mb });
        try w.print("  往返 used_percent   = {d:.1}（原 {d:.1}）\n", .{ restored.used_percent, stats.used_percent });
        try w.print("  往返 timestamp_ms   = {d}（原 {d}）\n", .{ restored.timestamp_ms, stats.timestamp_ms });

        // ignore_unknown_fields 演示
        const with_extra = "{\"total_mb\":8192,\"available_mb\":4096,\"used_percent\":50.0,\"timestamp_ms\":1700000000000,\"hostname\":\"web-01\",\"extra_field\":42}";
        if (jsonToStats(gpa, with_extra)) |_| {
            try w.print("  ?? 不该成功\n", .{});
        } else |e| {
            try w.print("  默认选项 + 未知字段 → error.{s}\n", .{@errorName(e)});
        }
        const lenient = try jsonToStatsLenient(gpa, with_extra);
        try w.print("  .ignore_unknown_fields=true → total_mb={d}（多余字段被跳过）\n", .{lenient.total_mb});
        try w.print("  ⚠️ parseFromSlice 返回 Parsed(T)，必须 defer parsed.deinit()\n", .{});
    }
    end("42.3");
```

运行输出：

```text
==== 42.3 JSON 反序列化：parseFromSlice + ignore_unknown_fields ====
  往返 total_mb       = 16384（原 16384）
  往返 available_mb   = 6144（原 6144）
  往返 used_percent   = 62.5（原 62.5）
  往返 timestamp_ms   = 1700000000000（原 1700000000000）
  默认选项 + 未知字段 → error.UnknownField
  .ignore_unknown_fields=true → total_mb=8192（多余字段被跳过）
  ⚠️ parseFromSlice 返回 Parsed(T)，必须 defer parsed.deinit()
```

输出解读：

- **往返四行相等**：struct → JSON string → struct，四个字段逐一比对。
  这是**序列化器的最小正确性测试**：如果 `Stringify.value` 和
  `parseFromSlice` 是互逆的，往返必然保真。42.7 的验证方式里这条是
  一个独立 test。
- **`error.UnknownField`**：`with_extra` 里有 `hostname` 和 `extra_field`
  两个 `MemStats` 没有的字段，默认选项直接报错。注意 Zig 的
  `if (expr) |_| {} else |e| {}` 错误捕获语法——`expr` 返回错误联合，
  `else` 分支拿到错误值 `@errorName(e)` 打成字符串。
- **`total_mb=8192`**：宽容版跳过多余字段，正常解析出 8192。注意
  `with_extra` 里的值（8192/4096/50.0）和 `sampleStats()` 的不同——
  这是故意的，证明解析器读的是**输入字符串**而不是缓存了上一个结果。

### 42.3.4 测试：JSON 往返与未知字段

```zig
// examples/42_memsrv/main.zig 第 434-466 行
test "JSON 往返：struct → string → struct，字段相等" {
    const a = std.testing.allocator;
    const original = MemStats{
        .total_mb = 16000,
        .available_mb = 6000,
        .used_percent = 62.5,
        .timestamp_ms = 1_700_000_000_000,
    };
    const json_str = try statsToJson(a, original);
    defer a.free(json_str);

    const restored = try jsonToStats(a, json_str);
    try std.testing.expectEqual(original.total_mb, restored.total_mb);
    try std.testing.expectEqual(original.available_mb, restored.available_mb);
    try std.testing.expectEqual(original.used_percent, restored.used_percent);
    try std.testing.expectEqual(original.timestamp_ms, restored.timestamp_ms);
}

test "ignore_unknown_fields：多余字段被跳过" {
    const a = std.testing.allocator;
    const json_str = "{\"total_mb\":8192,\"available_mb\":4096,\"used_percent\":50.0,\"timestamp_ms\":1700000000000,\"hostname\":\"web-01\",\"extra\":42}";
    const stats = try jsonToStatsLenient(a, json_str);
    try std.testing.expectEqual(@as(u64, 8192), stats.total_mb);
    try std.testing.expectEqual(@as(u64, 4096), stats.available_mb);
    try std.testing.expectEqual(@as(f64, 50.0), stats.used_percent);
    try std.testing.expectEqual(@as(i64, 1_700_000_000_000), stats.timestamp_ms);
}

test "默认选项遇到未知字段报错" {
    const a = std.testing.allocator;
    const json_str = "{\"total_mb\":8192,\"available_mb\":4096,\"used_percent\":50.0,\"timestamp_ms\":1700000000000,\"hostname\":\"web-01\"}";
    try std.testing.expectError(error.UnknownField, jsonToStats(a, json_str));
}
```

三个 test 覆盖了 42.3 的全部行为面：往返保真、宽容模式跳过、严格模式报错。
注意 `std.testing.expectError` 的用法：第一个参数是期望的错误值，第二个是
错误联合——它断言"这个表达式**恰好**返回这个错误"。

---

## 42.4 内存监控循环

### 42.4.1 代码与输出

```zig
// examples/42_memsrv/main.zig 第 312-330 行
    begin("42.4 内存监控循环：3 次采样");
    {
        var i: usize = 0;
        while (i < 3) : (i += 1) {
            const stats = sampleStats();
            try w.print("  [{d}] total={d} MB  available={d} MB  used={d:.1}%\n", .{
                i + 1,
                stats.total_mb,
                stats.available_mb,
                stats.used_percent,
            });
            if (i < 2) {
                // std.Io.sleep(io, duration, clock) —— .awake = 单调时钟，不受系统时间跳变影响
                try std.Io.sleep(io, .fromMilliseconds(100), .awake);
            }
        }
        try w.print("  采样 3 次完成（每次间隔 100ms）\n", .{});
    }
    end("42.4");
```

运行输出：

```text
==== 42.4 内存监控循环：3 次采样 ====
  [1] total=16384 MB  available=6144 MB  used=62.5%
  [2] total=16384 MB  available=6144 MB  used=62.5%
  [3] total=16384 MB  available=6144 MB  used=62.5%
  采样 3 次完成（每次间隔 100ms）
```

逐行讲：

- **第 315 行**：`while (i < 3) : (i += 1)`——Zig 的 while 带**继续表达式**，
  等价于 C 的 `for (i = 0; i < 3; i++)`。循环体里不手动 `i += 1`。
- **第 324-325 行**：`std.Io.sleep(io, .fromMilliseconds(100), .awake)`——
  0.17 的睡眠走 `std.Io`，不是旧的 `std.Thread.sleep`。
  第三个参数 `.awake` 选**单调时钟**（monotonic clock）：它只增不减，
  不受 NTP 校时、用户改系统时间的影响。对比 `.real`（墙钟）：
  如果管理员在 sleep 中途把系统时间往回拨一小时，`.real` 可能睡过头或
  提前醒，`.awake` 保证至少睡满 100ms。监控间隔用单调时钟是正确默认。
- **第 323 行**：`if (i < 2)`——最后一次迭代不睡。理由：睡完还要再打一行
  "采样完成"，那行字不需要等间隔。真实监控（无限循环）里这个分支不存在，
  本章只采样 3 次所以要有。
- **三次输出完全相同**：因为数据源是 `sampleStats()` 的硬编码样本。
  真实场景里把 `sampleStats()` 换成活体采样（Linux 读 `/proc`、macOS 调
  `sysctlbyname`），循环骨架一行不用改——这就是 42.1 把采集和解析分开
  的回报。

### 42.4.2 从演示到真实监控

ch6 的 memInfo 是一个 `while (true)` 无限循环：每 2 秒采样一次、打印一行、
错误 catch 住打印但不退出。本章把它压成 3 次迭代 + 100ms 间隔，理由是
**可复现**：无限循环的输出进不了文档，3 次迭代的可以。

真实监控循环的两个加固点，本章代码里已有雏形：

1. **错误不致命**：`sampleStats()` 换成活体采样后会返回 `!MemStats`，
   循环体要 `catch` 住单次失败（某次 sysctl 失败不代表下次也失败），
   打印错误、继续下一轮。ch6 的写法是
   `printUsedMemory() catch |err| std.debug.print(...)`，循环本身不退出。
2. **间隔用单调时钟**：`.awake` 而不是 `.real`，上文已述。

---

## 42.5 迷你 HTTP 内存服务

### 42.5.1 设计：进程内往返

ch6 的 memServer/memClient 是**两个独立程序**：服务端监听 8080，
客户端连上去收 JSON。本章把它压进**一个进程**：服务端跑在子线程，
客户端跑在主线程，端口用原子变量从服务端公布给客户端。

这个设计的好处：

1. **测试自包含**：`zig build-exe` 出一个二进制，`./main` 一次跑完
   服务端 + 客户端，不需要开两个终端。
2. **端口不冲突**：服务端从 48200 起向上扫（避开 macOS ephemeral 区间
   49152-65535），绑定成功就用那个端口。不存在"8080 被占了"的问题。
3. **关停确定**：服务端只服务 1 条请求就退出，主线程 `join()` 即同步——
   不存在"服务器线程还在跑、主线程怎么退"的问题。34 章的 zcache 用了
   同样的"quota + join"模式（见 34 章服务端关停）。

### 42.5.2 服务端上下文

```zig
// examples/42_memsrv/main.zig 第 159-166 行
/// 服务端上下文：io + 一份要服务的 JSON + 原子端口发布。
const HttpSrvCtx = struct {
    io: std.Io = undefined,
    body: []const u8 = "",
    /// 服务端实际绑定的端口。用原子发布 —— 端口是"扫出来的"，客户端必须等它确定。
    port: std.atomic.Value(u16) = std.atomic.Value(u16).init(0),
    /// 已服务请求数（quota=1 后退出）。
    served: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
};
```

逐行讲：

- **第 160 行**：`io: std.Io = undefined`——`std.Io` 是**值类型**不是指针，
  跨线程共享安全（31 章实测：底层是 Threaded 的 OS futex）。
  `undefined` 占位，构造时由 `main` 填入 `init.io`。
- **第 161 行**：`body: []const u8 = ""`——要服务的 JSON 正文。
  服务端**借用**这个切片（不 dupe），生命周期由主线程保证：主线程
  `join()` 服务端线程之后才 `gpa.free(json_str)`，所以借用期间始终有效。
- **第 163 行**：`port: std.atomic.Value(u16)`——**原子**端口变量。
  为什么是原子的：服务端线程写（绑定成功后 `store`），主线程读
  （`while (load == 0) yield`），跨线程共享的非原子变量是数据竞争
  （19 章的基础知识）。`std.atomic.Value(u16).init(0)` 的 0 是哨兵值
  表示"还没绑好"。
- **第 165 行**：`served: std.atomic.Value(usize)`——已服务计数。
  主线程在 `join()` 后读它做断言（"确实服务了 1 条"），所以也要原子。

### 42.5.3 服务端线程

```zig
// examples/42_memsrv/main.zig 第 169-216 行
/// 服务端线程主体：listen → accept 1 条 → std.http.Server 处理 → 退出。
fn httpServe(ctx: *HttpSrvCtx) void {
    const io = ctx.io;
    // 从高位端口开始扫，避开 ephemeral 区间（macOS 默认 49152–65535）
    var port: u16 = 48200;
    var server: std.Io.net.Server = undefined;
    while (port < 48220) : (port += 1) {
        const addr = std.Io.net.IpAddress.parseIp4("127.0.0.1", port) catch continue;
        if (addr.listen(io, .{ .reuse_address = true })) |s| {
            server = s;
            break;
        } else |_| {}
    }
    if (port >= 48220) {
        std.debug.print("  [server] 端口扫描失败\n", .{});
        return;
    }
    defer server.deinit(io);
    ctx.port.store(port, .release);

    // accept 恰好 1 条连接
    const stream = server.accept(io) catch return;
    defer stream.close(io);

    // std.http.Server 需要 std.Io.Reader 和 std.Io.Writer（裸接口，不是 net.Stream 包装）
    var rbuf: [4096]u8 = undefined;
    var wbuf: [4096]u8 = undefined;
    var stream_reader = stream.reader(io, &rbuf);
    var stream_writer = stream.writer(io, &wbuf);

    var http_server = std.http.Server.init(&stream_reader.interface, &stream_writer.interface);
    var request = http_server.receiveHead() catch return;

    // 只处理 GET /stats，其它一律 404
    if (request.head.method == .GET and std.mem.eql(u8, request.head.target, "/stats")) {
        request.respond(ctx.body, .{
            .status = .ok,
            .extra_headers = &.{.{ .name = "content-type", .value = "application/json" }},
            .keep_alive = false,
        }) catch return;
    } else {
        request.respond("{\"error\":\"not found\"}", .{
            .status = .not_found,
            .extra_headers = &.{.{ .name = "content-type", .value = "application/json" }},
            .keep_alive = false,
        }) catch return;
    }
    ctx.served.store(1, .release);
}
```

逐行讲：

- **第 172-180 行**：端口扫描循环。从 48200 开始尝试 `listen`，成功就
  `break`；失败（`AddressInUse`）就 `port += 1` 试下一个。上限 48220：
  扫 20 个端口都失败说明环境有问题（可能是端口耗尽），放弃并打印提示。
  `.reuse_address = true` 允许快速重启（TIME_WAIT 状态的端口可复用）。
  29 章讲过 `std.Io.net` 的 listen/accept 模型，这里不重复。
- **第 181-184 行**：扫描失败的 early return。注意此时 `ctx.port` 仍是 0，
  主线程的 `while (load == 0) yield` 会**死循环**——所以主线程那边
  必须有超时或上限（本章没有，因为 48200-48220 在开发机上几乎不可能全占；
  生产代码要加 `std.Io.sleep` 限流或重试上限，坑位清单第 6 条）。
- **第 186 行**：`ctx.port.store(port, .release)`——**发布**端口。
  `.release` 内存序保证：端口号的写入**先于**之后的任何读被其它线程看到。
  主线程用 `.acquire` 读（第 343 行），构成 release-acquire 对——
  31 章讲过这个模式的原理。
- **第 189 行**：`server.accept(io) catch return`——接受一条连接。
  本章 quota = 1：服务一条就退出，所以 accept 只调一次。
- **第 193-196 行**：从 `stream` 构造 `std.Io.Reader` 和 `std.Io.Writer`。
  每个需要一个栈缓冲（4096 字节）。`std.http.Server` 要的是**裸接口**
  （`&stream_reader.interface`），不是 `net.Stream` 本身——0.17 的
  `std.http.Server.init` 签名是 `(*std.Io.Reader, *std.Io.Writer)`。
- **第 198 行**：`std.http.Server.init(...)` 构造协议层状态机。
- **第 199 行**：`receiveHead()` 读请求行 + 头部，阻塞直到客户端发完。
  返回的 `request` 里有 `head.method`、`head.target`（路径）、头部表等。
- **第 202 行**：路由判断——`method == .GET` 且 `target == "/stats"`。
  `std.mem.eql(u8, ..., "/stats")` 是字节级精确匹配：查询字符串
  `"/stats?x=1"` 不匹配（target 含 `?` 之后的部分），`/stats/` 也不匹配。
  本章只有一个端点，够用了；多端点要切到 `std.mem.startsWith` 或
  手写 path 解析。
- **第 203-207 行**：`request.respond(body, options)`——0.17 的
  `std.http.Server` 一次性响应 API。body 是 `[]const u8`，options 里
  指定状态码 `.ok`（200）、`content-type: application/json` 头、
  `keep_alive = false`（响应完就关连接）。`respond` 内部会写状态行、
  头部、空行、body，然后 flush。
- **第 209-213 行**：404 分支。body 是硬编码的 JSON 错误响应
  `{"error":"not found"}`——注意 Zig 字符串转义：`\"` 在 Zig 字符串里
  就是 `"` 字符，所以 `"{\"error\":\"not found\"}"` 的 JSON 值是
  `{"error":"not found"}`。
- **第 215 行**：`ctx.served.store(1, .release)`——服务完成计数。
  主线程 `join()` 后读它（`.acquire`），确认服务端真的处理了请求
  （而不是 accept 失败提前 return）。

### 42.5.4 客户端与进程内往返

```zig
// examples/42_memsrv/main.zig 第 333-366 行
    begin("42.5 迷你 HTTP 内存服务：std.http.Server + Client 进程内往返");
    {
        const stats = sampleStats();
        const json_str = try statsToJson(gpa, stats);
        defer gpa.free(json_str);

        // 起服务端线程（恰好服务 1 条请求）
        var ctx = HttpSrvCtx{ .io = io, .body = json_str };
        const th = try std.Thread.spawn(.{}, httpServe, .{&ctx});
        // 等端口确定
        while (ctx.port.load(.acquire) == 0) std.Thread.yield() catch {};

        // std.http.Client 是结构体（不是指针），直接字面量初始化
        var client: std.http.Client = .{ .allocator = gpa, .io = io };
        defer client.deinit();

        // fetch 拿响应体
        var jw = std.Io.Writer.Allocating.init(gpa);
        defer jw.deinit();
        const uri_str = try std.fmt.allocPrint(gpa, "http://127.0.0.1:{d}/stats", .{ctx.port.load(.acquire)});
        defer gpa.free(uri_str);

        const result = try client.fetch(.{
            .location = .{ .url = uri_str },
            .method = .GET,
            .response_writer = &jw.writer,
        });
        try w.print("  GET /stats → {d} {s}\n", .{ @backingInt(result.status), result.status.phrase().? });
        try w.print("  响应体：{s}\n", .{jw.written()});
        try w.print("  服务端已服务 {d} 条请求\n", .{ctx.served.load(.acquire)});
        th.join();
        try w.print("  ✓ 进程内 HTTP 往返完成\n", .{});
    }
    end("42.5");
```

运行输出：

```text
==== 42.5 迷你 HTTP 内存服务：std.http.Server + Client 进程内往返 ====
  GET /stats → 200 OK
  响应体：{"total_mb":16384,"available_mb":6144,"used_percent":62.5,"timestamp_ms":1700000000000}
  服务端已服务 1 条请求
  ✓ 进程内 HTTP 往返完成
```

逐行讲：

- **第 340 行**：构造 `HttpSrvCtx`。`body = json_str` 是借用——`json_str`
  的 `defer gpa.free` 在 42.5 块结束时触发，晚于 `th.join()`，所以
  借用期间始终有效。
- **第 341 行**：`std.Thread.spawn(.{}, httpServe, .{&ctx})`——起服务端
  线程。19 章讲过 spawn 的签名：选项、函数、参数元组。
- **第 343 行**：`while (ctx.port.load(.acquire) == 0) std.Thread.yield() catch {}`——
  **自旋等待**端口发布。`.acquire` 读和 `httpServe` 里的 `.release` 写
  配对：一旦读到非 0，说明端口写入已完成且可见。`std.Thread.yield()`
  让出 CPU（`catch {}` 吞掉可能的错误——yield 在大多数平台不失败）。
- **第 346 行**：`std.http.Client = .{ .allocator = gpa, .io = io }`——
  0.17 的 `std.http.Client` 是**结构体**（不是指针、不需要 init 函数），
  字面量构造填两个字段即可。`defer client.deinit()` 释放内部状态。
- **第 350-351 行**：`std.Io.Writer.Allocating` 接收响应体。这次用
  `written()`（借用）而不是 `toOwnedSlice()`——因为响应体只在打印前
  有效，不需要长期持有，借用更省（省一次 dupe + 一次 free）。
- **第 352 行**：`std.fmt.allocPrint` 拼 URL。端口从原子变量再读一次
  （此时必为非 0）。
- **第 355-359 行**：`client.fetch(...)`——0.17 的 HTTP 客户端 API。
  `.location = .{ .url = uri_str }` 指定 URL，`.method = .GET`，
  `.response_writer` 指定响应体的写入目标。`fetch` 内部完成 DNS（这里
  是 IP 不需要）、TCP 连接、请求发送、响应接收的全过程。
  返回的 `result` 有 `status`（状态码枚举）。
- **第 360 行**：`@backingInt(result.status)` 把状态码枚举转成整数
  （200），`result.status.phrase()` 拿原因短语（`"OK"`）。`.?` 解包：
  `phrase()` 返回 `?[]const u8`，标准状态码都有短语。
- **第 361 行**：`jw.written()` 打印响应体——就是 42.2 序列化的那条 JSON。
  逐字节一致：序列化 → HTTP 传输 → 接收，全链路无损。
- **第 363 行**：`th.join()`——等服务端线程结束。quota=1 的语义保证它
  很快退出（accept → respond → return）。join 之后才能安全 `free(json_str)`
  （因为服务端借用了它）。

### 42.5.5 和 ch6 原始设计的差异

ch6 的 memServer 是**裸 TCP**：`accept` 之后直接往流里写 JSON 字符串，
没有 HTTP 协议层（客户端用 `read` 一次性读完）。本章升级为真正的
`std.http.Server`——`receiveHead` 解析请求、`respond` 构造响应。
差异的本质：

| | ch6 memServer | 本章 42.5 |
|---|---|---|
| 传输 | 裸 TCP 字节流 | HTTP/1.1 协议 |
| 请求解析 | 不解析（反正只发一种响应） | `receiveHead` 解析 method/target |
| 路由 | 无 | `GET /stats` → 200，其它 → 404 |
| 客户端 | `read` 一次性读完 | `std.http.Client.fetch` |
| 进程模型 | 两个独立程序 | 同进程两线程 |

裸 TCP 版少一层协议开销，但客户端没法用浏览器/curl/标准 HTTP 库调试；
HTTP 版多几十字节头部，换来整个生态的互操作性。真实监控服务选 HTTP。

---

## 42.6 坑位清单

按「会不会让程序静默算错/泄漏」排序。前 4 条是运行时才会暴露的。

### 一、会静默出错的（最危险）

1. **跨平台内存单位不统一**。`/proc/meminfo` 是 kB；`hw.memsize` 是字节；
   `getrusage().maxrss` 在 macOS 是字节、在 Linux 是 kB。混用不换算，
   数字差 1024 倍——不崩溃、不报错，就是监控数据离谱。纪律：**所有采样
   函数返回字节**，在结构体边界（`MemStats`）才换算成 MB，换算只发生一次。

2. **`kbToMb` 的整除丢精度**。`kb / 1024` 丢掉余数。监控够用，计费不够。
   需要精度时全程 `f64`：`@as(f64, @floatFromInt(kb)) / 1024.0`。

3. **`parseFromSlice` 返回的 `Parsed(T)` 不 deinit 就是泄漏**。它内部
   持有 arena，所有解析分配的内存都挂上面。`defer parsed.deinit()` 一行
   搞定，但**必须在 `return parsed.value` 之前注册**（defer 是逆序执行的，
   先注册后触发）。如果 `T` 里有切片字段指向 arena 内存，`return parsed.value`
   之后那些切片就悬空了——要么在 deinit 前 dupe 到调用方 allocator，
   要么让函数返回 `Parsed(T)` 本身、把 deinit 责任交给调用方。

4. **JSON 键名默认就是 Zig 字段名**。`total_mb` 序列化成 `"total_mb"`，
   不是 `"totalMb"`。和 JavaScript 客户端对接时，要么 Zig 侧用
   `totalMb` 命名（违反 Zig 命名惯例），要么客户端按 snake_case 取键，
   要么用 `Stringify.Options` 里的字段映射（本章不展开）。**在 API 文档里
   写清楚键名风格**，前后端各说各话是联调时最高发的 bug。

### 二、编译期能拦住但报错不友好的

5. **`Stringify.value` 参数顺序写错**。`Stringify.value(value, options, writer)`
   ——writer 在**最后**。写错位置的报错是
   `expected type 'json.Stringify.Options', found pointer`，
   不会告诉你正确顺序。看到 "found pointer" + 涉及 json 就是参数错位。

6. **服务端端口发布的自旋等待没有超时**。`while (port.load(.acquire) == 0) yield`
   在服务端线程提前退出时会死循环（端口永远不来）。本章靠"48200-48220
   几乎不可能全被占"回避了这个问题；生产代码要加 `std.Io.sleep` 限流或
   重试上限：`var retries: u32 = 0; while (port.load(.acquire) == 0) {
   if (retries > 1000) return error.ServerNotReady;
   retries += 1; std.Thread.yield() catch {}; }`。

### 三、设计层面的提醒

7. **`ignore_unknown_fields` 的默认值是 `false`**。开发期这是优点
   （拼错字段名立刻报错），上线前记得评估：如果服务端可能加字段，
   客户端必须开 `ignore_unknown_fields = true`。反过来如果**你**是服务端，
   加字段是安全的——老客户端报 `UnknownField` 是它们没开宽容模式，
   不是你破坏了兼容。

8. **`std.posix` 没封装的系统调用不等于不能调**。`sysctlbyname` 在
   `std.c` 里有 extern 声明，直接调即可（17 章 C interop 的实战）。
   不要因为"标准库没有"就放弃某个系统能力——Zig 的 `std.c` /
   `@extern` 就是为此准备的逃生门。

---

## 42.7 验证方式

三层，与全项目一致（见 2.8 节）：

```bash
cd examples/42_memsrv
zig fmt --check .                                    # 第 1 层：格式 + 语法
zig test main.zig                                    # 第 2 层：7 个 test
zig build-exe main.zig -femit-bin=/tmp/42_memsrv     # 第 3 层：main 也要能编
/tmp/42_memsrv                                        # 第 3 层：真跑一遍
```

第 3 层不可省：`zig test` 不看 `main`，而本章最要紧的 5 个运行时小节
**全在 `main` 里`。

跑完应看到（逐字节抄自 macOS 实测）：

```text
==== 42.1 /proc/meminfo 解析（Linux 理论 + macOS 替代） ====
  样本 MemTotal     = 16384000 kB → 16000 MB
  样本 MemAvailable = 6144000 kB → 6000 MB
  样本 used_percent = 62.5%
  本机总内存（sysctl hw.memsize）= 16384 MB
  本进程峰值 RSS（getrusage）= 2392 KB

  跨平台策略：Linux 读 /proc/meminfo，macOS 用 sysctl，Windows 用 GlobalMemoryStatusEx。
  parseMeminfo() 是纯函数 —— 不碰文件系统，测试用硬编码样本驱动。
==== 42.1 结束 ====
==== 42.2 JSON 序列化：std.json.Stringify.value ====
  MemStats → JSON：{"total_mb":16384,"available_mb":6144,"used_percent":62.5,"timestamp_ms":1700000000000}
  ⚠️ 0.17 签名：Stringify.value(value, options, writer) —— writer 在**最后**
==== 42.2 结束 ====
==== 42.3 JSON 反序列化：parseFromSlice + ignore_unknown_fields ====
  往返 total_mb       = 16384（原 16384）
  往返 available_mb   = 6144（原 6144）
  往返 used_percent   = 62.5（原 62.5）
  往返 timestamp_ms   = 1700000000000（原 1700000000000）
  默认选项 + 未知字段 → error.UnknownField
  .ignore_unknown_fields=true → total_mb=8192（多余字段被跳过）
  ⚠️ parseFromSlice 返回 Parsed(T)，必须 defer parsed.deinit()
==== 42.3 结束 ====
==== 42.4 内存监控循环：3 次采样 ====
  [1] total=16384 MB  available=6144 MB  used=62.5%
  [2] total=16384 MB  available=6144 MB  used=62.5%
  [3] total=16384 MB  available=6144 MB  used=62.5%
  采样 3 次完成（每次间隔 100ms）
==== 42.4 结束 ====
==== 42.5 迷你 HTTP 内存服务：std.http.Server + Client 进程内往返 ====
  GET /stats → 200 OK
  响应体：{"total_mb":16384,"available_mb":6144,"used_percent":62.5,"timestamp_ms":1700000000000}
  服务端已服务 1 条请求
  ✓ 进程内 HTTP 往返完成
==== 42.5 结束 ====
==== 42.6 坑位清单 ====
  ① macOS 没有 /proc —— 跨平台要分支（Linux 读文件 / macOS sysctl / Windows GlobalMemoryStatusEx）
  ② std.json.parseFromSlice 返回 Parsed(T) 拥有内存，必须 defer parsed.deinit()
  ③ .ignore_unknown_fields = true，否则未知字段直接报错
  ④ JSON 序列化 0.17 用 std.json.Stringify.value(x, .{}, writer)，不是旧的 std.json.stringify
  ⑤ 浮点百分比格式化 {d:.1} 保留一位小数
==== 42.6 结束 ====

自检通过
```

注意 42.1 的"本机总内存"和"峰值 RSS"两行：前者在 16 GB 机器上是
16384 MB（确定值），后者每次运行会变（分配器行为）。文档里对前者的
断言是"非 0 且合理"，对后者**不做断言**——这是 31 章确定性纪律的
应用：可复现的进断言，不可复现的只展示。

7 个 test 覆盖的行为面：

| test | 验什么 |
|---|---|
| `parseMeminfo：真实 /proc/meminfo 样本` | 五键样本解析出正确的 total/available，kB→MB 整除正确 |
| `parseMeminfo：缺键 / 空输入 / 乱序` | 空输入全 0、缺 MemAvailable 为 0、乱序不影响解析 |
| `calcUsedPercent：纯函数` | 正常计算、除零防护、全可用返回 0 |
| `JSON 往返：struct → string → struct，字段相等` | `Stringify.value` 与 `parseFromSlice` 互逆 |
| `ignore_unknown_fields：多余字段被跳过` | 宽容模式正常解析、多余字段不影响 |
| `默认选项遇到未知字段报错` | 严格模式对未知字段报 `error.UnknownField` |
| `sampleStats：确定性输出` | 硬编码样本的四个字段值精确匹配 |

---

上一章：[41 zpass](41-zpass.md) · 下一章：[43 并发文件索引器 zlocate](43-zlocate.md)
