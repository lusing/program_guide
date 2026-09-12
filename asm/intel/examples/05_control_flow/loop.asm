; ============================================================
; 文件: 05_control_flow/loop.asm
; 指令: LOOP
; 描述: 演示 LOOP 指令循环累加 1+2+...+10 = 55
; 编译: nasm -f win64 loop.asm -o loop.obj
; 链接: link /subsystem:console /entry:main loop.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
; 预期输出:
;   Sum 1+2+...+10 = 55 (LOOP with ECX=10)
;
; LOOP 指令说明:
;   LOOP label : 计数器减 1，若结果 != 0 则跳转到 label
;   计数器为 ECX（RCX 低 32 位），由 mov ecx, 10 初始化
;
; 关键陷阱: ECX 与 printf 的第 1 参数寄存器 RCX 共用！
;   若在循环体内调用 printf，会破坏 ECX 计数器导致死循环或错误结果。
;   解决方案: 先完成循环把累加结果存入非易失寄存器 r12，
;             循环结束后再调用 printf 输出。
;
; 累加过程 (ECX 从 10 递减到 1):
;   第 1 轮: r12 += 10, ECX 10 -> 9
;   第 2 轮: r12 += 9,  ECX 9  -> 8
;   ...
;   第10轮: r12 += 1,  ECX 1  -> 0 (退出)
;   总和 = 10+9+...+1 = 55
; ============================================================
default rel

section .data
    fmt db "Sum 1+2+...+10 = %lld (LOOP with ECX=10)", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32              ; shadow space

    ; -------------------------------------------------------
    ; 使用 LOOP 计算 1+2+...+10
    ; mov ecx, 10 会同时清零 RCX 的高 32 位，故 RCX = ECX = 计数值
    ; xor r12d, r12d 写 32 位寄存器会清零 r12 的高 32 位，得到 r12 = 0
    ; -------------------------------------------------------
    mov ecx, 10              ; 循环计数器 = 10 (清零 RCX 高 32 位)
    xor r12d, r12d           ; r12 = 0 (累加器)

.lp:
    add r12, rcx             ; r12 += rcx (当前计数值 10,9,...,1)
    loop .lp                 ; ECX--, 若 ECX != 0 跳转到 .lp

    ; 循环结束，r12 = 55。此时 RCX 已被 LOOP 清零，可安全用于 printf
    lea rcx, [fmt]
    mov rdx, r12             ; 累加结果
    call printf

    ; --- 退出进程（main 不能用 ret！） ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
