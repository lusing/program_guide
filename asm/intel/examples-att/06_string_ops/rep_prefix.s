	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */
.set cmp_len, 5
.set fill_len, 10

.data
# --- 1. rep movsb 的数据 ---
src_str: .string "World!"
.set src_len, .- src_str - 1	# 6

# --- 3/4. repe cmpsb 的数据 ---
cmp1: .string "Hello"
cmp2_same: .string "Hello"
cmp2_diff: .string "Hallo"

# --- 5. repne scasb 的数据 ---
strlen_str: .string "Hello"

# --- 2. rep stosb 的填充长度 ---

fmt_movsb: .string "1. rep movsb：把 [%s] 复制过去 -> dest = [%s]\n"
fmt_stosb: .string "2. rep stosb：用 '%c' 填了 %lld 个字节 -> [%s]\n"
fmt_cmp_eq: .string "3. repe cmpsb：[%s] 与 [%s] -> 完全相同\n"
fmt_cmp_df: .string "4. repe cmpsb：[%s] 与 [%s] -> 第 %lld 个字节起不同\n"
fmt_strlen: .string "5. repne scasb：strlen([%s]) = %lld\n"
fmt_done: .string "REP prefix comprehensive demo completed.\n"


.bss
dest_buf: .zero 64	# movsb 的目标缓冲区
fill_buf: .zero 64	# stosb 的填充缓冲区


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$32, %rsp
    movq	%r12, -8(%rbp)
    movq	%r13, -16(%rbp)
    movq	%r14, -24(%rbp)

# ========================================================
# 1. rep movsb —— 内存复制（这就是 memcpy 的内核）
# ========================================================
    leaq	src_str(%rip), %rsi	# RSI = 源
    leaq	dest_buf(%rip), %rdi	# RDI = 目标
    movq	$src_len, %rcx	# RCX = 字节数
    cld
    rep	movsb	# 复制 src_len 个字节
    movb	$0, dest_buf+src_len(%rip)	# 补上字符串结尾

    leaq	fmt_movsb(%rip), %rdi
    leaq	src_str(%rip), %rsi
    leaq	dest_buf(%rip), %rdx
    xorl	%eax, %eax
    call	printf

# ========================================================
# 2. rep stosb —— 内存填充（memset）
# 注意 MOVS/STOS 之后 RSI/RDI/RCX 都变了，参数必须重装
# ========================================================
    leaq	fill_buf(%rip), %rdi
    movb	$'#', %al	# AL = 填充字节
    movq	$fill_len, %rcx
    cld
    rep	stosb
    movb	$0, fill_buf+fill_len(%rip)

    leaq	fmt_stosb(%rip), %rdi
    movl	$'#', %esi	# %c：格式串里 %c 在前
    movq	$fill_len, %rdx	# %lld：长度
    leaq	fill_buf(%rip), %rcx	# %s：结果缓冲区
    xorl	%eax, %eax
    call	printf

# ========================================================
# 3. repe cmpsb —— 比较两个相同的串
# ========================================================
    leaq	cmp1(%rip), %rsi
    leaq	cmp2_same(%rip), %rdi
    movq	$cmp_len, %rcx
    cld
    repe	cmpsb
    setzb	%r12b	# 立刻保存 ZF（printf 会冲掉标志）

    testb	%r12b, %r12b
    jz	.L_mainneq3	# 本例不会走到这里
    leaq	fmt_cmp_eq(%rip), %rdi
    leaq	cmp1(%rip), %rsi
    leaq	cmp2_same(%rip), %rdx
    xorl	%eax, %eax
    call	printf
.L_mainneq3:

# ========================================================
# 4. repe cmpsb —— 比较两个不同的串
# ========================================================
    leaq	cmp1(%rip), %rsi
    leaq	cmp2_diff(%rip), %rdi
    movq	$cmp_len, %rcx
    cld
    repe	cmpsb

    setzb	%r12b	# r12b = 1 表示相等
    movq	%rcx, %r13	# r13 = 剩余未比字节数

    movq	$cmp_len, %r14
    subq	%r13, %r14
    decq	%r14	# 位置 = 长度 - 剩余 - 1

    testb	%r12b, %r12b
    jnz	.L_maineq4
    leaq	fmt_cmp_df(%rip), %rdi
    leaq	cmp1(%rip), %rsi
    leaq	cmp2_diff(%rip), %rdx
    movq	%r14, %rcx	# 首个不同的位置
    xorl	%eax, %eax
    call	printf
    jmp	.L_mainskip4
.L_maineq4:
    leaq	fmt_cmp_eq(%rip), %rdi
    leaq	cmp1(%rip), %rsi
    leaq	cmp2_diff(%rip), %rdx
    xorl	%eax, %eax
    call	printf
.L_mainskip4:

# ========================================================
# 5. repne scasb —— 求 strlen 的经典技巧
# RCX 先设成 -1（最大值），扫到 '\0' 停下后
# strlen = ~RCX - 1
# ========================================================
    leaq	strlen_str(%rip), %rdi
    xorb	%al, %al	# AL = 0，找的就是字符串结尾
    movq	$-1, %rcx	# RCX = 0xFFFFFFFFFFFFFFFF
    cld
    repne	scasb	# 不等（ZF=0）就继续扫

    notq	%rcx	# RCX = 已扫字节数（含 '\0'）
    decq	%rcx	# 去掉 '\0' 就是长度
    movq	%rcx, %r12

    leaq	fmt_strlen(%rip), %rdi
    leaq	strlen_str(%rip), %rsi
    movq	%r12, %rdx
    xorl	%eax, %eax
    call	printf

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %r12
    movq	-16(%rbp), %r13
    movq	-24(%rbp), %r14
    xorl	%eax, %eax
    leave
    ret
