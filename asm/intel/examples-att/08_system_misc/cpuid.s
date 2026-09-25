	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.bss
vendor_buf: .zero 13	# 12 字符厂商串 + 结尾 0


.data
fms_val: .long 0	# Family/Model/Stepping 原始值
feat_edx: .long 0	# 特性位图（EDX）

fmt_vendor: .string "CPU 厂商字符串： %s\n"
fmt_maxleaf: .string "CPUID 最大页号： 0x%X\n"
fmt_fms: .string "Family: %d, Model: %d, Stepping: %d\n"
fmt_features: .string "特性位图 EDX: 0x%08X\n"
lbl_feat: .string "支持的特性： "
fmt_done: .string "CPUID demo completed.\n"

w_fpu: .string "FPU "
w_tsc: .string "TSC "
w_cmov: .string "CMOV "
w_mmx: .string "MMX "
w_sse: .string "SSE "
w_sse2: .string "SSE2 "
w_htt: .string "HTT "
w_nl: .byte 10, 0

# 一条小宏：第 1 个参数是位号，第 2 个是要打印的字符串标签
# （%%skip 里的 %% 是 NASM 宏局部标签的写法，避免多次展开撞名）
	.text
.macro showfeat p1, p2
    btl	$\p1, %r13d
    jnc	99f
    leaq	\p2, %rdi
    xorl	%eax, %eax
    call	printf
99:
.endm


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$32, %rsp
    movq	%rbx, -8(%rbp)	# CPUID 会踩 EBX，先存一份
    movq	%r12, -16(%rbp)
    movq	%r13, -24(%rbp)

# --------------------------------------------------------
# 1. 页 0：厂商字符串 + 最大页号
# EBX = 第 0-3 个字符，EDX = 第 4-7 个，ECX = 第 8-11 个
# --------------------------------------------------------
    xorl	%eax, %eax
    cpuid
    movl	%eax, %r12d	# 最大页号留着后面用

    movl	%ebx, vendor_buf(%rip)	# "Genu"
    movl	%edx, vendor_buf+4(%rip)	# "ineI"
    movl	%ecx, vendor_buf+8(%rip)	# "ntel"
    movb	$0, vendor_buf+12(%rip)	# 字符串收尾

    leaq	fmt_vendor(%rip), %rdi
    leaq	vendor_buf(%rip), %rsi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_maxleaf(%rip), %rdi
    movq	%r12, %rsi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 2. 页 1：Family/Model/Stepping 和特性位图
# 结果必须马上搬进 callee-saved 寄存器，printf 会冲掉 eax/edx
# --------------------------------------------------------
    movl	$1, %eax
    cpuid
    movl	%eax, fms_val(%rip)
    movl	%edx, feat_edx(%rip)

# --------------------------------------------------------
# 3. 所有 CPUID 都取完了，把 EBX 还原
# --------------------------------------------------------
    movq	-8(%rbp), %rbx

    leaq	fmt_features(%rip), %rdi
    movl	feat_edx(%rip), %esi	# %08X
    xorl	%eax, %eax
    call	printf

    leaq	lbl_feat(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    movl	feat_edx(%rip), %r13d	# 宏里用 r13d 做 bt 的源
showfeat	0, w_fpu
showfeat	4, w_tsc
showfeat	15, w_cmov
showfeat	23, w_mmx
showfeat	25, w_sse
showfeat	26, w_sse2
showfeat	28, w_htt
    leaq	w_nl(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 4. 拆 Family/Model/Stepping
# Stepping = EAX[3:0]
# Model    = EAX[7:4] | (EAX[19:16] << 4)
# Family   = EAX[11:8]（若等于 0xF，还要加 EAX[27:20]）
# --------------------------------------------------------
    movl	fms_val(%rip), %r13d

    movl	%r13d, %eax
    andl	$0xF, %eax	# Stepping
    movl	%eax, %ecx

    movl	%r13d, %eax
    shrl	$4, %eax
    andl	$0xF, %eax	# 基础 Model
    movl	%r13d, %edx
    shrl	$16, %edx
    andl	$0xF, %edx	# 扩展 Model
    shll	$4, %edx
    orl	%edx, %eax	# Model = 两者拼接
    movl	%eax, %edx

    movl	%r13d, %eax
    shrl	$8, %eax
    andl	$0xF, %eax	# 基础 Family
    cmpl	$0xF, %eax
    jne	.L_mainno_ext_fam
    movl	%r13d, %r8d
    shrl	$20, %r8d
    andl	$0xFF, %r8d	# 扩展 Family
    addl	%r8d, %eax
.L_mainno_ext_fam:

    leaq	fmt_fms(%rip), %rdi
    movl	%eax, %esi	# Family
# rdx 已经是 Model
# rcx 已经是 Stepping
    xorl	%eax, %eax
    call	printf

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %rbx
    movq	-16(%rbp), %r12
    movq	-24(%rbp), %r13
    xorl	%eax, %eax
    leave
    ret
