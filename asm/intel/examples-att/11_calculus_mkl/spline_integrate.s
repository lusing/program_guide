	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */
.set NSEG, 20
.set NNODES, 21
.set NSITE, 1000
	# %define NSEG    20                      ; 区间段数
	# %define NNODES  21                      ; 节点数 = NSEG+1
	# %define NSITE   1000                    ; 积分采样点数

.data
	.align 16
dd_absmask: .quad 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF

	.align 8
dd_one: .double 1.0
dd_two: .double 2.0
dd_four: .double 4.0
dd_six: .double 6.0
dd_half: .double 0.5
dd_pi: .double 3.141592653589793
dd_1000: .double 1000.0
dd_sqr2_2: .double 0.7071067811865476	# sin(π/4) = √2/2
dd_h: .double 0.0	# π/20，运行时算
dd_h2_6: .double 0.0	# h²/6
dd_inv6h: .double 0.0	# 1/(6h)
dd_invh: .double 0.0	# 1/h
dd_step: .double 0.0	# π/1000
dd_tmp: .double 0.0

fmt_hdr: .string "=== 自然三次样条 + 梯形积分：∫₀^π sin(x)dx ===\n"
fmt_parm: .string "节点 %d 个（%d 段），h = π/%d = %.12f\n"
fmt_node: .string "验收一 max|S(x_i) − y_i| = %.3e   （≈0 表示样条严格过点）\n"
fmt_end: .string "验收二 S''(0) = %.3e，S''(π) = %.3e   （自然边界，应为 0）\n"
fmt_check: .string "中段抽查 S(π/4) = %.12f，真值 √2/2 = %.12f\n"
fmt_trap: .string "1000 点梯形积分结果 = %.12f\n"
fmt_exact: .string "精确值 2.0，绝对误差 = %.3e\n"
fmt_why: .string "误差主要来自 1000 点梯形法自身的 O(h²)，不是样条（样条过点误差 2e-16）。\n"
fmt_why2: .string "注：Linux 的 libmvec 也没有 MKL DF 那样的样条 API，故此处手写。\n"
fmt_done: .string "Spline integrate demo completed.\n"


.bss
	.align 16
xa: .zero (NNODES)*8	# 节点 x_i
ya: .zero (NNODES)*8	# 节点 y_i = sin(x_i)
mm: .zero (NNODES)*8	# 二阶导 M_i（M_0 = M_20 = 0）
w_rhs: .zero (NNODES)*8	# 右端项
w_cp: .zero (NNODES)*8	# Thomas 的 c'
w_dp: .zero (NNODES)*8	# Thomas 的 d'


.text

# ------------------------------------------------------------
# spline_eval —— 求 S(x)
# 入口：xmm0 = x（double）
# 出口：xmm0 = S(x)
# 依赖：r12 = xa，r13 = ya，r14 = mm
# 踩：rax/eax 与 **xmm0..xmm8**。
# 注意它把 xmm0..xmm8 全用了一遍，所以调用方**不能**把跨调用
# 要保留的值放在这些寄存器里 —— 一律落栈。（这里踩过一次：）
# 最初把积分累加器放 xmm6、prev 放 xmm7，结果都被 y_i / y_{i+1} 覆盖了。
# ------------------------------------------------------------
spline_eval:
# 定位区间 i = floor(x/h)，再夹到 [0, NSEG-1]
    movapd	%xmm0, %xmm1
    mulsd	dd_invh(%rip), %xmm1
    cvttsd2si	%xmm1, %eax	# 向零截断；x≥0 所以等价于 floor
    testl	%eax, %eax
    jns	.L_spline_evalnonneg
    xorl	%eax, %eax
.L_spline_evalnonneg:
    cmpl	$NSEG - 1, %eax
    jle	.L_spline_evalok
    movl	$NSEG - 1, %eax
.L_spline_evalok:
    movslq	%eax, %rax

# t = x − x_i，ht = h − t
    movsd	(%r12,%rax,8), %xmm2
    subsd	%xmm2, %xmm0	# xmm0 = t
    movsd	dd_h(%rip), %xmm3
    subsd	%xmm0, %xmm3	# xmm3 = ht

# 取出这个区间的四个数据
    movsd	(%r14,%rax,8), %xmm4	# M_i
    movsd	8(%r14,%rax,8), %xmm5	# M_{i+1}
    movsd	(%r13,%rax,8), %xmm6	# y_i
    movsd	8(%r13,%rax,8), %xmm7	# y_{i+1}

# 第一项 [M_i·ht³ + M_{i+1}·t³] / (6h)
    movapd	%xmm3, %xmm1
    mulsd	%xmm3, %xmm1
    mulsd	%xmm3, %xmm1
    mulsd	%xmm4, %xmm1	# M_i·ht³
    movapd	%xmm0, %xmm2
    mulsd	%xmm0, %xmm2
    mulsd	%xmm0, %xmm2
    mulsd	%xmm5, %xmm2	# M_{i+1}·t³
    addsd	%xmm2, %xmm1
    mulsd	dd_inv6h(%rip), %xmm1

# 第二项 (y_i − M_i·h²/6)·ht/h
    movapd	%xmm4, %xmm2
    mulsd	dd_h2_6(%rip), %xmm2
    subsd	%xmm2, %xmm6
    mulsd	%xmm3, %xmm6
    mulsd	dd_invh(%rip), %xmm6
    addsd	%xmm6, %xmm1

# 第三项 (y_{i+1} − M_{i+1}·h²/6)·t/h
    movapd	%xmm5, %xmm2
    mulsd	dd_h2_6(%rip), %xmm2
    subsd	%xmm2, %xmm7
    mulsd	%xmm0, %xmm7
    mulsd	dd_invh(%rip), %xmm7
    addsd	%xmm7, %xmm1

    movapd	%xmm1, %xmm0
    ret

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$96, %rsp
    movq	%rbx, -8(%rbp)	# w_cp 基址
    movq	%r12, -16(%rbp)	# xa
    movq	%r13, -24(%rbp)	# ya
    movq	%r14, -32(%rbp)	# mm
    movq	%r15, -40(%rbp)	# w_rhs
# [rbp-48] = 节点最大偏差   [rbp-56] = 积分结果   [rbp-64] = S(π/4)

    leaq	xa(%rip), %r12
    leaq	ya(%rip), %r13
    leaq	mm(%rip), %r14
    leaq	w_rhs(%rip), %r15
    leaq	w_cp(%rip), %rbx

# --------------------------------------------------------
# 0. h = π/NSEG 及派生常数
# --------------------------------------------------------
    movl	$NSEG, %eax
    cvtsi2sd	%eax, %xmm1
    movsd	dd_pi(%rip), %xmm0
    divsd	%xmm1, %xmm0
    movsd	%xmm0, dd_h(%rip)	# h

    movsd	dd_pi(%rip), %xmm1
    divsd	dd_1000(%rip), %xmm1
    movsd	%xmm1, dd_step(%rip)	# π/1000（注意不是 h/1000）

    movsd	%xmm0, %xmm1
    mulsd	%xmm0, %xmm1
    divsd	dd_six(%rip), %xmm1
    movsd	%xmm1, dd_h2_6(%rip)	# h²/6

    movsd	dd_six(%rip), %xmm1
    mulsd	dd_h(%rip), %xmm1	# 6h
    movsd	dd_one(%rip), %xmm2
    divsd	%xmm1, %xmm2
    movsd	%xmm2, dd_inv6h(%rip)	# 1/(6h)

    movsd	dd_one(%rip), %xmm2
    divsd	dd_h(%rip), %xmm2
    movsd	%xmm2, dd_invh(%rip)	# 1/h

# --------------------------------------------------------
# 1. 节点：x_i = i·h，y_i = sin(x_i)（x87 的 fsin 取真值）
# --------------------------------------------------------
    xorl	%ecx, %ecx
.L_mainfill:
    cvtsi2sd	%ecx, %xmm0
    mulsd	dd_h(%rip), %xmm0
    movsd	%xmm0, (%r12,%rcx,8)
    movsd	%xmm0, dd_tmp(%rip)
    fld	dd_tmp(%rip)
    fsin
    fstp	dd_tmp(%rip)
    movsd	dd_tmp(%rip), %xmm0
    movsd	%xmm0, (%r13,%rcx,8)
    incl	%ecx
    cmpl	$NNODES, %ecx
    jb	.L_mainfill

# --------------------------------------------------------
# 2. 右端项 rhs_i = 6·(y_{i+1} − 2y_i + y_{i-1}) / h²，i = 1..19
# --------------------------------------------------------
    movsd	dd_six(%rip), %xmm7
    movsd	dd_h(%rip), %xmm6
    mulsd	%xmm6, %xmm6
    divsd	%xmm6, %xmm7	# 6/h²
    movl	$1, %ecx
.L_mainrhs:
    movsd	8(%r13,%rcx,8), %xmm0	# y_{i+1}
    addsd	-8(%r13,%rcx,8), %xmm0	# + y_{i-1}
    movsd	(%r13,%rcx,8), %xmm1	# y_i
    addsd	%xmm1, %xmm1	# 2y_i
    subsd	%xmm1, %xmm0
    mulsd	%xmm7, %xmm0
    movsd	%xmm0, (%r15,%rcx,8)
    incl	%ecx
    cmpl	$NNODES - 1, %ecx	# 到 19
    jb	.L_mainrhs

# --------------------------------------------------------
# 3. Thomas 算法（追赶法）
# 系数恒为 a=1, b=4, c=1，于是正向扫递推：
# cp_i = 1 / (4 − cp_{i-1})，cp_0 = 0
# dp_i = (rhs_i − dp_{i-1}) · cp_i
# 反向回代：M_19 = dp_19；M_i = dp_i − cp_i·M_{i+1}
# --------------------------------------------------------
    xorpd	%xmm3, %xmm3	# cp_{i-1} = 0
    xorpd	%xmm4, %xmm4	# dp_{i-1} = 0
    leaq	w_dp(%rip), %rsi	# w_dp 基址（循环里没有 call，rsi 不会被动）
    movl	$1, %ecx
.L_mainfwd:
    movsd	dd_four(%rip), %xmm0
    subsd	%xmm3, %xmm0	# 4 − cp_{i-1}
    movsd	dd_one(%rip), %xmm1
    divsd	%xmm0, %xmm1	# cp_i
    movsd	%xmm1, (%rbx,%rcx,8)

    movsd	(%r15,%rcx,8), %xmm2	# rhs_i
    subsd	%xmm4, %xmm2
    mulsd	%xmm1, %xmm2	# dp_i
    movsd	%xmm2, (%rsi,%rcx,8)

    movapd	%xmm1, %xmm3
    movapd	%xmm2, %xmm4
    incl	%ecx
    cmpl	$NNODES - 1, %ecx
    jb	.L_mainfwd

    movl	$NNODES - 2, %ecx	# 19
    movsd	(%rsi,%rcx,8), %xmm0
    movsd	%xmm0, (%r14,%rcx,8)	# M_19 = dp_19
    decl	%ecx	# 18 … 1
.L_mainback:
    movsd	(%rsi,%rcx,8), %xmm0	# dp_i
    movsd	(%rbx,%rcx,8), %xmm1	# cp_i
    mulsd	8(%r14,%rcx,8), %xmm1	# ·M_{i+1}
    subsd	%xmm1, %xmm0
    movsd	%xmm0, (%r14,%rcx,8)
    decl	%ecx
    jnz	.L_mainback
# M_0 与 M_20 保持 0（自然边界），mm 数组初值本来就是 0

# --------------------------------------------------------
# 4. 验收一：S(x_i) 是否严格等于 y_i
# 最大值放内存里累积 —— spline_eval 会踩 xmm3
# --------------------------------------------------------
    movq	$0, -48(%rbp)
    movl	$0, %ecx
.L_mainnode:
    movsd	(%r12,%rcx,8), %xmm0
    call	spline_eval	# 不踩 rcx，放心直接用
    subsd	(%r13,%rcx,8), %xmm0
    andpd	dd_absmask(%rip), %xmm0
    maxsd	-48(%rbp), %xmm0
    movsd	%xmm0, -48(%rbp)
    incl	%ecx
    cmpl	$NNODES, %ecx
    jb	.L_mainnode

# --------------------------------------------------------
# 5. 1000 点梯形积分
# ∫ ≈ step · Σ_{j=1..1000} (S_{j-1} + S_j)/2
# S_0 = S(0) = y_0 = 0，所以 prev 初值 0。
# 累加器和 prev 都放栈上（见 spline_eval 的踩寄存器说明）。
# --------------------------------------------------------
    movq	$0, -72(%rbp)	# 累加器
    movq	$0, -80(%rbp)	# prev = S(x_0)
    movl	$1, %ecx
.L_mainsite:
    cvtsi2sd	%ecx, %xmm0
    mulsd	dd_step(%rip), %xmm0	# x = j·step
    call	spline_eval
    movsd	%xmm0, -88(%rbp)	# 先存下 S_j
    addsd	-80(%rbp), %xmm0	# S_j + S_{j-1}
    mulsd	dd_half(%rip), %xmm0
    addsd	-72(%rbp), %xmm0
    movsd	%xmm0, -72(%rbp)	# 累加器更新
    movsd	-88(%rbp), %xmm1
    movsd	%xmm1, -80(%rbp)	# prev ← S_j
    incl	%ecx
    cmpl	$NSITE, %ecx
    jbe	.L_mainsite
    movsd	-72(%rbp), %xmm0
    mulsd	dd_step(%rip), %xmm0
    movsd	%xmm0, -56(%rbp)

# 顺便抽查 S(π/4)
    movsd	dd_pi(%rip), %xmm0
    movsd	dd_four(%rip), %xmm1
    divsd	%xmm1, %xmm0
    call	spline_eval
    movsd	%xmm0, -64(%rbp)

# --------------------------------------------------------
# 6. 输出
# --------------------------------------------------------
    leaq	fmt_hdr(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_parm(%rip), %rdi
    movl	$NNODES, %esi
    movl	$NSEG, %edx
    movl	$NSEG, %ecx
    movsd	dd_h(%rip), %xmm0
    movl	$1, %eax
    call	printf

    leaq	fmt_node(%rip), %rdi
    movsd	-48(%rbp), %xmm0
    movl	$1, %eax
    call	printf

    leaq	fmt_end(%rip), %rdi
    movsd	(%r14), %xmm0	# M_0
    movsd	NSEG*8(%r14), %xmm1	# M_20
    movl	$2, %eax
    call	printf

    leaq	fmt_check(%rip), %rdi
    movsd	-64(%rbp), %xmm0
    movsd	dd_sqr2_2(%rip), %xmm1
    movl	$2, %eax
    call	printf

    leaq	fmt_trap(%rip), %rdi
    movsd	-56(%rbp), %xmm0
    movl	$1, %eax
    call	printf

    movsd	dd_two(%rip), %xmm0
    subsd	-56(%rbp), %xmm0	# 误差 = 2.0 − 结果
    leaq	fmt_exact(%rip), %rdi
    movl	$1, %eax
    call	printf

    leaq	fmt_why(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_why2(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %rbx
    movq	-16(%rbp), %r12
    movq	-24(%rbp), %r13
    movq	-32(%rbp), %r14
    movq	-40(%rbp), %r15
    xorl	%eax, %eax
    leave
    ret
