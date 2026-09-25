; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
N   equ 1024                      ; 数组元素数量
extern printf : PROC
extern ExitProcess : PROC
extern vsSin : PROC
extern vsCos : PROC
extern vsExp : PROC
extern mkl_get_version_string : PROC

.data
    align 4
    f_two_pi   DWORD 6.28318530
    f_N_float  DWORD 1024.0
    f_zero     DWORD 0.0

    align 8
    temp_d1    REAL8 0.0
    temp_d2    REAL8 0.0
    temp_d3    REAL8 0.0

    ; 格式字符串
    fmt_header BYTE "=== MKL VML向量数学 (从汇编调用) ===", 10, 0
    fmt_mkl    BYTE "MKL版本: %s", 10, 0
    fmt_info   BYTE "使用 mkl_rt.lib 运行时CPU调度 -> 自动选择AVX2代码路径", 10, 10, 0
    fmt_sep    BYTE "-------------------------------------------", 10, 0
    fmt_sin    BYTE "vsSin: sin(0)=%.4f  sin(PI/2)=%.4f  sin(PI)=%.4f", 10, 0
    fmt_cos    BYTE "vsCos: cos(0)=%.4f  cos(PI/2)=%.4f  cos(PI)=%.4f", 10, 0
    fmt_exp    BYTE "vsExp: exp(0)=%.4f  exp(PI/2)=%.4f  exp(PI)=%.4f", 10, 0
    fmt_n      BYTE "数组大小 N = %d, 每个函数处理 %d 个float", 10, 0
    fmt_done   BYTE 10, "MKL VML向量数学演示完成.", 10, 0


avxbss SEGMENT ALIGN(32) 'DATA'
    ; (align satisfied by SEGMENT ALIGN)
    x_array    DWORD N DUP(?); 输入数组
    sin_result DWORD N DUP(?); vsSin输出
    cos_result DWORD N DUP(?); vsCos输出
    exp_result DWORD N DUP(?); vsExp输出
    ALIGN 8
    f_step     DWORD 1 DUP(?); 步长 = 2π/N
    mkl_ver_buf BYTE 256 DUP(?); MKL版本字符串缓冲区

avxbss ENDS

.code
    ; MKL VML 函数
    ; MKL 服务函数

; ============================================================
; main
; ============================================================
main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 48                   ; shadow(32) + temps(16)

    ; --- 打印头部 ---
    lea rcx, fmt_header
    call printf

    ; --- 获取并打印MKL版本 ---
    lea rcx, mkl_ver_buf
    mov edx, 256
    call mkl_get_version_string

    lea rcx, fmt_mkl
    lea rdx, mkl_ver_buf
    call printf

    lea rcx, fmt_info
    call printf
    lea rcx, fmt_n
    mov edx, N
    mov r8d, N
    call printf

    ; -------------------------------------------------------
    ; 1. 生成输入数组 x[i] = i * (2π/N)
    ; -------------------------------------------------------
    movss xmm0, DWORD PTR [f_two_pi]
    divss xmm0, DWORD PTR [f_N_float]
    movss DWORD PTR [f_step], xmm0          ; step = 2π/N

    xor r12, r12                  ; i = 0
maingen_loop:
    cvtsi2ss xmm0, r12d           ; (float)i
    mulss xmm0, DWORD PTR [f_step]          ; i * step
    movss DWORD PTR [x_array+ r12*4], xmm0
    inc r12
    cmp r12, N
    jl maingen_loop

    ; -------------------------------------------------------
    ; 2. 调用 MKL VML 函数
    ;    mkl_rt.lib 会自动检测CPU并选择AVX2代码路径
    ; -------------------------------------------------------

    ; --- vsSin(N, x_array, sin_result) ---
    ; RCX = N, RDX = x_array, R8 = sin_result
    mov ecx, N
    lea rdx, x_array
    lea r8, sin_result
    call vsSin

    ; --- vsCos(N, x_array, cos_result) ---
    mov ecx, N
    lea rdx, x_array
    lea r8, cos_result
    call vsCos

    ; --- vsExp(N, x_array, exp_result) ---
    ; 注意: exp(2π) ≈ 535, 在float范围内
    mov ecx, N
    lea rdx, x_array
    lea r8, exp_result
    call vsExp

    ; -------------------------------------------------------
    ; 3. 打印结果 (采样点: x=0, π/2, π)
    ;    索引: 0, N/4, N/2
    ; -------------------------------------------------------
    lea rcx, fmt_sep
    call printf

    ; --- vsSin 结果 ---
    ; sin(0) = sin_result[0], sin(π/2) = sin_result[N/4], sin(π) = sin_result[N/2]
    movss xmm0, DWORD PTR [sin_result]
    cvtss2sd xmm0, xmm0
    movsd QWORD PTR [rsp+32], xmm0
    movss xmm0, DWORD PTR [sin_result+ (N/4)*4]
    cvtss2sd xmm0, xmm0
    movsd QWORD PTR [rsp+40], xmm0
    movss xmm0, DWORD PTR [sin_result+ (N/2)*4]
    cvtss2sd xmm0, xmm0
    movsd QWORD PTR [temp_d3], xmm0

    lea rcx, fmt_sin
    mov rdx, [rsp+32]
    mov r8, [rsp+40]
    mov r9, QWORD PTR [temp_d3]
    movsd xmm1, QWORD PTR [rsp+32]
    movsd xmm2, QWORD PTR [rsp+40]
    movsd xmm3, QWORD PTR [temp_d3]
    call printf

    ; --- vsCos 结果 ---
    movss xmm0, DWORD PTR [cos_result]
    cvtss2sd xmm0, xmm0
    movsd QWORD PTR [rsp+32], xmm0
    movss xmm0, DWORD PTR [cos_result+ (N/4)*4]
    cvtss2sd xmm0, xmm0
    movsd QWORD PTR [rsp+40], xmm0
    movss xmm0, DWORD PTR [cos_result+ (N/2)*4]
    cvtss2sd xmm0, xmm0
    movsd QWORD PTR [temp_d3], xmm0

    lea rcx, fmt_cos
    mov rdx, [rsp+32]
    mov r8, [rsp+40]
    mov r9, QWORD PTR [temp_d3]
    movsd xmm1, QWORD PTR [rsp+32]
    movsd xmm2, QWORD PTR [rsp+40]
    movsd xmm3, QWORD PTR [temp_d3]
    call printf

    ; --- vsExp 结果 ---
    movss xmm0, DWORD PTR [exp_result]
    cvtss2sd xmm0, xmm0
    movsd QWORD PTR [rsp+32], xmm0
    movss xmm0, DWORD PTR [exp_result+ (N/4)*4]
    cvtss2sd xmm0, xmm0
    movsd QWORD PTR [rsp+40], xmm0
    movss xmm0, DWORD PTR [exp_result+ (N/2)*4]
    cvtss2sd xmm0, xmm0
    movsd QWORD PTR [temp_d3], xmm0

    lea rcx, fmt_exp
    mov rdx, [rsp+32]
    mov r8, [rsp+40]
    mov r9, QWORD PTR [temp_d3]
    movsd xmm1, QWORD PTR [rsp+32]
    movsd xmm2, QWORD PTR [rsp+40]
    movsd xmm3, QWORD PTR [temp_d3]
    call printf

    ; --- 完成 ---
    lea rcx, fmt_done
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
