; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    FP_ONE   EQU 00010000h     ; 1.0
    pi_fixed DWORD 0003243Fh      ; pi * 65536 = 205887 -> 3.141...

    fmt_mul BYTE "1.500 * 2.000 = %d.%d", 10, 0
    fmt_div BYTE "1.000 / 4.000 = %d.%03d", 10, 0
    fmt_neg BYTE "-0.500 * 3.000 = -%d.%d   (SAR keeps the sign)", 10, 0
    fmt_pi  BYTE "pi as fixed = %d.%06d  (resolution 1/65536 ~ 1.5e-5)", 10, 0


.code

; SPLIT 定点值(EAX) -> 整数部分 r9d、三位小数 r10d（假定值为正）
SPLIT MACRO
    mov r9d, eax
    sar r9d, 16
    mov r10d, eax
    shl r10d, 16
    shr r10d, 16
    imul r10d, r10d, 1000
    shr r10d, 16
ENDM

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; ---- 1.5 * 2.0 = 3.0 ----
    mov eax, 00018000h
    movsxd rax, eax              ; 先符号扩展到 64 位再乘，避免高位丢失
    mov ecx, 00020000h
    movsxd rcx, ecx
    imul rax, rcx               ; 比例因子变成 2^32
    sar rax, 16                 ; 算术右移回 16.16
    SPLIT
    lea rcx, fmt_mul
    mov edx, r9d
    mov r8d, r10d
    call printf

    ; ---- 1.0 / 4.0 = 0.250 ----
    mov eax, FP_ONE
    movsxd rax, eax
    shl rax, 16                 ; 左移 16 位补比例因子
    mov ecx, 00040000h
    movsxd rcx, ecx
    xor edx, edx
    div rcx                     ; rax = 4000h = 0.25 in 16.16
    SPLIT
    lea rcx, fmt_div
    mov edx, r9d
    mov r8d, r10d
    call printf

    ; ---- -0.5 * 3.0 = -1.5（SAR 保符号）----
    mov eax, 0FFFF8000h         ; -0.5
    movsxd rax, eax
    mov ecx, 00030000h         ; 3.0
    movsxd rcx, ecx
    imul rax, rcx
    sar rax, 16                 ; = -98304（16.16 的 -1.5）
    neg rax                     ; 取绝对值便于拆分打印
    SPLIT
    lea rcx, fmt_neg
    mov edx, r9d
    mov r8d, r10d
    call printf

    ; ---- pi 的定点精度 ----
    mov eax, DWORD PTR [pi_fixed]         ; 注意方括号：NASM 里裸标签是取地址！
    mov r9d, eax
    sar r9d, 16                 ; 3
    movzx r10, ax               ; 低 16 位 = 小数原始值（243Fh）
    imul r10, r10, 1000000      ; 用 64 位乘：9279 * 10^6 超出 32 位！
    shr r10, 16                 ; 141586
    lea rcx, fmt_pi
    mov edx, r9d
    mov r8d, r10d
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
