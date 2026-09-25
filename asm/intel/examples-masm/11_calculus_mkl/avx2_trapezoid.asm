; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
N   equ 1024                      ; 积分区间数 (8的倍数)
extern printf : PROC
extern ExitProcess : PROC

.data
    align 4
    f_pi        DWORD 3.14159265
    f_N_float   DWORD 1024.0
    f_1_6       DWORD 0.16666667     ; 1/3! = 1/6
    f_1_120     DWORD 0.0083333333   ; 1/5! = 1/120
    f_1_5040    DWORD 0.00019841270  ; 1/7! = 1/5040
    f_half      DWORD 0.5
    d_two       REAL8 2.0
    abs_mask    QWORD 7FFFFFFFFFFFFFFFh  ; 清除符号位

    align 8
    temp_d      REAL8 0.0
    temp_d2     REAL8 0.0

    fmt_header  BYTE "=== AVX2梯形法数值积分 ===", 10, 0
    fmt_target  BYTE "目标: integral(sin(x), 0, PI) = 2.000000", 10, 0
    fmt_n       BYTE "区间数 N = %d", 10, 10, 0
    fmt_sep     BYTE "-------------------------------------------", 10, 0
    fmt_scalar  BYTE "[标量] 结果 = %.6f  误差 = %.6f", 10, 0
    fmt_avx2    BYTE "[AVX2] 结果 = %.6f  误差 = %.6f", 10, 0
    fmt_scyc    BYTE "  耗时: %llu cycles", 10, 0
    fmt_acyc    BYTE "  耗时: %llu cycles", 10, 0
    fmt_speed   BYTE 10, "加速比: %.2fx", 10, 0
    fmt_done    BYTE 10, "梯形法积分演示完成.", 10, 0


avxbss SEGMENT ALIGN(32) 'DATA'
    ; (align satisfied by SEGMENT ALIGN)
    x_array     DWORD N+1 DUP(?); x[0..N]
    f_array     DWORD N+1 DUP(?); f(x)=sin(x)[0..N]
    ALIGN 8
    f_h           DWORD 1 DUP(?); 步长 h = π/N
    scalar_res    DWORD 1 DUP(?); 标量积分结果
    avx2_res      DWORD 1 DUP(?); AVX2积分结果
    cyc_start     QWORD 1 DUP(?); RDTSC起始值
    cyc_scalar    QWORD 1 DUP(?); 标量耗时(cycles)
    cyc_avx2      QWORD 1 DUP(?); AVX2耗时(cycles)

avxbss ENDS

.code

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
    mulss xmm2, DWORD PTR [f_1_6]           ; xmm2 = x³/6
    mulss xmm3, DWORD PTR [f_1_120]         ; xmm3 = x⁵/120
    mulss xmm4, DWORD PTR [f_1_5040]        ; xmm4 = x⁷/5040
    ; 求和: x - x³/6 + x⁵/120 - x⁷/5040
    subss xmm0, xmm2
    addss xmm0, xmm3
    subss xmm0, xmm4
    ret

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
    ; 1. 预计算 x[i] 和 f[i] = sin(x[i])
    ;    x[i] = i * h, h = π/N
    ; -------------------------------------------------------
    movss xmm0, DWORD PTR [f_pi]
    divss xmm0, DWORD PTR [f_N_float]
    movss DWORD PTR [f_h], xmm0             ; h = π/N

    xor r12, r12                  ; i = 0
mainprecompute:
    ; x[i] = i * h
    cvtsi2ss xmm0, r12d           ; xmm0 = (float)i
    mulss xmm0, DWORD PTR [f_h]             ; xmm0 = i * h
    movss DWORD PTR [x_array+ r12*4], xmm0
    ; f[i] = sin(x[i])
    call compute_sin_scalar       ; xmm0 = sin(xXMMWORD PTR [i])
    movss DWORD PTR [f_array+ r12*4], xmm0
    inc r12
    cmp r12, N
    jle mainprecompute               ; i = 0..N (含端点, 共N+1个点)

    ; -------------------------------------------------------
    ; 2. 标量梯形法积分
    ;    result = h * (0.5*f[0] + Σf[1..N-1] + 0.5*f[N])
    ; -------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov QWORD PTR [cyc_start], rax

    ; 累加器初始化 = 0.5 * f[0]
    movss xmm0, DWORD PTR [f_half]
    mulss xmm0, DWORD PTR [f_array]
    movss DWORD PTR [rsp+32], xmm0          ; local accumulator

    mov r12, 1                    ; i = 1
mainscalar_loop:
    movss xmm0, DWORD PTR [rsp+32]
    addss xmm0, DWORD PTR [f_array+ r12*4]
    movss DWORD PTR [rsp+32], xmm0
    inc r12
    cmp r12, N
    jl mainscalar_loop               ; i = 1..N-1

    ; 加 0.5*f[N], 乘 h
    movss xmm0, DWORD PTR [f_half]
    mulss xmm0, DWORD PTR [f_array+ N*4]
    addss xmm0, DWORD PTR [rsp+32]
    mulss xmm0, DWORD PTR [f_h]
    movss DWORD PTR [scalar_res], xmm0

    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, QWORD PTR [cyc_start]
    mov QWORD PTR [cyc_scalar], rax

    ; -------------------------------------------------------
    ; 3. AVX2梯形法积分
    ;    策略: 用AVX2累加 f[0..N-1] (1024个=128组×8),
    ;    然后: result = h * (Σ - 0.5*f[0] + 0.5*f[N])
    ; -------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov QWORD PTR [cyc_start], rax

    vxorps ymm0, ymm0, ymm0       ; 累加器 = 0
    lea rsi, f_array
    mov r12, N / 8                ; 128次迭代

mainavx2_loop:
    vaddps ymm0, ymm0, YMMWORD PTR [rsi]      ; 累加8个float (直接从内存)
    add rsi, 32                   ; 指向下一组8个float
    dec r12
    jnz mainavx2_loop

    ; 水平求和 ymm0(8个float) -> xmm0[0]
    vextractf128 xmm1, ymm0, 1    ; 提取高128位到xmm1
    vaddps xmm0, xmm0, xmm1       ; xmm0 = XMMWORD PTR [s0+s4, s1+s5, s2+s6, s3+s7]
    vhaddps xmm0, xmm0, xmm0      ; XMMWORD PTR [s0+s1+s4+s5, s2+s3+s6+s7, ...]
    vhaddps xmm0, xmm0, xmm0      ; [总和, ...]

    ; 调整边界: 减去 0.5*f[0], 加上 0.5*f[N]
    movss xmm1, DWORD PTR [f_half]
    mulss xmm1, DWORD PTR [f_array]         ; 0.5*fDWORD PTR [0]
    subss xmm0, xmm1
    movss xmm1, DWORD PTR [f_half]
    mulss xmm1, DWORD PTR [f_array+ N*4]   ; 0.5*fDWORD PTR [N]
    addss xmm0, xmm1
    mulss xmm0, DWORD PTR [f_h]             ; × h
    movss DWORD PTR [avx2_res], xmm0

    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, QWORD PTR [cyc_start]
    mov QWORD PTR [cyc_avx2], rax

    vzeroupper                    ; 清除YMM高位, 避免AVX-SSE转换惩罚

    ; -------------------------------------------------------
    ; 4. 打印结果
    ; -------------------------------------------------------
    lea rcx, fmt_sep
    call printf

    ; --- 标量结果 ---
    movss xmm0, DWORD PTR [scalar_res]
    cvtss2sd xmm0, xmm0           ; float -> double
    movsd QWORD PTR [temp_d], xmm0          ; 保存结果
    subsd xmm0, QWORD PTR [d_two]           ; result - 2.0
    vandpd xmm0, xmm0, XMMWORD PTR [abs_mask] ; |result - 2.0| (AVX, 无对齐要求)
    movsd QWORD PTR [temp_d2], xmm0         ; 保存误差

    lea rcx, fmt_scalar
    mov rdx, QWORD PTR [temp_d]
    mov r8, QWORD PTR [temp_d2]
    movsd xmm1, QWORD PTR [temp_d]
    movsd xmm2, QWORD PTR [temp_d2]
    call printf

    ; 标量耗时
    lea rcx, fmt_scyc
    mov rdx, QWORD PTR [cyc_scalar]
    call printf

    ; --- AVX2结果 ---
    movss xmm0, DWORD PTR [avx2_res]
    cvtss2sd xmm0, xmm0
    movsd QWORD PTR [temp_d], xmm0
    subsd xmm0, QWORD PTR [d_two]
    vandpd xmm0, xmm0, XMMWORD PTR [abs_mask]
    movsd QWORD PTR [temp_d2], xmm0

    lea rcx, fmt_avx2
    mov rdx, QWORD PTR [temp_d]
    mov r8, QWORD PTR [temp_d2]
    movsd xmm1, QWORD PTR [temp_d]
    movsd xmm2, QWORD PTR [temp_d2]
    call printf

    ; AVX2耗时
    lea rcx, fmt_acyc
    mov rdx, QWORD PTR [cyc_avx2]
    call printf

    ; --- 加速比 ---
    mov rax, QWORD PTR [cyc_scalar]
    cvtsi2sd xmm0, rax            ; (double)scalar_cycles
    mov rax, QWORD PTR [cyc_avx2]
    cvtsi2sd xmm1, rax            ; (double)avx2_cycles
    divsd xmm0, xmm1              ; speedup = scalar / avx2
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
