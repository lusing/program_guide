	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */
.set str_len, 5

.data
search_str: .string "Hello"

fmt_search: .string "%lld. 在 [%s] 里找 '%c'\n"
fmt_found: .string "   找到了，位置 %lld（从 0 数起）\n"
fmt_not: .string "   没找到（%lld 字节全扫完了，RCX 归零）\n"
fmt_done: .string "SCAS/SCASB demo completed.\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$32, %rsp
    movq	%r12, -8(%rbp)	# r12-r15 都是被调用者保存寄存器，
    movq	%r13, -16(%rbp)	# 这里借它们跨 printf 存中间结果，
    movq	%r14, -24(%rbp)	# 退场前一律还原
    movq	%r15, -32(%rbp)

    movq	$1, %r15	# 序号计数器

# --------------------------------------------------------
# 1. 找 'o'（存在，位置 4）
# --------------------------------------------------------
    movb	$'o', %al
    movzbl	%al, %r12d	# 存下要找的字符，供 printf 用
    leaq	search_str(%rip), %rdi
    movq	$str_len, %rcx
    cld
    repne	scasb	# 一直扫到 ZF=1 或 RCX=0
    movq	%rcx, %r13	# 剩余未扫描字节数
    setzb	%r14b	# 找到则为 1

    leaq	fmt_search(%rip), %rdi
    movq	%r15, %rsi	# 第 2 个参数 %lld：序号
    leaq	search_str(%rip), %rdx	# 第 3 个参数 %s：字符串
    movq	%r12, %rcx	# 第 4 个参数 %c：字符
    xorl	%eax, %eax
    call	printf

    testb	%r14b, %r14b
    jz	.L_mainnot1
    movq	$str_len, %rax
    subq	%r13, %rax
    decq	%rax	# 位置 = 长度 - 剩余 - 1
    leaq	fmt_found(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf
    jmp	.L_mainnext1
.L_mainnot1:
    leaq	fmt_not(%rip), %rdi
    movq	$str_len, %rsi
    xorl	%eax, %eax
    call	printf
.L_mainnext1:

# --------------------------------------------------------
# 2. 找 'l'（存在，位置 2）
# --------------------------------------------------------
    incq	%r15
    movb	$'l', %al
    movzbl	%al, %r12d
    leaq	search_str(%rip), %rdi
    movq	$str_len, %rcx
    cld
    repne	scasb
    movq	%rcx, %r13
    setzb	%r14b

    leaq	fmt_search(%rip), %rdi
    movq	%r15, %rsi
    leaq	search_str(%rip), %rdx
    movq	%r12, %rcx
    xorl	%eax, %eax
    call	printf

    testb	%r14b, %r14b
    jz	.L_mainnot2
    movq	$str_len, %rax
    subq	%r13, %rax
    decq	%rax
    leaq	fmt_found(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf
    jmp	.L_mainnext2
.L_mainnot2:
    leaq	fmt_not(%rip), %rdi
    movq	$str_len, %rsi
    xorl	%eax, %eax
    call	printf
.L_mainnext2:

# --------------------------------------------------------
# 3. 找 'x'（不存在，RCX 会被扫到 0）
# --------------------------------------------------------
    incq	%r15
    movb	$'x', %al
    movzbl	%al, %r12d
    leaq	search_str(%rip), %rdi
    movq	$str_len, %rcx
    cld
    repne	scasb
    movq	%rcx, %r13
    setzb	%r14b

    leaq	fmt_search(%rip), %rdi
    movq	%r15, %rsi
    leaq	search_str(%rip), %rdx
    movq	%r12, %rcx
    xorl	%eax, %eax
    call	printf

    testb	%r14b, %r14b
    jz	.L_mainnot3
    movq	$str_len, %rax
    subq	%r13, %rax
    decq	%rax
    leaq	fmt_found(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf
    jmp	.L_mainnext3
.L_mainnot3:
    leaq	fmt_not(%rip), %rdi
    movq	$str_len, %rsi
    xorl	%eax, %eax
    call	printf
.L_mainnext3:

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
