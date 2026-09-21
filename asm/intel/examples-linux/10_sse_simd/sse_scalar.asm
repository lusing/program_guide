; ============================================================
; 文件: 10_sse_simd/sse_scalar.asm                         [Linux 版]
; 指令: ADDSS / SUBSS / MULSS / ADDSD / MULSD
; 描述: 标量运算 —— 一次只算一个数，但快得没有对手
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/10_sse_simd/sse_scalar.asm -o build/sse_scalar.o
; 链接: gcc -no-pie build/sse_scalar.o -o build/sse_scalar
; 对照: examples/10_sse_simd/sse_scalar.asm
;
; ------------------------------------------------------------
; 标量（scalar）和打包（packed）的区别只在「动几个数」：
;   addps  xmm0, xmm1   4 个 float 同时加
;   addss  xmm0, xmm1   只加最低那 1 个 float，高 3 个原样不动
;   addsd  xmm0, xmm1   只加最低那 1 个 double，高 64 位不动
;
; 「高位原样不动」这点很关键，也是个容易踩的坑：
; 连续做 addss 是安全的，但如果中间插了一条 movss（会清零高位），
; 后面再用之前的「高位」就会读到 0。
;
; 对现代编译出来的代码来说，标量 SSE 才是浮点运算的主战场 ——
; C 里的每个 `a + b` 基本都是 addss/addsd。
; 打包指令留给编译器自动向量化和手写内核。
;
; ------------------------------------------------------------
; Linux 传参：%f 的值直接放 xmm0，eax 记「用了几个向量寄存器」。
; Windows 那边是「按参数位置算的 xmmN + RDX/R8 双写」，本类几乎处处不同。
; ============================================================
default rel

section .data
    align 4
    f_val1  dd 3.14                     ; 单精度
    f_val2  dd 2.0
    align 8
    d_val1  dq 2.718281828459045        ; 双精度
    d_val2  dq 3.0
    align 8
    temp_d  dq 0.0

    fmt_addss db "ADDSS: 3.14 + 2.0 = %f", 10, 0
    fmt_subss db "SUBSS: 3.14 - 2.0 = %f", 10, 0
    fmt_mulss db "MULSS: 3.14 * 2.0 = %f", 10, 0
    fmt_addsd db "ADDSD: 2.71828... + 3.0 = %f", 10, 0
    fmt_mulsd db "MULSD: 2.71828... * 3.0 = %f", 10, 0
    fmt_done  db "SSE scalar arithmetic demo completed.", 10, 0

; 把 xmm0 里的结果落内存 → 装回 xmm0 → 用 %f 打出来
; （落一次内存是为了避开「%f 要 double 但结果可能是 float」的转换细节；
;   cvtss2sd 已经在调用点做掉了）
%macro print_x 1
    movsd [temp_d], xmm0
    movsd xmm0, [temp_d]
    lea rdi, [%1]
    mov eax, 1
    call printf
%endmacro

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; --------------------------------------------------------
    ; 1. ADDSS：单精度标量加，只动 xmm0 的低 32 位
    ; --------------------------------------------------------
    movss xmm0, [f_val1]                ; xmm0[31:0] = 3.14
    movss xmm1, [f_val2]                ; xmm1[31:0] = 2.0
    addss xmm0, xmm1                    ; = 5.14
    cvtss2sd xmm0, xmm0                 ; float -> double，交给 %f
    print_x fmt_addss

    ; --------------------------------------------------------
    ; 2. SUBSS
    ; --------------------------------------------------------
    movss xmm0, [f_val1]
    movss xmm1, [f_val2]
    subss xmm0, xmm1                    ; = 1.14
    cvtss2sd xmm0, xmm0
    print_x fmt_subss

    ; --------------------------------------------------------
    ; 3. MULSS
    ; --------------------------------------------------------
    movss xmm0, [f_val1]
    movss xmm1, [f_val2]
    mulss xmm0, xmm1                    ; = 6.28
    cvtss2sd xmm0, xmm0
    print_x fmt_mulss

    ; --------------------------------------------------------
    ; 4. ADDSD：双精度标量加，只动低 64 位
    ; --------------------------------------------------------
    movsd xmm0, [d_val1]
    movsd xmm1, [d_val2]
    addsd xmm0, xmm1                    ; = 5.71828...
    print_x fmt_addsd

    ; --------------------------------------------------------
    ; 5. MULSD
    ; --------------------------------------------------------
    movsd xmm0, [d_val1]
    movsd xmm1, [d_val2]
    mulsd xmm0, xmm1                    ; = 8.15484...
    print_x fmt_mulsd

    lea rdi, [fmt_done]
    xor eax, eax
    call printf

    xor eax, eax
    leave
    ret
