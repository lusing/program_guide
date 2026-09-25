; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

avxdata SEGMENT ALIGN(32) 'DATA'
    ; a = 1 + 2^-23（float 里比 1.0 大的最小数）
    ; (align satisfied by SEGMENT ALIGN)
    f_a   DWORD 8 DUP(3F800001h)
    ; b = 1 - 2^-23（位型 3F7FFFFEh，不是 3F7FFFFFh）
    ; 注意：1.0 以下 ulp 只有 2^-24，所以「比 1.0 小的最大数」
    ; 其实是 3F7FFFFFh = 1-2^-24；要凑出 1-2^-23 得再退一格。
    ; (align satisfied by SEGMENT ALIGN)
    f_b   DWORD 8 DUP(3F7FFFFEh)
    ; c = -1.0
    ; (align satisfied by SEGMENT ALIGN)
    f_c   DWORD 8 DUP(0BF800000h)

    ; 一组普通常数，用来证明 FMA 不是「另一种算法」
    ; (align satisfied by SEGMENT ALIGN)
    n_a   DWORD 8 DUP(2.0)
    ; (align satisfied by SEGMENT ALIGN)
    n_b   DWORD 8 DUP(3.0)
    ; (align satisfied by SEGMENT ALIGN)
    n_c   DWORD 8 DUP(4.0)

    align 16
    sse_out  DWORD 0.0, 0.0, 0.0, 0.0
    ; (align satisfied by SEGMENT ALIGN)
    fma_out  DWORD 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
    align 8
    temp_double REAL8 0.0

    str_yes  BYTE "YES", 0
    str_no   BYTE "NO", 0

    hdr      BYTE "FMA：一条顶两条，而且只舍入一次", 10, 0
    fmt_det  BYTE "探测：AVX2 = %s，FMA = %s", 10, 0
    t_desc   BYTE "1. 一个能看出差别的小例子", 10, 0
    t_desc2  BYTE "   a = 1 + 2^-23（float 里比 1.0 大的最小数，位型 0x3F800001）", 10, 0
    t_desc3  BYTE "   b = 1 - 2^-23（位型 0x3F7FFFFE）", 10, 0
    t_desc3b BYTE "   （坑：1.0 以下的 ulp 只有 2^-24，所以 0x3F7FFFFF 是 1-2^-24，不是 1-2^-23）", 10, 0
    t_desc4  BYTE "   c = -1.0", 10, 0
    t_desc5  BYTE "   精确值 a*b + c = -2^-46 = -1.4210854715202004e-14", 10, 0
    t_sse    BYTE "2. SSE 路径：mulps + addps，中间乘积被舍入两次", 10, 0
    t_sse2   BYTE "   a*b 的真值 1-2^-46 塞不进 float（只有 24 位有效位），先被舍入成 1.0", 10, 0
    t_sse3   BYTE "   然后 1.0 + (-1.0) = 0 —— 有效数字全被抵消了", 10, 0
    t_fma    BYTE "3. FMA 路径：vfmadd231ps，只有最后一次舍入", 10, 0
    t_norm   BYTE "4. 换一组普通常数（a=2, b=3, c=4），两条路径结果一样", 10, 0
    t_norm2  BYTE "   —— FMA 不是另一种算法，只是少了中间那一次舍入", 10, 0
    lb_sse   BYTE "mulps+addps 结果", 0
    lb_fma   BYTE "vfmadd231ps 结果", 0
    t_skip   BYTE "本机不支持 FMA（CPUID 页 1 ECX[12] / XCR0 已确认），无法演示。", 10, 0
    fmt_hi   BYTE "   %s = %.17g", 10, 0
    fmt_done BYTE "FMA demo completed.", 10, 0

avxdata ENDS

.code

; ------------------------------------------------------------
; cpu_features —— CPUID + XGETBV 探测，返回 eax 位图
;   bit0 = AVX    页1 ECX[28]，且 ECX[27] OSXSAVE，且 XCR0[2:1] = 11
;   bit1 = AVX2   页7 EBX[5]
;   bit2 = FMA    页1 ECX[12]
;   bit3 = 操作系统已放开 YMM 状态保存（XCR0[2:1]）
; ------------------------------------------------------------
cpu_features:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12

    xor  r12d, r12d

    mov  eax, 0
    cpuid
    mov  r9d, eax                    ; 最大页号
    cmp  r9d, 1
    jb   cpu_featuresdone

    mov  eax, 1
    xor  ecx, ecx
    cpuid
    mov  r8d, ecx

    bt   r8d, 12                     ; FMA（在页 1）
    jnc  cpu_featuresno_fma
    or   r12d, 4
cpu_featuresno_fma:
    bt   r8d, 28
    jnc  cpu_featuresdone
    bt   r8d, 27
    jnc  cpu_featuresdone

    xor  ecx, ecx
    xgetbv
    and  eax, 6
    cmp  eax, 6
    jne  cpu_featuresdone
    or   r12d, 9

    cmp  r9d, 7
    jb   cpu_featuresdone
    mov  eax, 7
    xor  ecx, ecx
    cpuid
    bt   ebx, 5
    jnc  cpu_featuresdone
    or   r12d, 2

cpu_featuresdone:
    mov  eax, r12d
    pop  r12
    pop  rbx
    leave
    ret

; ------------------------------------------------------------
; put_g17 —— 打印 "   标签 = 值（17 位有效数字）"
;   rcx = 以 0 结尾的标签串   xmm0 = double
; ------------------------------------------------------------
put_g17:
    push rbp
    mov  rbp, rsp
    sub  rsp, 32                     ; 影子空间
    mov  rdx, rcx                    ; 参数 1 = 标签
    movsd xmm1, xmm0                 ; 参数 2 是浮点 -> xmm1
    movsd QWORD PTR [temp_double], xmm1
    mov  r8, QWORD PTR [temp_double]           ; 浮点参数还要同时写整数槽
    lea rcx, fmt_hi
    call printf
    leave
    ret

; ------------------------------------------------------------
; sse_muladd —— 用 mulps + addps 算 out = a*b + c（128 位，4 通道）
;   rcx = a   rdx = b   r8 = c   r9 = out
; 纯 SSE，不调用别的函数。
; ------------------------------------------------------------
sse_muladd:
    push rbp
    mov  rbp, rsp
    movaps xmm0, XMMWORD PTR [rcx]               ; a
    movaps xmm1, XMMWORD PTR [rdx]               ; b
    mulps  xmm0, xmm1                ; t = a * b   ← 第一次舍入
    movaps xmm1, XMMWORD PTR [r8]                ; c
    addps  xmm0, xmm1                ; t = t + c   ← 第二次舍入
    movaps XMMWORD PTR [r9], xmm0
    leave
    ret

; ============================================================
; 主程序（/entry:main，所以退场用 ExitProcess，不能用 ret）
; ============================================================
main PROC
    push rbp
    mov  rbp, rsp
    sub  rsp, 32                     ; 影子空间

    call cpu_features
    mov  r12d, eax                   ; 特性位图

    lea rcx, hdr
    call printf

    ; 打印探测结果：AVX2（bit1）与 FMA（bit2）
    lea rdx, str_no
    mov  eax, r12d
    and  eax, 2
    cmp  eax, 2
    jne  mainno_ax2
    lea rdx, str_yes
mainno_ax2:
    lea r8, str_no
    mov  eax, r12d
    and  eax, 4
    cmp  eax, 4
    jne  mainno_f
    lea r8, str_yes
mainno_f:
    lea rcx, fmt_det
    call printf

    ; 本示例要 FMA（bit2）+ OS 放开 YMM（bit3）= 0b1100
    mov  eax, r12d
    and  eax, 12
    cmp  eax, 12
    je   mainfma_ok
    lea rcx, t_skip
    call printf
    jmp  mainfinish

mainfma_ok:
    lea rcx, t_desc
    call printf
    lea rcx, t_desc2
    call printf
    lea rcx, t_desc3
    call printf
    lea rcx, t_desc3b
    call printf
    lea rcx, t_desc4
    call printf
    lea rcx, t_desc5
    call printf

    ; --- 2. SSE 路径 ---
    lea rcx, t_sse
    call printf
    lea rcx, t_sse2
    call printf
    lea rcx, t_sse3
    call printf
    lea rcx, f_a
    lea rdx, f_b
    lea r8, f_c
    lea r9, sse_out
    call sse_muladd

    lea rcx, lb_sse
    movss xmm0, DWORD PTR [sse_out]
    cvtss2sd xmm0, xmm0
    call put_g17

    ; --- 3. FMA 路径 ---
    lea rcx, t_fma
    call printf
    vmovaps ymm0, YMMWORD PTR [f_c]
    vmovaps ymm1, YMMWORD PTR [f_a]
    vmovaps ymm2, YMMWORD PTR [f_b]
    vfmadd231ps ymm0, ymm1, ymm2     ; ymm0 = ymm1*ymm2 + ymm0
    vmovaps YMMWORD PTR [fma_out], ymm0
    vzeroupper

    lea rcx, lb_fma
    movss xmm0, DWORD PTR [fma_out]
    cvtss2sd xmm0, xmm0
    call put_g17

    ; --- 4. 普通常数：两条路径一致 ---
    lea rcx, t_norm
    call printf
    lea rcx, t_norm2
    call printf
    lea rcx, n_a
    lea rdx, n_b
    lea r8, n_c
    lea r9, sse_out
    call sse_muladd
    lea rcx, lb_sse
    movss xmm0, DWORD PTR [sse_out]
    cvtss2sd xmm0, xmm0
    call put_g17

    vmovaps ymm0, YMMWORD PTR [n_c]
    vmovaps ymm1, YMMWORD PTR [n_a]
    vmovaps ymm2, YMMWORD PTR [n_b]
    vfmadd231ps ymm0, ymm1, ymm2
    vmovaps YMMWORD PTR [fma_out], ymm0
    vzeroupper
    lea rcx, lb_fma
    movss xmm0, DWORD PTR [fma_out]
    cvtss2sd xmm0, xmm0
    call put_g17

mainfinish:
    lea rcx, fmt_done
    call printf

    xor  ecx, ecx
    call ExitProcess
main ENDP
END
