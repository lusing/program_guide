; ============================================================
; push_pop_regs.asm - 多寄存器 PUSH/POP
; ============================================================
; 演示:
;   - push imm  将立即数压入栈
;   - pop r64   从栈弹出值到寄存器
;   - 栈的 LIFO (后进先出) 特性
;
; 栈操作规则:
;   PUSH 指令: RSP -= 8, [RSP] = 值
;   POP  指令: 值 = [RSP], RSP += 8
;   最后压入的值最先弹出 (LIFO)
;
; 注意: push/pop 后栈恢复对齐, printf调用安全
; ============================================================

default rel

section .data
    fmt_push   db "Pushed values: 10, 20, 30 (in push order)", 10, 0
    fmt_pop    db "  Pop %lld: %lld", 10, 0
    fmt_note   db "Stack is LIFO: last pushed (30) is first popped.", 10, 0
    fmt_done   db "PUSH/POP registers demo completed.", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32                           ; 影子空间

    ; 打印压入顺序
    lea rcx, [fmt_push]
    call printf

    ; -------------------------------------------------------
    ; 压入三个值到栈 (10, 20, 30)
    ; 栈从高地址向低地址增长:
    ;   push 10  -> [RSP]     = 10  (最先压入, 栈底)
    ;   push 20  -> [RSP]     = 20
    ;   push 30  -> [RSP]     = 30  (最后压入, 栈顶)
    ; -------------------------------------------------------
    push 10
    push 20
    push 30

    ; -------------------------------------------------------
    ; 弹出值 (LIFO 顺序: 30, 20, 10)
    ; pop 从栈顶(RSP)读取值, 然后 RSP += 8
    ; -------------------------------------------------------
    pop r12                                ; r12 = 30 (最后压入, 最先弹出)
    pop r13                                ; r13 = 20
    pop r14                                ; r14 = 10 (最先压入, 最后弹出)

    ; 打印弹出顺序 (此时栈已恢复对齐, printf安全)
    lea rcx, [fmt_pop]
    mov rdx, 1                             ; 弹出序号
    mov r8, r12                            ; 值 = 30
    call printf

    lea rcx, [fmt_pop]
    mov rdx, 2
    mov r8, r13                            ; 值 = 20
    call printf

    lea rcx, [fmt_pop]
    mov rdx, 3
    mov r8, r14                            ; 值 = 10
    call printf

    ; 打印说明
    lea rcx, [fmt_note]
    call printf

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    lea rcx, [fmt_done]
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
