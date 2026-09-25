	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
val3: .double 3.0
val4: .double 4.0
val22: .double 22.0	# 被除数
val7: .double 7.0	# 除数
result: .double 0.0

fmt_mul: .string "FMULP: 3.0 * 4.0  = %f\n"
fmt_div: .string "FDIVP: 22.0 / 7.0 = %f   （≈ π 的粗略近似）\n"
fmt_done: .string "FPU mul/div demo completed.\n"

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
# 1. FMULP：3.0 * 4.0
# --------------------------------------------------------
    fld	val3(%rip)	# ST0 = 3.0
    fld	val4(%rip)	# ST0 = 4.0, ST1 = 3.0
    fmulp	# ST0 = 3.0 * 4.0 = 12.0
print_st0	fmt_mul

# --------------------------------------------------------
# 2. FDIVP：22.0 / 7.0
# 被除数先压（落在 ST1），除数后压（落在 ST0）
# --------------------------------------------------------
    fld	val22(%rip)	# ST0 = 22.0
    fld	val7(%rip)	# ST0 = 7.0, ST1 = 22.0
    fdivp	# ST0 = 22.0 / 7.0 = 3.142857...
print_st0	fmt_div

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
