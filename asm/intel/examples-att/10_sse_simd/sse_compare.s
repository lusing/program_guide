	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 4
f_val1: .float 3.14
f_val2: .float 2.72
	.align 8
d_val1: .double 3.14159
d_val2: .double 2.71828

	.align 16
packed1: .float 1.0, 2.0, 3.0, 4.0
	.align 16
packed2: .float 1.0, 3.0, 3.0, 5.0
	.align 16
mask_buf: .long 0, 0, 0, 0

fmt_comiss_gt: .string "COMISS: 3.14 > 2.72 成立\n"
fmt_comiss_lt: .string "COMISS: 3.14 > 2.72 不成立\n"
fmt_comisd_gt: .string "COMISD: 3.14159 > 2.71828 成立\n"
fmt_comisd_lt: .string "COMISD: 3.14159 > 2.71828 不成立\n"
fmt_cmpps: .string "CMPPS EQ 掩码: 0x%08X 0x%08X 0x%08X 0x%08X\n"
fmt_cmpps_note: .string "  （0xFFFFFFFF = 相等，0x00000000 = 不等）\n"
fmt_done: .string "SSE compare demo completed.\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

# --------------------------------------------------------
# 1. COMISS：标量单精度比较，结果进 EFLAGS
# --------------------------------------------------------
    movss	f_val1(%rip), %xmm0	# xmm0 = 3.14
    movss	f_val2(%rip), %xmm1	# xmm1 = 2.72
    comiss	%xmm1, %xmm0

    ja	.L_maincomiss_gt
# 落到这里就是 xmm0 <= xmm1

.L_maincomiss_lt:
    leaq	fmt_comiss_lt(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_maindo_comisd

.L_maincomiss_gt:
    leaq	fmt_comiss_gt(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 2. COMISD：标量双精度比较
# --------------------------------------------------------
.L_maindo_comisd:
    movsd	d_val1(%rip), %xmm0
    movsd	d_val2(%rip), %xmm1
    comisd	%xmm1, %xmm0

    ja	.L_maincomisd_gt

.L_maincomisd_lt:
    leaq	fmt_comisd_lt(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_maindo_cmpps

.L_maincomisd_gt:
    leaq	fmt_comisd_gt(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 3. CMPPS：打包比较，逐通道出掩码
# [1,2,3,4] vs [1,3,3,5] 比 EQ -> [全1, 0, 全1, 0]
# --------------------------------------------------------
.L_maindo_cmpps:
    movaps	packed1(%rip), %xmm0
    movaps	packed2(%rip), %xmm1
    cmpps	$0, %xmm1, %xmm0	# 0 = EQ
    movaps	%xmm0, mask_buf(%rip)

# 5 个参数：rdi 格式串，rsi/rdx/rcx/r8 = 四个掩码
    leaq	fmt_cmpps(%rip), %rdi
    movl	mask_buf(%rip), %esi
    movl	mask_buf+4(%rip), %edx
    movl	mask_buf+8(%rip), %ecx
    movl	mask_buf+12(%rip), %r8d
    xorl	%eax, %eax
    call	printf

    leaq	fmt_cmpps_note(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
