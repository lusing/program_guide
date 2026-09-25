	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_min: .string "CMOVG: min(%lld, %lld) = %lld  (if a > b, a = b)\n"
fmt_max: .string "CMOVL: max(%lld, %lld) = %lld  (if a < b, a = b)\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    movq	%r12, -8(%rbp)	# r12/r13 是被调用者保存寄存器
    movq	%r13, -16(%rbp)

# --------------------------------------------------------
# min(25, 10)：CMP 25,10 得 15 -> SF=0 OF=0 ZF=0
# CMOVG 条件「大于」成立 -> r12 = r13 = 10（留下较小者）
# --------------------------------------------------------
    movq	$25, %r12
    movq	$10, %r13
    cmpq	%r13, %r12
    cmovgq	%r13, %r12

    leaq	fmt_min(%rip), %rdi
    movq	$25, %rsi	# a
    movq	$10, %rdx	# b
    movq	%r12, %rcx	# 结果
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# max(25, 10)：同样的 CMP
# CMOVL 条件「小于」不成立 -> r12 保持 25（留下较大者）
# --------------------------------------------------------
    movq	$25, %r12
    movq	$10, %r13
    cmpq	%r13, %r12
    cmovlq	%r13, %r12

    leaq	fmt_max(%rip), %rdi
    movq	$25, %rsi
    movq	$10, %rdx
    movq	%r12, %rcx
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %r12
    movq	-16(%rbp), %r13
    xorl	%eax, %eax
    leave
    ret
