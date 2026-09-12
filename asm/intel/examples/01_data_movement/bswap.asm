; ============================================================
; 文件: 01_data_movement/bswap.asm
; 指令: BSWAP
; 描述: BSWAP字节序转换 - 大小端反转
; 编译: nasm -f win64 bswap.asm -o bswap.obj
; 链接: link /subsystem:console /entry:main bswap.obj msvcrt.lib kernel32.lib
; ============================================================
default rel

section .data
    align 8
    fmt32 db "32位反转: 0x12345678 -> bswap eax  => 0x%08x", 10, 0
    fmt64 db "64位反转: 0x123456789ABCDEF0 -> bswap rax => 0x%016llx", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 32位字节序反转: 0x12345678 -> 0x78563412
    mov eax, 0x12345678
    bswap eax
    lea rcx, [fmt32]
    mov edx, eax
    call printf

    ; 64位字节序反转: 0x123456789ABCDEF0 -> 0xF0DEBC9A78563412
    mov rax, 0x123456789ABCDEF0
    bswap rax
    lea rcx, [fmt64]
    mov rdx, rax
    call printf

    xor ecx, ecx
    call ExitProcess
