; ============================================================
; fpu_trig.asm - FSIN/FCOS/FPTAN 三角函数
; ============================================================
; 演示:
;   - fldpi            加载π到ST0
;   - fld [angle]; fsin   sin(angle)
;   - fld [angle]; fcos   cos(angle)
;   - fld [angle]; fptan  tan(angle) (结果: ST0=1.0, ST1=tan)
;
; 计算:
;   sin(pi/6) = 0.5
;   cos(pi/3) = 0.5
;   tan(pi/4) = 1.0
;
; 注意: FPTAN先压入1.0, 再将ST0替换为tan值
;       即执行后: ST0=1.0, ST1=tan(angle)
;       需要弹出1.0才能得到tan值
; ============================================================

default rel

section .data
    align 8
    result  dq 0.0             ; FPU结果存储
    align 4
    six     dd 6               ; 用于计算 pi/6
    three   dd 3               ; 用于计算 pi/3
    four    dd 4               ; 用于计算 pi/4

    fmt_pi   db "FLDPI: pi = %f", 10, 0
    fmt_sin  db "FSIN:  sin(pi/6) = %f  (expected: 0.5)", 10, 0
    fmt_cos  db "FCOS:  cos(pi/3) = %f  (expected: 0.5)", 10, 0
    fmt_tan  db "FPTAN: tan(pi/4) = %f  (expected: 1.0)", 10, 0
    fmt_done db "FPU trig demo completed.", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    finit                      ; 初始化FPU

    ; -------------------------------------------------------
    ; 1. FLDPI - 加载π常量到ST0
    ;    FPU内部使用66位精度的π值
    ; -------------------------------------------------------
    fldpi                      ; ST0 = π
    fstp qword [result]        ; 存储并弹出

    lea rcx, [fmt_pi]
    mov rdx, [result]
    movsd xmm1, [result]
    call printf

    ; -------------------------------------------------------
    ; 2. FSIN - 正弦函数
    ;    计算 sin(pi/6) = 0.5
    ;    使用 fidiv 将 pi 除以整数6 (fidiv直接从内存读取整数)
    ; -------------------------------------------------------
    fldpi                      ; ST0 = π
    fidiv dword [six]          ; ST0 = π/6
    fsin                       ; ST0 = sin(π/6) = 0.5
    fstp qword [result]        ; 存储并弹出

    lea rcx, [fmt_sin]
    mov rdx, [result]
    movsd xmm1, [result]
    call printf

    ; -------------------------------------------------------
    ; 3. FCOS - 余弦函数
    ;    计算 cos(pi/3) = 0.5
    ; -------------------------------------------------------
    fldpi                      ; ST0 = π
    fidiv dword [three]        ; ST0 = π/3
    fcos                       ; ST0 = cos(π/3) = 0.5
    fstp qword [result]        ; 存储并弹出

    lea rcx, [fmt_cos]
    mov rdx, [result]
    movsd xmm1, [result]
    call printf

    ; -------------------------------------------------------
    ; 4. FPTAN - 正切函数
    ;    计算 tan(pi/4) = 1.0
    ;    FPTAN的输出: 先压入1.0, ST0变为tan值
    ;    执行前: ST0 = angle
    ;    执行后: ST0 = 1.0, ST1 = tan(angle)
    ;    需要弹出1.0 (fstp st0) 才能获取tan值
    ; -------------------------------------------------------
    fldpi                      ; ST0 = π
    fidiv dword [four]         ; ST0 = π/4
    fptan                      ; ST0 = 1.0, ST1 = tan(π/4) = 1.0
    fstp st0                   ; 弹出1.0, ST0现在为tan(π/4)
    fstp qword [result]        ; 存储tan值并弹出

    lea rcx, [fmt_tan]
    mov rdx, [result]
    movsd xmm1, [result]
    call printf

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    lea rcx, [fmt_done]
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
