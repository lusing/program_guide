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

对应用层而言，线程在 P核还是 E核上运行由操作系统决定，程序无法直接控制。但可通过 `SetThreadAffinityMask` 等 Windows API 间接影响调度偏好。

## 编程建议

1. **不要假设所有核心支持相同指令集**——同一进程的线程可能在不同类型核心间迁移。
2. **运行时检测特性**——使用 CPUID 在程序启动时检测指令集支持情况，避免使用未支持的指令导致异常。
3. **AVX-512 谨慎使用**——E核可能不支持 AVX-512，若使用需做运行时降级（fallback 到 AVX2 或 SSE）。
4. **核心类型可在运行中变化**——线程被调度到另一类型核心后，之前的检测结果可能不再适用；对关键路径可定期重新检测。

---

> 上一篇：[调试方法](08_debugging.md) ｜ 返回 [首页](../README.md)
