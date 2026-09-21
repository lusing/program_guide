; ============================================================
; 文件: 01_data_movement/push_pop.asm                      [Linux 版]
; 指令: PUSH / POP
; 描述: 栈操作 —— 入栈出栈与 LIFO（后进先出）顺序
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/01_data_movement/push_pop.asm -o build/push_pop.o
; 链接: gcc -no-pie build/push_pop.o -o build/push_pop
; 对照: examples/01_data_movement/push_pop.asm
;
; 栈是往低地址长的：push 让 rsp 减 8，pop 让 rsp 加 8。
; x86-64 上 push/pop 的默认操作数宽度是 64 位，
; 想压 16 位要写 push word，8 位在 64 位模式下不允许（会报 invalid combination）。
; ============================================================
default rel

section .data
    align 8
    fmt_push db "push 顺序: %lld, %lld, %lld", 10, 0
    fmt_pop  db "pop  顺序: %lld, %lld, %lld (后进先出 LIFO)", 10, 0
    fmt_imm  db "push 立即数 0xFF 后 pop => %lld", 10, 0
    fmt_sp   db "压栈前后 rsp 变化: %lld 字节", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16                  ; 自己的栈帧，用来存放要跨 printf 保留的值

    ; 打印将入栈的顺序
    lea rdi, [fmt_push]
    mov esi, 1
    mov edx, 2
    mov ecx, 3
    xor eax, eax
    call printf

    ; 入栈 1, 2, 3 (3 在栈顶)
    ; r10/r11 是调用者保存寄存器，只要中间不 call，就可以放心当临时变量用。
    mov r10, rsp                 ; 压栈前的 rsp
    push 1
    push 2
    push 3
    mov r11, rsp                 ; 压了 3 个 = 24 字节

    ; rsp 差值（正数表示压栈后地址更低）
    ; r10/r11 是调用者保存寄存器，后面的 printf 会毁掉它们，
    ; 所以算出来先放进自己的栈帧 [rbp-8] 保存。
    mov rax, r10
    sub rax, r11
    mov [rbp-8], rax

    ; 出栈 (LIFO): 3, 2, 1
    ; 直接弹进 printf 的参数寄存器，顺序刚好就是 3、2、1
    pop rsi                      ; 3
    pop rdx                      ; 2
    pop rcx                      ; 1
    lea rdi, [fmt_pop]
    xor eax, eax
    call printf

    lea rdi, [fmt_sp]
    mov rsi, [rbp-8]
    xor eax, eax
    call printf

    ; push 立即数 0xFF (=255), 再 pop
    push 0xFF
    pop rax
    lea rdi, [fmt_imm]
    mov rsi, rax
    xor eax, eax
    call printf

    xor eax, eax
    leave
    ret
