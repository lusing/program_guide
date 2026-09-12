; ============================================================
; sse_mov.asm - SSE数据移动指令
; ============================================================
; 演示:
;   - movaps xmm0, [aligned_data]  对齐移动(要求16字节对齐!)
;   - movups xmm0, [data]          非对齐移动(不要求对齐)
;   - movss  xmm0, [float_val]     标量单精度(32bit)
;   - movsd  xmm0, [double_val]    标量双精度(64bit)
;
; 数据对齐: 用 align 16 确保16字节对齐
; ============================================================

default rel

section .data
    ; 16字节对齐的打包float数据 (4个float = 16字节)
    align 16
    packed_data  dd 1.0, 2.0, 3.0, 4.0

    ; 非对齐数据 (演示movups, 实际这里碰巧也对齐了)
    unaligned_data dd 5.0, 6.0, 7.0, 8.0

    ; 标量数据
    align 4
    float_val   dd 3.14            ; 单精度float (32位)
    align 8
    double_val  dq 2.718281828459045  ; 双精度double (64位)

    ; 存储缓冲区
    align 16
    xmm_buf     dd 0.0, 0.0, 0.0, 0.0   ; XMM寄存器存储缓冲区
    align 8
    temp_double dq 0.0                  ; 临时double存储

    ; 格式字符串
    fmt_movaps  db "MOVAPS: loaded 4 floats [1.0, 2.0, 3.0, 4.0]", 10, 0
    fmt_elem    db "  element[%d] = %f", 10, 0
    fmt_movups  db "MOVUPS: loaded 4 floats [5.0, 6.0, 7.0, 8.0]", 10, 0
    fmt_movss   db "MOVSS:  loaded scalar float  = %f", 10, 0
    fmt_movsd   db "MOVSD:  loaded scalar double = %f", 10, 0
    fmt_done    db "SSE data movement demo completed.", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; -------------------------------------------------------
    ; 1. MOVAPS - 对齐的打包移动 (要求16字节对齐)
    ;    从16字节对齐的内存加载128位到XMM寄存器
    ;    如果内存未对齐会触发异常!
    ; -------------------------------------------------------
    movaps xmm0, [packed_data]    ; 加载4个float到xmm0
    movaps [xmm_buf], xmm0        ; 存储到缓冲区

    lea rcx, [fmt_movaps]
    call printf

    ; 逐个打印元素
    ; printf("element[%d] = %f", index, double_val)
    ; 位置1(%d): RDX=index  位置2(%f): R8=double位模式, XMM2=double值

    ; 元素0: offset=0
    movss xmm0, [xmm_buf]         ; 加载float元素0
    cvtss2sd xmm2, xmm0           ; 转换为double到XMM2 (第2个浮点参数位)
    movsd [temp_double], xmm2     ; 存储double
    lea rcx, [fmt_elem]
    mov edx, 0                    ; 第1个变参: 索引(整数)
    mov r8, [temp_double]         ; 第2个变参: double位模式
    call printf                   ; XMM2已含double值

    ; 元素1: offset=4
    movss xmm0, [xmm_buf+4]
    cvtss2sd xmm2, xmm0
    movsd [temp_double], xmm2
    lea rcx, [fmt_elem]
    mov edx, 1
    mov r8, [temp_double]
    call printf

    ; 元素2: offset=8
    movss xmm0, [xmm_buf+8]
    cvtss2sd xmm2, xmm0
    movsd [temp_double], xmm2
    lea rcx, [fmt_elem]
    mov edx, 2
    mov r8, [temp_double]
    call printf

    ; 元素3: offset=12
    movss xmm0, [xmm_buf+12]
    cvtss2sd xmm2, xmm0
    movsd [temp_double], xmm2
    lea rcx, [fmt_elem]
    mov edx, 3
    mov r8, [temp_double]
    call printf

    ; -------------------------------------------------------
    ; 2. MOVUPS - 非对齐的打包移动 (不要求对齐)
    ;    与MOVAPS功能相同，但不要求内存16字节对齐
    ;    性能略低于MOVAPS (对齐数据应优先用MOVAPS)
    ; -------------------------------------------------------
    movups xmm0, [unaligned_data] ; 加载4个float
    movups [xmm_buf], xmm0        ; 存储到缓冲区

    lea rcx, [fmt_movups]
    call printf

    ; -------------------------------------------------------
    ; 3. MOVSS - 标量单精度移动 (32位float)
    ;    只移动XMM寄存器的最低32位
    ;    高96位保持不变 (加载时清零高96位)
    ; -------------------------------------------------------
    movss xmm0, [float_val]       ; 加载float 3.14到xmm0低32位
    cvtss2sd xmm1, xmm0           ; 转换为double用于打印
    movsd [temp_double], xmm1
    lea rcx, [fmt_movss]
    mov rdx, [temp_double]
    movsd xmm1, [temp_double]     ; XMM1 = double值
    call printf

    ; -------------------------------------------------------
    ; 4. MOVSD - 标量双精度移动 (64位double)
    ;    只移动XMM寄存器的最低64位
    ;    高64位保持不变
    ; -------------------------------------------------------
    movsd xmm0, [double_val]      ; 加载double 2.718...到xmm0低64位
    movsd [temp_double], xmm0     ; 存储到内存
    lea rcx, [fmt_movsd]
    mov rdx, [temp_double]
    movsd xmm1, [temp_double]     ; XMM1 = double值
    call printf

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    lea rcx, [fmt_done]
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
