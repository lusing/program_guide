; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    src8   BYTE 0FFh          ; 8位源 (无符号255 / 有符号-1)
    src16  WORD 0FFFFh        ; 16位源 (无符号65535 / 有符号-1)
    src32  DWORD 0FFFFFF80h    ; 32位源 (无符号4294967168 / 有符号-128)

    fmt_zx8_32  BYTE "MOVZX 8->32:    0xFF       => %u", 10, 0
    fmt_zx16_32 BYTE "MOVZX 16->32:   0xFFFF     => %u", 10, 0
    fmt_zx8_64  BYTE "MOVZX 8->64:    0xFF       => %llu", 10, 0
    fmt_zx16_64 BYTE "MOVZX 16->64:   0xFFFF     => %llu", 10, 0
    fmt_sx8_32  BYTE "MOVSX 8->32:    0xFF       => %d", 10, 0
    fmt_sx16_32 BYTE "MOVSX 16->32:   0xFFFF     => %d", 10, 0
    fmt_sx8_64  BYTE "MOVSX 8->64:    0xFF       => %lld", 10, 0
    fmt_sxd32   BYTE "MOVSXD 32->64:  0xFFFFFF80 => %lld", 10, 0
    fmt_cmp     BYTE "对比 0xFF: 零扩展(MOVZX)=%llu, 符号扩展(MOVSX)=%lld", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; MOVZX 8->32 (无符号零扩展): 0FFh => 255
    movzx eax, BYTE PTR [src8]
    lea rcx, fmt_zx8_32
    mov edx, eax
    call printf

    ; MOVZX 16->32: 0FFFFh => 65535
    movzx eax, WORD PTR [src16]
    lea rcx, fmt_zx16_32
    mov edx, eax
    call printf

    ; MOVZX 8->64: 0FFh => 255
    movzx rax, BYTE PTR [src8]
    lea rcx, fmt_zx8_64
    mov rdx, rax
    call printf

    ; MOVZX 16->64: 0FFFFh => 65535
    movzx rax, WORD PTR [src16]
    lea rcx, fmt_zx16_64
    mov rdx, rax
    call printf

    ; MOVSX 8->32 (有符号符号扩展): 0FFh => -1
    movsx eax, BYTE PTR [src8]
    lea rcx, fmt_sx8_32
    mov edx, eax
    call printf

    ; MOVSX 16->32: 0FFFFh => -1
    movsx eax, WORD PTR [src16]
    lea rcx, fmt_sx16_32
    mov edx, eax
    call printf

    ; MOVSX 8->64: 0FFh => -1
    movsx rax, BYTE PTR [src8]
    lea rcx, fmt_sx8_64
    mov rdx, rax
    call printf

    ; MOVSXD 32->64: 0FFFFFF80h => -128
    movsxd rax, DWORD PTR [src32]
    lea rcx, fmt_sxd32
    mov rdx, rax
    call printf

    ; 对比: 0FFh 零扩展=255, 符号扩展=-1
    movzx rdx, BYTE PTR [src8]      ; 零扩展 -> %llu
    movsx r8, BYTE PTR [src8]        ; 符号扩展 -> %lld
    lea rcx, fmt_cmp
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
