; ============================================================
; 文件: 06_string_ops/stosb.asm                            [Linux 版]
; 指令: STOSB / REP STOSB
; 描述: 字符串存储填充 —— 等价于 memset
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/06_string_ops/stosb.asm -o build/stosb.o
; 链接: gcc -no-pie build/stosb.o -o build/stosb
; 对照: examples/06_string_ops/stosb.asm
;
; STOS 只认两个寄存器：
;   AL  = 要写入的字节      RDI = 目标地址
; REP STOSB 就是 memset(RDI, AL, RCX)，在现代 CPU 上还有 ERMS 优化，跑得飞快。
; 本机 CPU 支持 ERMS（Enhanced REP MOVSB/STOSB），所以大块复制填充会走硬件快路径。
; 注意 RDI 在 SysV 里是第 1 个参数寄存器：填充做完之后要重新装参数。
; ============================================================
default rel

section .data
    fill1_len equ 20
    fill2_len equ 15

    fmt_fill   db "%lld. rep stosb: 填了 %lld 字节，用的是 '%c'", 10, 0
    fmt_result db "   Result: [%s]", 10, 0
    fmt_done   db "STOS/STOSB demo completed.", 10, 0

section .bss
    buf1 resb 64
    buf2 resb 64

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; --------------------------------------------------------
    ; 1. rep stosb：用 '*' 填 20 字节  ==  memset(buf1, '*', 20)
    ; --------------------------------------------------------
    lea rdi, [buf1]                    ; RDI = 目标
    mov al, '*'                        ; AL  = 填充值
    mov rcx, fill1_len                 ; RCX = 次数
    cld                                ; DF=0，RDI 递增
    rep stosb
    mov byte [buf1 + fill1_len], 0     ; 补结尾 0

    lea rdi, [fmt_fill]
    mov rsi, 1                         ; 序号
    mov rdx, fill1_len                 ; 长度
    mov ecx, '*'                       ; 字符
    xor eax, eax
    call printf

    lea rdi, [fmt_result]
    lea rsi, [buf1]
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; 2. rep stosb：用 '-' 填 15 字节
    ; --------------------------------------------------------
    lea rdi, [buf2]
    mov al, '-'
    mov rcx, fill2_len
    cld
    rep stosb
    mov byte [buf2 + fill2_len], 0

    lea rdi, [fmt_fill]
    mov rsi, 2
    mov rdx, fill2_len
    mov ecx, '-'
    xor eax, eax
    call printf

    lea rdi, [fmt_result]
    lea rsi, [buf2]
    xor eax, eax
    call printf

    lea rdi, [fmt_done]
    xor eax, eax
    call printf

    xor eax, eax
    leave
    ret
