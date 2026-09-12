; ============================================================
; avx2_trapezoid.asm - AVX2梯形法数值积分
; ============================================================
; 计算 ∫sin(x)dx, 区间 [0, π], 精确值 = 2.0
;
; 演示:
;   1. Taylor级数近似sin(x) - 标量与AVX2向量化对比
;   2. 梯形法数值积分 - 标量循环与AVX2并行求和
;   3. RDTSC指令计时对比性能
;
; 优化要点 (针对i7-12700F AVX2):
;   - YMM寄存器一次处理8个float (256位)
;   - vbroadcastss广播常数到所有lane
;   - vaddps直接从内存累加, 减少寄存器压力
;   - 水平求和技术: vextractf128 + vaddps + vhaddps
; ============================================================

default rel

N   equ 1024                      ; 积分区间数 (8的倍数)

section .data
    align 4
    f_pi        dd 3.14159265
    f_N_float   dd 1024.0
    f_1_6       dd 0.16666667     ; 1/3! = 1/6
    f_1_120     dd 0.0083333333   ; 1/5! = 1/120
    f_1_5040    dd 0.00019841270  ; 1/7! = 1/5040
    f_half      dd 0.5
    d_two       dq 2.0
    abs_mask    dq 0x7FFFFFFFFFFFFFFF  ; 清除符号位

    align 8
    temp_d      dq 0.0
    temp_d2     dq 0.0

    fmt_header  db "=== AVX2梯形法数值积分 ===", 10, 0
    fmt_target  db "目标: integral(sin(x), 0, PI) = 2.000000", 10, 0
    fmt_n       db "区间数 N = %d", 10, 10, 0
    fmt_sep     db "-------------------------------------------", 10, 0
    fmt_scalar  db "[标量] 结果 = %.6f  误差 = %.6f", 10, 0
    fmt_avx2    db "[AVX2] 结果 = %.6f  误差 = %.6f", 10, 0
    fmt_scyc    db "  耗时: %llu cycles", 10, 0
    fmt_acyc    db "  耗时: %llu cycles", 10, 0
    fmt_speed   db 10, "加速比: %.2fx", 10, 0
    fmt_done    db 10, "梯形法积分演示完成.", 10, 0

section .bss
    alignb 32
    x_array     resd N+1          ; x[0..N]
    f_array     resd N+1          ; f(x)=sin(x)[0..N]
    alignb 8
    f_h           resd 1          ; 步长 h = π/N
    scalar_res    resd 1          ; 标量积分结果
    avx2_res      resd 1          ; AVX2积分结果
    cyc_start     resq 1          ; RDTSC起始值
    cyc_scalar    resq 1          ; 标量耗时(cycles)
    cyc_avx2      resq 1          ; AVX2耗时(cycles)

section .text
    global main
    extern printf
    extern ExitProcess

; ============================================================
; compute_sin_scalar - 标量sin(x) Taylor级数近似
; 输入: xmm0 = x (float)
; 输出: xmm0 = sin(x) (float)
; sin(x) ≈ x - x³/3! + x⁵/5! - x⁷/7!
; ============================================================
compute_sin_scalar:
    movss xmm1, xmm0              ; xmm1 = x
    mulss xmm1, xmm0              ; xmm1 = x²
    movss xmm2, xmm1
    mulss xmm2, xmm0              ; xmm2 = x³
    movss xmm3, xmm2
    mulss xmm3, xmm1              ; xmm3 = x⁵
    movss xmm4, xmm3
    mulss xmm4, xmm1              ; xmm4 = x⁷
    ; 乘以系数
    mulss xmm2, [f_1_6]           ; xmm2 = x³/6
    mulss xmm3, [f_1_120]         ; xmm3 = x⁵/120
    mulss xmm4, [f_1_5040]        ; xmm4 = x⁷/5040
    ; 求和: x - x³/6 + x⁵/120 - x⁷/5040
    subss xmm0, xmm2
    addss xmm0, xmm3
    subss xmm0, xmm4
    ret

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
    ; 1. 预计算 x[i] 和 f[i] = sin(x[i])
    ;    x[i] = i * h, h = π/N
    ; -------------------------------------------------------
    movss xmm0, [f_pi]
    divss xmm0, [f_N_float]
    movss [f_h], xmm0             ; h = π/N

    xor r12, r12                  ; i = 0
.precompute:
    ; x[i] = i * h
    cvtsi2ss xmm0, r12d           ; xmm0 = (float)i
    mulss xmm0, [f_h]             ; xmm0 = i * h
    movss [x_array + r12*4], xmm0
    ; f[i] = sin(x[i])
    call compute_sin_scalar       ; xmm0 = sin(x[i])
    movss [f_array + r12*4], xmm0
    inc r12
    cmp r12, N
    jle .precompute               ; i = 0..N (含端点, 共N+1个点)

    ; -------------------------------------------------------
    ; 2. 标量梯形法积分
    ;    result = h * (0.5*f[0] + Σf[1..N-1] + 0.5*f[N])
    ; -------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov [cyc_start], rax

    ; 累加器初始化 = 0.5 * f[0]
    movss xmm0, [f_half]
    mulss xmm0, [f_array]
    movss [rsp+32], xmm0          ; local accumulator

    mov r12, 1                    ; i = 1
.scalar_loop:
    movss xmm0, [rsp+32]
    addss xmm0, [f_array + r12*4]
    movss [rsp+32], xmm0
    inc r12
    cmp r12, N
    jl .scalar_loop               ; i = 1..N-1

    ; 加 0.5*f[N], 乘 h
    movss xmm0, [f_half]
    mulss xmm0, [f_array + N*4]
    addss xmm0, [rsp+32]
    mulss xmm0, [f_h]
    movss [scalar_res], xmm0

    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, [cyc_start]
    mov [cyc_scalar], rax

    ; -------------------------------------------------------
    ; 3. AVX2梯形法积分
    ;    策略: 用AVX2累加 f[0..N-1] (1024个=128组×8),
    ;    然后: result = h * (Σ - 0.5*f[0] + 0.5*f[N])
    ; -------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov [cyc_start], rax

    vxorps ymm0, ymm0, ymm0       ; 累加器 = 0
    lea rsi, [f_array]
    mov r12, N / 8                ; 128次迭代

.avx2_loop:
    vaddps ymm0, ymm0, [rsi]      ; 累加8个float (直接从内存)
    add rsi, 32                   ; 指向下一组8个float
    dec r12
    jnz .avx2_loop

    ; 水平求和 ymm0(8个float) -> xmm0[0]
    vextractf128 xmm1, ymm0, 1    ; 提取高128位到xmm1
    vaddps xmm0, xmm0, xmm1       ; xmm0 = [s0+s4, s1+s5, s2+s6, s3+s7]
    vhaddps xmm0, xmm0, xmm0      ; [s0+s1+s4+s5, s2+s3+s6+s7, ...]
    vhaddps xmm0, xmm0, xmm0      ; [总和, ...]

    ; 调整边界: 减去 0.5*f[0], 加上 0.5*f[N]
    movss xmm1, [f_half]
    mulss xmm1, [f_array]         ; 0.5*f[0]
    subss xmm0, xmm1
    movss xmm1, [f_half]
    mulss xmm1, [f_array + N*4]   ; 0.5*f[N]
    addss xmm0, xmm1
    mulss xmm0, [f_h]             ; × h
    movss [avx2_res], xmm0

    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, [cyc_start]
    mov [cyc_avx2], rax

    vzeroupper                    ; 清除YMM高位, 避免AVX-SSE转换惩罚

    ; -------------------------------------------------------
    ; 4. 打印结果
    ; -------------------------------------------------------
    lea rcx, [fmt_sep]
    call printf

    ; --- 标量结果 ---
    movss xmm0, [scalar_res]
    cvtss2sd xmm0, xmm0           ; float -> double
    movsd [temp_d], xmm0          ; 保存结果
    subsd xmm0, [d_two]           ; result - 2.0
    vandpd xmm0, xmm0, [abs_mask] ; |result - 2.0| (AVX, 无对齐要求)
    movsd [temp_d2], xmm0         ; 保存误差

    lea rcx, [fmt_scalar]
    mov rdx, [temp_d]
    mov r8, [temp_d2]
    movsd xmm1, [temp_d]
    movsd xmm2, [temp_d2]
    call printf

    ; 标量耗时
    lea rcx, [fmt_scyc]
    mov rdx, [cyc_scalar]
    call printf

    ; --- AVX2结果 ---
    movss xmm0, [avx2_res]
    cvtss2sd xmm0, xmm0
    movsd [temp_d], xmm0
    subsd xmm0, [d_two]
    vandpd xmm0, xmm0, [abs_mask]
    movsd [temp_d2], xmm0

    lea rcx, [fmt_avx2]
    mov rdx, [temp_d]
    mov r8, [temp_d2]
    movsd xmm1, [temp_d]
    movsd xmm2, [temp_d2]
    call printf

    ; AVX2耗时
    lea rcx, [fmt_acyc]
    mov rdx, [cyc_avx2]
    call printf

    ; --- 加速比 ---
    mov rax, [cyc_scalar]
    cvtsi2sd xmm0, rax            ; (double)scalar_cycles
    mov rax, [cyc_avx2]
    cvtsi2sd xmm1, rax            ; (double)avx2_cycles
    divsd xmm0, xmm1              ; speedup = scalar / avx2
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
