	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */
.set N, 1024
	# %define N 1024

.data
# 16 字节对齐区：andps / maxps / subps 的内存操作数都必须是 16 的整数倍
	.align 16
f_ones: .float 1.0, 1.0, 1.0, 1.0
f_absmask: .long 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF

	.align 4
f_step: .float 0.0061359232	# 2π / 1024

fmt_hdr: .string "=== glibc libmvec 批量数学（_ZGVbN4v_*）===\n"
fmt_step: .string "采样点数 N = %d，区间 [0, 2π)，每次 call 处理 xmm0 里的 4 个\n"
fmt_sin: .string "_ZGVbN4v_sinf: x = %.4f  ->  %f\n"
fmt_cos: .string "_ZGVbN4v_cosf: x = %.4f  ->  %f\n"
fmt_exp: .string "_ZGVbN4v_expf: x = %.4f  ->  %f\n"
fmt_ident: .string "sin²+cos²-1 的最大偏差（SSE 手工扫描）： %.9f\n"
fmt_maxexp: .string "SSE 手工归约 max(exp 结果) = %f\n"
fmt_sig: .string "签名对比：MKL vsSin(n,in,out) | vForce vvsinf(out,in,&n) | libmvec _ZGVbN4v_sinf xmm0→xmm0\n"
fmt_done: .string "libmvec demo completed.\n"


.bss
	.align 16
x_arr: .zero (N)*4
y_sin: .zero (N)*4
y_cos: .zero (N)*4
y_exp: .zero (N)*4


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$32, %rsp
    movq	%rbx, -8(%rbp)	# rbx = x_arr 基址
    movq	%r12, -16(%rbp)	# r12 = 输出数组基址
    movq	%r13, -24(%rbp)	# r13 = 循环计数器

# --------------------------------------------------------
# 1. 先把 x[i] = i * (2π/N) 填好
# 用标量 SSE：cvtsi2ss 把下标转成 float，乘步长，存回数组
# （带下标的寻址不能用 RIP 相对，所以先用 lea 把基址装进 rbx）
# --------------------------------------------------------
    leaq	x_arr(%rip), %rbx
    xorl	%ecx, %ecx
.L_mainfill_x:
    cvtsi2ss	%ecx, %xmm0
    mulss	f_step(%rip), %xmm0
    movss	%xmm0, (%rbx,%rcx,4)
    incl	%ecx
    cmpl	$N, %ecx
    jb	.L_mainfill_x

# --------------------------------------------------------
# 2. 三组 libmvec 循环 —— 每次 call 只算 xmm0 里的 4 个：
# movups 装入 4 个输入 → call → movups 存回 4 个结果
# 循环计数器必须用被调用者保存寄存器（r13）：
# libmvec 函数会把 rcx 等调用者保存寄存器全部踩掉
# --------------------------------------------------------
    leaq	x_arr(%rip), %rbx
    leaq	y_sin(%rip), %r12
    xorl	%r13d, %r13d
.L_mainvloop_sin:
    movups	(%rbx,%r13,4), %xmm0	# 4 个输入装进 xmm0
    call	_ZGVbN4v_sinf	# 结果同样在 xmm0 里
    movups	%xmm0, (%r12,%r13,4)
    addl	$4, %r13d
    cmpl	$N, %r13d
    jb	.L_mainvloop_sin

    leaq	y_cos(%rip), %r12
    xorl	%r13d, %r13d
.L_mainvloop_cos:
    movups	(%rbx,%r13,4), %xmm0
    call	_ZGVbN4v_cosf
    movups	%xmm0, (%r12,%r13,4)
    addl	$4, %r13d
    cmpl	$N, %r13d
    jb	.L_mainvloop_cos

    leaq	y_exp(%rip), %r12
    xorl	%r13d, %r13d
.L_mainvloop_exp:
    movups	(%rbx,%r13,4), %xmm0
    call	_ZGVbN4v_expf
    movups	%xmm0, (%r12,%r13,4)
    addl	$4, %r13d
    cmpl	$N, %r13d
    jb	.L_mainvloop_exp

    leaq	fmt_hdr(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_step(%rip), %rdi
    movl	$N, %esi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 3. 抽查三个点：x[128] = π/2，x[256] = π
# %f 的值按顺序放 xmm0、xmm1…，eax 记「用了几个」
# --------------------------------------------------------
    movss	x_arr+128*4, %xmm0	# 第 1 个浮点参数：x
    cvtss2sd	%xmm0, %xmm0
    movss	y_sin+128*4, %xmm1	# 第 2 个浮点参数：sin(x)
    cvtss2sd	%xmm1, %xmm1
    leaq	fmt_sin(%rip), %rdi
    movl	$2, %eax
    call	printf

    movss	x_arr+128*4, %xmm0
    cvtss2sd	%xmm0, %xmm0
    movss	y_cos+128*4, %xmm1
    cvtss2sd	%xmm1, %xmm1
    leaq	fmt_cos(%rip), %rdi
    movl	$2, %eax
    call	printf

    movss	x_arr+256*4, %xmm0
    cvtss2sd	%xmm0, %xmm0
    movss	y_exp+256*4, %xmm1
    cvtss2sd	%xmm1, %xmm1
    leaq	fmt_exp(%rip), %rdi
    movl	$2, %eax
    call	printf

# --------------------------------------------------------
# 4. 手工 SIMD 验证 sin²+cos²=1：4 路并行求最大偏差
# maxps 顺着跑累积最大值，最后再做水平归约
# --------------------------------------------------------
    movaps	f_absmask(%rip), %xmm5	# 提前装好掩码，省得每轮读内存
    pxor	%xmm3, %xmm3	# xmm3 = 最大偏差，初值 0
    leaq	y_sin(%rip), %rbx
    leaq	y_cos(%rip), %r12
    xorl	%ecx, %ecx
.L_mainchk:
    movups	(%rbx,%rcx,4), %xmm0	# sin
    movups	(%r12,%rcx,4), %xmm1	# cos
    mulps	%xmm0, %xmm0	# sin²
    mulps	%xmm1, %xmm1	# cos²
    addps	%xmm1, %xmm0	# sin² + cos²
    subps	f_ones(%rip), %xmm0	# 减 1 就是偏差
    andps	%xmm5, %xmm0	# 取绝对值（清符号位）
    maxps	%xmm0, %xmm3	# 累积最大值
    addl	$4, %ecx
    cmpl	$N, %ecx
    jb	.L_mainchk

# 水平归约：把 4 条通道的最大值压成 1 个
    movaps	%xmm3, %xmm1
    shufps	$0x4E, %xmm1, %xmm1	# [2,3,0,1]：交换两个 64 位半
    maxps	%xmm1, %xmm3
    movaps	%xmm3, %xmm1
    shufps	$0xB1, %xmm1, %xmm1	# [1,0,3,2]：交换相邻两格
    maxps	%xmm1, %xmm3

    movss	%xmm3, %xmm0
    cvtss2sd	%xmm0, %xmm0
    leaq	fmt_ident(%rip), %rdi
    movl	$1, %eax
    call	printf

# --------------------------------------------------------
# 5. SSE 手工归约求 exp 最大值（macOS 版这里调 vDSP_maxv，
# libmvec 没有归约函数，正好把第 4 节的归约套路再用一遍）
# --------------------------------------------------------
    pxor	%xmm3, %xmm3
    leaq	y_exp(%rip), %rbx
    xorl	%ecx, %ecx
.L_mainmaxv:
    movups	(%rbx,%rcx,4), %xmm0
    maxps	%xmm0, %xmm3
    addl	$4, %ecx
    cmpl	$N, %ecx
    jb	.L_mainmaxv

    movaps	%xmm3, %xmm1
    shufps	$0x4E, %xmm1, %xmm1
    maxps	%xmm1, %xmm3
    movaps	%xmm3, %xmm1
    shufps	$0xB1, %xmm1, %xmm1
    maxps	%xmm1, %xmm3

    movss	%xmm3, %xmm0
    cvtss2sd	%xmm0, %xmm0
    leaq	fmt_maxexp(%rip), %rdi
    movl	$1, %eax
    call	printf

    leaq	fmt_sig(%rip), %rdi
    xorl	%eax, %eax
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
