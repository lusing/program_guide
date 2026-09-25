	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
fmt_inc: .string "inc rax: %lld + 1 => %lld\n"
fmt_dec: .string "dec rax: %lld - 1 => %lld\n"
fmt_neg: .string "neg rax: neg(%lld) => %lld\n"
fmt_cf: .string "INC 不影响 CF：先 stc 把 CF 置 1，inc 之后 CF 仍然是 %d\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

# inc: 41 + 1 = 42
    movq	$41, %rax
    incq	%rax	# rax = 42
    leaq	fmt_inc(%rip), %rdi
    movq	$41, %rsi
    movq	%rax, %rdx
    xorl	%eax, %eax
    call	printf

# dec: 100 - 1 = 99
    movq	$100, %rax
    decq	%rax	# rax = 99
    leaq	fmt_dec(%rip), %rdi
    movq	$100, %rsi
    movq	%rax, %rdx
    xorl	%eax, %eax
    call	printf

# neg: neg(55) = -55（等价于 0 - x，同时按二进制补码取反加一）
    movq	$55, %rax
    negq	%rax	# rax = -55
    leaq	fmt_neg(%rip), %rdi
    movq	$55, %rsi
    movq	%rax, %rdx
    xorl	%eax, %eax
    call	printf

# INC 不影响 CF：先 stc 置 CF=1，再做 inc，CF 仍是 1
    stc	# CF = 1
    incq	%rax	# rax = -54，CF 保持不变
    setcb	%sil	# sil = CF
    movzbq	%sil, %rsi
    pushfq
    popq	%r10	# 顺便把整套标志位抓下来看看
    leaq	fmt_cf(%rip), %rdi
    movq	%r10, -8(%rbp)
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %rdi
    call	l_putflags
    call	l_nl

    xorl	%eax, %eax
    leave
    ret

	.include "att_io.s"
