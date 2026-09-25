; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
ITERS equ 8000000
extern printf : PROC
extern ExitProcess : PROC
extern CreateThread : PROC
extern WaitForSingleObject : PROC

avxdata SEGMENT ALIGN(64) 'DATA'
    ; (align satisfied by SEGMENT ALIGN)
    ; 布局 A：两个计数器相邻 8 字节 —— 同一条缓存行（伪共享）
    layout_a0 QWORD 0
    layout_a1 QWORD 0
    ; 布局 B：相隔超过一条缓存行 —— 各占一行
    ; (align satisfied by SEGMENT ALIGN)
    layout_b0 QWORD 0
    QWORD 7 DUP(0)
    layout_b1 QWORD 0

    handles QWORD 2 DUP(0)

    fmt_head   BYTE "false sharing demo: 2 threads, %d increments each", 10, 0
    fmt_layout BYTE "layout %s: &c0=0x%016llX &c1=0x%016llX delta=%d (%s)", 10, 0
    fmt_cycles BYTE "  cycles = %llu", 10, 0
    tagA BYTE "A", 0
    tagB BYTE "B", 0
    same_line BYTE "same cache line", 0
    diff_line BYTE "different lines", 0
    fmt_ok BYTE "counters correct: %lld + %lld", 10, 0

avxdata ENDS

.code

; ------------------------------------------------------------
; thread_worker: RCX = 指向计数器的指针，纯本地自增（无竞争）
; ------------------------------------------------------------
thread_worker:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    mov r8d, ITERS
thread_workerloop:
    inc QWORD PTR [rbx]
    dec r8d
    jnz thread_workerloop
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

    mov QWORD PTR [rsp+32], 0        ; dwCreationFlags
    mov QWORD PTR [rsp+40], 0        ; lpThreadId
    xor ecx, ecx
    xor edx, edx
    lea r8, thread_worker
    mov r9, rbx
    call CreateThread
    mov QWORD PTR [handles], rax

    mov QWORD PTR [rsp+32], 0
    mov QWORD PTR [rsp+40], 0
    xor ecx, ecx
    xor edx, edx
    lea r8, thread_worker
    mov r9, r12
    call CreateThread
    mov QWORD PTR [handles+8], rax

    mov rcx, QWORD PTR [handles]
    mov edx, 0FFFFFFFFh
    call WaitForSingleObject
    mov rcx, QWORD PTR [handles+8]
    mov edx, 0FFFFFFFFh
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
REPORT MACRO tag_, c0_, c1_, cyc_, note_
    lea r8, [c0_]
    lea r9, [c1_]
    mov r11, r9
    sub r11, r8
    lea rcx, [fmt_layout]
    lea rdx, [tag_]
    mov [rsp+32], r11
    lea r11, [note_]
    mov [rsp+40], r11
    call printf
    lea rcx, [fmt_cycles]
    mov rdx, cyc_
    call printf
ENDM

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 64
    push rbx
    push r12

    lea rcx, fmt_head
    mov edx, ITERS
    call printf

    ; ---- 布局 A：伪共享 ----
    lea rdx, layout_a0
    lea r8, layout_a1
    call run_pair
    mov rbx, rax
    REPORT tagA, layout_a0, layout_a1, rbx, same_line

    ; ---- 布局 B：分行 ----
    lea rdx, layout_b0
    lea r8, layout_b1
    call run_pair
    mov rbx, rax
    REPORT tagB, layout_b0, layout_b1, rbx, diff_line

    ; ---- 正确性检查（两个布局互不影响）----
    lea rcx, fmt_ok
    mov rdx, QWORD PTR [layout_a0]
    mov r8, QWORD PTR [layout_a1]
    call printf

    pop r12
    pop rbx
    xor ecx, ecx
    call ExitProcess
main ENDP
END
