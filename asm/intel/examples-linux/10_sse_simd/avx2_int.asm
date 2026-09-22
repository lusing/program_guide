; ============================================================
; 文件: 10_sse_simd/avx2_int.asm                           [Linux 版]
; 指令: VPMULLD / VPSLLVD / VPERMD / VPBROADCASTD（AVX2）
; 描述: 整数运算从 128 位到 256 位 —— SSE 根本做不到的几件事
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/10_sse_simd/avx2_int.asm -o build/avx2_int.o
; 链接: gcc -no-pie build/avx2_int.o -o build/avx2_int
; 对照: examples/10_sse_simd/avx2_int.asm
;
; ------------------------------------------------------------
; AVX1 只把「浮点」宽度扩到 256 位。整数运算要等到 AVX2（2013，Haswell）
; 才补上 256 位版本 —— 这是 AVX1 和 AVX2 最本质的分界，也是为什么
; 2011~2013 那两年的编译器没法把整数循环向量化到 256 位。
;
; AVX2 在整数侧真正加了三个「SSE 做不到」的能力（本示例逐个演示）：
;
;   1. 256 位整数乘      vpmulld ymm   8 路 32 位有符号乘
;                        SSE 侧只有 128 位的 pmulld（且要 SSE4.1）
;   2. 每通道独立移位    vpsllvd ymm, ymm, ymm
;                        移位量本身是向量，8 个通道可以各移各的；
;                        SSE 的 pslld 只能给一个立即数，全体一起移。
;   3. 跨 lane 置换      vpermd ymm, ymm, ymm
;                        256 位向量在多数 shuffle 指令眼里是「两个独立的
;                        128 位 lane」，AVX1 的 vpermilps 只能在 lane 内换；
;                        想跨过中线必须用 AVX2 的 vpermd / vpermps。
;
; 第 3 点是最容易翻车的：用 AVX1 的 vpermilps 去写「反转 8 个元素」，
; 结果只会是前后两半各自反转，中间的 3 和 4 换不过去。
;
; 另外顺手演示 vpbroadcastd：SSE 时代把常数铺满所有通道要
; movss + shufps 两条，AVX2 一条搞定。
;
; ------------------------------------------------------------
; Linux 要点：整数结果用 %d 打印，参数走 rdi/rsi/rdx，不占 xmm；
; 用 ymm 之后照例 vzeroupper 再调 printf。
; ============================================================
default rel

section .data
    align 32
    mul_a    dd 100000, 200000, 300000, 400000, 500000, 600000, 700000, 800000
    align 32
    mul_b    dd 3, -3, 3, -3, 3, -3, 3, -3
    align 32
    sh_a     dd 1, 1, 1, 1, 1, 1, 1, 1
    align 32
    sh_cnt   dd 0, 1, 2, 3, 4, 5, 6, 7
    align 32
    pm_idx   dd 7, 6, 5, 4, 3, 2, 1, 0
    align 32
    pm_src   dd 10, 20, 30, 40, 50, 60, 70, 80
    align 32
    bcast    dd 7
    align 32
    out_buf  dd 0, 0, 0, 0, 0, 0, 0, 0

    hdr      db "AVX2 整数：SSE 做不到的三件事", 10, 0
    t1       db "1. VPMULLD —— 8 路 32 位有符号乘（SSE 只有 128 位版）", 10, 0
    t1c      db "   [100000 ... 800000] * [3,-3,3,-3,3,-3,3,-3]", 10, 0
    t2       db "2. VPSLLVD —— 每个通道各自移自己的位数（SSE 只能全体同移）", 10, 0
    t2c      db "   [1 x 8] 左移 [0,1,2,3,4,5,6,7] 位", 10, 0
    t3       db "3. VPERMD  —— 跨 128 位 lane 的任意置换（AVX1 只能在 lane 内换）", 10, 0
    t3c      db "   [10..80] 按索引 [7,6,5,4,3,2,1,0] 重排 = 整体反转", 10, 0
    t3l      db "   （若改用 AVX1 的 vpermilps，只会得到 40 30 20 10 80 70 60 50）", 10, 0
    t4       db "4. VPBROADCASTD —— 内存里的一个数铺满 8 个通道", 10, 0
    t4c      db "   [7] 广播", 10, 0
    t_skip   db "本机不支持 AVX2（CPUID 页 7 EBX[5] / XCR0 已确认），本示例无可演示内容。", 10, 0
    fmt_idx  db "     [%d] = %d", 10, 0
    fmt_done db "AVX2 integer demo completed.", 10, 0

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

    bt   r8d, 12
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
; print_ivec —— 把缓冲区里的 int32 逐个打成 "     [i] = 值"
;   rdi = int32*   esi = 个数
; ------------------------------------------------------------
print_ivec:
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
    mov  edx, [rbx + r13*4]
    lea  rdi, [fmt_idx]
    mov  esi, r13d
    xor  eax, eax
    call printf
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
    mov  r12d, eax

    lea  rdi, [hdr]
    xor  eax, eax
    call printf

    mov  eax, r12d
    and  eax, 10                     ; bit1(AVX2) + bit3(OS 放开 YMM) = 0b1010
    cmp  eax, 10
    je   .avx2_ok
    lea  rdi, [t_skip]
    xor  eax, eax
    call printf
    jmp  .finish

.avx2_ok:
    ; --- 1. vpmulld：8 路 32 位乘 ---
    lea  rdi, [t1]
    xor  eax, eax
    call printf
    lea  rdi, [t1c]
    xor  eax, eax
    call printf
    vmovdqa ymm1, [mul_a]
    vmovdqa ymm2, [mul_b]
    vpmulld ymm0, ymm1, ymm2
    vmovdqa [out_buf], ymm0
    vzeroupper
    lea  rdi, [out_buf]
    mov  esi, 8
    call print_ivec

    ; --- 2. vpsllvd：每通道独立移位量 ---
    lea  rdi, [t2]
    xor  eax, eax
    call printf
    lea  rdi, [t2c]
    xor  eax, eax
    call printf
    vmovdqa ymm1, [sh_a]
    vmovdqa ymm2, [sh_cnt]
    vpsllvd ymm0, ymm1, ymm2         ; ymm0 = ymm1 << ymm2（逐通道）
    vmovdqa [out_buf], ymm0
    vzeroupper
    lea  rdi, [out_buf]
    mov  esi, 8
    call print_ivec

    ; --- 3. vpermd：跨 lane 置换 ---
    lea  rdi, [t3]
    xor  eax, eax
    call printf
    lea  rdi, [t3c]
    xor  eax, eax
    call printf
    lea  rdi, [t3l]
    xor  eax, eax
    call printf
    vmovdqa ymm1, [pm_idx]           ; 索引向量
    vmovdqa ymm2, [pm_src]           ; 被重排的数据
    vpermd  ymm0, ymm1, ymm2         ; ymm0 = ymm2 按 ymm1 的索引取
    vmovdqa [out_buf], ymm0
    vzeroupper
    lea  rdi, [out_buf]
    mov  esi, 8
    call print_ivec

    ; --- 4. vpbroadcastd：一个数铺满 8 通道 ---
    lea  rdi, [t4]
    xor  eax, eax
    call printf
    lea  rdi, [t4c]
    xor  eax, eax
    call printf
    vpbroadcastd ymm0, [bcast]       ; SSE 写法要 movss + shufps 两条
    vmovdqa [out_buf], ymm0
    vzeroupper
    lea  rdi, [out_buf]
    mov  esi, 8
    call print_ivec

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
