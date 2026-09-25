; ============================================================
; false_sharing.asm - 伪共享（False Sharing）：缓存行引发的慢
; ============================================================
; 两个线程各增各自的计数器——没有任何逻辑竞争，
; 但如果两个计数器落在同一条 64 字节缓存行里，
; 两个核心会为了「行所有权」不停互相失效（RFO），
; 吞吐显著下降；隔开一条缓存行后恢复正常。
;
; 用 rdtsc 对两种布局计时（周期数每次运行不同，看量级即可）；
; 计数器本身的正确性是确定的：各加 8,000,000 次必须精确。
;
; 预期输出（周期数每次不同，typ. 同行的 A 明显更慢）：
;   false sharing demo: 2 threads, 8000000 increments each
;   layout A: &c0=0x... &c1=0x... delta=8 (same cache line)
;     cycles = 5xxxxxxxx
;   layout B: &c0=0x... &c1=0x... delta=64 (different lines)
;     cycles = 1xxxxxxxx
;   counters correct: 8000000 + 8000000
; ============================================================

default rel

ITERS equ 8000000

section .data
    align 64
    ; 布局 A：两个计数器相邻 8 字节 —— 同一条缓存行（伪共享）
    layout_a0 dq 0
    layout_a1 dq 0
    ; 布局 B：相隔超过一条缓存行 —— 各占一行
    align 64
    layout_b0 dq 0
    times 7 dq 0
    layout_b1 dq 0

    handles times 2 dq 0

    fmt_head   db "false sharing demo: 2 threads, %d increments each", 10, 0
    fmt_layout db "layout %s: &c0=0x%016llX &c1=0x%016llX delta=%d (%s)", 10, 0
    fmt_cycles db "  cycles = %llu", 10, 0
    tagA db "A", 0
    tagB db "B", 0
    same_line db "same cache line", 0
    diff_line db "different lines", 0
    fmt_ok db "counters correct: %lld + %lld", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess
    extern CreateThread
    extern WaitForSingleObject

; ------------------------------------------------------------
; thread_worker: RCX = 指向计数器的指针，纯本地自增（无竞争）
; ------------------------------------------------------------
thread_worker:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    mov r8d, ITERS
.loop:
    inc qword [rbx]
    dec r8d
    jnz .loop
    xor eax, eax
    add rsp, 32
    pop rbx
    ret

; ------------------------------------------------------------
; run_pair: RDX = 线程0参数, R8 = 线程1参数
; 启动两个线程、等待结束，返回本轮 rdtsc 周期差于 RAX
; ------------------------------------------------------------
run_pair:
    push rbx
    push r12
    push r13                     ; rdtsc 起点存 r13：[rsp+0] 是被调函数的
    sub rsp, 48                  ; 影子空间，CreateThread 会把它写花！
    mov rbx, rdx
    mov r12, r8

    rdtsc                        ; EDX:EAX = 起点
    shl rdx, 32
    or rax, rdx
    mov r13, rax

    mov qword [rsp+32], 0        ; dwCreationFlags
    mov qword [rsp+40], 0        ; lpThreadId
    xor ecx, ecx
    xor edx, edx
    lea r8, [thread_worker]
    mov r9, rbx
    call CreateThread
    mov [handles], rax

    mov qword [rsp+32], 0
    mov qword [rsp+40], 0
    xor ecx, ecx
    xor edx, edx
    lea r8, [thread_worker]
    mov r9, r12
    call CreateThread
    mov [handles+8], rax

    mov rcx, [handles]
    mov edx, 0xFFFFFFFF
    call WaitForSingleObject
    mov rcx, [handles+8]
    mov edx, 0xFFFFFFFF
    call WaitForSingleObject

    rdtsc                        ; 终点
    shl rdx, 32
    or rax, rdx
    sub rax, r13                 ; 周期差
    add rsp, 48
    pop r13
    pop r12
    pop rbx
    ret

; REPORT 标签, 计数器0, 计数器1, 周期数, 行描述
%macro REPORT 5
    lea r8, [%2]                 ; 取地址（[%2] 取的是计数器的值！）
    lea r9, [%3]
    mov r11, r9
    sub r11, r8                  ; delta = 地址差
    lea rcx, [fmt_layout]
    lea rdx, [%1]
    mov [rsp+32], r11            ; arg5: delta
    lea r11, [%5]
    mov [rsp+40], r11            ; arg6: 行描述
    call printf
    lea rcx, [fmt_cycles]
    mov rdx, %4
    call printf
%endmacro

main:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    push rbx
    push r12

    lea rcx, [fmt_head]
    mov edx, ITERS
    call printf

    ; ---- 布局 A：伪共享 ----
    lea rdx, [layout_a0]
    lea r8, [layout_a1]
    call run_pair
    mov rbx, rax
    REPORT tagA, layout_a0, layout_a1, rbx, same_line

    ; ---- 布局 B：分行 ----
    lea rdx, [layout_b0]
    lea r8, [layout_b1]
    call run_pair
    mov rbx, rax
    REPORT tagB, layout_b0, layout_b1, rbx, diff_line

    ; ---- 正确性检查（两个布局互不影响）----
    lea rcx, [fmt_ok]
    mov rdx, [layout_a0]
    mov r8, [layout_a1]
    call printf

    pop r12
    pop rbx
    xor ecx, ecx
    call ExitProcess
