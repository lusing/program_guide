; ============================================================
; 文件: 08_system_misc/cpuid.asm                           [Linux 版]
; 指令: CPUID
; 描述: 让 CPU 自报家门 —— 厂商字符串、型号、特性标志
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/08_system_misc/cpuid.asm -o build/cpuid.o
; 链接: gcc -no-pie build/cpuid.o -o build/cpuid
; 对照: examples/08_system_misc/cpuid.asm
;
; ------------------------------------------------------------
; CPUID 是「用 EAX（有时还有 ECX）选页，结果填回 EAX/EBX/ECX/EDX」的指令。
;   eax=0  -> EAX=最大页号；EBX/EDX/ECX 拼出 12 字节厂商串
;             Intel 是 "GenuineIntel"，AMD 是 "AuthenticAMD"
;   eax=1  -> EAX=Family/Model/Stepping，EDX/ECX=特性位图
;   eax=7, ecx=0 -> EBX 里是 AVX2 / AVX-512 / BMI 这些较新特性
;
; ------------------------------------------------------------
; 这个例子有一个 Linux 特有的要点：
;   CPUID 会把 EBX 覆盖掉，而 EBX 在 SysV 和 Win64 里都是
;   **被调用者保存**寄存器。所以取完 n 次 CPUID 之后，
;   一定要把 EBX 还原成调用者那会儿的值，否则 main 一 ret，
;   libc 启动代码立刻用坏掉的 rbx 去访存并崩溃。
; 这里直接在栈帧里存一份（[rbp-8]），比 Windows 版存 .data 更省事。
; ============================================================
default rel

section .bss
    vendor_buf   resb 13                ; 12 字符厂商串 + 结尾 0

section .data
    fms_val      dd 0                   ; Family/Model/Stepping 原始值
    feat_edx     dd 0                   ; 特性位图（EDX）

    fmt_vendor   db "CPU 厂商字符串： %s", 10, 0
    fmt_maxleaf  db "CPUID 最大页号： 0x%X", 10, 0
    fmt_fms      db "Family: %d, Model: %d, Stepping: %d", 10, 0
    fmt_features db "特性位图 EDX: 0x%08X", 10, 0
    lbl_feat     db "支持的特性： ", 0
    fmt_done     db "CPUID demo completed.", 10, 0

    w_fpu   db "FPU ", 0
    w_tsc   db "TSC ", 0
    w_cmov  db "CMOV ", 0
    w_mmx   db "MMX ", 0
    w_sse   db "SSE ", 0
    w_sse2  db "SSE2 ", 0
    w_htt   db "HTT ", 0
    w_nl    db 10, 0

; 一条小宏：第 1 个参数是位号，第 2 个是要打印的字符串标签
; （%%skip 里的 %% 是 NASM 宏局部标签的写法，避免多次展开撞名）
%macro showfeat 2
    bt r13d, %1
    jnc %%skip
    lea rdi, [%2]
    xor eax, eax
    call printf
%%skip:
%endmacro

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8],  rbx                   ; CPUID 会踩 EBX，先存一份
    mov [rbp-16], r12
    mov [rbp-24], r13

    ; --------------------------------------------------------
    ; 1. 页 0：厂商字符串 + 最大页号
    ;    EBX = 第 0-3 个字符，EDX = 第 4-7 个，ECX = 第 8-11 个
    ; --------------------------------------------------------
    xor eax, eax
    cpuid
    mov r12d, eax                       ; 最大页号留着后面用

    mov [vendor_buf],     ebx           ; "Genu"
    mov [vendor_buf + 4], edx           ; "ineI"
    mov [vendor_buf + 8], ecx           ; "ntel"
    mov byte [vendor_buf + 12], 0       ; 字符串收尾

    lea rdi, [fmt_vendor]
    lea rsi, [vendor_buf]
    xor eax, eax
    call printf

    lea rdi, [fmt_maxleaf]
    mov rsi, r12
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; 2. 页 1：Family/Model/Stepping 和特性位图
    ;    结果必须马上搬进 callee-saved 寄存器，printf 会冲掉 eax/edx
    ; --------------------------------------------------------
    mov eax, 1
    cpuid
    mov [fms_val], eax
    mov [feat_edx], edx

    ; --------------------------------------------------------
    ; 3. 所有 CPUID 都取完了，把 EBX 还原
    ; --------------------------------------------------------
    mov rbx, [rbp-8]

    lea rdi, [fmt_features]
    mov esi, [feat_edx]                 ; %08X
    xor eax, eax
    call printf

    lea rdi, [lbl_feat]
    xor eax, eax
    call printf
    mov r13d, [feat_edx]                ; 宏里用 r13d 做 bt 的源
    showfeat 0,  w_fpu
    showfeat 4,  w_tsc
    showfeat 15, w_cmov
    showfeat 23, w_mmx
    showfeat 25, w_sse
    showfeat 26, w_sse2
    showfeat 28, w_htt
    lea rdi, [w_nl]
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; 4. 拆 Family/Model/Stepping
    ;    Stepping = EAX[3:0]
    ;    Model    = EAX[7:4] | (EAX[19:16] << 4)
    ;    Family   = EAX[11:8]（若等于 0xF，还要加 EAX[27:20]）
    ; --------------------------------------------------------
    mov r13d, [fms_val]

    mov eax, r13d
    and eax, 0xF                        ; Stepping
    mov ecx, eax

    mov eax, r13d
    shr eax, 4
    and eax, 0xF                        ; 基础 Model
    mov edx, r13d
    shr edx, 16
    and edx, 0xF                        ; 扩展 Model
    shl edx, 4
    or eax, edx                         ; Model = 两者拼接
    mov edx, eax

    mov eax, r13d
    shr eax, 8
    and eax, 0xF                        ; 基础 Family
    cmp eax, 0xF
    jne .no_ext_fam
    mov r8d, r13d
    shr r8d, 20
    and r8d, 0xFF                       ; 扩展 Family
    add eax, r8d
.no_ext_fam:

    lea rdi, [fmt_fms]
    mov esi, eax                        ; Family
    ; rdx 已经是 Model
    ; rcx 已经是 Stepping
    xor eax, eax
    call printf

    lea rdi, [fmt_done]
    xor eax, eax
    call printf

    mov rbx, [rbp-8]
    mov r12, [rbp-16]
    mov r13, [rbp-24]
    xor eax, eax
    leave
    ret
