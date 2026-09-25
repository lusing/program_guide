; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    a_val   REAL8 3.14            ; 加法操作数1
    b_val   REAL8 2.72            ; 加法操作数2
    c_val   REAL8 10.5            ; 减法操作数1
    d_val   REAL8 3.7             ; 减法操作数2
    result  REAL8 0.0             ; 结果存储

    fmt_add  BYTE "FADDP: 3.14 + 2.72 = %f", 10, 0
    fmt_sub  BYTE "FSUBP: 10.5 - 3.7 = %f", 10, 0
    fmt_addm BYTE "FADD [mem]: 3.14 + 2.72 = %f  (ST0 += memory)", 10, 0
    fmt_done BYTE "FPU add/sub demo completed.", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    finit                      ; 初始化FPU

    ; -------------------------------------------------------
    ; 1. FADDP - 浮点加法并弹出
    ;    操作: ST0 = ST1 + ST0, 然后弹出原ST0
    ;    栈变化: [ST1, ST0] -> [ST0(=结果)]
    ; -------------------------------------------------------
    fld QWORD PTR [a_val]          ; ST0 = 3.14
    fld QWORD PTR [b_val]          ; ST0 = 2.72, ST1 = 3.14
    faddp                      ; ST0 = 3.14 + 2.72 = 5.86 (弹出后ST1变ST0)
    fstp QWORD PTR [result]        ; 存储结果, 栈空

    lea rcx, fmt_add
    mov rdx, [result]
    movsd xmm1, QWORD PTR [result]
    call printf

    ; -------------------------------------------------------
    ; 2. FSUBP - 浮点减法并弹出
    ;    操作: ST0 = ST1 - ST0, 然后弹出原ST0
    ;    注意顺序: ST1 - ST0 (不是ST0 - ST1)
    ; -------------------------------------------------------
    fld QWORD PTR [c_val]          ; ST0 = 10.5
    fld QWORD PTR [d_val]          ; ST0 = 3.7, ST1 = 10.5
    fsubp                      ; ST0 = 10.5 - 3.7 = 6.8 (弹出后ST1变ST0)
    fstp QWORD PTR [result]        ; 存储结果, 栈空

    lea rcx, fmt_sub
    mov rdx, [result]
    movsd xmm1, QWORD PTR [result]
    call printf

    ; -------------------------------------------------------
    ; 3. FADD QWORD PTR [mem] - 直接加内存中的值
    ;    操作: ST0 += [mem] (不改变栈深度)
    ;    与FADDP不同，不弹出，直接将内存值加到ST0
    ; -------------------------------------------------------
    fld QWORD PTR [a_val]          ; ST0 = 3.14
    fadd QWORD PTR [b_val]         ; ST0 = 3.14 + 2.72 = 5.86 (直接加内存值)
    fstp QWORD PTR [result]        ; 存储结果, 栈空

    lea rcx, fmt_addm
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
