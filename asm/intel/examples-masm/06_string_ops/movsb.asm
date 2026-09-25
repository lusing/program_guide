; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    src_str    BYTE "Hello, NASM!", 0       ; 源字符串
    src_len    EQU $ - src_str - 1        ; 字符串长度(不含null) = 12

    fmt_single BYTE "1. movsb: copied 1 byte -> dest[0] = '%c' (0x%02X)", 10, 0
    fmt_full   BYTE '2. rep movsb: copied %lld bytes -> dest = [%s]', 10, 0
    fmt_done   BYTE "MOVS/MOVSB demo completed.", 10, 0


.data?
    dest_buf   BYTE 64 DUP(?); 目标缓冲区


.code

main PROC
    push rbp
    mov rbp, rsp
    ; 保存 non-volatile 寄存器 (RDI, RSI)
    push rdi
    push rsi
    sub rsp, 32                           ; 影子空间 (2 pushes + 32 = 48 bytes, aligned)

    ; -------------------------------------------------------
    ; 1. movsb - 移动单个字节
    ; movsb: 将 RSI 指向的字节复制到 RDI 指向的位置
    ;        然后根据 DF 自动调整 RSI/RDI (+1 若 DF=0)
    ; CLD: 清除方向标志 DF=0, 使指针向前递增
    ; -------------------------------------------------------
    lea rsi, src_str                    ; RSI = 源地址
    lea rdi, dest_buf                   ; RDI = 目标地址
    cld                                   ; DF=0, 向前移动
    movsb                                 ; dest_buf[0] = src_str[0] = 'H'
                                          ; RSI += 1, RDI += 1

    ; 打印移动的单个字节
    movzx r8, BYTE PTR [dest_buf]             ; R8 = 字符的ASCII值
    movzx rdx, BYTE PTR [dest_buf]            ; RDX = 字符(用于%c)
    lea rcx, fmt_single
    ; RDX 已设置, R8 已设置
    call printf

    ; -------------------------------------------------------
    ; 2. rep movsb - 重复移动整个字符串
    ; rep 前缀重复执行 movsb, 每次后 RCX 减1, 直到 RCX=0
    ; 效果等同于 memcpy(dest_buf, src_str, src_len)
    ; -------------------------------------------------------
    lea rsi, src_str                    ; RSI = 源地址
    lea rdi, dest_buf                   ; RDI = 目标地址
    mov rcx, src_len                      ; RCX = 要复制的字节数
    cld                                   ; DF=0, 向前移动
    rep movsb                             ; 重复复制 src_len 个字节
    mov BYTE PTR [dest_buf + src_len], 0      ; 添加 null 终止符

    ; 打印复制后的完整字符串
    mov rdx, src_len                      ; RDX = 复制的字节数
    lea r8, dest_buf                    ; R8 = 目标字符串地址
    lea rcx, fmt_full
    call printf

    ; -------------------------------------------------------
    ; 恢复 non-volatile 寄存器
    ; -------------------------------------------------------
    add rsp, 32
    pop rsi
    pop rdi

    ; -------------------------------------------------------
    ; 完成 (重新分配影子空间供 printf 和 ExitProcess 使用)
    ; -------------------------------------------------------
    sub rsp, 32                           ; 影子空间
    lea rcx, fmt_done
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
main ENDP
END
