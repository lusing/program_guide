; ============================================================
; overflow.asm - 溢出判定：OF（有符号）vs CF（无符号）
; ============================================================
; 同一条 ADD，CPU 同时算两套标志：
;   OF = 有符号视角溢出（正+正=负 等）
;   CF = 无符号视角溢出（最高位向外进位）
; 两者独立，四种组合各举一例，用 seto/setc 取出打印：
;   INT64_MAX  + 1           -> OF=1 CF=0   有符号溢出
;   UINT64_MAX + 1           -> OF=0 CF=1   无符号进位（有符号视角是 -1+1=0）
;   1 + 2                    -> OF=0 CF=0   谁都没溢
;   INT64_MIN + INT64_MIN    -> OF=1 CF=1   双双溢出（负+负翻成正的 0）
;
; 预期输出:
;   INT64_MAX + 1        : result=0x8000000000000000  OF=1 CF=0
;   UINT64_MAX + 1       : result=0x0000000000000000  OF=0 CF=1
;   1 + 2                : result=0x0000000000000003  OF=0 CF=0
;   INT64_MIN + INT64_MIN: result=0x0000000000000000  OF=1 CF=1
; ============================================================

default rel

section .data
    fmt_line db "%s: result=0x%016llX  OF=%d CF=%d", 10, 0

    s1 db "INT64_MAX + 1        ", 0
    s2 db "UINT64_MAX + 1       ", 0
    s3 db "1 + 2                ", 0
    s4 db "INT64_MIN + INT64_MIN", 0

section .bss
    of_bit resb 1
    cf_bit resb 1

section .text
    global main
    extern printf
    extern ExitProcess

; DEMO_ADD 名称, 加数A, 加数B：算 A+B 并按 fmt_line 打印
; 注意：add 不支持 imm64 立即数（只有符号扩展的 imm32），
; 0x8000000000000000 这种大数必须先 mov 进寄存器再相加——
; 否则 NASM 只给一个 "signed dword exceeds bounds" 警告并截断！
%macro DEMO_ADD 3
    mov rax, %2
    mov rdx, %3
    add rax, rdx
    seto byte [of_bit]
    setc byte [cf_bit]
    lea rcx, [fmt_line]
    lea rdx, [%1]
    mov r8, rax
    movzx r9d, byte [of_bit]
    movzx r10d, byte [cf_bit]
    mov [rsp+32], r10           ; 第 5 变参（CF）走栈
    call printf
%endmacro

main:
    push rbp
    mov rbp, rsp
    sub rsp, 64                 ; 影子空间 + 第 5 变参栈槽

    DEMO_ADD s1, 0x7FFFFFFFFFFFFFFF, 1
    DEMO_ADD s2, 0xFFFFFFFFFFFFFFFF, 1
    DEMO_ADD s3, 1, 2
    DEMO_ADD s4, 0x8000000000000000, 0x8000000000000000

    xor ecx, ecx
    call ExitProcess
