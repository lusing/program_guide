; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    fmt_add BYTE "ADC 128位加法: 0xFFFFFFFFFFFFFFFF + 1 => 高位=0x%016llx 低位=0x%016llx", 10, 0
    fmt_sbb BYTE "SBB 带借位减法: %lld - %lld - 1(CF) = %lld", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; --- ADC: 128位加法 ---
    ; 低64位 = 0FFFFFFFFFFFFFFFFh, 高64位 = 0
    ; 加1: 低64位溢出产生进位, ADC把进位加到高位
    mov rax, 0FFFFFFFFFFFFFFFFh    ; 低64位
    mov rdx, 0                    ; 高64位
    mov rbx, 1
    add rax, rbx                   ; 低64位 +1, 溢出 -> CF=1, RAX=0
    adc rdx, 0                     ; 高64位 += 0 + CF = 1
    ; 结果: 高位=1, 低位=0 => 10000000000000000h (=2^64)
    mov r8, rax                    ; 低位 = 0
    ; rdx 已是高位 = 1
    lea rcx, fmt_add
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
    lea rcx, fmt_sbb
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
