; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    val_25  REAL8 2.5
    val_35  REAL8 3.5
    val_n25 REAL8 -2.5

    fmt_cw   BYTE "default CW = 0x%04X  (RC=nearest, all exceptions masked)", 10, 0
    fmt_line BYTE "RC=%s: frndint(2.5)=%.0f  frndint(%s)=%.0f  <- %s", 10, 0
    fmt_rest BYTE "CW restored = 0x%04X", 10, 0

    name0 BYTE "nearest", 0
    name1 BYTE "down   ", 0
    name2 BYTE "up     ", 0
    name3 BYTE "zero   ", 0
    src0  BYTE "3.5", 0
    srcn  BYTE "-2.5", 0
    note0 BYTE "half-to-even", 0
    note1 BYTE "floor", 0
    note2 BYTE "ceil", 0
    note3 BYTE "trunc", 0


.data?
    saved_cw  WORD 1 DUP(?)
    tmp_cw    WORD 1 DUP(?)
    res_tmp   QWORD 1 DUP(?)
    res_a     QWORD 1 DUP(?)
    res_b     QWORD 1 DUP(?)


.code

; ------------------------------------------------------------
; set_rc: 把舍入模式设为 ECX 的低 2 位（基于默认控制字）
; ------------------------------------------------------------
set_rc:
    movzx eax, WORD PTR [saved_cw]
    and eax, 0F3FFh             ; 清 RC 位 (bit11:10)
    and ecx, 3
    shl ecx, 10
    or eax, ecx
    mov [tmp_cw], ax
    fldcw WORD PTR [tmp_cw]         ; fldcw 只接受内存操作数
    ret

; ------------------------------------------------------------
; round_val: 取 [RDX] 处的 double，frndint 后写到临时变量并返回于 RAX
; 注意不能写回 [RDX]——源数据后面几种模式还要用！
; ------------------------------------------------------------
round_val:
    fld QWORD PTR [rdx]
    frndint
    fstp QWORD PTR [res_tmp]
    mov rax, [res_tmp]
    ret

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 64                 ; 32 影子空间 + 第 5/6 变参的栈槽

    finit                      ; 默认控制字 037Fh

    fnstcw WORD PTR [saved_cw]
    lea rcx, fmt_cw
    movzx rdx, WORD PTR [saved_cw]
    call printf

    ; ---- 模式 0: nearest, 演示 2.5 -> 2 与 3.5 -> 4（舍入到偶数）----
    xor ecx, ecx
    call set_rc
    lea rdx, val_25
    call round_val
    mov [res_a], rax
    lea rdx, val_35
    call round_val
    mov [res_b], rax
    lea rcx, fmt_line
    lea rdx, name0
    mov r8, [res_a]
    lea r9, src0
    mov rax, [res_b]
    mov [rsp+32], rax           ; 第 5 变参（%main0f）在栈上
    lea rax, note0
    mov [rsp+40], rax           ; 第 6 变参（%s）
    call printf

    ; ---- 模式 1: down (floor), 2.5 -> 2 与 -2.5 -> -3 ----
    mov ecx, 1
    call set_rc
    lea rdx, val_25
    call round_val
    mov [res_a], rax
    lea rdx, val_n25
    call round_val
    mov [res_b], rax
    lea rcx, fmt_line
    lea rdx, name1
    mov r8, [res_a]
    lea r9, srcn
    mov rax, [res_b]
    mov [rsp+32], rax
    lea rax, note1
    mov [rsp+40], rax
    call printf

    ; ---- 模式 2: up (ceil), 2.5 -> 3 与 -2.5 -> -2 ----
    mov ecx, 2
    call set_rc
    lea rdx, val_25
    call round_val
    mov [res_a], rax
    lea rdx, val_n25
    call round_val
    mov [res_b], rax
    lea rcx, fmt_line
    lea rdx, name2
    mov r8, [res_a]
    lea r9, srcn
    mov rax, [res_b]
    mov [rsp+32], rax
    lea rax, note2
    mov [rsp+40], rax
    call printf

    ; ---- 模式 3: zero (trunc), 2.5 -> 2 与 -2.5 -> -2 ----
    mov ecx, 3
    call set_rc
    lea rdx, val_25
    call round_val
    mov [res_a], rax
    lea rdx, val_n25
    call round_val
    mov [res_b], rax
    lea rcx, fmt_line
    lea rdx, name3
    mov r8, [res_a]
    lea r9, srcn
    mov rax, [res_b]
    mov [rsp+32], rax
    lea rax, note3
    mov [rsp+40], rax
    call printf

    ; ---- 恢复默认控制字 ----
    fldcw WORD PTR [saved_cw]
    lea rcx, fmt_rest
    movzx rdx, WORD PTR [saved_cw]
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
