	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
val_a: .double 3.14	# 较大
val_b: .double 2.72	# 较小
result: .double 0.0	# 只是给 fstp 一个落点，用来清栈

fmt_fcomi_gt: .string "FCOMI: 3.14 > 2.72 成立（CF=0 ZF=0 -> JA）\n"
fmt_fcomi_eq: .string "FCOMI: 3.14 == 2.72 成立（CF=0 ZF=1 -> JE）\n"
fmt_fcomi_lt: .string "FCOMI: 3.14 < 2.72 成立（CF=1 ZF=0 -> JB）\n"
fmt_fcom_gt: .string "FCOM : 3.14 > 2.72 成立（经 FPU 状态字转换）\n"
fmt_fcom_eq: .string "FCOM : 3.14 == 2.72 成立（经 FPU 状态字转换）\n"
fmt_fcom_lt: .string "FCOM : 3.14 < 2.72 成立（经 FPU 状态字转换）\n"
fmt_done: .string "FPU compare demo completed.\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

    finit

# --------------------------------------------------------
# 1. FCOMI：直接设置 EFLAGS
# 先压小的再压大的，于是 ST0 = 3.14、ST1 = 2.72
# --------------------------------------------------------
    fld	val_b(%rip)	# ST0 = 2.72
    fld	val_a(%rip)	# ST0 = 3.14, ST1 = 2.72
    fcomi	%st(1)	# 只设标志，不动栈

    ja	.L_mainfcomi_greater
    jb	.L_mainfcomi_less
# 落到这里说明相等

.L_mainfcomi_equal:
    fstp	result(%rip)	# 清掉 ST0
    fstp	result(%rip)	# 清掉 ST1（栈深归零）
    leaq	fmt_fcomi_eq(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_maindo_fcom

.L_mainfcomi_greater:
    fstp	result(%rip)
    fstp	result(%rip)
    leaq	fmt_fcomi_gt(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_maindo_fcom

.L_mainfcomi_less:
    fstp	result(%rip)
    fstp	result(%rip)
    leaq	fmt_fcomi_lt(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_maindo_fcom

# --------------------------------------------------------
# 2. FCOM：老路子，得先搬状态字再搬标志位
# --------------------------------------------------------
.L_maindo_fcom:
    fld	val_b(%rip)	# ST0 = 2.72
    fld	val_a(%rip)	# ST0 = 3.14, ST1 = 2.72
    fcom	%st(1)	# 结果只写进 FPU 状态字

    fnstsw	%ax	# AX = FPU 状态字
    sahf	# AH -> EFLAGS（C0->CF, C2->PF, C3->ZF）

    ja	.L_mainfcom_greater
    jb	.L_mainfcom_less

.L_mainfcom_equal:
    fstp	result(%rip)
    fstp	result(%rip)
    leaq	fmt_fcom_eq(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_maindone

.L_mainfcom_greater:
    fstp	result(%rip)
    fstp	result(%rip)
    leaq	fmt_fcom_gt(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_maindone

.L_mainfcom_less:
    fstp	result(%rip)
    fstp	result(%rip)
    leaq	fmt_fcom_lt(%rip), %rdi
    xorl	%eax, %eax
    call	printf

.L_maindone:
    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
