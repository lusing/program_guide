; ============================================================
; 文件: 08_system_misc/nop_align.asm                       [macOS 版]
; 指令: NOP / 多字节 NOP / ALIGN 伪指令
; 描述: 空操作指令与代码对齐 —— 唯一「什么都不改」的指令
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/08_system_misc/nop_align.asm -o build/nop_align.o
; 链接: clang -arch x86_64 build/nop_align.o -o build/nop_align
; 对照: examples/08_system_misc/nop_align.asm
;
; ------------------------------------------------------------
; NOP 的字面意义是「不做任何事」：不收操作数、不改寄存器、
; 不碰标志位、不碰内存。它的价值全在「占位置」：
;   - 把后面的指令垫到 16 / 32 字节边界（取指和分支预测更友好）
;   - 给运行时的热补丁留出可覆盖的空间（内核和 JIT 常用）
;   - 在流水线里做极短的填充（现代 CPU 里 NOP 也真的会花时间）
;
; 单字节 NOP 是 0x90，也就是 XCHG EAX,EAX 的特例。
; 需要 2~9 字节的时候，就用 0x0F 0x1F 系列的多字节 NOP，
; 它们是 CPU 专门认下的「真 NOP」，不会真的读内存：
;   1 字节  0x90
;   2 字节  0x66 0x90
;   3 字节  0x0F 0x1F 0x00
;   4 字节  0x0F 0x1F 0x40 0x00
;   5 字节  0x0F 0x1F 0x44 0x00 0x00
;
; 那个「0x90 = XCHG EAX,EAX」还有个著名副产品：
; 用 0x90 覆盖掉一条指令的开头，就能把整条指令废掉 ——
; 这是很多「热补丁」手段的起点。
;
; ------------------------------------------------------------
; 这个例子在两个平台上的机器码完全一样，
; 差别只在怎么调 printf（rdi/rsi/rdx 那一套，没有影子空间）。
; ============================================================
default rel

section .data
    fmt_nop1   db "1. 单字节 NOP（0x90）已执行。", 10, 0
    fmt_nop2   db "2. 多字节 NOP（0x66 0x90，2 字节）已执行。", 10, 0
    fmt_align  db "3. ALIGN 16：下一条指令被垫到 16 字节边界。", 10, 0
    fmt_loop   db "4. 循环入口对齐后跑了 5 圈，NOP 垫在循环体里。", 10, 0
    fmt_done   db "NOP and ALIGN demo completed.（NOP 不改动任何状态）", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], r12                    ; 循环里借了 r12，退场要还原

    ; --------------------------------------------------------
    ; 1. 单字节 NOP：不改变任何寄存器或标志位
    ; --------------------------------------------------------
    nop
    lea rdi, [fmt_nop1]
    xor eax, eax
    call _printf

    ; --------------------------------------------------------
    ; 2. 多字节 NOP：0x66 是操作数大小前缀，0x90 是 NOP，
    ;    两个字节合起来仍是一条合法指令（不读内存）
    ; --------------------------------------------------------
    db 0x66, 0x90
    lea rdi, [fmt_nop2]
    xor eax, eax
    call _printf

    ; --------------------------------------------------------
    ; 3. ALIGN 16：NASM 会自动插入足够多的 NOP 让下一条
    ;    指令落在 16 字节边界上
    ; --------------------------------------------------------
    align 16
    lea rdi, [fmt_align]
    xor eax, eax
    call _printf

    ; --------------------------------------------------------
    ; 4. 循环入口对齐：把 .loop_start 垫到 16 字节边界，
    ;    让每次迭代都从同一条取指线上的同一个位置开始
    ; --------------------------------------------------------
    align 16
    mov r12d, 5
.loop_start:
    nop                                 ; 这里在真实代码里可能就是热补丁的位置
    nop
    dec r12d
    jnz .loop_start

    lea rdi, [fmt_loop]
    xor eax, eax
    call _printf

    lea rdi, [fmt_done]
    xor eax, eax
    call _printf

    mov r12, [rbp-8]
    xor eax, eax
    leave
    ret
