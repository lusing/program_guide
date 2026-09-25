; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt_set    BYTE "1. Set flags: 0xFF + 1 = 0x100 (8-bit overflow, wraps to 0)", 10, 0
    fmt_saved  BYTE "   Saved flags (pushfq): CF=%lld, ZF=%lld, SF=%lld, OF=%lld", 10, 0
    fmt_chg    BYTE "2. Changed flags: 1 + 1 = 2 (no overflow)", 10, 0
    fmt_curr   BYTE "   Current flags: CF=%lld, ZF=%lld, SF=%lld, OF=%lld", 10, 0
    fmt_rst    BYTE "3. Restored flags via popfq:", 10, 0
    fmt_rstd   BYTE "   Restored flags: CF=%lld, ZF=%lld, SF=%lld, OF=%lld", 10, 0
    fmt_match  BYTE "   -> Restoration successful! (matches saved flags)", 10, 0
    fmt_done   BYTE "PUSHF/POPF demo completed.", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 48                           ; 32影子 + 8第5参数 + 8对齐 = 48

    ; -------------------------------------------------------
    ; 1. 设置标志位: 0FFh + 1 (8位溢出)
    ; 结果: AL=00h, CF=1, ZF=1, SF=0, OF=0
    ; -------------------------------------------------------
    mov al, 0FFh
    add al, 1                             ; 0FFh + 1 = 100h -> AL=00h, CF=1, ZF=1

    ; pushfq 保存 RFLAGS 到栈, 然后弹出到 r12 (push/pop 平衡, 栈对齐不变)
    pushfq
    pop r12                               ; r12 = saved RFLAGS

    ; 打印设置说明
    lea rcx, fmt_set
    call printf

    ; 打印保存的标志位 (从 r12 提取)
    ; CF=bit0, ZF=bit6, SF=bit7, OF=bit11
    mov rax, r12
    and rax, 1                            ; CF
    mov rdx, rax
    mov rax, r12
    shr rax, 6
    and rax, 1                            ; ZF
    mov r8, rax
    mov rax, r12
    shr rax, 7
    and rax, 1                            ; SF
    mov r9, rax
    mov rax, r12
    shr rax, 11
    and rax, 1                            ; OF
    mov [rsp+32], rax                     ; 第5参数
    lea rcx, fmt_saved
    call printf

    ; -------------------------------------------------------
    ; 2. 改变标志位: 1 + 1 (无溢出)
    ; 结果: AL=2, CF=0, ZF=0, SF=0, OF=0
    ; -------------------------------------------------------
    mov al, 1
    add al, 1                             ; 1 + 1 = 2, CF=0, ZF=0

    ; 读取当前 RFLAGS (pushfq + pop 平衡, 栈对齐不变)
    pushfq
    pop r13                               ; r13 = current RFLAGS

    ; 打印改变说明
    lea rcx, fmt_chg
    call printf

    ; 打印当前标志位 (从 r13 提取)
    mov rax, r13
    and rax, 1
    mov rdx, rax
    mov rax, r13
    shr rax, 6
    and rax, 1
    mov r8, rax
    mov rax, r13
    shr rax, 7
    and rax, 1
    mov r9, rax
    mov rax, r13
    shr rax, 11
    and rax, 1
    mov [rsp+32], rax
    lea rcx, fmt_curr
    call printf

    ; -------------------------------------------------------
    ; 3. 恢复标志位: push r12 + popfq 从栈恢复
    ; 将 r12 中保存的 RFLAGS 压入栈, 再用 popfq 恢复
    ; -------------------------------------------------------
    push r12                              ; 将保存的 RFLAGS 压入栈
    popfq                                 ; popfq 恢复 RFLAGS (栈平衡)

    ; 读取恢复后的 RFLAGS (pushfq + pop 平衡)
    pushfq
    pop r14                               ; r14 = restored RFLAGS

    ; 打印恢复说明
    lea rcx, fmt_rst
    call printf

    ; 打印恢复后的标志位 (从 r14 提取)
    mov rax, r14
    and rax, 1
    mov rdx, rax
    mov rax, r14
    shr rax, 6
    and rax, 1
    mov r8, rax
    mov rax, r14
    shr rax, 7
    and rax, 1
    mov r9, rax
    mov rax, r14
    shr rax, 11
    and rax, 1
    mov [rsp+32], rax
    lea rcx, fmt_rstd
    call printf

    ; 打印匹配确认
    lea rcx, fmt_match
    call printf

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    lea rcx, fmt_done
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
main ENDP
END
