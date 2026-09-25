	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
fmt1: .string "单操作数 imul rbx       : %lld * %lld => rax = %lld\n"
fmt2: .string "双操作数 imul rax,rbx   : %lld * %lld => rax = %lld\n"
fmt3: .string "三操作数 imul rax,rbx,10: %lld * 10  => rax = %lld\n"
fmt_neg: .string "负数乘法: %lld * %lld   => %lld\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    movq	%rbx, -8(%rbp)

# --- 单操作数: imul rbx -> RDX:RAX = RAX * RBX ---
    movq	$6, %rax
    movq	$7, %rbx
    imulq	%rbx	# 积在 RAX（有符号时高位放 RDX）
    movq	%rax, %rcx	# 先把结果挪到 rcx，免得下面盖掉 rdx
    leaq	fmt1(%rip), %rdi
    movq	$6, %rsi
    movq	$7, %rdx
    xorl	%eax, %eax
    call	printf

# --- 双操作数: imul rax, rbx ---
    movq	$12, %rax
    movq	$8, %rbx
    imulq	%rbx, %rax	# rax = 96
    movq	%rax, %rcx
    leaq	fmt2(%rip), %rdi
    movq	$12, %rsi
    movq	$8, %rdx
    xorl	%eax, %eax
    call	printf

# --- 三操作数: imul rax, rbx, 立即数 ---
    movq	$5, %rbx
    imulq	$10, %rbx, %rax	# rax = 5 * 10 = 50
    leaq	fmt3(%rip), %rdi
    movq	$5, %rsi
    movq	%rax, %rdx
    xorl	%eax, %eax
    call	printf

# --- 负数乘法: -7 * 3 ---
    movq	$-7, %rax
    movq	$3, %rbx
    imulq	%rbx, %rax	# rax = -21
    leaq	fmt_neg(%rip), %rdi
    movq	$-7, %rsi
    movq	$3, %rdx
    movq	%rax, %rcx
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %rbx
    xorl	%eax, %eax
    leave
    ret
