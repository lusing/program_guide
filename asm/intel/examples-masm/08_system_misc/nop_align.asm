; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt_nop1   BYTE "1. Single-byte NOP (0x90) executed.", 10, 0
    fmt_nop2   BYTE "2. Multi-byte NOP (0x66 0x90, 2 bytes) executed.", 10, 0
    fmt_align  BYTE "3. ALIGN 16 directive: code aligned to 16-byte boundary.", 10, 0
    fmt_loop   BYTE "4. NOP padding in loop: 5 iterations completed (loop aligned).", 10, 0
    fmt_done   BYTE "NOP and ALIGN demo completed. (NOP does not change any state)", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; -------------------------------------------------------
    ; 1. 单字节 NOP (90h)
    ; NOP 不做任何操作，不改变任何寄存器或标志位
    ; 常用于填充、延迟、或对齐
    ; -------------------------------------------------------
    nop
    lea rcx, fmt_nop1
    call printf

    ; -------------------------------------------------------
    ; 2. 多字节 NOP (2字节: 66h 90h)
    ; 66h 是操作数大小前缀，90h 是 NOP
    ; 组合后形成2字节的NOP指令
    ; 其他多字节NOP: 0Fh 1Fh 00h (3字节), 0Fh 1Fh 40h 00h (4字节)等
    ; -------------------------------------------------------
    db 66h, 90h
    lea rcx, fmt_nop2
    call printf

    ; -------------------------------------------------------
    ; 3. ALIGN 伪指令
    ; NASM 的 ALIGN 伪指令在代码中插入NOP填充
    ; 使下一条指令对齐到指定的字节边界
    ; ALIGN 16 对齐到16字节边界，优化指令预取和分支预测
    ; -------------------------------------------------------
    align 16
    lea rcx, fmt_align
    call printf

    ; -------------------------------------------------------
    ; 4. NOP 在循环对齐中的应用
    ; 将循环入口对齐到16字节边界可以提高性能
    ; 使每次迭代从对齐的地址开始执行
    ; -------------------------------------------------------
    align 16
    mov r12d, 5                ; 循环计数 = 5
mainloop_start:
    nop                        ; NOP填充（演示用途）
    nop                        ; 实际代码中此处可能是指令
    dec r12d
    jnz mainloop_start

    lea rcx, fmt_loop
    call printf

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    lea rcx, fmt_done
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx              ; exit code = 0
    call ExitProcess
main ENDP
END
