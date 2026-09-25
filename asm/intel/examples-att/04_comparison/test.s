	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_zero: .string "TEST 0, 0             -> ZF=1, value is zero\n"
fmt_nz: .string "TEST 0x%llx, self     -> ZF=0, value is non-zero\n"
fmt_odd: .string "TEST 0x%llx, 1        -> ZF=0, odd  (bit 0 = 1)\n"
fmt_even: .string "TEST 0x%llx, 1        -> ZF=1, even (bit 0 = 0)\n"
fmt_b7s: .string "TEST 0x%llx, 0x80     -> ZF=0, bit 7 is SET\n"
fmt_b7c: .string "TEST 0x%llx, 0x80     -> ZF=1, bit 7 is CLEAR\n"
fmt_null: .string "TEST ptr, ptr (NULL)  -> ZF=1, pointer is NULL\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

# --- TEST rax, rax: 判零（值为 0） ---
    xorq	%rax, %rax
    testq	%rax, %rax
    jnz	.L_maint1_nz
    leaq	fmt_zero(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_maint1_done
.L_maint1_nz:
    leaq	fmt_nz(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf
.L_maint1_done:

# --- TEST rax, rax: 判非零（值为 42） ---
    movq	$42, %rax
    testq	%rax, %rax
    jnz	.L_maint2_nz
    leaq	fmt_zero(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_maint2_done
.L_maint2_nz:
    leaq	fmt_nz(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf
.L_maint2_done:

# --- TEST rax, 1: 判奇偶（7：奇） ---
    movq	$7, %rax
    testq	$1, %rax
    jz	.L_maint3_even
    leaq	fmt_odd(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf
    jmp	.L_maint3_done
.L_maint3_even:
    leaq	fmt_even(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf
.L_maint3_done:

# --- TEST rax, 1: 判奇偶（8：偶） ---
    movq	$8, %rax
    testq	$1, %rax
    jz	.L_maint4_even
    leaq	fmt_odd(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf
    jmp	.L_maint4_done
.L_maint4_even:
    leaq	fmt_even(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf
.L_maint4_done:

# --- TEST rax, 0x80: 第 7 位已置（0x80） ---
    movq	$0x80, %rax
    testq	$0x80, %rax
    jz	.L_maint5_clear
    leaq	fmt_b7s(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf
    jmp	.L_maint5_done
.L_maint5_clear:
    leaq	fmt_b7c(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf
.L_maint5_done:

# --- TEST rax, 0x80: 第 7 位为零（0x7F） ---
    movq	$0x7F, %rax
    testq	$0x80, %rax
    jz	.L_maint6_clear
    leaq	fmt_b7s(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf
    jmp	.L_maint6_done
.L_maint6_clear:
    leaq	fmt_b7c(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf
.L_maint6_done:

# --- 实战：NULL 指针检测 ---
# test rax, rax 是检查指针是否为空的标准写法，比 cmp rax,0 短
    xorq	%rax, %rax	# 模拟空指针
    testq	%rax, %rax
    jnz	.L_maint7_notnull
    leaq	fmt_null(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_maint7_done
.L_maint7_notnull:
    leaq	fmt_nz(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf
.L_maint7_done:

    xorl	%eax, %eax
    leave
    ret
