; ============================================================
; mkl_vml_math.asm - 从汇编调用Intel MKL VML向量数学库
; ============================================================
; 演示:
;   1. 从x86-64汇编调用MKL VML (Vector Math Library) 函数
;   2. vsSin/vsCos/vsExp 批量计算数学函数 (N=1024个float)
;   3. mkl_get_version_string 获取MKL版本信息
;
; MKL VML函数签名 (Windows x64调用约定):
;   void vsSin(const int n, const float* a, float* y)
;       RCX = n (元素数量)
;       RDX = a (输入数组指针)
;       R8  = y (输出数组指针)
;
; 优势:
;   - mkl_rt.lib 运行时自动选择最优代码路径 (AVX2)
;   - 针对i7-12700F自动启用AVX2+FMA3指令
;   - 高度优化的数学函数实现 (比手写Taylor级数更精确)
; ============================================================

default rel

N   equ 1024                      ; 数组元素数量

section .data
    align 4
    f_two_pi   dd 6.28318530
    f_N_float  dd 1024.0
    f_zero     dd 0.0

    align 8
    temp_d1    dq 0.0
    temp_d2    dq 0.0
    temp_d3    dq 0.0

    ; 格式字符串
    fmt_header db "=== MKL VML向量数学 (从汇编调用) ===", 10, 0
    fmt_mkl    db "MKL版本: %s", 10, 0
    fmt_info   db "使用 mkl_rt.lib 运行时CPU调度 -> 自动选择AVX2代码路径", 10, 10, 0
    fmt_sep    db "-------------------------------------------", 10, 0
    fmt_sin    db "vsSin: sin(0)=%.4f  sin(PI/2)=%.4f  sin(PI)=%.4f", 10, 0
    fmt_cos    db "vsCos: cos(0)=%.4f  cos(PI/2)=%.4f  cos(PI)=%.4f", 10, 0
    fmt_exp    db "vsExp: exp(0)=%.4f  exp(PI/2)=%.4f  exp(PI)=%.4f", 10, 0
    fmt_n      db "数组大小 N = %d, 每个函数处理 %d 个float", 10, 0
    fmt_done   db 10, "MKL VML向量数学演示完成.", 10, 0

section .bss
    alignb 32
    x_array    resd N             ; 输入数组
    sin_result resd N             ; vsSin输出
    cos_result resd N             ; vsCos输出
    exp_result resd N             ; vsExp输出
    alignb 8
    f_step     resd 1             ; 步长 = 2π/N
    mkl_ver_buf resb 256          ; MKL版本字符串缓冲区

section .text
    global main
    extern printf
    extern ExitProcess
    ; MKL VML 函数
    extern vsSin
    extern vsCos
    extern vsExp
    ; MKL 服务函数
    extern mkl_get_version_string

; ============================================================
; main
; ============================================================
main:
    push rbp
    mov rbp, rsp
    sub rsp, 48                   ; shadow(32) + temps(16)

    ; --- 打印头部 ---
    lea rcx, [fmt_header]
    call printf

    ; --- 获取并打印MKL版本 ---
    lea rcx, [mkl_ver_buf]
    mov edx, 256
    call mkl_get_version_string

    lea rcx, [fmt_mkl]
    lea rdx, [mkl_ver_buf]
    call printf

    lea rcx, [fmt_info]
    call printf
    lea rcx, [fmt_n]
    mov edx, N
    mov r8d, N
    call printf

    ; -------------------------------------------------------
    ; 1. 生成输入数组 x[i] = i * (2π/N)
    ; -------------------------------------------------------
    movss xmm0, [f_two_pi]
    divss xmm0, [f_N_float]
    movss [f_step], xmm0          ; step = 2π/N

    xor r12, r12                  ; i = 0
.gen_loop:
    cvtsi2ss xmm0, r12d           ; (float)i
    mulss xmm0, [f_step]          ; i * step
    movss [x_array + r12*4], xmm0
    inc r12
    cmp r12, N
    jl .gen_loop

    ; -------------------------------------------------------
    ; 2. 调用 MKL VML 函数
    ;    mkl_rt.lib 会自动检测CPU并选择AVX2代码路径
    ; -------------------------------------------------------

    ; --- vsSin(N, x_array, sin_result) ---
    ; RCX = N, RDX = x_array, R8 = sin_result
    mov ecx, N
    lea rdx, [x_array]
    lea r8, [sin_result]
    call vsSin

    ; --- vsCos(N, x_array, cos_result) ---
    mov ecx, N
    lea rdx, [x_array]
    lea r8, [cos_result]
    call vsCos

    ; --- vsExp(N, x_array, exp_result) ---
    ; 注意: exp(2π) ≈ 535, 在float范围内
    mov ecx, N
    lea rdx, [x_array]
    lea r8, [exp_result]
    call vsExp

    ; -------------------------------------------------------
    ; 3. 打印结果 (采样点: x=0, π/2, π)
    ;    索引: 0, N/4, N/2
    ; -------------------------------------------------------
    lea rcx, [fmt_sep]
    call printf

    ; --- vsSin 结果 ---
    ; sin(0) = sin_result[0], sin(π/2) = sin_result[N/4], sin(π) = sin_result[N/2]
    movss xmm0, [sin_result]
    cvtss2sd xmm0, xmm0
    movsd [rsp+32], xmm0
    movss xmm0, [sin_result + (N/4)*4]
    cvtss2sd xmm0, xmm0
    movsd [rsp+40], xmm0
    movss xmm0, [sin_result + (N/2)*4]
    cvtss2sd xmm0, xmm0
    movsd [temp_d3], xmm0

    lea rcx, [fmt_sin]
    mov rdx, [rsp+32]
    mov r8, [rsp+40]
    mov r9, [temp_d3]
    movsd xmm1, [rsp+32]
    movsd xmm2, [rsp+40]
    movsd xmm3, [temp_d3]
    call printf

    ; --- vsCos 结果 ---
    movss xmm0, [cos_result]
    cvtss2sd xmm0, xmm0
    movsd [rsp+32], xmm0
    movss xmm0, [cos_result + (N/4)*4]
    cvtss2sd xmm0, xmm0
    movsd [rsp+40], xmm0
    movss xmm0, [cos_result + (N/2)*4]
    cvtss2sd xmm0, xmm0
    movsd [temp_d3], xmm0

    lea rcx, [fmt_cos]
    mov rdx, [rsp+32]
    mov r8, [rsp+40]
    mov r9, [temp_d3]
    movsd xmm1, [rsp+32]
    movsd xmm2, [rsp+40]
    movsd xmm3, [temp_d3]
    call printf

    ; --- vsExp 结果 ---
    movss xmm0, [exp_result]
    cvtss2sd xmm0, xmm0
    movsd [rsp+32], xmm0
    movss xmm0, [exp_result + (N/4)*4]
    cvtss2sd xmm0, xmm0
    movsd [rsp+40], xmm0
    movss xmm0, [exp_result + (N/2)*4]
    cvtss2sd xmm0, xmm0
    movsd [temp_d3], xmm0

    lea rcx, [fmt_exp]
    mov rdx, [rsp+32]
    mov r8, [rsp+40]
    mov r9, [temp_d3]
    movsd xmm1, [rsp+32]
    movsd xmm2, [rsp+40]
    movsd xmm3, [temp_d3]
    call printf

    ; --- 完成 ---
    lea rcx, [fmt_done]
    call printf

    xor ecx, ecx
    call ExitProcess
