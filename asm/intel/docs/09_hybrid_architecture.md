# Intel 混合架构（P核/E核）

Intel 自 12 代酷睿（Alder Lake）起引入了混合架构（Hybrid Architecture），将不同类型的核心集成在同一芯片上，兼顾高性能与高能效。

## 混合架构简介

混合架构包含两种核心类型：

- **P核（Performance Core，性能核）**：基于 Golden Cove（12 代）、Raptor Cove（13/14 代）、Lion Cove（Core Ultra 200S）等微架构。P核追求高 IPC 和高频率，支持超线程（Hyper-Threading），一个物理核可表现为两个逻辑核。
- **E核（Efficiency Core，能效核）**：基于 Gracemont（12-14 代）、Crestmont（Core Ultra）等 Mont 系列微架构。E核单线程性能较低但能效比极高，不支持超线程，以多核集群方式提供吞吐能力。

操作系统调度器根据负载将线程分配到不同核心：高优先级任务上 P核，后台任务上 E核。

## CPUID 检测核心类型

程序可通过 CPUID Leaf 0x1A（Intel Hybrid Information）查询当前运行所在的核心类型。查询前需先确认 CPUID 最大 leaf >= 0x1A：

```nasm
; 先确认 CPUID 最大 leaf >= 0x1A
mov eax, 0
cpuid
cmp eax, 0x1A
jb .no_hybrid

; 执行 Leaf 0x1A
mov eax, 0x1A
xor ecx, ecx
cpuid
; EAX bits 31:24 = Core Type
shr eax, 24
and eax, 0xFF
; 0x20 = Atom (E核), 0x40 = Core (P核), 0x00 = 非混合架构
```

核心类型值含义：`0x20` 表示 Atom/E核，`0x40` 表示 Core/P核，`0x00` 表示该 CPU 不采用混合架构或未报告核心类型。

## 指令集差异

P核与 E核在指令集支持上存在差异：

| 特性 | P核 | E核 |
|------|-----|-----|
| SSE4.2 | 支持 | 支持 |
| AVX2 | 支持 | 支持 |
| AVX-512 | 部分型号支持 | 通常不支持 |
| 超线程 | 支持 | 不支持 |

> 2026-09 在 i7-12700F（Alder Lake）上逐核实测（方法见下文绑核一节）：
> 全部 20 个逻辑处理器（P核与 E核）均报 AVX2 = YES；AVX-512 一律 NO——
> Golden Cove 的 P核物理上有 AVX-512 单元，但消费级 12 代因为 E核（Gracemont）
> 不支持而**整片禁用**。混合架构真正的指令集分界只有 AVX-512 一条。

程序可通过 CPUID Leaf 7（ECX=0）检测具体特性支持：
- EBX bit 5 = AVX2
- EBX bit 16 = AVX-512F（基础指令集）

```nasm
mov eax, 7
xor ecx, ecx
cpuid
test ebx, 0x20       ; bit 5 = AVX2
test ebx, 0x10000    ; bit 16 = AVX-512F
```

## Intel Thread Director

Intel Thread Director 是混合架构的硬件线程调度机制。它通过监控每个核心的负载与能力，向操作系统提供调度建议。操作系统通过 HFI（Hardware Feedback Interface）读取这些信息，做出调度决策。

对应用层而言，线程在 P核还是 E核上运行由操作系统决定，程序无法直接控制。但可通过 `SetThreadAffinityMask` 等 Windows API 间接影响调度偏好。macOS 上对应的行为由内核调度器与 QoS（`pthread_set_qos_class_self_np`、Grand Central Dispatch 的队列优先级）表达，汇编层面能做的仍然是同样的 `CPUID` 页 `0x1A` 探测。

本机实测注记（i7-12700F / Windows 11）：不绑核连续运行 11 次，`cpuid_hybrid.exe` 每次都报告 P核（`0x40`）——前台短促进程默认落在 P核上，与 Thread Director「前台优先 P核」的调度方向一致。想看到 E核，得用亲和掩码把进程钉到 LP16–19（见下文实测一节）。

## 编程建议

1. **不要假设所有核心支持相同指令集**——同一进程的线程可能在不同类型核心间迁移。
2. **运行时检测特性**——使用 CPUID 在程序启动时检测指令集支持情况，避免使用未支持的指令导致异常。
3. **AVX-512 谨慎使用**——E核可能不支持 AVX-512，若使用需做运行时降级（fallback 到 AVX2 或 SSE）；消费级 12 代更是 P/E 整片禁用（见下文实测）。
4. **核心类型可在运行中变化**——线程被调度到另一类型核心后，之前的检测结果可能不再适用；对关键路径可定期重新检测。

## 三台机器上的实测

这两件事都在 `08_system_misc/cpuid_hybrid.asm` 里演示了，三个平台各有一份：

| | 汇编 | 链接 |
|---|------|------|
| Windows | `nasm -f win64 examples/08_system_misc/cpuid_hybrid.asm -o cpuid_hybrid.obj` | `link ... cpuid_hybrid.obj` |
| macOS | `nasm -I lib -f macho64 examples-macos/08_system_misc/cpuid_hybrid.asm -o cpuid_hybrid.o` | `clang -arch x86_64 cpuid_hybrid.o -o cpuid_hybrid` |
| Linux | `nasm -I lib -f elf64 examples-linux/08_system_misc/cpuid_hybrid.asm -o cpuid_hybrid.o` | `gcc -no-pie cpuid_hybrid.o -o cpuid_hybrid` |

探测逻辑各平台完全一致，唯一要改的是「CPUID 会踩 `EBX`，而 `EBX` 是被调用者保存寄存器」——Windows 版把原值存到 `.data`，macOS / Linux 版存到栈帧的 `[rbp-8]`，取完所有 CPUID 后都必须还原。

在两台**没有混合架构**的旧 Intel 机器上各实测一遍（都是 macOS 版），正好对照「同一套探测代码，如何如实报告不同代际的能力」。2026-09 又在一台**真正的混合架构**机器（Alder Lake / Windows）上补测，页 0x1A 的两种答案第一次都跑了出来。

### Alder Lake（i7-12700F，2022；Family 6 / Model 151 / Stepping 2）——真·混合架构

Windows 11 下直接运行（Windows 版的输出串是英文）：

```text
Hybrid Architecture Supported: YES
Current Core Type: P-Core (Performance)
Raw Core Type Value: 0x40
AVX2: YES
AVX-512: NO
Hybrid architecture detection completed.
```

教程此前两台实测机器都够不到页 0x1A，「Hybrid = YES / 核心类型 0x40」这两行是第一次在真混合架构 CPU 上跑出来。不绑核连跑 11 次（构建脚本 1 次 + 手工 10 次），每次都是 P核——前台短促进程默认给 P核。

单次运行只能看到「操作系统恰好挑中的那个核」。想看到两种核型，不用改一行示例代码：用亲和掩码把进程钉在指定逻辑处理器上（`start /affinity <十六进制掩码> /wait prog.exe`，掩码在进程创建时生效）。i7-12700F 是 8 个 P核 × 2 超线程 + 4 个 E核 = 20 个逻辑处理器，把 20 个单比特掩码逐个跑完：

| 逻辑处理器 | 核心类型原始值 | 报告 | AVX2 | AVX-512 |
|-----------|---------------|------|------|---------|
| LP0 – LP15 | `0x40` | P-Core（8 个 P核 × 2 超线程） | YES | NO |
| LP16 – LP19 | `0x20` | E-Core（4 个 E核，无超线程） | YES | NO |

绑到 LP16（E核）时的完整输出：

```text
Hybrid Architecture Supported: YES
Current Core Type: E-Core (Efficiency)
Raw Core Type Value: 0x20
AVX2: YES
AVX-512: NO
Hybrid architecture detection completed.
```

四个读数，正好把本章前半的理论逐条落了地：

1. **P核在前，E核殿后**。Windows 把 8 个 P核（连同超线程）编在 LP0–15、4 个 E核编在 LP16–19；16 + 4 = 20，与系统报告的「12 核 20 线程」对上，也再次印证 E核不带超线程。
2. **页 0x1A 回答的是「我现在在哪」**。同一支程序、同一套代码，绑 LP0 报 `0x40`，绑 LP16 报 `0x20`——它查的是**当前逻辑处理器**的核型，不是整颗 CPU 的属性清单。这正是「线程可能迁移、检测要跟着跑」的根源。
3. **指令集基线一致**。20 个 LP 全部 AVX2 = YES：Gracemont（E核）与 Golden Cove（P核）的 SIMD 基线相同，写 AVX2 代码不需要按核型分路径。
4. **AVX-512 整片禁用**。连 P核也报 NO：Golden Cove 物理上有 AVX-512 单元，消费级 Alder Lake 因 E核不支持而全片关闭（12 代早期主板 BIOS 在禁用 E核时一度能开，后被微码封掉）。上一节表格里 P核「部分型号支持」在消费级桌面上的现实就是「都不支持」。

（这台机器的 CPUID 最大基本页号是 `0x20`，页 0x1A 自然可达；两台旧机器都停在 `0xD`，前置检查直接把页 0x1A 跳掉——这正是下面这组对照的价值。）

### Ivy Bridge（i7-3520M，2012；Family 6 / Model 58 / Stepping 9）

```
CPUID 最大页号： 0xD
支持混合架构（大小核）： NO
当前核心类型： 未知 / 未报告
AVX2： NO
AVX-512： NO
```

### Haswell（i7-4770HQ，2013；Family 6 / Model 70 / Stepping 1）

```
CPUID 最大页号： 0xD
支持混合架构（大小核）： NO
当前核心类型： 未知 / 未报告
核心类型原始值： 0x00
AVX2： YES
AVX-512： NO
提示：本机若无 AVX2，后面的 SIMD 示例会用 SSE 路径。
Hybrid architecture detection completed.
```

### 三台机器读出来的信息怎么对比

| 探测项 | i7-3520M（Ivy Bridge） | i7-4770HQ（Haswell） | i7-12700F（Alder Lake） | 说明 |
|--------|------------------------|----------------------|-------------------------|------|
| 最大页号 | `0xD` | `0xD` | `0x20` | 旧机器都停在扩展状态枚举（0xD），够不到 0x1A；新机器轻松越过 |
| 页 1A 能查吗 | 否（`0xD < 0x1A`，直接跳过） | 否（同样 `jb` 跳过） | **能** | 前置检查决定混合探测是否执行，这就是它的意义 |
| 核心类型 | 未报告 | 原始值 `0x00` | **`0x40`（P）/ `0x20`（E），随绑核翻转** | `0x00` = 非混合架构 / 未报告，不是 P 也不是 E |
| AVX2（页 7 EBX bit 5） | NO | **YES** | **YES（P/E 全部 20 个 LP）** | Haswell 起才有 AVX2；混合架构上两种核都有 |
| AVX-512F（页 7 EBX bit 16） | NO | NO | **NO（整片禁用，连 P核也没有）** | 消费级 12 代未放开；`simd_*` 示例只能走 SSE/AVX2 路径 |

五条可迁移的结论：

1. **前置检查决定了你能不能「安全地失败」**。两台旧机器最大页号都是 `0xD`，
   `cmp eax, 0x1A / jb` 直接把页 1A 查询跳掉了。不查就上会怎样？在 Haswell 上实测：
   越界查页 1A，CPU 返回的是 `EAX=0x00000007 / EBX=0x00000340 / ECX=0x00000340` ——
   既不是 0，也不是 1A 的输入回显，而是**别的页的遗留数据**，内容未定义、
   每代 CPU 可能都不同。这份输出里「核心类型原始值 0x00」恰好安全，
   但那是运气，不是保证；不能拿未定义的返回值做判断。
2. **最大页号相同不代表能力相同**。同样是 `0xD`，AVX2 一台 NO 一台 YES ——
   页 0 的最大页号只回答「有哪些页」，不回答「页里哪些位被置上」。能力要看位图。
3. **页 0x1A 是「问自己在哪」的接口**。同一支程序换绑一个 LP，答案就从 `0x40`
   变 `0x20`。运行时的核型检测要跟着线程走，不能只在启动时问一次就当作全局事实。
4. **核型分界不在 AVX2，在 AVX-512**。两种核的 SIMD 基线相同，写 AVX2 代码不用
   挑核；想上 AVX-512 才需要运行时位检测 + 降级路径——而消费级混合架构上它
   基本指望不上。
5. **同一段代码在三台机器上都能跑通且结论都正确**，靠的正是「先问、再查、
   按位判断」这套流程，而不是按 CPU 型号写死分支。

这正好是一份「正确的能力探测」长什么样：不是猜，而是问，然后如实降级。

---

> 上一章：[调试方法](08_debugging.md) ｜ 下一章：[macOS 平台移植指南](10_macos_porting.md) ｜ 返回：[README](../README.md)
