	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_nop1: .string "1. 单字节 NOP（0x90）已执行。\n"
fmt_nop2: .string "2. 多字节 NOP（0x66 0x90，2 字节）已执行。\n"
fmt_align: .string "3. ALIGN 16：下一条指令被垫到 16 字节边界。\n"
fmt_loop: .string "4. 循环入口对齐后跑了 5 圈，NOP 垫在循环体里。\n"
fmt_done: .string "NOP and ALIGN demo completed.（NOP 不改动任何状态）\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    movq	%r12, -8(%rbp)	# 循环里借了 r12，退场要还原

# --------------------------------------------------------
# 1. 单字节 NOP：不改变任何寄存器或标志位
# --------------------------------------------------------
    nop
    leaq	fmt_nop1(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 2. 多字节 NOP：0x66 是操作数大小前缀，0x90 是 NOP，
# 两个字节合起来仍是一条合法指令（不读内存）
# --------------------------------------------------------
	.byte 0x66, 0x90
    leaq	fmt_nop2(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 3. ALIGN 16：NASM 会自动插入足够多的 NOP 让下一条
# 指令落在 16 字节边界上
# --------------------------------------------------------
	.balign 16
    leaq	fmt_align(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 4. 循环入口对齐：把 .L_mainloop_start 垫到 16 字节边界，
# 让每次迭代都从同一条取指线上的同一个位置开始
# --------------------------------------------------------
	.balign 16
    movl	$5, %r12d
.L_mainloop_start:
    nop	# 这里在真实代码里可能就是热补丁的位置
    nop
    decl	%r12d
    jnz	.L_mainloop_start

    leaq	fmt_loop(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %r12
    xorl	%eax, %eax
    leave
    ret
