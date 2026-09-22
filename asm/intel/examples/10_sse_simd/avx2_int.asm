; ============================================================
; 文件: 10_sse_simd/avx2_int.asm                         [Windows 版]
; 指令: VPMULLD / VPSLLVD / VPERMD / VPBROADCASTD（AVX2）
; 描述: 整数运算从 128 位到 256 位 —— SSE 根本做不到的几件事
; 平台: Windows x86-64（COFF + Win64 ABI）
; 汇编: nasm -f win64 examples/10_sse_simd/avx2_int.asm -o build/avx2_int.obj
; 链接: link /subsystem:console /entry:main build/avx2_int.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
; 对照: examples-macos/10_sse_simd/avx2_int.asm ｜ examples-linux/10_sse_simd/avx2_int.asm
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
; Windows 要点：整数结果用 %d 打印，前三个参数依次走 rcx / rdx / r8；
; 用 ymm 之后照例 vzeroupper 再调 printf；
; 退场用 ExitProcess（main 是进程入口，不能用 ret）。
; 2026-09 已在 Windows 11（i7-12700F）实测：汇编、链接、运行通过，数值与 macOS 版一致。
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
.loop:
    cmp  r13d, r12d
    jge  .done
    mov  r8d, [rbx + r13*4]          ; 参数 2 = 值
    lea  rcx, [fmt_idx]
    mov  edx, r13d                   ; 参数 1 = 下标
    call printf
    inc  r13d
    jmp  .loop
.done:
    add  rsp, 40
    pop  r13
    pop  r12
    pop  rbx
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
    mov  r12d, eax                   ; main 不返回，可以随便用 r12 存位图

    lea  rcx, [hdr]
    call printf

    mov  eax, r12d
    and  eax, 10                     ; bit1(AVX2) + bit3(OS 放开 YMM) = 0b1010
    cmp  eax, 10
    je   .avx2_ok
    lea  rcx, [t_skip]
    call printf
    jmp  .finish

.avx2_ok:
    ; --- 1. vpmulld：8 路 32 位乘 ---
    lea  rcx, [t1]
    call printf
    lea  rcx, [t1c]
    call printf
    vmovdqa ymm1, [mul_a]
    vmovdqa ymm2, [mul_b]
    vpmulld ymm0, ymm1, ymm2
    vmovdqa [out_buf], ymm0
    vzeroupper
    lea  rcx, [out_buf]
    mov  edx, 8
    call print_ivec

    ; --- 2. vpsllvd：每通道独立移位量 ---
    lea  rcx, [t2]
    call printf
    lea  rcx, [t2c]
    call printf
    vmovdqa ymm1, [sh_a]
    vmovdqa ymm2, [sh_cnt]
    vpsllvd ymm0, ymm1, ymm2         ; ymm0 = ymm1 << ymm2（逐通道）
    vmovdqa [out_buf], ymm0
    vzeroupper
    lea  rcx, [out_buf]
    mov  edx, 8
    call print_ivec

    ; --- 3. vpermd：跨 lane 置换 ---
    lea  rcx, [t3]
    call printf
    lea  rcx, [t3c]
    call printf
    lea  rcx, [t3l]
    call printf
    vmovdqa ymm1, [pm_idx]           ; 索引向量
    vmovdqa ymm2, [pm_src]           ; 被重排的数据
    vpermd  ymm0, ymm1, ymm2         ; ymm0 = ymm2 按 ymm1 的索引取
    vmovdqa [out_buf], ymm0
    vzeroupper
    lea  rcx, [out_buf]
    mov  edx, 8
    call print_ivec

    ; --- 4. vpbroadcastd：一个数铺满 8 通道 ---
    lea  rcx, [t4]
    call printf
    lea  rcx, [t4c]
    call printf
    vpbroadcastd ymm0, [bcast]       ; SSE 写法要 movss + shufps 两条
    vmovdqa [out_buf], ymm0
    vzeroupper
    lea  rcx, [out_buf]
    mov  edx, 8
    call print_ivec

.finish:
    lea  rcx, [fmt_done]
    call printf

    xor  ecx, ecx
    call ExitProcess
