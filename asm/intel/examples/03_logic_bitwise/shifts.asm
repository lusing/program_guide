; ============================================================
; 文件: 03_logic_bitwise/shifts.asm
; 指令: SHL, SHR, SAR, ROL, ROR
; 描述: 移位和旋转指令演示
; 编译: nasm -f win64 shifts.asm -o shifts.obj
; 链接: link /subsystem:console /entry:main shifts.obj ucrt.lib kernel32.lib legacy_stdio_definitions.lib
; ============================================================
default rel

section .data
    fmt_shl1  db "SHL  0x1 << 1            = 0x%llx", 10, 0
    fmt_shl3  db "SHL  0x1 << 3            = 0x%llx", 10, 0
    fmt_shr   db "SHR  0x10 >> 1           = 0x%llx", 10, 0
    fmt_sar   db "SAR  -8 >> 1 (signed)   = 0x%llx  (-8 / 2 = -4)", 10, 0
    fmt_shrn  db "SHR  -8 >> 1 (unsigned) = 0x%llx  (高位补0)", 10, 0
    fmt_rol   db "ROL  0x12345678 <<< 4    = 0x%llx", 10, 0
    fmt_ror   db "ROR  0x12345678 >>> 4    = 0x%llx", 10, 0
    fmt_shlcl db "SHL  0x1 << CL(=4)       = 0x%llx", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    and rsp, -16             ; 确保16字节栈对齐
    sub rsp, 32              ; shadow space

    ; --- SHL: 逻辑左移1位 (×2) ---
    mov rax, 1
    shl rax, 1
    lea rcx, [fmt_shl1]
    mov rdx, rax
    call printf

    ; --- SHL: 左移3位 (×8) ---
    mov rax, 1
    shl rax, 3
    lea rcx, [fmt_shl3]
    mov rdx, rax
    call printf

    ; --- SHR: 逻辑右移1位 (÷2，无符号，高位补0) ---
    mov rax, 0x10
    shr rax, 1
    lea rcx, [fmt_shr]
    mov rdx, rax
    call printf

    ; --- SAR: 算术右移1位 (÷2，有符号，保留符号位) ---
    ; -8 >> 1 = -4 (0xFFFFFFFFFFFFFFFC)
    mov rax, -8
    sar rax, 1
    lea rcx, [fmt_sar]
    mov rdx, rax
    call printf

    ; --- SHR vs SAR: 对同一个负数，结果不同 ---
    ; -8 作为无符号右移，高位补0
    mov rax, -8
    shr rax, 1
    lea rcx, [fmt_shrn]
    mov rdx, rax
    call printf

    ; --- ROL: 循环左移4位 ---
    ; 0x12345678 → 0x23456781 (最高4位绕回到最低)
    mov rax, 0x12345678
    rol rax, 4
    lea rcx, [fmt_rol]
    mov rdx, rax
    call printf

    ; --- ROR: 循环右移4位 ---
    ; 0x12345678 → 0x81234567 (最低4位绕回到最高)
    mov rax, 0x12345678
    ror rax, 4
    lea rcx, [fmt_ror]
    mov rdx, rax
    call printf

    ; --- SHL with CL: 用CL寄存器指定移位量 ---
    mov rax, 1
    mov cl, 4
    shl rax, cl
    lea rcx, [fmt_shlcl]
    mov rdx, rax
    call printf

    xor ecx, ecx             ; exit code = 0
    call ExitProcess
