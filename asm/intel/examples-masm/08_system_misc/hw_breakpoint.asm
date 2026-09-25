; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
CTX_DBG equ 00100010h          ; CONTEXT_AMD64 | CONTEXT_DEBUG_REGISTERS
CTX_SIZE equ 4D0h              ; sizeof(CONTEXT) x64
extern printf : PROC
extern fflush : PROC
extern ExitProcess : PROC
extern AddVectoredExceptionHandler : PROC
extern GetThreadContext : PROC
extern SetThreadContext : PROC

.data
    fmt_arm  BYTE "HW execute breakpoint armed via DR0/DR7 (CONTEXT_DEBUG_REGISTERS)", 10, 0
    fmt_code BYTE "[VEH] ExceptionCode = 0x%08lX (SINGLE_STEP / #DB)", 10, 0
    fmt_hit  BYTE "[VEH] Rip == DR0 == 0x%016llX  (execute BP is a FAULT)", 10, 0
    fmt_dr   BYTE "[VEH] Dr6 = 0x%016llX (B0 set), Dr7 disabled, resuming", 10, 0
    fmt_run  BYTE "watch_here executed: EAX = 0x%lX", 10, 0
    fmt_done BYTE "done: hardware breakpoint survived without int3", 10, 0


.code

veh_handler:
    push rbx
    sub rsp, 32
    mov rbx, rcx                ; PEXCEPTION_POINTERS

    mov rdx, [rbx]
    mov edx, [rdx]              ; ExceptionCode
    lea rcx, fmt_code
    call printf

    ; Rip 应等于 Dr0：执行断点是 fault（触发在执行前）
    mov rdx, [rbx+8]            ; ContextRecord（就是线程上下文）
    mov r8, [rdx+0F8h]          ; Rip
    lea rcx, fmt_hit
    call printf

    ; Dr6 的 B0 位指示槽 0 命中；读出后把 Dr7 清零关闭断点
    mov rdx, [rbx+8]
    mov rdx, [rdx+68h]         ; Dr6（第 2 变参走 rdx）
    lea rcx, fmt_dr
    call printf

    mov rdx, [rbx+8]
    mov QWORD PTR [rdx+70h], 0     ; Dr7 = 0：关闭所有硬件断点
    mov QWORD PTR [rdx+68h], 0     ; Dr6 清零（写 0 即可，恢复现场）

    xor ecx, ecx
    call fflush
    add rsp, 32
    pop rbx
    mov eax, -1                 ; EXCEPTION_CONTINUE_EXECUTION
    ret                         ; 指令重执行，这次不再触发

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, (CTX_SIZE + 64 + 15)  AND   NOT 15       ; CONTEXT + 调用区，16 对齐

    ; ---- 安装 VEH ----
    mov ecx, 1
    lea rdx, veh_handler
    call AddVectoredExceptionHandler

    ; ---- 取当前线程上下文（伪句柄 -2 = GetCurrentThread()）----
    mov rcx, -2
    lea rdx, [rbp - CTX_SIZE]
    mov DWORD PTR [rdx+30h], CTX_DBG   ; ContextFlags（+30h）
    call GetThreadContext

    ; ---- Dr0 = 目标指令地址；Dr7 = L0 使能（RW=00 执行，LEN=00）----
    lea rax, watch_here
    mov [rbp - CTX_SIZE + 48h], rax    ; Dr0
    mov QWORD PTR [rbp - CTX_SIZE + 70h], 1 ; Dr7 = L0(bit0)
    mov rcx, -2
    lea rdx, [rbp - CTX_SIZE]
    call SetThreadContext

    lea rcx, fmt_arm
    call printf

    ; ---- 走几步无关代码，然后命中断点 ----
    xor r12d, r12d
mainfiller:
    inc r12d
    cmp r12d, 3
    jb mainfiller

watch_here:                     ; <- DR0 指向这里（执行断点）
    mov eax, 1234h             ; #DB 在这条 mov 执行前触发

    lea rcx, fmt_run
    mov edx, eax
    call printf
    lea rcx, fmt_done
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
