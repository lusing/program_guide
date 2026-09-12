; ============================================================
; 文件: 04_comparison/cmp.asm
; 指令: CMP
; 描述: 比较指令演示（执行减法但不保存结果，只设置标志位）
; 编译: nasm -f win64 cmp.asm -o cmp.obj
; 链接: link /subsystem:console /entry:main cmp.obj ucrt.lib kernel32.lib legacy_stdio_definitions.lib
; ============================================================
default rel

section .data
    ; 有符号比较结果
    fmt_gt   db "CMP %lld, %lld -> signed:  greater (JG)", 10, 0
    fmt_lt   db "CMP %lld, %lld -> signed:  less (JL)", 10, 0
    fmt_eq   db "CMP %lld, %lld -> equal (JE)", 10, 0
    ; 无符号比较结果
    fmt_ugt  db "CMP 0x%llx, 0x%llx -> unsigned: above (JA)", 10, 0
    fmt_ult  db "CMP 0x%llx, 0x%llx -> unsigned: below (JB)", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    and rsp, -16             ; 确保16字节栈对齐
    sub rsp, 32              ; shadow space

    ; === Case 1: CMP 5, 3 -> 有符号: 大于 ===
    ; 5 - 3 = 2: ZF=0, SF=0, OF=0 -> SF=OF 且 ZF=0 -> JG 跳转
    mov rax, 5
    mov rbx, 3
    cmp rax, rbx
    je .c1_eq
    jg .c1_gt
    lea rcx, [fmt_lt]
    jmp .c1_print
.c1_eq:
    lea rcx, [fmt_eq]
    jmp .c1_print
.c1_gt:
    lea rcx, [fmt_gt]
.c1_print:
    mov rdx, rax
    mov r8, rbx
    call printf

    ; === Case 2: CMP 3, 5 -> 有符号: 小于 ===
    ; 3 - 5 = -2: ZF=0, SF=1, OF=0 -> SF≠OF -> JL 跳转
    mov rax, 3
    mov rbx, 5
    cmp rax, rbx
    je .c2_eq
    jg .c2_gt
    lea rcx, [fmt_lt]
    jmp .c2_print
.c2_eq:
    lea rcx, [fmt_eq]
    jmp .c2_print
.c2_gt:
    lea rcx, [fmt_gt]
.c2_print:
    mov rdx, rax
    mov r8, rbx
    call printf

    ; === Case 3: CMP 5, 5 -> 相等 ===
    ; 5 - 5 = 0: ZF=1 -> JE 跳转
    mov rax, 5
    mov rbx, 5
    cmp rax, rbx
    je .c3_eq
    jg .c3_gt
    lea rcx, [fmt_lt]
    jmp .c3_print
.c3_eq:
    lea rcx, [fmt_eq]
    jmp .c3_print
.c3_gt:
    lea rcx, [fmt_gt]
.c3_print:
    mov rdx, rax
    mov r8, rbx
    call printf

    ; === Case 4: CMP -1, 1 -> 有符号: 小于 ===
    ; -1 - 1 = -2: ZF=0, SF=1, OF=0 -> SF≠OF -> JL 跳转
    mov rax, -1
    mov rbx, 1
    cmp rax, rbx
    je .c4_eq
    jg .c4_gt
    lea rcx, [fmt_lt]
    jmp .c4_print
.c4_eq:
    lea rcx, [fmt_eq]
    jmp .c4_print
.c4_gt:
    lea rcx, [fmt_gt]
.c4_print:
    mov rdx, rax
    mov r8, rbx
    call printf

    ; === Case 5: CMP -1, 1 -> 无符号: 大于 ===
    ; -1 的无符号值 = 0xFFFFFFFFFFFFFFFF（巨大正数）> 1
    ; CF=0, ZF=0 -> JA 跳转
    ; 这与有符号结果相反，是 CMP 的关键区别
    mov rax, -1
    mov rbx, 1
    cmp rax, rbx
    ja .c5_above
    lea rcx, [fmt_ult]
    jmp .c5_print
.c5_above:
    lea rcx, [fmt_ugt]
.c5_print:
    mov rdx, rax
    mov r8, rbx
    call printf

    xor ecx, ecx             ; exit code = 0
    call ExitProcess
