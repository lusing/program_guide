# 寄存器详解

寄存器（Register）是 CPU 内部速度最快的存储单元，位于处理器核心中。x86-64 架构提供了丰富的寄存器资源，本章逐一介绍。

## 通用寄存器（General-Purpose Registers）

x86-64 提供 **16 个 64 位通用寄存器**。每个寄存器可按不同位宽访问其子寄存器（Sub-register）：

| 64 位 | 32 位 | 16 位 | 8 位（低） | 8 位（高*） | 说明 |
|-------|-------|-------|-----------|------------|------|
| RAX   | EAX   | AX    | AL        | AH         | 累加器（Accumulator），也用于返回值 |
| RBX   | EBX   | BX    | BL        | BH         | 基址寄存器（Base） |
| RCX   | ECX   | CX    | CL        | CH         | 计数器（Counter），第1个参数 |
| RDX   | EDX   | DX    | DL        | DH         | 数据寄存器（Data），第2个参数 |
| RSI   | ESI   | SI    | SIL       | —          | 源变址（Source Index），第3个参数 |
| RDI   | EDI   | DI    | DIL       | —          | 目的变址（Destination Index），第4个参数 |
| RBP   | EBP   | BP    | BPL       | —          | 基址指针（Base Pointer），帧指针 |
| RSP   | ESP   | SP    | SPL       | —          | 栈指针（Stack Pointer） |
| R8    | R8D   | R8W   | R8B       | —          | 新增，第5个参数 |
| R9    | R9D   | R9W   | R9B       | —          | 新增，第6个参数 |
| R10   | R10D  | R10W  | R10B      | —          | 新增 |
| R11   | R11D  | R11W  | R11B      | —          | 新增 |
| R12   | R12D  | R12W  | R12B      | —          | 新增 |
| R13   | R13D  | R13W  | R13B      | —          | 新增 |
| R14   | R14D  | R14W  | R14B      | —          | 新增 |
| R15   | R15D  | R15W  | R15B      | —          | 新增 |

> \* 高 8 位寄存器（AH/BH/CH/DH）仅在 RAX–RDX 四个寄存器上可用。使用 `REX` 前缀访问 64 位操作数时，高 8 位寄存器将不可用，需改用 SPL/BPL/SIL/DIL。

### 访问子寄存器的行为

- 写入 **32 位**寄存器（如 `mov eax, 1`）会**自动零扩展**至 64 位（高 32 位清零）。
- 写入 **16 位或 8 位**寄存器（如 `mov ax, 1`）**只修改对应位**，高位保持不变。

```nasm
mov rax, 0xFFFFFFFFFFFFFFFF   ; RAX = 全1
mov eax, 1                     ; RAX = 0x0000000000000001 (高32位被清零!)
mov ax,  0xFFFF                ; RAX = 0x000000000000FFFF (仅低16位变化)
```

## 特殊寄存器

### RIP — 指令指针（Instruction Pointer）

RIP 指向下一条将要执行的指令地址。程序无法直接 `mov` 修改 RIP，只能通过跳转（JMP）、调用（CALL）、返回（RET）等指令间接改变。x86-64 新增了 **RIP 相对寻址**：

```nasm
lea rax, [rel msg]    ; 使用 RIP 相对寻址获取数据地址（位置无关代码）
```

### RFLAGS — 标志寄存器（Flags Register）

64 位标志寄存器，记录运算结果的状态与控制标志。详见 [标志寄存器](05_flags.md)。

### RSP — 栈指针（Stack Pointer）

始终指向当前栈顶。`PUSH`/`POP`/`CALL`/`RET` 等指令会自动修改 RSP。

### RBP — 基址指针（Base Pointer）

传统上用于标记函数栈帧的起始位置，方便通过固定偏移访问局部变量与参数。详见 [栈和栈帧](07_stack_frames.md)。

## 段寄存器（Segment Registers）

x86-64 中段寄存器仍存在，但在 64 位模式下作用大幅削弱（Flat Model，所有段基址均为 0）：

| 寄存器 | 全称 | 64 位模式用途 |
|--------|------|--------------|
| CS | 代码段（Code Segment） | 存放代码段选择子，CPU 由此获取指令 |
| DS | 数据段（Data Segment） | 数据段选择子（通常与 SS 相同） |
| SS | 栈段（Stack Segment） | 栈段选择子 |
| ES | 附加段（Extra Segment） | 字符串指令目的段（通常与 DS 相同） |
| FS | — | **Windows 64 位: 保留（一般不使用）/ Linux: 指向 TLS（线程局部存储）** |
| GS | — | **Windows 64 位: 指向 TEB（线程环境块）/ Linux: 内核态使用** |

> 在 64 位 Windows 用户态编程中，最常用的段寄存器是 **GS**，它指向线程环境块（TEB, Thread Environment Block），可通过 `gs:[0x30]` 获取 TEB 基址、`gs:[0x60]` 获取 PEB 指针等方式访问线程/进程信息。注意：这与 32 位 Windows 使用 **FS** 指向 TEB 不同，切勿混淆。

## SIMD 寄存器（XMM/YMM/ZMM）

x86-64 保证至少支持 **SSE2**，提供 16 个 128 位 XMM 寄存器，用于单指令多数据（SIMD）运算：

| 寄存器 | 位宽 | 指令集 | 说明 |
|--------|------|--------|------|
| XMM0–XMM15 | 128 位 | SSE/SSE2 | 128 位 SIMD，浮点/整数并行运算 |
| YMM0–YMM15 | 256 位 | AVX/AVX2 | 256 位 SIMD（XMM 为其低 128 位） |
| ZMM0–ZMM31 | 512 位 | AVX-512 | 512 位 SIMD（需特定 CPU 支持） |

XMM0 也用于浮点函数的返回值。详见 `10_sse_simd` 类别示例。

## 寄存器使用约定

在 Windows x64 调用约定中，寄存器分为 **易失性（Volatile）** 与 **非易失性（Non-volatile）** 两类：

| 寄存器 | 状态 | 说明 |
|--------|------|------|
| RAX | 易失 | 返回值 |
| RCX, RDX, R8, R9 | 易失 | 整数参数 1-4 |
| R10, R11 | 易失 | 调用方可自由使用 |
| RAX, RCX, RDX, R8-R11 | 易失 | 被调用方无需保存 |
| RBX, RBP, RDI, RSI, R12-R15 | 非易失 | 被调用方必须保存并恢复 |
| XMM0–XMM5 | 易失 | 浮点参数及返回值 |
| XMM6–XMM15 | 非易失 | 被调用方必须保存 |
| RSP | 非易失 | 必须保持栈对齐与平衡 |

> **易失性寄存器**：函数调用后值可能被破坏，调用方需自行保存。
> **非易失性寄存器**：函数保证调用前后值不变，被调用方使用前必须 PUSH、使用后 POP 恢复。

---

> 上一篇：[环境配置](02_environment.md) ｜ 下一篇：[内存寻址模式](04_memory_addressing.md)
