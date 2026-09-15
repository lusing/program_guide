; ============================================================
; 文件: 02_arithmetic/inc_dec_neg.asm                      [macOS 版]
; 指令: INC / DEC / NEG
; 描述: 递增 / 递减 / 取负 —— 重点是 INC/DEC 不改变 CF 这个特性
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/02_arithmetic/inc_dec_neg.asm -o build/inc_dec_neg.o
; 链接: clang -arch x86_64 build/inc_dec_neg.o -o build/inc_dec_neg
; 对照: examples/02_arithmetic/inc_dec_neg.asm
;
; INC / DEC 只影响 OF SF ZF AF PF，不动 CF。
; 所以想「不破坏进位链」地改计数器，就该用 INC/DEC 而不是 ADD/SUB。
; 但要小心：它们仍然会改 ZF，写循环时别把想保留的条件码一起冲掉。
; ============================================================
default rel

section .data
    align 8
    fmt_inc db "inc rax: %lld + 1 => %lld", 10, 0
    fmt_dec db "dec rax: %lld - 1 => %lld", 10, 0
    fmt_neg db "neg rax: neg(%lld) => %lld", 10, 0
    fmt_cf  db "INC 不影响 CF：先 stc 把 CF 置 1，inc 之后 CF 仍然是 %d", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; inc: 41 + 1 = 42
    mov rax, 41
    inc rax                          ; rax = 42
    lea rdi, [fmt_inc]
    mov rsi, 41
    mov rdx, rax
    xor eax, eax
    call _printf

    ; dec: 100 - 1 = 99
    mov rax, 100
    dec rax                          ; rax = 99
    lea rdi, [fmt_dec]
    mov rsi, 100
    mov rdx, rax
    xor eax, eax
    call _printf

    ; neg: neg(55) = -55（等价于 0 - x，同时按二进制补码取反加一）
    mov rax, 55
    neg rax                          ; rax = -55
    lea rdi, [fmt_neg]
    mov rsi, 55
    mov rdx, rax
    xor eax, eax
    call _printf

    ; INC 不影响 CF：先 stc 置 CF=1，再做 inc，CF 仍是 1
    stc                              ; CF = 1
    inc rax                          ; rax = -54，CF 保持不变
    setc sil                         ; sil = CF
    movzx rsi, sil
    pushfq
    pop r10                          ; 顺便把整套标志位抓下来看看
    lea rdi, [fmt_cf]
    mov [rbp-8], r10
    xor eax, eax
    call _printf

    mov rdi, [rbp-8]
    call m_putflags
    call m_nl

    xor eax, eax
    leave
    ret

%include "mac_io.inc"
