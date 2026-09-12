; ============================================================
; 文件: 02_arithmetic/idiv.asm
; 指令: IDIV
; 描述: 有符号除法 - 正数与负数 (除前用CQO扩展符号位)
; 编译: nasm -f win64 idiv.asm -o idiv.obj
; 链接: link /subsystem:console /entry:main idiv.obj msvcrt.lib kernel32.lib
; ============================================================
default rel

section .data
    align 8
    fmt_pos db "正数: 100 / 7  => 商=%lld, 余=%lld", 10, 0
    fmt_neg db "负数: -100 / 7 => 商=%lld, 余=%lld", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 正数: 100 / 7 (除前用 CQO 符号扩展 RAX -> RDX:RAX)
    mov rax, 100
    cqo                         ; RDX = RAX 符号扩展 (正数 => RDX=0)
    mov rbx, 7
    idiv rbx                    ; RAX=商=14, RDX=余=2
    mov r8, rdx                 ; r8 = 余数 2
    mov rdx, rax                ; rdx = 商 14
    lea rcx, [fmt_pos]
    call printf

    ; 负数: -100 / 7
    mov rax, -100
    cqo                         ; RDX = 0xFFFFFFFFFFFFFFFF (符号扩展)
    mov rbx, 7
    idiv rbx                    ; RAX=商=-14, RDX=余=-2 (向零截断)
    mov r8, rdx                 ; r8 = 余数 -2
    mov rdx, rax                ; rdx = 商 -14
    lea rcx, [fmt_neg]
    call printf

    xor ecx, ecx
    call ExitProcess
