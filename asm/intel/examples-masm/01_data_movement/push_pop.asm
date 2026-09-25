; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    fmt_push BYTE "push 顺序: %lld, %lld, %lld", 10, 0
    fmt_pop  BYTE "pop  顺序: %lld, %lld, %lld (后进先出 LIFO)", 10, 0
    fmt_imm  BYTE "push 立即数 0xFF 后 pop => %lld", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 打印将入栈的顺序
    lea rcx, fmt_push
    mov rdx, 1
    mov r8, 2
    mov r9, 3
    call printf

    ; 入栈 1, 2, 3 (3在栈顶)
    push 1
    push 2
    push 3

    ; 出栈 (LIFO): 3, 2, 1
    pop rax        ; 3
    pop r10        ; 2
    pop r11        ; 1
    lea rcx, fmt_pop
    mov rdx, rax   ; 3
    mov r8, r10    ; 2
    mov r9, r11    ; 1
    call printf

    ; push 立即数 0FFh (=255), 再 pop
    push 0FFh
    pop rax
    lea rcx, fmt_imm
    mov rdx, rax
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
