	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_gt: .string "CMP %lld, %lld -> signed:  greater (JG)\n"
fmt_lt: .string "CMP %lld, %lld -> signed:  less (JL)\n"
fmt_eq: .string "CMP %lld, %lld -> equal (JE)\n"
fmt_ugt: .string "CMP 0x%llx, 0x%llx -> unsigned: above (JA)\n"
fmt_ult: .string "CMP 0x%llx, 0x%llx -> unsigned: below (JB)\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    movq	%rbx, -8(%rbp)	# rbx 用来放比较的右操作数

# === Case 1: CMP 5, 3 -> 有符号：大于 ===
# 5 - 3 = 2：ZF=0, SF=0, OF=0 -> SF=OF 且 ZF=0 -> JG 跳转
    movq	$5, %rax
    movq	$3, %rbx
    cmpq	%rbx, %rax
    je	.L_mainc1_eq
    jg	.L_mainc1_gt
    leaq	fmt_lt(%rip), %rdi
    jmp	.L_mainc1_print
.L_mainc1_eq:
    leaq	fmt_eq(%rip), %rdi
    jmp	.L_mainc1_print
.L_mainc1_gt:
    leaq	fmt_gt(%rip), %rdi
.L_mainc1_print:
    movq	%rax, %rsi
    movq	%rbx, %rdx
    xorl	%eax, %eax
    call	printf

# === Case 2: CMP 3, 5 -> 有符号：小于 ===
# 3 - 5 = -2：ZF=0, SF=1, OF=0 -> SF≠OF -> JL 跳转
    movq	$3, %rax
    movq	$5, %rbx
    cmpq	%rbx, %rax
    je	.L_mainc2_eq
    jg	.L_mainc2_gt
    leaq	fmt_lt(%rip), %rdi
    jmp	.L_mainc2_print
.L_mainc2_eq:
    leaq	fmt_eq(%rip), %rdi
    jmp	.L_mainc2_print
.L_mainc2_gt:
    leaq	fmt_gt(%rip), %rdi
.L_mainc2_print:
    movq	%rax, %rsi
    movq	%rbx, %rdx
    xorl	%eax, %eax
    call	printf

# === Case 3: CMP 5, 5 -> 相等 ===
# 5 - 5 = 0：ZF=1 -> JE 跳转
    movq	$5, %rax
    movq	$5, %rbx
    cmpq	%rbx, %rax
    je	.L_mainc3_eq
    jg	.L_mainc3_gt
    leaq	fmt_lt(%rip), %rdi
    jmp	.L_mainc3_print
.L_mainc3_eq:
    leaq	fmt_eq(%rip), %rdi
    jmp	.L_mainc3_print
.L_mainc3_gt:
    leaq	fmt_gt(%rip), %rdi
.L_mainc3_print:
    movq	%rax, %rsi
    movq	%rbx, %rdx
    xorl	%eax, %eax
    call	printf

# === Case 4: CMP -1, 1 -> 有符号：小于 ===
# -1 - 1 = -2：SF=1, OF=0 -> SF≠OF -> JL
    movq	$-1, %rax
    movq	$1, %rbx
    cmpq	%rbx, %rax
    je	.L_mainc4_eq
    jg	.L_mainc4_gt
    leaq	fmt_lt(%rip), %rdi
    jmp	.L_mainc4_print
.L_mainc4_eq:
    leaq	fmt_eq(%rip), %rdi
    jmp	.L_mainc4_print
.L_mainc4_gt:
    leaq	fmt_gt(%rip), %rdi
.L_mainc4_print:
    movq	%rax, %rsi
    movq	%rbx, %rdx
    xorl	%eax, %eax
    call	printf

# === Case 5: 同一对操作数 -1 / 1，换成无符号就是「大于」 ===
# -1 按无符号解释是 0xFFFFFFFFFFFFFFFF，比 1 大得多
# CF=0, ZF=0 -> JA 跳转
    movq	$-1, %rax
    movq	$1, %rbx
    cmpq	%rbx, %rax
    ja	.L_mainc5_above
    leaq	fmt_ult(%rip), %rdi
    jmp	.L_mainc5_print
.L_mainc5_above:
    leaq	fmt_ugt(%rip), %rdi
.L_mainc5_print:
    movq	%rax, %rsi
    movq	%rbx, %rdx
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %rbx
    xorl	%eax, %eax
    leave
    ret
