; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    fmt_pos BYTE "正数: 100 / 7  => 商=%lld, 余=%lld", 10, 0
    fmt_neg BYTE "负数: -100 / 7 => 商=%lld, 余=%lld", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 正数: 100 / 7 (除前用 CQO 符号扩展 RAX -> RDX:RAX)
    mov rax, 100
    cqo                         ; RDX = RAX 符号扩展 (正数 => RDX=0)
    mov rbx, 7
    idiv rbx                    ; RAX=商=14, RDX=余=2
    mov r8, rdx                 ; r8 = 余数 2
    mov rdx, rax                ; rdx = 商 14
    lea rcx, fmt_pos
    call printf

    ; 负数: -100 / 7
    mov rax, -100
    cqo                         ; RDX = 0FFFFFFFFFFFFFFFFh (符号扩展)
    mov rbx, 7
    idiv rbx                    ; RAX=商=-14, RDX=余=-2 (向零截断)
    mov r8, rdx                 ; r8 = 余数 -2
    mov rdx, rax                ; rdx = 商 -14
    lea rcx, fmt_neg
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
