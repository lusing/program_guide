	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 16
packed1: .float 1.0, 2.0, 3.0, 4.0
	.align 16
packed2: .float 5.0, 6.0, 7.0, 8.0

	.align 16
xmm_buf: .float 0.0, 0.0, 0.0, 0.0

fmt_addps: .string "ADDPS: [1,2,3,4] + [5,6,7,8] = [6, 8, 10, 12]\n"
fmt_subps: .string "SUBPS: [1,2,3,4] - [5,6,7,8] = [-4, -4, -4, -4]\n"
fmt_mulps: .string "MULPS: [1,2,3,4] * [5,6,7,8] = [5, 12, 21, 32]\n"
fmt_divps: .string "DIVPS: [1,2,3,4] / [5,6,7,8] = [0.2, 0.3333, 0.4286, 0.5]\n"
fmt_elem: .string "  [%d] = %f\n"
fmt_done: .string "SSE packed arithmetic demo completed.\n"


.text

# ------------------------------------------------------------
# print_4floats —— 把 xmm_buf 里的 4 个 float 逐行打出来
# 这是本类唯一的「自定义函数」，注意它也要遵守 SysV：
# - 用 rbp 建帧，退场 leave
# - 不碰 rbx/r12-r15（它本来也不碰）
# ------------------------------------------------------------
print_4floats:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

    movss	xmm_buf(%rip), %xmm0
    cvtss2sd	%xmm0, %xmm0
    leaq	fmt_elem(%rip), %rdi
    movl	$0, %esi
    movl	$1, %eax
    call	printf

    movss	xmm_buf+4(%rip), %xmm0
    cvtss2sd	%xmm0, %xmm0
    leaq	fmt_elem(%rip), %rdi
    movl	$1, %esi
    movl	$1, %eax
    call	printf

    movss	xmm_buf+8(%rip), %xmm0
    cvtss2sd	%xmm0, %xmm0
    leaq	fmt_elem(%rip), %rdi
    movl	$2, %esi
    movl	$1, %eax
    call	printf

    movss	xmm_buf+12(%rip), %xmm0
    cvtss2sd	%xmm0, %xmm0
    leaq	fmt_elem(%rip), %rdi
    movl	$3, %esi
    movl	$1, %eax
    call	printf

    leave
    ret

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

# --------------------------------------------------------
# 1. ADDPS
# --------------------------------------------------------
    movaps	packed1(%rip), %xmm0	# xmm0 = [1,2,3,4]
    movaps	packed2(%rip), %xmm1	# xmm1 = [5,6,7,8]
    addps	%xmm1, %xmm0	# xmm0 = [6,8,10,12]
    movaps	%xmm0, xmm_buf(%rip)

    leaq	fmt_addps(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    call	print_4floats

# --------------------------------------------------------
# 2. SUBPS
# --------------------------------------------------------
    movaps	packed1(%rip), %xmm0
    movaps	packed2(%rip), %xmm1
    subps	%xmm1, %xmm0	# xmm0 = [-4,-4,-4,-4]
    movaps	%xmm0, xmm_buf(%rip)

    leaq	fmt_subps(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    call	print_4floats

# --------------------------------------------------------
# 3. MULPS
# --------------------------------------------------------
    movaps	packed1(%rip), %xmm0
    movaps	packed2(%rip), %xmm1
    mulps	%xmm1, %xmm0	# xmm0 = [5,12,21,32]
    movaps	%xmm0, xmm_buf(%rip)

    leaq	fmt_mulps(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    call	print_4floats

# --------------------------------------------------------
# 4. DIVPS
# --------------------------------------------------------
    movaps	packed1(%rip), %xmm0
    movaps	packed2(%rip), %xmm1
    divps	%xmm1, %xmm0	# xmm0 = [0.2, 0.333…, 0.428…, 0.5]
    movaps	%xmm0, xmm_buf(%rip)

    leaq	fmt_divps(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    call	print_4floats

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
