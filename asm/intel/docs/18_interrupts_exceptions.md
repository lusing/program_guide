# 中断与异常

CPU 的控制流除了跳转指令，还有两条「被动」通道：**异常**（CPU 自己
产生——除零、缺页、断点）与**中断**（外设产生——时钟、键盘、网卡）。
两者共用一套**向量号 → 处理程序**的分发机制。

本章参考李忠《从实模式到保护模式》第 10 章（实模式中断、8259A）与
第 18 章（IDT、中断门）、李忠《x86汇编语言：编写64位多处理器多线程
操作系统》第 3.11 节与第 5 章（APIC）、Intel SDM Vol.3 第 6 章。
用户态可运行示例在 [`examples/13_exceptions/`](../examples/13_exceptions/)
（3 支，全部在 Windows 实测通过）。

| 示例 | 演示 |
|------|------|
| `seh_div_zero.asm` | 捕获 `0xC0000094`（INT_DIVIDE_BY_ZERO），改 CONTEXT.Rip 跳过出错指令 |
| `seh_int3.asm` | 捕获 `0x80000003`（BREAKPOINT），实测 Windows 的 Rip 回拨坑 |
| `seh_null_write.asm` | 捕获 `0xC0000005`（ACCESS_VIOLATION），在处理器里改 CONTEXT.Rax 让指令重试成功 |

## 1. 异常的分类：fault / trap / abort

| 类别 | 语义 | 压栈的 RIP 指向 | 典型例子 |
|------|------|-----------------|----------|
| **fault** | 「出错的那条指令」 | **指令本身**（修复后可重执行） | #PF 缺页、#GP、#DE 除零 |
| **trap** | 「刚执行完的陷阱」 | 下一条指令 | #DB 单步、#BP 断点（INT3） |
| **abort** | 「现场已不可信」 | 不保证可恢复 | 双重故障 #DF、机器检查 #MC |

fault 的「指向指令本身」正是按需调页能工作的原因：处理程序把页
换入后 `iret`/返回，同一条访存指令**重执行**这次就成功了
（[第 16 章](16_paging.md)第 6 节）。

## 2. 向量号布局

```
0-31    处理器保留（架构定义的异常）
          0 #DE 除零        6 #UD 非法指令     12 #SS 栈段错误
          1 #DB 调试        7 #NM 无协处理器   13 #GP 通用保护
          2 NMI             8 #DF 双重故障    14 #PF 页故障
          3 #BP 断点        9 协处理器段越界   16 #MF x87 错
          4 #OF 溢出       10 #TS 无效TSS     17 #AC 对齐检查
          5 #BR 越界       11 #NP 段不存在    18 #MC 机器检查
                                              19 #XM SIMD 浮点
32-255  可编程使用（外部中断 + 软件中断 int n）
```

实模式的表叫**中断向量表 IVT**（固定在物理 0，1024 字节 = 256×4）；
保护模式起换成**中断描述符表 IDT**——位置不定，由 IDTR 指定，
每项是一个 8 字节（长模式 16 字节）的**门描述符**。

## 3. 从 IVT 到 IDT

### 3.1 实模式：IVT 与 BIOS 中断

实模式下 `int n` 直接取 IVT 第 n 项的 `段:偏移` 跳过去，没有权限
检查。BIOS 把自己的服务例程挂在 `0x10`（显示）、`0x13`（磁盘）、
`0x16`（键盘）等向量上——这就是「BIOS 中断调用」的实质
（李忠 R2P 第 10 章有完整的 RTC 时钟中断实例）。

引导代码全靠这批服务读磁盘、打字符——进入保护模式后就全部失效
（BIOS 是 16 位代码，见[第 15 章](15_real_protected_mode.md)第 3 节）。

### 3.2 保护模式：IDT 与门描述符

IDT 的每一项是三种「门」之一：

| 门 | 进入时 | 用途 |
|----|--------|------|
| **中断门** | 自动清 IF（关中断） | 硬件中断——防止处理中再被嵌套打断 |
| **陷阱门** | 不动 IF | 异常/系统调用——允许嵌套中断 |
| 任务门 | 硬件任务切换 | 基本绝迹（64 位下已删） |

门描述符里带着**目标代码段选择子 + 段内偏移 + DPL**。`int n` 与
中断到达都走同一套查找：`IDTR → IDT[n] → 门 → 目标段:偏移`。
DPL=3 的门（系统调用门）允许用户态主动 `int`，DPL=0 的门用户态
碰即 #GP——这是软件中断作为「受控入口」的权限意义。

### 3.3 长模式的差异

- IDT 项 16 字节，目标地址 64 位，中断压栈 **8 字节对齐**且自动压
  SS:RSP（仅特权级切换时）与 RFLAGS、CS:RIP；
- **IST（中断栈表）**：门里可以指定 TSS 的备用栈指针——NMI/机器检查
  这种「栈都可能坏了」的场景必须用（李忠 2024 第 3.11 节）；
- 压栈后自动压**错误码**的异常只有 8/10/11/12/13/14/17，
  其余没有——处理程序返回用 `iretq` 前要先 `add rsp, 8` 补齐（或用
  约定的「一律补」技巧），这是 64 位内核引导代码的经典错误点。

## 4. 中断控制器：8259A → APIC

外设的中断信号线要先经过**中断控制器**排队转发：

| 世代 | 芯片 | 特点 |
|------|------|------|
| 1981- | **8259A PIC** ×2 级联 | 15 个中断请求线（IRQ0-15），固定优先级，单核时代 |
| 多核时代 | **Local APIC + I/O APIC** | 每核一个 Local APIC（寄存器映射在物理 0xFEE00000），I/O APIC 汇聚外设，**中断可以定向投递到指定核** |

多核系统里「把网卡的硬中断钉在 3 号核、把定时器摊到各核」这类
亲和性调度，靠的就是 APIC 的**中断路由**（ICR 寄存器投递、
最低优先级模式、逻辑目标模式——李忠 2024 第 5 章用一整章展开，
包括 Local APIC 定时器的校准与多核广播 SIPI 的初始化协议）。

x2APIC 是它的后续：寄存器改走 MSR，省掉内存映射，支持更多核。

## 5. 用户态视角：Windows x64 的异常分发

内核之上，应用程序看到的「异常」是另一层封装。写纯汇编时最实用
的入口是**向量化异常处理器（VEH）**：

```nasm
        extern AddVectoredExceptionHandler
        mov ecx, 1                  ; First = 1：排最前
        lea rdx, [veh_handler]
        call AddVectoredExceptionHandler
```

处理器原型 `LONG handler(PEXCEPTION_POINTERS*)`，Win64 约定参数在
RCX。`EXCEPTION_POINTERS` 只有两个指针：

```
[RCX+0]  PEXCEPTION_RECORD   ; +0 是 ExceptionCode（0xC0000005 等）
[RCX+8]  PCONTEXT            ; 64 位 CONTEXT 结构（+0xF8 是 Rip，+0x78 是 Rax）
```

返回 `-1`（EXCEPTION_CONTINUE_EXECUTION）=「用（可修改的）CONTEXT 继续」；
返回 `0` = 交给下一个处理器（最终到 SEH/未处理崩溃）。

`seh_div_zero.asm` 的实测输出：

```
VEH installed, triggering idiv by zero...
[VEH] ExceptionCode = 0xC0000094 (INT_DIVIDE_BY_ZERO)
[VEH] faulting Rip skipped, execution continues
back in main: survived without a crash!
```

三个示例合起来覆盖了「处理器里能干什么」的全部三招：

1. **跳过出错指令**（改 Rip += 指令长度）——fault 的 Rip 指向指令
   本身，不跳过就会无限重触发；
2. **什么都不改，直接继续**——trap 语义（但见下面的坑）；
3. **改寄存器后重试**——把 CONTEXT.Rax 从坏指针换成有效缓冲区地址，
   同一条 `mov [rax], imm32` 重执行成功，缓冲区拿到 `0x5A5A5A5A`。

### 5.1 实测坑：Windows 对 BREAKPOINT 回拨 Rip

`seh_int3.asm` 开发时实测发现（Windows 11 / 2026-09）：CPU 本身是
trap 语义（Rip 应指向 INT3 之后），但 Windows 的用户态分发会把
**Rip 回拨到 0xCC 字节本身**。直接 CONTINUE_EXECUTION 会在同一条
INT3 上**无限重触发**（表现为进程卡死）。处理器必须手动
`add qword [Context->Rip], 1` 跳过 0xCC——这正是调试器实现软件断点
的同款操作（还原原字节 + Rip 越过断点）。

### 5.2 SEH 一句话导览

VEH 是「最先看到异常」的钩子；真正构成 Windows 结构化异常体系的是
**SEH**：基于栈展开（unwind）的 `__try/__except`。x64 SEH 不再用
链表遍历（x86 时代 FS:[0] 链，罗云彬《Win32 汇编》花了整章讲的
`EXCEPTION_REGISTRATION` 在 64 位已成历史），改为**表驱动**：
编译器在 `.pdata/.xdata` 里登记每个函数的栈帧布局与 unwind 代码，
异常时从表里恢复调用链。纯汇编写 unwind 表很繁——从汇编视角
捕获异常，VEH 是性价比最高的路径。

## 6. 本章坑清单

1. **fault 型异常不改 Rip 就 CONTINUE = 死循环**（除零、缺页都如此）。
2. **Windows 对 0x80000003 会把 Rip 回拨到 0xCC 上**——处理器里 +1。
3. **CONTEXT 的 Rip 在 +0xF8、Rax 在 +0x78**（x64 布局），
   现场改寄存器改的就是这份结构。
4. **VEH 里 printf 的输出会被缓冲吞掉**（崩溃路径不走正常退出）——
   打印后立刻 `fflush(NULL)`。
5. **64 位中断处理程序 iretq 前的 error code 对齐**：只有 8/10/11/12/
   13/14/17 压错误码，其余要手工补 8 字节。
6. **进入保护模式后 IVT 就失效**，中断向量全空——引导代码开中断
   前必须先建好 IDT（boot 链示例全程 `cli` 正是为此）。

---

> 上一章：[长模式：进入 64 位](17_long_mode.md) ｜ 返回：[README](../README.md)
