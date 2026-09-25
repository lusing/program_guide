; ============================================================
; seh_int3.asm - 用 VEH 捕获断点异常（INT 3）
; ============================================================
; INT 3（0xCC）触发 0x80000003（EXCEPTION_BREAKPOINT）。
; 实测坑（本机 Windows 11 / MSVC 14.52 验证）：
;   CPU 本身是 trap 语义（Rip 应指向 0xCC 之后），但 Windows 的
;   异常分发会把 Rip 回拨到 0xCC 字节上——直接返回
;   CONTINUE_EXECUTION 会在同一条 INT 3 上无限重触发。
;   处理器必须把 Rip 前移 1 字节跳过 0xCC（调试器同理，
;   还要先还原被改成 0xCC 的原字节）。
;
; 预期输出:
;   VEH installed, executing INT3...
;   [VEH] ExceptionCode = 0x80000003 (BREAKPOINT)
;   [VEH] Rip on entry = 0x00007FF6xxxxxxxx   <- 指向 0xCC 本身
;   [VEH] Windows rewinds Rip onto the 0xCC byte -> must skip it
;   after INT3: execution resumed at the next instruction
; ============================================================

default rel

section .data
    fmt_boot  db "VEH installed, executing INT3...", 10, 0
    fmt_code  db "[VEH] ExceptionCode = 0x%08lX (BREAKPOINT)", 10, 0
    fmt_rip   db "[VEH] Rip on entry = 0x%016llX   <- on the 0xCC byte itself", 10, 0
    fmt_trap  db "[VEH] Windows rewinds Rip onto the 0xCC byte -> must skip it", 10, 0
    fmt_alive db "after INT3: execution resumed at the next instruction", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess
    extern AddVectoredExceptionHandler

veh_handler:
    push rbx
    sub rsp, 32
    mov rbx, rcx                ; PEXCEPTION_POINTERS

    mov rdx, [rbx]              ; ExceptionRecord
    mov edx, [rdx]              ; ExceptionCode
    lea rcx, [fmt_code]
    call printf

    ; 打印进入处理器时的 Rip（实测指向 0xCC 字节本身）
    mov rdx, [rbx+8]            ; ContextRecord
    mov rdx, [rdx+0xF8]         ; CONTEXT.Rip
    lea rcx, [fmt_rip]
    call printf

    ; 跳过 1 字节的 0xCC，否则 CONTINUE_EXECUTION 会无限重触发
    mov rdx, [rbx+8]
    add qword [rdx+0xF8], 1

    lea rcx, [fmt_trap]
    call printf

    add rsp, 32
    pop rbx
    mov eax, -1                 ; EXCEPTION_CONTINUE_EXECUTION
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov ecx, 1
    lea rdx, [veh_handler]
    call AddVectoredExceptionHandler

    lea rcx, [fmt_boot]
    call printf

    int3                        ; 0xCC -> 0x80000003

    lea rcx, [fmt_alive]
    call printf

    xor ecx, ecx
    call ExitProcess
