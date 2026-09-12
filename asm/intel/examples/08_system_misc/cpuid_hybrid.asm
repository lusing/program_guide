; ============================================================
; cpuid_hybrid.asm - 检测Intel混合架构(P核/E核)
; ============================================================
; 演示:
;   - CPUID Leaf 0:    获取最大支持leaf
;   - CPUID Leaf 0x1A: Intel Hybrid Information (核心类型)
;     EAX bits 31:24 = Core Type: 0x20=Atom(E核), 0x40=Core(P核)
;   - CPUID Leaf 7 (ECX=0): 检测AVX2/AVX-512支持
;     EBX bit 5 = AVX2, EBX bit 16 = AVX-512F
;
; 注意: CPUID会破坏EAX,EBX,ECX,EDX
;       EBX对应RBX是non-volatile(被调用者保存)寄存器，必须保存!
; ============================================================

default rel

section .data
    saved_rbx  dq 0              ; 保存RBX（CPUID会破坏EBX）

    ; 格式字符串
    fmt_hybrid  db "Hybrid Architecture Supported: %s", 10, 0
    fmt_core    db "Current Core Type: %s", 10, 0
    fmt_raw     db "Raw Core Type Value: 0x%02X", 10, 0
    fmt_avx2    db "AVX2: %s", 10, 0
    fmt_avx512  db "AVX-512: %s", 10, 0
    fmt_done    db "Hybrid architecture detection completed.", 10, 0

    ; 字符串常量
    str_yes     db "YES", 0
    str_no      db "NO", 0
    str_pcore   db "P-Core (Performance)", 0
    str_ecore   db "E-Core (Efficiency)", 0
    str_unknown db "Unknown", 0

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
    ; 1. CPUID Leaf 0: 获取最大支持leaf
    ; 返回: EAX = 最大leaf号
    ; -------------------------------------------------------
    xor eax, eax
    cpuid
    mov r12d, eax             ; r12d = 最大leaf (non-volatile, 跨printf保存)

    ; -------------------------------------------------------
    ; 2. 检查混合架构 (Leaf 0x1A - Intel Hybrid Information)
    ;    r13 = 核心类型字节 (0表示不支持/未报告)
    ;    r15 = 混合架构标志 (1=支持, 0=不支持)
    ; -------------------------------------------------------
    xor r13, r13              ; core_type = 0 (默认)
    xor r15, r15              ; hybrid_supported = 0 (默认)

    cmp r12d, 0x1A
    jb .skip_hybrid

    ; Leaf 0x1A 可用，执行查询
    mov eax, 0x1A
    xor ecx, ecx
    cpuid
    ; EAX bits 31:24 = Core Type
    shr eax, 24
    and eax, 0xFF
    mov r13d, eax             ; r13d = 核心类型字节

    ; 核心类型非0 → 混合架构支持
    test eax, eax
    jz .skip_hybrid
    mov r15, 1                ; hybrid_supported = 1

.skip_hybrid:

    ; -------------------------------------------------------
    ; 3. 检测AVX2/AVX-512 (Leaf 7, sub-leaf 0)
    ;    r14 = EBX特性标志 (0表示Leaf 7不可用)
    ; -------------------------------------------------------
    xor r14, r14              ; features = 0 (默认)

    cmp r12d, 7
    jb .skip_leaf7

    mov eax, 7
    xor ecx, ecx
    cpuid
    mov r14d, ebx             ; r14d = EBX特性标志 (non-volatile, 跨printf保存)

.skip_leaf7:

    ; -------------------------------------------------------
    ; 恢复RBX (所有CPUID调用完成)
    ; -------------------------------------------------------
    mov rbx, [saved_rbx]

    ; -------------------------------------------------------
    ; 打印: Hybrid Architecture Supported: YES/NO
    ; printf(fmt_hybrid, yes/no) -> RCX, RDX
    ; -------------------------------------------------------
    lea rcx, [fmt_hybrid]
    test r15, r15
    jz .hybrid_no
    lea rdx, [str_yes]
    jmp .hybrid_print
.hybrid_no:
    lea rdx, [str_no]
.hybrid_print:
    call printf

    ; -------------------------------------------------------
    ; 打印: Current Core Type
    ; 0x40 = P-Core, 0x20 = E-Core, 其他 = Unknown
    ; -------------------------------------------------------
    lea rcx, [fmt_core]
    cmp r13d, 0x40
    je .core_is_p
    cmp r13d, 0x20
    je .core_is_e
    lea rdx, [str_unknown]
    jmp .core_print
.core_is_p:
    lea rdx, [str_pcore]
    jmp .core_print
.core_is_e:
    lea rdx, [str_ecore]
.core_print:
    call printf

    ; -------------------------------------------------------
    ; 打印: Raw Core Type Value (原始值)
    ; -------------------------------------------------------
    lea rcx, [fmt_raw]
    mov edx, r13d
    call printf

    ; -------------------------------------------------------
    ; 打印: AVX2 support
    ; EBX bit 5 = AVX2 (0x20)
    ; -------------------------------------------------------
    lea rcx, [fmt_avx2]
    test r14d, 0x20           ; bit 5 = AVX2
    jz .avx2_no
    lea rdx, [str_yes]
    jmp .avx2_print
.avx2_no:
    lea rdx, [str_no]
.avx2_print:
    call printf

    ; -------------------------------------------------------
    ; 打印: AVX-512 support
    ; EBX bit 16 = AVX-512F (0x10000)
    ; -------------------------------------------------------
    lea rcx, [fmt_avx512]
    test r14d, 0x10000        ; bit 16 = AVX-512F
    jz .avx512_no
    lea rdx, [str_yes]
    jmp .avx512_print
.avx512_no:
    lea rdx, [str_no]
.avx512_print:
    call printf

    ; -------------------------------------------------------
    ; 完成
    ; -------------------------------------------------------
    lea rcx, [fmt_done]
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx              ; exit code = 0
    call ExitProcess
