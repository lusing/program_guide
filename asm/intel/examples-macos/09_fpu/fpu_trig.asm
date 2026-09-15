; ============================================================
; 文件: 09_fpu/fpu_trig.asm                                [macOS 版]
; 指令: FLDPI / FSIN / FCOS / FPTAN / FIDIV
; 描述: x87 自带的三角函数 —— 四行指令算完 sin/cos/tan
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/09_fpu/fpu_trig.asm -o build/fpu_trig.o
; 链接: clang -arch x86_64 build/fpu_trig.o -o build/fpu_trig
; 对照: examples/09_fpu/fpu_trig.asm
;
; ------------------------------------------------------------
; x87 直接内建了 sin / cos / tan / 反正切 / 对数 / 开方 等超越函数
; （FSIN、FCOS、FPTAN、FPTAN、FYL2X、FSQRT …），
; 这是 1980 年代最让对手羡慕的一点：一条指令搞定软件库几十行的事。
; 代价是它们内部用多项式逼近，**慢**（FSIN 大约 50~100 周期），
; 而且只覆盖 [-2^63, 2^63] 附近的一个约化区间。
; 现代做法是这几条 SSE 指令 + 软件级范围归约，或者干脆调 libm。
;
; 几个要点：
;   FLDPI      —— 不用自己写 3.14159…，FPU 里就存了个 66 位精度的 π
;   FIDIV [mem] —— ST0 = ST0 / 内存里的整数（f 后面带 i 就是「整数操作数」）
;   FPTAN      —— 这条最反直觉：执行后 ST0 = 1.0，ST1 才是 tan 值。
;                 那个 1.0 是历史包袱，得先 `fstp st0` 把它扔掉
; ------------------------------------------------------------
; macOS 差异仅在参数传递：浮点结果 `movsd xmm0, [result]` + `mov eax,1`。
; ============================================================
default rel

section .data
    align 8
    result  dq 0.0

    align 4
    six     dd 6                        ; 用来算 π/6
    three   dd 3                        ; 用来算 π/3
    four    dd 4                        ; 用来算 π/4

    fmt_pi   db "FLDPI: π = %f", 10, 0
    fmt_sin  db "FSIN:  sin(π/6) = %f   （应为 0.5）", 10, 0
    fmt_cos  db "FCOS:  cos(π/3) = %f   （应为 0.5）", 10, 0
    fmt_tan  db "FPTAN: tan(π/4) = %f   （应为 1.0）", 10, 0
    fmt_done db "FPU trig demo completed.", 10, 0

%macro print_st0 1
    fstp qword [result]
    movsd xmm0, [result]
    lea rdi, [%1]
    mov eax, 1
    call _printf
%endmacro

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    finit

    ; --------------------------------------------------------
    ; 1. FLDPI：拿 FPU 内建的 π（66 位精度，比 double 还准）
    ; --------------------------------------------------------
    fldpi                               ; ST0 = π
    print_st0 fmt_pi

    ; --------------------------------------------------------
    ; 2. FSIN：sin(π/6) = 0.5
    ;    FIDIV 直接除内存里的整数，省掉一次 fld
    ; --------------------------------------------------------
    fldpi                               ; ST0 = π
    fidiv dword [six]                   ; ST0 = π / 6
    fsin                                ; ST0 = sin(π/6) = 0.5
    print_st0 fmt_sin

    ; --------------------------------------------------------
    ; 3. FCOS：cos(π/3) = 0.5
    ; --------------------------------------------------------
    fldpi
    fidiv dword [three]                 ; ST0 = π / 3
    fcos                                ; ST0 = cos(π/3) = 0.5
    print_st0 fmt_cos

    ; --------------------------------------------------------
    ; 4. FPTAN：tan(π/4) = 1.0
    ;    执行前：ST0 = 角度
    ;    执行后：ST0 = 1.0，ST1 = tan(角度)
    ;    所以要先把那个 1.0 弹掉，剩下的 ST0 才是答案
    ; --------------------------------------------------------
    fldpi
    fidiv dword [four]                  ; ST0 = π / 4
    fptan                               ; ST0 = 1.0, ST1 = tan(π/4)
    fstp st0                            ; 扔掉 1.0（光弹不存）
    print_st0 fmt_tan                   ; 现在 ST0 就是 tan 值

    lea rdi, [fmt_done]
    xor eax, eax
    call _printf

    xor eax, eax
    leave
    ret
