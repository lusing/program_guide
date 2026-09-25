; ============================================================
; fixed_point.asm - 16.16 定点数：没有 FPU 的年代怎么算小数
; ============================================================
; 16.16 定点：高 16 位整数、低 16 位小数，用补码表示负数。
;   1.0  = 0x00010000   1.5 = 0x00018000   -0.5 = 0xFFFF8000
; 乘法要点：两个 16.16 相乘比例因子翻倍（2^32），结果必须右移 16 位
;   ——而且要用 SAR（算术右移），否则负数结果会被 SHR 破坏符号。
; 除法要点：先左移 16 位补回比例因子再除。
;
; 预期输出:
;   1.500 * 2.000 = 3.0
;   1.000 / 4.000 = 0.250
;   -0.500 * 3.000 = -1.5   (SAR keeps the sign)
;   pi as fixed = 3.141586  (resolution 1/65536 ~ 1.5e-5)
; ============================================================

default rel

section .data
    FP_ONE   equ 0x00010000     ; 1.0
    pi_fixed dd 0x0003243F      ; pi * 65536 = 205887 -> 3.141...

    fmt_mul db "1.500 * 2.000 = %d.%d", 10, 0
    fmt_div db "1.000 / 4.000 = %d.%03d", 10, 0
    fmt_neg db "-0.500 * 3.000 = -%d.%d   (SAR keeps the sign)", 10, 0
    fmt_pi  db "pi as fixed = %d.%06d  (resolution 1/65536 ~ 1.5e-5)", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

; SPLIT 定点值(EAX) -> 整数部分 r9d、三位小数 r10d（假定值为正）
%macro SPLIT 0
    mov r9d, eax
    sar r9d, 16                 ; 整数部分
    mov r10d, eax
    shl r10d, 16
    shr r10d, 16                ; 取低 16 位小数原始值
    imul r10d, r10d, 1000
    shr r10d, 16                ; 小数前三位
%endmacro

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; ---- 1.5 * 2.0 = 3.0 ----
    mov eax, 0x00018000
    movsx rax, eax              ; 先符号扩展到 64 位再乘，避免高位丢失
    mov ecx, 0x00020000
    movsx rcx, ecx
    imul rax, rcx               ; 比例因子变成 2^32
    sar rax, 16                 ; 算术右移回 16.16
    SPLIT                       ; eax 仍是 32 位结果
    lea rcx, [fmt_mul]
    mov edx, r9d
    mov r8d, r10d
    call printf

    ; ---- 1.0 / 4.0 = 0.250 ----
    mov eax, FP_ONE
    movsx rax, eax
    shl rax, 16                 ; 左移 16 位补比例因子
    mov ecx, 0x00040000
    movsx rcx, ecx
    xor edx, edx
    div rcx                     ; rax = 0x4000 = 0.25 in 16.16
    SPLIT
    lea rcx, [fmt_div]
    mov edx, r9d
    mov r8d, r10d
    call printf

    ; ---- -0.5 * 3.0 = -1.5（SAR 保符号）----
    mov eax, 0xFFFF8000         ; -0.5
    movsx rax, eax
    mov ecx, 0x00030000         ; 3.0
    movsx rcx, ecx
    imul rax, rcx
    sar rax, 16                 ; = -98304（16.16 的 -1.5）
    neg rax                     ; 取绝对值便于拆分打印
    SPLIT
    lea rcx, [fmt_neg]
    mov edx, r9d
    mov r8d, r10d
    call printf

    ; ---- pi 的定点精度 ----
    mov eax, [pi_fixed]         ; 注意方括号：NASM 里裸标签是取地址！
    mov r9d, eax
    sar r9d, 16                 ; 3
    movzx r10, ax               ; 低 16 位 = 小数原始值（0x243F）
    imul r10, r10, 1000000      ; 用 64 位乘：9279 * 10^6 超出 32 位！
    shr r10, 16                 ; 141586
    lea rcx, [fmt_pi]
    mov edx, r9d
    mov r8d, r10d
    call printf

    xor ecx, ecx
    call ExitProcess
