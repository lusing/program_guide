; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    var      QWORD 100            ; 测试用内存变量
    byte_v   BYTE 0
    word_v   WORD 0
    dword_v  DWORD 0
    qword_v  QWORD 0

    fmt_imm   BYTE "立即数->寄存器: mov rax,42          => rax = %lld", 10, 0
    fmt_reg   BYTE "寄存器->寄存器: mov rbx,rax         => rbx = %lld", 10, 0
    fmt_m2r   BYTE "内存->寄存器:   mov rax,[var]       => rax = %lld", 10, 0
    fmt_r2m   BYTE "寄存器->内存:   mov [var],rax       => var = %lld", 10, 0
    fmt_byte  BYTE "字节传送: mov byte [b],0x41         => b   = %d (0x%02x)", 10, 0
    fmt_word  BYTE "字传送:   mov word [w],0x1234       => w   = %d (0x%04x)", 10, 0
    fmt_dword BYTE "双字传送: mov dword [d],0x12345678   => d   = %d (0x%08x)", 10, 0
    fmt_qword BYTE "四字传送: mov qword [q],0x123456789ABCDEF0 => q = 0x%016llx", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 立即数到寄存器
    mov rax, 42
    lea rcx, fmt_imm
    mov rdx, rax
    call printf

    ; 寄存器到寄存器 (重新载入 rax, 因 printf 会破坏 rax 返回值)
    mov rax, 42
    mov rbx, rax              ; rbx = 42
    lea rcx, fmt_reg
    mov rdx, rbx
    call printf

    ; 内存到寄存器
    mov rax, QWORD PTR [var]
    lea rcx, fmt_m2r
    mov rdx, rax
    call printf

    ; 寄存器到内存
    mov rax, 999
    mov QWORD PTR [var], rax
    lea rcx, fmt_r2m
    mov rdx, QWORD PTR [var]
    call printf

    ; 不同大小: byte (41h = 65)
    mov BYTE PTR [byte_v], 41h
    movzx edx, BYTE PTR [byte_v]
    lea rcx, fmt_byte
    mov r8d, edx
    call printf

    ; 不同大小: word (1234h = 4660)
    mov WORD PTR [word_v], 1234h
    movzx edx, WORD PTR [word_v]
    lea rcx, fmt_word
    mov r8d, edx
    call printf

    ; 不同大小: dword (12345678h)
    mov DWORD PTR [dword_v], 12345678h
    mov edx, DWORD PTR [dword_v]
    lea rcx, fmt_dword
    mov r8d, edx
    call printf

    ; 不同大小: qword (123456789ABCDEF0h)
    mov rax, 123456789ABCDEF0h
    mov QWORD PTR [qword_v], rax
    lea rcx, fmt_qword
    mov rdx, QWORD PTR [qword_v]
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
