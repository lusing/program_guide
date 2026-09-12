; ============================================================
; 文件: 05_control_flow/je_jne.asm
; 指令: JE, JNE, CMP
; 描述: 演示条件跳转（相等/不等）和if-else逻辑
; 编译: nasm -f win64 je_jne.asm -o je_jne.obj
; 链接: link /subsystem:console /entry:main je_jne.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
; 预期输出:
;   JE:  5 == 5  -> Equal (JE taken)
;   JNE: 5 != 3  -> Not equal (JNE taken)
;   If-else: 42 == 42 -> Match
; ============================================================
default rel

section .data
    fmt_je     db "JE:  5 == 5  -> Equal (JE taken)", 10, 0
    fmt_jne    db "JNE: 5 != 3  -> Not equal (JNE taken)", 10, 0
    fmt_match  db "If-else: 42 == 42 -> Match", 10, 0
    fmt_nomatch db "If-else: 42 == 42 -> No match", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32              ; shadow space

    ; -------------------------------------------------------
    ; 演示 JE: 比较两个相等的值
    ; CMP 执行 RAX - RDX 的减法运算，只设置标志位不存结果
    ; 5 - 5 = 0 -> ZF=1（零标志），JE 在 ZF=1 时跳转
    ; -------------------------------------------------------
    mov rax, 5
    mov rdx, 5
    cmp rax, rdx             ; 5 == 5, 设置 ZF=1
    je .equal_taken          ; JE: ZF=1时跳转（相等跳转）
    ; ZF=1 时不会执行到这里
    jmp .after_je
.equal_taken:
    lea rcx, [fmt_je]
    call printf
.after_je:

    ; -------------------------------------------------------
    ; 演示 JNE: 比较两个不相等的值
    ; 5 - 3 = 2 -> ZF=0（非零），JNE 在 ZF=0 时跳转
    ; -------------------------------------------------------
    mov rax, 5
    mov rdx, 3
    cmp rax, rdx             ; 5 != 3, 设置 ZF=0
    jne .notequal_taken     ; JNE: ZF=0时跳转（不等跳转）
    ; ZF=0 时不会执行到这里
    jmp .after_jne
.notequal_taken:
    lea rcx, [fmt_jne]
    call printf
.after_jne:

    ; -------------------------------------------------------
    ; 演示 if-else 逻辑
    ; 场景: 检查 value 是否等于 target
    ;   if (value == target) { 打印 Match }
    ;   else                 { 打印 No match }
    ; -------------------------------------------------------
    mov rax, 42              ; value
    mov rdx, 42              ; target
    cmp rax, rdx
    je .if_match            ; 相等则跳转到 match 分支

    ; --- else 分支 (不匹配) ---
    lea rcx, [fmt_nomatch]
    call printf
    jmp .after_ifelse        ; 跳过 match 分支

.if_match:
    ; --- if 分支 (匹配) ---
    lea rcx, [fmt_match]
    call printf

.after_ifelse:

    ; --- 退出进程 ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
