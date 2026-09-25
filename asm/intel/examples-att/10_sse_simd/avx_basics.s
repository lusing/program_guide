	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
# --- SSE 基线：4 个 float ---
	.align 16
sse_a: .float 1.0, 2.0, 3.0, 4.0
	.align 16
sse_b: .float 10.0, 10.0, 10.0, 10.0
	.align 16
sse_buf: .float 0.0, 0.0, 0.0, 0.0

# --- AVX：8 个 float，必须 32 字节对齐（vmovaps 要求）---
	.align 32
avx_a: .float 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0
	.align 32
avx_b: .float 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0
	.align 32
avx_sum: .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
	.align 32
avx_prod: .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0

hdr: .string "AVX 基础：VEX 三操作数 + 256 位 YMM\n"
t_sse: .string "1. SSE 基线（128 位，破坏性操作数）\n"
t_sse_c: .string "   addps xmm0,xmm1 算完 xmm0 原值就没了；想复用必须先 movaps 备份\n"
fmt_sum: .string "2. AVX：同一对源寄存器，连算两组结果（源没被破坏）\n"
fmt_sum_c: .string "   和： [1..8] + [10 x 8]\n"
fmt_prod_c: .string "   积： [1..8] * [10 x 8]\n"
t_zero: .string "3. vzeroupper：ymm 上半部已清零，现在可以安全调 printf 了\n"
t_skip: .string "本机不支持 AVX（CPUID 页 1 / XCR0 已确认），跳过第 2~3 段，只跑 SSE 基线。\n"
fmt_idx: .string "     [%d] = "
fmt_done: .string "AVX basics demo completed.\n"


.text

# ------------------------------------------------------------
# cpu_features —— CPUID + XGETBV 探测，返回 eax 位图
# bit0 = AVX    页1 ECX[28]，且 ECX[27] OSXSAVE，且 XCR0[2:1] = 11
# bit1 = AVX2   页7 EBX[5]
# bit2 = FMA    页1 ECX[12]      ← 注意：FMA 在页 1，不在页 7
# bit3 = 操作系统已放开 YMM 状态保存（XCR0[2:1]）
# 
# CPUID 会踩 rbx，而 rbx 是被调用者保存寄存器，所以这里先备份。
# 本函数不调用别的函数，纯寄存器运算。
# ------------------------------------------------------------
cpu_features:
    pushq	%rbp
    movq	%rsp, %rbp
    pushq	%rbx
    pushq	%r12

    xorl	%r12d, %r12d	# 结果位图

    movl	$0, %eax
    cpuid
    movl	%eax, %r9d	# r9d = 最大页号
    cmpl	$1, %r9d
    jb	.L_cpu_featuresdone	# 连页 1 都没有，什么都别问了

    movl	$1, %eax
    xorl	%ecx, %ecx
    cpuid
    movl	%ecx, %r8d	# 页 1 的特性位图在 ECX

    btl	$12, %r8d	# FMA
    jnc	.L_cpu_featuresno_fma
    orl	$4, %r12d
.L_cpu_featuresno_fma:
    btl	$28, %r8d	# AVX
    jnc	.L_cpu_featuresdone
    btl	$27, %r8d	# OSXSAVE（没它就说明 OS 没开扩展状态）
    jnc	.L_cpu_featuresdone

    xorl	%ecx, %ecx
    xgetbv	# XCR0 -> EDX:EAX
    andl	$6, %eax	# 只看 bit1(SSE) 和 bit2(YMM)
    cmpl	$6, %eax
    jne	.L_cpu_featuresdone	# OS 没放开 YMM，AVX 可用性不成立
    orl	$9, %r12d	# bit0(AVX) + bit3(OS 已放开 YMM)

    cmpl	$7, %r9d
    jb	.L_cpu_featuresdone
    movl	$7, %eax
    xorl	%ecx, %ecx
    cpuid
    btl	$5, %ebx	# AVX2
    jnc	.L_cpu_featuresdone
    orl	$2, %r12d

.L_cpu_featuresdone:
    movl	%r12d, %eax
    popq	%r12
    popq	%rbx
    leave
    ret

# ------------------------------------------------------------
# print_vec —— 把缓冲区里的 float 逐个打成 "     [i] = 值"
# rdi = float*   esi = 个数
# ------------------------------------------------------------
print_vec:
    pushq	%rbp
    movq	%rsp, %rbp
    pushq	%rbx
    pushq	%r12
    pushq	%r13
    subq	$8, %rsp	# 保持 16 字节对齐

    movq	%rdi, %rbx
    movl	%esi, %r12d
    xorl	%r13d, %r13d
.L_print_vecloop:
    cmpl	%r12d, %r13d
    jge	.L_print_vecdone
    leaq	fmt_idx(%rip), %rdi
    movl	%r13d, %esi
    xorl	%eax, %eax
    call	printf
    movss	(%rbx,%r13,4), %xmm0
    call	l_putf	# float -> %g
    call	l_nl
    incl	%r13d
    jmp	.L_print_vecloop
.L_print_vecdone:
    addq	$8, %rsp
    popq	%r13
    popq	%r12
    popq	%rbx
    leave
    ret

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    movq	%rbx, -8(%rbp)
    movq	%r12, -16(%rbp)

    call	cpu_features
    movl	%eax, %r12d	# r12d = 特性位图

    leaq	hdr(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 1. SSE 基线：128 位、破坏性操作数
# --------------------------------------------------------
    leaq	t_sse(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t_sse_c(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    movaps	sse_a(%rip), %xmm0
    movaps	sse_b(%rip), %xmm1
    addps	%xmm1, %xmm0	# xmm0 被覆盖：原值 [1,2,3,4] 消失
    movaps	%xmm0, sse_buf(%rip)
    leaq	sse_buf(%rip), %rdi
    movl	$4, %esi
    call	print_vec

# --------------------------------------------------------
# 第 2~3 段需要 AVX：bit0 = AVX 可用，bit3 = OS 放开了 YMM
# --------------------------------------------------------
    movl	%r12d, %eax
    andl	$9, %eax
    cmpl	$9, %eax
    je	.L_mainavx_ok
    leaq	t_skip(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_mainfinish

.L_mainavx_ok:
    leaq	fmt_sum(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    vmovaps	avx_a(%rip), %ymm1
    vmovaps	avx_b(%rip), %ymm2
    vaddps	%ymm2, %ymm1, %ymm0	# ymm0 = ymm1 + ymm2
    vmulps	%ymm2, %ymm1, %ymm3	# ymm1 / ymm2 还是原值，直接复用
    vmovaps	%ymm0, avx_sum(%rip)
    vmovaps	%ymm3, avx_prod(%rip)
    vzeroupper	# 落盘后立刻清上半部

    leaq	fmt_sum_c(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	avx_sum(%rip), %rdi
    movl	$8, %esi
    call	print_vec

    leaq	fmt_prod_c(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	avx_prod(%rip), %rdi
    movl	$8, %esi
    call	print_vec

    leaq	t_zero(%rip), %rdi
    xorl	%eax, %eax
    call	printf

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
