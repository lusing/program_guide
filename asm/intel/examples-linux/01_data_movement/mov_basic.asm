; ============================================================
; 文件: 01_data_movement/mov_basic.asm                     [Linux 版]
; 指令: MOV
; 描述: MOV 指令基础 —— 立即数 / 寄存器 / 内存之间的数据传送
; 平台: Linux x86-64，ELF 目标文件，System V AMD64 调用约定
; 汇编: nasm -I lib -f elf64 examples-linux/01_data_movement/mov_basic.asm -o build/mov_basic.o
; 链接: gcc -no-pie build/mov_basic.o -o build/mov_basic
; 对照: examples/01_data_movement/mov_basic.asm（Windows / MSVC 调用约定）
;
; 两个平台的差别只在「怎么把参数递给 printf」：
;   Windows: rcx rdx r8 r9，另需 32 字节影子空间（shadow space）
;   Linux  : rdi rsi rdx rcx r8 r9，没有影子空间
; MOV / MOVZX / LEA 这些指令本身两边完全一样。
; ============================================================
default rel

section .data
    align 8
    var      dq 100            ; 测试用内存变量
    byte_v   db 0
    word_v   dw 0
    dword_v  dd 0
    qword_v  dq 0

    fmt_imm   db "立即数->寄存器: mov rax,42          => rax = %lld", 10, 0
    fmt_reg   db "寄存器->寄存器: mov rbx,rax         => rbx = %lld", 10, 0
    fmt_m2r   db "内存->寄存器:   mov rax,[var]       => rax = %lld", 10, 0
    fmt_r2m   db "寄存器->内存:   mov [var],rax       => var = %lld", 10, 0
    fmt_byte  db "字节传送: mov byte [b],0x41         => b   = %d (0x%02x)", 10, 0
    fmt_word  db "字传送:   mov word [w],0x1234       => w   = %d (0x%04x)", 10, 0
    fmt_dword db "双字传送: mov dword [d],0x12345678   => d   = %d (0x%08x)", 10, 0
    fmt_qword db "四字传送: mov qword [q],0x123456789ABCDEF0 => q = 0x%016llx", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16                  ; 16 字节暂存区（System V 不需要 Windows 那样的影子空间）
    mov [rbp-8], rbx             ; rbx 是被调用者保存寄存器，退出前必须还原

    ; 立即数到寄存器
    mov rax, 42
    lea rdi, [fmt_imm]
    mov rsi, rax
    xor eax, eax                 ; 没有浮点参数 -> al = 0
    call printf

    ; 寄存器到寄存器 (重新载入 rax, 因 printf 会破坏 rax 返回值)
    mov rax, 42
    mov rbx, rax                 ; rbx = 42
    lea rdi, [fmt_reg]
    mov rsi, rbx
    xor eax, eax
    call printf

    ; 内存到寄存器
    mov rax, [var]
    lea rdi, [fmt_m2r]
    mov rsi, rax
    xor eax, eax
    call printf

    ; 寄存器到内存
    mov rax, 999
    mov [var], rax
    lea rdi, [fmt_r2m]
    mov rsi, [var]
    xor eax, eax
    call printf

    ; 不同大小: byte (0x41 = 65)
    mov byte [byte_v], 0x41
    movzx eax, byte [byte_v]
    lea rdi, [fmt_byte]
    mov esi, eax                 ; %d
    mov edx, eax                 ; %02x
    xor eax, eax
    call printf

    ; 不同大小: word (0x1234 = 4660)
    mov word [word_v], 0x1234
    movzx eax, word [word_v]
    lea rdi, [fmt_word]
    mov esi, eax
    mov edx, eax
    xor eax, eax
    call printf

    ; 不同大小: dword (0x12345678)
    mov dword [dword_v], 0x12345678
    mov eax, [dword_v]
    lea rdi, [fmt_dword]
    mov esi, eax
    mov edx, eax
    xor eax, eax
    call printf

    ; 不同大小: qword (0x123456789ABCDEF0)
    mov rax, 0x123456789ABCDEF0
    mov [qword_v], rax
    lea rdi, [fmt_qword]
    mov rsi, [qword_v]
    xor eax, eax
    call printf

    ; 还原被调用者保存寄存器，再从 main 正常返回
    ; 返回值放在 eax 里就是进程退出码（0 = 成功）
    mov rbx, [rbp-8]
    xor eax, eax
    leave
    ret
