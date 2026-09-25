	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
src_str: .string "Hello, NASM!"	# 源字符串
.set src_len, .- src_str - 1	# 长度（不含结尾的 0）= 12

fmt_single: .string "1. movsb: 复制 1 字节 -> dest[0] = '%c' (0x%02X)\n"
fmt_full: .string "2. rep movsb: 复制了 %lld 字节 -> dest = [%s]\n"
fmt_ptr: .string "   指针也动了：RSI 现在比源串开头大 %lld 字节\n"
fmt_done: .string "MOVS/MOVSB demo completed.\n"


.bss
dest_buf: .zero 64	# 目标缓冲区


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

# --------------------------------------------------------
# 1. movsb：把一个字节从 [RSI] 搬到 [RDI]，然后两个指针都 +1
# --------------------------------------------------------
    leaq	src_str(%rip), %rsi
    leaq	dest_buf(%rip), %rdi
    movq	%rsi, %r10	# 记下源串开头（r10 是调用者保存，这里够用）
    cld	# DF=0，向前走
    movsb	# dest_buf[0] = 'H'；RSI/RDI 各 +1
    movq	%rsi, %r11
    subq	%r10, %r11	# r11 = 1，指针正好前进 1 字节
    movq	%r11, -8(%rbp)	# 要跨 printf，先落栈

# 打印：注意 rsi/rdi 刚刚被 movsb 改过，参数要重新装
    movzbl	dest_buf(%rip), %esi	# %c 用
    movl	%esi, %edx	# 0x%02X 用
    leaq	fmt_single(%rip), %rdi	# rdi 最后装，免得被上面两行冲掉
    xorl	%eax, %eax
    call	printf

# 把「指针走了多远」也打出来
    leaq	fmt_ptr(%rip), %rdi
    movq	-8(%rbp), %rsi
    xorl	%eax, %eax
    call	printf

# --------------------------------------------------------
# 2. rep movsb：重复 RCX 次，等价于 memcpy(dest, src, 12)
# --------------------------------------------------------
    leaq	src_str(%rip), %rsi
    leaq	dest_buf(%rip), %rdi
    movq	$src_len, %rcx
    cld
    rep	movsb
    movb	$0, dest_buf+src_len(%rip)	# 补上结尾的 0，好当 C 字符串打印

    movq	$src_len, %rsi	# 第 2 个参数：字节数
    leaq	dest_buf(%rip), %rdx	# 第 3 个参数：目标串
    leaq	fmt_full(%rip), %rdi	# 第 1 个参数最后装
    xorl	%eax, %eax
    call	printf

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
