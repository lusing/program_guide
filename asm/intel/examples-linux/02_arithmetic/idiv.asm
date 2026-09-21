; ============================================================
; 文件: 02_arithmetic/idiv.asm                             [Linux 版]
; 指令: IDIV
; 描述: 有符号除法 —— 除之前用 CQO 把符号位扩展进 RDX
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/02_arithmetic/idiv.asm -o build/idiv.o
; 链接: gcc -no-pie build/idiv.o -o build/idiv
; 对照: examples/02_arithmetic/idiv.asm
;
; 无符号除法前 XOR EDX,EDX，有符号除法前 CQO（64 位）/ CDQ（32 位）。
; 记法：CQO = Convert Quadword to Octaword，把 RAX 的符号位铺满 RDX。
; 余数的符号跟被除数一致，除法一律向零截断 —— 和 C 语言一样，
; 但与 Python 的 // 和 %（向下取整）不同，写跨语言公式时要留神。
;
; 顺带一个 ABI 提醒：DIV/IDIV 的余数永远落在 RDX 里，
; 而 RDX 正好是 SysV 的第 3 个参数寄存器。
; 所以「先算完除法的商和余数、各自安放好，最后才装 printf 参数」是固定套路。
; ============================================================
default rel

section .data
    align 8
    fmt_pos db "正数: 100 / 7   => 商=%lld, 余=%lld", 10, 0
    fmt_neg db "负数: -100 / 7  => 商=%lld, 余=%lld（向零截断）", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rbx

    ; --- 正数: 100 / 7 ---
    mov rax, 100
    cqo                              ; RDX = RAX 的符号扩展（正数 => 0）
    mov rbx, 7
    idiv rbx                         ; RAX = 商 14，RDX = 余 2
    lea rdi, [fmt_pos]
    mov rsi, rax                     ; 第 2 个参数 = 商（rsi 先装好）
    ; rdx 里就是余数，直接当第 3 个参数用
    xor eax, eax                     ; 这只清掉 rax，rsi/rdx 不受影响
    call printf

    ; --- 负数: -100 / 7 ---
    mov rax, -100
    cqo                              ; RDX = 0xFFFFFFFFFFFFFFFF
    mov rbx, 7
    idiv rbx                         ; RAX = 商 -14，RDX = 余 -2
    lea rdi, [fmt_neg]
    mov rsi, rax
    xor eax, eax
    call printf

    mov rbx, [rbp-8]
    xor eax, eax
    leave
    ret
