; ============================================================
; 文件: 08_system_misc/rdtsc.asm                           [macOS 版]
; 指令: RDTSC / RDTSCP
; 描述: 读时间戳计数器 —— 用 CPU 自带的「纳秒级秒表」量代码
; 平台: macOS x86-64（Mach-O + System V AMD64）
; 汇编: nasm -I lib -f macho64 examples-macos/08_system_misc/rdtsc.asm -o build/rdtsc.o
; 链接: clang -arch x86_64 build/rdtsc.o -o build/rdtsc
; 对照: examples/08_system_misc/rdtsc.asm
;
; ------------------------------------------------------------
; RDTSC  把 64 位时间戳拆成 EDX（高 32 位）: EAX（低 32 位）
;        拼回来就是： shl rdx,32  /  or rax,rdx
;        注意 rdtsc 写的是 EDX/EAX，会自动把 RDX/RAX 的高位清零，
;        所以上面两句是安全的。
; RDTSCP 多一层「序列化」：等前面所有指令真正执行完再读计数，
;        顺带把 CPU 编号写进 ECX。测量代码段耗时时要用它，
;        否则乱序执行会让你量到「代码还没跑完就读了表」的假数据。
;
; 计数单位不是秒，是「参考时钟周期」。想换算成时间得知道
; 热频率；粗略估算时可以就用 rdtsc 差值比大小。
;
; ------------------------------------------------------------
; macOS 要点：rdtsc 不碰任何通用寄存器，所以移植只改调用约定。
; 中间结果放进 r12-r15（被调用者保存），退场前还原。
; ============================================================
default rel

section .data
    fmt_ts1     db "第一次 RDTSC 时间戳： %llu", 10, 0
    fmt_ts2     db "第二次 RDTSC 时间戳： %llu", 10, 0
    fmt_start   db "测量段起点： %llu", 10, 0
    fmt_end     db "测量段终点： %llu", 10, 0
    fmt_cycles  db "1000 次 NOP 循环消耗的周期数： %llu", 10, 0
    fmt_rdtscp  db "RDTSCP（序列化）时间戳： %llu", 10, 0
    fmt_note    db "提示：这个数会随负载浮动，但连续两次读一定严格递增。", 10, 0
    fmt_done    db "RDTSC demo completed.", 10, 0

section .text
    global _main
    extern _printf

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8],  r12
    mov [rbp-16], r13
    mov [rbp-24], r14                   ; 测量段起点
    mov [rbp-32], r15                   ; 测量段终点

    ; --------------------------------------------------------
    ; 1. 第一次读取
    ; --------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r12, rax

    lea rdi, [fmt_ts1]
    mov rsi, r12
    xor eax, eax
    call _printf

    ; --------------------------------------------------------
    ; 2. 再读一次，验证单调递增
    ; --------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r13, rax

    lea rdi, [fmt_ts2]
    mov rsi, r13
    xor eax, eax
    call _printf

    ; --------------------------------------------------------
    ; 3. 量一段代码：1000 次 NOP 循环
    ; --------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r14, rax                        ; 起点

    mov ecx, 1000
.measure_loop:
    nop
    dec ecx
    jnz .measure_loop

    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r15, rax                        ; 终点

    lea rdi, [fmt_start]
    mov rsi, r14
    xor eax, eax
    call _printf

    lea rdi, [fmt_end]
    mov rsi, r15
    xor eax, eax
    call _printf

    mov rax, r15
    sub rax, r14                        ; 周期差
    lea rdi, [fmt_cycles]
    mov rsi, rax
    xor eax, eax
    call _printf

    ; --------------------------------------------------------
    ; 4. RDTSCP：序列化版本，还会把 CPU 编号写进 ECX
    ; --------------------------------------------------------
    rdtscp
    shl rdx, 32
    or rax, rdx
    mov r12, rax

    lea rdi, [fmt_rdtscp]
    mov rsi, r12
    xor eax, eax
    call _printf

    lea rdi, [fmt_note]
    xor eax, eax
    call _printf

    lea rdi, [fmt_done]
    xor eax, eax
    call _printf

    mov r12, [rbp-8]
    mov r13, [rbp-16]
    mov r14, [rbp-24]
    mov r15, [rbp-32]
    xor eax, eax
    leave
    ret
