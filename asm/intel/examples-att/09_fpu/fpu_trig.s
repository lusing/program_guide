	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
result: .double 0.0

	.align 4
six: .long 6	# 用来算 π/6
three: .long 3	# 用来算 π/3
four: .long 4	# 用来算 π/4

fmt_pi: .string "FLDPI: π = %f\n"
fmt_sin: .string "FSIN:  sin(π/6) = %f   （应为 0.5）\n"
fmt_cos: .string "FCOS:  cos(π/3) = %f   （应为 0.5）\n"
fmt_tan: .string "FPTAN: tan(π/4) = %f   （应为 1.0）\n"
fmt_done: .string "FPU trig demo completed.\n"

	.text
.macro print_st0 p1
    fstp	result(%rip)
    movsd	result(%rip), %xmm0
    leaq	\p1(%rip), %rdi
    movl	$1, %eax
    call	printf
.endm


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

    finit

# --------------------------------------------------------
# 1. FLDPI：拿 FPU 内建的 π（66 位精度，比 double 还准）
# --------------------------------------------------------
    fldpi	# ST0 = π
print_st0	fmt_pi

# --------------------------------------------------------
# 2. FSIN：sin(π/6) = 0.5
# FIDIV 直接除内存里的整数，省掉一次 fld
# --------------------------------------------------------
    fldpi	# ST0 = π
    fidivl	six(%rip)	# ST0 = π / 6
    fsin	# ST0 = sin(π/6) = 0.5
print_st0	fmt_sin

# --------------------------------------------------------
# 3. FCOS：cos(π/3) = 0.5
# --------------------------------------------------------
    fldpi
    fidivl	three(%rip)	# ST0 = π / 3
    fcos	# ST0 = cos(π/3) = 0.5
print_st0	fmt_cos

# --------------------------------------------------------
# 4. FPTAN：tan(π/4) = 1.0
# 执行前：ST0 = 角度
# 执行后：ST0 = 1.0，ST1 = tan(角度)
# 所以要先把那个 1.0 弹掉，剩下的 ST0 才是答案
# --------------------------------------------------------
    fldpi
    fidivl	four(%rip)	# ST0 = π / 4
    fptan	# ST0 = 1.0, ST1 = tan(π/4)
    fstp	%st(0)	# 扔掉 1.0（光弹不存）
print_st0	fmt_tan	# 现在 ST0 就是 tan 值

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
