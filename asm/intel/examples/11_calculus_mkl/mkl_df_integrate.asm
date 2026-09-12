; ============================================================
; mkl_df_integrate.asm - MKL Data Fitting样条积分
; ============================================================
; 使用Intel MKL Data Fitting库进行三次样条插值和积分:
;   1. 在[0,π]区间取21个断点, 计算sin(x)函数值
;   2. 构建三次样条(Not-a-Knot边界条件)拟合数据
;   3. 用样条在1000个点上插值, 然后梯形法积分
;   4. 精确值: ∫sin(x)dx [0,π] = 2.0
;
; MKL DF API调用流程 (从汇编):
;   dfdNewTask1D      - 创建1D插值任务 (7参数: 4寄存器+3栈)
;   dfdEditPPSpline1D - 配置三次样条    (8参数: 4寄存器+4栈)
;   dfdConstruct1D    - 构建样条        (3参数: 全寄存器)
;   dfdInterpolate1D  - 样条插值        (12参数: 4寄存器+8栈)
;   dfDeleteTask      - 释放任务        (1参数: 寄存器)
; ============================================================

default rel

NX      equ 21                       ; 断点数
NSITE   equ 1000                     ; 插值点数

; MKL Data Fitting 常量
DF_PP_CUBIC        equ 4
DF_PP_BESSEL       equ 4
DF_BC_NOT_A_KNOT   equ 1
DF_NO_IC           equ 0
DF_PP_SPLINE       equ 0
DF_METHOD_STD      equ 0
DF_METHOD_PP       equ 1
DF_INTERP          equ 1
DF_NO_HINT         equ 0
DF_NO_APRIORI_INFO equ 0
DF_MATRIX_STORAGE_ROWS equ 0

section .data
    align 8
    d_pi           dq 3.14159265358979
    d_two          dq 2.0
    d_zero         dq 0.0
    d_inv_20       dq 0.05            ; 1/(NX-1) = 1/20
    d_inv_nsite    dq 0.001           ; 1/NSITE
    abs_mask       dq 0x7FFFFFFFFFFFFFFF

    ; Taylor系数 (double精度, 7项)
    d_1_6          dq 0.16666666666666667
    d_1_120        dq 0.008333333333333333
    d_1_5040       dq 0.00019841269841269841
    d_1_362880     dq 2.7557319223985893e-6
    d_1_39916800   dq 2.505210838544172e-8
    d_1_6227020800 dq 1.6059043836821613e-10

    align 8
    temp_d         dq 0.0
    temp_d2        dq 0.0

    ; 格式字符串
    fmt_header  db "=== MKL Data Fitting样条积分 ===", 10, 0
    fmt_info    db "使用三次样条拟合 sin(x), 插值后梯形法积分", 10, 0
    fmt_pts     db "断点数: %d, 插值点数: %d, 区间: [0, PI]", 10, 10, 0
    fmt_sep     db "-------------------------------------------", 10, 0
    fmt_step    db "[1] dfdNewTask1D      - 创建插值任务...", 10, 0
    fmt_step2   db "[2] dfdEditPPSpline1D - 配置三次样条...", 10, 0
    fmt_step3   db "[3] dfdConstruct1D    - 构建样条...", 10, 0
    fmt_step4   db "[4] dfdInterpolate1D  - 样条插值...", 10, 0
    fmt_step5   db "[5] dfDeleteTask      - 释放资源...", 10, 0
    fmt_ok      db "  -> 状态: %d (0=成功)", 10, 0
    fmt_result  db 10, "样条插值后梯形积分: %.10f", 10, 0
    fmt_exact   db "精确值:   2.0000000000", 10, 0
    fmt_error   db "误差:     %.2e", 10, 0
    fmt_done    db 10, "MKL Data Fitting样条积分演示完成.", 10, 0
    fmt_fail    db "  -> 错误! 状态: %d", 10, 0

section .bss
    alignb 8
    task_ptr     resq 1             ; DFTaskPtr
    x_breakpts   resq NX            ; 断点x坐标
    y_values     resq NX            ; 函数值
    site         resq NSITE         ; 插值点
    interp_result resq NSITE        ; 插值结果
    scoeff       resq (NX-1)*4      ; 样条系数
    mkl_status   resd 1

section .text
    global main
    extern printf
    extern ExitProcess
    extern dfdNewTask1D
    extern dfdEditPPSpline1D
    extern dfdConstruct1D
    extern dfdInterpolate1D
    extern dfDeleteTask

; ============================================================
; compute_sin_double - double精度sin(x) Taylor级数
; ============================================================
compute_sin_double:
    movsd xmm1, xmm0
    mulsd xmm1, xmm0               ; x²
    movsd xmm2, xmm1
    mulsd xmm2, xmm0               ; x³
    movsd xmm3, xmm2
    mulsd xmm3, xmm1               ; x⁵
    movsd xmm4, xmm3
    mulsd xmm4, xmm1               ; x⁷
    movsd xmm5, xmm4
    mulsd xmm5, xmm1               ; x⁹
    movsd xmm6, xmm5
    mulsd xmm6, xmm1               ; x¹¹
    movsd xmm7, xmm6
    mulsd xmm7, xmm1               ; x¹³
    mulsd xmm2, [d_1_6]
    mulsd xmm3, [d_1_120]
    mulsd xmm4, [d_1_5040]
    mulsd xmm5, [d_1_362880]
    mulsd xmm6, [d_1_39916800]
    mulsd xmm7, [d_1_6227020800]
    subsd xmm0, xmm2
    addsd xmm0, xmm3
    subsd xmm0, xmm4
    addsd xmm0, xmm5
    subsd xmm0, xmm6
    addsd xmm0, xmm7
    ret

; ============================================================
; main
; 栈布局 (sub rsp, 112):
;   [rsp+0..31]   shadow space
;   [rsp+32..103] 栈参数 (最多9个×8字节)
;   [rsp+104..111] 备用
; ============================================================
main:
    push rbp
    mov rbp, rsp
    sub rsp, 112                   ; 16字节对齐

    ; --- 打印头部 ---
    lea rcx, [fmt_header]
    call printf
    lea rcx, [fmt_info]
    call printf
    lea rcx, [fmt_pts]
    mov edx, NX
    mov r8d, NSITE
    call printf

    ; -------------------------------------------------------
    ; 1. 预计算断点和函数值
    ; -------------------------------------------------------
    xor r12, r12
.gen_loop:
    cvtsi2sd xmm0, r12
    mulsd xmm0, [d_pi]
    mulsd xmm0, [d_inv_20]
    movsd [x_breakpts + r12*8], xmm0
    call compute_sin_double
    movsd [y_values + r12*8], xmm0
    inc r12
    cmp r12, NX
    jl .gen_loop

    ; 生成插值点 (均匀分布在[0, π])
    xor r12, r12
.site_loop:
    cvtsi2sd xmm0, r12
    mulsd xmm0, [d_pi]
    mulsd xmm0, [d_inv_nsite]
    movsd [site + r12*8], xmm0
    inc r12
    cmp r12, NSITE
    jl .site_loop

    ; -------------------------------------------------------
    ; 2. dfdNewTask1D
    ; -------------------------------------------------------
    lea rcx, [fmt_step]
    call printf

    lea rcx, [task_ptr]
    mov edx, NX
    lea r8, [x_breakpts]
    xor r9d, r9d
    mov qword [rsp+32], 1
    lea rax, [y_values]
    mov [rsp+40], rax
    mov qword [rsp+48], 0
    call dfdNewTask1D
    mov [mkl_status], eax

    lea rcx, [fmt_ok]
    mov edx, [mkl_status]
    call printf
    cmp dword [mkl_status], 0
    jne .mkl_error

    ; -------------------------------------------------------
    ; 3. dfdEditPPSpline1D
    ; -------------------------------------------------------
    lea rcx, [fmt_step2]
    call printf

    mov rcx, [task_ptr]
    mov edx, DF_PP_CUBIC
    mov r8d, DF_PP_BESSEL
    mov r9d, DF_BC_NOT_A_KNOT
    mov qword [rsp+32], 0
    mov qword [rsp+40], DF_NO_IC
    mov qword [rsp+48], 0
    lea rax, [scoeff]
    mov [rsp+56], rax
    call dfdEditPPSpline1D
    mov [mkl_status], eax

    lea rcx, [fmt_ok]
    mov edx, [mkl_status]
    call printf
    cmp dword [mkl_status], 0
    jne .mkl_error

    ; -------------------------------------------------------
    ; 4. dfdConstruct1D
    ; -------------------------------------------------------
    lea rcx, [fmt_step3]
    call printf

    mov rcx, [task_ptr]
    mov edx, DF_PP_SPLINE
    xor r8d, r8d
    call dfdConstruct1D
    mov [mkl_status], eax

    lea rcx, [fmt_ok]
    mov edx, [mkl_status]
    call printf
    cmp dword [mkl_status], 0
    jne .mkl_error

    ; -------------------------------------------------------
    ; 5. dfdInterpolate1D - 样条插值
    ;    dfdInterpolate1D(task, type, method, nsite, site[], sitehint,
    ;                     ndorder, dorder[], datahint, r[], rhint, cell[])
    ;    12参数: RCX=task, RDX=type, R8=method, R9=nsite,
    ;          [rsp+32]=site, [rsp+40]=sitehint, [rsp+48]=ndorder,
    ;          [rsp+56]=dorder, [rsp+64]=datahint, [rsp+72]=r,
    ;          [rsp+80]=rhint, [rsp+88]=cell
    ; -------------------------------------------------------
    lea rcx, [fmt_step4]
    call printf

    mov rcx, [task_ptr]
    mov edx, DF_INTERP
    mov r8d, DF_METHOD_PP
    mov r9d, NSITE
    lea rax, [site]
    mov [rsp+32], rax
    mov qword [rsp+40], DF_NO_HINT
    mov qword [rsp+48], 1
    lea rax, [dorder_local]
    mov [rsp+56], rax
    mov qword [rsp+64], DF_NO_APRIORI_INFO
    lea rax, [interp_result]
    mov [rsp+72], rax
    mov qword [rsp+80], DF_MATRIX_STORAGE_ROWS
    mov qword [rsp+88], 0
    call dfdInterpolate1D
    mov [mkl_status], eax

    lea rcx, [fmt_ok]
    mov edx, [mkl_status]
    call printf
    cmp dword [mkl_status], 0
    jne .mkl_error

    ; -------------------------------------------------------
    ; 6. 手动梯形法积分插值结果
    ;    h = π/NSITE, result = h * Σ(interp[i])
    ; -------------------------------------------------------
    xor r12, r12
    pxor xmm0, xmm0                ; sum = 0
.trap_loop:
    movsd xmm1, [interp_result + r12*8]
    addsd xmm0, xmm1
    inc r12
    cmp r12, NSITE
    jl .trap_loop

    mulsd xmm0, [d_pi]
    mulsd xmm0, [d_inv_nsite]      ; result = sum * π/NSITE
    movsd [temp_d], xmm0

    ; -------------------------------------------------------
    ; 7. dfDeleteTask
    ; -------------------------------------------------------
    lea rcx, [fmt_step5]
    call printf

    lea rcx, [task_ptr]
    call dfDeleteTask
    mov [mkl_status], eax

    lea rcx, [fmt_ok]
    mov edx, [mkl_status]
    call printf

    ; -------------------------------------------------------
    ; 8. 打印结果
    ; -------------------------------------------------------
    lea rcx, [fmt_sep]
    call printf

    lea rcx, [fmt_result]
    mov rdx, [temp_d]
    movsd xmm1, [temp_d]
    call printf

    lea rcx, [fmt_exact]
    call printf

    movsd xmm0, [temp_d]
    subsd xmm0, [d_two]
    vandpd xmm0, xmm0, [abs_mask]
    movsd [temp_d2], xmm0
    lea rcx, [fmt_error]
    mov rdx, [temp_d2]
    movsd xmm1, [temp_d2]
    call printf

    lea rcx, [fmt_done]
    call printf
    jmp .exit

.mkl_error:
    lea rcx, [fmt_fail]
    mov edx, [mkl_status]
    call printf
    cmp qword [task_ptr], 0
    je .exit
    lea rcx, [task_ptr]
    call dfDeleteTask

.exit:
    xor ecx, ecx
    call ExitProcess

section .data
    dorder_local dd 1
