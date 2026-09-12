; ============================================================
; rep_prefix.asm - REP前缀综合演示
; ============================================================
; 演示:
;   - rep movsb    内存复制 (memcpy)
;   - rep stosb    内存填充 (memset)
;   - repe cmpsb   字符串比较
;   - repne scasb  查找字符 (strlen 实现)
;
; REP前缀总结:
;   rep    - 无条件重复直到RCX=0 (movsb, stosb, lodsb, outsb等)
;   repe   - 重复直到RCX=0 或 ZF=0 (cmpsb, scasb) - 相等时继续
;   repne  - 重复直到RCX=0 或 ZF=1 (cmpsb, scasb) - 不等时继续
;
; Windows x64 注意:
;   RDI 和 RSI 是 non-volatile 寄存器, 使用前必须 push 保存
; ============================================================

default rel

section .data
    ; rep movsb 演示数据
    src_str    db "World!", 0              ; 源字符串
    src_len    equ $ - src_str - 1           ; 长度 = 6

    ; repe cmpsb 演示数据
    cmp1       db "Hello", 0
    cmp2_same  db "Hello", 0                ; 相同
    cmp2_diff  db "Hallo", 0                ; 不同 (位置1)
    cmp_len    equ 5

    ; repne scasb (strlen) 演示数据
    strlen_str db "Hello", 0

    ; rep stosb 演示参数
    fill_len   equ 10

    ; 格式字符串
    fmt_movsb  db "1. rep movsb: copied [%s] -> dest = [%s]", 10, 0
    fmt_stosb  db "2. rep stosb: filled %lld bytes with '%c' -> [%s]", 10, 0
    fmt_cmp_eq db "3. repe cmpsb: [%s] vs [%s] -> EQUAL", 10, 0
    fmt_cmp_df db "4. repe cmpsb: [%s] vs [%s] -> DIFFERENT at position %lld", 10, 0
    fmt_strlen db "5. repne scasb: strlen([%s]) = %lld", 10, 0
    fmt_done   db "REP prefix comprehensive demo completed.", 10, 0

section .bss
    dest_buf   resb 64                      ; movsb 目标缓冲区
    fill_buf   resb 64                      ; stosb 填充缓冲区

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

    ; =======================================================
    ; 1. rep movsb - 内存复制 (memcpy)
    ; =======================================================
    lea rsi, [src_str]                     ; RSI = 源
    lea rdi, [dest_buf]                    ; RDI = 目标
    mov rcx, src_len                       ; RCX = 字节数
    cld                                    ; DF=0
    rep movsb                              ; 复制 src_len 字节
    mov byte [dest_buf + src_len], 0       ; null 终止符

    ; 打印结果: printf(fmt, src, dest)
    lea rcx, [fmt_movsb]
    lea rdx, [src_str]                     ; 源字符串
    lea r8, [dest_buf]                     ; 目标字符串
    call printf

    ; =======================================================
    ; 2. rep stosb - 内存填充 (memset)
    ; =======================================================
    lea rdi, [fill_buf]                    ; RDI = 目标缓冲区
    mov al, '#'                            ; AL = 填充字符
    mov rcx, fill_len                      ; RCX = 填充长度
    cld                                    ; DF=0
    rep stosb                              ; 填充 fill_len 字节
    mov byte [fill_buf + fill_len], 0      ; null 终止符

    ; 打印结果: printf(fmt, len, char, buf)
    lea rcx, [fmt_stosb]
    mov rdx, fill_len                      ; 填充长度
    mov r8d, '#'                           ; 填充字符
    lea r9, [fill_buf]                     ; 结果缓冲区
    call printf

    ; =======================================================
    ; 3. repe cmpsb - 字符串比较 (相同)
    ; =======================================================
    lea rsi, [cmp1]                        ; RSI = 串1
    lea rdi, [cmp2_same]                   ; RDI = 串2
    mov rcx, cmp_len                       ; RCX = 比较长度
    cld                                    ; DF=0
    repe cmpsb                             ; 重复比较直到不等或RCX=0

    ; ZF=1 表示全部相等 (必须在printf前检查, 因printf破坏标志)
    jz .eq3
    ; 不会执行到这里 (两串相同), 但保持结构完整
    jmp .skip3
.eq3:
    lea rcx, [fmt_cmp_eq]
    lea rdx, [cmp1]
    lea r8, [cmp2_same]
    call printf
.skip3:

    ; =======================================================
    ; 4. repe cmpsb - 字符串比较 (不同)
    ; =======================================================
    lea rsi, [cmp1]                        ; RSI = 串1
    lea rdi, [cmp2_diff]                   ; RDI = 串2
    mov rcx, cmp_len                       ; RCX = 比较长度
    cld                                    ; DF=0
    repe cmpsb                             ; 重复比较直到不等或RCX=0

    ; 保存状态: ZF 和 RCX
    setz r12b                              ; r12b = 1 if equal
    mov r13, rcx                           ; r13 = 剩余字节数

    ; 计算差异位置 (即使相等也计算, 不影响结果)
    mov r14, cmp_len
    sub r14, r13
    dec r14                                ; r14 = 位置 = cmp_len - RCX - 1

    ; 根据结果选择格式
    test r12b, r12b
    jnz .eq4
    ; 不同
    lea rcx, [fmt_cmp_df]
    lea rdx, [cmp1]
    lea r8, [cmp2_diff]
    mov r9, r14                           ; 位置
    call printf
    jmp .skip4
.eq4:
    ; 相同 (此例不会走到)
    lea rcx, [fmt_cmp_eq]
    lea rdx, [cmp1]
    lea r8, [cmp2_diff]
    call printf
.skip4:

    ; =======================================================
    ; 5. repne scasb - strlen 实现
    ; 扫描字符串直到找到 null 终止符
    ; strlen = NOT(RCX) - 1 (经典技巧)
    ; =======================================================
    lea rdi, [strlen_str]                  ; RDI = 字符串
    xor al, al                            ; AL = 0 (查找 null 终止符)
    mov rcx, -1                           ; RCX = 最大扫描长度
    cld                                   ; DF=0
    repne scasb                           ; 扫描直到找到 \0
    not rcx                               ; RCX = ~RCX = 字符数+1 (含null)
    dec rcx                               ; RCX = strlen (不含null)
    mov r12, rcx                          ; r12 = strlen

    ; 打印结果: printf(fmt, str, strlen)
    lea rcx, [fmt_strlen]
    lea rdx, [strlen_str]
    mov r8, r12
    call printf

    ; -------------------------------------------------------
    ; 恢复 non-volatile 寄存器
    ; -------------------------------------------------------
    add rsp, 32
    pop rsi
    pop rdi

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    sub rsp, 32                            ; 影子空间
    lea rcx, [fmt_done]
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
