; ============================================================
; 文件: 05_control_flow/jg_jl_signed.asm                   [Linux 版]
; 指令: JG / JGE / JL / JLE（有符号条件跳转）
; 描述: 有符号比较跳转，用正负数对比
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/05_control_flow/jg_jl_signed.asm -o build/jg_jl_signed.o
; 链接: gcc -no-pie build/jg_jl_signed.o -o build/jg_jl_signed
; 对照: examples/05_control_flow/jg_jl_signed.asm
;
; 有符号跳转只看 SF 和 OF 这两个标志：
;   JG  (Greater)   : SF = OF 且 ZF = 0
;   JGE (Greater=)  : SF = OF
;   JL  (Less)      : SF ≠ OF
;   JLE (Less=)     : SF ≠ OF 或 ZF = 1
; 记法：比较就是「做减法」，结果的符号位（SF）告诉你大小，
; 但如果减法本身溢出了（OF=1），符号位就是反的 —— 所以要 XOR 一下。
; 预期输出：四行都以 (taken) 结尾。
; ============================================================
default rel

section .data
    fmt_jg  db "JG:  5 > 3   -> Greater (JG taken)", 10, 0
    fmt_jl  db "JL: -1 < 1   -> Less (JL taken)", 10, 0
    fmt_jge db "JGE: 3 >= 3  -> Greater or equal (JGE taken)", 10, 0
    fmt_jle db "JLE: 3 <= 3  -> Less or equal (JLE taken)", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp

    ; --- JG：5 - 3 = 2，SF=0 OF=0 ZF=0 -> SF=OF 且 ZF=0 -> 跳 ---
    mov rax, 5
    mov rdx, 3
    cmp rax, rdx
    jg .jg_taken
    jmp .after_jg
.jg_taken:
    lea rdi, [fmt_jg]
    xor eax, eax
    call printf
.after_jg:

    ; --- JL：-1 - 1 = -2，SF=1 OF=0 ZF=0 -> SF≠OF -> 跳 ---
    mov rax, -1                      ; = 0xFFFFFFFFFFFFFFFF
    mov rdx, 1
    cmp rax, rdx
    jl .jl_taken
    jmp .after_jl
.jl_taken:
    lea rdi, [fmt_jl]
    xor eax, eax
    call printf
.after_jl:

    ; --- JGE：3 - 3 = 0，SF=0 OF=0 ZF=1 -> SF=OF -> 跳 ---
    mov rax, 3
    mov rdx, 3
    cmp rax, rdx
    jge .jge_taken
    jmp .after_jge
.jge_taken:
    lea rdi, [fmt_jge]
    xor eax, eax
    call printf
.after_jge:

    ; --- JLE：同样 3 - 3 = 0，ZF=1 就够了 -> 跳 ---
    mov rax, 3
    mov rdx, 3
    cmp rax, rdx
    jle .jle_taken
    jmp .after_jle
.jle_taken:
    lea rdi, [fmt_jle]
    xor eax, eax
    call printf
.after_jle:

    xor eax, eax
    leave
    ret
