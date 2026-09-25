; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt_je     BYTE "JE:  5 == 5  -> Equal (JE taken)", 10, 0
    fmt_jne    BYTE "JNE: 5 != 3  -> Not equal (JNE taken)", 10, 0
    fmt_match  BYTE "If-else: 42 == 42 -> Match", 10, 0
    fmt_nomatch BYTE "If-else: 42 == 42 -> No match", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32              ; shadow space

    ; -------------------------------------------------------
    ; 演示 JE: 比较两个相等的值
    ; CMP 执行 RAX - RDX 的减法运算，只设置标志位不存结果
    ; 5 - 5 = 0 -> ZF=1（零标志），JE 在 ZF=1 时跳转
    ; -------------------------------------------------------
    mov rax, 5
    mov rdx, 5
    cmp rax, rdx             ; 5 == 5, 设置 ZF=1
    je mainequal_taken          ; JE: ZF=1时跳转（相等跳转）
    ; ZF=1 时不会执行到这里
    jmp mainafter_je
mainequal_taken:
    lea rcx, fmt_je
    call printf
mainafter_je:

    ; -------------------------------------------------------
    ; 演示 JNE: 比较两个不相等的值
    ; 5 - 3 = 2 -> ZF=0（非零），JNE 在 ZF=0 时跳转
    ; -------------------------------------------------------
    mov rax, 5
    mov rdx, 3
    cmp rax, rdx             ; 5 != 3, 设置 ZF=0
    jne mainnotequal_taken     ; JNE: ZF=0时跳转（不等跳转）
    ; ZF=0 时不会执行到这里
    jmp mainafter_jne
mainnotequal_taken:
    lea rcx, fmt_jne
    call printf
mainafter_jne:

    ; -------------------------------------------------------
    ; 演示 if-else 逻辑
    ; 场景: 检查 value 是否等于 target
    ;   if (value == target) { 打印 Match }
    ;   else                 { 打印 No match }
    ; -------------------------------------------------------
    mov rax, 42              ; value
    mov rdx, 42              ; target
    cmp rax, rdx
    je mainif_match            ; 相等则跳转到 match 分支

    ; --- else 分支 (不匹配) ---
    lea rcx, fmt_nomatch
    call printf
    jmp mainafter_ifelse        ; 跳过 match 分支

mainif_match:
    ; --- if 分支 (匹配) ---
    lea rcx, fmt_match
    call printf

mainafter_ifelse:

    ; --- 退出进程 ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
main ENDP
END
