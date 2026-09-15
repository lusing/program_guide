; ============================================================
; 文件: 07_stack_ops/enter_leave.asm                       [macOS 版]
; 指令: ENTER / LEAVE
; 描述: 一条指令建立栈帧 —— 与 push rbp; mov rbp,rsp; sub rsp,N 完全等价
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/07_stack_ops/enter_leave.asm -o build/enter_leave.o
; 链接: clang -arch x86_64 build/enter_leave.o -o build/enter_leave
; 对照: examples/07_stack_ops/enter_leave.asm
;
; ------------------------------------------------------------
; ENTER imm16, imm8
;   第一个操作数 = 要分配的字节数（会自动向上凑成 16 的倍数）
;   第二个操作数 = 嵌套层数，0 表示不做嵌套复制
;   enter 64, 0  ≡  push rbp / mov rbp,rsp / sub rsp,64
; LEAVE        ≡  mov rsp,rbp / pop rbp
;
; ENTER 是 80186 时代为高级语言（尤其 Pascal 的嵌套函数）设计的，
; 现代编译器和手写汇编都更愿意直接写三条指令 —— 因为 ENTER 慢得多。
; 但读 80 年代的目标代码时一定会撞上它，所以必须认得。
;
; ------------------------------------------------------------
; macOS 与 Windows 在收场方式上有本质差别：
;   Windows 版用 /entry:main 直接把 main 当进程入口，
;   所以 leave 之后**不能 ret**（栈上没有返回地址），只能 call ExitProcess。
;   macOS 版 _main 是被 libSystem 启动代码 call 进来的，
;   栈上真有返回地址，所以老老实实 `leave / ret` 就对了。
; 另外 SysV 没有影子空间，`sub rsp,64` 是纯粹的局部变量空间。
; ============================================================
default rel

section .data
    fmt_manual db "1. 手动建帧（push rbp; mov rbp,rsp; sub rsp,64）：", 10, 0
    fmt_vars1  db "   [rbp-8]=%lld, [rbp-16]=%lld, [rbp-24]=%lld", 10, 0
    fmt_enter  db "2. ENTER 建帧（enter 64,0）：", 10, 0
    fmt_vars2  db "   [rbp-8]=%lld, [rbp-16]=%lld, [rbp-24]=%lld", 10, 0
    fmt_equiv  db "   （enter 64,0 与三条指令完全等价）", 10, 0
    fmt_done   db "ENTER/LEAVE demo completed.", 10, 0

section .text
    global _main
    extern _printf

_main:

    ; ========================================================
    ; 第 1 部分：手动建立栈帧
    ;   push rbp      -- 保存调用者的帧指针
    ;   mov rbp, rsp  -- RBP 钉在当前栈顶，之后局部变量都用 [rbp-N] 访问
    ;   sub rsp, 64   -- 一次性开 64 字节局部变量空间
    ; 注意 SysV 没有影子空间，这 64 字节全是自己的。
    ; ========================================================
    push rbp
    mov rbp, rsp
    sub rsp, 64

    mov qword [rbp-8],  42              ; 局部变量 1
    mov qword [rbp-16], 100             ; 局部变量 2
    mov qword [rbp-24], 7               ; 局部变量 3

    lea rdi, [fmt_manual]
    xor eax, eax
    call _printf

    lea rdi, [fmt_vars1]
    mov rsi, [rbp-8]                    ; 第 2 个参数
    mov rdx, [rbp-16]                   ; 第 3 个参数
    mov rcx, [rbp-24]                   ; 第 4 个参数
    xor eax, eax
    call _printf

    leave                               ; mov rsp,rbp; pop rbp，帧整体拆掉

    ; ========================================================
    ; 第 2 部分：用 ENTER 一条指令建立同样的帧
    ; ========================================================
    enter 64, 0                         ; 建帧 + 分配 64 字节

    mov qword [rbp-8],  200
    mov qword [rbp-16], 300
    mov qword [rbp-24], 400

    lea rdi, [fmt_enter]
    xor eax, eax
    call _printf

    lea rdi, [fmt_vars2]
    mov rsi, [rbp-8]                    ; 200
    mov rdx, [rbp-16]                   ; 300
    mov rcx, [rbp-24]                   ; 400
    xor eax, eax
    call _printf

    lea rdi, [fmt_equiv]
    xor eax, eax
    call _printf

    leave

    ; ========================================================
    ; 收尾：再建一个标准帧来打印结束语，然后正常 leave/ret
    ; （macOS 上 _main 是被调用的，栈上有返回地址，可以放心 ret）
    ; ========================================================
    push rbp
    mov rbp, rsp
    sub rsp, 16
    lea rdi, [fmt_done]
    xor eax, eax
    call _printf
    xor eax, eax
    leave
    ret
