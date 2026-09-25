; ============================================================
; hw_breakpoint.asm - 调试寄存器 DR0/DR7：硬件执行断点
; ============================================================
; x86 有 8 个调试寄存器（DR0-DR7），x64dbg/WindDbg 的「硬件断点」
; 就是它们——不修改代码字节（对比软件断点把指令换成 0xCC）：
;   DR0-DR3  断点线性地址（4 个槽）
;   DR6      触发时的状态（B0-B3 哪个槽命中）
;   DR7      使能/条件：每槽有 L/G（局部/全局使能）、RW（条件）、LEN
; 执行断点的字段组合：RW=00（执行）、LEN=00（长度 1）。
; 本例对一条指令地址设 DR0 执行断点（#DB，VEH 收到 0x80000004），
; 处理器里读出 Dr6/Dr7/Rip，再关闭断点恢复执行。
;
; API：GetCurrentThread() 的伪句柄恒为 (HANDLE)-2，直接传 -2；
;      Get/SetThreadContext 携带 CONTEXT_DEBUG_REGISTERS(0x00100010)。
; x64 CONTEXT 关键偏移：Dr0=+0x48  Dr6=+0x68  Dr7=+0x70  Rip=+0xF8。
;
; 预期输出:
;   HW execute breakpoint armed via DR0/DR7 (CONTEXT_DEBUG_REGISTERS)
;   [VEH] ExceptionCode = 0x80000004 (SINGLE_STEP / #DB)
;   [VEH] Rip == DR0 == 0x00007FFxxxxxxxxx  (execute BP is a FAULT)
;   [VEH] Dr6 = 0xFFFF0FF1 (B0 set), Dr7 disabled, resuming
;   watch_here executed: EAX = 0x1234
;   done: hardware breakpoint survived without int3
; ============================================================

default rel

CTX_DBG equ 0x00100010          ; CONTEXT_AMD64 | CONTEXT_DEBUG_REGISTERS
CTX_SIZE equ 0x4D0              ; sizeof(CONTEXT) x64

section .data
    fmt_arm  db "HW execute breakpoint armed via DR0/DR7 (CONTEXT_DEBUG_REGISTERS)", 10, 0
    fmt_code db "[VEH] ExceptionCode = 0x%08lX (SINGLE_STEP / #DB)", 10, 0
    fmt_hit  db "[VEH] Rip == DR0 == 0x%016llX  (execute BP is a FAULT)", 10, 0
    fmt_dr   db "[VEH] Dr6 = 0x%016llX (B0 set), Dr7 disabled, resuming", 10, 0
    fmt_run  db "watch_here executed: EAX = 0x%lX", 10, 0
    fmt_done db "done: hardware breakpoint survived without int3", 10, 0

section .text
    global main
    extern printf
    extern fflush
    extern ExitProcess
    extern AddVectoredExceptionHandler
    extern GetThreadContext
    extern SetThreadContext

veh_handler:
    push rbx
    sub rsp, 32
    mov rbx, rcx                ; PEXCEPTION_POINTERS

    mov rdx, [rbx]
    mov edx, [rdx]              ; ExceptionCode
    lea rcx, [fmt_code]
    call printf

    ; Rip 应等于 Dr0：执行断点是 fault（触发在执行前）
    mov rdx, [rbx+8]            ; ContextRecord（就是线程上下文）
    mov r8, [rdx+0xF8]          ; Rip
    lea rcx, [fmt_hit]
    call printf

    ; Dr6 的 B0 位指示槽 0 命中；读出后把 Dr7 清零关闭断点
    mov rdx, [rbx+8]
    mov rdx, [rdx+0x68]         ; Dr6（第 2 变参走 rdx）
    lea rcx, [fmt_dr]
    call printf

    mov rdx, [rbx+8]
    mov qword [rdx+0x70], 0     ; Dr7 = 0：关闭所有硬件断点
    mov qword [rdx+0x68], 0     ; Dr6 清零（写 0 即可，恢复现场）

    xor ecx, ecx
    call fflush
    add rsp, 32
    pop rbx
    mov eax, -1                 ; EXCEPTION_CONTINUE_EXECUTION
    ret                         ; 指令重执行，这次不再触发

main:
    push rbp
    mov rbp, rsp
    sub rsp, (CTX_SIZE + 64 + 15) & ~15       ; CONTEXT + 调用区，16 对齐

    ; ---- 安装 VEH ----
    mov ecx, 1
    lea rdx, [veh_handler]
    call AddVectoredExceptionHandler

    ; ---- 取当前线程上下文（伪句柄 -2 = GetCurrentThread()）----
    mov rcx, -2
    lea rdx, [rbp - CTX_SIZE]
    mov dword [rdx+0x30], CTX_DBG   ; ContextFlags（+0x30）
    call GetThreadContext

    ; ---- Dr0 = 目标指令地址；Dr7 = L0 使能（RW=00 执行，LEN=00）----
    lea rax, [watch_here]
    mov [rbp - CTX_SIZE + 0x48], rax    ; Dr0
    mov qword [rbp - CTX_SIZE + 0x70], 1 ; Dr7 = L0(bit0)
    mov rcx, -2
    lea rdx, [rbp - CTX_SIZE]
    call SetThreadContext

    lea rcx, [fmt_arm]
    call printf

    ; ---- 走几步无关代码，然后命中断点 ----
    xor r12d, r12d
.filler:
    inc r12d
    cmp r12d, 3
    jb .filler

watch_here:                     ; <- DR0 指向这里（执行断点）
    mov eax, 0x1234             ; #DB 在这条 mov 执行前触发

    lea rcx, [fmt_run]
    mov edx, eax
    call printf
    lea rcx, [fmt_done]
    call printf

    xor ecx, ecx
    call ExitProcess
