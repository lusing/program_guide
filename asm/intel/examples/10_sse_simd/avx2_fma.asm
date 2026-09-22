; ============================================================
; 文件: 10_sse_simd/avx2_fma.asm                         [Windows 版]
; 指令: VFMADD231PS（FMA3）+ MULPS/ADDPS 对照
; 描述: 一条指令顶两条，而且只舍入一次 —— 差别在小数点后第 14 位
; 平台: Windows x86-64（COFF + Win64 ABI）
; 汇编: nasm -f win64 examples/10_sse_simd/avx2_fma.asm -o build/avx2_fma.obj
; 链接: link /subsystem:console /entry:main build/avx2_fma.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
; 对照: examples-macos/10_sse_simd/avx2_fma.asm ｜ examples-linux/10_sse_simd/avx2_fma.asm
;
; ------------------------------------------------------------
; FMA（Fused Multiply-Add）把「乘」和「加」融成一条指令：
;     SSE：  mulps xmm0, xmm1    ; t = a * b   ← 这里舍入一次
;            addps xmm0, xmm2    ; t = t + c   ← 这里又舍入一次
;     FMA：  vfmadd231ps ymm0, ymm1, ymm2   ; ymm0 = ymm0 + ymm1*ymm2，只舍入一次
;
; 省一条指令只是附带的，真正值钱的是「中间乘积不做舍入」——
; a*b 的完整精度会一直带到最后的加法里。这在下面这个例子里会变成
; 天壤之别：SSE 算出 0，FMA 算出 -1.42e-14。
;
; 后缀 231 / 213 / 132 表示三个操作数各扮演什么角色：
;   vfmadd132ps d, s2, s3   ->   d = d*s3 + s2
;   vfmadd213ps d, s2, s3   ->   d = s2*d + s3
;   vfmadd231ps d, s2, s3   ->   d = s2*s3 + d      ← 最常用（累加器放 d）
; 记法：数字是「寄存器在乘法里的顺序」，而 d 总是同时也出现在加法里。
; 编译器生成的 FMA 大多数是 231，就是因为 `sum += a*b` 这种写法最自然。
;
; 注意 FMA 的 CPUID 位在页 1 ECX[12]，不是页 7 —— 页 7 里没有 FMA。
; 页 7 查的是 AVX2（EBX[5]）。二者都是 Haswell（2013）起，但探测位不同。
;
; 顺便记一个浮点坑：**1.0 两侧的 ulp 不一样**。1.0 以上的间距是 2^-23，
; 1.0 以下只有 2^-24（因为跨过 1.0 时指数从 127 掉到 126，尾数多一位可用）。
; 所以「比 1.0 小的最大数」是 0x3F7FFFFF = 1-2^-24，
; 要拿到 1-2^-23 得写成 0x3F7FFFFE。
;
; ------------------------------------------------------------
; Windows 要点：printf 第 1 个参数在 rcx，其后依次 rdx / r8；浮点参数既写
; xmm（本例是第 2 个浮点参数位 -> xmm1）又同时写整数槽（r8），MSVC 才认。
; 退场用 ExitProcess。本文件在 Windows 上**没有实测**（本机是 macOS）。
; ============================================================
default rel

section .data
    ; a = 1 + 2^-23（float 里比 1.0 大的最小数）
    align 32
    f_a   times 8 dd 0x3F800001
    ; b = 1 - 2^-23（位型 0x3F7FFFFE，不是 0x3F7FFFFF）
    ; 注意：1.0 以下 ulp 只有 2^-24，所以「比 1.0 小的最大数」
    ; 其实是 0x3F7FFFFF = 1-2^-24；要凑出 1-2^-23 得再退一格。
    align 32
    f_b   times 8 dd 0x3F7FFFFE
    ; c = -1.0
    align 32
    f_c   times 8 dd 0xBF800000

    ; 一组普通常数，用来证明 FMA 不是「另一种算法」
    align 32
    n_a   times 8 dd 2.0
    align 32
    n_b   times 8 dd 3.0
    align 32
    n_c   times 8 dd 4.0

    align 16
    sse_out  dd 0.0, 0.0, 0.0, 0.0
    align 32
    fma_out  dd 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
    align 8
    temp_double dq 0.0

    str_yes  db "YES", 0
    str_no   db "NO", 0

    hdr      db "FMA：一条顶两条，而且只舍入一次", 10, 0
    fmt_det  db "探测：AVX2 = %s，FMA = %s", 10, 0
    t_desc   db "1. 一个能看出差别的小例子", 10, 0
    t_desc2  db "   a = 1 + 2^-23（float 里比 1.0 大的最小数，位型 0x3F800001）", 10, 0
    t_desc3  db "   b = 1 - 2^-23（位型 0x3F7FFFFE）", 10, 0
    t_desc3b db "   （坑：1.0 以下的 ulp 只有 2^-24，所以 0x3F7FFFFF 是 1-2^-24，不是 1-2^-23）", 10, 0
    t_desc4  db "   c = -1.0", 10, 0
    t_desc5  db "   精确值 a*b + c = -2^-46 = -1.4210854715202004e-14", 10, 0
    t_sse    db "2. SSE 路径：mulps + addps，中间乘积被舍入两次", 10, 0
    t_sse2   db "   a*b 的真值 1-2^-46 塞不进 float（只有 24 位有效位），先被舍入成 1.0", 10, 0
    t_sse3   db "   然后 1.0 + (-1.0) = 0 —— 有效数字全被抵消了", 10, 0
    t_fma    db "3. FMA 路径：vfmadd231ps，只有最后一次舍入", 10, 0
    t_norm   db "4. 换一组普通常数（a=2, b=3, c=4），两条路径结果一样", 10, 0
    t_norm2  db "   —— FMA 不是另一种算法，只是少了中间那一次舍入", 10, 0
    lb_sse   db "mulps+addps 结果", 0
    lb_fma   db "vfmadd231ps 结果", 0
    t_skip   db "本机不支持 FMA（CPUID 页 1 ECX[12] / XCR0 已确认），无法演示。", 10, 0
    fmt_hi   db "   %s = %.17g", 10, 0
    fmt_done db "FMA demo completed.", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

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
    jb   .done

    mov  eax, 1
    xor  ecx, ecx
    cpuid
    mov  r8d, ecx

    bt   r8d, 12                     ; FMA（在页 1）
    jnc  .no_fma
    or   r12d, 4
.no_fma:
    bt   r8d, 28
    jnc  .done
    bt   r8d, 27
    jnc  .done

    xor  ecx, ecx
    xgetbv
    and  eax, 6
    cmp  eax, 6
    jne  .done
    or   r12d, 9

    cmp  r9d, 7
    jb   .done
    mov  eax, 7
    xor  ecx, ecx
    cpuid
    bt   ebx, 5
    jnc  .done
    or   r12d, 2

.done:
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
    movsd [temp_double], xmm1
    mov  r8, [temp_double]           ; 浮点参数还要同时写整数槽
    lea  rcx, [fmt_hi]
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
    movaps xmm0, [rcx]               ; a
    movaps xmm1, [rdx]               ; b
    mulps  xmm0, xmm1                ; t = a * b   ← 第一次舍入
    movaps xmm1, [r8]                ; c
    addps  xmm0, xmm1                ; t = t + c   ← 第二次舍入
    movaps [r9], xmm0
    leave
    ret

; ============================================================
; 主程序（/entry:main，所以退场用 ExitProcess，不能用 ret）
; ============================================================
main:
    push rbp
    mov  rbp, rsp
    sub  rsp, 32                     ; 影子空间

    call cpu_features
    mov  r12d, eax                   ; 特性位图

    lea  rcx, [hdr]
    call printf

    ; 打印探测结果：AVX2（bit1）与 FMA（bit2）
    lea  rdx, [str_no]
    mov  eax, r12d
    and  eax, 2
    cmp  eax, 2
    jne  .no_ax2
    lea  rdx, [str_yes]
.no_ax2:
    lea  r8, [str_no]
    mov  eax, r12d
    and  eax, 4
    cmp  eax, 4
    jne  .no_f
    lea  r8, [str_yes]
.no_f:
    lea  rcx, [fmt_det]
    call printf

    ; 本示例要 FMA（bit2）+ OS 放开 YMM（bit3）= 0b1100
    mov  eax, r12d
    and  eax, 12
    cmp  eax, 12
    je   .fma_ok
    lea  rcx, [t_skip]
    call printf
    jmp  .finish

.fma_ok:
    lea  rcx, [t_desc]
    call printf
    lea  rcx, [t_desc2]
    call printf
    lea  rcx, [t_desc3]
    call printf
    lea  rcx, [t_desc3b]
    call printf
    lea  rcx, [t_desc4]
    call printf
    lea  rcx, [t_desc5]
    call printf

    ; --- 2. SSE 路径 ---
    lea  rcx, [t_sse]
    call printf
    lea  rcx, [t_sse2]
    call printf
    lea  rcx, [t_sse3]
    call printf
    lea  rcx, [f_a]
    lea  rdx, [f_b]
    lea  r8,  [f_c]
    lea  r9,  [sse_out]
    call sse_muladd

    lea  rcx, [lb_sse]
    movss xmm0, [sse_out]
    cvtss2sd xmm0, xmm0
    call put_g17

    ; --- 3. FMA 路径 ---
    lea  rcx, [t_fma]
    call printf
    vmovaps ymm0, [f_c]
    vmovaps ymm1, [f_a]
    vmovaps ymm2, [f_b]
    vfmadd231ps ymm0, ymm1, ymm2     ; ymm0 = ymm1*ymm2 + ymm0
    vmovaps [fma_out], ymm0
    vzeroupper

    lea  rcx, [lb_fma]
    movss xmm0, [fma_out]
    cvtss2sd xmm0, xmm0
    call put_g17

    ; --- 4. 普通常数：两条路径一致 ---
    lea  rcx, [t_norm]
    call printf
    lea  rcx, [t_norm2]
    call printf
    lea  rcx, [n_a]
    lea  rdx, [n_b]
    lea  r8,  [n_c]
    lea  r9,  [sse_out]
    call sse_muladd
    lea  rcx, [lb_sse]
    movss xmm0, [sse_out]
    cvtss2sd xmm0, xmm0
    call put_g17

    vmovaps ymm0, [n_c]
    vmovaps ymm1, [n_a]
    vmovaps ymm2, [n_b]
    vfmadd231ps ymm0, ymm1, ymm2
    vmovaps [fma_out], ymm0
    vzeroupper
    lea  rcx, [lb_fma]
    movss xmm0, [fma_out]
    cvtss2sd xmm0, xmm0
    call put_g17

.finish:
    lea  rcx, [fmt_done]
    call printf

    xor  ecx, ecx
    call ExitProcess
