; ============================================================
; scasb.asm - 字符串扫描 (SCAS/SCASB)
; ============================================================
; 演示:
;   - scasb       扫描单字节: 比较 AL 与 [RDI], 设置标志
;   - repne scasb 重复扫描直到找到(ZF=1)或RCX=0
;   - 计算找到字符的位置
;   - 查找存在和不存在的字符
;
; repne scasb 行为:
;   每次比较 AL 与 [RDI], 不等则继续(ZF=0)
;   找到时停止(ZF=1), RCX 为剩余未扫描字节数
;   位置 = max_len - RCX - 1
;
; Windows x64 注意:
;   RDI 是 non-volatile 寄存器, 使用前必须 push 保存
;   只 push 1 个寄存器, 需 sub rsp,40 保持16字节对齐
; ============================================================

default rel

section .data
    search_str  db "Hello", 0               ; 搜索目标字符串
    str_len     equ 5                        ; 字符串长度

    fmt_search  db "%lld. Searching for '%c' in [%s]", 10, 0
    fmt_found   db "   Found at position %lld (0-indexed)", 10, 0
    fmt_not     db "   Not found (scanned all %lld bytes)", 10, 0
    fmt_done    db "SCAS/SCASB demo completed.", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    push rdi                               ; 保存 non-volatile (1个push)
    sub rsp, 40                            ; 影子空间+对齐 (1 push + 40 = 48, aligned)

    mov r15, 1                             ; 序号计数器

    ; -------------------------------------------------------
    ; 1. 搜索 'o' (存在, 在位置4)
    ; -------------------------------------------------------
    mov al, 'o'                            ; AL = 要查找的字符
    movzx r12, al                          ; r12 = 字符 (保存供printf使用)
    lea rdi, [search_str]                  ; RDI = 字符串地址
    mov rcx, str_len                       ; RCX = 最大扫描长度
    cld                                    ; DF=0, 向前扫描
    repne scasb                            ; 重复扫描直到找到或RCX=0

    mov r13, rcx                           ; r13 = 剩余字节数
    setz r14b                              ; r14b = 1 if found(ZF=1), 0 if not

    ; 打印搜索头
    lea rcx, [fmt_search]
    mov rdx, r15                           ; 序号
    mov r8, r12                            ; 字符
    lea r9, [search_str]                   ; 字符串
    call printf

    ; 根据结果打印
    test r14b, r14b
    jz .not1
    ; 找到 - 计算位置
    mov rax, str_len
    sub rax, r13
    dec rax                                ; pos = str_len - RCX - 1
    lea rcx, [fmt_found]
    mov rdx, rax
    call printf
    jmp .next1
.not1:
    ; 未找到
    lea rcx, [fmt_not]
    mov rdx, str_len
    call printf
.next1:

    ; -------------------------------------------------------
    ; 2. 搜索 'l' (存在, 在位置2)
    ; -------------------------------------------------------
    inc r15
    mov al, 'l'
    movzx r12, al
    lea rdi, [search_str]
    mov rcx, str_len
    cld
    repne scasb

    mov r13, rcx
    setz r14b

    lea rcx, [fmt_search]
    mov rdx, r15
    mov r8, r12
    lea r9, [search_str]
    call printf

    test r14b, r14b
    jz .not2
    mov rax, str_len
    sub rax, r13
    dec rax
    lea rcx, [fmt_found]
    mov rdx, rax
    call printf
    jmp .next2
.not2:
    lea rcx, [fmt_not]
    mov rdx, str_len
    call printf
.next2:

    ; -------------------------------------------------------
    ; 3. 搜索 'x' (不存在)
    ; -------------------------------------------------------
    inc r15
    mov al, 'x'
    movzx r12, al
    lea rdi, [search_str]
    mov rcx, str_len
    cld
    repne scasb

    mov r13, rcx
    setz r14b

    lea rcx, [fmt_search]
    mov rdx, r15
    mov r8, r12
    lea r9, [search_str]
    call printf

    test r14b, r14b
    jz .not3
    mov rax, str_len
    sub rax, r13
    dec rax
    lea rcx, [fmt_found]
    mov rdx, rax
    call printf
    jmp .next3
.not3:
    lea rcx, [fmt_not]
    mov rdx, str_len
    call printf
.next3:

    ; -------------------------------------------------------
    ; 恢复 non-volatile 寄存器
    ; -------------------------------------------------------
    add rsp, 40
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
