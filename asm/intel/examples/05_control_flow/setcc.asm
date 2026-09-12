; ============================================================
; 文件: 05_control_flow/setcc.asm
; 指令: SETE, SETG, SETL (条件字节设置 SETcc)
; 描述: 演示根据标志位设置字节寄存器为 0 或 1
; 编译: nasm -f win64 setcc.asm -o setcc.obj
; 链接: link /subsystem:console /entry:main setcc.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
; 预期输出:
;   CMP 5,3: sete=0 setg=1 setl=0
;   CMP 3,5: sete=0 setg=0 setl=1
;   CMP 5,5: sete=1 (equal!)
;
; SETcc 指令说明:
;   SETcc r8 : 若条件 cc 满足则置 1，否则置 0（只写低 8 位，高位不变）
;   常配合 MOVZX 零扩展为完整数值使用
;   sete : 相等则置 1 (ZF=1)
;   setg : 有符号大于则置 1 (SF=OF 且 ZF=0)
;   setl : 有符号小于则置 1 (SF!=OF)
;
; 注意:
;   - SETcc 只写低 8 位，需用 MOVZX 零扩展后才能作为完整整数打印
;   - SETcc 本身不修改标志位，故一次 CMP 后可连续捕获多个 SETcc 结果
;   - printf 会破坏标志位，故必须先捕获所有结果再调用 printf
; ============================================================
default rel

section .data
    fmt_53 db "CMP 5,3: sete=%lld setg=%lld setl=%lld", 10, 0
    fmt_35 db "CMP 3,5: sete=%lld setg=%lld setl=%lld", 10, 0
    fmt_55 db "CMP 5,5: sete=%lld (equal!)", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
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

    lea rcx, [fmt_53]
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

    lea rcx, [fmt_35]
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

    lea rcx, [fmt_55]
    mov rdx, r12             ; sete
    call printf

    ; --- 退出进程（main 不能用 ret！） ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
