; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC
extern AddVectoredExceptionHandler : PROC

.data
    fmt_boot  BYTE "VEH installed, executing INT3...", 10, 0
    fmt_code  BYTE "[VEH] ExceptionCode = 0x%08lX (BREAKPOINT)", 10, 0
    fmt_rip   BYTE "[VEH] Rip on entry = 0x%016llX   <- on the 0xCC byte itself", 10, 0
    fmt_trap  BYTE "[VEH] Windows rewinds Rip onto the 0xCC byte -> must skip it", 10, 0
    fmt_alive BYTE "after INT3: execution resumed at the next instruction", 10, 0


.code

veh_handler:
    push rbx
    sub rsp, 32
    mov rbx, rcx                ; PEXCEPTION_POINTERS

    mov rdx, [rbx]              ; ExceptionRecord
    mov edx, [rdx]              ; ExceptionCode
    lea rcx, fmt_code
    call printf

    ; 打印进入处理器时的 Rip（实测指向 0CCh 字节本身）
    mov rdx, [rbx+8]            ; ContextRecord
    mov rdx, [rdx+0F8h]         ; CONTEXT.Rip
    lea rcx, fmt_rip
    call printf

    ; 跳过 1 字节的 0CCh，否则 CONTINUE_EXECUTION 会无限重触发
    mov rdx, [rbx+8]
    add QWORD PTR [rdx+0F8h], 1

    lea rcx, fmt_trap
    call printf

    add rsp, 32
    pop rbx
    mov eax, -1                 ; EXCEPTION_CONTINUE_EXECUTION
    ret

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov ecx, 1
    lea rdx, veh_handler
    call AddVectoredExceptionHandler

    lea rcx, fmt_boot
    call printf

    int 3                        ; 0CCh -> 80000003h

    lea rcx, fmt_alive
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
