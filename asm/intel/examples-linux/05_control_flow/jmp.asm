; ============================================================
; 文件: 05_control_flow/jmp.asm                            [Linux 版]
; 指令: JMP
; 描述: 无条件跳转 —— 跳过一段代码
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/05_control_flow/jmp.asm -o build/jmp.o
; 链接: gcc -no-pie build/jmp.o -o build/jmp
; 对照: examples/05_control_flow/jmp.asm
;
; 预期输出：
;   Before jump
;   After jump
; ============================================================
default rel

section .data
    fmt_before db "Before jump", 10, 0
    fmt_skip   db "Skipped", 10, 0        ; 这行永远不会被打印
    fmt_after  db "After jump", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp

    ; --- 打印 "Before jump" ---
    lea rdi, [fmt_before]
    xor eax, eax
    call printf

    ; --- 无条件跳转到 .after_skip ---
    ; JMP 不看任何标志位，跳过去就是了
    jmp .after_skip

    ; --- 以下代码被跳过，永远不会执行 ---
    lea rdi, [fmt_skip]
    xor eax, eax
    call printf

.after_skip:
    ; --- 打印 "After jump" ---
    lea rdi, [fmt_after]
    xor eax, eax
    call printf

    xor eax, eax                     ; 退出码 0
    leave
    ret
