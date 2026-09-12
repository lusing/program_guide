; ============================================================
; fpu_compare.asm - FCOM/FCOMI 浮点比较
; ============================================================
; 演示:
;   - fcomi st0, st1  直接设置EFLAGS (现代方式，更高效)
;   - fcom st1        设置FPU状态字 (传统方式，需fnstsw+sahf转换)
;   - 比较后可用 JA/JB/JE 跳转
;
; 比较: 3.14 vs 2.72  (3.14 > 2.72)
; ============================================================

default rel

section .data
    align 8
    val_a   dq 3.14            ; 比较值1 (较大)
    val_b   dq 2.72            ; 比较值2 (较小)
    result  dq 0.0             ; 用于清空FPU栈

    fmt_fcomi_gt db "FCOMI: 3.14 > 2.72 is TRUE", 10, 0
    fmt_fcomi_eq db "FCOMI: 3.14 == 2.72 is TRUE", 10, 0
    fmt_fcomi_lt db "FCOMI: 3.14 < 2.72 is TRUE", 10, 0
    fmt_fcom_gt  db "FCOM:  3.14 > 2.72 is TRUE (via status word)", 10, 0
    fmt_fcom_eq  db "FCOM:  3.14 == 2.72 is TRUE (via status word)", 10, 0
    fmt_fcom_lt  db "FCOM:  3.14 < 2.72 is TRUE (via status word)", 10, 0
    fmt_done     db "FPU compare demo completed.", 10, 0

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
    ; 1. FCOMI - 直接设置EFLAGS的现代比较方式
    ;    fcomi st0, st1 比较 ST0 和 ST1
    ;    直接设置 CF 和 ZF (不需要状态字转换):
    ;      ST0 > ST1: CF=0, ZF=0  -> JA 跳转
    ;      ST0 < ST1: CF=1, ZF=0  -> JB 跳转
    ;      ST0 = ST1: CF=0, ZF=1  -> JE 跳转
    ;    注意: FCOMI 不修改FPU栈 (不弹出)
    ; -------------------------------------------------------
    fld qword [val_b]          ; ST0 = 2.72
    fld qword [val_a]          ; ST0 = 3.14, ST1 = 2.72
    fcomi st0, st1             ; 比较 ST0(3.14) 和 ST1(2.72), 设置EFLAGS

    ja .fcomi_greater          ; ST0 > ST1
    jb .fcomi_less             ; ST0 < ST1
    ; fall through: ST0 == ST1

.fcomi_equal:
    fstp qword [result]        ; 弹出ST0 清空栈
    fstp qword [result]        ; 弹出ST1 清空栈
    lea rcx, [fmt_fcomi_eq]
    call printf
    jmp .do_fcom

.fcomi_greater:
    fstp qword [result]        ; 弹出ST0
    fstp qword [result]        ; 弹出ST1
    lea rcx, [fmt_fcomi_gt]
    call printf
    jmp .do_fcom

.fcomi_less:
    fstp qword [result]        ; 弹出ST0
    fstp qword [result]        ; 弹出ST1
    lea rcx, [fmt_fcomi_lt]
    call printf
    jmp .do_fcom

    ; -------------------------------------------------------
    ; 2. FCOM - 传统比较方式 (通过FPU状态字)
    ;    fcom st1 比较 ST0 和 ST1, 结果在FPU状态字的C0/C2/C3位
    ;    需要用 fnstsw ax + sahf 将状态字转移到EFLAGS:
    ;      fnstsw ax  -> AX = FPU状态字
    ;      sahf       -> 将AH加载到EFLAGS (C0->CF, C2->PF, C3->ZF)
    ;    然后可以用 JA/JB/JE 跳转
    ; -------------------------------------------------------
.do_fcom:
    fld qword [val_b]          ; ST0 = 2.72
    fld qword [val_a]          ; ST0 = 3.14, ST1 = 2.72
    fcom st1                   ; 比较 ST0(3.14) 和 ST1(2.72)

    ; 将FPU状态字转移到EFLAGS
    fnstsw ax                  ; AX = FPU状态字
    sahf                       ; AH -> EFLAGS (C0->CF, C2->PF, C3->ZF)

    ja .fcom_greater           ; ST0 > ST1
    jb .fcom_less              ; ST0 < ST1
    ; fall through: ST0 == ST1

.fcom_equal:
    fstp qword [result]        ; 清空栈
    fstp qword [result]
    lea rcx, [fmt_fcom_eq]
    call printf
    jmp .done

.fcom_greater:
    fstp qword [result]        ; 清空栈
    fstp qword [result]
    lea rcx, [fmt_fcom_gt]
    call printf
    jmp .done

.fcom_less:
    fstp qword [result]        ; 清空栈
    fstp qword [result]
    lea rcx, [fmt_fcom_lt]
    call printf

.done:
    lea rcx, [fmt_done]
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
