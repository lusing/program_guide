; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern ExitProcess : PROC
extern GetStdHandle : PROC
extern WriteFile : PROC

.data
    msg     BYTE "MSVC link.exe pipeline OK!", 13, 10
    msg_len EQU $ - msg


.data?
    written DWORD 1 DUP(?)


.code
main PROC
    sub     rsp, 40              ; 32 字节影子空间 + 8 字节对齐

    ; GetStdHandle(STD_OUTPUT_HANDLE = -11)
    mov     ecx, -11
    call    GetStdHandle

    ; WriteFile(hStdOut, msg, msg_len,  AND written, NULL)
    mov     rcx, rax             ; 句柄
    lea rdx, msg       ; 缓冲区
    mov     r8d, msg_len         ; 长度
    lea r9, written    ; 已写字节数指针
    mov     QWORD PTR [rsp+32], 0    ; lpOverlapped = NULL
    call    WriteFile

    ; ExitProcess(0)
    xor     ecx, ecx
    call    ExitProcess
    ; 不会返回
main ENDP
END
