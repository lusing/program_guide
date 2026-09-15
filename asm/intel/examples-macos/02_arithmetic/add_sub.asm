; ============================================================
; 文件: 02_arithmetic/add_sub.asm                          [macOS 版]
; 指令: ADD / SUB
; 描述: 加法与减法 —— 寄存器 / 立即数 / 内存操作数，以及溢出时标志位的变化
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/02_arithmetic/add_sub.asm -o build/add_sub.o
; 链接: clang -arch x86_64 build/add_sub.o -o build/add_sub
; 对照: examples/02_arithmetic/add_sub.asm（Windows / MSVC 调用约定）
; ============================================================
default rel

section .data
    align 8
    mem dq 1000

    fmt_add_reg db "add rax,rbx  : %lld + %lld = %lld", 10, 0
    fmt_add_imm db "add rax,10   : %lld + 10 = %lld", 10, 0
    fmt_add_mem db "add [mem],rax: %lld + %lld = %lld (内存)", 10, 0
    fmt_sub_reg db "sub rax,rbx  : %lld - %lld = %lld", 10, 0
    fmt_sub_imm db "sub rax,5    : %lld - 5 = %lld", 10, 0
    fmt_ovf     db "溢出演示: %d + 1 = %d (有符号溢出)", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8], rbx                 ; rbx 被下面用到，先存起来

    ; add rax, rbx (寄存器加)
    mov rax, 50
    mov rbx, 30
    add rax, rbx                     ; rax = 80
    lea rdi, [fmt_add_reg]
    mov rsi, 50
    mov rdx, 30
    mov rcx, rax                     ; rcx 留到最后才装，避免被前面两行盖掉
    xor eax, eax
    call _printf

    ; add rax, 10 (立即数加)
    mov rax, 100
    add rax, 10                      ; rax = 110
    lea rdi, [fmt_add_imm]
    mov rsi, 100
    mov rdx, rax
    xor eax, eax
    call _printf

    ; add [mem], rax (内存加)
    mov qword [mem], 1000
    mov rax, 55
    add [mem], rax                   ; mem = 1055
    lea rdi, [fmt_add_mem]
    mov rsi, 1000
    mov rdx, 55
    mov rcx, [mem]
    xor eax, eax
    call _printf

    ; sub rax, rbx (寄存器减)
    mov rax, 200
    mov rbx, 75
    sub rax, rbx                     ; rax = 125
    lea rdi, [fmt_sub_reg]
    mov rsi, 200
    mov rdx, 75
    mov rcx, rax
    xor eax, eax
    call _printf

    ; sub rax, 5 (立即数减)
    mov rax, 50
    sub rax, 5                       ; rax = 45
    lea rdi, [fmt_sub_imm]
    mov rsi, 50
    mov rdx, rax
    xor eax, eax
    call _printf

    ; 溢出演示: 32 位 INT_MAX + 1
    mov eax, 0x7FFFFFFF              ; eax = 2147483647 (INT32_MAX)
    mov esi, eax                     ; 先存原值，esi 现在是第 2 个参数
    add eax, 1                       ; eax = 0x80000000, OF=1
    pushfq
    pop r10                          ; r10 = 这次加法之后的标志位快照
    mov edx, eax                     ; 第 3 个参数 = 结果
    lea rdi, [fmt_ovf]
    mov [rbp-16], r10                ; 要跨过 printf，所以先落栈保存
    xor eax, eax
    call _printf

    ; 把刚才那份标志位快照打出来：OF 应该是 1
    ; （注意必须在 add 之后立刻 pushfq，因为 printf 自己也会改标志位）
    mov rdi, [rbp-16]
    call m_putflags
    call m_nl

    mov rbx, [rbp-8]
    xor eax, eax
    leave
    ret

; ------------------------------------------------------------
; 下面这一行把 mac_io.inc 整个包含进来，于是就有了
; m_putflags / m_nl / m_putint 这些输出辅助例程。
; ------------------------------------------------------------
%include "mac_io.inc"
