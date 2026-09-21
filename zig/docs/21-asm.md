# 21 · 内联汇编与底层工具箱

> 对应示例：`examples/21_asm/`（x86_64 与 aarch64 各一份实现，comptime 守卫放行这两个目标）
>
> 读得懂、写得对、只在刀刃上用。

## 21.1 语法解剖

```zig
fn addImm(x: u64) u64 {
    var r = x;
    asm volatile ("add $5, %[r]"          // ① 模板串（AT&T 语法）
        : [r] "+r" (r),                    // ② 输出（具名约束）
                                           // ③ 输入（本例没有）
    );                                     // ④ 破坏列表（本例没有）
}
```

四段结构：**模板串**（`%[名字]` 引用操作数——LLVM 的具名占位，0.14 改形后的现行写法）、**输出**（`=` 只写 / `+` 读写）、**输入**、**clobber 列表**（告诉编译器哪些寄存器被蹂躏了）。多行模板用 `\\` 续行。**x86 默认 AT&T 语法**（`add 源, 目的`、立即数 `$5`、寄存器不写 `%`——`%` 是操作数占位专属）。

## 21.2 约束速查

| 约束 | 含义 |
|---|---|
| `"r"` | 任意通用寄存器 |
| `"+r"` | 同一寄存器又进又出（读写） |
| `"=r"` | 只输出 |
| `"{eax}"` | 固定绑定 eax（寄存器名花括号） |
| `"m"` / `"i"` | 内存操作数 / 立即数 |

## 21.3 volatile：防止蒸发

```zig
asm volatile ("rdtsc" ...)   // 有副作用的指令（读时钟、IO 端口）必须 volatile
```

没有 `volatile` 的 asm 块，编译器发现"输出没人用"可以整块删掉。**输出被使用**的纯计算（21.1）不需要；**为副作用而执行**的（rdtsc、端口 IO、屏障）必须 `volatile`。

## 21.4 实战：时间计数器计时

x86_64 的 `rdtsc`（CPU 时间戳计数器——纳秒级微基准；23 章有 `io` 时钟的宏观版）：

```zig
fn rdtsc() u64 {
    var lo: u32 = undefined;
    var hi: u32 = undefined;
    asm volatile (
        \\rdtsc
        : [lo] "={eax}" (lo),      // 时间戳低 32 位固定落在 eax
          [hi] "={edx}" (hi),      // 高 32 位固定落在 edx
    );
    return (@as(u64, hi) << 32) | lo;
}
```

两个输出**绑定固定寄存器**（rdtsc 的硬件规定），`\\` 单行指令也用多行串写法（模板串习惯统一）。

aarch64（Apple Silicon、Linux ARM 服务器）没有 rdtsc——对应物是**虚拟计数器** `cntvct_el0`，一条 `mrs` 直接读出 64 位，比 x86 版还省事：

```zig
fn cntvct() u64 {
    var v: u64 = undefined;
    asm volatile (
        \\mrs %[v], cntvct_el0
        : [v] "=r" (v),            // 64 位输出，寄存器交给编译器挑
    );
    return v;
}
```

两份实现之上包一层**编译期选路**的入口，调用方就不用关心架构了：

```zig
fn cycles() u64 {
    return switch (builtin.cpu.arch) {
        .x86_64 => rdtsc(),
        .aarch64 => cntvct(),
        else => unreachable,
    };
}
```

## 21.5 comptime 架构守卫

```zig
comptime {
    switch (builtin.cpu.arch) {
        .x86_64, .aarch64 => {},   // 有实现的目标放行
        else => @compileError("本章汇编示例实现了 x86_64 与 aarch64（其他架构思路见正文）"),
    }
}
```

汇编天然绑架构——**comptime 守卫**让代码在没实现的目标上**编译期就爆**（18 章 builtin 的应用）。跨架构支持就是 18.2 的模式：`switch (builtin.cpu.arch)` 每个 arch 一个实现，编译期选路，**未选中的分支不进产物**（交叉编译 aarch64 时 x86 的 AT&T 模板根本不会被 LLVM 看到）。

> **Apple Silicon（M 系 Mac）**：本示例给出 aarch64 实现后，`./run-all.sh` 在 arm64 Mac 上也能跑通 21 章（此前是 `error: 本章汇编示例针对 x86_64`）。本机（Intel x86_64 macOS）只能**交叉编译验证**：`zig build-exe main.zig -target aarch64-macos` 通过，反汇编可见 `mrs x8, CNTVCT_EL0`——运行验证待 arm64 真机。

## 21.6 底层工具箱：extern struct 与 @bitCast

```zig
const Pair = extern struct { a: u32, b: u32 };   // C 布局保证（17 章）
const p = Pair{ .a = 1, .b = 2 };
const as_u64: u64 = @bitCast(p);                  // 0x0000000200000001（低位 a）
```

`extern struct`（C ABI 布局）+ `@bitCast`（同宽重解释，03 章）+ `packed struct`（位精确，08 章）——和汇编配套的三件套：内存长什么样、怎么按位读出来，全在类型系统里说清。调用约定（`callconv(.c)`、`.Interrupt"` 等）在函数签名上标，裸机开发再细究。

## 21.7 坑位清单

1. **模板占位是 `%[名]`**：写成 `{[名]}`（网上旧提案语法）LLVM 直接拒绝——`Expected an identifier after {`。
2. **clobber 列表漏写**：汇编里动了没声明的寄存器，编译器还拿它存变量——数据神不知鬼不觉地坏；改了内存加 `"memory"`。
3. **忘 volatile**：输出没人用就整块被删——副作用指令全灭。
4. **AT&T 源目的顺序**：`add $5, %[r]` 是"r += 5"不是"5 += r"——Intel 语序刚好相反，混写必错。
5. **能不用就不用**：编译器 intrinsics（`@popCount`/`@ctz`/`@byteSwap`...）和 std 覆盖了绝大多数需求——asm 是最后手段，且每处都要注释"为什么非它不可"。
6. **aarch64 的立即数要带 `#`、目的在前**：`add %[r], %[r], #5`——照抄 x86 的 AT&T 语序（`add $5, %[r]`）在 arm64 上是非法指令；`mrs` 的输出必须是 64 位寄存器（用 `"=r"` 让编译器挑，别钉死某个 xN）。

---

上一章：[20 文件与 IO](20-files-io.md) · 下一章：[22 进程](22-process.md)
