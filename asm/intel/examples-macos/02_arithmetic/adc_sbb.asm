; ============================================================
; 文件: 02_arithmetic/adc_sbb.asm                          [macOS 版]
; 指令: ADC / SBB
; 描述: 带进位加法与带借位减法 —— 128 位加减法的实现手法
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/02_arithmetic/adc_sbb.asm -o build/adc_sbb.o
; 链接: clang -arch x86_64 build/adc_sbb.o -o build/adc_sbb
; 对照: examples/02_arithmetic/adc_sbb.asm
;
; x86-64 只有 CF 一个进位位，想算 128/256 位就得「低位用 ADD，高位用 ADC」，
; 借位同理用 SBB。这也是手写大数库的起点。
; ============================================================
default rel

section .data
    align 8
    fmt_add db "ADC 128位加法: 低位 0x%016llx + 1 => 高位=0x%016llx 低位=0x%016llx", 10, 0
    fmt_sbb db "SBB 带借位减法: %lld - %lld - 1(CF) = %lld", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8], rbx

    ; --- ADC: 128 位加法 ---
    ; 低 64 位 = 0xFFFFFFFFFFFFFFFF，高 64 位 = 0，加 1：
    ; 低 64 位溢出把 CF 置 1，ADC 再把 CF 加到高 64 位上。
    mov rax, 0xFFFFFFFFFFFFFFFF      ; 低 64 位
    mov rdx, 0                       ; 高 64 位
    mov rbx, 1
    add rax, rbx                     ; 低 64 位 +1 -> 回绕成 0, CF=1
    adc rdx, 0                       ; 高 64 位 += 0 + CF = 1
    ; 结果: 高位=1, 低位=0 => 0x1_0000000000000000 (= 2^64)
    lea rdi, [fmt_add]
    mov rsi, 0xFFFFFFFFFFFFFFFF      ; 第 2 个参数 = 原始低位
    mov rcx, rax                     ; 第 4 个参数 = 结果低位
    ; rdx 里现在就是结果高位，直接当第 3 个参数用；rcx 必须在 mov rdx 之前装好
    xor eax, eax
    call _printf

    ; --- SBB: 带借位减法 ---
    ; stc 把 CF 置 1，sbb rax,rbx 等价于 rax - rbx - CF
    mov rax, 100
    mov rbx, 30
    mov rsi, 100                     ; 被减数
    mov rdx, 30                      ; 减数
    stc                              ; CF = 1
    sbb rax, rbx                     ; rax = 100 - 30 - 1 = 69
    mov rcx, rax                     ; 结果
    lea rdi, [fmt_sbb]
    xor eax, eax
    call _printf

    ; 看一下 SBB 之后的 CF
    pushfq
    pop rdi
    call m_putflags
    call m_nl

    mov rbx, [rbp-8]
    xor eax, eax
    leave
    ret

%include "mac_io.inc"
