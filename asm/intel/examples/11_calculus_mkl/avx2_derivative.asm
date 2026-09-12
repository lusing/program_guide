; ============================================================
; avx2_derivative.asm - AVX2数值微分
; ============================================================
; 中心差分法: f'(x) ≈ (f(x+h) - f(x-h)) / (2h)
; f(x) = sin(x), 解析解 f'(x) = cos(x)
; 区间 [0, 2π], N=1024个采样点
;
; AVX2优化策略:
;   1. 偏移内存加载: 从 f_array+4 和 f_array-4 同时加载8个float
;   2. vsubps并行计算差值
;   3. vbroadcastss广播 1/(2h) 常数
;   4. vmulps并行计算导数
;
; 关键技术: 偏移加载实现有限差分
;   f_forward  = [f[i+1], f[i+2], ..., f[i+8]]  (从 f_array+(i+1)*4 加载)
;   f_backward = [f[i-1], f[i],   ..., f[i+6]]  (从 f_array+(i-1)*4 加载)
;   deriv = (f_forward - f_backward) / (2h)
; ============================================================

default rel

N   equ 1024                      ; 采样点数 (8的倍数)

section .data
    align 4
    f_two_pi   dd 6.28318530      ; 2π
    f_pi       dd 3.14159265
    f_half     dd 0.5
    f_two      dd 2.0
    f_N_float  dd 1024.0
    f_eight    dd 8.0
    ; Taylor系数 (sin) - 5项
    f_1_6      dd 0.16666667
    f_1_120    dd 0.0083333333
    f_1_5040   dd 0.00019841270
    f_1_362880 dd 0.0000027557319 ; 1/9!
    ; Taylor系数 (cos) - 5项
    f_1_2      dd 0.5             ; 1/2!
    f_1_24     dd 0.041666667     ; 1/4!
    f_1_720    dd 0.0013888889    ; 1/6!
    f_1_40320  dd 0.000024801587  ; 1/8!
    f_one      dd 1.0
    f_zero     dd 0.0
    abs_mask   dq 0x7FFFFFFFFFFFFFFF

    align 8
    temp_d     dq 0.0
    temp_d2    dq 0.0
    temp_f     dd 0.0

    ; 格式字符串
    fmt_header db "=== AVX2数值微分 (中心差分法) ===", 10, 0
    fmt_info   db "f(x) = sin(x),  f'(x) = cos(x),  区间 [0, 2*PI]", 10, 0
    fmt_n      db "采样点 N = %d", 10, 10, 0
    fmt_sep    db "-------------------------------------------", 10, 0
    fmt_samp   db "  x = %.4f  数值导数 = %.6f  解析解 = %.6f  误差 = %.2e", 10, 0
    fmt_scalar db "[标量] 最大误差 = %.2e", 10, 0
    fmt_avx2   db "[AVX2] 最大误差 = %.2e", 10, 0
    fmt_scyc   db "  耗时: %llu cycles", 10, 0
    fmt_acyc   db "  耗时: %llu cycles", 10, 0
    fmt_speed  db 10, "加速比: %.2fx", 10, 0
    fmt_done   db 10, "数值微分演示完成.", 10, 0

section .bss
    alignb 32
    x_array    resd N+1           ; x[0..N]
    f_array    resd N+1           ; sin(x)[0..N]
    d_array    resd N+1           ; 数值导数[0..N]
    alignb 8
    f_h        resd 1             ; 步长 h = 2π/N
    f_inv_2h   resd 1             ; 1/(2h)
    max_err_s  resd 1             ; 标量最大误差
    max_err_a  resd 1             ; AVX2最大误差
    cyc_start  resq 1
    cyc_scalar resq 1
    cyc_avx2   resq 1

section .text
    global main
    extern printf
    extern ExitProcess
    extern sinf
    extern cosf

; ============================================================
; reduce_pi - 将x归约到[-π, π]范围 (利用sin(x+2π)=sin(x))
; 输入: xmm0 = x    输出: xmm0 = x mod (2π), 在[-π, π]范围
; ============================================================
reduce_pi:
    movss xmm1, [f_two_pi]
    divss xmm0, xmm1              ; xmm0 = x / (2π)
    roundsd xmm0, xmm0, 0         ; 四舍五入到最近整数 (round to nearest)
    cvtsd2ss xmm0, xmm0           ; 转回 float
    mulss xmm0, xmm1              ; xmm0 = round(x/(2π)) * 2π
    subss xmm0, xmm0              ; xmm0 = 0 (错误!)
    ret

; 正确版本: reduce x to [-π, π]
; 使用 floor(x/(2π) + 0.5) 实现真正的 round-to-nearest
reduce_pi_correct:
    movss xmm2, xmm0              ; 保存原始x
    movss xmm1, [f_two_pi]
    divss xmm2, xmm1              ; xmm2 = x / (2π)
    ; floor(x/(2π) + 0.5) 实现 round-half-up
    movss xmm3, [f_half]
    addss xmm3, xmm2
    cvttss2si eax, xmm3           ; eax = floor(x/(2π) + 0.5)
    cvtsi2ss xmm3, eax
    mulss xmm3, xmm1              ; xmm3 = round(x/(2π)) * 2π
    subss xmm0, xmm3              ; xmm0 = x - round(x/(2π))*2π
    ret

; ============================================================
; compute_sin - 调用C标准库sinf (高精度)
; 输入: xmm0 = x    输出: xmm0 = sin(x)
; ============================================================
compute_sin:
    sub rsp, 40                   ; 32 shadow + 8 align
    call sinf
    add rsp, 40
    ret

; ============================================================
; compute_cos - 调用C标准库cosf (高精度)
; 输入: xmm0 = x    输出: xmm0 = cos(x)
; ============================================================
compute_cos:
    sub rsp, 40                   ; 32 shadow + 8 align
    call cosf
    add rsp, 40
    ret

; ============================================================
; main
; ============================================================
main:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; --- 打印头部 ---
    lea rcx, [fmt_header]
    call printf
    lea rcx, [fmt_info]
    call printf
    lea rcx, [fmt_n]
    mov edx, N
    call printf

    ; -------------------------------------------------------
    ; 1. 预计算 x[i] 和 f[i] = sin(x[i])
    ; -------------------------------------------------------
    movss xmm0, [f_two_pi]
    divss xmm0, [f_N_float]
    movss [f_h], xmm0             ; h = 2π/N
    ; 1/(2h)
    movss xmm1, [f_two]
    mulss xmm1, [f_h]
    movss xmm0, [f_one]
    divss xmm0, xmm1
    movss [f_inv_2h], xmm0        ; 1/(2h)

    xor r12, r12                  ; i = 0
.precompute:
    cvtsi2ss xmm0, r12d           ; (float)i
    mulss xmm0, [f_h]             ; i * h
    movss [x_array + r12*4], xmm0
    call compute_sin              ; xmm0 = sin(x)
    movss [f_array + r12*4], xmm0
    inc r12
    cmp r12, N
    jle .precompute               ; i = 0..N

    ; -------------------------------------------------------
    ; 2. 标量数值微分 + 误差计算
    ;    deriv[i] = (f[i+1] - f[i-1]) / (2h),  i=1..N-1
    ; -------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov [cyc_start], rax

    movss xmm0, [f_zero]
    movss [max_err_s], xmm0       ; max_error = 0
    mov r12, 1                    ; i = 1

.scalar_loop:
    ; deriv = (f[i+1] - f[i-1]) * (1/2h)
    movss xmm0, [f_array + r12*4 + 4]   ; f[i+1]
    movss xmm1, [f_array + r12*4 - 4]   ; f[i-1]
    subss xmm0, xmm1                    ; f[i+1] - f[i-1]
    mulss xmm0, [f_inv_2h]              ; × 1/(2h)
    movss [d_array + r12*4], xmm0       ; 存储导数

    ; 误差 = |deriv - cos(x[i])|
    movss xmm1, [x_array + r12*4]       ; x[i]
    call compute_cos                    ; xmm0_cos = cos(x[i])
    ; Wait - compute_cos clobbers xmm0! Need to save deriv first.
    ; Actually, let me restructure this.

    ; 保存导数值
    movss xmm2, [d_array + r12*4]       ; xmm2 = deriv
    ; 计算cos(x[i])
    movss xmm0, [x_array + r12*4]       ; xmm0 = x[i]
    call compute_cos                    ; xmm0 = cos(x[i])
    ; 误差 = |deriv - cos|
    subss xmm2, xmm0                    ; deriv - cos
    ; 取绝对值
    movd eax, xmm2
    and eax, 0x7FFFFFFF                 ; 清除符号位 (float)
    movd xmm2, eax                      ; xmm2 = |deriv - cos|
    ; 更新max_error
    movss xmm1, [max_err_s]
    ucomiss xmm2, xmm1
    jbe .skip_max_s
    movss [max_err_s], xmm2
.skip_max_s:

    inc r12
    cmp r12, N
    jl .scalar_loop                     ; i = 1..N-1

    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, [cyc_start]
    mov [cyc_scalar], rax

    ; -------------------------------------------------------
    ; 3. AVX2数值微分
    ;    处理 i=1..N-8 (127组×8=1016个点)
    ;    剩余 i=N-7..N-1 用标量处理
    ; -------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov [cyc_start], rax

    vbroadcastss ymm4, [f_inv_2h]  ; ymm4 = [1/(2h)] × 8
    lea rsi, [f_array + 4]         ; &f[1] (第一组起点)
    lea rdi, [d_array + 4]         ; &d[1]
    mov r12, (N - 1) / 8           ; 127组 (处理i=1..1016)
    ; Wait, (N-1)/8 = 1023/8 = 127.875 -> 127 (integer division)
    ; 127 groups × 8 = 1016 points (i=1..1016)
    ; Remaining: i=1017..1023 (7 points)

    mov r12, 127

.avx2_loop:
    ; 加载 f_forward = [f[i+1], ..., f[i+8]] (偏移+4 from current)
    vmovups ymm0, [rsi + 4]        ; f[i+1..i+8]
    ; 加载 f_backward = [f[i-1], ..., f[i+6]] (偏移-4 from current)
    vmovups ymm1, [rsi - 4]        ; f[i-1..i+6]
    ; 差值
    vsubps ymm0, ymm0, ymm1        ; f_forward - f_backward
    ; 导数 = 差值 × 1/(2h)
    vmulps ymm0, ymm0, ymm4        ; deriv
    ; 存储
    vmovups [rdi], ymm0            ; d[i..i+7] = deriv
    add rsi, 32                    ; 下一组8个float
    add rdi, 32
    dec r12
    jnz .avx2_loop

    ; 标量处理剩余点 i=1017..1023
    mov r12, 1017
.scalar_tail:
    movss xmm0, [f_array + r12*4 + 4]
    movss xmm1, [f_array + r12*4 - 4]
    subss xmm0, xmm1
    mulss xmm0, [f_inv_2h]
    movss [d_array + r12*4], xmm0
    inc r12
    cmp r12, N
    jl .scalar_tail

    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, [cyc_start]
    mov [cyc_avx2], rax

    vzeroupper

    ; -------------------------------------------------------
    ; 4. 计算AVX2版本的最大误差 (遍历d_array对比cos)
    ; -------------------------------------------------------
    movss xmm0, [f_zero]
    movss [max_err_a], xmm0
    mov r12, 1

.err_loop:
    movss xmm2, [d_array + r12*4]       ; deriv
    movss xmm0, [x_array + r12*4]
    call compute_cos                    ; xmm0 = cos(x[i])
    subss xmm2, xmm0
    movd eax, xmm2
    and eax, 0x7FFFFFFF
    movd xmm2, eax
    movss xmm1, [max_err_a]
    ucomiss xmm2, xmm1
    jbe .skip_max_a
    movss [max_err_a], xmm2
.skip_max_a:
    inc r12
    cmp r12, N
    jl .err_loop

    ; -------------------------------------------------------
    ; 5. 打印结果
    ; -------------------------------------------------------
    lea rcx, [fmt_sep]
    call printf

    ; 打印采样点: x=0, π/4, π/2, π, 3π/2
    ; 对应索引: 0, N/8, N/4, N/2, 3N/4
    ; 索引0是边界点(无导数), 从索引1开始
    mov r13, 1                    ; 索引1 (≈x=0)
    call print_sample
    mov r13, 128                  ; N/8 (≈x=π/4)
    call print_sample
    mov r13, 256                  ; N/4 (≈x=π/2)
    call print_sample
    mov r13, 512                  ; N/2 (≈x=π)
    call print_sample
    mov r13, 768                  ; 3N/4 (≈x=3π/2)
    call print_sample

    lea rcx, [fmt_sep]
    call printf

    ; --- 标量最大误差 ---
    movss xmm0, [max_err_s]
    cvtss2sd xmm0, xmm0
    movsd [temp_d], xmm0
    lea rcx, [fmt_scalar]
    mov rdx, [temp_d]
    movsd xmm1, [temp_d]
    call printf
    lea rcx, [fmt_scyc]
    mov rdx, [cyc_scalar]
    call printf

    ; --- AVX2最大误差 ---
    movss xmm0, [max_err_a]
    cvtss2sd xmm0, xmm0
    movsd [temp_d], xmm0
    lea rcx, [fmt_avx2]
    mov rdx, [temp_d]
    movsd xmm1, [temp_d]
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

    lea rcx, [fmt_done]
    call printf

    xor ecx, ecx
    call ExitProcess

; ============================================================
; print_sample - 打印单个采样点
; 输入: r13 = 索引
; 栈布局 (sub rsp, 80):
;   [rsp+0..31]  shadow space
;   [rsp+32..39] 第5参数 (error)
;   [rsp+40..47] x值 (double)
;   [rsp+48..55] 导数值 (double)
;   [rsp+56..63] cos值 (double)
;   [rsp+64..71] error值 (double)
;   [rsp+72..79] unused
; ============================================================
print_sample:
    push rbp
    mov rbp, rsp
    sub rsp, 80                   ; shadow(32) + 5th arg(8) + temps(40)

    ; x值 -> [rsp+40]
    movss xmm0, [x_array + r13*4]
    cvtss2sd xmm0, xmm0
    movsd [rsp+40], xmm0

    ; 数值导数 -> [rsp+48]
    movss xmm0, [d_array + r13*4]
    cvtss2sd xmm0, xmm0
    movsd [rsp+48], xmm0

    ; 解析解 cos(x) -> [rsp+56]
    movss xmm0, [x_array + r13*4]
    call compute_cos
    cvtss2sd xmm0, xmm0
    movsd [rsp+56], xmm0

    ; 误差 = |导数 - cos| -> [rsp+64]
    movsd xmm1, [rsp+48]
    subsd xmm1, [rsp+56]
    vandpd xmm1, xmm1, [abs_mask]  ; AVX版本, 无对齐要求
    movsd [rsp+64], xmm1

    ; printf(fmt, x, deriv, cos, error)
    lea rcx, [fmt_samp]
    mov rdx, [rsp+40]            ; x (int64 bit pattern)
    mov r8, [rsp+48]             ; deriv
    mov r9, [rsp+56]             ; cos
    movsd xmm1, [rsp+40]        ; x (double)
    movsd xmm2, [rsp+48]        ; deriv (double)
    movsd xmm3, [rsp+56]        ; cos (double)
    mov rax, [rsp+64]
    mov [rsp+32], rax            ; 5th arg on stack
    call printf

    leave
    ret
