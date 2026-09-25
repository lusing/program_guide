	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_add: .string "add_numbers(%lld, %lld) = %lld\n"
fmt_mul: .string "multiply(%lld, %lld) = %lld\n"
fmt_s4: .string "sum4(%lld, %lld, %lld, %lld) = %lld\n"


.text

# ------------------------------------------------------------
# add_numbers: 两数相加
# 输入: rdi = a, rsi = b
# 输出: rax = a + b
# ------------------------------------------------------------
add_numbers:
    movq	%rdi, %rax
    addq	%rsi, %rax
    ret

# ------------------------------------------------------------
# multiply: 两数相乘（有符号）
# 输入: rdi = a, rsi = b
# 输出: rax = a * b
# ------------------------------------------------------------
multiply:
    movq	%rdi, %rax
    imulq	%rsi, %rax
    ret

# ------------------------------------------------------------
# sum4: 四个参数相加，顺便演示第 3、4 个参数用的是 rdx 和 rcx
# 输入: rdi, rsi, rdx, rcx
# 输出: rax
# 
# 这个函数只用 rax，不碰被调用者保存寄存器，
# 所以既不需要建栈帧、也不需要 push/pop —— 这是「叶子函数」的标准长相。
# ------------------------------------------------------------
sum4:
    movq	%rdi, %rax
    addq	%rsi, %rax
    addq	%rdx, %rax
    addq	%rcx, %rax
    ret

# ============================================================
# main
# ============================================================
main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    movq	%r12, -8(%rbp)	# r12 用来跨 printf 保存返回值，先存原值

# --------------------------------------------------------
# add_numbers(10, 20)
# SysV：第 1 个参数 rdi，第 2 个参数 rsi，返回值 rax
# --------------------------------------------------------
    movq	$10, %rdi
    movq	$20, %rsi
    call	add_numbers
    movq	%rax, %r12	# 返回值落地（printf 会毁掉 rax）

    leaq	fmt_add(%rip), %rdi
    movq	$10, %rsi
    movq	$20, %rdx
    movq	%r12, %rcx
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# multiply(7, 6)
# --------------------------------------------------------
    movq	$7, %rdi
    movq	$6, %rsi
    call	multiply
    movq	%rax, %r12

    leaq	fmt_mul(%rip), %rdi
    movq	$7, %rsi
    movq	$6, %rdx
    movq	%r12, %rcx
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# add_numbers(100, 200)
# --------------------------------------------------------
    movq	$100, %rdi
    movq	$200, %rsi
    call	add_numbers
    movq	%rax, %r12

    leaq	fmt_add(%rip), %rdi
    movq	$100, %rsi
    movq	$200, %rdx
    movq	%r12, %rcx
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# multiply(15, 15)
# --------------------------------------------------------
    movq	$15, %rdi
    movq	$15, %rsi
    call	multiply
    movq	%rax, %r12

    leaq	fmt_mul(%rip), %rdi
    movq	$15, %rsi
    movq	$15, %rdx
    movq	%r12, %rcx
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# sum4(1, 2, 3, 4)：四个参数按 rdi rsi rdx rcx 依次装
# 注意装在 rdi/rsi 里的常量必须一开始就放好，
# 别在中间调用别的函数把它们冲掉。
# --------------------------------------------------------
    movq	$1, %rdi
    movq	$2, %rsi
    movq	$3, %rdx
    movq	$4, %rcx
    call	sum4
    movq	%rax, %r12

    leaq	fmt_s4(%rip), %rdi
    movq	$1, %rsi
    movq	$2, %rdx
    movq	$3, %rcx
    movq	$4, %r8	# 第 5 个参数
    movq	%r12, %r9	# 第 6 个参数
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %r12
    xorl	%eax, %eax
    leave
    ret
