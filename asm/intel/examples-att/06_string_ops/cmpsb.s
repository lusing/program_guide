	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */
.set str_len, 5

.data
str1: .string "Hello"	# 基准串
str2_same: .string "Hello"	# 与 str1 相同
str2_diff: .string "Hallo"	# 与 str1 不同（第 2 个字节起）

fmt_hdr: .string "%lld. 比较 [%s] 与 [%s]：\n"
fmt_equal: .string "   结果：完全相同（%lld 个字节全部命中）\n"
fmt_diff: .string "   结果：第 %lld 个字节起不同（RCX 还剩 %lld 字节没比）\n"
fmt_done: .string "CMPS/CMPSB demo completed.\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$32, %rsp
    movq	%r12, -8(%rbp)	# r12-r15 是被调用者保存寄存器，
    movq	%r13, -16(%rbp)	# 这里借它们跨 printf 存中间结果，
    movq	%r14, -24(%rbp)	# 退场前一律还原（main 用 ret 返回，
    movq	%r15, -32(%rbp)	# 破坏它们会让 libc 启动代码崩溃）

    movq	$1, %r15	# 比较序号

# --------------------------------------------------------
# 1. 相同的两个串："Hello" vs "Hello"
# --------------------------------------------------------
    leaq	str1(%rip), %rsi	# RSI = 串1
    leaq	str2_same(%rip), %rdi	# RDI = 串2
    movq	$str_len, %rcx	# RCX = 比较长度
    cld	# DF=0，指针递增
    repe	cmpsb	# 相等就继续，不等或 RCX=0 停下

    movq	%rcx, %r13	# 剩余未比较字节数
    setzb	%r12b	# ZF=1（全部相等）时 r12b=1

    leaq	fmt_hdr(%rip), %rdi
    movq	%r15, %rsi	# %lld：序号
    leaq	str1(%rip), %rdx	# %s：串1
    leaq	str2_same(%rip), %rcx	# %s：串2
    xorl	%eax, %eax
    call	printf

    testb	%r12b, %r12b	# 用保存下来的 ZF（printf 已把标志冲掉）
    jz	.L_maindiff1
    leaq	fmt_equal(%rip), %rdi
    movq	$str_len, %rsi
    xorl	%eax, %eax
    call	printf
    jmp	.L_mainnext1
.L_maindiff1:
    movq	$str_len, %rax
    subq	%r13, %rax
    decq	%rax	# 位置 = 长度 - 剩余 - 1
    leaq	fmt_diff(%rip), %rdi
    movq	%rax, %rsi	# %lld：位置
    movq	%r13, %rdx	# %lld：剩余
    xorl	%eax, %eax
    call	printf
.L_mainnext1:

# --------------------------------------------------------
# 2. 不同的两个串："Hello" vs "Hallo"
# 'e'(0x65) - 'a'(0x61) = 4 -> ZF=0，在第二个字节处停止
# --------------------------------------------------------
    incq	%r15
    leaq	str1(%rip), %rsi
    leaq	str2_diff(%rip), %rdi
    movq	$str_len, %rcx
    cld
    repe	cmpsb

    movq	%rcx, %r13
    setzb	%r12b

    leaq	fmt_hdr(%rip), %rdi
    movq	%r15, %rsi
    leaq	str1(%rip), %rdx
    leaq	str2_diff(%rip), %rcx
    xorl	%eax, %eax
    call	printf

    testb	%r12b, %r12b
    jz	.L_maindiff2
    leaq	fmt_equal(%rip), %rdi
    movq	$str_len, %rsi
    xorl	%eax, %eax
    call	printf
    jmp	.L_mainnext2
.L_maindiff2:
    movq	$str_len, %rax
    subq	%r13, %rax
    decq	%rax
    leaq	fmt_diff(%rip), %rdi
    movq	%rax, %rsi
    movq	%r13, %rdx
    xorl	%eax, %eax
    call	printf
.L_mainnext2:

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
