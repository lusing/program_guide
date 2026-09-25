; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt_of BYTE "OF: 127 + 1 -> Overflow (JO taken, OF=1)", 10, 0
    fmt_sf BYTE "SF: 0 - 1 -> Negative (JS taken, SF=1)", 10, 0
    fmt_pf BYTE "PF: 3 (0b00000011, two 1s) -> Even parity (JP taken, PF=1)", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32              ; shadow space

    ; -------------------------------------------------------
    ; 溢出标志 OF: 127 + 1 (有符号字节溢出)
    ; AL = 127 (7Fh) 是 8 位有符号最大正数
    ; ADD AL, 1 = 128 = 80h，作为有符号字节是 -128，发生溢出 -> OF=1
    ; JO 在 OF=1 时跳转
    ; -------------------------------------------------------
    mov al, 127              ; 7Fh (有符号 +127)
    add al, 1                ; 127+1=128，有符号溢出 -> OF=1
    jo mainof_detected          ; OF=1 -> 跳转
    ; 不会执行到这里
    jmp mainafter_of
mainof_detected:
    lea rcx, fmt_of
    call printf
mainafter_of:

    ; -------------------------------------------------------
    ; 符号标志 SF: 0 - 1 (结果为负)
    ; EAX = 0, SUB EAX, 1 = -1 = 0FFFFFFFFh，最高位(符号位)=1 -> SF=1
    ; JS 在 SF=1 时跳转
    ; -------------------------------------------------------
    xor eax, eax             ; EAX = 0
    sub eax, 1               ; 0 - 1 = -1 (0FFFFFFFFh) -> SF=1
    js mainsf_detected          ; SF=1 -> 跳转
    jmp mainafter_sf
mainsf_detected:
    lea rcx, fmt_sf
    call printf
mainafter_sf:

    ; -------------------------------------------------------
    ; 奇偶标志 PF: AL=3 (0b00000011，含 2 个 1，偶数)
    ; TEST AL, AL 做 AND 运算，结果 = AL = 3，低 8 位 03h 含 2 个 1
    ; PF 在结果低 8 位含偶数个 1 时置 1 -> PF=1
    ; JP 在 PF=1 时跳转
    ; -------------------------------------------------------
    mov al, 3                ; 03h = 00000011，两个 1 (偶数)
    test al, al              ; AND AL,AL，结果=3，PF=1
    jp mainpf_detected          ; PF=1 -> 跳转
    jmp mainafter_pf
mainpf_detected:
    lea rcx, fmt_pf
    call printf
mainafter_pf:

    ; --- 退出进程（main 不能用 ret！） ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
main ENDP
END
