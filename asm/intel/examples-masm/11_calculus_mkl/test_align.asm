; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

avxdata SEGMENT ALIGN(32) 'DATA'
    align 4
    f_one   DWORD 1.0
    ; (align satisfied by SEGMENT ALIGN)
    vec32   DWORD 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0

    fmt_msg BYTE "Hello from test_align!", 10, 0

avxdata ENDS

avxbss SEGMENT ALIGN(32) 'DATA'
    ; (align satisfied by SEGMENT ALIGN)
    buf     DWORD 1024 DUP(?)

avxbss ENDS

.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    lea rcx, fmt_msg
    call printf

    ; Touch the AVX2 data to make sure it's accessible
    vmovups ymm0, YMMWORD PTR [vec32]
    vzeroupper

    xor ecx, ecx
    call ExitProcess
main ENDP
END
