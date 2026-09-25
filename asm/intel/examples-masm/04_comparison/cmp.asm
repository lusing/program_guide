; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    ; 有符号比较结果
    fmt_gt   BYTE "CMP %lld, %lld -> signed:  greater (JG)", 10, 0
    fmt_lt   BYTE "CMP %lld, %lld -> signed:  less (JL)", 10, 0
    fmt_eq   BYTE "CMP %lld, %lld -> equal (JE)", 10, 0
    ; 无符号比较结果
    fmt_ugt  BYTE "CMP 0x%llx, 0x%llx -> unsigned: above (JA)", 10, 0
    fmt_ult  BYTE "CMP 0x%llx, 0x%llx -> unsigned: below (JB)", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    and rsp, -16             ; 确保16字节栈对齐
    sub rsp, 32              ; shadow space

    ; === Case 1: CMP 5, 3 -> 有符号: 大于 ===
    ; 5 - 3 = 2: ZF=0, SF=0, OF=0 -> SF=OF 且 ZF=0 -> JG 跳转
    mov rax, 5
    mov rbx, 3
    cmp rax, rbx
    je mainc1_eq
    jg mainc1_gt
    lea rcx, fmt_lt
    jmp mainc1_print
mainc1_eq:
    lea rcx, fmt_eq
    jmp mainc1_print
mainc1_gt:
    lea rcx, fmt_gt
mainc1_print:
    mov rdx, rax
    mov r8, rbx
    call printf

    ; === Case 2: CMP 3, 5 -> 有符号: 小于 ===
    ; 3 - 5 = -2: ZF=0, SF=1, OF=0 -> SF≠OF -> JL 跳转
    mov rax, 3
    mov rbx, 5
    cmp rax, rbx
    je mainc2_eq
    jg mainc2_gt
    lea rcx, fmt_lt
    jmp mainc2_print
mainc2_eq:
    lea rcx, fmt_eq
    jmp mainc2_print
mainc2_gt:
    lea rcx, fmt_gt
mainc2_print:
    mov rdx, rax
    mov r8, rbx
    call printf

    ; === Case 3: CMP 5, 5 -> 相等 ===
    ; 5 - 5 = 0: ZF=1 -> JE 跳转
    mov rax, 5
    mov rbx, 5
    cmp rax, rbx
    je mainc3_eq
    jg mainc3_gt
    lea rcx, fmt_lt
    jmp mainc3_print
mainc3_eq:
    lea rcx, fmt_eq
    jmp mainc3_print
mainc3_gt:
    lea rcx, fmt_gt
mainc3_print:
    mov rdx, rax
    mov r8, rbx
    call printf

    ; === Case 4: CMP -1, 1 -> 有符号: 小于 ===
    ; -1 - 1 = -2: ZF=0, SF=1, OF=0 -> SF≠OF -> JL 跳转
    mov rax, -1
    mov rbx, 1
    cmp rax, rbx
    je mainc4_eq
    jg mainc4_gt
    lea rcx, fmt_lt
    jmp mainc4_print
mainc4_eq:
    lea rcx, fmt_eq
    jmp mainc4_print
mainc4_gt:
    lea rcx, fmt_gt
mainc4_print:
    mov rdx, rax
    mov r8, rbx
    call printf

    ; === Case 5: CMP -1, 1 -> 无符号: 大于 ===
    ; -1 的无符号值 = 0FFFFFFFFFFFFFFFFh（巨大正数）> 1
    ; CF=0, ZF=0 -> JA 跳转
    ; 这与有符号结果相反，是 CMP 的关键区别
    mov rax, -1
    mov rbx, 1
    cmp rax, rbx
    ja mainc5_above
    lea rcx, fmt_ult
    jmp mainc5_print
mainc5_above:
    lea rcx, fmt_ugt
mainc5_print:
    mov rdx, rax
    mov r8, rbx
    call printf

    xor ecx, ecx             ; exit code = 0
    call ExitProcess
main ENDP
END
