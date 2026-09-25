	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
# 16 字节对齐的打包 float（4 个 float 正好 16 字节）
	.align 16
packed_data: .float 1.0, 2.0, 3.0, 4.0

# 不保证对齐的数据（演示 movups）
unaligned_data: .float 5.0, 6.0, 7.0, 8.0

	.align 4
float_val: .float 3.14	# 单精度
	.align 8
double_val: .double 2.718281828459045	# 双精度

	.align 16
xmm_buf: .float 0.0, 0.0, 0.0, 0.0	# 存放 XMM 里搬出来的 4 个 float
	.align 8
temp_double: .double 0.0

fmt_movaps: .string "MOVAPS: 一次搬进 4 个 float [1.0, 2.0, 3.0, 4.0]\n"
fmt_elem: .string "  element[%d] = %f\n"
fmt_movups: .string "MOVUPS: 一次搬进 4 个 float [5.0, 6.0, 7.0, 8.0]\n"
fmt_movss: .string "MOVSS:  搬进一个标量 float  = %f\n"
fmt_movsd: .string "MOVSD:  搬进一个标量 double = %f\n"
fmt_done: .string "SSE data movement demo completed.\n"

# 打一个 float 元素：%1 = 偏移，%2 = 下标
	.text
.macro print_elem p1, p2
    movss	xmm_buf+\p1, %xmm0	# 取第 \p2 个 float
    cvtss2sd	%xmm0, %xmm0	# float -> double（%f 要 double）
    leaq	fmt_elem(%rip), %rdi
    movl	$\p2, %esi
    movl	$1, %eax	# 用了 1 个向量寄存器
    call	printf
.endm

# 打一个 double：xmm1 里已经有值
.macro print_d p1
    movsd	%xmm1, %xmm0
    leaq	\p1(%rip), %rdi
    movl	$1, %eax
    call	printf
.endm


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

# --------------------------------------------------------
# 1. MOVAPS：对齐的打包搬运
# 内存地址必须是 16 的整数倍，否则 CPU 直接抛 #GP
# --------------------------------------------------------
    movaps	packed_data(%rip), %xmm0	# 4 个 float 一起进来
    movaps	%xmm0, xmm_buf(%rip)	# 再原样存到缓冲区

    leaq	fmt_movaps(%rip), %rdi
    xorl	%eax, %eax
    call	printf

print_elem	0, 0
print_elem	4, 1
print_elem	8, 2
print_elem	12, 3

# --------------------------------------------------------
# 2. MOVUPS：不对齐版本，功能一样，不挑地址
# --------------------------------------------------------
    movups	unaligned_data(%rip), %xmm0
    movups	%xmm0, xmm_buf(%rip)

    leaq	fmt_movups(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 3. MOVSS：标量单精度，只动低 32 位，高 96 位清零
# --------------------------------------------------------
    movss	float_val(%rip), %xmm0	# xmm0[31:0] = 3.14
    cvtss2sd	%xmm0, %xmm1	# 升成 double 才能用 %f 打
print_d	fmt_movss

# --------------------------------------------------------
# 4. MOVSD：标量双精度，只动低 64 位，高 64 位清零
# --------------------------------------------------------
    movsd	double_val(%rip), %xmm0	# xmm0[63:0] = 2.718281828...
    movsd	%xmm0, %xmm1
print_d	fmt_movsd

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
