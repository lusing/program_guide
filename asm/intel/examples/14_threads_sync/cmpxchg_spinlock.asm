; ============================================================
; cmpxchg_spinlock.asm - 用 LOCK CMPXCHG 写一个自旋锁
; ============================================================
; 自旋锁的加锁/解锁只有两条指令：
;   加锁：lock cmpxchg [lock], new  ——CAS：EAX==0 时写入 1 并 ZF=1（成功）
;         失败则自旋重试，中间插 PAUSE（提示 CPU「这是自旋等待」，
;         降低功耗并减少流水线误预测惩罚，P核/E核都受益）
;   解锁：mov dword [lock], 0      ——普通写即可（x64 对齐写是原子的）
;
; 4 个线程 × 250000 次临界区自增，总数必须精确等于 1,000,000。
; 同时演示 cmpxchg 的语义：先比较 EAX 与目标，相等才交换。
;
; 预期输出:
;   spinlock: 4 threads x 250000 critical sections
;   lock cmpxchg acquired/released 1000000 times total
;   counter = 1000000 (exact, no lost updates)
; ============================================================

default rel

ITERS    equ 250000
NTHREADS equ 4

section .data
    align 16
    spinlock  dd 0               ; 0 = 未锁，1 = 已锁
    counter   dq 0
    acquires  dq 0               ; 成功加锁次数（应等于总临界区数）
    handles   times NTHREADS dq 0

    fmt_head  db "spinlock: %d threads x %d critical sections", 10, 0
    fmt_acq   db "lock cmpxchg acquired/released %lld times total", 10, 0
    fmt_res   db "counter = %lld (exact, no lost updates)", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess
    extern CreateThread
    extern WaitForSingleObject

; ------------------------------------------------------------
; thread_worker: RCX 未用（计数器是全局的）
; ------------------------------------------------------------
thread_worker:
    push rbx
    sub rsp, 32
    mov ebx, ITERS
.loop:
    ; ---- 加锁：CAS(spinlock: 0 -> 1) ----
    ; 大坑：cmpxchg 失败时会把目标值装入 EAX。若重试前不重置期望值，
    ; EAX=1 会和「已锁」状态(=1)匹配成功——两个人同时进门！
    ; 所以 xor eax,eax 必须放在重试循环【内部】。
    mov ecx, 1                   ; 想写入的值（已锁）
.retry:
    xor eax, eax                 ; 期望值（未锁）——每次重试都要重置
    lock cmpxchg dword [spinlock], ecx
    jz .acquired                 ; ZF=1：交换成功，我们持有锁
    pause                        ; 失败：等一下再试
    jmp .retry
.acquired:
    ; ---- 临界区 ----
    inc qword [counter]
    inc qword [acquires]
    ; ---- 解锁：普通对齐写即原子 ----
    mov dword [spinlock], 0
    dec ebx
    jnz .loop
    xor eax, eax
    add rsp, 32
    pop rbx
    ret

main:
    push rbp
    mov rbp, rsp
    push rbx                     ; 先压非易失寄存器再 sub
    sub rsp, 56                  ; 56+8+8 = 72 ≡ 8? 不对——见下：
                                 ; 入口 rsp≡8；push rbp →≡0；push rbx →≡8；
                                 ; sub 56(≡8 mod 16) →≡0 ✓ call 时栈 16 对齐

    lea rcx, [fmt_head]
    mov edx, NTHREADS
    mov r8d, ITERS
    call printf

    ; ---- 启动 4 个线程 ----
    xor ebx, ebx
.spawn:
    cmp ebx, NTHREADS
    jge .wait
    mov qword [rsp+32], 0        ; dwCreationFlags
    mov qword [rsp+40], 0        ; lpThreadId
    xor ecx, ecx
    xor edx, edx
    lea r8, [thread_worker]
    xor r9d, r9d                 ; 参数不用
    call CreateThread
    lea r10, [handles]           ; 带索引的寻址必须先 lea 基址（避免 ADDR32 重定位）
    mov [r10 + rbx*8], rax
    inc ebx
    jmp .spawn
.wait:
    xor ebx, ebx
.wait_loop:
    cmp ebx, NTHREADS
    jge .report
    lea r10, [handles]
    mov rcx, [r10 + rbx*8]
    mov edx, 0xFFFFFFFF
    call WaitForSingleObject
    inc ebx
    jmp .wait_loop
.report:
    lea rcx, [fmt_acq]
    mov rdx, [acquires]
    call printf
    lea rcx, [fmt_res]
    mov rdx, [counter]
    call printf

    add rsp, 56
    pop rbx
    xor ecx, ecx
    call ExitProcess
