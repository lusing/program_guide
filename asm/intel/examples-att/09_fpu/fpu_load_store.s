	.globl main
/* n2att: NASM(elf64) -> AT&T(gas) */

.data
	.align 8
val_double: .double 3.141592653589793	# double（64 位）
	.align 4
val_float: .float 2.718281828	# float （32 位）
	.align 4
val_int: .long 42	# 32 位整数

	.align 8
result: .double 0.0

fmt_fld_d: .string "FLD qword  （double 3.14159...）： %f\n"
fmt_fld_f: .string "FLD dword  （float  2.71828...）： %f\n"
fmt_fild: .string "FILD dword （整数   42）：        %f\n"
fmt_fst: .string "FST        （存但**不**弹栈）：   %f\n"
fmt_fstp: .string "FSTP       （存完顺便弹栈）：     %f\n"
fmt_done: .string "FPU load/store demo completed.\n"

# 只负责把 [result] 打出来（不碰 FPU 栈）
	.text
.macro print_result p1
    movsd	result(%rip), %xmm0
    leaq	\p1(%rip), %rdi
    movl	$1, %eax
    call	printf
.endm


.text

main:
    pushq	%rbp
    movq	%rsp, %rbp
    subq	$16, %rsp

    finit	# 设置默认控制字（扩展精度、四舍五入）

# --------------------------------------------------------
# 1. FLD qword：64 位 double
# --------------------------------------------------------
    fld	val_double(%rip)	# ST0 = 3.141592653589793
    fstp	result(%rip)	# 存下来并弹栈（栈恢复空）
print_result	fmt_fld_d

# --------------------------------------------------------
# 2. FLD dword：32 位 float，进栈时自动升成 80 位扩展精度
# --------------------------------------------------------
    fld	val_float(%rip)	# ST0 = 2.718281828...
    fstp	result(%rip)	# 取出时截成 double
print_result	fmt_fld_f

# --------------------------------------------------------
# 3. FILD：把整数读进来并转成浮点
# --------------------------------------------------------
    fild	val_int(%rip)	# ST0 = 42.0
    fstp	result(%rip)
print_result	fmt_fild

# --------------------------------------------------------
# 4. FST 与 FSTP 的区别 —— 只差那个 p
# 先用 FST 存一份，ST0 还留在栈上，所以还能再取一次
# --------------------------------------------------------
    fld	val_double(%rip)	# ST0 = 3.14159...
    fst	result(%rip)	# 存到内存，ST0 仍在栈顶
print_result	fmt_fst	# 此时 FPU 栈深 = 1

    fstp	result(%rip)	# 这回带 p：存完就弹，栈深回到 0
print_result	fmt_fstp

    leaq	fmt_done(%rip), %rdi
    xorl	%eax, %eax
    call	printf

    xorl	%eax, %eax
    leave
    ret
