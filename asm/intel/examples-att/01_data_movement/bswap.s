	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
fmt32: .string "32位反转: 0x12345678 -> bswap eax  => 0x%08x\n"
fmt64: .string "64位反转: 0x123456789ABCDEF0 -> bswap rax => 0x%016llx\n"
fmt16: .string "16位反转: 0xABCD -> rol ax,8       => 0x%04x (BSWAP 不支持 16 位)\n"
fmt_re: .string "再反转一次就回来了: 0x%016llx\n"

w16: .word 0xABCD


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp

# 32 位字节序反转: 0x12345678 -> 0x78563412
    movl	$0x12345678, %eax
    bswapl	%eax
    leaq	fmt32(%rip), %rdi
    movl	%eax, %esi
    xorl	%eax, %eax
    call	printf

# 16 位字节序反转: 0xABCD -> 0xCDAB（BSWAP 最小只到 32 位）
    movzwl	w16(%rip), %eax
    rolw	$8, %ax	# 高字节低字节互换
    leaq	fmt16(%rip), %rdi
    movl	%eax, %esi
    xorl	%eax, %eax
    call	printf

# 64 位字节序反转: 0x123456789ABCDEF0 -> 0xF0DEBC9A78563412
    movq	$0x123456789ABCDEF0, %rax
    bswapq	%rax
    leaq	fmt64(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# 反转两次得到原值
# 注意 printf 的返回值放在 eax（打印的字符数），rax 已经被破坏，
# 所以这里必须重新装载一遍，不能接着用上面的 rax。
    movq	$0x123456789ABCDEF0, %rax
    bswapq	%rax
    bswapq	%rax
    leaq	fmt_re(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
