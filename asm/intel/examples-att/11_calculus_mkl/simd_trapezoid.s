	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */
.set N, 1024
	# %define N 1024

.data
	.align 8
d_pi: .double 3.141592653589793
d_h: .double 0.0	# π/N，运行时算
d_two: .double 2.0
d_twelve: .double 12.0

	.align 4
f_h: .float 0.0
f_pi: .float 3.1415926536
f_half: .float 0.5

# Taylor 系数（float）。向量版要用 shufps 广播到 4 条通道。
t_c0: .float 1.0
t_c1: .float -0.16666666667
t_c2: .float 0.0083333333333
t_c3: .float -0.00019841269841
t_c4: .float 0.0000027557319224
t_c5: .float -0.000000025052108385
t_c6: .float 0.00000000016059043837
t_c7: .float -0.00000000000076471637318
t_c8: .float 0.0000000000000028114572543

fmt_hdr: .string "=== 梯形法积分 ∫sin(x)dx，区间 [0, π] ===\n"
fmt_parm: .string "N = %d 个区间，h = π/N = %.9f\n"
fmt_scal: .string "标量版（mulss/addss）：      %.9f   误差 %.9f\n"
fmt_vec: .string "SIMD 版（mulps/addps 4 路）：%.9f   误差 %.9f\n"
fmt_exact: .string "精确值 = 2.0；梯形法的 O(h²) 截断误差 ≈ πh²/12 = %.9f\n"
fmt_time: .string "耗时：标量 %llu 周期，SIMD %llu 周期\n"
fmt_speed: .string "加速比 ≈ %.2f×（理论上限 4×，实际受循环开销和内存带宽限制）\n"
fmt_done: .string "SIMD trapezoid demo completed.\n"


.bss
	.align 16
x_arr: .zero N+1*4	# x_i = i·h

# ============================================================
# 两条 Horner 链写成 NASM 宏，在各自的循环体里展开
# ============================================================

# 标量版：入口 xmm0 = x，出口 xmm0 = x·P(x²) ≈ sin(x)
# 用到的临时寄存器：xmm0（入/出）、xmm1（t）、xmm2（P）
	.text
.macro TAYLOR_S
    movss	%xmm0, %xmm1
    mulss	%xmm1, %xmm1	# t = x²
    movss	t_c8(%rip), %xmm2
    mulss	%xmm1, %xmm2
    addss	t_c7(%rip), %xmm2
    mulss	%xmm1, %xmm2
    addss	t_c6(%rip), %xmm2
    mulss	%xmm1, %xmm2
    addss	t_c5(%rip), %xmm2
    mulss	%xmm1, %xmm2
    addss	t_c4(%rip), %xmm2
    mulss	%xmm1, %xmm2
    addss	t_c3(%rip), %xmm2
    mulss	%xmm1, %xmm2
    addss	t_c2(%rip), %xmm2
    mulss	%xmm1, %xmm2
    addss	t_c1(%rip), %xmm2
    mulss	%xmm1, %xmm2
    addss	t_c0(%rip), %xmm2
    mulss	%xmm2, %xmm0	# sin(x) = x·P(t)
.endm

# 向量版：入口 xmm0 = [x_i … x_i+3]，出口 xmm0 = [sin … sin]
# 系数常驻 xmm4..xmm13（在循环外用 shufps 广播好），临时用 xmm1、xmm2
.macro TAYLOR_V
    movaps	%xmm0, %xmm1
    mulps	%xmm1, %xmm1	# t = x²
    movaps	%xmm13, %xmm2
    mulps	%xmm1, %xmm2
    addps	%xmm12, %xmm2
    mulps	%xmm1, %xmm2
    addps	%xmm11, %xmm2
    mulps	%xmm1, %xmm2
    addps	%xmm10, %xmm2
    mulps	%xmm1, %xmm2
    addps	%xmm9, %xmm2
    mulps	%xmm1, %xmm2
    addps	%xmm8, %xmm2
    mulps	%xmm1, %xmm2
    addps	%xmm6, %xmm2
    mulps	%xmm1, %xmm2
    addps	%xmm5, %xmm2
    mulps	%xmm1, %xmm2
    addps	%xmm4, %xmm2	# P(t)
    mulps	%xmm2, %xmm0	# sin(x) = x·P(t)
.endm


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$48, %rsp
    movq	%rbx, -8(%rbp)	# x_arr 基址
    movq	%r12, -16(%rbp)	# 标量耗时
    movq	%r13, -24(%rbp)	# 向量耗时
# [rbp-32] = 标量 Σ   [rbp-40] = 向量 Σ   [rbp-44] = 端点修正 corr

# --------------------------------------------------------
# 0. 预备（不计时）：h = π/N，x[i] = i·h，端点修正项
# --------------------------------------------------------
    movl	$N, %eax
    cvtsi2sd	%eax, %xmm1	# xmm1 = (double)N
    movsd	d_pi(%rip), %xmm0
    divsd	%xmm1, %xmm0	# h = π/N
    movsd	%xmm0, d_h(%rip)
    cvtsd2ss	%xmm0, %xmm2
    movss	%xmm2, f_h(%rip)

    leaq	x_arr(%rip), %rbx
    xorl	%ecx, %ecx
.L_mainfillx:
    cvtsi2ss	%ecx, %xmm0
    mulss	f_h(%rip), %xmm0
    movss	%xmm0, (%rbx,%rcx,4)
    incl	%ecx
    cmpl	$N, %ecx
    jbe	.L_mainfillx	# 0..N，共 N+1 个点

# corr = (f_N − f_0)/2；x_arr[0] = 0 所以 f_0 = sin(0) = 0
    movss	f_pi(%rip), %xmm0
TAYLOR_S	# f_N = sin(π)
    subss	(%rbx), %xmm0
    mulss	f_half(%rip), %xmm0
    movss	%xmm0, -44(%rbp)

# --------------------------------------------------------
# 1. 标量版本：逐点 Horner + 累加
# --------------------------------------------------------
    lfence
    rdtsc
    shlq	$32, %rdx
    orq	%rdx, %rax
    movq	%rax, %r12	# 计时起点

    pxor	%xmm7, %xmm7
    xorl	%ecx, %ecx
.L_mainsloop:
    movss	(%rbx,%rcx,4), %xmm0
TAYLOR_S	# 内联展开，没有函数调用
    addss	%xmm0, %xmm7
    incl	%ecx
    cmpl	$N, %ecx
    jb	.L_mainsloop	# i = 0 … N-1

    lfence
    rdtsc
    shlq	$32, %rdx
    orq	%rdx, %rax
    subq	%r12, %rax
    movq	%rax, %r12
    movss	%xmm7, -32(%rbp)

# --------------------------------------------------------
# 2. SIMD 版本：同样的 Horner，一次 4 个
# 先把 9 个系数广播到 4 条通道（AVX2 里是 vbroadcastss 一条）
# --------------------------------------------------------
    movss	t_c0(%rip), %xmm4
    shufps	$0, %xmm4, %xmm4	# imm8=0 -> 4 条通道都取通道 0
    movss	t_c1(%rip), %xmm5
    shufps	$0, %xmm5, %xmm5
    movss	t_c2(%rip), %xmm6
    shufps	$0, %xmm6, %xmm6
    movss	t_c3(%rip), %xmm8
    shufps	$0, %xmm8, %xmm8
    movss	t_c4(%rip), %xmm9
    shufps	$0, %xmm9, %xmm9
    movss	t_c5(%rip), %xmm10
    shufps	$0, %xmm10, %xmm10
    movss	t_c6(%rip), %xmm11
    shufps	$0, %xmm11, %xmm11
    movss	t_c7(%rip), %xmm12
    shufps	$0, %xmm12, %xmm12
    movss	t_c8(%rip), %xmm13
    shufps	$0, %xmm13, %xmm13

    lfence
    rdtsc
    shlq	$32, %rdx
    orq	%rdx, %rax
    movq	%rax, %r13

    pxor	%xmm3, %xmm3
    xorl	%ecx, %ecx
.L_mainvloop:
    movups	(%rbx,%rcx,4), %xmm0	# x[i..i+3]
TAYLOR_V	# 内联展开
    addps	%xmm0, %xmm3	# 4 路累加
    addl	$4, %ecx
    cmpl	$N, %ecx
    jb	.L_mainvloop

    lfence
    rdtsc
    shlq	$32, %rdx
    orq	%rdx, %rax
    subq	%r13, %rax
    movq	%rax, %r13

# 水平归约：4 条通道求和
    movaps	%xmm3, %xmm0
    shufps	$0x4E, %xmm0, %xmm0	# [2,3,0,1]
    addps	%xmm0, %xmm3
    movaps	%xmm3, %xmm0
    shufps	$0xB1, %xmm0, %xmm0	# [1,0,3,2]
    addps	%xmm0, %xmm3
    movss	%xmm3, -40(%rbp)

# --------------------------------------------------------
# 3. 输出
# --------------------------------------------------------
    leaq	fmt_hdr(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_parm(%rip), %rdi
    movl	$N, %esi
    movsd	d_h(%rip), %xmm0
    movl	$1, %eax
    call	printf

# 标量结果 = h · (Σ标量 + corr)
    movss	-32(%rbp), %xmm0
    addss	-44(%rbp), %xmm0
    mulss	f_h(%rip), %xmm0
    cvtss2sd	%xmm0, %xmm0
    movsd	d_two(%rip), %xmm1
    subsd	%xmm0, %xmm1	# 误差 = 2.0 − 结果
    leaq	fmt_scal(%rip), %rdi
    movl	$2, %eax
    call	printf

# 向量结果 = h · (Σ向量 + corr)
    movss	-40(%rbp), %xmm0
    addss	-44(%rbp), %xmm0
    mulss	f_h(%rip), %xmm0
    cvtss2sd	%xmm0, %xmm0
    movsd	d_two(%rip), %xmm1
    subsd	%xmm0, %xmm1
    leaq	fmt_vec(%rip), %rdi
    movl	$2, %eax
    call	printf

# 理论截断误差 πh²/12
    movsd	d_h(%rip), %xmm0
    mulsd	%xmm0, %xmm0
    mulsd	d_pi(%rip), %xmm0
    movsd	d_twelve(%rip), %xmm1
    divsd	%xmm1, %xmm0
    leaq	fmt_exact(%rip), %rdi
    movl	$1, %eax
    call	printf

    leaq	fmt_time(%rip), %rdi
    movq	%r12, %rsi
    movq	%r13, %rdx
    xorl	%eax, %eax
    call	printf

    cvtsi2sd	%r12, %xmm0
    cvtsi2sd	%r13, %xmm1
    divsd	%xmm1, %xmm0
    leaq	fmt_speed(%rip), %rdi
    movl	$1, %eax
    call	printf

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %rbx
    movq	-16(%rbp), %r12
    movq	-24(%rbp), %r13
    xorl	%eax, %eax
    leave
    ret
