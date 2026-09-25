; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 4
    f_val1  DWORD 3.14            ; 单精度float (较大)
    f_val2  DWORD 2.72            ; 单精度float (较小)
    align 8
    d_val1  REAL8 3.14159         ; 双精度double (较大)
    d_val2  REAL8 2.71828         ; 双精度double (较小)

    ; 打包比较数据
    align 16
    packed1 DWORD 1.0, 2.0, 3.0, 4.0
    align 16
    packed2 DWORD 1.0, 3.0, 3.0, 5.0
    align 16
    mask_buf DWORD 0, 0, 0, 0     ; 掩码结果存储

    ; 格式字符串
    fmt_comiss_gt BYTE "COMISS: 3.14 > 2.72 is TRUE", 10, 0
    fmt_comiss_lt BYTE "COMISS: 3.14 > 2.72 is FALSE", 10, 0
    fmt_comisd_gt BYTE "COMISD: 3.14159 > 2.71828 is TRUE", 10, 0
    fmt_comisd_lt BYTE "COMISD: 3.14159 > 2.71828 is FALSE", 10, 0
    fmt_cmpps     BYTE "CMPPS EQ mask: 0x%08X 0x%08X 0x%08X 0x%08X", 10, 0
    fmt_cmpps_note BYTE "  (0xFFFFFFFF=equal, 0x00000000=not equal)", 10, 0
    fmt_done      BYTE "SSE compare demo completed.", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 48                ; 48字节: 32影子空间 + 16额外(第5个参数)

    ; -------------------------------------------------------
    ; 1. COMISS - 标量单精度比较 (设置EFLAGS)
    ;    比较 3.14 vs 2.72 (3.14 > 2.72)
    ; -------------------------------------------------------
    movss xmm0, DWORD PTR [f_val1]       ; xmm0 = 3.14
    movss xmm1, DWORD PTR [f_val2]       ; xmm1 = 2.72
    comiss xmm0, xmm1          ; 设置 EFLAGS

    ja maincomiss_gt              ; xmm0 > xmm1
    ; fall through: xmm0 <= xmm1

maincomiss_lt:
    lea rcx, fmt_comiss_lt
    call printf
    jmp maindo_comisd

maincomiss_gt:
    lea rcx, fmt_comiss_gt
    call printf

    ; -------------------------------------------------------
    ; 2. COMISD - 标量双精度比较 (设置EFLAGS)
    ;    比较 3.14159 vs 2.71828 (3.14159 > 2.71828)
    ; -------------------------------------------------------
maindo_comisd:
    movsd xmm0, QWORD PTR [d_val1]       ; xmm0 = 3.14159
    movsd xmm1, QWORD PTR [d_val2]       ; xmm1 = 2.71828
    comisd xmm0, xmm1          ; 设置 EFLAGS

    ja maincomisd_gt              ; xmm0 > xmm1
    ; fall through: xmm0 <= xmm1

maincomisd_lt:
    lea rcx, fmt_comisd_lt
    call printf
    jmp maindo_cmpps

maincomisd_gt:
    lea rcx, fmt_comisd_gt
    call printf

    ; -------------------------------------------------------
    ; 3. CMPPS - 打包比较 (生成掩码)
    ;    比较 [1,2,3,4] vs [1,3,3,5] 是否相等
    ;    结果: [EQ, NE, EQ, NE] = [0FFFFFFFFh, 0, 0FFFFFFFFh, 0]
    ;
    ;    比较码: 0=EQ, 1=LT, 2=LE, 3=UNORD, 4=NEQ, ...
    ;    结果每元素: 相等=全1(0FFFFFFFFh), 不等=全0(00000000h)
    ; -------------------------------------------------------
maindo_cmpps:
    movaps xmm0, XMMWORD PTR [packed1]     ; [1.0, 2.0, 3.0, 4.0]
    movaps xmm1, XMMWORD PTR [packed2]     ; [1.0, 3.0, 3.0, 5.0]
    cmpps xmm0, xmm1, 0        ; 0 = EQ, 掩码结果在xmm0
    movaps XMMWORD PTR [mask_buf], xmm0    ; 存储掩码到内存

    ; 打印4个掩码值 (需要5个参数: fmt + 4个mask)
    ; printf(fmt, m0, m1, m2, m3)
    ; RCX=fmt, RDX=m0, R8=m1, R9=m2, [rsp+32]=m3
    lea rcx, fmt_cmpps
    mov edx, DWORD PTR [mask_buf]        ; 元素0掩码
    mov r8d, DWORD PTR [mask_buf+4]      ; 元素1掩码
    mov r9d, DWORD PTR [mask_buf+8]      ; 元素2掩码
    mov eax, DWORD PTR [mask_buf+12]     ; 元素3掩码
    mov DWORD PTR [rsp+32], eax    ; 第5个参数(栈上)
    call printf

    lea rcx, fmt_cmpps_note
    call printf

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    lea rcx, fmt_done
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx
    call ExitProcess
main ENDP
END
