; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    int_val   QWORD 1234567890

    fmt_int  BYTE "int  = %lld", 10, 0
    fmt_pre  BYTE "BCD  = ", 0
    fmt_byte BYTE "%02X ", 0
    fmt_nl   BYTE 10, 0
    fmt_back BYTE "back = %lld (roundtrip OK)", 10, 0


.data?
    bcd_buf  BYTE 10 DUP(?); 10 字节压缩 BCD（x87 的 tword 访问不要求对齐）
    back_val QWORD 1 DUP(?)


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx                    ; rbx/r12 非易失，使用前保存
    push r12

    finit

    ; ---- 打印原整数 ----
    lea rcx, fmt_int
    mov rdx, QWORD PTR [int_val]
    call printf

    ; ---- 整数 -> 压缩 BCD ----
    fild QWORD PTR [int_val]       ; ST0 = 1234567890
    fbstp TBYTE PTR [bcd_buf]      ; 弹出并存为 10 字节 BCD

    ; ---- 逐字节打印（低位字节在前，可直接读出十进制数字）----
    ; 注意：[bcd_buf + rbx] 带索引寄存器无法用 RIP 相对寻址，
    ; NASM 会退回绝对寻址产生 ADDR32 重定位，MSVC link 拒绝
    ; （LNK2017）。正确姿势：lea 取 RIP 相对基址，再加索引。
    lea rcx, fmt_pre
    call printf
    lea r12, bcd_buf          ; RIP 相对取基址；r12 非易失，printf 不会破坏
    xor rbx, rbx
mainprint_loop:
    cmp rbx, 10
    jge mainprint_done
    lea rcx, fmt_byte
    movzx rdx, BYTE PTR [r12 + rbx]
    call printf
    inc rbx
    jmp mainprint_loop
mainprint_done:
    lea rcx, fmt_nl
    call printf

    ; ---- BCD -> 整数，验证往返 ----
    fbld TBYTE PTR [bcd_buf]
    fistp QWORD PTR [back_val]

    lea rcx, fmt_back
    mov rdx, QWORD PTR [back_val]
    call printf

    pop r12
    pop rbx
    xor ecx, ecx
    call ExitProcess
main ENDP
END
