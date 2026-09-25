; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt_53 BYTE "CMP 5,3: sete=%lld setg=%lld setl=%lld", 10, 0
    fmt_35 BYTE "CMP 3,5: sete=%lld setg=%lld setl=%lld", 10, 0
    fmt_55 BYTE "CMP 5,5: sete=%lld (equal!)", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32              ; shadow space

    ; -------------------------------------------------------
    ; 测试1: CMP 5, 3 (5 > 3)
    ; CMP 计算 5 - 3 = 2: ZF=0, SF=0, OF=0
    ;   sete (ZF=1?) -> 0
    ;   setg (5>3?)  -> 1
    ;   setl (5<3?)  -> 0
    ; 使用非易失寄存器 r12/r13/r14 保存结果，避免被 printf 破坏
    ; -------------------------------------------------------
    mov rax, 5
    mov rdx, 3
    cmp rax, rdx
    sete r12b                ; equal?   -> 0
    setg r13b                ; greater? -> 1
    setl r14b                ; less?    -> 0
    movzx r12, r12b          ; 零扩展为 64 位
    movzx r13, r13b
    movzx r14, r14b

    lea rcx, fmt_53
    mov rdx, r12             ; sete
    mov r8, r13              ; setg
    mov r9, r14              ; setl
    call printf

    ; -------------------------------------------------------
    ; 测试2: CMP 3, 5 (3 < 5)
    ; CMP 计算 3 - 5 = -2: ZF=0, SF=1, OF=0
    ;   sete -> 0
    ;   setg -> 0 (3 不大于 5)
    ;   setl -> 1 (3 小于 5)
    ; -------------------------------------------------------
    mov rax, 3
    mov rdx, 5
    cmp rax, rdx
    sete r12b
    setg r13b
    setl r14b
    movzx r12, r12b
    movzx r13, r13b
    movzx r14, r14b

    lea rcx, fmt_35
    mov rdx, r12             ; sete
    mov r8, r13              ; setg
    mov r9, r14              ; setl
    call printf

    ; -------------------------------------------------------
    ; 测试3: CMP 5, 5 (相等)
    ; CMP 计算 5 - 5 = 0: ZF=1
    ;   sete -> 1 (相等!)
    ; -------------------------------------------------------
    mov rax, 5
    mov rdx, 5
    cmp rax, rdx
    sete r12b                ; equal? -> 1
    movzx r12, r12b          ; 零扩展

    lea rcx, fmt_55
    mov rdx, r12             ; sete
    call printf

    ; --- 退出进程（main 不能用 ret！） ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
main ENDP
END
