; ============================================================
; fpu_control_word.asm - FPU 控制字与舍入模式
; ============================================================
; 演示:
;   - fnstcw 读取 16 位控制字（异常掩码 + 舍入控制 RC）
;   - 改 RC 位（bit11:10）后经内存写回 fldcw（fldcw 只接受 m16）
;   - 四种舍入模式下 frndint 的行为:
;       00 = 就近舍入（默认；半数舍入到偶数: 2.5->2, 3.5->4）
;       01 = 向下舍入 (floor)
;       10 = 向上舍入 (ceil)
;       11 = 向零舍入 (trunc)
;
; 注: Win64 变参函数（printf）的浮点参数走【整数槽】
;     (rcx,rdx,r8,r9,栈)，XMM 不参与——与 System V 完全不同。
;
; 预期输出:
;   default CW = 0x037F  (RC=nearest, all exceptions masked)
;   RC=nearest: frndint(2.5)=2  frndint(3.5)=4    <- half-to-even
;   RC=down   : frndint(2.5)=2  frndint(-2.5)=-3  <- floor
;   RC=up     : frndint(2.5)=3  frndint(-2.5)=-2  <- ceil
;   RC=zero   : frndint(2.5)=2  frndint(-2.5)=-2  <- trunc
;   CW restored = 0x037F
; ============================================================

default rel

section .data
    align 8
    val_25  dq 2.5
    val_35  dq 3.5
    val_n25 dq -2.5

    fmt_cw   db "default CW = 0x%04X  (RC=nearest, all exceptions masked)", 10, 0
    fmt_line db "RC=%s: frndint(2.5)=%.0f  frndint(%s)=%.0f  <- %s", 10, 0
    fmt_rest db "CW restored = 0x%04X", 10, 0

    name0 db "nearest", 0
    name1 db "down   ", 0
    name2 db "up     ", 0
    name3 db "zero   ", 0
    src0  db "3.5", 0
    srcn  db "-2.5", 0
    note0 db "half-to-even", 0
    note1 db "floor", 0
    note2 db "ceil", 0
    note3 db "trunc", 0

section .bss
    saved_cw  resw 1
    tmp_cw    resw 1
    res_tmp   resq 1
    res_a     resq 1
    res_b     resq 1

section .text
    global main
    extern printf
    extern ExitProcess

; ------------------------------------------------------------
; set_rc: 把舍入模式设为 ECX 的低 2 位（基于默认控制字）
; ------------------------------------------------------------
set_rc:
    movzx eax, word [saved_cw]
    and eax, 0xF3FF             ; 清 RC 位 (bit11:10)
    and ecx, 3
    shl ecx, 10
    or eax, ecx
    mov [tmp_cw], ax
    fldcw word [tmp_cw]         ; fldcw 只接受内存操作数
    ret

; ------------------------------------------------------------
; round_val: 取 [RDX] 处的 double，frndint 后写到临时变量并返回于 RAX
; 注意不能写回 [RDX]——源数据后面几种模式还要用！
; ------------------------------------------------------------
round_val:
    fld qword [rdx]
    frndint
    fstp qword [res_tmp]
    mov rax, [res_tmp]
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 64                 ; 32 影子空间 + 第 5/6 变参的栈槽

    finit                      ; 默认控制字 0x037F

    fnstcw word [saved_cw]
    lea rcx, [fmt_cw]
    movzx rdx, word [saved_cw]
    call printf

    ; ---- 模式 0: nearest, 演示 2.5 -> 2 与 3.5 -> 4（舍入到偶数）----
    xor ecx, ecx
    call set_rc
    lea rdx, [val_25]
    call round_val
    mov [res_a], rax
    lea rdx, [val_35]
    call round_val
    mov [res_b], rax
    lea rcx, [fmt_line]
    lea rdx, [name0]
    mov r8, [res_a]
    lea r9, [src0]
    mov rax, [res_b]
    mov [rsp+32], rax           ; 第 5 变参（%.0f）在栈上
    lea rax, [note0]
    mov [rsp+40], rax           ; 第 6 变参（%s）
    call printf

    ; ---- 模式 1: down (floor), 2.5 -> 2 与 -2.5 -> -3 ----
    mov ecx, 1
    call set_rc
    lea rdx, [val_25]
    call round_val
    mov [res_a], rax
    lea rdx, [val_n25]
    call round_val
    mov [res_b], rax
    lea rcx, [fmt_line]
    lea rdx, [name1]
    mov r8, [res_a]
    lea r9, [srcn]
    mov rax, [res_b]
    mov [rsp+32], rax
    lea rax, [note1]
    mov [rsp+40], rax
    call printf

    ; ---- 模式 2: up (ceil), 2.5 -> 3 与 -2.5 -> -2 ----
    mov ecx, 2
    call set_rc
    lea rdx, [val_25]
    call round_val
    mov [res_a], rax
    lea rdx, [val_n25]
    call round_val
    mov [res_b], rax
    lea rcx, [fmt_line]
    lea rdx, [name2]
    mov r8, [res_a]
    lea r9, [srcn]
    mov rax, [res_b]
    mov [rsp+32], rax
    lea rax, [note2]
    mov [rsp+40], rax
    call printf

    ; ---- 模式 3: zero (trunc), 2.5 -> 2 与 -2.5 -> -2 ----
    mov ecx, 3
    call set_rc
    lea rdx, [val_25]
    call round_val
    mov [res_a], rax
    lea rdx, [val_n25]
    call round_val
    mov [res_b], rax
    lea rcx, [fmt_line]
    lea rdx, [name3]
    mov r8, [res_a]
    lea r9, [srcn]
    mov rax, [res_b]
    mov [rsp+32], rax
    lea rax, [note3]
    mov [rsp+40], rax
    call printf

    ; ---- 恢复默认控制字 ----
    fldcw word [saved_cw]
    lea rcx, [fmt_rest]
    movzx rdx, word [saved_cw]
    call printf

    xor ecx, ecx
    call ExitProcess
