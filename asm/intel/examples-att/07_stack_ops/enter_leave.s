	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_manual: .string "1. 手动建帧（push rbp; mov rbp,rsp; sub rsp,64）：\n"
fmt_vars1: .string "   [rbp-8]=%lld, [rbp-16]=%lld, [rbp-24]=%lld\n"
fmt_enter: .string "2. ENTER 建帧（enter 64,0）：\n"
fmt_vars2: .string "   [rbp-8]=%lld, [rbp-16]=%lld, [rbp-24]=%lld\n"
fmt_equiv: .string "   （enter 64,0 与三条指令完全等价）\n"
fmt_done: .string "ENTER/LEAVE demo completed.\n"


.text

main:

# ========================================================
# 第 1 部分：手动建立栈帧
# push rbp      -- 保存调用者的帧指针
# mov rbp, rsp  -- RBP 钉在当前栈顶，之后局部变量都用 [rbp-N] 访问
# sub rsp, 64   -- 一次性开 64 字节局部变量空间
# 注意 SysV 没有影子空间，这 64 字节全是自己的。
# ========================================================
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$64, %rsp

    movq	$42, -8(%rbp)	# 局部变量 1
    movq	$100, -16(%rbp)	# 局部变量 2
    movq	$7, -24(%rbp)	# 局部变量 3

    leaq	fmt_manual(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_vars1(%rip), %rdi
    movq	-8(%rbp), %rsi	# 第 2 个参数
    movq	-16(%rbp), %rdx	# 第 3 个参数
    movq	-24(%rbp), %rcx	# 第 4 个参数
    xorl	%eax, %eax
    call	printf

    leave	# mov rsp,rbp; pop rbp，帧整体拆掉

# ========================================================
# 第 2 部分：用 ENTER 一条指令建立同样的帧
# ========================================================
    enter	$0, $64	# 建帧 + 分配 64 字节

    movq	$200, -8(%rbp)
    movq	$300, -16(%rbp)
    movq	$400, -24(%rbp)

    leaq	fmt_enter(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_vars2(%rip), %rdi
    movq	-8(%rbp), %rsi	# 200
    movq	-16(%rbp), %rdx	# 300
    movq	-24(%rbp), %rcx	# 400
    xorl	%eax, %eax
    call	printf

    leaq	fmt_equiv(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leave

# ========================================================
# 收尾：再建一个标准帧来打印结束语，然后正常 leave/ret
# （Linux 上 main 是被调用的，栈上有返回地址，可以放心 ret）
# ========================================================
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    xorl	%eax, %eax
    leave
    ret
