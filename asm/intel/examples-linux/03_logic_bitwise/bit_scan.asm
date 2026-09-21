; ============================================================
; 文件: 03_logic_bitwise/bit_scan.asm                      [Linux 版]
; 指令: BSF / BSR
; 描述: 位扫描 —— 找最低 / 最高的那个置 1 位
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/03_logic_bitwise/bit_scan.asm -o build/bit_scan.o
; 链接: gcc -no-pie build/bit_scan.o -o build/bit_scan
; 对照: examples/03_logic_bitwise/bit_scan.asm
;
;   BSF  从低位往高位找第一个 1，结果 = 下标（0 起）
;   BSR  从高位往低位找第一个 1，结果 = 最高位下标
; 源操作数为 0 时目标寄存器内容未定义，只保证 ZF=1 ——
; 所以调用前必须先测零，或者配合 TZCNT / LZCNT（BMI1/BMI2，本机没这俩扩展）。
; 位扫描最常见的用途：求以 2 为底的对数、找空闲的内存页、算哈希桶下标。
; ============================================================
default rel

section .data
    align 8
    fmt_bsf  db "BSF  0x%llx -> 最低置1位下标 %lld  (低->高)", 10, 0
    fmt_bsr  db "BSR  0x%llx -> 最高置1位下标 %lld  (高->低)", 10, 0
    fmt_log2 db "顺带求 log2(0x%llx 向上取整) = %lld", 10, 0
    fmt_zero db "BSF/BSR 遇到 0x0 -> ZF=1（目标值未定义，别用）", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rbx                 ; rbx 全程用作扫描输入，退场要还原

    ; --- BSF: 0x50 = 0b1010000，最低位的 1 在 bit 4 ---
    mov rbx, 0x50
    bsf rax, rbx                     ; rax = 4
    lea rdi, [fmt_bsf]
    mov rsi, rbx
    mov rdx, rax
    xor eax, eax
    call printf

    ; --- BSR: 同一个数的最高位 1 在 bit 6 ---
    mov rbx, 0x50
    bsr rax, rbx                     ; rax = 6
    lea rdi, [fmt_bsr]
    mov rsi, rbx
    mov rdx, rax
    xor eax, eax
    call printf

    ; --- 实用套路：BSR + 1 就是「向上取整的 log2」，用来算位图要几级 ---
    mov rbx, 0x9                     ; 0b1001 -> 最高位在 bit3
    bsr rax, rbx
    inc rax                          ; 3 + 1 = 4，即「4 位能装下 9」
    lea rdi, [fmt_log2]
    mov rsi, rbx
    mov rdx, rax
    xor eax, eax
    call printf

    ; --- 源为 0：ZF=1，结果不可信，所以要先判断 ---
    mov rbx, 0
    bsf rax, rbx                     ; 源是 0 -> ZF=1
    jnz .skip_zero                   ; ZF=1 时不跳，走下面这一支
    lea rdi, [fmt_zero]
    xor eax, eax
    call printf
.skip_zero:

    mov rbx, [rbp-8]
    xor eax, eax
    leave
    ret
