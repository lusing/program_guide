; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    one     REAL8 1.0
    dump    REAL8 0.0

    fmt_top0  BYTE "TOP after finit = %d", 10, 0
    fmt_tops  BYTE "after 1 fld: TOP=%d, after 2 fld: TOP=%d, after 3 fld: TOP=%d", 10, 0
    fmt_pop   BYTE "after 2 fstp: TOP=%d", 10, 0
    fmt_fxam1 BYTE "fxam on filled st0: C3C2C0 = %d,%d,%d (valid)", 10, 0
    fmt_fxam2 BYTE "fxam on empty register: C3C2 = %d,%d (empty)", 10, 0
    fmt_over  BYTE "after 9th fld: TOP=%d (wrapped), st0 = indefinite QNaN", 10, 0
    fmt_bits  BYTE "  st0 bits = 0x%016llX", 10, 0


.data?
    align 8
    st0_bits QWORD 1 DUP(?)


.code

; ------------------------------------------------------------
; get_top: 返回 TOP = (fnstsw >> 11)  AND  7 于 EAX
; ------------------------------------------------------------
get_top:
    fnstsw ax
    shr eax, 11
    and eax, 7
    ret

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    push r13
    push r14

    finit                      ; TOP = 0，8 个寄存器全空

    call get_top
    lea rcx, fmt_top0
    mov edx, eax
    call printf

    ; ---- 连压三个值：TOP 递减 7,6,5 ----
    fld QWORD PTR [one]
    call get_top
    mov r12d, eax
    fld QWORD PTR [one]
    call get_top
    mov r13d, eax
    fld QWORD PTR [one]
    call get_top
    mov r14d, eax
    lea rcx, fmt_tops
    mov edx, r12d
    mov r8d, r13d
    mov r9d, r14d
    call printf

    ; ---- 弹两个：TOP 回升到 7 ----
    fstp QWORD PTR [dump]
    fstp QWORD PTR [dump]
    call get_top
    lea rcx, fmt_pop
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
    lea rcx, fmt_fxam1
    mov edx, r12d
    mov r8d, r13d
    mov r9d, r14d
    call printf

    ; ---- 清空后 fxam：C3=1 C2=0（empty）----
    fstp QWORD PTR [dump]
    fxam
    fnstsw ax
    mov r12d, eax
    shr r12d, 14
    and r12d, 1                ; C3
    mov r13d, eax
    shr r13d, 10
    and r13d, 1                ; C2
    lea rcx, fmt_fxam2
    mov edx, r12d
    mov r8d, r13d
    call printf

    ; ---- 连 fld 9 次：前 8 次填满（TOP 回到 0），第 9 次溢出 ----
    mov ebx, 9
mainovf_loop:
    fld QWORD PTR [one]
    dec ebx
    jnz mainovf_loop
    ; 溢出时 TOP 不再前进（停在 0），st(0) 被改写为 indefinite QNaN
    fstp QWORD PTR [st0_bits]      ; 弹出 indefinite
    call get_top
    lea rcx, fmt_over
    mov edx, eax
    call printf
    lea rcx, fmt_bits
    mov rdx, QWORD PTR [st0_bits]
    call printf

    finit
    pop r14
    pop r13
    pop r12
    pop rbx
    xor ecx, ecx
    call ExitProcess
main ENDP
END
