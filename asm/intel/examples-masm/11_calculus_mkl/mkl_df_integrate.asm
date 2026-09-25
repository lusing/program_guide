; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
NX      equ 21                       ; 断点数
NSITE   equ 1000                     ; 插值点数
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
extern printf : PROC
extern ExitProcess : PROC
extern dfdNewTask1D : PROC
extern dfdEditPPSpline1D : PROC
extern dfdConstruct1D : PROC
extern dfdInterpolate1D : PROC
extern dfDeleteTask : PROC

.data
    align 8
    d_pi           REAL8 3.14159265358979
    d_two          REAL8 2.0
    d_zero         REAL8 0.0
    d_inv_20       REAL8 0.05            ; 1/(NX-1) = 1/20
    d_inv_nsite    REAL8 0.001           ; 1/NSITE
    abs_mask       QWORD 7FFFFFFFFFFFFFFFh

    ; Taylor系数 (double精度, 7项)
    d_1_6          REAL8 0.16666666666666667
    d_1_120        REAL8 0.008333333333333333
    d_1_5040       REAL8 0.00019841269841269841
    d_1_362880     REAL8 2.7557319223985893e-6
    d_1_39916800   REAL8 2.505210838544172e-8
    d_1_6227020800 REAL8 1.6059043836821613e-10

    align 8
    temp_d         REAL8 0.0
    temp_d2        REAL8 0.0

    ; 格式字符串
    fmt_header  BYTE "=== MKL Data Fitting样条积分 ===", 10, 0
    fmt_info    BYTE "使用三次样条拟合 sin(x), 插值后梯形法积分", 10, 0
    fmt_pts     BYTE "断点数: %d, 插值点数: %d, 区间: [0, PI]", 10, 10, 0
    fmt_sep     BYTE "-------------------------------------------", 10, 0
    fmt_step    BYTE "[1] dfdNewTask1D      - 创建插值任务...", 10, 0
    fmt_step2   BYTE "[2] dfdEditPPSpline1D - 配置三次样条...", 10, 0
    fmt_step3   BYTE "[3] dfdConstruct1D    - 构建样条...", 10, 0
    fmt_step4   BYTE "[4] dfdInterpolate1D  - 样条插值...", 10, 0
    fmt_step5   BYTE "[5] dfDeleteTask      - 释放资源...", 10, 0
    fmt_ok      BYTE "  -> 状态: %d (0=成功)", 10, 0
    fmt_result  BYTE 10, "样条插值后梯形积分: %.10f", 10, 0
    fmt_exact   BYTE "精确值:   2.0000000000", 10, 0
    fmt_error   BYTE "误差:     %.2e", 10, 0
    fmt_done    BYTE 10, "MKL Data Fitting样条积分演示完成.", 10, 0
    fmt_fail    BYTE "  -> 错误! 状态: %d", 10, 0

    dorder_local DWORD 1

.data?
    ALIGN 8
    task_ptr     QWORD 1 DUP(?); DFTaskPtr
    x_breakpts   QWORD NX DUP(?); 断点x坐标
    y_values     QWORD NX DUP(?); 函数值
    site         QWORD NSITE DUP(?); 插值点
    interp_result QWORD NSITE DUP(?); 插值结果
    scoeff       QWORD (NX-1)*4 DUP(?); 样条系数
    mkl_status   DWORD 1 DUP(?)


.code

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
    mulsd xmm2, QWORD PTR [d_1_6]
    mulsd xmm3, QWORD PTR [d_1_120]
    mulsd xmm4, QWORD PTR [d_1_5040]
    mulsd xmm5, QWORD PTR [d_1_362880]
    mulsd xmm6, QWORD PTR [d_1_39916800]
    mulsd xmm7, QWORD PTR [d_1_6227020800]
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
main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 112                   ; 16字节对齐

    ; --- 打印头部 ---
    lea rcx, fmt_header
    call printf
    lea rcx, fmt_info
    call printf
    lea rcx, fmt_pts
    mov edx, NX
    mov r8d, NSITE
    call printf

    ; -------------------------------------------------------
    ; 1. 预计算断点和函数值
    ; -------------------------------------------------------
    xor r12, r12
maingen_loop:
    cvtsi2sd xmm0, r12
    mulsd xmm0, QWORD PTR [d_pi]
    mulsd xmm0, QWORD PTR [d_inv_20]
    movsd QWORD PTR [x_breakpts+ r12*8], xmm0
    call compute_sin_double
    movsd QWORD PTR [y_values+ r12*8], xmm0
    inc r12
    cmp r12, NX
    jl maingen_loop

    ; 生成插值点 (均匀分布在[0, π])
    xor r12, r12
mainsite_loop:
    cvtsi2sd xmm0, r12
    mulsd xmm0, QWORD PTR [d_pi]
    mulsd xmm0, QWORD PTR [d_inv_nsite]
    movsd QWORD PTR [site+ r12*8], xmm0
    inc r12
    cmp r12, NSITE
    jl mainsite_loop

    ; -------------------------------------------------------
    ; 2. dfdNewTask1D
    ; -------------------------------------------------------
    lea rcx, fmt_step
    call printf

    lea rcx, task_ptr
    mov edx, NX
    lea r8, x_breakpts
    xor r9d, r9d
    mov QWORD PTR [rsp+32], 1
    lea rax, y_values
    mov [rsp+40], rax
    mov QWORD PTR [rsp+48], 0
    call dfdNewTask1D
    mov DWORD PTR [mkl_status], eax

    lea rcx, fmt_ok
    mov edx, DWORD PTR [mkl_status]
    call printf
    cmp DWORD PTR [mkl_status], 0
    jne mainmkl_error

    ; -------------------------------------------------------
    ; 3. dfdEditPPSpline1D
    ; -------------------------------------------------------
    lea rcx, fmt_step2
    call printf

    mov rcx, QWORD PTR [task_ptr]
    mov edx, DF_PP_CUBIC
    mov r8d, DF_PP_BESSEL
    mov r9d, DF_BC_NOT_A_KNOT
    mov QWORD PTR [rsp+32], 0
    mov QWORD PTR [rsp+40], DF_NO_IC
    mov QWORD PTR [rsp+48], 0
    lea rax, scoeff
    mov [rsp+56], rax
    call dfdEditPPSpline1D
    mov DWORD PTR [mkl_status], eax

    lea rcx, fmt_ok
    mov edx, DWORD PTR [mkl_status]
    call printf
    cmp DWORD PTR [mkl_status], 0
    jne mainmkl_error

    ; -------------------------------------------------------
    ; 4. dfdConstruct1D
    ; -------------------------------------------------------
    lea rcx, fmt_step3
    call printf

    mov rcx, QWORD PTR [task_ptr]
    mov edx, DF_PP_SPLINE
    xor r8d, r8d
    call dfdConstruct1D
    mov DWORD PTR [mkl_status], eax

    lea rcx, fmt_ok
    mov edx, DWORD PTR [mkl_status]
    call printf
    cmp DWORD PTR [mkl_status], 0
    jne mainmkl_error

    ; -------------------------------------------------------
    ; 5. dfdInterpolate1D - 样条插值
    ;    dfdInterpolate1D(task, type, method, nsite, site[], sitehint,
    ;                     ndorder, dorder[], datahint, r[], rhint, cell[])
    ;    12参数: RCX=task, RDX=type, R8=method, R9=nsite,
    ;          [rsp+32]=site, [rsp+40]=sitehint, [rsp+48]=ndorder,
    ;          [rsp+56]=dorder, [rsp+64]=datahint, [rsp+72]=r,
    ;          [rsp+80]=rhint, [rsp+88]=cell
    ; -------------------------------------------------------
    lea rcx, fmt_step4
    call printf

    mov rcx, QWORD PTR [task_ptr]
    mov edx, DF_INTERP
    mov r8d, DF_METHOD_PP
    mov r9d, NSITE
    lea rax, site
    mov [rsp+32], rax
    mov QWORD PTR [rsp+40], DF_NO_HINT
    mov QWORD PTR [rsp+48], 1
    lea rax, dorder_local
    mov [rsp+56], rax
    mov QWORD PTR [rsp+64], DF_NO_APRIORI_INFO
    lea rax, interp_result
    mov [rsp+72], rax
    mov QWORD PTR [rsp+80], DF_MATRIX_STORAGE_ROWS
    mov QWORD PTR [rsp+88], 0
    call dfdInterpolate1D
    mov DWORD PTR [mkl_status], eax

    lea rcx, fmt_ok
    mov edx, DWORD PTR [mkl_status]
    call printf
    cmp DWORD PTR [mkl_status], 0
    jne mainmkl_error

    ; -------------------------------------------------------
    ; 6. 手动梯形法积分插值结果
    ;    h = π/NSITE, result = h * Σ(interpQWORD PTR [i])
    ; -------------------------------------------------------
    xor r12, r12
    pxor xmm0, xmm0                ; sum = 0
maintrap_loop:
    movsd xmm1, QWORD PTR [interp_result+ r12*8]
    addsd xmm0, xmm1
    inc r12
    cmp r12, NSITE
    jl maintrap_loop

    mulsd xmm0, QWORD PTR [d_pi]
    mulsd xmm0, QWORD PTR [d_inv_nsite]      ; result = sum * π/NSITE
    movsd QWORD PTR [temp_d], xmm0

    ; -------------------------------------------------------
    ; 7. dfDeleteTask
    ; -------------------------------------------------------
    lea rcx, fmt_step5
    call printf

    lea rcx, task_ptr
    call dfDeleteTask
    mov DWORD PTR [mkl_status], eax

    lea rcx, fmt_ok
    mov edx, DWORD PTR [mkl_status]
    call printf

    ; -------------------------------------------------------
    ; 8. 打印结果
    ; -------------------------------------------------------
    lea rcx, fmt_sep
    call printf

    lea rcx, fmt_result
    mov rdx, QWORD PTR [temp_d]
    movsd xmm1, QWORD PTR [temp_d]
    call printf

    lea rcx, fmt_exact
    call printf

    movsd xmm0, QWORD PTR [temp_d]
    subsd xmm0, QWORD PTR [d_two]
    vandpd xmm0, xmm0, XMMWORD PTR [abs_mask]
    movsd QWORD PTR [temp_d2], xmm0
    lea rcx, fmt_error
    mov rdx, QWORD PTR [temp_d2]
    movsd xmm1, QWORD PTR [temp_d2]
    call printf

    lea rcx, fmt_done
    call printf
    jmp mainexit

mainmkl_error:
    lea rcx, fmt_fail
    mov edx, DWORD PTR [mkl_status]
    call printf
    cmp QWORD PTR [task_ptr], 0
    je mainexit
    lea rcx, task_ptr
    call dfDeleteTask

mainexit:
    xor ecx, ecx
    call ExitProcess

main ENDP
END
