	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_je: .string "JE:  5 == 5  -> Equal (JE taken)\n"
fmt_jne: .string "JNE: 5 != 3  -> Not equal (JNE taken)\n"
fmt_match: .string "If-else: 42 == 42 -> Match\n"
fmt_nomatch: .string "If-else: 42 == 42 -> No match\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp

# --------------------------------------------------------
# JE：ZF=1 时跳转，也就是「相等」
# CMP 做 5 - 5 = 0，只设标志位不写回结果 -> ZF=1
# --------------------------------------------------------
    movq	$5, %rax
    movq	$5, %rdx
    cmpq	%rdx, %rax
    je	.L_mainequal_taken
    jmp	.L_mainafter_je
.L_mainequal_taken:
    leaq	fmt_je(%rip), %rdi
    xorl	%eax, %eax
    call	printf
.L_mainafter_je:

# --------------------------------------------------------
# JNE：ZF=0 时跳转，也就是「不等」
# CMP 做 5 - 3 = 2 -> ZF=0
# --------------------------------------------------------
    movq	$5, %rax
    movq	$3, %rdx
    cmpq	%rdx, %rax
    jne	.L_mainnotequal_taken
    jmp	.L_mainafter_jne
.L_mainnotequal_taken:
    leaq	fmt_jne(%rip), %rdi
    xorl	%eax, %eax
    call	printf
.L_mainafter_jne:

# --------------------------------------------------------
# if-else 的汇编套路：
# if (value == target) { ... } else { ... }
# 编译器习惯把「不满足条件的分支」放在前面，
# 这样条件成立时可以直接跳过去，少一条 JMP。
# --------------------------------------------------------
    movq	$42, %rax	# value
    movq	$42, %rdx	# target
    cmpq	%rdx, %rax
    je	.L_mainif_match

# --- else 分支 ---
    leaq	fmt_nomatch(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_mainafter_ifelse

.L_mainif_match:
# --- if 分支 ---
    leaq	fmt_match(%rip), %rdi
    xorl	%eax, %eax
    call	printf

.L_mainafter_ifelse:

    xorl	%eax, %eax
    leave
    ret
