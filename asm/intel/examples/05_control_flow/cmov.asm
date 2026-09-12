; ============================================================
; 文件: 05_control_flow/cmov.asm
; 指令: CMOVG, CMOVL (条件移动 CMOVcc)
; 描述: 演示无分支条件移动实现 min/max
; 编译: nasm -f win64 cmov.asm -o cmov.obj
; 链接: link /subsystem:console /entry:main cmov.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
; 预期输出:
;   CMOVG: min(25, 10) = 10  (if a > b, a = b)
;   CMOVL: max(25, 10) = 25  (if a < b, a = b, else unchanged)
;
; CMOVcc 指令说明:
;   CMOVcc dst, src : 若条件 cc 满足则 dst = src，否则 dst 不变
;   实现无分支（branchless）代码，避免分支预测失败开销
;   cmovg : 有符号大于则移动 (条件同 JG:  SF=OF 且 ZF=0)
;   cmovl : 有符号小于则移动 (条件同 JL:  SF!=OF)
;
; min/max 实现原理 (a=25, b=10):
;   min: cmp a,b; cmovg a,b  -> 若 a>b 则 a=b (取较小者)
;   max: cmp a,b; cmovl a,b  -> 若 a<b 则 a=b (取较大者)，否则 a 不变
; ============================================================
default rel

section .data
    fmt_min db "CMOVG: min(%lld, %lld) = %lld  (if a > b, a = b)", 10, 0
    fmt_max db "CMOVL: max(%lld, %lld) = %lld  (if a < b, a = b)", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
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
    lea rcx, [fmt_min]
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
    lea rcx, [fmt_max]
    mov rdx, 25              ; a
    mov r8, 10               ; b
    mov r9, r12              ; max 结果
    call printf

    ; --- 退出进程（main 不能用 ret！） ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
