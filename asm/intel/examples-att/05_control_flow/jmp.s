	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_before: .string "Before jump\n"
fmt_skip: .string "Skipped\n"	# 这行永远不会被打印
fmt_after: .string "After jump\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp

# --- 打印 "Before jump" ---
    leaq	fmt_before(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --- 无条件跳转到 .L_mainafter_skip ---
# JMP 不看任何标志位，跳过去就是了
    jmp	.L_mainafter_skip

# --- 以下代码被跳过，永远不会执行 ---
    leaq	fmt_skip(%rip), %rdi
    xorl	%eax, %eax
    call	printf

.L_mainafter_skip:
# --- 打印 "After jump" ---
    leaq	fmt_after(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax	# 退出码 0
    leave
    ret
