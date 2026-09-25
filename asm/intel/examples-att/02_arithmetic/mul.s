	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
fmt8: .string "8位 mul:   255 * 10        => AX = %d (0x%x)\n"
fmt16: .string "16位 mul:  1000 * 100      => DX:AX = %lld\n"
fmt32: .string "32位 mul:  4000000000 * 2  => EDX:EAX = %llu\n"
fmt64: .string "64位 mul:  0xFFFFFFFFFFFFFFFF * 2 => RDX:RAX = 0x%016llx%016llx\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    movq	%rbx, -8(%rbp)

# --- 8 位: mul bl -> AX = AL * BL ---
    movb	$255, %al
    movb	$10, %bl
    mulb	%bl	# AX = 2550
    movzwl	%ax, %r10d
    leaq	fmt8(%rip), %rdi
    movl	%r10d, %esi	# %d
    movl	%r10d, %edx	# %x
    xorl	%eax, %eax
    call	printf

# --- 16 位: mul bx -> DX:AX = AX * BX ---
    movw	$1000, %ax
    movw	$100, %bx
    mulw	%bx	# DX:AX = 100000
    movzwq	%dx, %rsi	# 高 16 位
    shlq	$16, %rsi
    movzwl	%ax, %eax	# 低 16 位
    orq	%rax, %rsi
    leaq	fmt16(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --- 32 位: mul ebx -> EDX:EAX = EAX * EBX ---
    movl	$4000000000, %eax	# 0xEE6B2800
    movl	$2, %ebx
    mull	%ebx	# EDX:EAX = 8000000000
    shlq	$32, %rdx	# 高 32 位移到高位（RDX 已被零扩展）
    orq	%rax, %rdx	# 拼成完整 64 位
    leaq	fmt32(%rip), %rdi
    movq	%rdx, %rsi
    xorl	%eax, %eax
    call	printf

# --- 64 位: mul rbx -> RDX:RAX = RAX * RBX ---
    movq	$0xFFFFFFFFFFFFFFFF, %rax
    movq	$2, %rbx
    mulq	%rbx	# RDX=1, RAX=0xFFFFFFFFFFFFFFFE
    leaq	fmt64(%rip), %rdi
    movq	%rdx, %rsi	# 第 2 个参数 = 高 64 位（先装 rsi）
    movq	%rax, %rdx	# 第 3 个参数 = 低 64 位
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %rbx
    xorl	%eax, %eax
    leave
    ret
