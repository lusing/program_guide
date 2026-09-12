; ============================================================
; 文件: 02_arithmetic/inc_dec_neg.asm
; 指令: INC / DEC / NEG
; 描述: 递增/递减/取负 - 含CF标志位说明(INC/DEC不影响CF)
; 编译: nasm -f win64 inc_dec_neg.asm -o inc_dec_neg.obj
; 链接: link /subsystem:console /entry:main inc_dec_neg.obj msvcrt.lib kernel32.lib
; ============================================================
default rel

section .data
    align 8
    fmt_inc db "inc rax: %lld + 1 => %lld", 10, 0
    fmt_dec db "dec rax: %lld - 1 => %lld", 10, 0
    fmt_neg db "neg rax: neg(%lld) => %lld", 10, 0
    fmt_cf  db "INC不影响CF: 先stc(CF=1), inc后 CF仍=%d", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; inc: 41 + 1 = 42
    mov rax, 41
    inc rax                     ; rax = 42
    lea rcx, [fmt_inc]
    mov rdx, 41
    mov r8, rax
    call printf

    ; dec: 100 - 1 = 99
    mov rax, 100
    dec rax                     ; rax = 99
    lea rcx, [fmt_dec]
    mov rdx, 100
    mov r8, rax
    call printf

    ; neg: neg(55) = -55
    mov rax, 55
    neg rax                     ; rax = -55
    lea rcx, [fmt_neg]
    mov rdx, 55
    mov r8, rax
    call printf

    ; INC不影响CF: 先用 stc 置 CF=1, inc 后 CF 不变
    stc                         ; CF = 1
    inc rax                     ; INC 不改变 CF (仍为1)
    setc dl                     ; dl = CF (应为1)
    movzx rdx, dl              ; rdx = 1
    lea rcx, [fmt_cf]
    call printf

    xor ecx, ecx
    call ExitProcess
