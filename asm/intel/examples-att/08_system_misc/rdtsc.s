	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_ts1: .string "第一次 RDTSC 时间戳： %llu\n"
fmt_ts2: .string "第二次 RDTSC 时间戳： %llu\n"
fmt_start: .string "测量段起点： %llu\n"
fmt_end: .string "测量段终点： %llu\n"
fmt_cycles: .string "1000 次 NOP 循环消耗的周期数： %llu\n"
fmt_rdtscp: .string "RDTSCP（序列化）时间戳： %llu\n"
fmt_note: .string "提示：这个数会随负载浮动，但连续两次读一定严格递增。\n"
fmt_done: .string "RDTSC demo completed.\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$32, %rsp
    movq	%r12, -8(%rbp)
    movq	%r13, -16(%rbp)
    movq	%r14, -24(%rbp)	# 测量段起点
    movq	%r15, -32(%rbp)	# 测量段终点

# --------------------------------------------------------
# 1. 第一次读取
# --------------------------------------------------------
    rdtsc
    shlq	$32, %rdx
    orq	%rdx, %rax
    movq	%rax, %r12

    leaq	fmt_ts1(%rip), %rdi
    movq	%r12, %rsi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 2. 再读一次，验证单调递增
# --------------------------------------------------------
    rdtsc
    shlq	$32, %rdx
    orq	%rdx, %rax
    movq	%rax, %r13

    leaq	fmt_ts2(%rip), %rdi
    movq	%r13, %rsi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 3. 量一段代码：1000 次 NOP 循环
# --------------------------------------------------------
    rdtsc
    shlq	$32, %rdx
    orq	%rdx, %rax
    movq	%rax, %r14	# 起点

    movl	$1000, %ecx
.L_mainmeasure_loop:
    nop
    decl	%ecx
    jnz	.L_mainmeasure_loop

    rdtsc
    shlq	$32, %rdx
    orq	%rdx, %rax
    movq	%rax, %r15	# 终点

    leaq	fmt_start(%rip), %rdi
    movq	%r14, %rsi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_end(%rip), %rdi
    movq	%r15, %rsi
    xorl	%eax, %eax
    call	printf

    movq	%r15, %rax
    subq	%r14, %rax	# 周期差
    leaq	fmt_cycles(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 4. RDTSCP：序列化版本，还会把 CPU 编号写进 ECX
# --------------------------------------------------------
    rdtscp
    shlq	$32, %rdx
    orq	%rdx, %rax
    movq	%rax, %r12

    leaq	fmt_rdtscp(%rip), %rdi
    movq	%r12, %rsi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_note(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %r12
    movq	-16(%rbp), %r13
    movq	-24(%rbp), %r14
    movq	-32(%rbp), %r15
    xorl	%eax, %eax
    leave
    ret
