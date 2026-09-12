; ============================================================
; 文件: 02_arithmetic/add_sub.asm
; 指令: ADD / SUB
; 描述: 加法与减法 - 寄存器/立即数/内存及标志位溢出
; 编译: nasm -f win64 add_sub.asm -o add_sub.obj
; 链接: link /subsystem:console /entry:main add_sub.obj msvcrt.lib kernel32.lib
; ============================================================
default rel

section .data
    align 8
    mem dq 1000

    fmt_add_reg db "add rax,rbx  : %lld + %lld = %lld", 10, 0
    fmt_add_imm db "add rax,10   : %lld + 10 = %lld", 10, 0
    fmt_add_mem db "add [mem],rax: %lld + %lld = %lld (内存)", 10, 0
    fmt_sub_reg db "sub rax,rbx  : %lld - %lld = %lld", 10, 0
    fmt_sub_imm db "sub rax,5    : %lld - 5 = %lld", 10, 0
    fmt_ovf     db "溢出演示: %d + 1 = %d (有符号溢出 OF=1)", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; add rax, rbx (寄存器加)
    mov rax, 50
    mov rbx, 30
    add rax, rbx                ; rax = 80
    lea rcx, [fmt_add_reg]
    mov rdx, 50
    mov r8, 30
    mov r9, rax
    call printf

    ; add rax, 10 (立即数加)
    mov rax, 100
    add rax, 10                ; rax = 110
    lea rcx, [fmt_add_imm]
    mov rdx, 100
    mov r8, rax
    call printf

    ; add [mem], rax (内存加)
    mov qword [mem], 1000
    mov rax, 55
    add [mem], rax             ; mem = 1055
    lea rcx, [fmt_add_mem]
    mov rdx, 1000
    mov r8, 55
    mov r9, [mem]
    call printf

    ; sub rax, rbx (寄存器减)
    mov rax, 200
    mov rbx, 75
    sub rax, rbx               ; rax = 125
    lea rcx, [fmt_sub_reg]
    mov rdx, 200
    mov r8, 75
    mov r9, rax
    call printf

    ; sub rax, 5 (立即数减)
    mov rax, 50
    sub rax, 5                 ; rax = 45
    lea rcx, [fmt_sub_imm]
    mov rdx, 50
    mov r8, rax
    call printf

    ; 溢出演示: 32位 INT_MAX + 1
    mov eax, 0x7FFFFFFF        ; eax = 2147483647 (INT32_MAX)
    mov edx, eax               ; 保存原值 (2147483647)
    add eax, 1                 ; eax = 0x80000000 = -2147483648, OF=1
    mov r8d, eax               ; 结果
    lea rcx, [fmt_ovf]
    call printf

    xor ecx, ecx
    call ExitProcess
