; ============================================================
; 文件: 10_sse_simd/avx2_fma.asm                           [Linux 版]
; 指令: VFMADD231PS（FMA3）+ MULPS/ADDPS 对照
; 描述: 一条指令顶两条，而且只舍入一次 —— 差别在小数点后第 14 位
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/10_sse_simd/avx2_fma.asm -o build/avx2_fma.o
; 链接: gcc -no-pie build/avx2_fma.o -o build/avx2_fma
; 对照: examples/10_sse_simd/avx2_fma.asm
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
; 要拿到 1-2^-23 得写成 0x3F7FFFFE。< 这个坑是本示例写第一版时踩到的：
; 本来想用 (1+2^-23)(1-2^-23) 凑出 -2^-46，结果 b 少退了一格，
; 算出来是 +2^-24-2^-47，跟预期对不上，回头数位型才发现。
;
; ------------------------------------------------------------
; Linux 要点：这条测试用的是 float（单精度），打印前要 cvtss2sd 转 double，
; 而且必须用 %.17g 才能看清第 14 位的差别 —— 默认的 %g 只有 6 位有效数字，
; 两个结果都会被印成 0 或 -1.42109e-14，看不出「差了多少」。
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
;   rdi = 以 0 结尾的标签串   xmm0 = double
; ------------------------------------------------------------
put_g17:
    push rbp
    mov  rbp, rsp
    mov  rsi, rdi
    lea  rdi, [fmt_hi]
    mov  eax, 1                      ; 用掉 1 个 xmm 参数
    call printf
    leave
    ret

; ------------------------------------------------------------
; sse_muladd —— 用 mulps + addps 算 out = a*b + c（128 位，4 通道）
;   rdi = a   rsi = b   rdx = c   rcx = out
; 纯 SSE，不碰任何被调用者保存寄存器，也不调用别的函数。
; ------------------------------------------------------------
sse_muladd:
    push rbp
    mov  rbp, rsp
    movaps xmm0, [rdi]               ; a
    movaps xmm1, [rsi]               ; b
    mulps  xmm0, xmm1                ; t = a * b   ← 第一次舍入
    movaps xmm1, [rdx]               ; c
    addps  xmm0, xmm1                ; t = t + c   ← 第二次舍入
    movaps [rcx], xmm0
    leave
    ret

main:
    push rbp
    mov  rbp, rsp
    sub  rsp, 16
    mov  [rbp-8], rbx
    mov  [rbp-16], r12

    call cpu_features
    mov  r12d, eax

    lea  rdi, [hdr]
    xor  eax, eax
    call printf

    ; 打印探测结果：AVX2（bit1）与 FMA（bit2）
    lea  rsi, [str_no]
    mov  eax, r12d
    and  eax, 2
    cmp  eax, 2
    jne  .no_ax2
    lea  rsi, [str_yes]
.no_ax2:
    lea  rdx, [str_no]
    mov  eax, r12d
    and  eax, 4
    cmp  eax, 4
    jne  .no_f
    lea  rdx, [str_yes]
.no_f:
    lea  rdi, [fmt_det]
    xor  eax, eax
    call printf

    ; 本示例要 FMA（bit2）+ OS 放开 YMM（bit3）= 0b1100
    mov  eax, r12d
    and  eax, 12
    cmp  eax, 12
    je   .fma_ok
    lea  rdi, [t_skip]
    xor  eax, eax
    call printf
    jmp  .finish

.fma_ok:
    lea  rdi, [t_desc]
    xor  eax, eax
    call printf
    lea  rdi, [t_desc2]
    xor  eax, eax
    call printf
    lea  rdi, [t_desc3]
    xor  eax, eax
    call printf
    lea  rdi, [t_desc3b]
    xor  eax, eax
    call printf
    lea  rdi, [t_desc4]
    xor  eax, eax
    call printf
    lea  rdi, [t_desc5]
    xor  eax, eax
    call printf

    ; --- 2. SSE 路径 ---
    lea  rdi, [t_sse]
    xor  eax, eax
    call printf
    lea  rdi, [t_sse2]
    xor  eax, eax
    call printf
    lea  rdi, [t_sse3]
    xor  eax, eax
    call printf
    lea  rdi, [f_a]
    lea  rsi, [f_b]
    lea  rdx, [f_c]
    lea  rcx, [sse_out]
    call sse_muladd

    lea  rdi, [lb_sse]
    movss xmm0, [sse_out]
    cvtss2sd xmm0, xmm0
    call put_g17

    ; --- 3. FMA 路径 ---
    lea  rdi, [t_fma]
    xor  eax, eax
    call printf
    vmovaps ymm0, [f_c]
    vmovaps ymm1, [f_a]
    vmovaps ymm2, [f_b]
    vfmadd231ps ymm0, ymm1, ymm2     ; ymm0 = ymm1*ymm2 + ymm0
    vmovaps [fma_out], ymm0
    vzeroupper

    lea  rdi, [lb_fma]
    movss xmm0, [fma_out]
    cvtss2sd xmm0, xmm0
    call put_g17

    ; --- 4. 普通常数：两条路径一致 ---
    lea  rdi, [t_norm]
    xor  eax, eax
    call printf
    lea  rdi, [t_norm2]
    xor  eax, eax
    call printf
    lea  rdi, [n_a]
    lea  rsi, [n_b]
    lea  rdx, [n_c]
    lea  rcx, [sse_out]
    call sse_muladd
    lea  rdi, [lb_sse]
    movss xmm0, [sse_out]
    cvtss2sd xmm0, xmm0
    call put_g17

    vmovaps ymm0, [n_c]
    vmovaps ymm1, [n_a]
    vmovaps ymm2, [n_b]
    vfmadd231ps ymm0, ymm1, ymm2
    vmovaps [fma_out], ymm0
    vzeroupper
    lea  rdi, [lb_fma]
    movss xmm0, [fma_out]
    cvtss2sd xmm0, xmm0
    call put_g17

.finish:
    lea  rdi, [fmt_done]
    xor  eax, eax
    call printf

    mov  rbx, [rbp-8]
    mov  r12, [rbp-16]
    xor  eax, eax
    leave
    ret

%include "linux_io.inc"
