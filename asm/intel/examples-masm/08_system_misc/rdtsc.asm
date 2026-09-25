; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    fmt_ts1     BYTE "RDTSC timestamp #1: %llu", 10, 0
    fmt_ts2     BYTE "RDTSC timestamp #2: %llu", 10, 0
    fmt_start   BYTE "Loop start timestamp: %llu", 10, 0
    fmt_end     BYTE "Loop end timestamp:   %llu", 10, 0
    fmt_cycles  BYTE "Cycles elapsed (1000 NOP loop): %llu", 10, 0
    fmt_rdtscp  BYTE "RDTSCP timestamp (serialized): %llu", 10, 0
    fmt_done    BYTE "RDTSC demo completed.", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; -------------------------------------------------------
    ; 1. RDTSC - 读取时间戳计数器
    ; 结果: EDX = 高32位, EAX = 低32位
    ; 合并为64位: shl rdx, 32; or rax, rdx
    ; -------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx               ; RAX = 完整的64位时间戳
    mov r12, rax              ; 保存到r12 (non-volatile, printf不会破坏)

    lea rcx, fmt_ts1
    mov rdx, r12
    call printf

    ; -------------------------------------------------------
    ; 2. 第二次RDTSC - 展示时间戳递增
    ; -------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r13, rax

    lea rcx, fmt_ts2
    mov rdx, r13
    call printf

    ; -------------------------------------------------------
    ; 3. 测量一段代码的执行周期
    ;    执行1000次NOP循环，测量前后的时间戳差值
    ; -------------------------------------------------------
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r14, rax              ; r14 = 开始时间

    ; 被测量的代码段: 1000次循环
    mov ecx, 1000
mainmeasure_loop:
    nop
    dec ecx
    jnz mainmeasure_loop

    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r15, rax              ; r15 = 结束时间

    ; 打印开始和结束时间戳
    lea rcx, fmt_start
    mov rdx, r14
    call printf

    lea rcx, fmt_end
    mov rdx, r15
    call printf

    ; 计算并打印周期差
    mov rax, r15
    sub rax, r14              ; RAX = 结束 - 开始 = 耗时周期数
    mov rdx, rax

    lea rcx, fmt_cycles
    call printf

    ; -------------------------------------------------------
    ; 4. RDTSCP - 序列化版本的时间戳读取
    ;    RDTSCP 会等待之前所有指令执行完成后再读取
    ;    额外将CPU标识写入ECX (此处不使用)
    ;    注意: RDTSCP 自2008年以后的CPU普遍支持
    ; -------------------------------------------------------
    rdtscp
    shl rdx, 32
    or rax, rdx
    mov r12, rax              ; 复用r12

    lea rcx, fmt_rdtscp
    mov rdx, r12
    call printf

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    lea rcx, fmt_done
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx              ; exit code = 0
    call ExitProcess
main ENDP
END
