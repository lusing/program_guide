; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
ITERS    equ 1000000
NTHREADS equ 4
extern printf : PROC
extern ExitProcess : PROC
extern CreateThread : PROC
extern WaitForSingleObject : PROC

.data
    align 8
    counter  QWORD 0
    handles  QWORD NTHREADS DUP(0)
    mode     DWORD 0                ; 0 = plain inc, 1 = lock inc

    fmt_head BYTE "threads=%d iters=%d each", 10, 0
    fmt_res  BYTE "%-9s: total = %lld", 10, 0
    fmt_race BYTE "           -> LOST updates (race condition!)", 10, 0
    tag_plain BYTE "plain inc", 0
    tag_lock  BYTE "lock inc ", 0


.code

; ------------------------------------------------------------
; thread_worker: RCX =  AND counter（模式由全局 mode 决定）
; 遵循 Win64 约定：RBX 等非易失寄存器先保存
; ------------------------------------------------------------
thread_worker:
    push rbx
    sub rsp, 32                  ; 影子空间（本函数不调用 API，但保持规范）
    mov rbx, rcx                 ; RBX =  AND counter
    mov r8d, ITERS
    cmp DWORD PTR [mode], 0
    jne thread_workerlocked
thread_workerplain_loop:
    inc QWORD PTR [rbx]              ; 竞争！读-改-写不原子
    dec r8d
    jnz thread_workerplain_loop
    jmp thread_workerdone
thread_workerlocked:
thread_workerlock_loop:
    lock inc QWORD PTR [rbx]         ; 原子的读-改-写
    dec r8d
    jnz thread_workerlock_loop
thread_workerdone:
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
run_roundspawn:
    cmp ebx, NTHREADS
    jge run_roundwait
    ; CreateThread(NULL, 0, thread_worker,  AND counter, 0, NULL)
    ; 第 5/6 参必须布在 [rsp+20h] / [rsp+28h]（call 时刻）
    mov QWORD PTR [rsp+32], 0        ; dwCreationFlags = 0
    mov QWORD PTR [rsp+40], 0        ; lpThreadId = NULL
    xor ecx, ecx                 ; lpThreadAttributes
    xor edx, edx                 ; dwStackSize
    lea r8, thread_worker      ; lpStartAddress
    lea r9, counter            ; lpParameter
    call CreateThread
    ; 注意：[handles + rbx*8] 带索引无法 RIP 相对寻址（会触发
    ; MSVC 的 ADDR32 重定位错误 LNK2017），先用 lea 取基址再加索引
    lea r10, handles
    mov [r10 + rbx*8], rax
    inc ebx
    jmp run_roundspawn
run_roundwait:
    xor ebx, ebx
run_roundwait_loop:
    cmp ebx, NTHREADS
    jge run_rounddone
    lea r10, handles
    mov rcx, [r10 + rbx*8]
    mov edx, 0FFFFFFFFh          ; INFINITE
    call WaitForSingleObject
    inc ebx
    jmp run_roundwait_loop
run_rounddone:
    mov rax, QWORD PTR [counter]
    add rsp, 48
    pop rbx
    ret

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 64

    lea rcx, fmt_head
    mov edx, NTHREADS
    mov r8d, ITERS
    call printf

    ; ---- 第一轮：无锁 ----
    mov QWORD PTR [counter], 0
    mov DWORD PTR [mode], 0
    call run_round
    mov r12, rax                 ; 无锁总数
    lea rcx, fmt_res
    lea rdx, tag_plain
    mov r8, r12
    lea rcx, fmt_res
    lea rdx, tag_plain
    mov r8, r12
    call printf
    cmp r12, NTHREADS * ITERS     ; 被覆盖则必然更小
    jae mainok1
    lea rcx, fmt_race
    call printf
mainok1:

    ; ---- 第二轮：加锁前缀 ----
    mov QWORD PTR [counter], 0
    mov DWORD PTR [mode], 1
    call run_round
    mov r13, rax
    lea rcx, fmt_res
    lea rdx, tag_lock
    mov r8, r13
    call printf

    xor ecx, ecx
    call ExitProcess
main ENDP
END
