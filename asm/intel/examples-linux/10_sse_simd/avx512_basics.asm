; ============================================================
; 文件: 10_sse_simd/avx512_basics.asm                      [Linux 版]
; 指令: VPADDD / KMOVD / 合并掩码 {k1} / 归零掩码 {k1}{z}（AVX-512F）
; 描述: 512 位 ZMM + opmask k 寄存器 —— AVX-512 真正的新东西
; 平台: Linux x86-64（ELF + System V AMD64）
; 汇编: nasm -I lib -f elf64 examples-linux/10_sse_simd/avx512_basics.asm -o build/avx512_basics.o
; 链接: gcc -no-pie build/avx512_basics.o -o build/avx512_basics
;
; ------------------------------------------------------------
; AVX-512（2017，Skylake-X / Skylake-SP）做了三件以前做不到的事：
;
;   1. 向量宽度 256 -> 512 位（ymm -> zmm），16 个 float / 16 个 int32 一次算。
;
;   2. 新增 opmask 寄存器 k0~k7。这是 AVX-512 最本质的改变，比宽度翻倍
;      还重要：每条向量指令都可以带一个掩码，只更新被选中的通道。
;
;   3. 两种掩码语义：
;        合并掩码 {k1}     未选中的通道保留目标寄存器的旧值
;        归零掩码 {k1}{z}  未选中的通道被清零
;      以前要做「按条件加法」得先比较、再 and/andn、再 or 三条，
;      AVX-512 一条带掩码的指令就够了。
;
; 本示例逐段演示：16 路整数加 -> 合并掩码 -> 归零掩码。
; 运行时探测 AVX-512F（页 7 EBX[16]）+ XCR0[7:5] 三个状态位都置位，
; 缺任何一个就打印提示并正常退出 0。
;
; ------------------------------------------------------------
; Linux 要点：整数结果走 rdi/rsi/rdx，不占 xmm；
; 用 zmm 之后照例 vzeroupper 再调 printf。
; ============================================================
default rel

section .data
    align 64
    add_a    dd 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
    align 64
    add_b    dd 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100
    align 64
    ; 掩码：选偶数下标通道（bit0,2,4,...=1），即 0x5555
    mask_even dw 0x5555
    align 64
    ; 合并掩码用的「目标初值」：先放 1..16，带掩码加完后奇数下标仍保留这些值
    merge_init dd 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
    align 64
    out_buf  dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

    hdr      db "AVX-512 基础：ZMM 512 位 + opmask k 寄存器", 10, 0
    t1       db "1. VPADDD zmm —— 16 路 32 位整数加（AVX2 只有 8 路）", 10, 0
    t1c      db "   [1..16] + [100 x 16]", 10, 0
    t2       db "2. 合并掩码 {k1}：只更新偶数下标通道，其余保留目标初值", 10, 0
    t2c      db "   掩码 = 0x5555（bit 0,2,4,...,14 置位）；目标初值 = [1..16]", 10, 0
    t2d      db "   期望：偶数下标 = 初值+100，奇数下标 = 初值不变", 10, 0
    t3       db "3. 归零掩码 {k1}{z}：未选中通道直接清零", 10, 0
    t3c      db "   同样的掩码与输入，但奇数下标变成 0", 10, 0
    t_skip   db "本机不支持 AVX-512F（CPUID 页 7 EBX[16] / XCR0[7:5] 已确认），本示例无可演示内容。", 10, 0
    fmt_idx  db "     [%2d] = %d", 10, 0
    fmt_done db "AVX-512 basics demo completed.", 10, 0

section .text
    global main
    extern printf

; ------------------------------------------------------------
; cpu_features —— CPUID + XGETBV 探测，返回 eax 位图
;   bit0 = AVX         页1 ECX[28]，且 ECX[27] OSXSAVE，且 XCR0[2:1] = 11
;   bit1 = AVX2        页7 EBX[5]
;   bit2 = FMA         页1 ECX[12]
;   bit3 = OS 放开 YMM（XCR0[2:1]）
;   bit4 = AVX-512F    页7 EBX[16]
;   bit5 = OS 放开 ZMM/opmask（XCR0[7:5] 全 1）
; ------------------------------------------------------------
cpu_features:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12

    xor  r12d, r12d

    mov  eax, 0
    cpuid
    mov  r9d, eax                    ; 最大页号
    cmp  r9d, 1
    jb   .done

    mov  eax, 1
    xor  ecx, ecx
    cpuid
    mov  r8d, ecx

    bt   r8d, 12                     ; FMA
    jnc  .no_fma
    or   r12d, 4
.no_fma:
    bt   r8d, 28                     ; AVX
    jnc  .done
    bt   r8d, 27                     ; OSXSAVE
    jnc  .done

    xor  ecx, ecx
    xgetbv                           ; XCR0 -> EDX:EAX
    mov  r11d, eax                   ; 完整保存 XCR0，后面 AVX-512 的 [7:5] 还要用
    mov  r10d, eax
    and  r10d, 6
    cmp  r10d, 6                     ; XCR0[2:1] = YMM
    jne  .done
    or   r12d, 9                     ; bit0(AVX) + bit3(OS YMM)

    cmp  r9d, 7
    jb   .done
    mov  eax, 7
    xor  ecx, ecx
    cpuid
    bt   ebx, 5                      ; AVX2
    jnc  .no_avx2
    or   r12d, 2
.no_avx2:
    bt   ebx, 16                     ; AVX-512F
    jnc  .done
    or   r12d, 16

    ; XCR0[7:5]：opmask(5) + ZMM_Hi256(6) + Hi16_ZMM(7)，三者都要置位
    mov  r10d, r11d                  ; 取回之前保存的完整 XCR0
    and  r10d, 0xE0
    cmp  r10d, 0xE0
    jne  .done
    or   r12d, 32

.done:
    mov  eax, r12d
    pop  r12
    pop  rbx
    leave
    ret

; ------------------------------------------------------------
; print_ivec16 —— 把缓冲区里的 16 个 int32 逐个打出
;   rdi = int32*
; ------------------------------------------------------------
print_ivec16:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12
    push r13
    sub  rsp, 8

    mov  rbx, rdi
    xor  r13d, r13d
.loop:
    cmp  r13d, 16
    jge  .done
    mov  edx, [rbx + r13*4]
    lea  rdi, [fmt_idx]
    mov  esi, r13d
    xor  eax, eax
    call printf
    inc  r13d
    jmp  .loop
.done:
    add  rsp, 8
    pop  r13
    pop  r12
    pop  rbx
    leave
    ret

main:
    push rbp
    mov  rbp, rsp
    sub  rsp, 16
    mov  [rbp-8], rbx
    mov  [rbp-16], r12

    call cpu_features
    mov  r12d, eax

    lea  rdi, [hdr]
    xor  eax, eax
    call printf

    mov  eax, r12d
    and  eax, 48                     ; bit4(AVX-512F) + bit5(OS 放开 ZMM) = 0b110000
    cmp  eax, 48
    je   .avx512_ok
    lea  rdi, [t_skip]
    xor  eax, eax
    call printf
    jmp  .finish

.avx512_ok:
    ; --- 1. vpaddd zmm：16 路 32 位整数加 ---
    lea  rdi, [t1]
    xor  eax, eax
    call printf
    lea  rdi, [t1c]
    xor  eax, eax
    call printf
    vmovdqa32 zmm1, [add_a]
    vmovdqa32 zmm2, [add_b]
    vpaddd zmm0, zmm1, zmm2
    vmovdqa32 [out_buf], zmm0
    vzeroupper
    lea  rdi, [out_buf]
    call print_ivec16

    ; --- 2. 合并掩码 {k1}：偶数下标更新，奇数下标保留目标初值 ---
    lea  rdi, [t2]
    xor  eax, eax
    call printf
    lea  rdi, [t2c]
    xor  eax, eax
    call printf
    lea  rdi, [t2d]
    xor  eax, eax
    call printf
    mov  eax, [mask_even]            ; 0x5555
    kmovw k1, eax
    vmovdqa32 zmm0, [merge_init]     ; 目标初值 [1..16]
    vmovdqa32 zmm1, [add_b]          ; [100 x 16]
    vpaddd zmm0 {k1}, zmm0, zmm1     ; 只在 k1 置位的通道执行加法
    vmovdqa32 [out_buf], zmm0
    vzeroupper
    lea  rdi, [out_buf]
    call print_ivec16

    ; --- 3. 归零掩码 {k1}{z}：未选中通道清零 ---
    ; 注意：opmask k 寄存器是「调用者保存」的，上面 print_ivec16 里的
    ; printf 已经把 k1 冲掉了，这里必须重新加载掩码。
    lea  rdi, [t3]
    xor  eax, eax
    call printf
    lea  rdi, [t3c]
    xor  eax, eax
    call printf
    mov  eax, [mask_even]
    kmovw k1, eax                     ; 重新加载掩码 0x5555
    vmovdqa32 zmm1, [add_a]          ; [1..16]
    vmovdqa32 zmm2, [add_b]          ; [100 x 16]
    vpaddd zmm0 {k1}{z}, zmm1, zmm2  ; 偶数下标 = a+b，奇数下标 = 0
    vmovdqa32 [out_buf], zmm0
    vzeroupper
    lea  rdi, [out_buf]
    call print_ivec16

.finish:
    lea  rdi, [fmt_done]
    xor  eax, eax
    call printf

    mov  rbx, [rbp-8]
    mov  r12, [rbp-16]
    xor  eax, eax
    leave
    ret

%include "linux_io.inc"
