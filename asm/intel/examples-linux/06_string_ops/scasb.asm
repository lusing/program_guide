; ============================================================
; 文件: 06_string_ops/scasb.asm                            [Linux 版]
; 指令: SCASB / REPNE SCASB
; 描述: 字符串扫描 —— 用硬件循环找字符
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/06_string_ops/scasb.asm -o build/scasb.o
; 链接: gcc -no-pie build/scasb.o -o build/scasb
; 对照: examples/06_string_ops/scasb.asm
;
; SCASB 比较 AL 与 [RDI]，设置标志位但不改内存，RDI 自动 ±1。
; 配 REPNE（while RCX != 0 && ZF == 0）就能一路找下去：
;   找到了      -> ZF=1，RCX 里是「还没扫的字节数」
;   扫完了没找到 -> RCX=0，ZF=0
; 所以命中位置 = 总长度 - 剩余 RCX - 1。
; 用 REPE（ZF=1 继续）就变成「找第一个不等于 AL 的字节」，用途同样很广。
;
; Linux 上 RDI 是第 1 个参数寄存器，RCX 是第 4 个，
; 而这两个都被 SCASB 用掉了 —— 所以本例的每个 printf 参数都是重新装的。
; ============================================================
default rel

section .data
    search_str db "Hello", 0
    str_len    equ 5

    fmt_search db "%lld. 在 [%s] 里找 '%c'", 10, 0
    fmt_found  db "   找到了，位置 %lld（从 0 数起）", 10, 0
    fmt_not    db "   没找到（%lld 字节全扫完了，RCX 归零）", 10, 0
    fmt_done   db "SCAS/SCASB demo completed.", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8], r12                   ; r12-r15 都是被调用者保存寄存器，
    mov [rbp-16], r13                  ; 这里借它们跨 printf 存中间结果，
    mov [rbp-24], r14                  ; 退场前一律还原
    mov [rbp-32], r15

    mov r15, 1                         ; 序号计数器

    ; --------------------------------------------------------
    ; 1. 找 'o'（存在，位置 4）
    ; --------------------------------------------------------
    mov al, 'o'
    movzx r12d, al                     ; 存下要找的字符，供 printf 用
    lea rdi, [search_str]
    mov rcx, str_len
    cld
    repne scasb                        ; 一直扫到 ZF=1 或 RCX=0
    mov r13, rcx                       ; 剩余未扫描字节数
    setz r14b                          ; 找到则为 1

    lea rdi, [fmt_search]
    mov rsi, r15                       ; 第 2 个参数 %lld：序号
    lea rdx, [search_str]              ; 第 3 个参数 %s：字符串
    mov rcx, r12                       ; 第 4 个参数 %c：字符
    xor eax, eax
    call printf

    test r14b, r14b
    jz .not1
    mov rax, str_len
    sub rax, r13
    dec rax                            ; 位置 = 长度 - 剩余 - 1
    lea rdi, [fmt_found]
    mov rsi, rax
    xor eax, eax
    call printf
    jmp .next1
.not1:
    lea rdi, [fmt_not]
    mov rsi, str_len
    xor eax, eax
    call printf
.next1:

    ; --------------------------------------------------------
    ; 2. 找 'l'（存在，位置 2）
    ; --------------------------------------------------------
    inc r15
    mov al, 'l'
    movzx r12d, al
    lea rdi, [search_str]
    mov rcx, str_len
    cld
    repne scasb
    mov r13, rcx
    setz r14b

    lea rdi, [fmt_search]
    mov rsi, r15
    lea rdx, [search_str]
    mov rcx, r12
    xor eax, eax
    call printf

    test r14b, r14b
    jz .not2
    mov rax, str_len
    sub rax, r13
    dec rax
    lea rdi, [fmt_found]
    mov rsi, rax
    xor eax, eax
    call printf
    jmp .next2
.not2:
    lea rdi, [fmt_not]
    mov rsi, str_len
    xor eax, eax
    call printf
.next2:

    ; --------------------------------------------------------
    ; 3. 找 'x'（不存在，RCX 会被扫到 0）
    ; --------------------------------------------------------
    inc r15
    mov al, 'x'
    movzx r12d, al
    lea rdi, [search_str]
    mov rcx, str_len
    cld
    repne scasb
    mov r13, rcx
    setz r14b

    lea rdi, [fmt_search]
    mov rsi, r15
    lea rdx, [search_str]
    mov rcx, r12
    xor eax, eax
    call printf

    test r14b, r14b
    jz .not3
    mov rax, str_len
    sub rax, r13
    dec rax
    lea rdi, [fmt_found]
    mov rsi, rax
    xor eax, eax
    call printf
    jmp .next3
.not3:
    lea rdi, [fmt_not]
    mov rsi, str_len
    xor eax, eax
    call printf
.next3:

    lea rdi, [fmt_done]
    xor eax, eax
    call printf

    mov r12, [rbp-8]
    mov r13, [rbp-16]
    mov r14, [rbp-24]
    mov r15, [rbp-32]
    xor eax, eax
    leave
    ret
