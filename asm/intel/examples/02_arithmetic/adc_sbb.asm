; ============================================================
; 文件: 02_arithmetic/adc_sbb.asm
; 指令: ADC / SBB
; 描述: 带进位加法与带借位减法 - 128位运算
; 编译: nasm -f win64 adc_sbb.asm -o adc_sbb.obj
; 链接: link /subsystem:console /entry:main adc_sbb.obj msvcrt.lib kernel32.lib
; ============================================================
default rel

section .data
    align 8
    fmt_add db "ADC 128位加法: 0xFFFFFFFFFFFFFFFF + 1 => 高位=0x%016llx 低位=0x%016llx", 10, 0
    fmt_sbb db "SBB 带借位减法: %lld - %lld - 1(CF) = %lld", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; --- ADC: 128位加法 ---
    ; 低64位 = 0xFFFFFFFFFFFFFFFF, 高64位 = 0
    ; 加1: 低64位溢出产生进位, ADC把进位加到高位
    mov rax, 0xFFFFFFFFFFFFFFFF    ; 低64位
    mov rdx, 0                    ; 高64位
    mov rbx, 1
    add rax, rbx                   ; 低64位 +1, 溢出 -> CF=1, RAX=0
    adc rdx, 0                     ; 高64位 += 0 + CF = 1
    ; 结果: 高位=1, 低位=0 => 0x10000000000000000 (=2^64)
    mov r8, rax                    ; 低位 = 0
    ; rdx 已是高位 = 1
    lea rcx, [fmt_add]
    call printf

    ; --- SBB: 带借位减法 ---
    ; stc 置 CF=1, sbb rax,rbx => rax - rbx - 1
    mov rax, 100
    mov rbx, 30
    stc                            ; CF = 1
    sbb rax, rbx                   ; rax = 100 - 30 - 1 = 69
    mov rdx, 100
    mov r8, 30
    mov r9, rax                    ; 69
    lea rcx, [fmt_sbb]
    call printf

    xor ecx, ecx
    call ExitProcess
