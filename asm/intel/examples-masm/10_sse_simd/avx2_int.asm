; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

avxdata SEGMENT ALIGN(32) 'DATA'
    ; (align satisfied by SEGMENT ALIGN)
    mul_a    DWORD 100000, 200000, 300000, 400000, 500000, 600000, 700000, 800000
    ; (align satisfied by SEGMENT ALIGN)
    mul_b    DWORD 3, -3, 3, -3, 3, -3, 3, -3
    ; (align satisfied by SEGMENT ALIGN)
    sh_a     DWORD 1, 1, 1, 1, 1, 1, 1, 1
    ; (align satisfied by SEGMENT ALIGN)
    sh_cnt   DWORD 0, 1, 2, 3, 4, 5, 6, 7
    ; (align satisfied by SEGMENT ALIGN)
    pm_idx   DWORD 7, 6, 5, 4, 3, 2, 1, 0
    ; (align satisfied by SEGMENT ALIGN)
    pm_src   DWORD 10, 20, 30, 40, 50, 60, 70, 80
    ; (align satisfied by SEGMENT ALIGN)
    bcast    DWORD 7
    ; (align satisfied by SEGMENT ALIGN)
    out_buf  DWORD 0, 0, 0, 0, 0, 0, 0, 0

    hdr      BYTE "AVX2 整数：SSE 做不到的三件事", 10, 0
    t1       BYTE "1. VPMULLD —— 8 路 32 位有符号乘（SSE 只有 128 位版）", 10, 0
    t1c      BYTE "   [100000 ... 800000] * [3,-3,3,-3,3,-3,3,-3]", 10, 0
    t2       BYTE "2. VPSLLVD —— 每个通道各自移自己的位数（SSE 只能全体同移）", 10, 0
    t2c      BYTE "   [1 x 8] 左移 [0,1,2,3,4,5,6,7] 位", 10, 0
    t3       BYTE "3. VPERMD  —— 跨 128 位 lane 的任意置换（AVX1 只能在 lane 内换）", 10, 0
    t3c      BYTE "   [10..80] 按索引 [7,6,5,4,3,2,1,0] 重排 = 整体反转", 10, 0
    t3l      BYTE "   （若改用 AVX1 的 vpermilps，只会得到 40 30 20 10 80 70 60 50）", 10, 0
    t4       BYTE "4. VPBROADCASTD —— 内存里的一个数铺满 8 个通道", 10, 0
    t4c      BYTE "   [7] 广播", 10, 0
    t_skip   BYTE "本机不支持 AVX2（CPUID 页 7 EBX[5] / XCR0 已确认），本示例无可演示内容。", 10, 0
    fmt_idx  BYTE "     [%d] = %d", 10, 0
    fmt_done BYTE "AVX2 integer demo completed.", 10, 0

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

    bt   r8d, 12
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
; print_ivec —— 把缓冲区里的 int32 逐个打成 "     [i] = 值"
;   rcx = int32*   edx = 个数          （Win64：前两个参数在 rcx / rdx）
; ------------------------------------------------------------
print_ivec:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12
    push r13
    sub  rsp, 40                     ; 32 字节影子空间 + 8 字节对齐

    mov  rbx, rcx
    mov  r12d, edx
    xor  r13d, r13d
print_ivecloop:
    cmp  r13d, r12d
    jge  print_ivecdone
    mov  r8d, [rbx + r13*4]          ; 参数 2 = 值
    lea rcx, fmt_idx
    mov  edx, r13d                   ; 参数 1 = 下标
    call printf
    inc  r13d
    jmp  print_ivecloop
print_ivecdone:
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

    mov  eax, r12d
    and  eax, 10                     ; bit1(AVX2) + bit3(OS 放开 YMM) = 0b1010
    cmp  eax, 10
    je   mainavx2_ok
    lea rcx, t_skip
    call printf
    jmp  mainfinish

mainavx2_ok:
    ; --- 1. vpmulld：8 路 32 位乘 ---
    lea rcx, t1
    call printf
    lea rcx, t1c
    call printf
    vmovdqa ymm1, YMMWORD PTR [mul_a]
    vmovdqa ymm2, YMMWORD PTR [mul_b]
    vpmulld ymm0, ymm1, ymm2
    vmovdqa YMMWORD PTR [out_buf], ymm0
    vzeroupper
    lea rcx, out_buf
    mov  edx, 8
    call print_ivec

    ; --- 2. vpsllvd：每通道独立移位量 ---
    lea rcx, t2
    call printf
    lea rcx, t2c
    call printf
    vmovdqa ymm1, YMMWORD PTR [sh_a]
    vmovdqa ymm2, YMMWORD PTR [sh_cnt]
    vpsllvd ymm0, ymm1, ymm2         ; ymm0 = ymm1 << ymm2（逐通道）
    vmovdqa YMMWORD PTR [out_buf], ymm0
    vzeroupper
    lea rcx, out_buf
    mov  edx, 8
    call print_ivec

    ; --- 3. vpermd：跨 lane 置换 ---
    lea rcx, t3
    call printf
    lea rcx, t3c
    call printf
    lea rcx, t3l
    call printf
    vmovdqa ymm1, YMMWORD PTR [pm_idx]           ; 索引向量
    vmovdqa ymm2, YMMWORD PTR [pm_src]           ; 被重排的数据
    vpermd  ymm0, ymm1, ymm2         ; ymm0 = ymm2 按 ymm1 的索引取
    vmovdqa YMMWORD PTR [out_buf], ymm0
    vzeroupper
    lea rcx, out_buf
    mov  edx, 8
    call print_ivec

    ; --- 4. vpbroadcastd：一个数铺满 8 通道 ---
    lea rcx, t4
    call printf
    lea rcx, t4c
    call printf
    vpbroadcastd ymm0, DWORD PTR [bcast]       ; SSE 写法要 movss + shufps 两条
    vmovdqa YMMWORD PTR [out_buf], ymm0
    vzeroupper
    lea rcx, out_buf
    mov  edx, 8
    call print_ivec

mainfinish:
    lea rcx, fmt_done
    call printf

    xor  ecx, ecx
    call ExitProcess
main ENDP
END
