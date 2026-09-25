; ============================================================
; atomic_inc.asm - 数据竞争实锤：inc vs lock inc
; ============================================================
; 4 个线程各对同一个计数器加 1,000,000 次：
;   第一轮用普通 inc   ——inc [mem] 是「读-改-写」三条微操作，
;     4 个线程交错执行会互相覆盖，总数几乎必然少于 4,000,000
;   第二轮用 lock inc ——LOCK 前缀让整条读-改-写原子化，
;     总数恒等于 4,000,000
;
; API: CreateThread / WaitForSingleObject（kernel32）
; 线程入口按 Win64 约定：RCX = 参数指针，返回值放 RAX
;
; 预期输出（无锁总数每次运行都不同）：
;   threads=4 iters=1000000 each
;   plain inc  : total = 1723xxx  (LOST updates - race condition!)
;   lock inc   : total = 4000000  (exact)
; ============================================================

default rel

ITERS    equ 1000000
NTHREADS equ 4

section .data
    align 8
    counter  dq 0
    handles  times NTHREADS dq 0
    mode     dd 0                ; 0 = plain inc, 1 = lock inc

    fmt_head db "threads=%d iters=%d each", 10, 0
    fmt_res  db "%-9s: total = %lld", 10, 0
    fmt_race db "           -> LOST updates (race condition!)", 10, 0
    tag_plain db "plain inc", 0
    tag_lock  db "lock inc ", 0

section .text
    global main
    extern printf
    extern ExitProcess
    extern CreateThread
    extern WaitForSingleObject

; ------------------------------------------------------------
; thread_worker: RCX = &counter（模式由全局 mode 决定）
; 遵循 Win64 约定：RBX 等非易失寄存器先保存
; ------------------------------------------------------------
thread_worker:
    push rbx
    sub rsp, 32                  ; 影子空间（本函数不调用 API，但保持规范）
    mov rbx, rcx                 ; RBX = &counter
    mov r8d, ITERS
    cmp dword [mode], 0
    jne .locked
.plain_loop:
    inc qword [rbx]              ; 竞争！读-改-写不原子
    dec r8d
    jnz .plain_loop
    jmp .done
.locked:
.lock_loop:
    lock inc qword [rbx]         ; 原子的读-改-写
    dec r8d
    jnz .lock_loop
.done:
    xor eax, eax
    add rsp, 32
    pop rbx
    ret

; ------------------------------------------------------------
; run_round: 跑一轮（4 线程），返回总值于 RAX
; ------------------------------------------------------------
run_round:
    push rbx
    sub rsp, 48                  ; 影子空间 + 第 5/6 参的栈槽
    xor ebx, ebx                 ; 线程号
.spawn:
    cmp ebx, NTHREADS
    jge .wait
    ; CreateThread(NULL, 0, thread_worker, &counter, 0, NULL)
    ; 第 5/6 参必须布在 [rsp+0x20] / [rsp+0x28]（call 时刻）
    mov qword [rsp+32], 0        ; dwCreationFlags = 0
    mov qword [rsp+40], 0        ; lpThreadId = NULL
    xor ecx, ecx                 ; lpThreadAttributes
    xor edx, edx                 ; dwStackSize
    lea r8, [thread_worker]      ; lpStartAddress
    lea r9, [counter]            ; lpParameter
    call CreateThread
    ; 注意：[handles + rbx*8] 带索引无法 RIP 相对寻址（会触发
    ; MSVC 的 ADDR32 重定位错误 LNK2017），先用 lea 取基址再加索引
    lea r10, [handles]
    mov [r10 + rbx*8], rax
    inc ebx
    jmp .spawn
.wait:
    xor ebx, ebx
.wait_loop:
    cmp ebx, NTHREADS
    jge .done
    lea r10, [handles]
    mov rcx, [r10 + rbx*8]
    mov edx, 0xFFFFFFFF          ; INFINITE
    call WaitForSingleObject
    inc ebx
    jmp .wait_loop
.done:
    mov rax, [counter]
    add rsp, 48
    pop rbx
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    lea rcx, [fmt_head]
    mov edx, NTHREADS
    mov r8d, ITERS
    call printf

    ; ---- 第一轮：无锁 ----
    mov qword [counter], 0
    mov dword [mode], 0
    call run_round
    mov r12, rax                 ; 无锁总数
    lea rcx, [fmt_res]
    lea rdx, [tag_plain]
    mov r8, r12
    lea rcx, [fmt_res]
    lea rdx, [tag_plain]
    mov r8, r12
    call printf
    cmp r12, NTHREADS * ITERS     ; 被覆盖则必然更小
    jae .ok1
    lea rcx, [fmt_race]
    call printf
.ok1:

    ; ---- 第二轮：加锁前缀 ----
    mov qword [counter], 0
    mov dword [mode], 1
    call run_round
    mov r13, rax
    lea rcx, [fmt_res]
    lea rdx, [tag_lock]
    mov r8, r13
    call printf

    xor ecx, ecx
    call ExitProcess
