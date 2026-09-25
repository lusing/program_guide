; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt BYTE "Sum 1+2+...+10 = %lld (LOOP with ECX=10)", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32              ; shadow space

    ; -------------------------------------------------------
    ; 使用 LOOP 计算 1+2+...+10
    ; mov ecx, 10 会同时清零 RCX 的高 32 位，故 RCX = ECX = 计数值
    ; xor r12d, r12d 写 32 位寄存器会清零 r12 的高 32 位，得到 r12 = 0
    ; -------------------------------------------------------
    mov ecx, 10              ; 循环计数器 = 10 (清零 RCX 高 32 位)
    xor r12d, r12d           ; r12 = 0 (累加器)

mainlp:
    add r12, rcx             ; r12 += rcx (当前计数值 10,9,...,1)
    loop mainlp                 ; ECX--, 若 ECX != 0 跳转到 mainlp

    ; 循环结束，r12 = 55。此时 RCX 已被 LOOP 清零，可安全用于 printf
    lea rcx, fmt
    mov rdx, r12             ; 累加结果
    call printf

    ; --- 退出进程（main 不能用 ret！） ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
main ENDP
END
