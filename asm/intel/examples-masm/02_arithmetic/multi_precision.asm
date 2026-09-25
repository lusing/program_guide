; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 16
    ; 128 位操作数：小端序，低 64 位在前
    a_lo QWORD 0F000000000000001h
    a_hi QWORD 0000000000000001h
    b_lo QWORD 0FFFFFFFFFFFFFFFh
    b_hi QWORD 0000000000000000h

    r_lo QWORD 0
    r_hi QWORD 0

    m1   QWORD 123456789ABCDEF0h
    m2   QWORD 0FEDCBA9876543210h

    fmt_add1 BYTE "128-bit add : %016llX%016llX", 10, 0
    fmt_add2 BYTE "          + %016llX%016llX", 10, 0
    fmt_add3 BYTE "          = %016llX%016llX   (carry chain worked)", 10, 0
    fmt_sub1 BYTE "128-bit sub : %016llX%016llX", 10, 0
    fmt_sub2 BYTE "          - %016llX%016llX", 10, 0
    fmt_sub3 BYTE "          = %016llX%016llX", 10, 0
    fmt_mul1 BYTE "64x64->128  : %016llX * %016llX", 10, 0
    fmt_mul2 BYTE "          = %016llX%016llX", 10, 0
    fmt_cmp  BYTE "cmp 128     : a < b ? %s ; b < a ? %s", 10, 0
    yes BYTE "yes", 0
    no  BYTE "no ", 0


.code

; 打印 128 位（rdi = 格式串，r8=高 r9=低——由调用方布好前 4 参中的 2、3）
; 简化：直接在调用点布参。

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; ---- 打印加数 ----
    lea rcx, fmt_add1
    mov rdx, QWORD PTR [a_hi]
    mov r8, QWORD PTR [a_lo]
    call printf
    lea rcx, fmt_add2
    mov rdx, QWORD PTR [b_hi]
    mov r8, QWORD PTR [b_lo]
    call printf

    ; ---- 128 位加法：低位 add + 高位 adc ----
    mov rax, QWORD PTR [a_lo]
    add rax, QWORD PTR [b_lo]             ; 低 64 位相加，CF 记录进位
    mov rdx, QWORD PTR [a_hi]
    adc rdx, [b_hi]             ; 高 64 位 + 进位
    mov QWORD PTR [r_lo], rax
    mov QWORD PTR [r_hi], rdx

    lea rcx, fmt_add3
    mov rdx, QWORD PTR [r_hi]
    mov r8, QWORD PTR [r_lo]
    call printf

    ; ---- 打印被减数（就是刚才的和）----
    lea rcx, fmt_sub1
    mov rdx, QWORD PTR [r_hi]
    mov r8, QWORD PTR [r_lo]
    call printf
    lea rcx, fmt_sub2
    mov rdx, QWORD PTR [b_hi]
    mov r8, QWORD PTR [b_lo]
    call printf

    ; ---- 128 位减法：低位 sub + 高位 sbb ----
    mov rax, QWORD PTR [r_lo]
    sub rax, QWORD PTR [b_lo]             ; 低 64 位相减，CF 记录借位
    mov rdx, QWORD PTR [r_hi]
    sbb rdx, [b_hi]             ; 高 64 位 - 借位
    ; 结果应回到 a（可用 mov [a_lo] 校验，这里直接打印）
    lea rcx, fmt_sub3
    mov r8, rax
    ; rdx 已是高 64 位结果
    ; 布参：rcx=fmt, rdx=高, r8=低
    call printf

    ; ---- 64x64 -> 128 乘法 ----
    lea rcx, fmt_mul1
    mov rdx, QWORD PTR [m1]
    mov r8, QWORD PTR [m2]
    call printf
    mov rax, QWORD PTR [m1]
    mul QWORD PTR [m2]              ; rdx:rax = 128 位积（无符号）
    mov r9, rdx                 ; 暂存高 64
    mov QWORD PTR [r_lo], rax
    mov QWORD PTR [r_hi], r9
    lea rcx, fmt_mul2
    mov rdx, QWORD PTR [r_hi]
    mov r8, QWORD PTR [r_lo]
    call printf

    ; ---- 128 位比较：先高位后低位 ----
    ; a = 1h_F000...0001 ; b = 0h_0FFF...FFFF -> a > b
    mov rax, QWORD PTR [a_hi]
    cmp rax, QWORD PTR [b_hi]
    jb  maina_lt_b
    ja  maina_gt_b
    mov rax, QWORD PTR [a_lo]
    cmp rax, QWORD PTR [b_lo]
    jb  maina_lt_b
    ja  maina_gt_b
    ; 相等分支
    lea rdx, no
    lea r8, no
    jmp mainprint_cmp
maina_lt_b:
    lea rdx, yes              ; a < b = yes
    lea r8, no               ; b < a = no
    jmp mainprint_cmp
maina_gt_b:
    lea rdx, no               ; a < b = no
    lea r8, yes              ; b < a = yes
mainprint_cmp:
    lea rcx, fmt_cmp
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
