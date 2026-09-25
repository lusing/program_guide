; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    search_str  BYTE "Hello", 0               ; 搜索目标字符串
    str_len     EQU 5                        ; 字符串长度

    fmt_search  BYTE "%lld. Searching for '%c' in [%s]", 10, 0
    fmt_found   BYTE "   Found at position %lld (0-indexed)", 10, 0
    fmt_not     BYTE "   Not found (scanned all %lld bytes)", 10, 0
    fmt_done    BYTE "SCAS/SCASB demo completed.", 10, 0


.code

main PROC
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
    lea rdi, search_str                  ; RDI = 字符串地址
    mov rcx, str_len                       ; RCX = 最大扫描长度
    cld                                    ; DF=0, 向前扫描
    repne scasb                            ; 重复扫描直到找到或RCX=0

    mov r13, rcx                           ; r13 = 剩余字节数
    setz r14b                              ; r14b = 1 if found(ZF=1), 0 if not

    ; 打印搜索头
    lea rcx, fmt_search
    mov rdx, r15                           ; 序号
    mov r8, r12                            ; 字符
    lea r9, search_str                   ; 字符串
    call printf

    ; 根据结果打印
    test r14b, r14b
    jz mainnot1
    ; 找到 - 计算位置
    mov rax, str_len
    sub rax, r13
    dec rax                                ; pos = str_len - RCX - 1
    lea rcx, fmt_found
    mov rdx, rax
    call printf
    jmp mainnext1
mainnot1:
    ; 未找到
    lea rcx, fmt_not
    mov rdx, str_len
    call printf
mainnext1:

    ; -------------------------------------------------------
    ; 2. 搜索 'l' (存在, 在位置2)
    ; -------------------------------------------------------
    inc r15
    mov al, 'l'
    movzx r12, al
    lea rdi, search_str
    mov rcx, str_len
    cld
    repne scasb

    mov r13, rcx
    setz r14b

    lea rcx, fmt_search
    mov rdx, r15
    mov r8, r12
    lea r9, search_str
    call printf

    test r14b, r14b
    jz mainnot2
    mov rax, str_len
    sub rax, r13
    dec rax
    lea rcx, fmt_found
    mov rdx, rax
    call printf
    jmp mainnext2
mainnot2:
    lea rcx, fmt_not
    mov rdx, str_len
    call printf
mainnext2:

    ; -------------------------------------------------------
    ; 3. 搜索 'x' (不存在)
    ; -------------------------------------------------------
    inc r15
    mov al, 'x'
    movzx r12, al
    lea rdi, search_str
    mov rcx, str_len
    cld
    repne scasb

    mov r13, rcx
    setz r14b

    lea rcx, fmt_search
    mov rdx, r15
    mov r8, r12
    lea r9, search_str
    call printf

    test r14b, r14b
    jz mainnot3
    mov rax, str_len
    sub rax, r13
    dec rax
    lea rcx, fmt_found
    mov rdx, rax
    call printf
    jmp mainnext3
mainnot3:
    lea rcx, fmt_not
    mov rdx, str_len
    call printf
mainnext3:

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
