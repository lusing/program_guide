; test_link.asm - 验证 NASM + MSVC link.exe + 运行 流水线
; 使用 Win32 API 直接输出，不依赖 C 运行时初始化
; 入口点为 main，通过 ExitProcess 正常退出

global main
extern ExitProcess
extern GetStdHandle
extern WriteFile

section .data
    msg     db "MSVC link.exe pipeline OK!", 13, 10
    msg_len equ $ - msg

section .bss
    written resd 1

section .text
main:
    sub     rsp, 40              ; 32 字节影子空间 + 8 字节对齐

    ; GetStdHandle(STD_OUTPUT_HANDLE = -11)
    mov     ecx, -11
    call    GetStdHandle

    ; WriteFile(hStdOut, msg, msg_len, &written, NULL)
    mov     rcx, rax             ; 句柄
    lea     rdx, [rel msg]       ; 缓冲区
    mov     r8d, msg_len         ; 长度
    lea     r9, [rel written]    ; 已写字节数指针
    mov     qword [rsp+32], 0    ; lpOverlapped = NULL
    call    WriteFile

    ; ExitProcess(0)
    xor     ecx, ecx
    call    ExitProcess
    ; 不会返回
