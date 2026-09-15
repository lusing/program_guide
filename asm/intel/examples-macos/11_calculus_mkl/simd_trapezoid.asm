; ============================================================
; 文件: 11_calculus_mkl/simd_trapezoid.asm                 [macOS 版]
; 指令: MULPS / ADDPS / MULSS / ADDSS / MOVUPS / SHUFPS / RDTSC
; 描述: 梯形法数值积分 —— 标量 vs SIMD，用 RDTSC 量出真实差距
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/11_calculus_mkl/simd_trapezoid.asm -o build/simd_trapezoid.o
; 链接: clang -arch x86_64 build/simd_trapezoid.o -o build/simd_trapezoid
; 对照: examples/11_calculus_mkl/avx2_trapezoid.asm
;
; ★ 移植说明：原版是 AVX2（ymm/8 路 + vbroadcastss + vhaddps），
;   本机 Ivy Bridge 不支持 AVX2，这里用 SSE 的 xmm/4 路。
;   两处 AVX2 专属写法要改：
;     广播常数：AVX2 的 vbroadcastss 一条搞定
;               → SSE 用 movss + shufps xmm, xmm, 0
;     水平求和：AVX2 的 vextractf128 + vhaddps 两条搞定
;               → SSE 用两次 shufps + addps
;
; ------------------------------------------------------------
; 问题：∫₀^π sin(x) dx = 2.0（精确值）
;
; 两件事分开做：
;   1. **函数求值**：sin(x) 用 9 项 Taylor 级数
;         sin(x) = x · P(x²)，P(t) = c0 + c1·t + … + c8·t⁸
;      写成 Horner 形式。不用 x87 的 fsin，是为了让标量版和向量版
;      做**完全相同的算术工作**。
;   2. **梯形法求和**：
;         ∫ ≈ h·[ f₀/2 + f₁ + … + f_{N-1} + f_N/2 ]
;          = h·[ Σ_{i=0}^{N-1} f_i  +  (f_N − f₀)/2 ]
;      右边那种形式把求和变成整齐的 N 项（N=1024 正好 256 组向量），
;      端点只做一次事后修正，向量循环里一条分支都不用加。
;      这就是数值代码要改写求和顺序的典型理由：**让循环体整齐**。
;
; 关于「公平对比」：两条 Horner 链都用 NASM 宏写成，在循环体里**展开**，
; 谁都不额外付函数调用和传参的钱 —— 否则量出来的差距会掺进调用开销。
; RDTSC 拿的是参考时钟周期；计时前后各插一条 lfence，防止乱序执行
; 把计时指令提前。这是手写基准测试的基本纪律。
; ============================================================
default rel

%define N 1024

section .data
    align 8
    d_pi     dq 3.141592653589793
    d_h      dq 0.0                     ; π/N，运行时算
    d_two    dq 2.0
    d_twelve dq 12.0

    align 4
    f_h      dd 0.0
    f_pi     dd 3.1415926536
    f_half   dd 0.5

    ; Taylor 系数（float）。向量版要用 shufps 广播到 4 条通道。
    t_c0 dd  1.0
    t_c1 dd -0.16666666667
    t_c2 dd  0.0083333333333
    t_c3 dd -0.00019841269841
    t_c4 dd  0.0000027557319224
    t_c5 dd -0.000000025052108385
    t_c6 dd  0.00000000016059043837
    t_c7 dd -0.00000000000076471637318
    t_c8 dd  0.0000000000000028114572543

    fmt_hdr   db "=== 梯形法积分 ∫sin(x)dx，区间 [0, π] ===", 10, 0
    fmt_parm  db "N = %d 个区间，h = π/N = %.9f", 10, 0
    fmt_scal  db "标量版（mulss/addss）：      %.9f   误差 %.9f", 10, 0
    fmt_vec   db "SIMD 版（mulps/addps 4 路）：%.9f   误差 %.9f", 10, 0
    fmt_exact db "精确值 = 2.0；梯形法的 O(h²) 截断误差 ≈ πh²/12 = %.9f", 10, 0
    fmt_time  db "耗时：标量 %llu 周期，SIMD %llu 周期", 10, 0
    fmt_speed db "加速比 ≈ %.2f×（理论上限 4×，实际受循环开销和内存带宽限制）", 10, 0
    fmt_done  db "SIMD trapezoid demo completed.", 10, 0

section .bss
    alignb 16
    x_arr  resd N+1                     ; x_i = i·h

; ============================================================
; 两条 Horner 链写成 NASM 宏，在各自的循环体里展开
; ============================================================

; 标量版：入口 xmm0 = x，出口 xmm0 = x·P(x²) ≈ sin(x)
; 用到的临时寄存器：xmm0（入/出）、xmm1（t）、xmm2（P）
%macro TAYLOR_S 0
    movss xmm1, xmm0
    mulss xmm1, xmm1                    ; t = x²
    movss xmm2, [t_c8]
    mulss xmm2, xmm1
    addss xmm2, [t_c7]
    mulss xmm2, xmm1
    addss xmm2, [t_c6]
    mulss xmm2, xmm1
    addss xmm2, [t_c5]
    mulss xmm2, xmm1
    addss xmm2, [t_c4]
    mulss xmm2, xmm1
    addss xmm2, [t_c3]
    mulss xmm2, xmm1
    addss xmm2, [t_c2]
    mulss xmm2, xmm1
    addss xmm2, [t_c1]
    mulss xmm2, xmm1
    addss xmm2, [t_c0]
    mulss xmm0, xmm2                    ; sin(x) = x·P(t)
%endmacro

; 向量版：入口 xmm0 = [x_i … x_i+3]，出口 xmm0 = [sin … sin]
; 系数常驻 xmm4..xmm13（在循环外用 shufps 广播好），临时用 xmm1、xmm2
%macro TAYLOR_V 0
    movaps xmm1, xmm0
    mulps  xmm1, xmm1                   ; t = x²
    movaps xmm2, xmm13
    mulps  xmm2, xmm1
    addps  xmm2, xmm12
    mulps  xmm2, xmm1
    addps  xmm2, xmm11
    mulps  xmm2, xmm1
    addps  xmm2, xmm10
    mulps  xmm2, xmm1
    addps  xmm2, xmm9
    mulps  xmm2, xmm1
    addps  xmm2, xmm8
    mulps  xmm2, xmm1
    addps  xmm2, xmm6
    mulps  xmm2, xmm1
    addps  xmm2, xmm5
    mulps  xmm2, xmm1
    addps  xmm2, xmm4                   ; P(t)
    mulps  xmm0, xmm2                   ; sin(x) = x·P(t)
%endmacro

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    mov [rbp-8],  rbx                   ; x_arr 基址
    mov [rbp-16], r12                   ; 标量耗时
    mov [rbp-24], r13                   ; 向量耗时
    ; [rbp-32] = 标量 Σ   [rbp-40] = 向量 Σ   [rbp-44] = 端点修正 corr

    ; --------------------------------------------------------
    ; 0. 预备（不计时）：h = π/N，x[i] = i·h，端点修正项
    ; --------------------------------------------------------
    mov eax, N
    cvtsi2sd xmm1, eax                  ; xmm1 = (double)N
    movsd xmm0, [d_pi]
    divsd xmm0, xmm1                    ; h = π/N
    movsd [d_h], xmm0
    cvtsd2ss xmm2, xmm0
    movss [f_h], xmm2

    lea rbx, [x_arr]
    xor ecx, ecx
.fillx:
    cvtsi2ss xmm0, ecx
    mulss xmm0, [f_h]
    movss [rbx + rcx*4], xmm0
    inc ecx
    cmp ecx, N
    jbe .fillx                          ; 0..N，共 N+1 个点

    ; corr = (f_N − f_0)/2；x_arr[0] = 0 所以 f_0 = sin(0) = 0
    movss xmm0, [f_pi]
    TAYLOR_S                            ; f_N = sin(π)
    subss xmm0, [rbx]
    mulss xmm0, [f_half]
    movss [rbp-44], xmm0

    ; --------------------------------------------------------
    ; 1. 标量版本：逐点 Horner + 累加
    ; --------------------------------------------------------
    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r12, rax                        ; 计时起点

    pxor xmm7, xmm7
    xor ecx, ecx
.sloop:
    movss xmm0, [rbx + rcx*4]
    TAYLOR_S                            ; 内联展开，没有函数调用
    addss xmm7, xmm0
    inc ecx
    cmp ecx, N
    jb .sloop                           ; i = 0 … N-1

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r12
    mov r12, rax
    movss [rbp-32], xmm7

    ; --------------------------------------------------------
    ; 2. SIMD 版本：同样的 Horner，一次 4 个
    ;    先把 9 个系数广播到 4 条通道（AVX2 里是 vbroadcastss 一条）
    ; --------------------------------------------------------
    movss xmm4,  [t_c0]
    shufps xmm4,  xmm4,  0              ; imm8=0 -> 4 条通道都取通道 0
    movss xmm5,  [t_c1]
    shufps xmm5,  xmm5,  0
    movss xmm6,  [t_c2]
    shufps xmm6,  xmm6,  0
    movss xmm8,  [t_c3]
    shufps xmm8,  xmm8,  0
    movss xmm9,  [t_c4]
    shufps xmm9,  xmm9,  0
    movss xmm10, [t_c5]
    shufps xmm10, xmm10, 0
    movss xmm11, [t_c6]
    shufps xmm11, xmm11, 0
    movss xmm12, [t_c7]
    shufps xmm12, xmm12, 0
    movss xmm13, [t_c8]
    shufps xmm13, xmm13, 0

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r13, rax

    pxor xmm3, xmm3
    xor ecx, ecx
.vloop:
    movups xmm0, [rbx + rcx*4]          ; x[i..i+3]
    TAYLOR_V                            ; 内联展开
    addps  xmm3, xmm0                   ; 4 路累加
    add ecx, 4
    cmp ecx, N
    jb .vloop

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r13
    mov r13, rax

    ; 水平归约：4 条通道求和
    movaps xmm0, xmm3
    shufps xmm0, xmm0, 0x4E             ; [2,3,0,1]
    addps  xmm3, xmm0
    movaps xmm0, xmm3
    shufps xmm0, xmm0, 0xB1             ; [1,0,3,2]
    addps  xmm3, xmm0
    movss  [rbp-40], xmm3

    ; --------------------------------------------------------
    ; 3. 输出
    ; --------------------------------------------------------
    lea rdi, [fmt_hdr]
    xor eax, eax
    call _printf

    lea rdi, [fmt_parm]
    mov esi, N
    movsd xmm0, [d_h]
    mov eax, 1
    call _printf

    ; 标量结果 = h · (Σ标量 + corr)
    movss xmm0, [rbp-32]
    addss xmm0, [rbp-44]
    mulss xmm0, [f_h]
    cvtss2sd xmm0, xmm0
    movsd xmm1, [d_two]
    subsd xmm1, xmm0                    ; 误差 = 2.0 − 结果
    lea rdi, [fmt_scal]
    mov eax, 2
    call _printf

    ; 向量结果 = h · (Σ向量 + corr)
    movss xmm0, [rbp-40]
    addss xmm0, [rbp-44]
    mulss xmm0, [f_h]
    cvtss2sd xmm0, xmm0
    movsd xmm1, [d_two]
    subsd xmm1, xmm0
    lea rdi, [fmt_vec]
    mov eax, 2
    call _printf

    ; 理论截断误差 πh²/12
    movsd xmm0, [d_h]
    mulsd xmm0, xmm0
    mulsd xmm0, [d_pi]
    movsd xmm1, [d_twelve]
    divsd xmm0, xmm1
    lea rdi, [fmt_exact]
    mov eax, 1
    call _printf

    lea rdi, [fmt_time]
    mov rsi, r12
    mov rdx, r13
    xor eax, eax
    call _printf

    cvtsi2sd xmm0, r12
    cvtsi2sd xmm1, r13
    divsd xmm0, xmm1
    lea rdi, [fmt_speed]
    mov eax, 1
    call _printf

    lea rdi, [fmt_done]
    xor eax, eax
    call _printf

    mov rbx, [rbp-8]
    mov r12, [rbp-16]
    mov r13, [rbp-24]
    xor eax, eax
    leave
    ret
