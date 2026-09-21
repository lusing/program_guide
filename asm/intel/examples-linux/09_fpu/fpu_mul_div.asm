; ============================================================
; 文件: 09_fpu/fpu_mul_div.asm                             [Linux 版]
; 指令: FMUL / FMULP / FDIV / FDIVP
; 描述: x87 浮点乘除法 —— 顺便用 22/7 演一次圆周率近似
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/09_fpu/fpu_mul_div.asm -o build/fpu_mul_div.o
; 链接: gcc -no-pie build/fpu_mul_div.o -o build/fpu_mul_div
; 对照: examples/09_fpu/fpu_mul_div.asm
;
; ------------------------------------------------------------
; 和加减法同一套路：
;   fmulp   ST0 = ST1 * ST0，然后弹掉（乘法交换，方向无所谓）
;   fdivp   ST0 = ST1 / ST0，然后弹掉（**方向有所谓**：被除数必须在 ST1）
;
; 「栈顶是源、下一格是目的」这个约定是从 8087 传下来的，
; 读老代码时如果看到 fdivr（reverse），意思就是「反过来除」：
;   fdiv  st1, st0  ->  ST1 = ST1 / ST0
;   fdivr st1, st0  ->  ST1 = ST0 / ST1
;
; ------------------------------------------------------------
; Linux（SysV）传浮点参数只要一条 movsd xmm0, [mem]，
; 不像 Win64 要同时动 RDX 和 XMM1。这是本类示例改动最小的地方。
; ============================================================
default rel

section .data
    align 8
    val3    dq 3.0
    val4    dq 4.0
    val22   dq 22.0                     ; 被除数
    val7    dq 7.0                      ; 除数
    result  dq 0.0

    fmt_mul  db "FMULP: 3.0 * 4.0  = %f", 10, 0
    fmt_div  db "FDIVP: 22.0 / 7.0 = %f   （≈ π 的粗略近似）", 10, 0
    fmt_done db "FPU mul/div demo completed.", 10, 0

%macro print_st0 1
    fstp qword [result]
    movsd xmm0, [result]
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

    finit

    ; --------------------------------------------------------
    ; 1. FMULP：3.0 * 4.0
    ; --------------------------------------------------------
    fld qword [val3]                    ; ST0 = 3.0
    fld qword [val4]                    ; ST0 = 4.0, ST1 = 3.0
    fmulp                               ; ST0 = 3.0 * 4.0 = 12.0
    print_st0 fmt_mul

    ; --------------------------------------------------------
    ; 2. FDIVP：22.0 / 7.0
    ;    被除数先压（落在 ST1），除数后压（落在 ST0）
    ; --------------------------------------------------------
    fld qword [val22]                   ; ST0 = 22.0
    fld qword [val7]                    ; ST0 = 7.0, ST1 = 22.0
    fdivp                               ; ST0 = 22.0 / 7.0 = 3.142857...
    print_st0 fmt_div

    lea rdi, [fmt_done]
    xor eax, eax
    call printf

    xor eax, eax
    leave
    ret
