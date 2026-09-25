; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fill1_len  EQU 20                       ; 第一次填充长度
    fill2_len  EQU 15                       ; 第二次填充长度

    fmt_fill   BYTE "%lld. rep stosb: filled %lld bytes with '%c'", 10, 0
    fmt_result BYTE "   Result: %s", 10, 0
    fmt_done   BYTE "STOS/STOSB demo completed.", 10, 0


.data?
    buf1       BYTE 64 DUP(?); 缓冲区1
    buf2       BYTE 64 DUP(?); 缓冲区2


.code

main PROC
    push rbp
    mov rbp, rsp
    push rdi                               ; 保存 non-volatile (1个push)
    sub rsp, 40                            ; 影子空间+对齐 (1 push + 40 = 48, aligned)

    ; -------------------------------------------------------
    ; 1. rep stosb: 用 '*' 填充 20 字节
    ; 类似 memset(buf1, '*', 20)
    ; -------------------------------------------------------
    lea rdi, buf1                        ; RDI = 目标缓冲区
    mov al, '*'                            ; AL = 填充值
    mov rcx, fill1_len                     ; RCX = 填充长度
    cld                                    ; DF=0, RDI 递增
    rep stosb                              ; 重复填充
    mov BYTE PTR [buf1 + fill1_len], 0         ; null 终止符

    ; 打印填充信息
    lea rcx, fmt_fill
    mov rdx, 1                             ; 序号
    mov r8, fill1_len                      ; 长度
    mov r9, '*'                            ; 字符
    call printf

    ; 打印填充结果
    lea rcx, fmt_result
    lea rdx, buf1
    call printf

    ; -------------------------------------------------------
    ; 2. rep stosb: 用 '-' 填充 15 字节
    ; -------------------------------------------------------
    lea rdi, buf2
    mov al, '-'
    mov rcx, fill2_len
    cld
    rep stosb
    mov BYTE PTR [buf2 + fill2_len], 0

    ; 打印填充信息
    lea rcx, fmt_fill
    mov rdx, 2                             ; 序号
    mov r8, fill2_len
    mov r9, '-'
    call printf

    ; 打印填充结果
    lea rcx, fmt_result
    lea rdx, buf2
    call printf

    ; -------------------------------------------------------
    ; 恢复 non-volatile 寄存器
    ; -------------------------------------------------------
    add rsp, 40
    pop rdi

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    sub rsp, 32                            ; 影子空间
    lea rcx, fmt_done
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
main ENDP
END
