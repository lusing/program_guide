; ============================================================
; 文件: 10_sse_simd/sse_arithmetic.asm                     [macOS 版]
; 指令: ADDPS / SUBPS / MULPS / DIVPS
; 描述: 一条指令算四个 —— SIMD 的正题
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/10_sse_simd/sse_arithmetic.asm -o build/sse_arithmetic.o
; 链接: clang -arch x86_64 build/sse_arithmetic.o -o build/sse_arithmetic
; 对照: examples/10_sse_simd/sse_arithmetic.asm
;
; ------------------------------------------------------------
; 打包运算是一条直路：两个 128 位寄存器按「通道」逐位对齐计算，
; 4 个 float 互不干扰、一次算完。
;     [1,2,3,4] + [5,6,7,8] = [6, 8, 10, 12]
;     [1,2,3,4] - [5,6,7,8] = [-4,-4,-4,-4]
;     [1,2,3,4] * [5,6,7,8] = [5, 12, 21, 32]
;     [1,2,3,4] / [5,6,7,8] = [0.2, 0.333…, 0.428…, 0.5]
; 这就是所有「图像滤镜、矩阵乘、神经网络推理」的最底层形态。
; 128 位在 Ivy Bridge 上是 2 个周期，等于每周期出 2 个 float ——
; 换到 AVX 是 256 位、AVX-512 是 512 位，纯粹是宽度的军备竞赛。
;
; 一个反直觉的地方：MULPS 的 MSB 位是「乘」，不是「无符号」。
; x86 助记符里：
;   ps/pd 里的 p = packed，s/d = single/double
;   所以 addps = packed single 加，mulps = packed single 乘
;
; ------------------------------------------------------------
; macOS 要点：`"  [%d] = %f"` 的参数是 rdi / esi / xmm0 / eax=1。
; Windows 版需要 RDX + XMM2 双写，这里省掉一整条指令。
; ============================================================
default rel

section .data
    align 16
    packed1  dd 1.0, 2.0, 3.0, 4.0
    align 16
    packed2  dd 5.0, 6.0, 7.0, 8.0

    align 16
    xmm_buf  dd 0.0, 0.0, 0.0, 0.0

    fmt_addps db "ADDPS: [1,2,3,4] + [5,6,7,8] = [6, 8, 10, 12]", 10, 0
    fmt_subps db "SUBPS: [1,2,3,4] - [5,6,7,8] = [-4, -4, -4, -4]", 10, 0
    fmt_mulps db "MULPS: [1,2,3,4] * [5,6,7,8] = [5, 12, 21, 32]", 10, 0
    fmt_divps db "DIVPS: [1,2,3,4] / [5,6,7,8] = [0.2, 0.3333, 0.4286, 0.5]", 10, 0
    fmt_elem  db "  [%d] = %f", 10, 0
    fmt_done  db "SSE packed arithmetic demo completed.", 10, 0

section .text
    global _main
    extern _printf

; ------------------------------------------------------------
; print_4floats —— 把 xmm_buf 里的 4 个 float 逐行打出来
; 这是本类唯一的「自定义函数」，注意它也要遵守 SysV：
;   - 用 rbp 建帧，退场 leave
;   - 不碰 rbx/r12-r15（它本来也不碰）
; ------------------------------------------------------------
print_4floats:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    movss xmm0, [xmm_buf]
    cvtss2sd xmm0, xmm0
    lea rdi, [fmt_elem]
    mov esi, 0
    mov eax, 1
    call _printf

    movss xmm0, [xmm_buf + 4]
    cvtss2sd xmm0, xmm0
    lea rdi, [fmt_elem]
    mov esi, 1
    mov eax, 1
    call _printf

    movss xmm0, [xmm_buf + 8]
    cvtss2sd xmm0, xmm0
    lea rdi, [fmt_elem]
    mov esi, 2
    mov eax, 1
    call _printf

    movss xmm0, [xmm_buf + 12]
    cvtss2sd xmm0, xmm0
    lea rdi, [fmt_elem]
    mov esi, 3
    mov eax, 1
    call _printf

    leave
    ret

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; --------------------------------------------------------
    ; 1. ADDPS
    ; --------------------------------------------------------
    movaps xmm0, [packed1]              ; xmm0 = [1,2,3,4]
    movaps xmm1, [packed2]              ; xmm1 = [5,6,7,8]
    addps xmm0, xmm1                    ; xmm0 = [6,8,10,12]
    movaps [xmm_buf], xmm0

    lea rdi, [fmt_addps]
    xor eax, eax
    call _printf
    call print_4floats

    ; --------------------------------------------------------
    ; 2. SUBPS
    ; --------------------------------------------------------
    movaps xmm0, [packed1]
    movaps xmm1, [packed2]
    subps xmm0, xmm1                    ; xmm0 = [-4,-4,-4,-4]
    movaps [xmm_buf], xmm0

    lea rdi, [fmt_subps]
    xor eax, eax
    call _printf
    call print_4floats

    ; --------------------------------------------------------
    ; 3. MULPS
    ; --------------------------------------------------------
    movaps xmm0, [packed1]
    movaps xmm1, [packed2]
    mulps xmm0, xmm1                    ; xmm0 = [5,12,21,32]
    movaps [xmm_buf], xmm0

    lea rdi, [fmt_mulps]
    xor eax, eax
    call _printf
    call print_4floats

    ; --------------------------------------------------------
    ; 4. DIVPS
    ; --------------------------------------------------------
    movaps xmm0, [packed1]
    movaps xmm1, [packed2]
    divps xmm0, xmm1                    ; xmm0 = [0.2, 0.333…, 0.428…, 0.5]
    movaps [xmm_buf], xmm0

    lea rdi, [fmt_divps]
    xor eax, eax
    call _printf
    call print_4floats

    lea rdi, [fmt_done]
    xor eax, eax
    call _printf

    xor eax, eax
    leave
    ret
