; ============================================================
; lib/mac_io.inc — macOS（Mach-O / System V AMD64）输出辅助例程
;
; 依赖：libSystem 的 printf / putchar（由 clang 或 ld 自动链接）
; 用法：在示例文件末尾（顶层，不要在 %if 里）写一行
;
;       %include "mac_io.inc"
;
; 汇编时需要 -I 指向本目录：
;       nasm -I lib -f macho64 示例.asm -o 示例.o
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
;   m_nl            输出换行
;   m_puts          rdi = 以 0 结尾的字符串
;   m_putchar       dil = 字符
;   m_putint        rdi = 有符号整数          → %lld
;   m_putuint       rdi = 无符号整数          → %llu
;   m_putbool       rdi = 0/1                 → false/true
;   m_puthex        rdi = 值, rsi = 最少位数   → 0x 前缀 + 十六进制
;   m_putd          xmm0 = double             → %.6f
;   m_putg          xmm0 = double             → %g（自动去尾零）
;   m_putf          xmm0 = float（低 32 位）   → 先转 double 再 %g
;   m_putflags      rdi = pushfq 取到的值      → 六标志位一行
;   m_putsep        输出一个空格
; ============================================================

%ifndef MAC_IO_INC
%define MAC_IO_INC

%ifnidn __OUTPUT_FORMAT__, macho64
    %error "lib/mac_io.inc 只能配合 nasm -f macho64 使用（Windows 请用 -f win64）"
%endif

extern _printf

section .rodata
    m_s_nl      db 10, 0
    m_s_space   db " ", 0
    m_f_puts    db "%s", 0
    m_f_char    db "%c", 0
    m_f_ll      db "%lld", 0
    m_f_llu     db "%llu", 0
    m_f_bool    db "%s", 0
    m_f_hex     db "0x%0*llx", 0
    m_f_d       db "%.6f", 0
    m_f_g       db "%g", 0
    m_f_flags   db "CF=%d PF=%d AF=%d ZF=%d SF=%d OF=%d", 0
    m_w_true    db "true", 0
    m_w_false   db "false", 0

section .text

; ------------------------------------------------------------
; m_nl — 输出换行
; ------------------------------------------------------------
m_nl:
    push rbp
    mov rbp, rsp
    lea rdi, [m_s_nl]
    xor eax, eax
    call _printf
    leave
    ret

; ------------------------------------------------------------
; m_putsep — 输出一个空格
; ------------------------------------------------------------
m_putsep:
    push rbp
    mov rbp, rsp
    lea rdi, [m_s_space]
    xor eax, eax
    call _printf
    leave
    ret

; ------------------------------------------------------------
; m_puts — rdi = 以 0 结尾的字符串
; ------------------------------------------------------------
m_puts:
    push rbp
    mov rbp, rsp
    mov rsi, rdi                 ; 参数改成 printf 的第 2 个
    lea rdi, [m_f_puts]
    xor eax, eax
    call _printf
    leave
    ret

; ------------------------------------------------------------
; m_putchar — dil = 字符
; ------------------------------------------------------------
m_putchar:
    push rbp
    mov rbp, rsp
    movzx esi, dil
    lea rdi, [m_f_char]
    xor eax, eax
    call _printf
    leave
    ret

; ------------------------------------------------------------
; m_putint — rdi = 有符号 64 位整数
; ------------------------------------------------------------
m_putint:
    push rbp
    mov rbp, rsp
    mov rsi, rdi
    lea rdi, [m_f_ll]
    xor eax, eax
    call _printf
    leave
    ret

; ------------------------------------------------------------
; m_putuint — rdi = 无符号 64 位整数
; ------------------------------------------------------------
m_putuint:
    push rbp
    mov rbp, rsp
    mov rsi, rdi
    lea rdi, [m_f_llu]
    xor eax, eax
    call _printf
    leave
    ret

; ------------------------------------------------------------
; m_putbool — rdi = 0 或 1
; ------------------------------------------------------------
m_putbool:
    push rbp
    mov rbp, rsp
    test rdi, rdi
    lea rsi, [m_w_false]
    lea rax, [m_w_true]
    cmovnz rsi, rax
    lea rdi, [m_f_bool]
    xor eax, eax
    call _printf
    leave
    ret

; ------------------------------------------------------------
; m_puthex — rdi = 值，rsi = 最少位数（1..16）
; ------------------------------------------------------------
m_puthex:
    push rbp
    mov rbp, rsp
    mov rdx, rdi                 ; 第 3 个参数：值（对应 %llx）
    ; 第 2 个参数 rsi 已经是「最少位数」，直接留给格式串里的 * 用
    lea rdi, [m_f_hex]
    xor eax, eax
    call _printf
    leave
    ret

; ------------------------------------------------------------
; m_putd — xmm0 = double，输出 %.6f
; ------------------------------------------------------------
m_putd:
    push rbp
    mov rbp, rsp
    lea rdi, [m_f_d]
    mov eax, 1                   ; 用了 1 个 xmm 寄存器
    call _printf
    leave
    ret

; ------------------------------------------------------------
; m_putg — xmm0 = double，输出 %g
; ------------------------------------------------------------
m_putg:
    push rbp
    mov rbp, rsp
    lea rdi, [m_f_g]
    mov eax, 1
    call _printf
    leave
    ret

; ------------------------------------------------------------
; m_putf — xmm0 低 32 位 = float
; ------------------------------------------------------------
m_putf:
    push rbp
    mov rbp, rsp
    cvtss2sd xmm0, xmm0
    lea rdi, [m_f_g]
    mov eax, 1
    call _printf
    leave
    ret

; ------------------------------------------------------------
; m_putflags — rdi = pushfq 取到的标志寄存器值
; 依次输出 CF PF AF ZF SF OF，全在一行里
; ------------------------------------------------------------
m_putflags:
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

    lea rdi, [m_f_flags]
    xor eax, eax
    call _printf

    add rsp, 16
    pop r12
    pop rbx
    leave
    ret

%endif ; MAC_IO_INC
