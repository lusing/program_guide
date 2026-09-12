; ============================================================
; fpu_mul_div.asm - FMUL/FDIV 浮点乘除法
; ============================================================
; 演示:
;   - fmulp  ST0 = ST1 * ST0, 然后弹出
;   - fdivp  ST0 = ST1 / ST0, 然后弹出
;
; 计算: 3.0 * 4.0 = 12.0
;       22.0 / 7.0 = 3.142857...  (近似圆周率)
; ============================================================

default rel

section .data
    align 8
    val3    dq 3.0             ; 乘法操作数1
    val4    dq 4.0             ; 乘法操作数2
    val22   dq 22.0            ; 除法操作数1 (被除数)
    val7    dq 7.0             ; 除法操作数2 (除数)
    result  dq 0.0             ; 结果存储

    fmt_mul  db "FMULP: 3.0 * 4.0 = %f", 10, 0
    fmt_div  db "FDIVP: 22.0 / 7.0 = %f", 10, 0
    fmt_done db "FPU mul/div demo completed.", 10, 0

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
    ; 1. FMULP - 浮点乘法并弹出
    ;    操作: ST0 = ST1 * ST0, 然后弹出原ST0
    ;    栈变化: [ST1, ST0] -> [ST0(=结果)]
    ; -------------------------------------------------------
    fld qword [val3]           ; ST0 = 3.0
    fld qword [val4]           ; ST0 = 4.0, ST1 = 3.0
    fmulp                      ; ST0 = 3.0 * 4.0 = 12.0 (弹出后ST1变ST0)
    fstp qword [result]        ; 存储结果, 栈空

    lea rcx, [fmt_mul]
    mov rdx, [result]
    movsd xmm1, [result]
    call printf

    ; -------------------------------------------------------
    ; 2. FDIVP - 浮点除法并弹出
    ;    操作: ST0 = ST1 / ST0, 然后弹出原ST0
    ;    注意顺序: ST1 / ST0 (被除数在ST1, 除数在ST0)
    ; -------------------------------------------------------
    fld qword [val22]          ; ST0 = 22.0
    fld qword [val7]           ; ST0 = 7.0, ST1 = 22.0
    fdivp                      ; ST0 = 22.0 / 7.0 = 3.142857... (弹出后ST1变ST0)
    fstp qword [result]        ; 存储结果, 栈空

    lea rcx, [fmt_div]
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
