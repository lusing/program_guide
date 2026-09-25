; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt_min BYTE "CMOVG: min(%lld, %lld) = %lld  (if a > b, a = b)", 10, 0
    fmt_max BYTE "CMOVL: max(%lld, %lld) = %lld  (if a < b, a = b)", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32              ; shadow space

    ; -------------------------------------------------------
    ; 计算 min(25, 10) 使用 CMOVG
    ; r12 = 25, r13 = 10
    ; CMP r12, r13 计算 25 - 10 = 15，标志位: SF=0, OF=0, ZF=0
    ; CMOVG r12, r13: 条件"大于"成立 (25 > 10)，故 r12 = r13 = 10
    ; 结果 r12 = min = 10
    ; -------------------------------------------------------
    mov r12, 25
    mov r13, 10
    cmp r12, r13             ; 比较 r12 与 r13
    cmovg r12, r13           ; 若 r12 > r13，r12 = r13 (取较小者)

    ; 打印 min 结果
    ; printf 会破坏 RAX/RCX/RDX/R8-R11，但 r12 是非易失寄存器得以保留
    lea rcx, fmt_min
    mov rdx, 25              ; a
    mov r8, 10               ; b
    mov r9, r12              ; min 结果
    call printf

    ; -------------------------------------------------------
    ; 计算 max(25, 10) 使用 CMOVL
    ; r12 = 25, r13 = 10
    ; CMP r12, r13 计算 25 - 10 = 15，标志位: SF=0, OF=0, ZF=0
    ; CMOVL r12, r13: 条件"小于"不成立 (25 不 < 10)，故 r12 保持不变
    ; 结果 r12 = max = 25
    ; -------------------------------------------------------
    mov r12, 25
    mov r13, 10
    cmp r12, r13             ; 比较 r12 与 r13
    cmovl r12, r13           ; 若 r12 < r13，r12 = r13 (取较大者)；此处不满足，r12 不变

    ; 打印 max 结果
    lea rcx, fmt_max
    mov rdx, 25              ; a
    mov r8, 10               ; b
    mov r9, r12              ; max 结果
    call printf

    ; --- 退出进程（main 不能用 ret！） ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
main ENDP
END
