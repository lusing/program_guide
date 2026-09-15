; ============================================================
; 文件: 09_fpu/fpu_load_store.asm                          [macOS 版]
; 指令: FLD / FILD / FST / FSTP
; 描述: 数据和 x87 栈之间怎么来回搬 —— 以及 FST 与 FSTP 的一字之差
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/09_fpu/fpu_load_store.asm -o build/fpu_load_store.o
; 链接: clang -arch x86_64 build/fpu_load_store.o -o build/fpu_load_store
; 对照: examples/09_fpu/fpu_load_store.asm
;
; ------------------------------------------------------------
; FLD 家族（往上装）：
;   fld qword [m]   double  -> ST0
;   fld dword [m]   float   -> ST0（自动升成 80 位扩展精度）
;   fild dword [m]  整数    -> ST0（顺便变成浮点）
;   fld1 / fldz / fldpi / fldl2e ... 直接压常量，比从内存读快
;
; FST 家族（往下存）：
;   fst  qword [m]  存 ST0，**不弹栈**（栈深度不变）
;   fstp qword [m]  存 ST0，并弹栈
; 那个 p 就是 pop。忘了写 p 会让 FPU 栈悄悄长高，
; 循环里跑几百万次就会「栈溢出」—— x87 栈只有 8 格。
;
; 顺带一提：`fstp st0` 就是「光弹不存」，专门用来丢掉栈顶。
;
; ------------------------------------------------------------
; macOS 传浮点参数：只要 `movsd xmm0, [result]` + `mov eax,1`。
; Windows 那边得同时填 RDX 和 XMM1，这就是本例想让你对照的地方。
; ============================================================
default rel

section .data
    align 8
    val_double  dq 3.141592653589793    ; double（64 位）
    align 4
    val_float   dd 2.718281828          ; float （32 位）
    align 4
    val_int     dd 42                   ; 32 位整数

    align 8
    result      dq 0.0

    fmt_fld_d  db "FLD qword  （double 3.14159...）： %f", 10, 0
    fmt_fld_f  db "FLD dword  （float  2.71828...）： %f", 10, 0
    fmt_fild   db "FILD dword （整数   42）：        %f", 10, 0
    fmt_fst    db "FST        （存但**不**弹栈）：   %f", 10, 0
    fmt_fstp   db "FSTP       （存完顺便弹栈）：     %f", 10, 0
    fmt_done   db "FPU load/store demo completed.", 10, 0

; 只负责把 [result] 打出来（不碰 FPU 栈）
%macro print_result 1
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

    finit                               ; 设置默认控制字（扩展精度、四舍五入）

    ; --------------------------------------------------------
    ; 1. FLD qword：64 位 double
    ; --------------------------------------------------------
    fld qword [val_double]              ; ST0 = 3.141592653589793
    fstp qword [result]                 ; 存下来并弹栈（栈恢复空）
    print_result fmt_fld_d

    ; --------------------------------------------------------
    ; 2. FLD dword：32 位 float，进栈时自动升成 80 位扩展精度
    ; --------------------------------------------------------
    fld dword [val_float]               ; ST0 = 2.718281828...
    fstp qword [result]                 ; 取出时截成 double
    print_result fmt_fld_f

    ; --------------------------------------------------------
    ; 3. FILD：把整数读进来并转成浮点
    ; --------------------------------------------------------
    fild dword [val_int]                ; ST0 = 42.0
    fstp qword [result]
    print_result fmt_fild

    ; --------------------------------------------------------
    ; 4. FST 与 FSTP 的区别 —— 只差那个 p
    ;    先用 FST 存一份，ST0 还留在栈上，所以还能再取一次
    ; --------------------------------------------------------
    fld qword [val_double]              ; ST0 = 3.14159...
    fst qword [result]                  ; 存到内存，ST0 仍在栈顶
    print_result fmt_fst                ; 此时 FPU 栈深 = 1

    fstp qword [result]                 ; 这回带 p：存完就弹，栈深回到 0
    print_result fmt_fstp

    lea rdi, [fmt_done]
    xor eax, eax
    call _printf

    xor eax, eax
    leave
    ret
