	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */
	.include "att_io.s"

.data
fmt_set: .string "1. 造标志：0xFF + 1 = 0x100（8 位溢出回绕成 0）\n"
lbl_saved: .string "   存下来的标志（pushfq 那一刻）：\n"
fmt_chg: .string "2. 换一批标志：1 + 1 = 2（无溢出）\n"
lbl_curr: .string "   此刻的标志：\n"
fmt_rst: .string "3. 用 popfq 把存下来的标志装回去\n"
lbl_rstd: .string "   恢复后的标志：\n"
msg_cmp: .string "   六个标志位与存档完全一致？ "
fmt_done: .string "PUSHF/POPF demo completed.\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$32, %rsp
    movq	%r12, -8(%rbp)	# r12 = 存档的 RFLAGS
    movq	%r14, -16(%rbp)	# r14 = 恢复后的 RFLAGS

# --------------------------------------------------------
# 1. 造出一组特征明显的标志：0xFF + 1
# 结果 AL=0x00，CF=1（进位出去）、ZF=1（结果为 0）
# --------------------------------------------------------
    movb	$0xFF, %al
    addb	$1, %al

    pushfq	# RFLAGS 压栈
    popq	%r12	# 立刻弹进 r12（成对操作，栈保持平衡）

    leaq	fmt_set(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	lbl_saved(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    movq	%r12, %rdi
    call	l_putflags
    call	l_nl

# --------------------------------------------------------
# 2. 再算一次，把标志全冲掉
# 1 + 1 = 2，不进位、不为零、不为负、不溢出
# --------------------------------------------------------
    movb	$1, %al
    addb	$1, %al

    pushfq
    popq	%r14

    leaq	fmt_chg(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	lbl_curr(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    movq	%r14, %rdi
    call	l_putflags
    call	l_nl

# --------------------------------------------------------
# 3. 把第 1 步存下的标志装回去
# push r12 / popfq 是一对：先当普通数据压栈，再让 CPU 吃进去
# --------------------------------------------------------
    pushq	%r12
    popfq	# RFLAGS = r12

    pushfq
    popq	%r14	# r14 = 恢复之后的 RFLAGS

    leaq	fmt_rst(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	lbl_rstd(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    movq	%r14, %rdi
    call	l_putflags
    call	l_nl

# --------------------------------------------------------
# 4. 两个证据，证明「真的恢复了」，而不只是看起来像
# --------------------------------------------------------
# 证据一：逐位比一比（只看 CF..OF 这 12 位）
    leaq	msg_cmp(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    xorl	%edi, %edi
    movq	%r14, %rax
    xorq	%r12, %rax
    andl	$0x0FFF, %eax	# 相同则为 0，ZF 随即被置起
    seteb	%dil	# dil = 1 表示完全一致
    call	l_putbool
    call	l_nl

# 证据二：直接让 CPU 按恢复后的标志跳一次
# CF 被恢复成 1，所以 jc 一定会跳
    pushq	%r12
    popfq
    jc	.L_maincf_is_one	# 真的跳过去，说明 CF 确实=1
    leaq	w_cf_zero(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_mainafter_cf
.L_maincf_is_one:
    leaq	w_cf_one(%rip), %rdi
    xorl	%eax, %eax
    call	printf
.L_mainafter_cf:

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %r12
    movq	-16(%rbp), %r14
    xorl	%eax, %eax
    leave
    ret


.data
w_cf_one: .string "   条件跳转确认：popfq 之后 jc 跳了 -> CF 确实是 1\n"
w_cf_zero: .string "   条件跳转确认：jc 没跳 -> CF 是 0（不该出现）\n"
