	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_push: .string "压栈顺序：10, 20, 30\n"
fmt_pop: .string "  第 %lld 次 pop： %lld\n"
fmt_note: .string "栈是 LIFO 的：最后压进去的 30 最先弹出来。\n"
fmt_done: .string "PUSH/POP registers demo completed.\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$32, %rsp
    movq	%r12, -8(%rbp)	# 借 r12-r14 存弹出值，先备份原值
    movq	%r13, -16(%rbp)
    movq	%r14, -24(%rbp)

    leaq	fmt_push(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 依次压入 10、20、30
# push 10  -> [RSP]   = 10   （最先压入，落在高地址）
# push 20  -> [RSP-8] = 20
# push 30  -> [RSP-16]= 30   （最后压入，正好在栈顶）
# --------------------------------------------------------
    pushq	$10
    pushq	$20
    pushq	$30

# --------------------------------------------------------
# 按 LIFO 弹出：30、20、10
# --------------------------------------------------------
    popq	%r12	# r12 = 30（最后压入，最先弹出）
    popq	%r13	# r13 = 20
    popq	%r14	# r14 = 10（最先压入，最后弹出）

# 此时 RSP 已回到原位、对齐也恢复，可以放心调 printf
    leaq	fmt_pop(%rip), %rdi
    movq	$1, %rsi	# 弹出序号
    movq	%r12, %rdx	# 值 = 30
    xorl	%eax, %eax
    call	printf

    leaq	fmt_pop(%rip), %rdi
    movq	$2, %rsi
    movq	%r13, %rdx	# 值 = 20
    xorl	%eax, %eax
    call	printf

    leaq	fmt_pop(%rip), %rdi
    movq	$3, %rsi
    movq	%r14, %rdx	# 值 = 10
    xorl	%eax, %eax
    call	printf

    leaq	fmt_note(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %r12
    movq	-16(%rbp), %r13
    movq	-24(%rbp), %r14
    xorl	%eax, %eax
    leave
    ret
