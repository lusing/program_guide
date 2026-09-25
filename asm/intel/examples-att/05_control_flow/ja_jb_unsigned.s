	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
fmt_ja: .string "JA:  255 > 1 (unsigned)  -> Above (JA taken)\n"
fmt_jb: .string "JB:  1 < 255 (unsigned)  -> Below (JB taken)\n"
fmt_flg: .string "  这次 CMP 之后的标志位：\n"
fmt_ja_u: .string "Unsigned: 0xFFFFFFFF > 1 -> Above (JA taken)\n"
fmt_jl_s: .string "Signed:   0xFFFFFFFF < 1 -> Less  (JL taken)\n"
fmt_key: .string "Key: Same CMP, different jumps interpret flags differently!\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

# --- JA：255 - 1 = 254，CF=0 ZF=0 -> 跳 ---
    movl	$255, %eax
    movl	$1, %edx
    cmpl	%edx, %eax
    ja	.L_mainja_taken
    jmp	.L_mainafter_ja
.L_mainja_taken:
    leaq	fmt_ja(%rip), %rdi
    xorl	%eax, %eax
    call	printf
.L_mainafter_ja:

# --- JB：1 - 255 需要借位，CF=1 -> 跳 ---
    movl	$1, %eax
    movl	$255, %edx
    cmpl	%edx, %eax
    jb	.L_mainjb_taken
    jmp	.L_mainafter_jb
.L_mainjb_taken:
    leaq	fmt_jb(%rip), %rdi
    xorl	%eax, %eax
    call	printf
.L_mainafter_jb:

# --------------------------------------------------------
# 关键演示：0xFFFFFFFF 同一个位模式
# 无符号 = 4294967295（大于 1）
# 有符号 = -1        （小于 1）
# CMP EAX,EDX 算出 0xFFFFFFFE：
# CF=0（无借位）      -> JA 跳
# SF=1, OF=0          -> JL 跳
# 两个跳转都会成立！
# --------------------------------------------------------
    movl	$0xFFFFFFFF, %eax
    movl	$1, %edx
    cmpl	%edx, %eax
    pushfq
    popq	%r10	# 抓一份标志位快照，把上面的推理坐实
    movq	%r10, -8(%rbp)
    ja	.L_mainunsigned_above
.L_mainunsigned_above:
    leaq	fmt_flg(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    movq	-8(%rbp), %rdi
    call	l_putflags
    call	l_nl

    leaq	fmt_ja_u(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --- 同一个位模式，改用有符号跳转 ---
# 必须重新 CMP：上面的 printf 已经把标志位冲掉了
    movl	$0xFFFFFFFF, %eax
    movl	$1, %edx
    cmpl	%edx, %eax
    jl	.L_mainsigned_less
.L_mainsigned_less:
    leaq	fmt_jl_s(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --- 结论 ---
    leaq	fmt_key(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret

	.include "att_io.s"
