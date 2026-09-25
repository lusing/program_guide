	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
# a = 1 + 2^-23（float 里比 1.0 大的最小数）
	.align 32
f_a: .rept 8
	.long 0x3F800001
	.endr
# b = 1 - 2^-23（位型 0x3F7FFFFE，不是 0x3F7FFFFF）
# 注意：1.0 以下 ulp 只有 2^-24，所以「比 1.0 小的最大数」
# 其实是 0x3F7FFFFF = 1-2^-24；要凑出 1-2^-23 得再退一格。
	.align 32
f_b: .rept 8
	.long 0x3F7FFFFE
	.endr
# c = -1.0
	.align 32
f_c: .rept 8
	.long 0xBF800000
	.endr

# 一组普通常数，用来证明 FMA 不是「另一种算法」
	.align 32
n_a: .rept 8
	.float 2.0
	.endr
	.align 32
n_b: .rept 8
	.float 3.0
	.endr
	.align 32
n_c: .rept 8
	.float 4.0
	.endr

	.align 16
sse_out: .float 0.0, 0.0, 0.0, 0.0
	.align 32
fma_out: .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0

str_yes: .string "YES"
str_no: .string "NO"

hdr: .string "FMA：一条顶两条，而且只舍入一次\n"
fmt_det: .string "探测：AVX2 = %s，FMA = %s\n"
t_desc: .string "1. 一个能看出差别的小例子\n"
t_desc2: .string "   a = 1 + 2^-23（float 里比 1.0 大的最小数，位型 0x3F800001）\n"
t_desc3: .string "   b = 1 - 2^-23（位型 0x3F7FFFFE）\n"
t_desc3b: .string "   （坑：1.0 以下的 ulp 只有 2^-24，所以 0x3F7FFFFF 是 1-2^-24，不是 1-2^-23）\n"
t_desc4: .string "   c = -1.0\n"
t_desc5: .string "   精确值 a*b + c = -2^-46 = -1.4210854715202004e-14\n"
t_sse: .string "2. SSE 路径：mulps + addps，中间乘积被舍入两次\n"
t_sse2: .string "   a*b 的真值 1-2^-46 塞不进 float（只有 24 位有效位），先被舍入成 1.0\n"
t_sse3: .string "   然后 1.0 + (-1.0) = 0 —— 有效数字全被抵消了\n"
t_fma: .string "3. FMA 路径：vfmadd231ps，只有最后一次舍入\n"
t_norm: .string "4. 换一组普通常数（a=2, b=3, c=4），两条路径结果一样\n"
t_norm2: .string "   —— FMA 不是另一种算法，只是少了中间那一次舍入\n"
lb_sse: .string "mulps+addps 结果"
lb_fma: .string "vfmadd231ps 结果"
t_skip: .string "本机不支持 FMA（CPUID 页 1 ECX[12] / XCR0 已确认），无法演示。\n"
fmt_hi: .string "   %s = %.17g\n"
fmt_done: .string "FMA demo completed.\n"


.text

# ------------------------------------------------------------
# cpu_features —— CPUID + XGETBV 探测，返回 eax 位图
# bit0 = AVX    页1 ECX[28]，且 ECX[27] OSXSAVE，且 XCR0[2:1] = 11
# bit1 = AVX2   页7 EBX[5]
# bit2 = FMA    页1 ECX[12]
# bit3 = 操作系统已放开 YMM 状态保存（XCR0[2:1]）
# ------------------------------------------------------------
cpu_features:
    pushq	%rbp
    movq	%rsp, %rbp
    pushq	%rbx
    pushq	%r12

    xorl	%r12d, %r12d

    movl	$0, %eax
    cpuid
    movl	%eax, %r9d	# 最大页号
    cmpl	$1, %r9d
    jb	.L_cpu_featuresdone

    movl	$1, %eax
    xorl	%ecx, %ecx
    cpuid
    movl	%ecx, %r8d

    btl	$12, %r8d	# FMA（在页 1）
    jnc	.L_cpu_featuresno_fma
    orl	$4, %r12d
.L_cpu_featuresno_fma:
    btl	$28, %r8d
    jnc	.L_cpu_featuresdone
    btl	$27, %r8d
    jnc	.L_cpu_featuresdone

    xorl	%ecx, %ecx
    xgetbv
    andl	$6, %eax
    cmpl	$6, %eax
    jne	.L_cpu_featuresdone
    orl	$9, %r12d

    cmpl	$7, %r9d
    jb	.L_cpu_featuresdone
    movl	$7, %eax
    xorl	%ecx, %ecx
    cpuid
    btl	$5, %ebx
    jnc	.L_cpu_featuresdone
    orl	$2, %r12d

.L_cpu_featuresdone:
    movl	%r12d, %eax
    popq	%r12
    popq	%rbx
    leave
    ret

# ------------------------------------------------------------
# put_g17 —— 打印 "   标签 = 值（17 位有效数字）"
# rdi = 以 0 结尾的标签串   xmm0 = double
# ------------------------------------------------------------
put_g17:
    pushq	%rbp
    movq	%rsp, %rbp
    movq	%rdi, %rsi
    leaq	fmt_hi(%rip), %rdi
    movl	$1, %eax	# 用掉 1 个 xmm 参数
    call	printf
    leave
    ret

# ------------------------------------------------------------
# sse_muladd —— 用 mulps + addps 算 out = a*b + c（128 位，4 通道）
# rdi = a   rsi = b   rdx = c   rcx = out
# 纯 SSE，不碰任何被调用者保存寄存器，也不调用别的函数。
# ------------------------------------------------------------
sse_muladd:
    pushq	%rbp
    movq	%rsp, %rbp
    movaps	(%rdi), %xmm0	# a
    movaps	(%rsi), %xmm1	# b
    mulps	%xmm1, %xmm0	# t = a * b   ← 第一次舍入
    movaps	(%rdx), %xmm1	# c
    addps	%xmm1, %xmm0	# t = t + c   ← 第二次舍入
    movaps	%xmm0, (%rcx)
    leave
    ret

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    movq	%rbx, -8(%rbp)
    movq	%r12, -16(%rbp)

    call	cpu_features
    movl	%eax, %r12d

    leaq	hdr(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# 打印探测结果：AVX2（bit1）与 FMA（bit2）
    leaq	str_no(%rip), %rsi
    movl	%r12d, %eax
    andl	$2, %eax
    cmpl	$2, %eax
    jne	.L_mainno_ax2
    leaq	str_yes(%rip), %rsi
.L_mainno_ax2:
    leaq	str_no(%rip), %rdx
    movl	%r12d, %eax
    andl	$4, %eax
    cmpl	$4, %eax
    jne	.L_mainno_f
    leaq	str_yes(%rip), %rdx
.L_mainno_f:
    leaq	fmt_det(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# 本示例要 FMA（bit2）+ OS 放开 YMM（bit3）= 0b1100
    movl	%r12d, %eax
    andl	$12, %eax
    cmpl	$12, %eax
    je	.L_mainfma_ok
    leaq	t_skip(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_mainfinish

.L_mainfma_ok:
    leaq	t_desc(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t_desc2(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t_desc3(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t_desc3b(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t_desc4(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t_desc5(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --- 2. SSE 路径 ---
    leaq	t_sse(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t_sse2(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t_sse3(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	f_a(%rip), %rdi
    leaq	f_b(%rip), %rsi
    leaq	f_c(%rip), %rdx
    leaq	sse_out(%rip), %rcx
    call	sse_muladd

    leaq	lb_sse(%rip), %rdi
    movss	sse_out(%rip), %xmm0
    cvtss2sd	%xmm0, %xmm0
    call	put_g17

# --- 3. FMA 路径 ---
    leaq	t_fma(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    vmovaps	f_c(%rip), %ymm0
    vmovaps	f_a(%rip), %ymm1
    vmovaps	f_b(%rip), %ymm2
    vfmadd231ps	%ymm2, %ymm1, %ymm0	# ymm0 = ymm1*ymm2 + ymm0
    vmovaps	%ymm0, fma_out(%rip)
    vzeroupper

    leaq	lb_fma(%rip), %rdi
    movss	fma_out(%rip), %xmm0
    cvtss2sd	%xmm0, %xmm0
    call	put_g17

# --- 4. 普通常数：两条路径一致 ---
    leaq	t_norm(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t_norm2(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	n_a(%rip), %rdi
    leaq	n_b(%rip), %rsi
    leaq	n_c(%rip), %rdx
    leaq	sse_out(%rip), %rcx
    call	sse_muladd
    leaq	lb_sse(%rip), %rdi
    movss	sse_out(%rip), %xmm0
    cvtss2sd	%xmm0, %xmm0
    call	put_g17

    vmovaps	n_c(%rip), %ymm0
    vmovaps	n_a(%rip), %ymm1
    vmovaps	n_b(%rip), %ymm2
    vfmadd231ps	%ymm2, %ymm1, %ymm0
    vmovaps	%ymm0, fma_out(%rip)
    vzeroupper
    leaq	lb_fma(%rip), %rdi
    movss	fma_out(%rip), %xmm0
    cvtss2sd	%xmm0, %xmm0
    call	put_g17

.L_mainfinish:
    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %rbx
    movq	-16(%rbp), %r12
    xorl	%eax, %eax
    leave
    ret

	.include "att_io.s"
