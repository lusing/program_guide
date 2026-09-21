; ============================================================
; 文件: 05_control_flow/ja_jb_unsigned.asm                 [Linux 版]
; 指令: JA / JAE / JB / JBE（无符号条件跳转）
; 描述: 同一个 CMP，换成无符号跳转会得出完全相反的结论
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/05_control_flow/ja_jb_unsigned.asm -o build/ja_jb_unsigned.o
; 链接: gcc -no-pie build/ja_jb_unsigned.o -o build/ja_jb_unsigned
; 对照: examples/05_control_flow/ja_jb_unsigned.asm
;
; 无符号跳转只认 CF 和 ZF：
;   JA  (Above)      : CF=0 且 ZF=0
;   JAE (Above=)     : CF=0
;   JB  (Below)      : CF=1
;   JBE (Below=)     : CF=1 或 ZF=1
; 换句话说：CMP 排出来的标志位是同一份数据，
; JG/JL 走 SF 与 OF 那条线，JA/JB 走 CF 那条线。
; 对 0xFFFFFFFF 这种值，两条线会给出相反答案 —— 这正是本例的重点。
; ============================================================
default rel

section .data
    fmt_ja  db "JA:  255 > 1 (unsigned)  -> Above (JA taken)", 10, 0
    fmt_jb  db "JB:  1 < 255 (unsigned)  -> Below (JB taken)", 10, 0
    fmt_flg db "  这次 CMP 之后的标志位：", 10, 0
    fmt_ja_u db "Unsigned: 0xFFFFFFFF > 1 -> Above (JA taken)", 10, 0
    fmt_jl_s db "Signed:   0xFFFFFFFF < 1 -> Less  (JL taken)", 10, 0
    fmt_key  db "Key: Same CMP, different jumps interpret flags differently!", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; --- JA：255 - 1 = 254，CF=0 ZF=0 -> 跳 ---
    mov eax, 255
    mov edx, 1
    cmp eax, edx
    ja .ja_taken
    jmp .after_ja
.ja_taken:
    lea rdi, [fmt_ja]
    xor eax, eax
    call printf
.after_ja:

    ; --- JB：1 - 255 需要借位，CF=1 -> 跳 ---
    mov eax, 1
    mov edx, 255
    cmp eax, edx
    jb .jb_taken
    jmp .after_jb
.jb_taken:
    lea rdi, [fmt_jb]
    xor eax, eax
    call printf
.after_jb:

    ; --------------------------------------------------------
    ; 关键演示：0xFFFFFFFF 同一个位模式
    ;   无符号 = 4294967295（大于 1）
    ;   有符号 = -1        （小于 1）
    ; CMP EAX,EDX 算出 0xFFFFFFFE：
    ;   CF=0（无借位）      -> JA 跳
    ;   SF=1, OF=0          -> JL 跳
    ; 两个跳转都会成立！
    ; --------------------------------------------------------
    mov eax, 0xFFFFFFFF
    mov edx, 1
    cmp eax, edx
    pushfq
    pop r10                          ; 抓一份标志位快照，把上面的推理坐实
    mov [rbp-8], r10
    ja .unsigned_above
.unsigned_above:
    lea rdi, [fmt_flg]
    xor eax, eax
    call printf
    mov rdi, [rbp-8]
    call l_putflags
    call l_nl

    lea rdi, [fmt_ja_u]
    xor eax, eax
    call printf

    ; --- 同一个位模式，改用有符号跳转 ---
    ; 必须重新 CMP：上面的 printf 已经把标志位冲掉了
    mov eax, 0xFFFFFFFF
    mov edx, 1
    cmp eax, edx
    jl .signed_less
.signed_less:
    lea rdi, [fmt_jl_s]
    xor eax, eax
    call printf

    ; --- 结论 ---
    lea rdi, [fmt_key]
    xor eax, eax
    call printf

    xor eax, eax
    leave
    ret

%include "linux_io.inc"
