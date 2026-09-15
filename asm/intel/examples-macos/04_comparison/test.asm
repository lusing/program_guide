; ============================================================
; 文件: 04_comparison/test.asm                             [macOS 版]
; 指令: TEST
; 描述: 按位测试 —— 做 AND 但不写回结果，只设标志位
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/04_comparison/test.asm -o build/test.o
; 链接: clang -arch x86_64 build/test.o -o build/test
; 对照: examples/04_comparison/test.asm
;
; TEST 与 CMP 是一对：CMP 相当于「只设标志位的 SUB」，
; TEST 相当于「只设标志位的 AND」。
; 两个最常见的用法：
;   test rax, rax   是否为零（等价于 cmp rax,0，但机器码短得多）
;   test rax, 1     最低位是否为 1（判奇偶）
; 注意 TEST 会把 CF 和 OF 都清 0，AF 未定义。
; ============================================================
default rel

section .data
    fmt_zero  db "TEST 0, 0             -> ZF=1, value is zero", 10, 0
    fmt_nz    db "TEST 0x%llx, self     -> ZF=0, value is non-zero", 10, 0
    fmt_odd   db "TEST 0x%llx, 1        -> ZF=0, odd  (bit 0 = 1)", 10, 0
    fmt_even  db "TEST 0x%llx, 1        -> ZF=1, even (bit 0 = 0)", 10, 0
    fmt_b7s   db "TEST 0x%llx, 0x80     -> ZF=0, bit 7 is SET", 10, 0
    fmt_b7c   db "TEST 0x%llx, 0x80     -> ZF=1, bit 7 is CLEAR", 10, 0
    fmt_null  db "TEST ptr, ptr (NULL)  -> ZF=1, pointer is NULL", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; --- TEST rax, rax: 判零（值为 0） ---
    xor rax, rax
    test rax, rax
    jnz .t1_nz
    lea rdi, [fmt_zero]
    xor eax, eax
    call _printf
    jmp .t1_done
.t1_nz:
    lea rdi, [fmt_nz]
    mov rsi, rax
    xor eax, eax
    call _printf
.t1_done:

    ; --- TEST rax, rax: 判非零（值为 42） ---
    mov rax, 42
    test rax, rax
    jnz .t2_nz
    lea rdi, [fmt_zero]
    xor eax, eax
    call _printf
    jmp .t2_done
.t2_nz:
    lea rdi, [fmt_nz]
    mov rsi, rax
    xor eax, eax
    call _printf
.t2_done:

    ; --- TEST rax, 1: 判奇偶（7：奇） ---
    mov rax, 7
    test rax, 1
    jz .t3_even
    lea rdi, [fmt_odd]
    mov rsi, rax
    xor eax, eax
    call _printf
    jmp .t3_done
.t3_even:
    lea rdi, [fmt_even]
    mov rsi, rax
    xor eax, eax
    call _printf
.t3_done:

    ; --- TEST rax, 1: 判奇偶（8：偶） ---
    mov rax, 8
    test rax, 1
    jz .t4_even
    lea rdi, [fmt_odd]
    mov rsi, rax
    xor eax, eax
    call _printf
    jmp .t4_done
.t4_even:
    lea rdi, [fmt_even]
    mov rsi, rax
    xor eax, eax
    call _printf
.t4_done:

    ; --- TEST rax, 0x80: 第 7 位已置（0x80） ---
    mov rax, 0x80
    test rax, 0x80
    jz .t5_clear
    lea rdi, [fmt_b7s]
    mov rsi, rax
    xor eax, eax
    call _printf
    jmp .t5_done
.t5_clear:
    lea rdi, [fmt_b7c]
    mov rsi, rax
    xor eax, eax
    call _printf
.t5_done:

    ; --- TEST rax, 0x80: 第 7 位为零（0x7F） ---
    mov rax, 0x7F
    test rax, 0x80
    jz .t6_clear
    lea rdi, [fmt_b7s]
    mov rsi, rax
    xor eax, eax
    call _printf
    jmp .t6_done
.t6_clear:
    lea rdi, [fmt_b7c]
    mov rsi, rax
    xor eax, eax
    call _printf
.t6_done:

    ; --- 实战：NULL 指针检测 ---
    ; test rax, rax 是检查指针是否为空的标准写法，比 cmp rax,0 短
    xor rax, rax                     ; 模拟空指针
    test rax, rax
    jnz .t7_notnull
    lea rdi, [fmt_null]
    xor eax, eax
    call _printf
    jmp .t7_done
.t7_notnull:
    lea rdi, [fmt_nz]
    mov rsi, rax
    xor eax, eax
    call _printf
.t7_done:

    xor eax, eax
    leave
    ret
