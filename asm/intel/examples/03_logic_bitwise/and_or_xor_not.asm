; ============================================================
; 文件: 03_logic_bitwise/and_or_xor_not.asm
; 指令: AND, OR, XOR, NOT
; 描述: 基本逻辑运算演示（按位与、或、异或、取反）
; 编译: nasm -f win64 and_or_xor_not.asm -o and_or_xor_not.obj
; 链接: link /subsystem:console /entry:main and_or_xor_not.obj ucrt.lib kernel32.lib legacy_stdio_definitions.lib
; ============================================================
default rel

section .data
    fmt_and  db "AND  0xFF & 0x0F        = 0x%llx", 10, 0
    fmt_or   db "OR   0xF0 | 0x0F        = 0x%llx", 10, 0
    fmt_xor  db "XOR  0xFF ^ 0x0F        = 0x%llx", 10, 0
    fmt_not  db "NOT  ~0x0               = 0x%llx", 10, 0
    fmt_clr  db "XOR  0xDEADBEEF ^ self  = 0x%llx", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    and rsp, -16             ; 确保16字节栈对齐
    sub rsp, 32              ; shadow space

    ; --- AND: 按位与，掩码提取低4位 ---
    mov rax, 0xFF
    and rax, 0x0F
    lea rcx, [fmt_and]
    mov rdx, rax
    call printf

    ; --- OR: 按位或，设置低4位 ---
    mov rax, 0xF0
    or rax, 0x0F
    lea rcx, [fmt_or]
    mov rdx, rax
    call printf

    ; --- XOR: 按位异或，翻转低4位 ---
    mov rax, 0xFF
    xor rax, 0x0F
    lea rcx, [fmt_xor]
    mov rdx, rax
    call printf

    ; --- NOT: 按位取反 ---
    mov rax, 0x0
    not rax
    lea rcx, [fmt_not]
    mov rdx, rax
    call printf

    ; --- XOR 自身清零（常用技巧，比 mov rax,0 更短） ---
    mov rax, 0xDEADBEEF
    xor rax, rax
    lea rcx, [fmt_clr]
    mov rdx, rax
    call printf

    xor ecx, ecx             ; exit code = 0
    call ExitProcess
