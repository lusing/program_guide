; ============================================================
; 文件: 05_control_flow/jo_js_flags.asm
; 指令: JO, JS, JP (溢出/符号/奇偶标志跳转)
; 描述: 演示基于 OF/SF/PF 三个标志位的条件跳转
; 编译: nasm -f win64 jo_js_flags.asm -o jo_js_flags.obj
; 链接: link /subsystem:console /entry:main jo_js_flags.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
; 预期输出:
;   OF: 127 + 1 -> Overflow (JO taken, OF=1)
;   SF: 0 - 1 -> Negative (JS taken, SF=1)
;   PF: 3 (0b00000011, two 1s) -> Even parity (JP taken, PF=1)
;
; 指令说明:
;   JO : 溢出标志 OF=1 时跳转 (有符号算术溢出)
;   JS : 符号标志 SF=1 时跳转 (结果为负)
;   JP : 奇偶标志 PF=1 时跳转 (结果低 8 位含偶数个 1)
;
; 关键: 标志位由前一条运算指令设置，跳转指令紧随其后读取
;       printf 调用会破坏标志位，故每次检测后立即跳转、不在中间插入 printf
; ============================================================
default rel

section .data
    fmt_of db "OF: 127 + 1 -> Overflow (JO taken, OF=1)", 10, 0
    fmt_sf db "SF: 0 - 1 -> Negative (JS taken, SF=1)", 10, 0
    fmt_pf db "PF: 3 (0b00000011, two 1s) -> Even parity (JP taken, PF=1)", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32              ; shadow space

    ; -------------------------------------------------------
    ; 溢出标志 OF: 127 + 1 (有符号字节溢出)
    ; AL = 127 (0x7F) 是 8 位有符号最大正数
    ; ADD AL, 1 = 128 = 0x80，作为有符号字节是 -128，发生溢出 -> OF=1
    ; JO 在 OF=1 时跳转
    ; -------------------------------------------------------
    mov al, 127              ; 0x7F (有符号 +127)
    add al, 1                ; 127+1=128，有符号溢出 -> OF=1
    jo .of_detected          ; OF=1 -> 跳转
    ; 不会执行到这里
    jmp .after_of
.of_detected:
    lea rcx, [fmt_of]
    call printf
.after_of:

    ; -------------------------------------------------------
    ; 符号标志 SF: 0 - 1 (结果为负)
    ; EAX = 0, SUB EAX, 1 = -1 = 0xFFFFFFFF，最高位(符号位)=1 -> SF=1
    ; JS 在 SF=1 时跳转
    ; -------------------------------------------------------
    xor eax, eax             ; EAX = 0
    sub eax, 1               ; 0 - 1 = -1 (0xFFFFFFFF) -> SF=1
    js .sf_detected          ; SF=1 -> 跳转
    jmp .after_sf
.sf_detected:
    lea rcx, [fmt_sf]
    call printf
.after_sf:

    ; -------------------------------------------------------
    ; 奇偶标志 PF: AL=3 (0b00000011，含 2 个 1，偶数)
    ; TEST AL, AL 做 AND 运算，结果 = AL = 3，低 8 位 0x03 含 2 个 1
    ; PF 在结果低 8 位含偶数个 1 时置 1 -> PF=1
    ; JP 在 PF=1 时跳转
    ; -------------------------------------------------------
    mov al, 3                ; 0x03 = 00000011，两个 1 (偶数)
    test al, al              ; AND AL,AL，结果=3，PF=1
    jp .pf_detected          ; PF=1 -> 跳转
    jmp .after_pf
.pf_detected:
    lea rcx, [fmt_pf]
    call printf
.after_pf:

    ; --- 退出进程（main 不能用 ret！） ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
