; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    v_1    REAL8 1.0
    v_m2   REAL8 -2.0
    v_01   REAL8 0.1
    v_02   REAL8 0.2
    v_03   REAL8 0.3
    v_inf  QWORD 7FF0000000000000h     ; +inf 的位模式直接写出来

    fmt_line BYTE "%s: bits=0x%016llX  sign=%llu exp=%4llu mantissa=0x%013llX", 10, 0
    fmt_sum  BYTE "0.1+0.2 -> bits=0x%016llX", 10, 0
    fmt_lit  BYTE "0.3     -> bits=0x%016llX   (differ by 1 ULP!)", 10, 0

    n1 BYTE "+1.0", 0
    n2 BYTE "-2.0", 0
    n3 BYTE "0.1 ", 0
    n4 BYTE "+inf", 0


.code

; DECODE 名称, 变量：解码 sign/exp/mantissa 并按 fmt_line 打印
DECODE MACRO name_, var_
    mov rax, [var_]
    mov r8, rax
    mov r9, rax
    shr r9, 63
    mov r10, rax
    shr r10, 52
    and r10, 07FFh
    mov r11, rax
    shl r11, 12
    shr r11, 12
    lea rcx, [fmt_line]
    lea rdx, [name_]
    mov [rsp+32], r10
    mov [rsp+40], r11
    call printf
ENDM

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 64                 ; 影子空间 + 第 4/5 变参的栈槽

    DECODE n1, v_1
    DECODE n2, v_m2
    DECODE n3, v_01
    DECODE n4, v_inf

    ; ---- 0.1 + 0.2 的位模式 vs 字面量 0.3 ----
    movsd xmm0, QWORD PTR [v_01]
    addsd xmm0, QWORD PTR [v_02]
    movq rdx, xmm0
    lea rcx, fmt_sum
    call printf

    mov rdx, QWORD PTR [v_03]
    lea rcx, fmt_lit
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
