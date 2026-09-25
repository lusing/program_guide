	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_53: .string "CMP 5,3: sete=%lld setg=%lld setl=%lld\n"
fmt_35: .string "CMP 3,5: sete=%lld setg=%lld setl=%lld\n"
fmt_55: .string "CMP 5,5: sete=%lld (equal!)\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$32, %rsp
    movq	%r12, -8(%rbp)	# 三个被调用者保存寄存器，用来跨 printf 保存结果
    movq	%r13, -16(%rbp)
    movq	%r14, -24(%rbp)

# --------------------------------------------------------
# 测试 1：CMP 5,3 -> 5 - 3 = 2，ZF=0 SF=0 OF=0
# sete -> 0   setg -> 1   setl -> 0
# --------------------------------------------------------
    movq	$5, %rax
    movq	$3, %rdx
    cmpq	%rdx, %rax
    seteb	%r12b
    setgb	%r13b
    setlb	%r14b
    movzbq	%r12b, %r12
    movzbq	%r13b, %r13
    movzbq	%r14b, %r14

    leaq	fmt_53(%rip), %rdi
    movq	%r12, %rsi
    movq	%r13, %rdx
    movq	%r14, %rcx
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 测试 2：CMP 3,5 -> 3 - 5 = -2，ZF=0 SF=1 OF=0
# sete -> 0   setg -> 0   setl -> 1
# --------------------------------------------------------
    movq	$3, %rax
    movq	$5, %rdx
    cmpq	%rdx, %rax
    seteb	%r12b
    setgb	%r13b
    setlb	%r14b
    movzbq	%r12b, %r12
    movzbq	%r13b, %r13
    movzbq	%r14b, %r14

    leaq	fmt_35(%rip), %rdi
    movq	%r12, %rsi
    movq	%r13, %rdx
    movq	%r14, %rcx
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 测试 3：CMP 5,5 -> ZF=1，sete -> 1
# --------------------------------------------------------
    movq	$5, %rax
    movq	$5, %rdx
    cmpq	%rdx, %rax
    seteb	%r12b
    movzbq	%r12b, %r12

    leaq	fmt_55(%rip), %rdi
    movq	%r12, %rsi
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %r12
    movq	-16(%rbp), %r13
    movq	-24(%rbp), %r14
    xorl	%eax, %eax
    leave
    ret
