; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    five      QWORD 5
    forty_two QWORD 42

    fmt_pair1  BYTE "0xFF as u8 = %u, as i8 = %d", 10, 0
    fmt_neg    BYTE "neg(%d) = %lld, bits = 0x%016llX", 10, 0
    fmt_notinc BYTE "~%lld + 1 = %lld", 10, 0
    fmt_min    BYTE "INT64_MIN = 0x%016llX, neg(INT64_MIN) = 0x%016llX", 10, 0
    fmt_sext   BYTE "sign-extend 0x80 (i8) -> movsx -> 0x%016llX", 10, 0
    fmt_zext   BYTE "zero-extend 0x80 (u8) -> movzx -> 0x%016llX", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; ---- 0FFh 的两种解释 ----
    lea rcx, fmt_pair1
    mov edx, 255               ; 无符号解释
    mov r8d, -1                ; 有符号解释（同一个比特 11111111）
    call printf

    ; ---- neg 5 ----
    mov rax, QWORD PTR [five]
    neg rax                    ; 等价于 not rax + inc rax
    lea rcx, fmt_neg
    mov edx, 5
    mov r8, rax
    mov r9, rax
    call printf

    ; ---- NOT + INC == NEG ----
    mov rax, QWORD PTR [forty_two]
    not rax
    inc rax                    ; = -42
    lea rcx, fmt_notinc
    mov rdx, QWORD PTR [forty_two]
    mov r8, rax
    call printf

    ; ---- INT64_MIN 的补仍是自身 ----
    mov rax, 8000000000000000h
    mov rdx, rax
    neg rdx                    ; 仍是 8000h...0（溢出，OF=1）
    lea rcx, fmt_min
    mov r8, rdx
    call printf

    ; ---- 符号扩展 vs 零扩展 ----
    mov al, 80h
    movsx rax, al              ; 符号扩展
    lea rcx, fmt_sext
    mov rdx, rax
    call printf

    mov al, 80h
    movzx rax, al              ; 零扩展
    lea rcx, fmt_zext
    mov rdx, rax
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
