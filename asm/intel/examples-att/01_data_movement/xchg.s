	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
var: .quad 111

fmt_before: .string "寄存器交换前: rax=%lld, rbx=%lld\n"
fmt_after: .string "寄存器交换后: rax=%lld, rbx=%lld (xchg rax,rbx)\n"
fmt_m_before: .string "内存交换前:   var=%lld, rax=%lld\n"
fmt_m_after: .string "内存交换后:   var=%lld, rax=%lld (xchg [var],rax)\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$48, %rsp	# 5 个栈槽，存被调用者保存寄存器的原值
    movq	%rbx, -8(%rbp)
    movq	%r12, -16(%rbp)
    movq	%r13, -24(%rbp)
    movq	%r14, -32(%rbp)
    movq	%r15, -40(%rbp)

# --- 寄存器间交换 ---
# 用非易失寄存器(r12-r15)保存交换前/后的值，避免被 printf 破坏
    movq	$10, %rax
    movq	$20, %rbx
    movq	%rax, %r12	# r12 = 交换前 rax = 10
    movq	%rbx, %r13	# r13 = 交换前 rbx = 20
    xchgq	%rbx, %rax	# 交换后 rax=20, rbx=10
    movq	%rax, %r14	# r14 = 交换后 rax = 20
    movq	%rbx, %r15	# r15 = 交换后 rbx = 10
    leaq	fmt_before(%rip), %rdi
    movq	%r12, %rsi
    movq	%r13, %rdx
    xorl	%eax, %eax
    call	printf
    leaq	fmt_after(%rip), %rdi
    movq	%r14, %rsi
    movq	%r15, %rdx
    xorl	%eax, %eax
    call	printf

# --- 寄存器与内存交换 ---
    movq	$111, var(%rip)
    movq	$222, %rax
    movq	var(%rip), %r12	# r12 = 交换前 var = 111
    movq	%rax, %r13	# r13 = 交换前 rax = 222
    xchgq	%rax, var(%rip)	# 交换后 var=222, rax=111
    movq	var(%rip), %r14	# r14 = 交换后 var = 222
    movq	%rax, %r15	# r15 = 交换后 rax = 111
    leaq	fmt_m_before(%rip), %rdi
    movq	%r12, %rsi
    movq	%r13, %rdx
    xorl	%eax, %eax
    call	printf
    leaq	fmt_m_after(%rip), %rdi
    movq	%r14, %rsi
    movq	%r15, %rdx
    xorl	%eax, %eax
    call	printf

# 还原被调用者保存寄存器
    movq	-8(%rbp), %rbx
    movq	-16(%rbp), %r12
    movq	-24(%rbp), %r13
    movq	-32(%rbp), %r14
    movq	-40(%rbp), %r15

    xorl	%eax, %eax
    leave
    ret
