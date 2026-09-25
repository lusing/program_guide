	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */
.set N, 1024
	# %define N 1024

.data
	.align 8
d_pi: .double 3.141592653589793
d_h: .double 0.0009765625	# h = 1/N，正好是 2 的幂

	.align 16
v_one: .float 1.0, 1.0, 1.0, 1.0
v_four: .float 4.0, 4.0, 4.0, 4.0
v_h: .float 0.0009765625, 0.0009765625, 0.0009765625, 0.0009765625
v_step: .float 4.0, 4.0, 4.0, 4.0	# 每轮下标前进 4
v_idx0: .float 1.0, 2.0, 3.0, 4.0	# 起始下标（从奇数 1 开始）
v_wgt: .float 4.0, 2.0, 4.0, 2.0	# 交错权重，整例的核心

	.align 4
f_one: .float 1.0
f_two: .float 2.0
f_three: .float 3.0
f_four: .float 4.0
f_half: .float 0.5
f_h: .float 0.0009765625

fmt_hdr: .string "=== 辛普森法则向量化：∫₀¹ 4/(1+x²) dx = π ===\n"
fmt_parm: .string "N = %d 个区间（必须偶数），h = 1/N = %.10f\n"
fmt_smpl: .string "  抽查 f(x)=4/(1+x²)： f(0)=%f  f(0.5)=%f  f(1)=%f\n"
fmt_res: .string "向量版积分结果 = %.9f\n"
fmt_exact: .string "精确值 π = %.9f，绝对误差 = %.9f\n"
fmt_note: .string "权重向量 [4,2,4,2] 从奇数下标起步，循环里一条奇偶判断都没有；\n"
fmt_note2: .string "主循环吃完 i=1..1020（255 组），尾巴 i=1021..1023 用标量收。\n"
fmt_done: .string "SIMD Simpson demo completed.\n"


.text

# ------------------------------------------------------------
# f4 —— 标量算 f(x) = 4/(1+x²)
# 入口：xmm0 = x
# 出口：xmm0 = 4/(1+x²)
# ------------------------------------------------------------
f4:
    movss	%xmm0, %xmm1
    mulss	%xmm1, %xmm1	# x²
    addss	f_one(%rip), %xmm1	# 1 + x²
    movss	f_four(%rip), %xmm0
    divss	%xmm1, %xmm0	# 4 / (1+x²)
    ret

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$48, %rsp
# [rbp-8]  = 向量部分加权和
# [rbp-16] = 标量尾巴加权和
# [rbp-24] = 最终结果
# [rbp-32] / [rbp-40] / [rbp-48] = 抽查值 f(0) / f(0.5) / f(1)
# —— 必须落栈，不能留在 xmm4~xmm6 里：那是调用者保存寄存器，
# 中间夹的那两次 printf 会把它们冲掉（这里踩过一次）。

# --------------------------------------------------------
# 1. 抽查三次函数求值，先把 f 本身验证对
# --------------------------------------------------------
    pxor	%xmm0, %xmm0	# f(0)
    call	f4
    cvtss2sd	%xmm0, %xmm0
    movsd	%xmm0, -32(%rbp)

    movss	f_half(%rip), %xmm0	# f(0.5)
    call	f4
    cvtss2sd	%xmm0, %xmm0
    movsd	%xmm0, -40(%rbp)

    movss	f_one(%rip), %xmm0	# f(1)
    call	f4
    cvtss2sd	%xmm0, %xmm0
    movsd	%xmm0, -48(%rbp)

    leaq	fmt_hdr(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_parm(%rip), %rdi
    movl	$N, %esi
    movsd	d_h(%rip), %xmm0
    movl	$1, %eax
    call	printf

    movsd	-32(%rbp), %xmm0
    movsd	-40(%rbp), %xmm1
    movsd	-48(%rbp), %xmm2
    leaq	fmt_smpl(%rip), %rdi
    movl	$3, %eax
    call	printf

# --------------------------------------------------------
# 2. 向量化加权求和
# 常数向量先装好：1、4、h、步长 4、交错权重
# --------------------------------------------------------
    movaps	v_one(%rip), %xmm4
    movaps	v_four(%rip), %xmm5
    movaps	v_h(%rip), %xmm6
    movaps	v_step(%rip), %xmm8
    movaps	v_wgt(%rip), %xmm9
    movaps	v_idx0(%rip), %xmm10	# idx = [1,2,3,4]
    pxor	%xmm3, %xmm3	# 加权累加器

    xorl	%ecx, %ecx	# 已处理点数
.L_mainvloop:
    movaps	%xmm10, %xmm0
    mulps	%xmm6, %xmm0	# x = idx · h
    movaps	%xmm0, %xmm1
    mulps	%xmm1, %xmm1	# x²
    addps	%xmm4, %xmm1	# 1 + x²
    movaps	%xmm5, %xmm2
    divps	%xmm1, %xmm2	# f = 4 / (1+x²)   ← 4 路并行除法
    mulps	%xmm9, %xmm2	# × 交错权重 [4,2,4,2]
    addps	%xmm2, %xmm3	# 累加
    addps	%xmm8, %xmm10	# idx += 4
    addl	$4, %ecx
    cmpl	$N - 4, %ecx	# 处理 i = 1..1020
    jb	.L_mainvloop

# 水平归约
    movaps	%xmm3, %xmm0
    shufps	$0x4E, %xmm0, %xmm0	# [2,3,0,1]
    addps	%xmm0, %xmm3
    movaps	%xmm3, %xmm0
    shufps	$0xB1, %xmm0, %xmm0	# [1,0,3,2]
    addps	%xmm0, %xmm3
    movss	%xmm3, -8(%rbp)

# --------------------------------------------------------
# 3. 尾巴 i = 1021,1022,1023：凑不满一组，老实标量
# 奇数下标权重 4，偶数权重 2
# --------------------------------------------------------
    pxor	%xmm7, %xmm7
    movl	$N - 3, %ecx	# 1021
.L_maintail:
    cvtsi2ss	%ecx, %xmm0
    mulss	f_h(%rip), %xmm0
    call	f4
    testl	$1, %ecx
    jnz	.L_mainw4
    mulss	f_two(%rip), %xmm0
    jmp	.L_mainacc
.L_mainw4:
    mulss	f_four(%rip), %xmm0
.L_mainacc:
    addss	%xmm0, %xmm7
    incl	%ecx
    cmpl	$N - 1, %ecx	# 1023
    jbe	.L_maintail
    movss	%xmm7, -16(%rbp)

# --------------------------------------------------------
# 4. 合起来： result = h/3 · ( f₀ + f_N + Σ加权 )
# f₀ = f(0) = 4，f_N = f(1) = 2，直接用抽查时算好的值
# 这里重新算一遍，免得依赖前面的寄存器存活情况
# --------------------------------------------------------
    pxor	%xmm0, %xmm0
    call	f4	# f₀
    movss	%xmm0, %xmm4
    movss	f_one(%rip), %xmm0
    call	f4	# f_N
    addss	%xmm4, %xmm0	# f₀ + f_N
    addss	-8(%rbp), %xmm0	# + 向量加权和
    addss	-16(%rbp), %xmm0	# + 尾巴加权和
    mulss	f_h(%rip), %xmm0
    divss	f_three(%rip), %xmm0	# × h/3

    movss	%xmm0, -24(%rbp)

# --------------------------------------------------------
# 5. 输出
# --------------------------------------------------------
    movss	-24(%rbp), %xmm0
    cvtss2sd	%xmm0, %xmm0
    leaq	fmt_res(%rip), %rdi
    movl	$1, %eax
    call	printf

    movss	-24(%rbp), %xmm0
    cvtss2sd	%xmm0, %xmm0
    movsd	d_pi(%rip), %xmm1
    subsd	%xmm0, %xmm1	# xmm1 = π − 结果 = 绝对误差
    movsd	%xmm1, %xmm2	# 先存误差，再把 π 装回 xmm0
    movsd	d_pi(%rip), %xmm0
    movapd	%xmm2, %xmm1
    leaq	fmt_exact(%rip), %rdi
    movl	$2, %eax
    call	printf

    leaq	fmt_note(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_note2(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
