	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
src8: .byte 0xFF	# 8 位源 (无符号 255 / 有符号 -1)
src16: .word 0xFFFF	# 16 位源 (无符号 65535 / 有符号 -1)
src32: .long 0xFFFFFF80	# 32 位源 (无符号 4294967168 / 有符号 -128)

fmt_zx8_32: .string "MOVZX 8->32:    0xFF       => %u\n"
fmt_zx16_32: .string "MOVZX 16->32:   0xFFFF     => %u\n"
fmt_zx8_64: .string "MOVZX 8->64:    0xFF       => %llu\n"
fmt_zx16_64: .string "MOVZX 16->64:   0xFFFF     => %llu\n"
fmt_sx8_32: .string "MOVSX 8->32:    0xFF       => %d\n"
fmt_sx16_32: .string "MOVSX 16->32:   0xFFFF     => %d\n"
fmt_sx8_64: .string "MOVSX 8->64:    0xFF       => %lld\n"
fmt_sxd32: .string "MOVSXD 32->64:  0xFFFFFF80 => %lld\n"
fmt_cmp: .string "对比 0xFF: 零扩展(MOVZX)=%llu, 符号扩展(MOVSX)=%lld\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp

# MOVZX 8->32 (无符号零扩展): 0xFF => 255
    movzbl	src8(%rip), %eax
    leaq	fmt_zx8_32(%rip), %rdi
    movl	%eax, %esi	# %u 只取低 32 位
    xorl	%eax, %eax
    call	printf

# MOVZX 16->32: 0xFFFF => 65535
    movzwl	src16(%rip), %eax
    leaq	fmt_zx16_32(%rip), %rdi
    movl	%eax, %esi
    xorl	%eax, %eax
    call	printf

# MOVZX 8->64: 0xFF => 255
    movzbq	src8(%rip), %rax
    leaq	fmt_zx8_64(%rip), %rdi
    movq	%rax, %rsi	# %llu 要 64 位
    xorl	%eax, %eax
    call	printf

# MOVZX 16->64: 0xFFFF => 65535
    movzwq	src16(%rip), %rax
    leaq	fmt_zx16_64(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# MOVSX 8->32 (有符号符号扩展): 0xFF => -1
    movsbl	src8(%rip), %eax
    leaq	fmt_sx8_32(%rip), %rdi
    movl	%eax, %esi
    xorl	%eax, %eax
    call	printf

# MOVSX 16->32: 0xFFFF => -1
    movswl	src16(%rip), %eax
    leaq	fmt_sx16_32(%rip), %rdi
    movl	%eax, %esi
    xorl	%eax, %eax
    call	printf

# MOVSX 8->64: 0xFF => -1
    movsbq	src8(%rip), %rax
    leaq	fmt_sx8_64(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# MOVSXD 32->64: 0xFFFFFF80 => -128
    movslq	src32(%rip), %rax
    leaq	fmt_sxd32(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# 对比: 同一个字节 0xFF，零扩展得 255，符号扩展得 -1
    movzbq	src8(%rip), %rsi	# 第 2 个参数 -> %llu
    movsbq	src8(%rip), %rdx	# 第 3 个参数 -> %lld
    leaq	fmt_cmp(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
