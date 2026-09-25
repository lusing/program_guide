; ============================================================
; ieee754_bits.asm - IEEE 754 双精度的位级解剖
; ============================================================
; double = 1 位符号 + 11 位指数（移码，偏置 1023） + 52 位尾数。
; 把同一块内存分别当 double 读、当 u64 读，就能看到编码：
;   +1.0  = 0x3FF0000000000000   exp=1023(=1023+0) 尾数=0
;   -2.0  = 0xC000000000000000   sign=1, exp=1024
;   0.1   = 0x3FB999999999999A   尾数 0x999...9A（二进制无限循环被截断）
;   +inf  = 0x7FF0000000000000   指数全 1、尾数全 0
; 以及著名的 0.1 + 0.2 != 0.3（位模式差一 ULP）。
;
; 预期输出:
;   +1.0 : bits=0x3FF0000000000000  sign=0 exp= 1023 mantissa=0x0000000000000
;   -2.0 : bits=0xC000000000000000  sign=1 exp= 1024 mantissa=0x0000000000000
;   0.1  : bits=0x3FB999999999999A  sign=0 exp= 1019 mantissa=0x999999999999A
;   +inf : bits=0x7FF0000000000000  sign=0 exp= 2047 mantissa=0x0000000000000
;   0.1+0.2 -> bits=0x3FD3333333333334
;   0.3     -> bits=0x3FD3333333333333   (differ by 1 ULP!)
; ============================================================

default rel

section .data
    align 8
    v_1    dq 1.0
    v_m2   dq -2.0
    v_01   dq 0.1
    v_02   dq 0.2
    v_03   dq 0.3
    v_inf  dq 0x7FF0000000000000     ; +inf 的位模式直接写出来

    fmt_line db "%s: bits=0x%016llX  sign=%llu exp=%4llu mantissa=0x%013llX", 10, 0
    fmt_sum  db "0.1+0.2 -> bits=0x%016llX", 10, 0
    fmt_lit  db "0.3     -> bits=0x%016llX   (differ by 1 ULP!)", 10, 0

    n1 db "+1.0", 0
    n2 db "-2.0", 0
    n3 db "0.1 ", 0
    n4 db "+inf", 0

section .text
    global main
    extern printf
    extern ExitProcess

; DECODE 名称, 变量：解码 sign/exp/mantissa 并按 fmt_line 打印
%macro DECODE 2
    mov rax, [%2]
    mov r8, rax                 ; 第 2 变参：完整位模式
    mov r9, rax
    shr r9, 63                  ; 第 3 变参：sign
    mov r10, rax
    shr r10, 52
    and r10, 0x7FF              ; 第 4 变参：exp（移码）
    mov r11, rax
    shl r11, 12
    shr r11, 12                 ; 第 5 变参：mantissa（低 52 位）
    lea rcx, [fmt_line]
    lea rdx, [%1]
    mov [rsp+32], r10
    mov [rsp+40], r11
    call printf
%endmacro

main:
    push rbp
    mov rbp, rsp
    sub rsp, 64                 ; 影子空间 + 第 4/5 变参的栈槽

    DECODE n1, v_1
    DECODE n2, v_m2
    DECODE n3, v_01
    DECODE n4, v_inf

    ; ---- 0.1 + 0.2 的位模式 vs 字面量 0.3 ----
    movsd xmm0, [v_01]
    addsd xmm0, [v_02]
    movq rdx, xmm0
    lea rcx, [fmt_sum]
    call printf

    mov rdx, [v_03]
    lea rcx, [fmt_lit]
    call printf

    xor ecx, ecx
    call ExitProcess
