; ============================================================
; fpu_load_store.asm - FLD/FST/FSTP 加载与存储
; ============================================================
; 演示:
;   - fld qword [val]   从内存加载double到ST0
;   - fld dword [fval]  加载float到ST0 (自动提升为double)
;   - fst qword [result] 存储ST0到内存(保留栈)
;   - fstp qword [result] 存储并弹出
;   - fild dword [ival]  加载整数并转浮点
;
; printf %f注意 (Windows x64 varargs):
;   浮点值需同时放入XMM1和RDX寄存器
;   格式串在RCX
; ============================================================

default rel

section .data
    align 8
    val_double  dq 3.141592653589793   ; double (64位)
    align 4
    val_float   dd 2.718281828          ; float  (32位)
    align 4
    val_int     dd 42                   ; 整数 (32位)

    align 8
    result      dq 0.0                  ; FPU结果存储 (double)

    ; 格式字符串
    fmt_fld_d   db "FLD qword  (double 3.14159...): %f", 10, 0
    fmt_fld_f   db "FLD dword  (float  2.71828...): %f", 10, 0
    fmt_fild    db "FILD dword (int    42):         %f", 10, 0
    fmt_fst     db "FST  (store without pop):       %f", 10, 0
    fmt_fstp    db "FSTP (store and pop):           %f", 10, 0
    fmt_done    db "FPU load/store demo completed.", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    finit                      ; 初始化FPU (设置默认控制字)

    ; -------------------------------------------------------
    ; 1. FLD qword - 加载double到ST0
    ;    fld自动将内存中的64位double加载到FPU栈顶ST0
    ; -------------------------------------------------------
    fld qword [val_double]     ; ST0 = 3.141592653589793
    fstp qword [result]        ; 存储到result并弹出 (清空栈)

    ; printf("%f", result) - Windows x64 varargs
    lea rcx, [fmt_fld_d]
    mov rdx, [result]          ; double位模式到RDX
    movsd xmm1, [result]       ; double到XMM1
    call printf

    ; -------------------------------------------------------
    ; 2. FLD dword - 加载float到ST0 (自动提升为80位扩展精度)
    ; -------------------------------------------------------
    fld dword [val_float]      ; ST0 = 2.718281828 (提升为扩展精度)
    fstp qword [result]        ; 存储为double并弹出

    lea rcx, [fmt_fld_f]
    mov rdx, [result]
    movsd xmm1, [result]
    call printf

    ; -------------------------------------------------------
    ; 3. FILD dword - 加载整数并转换为浮点
    ;    fild将内存中的整数读取后转为浮点数放入ST0
    ; -------------------------------------------------------
    fild dword [val_int]       ; ST0 = 42.0
    fstp qword [result]        ; 存储为double并弹出

    lea rcx, [fmt_fild]
    mov rdx, [result]
    movsd xmm1, [result]
    call printf

    ; -------------------------------------------------------
    ; 4. FST vs FSTP 演示
    ;    FST:  存储ST0到内存，但不弹出 (ST0仍在栈上)
    ;    FSTP: 存储ST0到内存并弹出 (ST0从栈上移除)
    ; -------------------------------------------------------
    fld qword [val_double]     ; ST0 = 3.14159...
    fst qword [result]         ; 存储到result, ST0仍在栈上
    ; 此时FPU栈上有1个值 (ST0 = 3.14159...)

    lea rcx, [fmt_fst]
    mov rdx, [result]
    movsd xmm1, [result]
    call printf

    ; 现在用FSTP弹出剩余的值
    fstp qword [result]        ; 存储并弹出, 栈现在为空

    lea rcx, [fmt_fstp]
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
