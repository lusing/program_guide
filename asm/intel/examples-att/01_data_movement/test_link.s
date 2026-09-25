	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */
.set SYS_exit, 60
.set SYS_write, 1
.set STDOUT, 1
	# %define SYS_exit   60
	# %define SYS_write  1
	# %define STDOUT     1
	.globl _start

.data
msg: .string "NASM + ELF + ld pipeline OK!"
msg_tail: .byte 10
.set msg_len, .- msg


.text
_start:
# write(1, msg, msg_len)
    movq	$SYS_write, %rax
    movq	$STDOUT, %rdi
    leaq	msg(%rip), %rsi
    movq	$msg_len, %rdx
    syscall	# 返回值 rax = 实际写出的字节数

# 顺手把字节数转成退出码以外的东西不方便，这里直接 exit(0)
# 想验证 syscall 写入成功，可以在 shell 里看输出内容是否完整
    movq	$SYS_exit, %rax
    xorq	%rdi, %rdi	# 退出码 0
    syscall
# 不会返回
