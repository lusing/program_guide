; ============================================================
; 文件: 11_calculus_mkl/simd_derivative.asm                [Linux 版]
; 指令: MOVUPS / SUBPS / MULPS / ANDPS / MAXPS / SHUFPS
; 描述: SIMD 数值微分 —— 中心差分一次算 4 个点
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/11_calculus_mkl/simd_derivative.asm -o build/simd_derivative.o
; 链接: gcc -no-pie build/simd_derivative.o -o build/simd_derivative
; 对照: examples/11_calculus_mkl/avx2_derivative.asm
;
; ★ 移植说明：原版用 AVX2（ymm，一次 8 个 float）。
;   本机是 Ivy Bridge（i7-3520M），**不支持 AVX2**，
;   所以这里改用 SSE 的 xmm（一次 4 个 float）。
;   算法、数据布局、结论完全一致，只是向量宽度从 256 位降到 128 位。
;   把 movups 换成 vmovups、把 xmm 换成 ymm 就是 AVX2 版本 ——
;   这也正是 AVX2 相对 SSE 的全部差别：更宽的通道，一样的代码骨架。
;
; ------------------------------------------------------------
; 问题：f(x) = sin(x)，求 f'(x)，解析解是 cos(x)。
; 中心差分： f'(x) ≈ ( f(x+h) - f(x-h) ) / (2h)
; 在 [0, 2π] 上取 N=1024 个采样点，h = 2π/N。
;
; 向量化的关键技巧是「错位加载」：
;   要同时算 f[i..i+3] 四组差分，不需要任何 shuffle，
;   只要按两个不同偏移各读一次 128 位：
;     f_forward  = [f[i+1], f[i+2], f[i+3], f[i+4]]   从偏移 i*4+4 读
;     f_backward = [f[i-1], f[i],   f[i+1], f[i+2]]   从偏移 i*4-4 读
;   相减再乘 1/(2h)，就得到 [der[i], der[i+1], der[i+2], der[i+3]]。
;   所以这里**必须用 movups**（未对齐版本）——
;   偏移 4 字节的地址天然不是 16 的倍数，用 movaps 会直接 #GP 崩掉。
;
; 中心差分的截断误差是 O(h²)，量级 ≈ h²/6 · |f'''| ≤ h²/6。
; 本例 h ≈ 0.006136，所以预期最大误差约 6.3e-6 —— 程序会打出来验证。
; ============================================================
default rel

%define N 1024

section .data
    align 8
    d_h      dq 0.006135923151542565    ; 2π / 1024
    d_six    dq 6.0
    tmp_x    dq 0.0
    tmp_s    dq 0.0

    align 16
    f_inv2h  dd 81.4873309, 81.4873309, 81.4873309, 81.4873309   ; 1/(2h)
    abs_mask dd 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF

    fmt_hdr   db "=== SIMD 数值微分：f(x)=sin(x)，中心差分求 f'(x) ===", 10, 0
    fmt_parm  db "N = %d 个采样点，h = 2π/N = %.9f", 10, 0
    fmt_smpl  db "  x = %.6f :  差分值 %f   解析 cos(x) = %f", 10, 0
    fmt_max   db "整段最大绝对误差 = %.9f", 10, 0
    fmt_bnd   db "理论界 h²/6 = %.9f（中心差分的截断误差量级）", 10, 0
    fmt_why   db "实测略高于理论界：sin 表存成 float 后的舍入被 1/(2h)≈81.5 放大了一次。", 10, 0
    fmt_note  db "本机无 AVX2，故用 SSE 的 4 路；换成 ymm 就是 AVX2 的 8 路。", 10, 0
    fmt_done  db "SIMD derivative demo completed.", 10, 0

section .bss
    alignb 16
    f_arr   resd N+1                    ; sin(x_i)
    c_arr   resd N+1                    ; 参考用的 cos(x_i)
    d_arr   resd N+1                    ; 差分求出的导数

section .text
    global main
    extern printf

; ------------------------------------------------------------
; print_sample —— rsi = 下标 i，打印「x、差分值、解析 cos(x)」一行
; 依赖 main 里已就绪的 r12 = d_arr、r13 = c_arr（都是被调用者保存寄存器）
; ------------------------------------------------------------
print_sample:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    cvtsi2sd xmm0, rsi
    mulsd xmm0, [d_h]                   ; 第 1 个浮点参数：x = i·h
    movss xmm1, [r12 + rsi*4]
    cvtss2sd xmm1, xmm1                 ; 第 2 个：SIMD 差分算出的导数
    movss xmm2, [r13 + rsi*4]
    cvtss2sd xmm2, xmm2                 ; 第 3 个：解析解 cos
    lea rdi, [fmt_smpl]
    mov eax, 3                          ; 用了 3 个向量寄存器
    call printf
    leave
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8],  rbx                   ; f_arr
    mov [rbp-16], r12                   ; d_arr
    mov [rbp-24], r13                   ; c_arr

    ; --------------------------------------------------------
    ; 1. 造数据表：f[i] = sin(i·h)，同时存一份 cos(i·h) 当参考
    ;    造表这种一次性开销用最简单的标量办法（x87 的 fsin / fcos）
    ; --------------------------------------------------------
    lea rbx, [f_arr]
    lea r13, [c_arr]
    xor ecx, ecx
.fill:
    cvtsi2sd xmm0, ecx
    mulsd xmm0, [d_h]
    movsd [tmp_x], xmm0

    fld qword [tmp_x]
    fsin
    fstp qword [tmp_s]
    movsd xmm0, [tmp_s]
    cvtsd2ss xmm0, xmm0
    movss [rbx + rcx*4], xmm0           ; f[i]

    fld qword [tmp_x]
    fcos
    fstp qword [tmp_s]
    movsd xmm0, [tmp_s]
    cvtsd2ss xmm0, xmm0
    movss [r13 + rcx*4], xmm0           ; 参考 cos[i]

    inc ecx
    cmp ecx, N
    jbe .fill                           ; 0..N，共 N+1 个点

    ; --------------------------------------------------------
    ; 2. 向量化的中心差分
    ;    以「字节偏移」rcx 为游标，i = 1 对应 rcx = 0：
    ;      f_forward  在 rbx + rcx + 8
    ;      f_backward 在 rbx + rcx
    ;    每次前进 16 字节（4 个 float）。
    ; --------------------------------------------------------
    lea r12, [d_arr]
    movaps xmm4, [f_inv2h]              ; 常数 1/(2h) 常驻寄存器
    xor ecx, ecx
.vloop:
    movups xmm0, [rbx + rcx + 8]        ; [f[i+1], f[i+2], f[i+3], f[i+4]]
    movups xmm1, [rbx + rcx]            ; [f[i-1], f[i],   f[i+1], f[i+2]]
    subps  xmm0, xmm1
    mulps  xmm0, xmm4                   ; ÷ 2h
    movups [r12 + rcx + 4], xmm0        ; 存 der[i..i+3]
    add ecx, 16
    cmp ecx, (N-8)*4                    ; 覆盖 i = 1..1020（255 组 × 4）
    jbe .vloop

    ; --------------------------------------------------------
    ; 3. 同样 4 路并行求最大绝对误差
    ;    andps 清符号位当绝对值，maxps 沿途累积
    ; --------------------------------------------------------
    movaps xmm5, [abs_mask]
    pxor xmm3, xmm3
    xor ecx, ecx
.eloop:
    movups xmm0, [r12 + rcx + 4]        ; der[i..i+3]
    movups xmm1, [r13 + rcx + 4]        ; cos[i..i+3]
    subps  xmm0, xmm1
    andps  xmm0, xmm5
    maxps  xmm3, xmm0
    add ecx, 16
    cmp ecx, (N-8)*4
    jbe .eloop

    ; 水平归约：把 4 条通道的最大值压成 1 个
    movaps xmm1, xmm3
    shufps xmm1, xmm1, 0x4E             ; [2,3,0,1]
    maxps  xmm3, xmm1
    movaps xmm1, xmm3
    shufps xmm1, xmm1, 0xB1             ; [1,0,3,2]
    maxps  xmm3, xmm1
    movss  xmm7, xmm3                   ; xmm7 = 最大误差，留到最后打印

    ; --------------------------------------------------------
    ; 4. 输出
    ;    注意 xmm7 要在两次 print_sample 之后才用 —— print_sample 里的
    ;    printf 会踩掉所有 xmm，所以这里先把它落到栈上最稳。
    ; --------------------------------------------------------
    movss [rbp-32], xmm7

    lea rdi, [fmt_hdr]
    xor eax, eax
    call printf

    lea rdi, [fmt_parm]
    mov esi, N
    movsd xmm0, [d_h]
    mov eax, 1
    call printf

    mov rsi, 256                        ; x = 256h ≈ π/2
    call print_sample
    mov rsi, 512                        ; x = 512h ≈ π
    call print_sample
    mov rsi, 768                        ; x = 768h ≈ 3π/2
    call print_sample

    movss xmm0, [rbp-32]
    cvtss2sd xmm0, xmm0
    lea rdi, [fmt_max]
    mov eax, 1
    call printf

    movsd xmm0, [d_h]
    mulsd xmm0, xmm0                    ; h²
    divsd xmm0, [d_six]                 ; h²/6
    lea rdi, [fmt_bnd]
    mov eax, 1
    call printf

    lea rdi, [fmt_why]
    xor eax, eax
    call printf

    lea rdi, [fmt_note]
    xor eax, eax
    call printf

    lea rdi, [fmt_done]
    xor eax, eax
    call printf

    mov rbx, [rbp-8]
    mov r12, [rbp-16]
    mov r13, [rbp-24]
    xor eax, eax
    leave
    ret
