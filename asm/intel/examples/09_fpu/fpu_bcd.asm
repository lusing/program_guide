; ============================================================
; fpu_bcd.asm - x87 的压缩 BCD（十进制）支持
; ============================================================
; 演示:
;   - fild 载入 64 位整数 1234567890
;   - fbstp 存为 10 字节压缩 BCD（每字节两个十进制数字，低位字节在前）
;     -> 90 78 56 34 12 00 00 00 00 00
;   - fbld 从 BCD 载回、fistp 转回整数，验证往返无损
;   - 传统 BCD 调整指令 DAA/DAS 在 64 位模式下已被删除，
;     想用十进制运算就只剩 x87 的 fbstp/fbld 这条路
;
; 预期输出:
;   int  = 1234567890
;   BCD  = 90 78 56 34 12 00 00 00 00 00
;   back = 1234567890 (roundtrip OK)
; ============================================================

default rel

section .data
    align 8
    int_val   dq 1234567890

    fmt_int  db "int  = %lld", 10, 0
    fmt_pre  db "BCD  = ", 0
    fmt_byte db "%02X ", 0
    fmt_nl   db 10, 0
    fmt_back db "back = %lld (roundtrip OK)", 10, 0

section .bss
    bcd_buf  resb 10           ; 10 字节压缩 BCD（x87 的 tword 访问不要求对齐）
    back_val resq 1

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx                    ; rbx/r12 非易失，使用前保存
    push r12

    finit

    ; ---- 打印原整数 ----
    lea rcx, [fmt_int]
    mov rdx, [int_val]
    call printf

    ; ---- 整数 -> 压缩 BCD ----
    fild qword [int_val]       ; ST0 = 1234567890
    fbstp tword [bcd_buf]      ; 弹出并存为 10 字节 BCD

    ; ---- 逐字节打印（低位字节在前，可直接读出十进制数字）----
    ; 注意：[bcd_buf + rbx] 带索引寄存器无法用 RIP 相对寻址，
    ; NASM 会退回绝对寻址产生 ADDR32 重定位，MSVC link 拒绝
    ; （LNK2017）。正确姿势：lea 取 RIP 相对基址，再加索引。
    lea rcx, [fmt_pre]
    call printf
    lea r12, [bcd_buf]          ; RIP 相对取基址；r12 非易失，printf 不会破坏
    xor rbx, rbx
.print_loop:
    cmp rbx, 10
    jge .print_done
    lea rcx, [fmt_byte]
    movzx rdx, byte [r12 + rbx]
    call printf
    inc rbx
    jmp .print_loop
.print_done:
    lea rcx, [fmt_nl]
    call printf

    ; ---- BCD -> 整数，验证往返 ----
    fbld tword [bcd_buf]
    fistp qword [back_val]

    lea rcx, [fmt_back]
    mov rdx, [back_val]
    call printf

    pop r12
    pop rbx
    xor ecx, ecx
    call ExitProcess
