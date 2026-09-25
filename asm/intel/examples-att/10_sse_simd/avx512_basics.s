	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 64
add_a: .long 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
	.align 64
add_b: .long 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100
	.align 64
# 掩码：选偶数下标通道（bit0,2,4,...=1），即 0x5555
mask_even: .word 0x5555
	.align 64
# 合并掩码用的「目标初值」：先放 1..16，带掩码加完后奇数下标仍保留这些值
merge_init: .long 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
	.align 64
out_buf: .long 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

hdr: .string "AVX-512 基础：ZMM 512 位 + opmask k 寄存器\n"
t1: .string "1. VPADDD zmm —— 16 路 32 位整数加（AVX2 只有 8 路）\n"
t1c: .string "   [1..16] + [100 x 16]\n"
t2: .string "2. 合并掩码 {k1}：只更新偶数下标通道，其余保留目标初值\n"
t2c: .string "   掩码 = 0x5555（bit 0,2,4,...,14 置位）；目标初值 = [1..16]\n"
t2d: .string "   期望：偶数下标 = 初值+100，奇数下标 = 初值不变\n"
t3: .string "3. 归零掩码 {k1}{z}：未选中通道直接清零\n"
t3c: .string "   同样的掩码与输入，但奇数下标变成 0\n"
t_skip: .string "本机不支持 AVX-512F（CPUID 页 7 EBX[16] / XCR0[7:5] 已确认），本示例无可演示内容。\n"
fmt_idx: .string "     [%2d] = %d\n"
fmt_done: .string "AVX-512 basics demo completed.\n"


.text

# ------------------------------------------------------------
# cpu_features —— CPUID + XGETBV 探测，返回 eax 位图
# bit0 = AVX         页1 ECX[28]，且 ECX[27] OSXSAVE，且 XCR0[2:1] = 11
# bit1 = AVX2        页7 EBX[5]
# bit2 = FMA         页1 ECX[12]
# bit3 = OS 放开 YMM（XCR0[2:1]）
# bit4 = AVX-512F    页7 EBX[16]
# bit5 = OS 放开 ZMM/opmask（XCR0[7:5] 全 1）
# ------------------------------------------------------------
cpu_features:
    pushq	%rbp
    movq	%rsp, %rbp
    pushq	%rbx
    pushq	%r12

    xorl	%r12d, %r12d

    movl	$0, %eax
    cpuid
    movl	%eax, %r9d	# 最大页号
    cmpl	$1, %r9d
    jb	.L_cpu_featuresdone

    movl	$1, %eax
    xorl	%ecx, %ecx
    cpuid
    movl	%ecx, %r8d

    btl	$12, %r8d	# FMA
    jnc	.L_cpu_featuresno_fma
    orl	$4, %r12d
.L_cpu_featuresno_fma:
    btl	$28, %r8d	# AVX
    jnc	.L_cpu_featuresdone
    btl	$27, %r8d	# OSXSAVE
    jnc	.L_cpu_featuresdone

    xorl	%ecx, %ecx
    xgetbv	# XCR0 -> EDX:EAX
    movl	%eax, %r11d	# 完整保存 XCR0，后面 AVX-512 的 [7:5] 还要用
    movl	%eax, %r10d
    andl	$6, %r10d
    cmpl	$6, %r10d	# XCR0[2:1] = YMM
    jne	.L_cpu_featuresdone
    orl	$9, %r12d	# bit0(AVX) + bit3(OS YMM)

    cmpl	$7, %r9d
    jb	.L_cpu_featuresdone
    movl	$7, %eax
    xorl	%ecx, %ecx
    cpuid
    btl	$5, %ebx	# AVX2
    jnc	.L_cpu_featuresno_avx2
    orl	$2, %r12d
.L_cpu_featuresno_avx2:
    btl	$16, %ebx	# AVX-512F
    jnc	.L_cpu_featuresdone
    orl	$16, %r12d

# XCR0[7:5]：opmask(5) + ZMM_Hi256(6) + Hi16_ZMM(7)，三者都要置位
    movl	%r11d, %r10d	# 取回之前保存的完整 XCR0
    andl	$0xE0, %r10d
    cmpl	$0xE0, %r10d
    jne	.L_cpu_featuresdone
    orl	$32, %r12d

.L_cpu_featuresdone:
    movl	%r12d, %eax
    popq	%r12
    popq	%rbx
    leave
    ret

# ------------------------------------------------------------
# print_ivec16 —— 把缓冲区里的 16 个 int32 逐个打出
# rdi = int32*
# ------------------------------------------------------------
print_ivec16:
    pushq	%rbp
    movq	%rsp, %rbp
    pushq	%rbx
    pushq	%r12
    pushq	%r13
    subq	$8, %rsp

    movq	%rdi, %rbx
    xorl	%r13d, %r13d
.L_print_ivec16loop:
    cmpl	$16, %r13d
    jge	.L_print_ivec16done
    movl	(%rbx,%r13,4), %edx
    leaq	fmt_idx(%rip), %rdi
    movl	%r13d, %esi
    xorl	%eax, %eax
    call	printf
    incl	%r13d
    jmp	.L_print_ivec16loop
.L_print_ivec16done:
    addq	$8, %rsp
    popq	%r13
    popq	%r12
    popq	%rbx
    leave
    ret

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp
    movq	%rbx, -8(%rbp)
    movq	%r12, -16(%rbp)

    call	cpu_features
    movl	%eax, %r12d

    leaq	hdr(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    movl	%r12d, %eax
    andl	$48, %eax	# bit4(AVX-512F) + bit5(OS 放开 ZMM) = 0b110000
    cmpl	$48, %eax
    je	.L_mainavx512_ok
    leaq	t_skip(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    jmp	.L_mainfinish

.L_mainavx512_ok:
# --- 1. vpaddd zmm：16 路 32 位整数加 ---
    leaq	t1(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t1c(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    vmovdqa32	add_a(%rip), %zmm1
    vmovdqa32	add_b(%rip), %zmm2
    vpaddd	%zmm2, %zmm1, %zmm0
    vmovdqa32	%zmm0, out_buf(%rip)
    vzeroupper
    leaq	out_buf(%rip), %rdi
    call	print_ivec16

# --- 2. 合并掩码 {k1}：偶数下标更新，奇数下标保留目标初值 ---
    leaq	t2(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t2c(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t2d(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    movl	mask_even(%rip), %eax	# 0x5555
    kmovw	%eax, %k1
    vmovdqa32	merge_init(%rip), %zmm0	# 目标初值 [1..16]
    vmovdqa32	add_b(%rip), %zmm1	# [100 x 16]
    vpaddd	%zmm1, %zmm0, %zmm0{%k1}	# 只在 k1 置位的通道执行加法
    vmovdqa32	%zmm0, out_buf(%rip)
    vzeroupper
    leaq	out_buf(%rip), %rdi
    call	print_ivec16

# --- 3. 归零掩码 {k1}{z}：未选中通道清零 ---
# 注意：opmask k 寄存器是「调用者保存」的，上面 print_ivec16 里的
# printf 已经把 k1 冲掉了，这里必须重新加载掩码。
    leaq	t3(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    leaq	t3c(%rip), %rdi
    xorl	%eax, %eax
    call	printf
    movl	mask_even(%rip), %eax
    kmovw	%eax, %k1	# 重新加载掩码 0x5555
    vmovdqa32	add_a(%rip), %zmm1	# [1..16]
    vmovdqa32	add_b(%rip), %zmm2	# [100 x 16]
    vpaddd	%zmm2, %zmm1, %zmm0{%k1}{z}	# 偶数下标 = a+b，奇数下标 = 0
    vmovdqa32	%zmm0, out_buf(%rip)
    vzeroupper
    leaq	out_buf(%rip), %rdi
    call	print_ivec16

.L_mainfinish:
    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    movq	-8(%rbp), %rbx
    movq	-16(%rbp), %r12
    xorl	%eax, %eax
    leave
    ret

	.include "att_io.s"
