; ============================================================
; 文件: 02_arithmetic/mul.asm                              [macOS 版]
; 指令: MUL
; 描述: 无符号乘法 —— 8/16/32/64 位，结果放在扩展的寄存器对里
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/02_arithmetic/mul.asm -o build/mul.o
; 链接: clang -arch x86_64 build/mul.o -o build/mul
; 对照: examples/02_arithmetic/mul.asm
;
; MUL 的规则很死板：被乘数永远是 AL/AX/EAX/RAX（隐含），
; 乘数由你给，乘积写进 AX / DX:AX / EDX:EAX / RDX:RAX。
; 也就是说 64 位乘法会顺手把 RDX 也写掉 —— 而 RDX 在 SysV 里是第 3 个参数寄存器，
; 所以一定要先把积结算完、存好，再开始装 printf 的参数。
; ============================================================
default rel

section .data
    align 8
    fmt8  db "8位 mul:   255 * 10        => AX = %d (0x%x)", 10, 0
    fmt16 db "16位 mul:  1000 * 100      => DX:AX = %lld", 10, 0
    fmt32 db "32位 mul:  4000000000 * 2  => EDX:EAX = %llu", 10, 0
    fmt64 db "64位 mul:  0xFFFFFFFFFFFFFFFF * 2 => RDX:RAX = 0x%016llx%016llx", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rbx

    ; --- 8 位: mul bl -> AX = AL * BL ---
    mov al, 255
    mov bl, 10
    mul bl                           ; AX = 2550
    movzx r10d, ax
    lea rdi, [fmt8]
    mov esi, r10d                    ; %d
    mov edx, r10d                    ; %x
    xor eax, eax
    call _printf

    ; --- 16 位: mul bx -> DX:AX = AX * BX ---
    mov ax, 1000
    mov bx, 100
    mul bx                           ; DX:AX = 100000
    movzx rsi, dx                    ; 高 16 位
    shl rsi, 16
    movzx eax, ax                    ; 低 16 位
    or rsi, rax
    lea rdi, [fmt16]
    xor eax, eax
    call _printf

    ; --- 32 位: mul ebx -> EDX:EAX = EAX * EBX ---
    mov eax, 4000000000              ; 0xEE6B2800
    mov ebx, 2
    mul ebx                          ; EDX:EAX = 8000000000
    shl rdx, 32                      ; 高 32 位移到高位（RDX 已被零扩展）
    or rdx, rax                      ; 拼成完整 64 位
    lea rdi, [fmt32]
    mov rsi, rdx
    xor eax, eax
    call _printf

    ; --- 64 位: mul rbx -> RDX:RAX = RAX * RBX ---
    mov rax, 0xFFFFFFFFFFFFFFFF
    mov rbx, 2
    mul rbx                          ; RDX=1, RAX=0xFFFFFFFFFFFFFFFE
    lea rdi, [fmt64]
    mov rsi, rdx                     ; 第 2 个参数 = 高 64 位（先装 rsi）
    mov rdx, rax                     ; 第 3 个参数 = 低 64 位
    xor eax, eax
    call _printf

    mov rbx, [rbp-8]
    xor eax, eax
    leave
    ret
