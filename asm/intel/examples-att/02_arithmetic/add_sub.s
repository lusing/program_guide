	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
mem: .quad 1000

fmt_add_reg: .string "add rax,rbx  : %lld + %lld = %lld\n"
fmt_add_imm: .string "add rax,10   : %lld + 10 = %lld\n"
fmt_add_mem: .string "add [mem],rax: %lld + %lld = %lld (内存)\n"
fmt_sub_reg: .string "sub rax,rbx  : %lld - %lld = %lld\n"
fmt_sub_imm: .string "sub rax,5    : %lld - 5 = %lld\n"
fmt_ovf: .string "溢出演示: %d + 1 = %d (有符号溢出)\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$32, %rsp
    movq	%rbx, -8(%rbp)	# rbx 被下面用到，先存起来

# add rax, rbx (寄存器加)
    movq	$50, %rax
    movq	$30, %rbx
    addq	%rbx, %rax	# rax = 80
    leaq	fmt_add_reg(%rip), %rdi
    movq	$50, %rsi
    movq	$30, %rdx
    movq	%rax, %rcx	# rcx 留到最后才装，避免被前面两行盖掉
    xorl	%eax, %eax
    call	printf

# add rax, 10 (立即数加)
    movq	$100, %rax
    addq	$10, %rax	# rax = 110
    leaq	fmt_add_imm(%rip), %rdi
    movq	$100, %rsi
    movq	%rax, %rdx
    xorl	%eax, %eax
    call	printf

# add [mem], rax (内存加)
    movq	$1000, mem(%rip)
    movq	$55, %rax
    addq	%rax, mem(%rip)	# mem = 1055
    leaq	fmt_add_mem(%rip), %rdi
    movq	$1000, %rsi
    movq	$55, %rdx
    movq	mem(%rip), %rcx
    xorl	%eax, %eax
    call	printf

# sub rax, rbx (寄存器减)
    movq	$200, %rax
    movq	$75, %rbx
    subq	%rbx, %rax	# rax = 125
    leaq	fmt_sub_reg(%rip), %rdi
    movq	$200, %rsi
    movq	$75, %rdx
    movq	%rax, %rcx
    xorl	%eax, %eax
    call	printf

# sub rax, 5 (立即数减)
    movq	$50, %rax
    subq	$5, %rax	# rax = 45
    leaq	fmt_sub_imm(%rip), %rdi
    movq	$50, %rsi
    movq	%rax, %rdx
    xorl	%eax, %eax
    call	printf

# 溢出演示: 32 位 INT_MAX + 1
    movl	$0x7FFFFFFF, %eax	# eax = 2147483647 (INT32_MAX)
    movl	%eax, %esi	# 先存原值，esi 现在是第 2 个参数
    addl	$1, %eax	# eax = 0x80000000, OF=1
    pushfq
    popq	%r10	# r10 = 这次加法之后的标志位快照
    movl	%eax, %edx	# 第 3 个参数 = 结果
    leaq	fmt_ovf(%rip), %rdi
    movq	%r10, -16(%rbp)	# 要跨过 printf，所以先落栈保存
    xorl	%eax, %eax
    call	printf

# 把刚才那份标志位快照打出来：OF 应该是 1
# （注意必须在 add 之后立刻 pushfq，因为 printf 自己也会改标志位）
    movq	-16(%rbp), %rdi
    call	l_putflags
    call	l_nl

    movq	-8(%rbp), %rbx
    xorl	%eax, %eax
    leave
    ret

# ------------------------------------------------------------
# 下面这一行把 linux_io.inc 整个包含进来，于是就有了
# l_putflags / l_nl / l_putint 这些输出辅助例程。
# ------------------------------------------------------------
	.include "att_io.s"
