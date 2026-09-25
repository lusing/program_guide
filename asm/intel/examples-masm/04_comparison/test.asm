; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    ; TEST rax, rax - 检测零
    fmt_zero  BYTE "TEST 0, 0             -> ZF=1, value is zero", 10, 0
    fmt_nz    BYTE "TEST 0x%llx, self     -> ZF=0, value is non-zero", 10, 0
    ; TEST rax, 1 - 检测奇偶
    fmt_odd   BYTE "TEST 0x%llx, 1        -> ZF=0, odd  (bit 0 = 1)", 10, 0
    fmt_even  BYTE "TEST 0x%llx, 1        -> ZF=1, even (bit 0 = 0)", 10, 0
    ; TEST rax, 80h - 检测第7位
    fmt_b7s   BYTE "TEST 0x%llx, 0x80     -> ZF=0, bit 7 is SET", 10, 0
    fmt_b7c   BYTE "TEST 0x%llx, 0x80     -> ZF=1, bit 7 is CLEAR", 10, 0
    ; NULL指针检测
    fmt_null  BYTE "TEST ptr, ptr (NULL)  -> ZF=1, pointer is NULL", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    and rsp, -16             ; 确保16字节栈对齐
    sub rsp, 32              ; shadow space

    ; --- TEST rax, rax: 检测零 (值为0) ---
    ; TEST 执行 AND 但不保存结果，只设标志位
    ; 0 AND 0 = 0 -> ZF=1
    xor rax, rax             ; rax = 0
    test rax, rax
    jnz maint1_nz
    lea rcx, fmt_zero
    call printf
    jmp maint1_done
maint1_nz:
    lea rcx, fmt_nz
    mov rdx, rax
    call printf
maint1_done:

    ; --- TEST rax, rax: 检测非零 (值为42) ---
    ; 42 AND 42 = 42 -> ZF=0
    mov rax, 42
    test rax, rax
    jnz maint2_nz
    lea rcx, fmt_zero
    call printf
    jmp maint2_done
maint2_nz:
    lea rcx, fmt_nz
    mov rdx, rax
    call printf
maint2_done:

    ; --- TEST rax, 1: 检测奇偶 (奇数) ---
    ; 7 AND 1 = 1 -> ZF=0 (奇数)
    mov rax, 7
    test rax, 1
    jz maint3_even
    lea rcx, fmt_odd
    mov rdx, rax
    call printf
    jmp maint3_done
maint3_even:
    lea rcx, fmt_even
    mov rdx, rax
    call printf
maint3_done:

    ; --- TEST rax, 1: 检测奇偶 (偶数) ---
    ; 8 AND 1 = 0 -> ZF=1 (偶数)
    mov rax, 8
    test rax, 1
    jz maint4_even
    lea rcx, fmt_odd
    mov rdx, rax
    call printf
    jmp maint4_done
maint4_even:
    lea rcx, fmt_even
    mov rdx, rax
    call printf
maint4_done:

    ; --- TEST rax, 80h: 检测第7位 (设置) ---
    ; 80h AND 80h = 80h -> ZF=0 (bit 7 = 1)
    mov rax, 80h
    test rax, 80h
    jz maint5_clear
    lea rcx, fmt_b7s
    mov rdx, rax
    call printf
    jmp maint5_done
maint5_clear:
    lea rcx, fmt_b7c
    mov rdx, rax
    call printf
maint5_done:

    ; --- TEST rax, 80h: 检测第7位 (清除) ---
    ; 7Fh AND 80h = 0 -> ZF=1 (bit 7 = 0)
    mov rax, 7Fh
    test rax, 80h
    jz maint6_clear
    lea rcx, fmt_b7s
    mov rdx, rax
    call printf
    jmp maint6_done
maint6_clear:
    lea rcx, fmt_b7c
    mov rdx, rax
    call printf
maint6_done:

    ; --- 实际应用: NULL指针检测 ---
    ; test rax, rax 是检查指针是否为NULL的标准写法
    ; 比 cmp rax, 0 更短（3字节 vs 7字节）
    xor rax, rax             ; rax = NULL (模拟空指针)
    test rax, rax
    jnz maint7_notnull
    lea rcx, fmt_null
    call printf
    jmp maint7_done
maint7_notnull:
    lea rcx, fmt_nz
    mov rdx, rax
    call printf
maint7_done:

    xor ecx, ecx             ; exit code = 0
    call ExitProcess
main ENDP
END
