; ============================================================
; 文件: 02_arithmetic/imul.asm
; 指令: IMUL
; 描述: 有符号乘法 - 单/双/三操作数与负数
; 编译: nasm -f win64 imul.asm -o imul.obj
; 链接: link /subsystem:console /entry:main imul.obj msvcrt.lib kernel32.lib
; ============================================================
default rel

section .data
    align 8
    fmt1   db "单操作数 imul rbx       : %lld * %lld => RDX:RAX = %lld", 10, 0
    fmt2   db "双操作数 imul rax,rbx   : %lld * %lld => rax = %lld", 10, 0
    fmt3   db "三操作数 imul rax,rbx,10: %lld * 10  => rax = %lld", 10, 0
    fmt_neg db "负数乘法: -7 * 3        => %lld", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 单操作数: imul rbx -> RDX:RAX = RAX * RBX
    mov rax, 6
    mov rbx, 7
    imul rbx                    ; RAX = 42
    lea rcx, [fmt1]
    mov rdx, 6
    mov r8, 7
    mov r9, rax
    call printf

    ; 双操作数: imul rax, rbx
    mov rax, 12
    mov rbx, 8
    imul rax, rbx               ; rax = 96
    lea rcx, [fmt2]
    mov rdx, 12
    mov r8, 8
    mov r9, rax
    call printf

    ; 三操作数: imul rax, rbx, 10
    mov rbx, 5
    imul rax, rbx, 10           ; rax = 5 * 10 = 50
    lea rcx, [fmt3]
    mov rdx, 5
    mov r8, rax
    call printf

    ; 负数乘法: -7 * 3
    mov rax, -7
    mov rbx, 3
    imul rax, rbx               ; rax = -21
    lea rcx, [fmt_neg]
    mov rdx, rax
    call printf

    xor ecx, ecx
    call ExitProcess
