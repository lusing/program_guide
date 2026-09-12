; ============================================================
; 文件: 01_data_movement/lea.asm
; 指令: LEA
; 描述: LEA地址计算 - 有效地址计算与快速乘法
; 编译: nasm -f win64 lea.asm -o lea.obj
; 链接: link /subsystem:console /entry:main lea.obj msvcrt.lib kernel32.lib
; ============================================================
default rel

section .data
    align 8
    qarray dq 100, 200, 300, 400, 500, 600, 700, 800   ; 8字节元素数组
    darray dd 10, 20, 30, 40, 50, 60, 70, 80            ; 4字节元素数组

    fmt_base   db "简单地址: lea rax,[rbx]            => 0x%llx (数组首地址)", 10, 0
    fmt_off8   db "偏移地址: lea rax,[rbx+8]          => 0x%llx (偏移+8)", 10, 0
    fmt_idx4   db "乘法计算: lea rax,[rbx+rcx*4]      => darray[2]=%d", 10, 0
    fmt_idx8   db "乘法计算: lea rax,[rbx+rcx*8]      => qarray[3]=%lld", 10, 0
    fmt_cplx   db "复合计算: lea rax,[rbx+rcx*8+16]   => qarray[5]=%lld", 10, 0
    fmt_mul3   db "快速乘法: lea rax,[rax+rax*2] (x3) => 7*3=%lld", 10, 0
    fmt_mul5   db "快速乘法: lea rax,[rax+rax*4] (x5) => 7*5=%lld", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 简单地址: lea rax,[rbx] -> 取数组首地址
    lea rbx, [qarray]
    lea rax, [rbx]
    lea rcx, [fmt_base]
    mov rdx, rax
    call printf

    ; 偏移地址: lea rax,[rbx+8]
    lea rax, [rbx+8]
    lea rcx, [fmt_off8]
    mov rdx, rax
    call printf

    ; 乘法计算: lea rax,[rbx+rcx*4] -> darray[2]=30
    lea rbx, [darray]
    mov r9, 2
    lea rax, [rbx+r9*4]
    mov edx, dword [rax]        ; 取出值 30
    lea rcx, [fmt_idx4]
    call printf

    ; 乘法计算: lea rax,[rbx+rcx*8] -> qarray[3]=400
    lea rbx, [qarray]
    mov r9, 3
    lea rax, [rbx+r9*8]
    mov rdx, [rax]              ; 取出值 400
    lea rcx, [fmt_idx8]
    call printf

    ; 复合计算: lea rax,[rbx+rcx*8+16] -> 3*8+16=40 => qarray[5]=600
    mov r9, 3
    lea rax, [rbx+r9*8+16]
    mov rdx, [rax]              ; 取出值 600
    lea rcx, [fmt_cplx]
    call printf

    ; 快速乘法 x3: lea rax,[rax+rax*2]
    mov rax, 7
    lea rax, [rax+rax*2]        ; 7+14=21
    lea rcx, [fmt_mul3]
    mov rdx, rax
    call printf

    ; 快速乘法 x5: lea rax,[rax+rax*4]
    mov rax, 7
    lea rax, [rax+rax*4]        ; 7+28=35
    lea rcx, [fmt_mul5]
    mov rdx, rax
    call printf

    xor ecx, ecx
    call ExitProcess
