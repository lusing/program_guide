; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
ITERS    equ 250000
NTHREADS equ 4
extern printf : PROC
extern ExitProcess : PROC
extern CreateThread : PROC
extern WaitForSingleObject : PROC

.data
    align 16
    spinlock  DWORD 0               ; 0 = 未锁，1 = 已锁
    counter   QWORD 0
    acquires  QWORD 0               ; 成功加锁次数（应等于总临界区数）
    handles   QWORD NTHREADS DUP(0)

    fmt_head  BYTE "spinlock: %d threads x %d critical sections", 10, 0
    fmt_acq   BYTE "lock cmpxchg acquired/released %lld times total", 10, 0
    fmt_res   BYTE "counter = %lld (exact, no lost updates)", 10, 0


.code

; ------------------------------------------------------------
; thread_worker: RCX 未用（计数器是全局的）
; ------------------------------------------------------------
thread_worker:
    push rbx
    sub rsp, 32
    mov ebx, ITERS
thread_workerloop:
    ; ---- 加锁：CAS(spinlock: 0 -> 1) ----
    ; 大坑：cmpxchg 失败时会把目标值装入 EAX。若重试前不重置期望值，
    ; EAX=1 会和「已锁」状态(=1)匹配成功——两个人同时进门！
    ; 所以 xor eax,eax 必须放在重试循环【内部】。
    mov ecx, 1                   ; 想写入的值（已锁）
thread_workerretry:
    xor eax, eax                 ; 期望值（未锁）——每次重试都要重置
    lock cmpxchg DWORD PTR [spinlock], ecx
    jz thread_workeracquired                 ; ZF=1：交换成功，我们持有锁
    pause                        ; 失败：等一下再试
    jmp thread_workerretry
thread_workeracquired:
    ; ---- 临界区 ----
    inc QWORD PTR [counter]
    inc QWORD PTR [acquires]
    ; ---- 解锁：普通对齐写即原子 ----
    mov DWORD PTR [spinlock], 0
    dec ebx
    jnz thread_workerloop
    xor eax, eax
    add rsp, 32
    pop rbx
    ret

main PROC
    push rbp
    mov rbp, rsp
    push rbx                     ; 先压非易失寄存器再 sub
    sub rsp, 56                  ; 56+8+8 = 72 ≡ 8? 不对——见下：
                                 ; 入口 rsp≡8；push rbp →≡0；push rbx →≡8；
                                 ; sub 56(≡8 mod 16) →≡0 ✓ call 时栈 16 对齐

    lea rcx, fmt_head
    mov edx, NTHREADS
    mov r8d, ITERS
    call printf

    ; ---- 启动 4 个线程 ----
    xor ebx, ebx
mainspawn:
    cmp ebx, NTHREADS
    jge mainwait
    mov QWORD PTR [rsp+32], 0        ; dwCreationFlags
    mov QWORD PTR [rsp+40], 0        ; lpThreadId
    xor ecx, ecx
    xor edx, edx
    lea r8, thread_worker
    xor r9d, r9d                 ; 参数不用
    call CreateThread
    lea r10, handles           ; 带索引的寻址必须先 lea 基址（避免 ADDR32 重定位）
    mov [r10 + rbx*8], rax
    inc ebx
    jmp mainspawn
mainwait:
    xor ebx, ebx
mainwait_loop:
    cmp ebx, NTHREADS
    jge mainreport
    lea r10, handles
    mov rcx, [r10 + rbx*8]
    mov edx, 0FFFFFFFFh
    call WaitForSingleObject
    inc ebx
    jmp mainwait_loop
mainreport:
    lea rcx, fmt_acq
    mov rdx, QWORD PTR [acquires]
    call printf
    lea rcx, fmt_res
    mov rdx, QWORD PTR [counter]
    call printf

    add rsp, 56
    pop rbx
    xor ecx, ecx
    call ExitProcess
main ENDP
END
