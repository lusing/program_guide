; ============================================================
; fpu_stack.asm - FPU 栈顶指针 TOP、FXAM 与栈溢出
; ============================================================
; x87 是 8 深度的硬件栈机。状态字 (fnstsw) 的 bit13:11 是 TOP：
;   - 空栈时 TOP = 0（下一个 fld 写物理寄存器 0）
;   - 每次 fld：TOP = (TOP-1) & 7，新值成为 st0
;   - 每次 fstp：弹出，TOP = (TOP+1) & 7
;
; 演示:
;   - fnstsw 读取 TOP，观察 fld/fstp 推进与回绕
;   - fxam 判断 st0 类别：有值 C3=0,C2=1,C0=0；空 C3=1,C2=0
;   - 连续 fld 9 次：第 9 次栈溢出。默认掩码下不抛异常，
;     st0 变成「不确定值」QNaN indefinite（0xFFF8000000000000）
;
; 预期输出:
;   TOP after finit = 0
;   after 1 fld: TOP=7, after 2 fld: TOP=6, after 3 fld: TOP=5
;   after 2 fstp: TOP=7
;   fxam on filled st0: C3C2C0 = 0,1,0 (valid)
;   fxam on empty register: C3C2 = 1,0 (empty)
;   after 9th fld: TOP=7 (wrapped), st0 = indefinite QNaN
;     st0 bits = 0xFFF8000000000000
; ============================================================

default rel

section .data
    align 8
    one     dq 1.0
    dump    dq 0.0

    fmt_top0  db "TOP after finit = %d", 10, 0
    fmt_tops  db "after 1 fld: TOP=%d, after 2 fld: TOP=%d, after 3 fld: TOP=%d", 10, 0
    fmt_pop   db "after 2 fstp: TOP=%d", 10, 0
    fmt_fxam1 db "fxam on filled st0: C3C2C0 = %d,%d,%d (valid)", 10, 0
    fmt_fxam2 db "fxam on empty register: C3C2 = %d,%d (empty)", 10, 0
    fmt_over  db "after 9th fld: TOP=%d (wrapped), st0 = indefinite QNaN", 10, 0
    fmt_bits  db "  st0 bits = 0x%016llX", 10, 0

section .bss
    align 8
    st0_bits resq 1

section .text
    global main
    extern printf
    extern ExitProcess

; ------------------------------------------------------------
; get_top: 返回 TOP = (fnstsw >> 11) & 7 于 EAX
; ------------------------------------------------------------
get_top:
    fnstsw ax
    shr eax, 11
    and eax, 7
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    push r13
    push r14

    finit                      ; TOP = 0，8 个寄存器全空

    call get_top
    lea rcx, [fmt_top0]
    mov edx, eax
    call printf

    ; ---- 连压三个值：TOP 递减 7,6,5 ----
    fld qword [one]
    call get_top
    mov r12d, eax
    fld qword [one]
    call get_top
    mov r13d, eax
    fld qword [one]
    call get_top
    mov r14d, eax
    lea rcx, [fmt_tops]
    mov edx, r12d
    mov r8d, r13d
    mov r9d, r14d
    call printf

    ; ---- 弹两个：TOP 回升到 7 ----
    fstp qword [dump]
    fstp qword [dump]
    call get_top
    lea rcx, [fmt_pop]
    mov edx, eax
    call printf

    ; ---- fxam 有值：C3=0 C2=1 C0=0 ----
    fxam
    fnstsw ax
    mov r12d, eax
    shr r12d, 14
    and r12d, 1                ; C3
    mov r13d, eax
    shr r13d, 10
    and r13d, 1                ; C2
    mov r14d, eax
    shr r14d, 8
    and r14d, 1                ; C0
    lea rcx, [fmt_fxam1]
    mov edx, r12d
    mov r8d, r13d
    mov r9d, r14d
    call printf

    ; ---- 清空后 fxam：C3=1 C2=0（empty）----
    fstp qword [dump]
    fxam
    fnstsw ax
    mov r12d, eax
    shr r12d, 14
    and r12d, 1                ; C3
    mov r13d, eax
    shr r13d, 10
    and r13d, 1                ; C2
    lea rcx, [fmt_fxam2]
    mov edx, r12d
    mov r8d, r13d
    call printf

    ; ---- 连 fld 9 次：前 8 次填满（TOP 回到 0），第 9 次溢出 ----
    mov ebx, 9
.ovf_loop:
    fld qword [one]
    dec ebx
    jnz .ovf_loop
    ; 溢出时 TOP 不再前进（停在 0），st0 被改写为 indefinite QNaN
    fstp qword [st0_bits]      ; 弹出 indefinite
    call get_top
    lea rcx, [fmt_over]
    mov edx, eax
    call printf
    lea rcx, [fmt_bits]
    mov rdx, [st0_bits]
    call printf

    finit
    pop r14
    pop r13
    pop r12
    pop rbx
    xor ecx, ecx
    call ExitProcess
