; ============================================================
; seh_div_zero.asm - 用 VEH 捕获除零异常（Windows x64）
; ============================================================
; 演示（不写一行 C 代码的"结构化异常处理"）：
;   - AddVectoredExceptionHandler 注册向量化处理器（VEH）
;     原型：PVOID AddVectoredExceptionHandler(ULONG First, PVEH_HANDLER)
;   - 处理器参数 RCX = PEXCEPTION_POINTERS：
;       [RCX+0]  = PEXCEPTION_RECORD（+0 是 ExceptionCode）
;       [RCX+8]  = PCONTEXT（+0xF8 是 Rip）
;   - IDIV 除零触发 0xC0000094（EXCEPTION_INT_DIVIDE_BY_ZERO）
;     ——fault 型异常：CONTEXT.Rip 指向出错指令本身，
;     直接返回 CONTINUE_EXECUTION 会死循环；
;     处理器里把 Rip += 指令长度，"跳过"出错指令后继续。
;
; 预期输出:
;   VEH installed, triggering idiv by zero...
;   [VEH] ExceptionCode = 0xC0000094 (INT_DIVIDE_BY_ZERO)
;   [VEH] faulting Rip skipped, execution continues
;   back in main: survived without a crash!
; ============================================================

default rel

section .data
    fmt_boot  db "VEH installed, triggering idiv by zero...", 10, 0
    fmt_code  db "[VEH] ExceptionCode = 0x%08lX (INT_DIVIDE_BY_ZERO)", 10, 0
    fmt_skip  db "[VEH] faulting Rip skipped, execution continues", 10, 0
    fmt_alive db "back in main: survived without a crash!", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess
    extern AddVectoredExceptionHandler

; ------------------------------------------------------------
; VEH 处理器：RCX = PEXCEPTION_POINTERS，返回 LONG
;   返回 -1 (EXCEPTION_CONTINUE_EXECUTION)：用（可修改的）CONTEXT 继续
;   返回  0 (EXCEPTION_CONTINUE_SEARCH)：交给下一个处理器
; 注意：此处用 volatile 寄存器即可，VEH 调用遵循 Win64 约定
; ------------------------------------------------------------
veh_handler:
    push rbx
    sub rsp, 32                 ; 影子空间（内部 call printf 需要）
    mov rbx, rcx                ; 保存 PEXCEPTION_POINTERS（printf 会破坏 rcx）

    mov rdx, [rbx]              ; ExceptionRecord
    mov edx, [rdx]              ; ExceptionCode（低 32 位）
    lea rcx, [fmt_code]
    call printf

    ; 把 CONTEXT.Rip 前移 2 字节，跳过 2 字节的 idiv ecx (F7 F9)
    mov rdx, [rbx+8]            ; ContextRecord
    add qword [rdx+0xF8], 2     ; CONTEXT.Rip

    lea rcx, [fmt_skip]
    call printf

    add rsp, 32
    pop rbx
    mov eax, -1                 ; EXCEPTION_CONTINUE_EXECUTION
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 安装 VEH：AddVectoredExceptionHandler(1, veh_handler)
    mov ecx, 1
    lea rdx, [veh_handler]
    call AddVectoredExceptionHandler
    ; 返回值 rax = 句柄（1 = 首位）；这里不检查，直接演示

    lea rcx, [fmt_boot]
    call printf

    ; ---- 触发除零：idiv ecx，其中 ecx = 0 ----
    mov eax, 1                  ; 被除数低 32 位
    xor edx, edx                ; 高 32 位清零（有符号除法要求）
    xor ecx, ecx                ; 除数 = 0
    db 0xF7, 0xF9               ; idiv ecx（2 字节）-> 0xC0000094
    ; VEH 返回后从这里继续（Rip 已被 +2）

    lea rcx, [fmt_alive]
    call printf

    xor ecx, ecx
    call ExitProcess
