; ============================================================
; complement.asm - 补码：同一串比特的两种解释
; ============================================================
; 计算机只有比特，「有无符号」是解释方式：
;   - 0xFF     作为 u8 = 255；作为 i8 = -1
;   - 取反加一 = 求补（neg 等价于 NOT + INC）
;   - INT64_MIN 取负还是 INT64_MIN（0x8000...0 的补还是自己）——
;     这就是 C 标准里 signed 溢出是未定义行为的原因之一
;
; 预期输出:
;   0xFF as u8 = 255, as i8 = -1
;   neg(5) = -5, bits = 0xFFFFFFFFFFFFFFFB
;   ~42 + 1 = -42
;   INT64_MIN = 0x8000000000000000, neg(INT64_MIN) = 0x8000000000000000
;   sign-extend 0x80 (i8) -> movsx -> 0xFFFFFFFFFFFFFF80
;   zero-extend 0x80 (u8) -> movzx -> 0x0000000000000080
; ============================================================

default rel

section .data
    five      dq 5
    forty_two dq 42

    fmt_pair1  db "0xFF as u8 = %u, as i8 = %d", 10, 0
    fmt_neg    db "neg(%d) = %lld, bits = 0x%016llX", 10, 0
    fmt_notinc db "~%lld + 1 = %lld", 10, 0
    fmt_min    db "INT64_MIN = 0x%016llX, neg(INT64_MIN) = 0x%016llX", 10, 0
    fmt_sext   db "sign-extend 0x80 (i8) -> movsx -> 0x%016llX", 10, 0
    fmt_zext   db "zero-extend 0x80 (u8) -> movzx -> 0x%016llX", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; ---- 0xFF 的两种解释 ----
    lea rcx, [fmt_pair1]
    mov edx, 255               ; 无符号解释
    mov r8d, -1                ; 有符号解释（同一个比特 11111111）
    call printf

    ; ---- neg 5 ----
    mov rax, [five]
    neg rax                    ; 等价于 not rax + inc rax
    lea rcx, [fmt_neg]
    mov edx, 5
    mov r8, rax
    mov r9, rax
    call printf

    ; ---- NOT + INC == NEG ----
    mov rax, [forty_two]
    not rax
    inc rax                    ; = -42
    lea rcx, [fmt_notinc]
    mov rdx, [forty_two]
    mov r8, rax
    call printf

    ; ---- INT64_MIN 的补仍是自身 ----
    mov rax, 0x8000000000000000
    mov rdx, rax
    neg rdx                    ; 仍是 0x8000...0（溢出，OF=1）
    lea rcx, [fmt_min]
    mov r8, rdx
    call printf

    ; ---- 符号扩展 vs 零扩展 ----
    mov al, 0x80
    movsx rax, al              ; 符号扩展
    lea rcx, [fmt_sext]
    mov rdx, rax
    call printf

    mov al, 0x80
    movzx rax, al              ; 零扩展
    lea rcx, [fmt_zext]
    mov rdx, rax
    call printf

    xor ecx, ecx
    call ExitProcess
