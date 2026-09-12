; ============================================================
; 文件: 05_control_flow/jg_jl_signed.asm
; 指令: JG, JGE, JL, JLE (有符号条件跳转)
; 描述: 演示有符号比较跳转，用正数和负数对比
; 编译: nasm -f win64 jg_jl_signed.asm -o jg_jl_signed.obj
; 链接: link /subsystem:console /entry:main jg_jl_signed.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
; 预期输出:
;   JG:  5 > 3   -> Greater (JG taken)
;   JL: -1 < 1   -> Less (JL taken)
;   JGE: 3 >= 3  -> Greater or equal (JGE taken)
;   JLE: 3 <= 3  -> Less or equal (JLE taken)
;
; 有符号跳转指令说明:
;   JG  (Jump if Greater)           : SF=OF 且 ZF=0  (大于)
;   JGE (Jump if Greater or Equal)  : SF=OF           (大于等于)
;   JL  (Jump if Less)              : SF!=OF          (小于)
;   JLE (Jump if Less or Equal)     : SF!=OF 或 ZF=1  (小于等于)
; ============================================================
default rel

section .data
    fmt_jg  db "JG:  5 > 3   -> Greater (JG taken)", 10, 0
    fmt_jl  db "JL: -1 < 1   -> Less (JL taken)", 10, 0
    fmt_jge db "JGE: 3 >= 3  -> Greater or equal (JGE taken)", 10, 0
    fmt_jle db "JLE: 3 <= 3  -> Less or equal (JLE taken)", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32              ; shadow space

    ; -------------------------------------------------------
    ; JG: 有符号大于跳转
    ; 比较 5 和 3: 5 > 3 (有符号), JG 跳转
    ; CMP 计算 RAX - RDX = 5 - 3 = 2, SF=0, OF=0, ZF=0
    ; JG 条件: SF=OF 且 ZF=0 -> 0=0 且 ZF=0 -> 跳转
    ; -------------------------------------------------------
    mov rax, 5
    mov rdx, 3
    cmp rax, rdx
    jg .jg_taken             ; 有符号: 5 > 3, 跳转
    ; 不会执行到这里
    jmp .after_jg
.jg_taken:
    lea rcx, [fmt_jg]
    call printf
.after_jg:

    ; -------------------------------------------------------
    ; JL: 有符号小于跳转
    ; 比较 -1 和 1: -1 < 1 (有符号), JL 跳转
    ; CMP 计算 RAX - RDX = -1 - 1 = -2
    ; -2 的 SF=1, OF=0, ZF=0
    ; JL 条件: SF!=OF -> 1!=0 -> 跳转
    ; -------------------------------------------------------
    mov rax, -1              ; RAX = 0xFFFFFFFFFFFFFFFF (-1 的64位补码)
    mov rdx, 1
    cmp rax, rdx
    jl .jl_taken             ; 有符号: -1 < 1, 跳转
    ; 不会执行到这里
    jmp .after_jl
.jl_taken:
    lea rcx, [fmt_jl]
    call printf
.after_jl:

    ; -------------------------------------------------------
    ; JGE: 有符号大于等于跳转
    ; 比较 3 和 3: 3 >= 3 (有符号), JGE 跳转
    ; CMP 计算 3 - 3 = 0, SF=0, OF=0, ZF=1
    ; JGE 条件: SF=OF -> 0=0 -> 跳转
    ; -------------------------------------------------------
    mov rax, 3
    mov rdx, 3
    cmp rax, rdx
    jge .jge_taken          ; 有符号: 3 >= 3, 跳转
    ; 不会执行到这里
    jmp .after_jge
.jge_taken:
    lea rcx, [fmt_jge]
    call printf
.after_jge:

    ; -------------------------------------------------------
    ; JLE: 有符号小于等于跳转
    ; 比较 3 和 3: 3 <= 3 (有符号), JLE 跳转
    ; CMP 计算 3 - 3 = 0, SF=0, OF=0, ZF=1
    ; JLE 条件: SF!=OF 或 ZF=1 -> ZF=1 -> 跳转
    ; -------------------------------------------------------
    mov rax, 3
    mov rdx, 3
    cmp rax, rdx
    jle .jle_taken          ; 有符号: 3 <= 3, 跳转
    ; 不会执行到这里
    jmp .after_jle
.jle_taken:
    lea rcx, [fmt_jle]
    call printf
.after_jle:

    ; --- 退出进程 ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
