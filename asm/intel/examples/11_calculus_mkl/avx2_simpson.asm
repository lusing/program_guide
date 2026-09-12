; ============================================================
; avx2_simpson.asm - AVX2辛普森法则数值积分
; ============================================================
; 计算 ∫4/(1+x²)dx, 区间 [0, 1], 精确值 = π ≈ 3.14159
;
; 辛普森1/3法则:
;   ∫f(x)dx ≈ h/3 * [f(x₀) + 4·Σf(x_odd) + 2·Σf(x_even) + f(xₙ)]
;
; AVX2优化策略:
;   1. 向量化函数求值: 用YMM寄存器一次计算8个f(x) = 4/(1+x²)
;   2. 加权向量累加: 用 [4,2,4,2,4,2,4,2] 权重向量并行计算加权和
;   3. FMA优化: vfmadd231ps 同时执行乘法+加法
;
; f(x) = 4/(1+x²) 的向量化计算:
;   ymm_x² = ymm_x * ymm_x
;   ymm_1+x² = ymm_x² + 1.0
;   ymm_f = 4.0 / ymm_1+x²
; ============================================================

default rel

N   equ 1024                      ; 区间数 (必须为偶数, 且为8的倍数)

section .data
    align 4
    f_one      dd 1.0
    f_four     dd 4.0
    f_two_f    dd 2.0
    f_three    dd 3.0
    f_eight    dd 8.0
    f_N_float  dd 1024.0
    f_h        dd 0.0             ; 步长 h = 1/N (运行时计算)
    f_h_over_3 dd 0.0             ; h/3 (运行时计算)
    d_pi       dq 3.14159265358979
    abs_mask   dq 0x7FFFFFFFFFFFFFFF

    align 8
    temp_d     dq 0.0
    temp_d2    dq 0.0

    ; AVX2常量向量 (32字节对齐)
    align 32
    idx_vec    dd 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0  ; 索引向量
    weight_vec dd 4.0, 2.0, 4.0, 2.0, 4.0, 2.0, 4.0, 2.0  ; 辛普森权重

    ; 格式字符串
    fmt_header db "=== AVX2辛普森法则数值积分 ===", 10, 0
    fmt_target db "目标: integral(4/(1+x^2), 0, 1) = PI = 3.141593", 10, 0
    fmt_n      db "区间数 N = %d", 10, 10, 0
    fmt_sep    db "-------------------------------------------", 10, 0
    fmt_scalar db "[标量] 结果 = %.6f  误差 = %.6f", 10, 0
    fmt_avx2   db "[AVX2] 结果 = %.6f  误差 = %.6f", 10, 0
    fmt_scyc   db "  耗时: %llu cycles", 10, 0
    fmt_acyc   db "  耗时: %llu cycles", 10, 0
    fmt_speed  db 10, "加速比: %.2fx", 10, 0
    fmt_done   db 10, "辛普森法则积分演示完成.", 10, 0

section .bss
    alignb 32
    f_array    resd N+1           ; f(x)值数组 [0..N]
    alignb 8
    scalar_res resd 1
    avx2_res   resd 1
    cyc_start  resq 1
    cyc_scalar resq 1
    cyc_avx2   resq 1

section .text
    global main
    extern printf
    extern ExitProcess

; ============================================================
; main
; ============================================================
main:
    push rbp
    mov rbp, rsp
    sub rsp, 64                   ; shadow(32) + locals(32)

    ; --- 打印头部 ---
    lea rcx, [fmt_header]
    call printf
    lea rcx, [fmt_target]
    call printf
    lea rcx, [fmt_n]
    mov edx, N
    call printf

    ; -------------------------------------------------------
    ; 1. 预计算步长和f(x)值数组
    ; -------------------------------------------------------
    ; h = 1.0 / N
    movss xmm0, [f_one]
    divss xmm0, [f_N_float]
    movss [f_h], xmm0
    ; h/3 = h / 3
    divss xmm0, [f_three]
    movss [f_h_over_3], xmm0

    ; --- AVX2向量化预计算 f[0..N-1] (128组×8) ---
    ; x[i] = i * h, f[i] = 4/(1+x[i]²)
    vmovups ymm0, [idx_vec]       ; ymm0 = [0,1,2,3,4,5,6,7] (索引计数器)
    vbroadcastss ymm1, [f_h]      ; ymm1 = [h,h,h,h,h,h,h,h]
    vbroadcastss ymm2, [f_one]    ; ymm2 = [1,1,1,1,1,1,1,1]
    vbroadcastss ymm3, [f_four]   ; ymm3 = [4,4,4,4,4,4,4,4]
    vbroadcastss ymm8, [f_eight]  ; ymm8 = [8,8,8,8,8,8,8,8]

    lea rsi, [f_array]
    mov r12, N / 8                ; 128组

.precompute_avx2:
    ; x = index * h
    vmulps ymm4, ymm0, ymm1       ; ymm4 = x[i..i+7]
    ; f(x) = 4 / (1 + x²)
    vmulps ymm5, ymm4, ymm4       ; ymm5 = x²
    vaddps ymm5, ymm5, ymm2       ; ymm5 = 1 + x²
    vdivps ymm5, ymm3, ymm5       ; ymm5 = 4 / (1+x²) = f(x)
    vmovups [rsi], ymm5           ; 存储8个f值
    ; 索引计数器 += 8
    vaddps ymm0, ymm0, ymm8
    add rsi, 32
    dec r12
    jnz .precompute_avx2

    ; 标量计算最后一个点 f[N]
    ; x[N] = N * h = 1.0
    ; f(1.0) = 4/(1+1) = 2.0
    movss xmm0, [f_two_f]
    movss [f_array + N*4], xmm0   ; f[N] = 2.0

    ; -------------------------------------------------------
    ; 2. 标量辛普森积分
    ;    result = h/3 * (f[0] + 4·Σf(odd) + 2·Σf(even) + f[N])
    ; -------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov [cyc_start], rax

    ; 累加器 = f[0]
    movss xmm0, [f_array]
    movss [rsp+32], xmm0

    mov r12, 1                    ; i = 1
.scalar_loop:
    movss xmm0, [f_array + r12*4]
    test r12, 1                   ; 奇偶检测
    jz .even_idx
    ; 奇数索引: 权重 = 4
    mulss xmm0, [f_four]
    jmp .accumulate
.even_idx:
    ; 偶数索引: 权重 = 2
    mulss xmm0, [f_two_f]
.accumulate:
    addss xmm0, [rsp+32]
    movss [rsp+32], xmm0
    inc r12
    cmp r12, N
    jl .scalar_loop               ; i = 1..N-1

    ; 加 f[N], 乘 h/3
    movss xmm0, [f_array + N*4]
    addss xmm0, [rsp+32]
    mulss xmm0, [f_h_over_3]
    movss [scalar_res], xmm0

    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, [cyc_start]
    mov [cyc_scalar], rax

    ; -------------------------------------------------------
    ; 3. AVX2辛普森积分
    ;    策略: 处理 f[1..N] (1024个值 = 128组×8)
    ;    权重向量 = [4,2,4,2,4,2,4,2]
    ;    result = h/3 * (f[0] + Σ(f[i]·w[i]) - f[N])
    ;    (f[N]多算了1倍权重, 需减去)
    ; -------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov [cyc_start], rax

    vxorps ymm0, ymm0, ymm0       ; 累加器 = 0
    vmovups ymm7, [weight_vec]    ; 权重向量 [4,2,4,2,4,2,4,2]
    lea rsi, [f_array + 4]        ; &f[1]
    mov r12, N / 8                ; 128组

.avx2_loop:
    vmovups ymm1, [rsi]           ; 加载8个f值: f[i..i+7]
    ; 使用FMA: ymm0 += ymm1 * ymm7
    vfmadd231ps ymm0, ymm1, ymm7  ; ymm0 = ymm0 + ymm1 * ymm7
    add rsi, 32
    dec r12
    jnz .avx2_loop

    ; 水平求和 ymm0(8 floats) -> xmm0[0]
    vextractf128 xmm1, ymm0, 1    ; 提取高128位
    vaddps xmm0, xmm0, xmm1       ; [s0+s4, s1+s5, s2+s6, s3+s7]
    vhaddps xmm0, xmm0, xmm0      ; [s0+s1+s4+s5, s2+s3+s6+s7, ...]
    vhaddps xmm0, xmm0, xmm0      ; [总和, ...]

    ; result = h/3 * (f[0] + weighted_sum - f[N])
    movss xmm1, [f_array]         ; f[0]
    addss xmm0, xmm1              ; + f[0]
    movss xmm1, [f_array + N*4]   ; f[N]
    subss xmm0, xmm1              ; - f[N] (修正端点权重)
    mulss xmm0, [f_h_over_3]      ; × h/3
    movss [avx2_res], xmm0

    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, [cyc_start]
    mov [cyc_avx2], rax

    vzeroupper                    ; 清除YMM高位

    ; -------------------------------------------------------
    ; 4. 打印结果
    ; -------------------------------------------------------
    lea rcx, [fmt_sep]
    call printf

    ; --- 标量结果 ---
    movss xmm0, [scalar_res]
    cvtss2sd xmm0, xmm0
    movsd [temp_d], xmm0
    subsd xmm0, [d_pi]            ; result - π
    vandpd xmm0, xmm0, [abs_mask] ; |result - π| (AVX, 无对齐要求)
    movsd [temp_d2], xmm0

    lea rcx, [fmt_scalar]
    mov rdx, [temp_d]
    mov r8, [temp_d2]
    movsd xmm1, [temp_d]
    movsd xmm2, [temp_d2]
    call printf

    lea rcx, [fmt_scyc]
    mov rdx, [cyc_scalar]
    call printf

    ; --- AVX2结果 ---
    movss xmm0, [avx2_res]
    cvtss2sd xmm0, xmm0
    movsd [temp_d], xmm0
    subsd xmm0, [d_pi]
    vandpd xmm0, xmm0, [abs_mask]
    movsd [temp_d2], xmm0

    lea rcx, [fmt_avx2]
    mov rdx, [temp_d]
    mov r8, [temp_d2]
    movsd xmm1, [temp_d]
    movsd xmm2, [temp_d2]
    call printf

    lea rcx, [fmt_acyc]
    mov rdx, [cyc_avx2]
    call printf

    ; --- 加速比 ---
    mov rax, [cyc_scalar]
    cvtsi2sd xmm0, rax
    mov rax, [cyc_avx2]
    cvtsi2sd xmm1, rax
    divsd xmm0, xmm1
    movsd [temp_d], xmm0

    lea rcx, [fmt_speed]
    mov rdx, [temp_d]
    movsd xmm1, [temp_d]
    call printf

    ; --- 完成 ---
    lea rcx, [fmt_done]
    call printf

    xor ecx, ecx
    call ExitProcess
