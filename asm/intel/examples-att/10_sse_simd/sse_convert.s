	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 4
int32_val: .long 42
float_val: .float 3.7	# 拿来演示「舍入 vs 截断」
	.align 8
int64_val: .quad 1000000
double_val: .double 2.718281828459045
	.align 4
fpi_val: .float 3.14
	.align 8
temp_d: .double 0.0
temp_i: .long 0

fmt_i2ss: .string "cvtsi2ss:  int32  42        -> float  %f\n"
fmt_i2sd: .string "cvtsi2sd:  int64  1000000   -> double %f\n"
fmt_ss2si: .string "cvtss2si:  float  3.7       -> int    %d  （就近舍入）\n"
fmt_ttss2si: .string "cvttss2si: float  3.7       -> int    %d  （向零截断）\n"
fmt_ss2sd: .string "cvtss2sd:  float  3.14      -> double %f\n"
fmt_sd2ss: .string "cvtsd2ss:  double 2.71828.. -> float  %f  （精度有损）\n"
fmt_done: .string "SSE type conversion demo completed.\n"

	.text
.macro print_d p1
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
# 1. cvtsi2ss：32 位整数 -> 单精度
# --------------------------------------------------------
    movl	int32_val(%rip), %eax	# eax = 42
    cvtsi2ss	%eax, %xmm0	# xmm0[31:0] = 42.0f
    cvtss2sd	%xmm0, %xmm0	# 升成 double 给 %f
print_d	fmt_i2ss

# --------------------------------------------------------
# 2. cvtsi2sd：64 位整数 -> 双精度
# --------------------------------------------------------
    movq	int64_val(%rip), %rax	# rax = 1000000
    cvtsi2sd	%rax, %xmm0	# xmm0[63:0] = 1000000.0
print_d	fmt_i2sd

# --------------------------------------------------------
# 3. cvtss2si：单精度 -> 整数，按 MXCSR 舍入模式（默认就近）
# 3.7 -> 4
# --------------------------------------------------------
    movss	float_val(%rip), %xmm0
    cvtss2sil	%xmm0, %eax	# eax = 4
    movl	%eax, temp_i(%rip)
    leaq	fmt_ss2si(%rip), %rdi
    movl	temp_i(%rip), %esi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 4. cvttss2si：多一个 t，就变成无条件向零截断
# 3.7 -> 3
# --------------------------------------------------------
    movss	float_val(%rip), %xmm0
    cvttss2si	%xmm0, %eax	# eax = 3
    movl	%eax, temp_i(%rip)
    leaq	fmt_ttss2si(%rip), %rdi
    movl	temp_i(%rip), %esi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 5. cvtss2sd：float -> double，有效数字从 ~7 位扩到 ~15 位
# --------------------------------------------------------
    movss	fpi_val(%rip), %xmm1	# 3.14f
    cvtss2sd	%xmm1, %xmm0
print_d	fmt_ss2sd

# --------------------------------------------------------
# 6. cvtsd2ss：double -> float，精度会丢
# 打出来要用 %f，所以再 cvtss2sd 升回 double
# --------------------------------------------------------
    movsd	double_val(%rip), %xmm1	# 2.718281828459045
    cvtsd2ss	%xmm1, %xmm0	# 降成 float（只剩约 7 位）
    cvtss2sd	%xmm0, %xmm0	# 升回 double 以便打印
print_d	fmt_sd2ss

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
