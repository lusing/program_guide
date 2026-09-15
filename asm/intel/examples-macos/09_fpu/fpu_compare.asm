; ============================================================
; 文件: 09_fpu/fpu_compare.asm                             [macOS 版]
; 指令: FCOMI / FCOM + FNSTSW + SAHF
; 描述: 浮点比较 —— 新老两条路，一条直通 EFLAGS，一条要绕状态字
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/09_fpu/fpu_compare.asm -o build/fpu_compare.o
; 链接: clang -arch x86_64 build/fpu_compare.o -o build/fpu_compare
; 对照: examples/09_fpu/fpu_compare.asm
;
; ------------------------------------------------------------
; 老路（8087 就有）：FCOM 只把结果写进**FPU 自己的状态字**的
; C3/C2/C0 三位，通用标志位一点没动。要用 JA/JB/JE 还得转一道：
;     fnstsw ax      ; AX = FPU 状态字（fn 前缀 = 不等 FPU 空闲）
;     sahf           ; AH 灌进 EFLAGS：C0->CF，C2->PF，C3->ZF
; 然后 JA/JB/JE 才认得。
;
; 新路（1994 年 Pentium 起）：FCOMI 直接写 CF/ZF/PF，省掉中转：
;     fcomi st0, st1
;     ja  大于 / jb 小于 / je 相等
; 代价是它比 FCOM 慢一点，但省下的两条指令通常更划算。
;
; 两个坑：
;   - FCOM/FCOMI 都**不弹栈**，判完记得自己清干净（本例弹两次）；
;   - 遇到 NaN 时 CF=ZF=PF=1，ja/jb/je 全不跳 ——
;     所以「不大于也不小于也不等于」正好可以用来识别 NaN。
;
; ------------------------------------------------------------
; macOS 要点：这段逻辑与平台无关，只把 printf 参数从
; rcx/rdx 换成 rdi/rsi，并去掉影子空间。
; ============================================================
default rel

section .data
    align 8
    val_a   dq 3.14                     ; 较大
    val_b   dq 2.72                     ; 较小
    result  dq 0.0                      ; 只是给 fstp 一个落点，用来清栈

    fmt_fcomi_gt db "FCOMI: 3.14 > 2.72 成立（CF=0 ZF=0 -> JA）", 10, 0
    fmt_fcomi_eq db "FCOMI: 3.14 == 2.72 成立（CF=0 ZF=1 -> JE）", 10, 0
    fmt_fcomi_lt db "FCOMI: 3.14 < 2.72 成立（CF=1 ZF=0 -> JB）", 10, 0
    fmt_fcom_gt  db "FCOM : 3.14 > 2.72 成立（经 FPU 状态字转换）", 10, 0
    fmt_fcom_eq  db "FCOM : 3.14 == 2.72 成立（经 FPU 状态字转换）", 10, 0
    fmt_fcom_lt  db "FCOM : 3.14 < 2.72 成立（经 FPU 状态字转换）", 10, 0
    fmt_done     db "FPU compare demo completed.", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    finit

    ; --------------------------------------------------------
    ; 1. FCOMI：直接设置 EFLAGS
    ;    先压小的再压大的，于是 ST0 = 3.14、ST1 = 2.72
    ; --------------------------------------------------------
    fld qword [val_b]                   ; ST0 = 2.72
    fld qword [val_a]                   ; ST0 = 3.14, ST1 = 2.72
    fcomi st0, st1                      ; 只设标志，不动栈

    ja .fcomi_greater
    jb .fcomi_less
    ; 落到这里说明相等

.fcomi_equal:
    fstp qword [result]                 ; 清掉 ST0
    fstp qword [result]                 ; 清掉 ST1（栈深归零）
    lea rdi, [fmt_fcomi_eq]
    xor eax, eax
    call _printf
    jmp .do_fcom

.fcomi_greater:
    fstp qword [result]
    fstp qword [result]
    lea rdi, [fmt_fcomi_gt]
    xor eax, eax
    call _printf
    jmp .do_fcom

.fcomi_less:
    fstp qword [result]
    fstp qword [result]
    lea rdi, [fmt_fcomi_lt]
    xor eax, eax
    call _printf
    jmp .do_fcom

    ; --------------------------------------------------------
    ; 2. FCOM：老路子，得先搬状态字再搬标志位
    ; --------------------------------------------------------
.do_fcom:
    fld qword [val_b]                   ; ST0 = 2.72
    fld qword [val_a]                   ; ST0 = 3.14, ST1 = 2.72
    fcom st1                            ; 结果只写进 FPU 状态字

    fnstsw ax                           ; AX = FPU 状态字
    sahf                                ; AH -> EFLAGS（C0->CF, C2->PF, C3->ZF）

    ja .fcom_greater
    jb .fcom_less

.fcom_equal:
    fstp qword [result]
    fstp qword [result]
    lea rdi, [fmt_fcom_eq]
    xor eax, eax
    call _printf
    jmp .done

.fcom_greater:
    fstp qword [result]
    fstp qword [result]
    lea rdi, [fmt_fcom_gt]
    xor eax, eax
    call _printf
    jmp .done

.fcom_less:
    fstp qword [result]
    fstp qword [result]
    lea rdi, [fmt_fcom_lt]
    xor eax, eax
    call _printf

.done:
    lea rdi, [fmt_done]
    xor eax, eax
    call _printf

    xor eax, eax
    leave
    ret
