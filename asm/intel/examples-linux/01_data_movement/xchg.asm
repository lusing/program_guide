; ============================================================
; 文件: 01_data_movement/xchg.asm                          [Linux 版]
; 指令: XCHG
; 描述: XCHG 交换指令 —— 寄存器间 / 寄存器与内存之间交换
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/01_data_movement/xchg.asm -o build/xchg.o
; 链接: gcc -no-pie build/xchg.o -o build/xchg
; 对照: examples/01_data_movement/xchg.asm（Windows / MSVC 调用约定）
;
; 带内存操作数的 XCHG 隐含 LOCK 前缀，天然原子 —— 这是它相对「MOV 三连」的价值。
;
; 这一节同时演示 ABI 里最容易踩的两条：
;   1) 调用者保存寄存器（rax rcx rdx rsi rdi r8-r11）在 call 之后内容不定，
;      printf 还会把「打印了多少字符」放进 eax，所以 rax 千万别指望能留到下一次打印；
;   2) 想在两次调用之间保存现场，要用被调用者保存寄存器 rbx / r12-r15，
;      而 Linux 下 main 是被 libc 启动代码调用进来的普通函数，
;      用完这些寄存器必须还原，否则 return 之后启动代码会踩到坏值而崩溃。
; ============================================================
default rel

section .data
    align 8
    var dq 111

    fmt_before   db "寄存器交换前: rax=%lld, rbx=%lld", 10, 0
    fmt_after    db "寄存器交换后: rax=%lld, rbx=%lld (xchg rax,rbx)", 10, 0
    fmt_m_before db "内存交换前:   var=%lld, rax=%lld", 10, 0
    fmt_m_after  db "内存交换后:   var=%lld, rax=%lld (xchg [var],rax)", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 48                  ; 5 个栈槽，存被调用者保存寄存器的原值
    mov [rbp-8],  rbx
    mov [rbp-16], r12
    mov [rbp-24], r13
    mov [rbp-32], r14
    mov [rbp-40], r15

    ; --- 寄存器间交换 ---
    ; 用非易失寄存器(r12-r15)保存交换前/后的值，避免被 printf 破坏
    mov rax, 10
    mov rbx, 20
    mov r12, rax              ; r12 = 交换前 rax = 10
    mov r13, rbx              ; r13 = 交换前 rbx = 20
    xchg rax, rbx             ; 交换后 rax=20, rbx=10
    mov r14, rax              ; r14 = 交换后 rax = 20
    mov r15, rbx              ; r15 = 交换后 rbx = 10
    lea rdi, [fmt_before]
    mov rsi, r12
    mov rdx, r13
    xor eax, eax
    call printf
    lea rdi, [fmt_after]
    mov rsi, r14
    mov rdx, r15
    xor eax, eax
    call printf

    ; --- 寄存器与内存交换 ---
    mov qword [var], 111
    mov rax, 222
    mov r12, [var]            ; r12 = 交换前 var = 111
    mov r13, rax              ; r13 = 交换前 rax = 222
    xchg [var], rax           ; 交换后 var=222, rax=111
    mov r14, [var]            ; r14 = 交换后 var = 222
    mov r15, rax              ; r15 = 交换后 rax = 111
    lea rdi, [fmt_m_before]
    mov rsi, r12
    mov rdx, r13
    xor eax, eax
    call printf
    lea rdi, [fmt_m_after]
    mov rsi, r14
    mov rdx, r15
    xor eax, eax
    call printf

    ; 还原被调用者保存寄存器
    mov rbx, [rbp-8]
    mov r12, [rbp-16]
    mov r13, [rbp-24]
    mov r14, [rbp-32]
    mov r15, [rbp-40]

    xor eax, eax
    leave
    ret
