; ============================================================
; seh_null_write.asm - 捕获空指针写入，并在处理器里"修好"它
; ============================================================
; 对地址 0 写入触发 0xC0000005（EXCEPTION_ACCESS_VIOLATION）。
; 这是 fault 型异常：CONTEXT.Rip 指向出错指令本身。
; 与 seh_div_zero 的"跳过"不同，这次展示更强的操作——
; 直接改写 CONTEXT 里的寄存器：
;   把 RAX（坏指针）换成有效缓冲区地址，返回 CONTINUE_EXECUTION
; 后处理器会在同一条指令上重试，这次写入成功。
; ExceptionRecord+0x20 起是 ExceptionInformation[]：
;   [0]=8 读/写（0=读 1=写），[1]=8 访问的目标地址（这里是 0）
;
; 预期输出:
;   VEH installed, writing to address 0...
;   [VEH] ExceptionCode = 0xC0000005 (ACCESS_VIOLATION)
;   [VEH] Context.Rax patched to a valid buffer, retrying
;   back in main: the store retried and landed in the buffer = 0x5A5A5A5A
; ============================================================

default rel

section .data
    fmt_boot  db "VEH installed, writing to address 0...", 10, 0
    fmt_code  db "[VEH] ExceptionCode = 0x%08lX (ACCESS_VIOLATION)", 10, 0
    fmt_info  db "[VEH] op=%s target=0x%016llX", 10, 0
    fmt_patch db "[VEH] Context.Rax patched to a valid buffer, retrying", 10, 0
    fmt_alive db "back in main: the store retried and landed in the buffer = 0x%08lX", 10, 0

    op_read  db "read ", 0
    op_write db "write", 0

section .bss
    save_buf resd 1             ; 处理器里改道写入的目标

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

    ; 改写 CONTEXT.Rax 为有效缓冲区地址 -> 重试同一条指令
    mov rdx, [rbx+8]            ; ContextRecord
    lea rax, [save_buf]
    mov [rdx+0x78], rax         ; CONTEXT.Rax
    ; Rip 保持不动：CONTINUE_EXECUTION 会在原指令上重试

    lea rcx, [fmt_patch]
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

    ; ---- 触发：向地址 0 写入 ----
    xor eax, eax                ; RAX = 0（坏指针）
    db 0xC7, 0x00, 0x5A, 0x5A, 0x5A, 0x5A   ; mov dword [rax], 0x5A5A5A5A
    ; 处理器把 RAX 换成 save_buf 后，这条 6 字节指令重试成功

    ; 验证：读回缓冲区（写入的只是低字节 0x5A，先清零缓冲区保证确定）
    lea rcx, [fmt_alive]
    mov edx, [save_buf]
    call printf

    xor ecx, ecx
    call ExitProcess
