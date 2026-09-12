; ============================================================
; cmpsb.asm - 字符串比较 (CMPS/CMPSB)
; ============================================================
; 演示:
;   - cmpsb      比较单字节 (RSI vs RDI), 设置标志
;   - repe cmpsb 重复比较直到不等或RCX=0
;   - 用 ZF 判断结果: ZF=1 相等, ZF=0 不等
;   - 比较相同字符串和不同字符串
;
; repe cmpsb 行为:
;   每次比较 [RSI] 与 [RDI], 若相等(ZF=1)则继续
;   不等时停止, RCX 为剩余未比较的字节数
;
; Windows x64 注意:
;   RDI 和 RSI 是 non-volatile 寄存器, 使用前必须 push 保存
; ============================================================

default rel

section .data
    str1       db "Hello", 0                ; 基准字符串
    str2_same  db "Hello", 0                ; 相同字符串
    str2_diff  db "Hallo", 0                ; 不同字符串 (位置1不同)
    str_len    equ 5                         ; 字符串长度

    fmt_hdr    db "%lld. Comparing [%s] vs [%s]", 10, 0
    fmt_equal  db "   Result: EQUAL (all %lld bytes matched)", 10, 0
    fmt_diff   db "   Result: DIFFERENT at position %lld (RCX remaining: %lld)", 10, 0
    fmt_done   db "CMPS/CMPSB demo completed.", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    push rdi                               ; 保存 non-volatile
    push rsi                               ; 保存 non-volatile
    sub rsp, 32                            ; 影子空间 (2 pushes + 32 = 48, aligned)

    ; r15 = 比较序号计数器
    mov r15, 1

    ; -------------------------------------------------------
    ; 1. 比较相同字符串: "Hello" vs "Hello"
    ; -------------------------------------------------------
    lea rsi, [str1]                        ; RSI = 串1
    lea rdi, [str2_same]                  ; RDI = 串2
    mov rcx, str_len                      ; RCX = 比较长度
    cld                                   ; DF=0, 向前比较
    repe cmpsb                            ; 重复比较直到不等或RCX=0

    ; 保存 RCX 和 ZF (printf会破坏标志, 必须先保存)
    mov r13, rcx
    setz r12b                             ; r12b = 1 if equal(ZF=1)

    ; 打印比较头
    lea rcx, [fmt_hdr]
    mov rdx, r15                          ; 序号
    lea r8, [str1]                        ; 串1
    lea r9, [str2_same]                  ; 串2
    call printf

    ; 检查保存的 ZF (不能用jz, 因printf破坏了标志)
    test r12b, r12b
    jnz .eq1
    ; 不同 - 计算位置: pos = str_len - RCX - 1
    mov r14, str_len
    sub r14, r13
    dec r14                               ; r14 = 位置
    lea rcx, [fmt_diff]
    mov rdx, r14                          ; 位置
    mov r8, r13                           ; 剩余
    call printf
    jmp .next1
.eq1:
    ; 相同
    lea rcx, [fmt_equal]
    mov rdx, str_len                      ; 匹配长度
    call printf
.next1:

    ; -------------------------------------------------------
    ; 2. 比较不同字符串: "Hello" vs "Hallo"
    ; -------------------------------------------------------
    inc r15                               ; 序号 = 2
    lea rsi, [str1]                        ; RSI = 串1
    lea rdi, [str2_diff]                  ; RDI = 串2
    mov rcx, str_len                      ; RCX = 比较长度
    cld                                   ; DF=0
    repe cmpsb                            ; 重复比较直到不等或RCX=0

    ; 保存 RCX 和 ZF
    mov r13, rcx
    setz r12b                             ; r12b = 1 if equal(ZF=1)

    ; 打印比较头
    lea rcx, [fmt_hdr]
    mov rdx, r15                          ; 序号
    lea r8, [str1]                        ; 串1
    lea r9, [str2_diff]                   ; 串2
    call printf

    ; 检查保存的 ZF
    test r12b, r12b
    jnz .eq2
    ; 不同 - 计算位置
    mov r14, str_len
    sub r14, r13
    dec r14                               ; r14 = 位置
    lea rcx, [fmt_diff]
    mov rdx, r14                          ; 位置
    mov r8, r13                           ; 剩余
    call printf
    jmp .next2
.eq2:
    ; 相同
    lea rcx, [fmt_equal]
    mov rdx, str_len
    call printf
.next2:

    ; -------------------------------------------------------
    ; 恢复 non-volatile 寄存器
    ; -------------------------------------------------------
    add rsp, 32
    pop rsi
    pop rdi

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    sub rsp, 32                           ; 影子空间
    lea rcx, [fmt_done]
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
