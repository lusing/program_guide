# 调用约定（Win64 与 System V AMD64）

调用约定（Calling Convention）规定了函数之间如何传递参数、返回值以及如何使用寄存器和栈。

x86-64 上有**两个**主流约定：

- **Windows x64**（Microsoft x64 ABI）——Windows 平台使用
- **System V AMD64 ABI**（下称 SysV）——macOS、Linux、BSD 使用

两者差别不小，而且**同一份 C 代码在两平台上编译出的汇编调用序列完全不同**。本章先讲 Win64，再讲 SysV，最后给出一张对照表。macOS 相关的完整讨论见 [macOS 平台移植指南](10_macos_porting.md)。

## 一、Windows x64 调用约定

### 参数传递规则

Windows x64 约定中，前 4 个参数通过寄存器传递，多余的参数通过栈传递：

| 参数序号 | 整数/指针 | 浮点数 |
|---------|----------|--------|
| 第 1 个 | RCX | XMM0 |
| 第 2 个 | RDX | XMM1 |
| 第 3 个 | R8  | XMM2 |
| 第 4 个 | R9  | XMM3 |
| 第 5 个起 | 栈 | 栈 |

> 当参数为**混合类型**时，整数/指针占用整数寄存器序列（RCX, RDX, R8, R9），浮点占用 XMM 寄存器序列（XMM0–XMM3），但**两个序列都按参数的位置序号索引，而非各自从 0 重新计数**。例如 `f(int a, double b, int c)` → a→RCX、b→XMM1、c→R8；即 b 是第 2 个参数就用 XMM**1**（而非 XMM0），c 是第 3 个参数就用 R8。第 5 个及以后的参数无论类型一律走栈。

### 栈传递规则

第 5 个及以后的参数按**从左到右**的顺序压入栈中（注意：这与 32 位 cdecl 的从右到左相反）：

```nasm
; 调用 f(a, b, c, d, e, f)  — 6个整数参数
; a→RCX, b→RDX, c→R8, d→R9, e→[rsp+0x20], f→[rsp+0x28]
mov  rcx, 1           ; 参数1
mov  rdx, 2           ; 参数2
mov  r8,  3           ; 参数3
mov  r9,  4           ; 参数4
mov  qword [rsp + 0x20], 5   ; 参数5
mov  qword [rsp + 0x28], 6   ; 参数6
call f
```

### 影子空间（Shadow Space）

Windows x64 强制要求调用方在栈上预留 **32 字节（4 × 8）的影子空间**，位于参数 5 起的栈参数**之前**（低地址方向）。这 32 字节供被调用方保存 RCX/RDX/R8/R9（如果需要）。

即使函数参数少于 4 个，影子空间也**必须分配**：

```nasm
sub  rsp, 32          ; 分配 32 字节影子空间（至少4参数的情况）
mov  rcx, param1
call some_function
add  rsp, 32          ; 释放影子空间
```

### 栈对齐（16 字节）

在执行 `CALL` 指令时，**RSP 必须是 16 字节对齐的**。`CALL` 会将 8 字节返回地址压栈，因此进入函数时 RSP 对 16 取模余 8（`RSP % 16 == 8`）。

常见做法是分配 `32（影子空间）+ 8（对齐填充）= 40` 字节。因为 `main` 入口时 RSP % 16 == 8（CALL 压入的返回地址所致），`sub rsp, 40` 后 RSP 恢复到 16 字节对齐（40 % 16 == 8，8 - 8 == 0），从而保证内部 `call` 时对齐：

```nasm
main:
    ; 入口: RSP % 16 == 8 (被 CRT CALL 压入返回地址)
    sub  rsp, 40          ; 32影子 + 8对齐填充 → 此时 RSP % 16 == 0
    ; ... 设置参数并调用 ...
    mov  rcx, 1
    call printf           ; CALL 前 RSP % 16 == 0，对齐正确
    xor  ecx, ecx         ; 退出码 0
    call ExitProcess      ; 退出进程（/entry:main 必须用 ExitProcess）
```

> **未对齐的栈会导致崩溃**：许多 C 运行时函数和 Windows API 内部使用 XMM 指令要求 16 字节对齐，RSP 不对齐会触发访问违例（Access Violation）。这是汇编初学者最常遇到的错误之一。

### 返回值

| 返回类型 | 寄存器 |
|---------|--------|
| 整数/指针（≤64位） | RAX |
| 浮点数 | XMM0 |
| 128 位（如 `__m128`） | RAX + RDX |

函数正常返回后，RAX（或 XMM0）即为返回值。

### Volatile vs Non-volatile 寄存器

| 寄存器 | 类型 | 说明 |
|--------|------|------|
| RAX, RCX, RDX, R8–R11 | 易失（Volatile） | 调用后值可能被破坏，调用方需自行保存 |
| RBX, RBP, RDI, RSI, R12–R15 | 非易失（Non-volatile） | 调用前后值保证不变，被调用方负责保存/恢复 |
| XMM0–XMM5 | 易失 | 浮点参数/返回值 |
| XMM6–XMM15 | 非易失 | 被调用方负责保存/恢复 |
| RSP | 非易失 | 必须在函数返回前恢复至入口值（保持平衡） |

> 被调用方使用非易失性寄存器前必须 `push` 保存，返回前 `pop` 恢复。

### 函数调用完整示例

下面是一个完整示例：调用 C 库函数 `printf` 打印格式化字符串，展示参数传递、影子空间与栈对齐：

```nasm
; calling.asm — 演示 Windows x64 调用约定
extern printf
extern ExitProcess

section .data
    fmt  db  'sum(%d, %d) = %d', 10, 0    ; 格式串

section .text
global main

; int add(int a, int b) — 接收两个整数，返回和
add_ints:
    mov  eax, ecx          ; EAX = a (第1参数，32位)
    add  eax, edx          ; EAX += b (第2参数)
    ret                    ; 返回值在 EAX/RAX

main:
    sub  rsp, 40           ; 32影子 + 8对齐

    ; 调用 add_ints(10, 20)
    mov  ecx, 10           ; 参数1 → ECX
    mov  edx, 20           ; 参数2 → EDX
    call add_ints          ; 返回值在 EAX

    ; 调用 printf("sum(%d, %d) = %d\n", 10, 20, result)
    lea  rcx, [rel fmt]    ; 参数1: 格式串 → RCX
    mov  edx, 10           ; 参数2: 10 → RDX
    mov  r8d, 20           ; 参数3: 20 → R8D
    mov  r9d, eax          ; 参数4: result → R9D
    call printf

    xor  ecx, ecx          ; 退出码 0
    call ExitProcess       ; 退出进程（/entry:main 必须用 ExitProcess）
```

### 调用过程图解

```
调用 printf 前（已 sub rsp, 40）:

高地址
┌──────────────────┐
│  返回地址 (main)  │  ← [rsp+40] (CALL压入)
├──────────────────┤
│  影子空间 32 字节  │  ← [rsp+0]  ~ [rsp+31]  (供printf保存RCX~R9)
├──────────────────┤
│   8 字节对齐填充   │  ← [rsp+32] ~ [rsp+39]
└──────────────────┘
低地址
        ↑ RSP 指向此处，16字节对齐
```

---

## 二、System V AMD64 调用约定（macOS / Linux）

### 参数传递规则

前 6 个整数/指针参数走寄存器，第 7 个起走栈：

| 参数序号 | 整数/指针 | 浮点数 |
|---------|----------|--------|
| 第 1 个 | RDI | XMM0 |
| 第 2 个 | RSI | XMM1 |
| 第 3 个 | RDX | XMM2 |
| 第 4 个 | RCX | XMM3 |
| 第 5 个 | R8  | XMM4 |
| 第 6 个 | R9  | XMM5 |
| 第 7 个起 | 栈 | 栈（XMM6/XMM7 也能用，之后才走栈） |

**最关键的一点：整数和浮点的编号各自从 0 开始，互不影响。**

对比一下同一句 `printf`：

```nasm
; 调用 printf("a=%d b=%f c=%d d=%f", 1, 2.0, 3, 4.0)
;   Windows：浮点按「参数位置」索引 -> 第 2 个参数用 XMM1，第 4 个用 XMM3
;           而且每个浮点参数还得在对应通用寄存器里再放一份位模式
mov  rcx, fmt
mov  edx, 1                 ; b 也要占 RDX
mov  r8d, 3
mov  r9d, 4
mov  rdx, [d2]              ; ← b 的位模式又进 RDX
mov  r8,  [d4]              ; ← d 的位模式又进 R8
movsd xmm1, [d2]
movsd xmm3, [d4]
call printf

;   macOS / SysV：整数一路 rdi/rsi/rdx/rcx，浮点一路 xmm0/xmm1，各数各的
mov  rdi, fmt
mov  esi, 1
mov  edx, 3
mov  ecx, 4
movsd xmm0, [d2]
movsd xmm1, [d4]
mov  eax, 2                 ; al = 用到的 xmm 个数
call _printf
```

### 没有影子空间

SysV **不要求**调用方预留影子空间。所以 Windows 里常见的 `sub rsp, 32`，在 macOS 上如果写了，那就是纯粹的局部变量空间，不写也不影响正确性。

第 7 个起的栈参数按**从右到左**压栈（与 Win64 的从左到右相反），也就是第一个栈参数在最低地址：

```nasm
; 调用 g(a,b,c,d,e,f,g,h) —— a..f 走寄存器，g,h 走栈
; g→[rsp+0]，h→[rsp+8]（调用时的 rsp，不含返回地址）
sub  rsp, 16
mov  qword [rsp],   7
mov  qword [rsp+8], 8
call g
add  rsp, 16
```

### 栈对齐

与 Win64 相同：**执行 `call` 时 `rsp` 必须是 16 的整数倍**。因此被调用函数刚进入时 `rsp ≡ 8 (mod 16)`（call 压入了返回地址）。标准的建帧 `push rbp` 会把 `rsp` 拉回 16 的整数倍，之后按 16 的倍数分配局部空间即可。

### 返回值

| 类型 | 位置 |
|------|------|
| 整数/指针 | RAX（128 位结果用 RDX:RAX） |
| 浮点 | XMM0（两个浮点返回值用 XMM0:XMM1） |

### Volatile vs Non-volatile

与 Win64 **完全一致**：

| 分类 | 寄存器 | 责任 |
|------|--------|------|
| 调用者保存（volatile） | RAX、RCX、RDX、RSI、RDI、R8–R11、**全部 XMM** | 调用方若需跨 `call` 保留，自己存 |
| 被调用者保存（non-volatile） | RBX、RBP、R12–R15 | 被调用方用前必须备份，返回前还原 |

> **`printf` / `strlen` 等 libc 函数会踩掉所有调用者保存寄存器**，包括 `RAX`（`printf` 的返回值——打印字符数——就在 `eax` 里）和**每一个 XMM 寄存器**。跨 `call` 要活下来的浮点值必须落栈，没有例外。

### 函数调用完整示例

```asm
default rel

section .data
    fmt_sum db "sum4(%d,%d,%d,%d) = %d", 10, 0
    fmt_avg db "avg = %f", 10, 0

section .text
    global _main
    extern _printf

; int sum4(int a, int b, int c, int d)     —— 参数 rdi rsi rdx rcx
sum4:
    lea rax, [rdi + rsi]
    add rax, rdx
    add rax, rcx
    ret                                  ; 结果在 rax

; double avg4(double a, double b, double c, double d)  —— 参数 xmm0..xmm3
avg4:
    addsd xmm0, xmm1
    addsd xmm0, xmm2
    addsd xmm0, xmm3
    divsd xmm0, [half]                   ; 结果在 xmm0
    ret

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; --- 调用整数函数 ---
    mov edi, 10
    mov esi, 20
    mov edx, 30
    mov ecx, 40
    call sum4
    mov r8d, eax                         ; 第 5 个 printf 参数走 r8

    lea rdi, [fmt_sum]
    mov esi, 10
    mov edx, 20
    mov ecx, 30
    xor eax, eax
    call _printf

    ; --- 调用浮点函数 ---
    movsd xmm0, [v10]
    movsd xmm1, [v20]
    movsd xmm2, [v30]
    movsd xmm3, [v40]
    call avg4
    lea rdi, [fmt_avg]
    mov eax, 1                           ; 用了 1 个 xmm
    call _printf

    xor eax, eax
    leave
    ret                                  ; 返回 libSystem，不是 ExitProcess
```

## 三、两套约定对照总表

| 项目 | Windows x64 | System V AMD64（macOS / Linux） |
|------|-------------|-------------------------------|
| 整数参数 | RCX, RDX, R8, R9（4 个） | RDI, RSI, RDX, RCX, R8, R9（6 个） |
| 浮点参数 | XMM0–XMM3，按**参数位置**索引 | XMM0–XMM7，**独立编号** |
| 浮点参数是否要占用通用寄存器 | **要**（同一位置双写） | 不要 |
| 第 n 个起走栈 | 第 5 个 | 第 7 个 |
| 栈参数顺序 | 从左到右 | 从右到左 |
| 影子空间 | 调用者预留 32 字节 | **无** |
| 可变参数标记 | 同下 | `al` = 用到的 XMM 个数 |
| 返回值（整数） | RAX / RDX:RAX | RAX / RDX:RAX |
| 返回值（浮点） | XMM0 / XMM0:XMM1 | XMM0 / XMM0:XMM1 |
| 调用者保存 | RAX RCX RDX R8-R11 XMM* | RAX RCX RDX RSI RDI R8-R11 XMM* |
| 被调用者保存 | RBX RBP RSI RDI R12-R15 | RBX RBP R12-R15 |
| `call` 时栈对齐 | 16 的倍数 | 16 的倍数 |
| 入口符号 | `main`（`/entry:main`） | `_main` |
| 收场方式 | `call ExitProcess`（**不能 `ret`**） | `leave` / `ret` |

> 注意中间两行的一个反直觉之处：**RSI 和 RDI 在 Windows 里是被调用者保存**（要 push/pop 保护），**在 SysV 里是调用者保存**（不用保护，但会被 `printf` 冲掉）。
> 第 6 类的字符串指令示例正好用得上这一点：Windows 版要 `push rsi / push rdi`，macOS 版不需要 —— 代价是每条字符串指令之后，`printf` 的参数必须从头再装一遍，因为 `RSI`/`RDI`/`RCX` 同时是字符串指令的操作数和参数寄存器。

---

> 上一篇：[标志寄存器](05_flags.md) ｜ 下一篇：[栈和栈帧](07_stack_frames.md) ｜ 延伸：[macOS 平台移植指南](10_macos_porting.md)
