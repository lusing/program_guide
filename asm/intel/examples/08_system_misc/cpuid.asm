; ============================================================
; cpuid.asm - CPUID获取CPU信息
; ============================================================
; 演示:
;   - mov eax,0; cpuid  获取vendor字符串(EBX+EDX+ECX)
;   - mov eax,1; cpuid  获取CPU特性标志和Family/Model/Stepping
;   - 提取并打印vendor字符串 ("GenuineIntel" 或 "AuthenticAMD")
;   - 打印Family/Model/Stepping信息
;
; 注意: CPUID会破坏EAX,EBX,ECX,EDX
;       EBX对应RBX是non-volatile(被调用者保存)寄存器，必须保存!
; ============================================================

default rel

section .data
    ; CPUID结果存储
    vendor_buf   times 13 db 0     ; 12字符vendor字符串 + null终止符
    saved_rbx    dq 0              ; 保存RBX（CPUID会破坏EBX）
    family_val   dd 0
    model_val    dd 0
    stepping_val dd 0

    ; 格式字符串
    fmt_vendor   db "CPU Vendor String: %s", 10, 0
    fmt_fms      db "Family: %d, Model: %d, Stepping: %d", 10, 0
    fmt_features db "Feature flags (EDX): 0x%08X", 10, 0
    fmt_done     db "CPUID demo completed.", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; -------------------------------------------------------
    ; 保存RBX (non-volatile, CPUID会破坏EBX)
    ; 使用.data变量保存，避免栈对齐问题
    ; -------------------------------------------------------
    mov [saved_rbx], rbx

    ; -------------------------------------------------------
    ; CPUID EAX=0: 获取vendor字符串
    ; 返回: EBX=前4字符, EDX=中4字符, ECX=后4字符
    ; 例如Intel: EBX="Genu" EDX="ineI" ECX="ntel"
    ; -------------------------------------------------------
    xor eax, eax              ; EAX = 0 (vendor ID leaf)
    cpuid
    ; 将vendor字符串写入缓冲区
    mov [vendor_buf], ebx     ; 字符 0-3
    mov [vendor_buf+4], edx   ; 字符 4-7
    mov [vendor_buf+8], ecx   ; 字符 8-11
    mov byte [vendor_buf+12], 0  ; null终止符

    ; 打印vendor字符串
    lea rcx, [fmt_vendor]
    lea rdx, [vendor_buf]
    call printf

    ; -------------------------------------------------------
    ; CPUID EAX=1: 获取Feature信息和Family/Model/Stepping
    ; 返回: EAX=FMS信息, EDX=Feature标志, ECX=扩展Feature
    ; -------------------------------------------------------
    mov eax, 1                ; EAX = 1 (feature info leaf)
    cpuid

    ; 保存我们需要的数据（CPUID后EBX被破坏，但此时不需要EBX）
    mov r12d, eax             ; r12d = FMS信息
    mov r13d, edx             ; r13d = Feature标志

    ; -------------------------------------------------------
    ; 恢复RBX (所有CPUID调用完成后)
    ; -------------------------------------------------------
    mov rbx, [saved_rbx]

    ; -------------------------------------------------------
    ; 打印Feature标志 (EDX)
    ; 位0: FPU, 位23: MMX, 位25: SSE, 位26: SSE2, 位28: HTT
    ; -------------------------------------------------------
    lea rcx, [fmt_features]
    mov edx, r13d
    call printf

    ; -------------------------------------------------------
    ; 提取Family/Model/Stepping (从r12d = EAX)
    ;
    ; Stepping = EAX[3:0]
    ; Model    = EAX[7:4] | (EAX[19:16] << 4)   (扩展模型)
    ; Family   = EAX[11:8] (+ EAX[27:20] 如果 base family == 0xF)
    ; -------------------------------------------------------

    ; Stepping = EAX & 0xF
    mov eax, r12d
    and eax, 0xF
    mov [stepping_val], eax

    ; Model = (EAX >> 4) & 0xF | ((EAX >> 16) & 0xF) << 4
    mov eax, r12d
    shr eax, 4
    and eax, 0xF              ; base model
    mov ecx, r12d
    shr ecx, 16
    and ecx, 0xF              ; extended model
    shl ecx, 4
    or eax, ecx               ; full model
    mov [model_val], eax

    ; Family = (EAX >> 8) & 0xF
    ;         (+ (EAX >> 20) & 0xFF if base family == 0xF)
    mov eax, r12d
    shr eax, 8
    and eax, 0xF              ; base family
    cmp eax, 0xF
    jne .no_ext_family
    mov ecx, r12d
    shr ecx, 20
    and ecx, 0xFF             ; extended family
    add eax, ecx              ; full family = base + extended
.no_ext_family:
    mov [family_val], eax

    ; 打印Family/Model/Stepping
    ; printf(fmt, family, model, stepping) -> RCX, RDX, R8, R9
    lea rcx, [fmt_fms]
    mov edx, [family_val]
    mov r8d, [model_val]
    mov r9d, [stepping_val]
    call printf

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    lea rcx, [fmt_done]
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx              ; exit code = 0
    call ExitProcess
