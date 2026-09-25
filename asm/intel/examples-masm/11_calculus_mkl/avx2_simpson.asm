; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
N   equ 1024                      ; 区间数 (必须为偶数, 且为8的倍数)
extern printf : PROC
extern ExitProcess : PROC

avxdata SEGMENT ALIGN(32) 'DATA'
    align 4
    f_one      DWORD 1.0
    f_four     DWORD 4.0
    f_two_f    DWORD 2.0
    f_three    DWORD 3.0
    f_eight    DWORD 8.0
    f_N_float  DWORD 1024.0
    f_h        DWORD 0.0             ; 步长 h = 1/N (运行时计算)
    f_h_over_3 DWORD 0.0             ; h/3 (运行时计算)
    d_pi       REAL8 3.14159265358979
    abs_mask   QWORD 7FFFFFFFFFFFFFFFh

    align 8
    temp_d     REAL8 0.0
    temp_d2    REAL8 0.0

    ; AVX2常量向量 (32字节对齐)
    ; (align satisfied by SEGMENT ALIGN)
    idx_vec    DWORD 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0  ; 索引向量
    weight_vec DWORD 4.0, 2.0, 4.0, 2.0, 4.0, 2.0, 4.0, 2.0  ; 辛普森权重

    ; 格式字符串
    fmt_header BYTE "=== AVX2辛普森法则数值积分 ===", 10, 0
    fmt_target BYTE "目标: integral(4/(1+x^2), 0, 1) = PI = 3.141593", 10, 0
    fmt_n      BYTE "区间数 N = %d", 10, 10, 0
    fmt_sep    BYTE "-------------------------------------------", 10, 0
    fmt_scalar BYTE "[标量] 结果 = %.6f  误差 = %.6f", 10, 0
    fmt_avx2   BYTE "[AVX2] 结果 = %.6f  误差 = %.6f", 10, 0
    fmt_scyc   BYTE "  耗时: %llu cycles", 10, 0
    fmt_acyc   BYTE "  耗时: %llu cycles", 10, 0
    fmt_speed  BYTE 10, "加速比: %.2fx", 10, 0
    fmt_done   BYTE 10, "辛普森法则积分演示完成.", 10, 0

avxdata ENDS

avxbss SEGMENT ALIGN(32) 'DATA'
    ; (align satisfied by SEGMENT ALIGN)
    f_array    DWORD N+1 DUP(?); f(x)值数组 [0..N]
    ALIGN 8
    scalar_res DWORD 1 DUP(?)
    avx2_res   DWORD 1 DUP(?)
    cyc_start  QWORD 1 DUP(?)
    cyc_scalar QWORD 1 DUP(?)
    cyc_avx2   QWORD 1 DUP(?)

avxbss ENDS

.code

; ============================================================
; main
; ============================================================
main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 64                   ; shadow(32) + locals(32)

    ; --- 打印头部 ---
    lea rcx, fmt_header
    call printf
    lea rcx, fmt_target
    call printf
    lea rcx, fmt_n
    mov edx, N
    call printf

    ; -------------------------------------------------------
    ; 1. 预计算步长和f(x)值数组
    ; -------------------------------------------------------
    ; h = 1.0 / N
    movss xmm0, DWORD PTR [f_one]
    divss xmm0, DWORD PTR [f_N_float]
    movss DWORD PTR [f_h], xmm0
    ; h/3 = h / 3
    divss xmm0, DWORD PTR [f_three]
    movss DWORD PTR [f_h_over_3], xmm0

    ; --- AVX2向量化预计算 f[0..N-1] (128组×8) ---
    ; x[i] = i * h, f[i] = 4/(1+x[i]²)
    vmovups ymm0, YMMWORD PTR [idx_vec]       ; ymm0 = [0,1,2,3,4,5,6,7] (索引计数器)
    vbroadcastss ymm1, DWORD PTR [f_h]      ; ymm1 = [h,h,h,h,h,h,h,h]
    vbroadcastss ymm2, DWORD PTR [f_one]    ; ymm2 = [1,1,1,1,1,1,1,1]
    vbroadcastss ymm3, DWORD PTR [f_four]   ; ymm3 = [4,4,4,4,4,4,4,4]
    vbroadcastss ymm8, DWORD PTR [f_eight]  ; ymm8 = [8,8,8,8,8,8,8,8]

    lea rsi, f_array
    mov r12, N / 8                ; 128组

mainprecompute_avx2:
    ; x = index * h
    vmulps ymm4, ymm0, ymm1       ; ymm4 = xYMMWORD PTR [i..i+7]
    ; f(x) = 4 / (1 + x²)
    vmulps ymm5, ymm4, ymm4       ; ymm5 = x²
    vaddps ymm5, ymm5, ymm2       ; ymm5 = 1 + x²
    vdivps ymm5, ymm3, ymm5       ; ymm5 = 4 / (1+x²) = f(x)
    vmovups YMMWORD PTR [rsi], ymm5           ; 存储8个f值
    ; 索引计数器 += 8
    vaddps ymm0, ymm0, ymm8
    add rsi, 32
    dec r12
    jnz mainprecompute_avx2

    ; 标量计算最后一个点 f[N]
    ; x[N] = N * h = 1.0
    ; f(1.0) = 4/(1+1) = 2.0
    movss xmm0, DWORD PTR [f_two_f]
    movss DWORD PTR [f_array+ N*4], xmm0   ; fDWORD PTR [N] = 2.0

    ; -------------------------------------------------------
    ; 2. 标量辛普森积分
    ;    result = h/3 * (f[0] + 4·Σf(odd) + 2·Σf(even) + f[N])
    ; -------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov QWORD PTR [cyc_start], rax

    ; 累加器 = f[0]
    movss xmm0, DWORD PTR [f_array]
    movss DWORD PTR [rsp+32], xmm0

    mov r12, 1                    ; i = 1
mainscalar_loop:
    movss xmm0, DWORD PTR [f_array+ r12*4]
    test r12, 1                   ; 奇偶检测
    jz maineven_idx
    ; 奇数索引: 权重 = 4
    mulss xmm0, DWORD PTR [f_four]
    jmp mainaccumulate
maineven_idx:
    ; 偶数索引: 权重 = 2
    mulss xmm0, DWORD PTR [f_two_f]
mainaccumulate:
    addss xmm0, DWORD PTR [rsp+32]
    movss DWORD PTR [rsp+32], xmm0
    inc r12
    cmp r12, N
    jl mainscalar_loop               ; i = 1..N-1

    ; 加 f[N], 乘 h/3
    movss xmm0, DWORD PTR [f_array+ N*4]
    addss xmm0, DWORD PTR [rsp+32]
    mulss xmm0, DWORD PTR [f_h_over_3]
    movss DWORD PTR [scalar_res], xmm0

    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, QWORD PTR [cyc_start]
    mov QWORD PTR [cyc_scalar], rax

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
    mov QWORD PTR [cyc_start], rax

    vxorps ymm0, ymm0, ymm0       ; 累加器 = 0
    vmovups ymm7, YMMWORD PTR [weight_vec]    ; 权重向量 [4,2,4,2,4,2,4,2]
    lea rsi, [f_array + 4]        ;  AND f[1]
    mov r12, N / 8                ; 128组

mainavx2_loop:
    vmovups ymm1, YMMWORD PTR [rsi]           ; 加载8个f值: fYMMWORD PTR [i..i+7]
    ; 使用FMA: ymm0 += ymm1 * ymm7
    vfmadd231ps ymm0, ymm1, ymm7  ; ymm0 = ymm0 + ymm1 * ymm7
    add rsi, 32
    dec r12
    jnz mainavx2_loop

    ; 水平求和 ymm0(8 floats) -> xmm0[0]
    vextractf128 xmm1, ymm0, 1    ; 提取高128位
    vaddps xmm0, xmm0, xmm1       ; XMMWORD PTR [s0+s4, s1+s5, s2+s6, s3+s7]
    vhaddps xmm0, xmm0, xmm0      ; XMMWORD PTR [s0+s1+s4+s5, s2+s3+s6+s7, ...]
    vhaddps xmm0, xmm0, xmm0      ; [总和, ...]

    ; result = h/3 * (f[0] + weighted_sum - f[N])
    movss xmm1, DWORD PTR [f_array]         ; fDWORD PTR [0]
    addss xmm0, xmm1              ; + fDWORD PTR [0]
    movss xmm1, DWORD PTR [f_array+ N*4]   ; fDWORD PTR [N]
    subss xmm0, xmm1              ; - fDWORD PTR [N] (修正端点权重)
    mulss xmm0, DWORD PTR [f_h_over_3]      ; × h/3
    movss DWORD PTR [avx2_res], xmm0

    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, QWORD PTR [cyc_start]
    mov QWORD PTR [cyc_avx2], rax

    vzeroupper                    ; 清除YMM高位

    ; -------------------------------------------------------
    ; 4. 打印结果
    ; -------------------------------------------------------
    lea rcx, fmt_sep
    call printf

    ; --- 标量结果 ---
    movss xmm0, DWORD PTR [scalar_res]
    cvtss2sd xmm0, xmm0
    movsd QWORD PTR [temp_d], xmm0
    subsd xmm0, QWORD PTR [d_pi]            ; result - π
    vandpd xmm0, xmm0, XMMWORD PTR [abs_mask] ; |result - π| (AVX, 无对齐要求)
    movsd QWORD PTR [temp_d2], xmm0

    lea rcx, fmt_scalar
    mov rdx, QWORD PTR [temp_d]
    mov r8, QWORD PTR [temp_d2]
    movsd xmm1, QWORD PTR [temp_d]
    movsd xmm2, QWORD PTR [temp_d2]
    call printf

    lea rcx, fmt_scyc
    mov rdx, QWORD PTR [cyc_scalar]
    call printf

    ; --- AVX2结果 ---
    movss xmm0, DWORD PTR [avx2_res]
    cvtss2sd xmm0, xmm0
    movsd QWORD PTR [temp_d], xmm0
    subsd xmm0, QWORD PTR [d_pi]
    vandpd xmm0, xmm0, XMMWORD PTR [abs_mask]
    movsd QWORD PTR [temp_d2], xmm0

    lea rcx, fmt_avx2
    mov rdx, QWORD PTR [temp_d]
    mov r8, QWORD PTR [temp_d2]
    movsd xmm1, QWORD PTR [temp_d]
    movsd xmm2, QWORD PTR [temp_d2]
    call printf

    lea rcx, fmt_acyc
    mov rdx, QWORD PTR [cyc_avx2]
    call printf

    ; --- 加速比 ---
    mov rax, QWORD PTR [cyc_scalar]
    cvtsi2sd xmm0, rax
    mov rax, QWORD PTR [cyc_avx2]
    cvtsi2sd xmm1, rax
    divsd xmm0, xmm1
    movsd QWORD PTR [temp_d], xmm0

    lea rcx, fmt_speed
    mov rdx, QWORD PTR [temp_d]
    movsd xmm1, QWORD PTR [temp_d]
    call printf

    ; --- 完成 ---
    lea rcx, fmt_done
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
