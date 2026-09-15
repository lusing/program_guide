; ============================================================
; 文件: 01_data_movement/lea.asm                           [macOS 版]
; 指令: LEA
; 描述: LEA 地址计算 —— Effective Address 与「用 LEA 做快速乘法」
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/01_data_movement/lea.asm -o build/lea.o
; 链接: clang -arch x86_64 build/lea.o -o build/lea
; 对照: examples/01_data_movement/lea.asm
;
; 注意 LEA 的地址表达式里可以用 rbp/rsp 之外的任意 64 位基址和索引寄存器，
; 但比例因子只能是 1 / 2 / 4 / 8。想「×3」就写 [rax+rax*2]。
; ============================================================
default rel

section .data
    align 8
    qarray dq 100, 200, 300, 400, 500, 600, 700, 800   ; 8 字节元素数组
    darray dd 10, 20, 30, 40, 50, 60, 70, 80          ; 4 字节元素数组

    fmt_base   db "简单地址: lea rax,[rbx]            => 0x%llx (数组首地址)", 10, 0
    fmt_off8   db "偏移地址: lea rax,[rbx+8]          => 0x%llx (偏移+8)", 10, 0
    fmt_idx4   db "乘法计算: lea rax,[rbx+r9*4]       => darray[2]=%d", 10, 0
    fmt_idx8   db "乘法计算: lea rax,[rbx+r9*8]       => qarray[3]=%lld", 10, 0
    fmt_cplx   db "复合计算: lea rax,[rbx+r9*8+16]    => qarray[5]=%lld", 10, 0
    fmt_mul3   db "快速乘法: lea rax,[rax+rax*2] (x3) => 7*3=%lld", 10, 0
    fmt_mul5   db "快速乘法: lea rax,[rax+rax*4] (x5) => 7*5=%lld", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rbx             ; rbx 用来存数组基址，退场前要还原

    ; 简单地址: lea rax,[rbx] -> 取数组首地址
    lea rbx, [qarray]
    lea rax, [rbx]
    lea rdi, [fmt_base]
    mov rsi, rax
    xor eax, eax
    call _printf

    ; 偏移地址: lea rax,[rbx+8]
    lea rax, [rbx+8]
    lea rdi, [fmt_off8]
    mov rsi, rax
    xor eax, eax
    call _printf

    ; 乘法计算: lea rax,[rbx+r9*4] -> darray[2]=30
    lea rbx, [darray]
    mov r9, 2
    lea rax, [rbx+r9*4]
    mov esi, dword [rax]         ; 取出值 30
    lea rdi, [fmt_idx4]
    xor eax, eax
    call _printf

    ; 乘法计算: lea rax,[rbx+r9*8] -> qarray[3]=400
    lea rbx, [qarray]
    mov r9, 3
    lea rax, [rbx+r9*8]
    mov rsi, [rax]               ; 取出值 400
    lea rdi, [fmt_idx8]
    xor eax, eax
    call _printf

    ; 复合计算: lea rax,[rbx+r9*8+16] -> 3*8+16=40 => qarray[5]=600
    mov r9, 3
    lea rax, [rbx+r9*8+16]
    mov rsi, [rax]               ; 取出值 600
    lea rdi, [fmt_cplx]
    xor eax, eax
    call _printf

    ; 快速乘法 x3: lea rax,[rax+rax*2]
    mov rax, 7
    lea rax, [rax+rax*2]         ; 7+14=21
    lea rdi, [fmt_mul3]
    mov rsi, rax
    xor eax, eax
    call _printf

    ; 快速乘法 x5: lea rax,[rax+rax*4]
    mov rax, 7
    lea rax, [rax+rax*4]         ; 7+28=35
    lea rdi, [fmt_mul5]
    mov rsi, rax
    xor eax, eax
    call _printf

    mov rbx, [rbp-8]
    xor eax, eax
    leave
    ret
