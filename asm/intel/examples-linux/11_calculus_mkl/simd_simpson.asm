; ============================================================
; 文件: 11_calculus_mkl/simd_simpson.asm                   [Linux 版]
; 指令: MOVUPS / ADDPS / MULPS / DIVPS / SHUFPS
; 描述: 辛普森法则向量化 —— 一个交错的权重向量干掉所有分支
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/11_calculus_mkl/simd_simpson.asm -o build/simd_simpson.o
; 链接: gcc -no-pie build/simd_simpson.o -o build/simd_simpson
; 对照: examples/11_calculus_mkl/avx2_simpson.asm
;
; ★ 移植说明：原版用 AVX2（ymm/8 路，权重 [4,2,4,2,4,2,4,2] + FMA 的 vfmadd231ps）。
;   本机 Ivy Bridge 既没有 AVX2 也没有 FMA，所以：
;     - 通道宽度从 8 降到 4，权重向量变成 [4,2,4,2]
;     - vfmadd231ps（乘加一体）拆成 mulps + addps 两条
;   算法的关键技巧（交错权重）完全保留。
;
; ------------------------------------------------------------
; 问题：∫₀¹ 4/(1+x²) dx = π ≈ 3.14159265（精确值）
;
; 辛普森 1/3 法则（N 必须是偶数）：
;   ∫ ≈ h/3 · [ f₀ + 4·(f₁+f₃+…+f_{N-1}) + 2·(f₂+f₄+…+f_{N-2}) + f_N ]
;
; 朴素做法会在循环里判奇偶、分支、挑系数 —— 向量化的天敌。
; 巧妙之处在于：**把权重做成一常量向量 [4,2,4,2]**，
; 然后从**奇数下标**开始一次吃 4 个点。因为起点是奇数，
; 通道 0 和 2 永远落在奇数下标（权重 4），通道 1 和 3 永远落在
; 偶数下标（权重 2）—— 一次 mulps 就替掉了循环里所有的奇偶判断。
; 这是 SIMD 数值代码里最值得学的一招：**用数据布局换掉控制流**。
;
; 尾部还剩 3 个点（i = 1021,1022,1023）凑不成一组，就老实标量处理 ——
; 真实代码里也常常是「主循环吃整块 + 尾巴单独收」，不必强求。
;
; h = 1/1024 = 0.0009765625，本身是 2 的幂，所以 idx·h 是精确的，
; 不用额外做范围归约或累加误差补偿。
; ============================================================
default rel

%define N 1024

section .data
    align 8
    d_pi     dq 3.141592653589793
    d_h      dq 0.0009765625            ; h = 1/N，正好是 2 的幂

    align 16
    v_one    dd 1.0, 1.0, 1.0, 1.0
    v_four   dd 4.0, 4.0, 4.0, 4.0
    v_h      dd 0.0009765625, 0.0009765625, 0.0009765625, 0.0009765625
    v_step   dd 4.0, 4.0, 4.0, 4.0              ; 每轮下标前进 4
    v_idx0   dd 1.0, 2.0, 3.0, 4.0              ; 起始下标（从奇数 1 开始）
    v_wgt    dd 4.0, 2.0, 4.0, 2.0              ; 交错权重，整例的核心

    align 4
    f_one    dd 1.0
    f_two    dd 2.0
    f_three  dd 3.0
    f_four   dd 4.0
    f_half   dd 0.5
    f_h      dd 0.0009765625

    fmt_hdr   db "=== 辛普森法则向量化：∫₀¹ 4/(1+x²) dx = π ===", 10, 0
    fmt_parm  db "N = %d 个区间（必须偶数），h = 1/N = %.10f", 10, 0
    fmt_smpl  db "  抽查 f(x)=4/(1+x²)： f(0)=%f  f(0.5)=%f  f(1)=%f", 10, 0
    fmt_res   db "向量版积分结果 = %.9f", 10, 0
    fmt_exact db "精确值 π = %.9f，绝对误差 = %.9f", 10, 0
    fmt_note  db "权重向量 [4,2,4,2] 从奇数下标起步，循环里一条奇偶判断都没有；", 10, 0
    fmt_note2 db "主循环吃完 i=1..1020（255 组），尾巴 i=1021..1023 用标量收。", 10, 0
    fmt_done  db "SIMD Simpson demo completed.", 10, 0

section .text
    global main
    extern printf

; ------------------------------------------------------------
; f4 —— 标量算 f(x) = 4/(1+x²)
;   入口：xmm0 = x
;   出口：xmm0 = 4/(1+x²)
; ------------------------------------------------------------
f4:
    movss xmm1, xmm0
    mulss xmm1, xmm1                    ; x²
    addss xmm1, [f_one]                 ; 1 + x²
    movss xmm0, [f_four]
    divss xmm0, xmm1                    ; 4 / (1+x²)
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    ; [rbp-8]  = 向量部分加权和
    ; [rbp-16] = 标量尾巴加权和
    ; [rbp-24] = 最终结果
    ; [rbp-32] / [rbp-40] / [rbp-48] = 抽查值 f(0) / f(0.5) / f(1)
    ;   —— 必须落栈，不能留在 xmm4~xmm6 里：那是调用者保存寄存器，
    ;      中间夹的那两次 printf 会把它们冲掉（这里踩过一次）。

    ; --------------------------------------------------------
    ; 1. 抽查三次函数求值，先把 f 本身验证对
    ; --------------------------------------------------------
    pxor xmm0, xmm0                     ; f(0)
    call f4
    cvtss2sd xmm0, xmm0
    movsd [rbp-32], xmm0

    movss xmm0, [f_half]                ; f(0.5)
    call f4
    cvtss2sd xmm0, xmm0
    movsd [rbp-40], xmm0

    movss xmm0, [f_one]                 ; f(1)
    call f4
    cvtss2sd xmm0, xmm0
    movsd [rbp-48], xmm0

    lea rdi, [fmt_hdr]
    xor eax, eax
    call printf

    lea rdi, [fmt_parm]
    mov esi, N
    movsd xmm0, [d_h]
    mov eax, 1
    call printf

    movsd xmm0, [rbp-32]
    movsd xmm1, [rbp-40]
    movsd xmm2, [rbp-48]
    lea rdi, [fmt_smpl]
    mov eax, 3
    call printf

    ; --------------------------------------------------------
    ; 2. 向量化加权求和
    ;    常数向量先装好：1、4、h、步长 4、交错权重
    ; --------------------------------------------------------
    movaps xmm4, [v_one]
    movaps xmm5, [v_four]
    movaps xmm6, [v_h]
    movaps xmm8, [v_step]
    movaps xmm9, [v_wgt]
    movaps xmm10, [v_idx0]              ; idx = [1,2,3,4]
    pxor xmm3, xmm3                     ; 加权累加器

    xor ecx, ecx                        ; 已处理点数
.vloop:
    movaps xmm0, xmm10
    mulps  xmm0, xmm6                   ; x = idx · h
    movaps xmm1, xmm0
    mulps  xmm1, xmm1                   ; x²
    addps  xmm1, xmm4                   ; 1 + x²
    movaps xmm2, xmm5
    divps  xmm2, xmm1                   ; f = 4 / (1+x²)   ← 4 路并行除法
    mulps  xmm2, xmm9                   ; × 交错权重 [4,2,4,2]
    addps  xmm3, xmm2                   ; 累加
    addps  xmm10, xmm8                  ; idx += 4
    add ecx, 4
    cmp ecx, N - 4                      ; 处理 i = 1..1020
    jb .vloop

    ; 水平归约
    movaps xmm0, xmm3
    shufps xmm0, xmm0, 0x4E             ; [2,3,0,1]
    addps  xmm3, xmm0
    movaps xmm0, xmm3
    shufps xmm0, xmm0, 0xB1             ; [1,0,3,2]
    addps  xmm3, xmm0
    movss  [rbp-8], xmm3

    ; --------------------------------------------------------
    ; 3. 尾巴 i = 1021,1022,1023：凑不满一组，老实标量
    ;    奇数下标权重 4，偶数权重 2
    ; --------------------------------------------------------
    pxor xmm7, xmm7
    mov ecx, N - 3                      ; 1021
.tail:
    cvtsi2ss xmm0, ecx
    mulss xmm0, [f_h]
    call f4
    test ecx, 1
    jnz .w4
    mulss xmm0, [f_two]
    jmp .acc
.w4:
    mulss xmm0, [f_four]
.acc:
    addss xmm7, xmm0
    inc ecx
    cmp ecx, N - 1                      ; 1023
    jbe .tail
    movss [rbp-16], xmm7

    ; --------------------------------------------------------
    ; 4. 合起来： result = h/3 · ( f₀ + f_N + Σ加权 )
    ;    f₀ = f(0) = 4，f_N = f(1) = 2，直接用抽查时算好的值
    ;    这里重新算一遍，免得依赖前面的寄存器存活情况
    ; --------------------------------------------------------
    pxor xmm0, xmm0
    call f4                             ; f₀
    movss xmm4, xmm0
    movss xmm0, [f_one]
    call f4                             ; f_N
    addss xmm0, xmm4                    ; f₀ + f_N
    addss xmm0, [rbp-8]                 ; + 向量加权和
    addss xmm0, [rbp-16]                ; + 尾巴加权和
    mulss xmm0, [f_h]
    divss xmm0, [f_three]               ; × h/3

    movss [rbp-24], xmm0

    ; --------------------------------------------------------
    ; 5. 输出
    ; --------------------------------------------------------
    movss xmm0, [rbp-24]
    cvtss2sd xmm0, xmm0
    lea rdi, [fmt_res]
    mov eax, 1
    call printf

    movss xmm0, [rbp-24]
    cvtss2sd xmm0, xmm0
    movsd xmm1, [d_pi]
    subsd xmm1, xmm0                    ; xmm1 = π − 结果 = 绝对误差
    movsd xmm2, xmm1                    ; 先存误差，再把 π 装回 xmm0
    movsd xmm0, [d_pi]
    movapd xmm1, xmm2
    lea rdi, [fmt_exact]
    mov eax, 2
    call printf

    lea rdi, [fmt_note]
    xor eax, eax
    call printf

    lea rdi, [fmt_note2]
    xor eax, eax
    call printf

    lea rdi, [fmt_done]
    xor eax, eax
    call printf

    xor eax, eax
    leave
    ret
