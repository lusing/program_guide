; ============================================================
; 文件: 10_sse_simd/sse_convert.asm                        [Linux 版]
; 指令: CVTSI2SS / CVTSI2SD / CVTSS2SI / CVTTSS2SI / CVTSS2SD / CVTSD2SS
; 描述: 类型转换 —— 整数、float、double 之间怎么互相搬家
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/10_sse_simd/sse_convert.asm -o build/sse_convert.o
; 链接: gcc -no-pie build/sse_convert.o -o build/sse_convert
; 对照: examples/10_sse_simd/sse_convert.asm
;
; ------------------------------------------------------------
; 助记符的构词法：cvt（convert）+ 源类型 + 2（to）+ 目的类型
;   si = signed integer（l 后缀表示 64 位）   ss = scalar single
;   sd = scalar double
; 于是：
;   cvtsi2ss  xmm0, eax    int32  -> float
;   cvtsi2sd  xmm0, rax    int64  -> double
;   cvtss2si  eax,  xmm0   float  -> int（按 MXCSR 的舍入模式）
;   cvttss2si eax,  xmm0   float  -> int（**t = truncate，向零截断**）
;   cvtss2sd / cvtsd2ss    float <-> double
;
; 最容易搞混的就是 cvtss2si 和 cvttss2si：
;   3.7 走 cvtsi2si  -> 4（默认就近舍入，偶数优先）
;   3.7 走 cvttss2si -> 3（无条件朝零砍）
; 而「-3.7」在两条指令下分别是 -4 和 -3，别把负数的结果想当然。
;
; 另外注意 cvtsi2ss/cvtsi2sd 会**保留 xmm 的高位**（只有低 32/64 位被写）。
; 这在跨指令复用时是个隐蔽的依赖源，现代编译器会特意插 vxorps 打破它。
; 浮点转整数若超出目标位宽会得到 0x80000000（整数不定值），这也是
; 为什么编译器在这一步之后通常紧跟一条分支做范围检查。
;
; ------------------------------------------------------------
; Linux 传参：`%f` 的值放 xmm0；`%d` 的值放 esi。两条都很直接。
; ============================================================
default rel

section .data
    align 4
    int32_val  dd 42
    float_val  dd 3.7                   ; 拿来演示「舍入 vs 截断」
    align 8
    int64_val  dq 1000000
    double_val dq 2.718281828459045
    align 4
    fpi_val    dd 3.14
    align 8
    temp_d     dq 0.0
    temp_i     dd 0

    fmt_i2ss    db "cvtsi2ss:  int32  42        -> float  %f", 10, 0
    fmt_i2sd    db "cvtsi2sd:  int64  1000000   -> double %f", 10, 0
    fmt_ss2si   db "cvtss2si:  float  3.7       -> int    %d  （就近舍入）", 10, 0
    fmt_ttss2si db "cvttss2si: float  3.7       -> int    %d  （向零截断）", 10, 0
    fmt_ss2sd   db "cvtss2sd:  float  3.14      -> double %f", 10, 0
    fmt_sd2ss   db "cvtsd2ss:  double 2.71828.. -> float  %f  （精度有损）", 10, 0
    fmt_done    db "SSE type conversion demo completed.", 10, 0

%macro print_d 1
    movsd [temp_d], xmm0
    movsd xmm0, [temp_d]
    lea rdi, [%1]
    mov eax, 1
    call printf
%endmacro

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; --------------------------------------------------------
    ; 1. cvtsi2ss：32 位整数 -> 单精度
    ; --------------------------------------------------------
    mov eax, [int32_val]                ; eax = 42
    cvtsi2ss xmm0, eax                  ; xmm0[31:0] = 42.0f
    cvtss2sd xmm0, xmm0                 ; 升成 double 给 %f
    print_d fmt_i2ss

    ; --------------------------------------------------------
    ; 2. cvtsi2sd：64 位整数 -> 双精度
    ; --------------------------------------------------------
    mov rax, [int64_val]                ; rax = 1000000
    cvtsi2sd xmm0, rax                  ; xmm0[63:0] = 1000000.0
    print_d fmt_i2sd

    ; --------------------------------------------------------
    ; 3. cvtss2si：单精度 -> 整数，按 MXCSR 舍入模式（默认就近）
    ;    3.7 -> 4
    ; --------------------------------------------------------
    movss xmm0, [float_val]
    cvtss2si eax, xmm0                  ; eax = 4
    mov [temp_i], eax
    lea rdi, [fmt_ss2si]
    mov esi, [temp_i]
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; 4. cvttss2si：多一个 t，就变成无条件向零截断
    ;    3.7 -> 3
    ; --------------------------------------------------------
    movss xmm0, [float_val]
    cvttss2si eax, xmm0                 ; eax = 3
    mov [temp_i], eax
    lea rdi, [fmt_ttss2si]
    mov esi, [temp_i]
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; 5. cvtss2sd：float -> double，有效数字从 ~7 位扩到 ~15 位
    ; --------------------------------------------------------
    movss xmm1, [fpi_val]               ; 3.14f
    cvtss2sd xmm0, xmm1
    print_d fmt_ss2sd

    ; --------------------------------------------------------
    ; 6. cvtsd2ss：double -> float，精度会丢
    ;    打出来要用 %f，所以再 cvtss2sd 升回 double
    ; --------------------------------------------------------
    movsd xmm1, [double_val]            ; 2.718281828459045
    cvtsd2ss xmm0, xmm1                 ; 降成 float（只剩约 7 位）
    cvtss2sd xmm0, xmm0                 ; 升回 double 以便打印
    print_d fmt_sd2ss

    lea rdi, [fmt_done]
    xor eax, eax
    call printf

    xor eax, eax
    leave
    ret
