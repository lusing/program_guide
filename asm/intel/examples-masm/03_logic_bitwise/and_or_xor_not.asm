; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt_and  BYTE "AND  0xFF & 0x0F        = 0x%llx", 10, 0
    fmt_or   BYTE "OR   0xF0 | 0x0F        = 0x%llx", 10, 0
    fmt_xor  BYTE "XOR  0xFF ^ 0x0F        = 0x%llx", 10, 0
    fmt_not  BYTE "NOT  ~0x0               = 0x%llx", 10, 0
    fmt_clr  BYTE "XOR  0xDEADBEEF ^ self  = 0x%llx", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    and rsp, -16             ; 确保16字节栈对齐
    sub rsp, 32              ; shadow space

    ; --- AND: 按位与，掩码提取低4位 ---
    mov rax, 0FFh
    and rax, 0Fh
    lea rcx, fmt_and
    mov rdx, rax
    call printf

    ; --- OR: 按位或，设置低4位 ---
    mov rax, 0F0h
    or rax, 0Fh
    lea rcx, fmt_or
    mov rdx, rax
    call printf

    ; --- XOR: 按位异或，翻转低4位 ---
    mov rax, 0FFh
    xor rax, 0Fh
    lea rcx, fmt_xor
    mov rdx, rax
    call printf

    ; --- NOT: 按位取反 ---
    mov rax, 0h
    not rax
    lea rcx, fmt_not
    mov rdx, rax
    call printf

    ; --- XOR 自身清零（常用技巧，比 mov rax,0 更短） ---
    mov rax, 0DEADBEEFh
    xor rax, rax
    lea rcx, fmt_clr
    mov rdx, rax
    call printf

    xor ecx, ecx             ; exit code = 0
    call ExitProcess
main ENDP
END
