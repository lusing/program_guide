; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

avxdata SEGMENT ALIGN(32) 'DATA'
    ; --- SSE 基线：4 个 float ---
    align 16
    sse_a    DWORD 1.0, 2.0, 3.0, 4.0
    align 16
    sse_b    DWORD 10.0, 10.0, 10.0, 10.0
    align 16
    sse_buf  DWORD 0.0, 0.0, 0.0, 0.0

    ; --- AVX：8 个 float，必须 32 字节对齐（vmovaps 要求）---
    ; (align satisfied by SEGMENT ALIGN)
    avx_a    DWORD 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0
    ; (align satisfied by SEGMENT ALIGN)
    avx_b    DWORD 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0
    ; (align satisfied by SEGMENT ALIGN)
    avx_sum  DWORD 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
    ; (align satisfied by SEGMENT ALIGN)
    avx_prod DWORD 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0

    align 8
    temp_double REAL8 0.0

    hdr        BYTE "AVX 基础：VEX 三操作数 + 256 位 YMM", 10, 0
    t_sse      BYTE "1. SSE 基线（128 位，破坏性操作数）", 10, 0
    t_sse_c    BYTE "   addps xmm0,xmm1 算完 xmm0 原值就没了；想复用必须先 movaps 备份", 10, 0
    fmt_sum    BYTE "2. AVX：同一对源寄存器，连算两组结果（源没被破坏）", 10, 0
    fmt_sum_c  BYTE "   和： [1..8] + [10 x 8]", 10, 0
    fmt_prod_c BYTE "   积： [1..8] * [10 x 8]", 10, 0
    t_zero     BYTE "3. vzeroupper：ymm 上半部已清零，现在可以安全调 printf 了", 10, 0
    t_skip     BYTE "本机不支持 AVX（CPUID 页 1 / XCR0 已确认），跳过第 2~3 段，只跑 SSE 基线。", 10, 0
    fmt_idx    BYTE "     [%d] = %f", 10, 0
    fmt_done   BYTE "AVX basics demo completed.", 10, 0

avxdata ENDS

.code

; ------------------------------------------------------------
; cpu_features —— CPUID + XGETBV 探测，返回 eax 位图
;   bit0 = AVX    页1 ECX[28]，且 ECX[27] OSXSAVE，且 XCR0[2:1] = 11
;   bit1 = AVX2   页7 EBX[5]
;   bit2 = FMA    页1 ECX[12]      ← 注意：FMA 在页 1，不在页 7
;   bit3 = 操作系统已放开 YMM 状态保存（XCR0[2:1]）
;
; CPUID 会踩 rbx，而 rbx 是被调用者保存寄存器，所以这里先备份。
; 本函数不调用别的函数，纯寄存器运算。
; ------------------------------------------------------------
cpu_features:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12

    xor  r12d, r12d                  ; 结果位图

    mov  eax, 0
    cpuid
    mov  r9d, eax                    ; r9d = 最大页号
    cmp  r9d, 1
    jb   cpu_featuresdone                       ; 连页 1 都没有，什么都别问了

    mov  eax, 1
    xor  ecx, ecx
    cpuid
    mov  r8d, ecx                    ; 页 1 的特性位图在 ECX

    bt   r8d, 12                     ; FMA
    jnc  cpu_featuresno_fma
    or   r12d, 4
cpu_featuresno_fma:
    bt   r8d, 28                     ; AVX
    jnc  cpu_featuresdone
    bt   r8d, 27                     ; OSXSAVE（没它就说明 OS 没开扩展状态）
    jnc  cpu_featuresdone

    xor  ecx, ecx
    xgetbv                           ; XCR0 -> EDX:EAX
    and  eax, 6                      ; 只看 bit1(SSE) 和 bit2(YMM)
    cmp  eax, 6
    jne  cpu_featuresdone                       ; OS 没放开 YMM，AVX 可用性不成立
    or   r12d, 9                     ; bit0(AVX) + bit3(OS 已放开 YMM)

    cmp  r9d, 7
    jb   cpu_featuresdone
    mov  eax, 7
    xor  ecx, ecx
    cpuid
    bt   ebx, 5                      ; AVX2
    jnc  cpu_featuresdone
    or   r12d, 2

cpu_featuresdone:
    mov  eax, r12d
    pop  r12
    pop  rbx
    leave
    ret

; ------------------------------------------------------------
; print_vec —— 把缓冲区里的 float 逐个打成 "     [i] = 值"
;   rcx = float*   edx = 个数          （Win64：前两个参数在 rcx / rdx）
; ------------------------------------------------------------
print_vec:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12
    push r13
    sub  rsp, 40                     ; 32 字节影子空间 + 8 字节对齐

    mov  rbx, rcx
    mov  r12d, edx
    xor  r13d, r13d
print_vecloop:
    cmp  r13d, r12d
    jge  print_vecdone
    movss xmm0, DWORD PTR [rbx+ r13*4]
    cvtss2sd xmm2, xmm0              ; 第 2 个浮点参数位（参数 2 = 值）
    movsd QWORD PTR [temp_double], xmm2
    lea rcx, fmt_idx
    mov  edx, r13d                   ; 参数 1 = 下标
    mov  r8, QWORD PTR [temp_double]           ; 浮点参数还要同时写整数槽
    call printf
    inc  r13d
    jmp  print_vecloop
print_vecdone:
    add  rsp, 40
    pop  r13
    pop  r12
    pop  rbx
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
    mov  r12d, eax                   ; main 不返回，可以随便用 r12 存位图

    lea rcx, hdr
    call printf

    ; --------------------------------------------------------
    ; 1. SSE 基线：128 位、破坏性操作数
    ; --------------------------------------------------------
    lea rcx, t_sse
    call printf
    lea rcx, t_sse_c
    call printf
    movaps xmm0, XMMWORD PTR [sse_a]
    movaps xmm1, XMMWORD PTR [sse_b]
    addps  xmm0, xmm1                ; xmm0 被覆盖：原值 [1,2,3,4] 消失
    movaps XMMWORD PTR [sse_buf], xmm0
    lea rcx, sse_buf
    mov  edx, 4
    call print_vec

    ; --------------------------------------------------------
    ; 第 2 NOT 3 段需要 AVX：bit0 = AVX 可用，bit3 = OS 放开了 YMM
    ; --------------------------------------------------------
    mov  eax, r12d
    and  eax, 9
    cmp  eax, 9
    je   mainavx_ok
    lea rcx, t_skip
    call printf
    jmp  mainfinish

mainavx_ok:
    lea rcx, fmt_sum
    call printf

    vmovaps ymm1, YMMWORD PTR [avx_a]
    vmovaps ymm2, YMMWORD PTR [avx_b]
    vaddps  ymm0, ymm1, ymm2         ; ymm0 = ymm1 + ymm2
    vmulps  ymm3, ymm1, ymm2         ; ymm1 / ymm2 还是原值，直接复用
    vmovaps YMMWORD PTR [avx_sum],  ymm0
    vmovaps YMMWORD PTR [avx_prod], ymm3
    vzeroupper                       ; 落盘后立刻清上半部

    lea rcx, fmt_sum_c
    call printf
    lea rcx, avx_sum
    mov  edx, 8
    call print_vec

    lea rcx, fmt_prod_c
    call printf
    lea rcx, avx_prod
    mov  edx, 8
    call print_vec

    lea rcx, t_zero
    call printf

mainfinish:
    lea rcx, fmt_done
    call printf

    xor  ecx, ecx
    call ExitProcess
main ENDP
END
