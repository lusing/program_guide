; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC
extern AddVectoredExceptionHandler : PROC

.data
    fmt_boot  BYTE "VEH installed, writing to address 0...", 10, 0
    fmt_code  BYTE "[VEH] ExceptionCode = 0x%08lX (ACCESS_VIOLATION)", 10, 0
    fmt_info  BYTE "[VEH] op=%s target=0x%016llX", 10, 0
    fmt_patch BYTE "[VEH] Context.Rax patched to a valid buffer, retrying", 10, 0
    fmt_alive BYTE "back in main: the store retried and landed in the buffer = 0x%08lX", 10, 0

    op_read  BYTE "read ", 0
    op_write BYTE "write", 0


.data?
    save_buf DWORD 1 DUP(?); 处理器里改道写入的目标


.code

veh_handler:
    push rbx
    sub rsp, 32
    mov rbx, rcx                ; PEXCEPTION_POINTERS

    mov rdx, [rbx]              ; ExceptionRecord
    mov edx, [rdx]              ; ExceptionCode
    lea rcx, fmt_code
    call printf

    ; 改写 CONTEXT.Rax 为有效缓冲区地址 -> 重试同一条指令
    mov rdx, [rbx+8]            ; ContextRecord
    lea rax, save_buf
    mov [rdx+78h], rax         ; CONTEXT.Rax
    ; Rip 保持不动：CONTINUE_EXECUTION 会在原指令上重试

    lea rcx, fmt_patch
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

    ; ---- 触发：向地址 0 写入 ----
    xor eax, eax                ; RAX = 0（坏指针）
    db 0C7h, 00h, 5Ah, 5Ah, 5Ah, 5Ah   ; mov DWORD PTR [rax], 5A5A5A5Ah
    ; 处理器把 RAX 换成 save_buf 后，这条 6 字节指令重试成功

    ; 验证：读回缓冲区（写入的只是低字节 5Ah，先清零缓冲区保证确定）
    lea rcx, fmt_alive
    mov edx, DWORD PTR [save_buf]
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
