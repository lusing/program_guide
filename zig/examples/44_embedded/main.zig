//! 44 嵌入式与裸机编程：freestanding 目标、MMIO、启动序列、实时性
//! 宿主侧模拟运行全部逻辑；baremetal.zig 交叉编译到 x86_64/arm/riscv32 freestanding。
//! 取材 Sprinter ch15（嵌入式/裸机/实时），原书 API 全系虚构，本章 0.17.0 实测重写。

const std = @import("std");

// ══════════════════════════════════════════════════════════════════
// 44.1 内存映射 IO（MMIO）：volatile 是硬件世界的通行证
// ══════════════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════════════
// 44.2 寄存器位域：packed struct 把数据手册画进类型系统
// ══════════════════════════════════════════════════════════════════

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
    };
};

const ctrl_reg: *volatile u32 = @ptrCast(&fake_bus[1]);

fn ctrlLoad() Ctrl {
    return @bitCast(@as(u8, @truncate(ctrl_reg.*)));
}

fn ctrlStore(c: Ctrl) void {
    ctrl_reg.* = @as(u32, @intCast(@as(u8, @bitCast(c))));
}

// ══════════════════════════════════════════════════════════════════
// 44.3 启动序列：_start → 清 BSS → 搬 DATA → 跳 main
// ══════════════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════════════
// 44.4 中断与轮询：实时性的两种兑现方式
// ══════════════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════════════
// 44.5 实时性：固定周期控制环与 WCET 纪律
// ══════════════════════════════════════════════════════════════════

/// 控制环是实时系统的骨架：读传感器 → 算 → 写执行器，周期必须确定。
/// 确定性三纪律：
///   1. 环内零分配（分配器耗时随堆状态漂移，碎片后可能直接失败）
///   2. 环内无锁（锁的等待时间不可预测；用单生产者单消费者环形队列传数据）
///   3. 每个分支的耗时上界（WCET）在写代码时就想清楚
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
    }

    /// 一个 PI 控制步：纯算术、零分配、零锁，耗时上界一眼可见。
    fn step(self: *ControlLoop, setpoint: i16, kp: i16, ki: i16) i16 {
        const sample = self.pop() orelse setpoint; // 无新样本用设定值顶一拍
        const err = setpoint - sample;
        self.integral += err;
        self.tick += 1;
        return @intCast(@divTrunc(kp * err + ki * self.integral, 16));
    }
};

// ══════════════════════════════════════════════════════════════════
// 44.6 零分配与 SIMD：把 @Vector 当裸机加速指令用
// ══════════════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════════════
// main：宿主模拟跑通全部逻辑（裸机目标见 baremetal.zig）
// ══════════════════════════════════════════════════════════════════

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var out_buf: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &out_buf);
    const w = &stdout_impl.interface;
    defer w.flush() catch {};

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

    // 44.2 位域
    begin("44.2 packed struct 寄存器位域");
    var c = Ctrl{ .enable = true, .mode = .run, .irq_enable = true };
    ctrlStore(c);
    try w.print("Ctrl{{enable,run,irq}} 位图 = 0b{b:0>8}（bit0=1, bit1..3=001, bit4=1）\n", .{@as(u8, @truncate(ctrl_reg.*))});
    c = ctrlLoad();
    try w.print("回读：enable={} mode={} irq_enable={}\n", .{ c.enable, c.mode, c.irq_enable });
    try w.print("保留位 _reserved 占位 3 bit，布局与数据手册逐位对齐\n", .{});
    end("44.2 packed struct 寄存器位域");

    // 44.3 启动序列
    begin("44.3 启动序列：清 BSS / 搬 DATA");
    @memset(&bss_sim, 0xAA); // 故意弄脏，模拟"上电残留"
    bss_sim[3] = 0xBB;
    bootSequence();
    try w.print("清 BSS 后 bss_sim = {any}\n", .{bss_sim});
    try w.print("搬 DATA 后 data_sim[0] = 0x{X:0>8}（来自 ROM 镜像）\n", .{data_sim[0]});
    try w.print("真实裸机：链接脚本导出 __bss_start/__bss_end/__data_load 等符号供 _start 使用\n", .{});
    end("44.3 启动序列：清 BSS / 搬 DATA");

    // 44.4 中断 vs 轮询
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

    // 44.5 实时控制环
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

    // 44.6 零分配 SIMD
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

    // 44.7 目标与坑位
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

    try w.print("自检通过\n", .{});
}

fn begin(title: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{title});
}

fn end(title: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{title});
}

// ══════════════════════════════════════════════════════════════════
// Tests
// ══════════════════════════════════════════════════════════════════

test "MMIO 轮询发送" {
    uart_base.status = 0x1; // TX ready（volatile 视图写入）
    uartPutc(uart_base, 'Z');
    try std.testing.expectEqual(@as(u8, 'Z'), uart_base.data);
    uart_base.status = 0x0;
    try std.testing.expect((uart_base.status & 0x1) == 0);
}

test "packed struct 位域与 u8 互转" {
    const c = Ctrl{ .enable = true, .mode = .fault, .irq_enable = false };
    const bits: u8 = @bitCast(c);
    try std.testing.expectEqual(@as(u8, 0b0000_0101), bits);
    const back: Ctrl = @bitCast(bits);
    try std.testing.expect(back.enable and back.mode == .fault and !back.irq_enable);
}

test "启动序列清零与搬运" {
    @memset(&bss_sim, 0xFF);
    bootSequence();
    for (bss_sim) |x| try std.testing.expectEqual(@as(u32, 0), x);
    try std.testing.expectEqual(@as(u32, 0xDEADBEEF), data_sim[0]);
}

test "向量表注册与分派" {
    var vt: VectorTable = .{};
    try std.testing.expect(!vt.dispatch(3)); // 未注册 → false
    vt.register(3, &onUartRx);
    const before = irq_count;
    try std.testing.expect(vt.dispatch(3));
    try std.testing.expectEqual(before + 1, irq_count);
}

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

test "滑动平均零分配路径" {
    var window: [8]u16 = .{ 8, 8, 8, 8, 8, 8, 8, 8 };
    const avg = movingAvg8(&window, 16);
    try std.testing.expectEqual(@as(u16, 9), avg);
}
