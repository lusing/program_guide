; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    fmt32 BYTE "32位反转: 0x12345678 -> bswap eax  => 0x%08x", 10, 0
    fmt64 BYTE "64位反转: 0x123456789ABCDEF0 -> bswap rax => 0x%016llx", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 32位字节序反转: 12345678h -> 78563412h
    mov eax, 12345678h
    bswap eax
    lea rcx, fmt32
    mov edx, eax
    call printf

    ; 64位字节序反转: 123456789ABCDEF0h -> 0F0DEBC9A78563412h
    mov rax, 123456789ABCDEF0h
    bswap rax
    lea rcx, fmt64
    mov rdx, rax
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
