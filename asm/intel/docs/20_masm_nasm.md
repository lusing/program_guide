# MASM ↔ NASM 对照：怎么读懂那些经典教材

本教程通篇用 **NASM** 语法，但中文世界最流行的几本汇编书几乎全是
**MASM** 系：

| 书 | 语法与年代 |
|----|-----------|
| 王爽《汇编语言》（第 3 版） | MASM（DOS/16 位实模式为主） |
| 各大学《汇编语言程序设计》教材（2019 版实测） | MASM，DOS `INT 21H` 风格，段用 `SEGMENT/ENDS` |
| 罗云彬《Windows 环境下 32 位汇编语言程序设计》 | MASM32（Win32 API，`invoke`/`.data`/`proc`） |
| 李忠两本（R2P / 64 位多处理器） | **NASM**——与本书一致 |

读完本章你应该能拿着任何一本 MASM 教材，把示例「翻译」成 NASM
并放进本教程的 Win64 工程里跑。

## 1. 两种语法的哲学差异

- **MASM**：智能型。汇编器记着变量类型/尺寸，`mov [buf], 1` 靠推断；
  有高级伪指令（`invoke`、`if`/`elseif`、`.while`）、段自动管理。
  贴近「带宏的高层汇编」。
- **NASM**：直白型。**所见即所得**：内存访问必须写方括号，尺寸
  不推断（要么指令名带尺寸要么 `byte/word/dword` 前缀），没有
  高级流程伪指令。贴近「指令的文本表示」。

一句话记忆：**MASM 里 `mov eax, var` 是取值、`offset var` 才是取地址；
NASM 里 `mov eax, var` 是取地址（立即数）、`mov eax, [var]` 才是取值。**

## 2. 逐项对照表

### 2.1 程序骨架

MASM（教材经典骨架，2019 版教材第 4 章原文，OCR 清理后）：

```asm
DSEG    SEGMENT                    ; 数据段开始
DATA1   DB 1AH, 24H                ; 定义原始数据
DATA2   DW 0                       ; 保存结果单元
DSEG    ENDS                       ; 数据段结束

SSEG    SEGMENT STACK              ; 堆栈段开始
SKTOP   DB 40 DUP (0)              ; 定义堆栈空间
SSEG    ENDS                       ; 堆栈段结束

CSEG    SEGMENT                    ; 代码段开始
        ASSUME CS:CSEG, DS:DSEG, SS:SSEG
START:  MOV AX, DSEG               ; 初始化数据段基址
        MOV DS, AX
        MOV AL, DATA1              ; 取第一个数据
        ADD AL, DATA1+1            ; 与第二个数据相加
        MOV BYTE PTR DATA2, AL     ; 保存结果
        MOV AH, 4CH                ; 程序结束退出
        INT 21H                    ; DOS 系统调用
CSEG    ENDS                       ; 代码段结束
        END START                  ; 源程序结束
```

NASM（本教程的 Win64 等价物）：

```nasm
default rel

section .data
    data1   db 0x1A, 0x24
    data2   dw 0

section .text
    global main
    extern printf, ExitProcess
main:
    push rbp
    mov  rbp, rsp
    sub  rsp, 32
    movzx eax, byte [data1]
    add   al, [data1+1]
    mov   [data2], al
    ; ... printf ...
    xor  ecx, ecx
    call ExitProcess
```

骨架映射：`SEGMENT/ENDS` → `section`；`ASSUME` 无需（平坦模型 +
链接器解析）；DOS 的 `MOV AH,4CH / INT 21H` 退出 → Windows 的
`ExitProcess`；`END START` → 入口交给 `/entry:main`。

### 2.2 常用元素对照

| 功能 | MASM | NASM |
|------|------|------|
| 字节/字/双字/四字数据 | `db/dw/dd/dq` | 相同（`db/dw/dd/dq`） |
| 重复填充 | `DB 40 DUP (0)` | `times 40 db 0` |
| 未初始化数据 | `.data?` 段 / `data db ?` | `section .bss` + `resb/resw/resd/resq` |
| 取地址 | `offset var` / `lea ax, var` | `lea rax, [var]`（勿用裸 `mov rax, var`，那是把地址当立即数，见 2.4） |
| 取值 | `mov eax, var` | `mov eax, [var]` |
| 指定内存尺寸 | `mov BYTE PTR [mem], 1` | `mov byte [mem], 1`（或 `mov [mem], strict byte 1`） |
| 局部标号 | `@@:` + `@F/@B`（匿名） | `.label:`（`.` 前缀属于上一个非局部标号） |
| 过程 | `name PROC ... RET name ENDP` | `name: ... ret`（自行保存寄存器） |
| 调用 API | `invoke MessageBoxA, hWnd, lpText, ...` | 手工布参（rcx/rdx/r8/r9/栈）+ `call` |
| 宏 | `name MACRO ... ENDM` | `%macro name nargs ... %endmacro` |
| 宏内参数 | `parm`（按名引用） | `%1`、`%2`…（按序号，`%rep` 里配 `%%label` 生成唯一标号） |
| 重复汇编 | `REPT n ... ENDM` | `%rep n ... %endrep` |
| 重复汇编（列表） | `IRP p, <a,b,c> ... ENDM` | 无直接对应（`%rep` + 手工展开或 `%macro` 重载） |
| 重复汇编（字符） | `IRPC p, ABC ... ENDM` | 无直接对应（预处理期字符串迭代要 `%rep`+`%strcat` 组合） |
| 条件汇编 | `IF/ELSE/ENDIF`（伪指令） | `%if/%else/%endif` |
| 条件汇编（定义检查） | `IFDEF/IFNDEF name` | `%ifdef/%ifndef name` |
| 宏库 | `INCLUDE macro.lib`（宏库 = 纯宏文件） | `%include "macro.inc"`（同名文件即可） |
| 包含文件 | `include windows.inc` | `%include "xxx.inc"` |
| 当前位置计数器 | `$` | `$`（本指令地址）；`$$` = 段起始 |
| 对齐 | `ALIGN 16` | `align 16` |
| 常量 | `X EQU 100` / `X = 100` | `X equ 100` / `X: equ 100`（`%define` 更常用） |
| 全局符号 | `PUBLIC` | `global` |
| 外部符号 | `EXTRN/EXTERN` | `extern` |

### 2.3 `invoke` 的展开

罗云彬的书通篇 `invoke`——它只是个**按调用约定布参的宏**。
Win32 下 `invoke f, a, b, c` ≈ `push c; push b; push a; call f`
（stdcall 参数逆序入栈）。Win64 x64 下没有 `invoke`，必须手工：

```nasm
; MASM32 (Win32)                    ; NASM (Win64, 本教程风格)
; invoke MessageBoxA, NULL,         mov  rcx, 0            ; hWnd
;            addr szText,           lea  rdx, [szText]     ; lpText
;            addr szCaption,        lea  r8,  [szCaption]  ; lpCaption
;            MB_OK                  mov  r9d, 0            ; uType
;                                   sub  rsp, 32           ; 影子空间！
;                                   call MessageBoxA
```

`addr` ≈ `lea`。注意 x64 手工布参的三个必做：寄存器顺序
（rcx,rdx,r8,r9）、**32 字节影子空间**、栈 16 字节对齐
（详见[第 6 章](06_calling_convention.md)与[第 19 章](19_multicore_atomic.md)第 8 节）。

### 2.4 三个最容易栽的翻译陷阱

1. **裸标签 = 地址**。教材写 `mov ax, DATA1`（取值）；NASM 直译
   `mov ax, DATA1` 会把**地址**装进去（NASM 语法里没有上下文推断）。
   一律加方括号。同理 `mov eax, label` 会产生绝对地址重定位——
   在 MSVC 链接的 Win64 目标里直接 LNK2017（本教程实测坑，见
   [第 17 章](17_long_mode.md)第 6 节）。
2. **DOS 中断全部失效**。教材里的 `INT 21H`（AH=01/02/09/4CH 等）、
   `INT 10H`、`INT 16H` 是 16 位实模式 + DOS 的服务——Win64 下
   既没有 DOS（改 Windows API）也没有实模式（`int n` 走异常，
   见[第 18 章](18_interrupts_exceptions.md)）。翻译程序时先把
   I/O 调用换成 API：`INT 21H/AH=09H` → `printf`，
   `/AH=4CH` → `ExitProcess`，`INT 16H` → `getchar`/控制台 API。
3. **段寄存器语义换了人间**。教材花大力气讲 `ASSUME`、`MOV DS, AX`、
   ES:DI 串操作——64 位平坦模型下 DS/ES/SS 基址恒 0，段初始化
   代码全部删掉，`movsb` 的 es:di 变成 rdi（见
   [第 15 章](15_real_protected_mode.md)与[第 17 章](17_long_mode.md)）。

### 2.5 16 位教材示例的现代化路径

把王爽/教材的 16 位示例搬进本教程有两条路：

- **改写成 Win64**（推荐）：把「显存/BIOS/DOS」换成 printf/ExitProcess，
  算法逻辑原样保留——本教程 `examples/` 各类就是这条路的产物；
- **原汁原味跑 16 位**：用 `nasm -f bin` 生成裸二进制，在
  QEMU/DOSBox 里运行——本教程 `boot/01_mbr_hello.asm` 演示的正是
  这条路线（QEMU 无头 + 串口输出，见[第 15 章](15_real_protected_mode.md)）。

## 3. 想深入读某本书的路线建议

| 书 | 怎么读 |
|----|--------|
| 王爽《汇编语言》 | 基础概念最佳入门；示例为 DOS 16 位，按 2.5 现代化 |
| 《80X86汇编语言程序设计教程》 | 硬件原理参考书：第 7-8 章宏/重复汇编/模块化最系统（本表 MASM 高级伪指令对照的出处），第 10 章保护方式 11 个实例与 TSS/调用门/V86、11.2 调试寄存器是[第 8 章](08_debugging.md)硬件断点与[第 15/17 章](15_real_protected_mode.md)的深挖材料；MASM 5.x 时代注意与 6.x 语法差异 |
| 《汇编语言程序设计》教材（2019 版） | 系统性参考书：指令集/伪指令/寻址方式的速查手册；DOS 服务部分跳过 |
| 罗云彬《Win32 汇编》 | Windows 消息循环/资源/SEH(x86 版)的最佳实战书；`invoke` 对照 2.3，x86 SEH 一章与 x64 差异大（见[第 18 章](18_interrupts_exceptions.md)第 5.2 节） |
| 李忠《从实模式到保护模式》 | 与本教程 [15-16 章](15_real_protected_mode.md)直接对应，NASM 同源 |
| 《汇编语言编程艺术》（AoA，中译本） | Randall Hyde 的教学经典，但用自创的 HLA 语法（介于 Pascal 与汇编之间）；第 8 章「多精度运算」与第 10 章「位操作」（打包/解包/位计数）是同类书里最深的全科教材，本教程的 `multi_precision.asm` 与 `bit_fields.asm` 即取材于此；读它时按本表对照 HLA→NASM 即可 |
| 李忠《64 位多处理器多线程操作系统》 | 对应[第 17-19 章](17_long_mode.md)，进阶必读 |
| Intel SDM（三卷合一） | 一切争议的终审法院——指令语义/CR/MSR/页表格式查它 |

## 4. 本章坑清单

1. `mov eax, var`（MASM 取值）≠ `mov eax, var`（NASM 取地址）——
   翻译教材示例时第一件事就是补方括号。
2. `DUP` 没有直译：`40 DUP (0)` → `times 40 db 0`。
3. `invoke`/`addr`/`local`/`.if` 都是 MASM 宏世界，NASM 一概手工。
4. DOS `INT 21H` 家族在 Windows 不可用，逐个换 API。
5. 教材的「修改 DS/ES」代码在 Win64 全删（基址恒 0）。
6. 汇编教材普遍 32/16 位——寄存器名、指针宽度、调用约定要整体升级，
   不是把 `ax` 改成 `rax` 就完事（影子空间、栈对齐、变参走整数槽，
   见[第 6 章](06_calling_convention.md)）。

---

> 上一章：[多核与原子同步](19_multicore_atomic.md) ｜ 返回：[README](../README.md)
