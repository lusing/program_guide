	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_and: .string "AND  0xFF & 0x0F        = 0x%llx\n"
fmt_or: .string "OR   0xF0 | 0x0F        = 0x%llx\n"
fmt_xor: .string "XOR  0xFF ^ 0x0F        = 0x%llx\n"
fmt_not: .string "NOT  ~0x0               = 0x%llx\n"
fmt_clr: .string "XOR  0xDEADBEEF ^ self  = 0x%llx（清零惯用法）\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp

# --- AND: 按位与，掩码提取低 4 位 ---
    movq	$0xFF, %rax
    andq	$0x0F, %rax
    leaq	fmt_and(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# --- OR: 按位或，置上低 4 位 ---
    movq	$0xF0, %rax
    orq	$0x0F, %rax
    leaq	fmt_or(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# --- XOR: 按位异或，翻转低 4 位 ---
    movq	$0xFF, %rax
    xorq	$0x0F, %rax
    leaq	fmt_xor(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# --- NOT: 按位取反（注意 NOT 不影响任何标志位） ---
    movq	$0x0, %rax
    notq	%rax
    leaq	fmt_not(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# --- XOR 自身清零：比 mov rax,0 更短，而且顺手清掉 CF/OF ---
    movq	$0xDEADBEEF, %rax
    xorq	%rax, %rax
    leaq	fmt_clr(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax	# 退出码 0
    leave
    ret
