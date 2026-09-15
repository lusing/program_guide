; ============================================================
; 文件: 05_control_flow/setcc.asm                          [macOS 版]
; 指令: SETE / SETG / SETL（条件字节设置 SETcc）
; 描述: 按标志位把字节寄存器写成 0 或 1
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/05_control_flow/setcc.asm -o build/setcc.o
; 链接: clang -arch x86_64 build/setcc.o -o build/setcc
; 对照: examples/05_control_flow/setcc.asm
;
; 三条铁律：
;   1) SETcc 只写目标寄存器的低 8 位，高位保持原样
;      -> 想当整数用，必须紧跟 MOVZX 零扩展；
;   2) SETcc 本身不改标志位，所以一次 CMP 之后可以连着抓好几个结果；
;   3) printf 会改标志位，所以必须先把所有 SETcc 结果抓完再打印。
; C 里 `int x = (a > b);` 生成的就是 SETcc + MOVZX 这一对。
; ============================================================
default rel

section .data
    fmt_53 db "CMP 5,3: sete=%lld setg=%lld setl=%lld", 10, 0
    fmt_35 db "CMP 3,5: sete=%lld setg=%lld setl=%lld", 10, 0
    fmt_55 db "CMP 5,5: sete=%lld (equal!)", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8], r12                 ; 三个被调用者保存寄存器，用来跨 printf 保存结果
    mov [rbp-16], r13
    mov [rbp-24], r14

    ; --------------------------------------------------------
    ; 测试 1：CMP 5,3 -> 5 - 3 = 2，ZF=0 SF=0 OF=0
    ;   sete -> 0   setg -> 1   setl -> 0
    ; --------------------------------------------------------
    mov rax, 5
    mov rdx, 3
    cmp rax, rdx
    sete r12b
    setg r13b
    setl r14b
    movzx r12, r12b
    movzx r13, r13b
    movzx r14, r14b

    lea rdi, [fmt_53]
    mov rsi, r12
    mov rdx, r13
    mov rcx, r14
    xor eax, eax
    call _printf

    ; --------------------------------------------------------
    ; 测试 2：CMP 3,5 -> 3 - 5 = -2，ZF=0 SF=1 OF=0
    ;   sete -> 0   setg -> 0   setl -> 1
    ; --------------------------------------------------------
    mov rax, 3
    mov rdx, 5
    cmp rax, rdx
    sete r12b
    setg r13b
    setl r14b
    movzx r12, r12b
    movzx r13, r13b
    movzx r14, r14b

    lea rdi, [fmt_35]
    mov rsi, r12
    mov rdx, r13
    mov rcx, r14
    xor eax, eax
    call _printf

    ; --------------------------------------------------------
    ; 测试 3：CMP 5,5 -> ZF=1，sete -> 1
    ; --------------------------------------------------------
    mov rax, 5
    mov rdx, 5
    cmp rax, rdx
    sete r12b
    movzx r12, r12b

    lea rdi, [fmt_55]
    mov rsi, r12
    xor eax, eax
    call _printf

    mov r12, [rbp-8]
    mov r13, [rbp-16]
    mov r14, [rbp-24]
    xor eax, eax
    leave
    ret
