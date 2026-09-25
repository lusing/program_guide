	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 32
mul_a: .long 100000, 200000, 300000, 400000, 500000, 600000, 700000, 800000
	.align 32
mul_b: .long 3, -3, 3, -3, 3, -3, 3, -3
	.align 32
sh_a: .long 1, 1, 1, 1, 1, 1, 1, 1
	.align 32
sh_cnt: .long 0, 1, 2, 3, 4, 5, 6, 7
	.align 32
pm_idx: .long 7, 6, 5, 4, 3, 2, 1, 0
	.align 32
pm_src: .long 10, 20, 30, 40, 50, 60, 70, 80
	.align 32
bcast: .long 7
	.align 32
out_buf: .long 0, 0, 0, 0, 0, 0, 0, 0

hdr: .string "AVX2 整数：SSE 做不到的三件事\n"
t1: .string "1. VPMULLD —— 8 路 32 位有符号乘（SSE 只有 128 位版）\n"
t1c: .string "   [100000 ... 800000] * [3,-3,3,-3,3,-3,3,-3]\n"
t2: .string "2. VPSLLVD —— 每个通道各自移自己的位数（SSE 只能全体同移）\n"
t2c: .string "   [1 x 8] 左移 [0,1,2,3,4,5,6,7] 位\n"
t3: .string "3. VPERMD  —— 跨 128 位 lane 的任意置换（AVX1 只能在 lane 内换）\n"
t3c: .string "   [10..80] 按索引 [7,6,5,4,3,2,1,0] 重排 = 整体反转\n"
t3l: .string "   （若改用 AVX1 的 vpermilps，只会得到 40 30 20 10 80 70 60 50）\n"
t4: .string "4. VPBROADCASTD —— 内存里的一个数铺满 8 个通道\n"
t4c: .string "   [7] 广播\n"
t_skip: .string "本机不支持 AVX2（CPUID 页 7 EBX[5] / XCR0 已确认），本示例无可演示内容。\n"
fmt_idx: .string "     [%d] = %d\n"
fmt_done: .string "AVX2 integer demo completed.\n"


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

    btl	$12, %r8d
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
# print_ivec —— 把缓冲区里的 int32 逐个打成 "     [i] = 值"
# rdi = int32*   esi = 个数
# ------------------------------------------------------------
print_ivec:
    pushq	%rbp
    movq	%rsp, %rbp
    pushq	%rbx
    pushq	%r12
    pushq	%r13
    subq	$8, %rsp	# 保持 16 字节对齐

    movq	%rdi, %rbx
    movl	%esi, %r12d
    xorl	%r13d, %r13d
.L_print_ivecloop:
    cmpl	%r12d, %r13d
    jge	.L_print_ivecdone
    movl	(%rbx,%r13,4), %edx
    leaq	fmt_idx(%rip), %rdi
    movl	%r13d, %esi
    xorl	%eax, %eax
    call	printf
    incl	%r13d
    jmp	.L_print_ivecloop
.L_print_ivecdone:
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
    movl	%eax, %r12d

    leaq	hdr(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    movl	%r12d, %eax
    andl	$10, %eax	# bit1(AVX2) + bit3(OS 放开 YMM) = 0b1010
    cmpl	$10, %eax
    je	.L_mainavx2_ok
    leaq	t_skip(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_mainfinish

.L_mainavx2_ok:
# --- 1. vpmulld：8 路 32 位乘 ---
    leaq	t1(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t1c(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    vmovdqa	mul_a(%rip), %ymm1
    vmovdqa	mul_b(%rip), %ymm2
    vpmulld	%ymm2, %ymm1, %ymm0
    vmovdqa	%ymm0, out_buf(%rip)
    vzeroupper
    leaq	out_buf(%rip), %rdi
    movl	$8, %esi
    call	print_ivec

# --- 2. vpsllvd：每通道独立移位量 ---
    leaq	t2(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t2c(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    vmovdqa	sh_a(%rip), %ymm1
    vmovdqa	sh_cnt(%rip), %ymm2
    vpsllvd	%ymm2, %ymm1, %ymm0	# ymm0 = ymm1 << ymm2（逐通道）
    vmovdqa	%ymm0, out_buf(%rip)
    vzeroupper
    leaq	out_buf(%rip), %rdi
    movl	$8, %esi
    call	print_ivec

# --- 3. vpermd：跨 lane 置换 ---
    leaq	t3(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t3c(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t3l(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    vmovdqa	pm_idx(%rip), %ymm1	# 索引向量
    vmovdqa	pm_src(%rip), %ymm2	# 被重排的数据
    vpermd	%ymm2, %ymm1, %ymm0	# ymm0 = ymm2 按 ymm1 的索引取
    vmovdqa	%ymm0, out_buf(%rip)
    vzeroupper
    leaq	out_buf(%rip), %rdi
    movl	$8, %esi
    call	print_ivec

# --- 4. vpbroadcastd：一个数铺满 8 通道 ---
    leaq	t4(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t4c(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    vpbroadcastd	bcast(%rip), %ymm0	# SSE 写法要 movss + shufps 两条
    vmovdqa	%ymm0, out_buf(%rip)
    vzeroupper
    leaq	out_buf(%rip), %rdi
    movl	$8, %esi
    call	print_ivec

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
