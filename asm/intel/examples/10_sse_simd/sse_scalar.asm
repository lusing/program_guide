; ============================================================
; sse_scalar.asm - SSE标量(Scalar)运算
; ============================================================
; 演示:
;   单精度(float, 32位):
;     - addss xmm0, xmm1  标量加 (只操作最低32位)
;     - subss xmm0, xmm1  标量减
;     - mulss xmm0, xmm1  标量乘
;   双精度(double, 64位):
;     - addsd xmm0, xmm1  标量加 (只操作最低64位)
;     - mulsd xmm0, xmm1  标量乘
;
; 标量 vs 打包:
;   打包(addps): 4个float同时运算
;   标量(addss): 只对最低1个float运算, 高位保持不变
; ============================================================

default rel

section .data
    align 4
    f_val1  dd 3.14            ; 单精度float
    f_val2  dd 2.0             ; 单精度float
    align 8
    d_val1  dq 2.718281828459045  ; 双精度double
    d_val2  dq 3.0             ; 双精度double
    align 8
    temp_d  dq 0.0             ; 临时double存储

    ; 单精度结果格式
    fmt_addss db "ADDSS: 3.14 + 2.0 = %f", 10, 0
    fmt_subss db "SUBSS: 3.14 - 2.0 = %f", 10, 0
    fmt_mulss db "MULSS: 3.14 * 2.0 = %f", 10, 0
    ; 双精度结果格式
    fmt_addsd db "ADDSD: 2.71828... + 3.0 = %f", 10, 0
    fmt_mulsd db "MULSD: 2.71828... * 3.0 = %f", 10, 0
    fmt_done  db "SSE scalar arithmetic demo completed.", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; -------------------------------------------------------
    ; 1. ADDSS - 单精度标量加法 (只操作xmm低32位)
    ;    3.14 + 2.0 = 5.14
    ; -------------------------------------------------------
    movss xmm0, [f_val1]       ; xmm0[31:0] = 3.14
    movss xmm1, [f_val2]       ; xmm1[31:0] = 2.0
    addss xmm0, xmm1           ; xmm0[31:0] = 5.14 (高位不变)
    ; 转换为double用于printf
    cvtss2sd xmm1, xmm0        ; xmm1[63:0] = (double)5.14
    movsd [temp_d], xmm1
    lea rcx, [fmt_addss]
    mov rdx, [temp_d]
    movsd xmm1, [temp_d]
    call printf

    ; -------------------------------------------------------
    ; 2. SUBSS - 单精度标量减法
    ;    3.14 - 2.0 = 1.14
    ; -------------------------------------------------------
    movss xmm0, [f_val1]
    movss xmm1, [f_val2]
    subss xmm0, xmm1           ; xmm0[31:0] = 1.14
    cvtss2sd xmm1, xmm0
    movsd [temp_d], xmm1
    lea rcx, [fmt_subss]
    mov rdx, [temp_d]
    movsd xmm1, [temp_d]
    call printf

    ; -------------------------------------------------------
    ; 3. MULSS - 单精度标量乘法
    ;    3.14 * 2.0 = 6.28
    ; -------------------------------------------------------
    movss xmm0, [f_val1]
    movss xmm1, [f_val2]
    mulss xmm0, xmm1           ; xmm0[31:0] = 6.28
    cvtss2sd xmm1, xmm0
    movsd [temp_d], xmm1
    lea rcx, [fmt_mulss]
    mov rdx, [temp_d]
    movsd xmm1, [temp_d]
    call printf

    ; -------------------------------------------------------
    ; 4. ADDSD - 双精度标量加法 (只操作xmm低64位)
    ;    2.71828... + 3.0 = 5.71828...
    ; -------------------------------------------------------
    movsd xmm0, [d_val1]       ; xmm0[63:0] = 2.718...
    movsd xmm1, [d_val2]       ; xmm1[63:0] = 3.0
    addsd xmm0, xmm1           ; xmm0[63:0] = 5.718...
    movsd [temp_d], xmm0       ; 存储double结果
    lea rcx, [fmt_addsd]
    mov rdx, [temp_d]
    movsd xmm1, [temp_d]       ; XMM1 = double值 (第1个浮点参数位)
    call printf

    ; -------------------------------------------------------
    ; 5. MULSD - 双精度标量乘法
    ;    2.71828... * 3.0 = 8.154...
    ; -------------------------------------------------------
    movsd xmm0, [d_val1]
    movsd xmm1, [d_val2]
    mulsd xmm0, xmm1           ; xmm0[63:0] = 8.154...
    movsd [temp_d], xmm0
    lea rcx, [fmt_mulsd]
    mov rdx, [temp_d]
    movsd xmm1, [temp_d]
    call printf

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    lea rcx, [fmt_done]
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
