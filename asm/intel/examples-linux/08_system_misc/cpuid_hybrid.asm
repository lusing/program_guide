; ============================================================
; 文件: 08_system_misc/cpuid_hybrid.asm                    [Linux 版]
; 指令: CPUID（页 0 / 页 1Ah / 页 7）
; 描述: 检测 Intel 大小核（P-Core / E-Core）与 AVX2 / AVX-512
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/08_system_misc/cpuid_hybrid.asm -o build/cpuid_hybrid.o
; 链接: gcc -no-pie build/cpuid_hybrid.o -o build/cpuid_hybrid
; 对照: examples/08_system_misc/cpuid_hybrid.asm
;
; ------------------------------------------------------------
; 三个页各管一件事：
;   页 0    -> EAX = 最大页号。想用某个页之前，先确认它存在。
;   页 1A   -> Intel 混合架构信息：EAX[31:24] = 当前核心类型
;              0x40 = P-Core（性能核）  0x20 = E-Core（能效核）
;   页 7, ecx=0 -> EBX 位图：bit 5 = AVX2，bit 16 = AVX-512F
;
; 关键习惯：**先问最大页号，再决定要不要查**。
; 老 CPU 遇到不存在的页会把输入原样返回，不先判断就会读出假数据。
; 本机是 Ivy Bridge（i7-3520M），所以页 1A 不存在、AVX2 也不支持 ——
; 程序会如实报 NO，这本身就是一次正确的「能力探测」示范。
;
; ------------------------------------------------------------
; Linux 要点：CPUID 会踩 EBX，而 EBX 是被调用者保存寄存器，
; 取完所有 CPUID 必须还原，否则 main 一 ret，libc 启动代码会踩到坏值而崩溃。
; ============================================================
default rel

section .data
    fmt_maxleaf db "CPUID 最大页号： 0x%X", 10, 0
    fmt_hybrid  db "支持混合架构（大小核）： %s", 10, 0
    fmt_core    db "当前核心类型： %s", 10, 0
    fmt_raw     db "核心类型原始值： 0x%02X", 10, 0
    fmt_avx2    db "AVX2： %s", 10, 0
    fmt_avx512  db "AVX-512： %s", 10, 0
    fmt_note    db "提示：本机若无 AVX2，后面的 SIMD 示例会用 SSE 路径。", 10, 0
    fmt_done    db "Hybrid architecture detection completed.", 10, 0

    w_yes   db "YES", 0
    w_no    db "NO", 0
    w_pcore db "P-Core（性能核）", 0
    w_ecore db "E-Core（能效核）", 0
    w_unk   db "未知 / 未报告", 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    mov [rbp-8],  rbx                   ; CPUID 会踩 EBX，必须还原
    mov [rbp-16], r12                   ; 最大页号
    mov [rbp-24], r13                   ; 核心类型字节
    mov [rbp-32], r14                   ; 页 7 的 EBX 位图
    mov [rbp-40], r15                   ; 是否支持混合架构

    ; --------------------------------------------------------
    ; 1. 页 0：最大页号
    ; --------------------------------------------------------
    xor eax, eax
    cpuid
    mov r12d, eax

    lea rdi, [fmt_maxleaf]
    mov rsi, r12
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; 2. 页 1Ah：混合架构核心类型
    ; --------------------------------------------------------
    xor r13, r13                        ; core_type = 0
    xor r15, r15                        ; hybrid_supported = 0

    cmp r12d, 0x1A
    jb .skip_hybrid                     ; 没有这一页，跳过

    mov eax, 0x1A
    xor ecx, ecx
    cpuid
    shr eax, 24                         ; EAX[31:24] = 核心类型
    and eax, 0xFF
    mov r13d, eax

    test eax, eax
    jz .skip_hybrid                     ; 非 0 才算支持
    mov r15, 1
.skip_hybrid:

    ; --------------------------------------------------------
    ; 3. 页 7（子页 0）：AVX2 / AVX-512 位图
    ; --------------------------------------------------------
    xor r14, r14

    cmp r12d, 7
    jb .skip_leaf7

    mov eax, 7
    xor ecx, ecx
    cpuid
    mov r14d, ebx
.skip_leaf7:

    ; --------------------------------------------------------
    ; 4. CPUID 全部完成，还原 EBX
    ; --------------------------------------------------------
    mov rbx, [rbp-8]

    ; ------ 混合架构支持？ ------
    lea rdi, [fmt_hybrid]
    lea rsi, [w_no]
    lea rdx, [w_yes]
    test r15, r15
    cmovnz rsi, rdx
    xor eax, eax
    call printf

    ; ------ 当前核心类型 ------
    lea rdi, [fmt_core]
    lea rsi, [w_unk]
    lea rdx, [w_pcore]
    lea rcx, [w_ecore]
    cmp r13d, 0x40
    cmove rsi, rdx                      ; P-Core
    cmp r13d, 0x20
    cmove rsi, rcx                      ; E-Core
    xor eax, eax
    call printf

    lea rdi, [fmt_raw]
    mov rsi, r13
    xor eax, eax
    call printf

    ; ------ AVX2（EBX bit 5）------
    lea rdi, [fmt_avx2]
    lea rsi, [w_no]
    lea rdx, [w_yes]
    bt r14d, 5
    cmovc rsi, rdx
    xor eax, eax
    call printf

    ; ------ AVX-512F（EBX bit 16）------
    lea rdi, [fmt_avx512]
    lea rsi, [w_no]
    lea rdx, [w_yes]
    bt r14d, 16
    cmovc rsi, rdx
    xor eax, eax
    call printf

    lea rdi, [fmt_note]
    xor eax, eax
    call printf

    lea rdi, [fmt_done]
    xor eax, eax
    call printf

    mov rbx, [rbp-8]
    mov r12, [rbp-16]
    mov r13, [rbp-24]
    mov r14, [rbp-32]
    mov r15, [rbp-40]
    xor eax, eax
    leave
    ret
