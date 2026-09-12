; Minimal simpson test - does it crash before printf?
default rel

N   equ 1024

section .data
    align 4
    f_one      dd 1.0
    f_four     dd 4.0
    f_two_f    dd 2.0
    f_three    dd 3.0
    f_eight    dd 8.0
    f_N_float  dd 1024.0
    f_h        dd 0.0
    f_h_over_3 dd 0.0
    d_pi       dq 3.14159265358979
    abs_mask   dq 0x7FFFFFFFFFFFFFFF

    align 8
    temp_d     dq 0.0
    temp_d2    dq 0.0

    align 32
    idx_vec    dd 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0
    weight_vec dd 4.0, 2.0, 4.0, 2.0, 4.0, 2.0, 4.0, 2.0

    fmt_header db "=== AVX2 Simpson ===", 10, 0

section .bss
    alignb 32
    f_array    resd N+1
    alignb 8
    scalar_res resd 1
    avx2_res   resd 1
    cyc_start  resq 1
    cyc_scalar resq 1
    cyc_avx2   resq 1

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; Test 1: Just exit immediately
    ; mov ecx, 42
    ; call ExitProcess

    ; Test 2: Try printf
    lea rcx, [fmt_header]
    call printf

    ; Test 3: AVX2 operations
    vmovups ymm0, [idx_vec]
    vbroadcastss ymm1, [f_h]
    vmulps ymm2, ymm0, ymm1
    vmovups [f_array], ymm2
    vzeroupper

    xor ecx, ecx
    call ExitProcess
