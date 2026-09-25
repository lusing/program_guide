; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 4
    f_val1  DWORD 3.14            ; 单精度float
    f_val2  DWORD 2.0             ; 单精度float
    align 8
    d_val1  REAL8 2.718281828459045  ; 双精度double
    d_val2  REAL8 3.0             ; 双精度double
    align 8
    temp_d  REAL8 0.0             ; 临时double存储

    ; 单精度结果格式
    fmt_addss BYTE "ADDSS: 3.14 + 2.0 = %f", 10, 0
    fmt_subss BYTE "SUBSS: 3.14 - 2.0 = %f", 10, 0
    fmt_mulss BYTE "MULSS: 3.14 * 2.0 = %f", 10, 0
    ; 双精度结果格式
    fmt_addsd BYTE "ADDSD: 2.71828... + 3.0 = %f", 10, 0
    fmt_mulsd BYTE "MULSD: 2.71828... * 3.0 = %f", 10, 0
    fmt_done  BYTE "SSE scalar arithmetic demo completed.", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; -------------------------------------------------------
    ; 1. ADDSS - 单精度标量加法 (只操作xmm低32位)
    ;    3.14 + 2.0 = 5.14
    ; -------------------------------------------------------
    movss xmm0, DWORD PTR [f_val1]       ; xmm0[31:0] = 3.14
    movss xmm1, DWORD PTR [f_val2]       ; xmm1[31:0] = 2.0
    addss xmm0, xmm1           ; xmm0[31:0] = 5.14 (高位不变)
    ; 转换为double用于printf
    cvtss2sd xmm1, xmm0        ; xmm1[63:0] = (double)5.14
    movsd QWORD PTR [temp_d], xmm1
    lea rcx, fmt_addss
    mov rdx, QWORD PTR [temp_d]
    movsd xmm1, QWORD PTR [temp_d]
    call printf

    ; -------------------------------------------------------
    ; 2. SUBSS - 单精度标量减法
    ;    3.14 - 2.0 = 1.14
    ; -------------------------------------------------------
    movss xmm0, DWORD PTR [f_val1]
    movss xmm1, DWORD PTR [f_val2]
    subss xmm0, xmm1           ; xmm0[31:0] = 1.14
    cvtss2sd xmm1, xmm0
    movsd QWORD PTR [temp_d], xmm1
    lea rcx, fmt_subss
    mov rdx, QWORD PTR [temp_d]
    movsd xmm1, QWORD PTR [temp_d]
    call printf

    ; -------------------------------------------------------
    ; 3. MULSS - 单精度标量乘法
    ;    3.14 * 2.0 = 6.28
    ; -------------------------------------------------------
    movss xmm0, DWORD PTR [f_val1]
    movss xmm1, DWORD PTR [f_val2]
    mulss xmm0, xmm1           ; xmm0[31:0] = 6.28
    cvtss2sd xmm1, xmm0
    movsd QWORD PTR [temp_d], xmm1
    lea rcx, fmt_mulss
    mov rdx, QWORD PTR [temp_d]
    movsd xmm1, QWORD PTR [temp_d]
    call printf

    ; -------------------------------------------------------
    ; 4. ADDSD - 双精度标量加法 (只操作xmm低64位)
    ;    2.71828... + 3.0 = 5.71828...
    ; -------------------------------------------------------
    movsd xmm0, QWORD PTR [d_val1]       ; xmm0[63:0] = 2.718...
    movsd xmm1, QWORD PTR [d_val2]       ; xmm1[63:0] = 3.0
    addsd xmm0, xmm1           ; xmm0[63:0] = 5.718...
    movsd QWORD PTR [temp_d], xmm0       ; 存储double结果
    lea rcx, fmt_addsd
    mov rdx, QWORD PTR [temp_d]
    movsd xmm1, QWORD PTR [temp_d]       ; XMM1 = double值 (第1个浮点参数位)
    call printf

    ; -------------------------------------------------------
    ; 5. MULSD - 双精度标量乘法
    ;    2.71828... * 3.0 = 8.154...
    ; -------------------------------------------------------
    movsd xmm0, QWORD PTR [d_val1]
    movsd xmm1, QWORD PTR [d_val2]
    mulsd xmm0, xmm1           ; xmm0[63:0] = 8.154...
    movsd QWORD PTR [temp_d], xmm0
    lea rcx, fmt_mulsd
    mov rdx, QWORD PTR [temp_d]
    movsd xmm1, QWORD PTR [temp_d]
    call printf

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    lea rcx, fmt_done
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
main ENDP
END
