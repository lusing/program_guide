; ============================================================
; 文件: 01_data_movement/mov_basic.asm
; 指令: MOV
; 描述: MOV指令基础 - 立即数/寄存器/内存间的数据传送
; 编译: nasm -f win64 mov_basic.asm -o mov_basic.obj
; 链接: link /subsystem:console /entry:main mov_basic.obj msvcrt.lib kernel32.lib
; ============================================================
default rel

section .data
    align 8
    var      dq 100            ; 测试用内存变量
    byte_v   db 0
    word_v   dw 0
    dword_v  dd 0
    qword_v  dq 0

    fmt_imm   db "立即数->寄存器: mov rax,42          => rax = %lld", 10, 0
    fmt_reg   db "寄存器->寄存器: mov rbx,rax         => rbx = %lld", 10, 0
    fmt_m2r   db "内存->寄存器:   mov rax,[var]       => rax = %lld", 10, 0
    fmt_r2m   db "寄存器->内存:   mov [var],rax       => var = %lld", 10, 0
    fmt_byte  db "字节传送: mov byte [b],0x41         => b   = %d (0x%02x)", 10, 0
    fmt_word  db "字传送:   mov word [w],0x1234       => w   = %d (0x%04x)", 10, 0
    fmt_dword db "双字传送: mov dword [d],0x12345678   => d   = %d (0x%08x)", 10, 0
    fmt_qword db "四字传送: mov qword [q],0x123456789ABCDEF0 => q = 0x%016llx", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 立即数到寄存器
    mov rax, 42
    lea rcx, [fmt_imm]
    mov rdx, rax
    call printf

    ; 寄存器到寄存器 (重新载入 rax, 因 printf 会破坏 rax 返回值)
    mov rax, 42
    mov rbx, rax              ; rbx = 42
    lea rcx, [fmt_reg]
    mov rdx, rbx
    call printf

    ; 内存到寄存器
    mov rax, [var]
    lea rcx, [fmt_m2r]
    mov rdx, rax
    call printf

    ; 寄存器到内存
    mov rax, 999
    mov [var], rax
    lea rcx, [fmt_r2m]
    mov rdx, [var]
    call printf

    ; 不同大小: byte (0x41 = 65)
    mov byte [byte_v], 0x41
    movzx edx, byte [byte_v]
    lea rcx, [fmt_byte]
    mov r8d, edx
    call printf

    ; 不同大小: word (0x1234 = 4660)
    mov word [word_v], 0x1234
    movzx edx, word [word_v]
    lea rcx, [fmt_word]
    mov r8d, edx
    call printf

    ; 不同大小: dword (0x12345678)
    mov dword [dword_v], 0x12345678
    mov edx, [dword_v]
    lea rcx, [fmt_dword]
    mov r8d, edx
    call printf

    ; 不同大小: qword (0x123456789ABCDEF0)
    mov rax, 0x123456789ABCDEF0
    mov [qword_v], rax
    lea rcx, [fmt_qword]
    mov rdx, [qword_v]
    call printf

    xor ecx, ecx
    call ExitProcess
