	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */
.set N, 1024
	# %define N 1024

.data
	.align 8
d_h: .double 0.006135923151542565	# 2π / 1024
d_six: .double 6.0
tmp_x: .double 0.0
tmp_s: .double 0.0

	.align 16
f_inv2h: .float 81.4873309, 81.4873309, 81.4873309, 81.4873309	# 1/(2h)
abs_mask: .long 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF

fmt_hdr: .string "=== SIMD 数值微分：f(x)=sin(x)，中心差分求 f'(x) ===\n"
fmt_parm: .string "N = %d 个采样点，h = 2π/N = %.9f\n"
fmt_smpl: .string "  x = %.6f :  差分值 %f   解析 cos(x) = %f\n"
fmt_max: .string "整段最大绝对误差 = %.9f\n"
fmt_bnd: .string "理论界 h²/6 = %.9f（中心差分的截断误差量级）\n"
fmt_why: .string "实测略高于理论界：sin 表存成 float 后的舍入被 1/(2h)≈81.5 放大了一次。\n"
fmt_note: .string "本机无 AVX2，故用 SSE 的 4 路；换成 ymm 就是 AVX2 的 8 路。\n"
fmt_done: .string "SIMD derivative demo completed.\n"


.bss
	.align 16
f_arr: .zero N+1*4	# sin(x_i)
c_arr: .zero N+1*4	# 参考用的 cos(x_i)
d_arr: .zero N+1*4	# 差分求出的导数


.text

# ------------------------------------------------------------
# print_sample —— rsi = 下标 i，打印「x、差分值、解析 cos(x)」一行
# 依赖 main 里已就绪的 r12 = d_arr、r13 = c_arr（都是被调用者保存寄存器）
# ------------------------------------------------------------
print_sample:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    cvtsi2sd	%rsi, %xmm0
    mulsd	d_h(%rip), %xmm0	# 第 1 个浮点参数：x = i·h
    movss	(%r12,%rsi,4), %xmm1
    cvtss2sd	%xmm1, %xmm1	# 第 2 个：SIMD 差分算出的导数
    movss	(%r13,%rsi,4), %xmm2
    cvtss2sd	%xmm2, %xmm2	# 第 3 个：解析解 cos
    leaq	fmt_smpl(%rip), %rdi
    movl	$3, %eax	# 用了 3 个向量寄存器
    call	printf
    leave
    ret

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$32, %rsp
    movq	%rbx, -8(%rbp)	# f_arr
    movq	%r12, -16(%rbp)	# d_arr
    movq	%r13, -24(%rbp)	# c_arr

# --------------------------------------------------------
# 1. 造数据表：f[i] = sin(i·h)，同时存一份 cos(i·h) 当参考
# 造表这种一次性开销用最简单的标量办法（x87 的 fsin / fcos）
# --------------------------------------------------------
    leaq	f_arr(%rip), %rbx
    leaq	c_arr(%rip), %r13
    xorl	%ecx, %ecx
.L_mainfill:
    cvtsi2sd	%ecx, %xmm0
    mulsd	d_h(%rip), %xmm0
    movsd	%xmm0, tmp_x(%rip)

    fld	tmp_x(%rip)
    fsin
    fstp	tmp_s(%rip)
    movsd	tmp_s(%rip), %xmm0
    cvtsd2ss	%xmm0, %xmm0
    movss	%xmm0, (%rbx,%rcx,4)	# f[i]

    fld	tmp_x(%rip)
    fcos
    fstp	tmp_s(%rip)
    movsd	tmp_s(%rip), %xmm0
    cvtsd2ss	%xmm0, %xmm0
    movss	%xmm0, (%r13,%rcx,4)	# 参考 cos[i]

    incl	%ecx
    cmpl	$N, %ecx
    jbe	.L_mainfill	# 0..N，共 N+1 个点

# --------------------------------------------------------
# 2. 向量化的中心差分
# 以「字节偏移」rcx 为游标，i = 1 对应 rcx = 0：
# f_forward  在 rbx + rcx + 8
# f_backward 在 rbx + rcx
# 每次前进 16 字节（4 个 float）。
# --------------------------------------------------------
    leaq	d_arr(%rip), %r12
    movaps	f_inv2h(%rip), %xmm4	# 常数 1/(2h) 常驻寄存器
    xorl	%ecx, %ecx
.L_mainvloop:
    movups	8(%rbx,%rcx), %xmm0	# [f[i+1], f[i+2], f[i+3], f[i+4]]
    movups	(%rbx,%rcx), %xmm1	# [f[i-1], f[i],   f[i+1], f[i+2]]
    subps	%xmm1, %xmm0
    mulps	%xmm4, %xmm0	# ÷ 2h
    movups	%xmm0, 4(%r12,%rcx)	# 存 der[i..i+3]
    addl	$16, %ecx
    cmpl	(N-8)*4, %ecx	# 覆盖 i = 1..1020（255 组 × 4）
    jbe	.L_mainvloop

# --------------------------------------------------------
# 3. 同样 4 路并行求最大绝对误差
# andps 清符号位当绝对值，maxps 沿途累积
# --------------------------------------------------------
    movaps	abs_mask(%rip), %xmm5
    pxor	%xmm3, %xmm3
    xorl	%ecx, %ecx
.L_maineloop:
    movups	4(%r12,%rcx), %xmm0	# der[i..i+3]
    movups	4(%r13,%rcx), %xmm1	# cos[i..i+3]
    subps	%xmm1, %xmm0
    andps	%xmm5, %xmm0
    maxps	%xmm0, %xmm3
    addl	$16, %ecx
    cmpl	(N-8)*4, %ecx
    jbe	.L_maineloop

# 水平归约：把 4 条通道的最大值压成 1 个
    movaps	%xmm3, %xmm1
    shufps	$0x4E, %xmm1, %xmm1	# [2,3,0,1]
    maxps	%xmm1, %xmm3
    movaps	%xmm3, %xmm1
    shufps	$0xB1, %xmm1, %xmm1	# [1,0,3,2]
    maxps	%xmm1, %xmm3
    movss	%xmm3, %xmm7	# xmm7 = 最大误差，留到最后打印

# --------------------------------------------------------
# 4. 输出
# 注意 xmm7 要在两次 print_sample 之后才用 —— print_sample 里的
# printf 会踩掉所有 xmm，所以这里先把它落到栈上最稳。
# --------------------------------------------------------
    movss	%xmm7, -32(%rbp)

    leaq	fmt_hdr(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_parm(%rip), %rdi
    movl	$N, %esi
    movsd	d_h(%rip), %xmm0
    movl	$1, %eax
    call	printf

    movq	$256, %rsi	# x = 256h ≈ π/2
    call	print_sample
    movq	$512, %rsi	# x = 512h ≈ π
    call	print_sample
    movq	$768, %rsi	# x = 768h ≈ 3π/2
    call	print_sample

    movss	-32(%rbp), %xmm0
    cvtss2sd	%xmm0, %xmm0
    leaq	fmt_max(%rip), %rdi
    movl	$1, %eax
    call	printf

    movsd	d_h(%rip), %xmm0
    mulsd	%xmm0, %xmm0	# h²
    divsd	d_six(%rip), %xmm0	# h²/6
    leaq	fmt_bnd(%rip), %rdi
    movl	$1, %eax
    call	printf

    leaq	fmt_why(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_note(%rip), %rdi
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
