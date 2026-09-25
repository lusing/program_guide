; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 4
    int32_val   DWORD 42              ; 32位整数
    float_val   DWORD 3.7             ; 单精度float (用于舍入/截断演示)
    align 8
    int64_val   QWORD 1000000         ; 64位整数
    double_val  REAL8 2.718281828459045  ; 双精度double
    align 4
    fpi_val     DWORD 3.14            ; 单精度float (用于float->double)
    align 8
    temp_d      REAL8 0.0             ; 临时double存储
    temp_i      DWORD 0               ; 临时整数存储

    ; 格式字符串
    fmt_i2ss    BYTE "cvtsi2ss:  int32 42        -> float  %f", 10, 0
    fmt_i2sd    BYTE "cvtsi2sd:  int64 1000000   -> double %f", 10, 0
    fmt_ss2si   BYTE "cvtss2si:  float 3.7       -> int    %d (rounded)", 10, 0
    fmt_ttss2si BYTE "cvttss2si: float 3.7       -> int    %d (truncated)", 10, 0
    fmt_ss2sd   BYTE "cvtss2sd:  float 3.14      -> double %f", 10, 0
    fmt_sd2ss   BYTE "cvtsd2ss:  double 2.71828.. -> float  %f (precision loss)", 10, 0
    fmt_done    BYTE "SSE type conversion demo completed.", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; -------------------------------------------------------
    ; 1. cvtsi2ss - 32位整数转单精度float
    ;    cvtsi2ss xmm0, eax  -> xmm0[31:0] = (float)eax
    ; -------------------------------------------------------
    mov eax, DWORD PTR [int32_val]        ; eax = 42
    cvtsi2ss xmm0, eax          ; xmm0[31:0] = 42.0f
    ; 转为double用于printf
    cvtss2sd xmm1, xmm0         ; xmm1 = (double)42.0
    movsd QWORD PTR [temp_d], xmm1
    lea rcx, fmt_i2ss
    mov rdx, QWORD PTR [temp_d]
    movsd xmm1, QWORD PTR [temp_d]
    call printf

    ; -------------------------------------------------------
    ; 2. cvtsi2sd - 64位整数转双精度double
    ;    cvtsi2sd xmm0, rax  -> xmm0[63:0] = (double)rax
    ; -------------------------------------------------------
    mov rax, QWORD PTR [int64_val]        ; rax = 1000000
    cvtsi2sd xmm0, rax          ; xmm0[63:0] = 1000000.0
    movsd QWORD PTR [temp_d], xmm0        ; 直接是double, 存储即可
    lea rcx, fmt_i2sd
    mov rdx, QWORD PTR [temp_d]
    movsd xmm1, QWORD PTR [temp_d]
    call printf

    ; -------------------------------------------------------
    ; 3. cvtss2si - 单精度转整数 (四舍五入)
    ;    按MXCSR中的舍入模式 (默认: 就近舍入 round-to-nearest-even)
    ;    cvtss2si eax, xmm0  -> eax = (int)xmm0[31:0]
    ;    3.7 四舍五入 = 4
    ; -------------------------------------------------------
    movss xmm0, DWORD PTR [float_val]     ; xmm0[31:0] = 3.7f
    cvtss2si eax, xmm0          ; eax = 4 (就近舍入)
    mov DWORD PTR [temp_i], eax
    lea rcx, fmt_ss2si
    mov edx, DWORD PTR [temp_i]
    call printf

    ; -------------------------------------------------------
    ; 4. cvttss2si - 单精度转整数 (截断)
    ;    始终向零截断, 不受MXCSR舍入模式影响
    ;    cvttss2si eax, xmm0  -> eax = (int)xmm0[31:0]
    ;    3.7 截断 = 3
    ; -------------------------------------------------------
    movss xmm0, DWORD PTR [float_val]     ; xmm0[31:0] = 3.7f
    cvttss2si eax, xmm0         ; eax = 3 (截断)
    mov DWORD PTR [temp_i], eax
    lea rcx, fmt_ttss2si
    mov edx, DWORD PTR [temp_i]
    call printf

    ; -------------------------------------------------------
    ; 5. cvtss2sd - 单精度float转双精度double
    ;    cvtss2sd xmm0, xmm1  -> xmm0[63:0] = (double)xmm1[31:0]
    ;    float精度(约7位有效数字)扩展为double精度(约15位)
    ; -------------------------------------------------------
    movss xmm1, DWORD PTR [fpi_val]       ; xmm1[31:0] = 3.14f
    cvtss2sd xmm0, xmm1         ; xmm0[63:0] = (double)3.14
    movsd QWORD PTR [temp_d], xmm0
    lea rcx, fmt_ss2sd
    mov rdx, QWORD PTR [temp_d]
    movsd xmm1, QWORD PTR [temp_d]
    call printf

    ; -------------------------------------------------------
    ; 6. cvtsd2ss - 双精度double转单精度float
    ;    cvtsd2ss xmm0, xmm1  -> xmm0[31:0] = (float)xmm1[63:0]
    ;    double精度降为float精度 (可能丢失精度)
    ;    打印时需再次cvtss2sd转回double
    ; -------------------------------------------------------
    movsd xmm1, QWORD PTR [double_val]    ; xmm1[63:0] = 2.718281828459045
    cvtsd2ss xmm0, xmm1         ; xmm0[31:0] = (float)2.7182818...
    ; float结果转回double用于printf
    cvtss2sd xmm1, xmm0         ; xmm1 = (double)(float)2.71828...
    movsd QWORD PTR [temp_d], xmm1
    lea rcx, fmt_sd2ss
    mov rdx, QWORD PTR [temp_d]
    movsd xmm1, QWORD PTR [temp_d]
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
