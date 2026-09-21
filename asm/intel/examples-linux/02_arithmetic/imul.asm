; ============================================================
; 文件: 02_arithmetic/imul.asm                             [Linux 版]
; 指令: IMUL
; 描述: 有符号乘法 —— 单操作数 / 双操作数 / 三操作数三种形式
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/02_arithmetic/imul.asm -o build/imul.o
; 链接: gcc -no-pie build/imul.o -o build/imul
; 对照: examples/02_arithmetic/imul.asm
;
; IMUL 和 MUL 的关系：单操作数形式一样会写 RDX（高位），
; 但双操作数和三操作数形式只写目标寄存器，不碰 RDX，用起来方便得多。
; 编译器生成的普通乘法几乎都是三操作数 IMUL。
; ============================================================
default rel

section .data
    align 8
    fmt1    db "单操作数 imul rbx       : %lld * %lld => rax = %lld", 10, 0
    fmt2    db "双操作数 imul rax,rbx   : %lld * %lld => rax = %lld", 10, 0
    fmt3    db "三操作数 imul rax,rbx,10: %lld * 10  => rax = %lld", 10, 0
    fmt_neg db "负数乘法: %lld * %lld   => %lld", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rbx

    ; --- 单操作数: imul rbx -> RDX:RAX = RAX * RBX ---
    mov rax, 6
    mov rbx, 7
    imul rbx                         ; 积在 RAX（有符号时高位放 RDX）
    mov rcx, rax                     ; 先把结果挪到 rcx，免得下面盖掉 rdx
    lea rdi, [fmt1]
    mov rsi, 6
    mov rdx, 7
    xor eax, eax
    call printf

    ; --- 双操作数: imul rax, rbx ---
    mov rax, 12
    mov rbx, 8
    imul rax, rbx                    ; rax = 96
    mov rcx, rax
    lea rdi, [fmt2]
    mov rsi, 12
    mov rdx, 8
    xor eax, eax
    call printf

    ; --- 三操作数: imul rax, rbx, 立即数 ---
    mov rbx, 5
    imul rax, rbx, 10                ; rax = 5 * 10 = 50
    lea rdi, [fmt3]
    mov rsi, 5
    mov rdx, rax
    xor eax, eax
    call printf

    ; --- 负数乘法: -7 * 3 ---
    mov rax, -7
    mov rbx, 3
    imul rax, rbx                    ; rax = -21
    lea rdi, [fmt_neg]
    mov rsi, -7
    mov rdx, 3
    mov rcx, rax
    xor eax, eax
    call printf

    mov rbx, [rbp-8]
    xor eax, eax
    leave
    ret
