; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
N   equ 1024
extern printf : PROC
extern ExitProcess : PROC

avxdata SEGMENT ALIGN(32) 'DATA'
    align 4
    f_one      DWORD 1.0
    f_four     DWORD 4.0
    f_two_f    DWORD 2.0
    f_three    DWORD 3.0
    f_eight    DWORD 8.0
    f_N_float  DWORD 1024.0
    f_h        DWORD 0.0
    f_h_over_3 DWORD 0.0
    d_pi       REAL8 3.14159265358979
    abs_mask   QWORD 7FFFFFFFFFFFFFFFh

    align 8
    temp_d     REAL8 0.0
    temp_d2    REAL8 0.0

    ; (align satisfied by SEGMENT ALIGN)
    idx_vec    DWORD 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0
    weight_vec DWORD 4.0, 2.0, 4.0, 2.0, 4.0, 2.0, 4.0, 2.0

    fmt_header BYTE "=== AVX2 Simpson ===", 10, 0

avxdata ENDS

avxbss SEGMENT ALIGN(32) 'DATA'
    ; (align satisfied by SEGMENT ALIGN)
    f_array    DWORD N+1 DUP(?)
    ALIGN 8
    scalar_res DWORD 1 DUP(?)
    avx2_res   DWORD 1 DUP(?)
    cyc_start  QWORD 1 DUP(?)
    cyc_scalar QWORD 1 DUP(?)
    cyc_avx2   QWORD 1 DUP(?)

avxbss ENDS

.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; Test 1: Just exit immediately
    ; mov ecx, 42
    ; call ExitProcess

    ; Test 2: Try printf
    lea rcx, fmt_header
    call printf

    ; Test 3: AVX2 operations
    vmovups ymm0, YMMWORD PTR [idx_vec]
    vbroadcastss ymm1, DWORD PTR [f_h]
    vmulps ymm2, ymm0, ymm1
    vmovups YMMWORD PTR [f_array], ymm2
    vzeroupper

    xor ecx, ecx
    call ExitProcess
main ENDP
END
