	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_jg: .string "JG:  5 > 3   -> Greater (JG taken)\n"
fmt_jl: .string "JL: -1 < 1   -> Less (JL taken)\n"
fmt_jge: .string "JGE: 3 >= 3  -> Greater or equal (JGE taken)\n"
fmt_jle: .string "JLE: 3 <= 3  -> Less or equal (JLE taken)\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp

# --- JG：5 - 3 = 2，SF=0 OF=0 ZF=0 -> SF=OF 且 ZF=0 -> 跳 ---
    movq	$5, %rax
    movq	$3, %rdx
    cmpq	%rdx, %rax
    jg	.L_mainjg_taken
    jmp	.L_mainafter_jg
.L_mainjg_taken:
    leaq	fmt_jg(%rip), %rdi
    xorl	%eax, %eax
    call	printf
.L_mainafter_jg:

# --- JL：-1 - 1 = -2，SF=1 OF=0 ZF=0 -> SF≠OF -> 跳 ---
    movq	$-1, %rax	# = 0xFFFFFFFFFFFFFFFF
    movq	$1, %rdx
    cmpq	%rdx, %rax
    jl	.L_mainjl_taken
    jmp	.L_mainafter_jl
.L_mainjl_taken:
    leaq	fmt_jl(%rip), %rdi
    xorl	%eax, %eax
    call	printf
.L_mainafter_jl:

# --- JGE：3 - 3 = 0，SF=0 OF=0 ZF=1 -> SF=OF -> 跳 ---
    movq	$3, %rax
    movq	$3, %rdx
    cmpq	%rdx, %rax
    jge	.L_mainjge_taken
    jmp	.L_mainafter_jge
.L_mainjge_taken:
    leaq	fmt_jge(%rip), %rdi
    xorl	%eax, %eax
    call	printf
.L_mainafter_jge:

# --- JLE：同样 3 - 3 = 0，ZF=1 就够了 -> 跳 ---
    movq	$3, %rax
    movq	$3, %rdx
    cmpq	%rdx, %rax
    jle	.L_mainjle_taken
    jmp	.L_mainafter_jle
.L_mainjle_taken:
    leaq	fmt_jle(%rip), %rdi
    xorl	%eax, %eax
    call	printf
.L_mainafter_jle:

    xorl	%eax, %eax
    leave
    ret
