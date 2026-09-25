; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    result  REAL8 0.0             ; FPU结果存储
    align 4
    six     DWORD 6               ; 用于计算 pi/6
    three   DWORD 3               ; 用于计算 pi/3
    four    DWORD 4               ; 用于计算 pi/4

    fmt_pi   BYTE "FLDPI: pi = %f", 10, 0
    fmt_sin  BYTE "FSIN:  sin(pi/6) = %f  (expected: 0.5)", 10, 0
    fmt_cos  BYTE "FCOS:  cos(pi/3) = %f  (expected: 0.5)", 10, 0
    fmt_tan  BYTE "FPTAN: tan(pi/4) = %f  (expected: 1.0)", 10, 0
    fmt_done BYTE "FPU trig demo completed.", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    finit                      ; 初始化FPU

    ; -------------------------------------------------------
    ; 1. FLDPI - 加载π常量到ST0
    ;    FPU内部使用66位精度的π值
    ; -------------------------------------------------------
    fldpi                      ; ST0 = π
    fstp QWORD PTR [result]        ; 存储并弹出

    lea rcx, fmt_pi
    mov rdx, [result]
    movsd xmm1, QWORD PTR [result]
    call printf

    ; -------------------------------------------------------
    ; 2. FSIN - 正弦函数
    ;    计算 sin(pi/6) = 0.5
    ;    使用 fidiv 将 pi 除以整数6 (fidiv直接从内存读取整数)
    ; -------------------------------------------------------
    fldpi                      ; ST0 = π
    fidiv DWORD PTR [six]          ; ST0 = π/6
    fsin                       ; ST0 = sin(π/6) = 0.5
    fstp QWORD PTR [result]        ; 存储并弹出

    lea rcx, fmt_sin
    mov rdx, [result]
    movsd xmm1, QWORD PTR [result]
    call printf

    ; -------------------------------------------------------
    ; 3. FCOS - 余弦函数
    ;    计算 cos(pi/3) = 0.5
    ; -------------------------------------------------------
    fldpi                      ; ST0 = π
    fidiv DWORD PTR [three]        ; ST0 = π/3
    fcos                       ; ST0 = cos(π/3) = 0.5
    fstp QWORD PTR [result]        ; 存储并弹出

    lea rcx, fmt_cos
    mov rdx, [result]
    movsd xmm1, QWORD PTR [result]
    call printf

    ; -------------------------------------------------------
    ; 4. FPTAN - 正切函数
    ;    计算 tan(pi/4) = 1.0
    ;    FPTAN的输出: 先压入1.0, ST0变为tan值
    ;    执行前: ST0 = angle
    ;    执行后: ST0 = 1.0, ST1 = tan(angle)
    ;    需要弹出1.0 (fstp st(0)) 才能获取tan值
    ; -------------------------------------------------------
    fldpi                      ; ST0 = π
    fidiv DWORD PTR [four]         ; ST0 = π/4
    fptan                      ; ST0 = 1.0, ST1 = tan(π/4) = 1.0
    fstp st(0)                   ; 弹出1.0, ST0现在为tan(π/4)
    fstp QWORD PTR [result]        ; 存储tan值并弹出

    lea rcx, fmt_tan
    mov rdx, [result]
    movsd xmm1, QWORD PTR [result]
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
