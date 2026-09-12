; ============================================================
; 文件: 04_comparison/test.asm
; 指令: TEST
; 描述: 按位测试指令演示（执行AND但不保存结果，只设标志位）
; 编译: nasm -f win64 test.asm -o test.obj
; 链接: link /subsystem:console /entry:main test.obj ucrt.lib kernel32.lib legacy_stdio_definitions.lib
; ============================================================
default rel

section .data
    ; TEST rax, rax - 检测零
    fmt_zero  db "TEST 0, 0             -> ZF=1, value is zero", 10, 0
    fmt_nz    db "TEST 0x%llx, self     -> ZF=0, value is non-zero", 10, 0
    ; TEST rax, 1 - 检测奇偶
    fmt_odd   db "TEST 0x%llx, 1        -> ZF=0, odd  (bit 0 = 1)", 10, 0
    fmt_even  db "TEST 0x%llx, 1        -> ZF=1, even (bit 0 = 0)", 10, 0
    ; TEST rax, 0x80 - 检测第7位
    fmt_b7s   db "TEST 0x%llx, 0x80     -> ZF=0, bit 7 is SET", 10, 0
    fmt_b7c   db "TEST 0x%llx, 0x80     -> ZF=1, bit 7 is CLEAR", 10, 0
    ; NULL指针检测
    fmt_null  db "TEST ptr, ptr (NULL)  -> ZF=1, pointer is NULL", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    and rsp, -16             ; 确保16字节栈对齐
    sub rsp, 32              ; shadow space

    ; --- TEST rax, rax: 检测零 (值为0) ---
    ; TEST 执行 AND 但不保存结果，只设标志位
    ; 0 AND 0 = 0 -> ZF=1
    xor rax, rax             ; rax = 0
    test rax, rax
    jnz .t1_nz
    lea rcx, [fmt_zero]
    call printf
    jmp .t1_done
.t1_nz:
    lea rcx, [fmt_nz]
    mov rdx, rax
    call printf
.t1_done:

    ; --- TEST rax, rax: 检测非零 (值为42) ---
    ; 42 AND 42 = 42 -> ZF=0
    mov rax, 42
    test rax, rax
    jnz .t2_nz
    lea rcx, [fmt_zero]
    call printf
    jmp .t2_done
.t2_nz:
    lea rcx, [fmt_nz]
    mov rdx, rax
    call printf
.t2_done:

    ; --- TEST rax, 1: 检测奇偶 (奇数) ---
    ; 7 AND 1 = 1 -> ZF=0 (奇数)
    mov rax, 7
    test rax, 1
    jz .t3_even
    lea rcx, [fmt_odd]
    mov rdx, rax
    call printf
    jmp .t3_done
.t3_even:
    lea rcx, [fmt_even]
    mov rdx, rax
    call printf
.t3_done:

    ; --- TEST rax, 1: 检测奇偶 (偶数) ---
    ; 8 AND 1 = 0 -> ZF=1 (偶数)
    mov rax, 8
    test rax, 1
    jz .t4_even
    lea rcx, [fmt_odd]
    mov rdx, rax
    call printf
    jmp .t4_done
.t4_even:
    lea rcx, [fmt_even]
    mov rdx, rax
    call printf
.t4_done:

    ; --- TEST rax, 0x80: 检测第7位 (设置) ---
    ; 0x80 AND 0x80 = 0x80 -> ZF=0 (bit 7 = 1)
    mov rax, 0x80
    test rax, 0x80
    jz .t5_clear
    lea rcx, [fmt_b7s]
    mov rdx, rax
    call printf
    jmp .t5_done
.t5_clear:
    lea rcx, [fmt_b7c]
    mov rdx, rax
    call printf
.t5_done:

    ; --- TEST rax, 0x80: 检测第7位 (清除) ---
    ; 0x7F AND 0x80 = 0 -> ZF=1 (bit 7 = 0)
    mov rax, 0x7F
    test rax, 0x80
    jz .t6_clear
    lea rcx, [fmt_b7s]
    mov rdx, rax
    call printf
    jmp .t6_done
.t6_clear:
    lea rcx, [fmt_b7c]
    mov rdx, rax
    call printf
.t6_done:

    ; --- 实际应用: NULL指针检测 ---
    ; test rax, rax 是检查指针是否为NULL的标准写法
    ; 比 cmp rax, 0 更短（3字节 vs 7字节）
    xor rax, rax             ; rax = NULL (模拟空指针)
    test rax, rax
    jnz .t7_notnull
    lea rcx, [fmt_null]
    call printf
    jmp .t7_done
.t7_notnull:
    lea rcx, [fmt_nz]
    mov rdx, rax
    call printf
.t7_done:

    xor ecx, ecx             ; exit code = 0
    call ExitProcess
