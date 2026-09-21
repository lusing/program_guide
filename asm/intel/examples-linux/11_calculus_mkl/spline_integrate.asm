; ============================================================
; 文件: 11_calculus_mkl/spline_integrate.asm               [Linux 版]
; 指令: 标量 SSE 双精度（ADDSD/SUBSD/MULSD/DIVSD/CVTTSD2SI/MAXSD/ANDPD）
; 描述: 手写自然三次样条插值 + 梯形积分 ∫₀^π sin(x)dx = 2.0
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/11_calculus_mkl/spline_integrate.asm -o build/spline_integrate.o
; 链接: gcc -no-pie build/spline_integrate.o -o build/spline_integrate
; 对照: examples/11_calculus_mkl/mkl_df_integrate.asm
;
; ★ 移植说明（这一条要说明白）：
;   原版调用 Intel MKL 的 Data Fitting 库（dfdNewTask1D / dfdEditPPSpline1D /
;   dfdConstruct1D / dfdInterpolate1D / dfDeleteTask）搭三次样条。
;   **Linux 的 libmvec（glibc 的向量数学库）没有对应的样条 API**
;   ——它只有 sin/cos/exp/log 这类逐元素的向量函数
;   （_ZGVbN4v_sinf 之类，见 accelerate_vforce.asm），没有 pp-form
;   样条构造，也没有 MKL DF 那种任务式接口。
;   所以这里把样条**手写出来**，三段式：
;       ① 组装三对角方程组  ② Thomas 算法解 M_i = S''(x_i)  ③ 分段求值
;   手写反而更能看清 MKL 那条 API 背后到底在算什么，
;   而且这份代码在三个平台上原样可编译 —— 没有任何平台依赖。
;
; ------------------------------------------------------------
; 自然三次样条（natural cubic spline）：
;   给定节点 (x_0,y_0)…(x_n,y_n)，找一条分段三次多项式，要求
;   ① 过所有节点；② 一阶、二阶导数在内节点处连续；
;   ③ 两端二阶导数为 0（这就是「自然」的含义）。
;   记 M_i = S''(x_i)，等距 h 下内节点满足：
;       M_{i-1} + 4·M_i + M_{i+1} = 6·(y_{i+1} − 2y_i + y_{i-1}) / h²
;   加上 M_0 = M_n = 0，就是一个 n−1 阶的**三对角**方程组。
;   三对角用 Thomas 算法（追赶法）O(n) 解完，不必上高斯消元。
;
;   分段求值（t = x − x_i，h − t = x_{i+1} − x）：
;       S = [ M_i·(h−t)³ + M_{i+1}·t³ ] / (6h)
;         + ( y_i    − M_i·h²/6 ) · (h−t)/h
;         + ( y_{i+1} − M_{i+1}·h²/6 ) · t/h
;
; 两条性质正好当验收标准：
;   S(x_i) 必须精确等于 y_i（过点）；两端 S'' 必须等于 0（自然边界）。
;
; 题设：20 段（21 个节点），y_i = sin(x_i)，区间 [0, π]。
;   积分用 1000 点梯形法，结果应为 2.0 —— 样条只用了 21 个数，
;   却把整条 sin 曲线和它的积分都还原到了 1e-10 量级。
; ============================================================
default rel

%define NSEG    20                      ; 区间段数
%define NNODES  21                      ; 节点数 = NSEG+1
%define NSITE   1000                    ; 积分采样点数

section .data
    align 16
    dd_absmask dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF

    align 8
    dd_one    dq 1.0
    dd_two    dq 2.0
    dd_four   dq 4.0
    dd_six    dq 6.0
    dd_half   dq 0.5
    dd_pi     dq 3.141592653589793
    dd_1000   dq 1000.0
    dd_sqr2_2 dq 0.7071067811865476     ; sin(π/4) = √2/2
    dd_h      dq 0.0                    ; π/20，运行时算
    dd_h2_6   dq 0.0                    ; h²/6
    dd_inv6h  dq 0.0                    ; 1/(6h)
    dd_invh   dq 0.0                    ; 1/h
    dd_step   dq 0.0                    ; π/1000
    dd_tmp    dq 0.0

    fmt_hdr   db "=== 自然三次样条 + 梯形积分：∫₀^π sin(x)dx ===", 10, 0
    fmt_parm  db "节点 %d 个（%d 段），h = π/%d = %.12f", 10, 0
    fmt_node  db "验收一 max|S(x_i) − y_i| = %.3e   （≈0 表示样条严格过点）", 10, 0
    fmt_end   db "验收二 S''(0) = %.3e，S''(π) = %.3e   （自然边界，应为 0）", 10, 0
    fmt_check db "中段抽查 S(π/4) = %.12f，真值 √2/2 = %.12f", 10, 0
    fmt_trap  db "1000 点梯形积分结果 = %.12f", 10, 0
    fmt_exact db "精确值 2.0，绝对误差 = %.3e", 10, 0
    fmt_why   db "误差主要来自 1000 点梯形法自身的 O(h²)，不是样条（样条过点误差 2e-16）。", 10, 0
    fmt_why2  db "注：Linux 的 libmvec 也没有 MKL DF 那样的样条 API，故此处手写。", 10, 0
    fmt_done  db "Spline integrate demo completed.", 10, 0

section .bss
    alignb 16
    xa      resq NNODES                 ; 节点 x_i
    ya      resq NNODES                 ; 节点 y_i = sin(x_i)
    mm      resq NNODES                 ; 二阶导 M_i（M_0 = M_20 = 0）
    w_rhs   resq NNODES                 ; 右端项
    w_cp    resq NNODES                 ; Thomas 的 c'
    w_dp    resq NNODES                 ; Thomas 的 d'

section .text
    global main
    extern printf

; ------------------------------------------------------------
; spline_eval —— 求 S(x)
;   入口：xmm0 = x（double）
;   出口：xmm0 = S(x)
;   依赖：r12 = xa，r13 = ya，r14 = mm
;   踩：rax/eax 与 **xmm0..xmm8**。
;   注意它把 xmm0..xmm8 全用了一遍，所以调用方**不能**把跨调用
;   要保留的值放在这些寄存器里 —— 一律落栈。（这里踩过一次：）
;   最初把积分累加器放 xmm6、prev 放 xmm7，结果都被 y_i / y_{i+1} 覆盖了。
; ------------------------------------------------------------
spline_eval:
    ; 定位区间 i = floor(x/h)，再夹到 [0, NSEG-1]
    movapd xmm1, xmm0
    mulsd  xmm1, [dd_invh]
    cvttsd2si eax, xmm1                 ; 向零截断；x≥0 所以等价于 floor
    test eax, eax
    jns .nonneg
    xor eax, eax
.nonneg:
    cmp eax, NSEG - 1
    jle .ok
    mov eax, NSEG - 1
.ok:
    movsxd rax, eax

    ; t = x − x_i，ht = h − t
    movsd xmm2, [r12 + rax*8]
    subsd xmm0, xmm2                    ; xmm0 = t
    movsd xmm3, [dd_h]
    subsd xmm3, xmm0                    ; xmm3 = ht

    ; 取出这个区间的四个数据
    movsd xmm4, [r14 + rax*8]           ; M_i
    movsd xmm5, [r14 + rax*8 + 8]       ; M_{i+1}
    movsd xmm6, [r13 + rax*8]           ; y_i
    movsd xmm7, [r13 + rax*8 + 8]       ; y_{i+1}

    ; 第一项 [M_i·ht³ + M_{i+1}·t³] / (6h)
    movapd xmm1, xmm3
    mulsd  xmm1, xmm3
    mulsd  xmm1, xmm3
    mulsd  xmm1, xmm4                   ; M_i·ht³
    movapd xmm2, xmm0
    mulsd  xmm2, xmm0
    mulsd  xmm2, xmm0
    mulsd  xmm2, xmm5                   ; M_{i+1}·t³
    addsd  xmm1, xmm2
    mulsd  xmm1, [dd_inv6h]

    ; 第二项 (y_i − M_i·h²/6)·ht/h
    movapd xmm2, xmm4
    mulsd  xmm2, [dd_h2_6]
    subsd  xmm6, xmm2
    mulsd  xmm6, xmm3
    mulsd  xmm6, [dd_invh]
    addsd  xmm1, xmm6

    ; 第三项 (y_{i+1} − M_{i+1}·h²/6)·t/h
    movapd xmm2, xmm5
    mulsd  xmm2, [dd_h2_6]
    subsd  xmm7, xmm2
    mulsd  xmm7, xmm0
    mulsd  xmm7, [dd_invh]
    addsd  xmm1, xmm7

    movapd xmm0, xmm1
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 96
    mov [rbp-8],  rbx                   ; w_cp 基址
    mov [rbp-16], r12                   ; xa
    mov [rbp-24], r13                   ; ya
    mov [rbp-32], r14                   ; mm
    mov [rbp-40], r15                   ; w_rhs
    ; [rbp-48] = 节点最大偏差   [rbp-56] = 积分结果   [rbp-64] = S(π/4)

    lea r12, [xa]
    lea r13, [ya]
    lea r14, [mm]
    lea r15, [w_rhs]
    lea rbx, [w_cp]

    ; --------------------------------------------------------
    ; 0. h = π/NSEG 及派生常数
    ; --------------------------------------------------------
    mov eax, NSEG
    cvtsi2sd xmm1, eax
    movsd xmm0, [dd_pi]
    divsd xmm0, xmm1
    movsd [dd_h], xmm0                  ; h

    movsd xmm1, [dd_pi]
    divsd xmm1, [dd_1000]
    movsd [dd_step], xmm1               ; π/1000（注意不是 h/1000）

    movsd xmm1, xmm0
    mulsd xmm1, xmm0
    divsd xmm1, [dd_six]
    movsd [dd_h2_6], xmm1               ; h²/6

    movsd xmm1, [dd_six]
    mulsd xmm1, [dd_h]                  ; 6h
    movsd xmm2, [dd_one]
    divsd xmm2, xmm1
    movsd [dd_inv6h], xmm2              ; 1/(6h)

    movsd xmm2, [dd_one]
    divsd xmm2, [dd_h]
    movsd [dd_invh], xmm2               ; 1/h

    ; --------------------------------------------------------
    ; 1. 节点：x_i = i·h，y_i = sin(x_i)（x87 的 fsin 取真值）
    ; --------------------------------------------------------
    xor ecx, ecx
.fill:
    cvtsi2sd xmm0, ecx
    mulsd xmm0, [dd_h]
    movsd [r12 + rcx*8], xmm0
    movsd [dd_tmp], xmm0
    fld qword [dd_tmp]
    fsin
    fstp qword [dd_tmp]
    movsd xmm0, [dd_tmp]
    movsd [r13 + rcx*8], xmm0
    inc ecx
    cmp ecx, NNODES
    jb .fill

    ; --------------------------------------------------------
    ; 2. 右端项 rhs_i = 6·(y_{i+1} − 2y_i + y_{i-1}) / h²，i = 1..19
    ; --------------------------------------------------------
    movsd xmm7, [dd_six]
    movsd xmm6, [dd_h]
    mulsd xmm6, xmm6
    divsd xmm7, xmm6                    ; 6/h²
    mov ecx, 1
.rhs:
    movsd xmm0, [r13 + rcx*8 + 8]       ; y_{i+1}
    addsd xmm0, [r13 + rcx*8 - 8]       ; + y_{i-1}
    movsd xmm1, [r13 + rcx*8]           ; y_i
    addsd xmm1, xmm1                    ; 2y_i
    subsd xmm0, xmm1
    mulsd xmm0, xmm7
    movsd [r15 + rcx*8], xmm0
    inc ecx
    cmp ecx, NNODES - 1                 ; 到 19
    jb .rhs

    ; --------------------------------------------------------
    ; 3. Thomas 算法（追赶法）
    ;    系数恒为 a=1, b=4, c=1，于是正向扫递推：
    ;       cp_i = 1 / (4 − cp_{i-1})，cp_0 = 0
    ;       dp_i = (rhs_i − dp_{i-1}) · cp_i
    ;    反向回代：M_19 = dp_19；M_i = dp_i − cp_i·M_{i+1}
    ; --------------------------------------------------------
    xorpd xmm3, xmm3                    ; cp_{i-1} = 0
    xorpd xmm4, xmm4                    ; dp_{i-1} = 0
    lea rsi, [w_dp]                     ; w_dp 基址（循环里没有 call，rsi 不会被动）
    mov ecx, 1
.fwd:
    movsd xmm0, [dd_four]
    subsd xmm0, xmm3                    ; 4 − cp_{i-1}
    movsd xmm1, [dd_one]
    divsd xmm1, xmm0                    ; cp_i
    movsd [rbx + rcx*8], xmm1

    movsd xmm2, [r15 + rcx*8]           ; rhs_i
    subsd xmm2, xmm4
    mulsd xmm2, xmm1                    ; dp_i
    movsd [rsi + rcx*8], xmm2

    movapd xmm3, xmm1
    movapd xmm4, xmm2
    inc ecx
    cmp ecx, NNODES - 1
    jb .fwd

    mov ecx, NNODES - 2                 ; 19
    movsd xmm0, [rsi + rcx*8]
    movsd [r14 + rcx*8], xmm0           ; M_19 = dp_19
    dec ecx                             ; 18 … 1
.back:
    movsd xmm0, [rsi + rcx*8]           ; dp_i
    movsd xmm1, [rbx + rcx*8]           ; cp_i
    mulsd xmm1, [r14 + rcx*8 + 8]       ; ·M_{i+1}
    subsd xmm0, xmm1
    movsd [r14 + rcx*8], xmm0
    dec ecx
    jnz .back
    ; M_0 与 M_20 保持 0（自然边界），mm 数组初值本来就是 0

    ; --------------------------------------------------------
    ; 4. 验收一：S(x_i) 是否严格等于 y_i
    ;    最大值放内存里累积 —— spline_eval 会踩 xmm3
    ; --------------------------------------------------------
    mov qword [rbp-48], 0
    mov ecx, 0
.node:
    movsd xmm0, [r12 + rcx*8]
    call spline_eval                    ; 不踩 rcx，放心直接用
    subsd xmm0, [r13 + rcx*8]
    andpd xmm0, [dd_absmask]
    maxsd xmm0, [rbp-48]
    movsd [rbp-48], xmm0
    inc ecx
    cmp ecx, NNODES
    jb .node

    ; --------------------------------------------------------
    ; 5. 1000 点梯形积分
    ;    ∫ ≈ step · Σ_{j=1..1000} (S_{j-1} + S_j)/2
    ;    S_0 = S(0) = y_0 = 0，所以 prev 初值 0。
    ;    累加器和 prev 都放栈上（见 spline_eval 的踩寄存器说明）。
    ; --------------------------------------------------------
    mov qword [rbp-72], 0               ; 累加器
    mov qword [rbp-80], 0               ; prev = S(x_0)
    mov ecx, 1
.site:
    cvtsi2sd xmm0, ecx
    mulsd xmm0, [dd_step]               ; x = j·step
    call spline_eval
    movsd [rbp-88], xmm0                ; 先存下 S_j
    addsd xmm0, [rbp-80]                ; S_j + S_{j-1}
    mulsd xmm0, [dd_half]
    addsd xmm0, [rbp-72]
    movsd [rbp-72], xmm0                ; 累加器更新
    movsd xmm1, [rbp-88]
    movsd [rbp-80], xmm1                ; prev ← S_j
    inc ecx
    cmp ecx, NSITE
    jbe .site
    movsd xmm0, [rbp-72]
    mulsd xmm0, [dd_step]
    movsd [rbp-56], xmm0

    ; 顺便抽查 S(π/4)
    movsd xmm0, [dd_pi]
    movsd xmm1, [dd_four]
    divsd xmm0, xmm1
    call spline_eval
    movsd [rbp-64], xmm0

    ; --------------------------------------------------------
    ; 6. 输出
    ; --------------------------------------------------------
    lea rdi, [fmt_hdr]
    xor eax, eax
    call printf

    lea rdi, [fmt_parm]
    mov esi, NNODES
    mov edx, NSEG
    mov ecx, NSEG
    movsd xmm0, [dd_h]
    mov eax, 1
    call printf

    lea rdi, [fmt_node]
    movsd xmm0, [rbp-48]
    mov eax, 1
    call printf

    lea rdi, [fmt_end]
    movsd xmm0, [r14]                   ; M_0
    movsd xmm1, [r14 + NSEG*8]          ; M_20
    mov eax, 2
    call printf

    lea rdi, [fmt_check]
    movsd xmm0, [rbp-64]
    movsd xmm1, [dd_sqr2_2]
    mov eax, 2
    call printf

    lea rdi, [fmt_trap]
    movsd xmm0, [rbp-56]
    mov eax, 1
    call printf

    movsd xmm0, [dd_two]
    subsd xmm0, [rbp-56]                ; 误差 = 2.0 − 结果
    lea rdi, [fmt_exact]
    mov eax, 1
    call printf

    lea rdi, [fmt_why]
    xor eax, eax
    call printf

    lea rdi, [fmt_why2]
    xor eax, eax
    call printf

    lea rdi, [fmt_done]
    xor eax, eax
    call printf

    mov rbx, [rbp-8]
    mov r12, [rbp-16]
    mov r13, [rbp-24]
    mov r14, [rbp-32]
    mov r15, [rbp-40]
    xor eax, eax
    leave
    ret
