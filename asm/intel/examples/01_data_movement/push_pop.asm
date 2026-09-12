; ============================================================
; 文件: 01_data_movement/push_pop.asm
; 指令: PUSH / POP
; 描述: 栈操作 - 入栈出栈与LIFO(后进先出)顺序
; 编译: nasm -f win64 push_pop.asm -o push_pop.obj
; 链接: link /subsystem:console /entry:main push_pop.obj msvcrt.lib kernel32.lib
; ============================================================
default rel

section .data
    align 8
    fmt_push db "push 顺序: %lld, %lld, %lld", 10, 0
    fmt_pop  db "pop  顺序: %lld, %lld, %lld (后进先出 LIFO)", 10, 0
    fmt_imm  db "push 立即数 0xFF 后 pop => %lld", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 打印将入栈的顺序
    lea rcx, [fmt_push]
    mov rdx, 1
    mov r8, 2
    mov r9, 3
    call printf

    ; 入栈 1, 2, 3 (3在栈顶)
    push 1
    push 2
    push 3

    ; 出栈 (LIFO): 3, 2, 1
    pop rax        ; 3
    pop r10        ; 2
    pop r11        ; 1
    lea rcx, [fmt_pop]
    mov rdx, rax   ; 3
    mov r8, r10    ; 2
    mov r9, r11    ; 1
    call printf

    ; push 立即数 0xFF (=255), 再 pop
    push 0xFF
    pop rax
    lea rcx, [fmt_imm]
    mov rdx, rax
    call printf

    xor ecx, ecx
    call ExitProcess
