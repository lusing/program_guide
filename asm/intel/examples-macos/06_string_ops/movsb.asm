; ============================================================
; 文件: 06_string_ops/movsb.asm                            [macOS 版]
; 指令: MOVSB / REP MOVSB
; 描述: 字符串移动 —— 单字节复制与「整段 memcpy」
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/06_string_ops/movsb.asm -o build/movsb.o
; 链接: clang -arch x86_64 build/movsb.o -o build/movsb
; 对照: examples/06_string_ops/movsb.asm
;
; MOVS 用的三个寄存器在 SysV 里全部是参数寄存器：
;   RSI = 源索引   RDI = 目标索引   RCX = 重复次数（REP 前缀用）
; 好消息：SysV 里 RSI/RDI 是调用者保存，不必像 Windows 那样 push 保护；
; 坏消息：它们和 printf 的前两个参数寄存器撞车，
;         所以每条字符串指令做完之后，printf 的参数必须从头装一遍。
; 例子里每条「打印」都重新 lea 目标字符串，就是为了避开这个坑。
;
; CLD 清方向标志（DF=0，指针递增），STD 置 DF=1（指针递减）。
; ABI 规定 DF 必须在函数调用前后都是 0，所以自己改过之后要记得 CLD 回来。
; ============================================================
default rel

section .data
    src_str db "Hello, NASM!", 0       ; 源字符串
    src_len equ $ - src_str - 1        ; 长度（不含结尾的 0）= 12

    fmt_single db "1. movsb: 复制 1 字节 -> dest[0] = '%c' (0x%02X)", 10, 0
    fmt_full   db "2. rep movsb: 复制了 %lld 字节 -> dest = [%s]", 10, 0
    fmt_ptr    db "   指针也动了：RSI 现在比源串开头大 %lld 字节", 10, 0
    fmt_done   db "MOVS/MOVSB demo completed.", 10, 0

section .bss
    dest_buf resb 64                   ; 目标缓冲区

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; --------------------------------------------------------
    ; 1. movsb：把一个字节从 [RSI] 搬到 [RDI]，然后两个指针都 +1
    ; --------------------------------------------------------
    lea rsi, [src_str]
    lea rdi, [dest_buf]
    mov r10, rsi                       ; 记下源串开头（r10 是调用者保存，这里够用）
    cld                                ; DF=0，向前走
    movsb                              ; dest_buf[0] = 'H'；RSI/RDI 各 +1
    mov r11, rsi
    sub r11, r10                       ; r11 = 1，指针正好前进 1 字节
    mov [rbp-8], r11                   ; 要跨 printf，先落栈

    ; 打印：注意 rsi/rdi 刚刚被 movsb 改过，参数要重新装
    movzx esi, byte [dest_buf]         ; %c 用
    mov edx, esi                       ; 0x%02X 用
    lea rdi, [fmt_single]              ; rdi 最后装，免得被上面两行冲掉
    xor eax, eax
    call _printf

    ; 把「指针走了多远」也打出来
    lea rdi, [fmt_ptr]
    mov rsi, [rbp-8]
    xor eax, eax
    call _printf

    ; --------------------------------------------------------
    ; 2. rep movsb：重复 RCX 次，等价于 memcpy(dest, src, 12)
    ; --------------------------------------------------------
    lea rsi, [src_str]
    lea rdi, [dest_buf]
    mov rcx, src_len
    cld
    rep movsb
    mov byte [dest_buf + src_len], 0   ; 补上结尾的 0，好当 C 字符串打印

    mov rsi, src_len                   ; 第 2 个参数：字节数
    lea rdx, [dest_buf]                ; 第 3 个参数：目标串
    lea rdi, [fmt_full]                ; 第 1 个参数最后装
    xor eax, eax
    call _printf

    lea rdi, [fmt_done]
    xor eax, eax
    call _printf

    xor eax, eax
    leave
    ret
