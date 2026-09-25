; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    ; 16字节对齐的打包float数据
    align 16
    packed1  DWORD 1.0, 2.0, 3.0, 4.0
    align 16
    packed2  DWORD 5.0, 6.0, 7.0, 8.0

    ; 存储缓冲区
    align 16
    xmm_buf     DWORD 0.0, 0.0, 0.0, 0.0
    align 8
    temp_double REAL8 0.0

    ; 格式字符串
    fmt_addps BYTE "ADDPS: [1,2,3,4] + [5,6,7,8] = [6, 8, 10, 12]", 10, 0
    fmt_subps BYTE "SUBPS: [1,2,3,4] - [5,6,7,8] = [-4, -4, -4, -4]", 10, 0
    fmt_mulps BYTE "MULPS: [1,2,3,4] * [5,6,7,8] = [5, 12, 21, 32]", 10, 0
    fmt_divps BYTE "DIVPS: [1,2,3,4] / [5,6,7,8] = [0.2, 0.333, 0.428, 0.5]", 10, 0
    fmt_elem  BYTE "  [%d] = %f", 10, 0
    fmt_done  BYTE "SSE packed arithmetic demo completed.", 10, 0


.code

; ============================================================
; 子程序: print_4floats
; 打印xmm_buf中的4个float元素
; 调用前确保xmm_buf已填充数据
; ============================================================
print_4floats:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 元素0: offset=0
    movss xmm0, DWORD PTR [xmm_buf]
    cvtss2sd xmm2, xmm0           ; float -> double (第2个浮点参数位)
    movsd QWORD PTR [temp_double], xmm2
    lea rcx, fmt_elem
    mov edx, 0
    mov r8, QWORD PTR [temp_double]
    call printf

    ; 元素1: offset=4
    movss xmm0, DWORD PTR [xmm_buf+4]
    cvtss2sd xmm2, xmm0
    movsd QWORD PTR [temp_double], xmm2
    lea rcx, fmt_elem
    mov edx, 1
    mov r8, QWORD PTR [temp_double]
    call printf

    ; 元素2: offset=8
    movss xmm0, DWORD PTR [xmm_buf+8]
    cvtss2sd xmm2, xmm0
    movsd QWORD PTR [temp_double], xmm2
    lea rcx, fmt_elem
    mov edx, 2
    mov r8, QWORD PTR [temp_double]
    call printf

    ; 元素3: offset=12
    movss xmm0, DWORD PTR [xmm_buf+12]
    cvtss2sd xmm2, xmm0
    movsd QWORD PTR [temp_double], xmm2
    lea rcx, fmt_elem
    mov edx, 3
    mov r8, QWORD PTR [temp_double]
    call printf

    leave
    ret

; ============================================================
; 主程序
; ============================================================
main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; -------------------------------------------------------
    ; 1. ADDPS - 4个float并行相加
    ;    xmm0[0..3] = xmm0[0..3] + xmm1[0..3]
    ; -------------------------------------------------------
    movaps xmm0, XMMWORD PTR [packed1]        ; xmm0 = [1,2,3,4]
    movaps xmm1, XMMWORD PTR [packed2]        ; xmm1 = [5,6,7,8]
    addps xmm0, xmm1             ; xmm0 = [6,8,10,12]
    movaps XMMWORD PTR [xmm_buf], xmm0       ; 存储结果

    lea rcx, fmt_addps
    call printf
    call print_4floats

    ; -------------------------------------------------------
    ; 2. SUBPS - 4个float并行相减
    ;    xmm0[0..3] = xmm0[0..3] - xmm1[0..3]
    ; -------------------------------------------------------
    movaps xmm0, XMMWORD PTR [packed1]        ; 重新加载 [1,2,3,4]
    movaps xmm1, XMMWORD PTR [packed2]        ; [5,6,7,8]
    subps xmm0, xmm1             ; xmm0 = [-4,-4,-4,-4]
    movaps XMMWORD PTR [xmm_buf], xmm0

    lea rcx, fmt_subps
    call printf
    call print_4floats

    ; -------------------------------------------------------
    ; 3. MULPS - 4个float并行相乘
    ;    xmm0[0..3] = xmm0[0..3] * xmm1[0..3]
    ; -------------------------------------------------------
    movaps xmm0, XMMWORD PTR [packed1]
    movaps xmm1, XMMWORD PTR [packed2]
    mulps xmm0, xmm1             ; xmm0 = [5,12,21,32]
    movaps XMMWORD PTR [xmm_buf], xmm0

    lea rcx, fmt_mulps
    call printf
    call print_4floats

    ; -------------------------------------------------------
    ; 4. DIVPS - 4个float并行相除
    ;    xmm0[0..3] = xmm0[0..3] / xmm1[0..3]
    ; -------------------------------------------------------
    movaps xmm0, XMMWORD PTR [packed1]
    movaps xmm1, XMMWORD PTR [packed2]
    divps xmm0, xmm1             ; xmm0 = [0.2, 0.333, 0.428, 0.5]
    movaps XMMWORD PTR [xmm_buf], xmm0

    lea rcx, fmt_divps
    call printf
    call print_4floats

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
