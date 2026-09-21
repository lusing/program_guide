; ============================================================
; 文件: 01_data_movement/mov_extend.asm                    [Linux 版]
; 指令: MOVZX / MOVSX / MOVSXD
; 描述: 零扩展与符号扩展传送
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/01_data_movement/mov_extend.asm -o build/mov_extend.o
; 链接: gcc -no-pie build/mov_extend.o -o build/mov_extend
; 对照: examples/01_data_movement/mov_extend.asm
; ============================================================
default rel

section .data
    align 8
    src8   db 0xFF          ; 8 位源 (无符号 255 / 有符号 -1)
    src16  dw 0xFFFF        ; 16 位源 (无符号 65535 / 有符号 -1)
    src32  dd 0xFFFFFF80    ; 32 位源 (无符号 4294967168 / 有符号 -128)

    fmt_zx8_32  db "MOVZX 8->32:    0xFF       => %u", 10, 0
    fmt_zx16_32 db "MOVZX 16->32:   0xFFFF     => %u", 10, 0
    fmt_zx8_64  db "MOVZX 8->64:    0xFF       => %llu", 10, 0
    fmt_zx16_64 db "MOVZX 16->64:   0xFFFF     => %llu", 10, 0
    fmt_sx8_32  db "MOVSX 8->32:    0xFF       => %d", 10, 0
    fmt_sx16_32 db "MOVSX 16->32:   0xFFFF     => %d", 10, 0
    fmt_sx8_64  db "MOVSX 8->64:    0xFF       => %lld", 10, 0
    fmt_sxd32   db "MOVSXD 32->64:  0xFFFFFF80 => %lld", 10, 0
    fmt_cmp     db "对比 0xFF: 零扩展(MOVZX)=%llu, 符号扩展(MOVSX)=%lld", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp

    ; MOVZX 8->32 (无符号零扩展): 0xFF => 255
    movzx eax, byte [src8]
    lea rdi, [fmt_zx8_32]
    mov esi, eax                 ; %u 只取低 32 位
    xor eax, eax
    call printf

    ; MOVZX 16->32: 0xFFFF => 65535
    movzx eax, word [src16]
    lea rdi, [fmt_zx16_32]
    mov esi, eax
    xor eax, eax
    call printf

    ; MOVZX 8->64: 0xFF => 255
    movzx rax, byte [src8]
    lea rdi, [fmt_zx8_64]
    mov rsi, rax                 ; %llu 要 64 位
    xor eax, eax
    call printf

    ; MOVZX 16->64: 0xFFFF => 65535
    movzx rax, word [src16]
    lea rdi, [fmt_zx16_64]
    mov rsi, rax
    xor eax, eax
    call printf

    ; MOVSX 8->32 (有符号符号扩展): 0xFF => -1
    movsx eax, byte [src8]
    lea rdi, [fmt_sx8_32]
    mov esi, eax
    xor eax, eax
    call printf

    ; MOVSX 16->32: 0xFFFF => -1
    movsx eax, word [src16]
    lea rdi, [fmt_sx16_32]
    mov esi, eax
    xor eax, eax
    call printf

    ; MOVSX 8->64: 0xFF => -1
    movsx rax, byte [src8]
    lea rdi, [fmt_sx8_64]
    mov rsi, rax
    xor eax, eax
    call printf

    ; MOVSXD 32->64: 0xFFFFFF80 => -128
    movsxd rax, dword [src32]
    lea rdi, [fmt_sxd32]
    mov rsi, rax
    xor eax, eax
    call printf

    ; 对比: 同一个字节 0xFF，零扩展得 255，符号扩展得 -1
    movzx rsi, byte [src8]       ; 第 2 个参数 -> %llu
    movsx rdx, byte [src8]       ; 第 3 个参数 -> %lld
    lea rdi, [fmt_cmp]
    xor eax, eax
    call printf

    xor eax, eax
    leave
    ret
