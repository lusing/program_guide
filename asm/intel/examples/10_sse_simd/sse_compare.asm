; ============================================================
; sse_compare.asm - SSE比较指令
; ============================================================
; 演示:
;   - comiss xmm0, xmm1  比较标量单精度, 设置EFLAGS
;   - comisd xmm0, xmm1  比较标量双精度, 设置EFLAGS
;   - 比较后可用 JA/JB/JE 跳转
;   - cmpps xmm0, xmm1, 0  打包比较(0=EQ), 结果为掩码
;
; COMISS/COMISD 设置EFLAGS:
;   xmm0 > xmm1: CF=0, ZF=0  -> JA 跳转
;   xmm0 < xmm1: CF=1, ZF=0  -> JB 跳转
;   xmm0 = xmm1: CF=0, ZF=1  -> JE 跳转
;
; CMPPS 比较码:
;   0=EQ, 1=LT, 2=LE, 3=UNORD, 4=NEQ, 5=NLT, 6=NLE, 7=ORD
;   结果: 相等=0xFFFFFFFF, 不等=0x00000000 (每元素)
; ============================================================

default rel

section .data
    align 4
    f_val1  dd 3.14            ; 单精度float (较大)
    f_val2  dd 2.72            ; 单精度float (较小)
    align 8
    d_val1  dq 3.14159         ; 双精度double (较大)
    d_val2  dq 2.71828         ; 双精度double (较小)

    ; 打包比较数据
    align 16
    packed1 dd 1.0, 2.0, 3.0, 4.0
    align 16
    packed2 dd 1.0, 3.0, 3.0, 5.0
    align 16
    mask_buf dd 0, 0, 0, 0     ; 掩码结果存储

    ; 格式字符串
    fmt_comiss_gt db "COMISS: 3.14 > 2.72 is TRUE", 10, 0
    fmt_comiss_lt db "COMISS: 3.14 > 2.72 is FALSE", 10, 0
    fmt_comisd_gt db "COMISD: 3.14159 > 2.71828 is TRUE", 10, 0
    fmt_comisd_lt db "COMISD: 3.14159 > 2.71828 is FALSE", 10, 0
    fmt_cmpps     db "CMPPS EQ mask: 0x%08X 0x%08X 0x%08X 0x%08X", 10, 0
    fmt_cmpps_note db "  (0xFFFFFFFF=equal, 0x00000000=not equal)", 10, 0
    fmt_done      db "SSE compare demo completed.", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 48                ; 48字节: 32影子空间 + 16额外(第5个参数)

    ; -------------------------------------------------------
    ; 1. COMISS - 标量单精度比较 (设置EFLAGS)
    ;    比较 3.14 vs 2.72 (3.14 > 2.72)
    ; -------------------------------------------------------
    movss xmm0, [f_val1]       ; xmm0 = 3.14
    movss xmm1, [f_val2]       ; xmm1 = 2.72
    comiss xmm0, xmm1          ; 设置 EFLAGS

    ja .comiss_gt              ; xmm0 > xmm1
    ; fall through: xmm0 <= xmm1

.comiss_lt:
    lea rcx, [fmt_comiss_lt]
    call printf
    jmp .do_comisd

.comiss_gt:
    lea rcx, [fmt_comiss_gt]
    call printf

    ; -------------------------------------------------------
    ; 2. COMISD - 标量双精度比较 (设置EFLAGS)
    ;    比较 3.14159 vs 2.71828 (3.14159 > 2.71828)
    ; -------------------------------------------------------
.do_comisd:
    movsd xmm0, [d_val1]       ; xmm0 = 3.14159
    movsd xmm1, [d_val2]       ; xmm1 = 2.71828
    comisd xmm0, xmm1          ; 设置 EFLAGS

    ja .comisd_gt              ; xmm0 > xmm1
    ; fall through: xmm0 <= xmm1

.comisd_lt:
    lea rcx, [fmt_comisd_lt]
    call printf
    jmp .do_cmpps

.comisd_gt:
    lea rcx, [fmt_comisd_gt]
    call printf

    ; -------------------------------------------------------
    ; 3. CMPPS - 打包比较 (生成掩码)
    ;    比较 [1,2,3,4] vs [1,3,3,5] 是否相等
    ;    结果: [EQ, NE, EQ, NE] = [0xFFFFFFFF, 0, 0xFFFFFFFF, 0]
    ;
    ;    比较码: 0=EQ, 1=LT, 2=LE, 3=UNORD, 4=NEQ, ...
    ;    结果每元素: 相等=全1(0xFFFFFFFF), 不等=全0(0x00000000)
    ; -------------------------------------------------------
.do_cmpps:
    movaps xmm0, [packed1]     ; [1.0, 2.0, 3.0, 4.0]
    movaps xmm1, [packed2]     ; [1.0, 3.0, 3.0, 5.0]
    cmpps xmm0, xmm1, 0        ; 0 = EQ, 掩码结果在xmm0
    movaps [mask_buf], xmm0    ; 存储掩码到内存

    ; 打印4个掩码值 (需要5个参数: fmt + 4个mask)
    ; printf(fmt, m0, m1, m2, m3)
    ; RCX=fmt, RDX=m0, R8=m1, R9=m2, [rsp+32]=m3
    lea rcx, [fmt_cmpps]
    mov edx, [mask_buf]        ; 元素0掩码
    mov r8d, [mask_buf+4]      ; 元素1掩码
    mov r9d, [mask_buf+8]      ; 元素2掩码
    mov eax, [mask_buf+12]     ; 元素3掩码
    mov dword [rsp+32], eax    ; 第5个参数(栈上)
    call printf

    lea rcx, [fmt_cmpps_note]
    call printf

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    lea rcx, [fmt_done]
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
