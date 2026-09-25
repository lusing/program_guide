	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
a_val: .double 3.14	# 被加数
b_val: .double 2.72	# 加数
c_val: .double 10.5	# 被减数
d_val: .double 3.7	# 减数
result: .double 0.0	# 结果暂存

fmt_add: .string "FADDP:      3.14 + 2.72 = %f\n"
fmt_sub: .string "FSUBP:      10.5 - 3.7  = %f\n"
fmt_addm: .string "FADD [mem]: 3.14 + 2.72 = %f   （ST0 += 内存，不弹栈）\n"
fmt_done: .string "FPU add/sub demo completed.\n"

# 把 ST0 存到内存、搬进 xmm0、用 %f 打出来。
# 注意 `mov eax, 1`：告诉 printf「我用了 1 个向量寄存器」。
	.text
.macro print_st0 p1
    fstp	result(%rip)	# ST0 -> 内存，并弹出
    movsd	result(%rip), %xmm0	# 内存 -> xmm0（SysV 第 1 个浮点参数）
    leaq	\p1(%rip), %rdi
    movl	$1, %eax
    call	printf
.endm


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

    finit	# 复位 FPU（控制字、栈指针、异常状态）

# --------------------------------------------------------
# 1. FADDP：先压 a，再压 b，栈顶相加后弹掉一格
# 栈：[a] -> [a, b] -> [a+b]
# --------------------------------------------------------
    fld	a_val(%rip)	# ST0 = 3.14
    fld	b_val(%rip)	# ST0 = 2.72, ST1 = 3.14
    faddp	# ST0 = 3.14 + 2.72 = 5.86
print_st0	fmt_add

# --------------------------------------------------------
# 2. FSUBP：方向是 ST1 - ST0
# 栈：[10.5] -> [10.5, 3.7] -> [10.5 - 3.7]
# --------------------------------------------------------
    fld	c_val(%rip)	# ST0 = 10.5
    fld	d_val(%rip)	# ST0 = 3.7, ST1 = 10.5
    fsubp	# ST0 = 10.5 - 3.7 = 6.8
print_st0	fmt_sub

# --------------------------------------------------------
# 3. FADD 直接吃内存操作数：栈深度不变
# --------------------------------------------------------
    fld	a_val(%rip)	# ST0 = 3.14
    fadd	b_val(%rip)	# ST0 = ST0 + 2.72 = 5.86
print_st0	fmt_addm

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
