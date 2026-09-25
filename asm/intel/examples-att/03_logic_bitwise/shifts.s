	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_shl1: .string "SHL  0x1 << 1            = 0x%llx\n"
fmt_shl3: .string "SHL  0x1 << 3            = 0x%llx\n"
fmt_shr: .string "SHR  0x10 >> 1           = 0x%llx\n"
fmt_sar: .string "SAR  -8 >> 1 (signed)    = 0x%llx  (-8 / 2 = -4)\n"
fmt_shrn: .string "SHR  -8 >> 1 (unsigned)  = 0x%llx  (高位补 0)\n"
fmt_rol: .string "ROL  eax,4 (32位) 0x12345678 <<< 4 = 0x%llx\n"
fmt_ror: .string "ROR  eax,4 (32位) 0x12345678 >>> 4 = 0x%llx\n"
fmt_rol64: .string "ROL  rax,4 (64位) 0x12345678 <<< 4 = 0x%llx  (没绕回来)\n"
fmt_shlcl: .string "SHL  0x1 << CL(=4)       = 0x%llx\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp

# --- SHL: 逻辑左移 1 位（×2） ---
    movq	$1, %rax
    shlq	$1, %rax
    leaq	fmt_shl1(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# --- SHL: 左移 3 位（×8） ---
    movq	$1, %rax
    shlq	$3, %rax
    leaq	fmt_shl3(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# --- SHR: 逻辑右移 1 位（高位补 0） ---
    movq	$0x10, %rax
    shrq	$1, %rax
    leaq	fmt_shr(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# --- SAR: 算术右移 1 位（保留符号位）---
# -8 >> 1 = -4 = 0xFFFFFFFFFFFFFFFC
    movq	$-8, %rax
    sarq	$1, %rax
    leaq	fmt_sar(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# --- 同一个负数用 SHR：高位补 0，结果变成很大的无符号数 ---
    movq	$-8, %rax
    shrq	$1, %rax
    leaq	fmt_shrn(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# --- ROL: 循环左移 4 位 ---
# 0x12345678 -> 0x23456781（最高 4 位绕回最低）
# 注意这里用 32 位的 eax：循环移位是在「操作数宽度」里转圈的，
# 换成 64 位的 rax 就是 0x123456780，看不到回绕 —— 见下面那行对比。
    movl	$0x12345678, %eax
    roll	$4, %eax
    leaq	fmt_rol(%rip), %rdi
    movq	%rax, %rsi	# 32 位写 eax 会顺手把 rax 高 32 位清零
    xorl	%eax, %eax
    call	printf

# --- ROR: 循环右移 4 位 ---
# 0x12345678 -> 0x81234567（最低 4 位绕回最高）
    movl	$0x12345678, %eax
    rorl	$4, %eax
    leaq	fmt_ror(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# --- 同样的位模式换成 64 位宽度：左移 4 位只是单纯放大 16 倍 ---
    movq	$0x12345678, %rax
    rolq	$4, %rax
    leaq	fmt_rol64(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

# --- 用 CL 指定移位量 ---
# 注意：在 SysV 里 rcx 是第 4 个参数寄存器，装完移位量之后
# 这个 call 就不要再指望 rcx 里还是别的东西了。
    movq	$1, %rax
    movq	$4, %rcx
    shlq	%cl, %rax
    leaq	fmt_shlcl(%rip), %rdi
    movq	%rax, %rsi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax	# 退出码 0
    leave
    ret
