; ============================================================
; 文件: 05_control_flow/je_jne.asm                         [macOS 版]
; 指令: JE / JNE + CMP
; 描述: 相等 / 不等跳转，以及 if-else 的标准汇编写法
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/05_control_flow/je_jne.asm -o build/je_jne.o
; 链接: clang -arch x86_64 build/je_jne.o -o build/je_jne
; 对照: examples/05_control_flow/je_jne.asm
;
; 预期输出：
;   JE:  5 == 5  -> Equal (JE taken)
;   JNE: 5 != 3  -> Not equal (JNE taken)
;   If-else: 42 == 42 -> Match
; ============================================================
default rel

section .data
    fmt_je      db "JE:  5 == 5  -> Equal (JE taken)", 10, 0
    fmt_jne     db "JNE: 5 != 3  -> Not equal (JNE taken)", 10, 0
    fmt_match   db "If-else: 42 == 42 -> Match", 10, 0
    fmt_nomatch db "If-else: 42 == 42 -> No match", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp

    ; --------------------------------------------------------
    ; JE：ZF=1 时跳转，也就是「相等」
    ; CMP 做 5 - 5 = 0，只设标志位不写回结果 -> ZF=1
    ; --------------------------------------------------------
    mov rax, 5
    mov rdx, 5
    cmp rax, rdx
    je .equal_taken
    jmp .after_je
.equal_taken:
    lea rdi, [fmt_je]
    xor eax, eax
    call _printf
.after_je:

    ; --------------------------------------------------------
    ; JNE：ZF=0 时跳转，也就是「不等」
    ; CMP 做 5 - 3 = 2 -> ZF=0
    ; --------------------------------------------------------
    mov rax, 5
    mov rdx, 3
    cmp rax, rdx
    jne .notequal_taken
    jmp .after_jne
.notequal_taken:
    lea rdi, [fmt_jne]
    xor eax, eax
    call _printf
.after_jne:

    ; --------------------------------------------------------
    ; if-else 的汇编套路：
    ;   if (value == target) { ... } else { ... }
    ; 编译器习惯把「不满足条件的分支」放在前面，
    ; 这样条件成立时可以直接跳过去，少一条 JMP。
    ; --------------------------------------------------------
    mov rax, 42                      ; value
    mov rdx, 42                      ; target
    cmp rax, rdx
    je .if_match

    ; --- else 分支 ---
    lea rdi, [fmt_nomatch]
    xor eax, eax
    call _printf
    jmp .after_ifelse

.if_match:
    ; --- if 分支 ---
    lea rdi, [fmt_match]
    xor eax, eax
    call _printf

.after_ifelse:

    xor eax, eax
    leave
    ret
