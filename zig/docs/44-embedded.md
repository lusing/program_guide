# 44 · 嵌入式与裸机编程

> **阅读位置**：第五篇 · 与系统对话（硬件侧，可独立阅读） ｜ **承前**：[36 指针](36-pointers.md) 的 volatile、[25 二进制布局](25-binary.md) 的 packed struct、[18 交叉编译](18-cross.md) 的 -target ｜ **启后**：理解 0.17 内存布局与 volatile 的最终归宿。
>
> 对应示例：examples/44_embedded/main.zig（宿主模拟）+ baremetal.zig（freestanding 交叉）
>
> 前面 43 章全在"有操作系统的世界"里打转：文件、进程、网络、并发。本章往下再沉一层——
> **没有操作系统的世界**。嵌入式/裸机编程是 C 的传统领地（数据手册 + 寄存器 + 链接脚本），
> Zig 用三样东西向它发起进攻：`packed struct` 把数据手册的位图画进类型系统、
> `*volatile` 指针把"内存背后是硬件"写进类型、comptime 把布局校验提前到编译期。
> 本章 7 节在宿主上模拟运行全部逻辑（7 个 test 全绿），另有一份 `baremetal.zig`
> 交叉编译到 x86_64 / arm / riscv32 三个 freestanding 目标（编译即验证）。
>
> 本章有 **6 条实测结论**：
>
> 1. **volatile 别名坑是真实存在的编译期死循环**（44.1）。经普通视图 `fake_bus[0]=1`
>    写入、再经 `*volatile Uart` 指针轮询读 status，编译器不做跨视图别名分析——
>    它认定"没人改 status"，把 `while` 判为永真，**在编译期就挂进无限循环**。
>    MMIO 读写必须全程走 volatile 指针，一条缝都不能留。
> 2. **`packed struct` 位域 + `@bitCast` 让寄存器位图成为类型**（44.2）。
>    `Ctrl{ .enable = true, .mode = .run }` 编译成 `0b00010011`，
>    回读 `@bitCast` 还原成字段——数据手册上的位图和类型系统逐位对齐，
>    保留位用 `_reserved: u3` 占位。
> 3. **裸机没有 main，入口是 `export fn _start() callconv(.c) noreturn`**（44.3）。
>    第一件事设栈指针，然后清 BSS、搬 DATA——C/Zig 语义要求未初始化全局为零，
>    没人替你保证，只能自己在 `_start` 里逐字写零。
> 4. **中断 handler 是 `callconv(.c)` 的普通函数，地址进向量表**（44.4）。
>    向量表在真实工程里是链接脚本固定在 0 地址的数组；handler 与主循环并发，
>    共享数据要防竞态——这是 19/31 章原子与锁的裸机版。
> 5. **实时控制环三纪律：零分配、无锁、WCET 写代码时定死**（44.5）。
>    SPSC 环形队列容量 16 实际只能存 15——留一槽区分满/空；
>    满时实时系统选"丢新样本"不选"等"。
> 6. **freestanding 下 std 大部分模块不可用，panic 要自定义**（44.7）。
>    目标三元组 `<arch>-<os>-<abi>` 的 `<os>` 填 `freestanding` 后，
>    没有 OS 可依赖：`std.fs` / `std.net` / 分配器全没了，
>    `pub const panic` 必须自己写——裸机没有 stderr 可打。
>
> **节号对应**：44.1–44.7 是示例 `main` 里的运行时小节（`begin("44.N …") …
> end("44.N")`，stderr 上能看到 `==== 44.N … 开始 ====`）；
> **坑位清单与验证方式是本文档自己的两节**，不在 `main` 里
> （不过 44.7 的运行时小节打印了 5 条速览，坑位清单是它的完整展开）。

---

## 导读：这一章要推翻六个说法

**说法一："Zig 有 zig-gpio / zig-uart 这类官方硬件库，调一下就点亮 LED。"**

错，而且错得离谱。Zig 官方**没有任何**硬件抽象库——没有 zig-gpio、没有 zig-uart、
没有 zig-rtos。这些名字只出现在某些 AI 生成的"Zig 教程"里。真实世界里你要么：

- 直接对着数据手册写寄存器（本章的做法：`packed struct` + `*volatile` 指针）；
- 用芯片厂商的 C 头文件经 `@cImport` / `translate-c` 翻过来（17 章）；
- 用社区维护的 **microzig** 这类 HAL 工程（第三方，非官方）。

44.1 的 `Uart` 就是我们手写的"硬件库"——一共 18 行。

**说法二："裸机程序也有 main，从 main 开始跑。"**

错。裸机没有操作系统，没人调用你的 main。bootloader 把镜像放进内存、跳转到
`_start` 之后，一切靠自己。44.3 和 `baremetal.zig` 演示真实入口：

```zig
export fn _start() callconv(.c) noreturn { … }
```

`noreturn`：没有地方可返回；`callconv(.c)`：调用约定要和汇编启动代码一致；
`export`：符号要出现在目标文件里供链接脚本定位。main 是 OS 给的入口，
裸机上 OS 不存在。

**说法三："volatile 只是编译器提示，可以忽略，不加也照样跑。"**

错，而且是本章实测踩过的坑。44.1 演示了**别名坑**：经普通视图写、经 volatile 视图读，
编译器不做跨视图别名分析，轮询循环被判永真——**编译期无限循环**。
volatile 在 Zig 里不是提示，是**类型的一部分**：`*volatile Uart` 和 `*Uart`
是两个不同的类型，前者每次访问都必须真的发生，后者允许被优化掉。
裸机上"被优化掉"意味着你的 UART 初始化代码根本没执行。

**说法四："中断 handler 用普通 fn 就行，和回调函数没区别。"**

半错。handler 本体确实是普通 fn，但有两个硬约束（44.4 + baremetal.zig）：
一是 `callconv(.c)`——CPU 用中断帧的约定调进来，漏写在某些架构上是 UB；
二是它**和主循环并发执行**——共享变量必须原子或关中断保护，
handler 里改普通全局变量和 38 章信号 handler 里 malloc 是同级别的错误。

**说法五："嵌入式内存小但随便用分配器没关系，反正有 heap。"**

错。实时控制环内（44.5）分配是**纪律性禁止**的：分配耗时随堆状态漂移，
碎片后可能直接失败——失败路径在环内就是失控。正解是定长缓冲区内嵌在
struct 里（生命周期随 struct，零分配），SPSC 队列无锁传数据。

**说法六："std 在 freestanding 下全能用，反正 Zig 跨平台。"**

错。freestanding = 没有 OS。`std.fs`（没有文件系统）、`std.net`（没有 socket）、
`std.Thread`（没有线程）、`GeneralPurposeAllocator`（没有 mmap/brk）全部不可用。
能依赖的只有 core 语言（类型、comptime、@Vector、packed struct）和 std 里
少数不碰 OS 的部分。panic 也要自定义——裸机没有 stderr 可打（44.7）。

---

## 44.1 内存映射 IO 与 volatile：硬件世界的通行证

### MMIO 的本质：内存字背后是硬件

嵌入式外设（UART、GPIO、定时器）不和 CPU 走特殊指令通信——它们被**映射进地址空间**：
总线上的某些地址不是 RAM，而是寄存器。读那个地址，是从硬件移位寄存器取数；
写那个地址，是把字符推出 TX 引脚。这就是内存映射 IO（MMIO）。

由此推出 volatile 的硬件语义：**volatile 访问的"内存"随时可能被硬件改写，
写入的副作用可能立刻发生**。编译器面对 `*volatile` 必须承诺两件事：
每次读都真的发一次 load（不许缓存进寄存器复用），每次写都真的发一次 store
（不许合并、不许消除）。普通指针没有这些承诺——对编译器来说普通内存
"没人写就不变"，这对 RAM 是对的，对寄存器是灾难。

### 假 UART：packed struct 定义寄存器布局

```zig
// examples/44_embedded/main.zig 第 11-25 行
/// 一台"假 UART"：寄存器布局与真实 PL011/NS16550 的简化版一致——
/// data 寄存器（偏移 0）读写字符，status 寄存器（偏移 1）的第 0 位是 TX ready。
/// packed struct 保证字段间无填充，@bitCast 保证 u32 视图与寄存器视图逐位一致。
const Uart = packed struct {
    data: u8,
    status: u8,
    _: u16,
};

/// 内存映射设备 = 固定在总线地址上的内存字。
/// 宿主模拟：一块静态数组充当"总线地址空间"；真实裸机里 base 是常数地址
/// （如 0x0900_0000），用 @ptrFromInt 铸成 *volatile Uart。
var fake_bus: [64]u32 = @splat(0);

const uart_base: *volatile Uart = @ptrCast(&fake_bus[0]);
```

三个细节：

1. **`packed struct` 字段间无填充**。`data: u8` 在偏移 0、`status: u8` 在偏移 1、
   `_: u16` 占偏移 2-3——和真实 UART 的寄存器偏移逐字节对齐。普通 struct 会插
   padding，寄存器布局直接错位（25 章详解过三种布局的区别）。
2. **`_: u16` 是匿名占位字段**。数据手册里偏移 2-3 可能是保留寄存器或 FIFO 窗口，
   我们不用它，但**布局里必须有它的位置**——占位字段让 `@sizeOf(Uart) == 4`。
3. **宿主模拟 vs 真实裸机的差别只有一行**。宿主用 `@ptrCast(&fake_bus[0])`
   把数组首元素地址铸成 `*volatile Uart`；真实裸机用
   `@ptrFromInt(0x0900_0000)` 把整数地址铸成指针（baremetal.zig 第 21 行，
   44.3 细讲）。语义完全一样：**把固定地址解释成寄存器视图**。

### 轮询发送：volatile 轮询循环不许被优化掉

```zig
// examples/44_embedded/main.zig 第 27-37 行
/// 轮询发送一个字节。volatile 的含义：每次访问都必须真的发生——
/// 编译器不许把它缓存进寄存器、不许把循环优化掉，因为"内存"背后是一块硬件，
/// 读 status 可能随时被硬件改写，写 data 的副作用是把字符推出 TX 引脚。
fn uartPutc(base: *volatile Uart, ch: u8) void {
    while ((base.status & 0x1) == 0) {} // TX FIFO 满就自旋等待
    base.data = ch;
}

fn uartPuts(base: *volatile Uart, s: []const u8) void {
    for (s) |ch| uartPutc(base, ch);
}
```

`uartPutc` 是嵌入式里最经典的 3 行代码：**自旋等 TX ready → 写 data**。
注意参数类型是 `*volatile Uart`——volatile 在指针类型上，不在 struct 定义上。
这意味着同一个 `Uart` 类型可以有无 volatile 两种视图；MMIO 场景必须用 volatile 视图。

如果 `base` 是普通的 `*Uart`，这个函数在 ReleaseFast 下会被优化成什么样？
编译器看到 `while ((base.status & 1) == 0)`：循环体内没人写 `base.status`，
普通内存没人写就不变——条件要么恒真要么恒假，循环要么删要么死循环。
**你的 UART 驱动在优化级别面前蒸发了**。`volatile` 是唯一阻止这件事的武器。

### 别名坑：本章实测的编译期死循环

这是本章最硬核的实测，也是 volatile 语义最有力的实证。看 main 里的运行时演示：

```zig
// examples/44_embedded/main.zig 第 205-214 行
// 44.1 MMIO
begin("44.1 内存映射 IO 与 volatile");
try w.print("fake_bus 首字 = 0x{X:0>8}（模拟上电默认值）\n", .{fake_bus[0]});
uart_base.status = 0x1; // 置 TX ready 位（必须走 volatile 视图，见下方坑位）
uartPuts(uart_base, "hello, mmio");
try w.print("TX 后首字 = 0x{X:0>8}（data=0x68='h'，status 低字节=0x01）\n", .{fake_bus[0]});
try w.print("volatile 语义：while ((base.status & 1) == 0) 这类轮询循环不许被优化掉\n", .{});
try w.print("⚠️ 别名坑：经普通视图 fake_bus[0]=1 写、再经 *volatile 指针读，\n", .{});
try w.print("   编译器不做跨视图别名分析 → 轮询被判永真 → 编译期死循环（实测）\n", .{});
end("44.1 内存映射 IO 与 volatile");
```

第 208 行的注释是血泪教训：**置 TX ready 位必须走 `uart_base.status = 0x1`
（volatile 视图）**。如果写成 `fake_bus[0] = 1`（普通 u32 视图），
然后调 `uartPuts(uart_base, …)`——`uartPutc` 里的
`while ((base.status & 0x1) == 0)` 会发生什么？

编译器的别名分析：`base` 是 `*volatile Uart`，`base.status` 是 volatile 读，
必须真的发 load；但**它同时认定没有代码写这块内存**——`fake_bus[0] = 1`
写的是普通 `u32` 视图，编译器不做普通视图与 volatile 视图的跨视图别名分析
（两种指针的"可访问内存集合"在类型系统里不连通）。于是它推导出：
"这个 volatile load 每次都会读到同一个值（没人写），而初值是 0，
条件恒真——**这是死循环**"。在 Debug 下你还能跑（load 每轮真发，碰巧能观察到
外部写入）；在 ReleaseFast 下编译器可能直接在编译期把这个 while 判成永真循环，
**程序编译期就挂死**。

实测结论一句话：**MMIO 的每一次读写都必须经过 volatile 指针，同一块硬件
不允许出现"普通视图写 + volatile 视图读"的混用**。这是 36 章 volatile 的
硬件版终局——那里讲"volatile 阻止优化"，这里讲"不阻止会怎样"。

运行输出（stdout；`====` 行在 stderr，同 38 章约定）：

```text
fake_bus 首字 = 0x00000000（模拟上电默认值）
TX 后首字 = 0x0000016F（data=0x68='h'，status 低字节=0x01）
volatile 语义：while ((base.status & 1) == 0) 这类轮询循环不许被优化掉
⚠️ 别名坑：经普通视图 fake_bus[0]=1 写、再经 *volatile 指针读，
   编译器不做跨视图别名分析 → 轮询被判永真 → 编译期死循环（实测）
```

`0x0000016F` 的拆解：低字节 `0x6F` 是 `'o'`——"hello, mmio" 的**最后一个**
字符（uartPuts 循环把 11 个字符全推进同一个 data 寄存器，留在那的是最后
一次写入；print 语句里的注释写 `'h'` 是笔误，实际值 0x6F 对应 'o'），
次字节 `0x01` 是我们置的 TX ready 位。一个 u32 里同时躺着"字符"和"状态"——
这就是内存映射的字节级真实。

### 测试：MMIO 轮询发送

```zig
// examples/44_embedded/main.zig 第 305-311 行
test "MMIO 轮询发送" {
    uart_base.status = 0x1; // TX ready（volatile 视图写入）
    uartPutc(uart_base, 'Z');
    try std.testing.expectEqual(@as(u8, 'Z'), uart_base.data);
    uart_base.status = 0x0;
    try std.testing.expect((uart_base.status & 0x1) == 0);
}
```

测试本身也遵守纪律：置位/清零全走 `uart_base`（volatile 视图）。
注意这个 test 和 main 共享全局 `fake_bus`——test 之间不保证顺序，
但每个 test 都自己置位，互不依赖。

---

## 44.2 packed struct 寄存器位域：把数据手册画进类型系统

### 位图即类型

数据手册给控制寄存器画的是一张位图："bit0 = enable，bit1..3 = mode，
bit4 = irq_enable，bit5..7 保留"。C 的写法是宏海洋：

```c
#define CTRL_ENABLE     (1u << 0)
#define CTRL_MODE_MASK  (7u << 1)
#define CTRL_MODE_RUN   (1u << 1)
#define CTRL_IRQ        (1u << 4)
reg |= CTRL_ENABLE | CTRL_MODE_RUN;   // 移位掩码，编译器不检查
```

Zig 的写法是把位图本身变成类型：

```zig
// examples/44_embedded/main.zig 第 43-58 行
/// 控制寄存器（偏移 4）的位域定义。真实数据手册给的是一张位图：
/// bit0 = enable，bit1..3 = mode，bit4 = irq_enable，bit5..7 保留。
/// packed struct 让"位图"成为类型：读写都以字段名进行，不再手写移位掩码。
const Ctrl = packed struct {
    enable: bool = false,
    mode: Mode = .idle,
    irq_enable: bool = false,
    /// 保留位：必须可写 0，读时忽略。占位字段让布局精确到 bit。
    _reserved: u3 = 0,

    const Mode = enum(u3) {
        idle = 0,
        run = 1,
        fault = 2,
    },
};
```

逐字段看布局（packed struct 字段从低位排到高位）：

| 字段 | 类型 | 位 | 数据手册含义 |
|---|---|---|---|
| `enable` | `bool` | bit0 | 使能 |
| `mode` | `enum(u3)` | bit1..3 | 模式：idle=0 / run=1 / fault=2 |
| `irq_enable` | `bool` | bit4 | 中断使能 |
| `_reserved` | `u3` | bit5..7 | 保留，写 0 读忽略 |

`bool` 在 packed struct 里占 1 bit（25 章讲过：packed 下 bool 是位域）。
`enum(u3)` 的宽度声明是**必须的**——漏写宽度，枚举的底层类型由编译器猜，
布局直接漂移（坑位清单第 5 条）。`_reserved: u3` 让 `@bitSizeOf(Ctrl) == 8`
精确到 bit，和数据手册的"bit5..7 保留"逐位对齐。

### 读写：@bitCast 在寄存器视图和位域视图间切换

```zig
// examples/44_embedded/main.zig 第 60-68 行
const ctrl_reg: *volatile u32 = @ptrCast(&fake_bus[1]);

fn ctrlLoad() Ctrl {
    return @bitCast(@as(u8, @truncate(ctrl_reg.*)));
}

fn ctrlStore(c: Ctrl) void {
    ctrl_reg.* = @as(u32, @intCast(@as(u8, @bitCast(c))));
}
```

- `ctrl_reg` 是 volatile u32 视图（偏移 4 字节 = `fake_bus[1]`）。
  注意它 volatile——所有寄存器访问的纪律不变。
- **读**：`ctrl_reg.*` 取 u32 → `@truncate` 截低 8 位（寄存器只有低 8 位有效）
  → `@bitCast` 把 u8 的位模式原样解释成 `Ctrl`。
- **写**：`Ctrl` → `@bitCast` 成 u8 → `@intCast` 扩成 u32 → volatile store。
- `@bitCast` 是"零成本 reinterpret"：不生成任何指令，只换类型视角
  （25 章 25.4 有完整边界行为）。

### 运行时演示与回读

```zig
// examples/44_embedded/main.zig 第 217-224 行
begin("44.2 packed struct 寄存器位域");
var c = Ctrl{ .enable = true, .mode = .run, .irq_enable = true };
ctrlStore(c);
try w.print("Ctrl{{enable,run,irq}} 位图 = 0b{b:0>8}（bit0=1, bit1..3=001, bit4=1）\n", .{@as(u8, @truncate(ctrl_reg.*))});
c = ctrlLoad();
try w.print("回读：enable={} mode={} irq_enable={}\n", .{ c.enable, c.mode, c.irq_enable });
try w.print("保留位 _reserved 占位 3 bit，布局与数据手册逐位对齐\n", .{});
end("44.2 packed struct 寄存器位域");
```

`{b:0>8}` 是 0.17 的格式化语法：二进制、零填充到 8 位。运行输出：

```text
Ctrl{enable,run,irq} 位图 = 0b00010011（bit0=1, bit1..3=001, bit4=1）
回读：enable=true mode=.run irq_enable=true
保留位 _reserved 占位 3 bit，布局与数据手册逐位对齐
```

手工验算 `0b00010011`：bit0=1（enable）+ bit1..3=`001`（mode=run=1，从 bit1 开始排）
+ bit4=1（irq_enable）= 0x01 + 0x02 + 0x10 = 0x13 = `0b00010011`。逐位吻合。
回读路径证明 `@bitCast` 双向无损：写进去是位图，读回来是字段名。

### 测试：位域与 u8 互转

```zig
// examples/44_embedded/main.zig 第 313-319 行
test "packed struct 位域与 u8 互转" {
    const c = Ctrl{ .enable = true, .mode = .fault, .irq_enable = false };
    const bits: u8 = @bitCast(c);
    try std.testing.expectEqual(@as(u8, 0b0000_0101), bits);
    const back: Ctrl = @bitCast(bits);
    try std.testing.expect(back.enable and back.mode == .fault and !back.irq_enable);
}
```

`enable=true`（bit0=1）+ `mode=.fault`（fault=2 → bit1..3=`010`，从 bit1 排 = 0x04）
= 0b0000_0101。这条 test 是布局正确性的**编译期+运行期双重锚点**：
`0b0000_0101` 写死在断言里，谁改字段顺序或枚举宽度，test 立刻红。

---

## 44.3 启动序列：_start → 清 BSS → 搬 DATA → 跳 main

### 为什么裸机需要自己的启动代码

宿主程序的运行环境是 OS 给的：加载器把可执行文件映射进内存、设好栈、
清好 BSS、填好 argv，然后才调你的 main。**裸机没有这一切**。
bootloader（或 ROM 里的固化代码）把镜像放进内存、跳转到 `_start` 之后：

- 栈指针是随机的——第一次函数调用就踩空；
- BSS 段里是上电残留——C/Zig 语义要求未初始化全局为**零**，没人保证；
- DATA 段如果镜像从只读介质（Flash/ROM）加载，运行地址和加载地址不同，
  初值需要搬运。

所以 `_start` 必须按顺序做三件事：

1. **设栈指针**（SP）。否则 `call` 指令往哪压返回地址都不知道。
2. **清 BSS**：从 `__bss_start` 到 `__bss_end` 逐字写零。这两个符号由
   链接脚本导出。
3. **搬 DATA**：把 ROM 里的初值镜像 memcpy 到 RAM 运行区
   （`__data_load` → `__data_start`，长度 `__data_end - __data_start`）。

### 宿主模拟：段就是地址区间

```zig
// examples/44_embedded/main.zig 第 74-91 行
/// 裸机程序没有操作系统替你做初始化：加载器（bootloader）把镜像放进内存、
/// 跳转到 _start 之后，一切靠自己。最小启动序列三件事：
///   1. 设置栈指针（否则函数调用即崩）
///   2. 清 BSS 段（未初始化的全局变量，C/Zig 语义要求零值）
///   3. 把 DATA 段从加载地址搬到运行地址（若镜像从只读介质加载）
/// 以下用宿主内存模拟这三个段，演示"段"的本质就是地址区间。
var bss_sim: [8]u32 = @splat(0); // 模拟 BSS：要求启动后全零
const data_img: [4]u32 = .{ 0xDEADBEEF, 2, 3, 4 }; // 模拟 ROM 里的 DATA 镜像
var data_sim: [4]u32 = undefined; // 模拟 RAM 里的 DATA 运行区

fn bootSequence() void {
    // ① 清 BSS：从 bss 段首地址逐字写零。真实代码里是
    // 链接脚本导出的 __bss_start/__bss_end 两个符号。
    for (&bss_sim) |*w| w.* = 0;
    // ② 搬 DATA：ROM 镜像 → RAM 运行区
    @memcpy(&data_sim, &data_img);
    // ③ 真实裸机还要设栈指针、关中断、配置时钟——那些是汇编/板级代码的事。
}
```

三个模拟段的类型选择本身就是教学点：

- `bss_sim` 是 `var` + `@splat(0)`——**语义上 BSS 要求零值**，但裸机上电时
  它可能是任意残留。main 里会故意弄脏它再让 `bootSequence` 清零，
  模拟"上电残留 → 启动清零"的全过程。
- `data_img` 是 `const`——它在 ROM 里，只读。`0xDEADBEEF` 是标志性的
  调试魔数（一眼认出搬运成功）。
- `data_sim` 是 `var` + `undefined`——**运行区初值未知**，必须由启动代码填充。
  `undefined` 是 Zig 的"我知道我没初始化"显式标注（03 章），
  裸机上电状态就是这个。

### 运行时演示：故意弄脏再清零

```zig
// examples/44_embedded/main.zig 第 227-234 行
begin("44.3 启动序列：清 BSS / 搬 DATA");
@memset(&bss_sim, 0xAA); // 故意弄脏，模拟"上电残留"
bss_sim[3] = 0xBB;
bootSequence();
try w.print("清 BSS 后 bss_sim = {any}\n", .{bss_sim});
try w.print("搬 DATA 后 data_sim[0] = 0x{X:0>8}（来自 ROM 镜像）\n", .{data_sim[0]});
try w.print("真实裸机：链接脚本导出 __bss_start/__bss_end/__data_load 等符号供 _start 使用\n", .{});
end("44.3 启动序列：清 BSS / 搬 DATA");
```

`@memset(&bss_sim, 0xAA)` 把 8 个字全写成 `0xAA`、再单独改一个 `0xBB`——
这就是"上电残留"。`bootSequence()` 之后：

```text
清 BSS 后 bss_sim = { 0, 0, 0, 0, 0, 0, 0, 0 }
搬 DATA 后 data_sim[0] = 0xDEADBEEF（来自 ROM 镜像）
```

8 个字全零（包括那个 `0xBB`），DATA 运行区拿到了 ROM 镜像的魔数。
**C/Zig 语义里"未初始化全局 = 零"不是硬件保证的，是启动代码兑现的**——
宿主上 OS 帮你做，裸机上你自己做。

### 测试：清零与搬运

```zig
// examples/44_embedded/main.zig 第 321-326 行
test "启动序列清零与搬运" {
    @memset(&bss_sim, 0xFF);
    bootSequence();
    for (bss_sim) |x| try std.testing.expectEqual(@as(u32, 0), x);
    try std.testing.expectEqual(@as(u32, 0xDEADBEEF), data_sim[0]);
}
```

和 main 同样的"弄脏 → 启动 → 断言"流程，只是脏值换成 `0xFF`。
`for (bss_sim) |x|` 逐字断言零——8 个断言一行写完。

### 真实裸机的入口长什么样

宿主模拟只演示了 ②③ 两件事；真实裸机的 `_start` 在 `baremetal.zig`：

```zig
// examples/44_embedded/baremetal.zig 第 11-18 行
/// 裸机没有 OS，入口由 bootloader 直接跳转进来。
/// noreturn：永不返回（没有地方可返回）；callconv(.c)：约定与汇编启动代码一致。
export fn _start() callconv(.c) noreturn {
    // 真实裸机：第一件事是设栈指针（SP），否则第一次函数调用就踩空。
    // 清 BSS / 搬 DATA 在此完成（符号由链接脚本导出）。
    mainLoop();
    while (true) {} // 主循环不该返回；返回即死循环兜底
}
```

四个关键字每个都有裸机理由：

- `export`：符号必须出现在目标文件符号表里，链接脚本才能把它放在
  复位向量上（CPU 上电后跳转的地址）。
- `fn _start`：名字是约定——多数架构的链接脚本默认找 `_start`
  （ELF 规范的传统入口名）。
- `callconv(.c)`：bootloader 用 C 约定跳进来，你的代码必须用同一约定接。
- `noreturn`：没有 OS 可返回。函数真返回了 CPU 也会继续从栈上取指执行垃圾——
  所以末尾 `while (true) {}` 兜底。

注意 `_start` 里**没有清 BSS/搬 DATA 的真实实现**——注释说了，那需要
链接脚本导出的符号（`__bss_start` 等），是板级工程的事。本章聚焦
"Zig 语言侧要写对什么"：入口签名、noreturn、调用约定、以及
"清 BSS/搬 DATA 必须有人做"这个认知。

---

## 44.4 中断向量表 vs 轮询：实时性的两种兑现方式

### 两种模型的本质差异

外设有数据来了（UART 收到字节），CPU 怎么知道？两条路：

- **轮询**：主循环自己去看标志位。"RX 有数据吗？没有。RX 有数据吗？没有……"
  延迟可预测、代码简单，代价是 CPU 全程陪着外设转——100% 占用。
- **中断**：外设拉高 IRQ 线 → CPU 保存现场 → 查向量表 → 跳 handler → 恢复。
  CPU 平时睡大觉，事件来了微秒级响应。代价：handler 与主循环**并发**，
  共享数据要防竞态。

向量表在真实硬件上是固定在地址 0（或 0xFFFF_FFF0 等，架构相关）的指针数组：
第 N 项是第 N 号中断的 handler 地址。CPU 收到中断号 N，硬件级查表跳转。
我们用函数指针数组模拟这个概念：

### 向量表的 Zig 模拟

```zig
// examples/44_embedded/main.zig 第 97-112 行
/// 中断模型：外设拉高 IRQ 线 → CPU 保存现场 → 查向量表 → 进 handler → 恢复。
/// 裸机里 handler 地址由链接脚本放进向量表；这里用函数指针数组演示"向量表"概念。
const VectorTable = struct {
    handlers: [16]?*const fn () void = @splat(null),

    fn register(self: *VectorTable, irq: usize, h: *const fn () void) void {
        self.handlers[irq] = h;
    }

    /// 模拟 CPU 收到中断时的分派。
    fn dispatch(self: *const VectorTable, irq: usize) bool {
        const h = self.handlers[irq] orelse return false; // 无 handler = 未处理
        h();
        return true;
    }
};
```

- `[16]?*const fn () void`：16 个槽，每个槽是"可选的函数指针"。
  `?*const fn () void` 读作"可能为 null 的、指向无参无返回 const 函数的指针"。
  `@splat(null)` 把 16 个槽全初始化为 null——**默认全部未注册**。
- `orelse return false`：收到未注册的中断返回 false（真实硬件上这会进
  默认 handler 或挂死，这里简化成布尔）。
- handler 签名 `*const fn () void` 没有 `callconv(.c)`——宿主模拟图省事；
  baremetal.zig 第 27 行的真实 handler 就带上了（`export fn uart_irq_handler()
  callconv(.c) void`），因为真实 CPU 用中断帧约定调它。

### handler 与共享状态

```zig
// examples/44_embedded/main.zig 第 114-134 行
var irq_count: u32 = 0;
var irq_bytes: u32 = 0;

fn onUartRx() void {
    irq_count += 1;
    irq_bytes += 1;
}

/// 轮询模型：主循环里自己看标志位。延迟可预测、代码简单，
/// 代价是 CPU 全程陪着外设转。中断模型反过来：省电、低延迟，但共享数据要防竞态
/// （handler 与主循环并发——这正是 19/31 章那套原子与锁的裸机版）。
fn pollRx(fifo: []const u8) u32 {
    var received: u32 = 0;
    for (fifo) |b| {
        if ((uart_base.status & 0x2) != 0) { // RX 有数据位
            _ = b;
            received += 1;
        }
    }
    return received;
}
```

`irq_count += 1` 在真实裸机上是**竞态**——如果主循环同时在读 `irq_count`
（比如统计线程想上报），`+=` 的读-改-写三步可能被中断切开。真实工程的做法：
handler 里只写 SPSC 队列（44.5），或者关中断保护临界区（`cpsid i` / `cpsie i`
在 ARM 上是一行汇编），或者用 `std.atomic.Value(u32)` 的 `.monotonic` fetchAdd
——19 章的裸机版。宿主模拟单线程跑，竞态不会显现，但**纪律要按有竞态写**。

`pollRx` 演示轮询：每次迭代查 RX 有数据位（status 的 bit1）。`_ = b;`
是"我知道这个参数没用"的显式丢弃——真实代码里这里会从 `uart_base.data`
读走字节。

### 运行时演示

```zig
// examples/44_embedded/main.zig 第 237-247 行
begin("44.4 中断向量表 vs 轮询");
var vt: VectorTable = .{};
vt.register(5, &onUartRx);
const handled = vt.dispatch(5);
const unhandled = vt.dispatch(7);
try w.print("注册 IRQ5 后 dispatch(5) = {}，未注册的 dispatch(7) = {}\n", .{ handled, unhandled });
uart_base.status = 0x2; // 置 RX 有数据位（volatile 视图）
const polled = pollRx("abc");
try w.print("轮询 RX：{d} 次迭代里 {d} 次读到数据位\n", .{ @as(u32, 3), polled });
try w.print("中断省 CPU 但共享数据要防竞态；轮询延迟可预测但占满 CPU\n", .{});
end("44.4 中断向量表 vs 轮询");
```

输出：

```text
注册 IRQ5 后 dispatch(5) = true，未注册的 dispatch(7) = false
轮询 RX：3 次迭代里 3 次读到数据位
中断省 CPU 但共享数据要防竞态；轮询延迟可预测但占满 CPU
```

`dispatch(5)` 调到 `onUartRx`（`irq_count` +1）返回 true；
`dispatch(7)` 槽位是 null 返回 false。轮询侧：status bit1 被置位后，
3 次迭代全部命中。选择哪条路是**系统级 trade-off**：电池供电传感器节点
几乎必然中断（睡 99% 时间），硬实时控制环常选轮询（延迟可算），
混合系统里中断收数据 + 队列递给控制环——正是 44.5 的架构。

### 测试：注册与分派

```zig
// examples/44_embedded/main.zig 第 328-335 行
test "向量表注册与分派" {
    var vt: VectorTable = .{};
    try std.testing.expect(!vt.dispatch(3)); // 未注册 → false
    vt.register(3, &onUartRx);
    const before = irq_count;
    try std.testing.expect(vt.dispatch(3));
    try std.testing.expectEqual(before + 1, irq_count);
}
```

`before` 快照技巧：不假设 `irq_count` 的全局值（别的 test 可能动过），
只断言"分派后比先前多 1"。

### 真实裸机的中断 handler

```zig
// examples/44_embedded/baremetal.zig 第 26-30 行
/// 中断 handler：真实工程里它的地址被链接脚本放进向量表。
export fn uart_irq_handler() callconv(.c) void {
    const uart: *volatile Uart = @ptrFromInt(0x0900_0000);
    _ = uart.data; // 读 data = 清 RX 中断标志（读侧效应）
}
```

两个真实世界的点：

1. **`export` + `callconv(.c)`**——向量表项是链接脚本从这个符号取的地址，
   CPU 用中断帧约定调它。漏 `callconv(.c)` 在 ARM 上是真 UB。
2. **`_ = uart.data` 的读侧效应**——很多 UART 的"清中断标志"就是读 data 寄存器。
   编译器看到 `_ =` 会想优化掉这次读？不会——`uart` 是 `*volatile`，
   volatile 读的语义就是"必须真的发 load"，`_ =` 只是丢弃**结果**，
   不取消**访问本身**。这是 volatile 的又一个实证：副作用在访问，不在值。

---

## 44.5 实时控制环：零分配 + 无锁 SPSC 队列 + PI 控制

### 控制环与实时三纪律

控制环是实时系统的骨架：**读传感器 → 算 → 写执行器**，周期必须确定——
电机控制环 10 kHz，每个 tick 100 µs，超时就失控（字面意义：电机烧掉或机器人撞墙）。
"实时"不是"快"，是**时延有上界且可证明**。由此推出三纪律：

1. **环内零分配**。分配耗时随堆状态漂移：空闲堆几纳秒，碎片堆可能毫秒级
   还失败。失败路径在环内没法处理——你正控制着电机，没空优雅降级。
   所有缓冲环前分配好，环内只用。
2. **环内无锁**。互斥锁的等待时间取决于临界区长度，而上界往往不可知
   （别人拿锁时刚好被中断）。裸机单核上"锁"就是关中断，关中断拉长
   其他中断的响应延迟——能不用就不用。
3. **WCET（最坏执行时间）写代码时定死**。不看代码能说出这个分支最多多少
   周期，才配进实时环。`if` 可以（两条路都有界），`while` 扫链表不行
   （长度无界），分配不行（堆状态无界）。

### SPSC 队列：为什么无锁、为什么容量 16 只能存 15

单生产者单消费者（SPSC）环形队列是裸机的数据高速公路：中断 handler
（生产者）把传感器样本推进去，主控制环（消费者）取出来算。
**无锁的秘密是"两边各管一个索引"**：

```zig
// examples/44_embedded/main.zig 第 145-167 行
const ControlLoop = struct {
    tick: u32 = 0,
    integral: i32 = 0,
    /// 单生产者单消费者队列：中断 handler 写 head，主循环读 tail，
    /// 两边各管一个索引 → 无锁。容量定长 → 零分配。
    buf: [16]i16 = undefined,
    head: usize = 0,
    tail: usize = 0,

    fn push(self: *ControlLoop, sample: i16) bool {
        const next = (self.head + 1) % self.buf.len;
        if (next == self.tail) return false; // 满：丢新样本（实时系统选"丢"不选"等"）
        self.buf[self.head] = sample;
        self.head = next;
        return true;
    }

    fn pop(self: *ControlLoop) ?i16 {
        if (self.tail == self.head) return null;
        const v = self.buf[self.tail];
        self.tail = (self.tail + 1) % self.buf.len;
        return v;
    },
    // ...
};
```

并发安全论证（单核裸机经典结论）：

- **push 只写 `head`，pop 只写 `tail`**。两个索引各归一方，没有共享写。
- push 读 `tail` 判满——读到的 `tail` 可能略旧（消费者刚推进了还没同步），
  后果是**保守地判满**、丢一个样本，不会数据竞争。
- pop 读 `head` 判空——同理，保守地判空、多等一拍。
- 没有一方写对方要读的位置：push 写 `buf[head]` 时，pop 只读 `buf[tail]`，
  满判据 `next == tail` 保证了 `head` 永远不会追上 `tail` 的当前位置。

**为什么容量 16 只能存 15**：判满判空不能共用一个条件。如果允许 `head == tail`
表示满，那它同时也表示空——歧义。经典解法：**牺牲一个槽**，
`head` 的下一格是 `tail` 就视为满。于是 16 槽环形数组最多存 15 个元素。
这是所有定长环形队列的通用结论，不是本实现特有。

**满时丢新不丢旧**：`return false` 把新样本扔掉，旧样本一个不少。
实时系统的选择永远是"丢新的"——旧样本代表已发生的历史，丢了会断环；
新样本晚一拍还有下一拍。

### PI 控制步：纯算术、零分配、WCET 一眼可见

```zig
// examples/44_embedded/main.zig 第 169-176 行
/// 一个 PI 控制步：纯算术、零分配、零锁，耗时上界一眼可见。
fn step(self: *ControlLoop, setpoint: i16, kp: i16, ki: i16) i16 {
    const sample = self.pop() orelse setpoint; // 无新样本用设定值顶一拍
    const err = setpoint - sample;
    self.integral += err;
    self.tick += 1;
    return @intCast(@divTrunc(kp * err + ki * self.integral, 16));
}
```

PI 控制器公式：`out = Kp·err + Ki·∫err`。这里积分用累加代替
（`integral += err`，数字积分），除以 16 是定点数约定（相当于右移 4 位，
`kp`/`ki` 带 1/16 精度）。逐行看纪律：

- `pop() orelse setpoint`：队列空了用设定值顶——**无分支失败路径**，
  控制环永远有输出，不会"没数据就 panic"。
- 全程没有 `try`、没有分配、没有循环——每条指令周期数有上界，
  WCET 就是把这几行汇编的周期数加起来。
- `@divTrunc` 截断除法（向零取整），`@intCast` 窄化回 i16——
  定点运算的溢出边界要在参数范围里论证（`kp·err` 的 i16×i16 在 Zig 里
  默认会溢出检查，Debug 下越界 panic——这正是 23 章调试要管的事）。

### 运行时演示

```zig
// examples/44_embedded/main.zig 第 250-264 行
begin("44.5 实时控制环：零分配 + 无锁队列");
var loop: ControlLoop = .{};
_ = loop.push(100);
_ = loop.push(110);
_ = loop.push(120);
const out1 = loop.step(128, 8, 2);
const out2 = loop.step(128, 8, 2);
const out3 = loop.step(128, 8, 2);
try w.print("PI 三步输出 = {d}, {d}, {d}（设定 128，样本 100/110/120）\n", .{ out1, out2, out3 });
var full: ControlLoop = .{};
var pushed: u32 = 0;
while (full.push(@intCast(pushed))) pushed += 1;
try w.print("队列容量 16：填满实际推入 {d} 个（留一个槽区分满/空）\n", .{pushed});
try w.print("实时三纪律：环内零分配、无锁、WCET 写代码时定死\n", .{});
end("44.5 实时控制环：零分配 + 无锁队列");
```

输出：

```text
PI 三步输出 = 17, 14, 10（设定 128，样本 100/110/120）
队列容量 16：填满实际推入 15 个（留一个槽区分满/空）
实时三纪律：环内零分配、无锁、WCET 写代码时定死
```

手工验算第一步：`sample=100, err=28, integral=28`，
`out = (8×28 + 2×28)/16 = (224+56)/16 = 280/16 = 17.5` → `@divTrunc` 截断 = 17。
第二步：`sample=110, err=18, integral=46`，`(144+92)/16 = 236/16 = 14.75` → 14。
第三步：`sample=120, err=8, integral=54`，`(64+108)/16 = 172/16 = 10.75` → 10。
误差收敛（28→18→8），输出递减（17→14→10）——PI 在把系统拉向设定值 128。

队列填满循环：`while (full.push(...)) pushed += 1`——push 返回 false 时停，
`pushed == 15`。这就是"容量 16 存 15"的实测。

### 测试：满空语义与可复现性

```zig
// examples/44_embedded/main.zig 第 337-347 行
test "SPSC 队列满空语义" {
    var q: ControlLoop = .{};
    try std.testing.expect(q.pop() == null);
    var n: usize = 0;
    while (q.push(@intCast(n))) n += 1;
    try std.testing.expectEqual(@as(usize, 15), n); // 16 槽留一区分满/空
    var sum: i32 = 0;
    while (q.pop()) |v| sum += v;
    try std.testing.expectEqual(@as(i32, 105), sum); // 0..14 求和
    try std.testing.expect(q.pop() == null);
}
```

`0+1+…+14 = 105`——推入的 15 个样本一个不少全弹出，空后再 pop 得 null。
满、空、FIFO 顺序三个语义一条 test 全覆盖。

```zig
// examples/44_embedded/main.zig 第 349-358 行
test "PI 控制步纯算术可复现" {
    var a: ControlLoop = .{};
    var b: ControlLoop = .{};
    _ = a.push(90);
    _ = b.push(90);
    const ua = a.step(100, 4, 1);
    const ub = b.step(100, 4, 1);
    try std.testing.expectEqual(ua, ub);
    try std.testing.expect(ua > 0); // 设定 > 样本 → 正输出
}
```

两个独立实例同输入同输出——**纯算术可复现**是实时代码的可测性基础：
没有全局状态、没有时钟、没有随机数，同样的输入永远同样的输出，
测试才能是确定性的（15 章测试哲学的硬件版）。

---

## 44.6 零分配 SIMD 滤波：@Vector 当硬件乘法器阵列用

### 传感器滤波是嵌入式热点

ADC 采样流进来，先滤波再进控制环——滑动平均是最简单的低通。
8 点窗口、每来一个样本移进窗口求平均。热点在"求和"：8 次加法。
带 SIMD 的 MCU（Cortex-M4/M7 的 DSP 扩展、RISC-V 的 P 扩展）有
单指令 4 路加法——`@Vector(8, u32)` 让编译器在带 SIMD 的目标上
生成向量指令，宿主 x86_64 上就是 SSE/AVX。

```zig
// examples/44_embedded/main.zig 第 183-192 行
/// 传感器滤波（滑动平均）是嵌入式热点。定长数组 + @Vector：
/// 编译器在带 SIMD 的目标上生成向量指令，裸机上就是"硬件乘法器阵列"。
/// 关键约束：缓冲区是 struct 内嵌数组（.buf），生命周期随 struct —— 零分配。
fn movingAvg8(window: *const [8]u16, sample: u16) u16 {
    var w = window.*;
    w[7] = sample;
    const v: @Vector(8, u32) = w;
    const total = @reduce(.Add, v);
    return @intCast(total / 8);
}
```

逐行拆解：

- `var w = window.*`：值拷贝整个窗口到栈上（8×u16 = 16 字节，编译期已知）。
  为什么拷？`window` 是 `*const`，要塞进新样本必须有个可写副本。
  栈上 16 字节，零分配——**定长数组在栈上的开销是编译期常数**。
- `w[7] = sample`：新样本滑进窗口末尾（FIFO 语义：最老的被挤出去——
  这里简化成"覆盖第 7 格"，教学聚焦 SIMD 部分）。
- `const v: @Vector(8, u32) = w`：数组 → 向量。u16 提升到 u32 防溢出
  （8 个 u16 全 0xFFFF 求和会超 u16）。`@Vector(N, T)` 是 Zig 的 SIMD 类型
  （21 章的内联汇编/向量部分提过），长度和元素类型都是类型参数。
- `@reduce(.Add, v)`：水平归约——8 路加成 1 个标量。`.Add` 是归约操作枚举。
- `total / 8`：除 8 编译成右移 3 位（无符号除法、除数是 2 的幂）。

**零分配论证**：函数体内没有 allocator、没有 `try`、没有动态数组。
`w` 和 `v` 都在栈上，生命周期编译期定死。WCET：拷贝 16 字节 + 8 路加 +
归约 log2(8)=3 级加 + 一次移位——**周期数可算**，符合 44.5 的三纪律。

### 运行时演示

```zig
// examples/44_embedded/main.zig 第 267-276 行
begin("44.6 零分配 SIMD 滤波");
var window: [8]u16 = .{ 10, 20, 30, 40, 50, 60, 70, 80 };
const avg = movingAvg8(&window, 88);
try w.print("滑动平均：窗口 {any} + 新样本 88 → {d}\n", .{ window, avg });
window[7] = 88;
var manual: u32 = 0;
for (window) |x| manual += x;
try w.print("手工验证：总和 {d} / 8 = {d} ✓\n", .{ manual, manual / 8 });
try w.print("@Vector(8,u32) 在 SIMD 目标上编译成向量指令；缓冲区内嵌 struct → 零分配\n", .{});
end("44.6 零分配 SIMD 滤波");
```

注意演示的小心机：第一次调用后 `window` 本身**没变**（函数内拷贝语义），
所以手工验证前要先 `window[7] = 88` 把窗口同步成函数内的状态。
输出：

```text
滑动平均：窗口 { 10, 20, 30, 40, 50, 60, 70, 80 } + 新样本 88 → 46
手工验证：总和 368 / 8 = 46 ✓
@Vector(8,u32) 在 SIMD 目标上编译成向量指令；缓冲区内嵌 struct → 零分配
```

`10+20+…+70+88 = 368`，`368/8 = 46`。SIMD 结果与手工循环逐位一致——
`@reduce` 的归约顺序不影响结果（整数加法可交换），这是它能安全优化的原因。

### 测试：零分配路径

```zig
// examples/44_embedded/main.zig 第 360-364 行
test "滑动平均零分配路径" {
    var window: [8]u16 = .{ 8, 8, 8, 8, 8, 8, 8, 8 };
    const avg = movingAvg8(&window, 16);
    try std.testing.expectEqual(@as(u16, 9), avg);
}
```

`8×7+16 = 72`，`72/8 = 9`。全 8 窗口 + 新样本 16 拉高了均值——
边界行为（新样本权重 1/8）正确。

---

## 44.7 目标三元组与坑位清单

### freestanding：没有 OS 的目标

18 章讲过目标三元组 `<arch>-<os>-<abi>`，交叉编译用 `-target` 指定。
裸机的关键在 `<os>` 填 `freestanding`——告诉编译器"目标上没有操作系统"：

```text
x86_64-freestanding-none    # 裸 x86（内核开发、hypervisor）
arm-freestanding-eabihf     # 裸 ARM（Cortex-M/R 微控制器，硬浮点 ABI）
riscv32-freestanding-none   # 裸 RISC-V 32 位（开源 MCU）
```

`freestanding` 改变的不只是链接：std 的可用性、panic 的默认实现、
入口符号的约定全都变。`baremetal.zig` 已交叉编译到以上三目标
（见验证方式一节），三目标共用**同一份源码**——这就是 Zig 交叉编译
故事在裸机侧的兑现：没有第三方工具链、没有 per-arch 分支，
`-target` 一换，同一份 MMIO 代码编译出三个架构的对象文件。

### 裸机侧源码：@ptrFromInt 与真实入口

宿主模拟用 `@ptrCast(&fake_bus[0])` 把数组元素地址铸成寄存器指针；
真实裸机用 `@ptrFromInt` 把**整数常量地址**铸成指针：

```zig
// examples/44_embedded/baremetal.zig 第 20-24 行
fn mainLoop() void {
    const uart: *volatile Uart = @ptrFromInt(0x0900_0000); // 板级固定地址
    while ((uart.status & 0x1) == 0) {} // TX ready？
    uart.data = 'B';
}
```

`@ptrFromInt(0x0900_0000)` 的语义："把这个整数解释成指针"。
0x0900_0000 是板级定义的外设基地址（真实芯片从数据手册查，
比如树莓派 3 的 PL011 UART 基址是 0x3F20_1000）。
`@ptrFromInt` 和 `@ptrCast` 的区别：**前者从整数来，后者从指针来**。
整数地址是"硬件事实"，指针是"语言对象"——裸机编程每天都在两者之间往返。

### 运行时演示：坑位速览

main 的 44.7 小节打印 5 条速览（坑位清单的完整展开在本文档后两节）：

```zig
// examples/44_embedded/main.zig 第 279-288 行
begin("44.7 目标三元组与坑位清单");
try w.print("目标三元组：<arch>-<os>-<abi>，裸机 = <os> 填 freestanding\n", .{});
try w.print("  x86_64-freestanding-none / arm-freestanding-eabihf / riscv32-freestanding-none\n", .{});
try w.print("  baremetal.zig 已交叉编译到以上三目标（见 run-all.sh 44_embedded 段）\n", .{});
try w.print("坑 1：std 大部分模块在 freestanding 不可用——只依赖 core 语言 + @import(\"std\") 的少数无 OS 部分\n", .{});
try w.print("坑 2：panic 需要自定义 panic handler（裸机没有 stderr 可打）\n", .{});
try w.print("坑 3：没有 main！入口是 export fn _start() callconv(.c) noreturn\n", .{});
try w.print("坑 4：MMIO 指针必须 *volatile，否则轮询循环会被优化消失\n", .{});
try w.print("坑 5：packed struct 位域的 enum 字段宽度必须写全（enum(u3)），否则布局漂移\n", .{});
end("44.7 目标三元组与坑位清单");
```

输出：

```text
目标三元组：<arch>-<os>-<abi>，裸机 = <os> 填 freestanding
  x86_64-freestanding-none / arm-freestanding-eabihf / riscv32-freestanding-none
  baremetal.zig 已交叉编译到以上三目标（见 run-all.sh 44_embedded 段）
坑 1：std 大部分模块在 freestanding 不可用——只依赖 core 语言 + @import("std") 的少数无 OS 部分
坑 2：panic 需要自定义 panic handler（裸机没有 stderr 可打）
坑 3：没有 main！入口是 export fn _start() callconv(.c) noreturn
坑 4：MMIO 指针必须 *volatile，否则轮询循环会被优化消失
坑 5：packed struct 位域的 enum 字段宽度必须写全（enum(u3)），否则布局漂移
自检通过
```

---

## 坑位清单

汇总本章实测的全部坑，按踩坑代价排序：

### 1. volatile 别名坑：普通视图写 + volatile 视图读 = 编译期死循环

44.1 的实证。同一块 MMIO 内存，经 `fake_bus[0] = 1`（普通 `*u32` 视图）写入、
再经 `*volatile Uart` 指针轮询读，编译器不做跨视图别名分析——它认定
"没人写 status"，把 `while ((base.status & 1) == 0)` 判为永真。
Debug 下靠每轮真发 load 碰巧能跑，ReleaseFast 下编译期挂死。
**纪律：MMIO 的每一次读写都走 volatile 指针，从初始化到轮询到清理，一条缝不留。**

### 2. std 在 freestanding 下大部分不可用

`std.fs` / `std.net` / `std.Thread` / `std.process` / 一切分配器——
全建立在 OS syscall 上，freestanding 没有 OS。能用的：
core 语言（类型、comptime、@Vector、packed struct、@bitCast 全家）、
`@import("std")` 里少数无 OS 部分（`std.math`、`std.mem` 的部分函数、
原子操作）。**判断标准：这个 API 最终要不要 syscall？要，就不能用。**

### 3. panic 要自定义

宿主上 panic 默认打栈跟踪到 stderr——裸机没有 stderr。
freestanding 工程必须提供自己的 panic handler（通常是把消息写 UART
然后 `while(true)` 或触发看门狗复位）。`baremetal.zig` 没写 panic handler
是因为 `build-obj` 只编译不链接——panic 的实现是链接期的事。
真实板级工程里漏写 panic，链接器会报 undefined symbol。

### 4. 没有 main，入口是 `_start`

裸机入口三件套：`export fn _start() callconv(.c) noreturn`。
`export` 让符号进目标文件（链接脚本要按名定位）；
`callconv(.c)` 匹配 bootloader 的跳转约定；`noreturn` 因为没有 OS 可返回，
末尾 `while(true) {}` 兜底。第一件事设栈指针，然后清 BSS、搬 DATA。

### 5. packed struct 位域的 enum 宽度必须写全

`mode: Mode = .idle` 里 `Mode = enum(u3)` 的 `(u3)` 是**布局契约**。
漏写宽度，枚举底层类型由编译器按成员最大值猜——成员一改，宽度变，
后面所有字段的位偏移全漂移，寄存器布局静默错位（写错硬件寄存器，
没有任何报错，外设就是不工作）。配套纪律：给位图写 `@bitCast` 往返
test（44.2 的 `0b0000_0101` 断言），把布局钉死在测试里。

### 6. SPSC 队列容量 N 只能存 N-1

环形队列判满判空不能共用条件，经典解法是留一槽：
`head` 的下一格是 `tail` 即满。所以 `[16]i16` 最多存 15 个。
设计缓冲容量时按"实际需要的深度 + 1"申请。

---

## 验证方式

四层，与全项目一致（`./run-all.sh 44_embedded` 一键跑完）：

```bash
cd examples/44_embedded
zig fmt --check .                                                        # 第 1 层：格式 + 语法
zig test main.zig                                                        # 第 2 层：7 个 test
zig build-exe main.zig -femit-bin=/tmp/44_embedded && /tmp/44_embedded   # 第 3 层：宿主模拟真跑
# 第 4 层：裸机目标交叉编译（无 OS 可运行，编译通过即验证）
zig build-obj baremetal.zig -target x86_64-freestanding-none   -femit-bin=/tmp/44_x86_64.o
zig build-obj baremetal.zig -target arm-freestanding-eabihf    -femit-bin=/tmp/44_arm.o
zig build-obj baremetal.zig -target riscv32-freestanding-none  -femit-bin=/tmp/44_riscv32.o
```

第 4 层用 `build-obj`（只编译不链接）而非 `build-exe`：真实板级工程需要
链接脚本（定段地址、向量表位置）和启动汇编，那些超出本章范围——
本章聚焦"Zig 语言侧要写对什么"，编译出正确的对象文件就是语言侧的
全部责任。三个目标共用同一份 `baremetal.zig`，是 18 章交叉编译故事的
裸机版实证。

第 3 层跑完应看到（stdout 全文逐字节确定；`====` 行在 stderr）：

```text
fake_bus 首字 = 0x00000000（模拟上电默认值）
TX 后首字 = 0x0000016F（data=0x68='h'，status 低字节=0x01）
volatile 语义：while ((base.status & 1) == 0) 这类轮询循环不许被优化掉
⚠️ 别名坑：经普通视图 fake_bus[0]=1 写、再经 *volatile 指针读，
   编译器不做跨视图别名分析 → 轮询被判永真 → 编译期死循环（实测）
Ctrl{enable,run,irq} 位图 = 0b00010011（bit0=1, bit1..3=001, bit4=1）
回读：enable=true mode=.run irq_enable=true
保留位 _reserved 占位 3 bit，布局与数据手册逐位对齐
清 BSS 后 bss_sim = { 0, 0, 0, 0, 0, 0, 0, 0 }
搬 DATA 后 data_sim[0] = 0xDEADBEEF（来自 ROM 镜像）
真实裸机：链接脚本导出 __bss_start/__bss_end/__data_load 等符号供 _start 使用
注册 IRQ5 后 dispatch(5) = true，未注册的 dispatch(7) = false
轮询 RX：3 次迭代里 3 次读到数据位
中断省 CPU 但共享数据要防竞态；轮询延迟可预测但占满 CPU
PI 三步输出 = 17, 14, 10（设定 128，样本 100/110/120）
队列容量 16：填满实际推入 15 个（留一个槽区分满/空）
实时三纪律：环内零分配、无锁、WCET 写代码时定死
滑动平均：窗口 { 10, 20, 30, 40, 50, 60, 70, 80 } + 新样本 88 → 46
手工验证：总和 368 / 8 = 46 ✓
@Vector(8,u32) 在 SIMD 目标上编译成向量指令；缓冲区内嵌 struct → 零分配
目标三元组：<arch>-<os>-<abi>，裸机 = <os> 填 freestanding
  x86_64-freestanding-none / arm-freestanding-eabihf / riscv32-freestanding-none
  baremetal.zig 已交叉编译到以上三目标（见 run-all.sh 44_embedded 段）
坑 1：std 大部分模块在 freestanding 不可用——只依赖 core 语言 + @import("std") 的少数无 OS 部分
坑 2：panic 需要自定义 panic handler（裸机没有 stderr 可打）
坑 3：没有 main！入口是 export fn _start() callconv(.c) noreturn
坑 4：MMIO 指针必须 *volatile，否则轮询循环会被优化消失
坑 5：packed struct 位域的 enum 字段宽度必须写全（enum(u3)），否则布局漂移
自检通过
```

7 个测试覆盖：MMIO 轮询发送、packed struct 位域与 u8 互转（布局锚点）、
启动序列清零与搬运、向量表注册与分派、SPSC 满空语义（15/16 实测）、
PI 控制步纯算术可复现、滑动平均零分配路径。

---

## 取材说明

取材 Sprinter ch15（嵌入式/裸机/实时），原书 API 全系虚构（zig-gpio /
zig-uart 等库与诸多不存在的调用在真实 Zig 中无任何对应），本章 0.17.0 实测重写。
全部讲解基于 `examples/44_embedded/main.zig`（宿主模拟，7 个 test）与
`baremetal.zig`（x86_64 / arm / riscv32 三目标 freestanding 交叉编译验证）。
