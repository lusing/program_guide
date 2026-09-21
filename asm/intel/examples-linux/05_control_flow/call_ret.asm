; ============================================================
; 文件: 05_control_flow/call_ret.asm                       [Linux 版]
; 指令: CALL / RET
; 描述: 自己定义子函数、按 ABI 传参、用 RET 返回
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/05_control_flow/call_ret.asm -o build/call_ret.o
; 链接: gcc -no-pie build/call_ret.o -o build/call_ret
; 对照: examples/05_control_flow/call_ret.asm
;
; 这是 Windows 和 Linux 差别最大的一个例子，两处都值得记住：
;
; 1) 参数寄存器
;      Windows: 第 1~4 个参数 rcx rdx r8 r9（第 5 个起走栈）
;      Linux  : 第 1~6 个参数 rdi rsi rdx rcx r8 r9（第 7 个起走栈）
;
; 2) 能不能用 RET 从 main 返回
;      Windows 版用 link /entry:main 指定入口，栈上没有返回地址，
;      所以 main 只能用 ExitProcess 退出；
;      Linux 版 main 是被 libc（crt1.o）启动代码 call 进来的普通函数，
;      用 ret 正常返回即可，返回值放 eax 就是进程退出码。
;      代价是必须遵守被调用者保存寄存器（rbx / r12-r15）的约定。
;
; 预期输出：
;   add_numbers(10, 20) = 30
;   multiply(7, 6) = 42
;   add_numbers(100, 200) = 300
;   multiply(15, 15) = 225
;   sum4(1, 2, 3, 4) = 10
; ============================================================
default rel

section .data
    fmt_add db "add_numbers(%lld, %lld) = %lld", 10, 0
    fmt_mul db "multiply(%lld, %lld) = %lld", 10, 0
    fmt_s4  db "sum4(%lld, %lld, %lld, %lld) = %lld", 10, 0

section .text
    global main
    extern printf

; ------------------------------------------------------------
; add_numbers: 两数相加
; 输入: rdi = a, rsi = b
; 输出: rax = a + b
; ------------------------------------------------------------
add_numbers:
    mov rax, rdi
    add rax, rsi
    ret

; ------------------------------------------------------------
; multiply: 两数相乘（有符号）
; 输入: rdi = a, rsi = b
; 输出: rax = a * b
; ------------------------------------------------------------
multiply:
    mov rax, rdi
    imul rax, rsi
    ret

; ------------------------------------------------------------
; sum4: 四个参数相加，顺便演示第 3、4 个参数用的是 rdx 和 rcx
; 输入: rdi, rsi, rdx, rcx
; 输出: rax
;
; 这个函数只用 rax，不碰被调用者保存寄存器，
; 所以既不需要建栈帧、也不需要 push/pop —— 这是「叶子函数」的标准长相。
; ------------------------------------------------------------
sum4:
    mov rax, rdi
    add rax, rsi
    add rax, rdx
    add rax, rcx
    ret

; ============================================================
; main
; ============================================================
main:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], r12                 ; r12 用来跨 printf 保存返回值，先存原值

    ; --------------------------------------------------------
    ; add_numbers(10, 20)
    ; SysV：第 1 个参数 rdi，第 2 个参数 rsi，返回值 rax
    ; --------------------------------------------------------
    mov rdi, 10
    mov rsi, 20
    call add_numbers
    mov r12, rax                     ; 返回值落地（printf 会毁掉 rax）

    lea rdi, [fmt_add]
    mov rsi, 10
    mov rdx, 20
    mov rcx, r12
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; multiply(7, 6)
    ; --------------------------------------------------------
    mov rdi, 7
    mov rsi, 6
    call multiply
    mov r12, rax

    lea rdi, [fmt_mul]
    mov rsi, 7
    mov rdx, 6
    mov rcx, r12
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; add_numbers(100, 200)
    ; --------------------------------------------------------
    mov rdi, 100
    mov rsi, 200
    call add_numbers
    mov r12, rax

    lea rdi, [fmt_add]
    mov rsi, 100
    mov rdx, 200
    mov rcx, r12
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; multiply(15, 15)
    ; --------------------------------------------------------
    mov rdi, 15
    mov rsi, 15
    call multiply
    mov r12, rax

    lea rdi, [fmt_mul]
    mov rsi, 15
    mov rdx, 15
    mov rcx, r12
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; sum4(1, 2, 3, 4)：四个参数按 rdi rsi rdx rcx 依次装
    ; 注意装在 rdi/rsi 里的常量必须一开始就放好，
    ; 别在中间调用别的函数把它们冲掉。
    ; --------------------------------------------------------
    mov rdi, 1
    mov rsi, 2
    mov rdx, 3
    mov rcx, 4
    call sum4
    mov r12, rax

    lea rdi, [fmt_s4]
    mov rsi, 1
    mov rdx, 2
    mov rcx, 3
    mov r8, 4                        ; 第 5 个参数
    mov r9, r12                      ; 第 6 个参数
    xor eax, eax
    call printf

    mov r12, [rbp-8]
    xor eax, eax
    leave
    ret
