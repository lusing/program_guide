; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    val_a   REAL8 3.14            ; 比较值1 (较大)
    val_b   REAL8 2.72            ; 比较值2 (较小)
    result  REAL8 0.0             ; 用于清空FPU栈

    fmt_fcomi_gt BYTE "FCOMI: 3.14 > 2.72 is TRUE", 10, 0
    fmt_fcomi_eq BYTE "FCOMI: 3.14 == 2.72 is TRUE", 10, 0
    fmt_fcomi_lt BYTE "FCOMI: 3.14 < 2.72 is TRUE", 10, 0
    fmt_fcom_gt  BYTE "FCOM:  3.14 > 2.72 is TRUE (via status word)", 10, 0
    fmt_fcom_eq  BYTE "FCOM:  3.14 == 2.72 is TRUE (via status word)", 10, 0
    fmt_fcom_lt  BYTE "FCOM:  3.14 < 2.72 is TRUE (via status word)", 10, 0
    fmt_done     BYTE "FPU compare demo completed.", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    finit                      ; 初始化FPU

    ; -------------------------------------------------------
    ; 1. FCOMI - 直接设置EFLAGS的现代比较方式
    ;    fcomi st(0), st(1) 比较 ST0 和 ST1
    ;    直接设置 CF 和 ZF (不需要状态字转换):
    ;      ST0 > ST1: CF=0, ZF=0  -> JA 跳转
    ;      ST0 < ST1: CF=1, ZF=0  -> JB 跳转
    ;      ST0 = ST1: CF=0, ZF=1  -> JE 跳转
    ;    注意: FCOMI 不修改FPU栈 (不弹出)
    ; -------------------------------------------------------
    fld QWORD PTR [val_b]          ; ST0 = 2.72
    fld QWORD PTR [val_a]          ; ST0 = 3.14, ST1 = 2.72
    fcomi st(0), st(1)             ; 比较 ST0(3.14) 和 ST1(2.72), 设置EFLAGS

    ja mainfcomi_greater          ; ST0 > ST1
    jb mainfcomi_less             ; ST0 < ST1
    ; fall through: ST0 == ST1

mainfcomi_equal:
    fstp QWORD PTR [result]        ; 弹出ST0 清空栈
    fstp QWORD PTR [result]        ; 弹出ST1 清空栈
    lea rcx, fmt_fcomi_eq
    call printf
    jmp maindo_fcom

mainfcomi_greater:
    fstp QWORD PTR [result]        ; 弹出ST0
    fstp QWORD PTR [result]        ; 弹出ST1
    lea rcx, fmt_fcomi_gt
    call printf
    jmp maindo_fcom

mainfcomi_less:
    fstp QWORD PTR [result]        ; 弹出ST0
    fstp QWORD PTR [result]        ; 弹出ST1
    lea rcx, fmt_fcomi_lt
    call printf
    jmp maindo_fcom

    ; -------------------------------------------------------
    ; 2. FCOM - 传统比较方式 (通过FPU状态字)
    ;    fcom st(1) 比较 ST0 和 ST1, 结果在FPU状态字的C0/C2/C3位
    ;    需要用 fnstsw ax + sahf 将状态字转移到EFLAGS:
    ;      fnstsw ax  -> AX = FPU状态字
    ;      sahf       -> 将AH加载到EFLAGS (C0->CF, C2->PF, C3->ZF)
    ;    然后可以用 JA/JB/JE 跳转
    ; -------------------------------------------------------
maindo_fcom:
    fld QWORD PTR [val_b]          ; ST0 = 2.72
    fld QWORD PTR [val_a]          ; ST0 = 3.14, ST1 = 2.72
    fcom st(1)                   ; 比较 ST0(3.14) 和 ST1(2.72)

    ; 将FPU状态字转移到EFLAGS
    fnstsw ax                  ; AX = FPU状态字
    sahf                       ; AH -> EFLAGS (C0->CF, C2->PF, C3->ZF)

    ja mainfcom_greater           ; ST0 > ST1
    jb mainfcom_less              ; ST0 < ST1
    ; fall through: ST0 == ST1

mainfcom_equal:
    fstp QWORD PTR [result]        ; 清空栈
    fstp QWORD PTR [result]
    lea rcx, fmt_fcom_eq
    call printf
    jmp maindone

mainfcom_greater:
    fstp QWORD PTR [result]        ; 清空栈
    fstp QWORD PTR [result]
    lea rcx, fmt_fcom_gt
    call printf
    jmp maindone

mainfcom_less:
    fstp QWORD PTR [result]        ; 清空栈
    fstp QWORD PTR [result]
    lea rcx, fmt_fcom_lt
    call printf

maindone:
    lea rcx, fmt_done
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
main ENDP
END
