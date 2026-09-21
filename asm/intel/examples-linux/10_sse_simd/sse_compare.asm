; ============================================================
; 文件: 10_sse_simd/sse_compare.asm                        [Linux 版]
; 指令: COMISS / COMISD / CMPPS
; 描述: 浮点比较 —— 一边出标志位、一边出掩码
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/10_sse_simd/sse_compare.asm -o build/sse_compare.o
; 链接: gcc -no-pie build/sse_compare.o -o build/sse_compare
; 对照: examples/10_sse_simd/sse_compare.asm
;
; ------------------------------------------------------------
; 两条路，用途完全不同：
;
; COMISS / COMISD —— 标量比较，只写 EFLAGS，专门喂给 ja/jb/je：
;     xmm0 > xmm1 -> CF=0 ZF=0 -> JA
;     xmm0 < xmm1 -> CF=1 ZF=0 -> JB
;     xmm0 = xmm1 -> CF=0 ZF=1 -> JE
;   注意它是**无序敏感**的：碰到 NaN 会置 CF=ZF=PF=1，
;   于是 ja/jb/je 全不跳。想显式处理 NaN 就配 jp 用。
;
; CMPPS —— 打包比较，不写标志位，而是给每个通道生成一个掩码：
;     成立 -> 0xFFFFFFFF，不成立 -> 0x00000000
;   比较码是立即数：0=EQ 1=LT 2=LE 3=UNORD 4=NEQ 5=NLT 6=NLE 7=ORD
;   给「按条件筛数据」用（配上 andps 就是无分支的 select）。
;
; 记忆法：COMISS 的 s 是「标量」，CMPPS 的 p 是「打包」。
; 两个比较类指令各有 s/p 版本，只是打包版只做掩码、不出标志。
;
; ------------------------------------------------------------
; Linux 要点：`fmt_cmpps` 有 5 个参数（格式串 + 4 个掩码），
; SysV 的 rdi/rsi/rdx/rcx/r8 刚好装下 —— 一个字节栈都不用动。
; Windows 版必须写 `mov dword [rsp+32], eax`，还得为此多开 16 字节栈。
; ============================================================
default rel

section .data
    align 4
    f_val1  dd 3.14
    f_val2  dd 2.72
    align 8
    d_val1  dq 3.14159
    d_val2  dq 2.71828

    align 16
    packed1  dd 1.0, 2.0, 3.0, 4.0
    align 16
    packed2  dd 1.0, 3.0, 3.0, 5.0
    align 16
    mask_buf dd 0, 0, 0, 0

    fmt_comiss_gt  db "COMISS: 3.14 > 2.72 成立", 10, 0
    fmt_comiss_lt  db "COMISS: 3.14 > 2.72 不成立", 10, 0
    fmt_comisd_gt  db "COMISD: 3.14159 > 2.71828 成立", 10, 0
    fmt_comisd_lt  db "COMISD: 3.14159 > 2.71828 不成立", 10, 0
    fmt_cmpps      db "CMPPS EQ 掩码: 0x%08X 0x%08X 0x%08X 0x%08X", 10, 0
    fmt_cmpps_note db "  （0xFFFFFFFF = 相等，0x00000000 = 不等）", 10, 0
    fmt_done       db "SSE compare demo completed.", 10, 0

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; --------------------------------------------------------
    ; 1. COMISS：标量单精度比较，结果进 EFLAGS
    ; --------------------------------------------------------
    movss xmm0, [f_val1]                ; xmm0 = 3.14
    movss xmm1, [f_val2]                ; xmm1 = 2.72
    comiss xmm0, xmm1

    ja .comiss_gt
    ; 落到这里就是 xmm0 <= xmm1

.comiss_lt:
    lea rdi, [fmt_comiss_lt]
    xor eax, eax
    call printf
    jmp .do_comisd

.comiss_gt:
    lea rdi, [fmt_comiss_gt]
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; 2. COMISD：标量双精度比较
    ; --------------------------------------------------------
.do_comisd:
    movsd xmm0, [d_val1]
    movsd xmm1, [d_val2]
    comisd xmm0, xmm1

    ja .comisd_gt

.comisd_lt:
    lea rdi, [fmt_comisd_lt]
    xor eax, eax
    call printf
    jmp .do_cmpps

.comisd_gt:
    lea rdi, [fmt_comisd_gt]
    xor eax, eax
    call printf

    ; --------------------------------------------------------
    ; 3. CMPPS：打包比较，逐通道出掩码
    ;    [1,2,3,4] vs [1,3,3,5] 比 EQ -> [全1, 0, 全1, 0]
    ; --------------------------------------------------------
.do_cmpps:
    movaps xmm0, [packed1]
    movaps xmm1, [packed2]
    cmpps xmm0, xmm1, 0                 ; 0 = EQ
    movaps [mask_buf], xmm0

    ; 5 个参数：rdi 格式串，rsi/rdx/rcx/r8 = 四个掩码
    lea rdi, [fmt_cmpps]
    mov esi, [mask_buf]
    mov edx, [mask_buf + 4]
    mov ecx, [mask_buf + 8]
    mov r8d, [mask_buf + 12]
    xor eax, eax
    call printf

    lea rdi, [fmt_cmpps_note]
    xor eax, eax
    call printf

    lea rdi, [fmt_done]
    xor eax, eax
    call printf

    xor eax, eax
    leave
    ret
