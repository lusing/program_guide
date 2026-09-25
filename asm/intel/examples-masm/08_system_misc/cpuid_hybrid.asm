; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    saved_rbx  QWORD 0              ; 保存RBX（CPUID会破坏EBX）

    ; 格式字符串
    fmt_hybrid  BYTE "Hybrid Architecture Supported: %s", 10, 0
    fmt_core    BYTE "Current Core Type: %s", 10, 0
    fmt_raw     BYTE "Raw Core Type Value: 0x%02X", 10, 0
    fmt_avx2    BYTE "AVX2: %s", 10, 0
    fmt_avx512  BYTE "AVX-512: %s", 10, 0
    fmt_done    BYTE "Hybrid architecture detection completed.", 10, 0

    ; 字符串常量
    str_yes     BYTE "YES", 0
    str_no      BYTE "NO", 0
    str_pcore   BYTE "P-Core (Performance)", 0
    str_ecore   BYTE "E-Core (Efficiency)", 0
    str_unknown BYTE "Unknown", 0


.code

main PROC
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; -------------------------------------------------------
    ; 保存RBX (non-volatile, CPUID会破坏EBX)
    ; 使用.data变量保存，避免栈对齐问题
    ; -------------------------------------------------------
    mov QWORD PTR [saved_rbx], rbx

    ; -------------------------------------------------------
    ; 1. CPUID Leaf 0: 获取最大支持leaf
    ; 返回: EAX = 最大leaf号
    ; -------------------------------------------------------
    xor eax, eax
    cpuid
    mov r12d, eax             ; r12d = 最大leaf (non-volatile, 跨printf保存)

    ; -------------------------------------------------------
    ; 2. 检查混合架构 (Leaf 1Ah - Intel Hybrid Information)
    ;    r13 = 核心类型字节 (0表示不支持/未报告)
    ;    r15 = 混合架构标志 (1=支持, 0=不支持)
    ; -------------------------------------------------------
    xor r13, r13              ; core_type = 0 (默认)
    xor r15, r15              ; hybrid_supported = 0 (默认)

    cmp r12d, 1Ah
    jb mainskip_hybrid

    ; Leaf 1Ah 可用，执行查询
    mov eax, 1Ah
    xor ecx, ecx
    cpuid
    ; EAX bits 31:24 = Core Type
    shr eax, 24
    and eax, 0FFh
    mov r13d, eax             ; r13d = 核心类型字节

    ; 核心类型非0 → 混合架构支持
    test eax, eax
    jz mainskip_hybrid
    mov r15, 1                ; hybrid_supported = 1

mainskip_hybrid:

    ; -------------------------------------------------------
    ; 3. 检测AVX2/AVX-512 (Leaf 7, sub-leaf 0)
    ;    r14 = EBX特性标志 (0表示Leaf 7不可用)
    ; -------------------------------------------------------
    xor r14, r14              ; features = 0 (默认)

    cmp r12d, 7
    jb mainskip_leaf7

    mov eax, 7
    xor ecx, ecx
    cpuid
    mov r14d, ebx             ; r14d = EBX特性标志 (non-volatile, 跨printf保存)

mainskip_leaf7:

    ; -------------------------------------------------------
    ; 恢复RBX (所有CPUID调用完成)
    ; -------------------------------------------------------
    mov rbx, QWORD PTR [saved_rbx]

    ; -------------------------------------------------------
    ; 打印: Hybrid Architecture Supported: YES/NO
    ; printf(fmt_hybrid, yes/no) -> RCX, RDX
    ; -------------------------------------------------------
    lea rcx, fmt_hybrid
    test r15, r15
    jz mainhybrid_no
    lea rdx, str_yes
    jmp mainhybrid_print
mainhybrid_no:
    lea rdx, str_no
mainhybrid_print:
    call printf

    ; -------------------------------------------------------
    ; 打印: Current Core Type
    ; 40h = P-Core, 20h = E-Core, 其他 = Unknown
    ; -------------------------------------------------------
    lea rcx, fmt_core
    cmp r13d, 40h
    je maincore_is_p
    cmp r13d, 20h
    je maincore_is_e
    lea rdx, str_unknown
    jmp maincore_print
maincore_is_p:
    lea rdx, str_pcore
    jmp maincore_print
maincore_is_e:
    lea rdx, str_ecore
maincore_print:
    call printf

    ; -------------------------------------------------------
    ; 打印: Raw Core Type Value (原始值)
    ; -------------------------------------------------------
    lea rcx, fmt_raw
    mov edx, r13d
    call printf

    ; -------------------------------------------------------
    ; 打印: AVX2 support
    ; EBX bit 5 = AVX2 (20h)
    ; -------------------------------------------------------
    lea rcx, fmt_avx2
    test r14d, 20h           ; bit 5 = AVX2
    jz mainavx2_no
    lea rdx, str_yes
    jmp mainavx2_print
mainavx2_no:
    lea rdx, str_no
mainavx2_print:
    call printf

    ; -------------------------------------------------------
    ; 打印: AVX-512 support
    ; EBX bit 16 = AVX-512F (10000h)
    ; -------------------------------------------------------
    lea rcx, fmt_avx512
    test r14d, 10000h        ; bit 16 = AVX-512F
    jz mainavx512_no
    lea rdx, str_yes
    jmp mainavx512_print
mainavx512_no:
    lea rdx, str_no
mainavx512_print:
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
