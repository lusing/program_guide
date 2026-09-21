; ============================================================
; 文件: 02_arithmetic/div.asm                              [Linux 版]
; 指令: DIV
; 描述: 无符号除法 —— 32 位与 64 位，除之前必须清零高位寄存器
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/02_arithmetic/div.asm -o build/div.o
; 链接: gcc -no-pie build/div.o -o build/div
; 对照: examples/02_arithmetic/div.asm
;
; DIV 是「双宽度被除数」：EDX:EAX ÷ 源，商回 EAX，余数回 EDX。
; 所以做普通 32 位除法前一定要 xor edx,edx，否则余下的一半会把结果搅乱，
; 商超过 32 位时还会触发 #DE（在 Linux 上是 SIGFPE，直接被信号打死）。
; ============================================================
default rel

section .data
    align 8
    fmt32 db "32位 div: 100 / 7            => 商=%d, 余=%d", 10, 0
    fmt64 db "64位 div: 1000000000000 / 3  => 商=%lld, 余=%lld", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rbx

    ; --- 32 位: EDX:EAX / EBX ---
    mov eax, 100
    xor edx, edx                     ; 清零高位（重要！）
    mov ebx, 7
    div ebx                          ; EAX = 商 14，EDX = 余 2
    lea rdi, [fmt32]
    mov esi, eax                     ; 第 2 个参数 = 商
    ; 32 位写 EDX 会自动把 RDX 的高 32 位清零，所以这里 rdx 已经是干净的余数
    xor eax, eax
    call printf

    ; --- 64 位: RDX:RAX / RBX ---
    mov rax, 1000000000000
    xor rdx, rdx                     ; 清零高位（重要！）
    mov rbx, 3
    div rbx                          ; RAX = 商 333333333333，RDX = 余 1
    lea rdi, [fmt64]
    mov rsi, rax                     ; 第 2 个参数 = 商
    ; rdx 就是余数，直接当第 3 个参数
    xor eax, eax
    call printf

    mov rbx, [rbp-8]
    xor eax, eax
    leave
    ret
