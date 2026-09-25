	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
qarray: .quad 100, 200, 300, 400, 500, 600, 700, 800	# 8 字节元素数组
darray: .long 10, 20, 30, 40, 50, 60, 70, 80	# 4 字节元素数组

fmt_base: .string "简单地址: lea rax,[rbx]            => 0x%llx (数组首地址)\n"
fmt_off8: .string "偏移地址: lea rax,[rbx+8]          => 0x%llx (偏移+8)\n"
fmt_idx4: .string "乘法计算: lea rax,[rbx+r9*4]       => darray[2]=%d\n"
fmt_idx8: .string "乘法计算: lea rax,[rbx+r9*8]       => qarray[3]=%lld\n"
fmt_cplx: .string "复合计算: lea rax,[rbx+r9*8+16]    => qarray[5]=%lld\n"
fmt_mul3: .string "快速乘法: lea rax,[rax+rax*2] (x3) => 7*3=%lld\n"
fmt_mul5: .string "快速乘法: lea rax,[rax+rax*4] (x5) => 7*5=%lld\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    movq	%rbx, -8(%rbp)	# rbx 用来存数组基址，退场前要还原

# 简单地址: lea rax,[rbx] -> 取数组首地址
    leaq	qarray(%rip), %rbx
    leaq	(%rbx), %rax
    leaq	fmt_base(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# 偏移地址: lea rax,[rbx+8]
    leaq	8(%rbx), %rax
    leaq	fmt_off8(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# 乘法计算: lea rax,[rbx+r9*4] -> darray[2]=30
    leaq	darray(%rip), %rbx
    movq	$2, %r9
    leaq	(%rbx,%r9,4), %rax
    movl	(%rax), %esi	# 取出值 30
    leaq	fmt_idx4(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# 乘法计算: lea rax,[rbx+r9*8] -> qarray[3]=400
    leaq	qarray(%rip), %rbx
    movq	$3, %r9
    leaq	(%rbx,%r9,8), %rax
    movq	(%rax), %rsi	# 取出值 400
    leaq	fmt_idx8(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# 复合计算: lea rax,[rbx+r9*8+16] -> 3*8+16=40 => qarray[5]=600
    movq	$3, %r9
    leaq	16(%rbx,%r9,8), %rax
    movq	(%rax), %rsi	# 取出值 600
    leaq	fmt_cplx(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# 快速乘法 x3: lea rax,[rax+rax*2]
    movq	$7, %rax
    leaq	(%rax,%rax,2), %rax	# 7+14=21
    leaq	fmt_mul3(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# 快速乘法 x5: lea rax,[rax+rax*4]
    movq	$7, %rax
    leaq	(%rax,%rax,4), %rax	# 7+28=35
    leaq	fmt_mul5(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %rbx
    xorl	%eax, %eax
    leave
    ret
