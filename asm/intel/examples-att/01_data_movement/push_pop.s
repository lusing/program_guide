	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
fmt_push: .string "push 顺序: %lld, %lld, %lld\n"
fmt_pop: .string "pop  顺序: %lld, %lld, %lld (后进先出 LIFO)\n"
fmt_imm: .string "push 立即数 0xFF 后 pop => %lld\n"
fmt_sp: .string "压栈前后 rsp 变化: %lld 字节\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp	# 自己的栈帧，用来存放要跨 printf 保留的值

# 打印将入栈的顺序
    leaq	fmt_push(%rip), %rdi
    movl	$1, %esi
    movl	$2, %edx
    movl	$3, %ecx
    xorl	%eax, %eax
    call	printf

# 入栈 1, 2, 3 (3 在栈顶)
# r10/r11 是调用者保存寄存器，只要中间不 call，就可以放心当临时变量用。
    movq	%rsp, %r10	# 压栈前的 rsp
    pushq	$1
    pushq	$2
    pushq	$3
    movq	%rsp, %r11	# 压了 3 个 = 24 字节

# rsp 差值（正数表示压栈后地址更低）
# r10/r11 是调用者保存寄存器，后面的 printf 会毁掉它们，
# 所以算出来先放进自己的栈帧 [rbp-8] 保存。
    movq	%r10, %rax
    subq	%r11, %rax
    movq	%rax, -8(%rbp)

# 出栈 (LIFO): 3, 2, 1
# 直接弹进 printf 的参数寄存器，顺序刚好就是 3、2、1
    popq	%rsi	# 3
    popq	%rdx	# 2
    popq	%rcx	# 1
    leaq	fmt_pop(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_sp(%rip), %rdi
    movq	-8(%rbp), %rsi
    xorl	%eax, %eax
    call	printf

# push 立即数 0xFF (=255), 再 pop
    pushq	$0xFF
    popq	%rax
    leaq	fmt_imm(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
