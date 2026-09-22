; ============================================================
; 文件: 10_sse_simd/avx_basics.asm                         [Linux 版]
; 指令: VADDPS / VMULPS / VZEROUPPER（AVX1，256 位 YMM）
; 描述: VEX 编码到底带来什么 —— 三操作数 + 一次算 8 个 float
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/10_sse_simd/avx_basics.asm -o build/avx_basics.o
; 链接: gcc -no-pie build/avx_basics.o -o build/avx_basics
; 对照: examples/10_sse_simd/avx_basics.asm
;
; ------------------------------------------------------------
; AVX（2011，Sandy Bridge）做了两件事：
;   1. 向量宽度 128 -> 256 位（xmm -> ymm），8 个 float 一次算；
;   2. 换掉整条指令编码，新增 VEX 前缀，指令从「两操作数」变「三操作数」。
;
; 第 2 条比第 1 条重要得多。SSE 的 addps 是破坏性的：
;     addps xmm0, xmm1          ; xmm0 = xmm0 + xmm1，xmm0 的原值没了
; 想在别处复用 xmm0 就得先 movaps 备份一条。AVX 的 vaddps 不是：
;     vaddps ymm0, ymm1, ymm2   ; ymm0 = ymm1 + ymm2，ymm1 / ymm2 原样保留
; 这叫「非破坏性源操作数」。本示例第 2 段就靠这一点，用同一对源寄存器
; 直接算出「和」与「积」两组结果 —— 换成 SSE 写法就得先插一条备份。
;
; 注意「VEX 编码」和「256 位」是两件事：vaddps xmm0,xmm1,xmm2 是 128 位的
; VEX 编码，照样是三操作数。只要助记符前面有 v，就是 VEX 编码。
;
; ------------------------------------------------------------
; 用了 ymm 之后必须 vzeroupper。
; ymm 的上半 128 位在没清零时是「脏」的，而后续的 SSE 指令（printf 内部
; 就有一堆）在 Haswell 上会让 CPU 保存/恢复整个上半部，每次付出几十个
; 周期的 AVX↔SSE 转换惩罚。养成习惯：算完 -> vzeroupper -> 再调 libc。
; 本示例把结果先落内存、再 vzeroupper、最后才 printf，顺序就是这个道理。
;
; ------------------------------------------------------------
; Linux 要点：探测 AVX 不能只看 CPUID，还要看操作系统有没有放开 YMM 状态。
;   页 1 ECX[27] = OSXSAVE、ECX[28] = AVX；
;   再 XGETBV 读 XCR0，要求 bit1|bit2 = 11 —— 否则 ymm 指令直接 #UD。
; 只判 CPUID 的代码在「CPU 支持但 OS 没开」的机器上会当场崩，
; 虚拟机和老系统上这种组合很常见。
; ============================================================
default rel

section .data
    ; --- SSE 基线：4 个 float ---
    align 16
    sse_a    dd 1.0, 2.0, 3.0, 4.0
    align 16
    sse_b    dd 10.0, 10.0, 10.0, 10.0
    align 16
    sse_buf  dd 0.0, 0.0, 0.0, 0.0

    ; --- AVX：8 个 float，必须 32 字节对齐（vmovaps 要求）---
    align 32
    avx_a    dd 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0
    align 32
    avx_b    dd 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0
    align 32
    avx_sum  dd 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
    align 32
    avx_prod dd 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0

    hdr        db "AVX 基础：VEX 三操作数 + 256 位 YMM", 10, 0
    t_sse      db "1. SSE 基线（128 位，破坏性操作数）", 10, 0
    t_sse_c    db "   addps xmm0,xmm1 算完 xmm0 原值就没了；想复用必须先 movaps 备份", 10, 0
    fmt_sum    db "2. AVX：同一对源寄存器，连算两组结果（源没被破坏）", 10, 0
    fmt_sum_c  db "   和： [1..8] + [10 x 8]", 10, 0
    fmt_prod_c db "   积： [1..8] * [10 x 8]", 10, 0
    t_zero     db "3. vzeroupper：ymm 上半部已清零，现在可以安全调 printf 了", 10, 0
    t_skip     db "本机不支持 AVX（CPUID 页 1 / XCR0 已确认），跳过第 2~3 段，只跑 SSE 基线。", 10, 0
    fmt_idx    db "     [%d] = ", 0
    fmt_done   db "AVX basics demo completed.", 10, 0

section .text
    global main
    extern printf

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
    jb   .done                       ; 连页 1 都没有，什么都别问了

    mov  eax, 1
    xor  ecx, ecx
    cpuid
    mov  r8d, ecx                    ; 页 1 的特性位图在 ECX

    bt   r8d, 12                     ; FMA
    jnc  .no_fma
    or   r12d, 4
.no_fma:
    bt   r8d, 28                     ; AVX
    jnc  .done
    bt   r8d, 27                     ; OSXSAVE（没它就说明 OS 没开扩展状态）
    jnc  .done

    xor  ecx, ecx
    xgetbv                           ; XCR0 -> EDX:EAX
    and  eax, 6                      ; 只看 bit1(SSE) 和 bit2(YMM)
    cmp  eax, 6
    jne  .done                       ; OS 没放开 YMM，AVX 可用性不成立
    or   r12d, 9                     ; bit0(AVX) + bit3(OS 已放开 YMM)

    cmp  r9d, 7
    jb   .done
    mov  eax, 7
    xor  ecx, ecx
    cpuid
    bt   ebx, 5                      ; AVX2
    jnc  .done
    or   r12d, 2

.done:
    mov  eax, r12d
    pop  r12
    pop  rbx
    leave
    ret

; ------------------------------------------------------------
; print_vec —— 把缓冲区里的 float 逐个打成 "     [i] = 值"
;   rdi = float*   esi = 个数
; ------------------------------------------------------------
print_vec:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12
    push r13
    sub  rsp, 8                      ; 保持 16 字节对齐

    mov  rbx, rdi
    mov  r12d, esi
    xor  r13d, r13d
.loop:
    cmp  r13d, r12d
    jge  .done
    lea  rdi, [fmt_idx]
    mov  esi, r13d
    xor  eax, eax
    call printf
    movss xmm0, [rbx + r13*4]
    call l_putf                      ; float -> %g
    call l_nl
    inc  r13d
    jmp  .loop
.done:
    add  rsp, 8
    pop  r13
    pop  r12
    pop  rbx
    leave
    ret

main:
    push rbp
    mov  rbp, rsp
    sub  rsp, 16
    mov  [rbp-8], rbx
    mov  [rbp-16], r12

    call cpu_features
    mov  r12d, eax                   ; r12d = 特性位图

    lea  rdi, [hdr]
    xor  eax, eax
    call printf

    ; --------------------------------------------------------
    ; 1. SSE 基线：128 位、破坏性操作数
    ; --------------------------------------------------------
    lea  rdi, [t_sse]
    xor  eax, eax
    call printf
    lea  rdi, [t_sse_c]
    xor  eax, eax
    call printf
    movaps xmm0, [sse_a]
    movaps xmm1, [sse_b]
    addps  xmm0, xmm1                ; xmm0 被覆盖：原值 [1,2,3,4] 消失
    movaps [sse_buf], xmm0
    lea  rdi, [sse_buf]
    mov  esi, 4
    call print_vec

    ; --------------------------------------------------------
    ; 第 2~3 段需要 AVX：bit0 = AVX 可用，bit3 = OS 放开了 YMM
    ; --------------------------------------------------------
    mov  eax, r12d
    and  eax, 9
    cmp  eax, 9
    je   .avx_ok
    lea  rdi, [t_skip]
    xor  eax, eax
    call printf
    jmp  .finish

.avx_ok:
    lea  rdi, [fmt_sum]
    xor  eax, eax
    call printf

    vmovaps ymm1, [avx_a]
    vmovaps ymm2, [avx_b]
    vaddps  ymm0, ymm1, ymm2         ; ymm0 = ymm1 + ymm2
    vmulps  ymm3, ymm1, ymm2         ; ymm1 / ymm2 还是原值，直接复用
    vmovaps [avx_sum],  ymm0
    vmovaps [avx_prod], ymm3
    vzeroupper                       ; 落盘后立刻清上半部

    lea  rdi, [fmt_sum_c]
    xor  eax, eax
    call printf
    lea  rdi, [avx_sum]
    mov  esi, 8
    call print_vec

    lea  rdi, [fmt_prod_c]
    xor  eax, eax
    call printf
    lea  rdi, [avx_prod]
    mov  esi, 8
    call print_vec

    lea  rdi, [t_zero]
    xor  eax, eax
    call printf

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
