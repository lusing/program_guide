	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt: .string "Sum 1+2+...+10 = %lld (LOOP with ECX=10)\n"
fmt_ecx: .string "循环结束后 ECX = %lld（LOOP 直接把它减到 0）\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

# --------------------------------------------------------
# mov ecx, 10 会顺手把 RCX 高 32 位清零，所以 RCX = 10
# r10 是调用者保存寄存器，循环体里没有任何 call，可以放心当累加器
# --------------------------------------------------------
    movl	$10, %ecx	# 计数器
    xorl	%r10d, %r10d	# 累加器 = 0

.L_mainlp:
    addq	%rcx, %r10	# r10 += 当前计数值（10, 9, …, 1）
    loop	.L_mainlp	# ECX -= 1，非 0 就跳回 .L_mainlp
# 此时 r10 = 55，RCX = 0

    movq	%rcx, -8(%rbp)	# 把 ECX 留个证据

    leaq	fmt(%rip), %rdi
    movq	%r10, %rsi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_ecx(%rip), %rdi
    movq	-8(%rbp), %rsi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
