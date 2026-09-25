	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
var: .quad 100	# 测试用内存变量
byte_v: .byte 0
word_v: .word 0
dword_v: .long 0
qword_v: .quad 0

fmt_imm: .string "立即数->寄存器: mov rax,42          => rax = %lld\n"
fmt_reg: .string "寄存器->寄存器: mov rbx,rax         => rbx = %lld\n"
fmt_m2r: .string "内存->寄存器:   mov rax,[var]       => rax = %lld\n"
fmt_r2m: .string "寄存器->内存:   mov [var],rax       => var = %lld\n"
fmt_byte: .string "字节传送: mov byte [b],0x41         => b   = %d (0x%02x)\n"
fmt_word: .string "字传送:   mov word [w],0x1234       => w   = %d (0x%04x)\n"
fmt_dword: .string "双字传送: mov dword [d],0x12345678   => d   = %d (0x%08x)\n"
fmt_qword: .string "四字传送: mov qword [q],0x123456789ABCDEF0 => q = 0x%016llx\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp	# 16 字节暂存区（System V 不需要 Windows 那样的影子空间）
    movq	%rbx, -8(%rbp)	# rbx 是被调用者保存寄存器，退出前必须还原

# 立即数到寄存器
    movq	$42, %rax
    leaq	fmt_imm(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax	# 没有浮点参数 -> al = 0
    call	printf

# 寄存器到寄存器 (重新载入 rax, 因 printf 会破坏 rax 返回值)
    movq	$42, %rax
    movq	%rax, %rbx	# rbx = 42
    leaq	fmt_reg(%rip), %rdi
    movq	%rbx, %rsi
    xorl	%eax, %eax
    call	printf

# 内存到寄存器
    movq	var(%rip), %rax
    leaq	fmt_m2r(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# 寄存器到内存
    movq	$999, %rax
    movq	%rax, var(%rip)
    leaq	fmt_r2m(%rip), %rdi
    movq	var(%rip), %rsi
    xorl	%eax, %eax
    call	printf

# 不同大小: byte (0x41 = 65)
    movb	$0x41, byte_v(%rip)
    movzbl	byte_v(%rip), %eax
    leaq	fmt_byte(%rip), %rdi
    movl	%eax, %esi	# %d
    movl	%eax, %edx	# %02x
    xorl	%eax, %eax
    call	printf

# 不同大小: word (0x1234 = 4660)
    movw	$0x1234, word_v(%rip)
    movzwl	word_v(%rip), %eax
    leaq	fmt_word(%rip), %rdi
    movl	%eax, %esi
    movl	%eax, %edx
    xorl	%eax, %eax
    call	printf

# 不同大小: dword (0x12345678)
    movl	$0x12345678, dword_v(%rip)
    movl	dword_v(%rip), %eax
    leaq	fmt_dword(%rip), %rdi
    movl	%eax, %esi
    movl	%eax, %edx
    xorl	%eax, %eax
    call	printf

# 不同大小: qword (0x123456789ABCDEF0)
    movq	$0x123456789ABCDEF0, %rax
    movq	%rax, qword_v(%rip)
    leaq	fmt_qword(%rip), %rdi
    movq	qword_v(%rip), %rsi
    xorl	%eax, %eax
    call	printf

# 还原被调用者保存寄存器，再从 main 正常返回
# 返回值放在 eax 里就是进程退出码（0 = 成功）
    movq	-8(%rbp), %rbx
    xorl	%eax, %eax
    leave
    ret
