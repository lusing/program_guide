	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */
.set fill1_len, 20
.set fill2_len, 15

.data

fmt_fill: .string "%lld. rep stosb: 填了 %lld 字节，用的是 '%c'\n"
fmt_result: .string "   Result: [%s]\n"
fmt_done: .string "STOS/STOSB demo completed.\n"


.bss
buf1: .zero 64
buf2: .zero 64


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

# --------------------------------------------------------
# 1. rep stosb：用 '*' 填 20 字节  ==  memset(buf1, '*', 20)
# --------------------------------------------------------
    leaq	buf1(%rip), %rdi	# RDI = 目标
    movb	$'*', %al	# AL  = 填充值
    movq	$fill1_len, %rcx	# RCX = 次数
    cld	# DF=0，RDI 递增
    rep	stosb
    movb	$0, buf1+fill1_len(%rip)	# 补结尾 0

    leaq	fmt_fill(%rip), %rdi
    movq	$1, %rsi	# 序号
    movq	$fill1_len, %rdx	# 长度
    movl	$'*', %ecx	# 字符
    xorl	%eax, %eax
    call	printf

    leaq	fmt_result(%rip), %rdi
    leaq	buf1(%rip), %rsi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 2. rep stosb：用 '-' 填 15 字节
# --------------------------------------------------------
    leaq	buf2(%rip), %rdi
    movb	$'-', %al
    movq	$fill2_len, %rcx
    cld
    rep	stosb
    movb	$0, buf2+fill2_len(%rip)

    leaq	fmt_fill(%rip), %rdi
    movq	$2, %rsi
    movq	$fill2_len, %rdx
    movl	$'-', %ecx
    xorl	%eax, %eax
    call	printf

    leaq	fmt_result(%rip), %rdi
    leaq	buf2(%rip), %rsi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
