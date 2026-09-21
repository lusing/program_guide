; ============================================================
; 文件: 11_calculus_mkl/accelerate_vforce.asm              [Linux 版]
; 指令: —（调用 glibc libmvec 的向量数学函数）
; 描述: 从汇编调用 Linux 上的厂商数学库 —— MKL VML 的对应物
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/11_calculus_mkl/accelerate_vforce.asm -o build/accelerate_vforce.o
; 链接: gcc -no-pie build/accelerate_vforce.o -o build/accelerate_vforce -lm -lmvec
; 对照: examples/11_calculus_mkl/mkl_vml_math.asm（Windows 版）
;
; LINK: -lm -lmvec
;
; ------------------------------------------------------------
; 同一个「批量算 sin/cos/exp」的需求，三个平台的解法完全不同：
;
;   Windows：Intel MKL 的 VML（Vector Math Library）
;       void vsSin(const int n, const float* a, float* y)
;            RCX = n，RDX = 输入，R8 = 输出     —— 整批算完，n 按值传
;
;   macOS  ：Accelerate.framework 里的 vForce
;       void vvsinf(float *y, const float *x, const int *n)
;            RDI = 输出，RSI = 输入，RDX = 指向 n 的指针 —— 整批算完，n 按指针传
;
;   Linux  ：glibc 的 libmvec（glibc ≥ 2.22，随 libm 一起发布）
;       void _ZGVbN4v_sinf(...)  —— 不传指针：**4 个 float 打包进 xmm0
;            传进去，算好的 4 个结果同样在 xmm0 里回来**
;
; libmvec 的四个坑一定要看清：
;   1. **没有 n 参数，一次只处理一个向量寄存器（SSE 版 = 4 个 float）**。
;      想算 1024 个点的数组，必须在汇编里自己写循环：
;      每次 `movups xmm0,[x]` → call → `movups [y],xmm0`，指针步进 16 字节。
;   2. **函数名是改编（mangled）的**：_ZGV<isa>N<lanes><参数串>_<函数名>
;        isa   ：b = SSE4 基线（N4），d = AVX2（N8），e = AVX-512（N16）
;        参数串：v = 一个按值传递的向量参数（走 xmm0/ymm0/zmm0）
;      所以 SSE 版叫 _ZGVbN4v_sinf，AVX2 版叫 _ZGVdN8v_sinf。
;      本指南的 SIMD 章节用 SSE，这里就固定调 _ZGVbN4v_*（哪台 x86-64 都能跑）。
;   3. **输入输出都在 xmm0**。和 MKL/vForce 传三个指针完全不同，
;      返回值不占参数位置（函数名参数串里只有输入的 v）。
;   4. **要显式链接 -lmvec**（光 -lm 不一定带得上来；libmvec 是独立库）。
;
; 至于「求数组最大值」（macOS 那边用 vDSP_maxv），libmvec 没有归约类
; 函数 —— 就用本例第 4 节那段 SSE 手工循环，4 路并行照样扫完全部 1024 个。
;
; 例题做的事：
;   1. 用 libmvec 循环算出 1024 个点的 sin / cos / exp
;   2. 用 SSE 手工验证恒等式 sin²x + cos²x = 1 的最大偏差
;   3. 用 SSE 手工归约求 exp 结果的最大值（vDSP_maxv 的替代品）
; ============================================================
default rel

%define N 1024

section .data
    ; 16 字节对齐区：andps / maxps / subps 的内存操作数都必须是 16 的整数倍
    align 16
    f_ones    dd 1.0, 1.0, 1.0, 1.0
    f_absmask dd 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF

    align 4
    f_step    dd 0.0061359232           ; 2π / 1024

    fmt_hdr    db "=== glibc libmvec 批量数学（_ZGVbN4v_*）===", 10, 0
    fmt_step   db "采样点数 N = %d，区间 [0, 2π)，每次 call 处理 xmm0 里的 4 个", 10, 0
    fmt_sin    db "_ZGVbN4v_sinf: x = %.4f  ->  %f", 10, 0
    fmt_cos    db "_ZGVbN4v_cosf: x = %.4f  ->  %f", 10, 0
    fmt_exp    db "_ZGVbN4v_expf: x = %.4f  ->  %f", 10, 0
    fmt_ident  db "sin²+cos²-1 的最大偏差（SSE 手工扫描）： %.9f", 10, 0
    fmt_maxexp db "SSE 手工归约 max(exp 结果) = %f", 10, 0
    fmt_sig    db "签名对比：MKL vsSin(n,in,out) | vForce vvsinf(out,in,&n) | libmvec _ZGVbN4v_sinf xmm0→xmm0", 10, 0
    fmt_done   db "libmvec demo completed.", 10, 0

section .bss
    alignb 16
    x_arr   resd N
    y_sin   resd N
    y_cos   resd N
    y_exp   resd N

section .text
    global main
    extern printf
    extern _ZGVbN4v_sinf
    extern _ZGVbN4v_cosf
    extern _ZGVbN4v_expf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8], rbx                    ; rbx = x_arr 基址
    mov [rbp-16], r12                   ; r12 = 输出数组基址
    mov [rbp-24], r13                   ; r13 = 循环计数器

    ; --------------------------------------------------------
    ; 1. 先把 x[i] = i * (2π/N) 填好
    ;    用标量 SSE：cvtsi2ss 把下标转成 float，乘步长，存回数组
    ;    （带下标的寻址不能用 RIP 相对，所以先用 lea 把基址装进 rbx）
    ; --------------------------------------------------------
    lea rbx, [x_arr]
    xor ecx, ecx
.fill_x:
    cvtsi2ss xmm0, ecx
    mulss xmm0, [f_step]
    movss [rbx + rcx*4], xmm0
    inc ecx
    cmp ecx, N
    jb .fill_x

    ; --------------------------------------------------------
    ; 2. 三组 libmvec 循环 —— 每次 call 只算 xmm0 里的 4 个：
    ;      movups 装入 4 个输入 → call → movups 存回 4 个结果
    ;    循环计数器必须用被调用者保存寄存器（r13）：
    ;    libmvec 函数会把 rcx 等调用者保存寄存器全部踩掉
    ; --------------------------------------------------------
    lea rbx, [x_arr]
    lea r12, [y_sin]
    xor r13d, r13d
.vloop_sin:
    movups xmm0, [rbx + r13*4]          ; 4 个输入装进 xmm0
    call _ZGVbN4v_sinf                  ; 结果同样在 xmm0 里
    movups [r12 + r13*4], xmm0
    add r13d, 4
    cmp r13d, N
    jb .vloop_sin

    lea r12, [y_cos]
    xor r13d, r13d
.vloop_cos:
    movups xmm0, [rbx + r13*4]
    call _ZGVbN4v_cosf
    movups [r12 + r13*4], xmm0
    add r13d, 4
    cmp r13d, N
    jb .vloop_cos

    lea r12, [y_exp]
    xor r13d, r13d
.vloop_exp:
    movups xmm0, [rbx + r13*4]
    call _ZGVbN4v_expf
    movups [r12 + r13*4], xmm0
    add r13d, 4
    cmp r13d, N
    jb .vloop_exp

    lea rdi, [fmt_hdr]
    xor eax, eax
    call printf

    lea rdi, [fmt_step]
    mov esi, N
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; 3. 抽查三个点：x[128] = π/2，x[256] = π
    ;    %f 的值按顺序放 xmm0、xmm1…，eax 记「用了几个」
    ; --------------------------------------------------------
    movss xmm0, [x_arr + 128*4]         ; 第 1 个浮点参数：x
    cvtss2sd xmm0, xmm0
    movss xmm1, [y_sin + 128*4]         ; 第 2 个浮点参数：sin(x)
    cvtss2sd xmm1, xmm1
    lea rdi, [fmt_sin]
    mov eax, 2
    call printf

    movss xmm0, [x_arr + 128*4]
    cvtss2sd xmm0, xmm0
    movss xmm1, [y_cos + 128*4]
    cvtss2sd xmm1, xmm1
    lea rdi, [fmt_cos]
    mov eax, 2
    call printf

    movss xmm0, [x_arr + 256*4]
    cvtss2sd xmm0, xmm0
    movss xmm1, [y_exp + 256*4]
    cvtss2sd xmm1, xmm1
    lea rdi, [fmt_exp]
    mov eax, 2
    call printf

    ; --------------------------------------------------------
    ; 4. 手工 SIMD 验证 sin²+cos²=1：4 路并行求最大偏差
    ;    maxps 顺着跑累积最大值，最后再做水平归约
    ; --------------------------------------------------------
    movaps xmm5, [f_absmask]            ; 提前装好掩码，省得每轮读内存
    pxor xmm3, xmm3                     ; xmm3 = 最大偏差，初值 0
    lea rbx, [y_sin]
    lea r12, [y_cos]
    xor ecx, ecx
.chk:
    movups xmm0, [rbx + rcx*4]          ; sin
    movups xmm1, [r12 + rcx*4]          ; cos
    mulps xmm0, xmm0                    ; sin²
    mulps xmm1, xmm1                    ; cos²
    addps xmm0, xmm1                    ; sin² + cos²
    subps xmm0, [f_ones]                ; 减 1 就是偏差
    andps xmm0, xmm5                    ; 取绝对值（清符号位）
    maxps xmm3, xmm0                    ; 累积最大值
    add ecx, 4
    cmp ecx, N
    jb .chk

    ; 水平归约：把 4 条通道的最大值压成 1 个
    movaps xmm1, xmm3
    shufps xmm1, xmm1, 0x4E             ; [2,3,0,1]：交换两个 64 位半
    maxps  xmm3, xmm1
    movaps xmm1, xmm3
    shufps xmm1, xmm1, 0xB1             ; [1,0,3,2]：交换相邻两格
    maxps  xmm3, xmm1

    movss xmm0, xmm3
    cvtss2sd xmm0, xmm0
    lea rdi, [fmt_ident]
    mov eax, 1
    call printf

    ; --------------------------------------------------------
    ; 5. SSE 手工归约求 exp 最大值（macOS 版这里调 vDSP_maxv，
    ;    libmvec 没有归约函数，正好把第 4 节的归约套路再用一遍）
    ; --------------------------------------------------------
    pxor xmm3, xmm3
    lea rbx, [y_exp]
    xor ecx, ecx
.maxv:
    movups xmm0, [rbx + rcx*4]
    maxps xmm3, xmm0
    add ecx, 4
    cmp ecx, N
    jb .maxv

    movaps xmm1, xmm3
    shufps xmm1, xmm1, 0x4E
    maxps  xmm3, xmm1
    movaps xmm1, xmm3
    shufps xmm1, xmm1, 0xB1
    maxps  xmm3, xmm1

    movss xmm0, xmm3
    cvtss2sd xmm0, xmm0
    lea rdi, [fmt_maxexp]
    mov eax, 1
    call printf

    lea rdi, [fmt_sig]
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
