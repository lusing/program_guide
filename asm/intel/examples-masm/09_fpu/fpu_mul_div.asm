; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    val3    REAL8 3.0             ; 乘法操作数1
    val4    REAL8 4.0             ; 乘法操作数2
    val22   REAL8 22.0            ; 除法操作数1 (被除数)
    val7    REAL8 7.0             ; 除法操作数2 (除数)
    result  REAL8 0.0             ; 结果存储

    fmt_mul  BYTE "FMULP: 3.0 * 4.0 = %f", 10, 0
    fmt_div  BYTE "FDIVP: 22.0 / 7.0 = %f", 10, 0
    fmt_done BYTE "FPU mul/div demo completed.", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    finit                      ; 初始化FPU

    ; -------------------------------------------------------
    ; 1. FMULP - 浮点乘法并弹出
    ;    操作: ST0 = ST1 * ST0, 然后弹出原ST0
    ;    栈变化: [ST1, ST0] -> [ST0(=结果)]
    ; -------------------------------------------------------
    fld QWORD PTR [val3]           ; ST0 = 3.0
    fld QWORD PTR [val4]           ; ST0 = 4.0, ST1 = 3.0
    fmulp                      ; ST0 = 3.0 * 4.0 = 12.0 (弹出后ST1变ST0)
    fstp QWORD PTR [result]        ; 存储结果, 栈空

    lea rcx, fmt_mul
    mov rdx, [result]
    movsd xmm1, QWORD PTR [result]
    call printf

    ; -------------------------------------------------------
    ; 2. FDIVP - 浮点除法并弹出
    ;    操作: ST0 = ST1 / ST0, 然后弹出原ST0
    ;    注意顺序: ST1 / ST0 (被除数在ST1, 除数在ST0)
    ; -------------------------------------------------------
    fld QWORD PTR [val22]          ; ST0 = 22.0
    fld QWORD PTR [val7]           ; ST0 = 7.0, ST1 = 22.0
    fdivp                      ; ST0 = 22.0 / 7.0 = 3.142857... (弹出后ST1变ST0)
    fstp QWORD PTR [result]        ; 存储结果, 栈空

    lea rcx, fmt_div
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
