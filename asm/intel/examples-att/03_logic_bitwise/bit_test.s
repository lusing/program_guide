	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
fmt_bt3: .string "BT   rax,3  -> CF=%lld  (0x08 的 bit 3 = 1)\n"
fmt_bt5: .string "BT   rax,5  -> CF=%lld  (0x08 的 bit 5 = 0)\n"
fmt_bts: .string "BTS  rax,5  -> CF=%lld, rax = 0x%llx  (置 bit 5)\n"
fmt_btr: .string "BTR  rax,5  -> CF=%lld, rax = 0x%llx  (清 bit 5)\n"
fmt_btc: .string "BTC  rax,3  -> CF=%lld, rax = 0x%llx  (翻转 bit 3)\n"


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

# --- BT: 测试第 3 位（0x08 = 0b1000，bit3 = 1） ---
# 注意顺序：xor esi,esi 会把 CF 清掉，所以必须先清零再执行 BT。
    movq	$0x08, %rax
    xorl	%esi, %esi
    btq	$3, %rax
    setcb	%sil	# sil = CF
    leaq	fmt_bt3(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --- BT: 测试第 5 位（0x08 的 bit5 = 0） ---
    movq	$0x08, %rax
    xorl	%esi, %esi
    btq	$5, %rax
    setcb	%sil
    leaq	fmt_bt5(%rip), %rdi
    xorl	%eax, %eax
    call	printf

# --- BTS: 测试并置位第 5 位 ---
# CF = 旧值（bit5 = 0），随后 bit5 变 1 => rax = 0x28
    movq	$0x08, %rax
    xorl	%esi, %esi
    btsq	$5, %rax
    setcb	%sil	# CF 里是旧值
    leaq	fmt_bts(%rip), %rdi
    movq	%rax, %rdx	# rax 已经变了，先放进 rdx
    xorl	%eax, %eax
    call	printf

# --- BTR: 测试并清位第 5 位 ---
# 从 0x28 开始，CF = 旧值（bit5 = 1），随后 bit5 变 0 => rax = 0x08
    movq	$0x28, %rax
    xorl	%esi, %esi
    btrq	$5, %rax
    setcb	%sil
    leaq	fmt_btr(%rip), %rdi
    movq	%rax, %rdx
    xorl	%eax, %eax
    call	printf

# --- BTC: 测试并翻转第 3 位 ---
# 从 0x08 开始，CF = 旧值（bit3 = 1），随后 bit3 翻转 => rax = 0x00
    movq	$0x08, %rax
    xorl	%esi, %esi
    btcq	$3, %rax
    setcb	%sil
    leaq	fmt_btc(%rip), %rdi
    movq	%rax, %rdx
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
