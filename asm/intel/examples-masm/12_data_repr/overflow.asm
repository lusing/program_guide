; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt_line BYTE "%s: result=0x%016llX  OF=%d CF=%d", 10, 0

    s1 BYTE "INT64_MAX + 1        ", 0
    s2 BYTE "UINT64_MAX + 1       ", 0
    s3 BYTE "1 + 2                ", 0
    s4 BYTE "INT64_MIN + INT64_MIN", 0


.data?
    of_bit BYTE 1 DUP(?)
    cf_bit BYTE 1 DUP(?)


.code

; DEMO_ADD 名称, 加数A, 加数B：算 A+B 并按 fmt_line 打印
; 注意：add 不支持 imm64 立即数（只有符号扩展的 imm32），
; 8000000000000000h 这种大数必须先 mov 进寄存器再相加——
; 否则 NASM 只给一个 "signed dword exceeds bounds" 警告并截断！
DEMO_ADD MACRO name_, valA, valB
    mov rax, valA
    mov rdx, valB
    add rax, rdx
    seto BYTE PTR [of_bit]
    setc BYTE PTR [cf_bit]
    lea rcx, [fmt_line]
    lea rdx, [name_]
    mov r8, rax
    movzx r9d, BYTE PTR [of_bit]
    movzx r10d, BYTE PTR [cf_bit]
    mov [rsp+32], r10
    call printf
ENDM

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 64                 ; 影子空间 + 第 5 变参栈槽

    DEMO_ADD s1, 7FFFFFFFFFFFFFFFh, 1
    DEMO_ADD s2, 0FFFFFFFFFFFFFFFFh, 1
    DEMO_ADD s3, 1, 2
    DEMO_ADD s4, 8000000000000000h, 8000000000000000h

    xor ecx, ecx
    call ExitProcess
main ENDP
END
