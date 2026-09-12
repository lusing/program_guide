; ============================================================
; 文件: 03_logic_bitwise/bit_scan.asm
; 指令: BSF, BSR
; 描述: 位扫描指令演示（前向/反向扫描第一个置1位）
; 编译: nasm -f win64 bit_scan.asm -o bit_scan.obj
; 链接: link /subsystem:console /entry:main bit_scan.obj ucrt.lib kernel32.lib legacy_stdio_definitions.lib
; ============================================================
default rel

section .data
    fmt_bsf  db "BSF  0x%llx -> first set bit at index %lld  (low->high)", 10, 0
    fmt_bsr  db "BSR  0x%llx -> first set bit at index %lld  (high->low)", 10, 0
    fmt_zero db "BSF/BSR on 0x0 -> ZF=1 (no set bit found)", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    and rsp, -16             ; 确保16字节栈对齐
    sub rsp, 32              ; shadow space

    ; --- BSF: 从低位向高位扫描，找到第一个1的位置 ---
    ; 0x50 = 0b1010000, 最低位的1在 bit 4
    mov rbx, 0x50
    bsf rax, rbx             ; rax = 4
    lea rcx, [fmt_bsf]
    mov rdx, rbx             ; 输入值
    mov r8, rax              ; 扫描结果
    call printf

    ; --- BSR: 从高位向低位扫描，找到第一个1的位置 ---
    ; 0x50 = 0b1010000, 最高位的1在 bit 6
    mov rbx, 0x50
    bsr rax, rbx             ; rax = 6
    lea rcx, [fmt_bsr]
    mov rdx, rbx
    mov r8, rax
    call printf

    ; --- BSF on 0: 源操作数为0时 ZF=1 ---
    ; BSF/BSR 在源为0时设置 ZF=1，目标寄存器值未定义
    mov rbx, 0
    bsf rax, rbx             ; ZF=1 (rbx 为 0)
    jnz .skip_zero           ; ZF=0 则跳过（此处不跳）
    lea rcx, [fmt_zero]
    call printf
.skip_zero:

    xor ecx, ecx             ; exit code = 0
    call ExitProcess
