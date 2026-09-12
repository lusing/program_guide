; ============================================================
; 文件: 01_data_movement/mov_extend.asm
; 指令: MOVZX / MOVSX / MOVSXD
; 描述: 零扩展与符号扩展传送
; 编译: nasm -f win64 mov_extend.asm -o mov_extend.obj
; 链接: link /subsystem:console /entry:main mov_extend.obj msvcrt.lib kernel32.lib
; ============================================================
default rel

section .data
    align 8
    src8   db 0xFF          ; 8位源 (无符号255 / 有符号-1)
    src16  dw 0xFFFF        ; 16位源 (无符号65535 / 有符号-1)
    src32  dd 0xFFFFFF80    ; 32位源 (无符号4294967168 / 有符号-128)

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
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; MOVZX 8->32 (无符号零扩展): 0xFF => 255
    movzx eax, byte [src8]
    lea rcx, [fmt_zx8_32]
    mov edx, eax
    call printf

    ; MOVZX 16->32: 0xFFFF => 65535
    movzx eax, word [src16]
    lea rcx, [fmt_zx16_32]
    mov edx, eax
    call printf

    ; MOVZX 8->64: 0xFF => 255
    movzx rax, byte [src8]
    lea rcx, [fmt_zx8_64]
    mov rdx, rax
    call printf

    ; MOVZX 16->64: 0xFFFF => 65535
    movzx rax, word [src16]
    lea rcx, [fmt_zx16_64]
    mov rdx, rax
    call printf

    ; MOVSX 8->32 (有符号符号扩展): 0xFF => -1
    movsx eax, byte [src8]
    lea rcx, [fmt_sx8_32]
    mov edx, eax
    call printf

    ; MOVSX 16->32: 0xFFFF => -1
    movsx eax, word [src16]
    lea rcx, [fmt_sx16_32]
    mov edx, eax
    call printf

    ; MOVSX 8->64: 0xFF => -1
    movsx rax, byte [src8]
    lea rcx, [fmt_sx8_64]
    mov rdx, rax
    call printf

    ; MOVSXD 32->64: 0xFFFFFF80 => -128
    movsxd rax, dword [src32]
    lea rcx, [fmt_sxd32]
    mov rdx, rax
    call printf

    ; 对比: 0xFF 零扩展=255, 符号扩展=-1
    movzx rdx, byte [src8]      ; 零扩展 -> %llu
    movsx r8, byte [src8]        ; 符号扩展 -> %lld
    lea rcx, [fmt_cmp]
    call printf

    xor ecx, ecx
    call ExitProcess
