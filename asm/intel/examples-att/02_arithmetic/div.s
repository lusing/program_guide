	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
fmt32: .string "32位 div: 100 / 7            => 商=%d, 余=%d\n"
fmt64: .string "64位 div: 1000000000000 / 3  => 商=%lld, 余=%lld\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    movq	%rbx, -8(%rbp)

# --- 32 位: EDX:EAX / EBX ---
    movl	$100, %eax
    xorl	%edx, %edx	# 清零高位（重要！）
    movl	$7, %ebx
    divl	%ebx	# EAX = 商 14，EDX = 余 2
    leaq	fmt32(%rip), %rdi
    movl	%eax, %esi	# 第 2 个参数 = 商
# 32 位写 EDX 会自动把 RDX 的高 32 位清零，所以这里 rdx 已经是干净的余数
    xorl	%eax, %eax
    call	printf

# --- 64 位: RDX:RAX / RBX ---
    movq	$1000000000000, %rax
    xorq	%rdx, %rdx	# 清零高位（重要！）
    movq	$3, %rbx
    divq	%rbx	# RAX = 商 333333333333，RDX = 余 1
    leaq	fmt64(%rip), %rdi
    movq	%rax, %rsi	# 第 2 个参数 = 商
# rdx 就是余数，直接当第 3 个参数
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %rbx
    xorl	%eax, %eax
    leave
    ret
