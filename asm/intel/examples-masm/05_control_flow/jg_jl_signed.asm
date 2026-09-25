; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt_jg  BYTE "JG:  5 > 3   -> Greater (JG taken)", 10, 0
    fmt_jl  BYTE "JL: -1 < 1   -> Less (JL taken)", 10, 0
    fmt_jge BYTE "JGE: 3 >= 3  -> Greater or equal (JGE taken)", 10, 0
    fmt_jle BYTE "JLE: 3 <= 3  -> Less or equal (JLE taken)", 10, 0


.code

main PROC
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
    jg mainjg_taken             ; 有符号: 5 > 3, 跳转
    ; 不会执行到这里
    jmp mainafter_jg
mainjg_taken:
    lea rcx, fmt_jg
    call printf
mainafter_jg:

    ; -------------------------------------------------------
    ; JL: 有符号小于跳转
    ; 比较 -1 和 1: -1 < 1 (有符号), JL 跳转
    ; CMP 计算 RAX - RDX = -1 - 1 = -2
    ; -2 的 SF=1, OF=0, ZF=0
    ; JL 条件: SF!=OF -> 1!=0 -> 跳转
    ; -------------------------------------------------------
    mov rax, -1              ; RAX = 0FFFFFFFFFFFFFFFFh (-1 的64位补码)
    mov rdx, 1
    cmp rax, rdx
    jl mainjl_taken             ; 有符号: -1 < 1, 跳转
    ; 不会执行到这里
    jmp mainafter_jl
mainjl_taken:
    lea rcx, fmt_jl
    call printf
mainafter_jl:

    ; -------------------------------------------------------
    ; JGE: 有符号大于等于跳转
    ; 比较 3 和 3: 3 >= 3 (有符号), JGE 跳转
    ; CMP 计算 3 - 3 = 0, SF=0, OF=0, ZF=1
    ; JGE 条件: SF=OF -> 0=0 -> 跳转
    ; -------------------------------------------------------
    mov rax, 3
    mov rdx, 3
    cmp rax, rdx
    jge mainjge_taken          ; 有符号: 3 >= 3, 跳转
    ; 不会执行到这里
    jmp mainafter_jge
mainjge_taken:
    lea rcx, fmt_jge
    call printf
mainafter_jge:

    ; -------------------------------------------------------
    ; JLE: 有符号小于等于跳转
    ; 比较 3 和 3: 3 <= 3 (有符号), JLE 跳转
    ; CMP 计算 3 - 3 = 0, SF=0, OF=0, ZF=1
    ; JLE 条件: SF!=OF 或 ZF=1 -> ZF=1 -> 跳转
    ; -------------------------------------------------------
    mov rax, 3
    mov rdx, 3
    cmp rax, rdx
    jle mainjle_taken          ; 有符号: 3 <= 3, 跳转
    ; 不会执行到这里
    jmp mainafter_jle
mainjle_taken:
    lea rcx, fmt_jle
    call printf
mainafter_jle:

    ; --- 退出进程 ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
main ENDP
END
