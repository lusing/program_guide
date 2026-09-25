	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_of: .string "OF: 127 + 1 -> Overflow (JO taken, OF=1)\n"
fmt_sf: .string "SF: 0 - 1 -> Negative (JS taken, SF=1)\n"
fmt_pf: .string "PF: 3 (0b00000011, two 1s) -> Even parity (JP taken, PF=1)\n"
fmt_ovf: .string "  快照（127+1 之后）：\n"
fmt_neg: .string "  快照（0-1 之后）：\n"
fmt_par: .string "  快照（test al,al  之后，AL=3）：\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

# --------------------------------------------------------
# OF：AL = 127（8 位有符号最大值）+ 1 = 0x80 = -128，溢出 -> OF=1
# --------------------------------------------------------
    movb	$127, %al
    addb	$1, %al
    pushfq
    popq	%r10
    movq	%r10, -8(%rbp)
    jo	.L_mainof_detected
    jmp	.L_mainafter_of
.L_mainof_detected:
    leaq	fmt_of(%rip), %rdi
    xorl	%eax, %eax
    call	printf
.L_mainafter_of:
    leaq	fmt_ovf(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    movq	-8(%rbp), %rdi
    call	l_putflags
    call	l_nl

# --------------------------------------------------------
# SF：0 - 1 = -1 = 0xFFFFFFFF，最高位是 1 -> SF=1
# --------------------------------------------------------
    xorl	%eax, %eax
    subl	$1, %eax
    pushfq
    popq	%r10
    movq	%r10, -8(%rbp)
    js	.L_mainsf_detected
    jmp	.L_mainafter_sf
.L_mainsf_detected:
    leaq	fmt_sf(%rip), %rdi
    xorl	%eax, %eax
    call	printf
.L_mainafter_sf:
    leaq	fmt_neg(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    movq	-8(%rbp), %rdi
    call	l_putflags
    call	l_nl

# --------------------------------------------------------
# PF：AL = 3 = 0b00000011，低 8 位里有 2 个 1（偶数）-> PF=1
# TEST AL,AL 的结果就是 AL 本身，PF 只看结果低 8 位的奇偶性
# --------------------------------------------------------
    movb	$3, %al
    testb	%al, %al
    pushfq
    popq	%r10
    movq	%r10, -8(%rbp)
    jp	.L_mainpf_detected
    jmp	.L_mainafter_pf
.L_mainpf_detected:
    leaq	fmt_pf(%rip), %rdi
    xorl	%eax, %eax
    call	printf
.L_mainafter_pf:
    leaq	fmt_par(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    movq	-8(%rbp), %rdi
    call	l_putflags
    call	l_nl

    xorl	%eax, %eax
    leave
    ret

	.include "att_io.s"
