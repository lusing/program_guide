	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
fmt_add: .string "ADC 128位加法: 低位 0x%016llx + 1 => 高位=0x%016llx 低位=0x%016llx\n"
fmt_sbb: .string "SBB 带借位减法: %lld - %lld - 1(CF) = %lld\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$32, %rsp
    movq	%rbx, -8(%rbp)

# --- ADC: 128 位加法 ---
# 低 64 位 = 0xFFFFFFFFFFFFFFFF，高 64 位 = 0，加 1：
# 低 64 位溢出把 CF 置 1，ADC 再把 CF 加到高 64 位上。
    movq	$0xFFFFFFFFFFFFFFFF, %rax	# 低 64 位
    movq	$0, %rdx	# 高 64 位
    movq	$1, %rbx
    addq	%rbx, %rax	# 低 64 位 +1 -> 回绕成 0, CF=1
    adcq	$0, %rdx	# 高 64 位 += 0 + CF = 1
# 结果: 高位=1, 低位=0 => 0x1_0000000000000000 (= 2^64)
    leaq	fmt_add(%rip), %rdi
    movq	$0xFFFFFFFFFFFFFFFF, %rsi	# 第 2 个参数 = 原始低位
    movq	%rax, %rcx	# 第 4 个参数 = 结果低位
# rdx 里现在就是结果高位，直接当第 3 个参数用；rcx 必须在 mov rdx 之前装好
    xorl	%eax, %eax
    call	printf

# --- SBB: 带借位减法 ---
# stc 把 CF 置 1，sbb rax,rbx 等价于 rax - rbx - CF
    movq	$100, %rax
    movq	$30, %rbx
    movq	$100, %rsi	# 被减数
    movq	$30, %rdx	# 减数
    stc	# CF = 1
    sbbq	%rbx, %rax	# rax = 100 - 30 - 1 = 69
# 标志位必须紧贴 sbb 抓：后面 lea/xor/call 全会改 RFLAGS，
# 尤其 printf 返回后标志位完全是 libc 的遗留值（macOS 上实测 PF 会变）。
    pushfq
    popq	%r10
    movq	%r10, -16(%rbp)	# 快照存进栈槽，等 printf 打完再取出来
    movq	%rax, %rcx	# 结果
    leaq	fmt_sbb(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# 打 SBB 那一刻的标志位（快照，不是 printf 留下的）
    movq	-16(%rbp), %rdi
    call	l_putflags
    call	l_nl

    movq	-8(%rbp), %rbx
    xorl	%eax, %eax
    leave
    ret

	.include "att_io.s"
