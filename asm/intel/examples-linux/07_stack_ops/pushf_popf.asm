; ============================================================
; 文件: 07_stack_ops/pushf_popf.asm                        [Linux 版]
; 指令: PUSHFQ / POPFQ
; 描述: 把整个 RFLAGS 存进栈、再原样装回去
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/07_stack_ops/pushf_popf.asm -o build/pushf_popf.o
; 链接: gcc -no-pie build/pushf_popf.o -o build/pushf_popf
; 对照: examples/07_stack_ops/pushf_popf.asm
;
; 本例用了 lib/linux_io.inc 里的 l_putflags —— 给一个 RFLAGS 值，
; 它把 CF PF AF ZF SF OF 六个标志一行打出来，省得每次手写位提取。
;
; ------------------------------------------------------------
; RFLAGS 里我们关心的位：
;   CF = bit 0    PF = bit 2    AF = bit 4
;   ZF = bit 6    SF = bit 7    OF = bit 11
; 想单独拿某一位有两条路：
;   位测试指令  bt rflags, 6  /  setc al
;   位运算      mov rax,r12 / shr rax,6 / and eax,1
; 本例两条都用了：主体走位运算，最后用 bt 再验一次。
;
; ------------------------------------------------------------
; Linux（SysV）在这个例子上比 Windows 省事很多：
;   Windows 版要 5 个参数，第 5 个得写 [rsp+32]（影子空间之上），
;   SysV 的 5 个参数 rdi/rsi/rdx/rcx/r8 全在寄存器里，一个字节栈都不用碰。
; 另外 Linux 上还能直接 `pushfq / popfq` 恢复标志后
; 用 jc/jz 真的跳一次，肉眼确认恢复生效。
; ============================================================
default rel

%include "linux_io.inc"

section .data
    fmt_set    db "1. 造标志：0xFF + 1 = 0x100（8 位溢出回绕成 0）", 10, 0
    lbl_saved  db "   存下来的标志（pushfq 那一刻）：", 10, 0
    fmt_chg    db "2. 换一批标志：1 + 1 = 2（无溢出）", 10, 0
    lbl_curr   db "   此刻的标志：", 10, 0
    fmt_rst    db "3. 用 popfq 把存下来的标志装回去", 10, 0
    lbl_rstd   db "   恢复后的标志：", 10, 0
    msg_cmp    db "   六个标志位与存档完全一致？ ", 0
    fmt_done   db "PUSHF/POPF demo completed.", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8],  r12                   ; r12 = 存档的 RFLAGS
    mov [rbp-16], r14                   ; r14 = 恢复后的 RFLAGS

    ; --------------------------------------------------------
    ; 1. 造出一组特征明显的标志：0xFF + 1
    ;    结果 AL=0x00，CF=1（进位出去）、ZF=1（结果为 0）
    ; --------------------------------------------------------
    mov al, 0xFF
    add al, 1

    pushfq                              ; RFLAGS 压栈
    pop r12                             ; 立刻弹进 r12（成对操作，栈保持平衡）

    lea rdi, [fmt_set]
    xor eax, eax
    call printf

    lea rdi, [lbl_saved]
    xor eax, eax
    call printf
    mov rdi, r12
    call l_putflags
    call l_nl

    ; --------------------------------------------------------
    ; 2. 再算一次，把标志全冲掉
    ;    1 + 1 = 2，不进位、不为零、不为负、不溢出
    ; --------------------------------------------------------
    mov al, 1
    add al, 1

    pushfq
    pop r14

    lea rdi, [fmt_chg]
    xor eax, eax
    call printf

    lea rdi, [lbl_curr]
    xor eax, eax
    call printf
    mov rdi, r14
    call l_putflags
    call l_nl

    ; --------------------------------------------------------
    ; 3. 把第 1 步存下的标志装回去
    ;    push r12 / popfq 是一对：先当普通数据压栈，再让 CPU 吃进去
    ; --------------------------------------------------------
    push r12
    popfq                               ; RFLAGS = r12

    pushfq
    pop r14                             ; r14 = 恢复之后的 RFLAGS

    lea rdi, [fmt_rst]
    xor eax, eax
    call printf

    lea rdi, [lbl_rstd]
    xor eax, eax
    call printf
    mov rdi, r14
    call l_putflags
    call l_nl

    ; --------------------------------------------------------
    ; 4. 两个证据，证明「真的恢复了」，而不只是看起来像
    ; --------------------------------------------------------
    ; 证据一：逐位比一比（只看 CF..OF 这 12 位）
    lea rdi, [msg_cmp]
    xor eax, eax
    call printf
    xor edi, edi
    mov rax, r14
    xor rax, r12
    and eax, 0x0FFF                     ; 相同则为 0，ZF 随即被置起
    sete dil                            ; dil = 1 表示完全一致
    call l_putbool
    call l_nl

    ; 证据二：直接让 CPU 按恢复后的标志跳一次
    ;   CF 被恢复成 1，所以 jc 一定会跳
    push r12
    popfq
    jc .cf_is_one                       ; 真的跳过去，说明 CF 确实=1
    lea rdi, [w_cf_zero]
    xor eax, eax
    call printf
    jmp .after_cf
.cf_is_one:
    lea rdi, [w_cf_one]
    xor eax, eax
    call printf
.after_cf:

    lea rdi, [fmt_done]
    xor eax, eax
    call printf

    mov r12, [rbp-8]
    mov r14, [rbp-16]
    xor eax, eax
    leave
    ret

section .data
    w_cf_one   db "   条件跳转确认：popfq 之后 jc 跳了 -> CF 确实是 1", 10, 0
    w_cf_zero  db "   条件跳转确认：jc 没跳 -> CF 是 0（不该出现）", 10, 0
