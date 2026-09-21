; ============================================================
; 文件: 04_comparison/cmp.asm                              [Linux 版]
; 指令: CMP
; 描述: 比较指令 —— 做减法但不写回结果，只设标志位
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/04_comparison/cmp.asm -o build/cmp.o
; 链接: gcc -no-pie build/cmp.o -o build/cmp
; 对照: examples/04_comparison/cmp.asm
;
; CMP 是这一章的分水岭：同一对操作数，看成有符号还是无符号，
; 跳转条件完全相反 ——
;   有符号：JG / JL / JGE / JLE  看 SF 与 OF 是否相等
;   无符号：JA / JB / JAE / JBE  只看 CF 与 ZF
; 典型例子就是 -1 和 1：有符号 -1 < 1，无符号 0xFFFFFFFFFFFFFFFF > 1。
; ============================================================
default rel

section .data
    fmt_gt  db "CMP %lld, %lld -> signed:  greater (JG)", 10, 0
    fmt_lt  db "CMP %lld, %lld -> signed:  less (JL)", 10, 0
    fmt_eq  db "CMP %lld, %lld -> equal (JE)", 10, 0
    fmt_ugt db "CMP 0x%llx, 0x%llx -> unsigned: above (JA)", 10, 0
    fmt_ult db "CMP 0x%llx, 0x%llx -> unsigned: below (JB)", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rbx                 ; rbx 用来放比较的右操作数

    ; === Case 1: CMP 5, 3 -> 有符号：大于 ===
    ; 5 - 3 = 2：ZF=0, SF=0, OF=0 -> SF=OF 且 ZF=0 -> JG 跳转
    mov rax, 5
    mov rbx, 3
    cmp rax, rbx
    je .c1_eq
    jg .c1_gt
    lea rdi, [fmt_lt]
    jmp .c1_print
.c1_eq:
    lea rdi, [fmt_eq]
    jmp .c1_print
.c1_gt:
    lea rdi, [fmt_gt]
.c1_print:
    mov rsi, rax
    mov rdx, rbx
    xor eax, eax
    call printf

    ; === Case 2: CMP 3, 5 -> 有符号：小于 ===
    ; 3 - 5 = -2：ZF=0, SF=1, OF=0 -> SF≠OF -> JL 跳转
    mov rax, 3
    mov rbx, 5
    cmp rax, rbx
    je .c2_eq
    jg .c2_gt
    lea rdi, [fmt_lt]
    jmp .c2_print
.c2_eq:
    lea rdi, [fmt_eq]
    jmp .c2_print
.c2_gt:
    lea rdi, [fmt_gt]
.c2_print:
    mov rsi, rax
    mov rdx, rbx
    xor eax, eax
    call printf

    ; === Case 3: CMP 5, 5 -> 相等 ===
    ; 5 - 5 = 0：ZF=1 -> JE 跳转
    mov rax, 5
    mov rbx, 5
    cmp rax, rbx
    je .c3_eq
    jg .c3_gt
    lea rdi, [fmt_lt]
    jmp .c3_print
.c3_eq:
    lea rdi, [fmt_eq]
    jmp .c3_print
.c3_gt:
    lea rdi, [fmt_gt]
.c3_print:
    mov rsi, rax
    mov rdx, rbx
    xor eax, eax
    call printf

    ; === Case 4: CMP -1, 1 -> 有符号：小于 ===
    ; -1 - 1 = -2：SF=1, OF=0 -> SF≠OF -> JL
    mov rax, -1
    mov rbx, 1
    cmp rax, rbx
    je .c4_eq
    jg .c4_gt
    lea rdi, [fmt_lt]
    jmp .c4_print
.c4_eq:
    lea rdi, [fmt_eq]
    jmp .c4_print
.c4_gt:
    lea rdi, [fmt_gt]
.c4_print:
    mov rsi, rax
    mov rdx, rbx
    xor eax, eax
    call printf

    ; === Case 5: 同一对操作数 -1 / 1，换成无符号就是「大于」 ===
    ; -1 按无符号解释是 0xFFFFFFFFFFFFFFFF，比 1 大得多
    ; CF=0, ZF=0 -> JA 跳转
    mov rax, -1
    mov rbx, 1
    cmp rax, rbx
    ja .c5_above
    lea rdi, [fmt_ult]
    jmp .c5_print
.c5_above:
    lea rdi, [fmt_ugt]
.c5_print:
    mov rsi, rax
    mov rdx, rbx
    xor eax, eax
    call printf

    mov rbx, [rbp-8]
    xor eax, eax
    leave
    ret
