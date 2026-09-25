; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

avxdata SEGMENT ALIGN(64) 'DATA'
    ; (align satisfied by SEGMENT ALIGN)
    add_a    DWORD 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
    ; (align satisfied by SEGMENT ALIGN)
    add_b    DWORD 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100
    ; (align satisfied by SEGMENT ALIGN)
    ; 掩码：选偶数下标通道（bit0,2,4,...=1），即 5555h
    mask_even WORD 5555h
    ; (align satisfied by SEGMENT ALIGN)
    ; 合并掩码用的「目标初值」：先放 1..16，带掩码加完后奇数下标仍保留这些值
    merge_init DWORD 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
    ; (align satisfied by SEGMENT ALIGN)
    out_buf  DWORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

    hdr      BYTE "AVX-512 基础：ZMM 512 位 + opmask k 寄存器", 10, 0
    t1       BYTE "1. VPADDD zmm —— 16 路 32 位整数加（AVX2 只有 8 路）", 10, 0
    t1c      BYTE "   [1..16] + [100 x 16]", 10, 0
    t2       BYTE "2. 合并掩码 {k1}：只更新偶数下标通道，其余保留目标初值", 10, 0
    t2c      BYTE "   掩码 = 0x5555（bit 0,2,4,...,14 置位）；目标初值 = [1..16]", 10, 0
    t2d      BYTE "   期望：偶数下标 = 初值+100，奇数下标 = 初值不变", 10, 0
    t3       BYTE "3. 归零掩码 {k1}{z}：未选中通道直接清零", 10, 0
    t3c      BYTE "   同样的掩码与输入，但奇数下标变成 0", 10, 0
    t_skip   BYTE "本机不支持 AVX-512F（CPUID 页 7 EBX[16] / XCR0[7:5] 已确认），本示例无可演示内容。", 10, 0
    fmt_idx  BYTE "     [%2d] = %d", 10, 0
    fmt_done BYTE "AVX-512 basics demo completed.", 10, 0

avxdata ENDS

.code

; ------------------------------------------------------------
; cpu_features —— CPUID + XGETBV 探测，返回 eax 位图
;   bit0 = AVX         页1 ECX[28]，且 ECX[27] OSXSAVE，且 XCR0[2:1] = 11
;   bit1 = AVX2        页7 EBX[5]
;   bit2 = FMA         页1 ECX[12]
;   bit3 = OS 放开 YMM（XCR0[2:1]）
;   bit4 = AVX-512F    页7 EBX[16]
;   bit5 = OS 放开 ZMM/opmask（XCR0[7:5] 全 1）
;
; CPUID 会踩 rbx，而 rbx 是被调用者保存寄存器，所以这里先备份。
; 本函数不调用别的函数，纯寄存器运算。
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

    bt   r8d, 12                     ; FMA
    jnc  cpu_featuresno_fma
    or   r12d, 4
cpu_featuresno_fma:
    bt   r8d, 28                     ; AVX
    jnc  cpu_featuresdone
    bt   r8d, 27                     ; OSXSAVE
    jnc  cpu_featuresdone

    xor  ecx, ecx
    xgetbv                           ; XCR0 -> EDX:EAX
    mov  r11d, eax                   ; 完整保存 XCR0，后面 AVX-512 的 [7:5] 还要用
    mov  r10d, eax
    and  r10d, 6
    cmp  r10d, 6                     ; XCR0[2:1] = YMM
    jne  cpu_featuresdone
    or   r12d, 9                     ; bit0(AVX) + bit3(OS YMM)

    cmp  r9d, 7
    jb   cpu_featuresdone
    mov  eax, 7
    xor  ecx, ecx
    cpuid
    bt   ebx, 5                      ; AVX2
    jnc  cpu_featuresno_avx2
    or   r12d, 2
cpu_featuresno_avx2:
    bt   ebx, 16                     ; AVX-512F
    jnc  cpu_featuresdone
    or   r12d, 16

    ; XCR0[7:5]：opmask(5) + ZMM_Hi256(6) + Hi16_ZMM(7)，三者都要置位
    mov  r10d, r11d                  ; 取回之前保存的完整 XCR0
    and  r10d, 0E0h
    cmp  r10d, 0E0h
    jne  cpu_featuresdone
    or   r12d, 32

cpu_featuresdone:
    mov  eax, r12d
    pop  r12
    pop  rbx
    leave
    ret

; ------------------------------------------------------------
; print_ivec16 —— 把缓冲区里的 16 个 int32 逐个打成 "     [i] = 值"
;   rcx = int32*                       （Win64：第 1 个参数在 rcx）
; ------------------------------------------------------------
print_ivec16:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12
    push r13
    sub  rsp, 40                     ; 32 字节影子空间 + 8 字节对齐

    mov  rbx, rcx
    xor  r13d, r13d
print_ivec16loop:
    cmp  r13d, 16
    jge  print_ivec16done
    mov  r8d, [rbx + r13*4]          ; 参数 2 = 值
    lea rcx, fmt_idx
    mov  edx, r13d                   ; 参数 1 = 下标
    call printf
    inc  r13d
    jmp  print_ivec16loop
print_ivec16done:
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
    and  eax, 48                     ; bit4(AVX-512F) + bit5(OS 放开 ZMM) = 0b110000
    cmp  eax, 48
    je   mainavx512_ok
    lea rcx, t_skip
    call printf
    jmp  mainfinish

mainavx512_ok:
    ; --- 1. vpaddd zmm：16 路 32 位整数加 ---
    lea rcx, t1
    call printf
    lea rcx, t1c
    call printf
    vmovdqa32 zmm1, ZMMWORD PTR [add_a]
    vmovdqa32 zmm2, ZMMWORD PTR [add_b]
    vpaddd zmm0, zmm1, zmm2
    vmovdqa32 ZMMWORD PTR [out_buf], zmm0
    vzeroupper
    lea rcx, out_buf
    call print_ivec16

    ; --- 2. 合并掩码 {k1}：偶数下标更新，奇数下标保留目标初值 ---
    lea rcx, t2
    call printf
    lea rcx, t2c
    call printf
    lea rcx, t2d
    call printf
    mov  eax, DWORD PTR [mask_even]            ; 5555h
    kmovw k1, eax
    vmovdqa32 zmm0, ZMMWORD PTR [merge_init]     ; 目标初值 ZMMWORD PTR [1..16]
    vmovdqa32 zmm1, ZMMWORD PTR [add_b]          ; [100 x 16]
    vpaddd zmm0 {k1}, zmm0, zmm1     ; 只在 k1 置位的通道执行加法
    vmovdqa32 ZMMWORD PTR [out_buf], zmm0
    vzeroupper
    lea rcx, out_buf
    call print_ivec16

    ; --- 3. 归零掩码 {k1}{z}：未选中通道清零 ---
    ; 注意：opmask k 寄存器是「调用者保存」的，上面 print_ivec16 里的
    ; printf 已经把 k1 冲掉了，这里必须重新加载掩码。
    lea rcx, t3
    call printf
    lea rcx, t3c
    call printf
    mov  eax, DWORD PTR [mask_even]
    kmovw k1, eax                     ; 重新加载掩码 5555h
    vmovdqa32 zmm1, ZMMWORD PTR [add_a]           ; ZMMWORD PTR [1..16]
    vmovdqa32 zmm2, ZMMWORD PTR [add_b]           ; [100 x 16]
    vpaddd zmm0 {k1}{z}, zmm1, zmm2   ; 偶数下标 = a+b，奇数下标 = 0
    vmovdqa32 ZMMWORD PTR [out_buf], zmm0
    vzeroupper
    lea rcx, out_buf
    call print_ivec16

mainfinish:
    lea rcx, fmt_done
    call printf

    xor  ecx, ecx
    call ExitProcess
main ENDP
END
