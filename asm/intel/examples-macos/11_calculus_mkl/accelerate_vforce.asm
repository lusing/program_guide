; ============================================================
; 文件: 11_calculus_mkl/accelerate_vforce.asm              [macOS 版]
; 指令: —（调用 Accelerate 的 vForce / vDSP 向量数学库）
; 描述: 从汇编调用 macOS 上的厂商数学库 —— MKL VML 的对应物
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/11_calculus_mkl/accelerate_vforce.asm -o build/accelerate_vforce.o
; 链接: clang -arch x86_64 build/accelerate_vforce.o -o build/accelerate_vforce -framework Accelerate
; 对照: examples/11_calculus_mkl/mkl_vml_math.asm
;
; LINK: -framework Accelerate
;
; ------------------------------------------------------------
; Windows 那边调的是 Intel MKL 的 VML（Vector Math Library）：
;     void vsSin(const int n, const float* a, float* y)
;          RCX = n，RDX = 输入，R8 = 输出
;
; macOS 上的对应物是 **Accelerate.framework 里的 vForce**：
;     void vvsinf(float *y, const float *x, const int *n)
;          RDI = 输出，RSI = 输入，RDX = 指向 n 的指针
;
; 三个坑一定要看清：
;   1. **参数顺序反过来了**。MKL 是 (n, 输入, 输出)，
;      vForce 是 (输出, 输入, &n) —— 输出在前。
;   2. **n 是按指针传的**（`const int *n`），所以要 `lea rdx,[n]`，
;      不能像 MKL 那样直接 `mov edx, n`。
;   3. 单精度函数统一是 `vv` 前缀（vector-vector）：
;      vvsinf / vvcosf / vvexpf / vvlogf / vvpowf / vvsincosf …
;      末尾的 f 表示 float（不带 f 的是 double 版本）。
;
; 调用约定上还有个「同门不同命」的例子：vForce 的 n 是 `const int *`，
; 而 vDSP 的 vDSP_maxv 是 `vDSP_Length`（就是 unsigned long，按值传）。
; 同一个框架里两种风格并存，只能逐个查头文件 —— 这一点两平台都一样。
;
; 例题做的事：
;   1. 用 vForce 一次算出 1024 个点的 sin / cos / exp
;   2. 用 SSE 手工验证恒等式 sin²x + cos²x = 1 的最大偏差
;   3. 用 vDSP_maxv 求 exp 结果的最大值（对比「按值传 n」的写法）
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
    nval      dd N                      ; vForce 要的是 &nval

    fmt_hdr    db "=== Accelerate vForce / vDSP 批量数学 ===", 10, 0
    fmt_step   db "采样点数 N = %d，区间 [0, 2π)", 10, 0
    fmt_sin    db "vvsinf: x = %.4f  ->  %f", 10, 0
    fmt_cos    db "vvcosf: x = %.4f  ->  %f", 10, 0
    fmt_exp    db "vvexpf: x = %.4f  ->  %f", 10, 0
    fmt_ident  db "sin²+cos²-1 的最大偏差（SSE 手工扫描）： %.9f", 10, 0
    fmt_maxexp db "vDSP_maxv(exp 结果) = %f", 10, 0
    fmt_sig    db "签名对比：MKL vsSin(n,in,out) | vForce vvsinf(out,in,&n) | vDSP vDSP_maxv(in,stride,out,n)", 10, 0
    fmt_done   db "Accelerate vForce demo completed.", 10, 0

section .bss
    alignb 16
    x_arr   resd N
    y_sin   resd N
    y_cos   resd N
    y_exp   resd N
    f_max   resd 4

section .text
    global _main
    extern _printf
    extern _vvsinf
    extern _vvcosf
    extern _vvexpf
    extern _vDSP_maxv

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rbx                    ; rbx = 数组基址

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
    ; 2. 三次 vForce 调用 —— 每次都是「给一个数组，整批算完」
    ;    注意参数是 (输出, 输入, &n)，和 MKL 的 (n, 输入, 输出) 正好不同
    ; --------------------------------------------------------
    lea rdi, [y_sin]
    lea rsi, [x_arr]
    lea rdx, [nval]
    call _vvsinf

    lea rdi, [y_cos]
    lea rsi, [x_arr]
    lea rdx, [nval]
    call _vvcosf

    lea rdi, [y_exp]
    lea rsi, [x_arr]
    lea rdx, [nval]
    call _vvexpf

    lea rdi, [fmt_hdr]
    xor eax, eax
    call _printf

    lea rdi, [fmt_step]
    mov esi, N
    xor eax, eax
    call _printf

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
    call _printf

    movss xmm0, [x_arr + 128*4]
    cvtss2sd xmm0, xmm0
    movss xmm1, [y_cos + 128*4]
    cvtss2sd xmm1, xmm1
    lea rdi, [fmt_cos]
    mov eax, 2
    call _printf

    movss xmm0, [x_arr + 256*4]
    cvtss2sd xmm0, xmm0
    movss xmm1, [y_exp + 256*4]
    cvtss2sd xmm1, xmm1
    lea rdi, [fmt_exp]
    mov eax, 2
    call _printf

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
    call _printf

    ; --------------------------------------------------------
    ; 5. vDSP 求最大值 —— 顺带看清「参数顺序」能有多离谱
    ;    void vDSP_maxv(const float *A, vDSP_Stride IA,
    ;                   float *C, vDSP_Length N)
    ;        四个参数：输入、步长、输出、长度。
    ;    注意它既不是 MKL 的 (n, in, out)，也不是 vForce 的 (out, in, &n)，
    ;    而是 (in, stride, out, n) —— 输出被夹在第三个。
    ;    vDSP_Stride 是 long（按值传 64 位），vDSP_Length 是 unsigned long。
    ; --------------------------------------------------------
    lea rdi, [y_exp]                    ; A：输入数组
    mov esi, 1                          ; IA：步长 1（逐个取）
    lea rdx, [f_max]                    ; C：结果存放处
    mov ecx, N                          ; N：元素个数
    call _vDSP_maxv

    movss xmm0, [f_max]
    cvtss2sd xmm0, xmm0
    lea rdi, [fmt_maxexp]
    mov eax, 1
    call _printf

    lea rdi, [fmt_sig]
    xor eax, eax
    call _printf

    lea rdi, [fmt_done]
    xor eax, eax
    call _printf

    mov rbx, [rbp-8]
    mov r12, [rbp-16]
    xor eax, eax
    leave
    ret
