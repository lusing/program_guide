; ============================================================
; 文件: 06_string_ops/cmpsb.asm                            [macOS 版]
; 指令: CMPSB / REPE CMPSB
; 描述: 字符串比较 —— 硬件级逐字节比对（memcmp）
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/06_string_ops/cmpsb.asm -o build/cmpsb.o
; 链接: clang -arch x86_64 build/cmpsb.o -o build/cmpsb
; 对照: examples/06_string_ops/cmpsb.asm
;
; CMPSB 把 [RSI] 与 [RDI] 相减（只设标志，不动内存），随后两个指针各自 ±1。
; 配 REPE（ZF=1 时继续）就是标准库 memcmp 的做法：
;   全部相等      -> RCX 归零，ZF=1
;   中途撞上不等  -> 立刻停下，ZF=0，RCX = 还没比过的字节数
; 所以「首个不同的位置」= 总长度 - 剩余 RCX - 1。
;
; 还想提醒一句反过来用的情况：配 REPNE（ZF=0 时继续）就是「找第一对相同的字节」。
;
; ------------------------------------------------------------
; SysV 与 Win64 的差别在这里只有一处，但很关键：
;   Windows 里 RSI/RDI 是 non-volatile，用前必须 push 保存、用完 pop 回来；
;   macOS（SysV）里它们是调用者保存，**不用保护** ——
;   代价是它们正好是 printf 的第 1、第 2 个参数寄存器，
;   所以每个 printf 之前，全部参数都得从头再装一遍。
; 另外 ZF 会被 printf 破坏，比较完必须立刻用 setz 落到寄存器或栈里。
; ============================================================
default rel

section .data
    str1       db "Hello", 0                ; 基准串
    str2_same  db "Hello", 0                ; 与 str1 相同
    str2_diff  db "Hallo", 0                ; 与 str1 不同（第 2 个字节起）
    str_len    equ 5                        ; 比较长度

    fmt_hdr    db "%lld. 比较 [%s] 与 [%s]：", 10, 0
    fmt_equal  db "   结果：完全相同（%lld 个字节全部命中）", 10, 0
    fmt_diff   db "   结果：第 %lld 个字节起不同（RCX 还剩 %lld 字节没比）", 10, 0
    fmt_done   db "CMPS/CMPSB demo completed.", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8],  r12                   ; r12-r15 是被调用者保存寄存器，
    mov [rbp-16], r13                   ; 这里借它们跨 printf 存中间结果，
    mov [rbp-24], r14                   ; 退场前一律还原（_main 用 ret 返回，
    mov [rbp-32], r15                   ; 破坏它们会让 dyld 崩溃）

    mov r15, 1                          ; 比较序号

    ; --------------------------------------------------------
    ; 1. 相同的两个串："Hello" vs "Hello"
    ; --------------------------------------------------------
    lea rsi, [str1]                     ; RSI = 串1
    lea rdi, [str2_same]                ; RDI = 串2
    mov rcx, str_len                    ; RCX = 比较长度
    cld                                 ; DF=0，指针递增
    repe cmpsb                          ; 相等就继续，不等或 RCX=0 停下

    mov r13, rcx                        ; 剩余未比较字节数
    setz r12b                           ; ZF=1（全部相等）时 r12b=1

    lea rdi, [fmt_hdr]
    mov rsi, r15                        ; %lld：序号
    lea rdx, [str1]                     ; %s：串1
    lea rcx, [str2_same]                ; %s：串2
    xor eax, eax
    call _printf

    test r12b, r12b                     ; 用保存下来的 ZF（printf 已把标志冲掉）
    jz .diff1
    lea rdi, [fmt_equal]
    mov rsi, str_len
    xor eax, eax
    call _printf
    jmp .next1
.diff1:
    mov rax, str_len
    sub rax, r13
    dec rax                             ; 位置 = 长度 - 剩余 - 1
    lea rdi, [fmt_diff]
    mov rsi, rax                        ; %lld：位置
    mov rdx, r13                        ; %lld：剩余
    xor eax, eax
    call _printf
.next1:

    ; --------------------------------------------------------
    ; 2. 不同的两个串："Hello" vs "Hallo"
    ;    'e'(0x65) - 'a'(0x61) = 4 -> ZF=0，在第二个字节处停止
    ; --------------------------------------------------------
    inc r15
    lea rsi, [str1]
    lea rdi, [str2_diff]
    mov rcx, str_len
    cld
    repe cmpsb

    mov r13, rcx
    setz r12b

    lea rdi, [fmt_hdr]
    mov rsi, r15
    lea rdx, [str1]
    lea rcx, [str2_diff]
    xor eax, eax
    call _printf

    test r12b, r12b
    jz .diff2
    lea rdi, [fmt_equal]
    mov rsi, str_len
    xor eax, eax
    call _printf
    jmp .next2
.diff2:
    mov rax, str_len
    sub rax, r13
    dec rax
    lea rdi, [fmt_diff]
    mov rsi, rax
    mov rdx, r13
    xor eax, eax
    call _printf
.next2:

    lea rdi, [fmt_done]
    xor eax, eax
    call _printf

    mov r12, [rbp-8]
    mov r13, [rbp-16]
    mov r14, [rbp-24]
    mov r15, [rbp-32]
    xor eax, eax
    leave
    ret
