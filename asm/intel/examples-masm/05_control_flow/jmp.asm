; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt_before BYTE "Before jump", 10, 0
    fmt_skip   BYTE "Skipped", 10, 0        ; 这行永远不会被打印
    fmt_after  BYTE "After jump", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32              ; shadow space

    ; --- 打印 "Before jump" ---
    lea rcx, fmt_before
    call printf

    ; --- 无条件跳转到 mainafter_skip ---
    ; JMP 不检查任何标志位，直接跳转
    jmp mainafter_skip

    ; --- 以下代码被跳过，永远不会执行 ---
    lea rcx, fmt_skip
    call printf

mainafter_skip:
    ; --- 打印 "After jump" ---
    lea rcx, fmt_after
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
main ENDP
END
