; ============================================================
; 文件: 03_logic_bitwise/and_or_xor_not.asm                [macOS 版]
; 指令: AND / OR / XOR / NOT
; 描述: 基本逻辑运算 —— 掩码提取、置位、翻转、取反
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/03_logic_bitwise/and_or_xor_not.asm -o build/and_or_xor_not.o
; 链接: clang -arch x86_64 build/and_or_xor_not.o -o build/and_or_xor_not
; 对照: examples/03_logic_bitwise/and_or_xor_not.asm
;
; Windows 版开头有一段 `and rsp,-16`，是为了在压影子空间之前自己保证 16 字节对齐。
; macOS 走 SysV，压过 rbp 之后栈就已经对齐，不需要这一手（写了也不算错）。
; ============================================================
default rel

section .data
    fmt_and db "AND  0xFF & 0x0F        = 0x%llx", 10, 0
    fmt_or  db "OR   0xF0 | 0x0F        = 0x%llx", 10, 0
    fmt_xor db "XOR  0xFF ^ 0x0F        = 0x%llx", 10, 0
    fmt_not db "NOT  ~0x0               = 0x%llx", 10, 0
    fmt_clr db "XOR  0xDEADBEEF ^ self  = 0x%llx（清零惯用法）", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp

    ; --- AND: 按位与，掩码提取低 4 位 ---
    mov rax, 0xFF
    and rax, 0x0F
    lea rdi, [fmt_and]
    mov rsi, rax
    xor eax, eax
    call _printf

    ; --- OR: 按位或，置上低 4 位 ---
    mov rax, 0xF0
    or rax, 0x0F
    lea rdi, [fmt_or]
    mov rsi, rax
    xor eax, eax
    call _printf

    ; --- XOR: 按位异或，翻转低 4 位 ---
    mov rax, 0xFF
    xor rax, 0x0F
    lea rdi, [fmt_xor]
    mov rsi, rax
    xor eax, eax
    call _printf

    ; --- NOT: 按位取反（注意 NOT 不影响任何标志位） ---
    mov rax, 0x0
    not rax
    lea rdi, [fmt_not]
    mov rsi, rax
    xor eax, eax
    call _printf

    ; --- XOR 自身清零：比 mov rax,0 更短，而且顺手清掉 CF/OF ---
    mov rax, 0xDEADBEEF
    xor rax, rax
    lea rdi, [fmt_clr]
    mov rsi, rax
    xor eax, eax
    call _printf

    xor eax, eax                     ; 退出码 0
    leave
    ret
