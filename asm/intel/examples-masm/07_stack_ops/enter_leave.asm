; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt_manual BYTE "1. Manual frame (push rbp; mov rbp,rsp; sub rsp,64):", 10, 0
    fmt_vars1  BYTE "   [rbp-8]=%lld, [rbp-16]=%lld, [rbp-24]=%lld", 10, 0
    fmt_enter  BYTE "2. ENTER frame (enter 64,0):", 10, 0
    fmt_vars2  BYTE "   [rbp-8]=%lld, [rbp-16]=%lld, [rbp-24]=%lld", 10, 0
    fmt_equiv  BYTE "   (enter 64,0 == push rbp; mov rbp,rsp; sub rsp,64)", 10, 0
    fmt_done   BYTE "ENTER/LEAVE demo completed.", 10, 0


.code

main PROC

    ; =======================================================
    ; Part 1: 手动建立栈帧
    ; push rbp        ; 保存旧 RBP
    ; mov rbp, rsp    ; RBP = 当前 RSP (栈帧基址)
    ; sub rsp, 64     ; 32影子空间 + 32局部变量空间
    ; =======================================================
    push rbp
    mov rbp, rsp
    sub rsp, 64                           ; 32影子 + 32局部, RSP对齐

    ; 使用 [rbp-offset] 访问局部变量
    mov QWORD PTR [rbp-8], 42                 ; 局部变量1
    mov QWORD PTR [rbp-16], 100               ; 局部变量2
    mov QWORD PTR [rbp-24], 7                 ; 局部变量3

    ; 打印标题
    lea rcx, fmt_manual
    call printf

    ; 打印局部变量值 (直接从栈帧读取)
    lea rcx, fmt_vars1
    mov rdx, [rbp-8]                      ; 42
    mov r8, [rbp-16]                      ; 100
    mov r9, [rbp-24]                      ; 7
    call printf

    ; leave: 恢复栈帧 (mov rsp, rbp; pop rbp)
    leave                                 ; RSP恢复, RBP恢复

    ; =======================================================
    ; Part 2: 使用 ENTER 指令建立栈帧
    ; enter 64, 0 等价于:
    ;   push rbp
    ;   mov rbp, rsp
    ;   sub rsp, 64
    ; 第二个参数 0 = 嵌套级别 (无嵌套)
    ; 64 = 32影子空间 + 32局部变量空间
    ; =======================================================
    enter 64, 0                           ; 建立栈帧 + 64字节空间

    ; 使用 [rbp-offset] 访问局部变量 (与手动方式相同)
    mov QWORD PTR [rbp-8], 200                ; 局部变量1
    mov QWORD PTR [rbp-16], 300               ; 局部变量2
    mov QWORD PTR [rbp-24], 400               ; 局部变量3

    ; 打印标题
    lea rcx, fmt_enter
    call printf

    ; 打印局部变量值
    lea rcx, fmt_vars2
    mov rdx, [rbp-8]                      ; 200
    mov r8, [rbp-16]                      ; 300
    mov r9, [rbp-24]                      ; 400
    call printf

    ; 打印等价说明
    lea rcx, fmt_equiv
    call printf

    ; leave: 恢复栈帧 (不能用 ret!)
    leave                                 ; RSP恢复, RBP恢复

    ; =======================================================
    ; 退出 (leave后需重新分配影子空间)
    ; 注意: leave后不能用ret, 因为main是进程真实入口点
    ; =======================================================
    sub rsp, 40                           ; 32影子 + 8对齐 (leave后RSP≡8, 需对齐)
    lea rcx, fmt_done
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
main ENDP
END
