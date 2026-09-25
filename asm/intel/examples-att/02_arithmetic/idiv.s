	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
fmt_pos: .string "正数: 100 / 7   => 商=%lld, 余=%lld\n"
fmt_neg: .string "负数: -100 / 7  => 商=%lld, 余=%lld（向零截断）\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    movq	%rbx, -8(%rbp)

# --- 正数: 100 / 7 ---
    movq	$100, %rax
    cqo	# RDX = RAX 的符号扩展（正数 => 0）
    movq	$7, %rbx
    idivq	%rbx	# RAX = 商 14，RDX = 余 2
    leaq	fmt_pos(%rip), %rdi
    movq	%rax, %rsi	# 第 2 个参数 = 商（rsi 先装好）
# rdx 里就是余数，直接当第 3 个参数用
    xorl	%eax, %eax	# 这只清掉 rax，rsi/rdx 不受影响
    call	printf

# --- 负数: -100 / 7 ---
    movq	$-100, %rax
    cqo	# RDX = 0xFFFFFFFFFFFFFFFF
    movq	$7, %rbx
    idivq	%rbx	# RAX = 商 -14，RDX = 余 -2
    leaq	fmt_neg(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %rbx
    xorl	%eax, %eax
    leave
    ret
