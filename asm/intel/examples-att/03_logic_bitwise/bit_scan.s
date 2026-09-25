	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
fmt_bsf: .string "BSF  0x%llx -> 最低置1位下标 %lld  (低->高)\n"
fmt_bsr: .string "BSR  0x%llx -> 最高置1位下标 %lld  (高->低)\n"
fmt_log2: .string "顺带求 log2(0x%llx 向上取整) = %lld\n"
fmt_zero: .string "BSF/BSR 遇到 0x0 -> ZF=1（目标值未定义，别用）\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    movq	%rbx, -8(%rbp)	# rbx 全程用作扫描输入，退场要还原

# --- BSF: 0x50 = 0b1010000，最低位的 1 在 bit 4 ---
    movq	$0x50, %rbx
    bsfq	%rbx, %rax	# rax = 4
    leaq	fmt_bsf(%rip), %rdi
    movq	%rbx, %rsi
    movq	%rax, %rdx
    xorl	%eax, %eax
    call	printf

# --- BSR: 同一个数的最高位 1 在 bit 6 ---
    movq	$0x50, %rbx
    bsrq	%rbx, %rax	# rax = 6
    leaq	fmt_bsr(%rip), %rdi
    movq	%rbx, %rsi
    movq	%rax, %rdx
    xorl	%eax, %eax
    call	printf

# --- 实用套路：BSR + 1 就是「向上取整的 log2」，用来算位图要几级 ---
    movq	$0x9, %rbx	# 0b1001 -> 最高位在 bit3
    bsrq	%rbx, %rax
    incq	%rax	# 3 + 1 = 4，即「4 位能装下 9」
    leaq	fmt_log2(%rip), %rdi
    movq	%rbx, %rsi
    movq	%rax, %rdx
    xorl	%eax, %eax
    call	printf

# --- 源为 0：ZF=1，结果不可信，所以要先判断 ---
    movq	$0, %rbx
    bsfq	%rbx, %rax	# 源是 0 -> ZF=1
    jnz	.L_mainskip_zero	# ZF=1 时不跳，走下面这一支
    leaq	fmt_zero(%rip), %rdi
    xorl	%eax, %eax
    call	printf
.L_mainskip_zero:

    movq	-8(%rbp), %rbx
    xorl	%eax, %eax
    leave
    ret
