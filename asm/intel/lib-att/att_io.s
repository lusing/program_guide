# ============================================================
# lib-att/att_io.s — AT&T（GNU as / Linux / SysV）输出辅助例程
# 与 lib/linux_io.inc 例程同名的 AT&T 版（l_nl / l_puts / ...）
# 用法：.include "att_io.s"（汇编时 -I 指向 lib-att/）
# ============================================================

.section .rodata
l_s_nl:     .string "\n"
l_s_space:  .string " "
l_f_puts:   .string "%s"
l_f_char:   .string "%c"
l_f_ll:     .string "%lld"
l_f_llu:    .string "%llu"
l_f_bool:   .string "%s"
l_f_hex:    .string "0x%0*llx"
l_f_d:      .string "%.6f"
l_f_g:      .string "%g"
l_f_flags:  .string "CF=%d PF=%d AF=%d ZF=%d SF=%d OF=%d"
l_w_true:   .string "true"
l_w_false:  .string "false"

.text

# l_nl — 输出换行
l_nl:
    pushq   %rbp
    movq    %rsp, %rbp
    leaq    l_s_nl(%rip), %rdi
    xorl    %eax, %eax
    call    printf
    leave
    ret

# l_putsep — 输出一个空格
l_putsep:
    pushq   %rbp
    movq    %rsp, %rbp
    leaq    l_s_space(%rip), %rdi
    xorl    %eax, %eax
    call    printf
    leave
    ret

# l_puts — rdi = 字符串
l_puts:
    pushq   %rbp
    movq    %rsp, %rbp
    movq    %rdi, %rsi
    leaq    l_f_puts(%rip), %rdi
    xorl    %eax, %eax
    call    printf
    leave
    ret

# l_putchar — dil = 字符
l_putchar:
    pushq   %rbp
    movq    %rsp, %rbp
    movzbl  %dil, %esi
    leaq    l_f_char(%rip), %rdi
    xorl    %eax, %eax
    call    printf
    leave
    ret

# l_putint — rdi = 有符号 64 位
l_putint:
    pushq   %rbp
    movq    %rsp, %rbp
    movq    %rdi, %rsi
    leaq    l_f_ll(%rip), %rdi
    xorl    %eax, %eax
    call    printf
    leave
    ret

# l_putuint — rdi = 无符号 64 位
l_putuint:
    pushq   %rbp
    movq    %rsp, %rbp
    movq    %rdi, %rsi
    leaq    l_f_llu(%rip), %rdi
    xorl    %eax, %eax
    call    printf
    leave
    ret

# l_putbool — rdi = 0/1
l_putbool:
    pushq   %rbp
    movq    %rsp, %rbp
    testq   %rdi, %rdi
    leaq    l_w_true(%rip), %rsi
    jnz     1f
    leaq    l_w_false(%rip), %rsi
1:
    leaq    l_f_bool(%rip), %rdi
    xorl    %eax, %eax
    call    printf
    leave
    ret

# l_puthex — rdi = 值, rsi = 最少位数
l_puthex:
    pushq   %rbp
    movq    %rsp, %rbp
    movq    %rsi, %rdx
    movq    %rdi, %rsi
    leaq    l_f_hex(%rip), %rdi
    xorl    %eax, %eax
    call    printf
    leave
    ret

# l_putd — xmm0 = double
l_putd:
    pushq   %rbp
    movq    %rsp, %rbp
    leaq    l_f_d(%rip), %rdi
    movl    $1, %eax
    call    printf
    leave
    ret

# l_putg — xmm0 = double (%g)
l_putg:
    pushq   %rbp
    movq    %rsp, %rbp
    leaq    l_f_g(%rip), %rdi
    movl    $1, %eax
    call    printf
    leave
    ret

# l_putf — xmm0 = float（先转 double）
l_putf:
    pushq   %rbp
    movq    %rsp, %rbp
    cvtss2sd %xmm0, %xmm0
    leaq    l_f_g(%rip), %rdi
    movl    $1, %eax
    call    printf
    leave
    ret

# l_putflags — rdi = pushfq 取到的标志值，依次输出 CF PF AF ZF SF OF
l_putflags:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    subq    $16, %rsp
    movq    %rdi, %rbx
    movq    %rbx, %rsi
    shrq    $0, %rsi
    andl    $1, %esi             # CF = bit 0
    movq    %rbx, %rdx
    shrq    $2, %rdx
    andl    $1, %edx             # PF = bit 2
    movq    %rbx, %rcx
    shrq    $4, %rcx
    andl    $1, %ecx             # AF = bit 4
    movq    %rbx, %r8
    shrq    $6, %r8
    andl    $1, %r8d             # ZF = bit 6
    movq    %rbx, %r9
    shrq    $7, %r9
    andl    $1, %r9d             # SF = bit 7
    movq    %rbx, %r12
    shrq    $11, %r12
    andl    $1, %r12d            # OF = bit 11
    movq    %r12, (%rsp)
    leaq    l_f_flags(%rip), %rdi
    xorl    %eax, %eax
    call    printf
    addq    $16, %rsp
    popq    %r12
    popq    %rbx
    leave
    ret
