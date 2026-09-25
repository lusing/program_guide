	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_maxleaf: .string "CPUID 最大页号： 0x%X\n"
fmt_hybrid: .string "支持混合架构（大小核）： %s\n"
fmt_core: .string "当前核心类型： %s\n"
fmt_raw: .string "核心类型原始值： 0x%02X\n"
fmt_avx2: .string "AVX2： %s\n"
fmt_avx512: .string "AVX-512： %s\n"
fmt_note: .string "提示：本机若无 AVX2，后面的 SIMD 示例会用 SSE 路径。\n"
fmt_done: .string "Hybrid architecture detection completed.\n"

w_yes: .string "YES"
w_no: .string "NO"
w_pcore: .string "P-Core（性能核）"
w_ecore: .string "E-Core（能效核）"
w_unk: .string "未知 / 未报告"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$48, %rsp
    movq	%rbx, -8(%rbp)	# CPUID 会踩 EBX，必须还原
    movq	%r12, -16(%rbp)	# 最大页号
    movq	%r13, -24(%rbp)	# 核心类型字节
    movq	%r14, -32(%rbp)	# 页 7 的 EBX 位图
    movq	%r15, -40(%rbp)	# 是否支持混合架构

# --------------------------------------------------------
# 1. 页 0：最大页号
# --------------------------------------------------------
    xorl	%eax, %eax
    cpuid
    movl	%eax, %r12d

    leaq	fmt_maxleaf(%rip), %rdi
    movq	%r12, %rsi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 2. 页 1Ah：混合架构核心类型
# --------------------------------------------------------
    xorq	%r13, %r13	# core_type = 0
    xorq	%r15, %r15	# hybrid_supported = 0

    cmpl	$0x1A, %r12d
    jb	.L_mainskip_hybrid	# 没有这一页，跳过

    movl	$0x1A, %eax
    xorl	%ecx, %ecx
    cpuid
    shrl	$24, %eax	# EAX[31:24] = 核心类型
    andl	$0xFF, %eax
    movl	%eax, %r13d

    testl	%eax, %eax
    jz	.L_mainskip_hybrid	# 非 0 才算支持
    movq	$1, %r15
.L_mainskip_hybrid:

# --------------------------------------------------------
# 3. 页 7（子页 0）：AVX2 / AVX-512 位图
# --------------------------------------------------------
    xorq	%r14, %r14

    cmpl	$7, %r12d
    jb	.L_mainskip_leaf7

    movl	$7, %eax
    xorl	%ecx, %ecx
    cpuid
    movl	%ebx, %r14d
.L_mainskip_leaf7:

# --------------------------------------------------------
# 4. CPUID 全部完成，还原 EBX
# --------------------------------------------------------
    movq	-8(%rbp), %rbx

# ------ 混合架构支持？ ------
    leaq	fmt_hybrid(%rip), %rdi
    leaq	w_no(%rip), %rsi
    leaq	w_yes(%rip), %rdx
    testq	%r15, %r15
    cmovnzq	%rdx, %rsi
    xorl	%eax, %eax
    call	printf

# ------ 当前核心类型 ------
    leaq	fmt_core(%rip), %rdi
    leaq	w_unk(%rip), %rsi
    leaq	w_pcore(%rip), %rdx
    leaq	w_ecore(%rip), %rcx
    cmpl	$0x40, %r13d
    cmoveq	%rdx, %rsi	# P-Core
    cmpl	$0x20, %r13d
    cmoveq	%rcx, %rsi	# E-Core
    xorl	%eax, %eax
    call	printf

    leaq	fmt_raw(%rip), %rdi
    movq	%r13, %rsi
    xorl	%eax, %eax
    call	printf

# ------ AVX2（EBX bit 5）------
    leaq	fmt_avx2(%rip), %rdi
    leaq	w_no(%rip), %rsi
    leaq	w_yes(%rip), %rdx
    btl	$5, %r14d
    cmovcq	%rdx, %rsi
    xorl	%eax, %eax
    call	printf

# ------ AVX-512F（EBX bit 16）------
    leaq	fmt_avx512(%rip), %rdi
    leaq	w_no(%rip), %rsi
    leaq	w_yes(%rip), %rdx
    btl	$16, %r14d
    cmovcq	%rdx, %rsi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_note(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %rbx
    movq	-16(%rbp), %r12
    movq	-24(%rbp), %r13
    movq	-32(%rbp), %r14
    movq	-40(%rbp), %r15
    xorl	%eax, %eax
    leave
    ret
