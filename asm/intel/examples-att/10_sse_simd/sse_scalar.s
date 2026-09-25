	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 4
f_val1: .float 3.14	# 单精度
f_val2: .float 2.0
	.align 8
d_val1: .double 2.718281828459045	# 双精度
d_val2: .double 3.0
	.align 8
temp_d: .double 0.0

fmt_addss: .string "ADDSS: 3.14 + 2.0 = %f\n"
fmt_subss: .string "SUBSS: 3.14 - 2.0 = %f\n"
fmt_mulss: .string "MULSS: 3.14 * 2.0 = %f\n"
fmt_addsd: .string "ADDSD: 2.71828... + 3.0 = %f\n"
fmt_mulsd: .string "MULSD: 2.71828... * 3.0 = %f\n"
fmt_done: .string "SSE scalar arithmetic demo completed.\n"

# 把 xmm0 里的结果落内存 → 装回 xmm0 → 用 %f 打出来
# （落一次内存是为了避开「%f 要 double 但结果可能是 float」的转换细节；
# cvtss2sd 已经在调用点做掉了）
	.text
.macro print_x p1
    movsd	%xmm0, temp_d(%rip)
    movsd	temp_d(%rip), %xmm0
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
# 1. ADDSS：单精度标量加，只动 xmm0 的低 32 位
# --------------------------------------------------------
    movss	f_val1(%rip), %xmm0	# xmm0[31:0] = 3.14
    movss	f_val2(%rip), %xmm1	# xmm1[31:0] = 2.0
    addss	%xmm1, %xmm0	# = 5.14
    cvtss2sd	%xmm0, %xmm0	# float -> double，交给 %f
print_x	fmt_addss

# --------------------------------------------------------
# 2. SUBSS
# --------------------------------------------------------
    movss	f_val1(%rip), %xmm0
    movss	f_val2(%rip), %xmm1
    subss	%xmm1, %xmm0	# = 1.14
    cvtss2sd	%xmm0, %xmm0
print_x	fmt_subss

# --------------------------------------------------------
# 3. MULSS
# --------------------------------------------------------
    movss	f_val1(%rip), %xmm0
    movss	f_val2(%rip), %xmm1
    mulss	%xmm1, %xmm0	# = 6.28
    cvtss2sd	%xmm0, %xmm0
print_x	fmt_mulss

# --------------------------------------------------------
# 4. ADDSD：双精度标量加，只动低 64 位
# --------------------------------------------------------
    movsd	d_val1(%rip), %xmm0
    movsd	d_val2(%rip), %xmm1
    addsd	%xmm1, %xmm0	# = 5.71828...
print_x	fmt_addsd

# --------------------------------------------------------
# 5. MULSD
# --------------------------------------------------------
    movsd	d_val1(%rip), %xmm0
    movsd	d_val2(%rip), %xmm1
    mulsd	%xmm1, %xmm0	# = 8.15484...
print_x	fmt_mulsd

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
