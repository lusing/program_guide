; ============================================================
; 文件: 05_control_flow/jmp.asm
; 指令: JMP
; 描述: 演示无条件跳转，跳过代码块
; 编译: nasm -f win64 jmp.asm -o jmp.obj
; 链接: link /subsystem:console /entry:main jmp.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
; 预期输出:
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
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32              ; shadow space

    ; --- 打印 "Before jump" ---
    lea rcx, [fmt_before]
    call printf

    ; --- 无条件跳转到 .after_skip ---
    ; JMP 不检查任何标志位，直接跳转
    jmp .after_skip

    ; --- 以下代码被跳过，永远不会执行 ---
    lea rcx, [fmt_skip]
    call printf

.after_skip:
    ; --- 打印 "After jump" ---
    lea rcx, [fmt_after]
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
