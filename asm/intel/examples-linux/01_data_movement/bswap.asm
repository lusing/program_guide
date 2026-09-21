; ============================================================
; 文件: 01_data_movement/bswap.asm                         [Linux 版]
; 指令: BSWAP
; 描述: BSWAP 字节序反转 —— 大端/小端互换
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/01_data_movement/bswap.asm -o build/bswap.o
; 链接: gcc -no-pie build/bswap.o -o build/bswap
; 对照: examples/01_data_movement/bswap.asm
;
; x86 是小端机。网络字节序（big-endian）和 x86 内存字节序相反，
; 所以在 Linux 上写 socket / 二进制文件格式时，BSWAP 是最直接的转换手段。
; 注意 BSWAP 不接受 8 位操作数，16 位也要先 movzx 到 32 位再手工交换。
; ============================================================
default rel

section .data
    align 8
    fmt32  db "32位反转: 0x12345678 -> bswap eax  => 0x%08x", 10, 0
    fmt64  db "64位反转: 0x123456789ABCDEF0 -> bswap rax => 0x%016llx", 10, 0
    fmt16  db "16位反转: 0xABCD -> rol ax,8       => 0x%04x (BSWAP 不支持 16 位)", 10, 0
    fmt_re db "再反转一次就回来了: 0x%016llx", 10, 0

    w16    dw 0xABCD

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp

    ; 32 位字节序反转: 0x12345678 -> 0x78563412
    mov eax, 0x12345678
    bswap eax
    lea rdi, [fmt32]
    mov esi, eax
    xor eax, eax
    call printf

    ; 16 位字节序反转: 0xABCD -> 0xCDAB（BSWAP 最小只到 32 位）
    movzx eax, word [w16]
    rol ax, 8                    ; 高字节低字节互换
    lea rdi, [fmt16]
    mov esi, eax
    xor eax, eax
    call printf

    ; 64 位字节序反转: 0x123456789ABCDEF0 -> 0xF0DEBC9A78563412
    mov rax, 0x123456789ABCDEF0
    bswap rax
    lea rdi, [fmt64]
    mov rsi, rax
    xor eax, eax
    call printf

    ; 反转两次得到原值
    ; 注意 printf 的返回值放在 eax（打印的字符数），rax 已经被破坏，
    ; 所以这里必须重新装载一遍，不能接着用上面的 rax。
    mov rax, 0x123456789ABCDEF0
    bswap rax
    bswap rax
    lea rdi, [fmt_re]
    mov rsi, rax
    xor eax, eax
    call printf

    xor eax, eax
    leave
    ret
