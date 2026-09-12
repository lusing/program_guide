; Test: does align 32 in .data cause crashes?
default rel

section .data
    align 4
    f_one   dd 1.0
    align 32
    vec32   dd 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0

    fmt_msg db "Hello from test_align!", 10, 0

section .bss
    alignb 32
    buf     resd 1024

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    lea rcx, [fmt_msg]
    call printf

    ; Touch the AVX2 data to make sure it's accessible
    vmovups ymm0, [vec32]
    vzeroupper

    xor ecx, ecx
    call ExitProcess
