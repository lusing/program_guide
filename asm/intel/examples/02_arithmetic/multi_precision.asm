; ============================================================
; multi_precision.asm - 扩展精度算术：128 位加减与 64x64->128
; ============================================================
; 汇编不限制整数大小——8/16/32/64 只是「一条指令能处理的最大宽度」。
; 更宽的整数用指令链拼（参考《汇编语言编程艺术》AoA 第 8.1 节）：
;   加法：低位 add，高位 adc（把 CF 接进下一段）
;   减法：低位 sub，高位 sbb（把借位接进下一段）
;   乘法：mul r64 直接产出 128 位积（rdx:rax）
;   比较：先比高位；高位相等再比低位
;
; 预期输出:
;   128-bit add : 0000000000000001F0000000000000001
;              + 00000000000000000FFFFFFFFFFFFFFF
;              = 00000000000000020000000000000000   (carry chain worked)
;   128-bit sub : 00000000000000020000000000000000
;              - 00000000000000000FFFFFFFFFFFFFFF
;              = 0000000000000001F0000000000000001
;   64x64->128  : 123456789ABCDEF0 * FEDCBA9876543210
;              = 121FA00AD77D7422236D88FE5618CF00
;   cmp 128     : a < b ? no ; b < a ? yes
; ============================================================

default rel

section .data
    align 16
    ; 128 位操作数：小端序，低 64 位在前
    a_lo dq 0xF000000000000001
    a_hi dq 0x0000000000000001
    b_lo dq 0x0FFFFFFFFFFFFFFF
    b_hi dq 0x0000000000000000

    r_lo dq 0
    r_hi dq 0

    m1   dq 0x123456789ABCDEF0
    m2   dq 0xFEDCBA9876543210

    fmt_add1 db "128-bit add : %016llX%016llX", 10, 0
    fmt_add2 db "          + %016llX%016llX", 10, 0
    fmt_add3 db "          = %016llX%016llX   (carry chain worked)", 10, 0
    fmt_sub1 db "128-bit sub : %016llX%016llX", 10, 0
    fmt_sub2 db "          - %016llX%016llX", 10, 0
    fmt_sub3 db "          = %016llX%016llX", 10, 0
    fmt_mul1 db "64x64->128  : %016llX * %016llX", 10, 0
    fmt_mul2 db "          = %016llX%016llX", 10, 0
    fmt_cmp  db "cmp 128     : a < b ? %s ; b < a ? %s", 10, 0
    yes db "yes", 0
    no  db "no ", 0

section .text
    global main
    extern printf
    extern ExitProcess

; 打印 128 位（rdi = 格式串，r8=高 r9=低——由调用方布好前 4 参中的 2、3）
; 简化：直接在调用点布参。

main:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; ---- 打印加数 ----
    lea rcx, [fmt_add1]
    mov rdx, [a_hi]
    mov r8, [a_lo]
    call printf
    lea rcx, [fmt_add2]
    mov rdx, [b_hi]
    mov r8, [b_lo]
    call printf

    ; ---- 128 位加法：低位 add + 高位 adc ----
    mov rax, [a_lo]
    add rax, [b_lo]             ; 低 64 位相加，CF 记录进位
    mov rdx, [a_hi]
    adc rdx, [b_hi]             ; 高 64 位 + 进位
    mov [r_lo], rax
    mov [r_hi], rdx

    lea rcx, [fmt_add3]
    mov rdx, [r_hi]
    mov r8, [r_lo]
    call printf

    ; ---- 打印被减数（就是刚才的和）----
    lea rcx, [fmt_sub1]
    mov rdx, [r_hi]
    mov r8, [r_lo]
    call printf
    lea rcx, [fmt_sub2]
    mov rdx, [b_hi]
    mov r8, [b_lo]
    call printf

    ; ---- 128 位减法：低位 sub + 高位 sbb ----
    mov rax, [r_lo]
    sub rax, [b_lo]             ; 低 64 位相减，CF 记录借位
    mov rdx, [r_hi]
    sbb rdx, [b_hi]             ; 高 64 位 - 借位
    ; 结果应回到 a（可用 mov [a_lo] 校验，这里直接打印）
    lea rcx, [fmt_sub3]
    mov r8, rax
    ; rdx 已是高 64 位结果
    ; 布参：rcx=fmt, rdx=高, r8=低
    call printf

    ; ---- 64x64 -> 128 乘法 ----
    lea rcx, [fmt_mul1]
    mov rdx, [m1]
    mov r8, [m2]
    call printf
    mov rax, [m1]
    mul qword [m2]              ; rdx:rax = 128 位积（无符号）
    mov r9, rdx                 ; 暂存高 64
    mov [r_lo], rax
    mov [r_hi], r9
    lea rcx, [fmt_mul2]
    mov rdx, [r_hi]
    mov r8, [r_lo]
    call printf

    ; ---- 128 位比较：先高位后低位 ----
    ; a = 0x1_F000...0001 ; b = 0x0_0FFF...FFFF -> a > b
    mov rax, [a_hi]
    cmp rax, [b_hi]
    jb  .a_lt_b
    ja  .a_gt_b
    mov rax, [a_lo]
    cmp rax, [b_lo]
    jb  .a_lt_b
    ja  .a_gt_b
    ; 相等分支
    lea rdx, [no]
    lea r8,  [no]
    jmp .print_cmp
.a_lt_b:
    lea rdx, [yes]              ; a < b = yes
    lea r8,  [no]               ; b < a = no
    jmp .print_cmp
.a_gt_b:
    lea rdx, [no]               ; a < b = no
    lea r8,  [yes]              ; b < a = yes
.print_cmp:
    lea rcx, [fmt_cmp]
    call printf

    xor ecx, ecx
    call ExitProcess
