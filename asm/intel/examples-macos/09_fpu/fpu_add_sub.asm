; ============================================================
; 文件: 09_fpu/fpu_add_sub.asm                             [macOS 版]
; 指令: FADD / FADDP / FSUB / FSUBP
; 描述: x87 浮点加减法 —— 一台上世纪留下的「栈式协处理器」
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/09_fpu/fpu_add_sub.asm -o build/fpu_add_sub.o
; 链接: clang -arch x86_64 build/fpu_add_sub.o -o build/fpu_add_sub
; 对照: examples/09_fpu/fpu_add_sub.asm
;
; ------------------------------------------------------------
; x87 不是「寄存器组」，而是一个 8 层的浮点栈 ST0…ST7。
; 所有运算默认在栈顶两格之间进行，所以指令名后面那个 p
; （pop）就格外重要：
;   faddp        ST0 = ST1 + ST0，然后弹掉 ST0
;   fsubp        ST0 = ST1 - ST0，然后弹掉 ST0   ← 方向是「ST1 减 ST0」
;   fadd [mem]   ST0 = ST0 + [mem]，**不弹**
;
; 为什么 fsubp 要被减数在下面？因为 x87 运算约定是
; 「目的操作数在 ST1，源操作数在 ST0」，所以 fld a / fld b
; 之后 a 在 ST1、b 在 ST0，fsubp 算出来就是 a - b。
;
; ------------------------------------------------------------
; SysV 与 Win64 在浮点传参上完全不同：
;   Win64:  整数参数在 rcx/rdx/r8/r9，浮点参数在 xmm0...，
;           而且 **同一序号位置会被两边占用**（第 2 个参数既占 RDX 又占 XMM1），
;           所以 Windows 版要写 `mov rdx,[result]` + `movsd xmm1,[result]` 两条。
;   SysV :  整数和浮点的寄存器编号**各自独立**，第 1 个浮点参数就是 xmm0，
;           一条 `movsd xmm0,[result]` 就够了。
;   两边共同点：调可变参数函数前必须设 al = 用到的 xmm 个数。
; ============================================================
default rel

section .data
    align 8
    a_val   dq 3.14                     ; 被加数
    b_val   dq 2.72                     ; 加数
    c_val   dq 10.5                     ; 被减数
    d_val   dq 3.7                      ; 减数
    result  dq 0.0                      ; 结果暂存

    fmt_add  db "FADDP:      3.14 + 2.72 = %f", 10, 0
    fmt_sub  db "FSUBP:      10.5 - 3.7  = %f", 10, 0
    fmt_addm db "FADD [mem]: 3.14 + 2.72 = %f   （ST0 += 内存，不弹栈）", 10, 0
    fmt_done db "FPU add/sub demo completed.", 10, 0

; 把 ST0 存到内存、搬进 xmm0、用 %f 打出来。
; 注意 `mov eax, 1`：告诉 printf「我用了 1 个向量寄存器」。
%macro print_st0 1
    fstp qword [result]                 ; ST0 -> 内存，并弹出
    movsd xmm0, [result]                ; 内存 -> xmm0（SysV 第 1 个浮点参数）
    lea rdi, [%1]
    mov eax, 1
    call _printf
%endmacro

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    finit                               ; 复位 FPU（控制字、栈指针、异常状态）

    ; --------------------------------------------------------
    ; 1. FADDP：先压 a，再压 b，栈顶相加后弹掉一格
    ;    栈：[a] -> [a, b] -> [a+b]
    ; --------------------------------------------------------
    fld qword [a_val]                   ; ST0 = 3.14
    fld qword [b_val]                   ; ST0 = 2.72, ST1 = 3.14
    faddp                               ; ST0 = 3.14 + 2.72 = 5.86
    print_st0 fmt_add

    ; --------------------------------------------------------
    ; 2. FSUBP：方向是 ST1 - ST0
    ;    栈：[10.5] -> [10.5, 3.7] -> [10.5 - 3.7]
    ; --------------------------------------------------------
    fld qword [c_val]                   ; ST0 = 10.5
    fld qword [d_val]                   ; ST0 = 3.7, ST1 = 10.5
    fsubp                               ; ST0 = 10.5 - 3.7 = 6.8
    print_st0 fmt_sub

    ; --------------------------------------------------------
    ; 3. FADD 直接吃内存操作数：栈深度不变
    ; --------------------------------------------------------
    fld qword [a_val]                   ; ST0 = 3.14
    fadd qword [b_val]                  ; ST0 = ST0 + 2.72 = 5.86
    print_st0 fmt_addm

    lea rdi, [fmt_done]
    xor eax, eax
    call _printf

    xor eax, eax
    leave
    ret
