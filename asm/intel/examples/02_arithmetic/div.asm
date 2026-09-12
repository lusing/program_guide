; ============================================================
; 文件: 02_arithmetic/div.asm
; 指令: DIV
; 描述: 无符号除法 - 32位与64位 (除前必须清零高位寄存器)
; 编译: nasm -f win64 div.asm -o div.obj
; 链接: link /subsystem:console /entry:main div.obj msvcrt.lib kernel32.lib
; ============================================================
default rel

section .data
    align 8
    fmt32 db "32位 div: 100 / 7            => 商=%d, 余=%d", 10, 0
    fmt64 db "64位 div: 1000000000000 / 3  => 商=%lld, 余=%lld", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 32位: EDX:EAX / EBX, 除前必须清零 EDX
    mov eax, 100
    xor edx, edx               ; 清零高位 (重要!)
    mov ebx, 7
    div ebx                    ; EAX=商=14, EDX=余=2
    mov r8d, edx               ; r8 = 余数 2
    mov edx, eax               ; rdx = 商 14
    lea rcx, [fmt32]
    call printf

    ; 64位: RDX:RAX / RBX, 除前必须清零 RDX
    mov rax, 1000000000000
    xor rdx, rdx               ; 清零高位 (重要!)
    mov rbx, 3
    div rbx                    ; RAX=商=333333333333, RDX=余=1
    mov r8, rdx                ; r8 = 余数 1
    mov rdx, rax               ; rdx = 商
    lea rcx, [fmt64]
    call printf

    xor ecx, ecx
    call ExitProcess
