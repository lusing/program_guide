; ============================================================
; 文件: 03_logic_bitwise/shifts.asm                        [Linux 版]
; 指令: SHL / SHR / SAR / ROL / ROR
; 描述: 移位与循环移位
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/03_logic_bitwise/shifts.asm -o build/shifts.o
; 链接: gcc -no-pie build/shifts.o -o build/shifts
; 对照: examples/03_logic_bitwise/shifts.asm
;
; 三个「右移」要分清：
;   SHR  逻辑右移，高位补 0，按无符号解释
;   SAR  算术右移，高位补符号位，按有符号解释（-8 >> 1 = -4）
;   ROR  循环右移，跑出去的低位从高位绕回来
; 移位数 > 1 时只有 CL 能当寄存器操作数（`shl rax, cl`），
; 想用别的寄存器就得先 mov 到 cl —— 这一点在两个平台完全一样。
; ============================================================
default rel

section .data
    fmt_shl1  db "SHL  0x1 << 1            = 0x%llx", 10, 0
    fmt_shl3  db "SHL  0x1 << 3            = 0x%llx", 10, 0
    fmt_shr   db "SHR  0x10 >> 1           = 0x%llx", 10, 0
    fmt_sar   db "SAR  -8 >> 1 (signed)    = 0x%llx  (-8 / 2 = -4)", 10, 0
    fmt_shrn  db "SHR  -8 >> 1 (unsigned)  = 0x%llx  (高位补 0)", 10, 0
    fmt_rol   db "ROL  eax,4 (32位) 0x12345678 <<< 4 = 0x%llx", 10, 0
    fmt_ror   db "ROR  eax,4 (32位) 0x12345678 >>> 4 = 0x%llx", 10, 0
    fmt_rol64 db "ROL  rax,4 (64位) 0x12345678 <<< 4 = 0x%llx  (没绕回来)", 10, 0
    fmt_shlcl db "SHL  0x1 << CL(=4)       = 0x%llx", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp

    ; --- SHL: 逻辑左移 1 位（×2） ---
    mov rax, 1
    shl rax, 1
    lea rdi, [fmt_shl1]
    mov rsi, rax
    xor eax, eax
    call printf

    ; --- SHL: 左移 3 位（×8） ---
    mov rax, 1
    shl rax, 3
    lea rdi, [fmt_shl3]
    mov rsi, rax
    xor eax, eax
    call printf

    ; --- SHR: 逻辑右移 1 位（高位补 0） ---
    mov rax, 0x10
    shr rax, 1
    lea rdi, [fmt_shr]
    mov rsi, rax
    xor eax, eax
    call printf

    ; --- SAR: 算术右移 1 位（保留符号位）---
    ; -8 >> 1 = -4 = 0xFFFFFFFFFFFFFFFC
    mov rax, -8
    sar rax, 1
    lea rdi, [fmt_sar]
    mov rsi, rax
    xor eax, eax
    call printf

    ; --- 同一个负数用 SHR：高位补 0，结果变成很大的无符号数 ---
    mov rax, -8
    shr rax, 1
    lea rdi, [fmt_shrn]
    mov rsi, rax
    xor eax, eax
    call printf

    ; --- ROL: 循环左移 4 位 ---
    ; 0x12345678 -> 0x23456781（最高 4 位绕回最低）
    ; 注意这里用 32 位的 eax：循环移位是在「操作数宽度」里转圈的，
    ; 换成 64 位的 rax 就是 0x123456780，看不到回绕 —— 见下面那行对比。
    mov eax, 0x12345678
    rol eax, 4
    lea rdi, [fmt_rol]
    mov rsi, rax                     ; 32 位写 eax 会顺手把 rax 高 32 位清零
    xor eax, eax
    call printf

    ; --- ROR: 循环右移 4 位 ---
    ; 0x12345678 -> 0x81234567（最低 4 位绕回最高）
    mov eax, 0x12345678
    ror eax, 4
    lea rdi, [fmt_ror]
    mov rsi, rax
    xor eax, eax
    call printf

    ; --- 同样的位模式换成 64 位宽度：左移 4 位只是单纯放大 16 倍 ---
    mov rax, 0x12345678
    rol rax, 4
    lea rdi, [fmt_rol64]
    mov rsi, rax
    xor eax, eax
    call printf

    ; --- 用 CL 指定移位量 ---
    ; 注意：在 SysV 里 rcx 是第 4 个参数寄存器，装完移位量之后
    ; 这个 call 就不要再指望 rcx 里还是别的东西了。
    mov rax, 1
    mov rcx, 4
    shl rax, cl
    lea rdi, [fmt_shlcl]
    mov rsi, rax
    xor eax, eax
    call printf

    xor eax, eax                     ; 退出码 0
    leave
    ret
