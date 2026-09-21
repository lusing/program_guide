; ============================================================
; 文件: 06_string_ops/rep_prefix.asm                       [macOS 版]
; 指令: REP / REPE / REPNE 前缀综合演示
; 描述: 用硬件循环一口气完成 memcpy / memset / memcmp / strlen
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/06_string_ops/rep_prefix.asm -o build/rep_prefix.o
; 链接: clang -arch x86_64 build/rep_prefix.o -o build/rep_prefix
; 对照: examples/06_string_ops/rep_prefix.asm
;
; ------------------------------------------------------------
; 三个前缀的区别（看的是「继续条件」）：
;   REP    无条件重复，直到 RCX=0            —— 配 MOVS/STOS/LODS
;   REPE   等价于 REPZ：ZF=1 才继续（相等时继续）  —— 配 CMPS/SCAS
;   REPNE  等价于 REPNZ：ZF=0 才继续（不等时继续） —— 配 CMPS/SCAS
; 三种前缀都还会额外检查 RCX，所以「最多重复 RCX 次」是硬上限。
;
; 五个例子里最值得记的是第 5 个：repne scasb 求 strlen。
; 把 RCX 设成一个不可能的巨值（-1，即 0xFFFF...FFFF），扫到 '\0' 停下，
; 此时 RCX = -1 - (len+1)，取反减一就得到长度 —— 这是位运算的漂亮用法。
;
; ------------------------------------------------------------
; macOS 移植要点：
;   1. RSI/RDI/RCX 全是参数寄存器，每条字符串指令之后 printf 参数重装；
;   2. RSI/RDI 在 SysV 是调用者保存，不必像 Windows 那样 push/pop；
;   3. 标志位（ZF）在 printf 前必须用 setz 抢救出来；
;   4. 中间结果放 r12-r15，退场前还原（_main 靠 ret 返回）。
;   5. **取数据地址一律用 lea reg,[label]（配合文件里的 default rel）**。
;      写成 `mov rsi, cmp1` 这种「把绝对地址当立即数」的形式，nasm 会编出
;      一条 64 位绝对重定位，而 macOS 的可执行文件默认是 PIE，链接器直接报
;      ld: illegal text-relocation in '_main'+0x3A to 'cmp1'
;      Windows（非 PIE）和 Linux（本教程用 gcc -no-pie）都允许这么写，
;      所以同一行源码在另两个平台能过、只在 macOS 挂 —— 这是移植时最常踩的一个。
; ============================================================
default rel

section .data
    ; --- 1. rep movsb 的数据 ---
    src_str    db "World!", 0
    src_len    equ $ - src_str - 1      ; 6

    ; --- 3/4. repe cmpsb 的数据 ---
    cmp1       db "Hello", 0
    cmp2_same  db "Hello", 0
    cmp2_diff  db "Hallo", 0
    cmp_len    equ 5

    ; --- 5. repne scasb 的数据 ---
    strlen_str db "Hello", 0

    ; --- 2. rep stosb 的填充长度 ---
    fill_len   equ 10

    fmt_movsb  db "1. rep movsb：把 [%s] 复制过去 -> dest = [%s]", 10, 0
    fmt_stosb  db "2. rep stosb：用 '%c' 填了 %lld 个字节 -> [%s]", 10, 0
    fmt_cmp_eq db "3. repe cmpsb：[%s] 与 [%s] -> 完全相同", 10, 0
    fmt_cmp_df db "4. repe cmpsb：[%s] 与 [%s] -> 第 %lld 个字节起不同", 10, 0
    fmt_strlen db "5. repne scasb：strlen([%s]) = %lld", 10, 0
    fmt_done   db "REP prefix comprehensive demo completed.", 10, 0

section .bss
    dest_buf   resb 64                  ; movsb 的目标缓冲区
    fill_buf   resb 64                  ; stosb 的填充缓冲区

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8],  r12
    mov [rbp-16], r13
    mov [rbp-24], r14

    ; ========================================================
    ; 1. rep movsb —— 内存复制（这就是 memcpy 的内核）
    ; ========================================================
    lea rsi, [src_str]                  ; RSI = 源
    lea rdi, [dest_buf]                 ; RDI = 目标
    mov rcx, src_len                    ; RCX = 字节数
    cld
    rep movsb                           ; 复制 src_len 个字节
    mov byte [dest_buf + src_len], 0    ; 补上字符串结尾

    lea rdi, [fmt_movsb]
    lea rsi, [src_str]                  ; 取地址必须用 lea（RIP 相对），见下方移植要点 5
    lea rdx, [dest_buf]
    xor eax, eax
    call _printf

    ; ========================================================
    ; 2. rep stosb —— 内存填充（memset）
    ;    注意 MOVS/STOS 之后 RSI/RDI/RCX 都变了，参数必须重装
    ; ========================================================
    lea rdi, [fill_buf]
    mov al, '#'                         ; AL = 填充字节
    mov rcx, fill_len
    cld
    rep stosb
    mov byte [fill_buf + fill_len], 0

    lea rdi, [fmt_stosb]
    mov esi, '#'                        ; %c：格式串里 %c 在前
    mov rdx, fill_len                   ; %lld：长度
    lea rcx, [fill_buf]                 ; %s：结果缓冲区
    xor eax, eax
    call _printf

    ; ========================================================
    ; 3. repe cmpsb —— 比较两个相同的串
    ; ========================================================
    lea rsi, [cmp1]
    lea rdi, [cmp2_same]
    mov rcx, cmp_len
    cld
    repe cmpsb
    setz r12b                           ; 立刻保存 ZF（printf 会冲掉标志）

    test r12b, r12b
    jz .neq3                            ; 本例不会走到这里
    lea rdi, [fmt_cmp_eq]
    lea rsi, [cmp1]
    lea rdx, [cmp2_same]
    xor eax, eax
    call _printf
.neq3:

    ; ========================================================
    ; 4. repe cmpsb —— 比较两个不同的串
    ; ========================================================
    lea rsi, [cmp1]
    lea rdi, [cmp2_diff]
    mov rcx, cmp_len
    cld
    repe cmpsb

    setz r12b                           ; r12b = 1 表示相等
    mov r13, rcx                        ; r13 = 剩余未比字节数

    mov r14, cmp_len
    sub r14, r13
    dec r14                             ; 位置 = 长度 - 剩余 - 1

    test r12b, r12b
    jnz .eq4
    lea rdi, [fmt_cmp_df]
    lea rsi, [cmp1]
    lea rdx, [cmp2_diff]
    mov rcx, r14                        ; 首个不同的位置
    xor eax, eax
    call _printf
    jmp .skip4
.eq4:
    lea rdi, [fmt_cmp_eq]
    lea rsi, [cmp1]
    lea rdx, [cmp2_diff]
    xor eax, eax
    call _printf
.skip4:

    ; ========================================================
    ; 5. repne scasb —— 求 strlen 的经典技巧
    ;    RCX 先设成 -1（最大值），扫到 '\0' 停下后
    ;    strlen = ~RCX - 1
    ; ========================================================
    lea rdi, [strlen_str]
    xor al, al                          ; AL = 0，找的就是字符串结尾
    mov rcx, -1                         ; RCX = 0xFFFFFFFFFFFFFFFF
    cld
    repne scasb                         ; 不等（ZF=0）就继续扫

    not rcx                             ; RCX = 已扫字节数（含 '\0'）
    dec rcx                             ; 去掉 '\0' 就是长度
    mov r12, rcx

    lea rdi, [fmt_strlen]
    lea rsi, [strlen_str]
    mov rdx, r12
    xor eax, eax
    call _printf

    lea rdi, [fmt_done]
    xor eax, eax
    call _printf

    mov r12, [rbp-8]
    mov r13, [rbp-16]
    mov r14, [rbp-24]
    xor eax, eax
    leave
    ret
