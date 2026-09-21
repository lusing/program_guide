; ============================================================
; lib/linux_io.inc — Linux（ELF / System V AMD64）输出辅助例程
;
; 依赖：glibc 的 printf（由 gcc -no-pie 自动链接）
; 用法：在示例文件末尾（顶层，不要在 %if 里）写一行
;
;       %include "linux_io.inc"
;
; 汇编时需要 -I 指向本目录：
;       nasm -I lib -f elf64 示例.asm -o 示例.o
;
; 链接必须是**非 PIE**：gcc -no-pie 示例.o -o 示例
; （发行版 gcc 默认开 PIE，而 NASM 源码里的绝对重定位在 PIE 下编不过；
;   这也是 Linux 版和 macOS 版在工具链上最大的差别，见 docs/11_linux.md）
;
; ------------------------------------------------------------
; System V AMD64 传参速查（后面第 06 章详解）
;   整数/指针：arg1 rdi   arg2 rsi   arg3 rdx   arg4 rcx   arg5 r8   arg6 r9
;              第 7 个起放到栈上，按 [rsp+0]、[rsp+8] 依次排列
;   浮点      ：xmm0 … xmm7，与整数参数各自独立编号
;   调用可变参数函数（printf）前必须设 al = 用到的 xmm 寄存器个数
;   执行 call 时 rsp 必须 16 字节对齐
;
; ------------------------------------------------------------
; 本文件提供的例程（都是局部符号，不会和示例里的名字冲突）
;   l_nl            输出换行
;   l_puts          rdi = 以 0 结尾的字符串
;   l_putchar       dil = 字符
;   l_putint        rdi = 有符号整数          → %lld
;   l_putuint       rdi = 无符号整数          → %llu
;   l_putbool       rdi = 0/1                 → false/true
;   l_puthex        rdi = 值, rsi = 最少位数   → 0x 前缀 + 十六进制
;   l_putd          xmm0 = double             → %.6f
;   l_putg          xmm0 = double             → %g（自动去尾零）
;   l_putf          xmm0 = float（低 32 位）   → 先转 double 再 %g
;   l_putflags      rdi = pushfq 取到的值      → 六标志位一行
;   l_putsep        输出一个空格
; ============================================================

%ifndef LINUX_IO_INC
%define LINUX_IO_INC

%ifnidn __OUTPUT_FORMAT__, elf64
    %error "lib/linux_io.inc 只能配合 nasm -f elf64 使用（Windows 请用 -f win64，macOS 用 -f macho64）"
%endif

extern printf

section .rodata
    l_s_nl      db 10, 0
    l_s_space   db " ", 0
    l_f_puts    db "%s", 0
    l_f_char    db "%c", 0
    l_f_ll      db "%lld", 0
    l_f_llu     db "%llu", 0
    l_f_bool    db "%s", 0
    l_f_hex     db "0x%0*llx", 0
    l_f_d       db "%.6f", 0
    l_f_g       db "%g", 0
    l_f_flags   db "CF=%d PF=%d AF=%d ZF=%d SF=%d OF=%d", 0
    l_w_true    db "true", 0
    l_w_false   db "false", 0

section .text

; ------------------------------------------------------------
; l_nl — 输出换行
; ------------------------------------------------------------
l_nl:
    push rbp
    mov rbp, rsp
    lea rdi, [l_s_nl]
    xor eax, eax
    call printf
    leave
    ret

; ------------------------------------------------------------
; l_putsep — 输出一个空格
; ------------------------------------------------------------
l_putsep:
    push rbp
    mov rbp, rsp
    lea rdi, [l_s_space]
    xor eax, eax
    call printf
    leave
    ret

; ------------------------------------------------------------
; l_puts — rdi = 以 0 结尾的字符串
; ------------------------------------------------------------
l_puts:
    push rbp
    mov rbp, rsp
    mov rsi, rdi                 ; 参数改成 printf 的第 2 个
    lea rdi, [l_f_puts]
    xor eax, eax
    call printf
    leave
    ret

; ------------------------------------------------------------
; l_putchar — dil = 字符
; ------------------------------------------------------------
l_putchar:
    push rbp
    mov rbp, rsp
    movzx esi, dil
    lea rdi, [l_f_char]
    xor eax, eax
    call printf
    leave
    ret

; ------------------------------------------------------------
; l_putint — rdi = 有符号 64 位整数
; ------------------------------------------------------------
l_putint:
    push rbp
    mov rbp, rsp
    mov rsi, rdi
    lea rdi, [l_f_ll]
    xor eax, eax
    call printf
    leave
    ret

; ------------------------------------------------------------
; l_putuint — rdi = 无符号 64 位整数
; ------------------------------------------------------------
l_putuint:
    push rbp
    mov rbp, rsp
    mov rsi, rdi
    lea rdi, [l_f_llu]
    xor eax, eax
    call printf
    leave
    ret

; ------------------------------------------------------------
; l_putbool — rdi = 0 或 1
; ------------------------------------------------------------
l_putbool:
    push rbp
    mov rbp, rsp
    test rdi, rdi
    lea rsi, [l_w_false]
    lea rax, [l_w_true]
    cmovnz rsi, rax
    lea rdi, [l_f_bool]
    xor eax, eax
    call printf
    leave
    ret

; ------------------------------------------------------------
; l_puthex — rdi = 值，rsi = 最少位数（1..16）
; ------------------------------------------------------------
l_puthex:
    push rbp
    mov rbp, rsp
    mov rdx, rdi                 ; 第 3 个参数：值（对应 %llx）
    ; 第 2 个参数 rsi 已经是「最少位数」，直接留给格式串里的 * 用
    lea rdi, [l_f_hex]
    xor eax, eax
    call printf
    leave
    ret

; ------------------------------------------------------------
; l_putd — xmm0 = double，输出 %.6f
; ------------------------------------------------------------
l_putd:
    push rbp
    mov rbp, rsp
    lea rdi, [l_f_d]
    mov eax, 1                   ; 用了 1 个 xmm 寄存器
    call printf
    leave
    ret

; ------------------------------------------------------------
; l_putg — xmm0 = double，输出 %g
; ------------------------------------------------------------
l_putg:
    push rbp
    mov rbp, rsp
    lea rdi, [l_f_g]
    mov eax, 1
    call printf
    leave
    ret

; ------------------------------------------------------------
; l_putf — xmm0 低 32 位 = float
; ------------------------------------------------------------
l_putf:
    push rbp
    mov rbp, rsp
    cvtss2sd xmm0, xmm0
    lea rdi, [l_f_g]
    mov eax, 1
    call printf
    leave
    ret

; ------------------------------------------------------------
; l_putflags — rdi = pushfq 取到的标志寄存器值
; 依次输出 CF PF AF ZF SF OF，全在一行里
; ------------------------------------------------------------
l_putflags:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    sub rsp, 16                  ; 第 6 个参数走栈，同时保持 16 字节对齐
    mov rbx, rdi                 ; rbx = 标志值

    mov rsi, rbx
    and esi, 1                   ; CF = bit 0

    mov rdx, rbx
    shr rdx, 2
    and edx, 1                   ; PF = bit 2

    mov rcx, rbx
    shr rcx, 4
    and ecx, 1                   ; AF = bit 4

    mov r8, rbx
    shr r8, 6
    and r8d, 1                   ; ZF = bit 6

    mov r9, rbx
    shr r9, 7
    and r9d, 1                   ; SF = bit 7

    mov r12, rbx
    shr r12, 11
    and r12d, 1                  ; OF = bit 11
    mov [rsp], r12

    lea rdi, [l_f_flags]
    xor eax, eax
    call printf

    add rsp, 16
    pop r12
    pop rbx
    leave
    ret

%endif ; LINUX_IO_INC
