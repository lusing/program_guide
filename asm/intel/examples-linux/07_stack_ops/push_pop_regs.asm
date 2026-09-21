; ============================================================
; 文件: 07_stack_ops/push_pop_regs.asm                     [Linux 版]
; 指令: PUSH imm / POP r64
; 描述: 栈的后进先出（LIFO）特性
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/07_stack_ops/push_pop_regs.asm -o build/push_pop_regs.o
; 链接: gcc -no-pie build/push_pop_regs.o -o build/push_pop_regs
; 对照: examples/07_stack_ops/push_pop_regs.asm
;
; ------------------------------------------------------------
; 栈规则（x86-64 栈向低地址增长）：
;   PUSH r/m64/imm  ->  RSP -= 8 ; [RSP] = 值
;   POP  r64        ->  r64 = [RSP] ; RSP += 8
; 所以最后压进去的最先弹出来 —— LIFO。
;
; 这里栈上直接 push 立即数是 64 位操作，一次占 8 字节。
; 三个 push / 三个 pop 是配对的，中间那段 RSP 临时变成
; 「≡ 8 (mod 16)」，但那段里没有 call，所以不影响对齐。
;
; ------------------------------------------------------------
; Linux 差别：
;   1. 这里的中间值放在 r12/r13/r14 —— 被调用者保存寄存器，
;      进函数先存到栈上，ret 之前必须原样还原（否则 libc 启动代码会崩）；
;   2. 参数是 rdi/rsi/rdx，不用影子空间。
; ============================================================
default rel

section .data
    fmt_push   db "压栈顺序：10, 20, 30", 10, 0
    fmt_pop    db "  第 %lld 次 pop： %lld", 10, 0
    fmt_note   db "栈是 LIFO 的：最后压进去的 30 最先弹出来。", 10, 0
    fmt_done   db "PUSH/POP registers demo completed.", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8],  r12                   ; 借 r12-r14 存弹出值，先备份原值
    mov [rbp-16], r13
    mov [rbp-24], r14

    lea rdi, [fmt_push]
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; 依次压入 10、20、30
    ;   push 10  -> [RSP]   = 10   （最先压入，落在高地址）
    ;   push 20  -> [RSP-8] = 20
    ;   push 30  -> [RSP-16]= 30   （最后压入，正好在栈顶）
    ; --------------------------------------------------------
    push 10
    push 20
    push 30

    ; --------------------------------------------------------
    ; 按 LIFO 弹出：30、20、10
    ; --------------------------------------------------------
    pop r12                             ; r12 = 30（最后压入，最先弹出）
    pop r13                             ; r13 = 20
    pop r14                             ; r14 = 10（最先压入，最后弹出）

    ; 此时 RSP 已回到原位、对齐也恢复，可以放心调 printf
    lea rdi, [fmt_pop]
    mov rsi, 1                          ; 弹出序号
    mov rdx, r12                        ; 值 = 30
    xor eax, eax
    call printf

    lea rdi, [fmt_pop]
    mov rsi, 2
    mov rdx, r13                        ; 值 = 20
    xor eax, eax
    call printf

    lea rdi, [fmt_pop]
    mov rsi, 3
    mov rdx, r14                        ; 值 = 10
    xor eax, eax
    call printf

    lea rdi, [fmt_note]
    xor eax, eax
    call printf

    lea rdi, [fmt_done]
    xor eax, eax
    call printf

    mov r12, [rbp-8]
    mov r13, [rbp-16]
    mov r14, [rbp-24]
    xor eax, eax
    leave
    ret
