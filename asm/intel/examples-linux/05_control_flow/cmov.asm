; ============================================================
; 文件: 05_control_flow/cmov.asm                           [Linux 版]
; 指令: CMOVG / CMOVL（条件移动 CMOVcc）
; 描述: 无分支（branchless）实现 min / max
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/05_control_flow/cmov.asm -o build/cmov.o
; 链接: gcc -no-pie build/cmov.o -o build/cmov
; 对照: examples/05_control_flow/cmov.asm
;
; CMOVcc dst, src：条件成立才 dst = src，否则 dst 原样不动。
; 好处是不产生跳转，不吃分支预测失败的惩罚，也天然免疫时序侧信道攻击。
; 注意两者的条件与 JG / JL 完全一致：
;   cmovg : SF=OF 且 ZF=0（有符号大于）
;   cmovl : SF≠OF（有符号小于）
; 想看无符号版本就是 cmova / cmovb。
; ============================================================
default rel

section .data
    fmt_min db "CMOVG: min(%lld, %lld) = %lld  (if a > b, a = b)", 10, 0
    fmt_max db "CMOVL: max(%lld, %lld) = %lld  (if a < b, a = b)", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], r12                 ; r12/r13 是被调用者保存寄存器
    mov [rbp-16], r13

    ; --------------------------------------------------------
    ; min(25, 10)：CMP 25,10 得 15 -> SF=0 OF=0 ZF=0
    ; CMOVG 条件「大于」成立 -> r12 = r13 = 10（留下较小者）
    ; --------------------------------------------------------
    mov r12, 25
    mov r13, 10
    cmp r12, r13
    cmovg r12, r13

    lea rdi, [fmt_min]
    mov rsi, 25                      ; a
    mov rdx, 10                      ; b
    mov rcx, r12                     ; 结果
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; max(25, 10)：同样的 CMP
    ; CMOVL 条件「小于」不成立 -> r12 保持 25（留下较大者）
    ; --------------------------------------------------------
    mov r12, 25
    mov r13, 10
    cmp r12, r13
    cmovl r12, r13

    lea rdi, [fmt_max]
    mov rsi, 25
    mov rdx, 10
    mov rcx, r12
    xor eax, eax
    call printf

    mov r12, [rbp-8]
    mov r13, [rbp-16]
    xor eax, eax
    leave
    ret
