; ============================================================
; 文件: 10_sse_simd/sse_mov.asm                            [macOS 版]
; 指令: MOVAPS / MOVUPS / MOVSS / MOVSD
; 描述: 数据怎么进出 XMM 寄存器 —— 对齐与不对齐的价格差
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/10_sse_simd/sse_mov.asm -o build/sse_mov.o
; 链接: clang -arch x86_64 build/sse_mov.o -o build/sse_mov
; 对照: examples/10_sse_simd/sse_mov.asm
;
; ------------------------------------------------------------
;    movaps  128 位整体搬，**要求 16 字节对齐**，否则 #GP 异常
;    movups  128 位整体搬，不要求对齐（老 CPU 上会慢一截）
;    movss   只搬低 32 位（1 个 float）
;    movsd   只搬低 64 位（1 个 double）
; 那对 a/u 就是 aligned / unaligned 的缩写。
; 近十年的 CPU 上对齐与否的差距已经很小，但**对齐仍是硬要求**：
; 用 movaps 碰未对齐地址是直接崩，不是变慢。
;
; 命名规律记住一条就够：后缀两字母，第一个是 s（scalar）还是 p（packed），
; 第二个是 s（single）还是 d（double）：
;   ss = 标量单精度   sd = 标量双精度
;   ps = 打包单精度   pd = 打包双精度
; 所以 addss 是「加一个 float」，addps 是「一次加四个 float」。
;
; ------------------------------------------------------------
; macOS（SysV）浮点传参的好处在这里体现得淋漓尽致：
;   `"  [%d] = %f"` 只要 rdi=格式、esi=索引、xmm0=值、eax=1 —— 全在寄存器；
;   Windows 版则要把同一个 %f 同时放进 RDX 和 XMM2/XMM1，编号还得按位置对齐。
; ============================================================
default rel

section .data
    ; 16 字节对齐的打包 float（4 个 float 正好 16 字节）
    align 16
    packed_data    dd 1.0, 2.0, 3.0, 4.0

    ; 不保证对齐的数据（演示 movups）
    unaligned_data dd 5.0, 6.0, 7.0, 8.0

    align 4
    float_val   dd 3.14                 ; 单精度
    align 8
    double_val  dq 2.718281828459045    ; 双精度

    align 16
    xmm_buf     dd 0.0, 0.0, 0.0, 0.0   ; 存放 XMM 里搬出来的 4 个 float
    align 8
    temp_double dq 0.0

    fmt_movaps db "MOVAPS: 一次搬进 4 个 float [1.0, 2.0, 3.0, 4.0]", 10, 0
    fmt_elem   db "  element[%d] = %f", 10, 0
    fmt_movups db "MOVUPS: 一次搬进 4 个 float [5.0, 6.0, 7.0, 8.0]", 10, 0
    fmt_movss  db "MOVSS:  搬进一个标量 float  = %f", 10, 0
    fmt_movsd  db "MOVSD:  搬进一个标量 double = %f", 10, 0
    fmt_done   db "SSE data movement demo completed.", 10, 0

; 打一个 float 元素：%1 = 偏移，%2 = 下标
%macro print_elem 2
    movss xmm0, [xmm_buf + %1]          ; 取第 %2 个 float
    cvtss2sd xmm0, xmm0                 ; float -> double（%f 要 double）
    lea rdi, [fmt_elem]
    mov esi, %2
    mov eax, 1                          ; 用了 1 个向量寄存器
    call _printf
%endmacro

; 打一个 double：xmm1 里已经有值
%macro print_d 1
    movsd xmm0, xmm1
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

    ; --------------------------------------------------------
    ; 1. MOVAPS：对齐的打包搬运
    ;    内存地址必须是 16 的整数倍，否则 CPU 直接抛 #GP
    ; --------------------------------------------------------
    movaps xmm0, [packed_data]          ; 4 个 float 一起进来
    movaps [xmm_buf], xmm0              ; 再原样存到缓冲区

    lea rdi, [fmt_movaps]
    xor eax, eax
    call _printf

    print_elem 0,  0
    print_elem 4,  1
    print_elem 8,  2
    print_elem 12, 3

    ; --------------------------------------------------------
    ; 2. MOVUPS：不对齐版本，功能一样，不挑地址
    ; --------------------------------------------------------
    movups xmm0, [unaligned_data]
    movups [xmm_buf], xmm0

    lea rdi, [fmt_movups]
    xor eax, eax
    call _printf

    ; --------------------------------------------------------
    ; 3. MOVSS：标量单精度，只动低 32 位，高 96 位清零
    ; --------------------------------------------------------
    movss xmm0, [float_val]             ; xmm0[31:0] = 3.14
    cvtss2sd xmm1, xmm0                 ; 升成 double 才能用 %f 打
    print_d fmt_movss

    ; --------------------------------------------------------
    ; 4. MOVSD：标量双精度，只动低 64 位，高 64 位清零
    ; --------------------------------------------------------
    movsd xmm0, [double_val]            ; xmm0[63:0] = 2.718281828...
    movsd xmm1, xmm0
    print_d fmt_movsd

    lea rdi, [fmt_done]
    xor eax, eax
    call _printf

    xor eax, eax
    leave
    ret
