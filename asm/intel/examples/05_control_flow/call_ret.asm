; ============================================================
; 文件: 05_control_flow/call_ret.asm
; 指令: CALL, RET
; 描述: 演示函数调用和返回，定义辅助函数
; 编译: nasm -f win64 call_ret.asm -o call_ret.obj
; 链接: link /subsystem:console /entry:main call_ret.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
; 预期输出:
;   add_numbers(10, 20) = 30
;   multiply(7, 6) = 42
;   add_numbers(100, 200) = 300
;   multiply(15, 15) = 225
;
; 关键说明:
;   - 子函数（被CALL调用）可以用 RET 返回，RET会弹出返回地址
;   - main 是入口点（/entry:main），没有返回地址在栈上，不能用RET
;   - main 必须用 ExitProcess 退出
;   - printf 会破坏 volatile 寄存器（RAX/RCX/RDX/R8-R11）
;     因此调用 printf 前需用 r12 等保存结果
; ============================================================
default rel

section .data
    fmt_add db "add_numbers(%lld, %lld) = %lld", 10, 0
    fmt_mul db "multiply(%lld, %lld) = %lld", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

; -------------------------------------------------------
; add_numbers: 两数相加
; 输入: RCX = a, RDX = b
; 输出: RAX = a + b
; 说明: 子函数可以用 RET（CALL会压入返回地址，RET弹出它）
; -------------------------------------------------------
add_numbers:
    mov rax, rcx             ; RAX = a
    add rax, rdx             ; RAX = a + b
    ret

; -------------------------------------------------------
; multiply: 两数相乘（有符号乘法）
; 输入: RCX = a, RDX = b
; 输出: RAX = a * b
; -------------------------------------------------------
multiply:
    mov rax, rcx             ; RAX = a
    imul rax, rdx            ; RAX = a * b (有符号乘法)
    ret

; ============================================================
; main: 主入口点
; ============================================================
main:
    push rbp
    mov rbp, rsp
    sub rsp, 32              ; shadow space

    ; -------------------------------------------------------
    ; 调用 add_numbers(10, 20)
    ; Win64 调用约定: 第1参数 RCX, 第2参数 RDX
    ; -------------------------------------------------------
    mov rcx, 10
    mov rdx, 20
    call add_numbers         ; 返回值在 RAX
    mov r12, rax             ; 保存结果到 r12（printf 会破坏 RAX）

    ; 打印 "add_numbers(10, 20) = 30"
    ; printf(fmt, a, b, result) -> RCX, RDX, R8, R9
    lea rcx, [fmt_add]
    mov rdx, 10              ; 第1个参数值
    mov r8, 20               ; 第2个参数值
    mov r9, r12              ; 结果
    call printf

    ; -------------------------------------------------------
    ; 调用 multiply(7, 6)
    ; -------------------------------------------------------
    mov rcx, 7
    mov rdx, 6
    call multiply
    mov r12, rax             ; 保存结果

    lea rcx, [fmt_mul]
    mov rdx, 7
    mov r8, 6
    mov r9, r12
    call printf

    ; -------------------------------------------------------
    ; 调用 add_numbers(100, 200)
    ; -------------------------------------------------------
    mov rcx, 100
    mov rdx, 200
    call add_numbers
    mov r12, rax             ; 保存结果

    lea rcx, [fmt_add]
    mov rdx, 100
    mov r8, 200
    mov r9, r12
    call printf

    ; -------------------------------------------------------
    ; 调用 multiply(15, 15)
    ; -------------------------------------------------------
    mov rcx, 15
    mov rdx, 15
    call multiply
    mov r12, rax             ; 保存结果

    lea rcx, [fmt_mul]
    mov rdx, 15
    mov r8, 15
    mov r9, r12
    call printf

    ; --- 退出进程（main 不能用 ret！） ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
