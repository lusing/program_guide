; ============================================================
; bit_fields.asm - 位域的打包与解包（RGB565）+ popcount
; ============================================================
; 「位域」= 把多个小字段挤进一个整数的固定位段
; （《汇编语言编程艺术》AoA 第 10 章的主题）。三板斧：
;   打包：先 and 掩码截断到字段宽度，再 shift 到位段，or 进容器
;   解包：shift 到最低位，再 and 掩码取出字段
;   逐位操作：bt/bts/btr/btc 直接对「第 n 位」读/置/清/取反
;
; 预期输出:
;   RGB565 pack  : r=0x1F g=0x3F b=0x1F -> 0xFFFF
;   RGB565 unpack: r=0x1F g=0x3F b=0x1F (roundtrip OK)
;   bt/bts/btr/btc on bit 7 of 0x80: 1 -> set 1 -> clear 0 -> toggle 1
;   popcount(0x8000000000000001) = 2 (loop)  | 2 (popcnt, needs SSE4.2)
; ============================================================

default rel

section .data
    align 8
    red    dq 0x1F
    green  dq 0x3F
    blue   dq 0x1F
    packed dq 0

    mask_r  equ 0x1F
    mask_g  equ 0x3F
    mask_b  equ 0x1F

    bitsv   dq 0x80
    popval  dq 0x8000000000000001

    fmt_pack db "RGB565 pack  : r=0x%llX g=0x%llX b=0x%llX -> 0x%llX", 10, 0
    fmt_unp  db "RGB565 unpack: r=0x%llX g=0x%llX b=0x%llX (roundtrip OK)", 10, 0
    fmt_bt   db "bt/bts/btr/btc on bit 7 of 0x80: %d -> set %d -> clear %d -> toggle %d", 10, 0
    fmt_pop  db "popcount(0x8000000000000001) = %d (loop)  | %d (popcnt, needs SSE4.2)", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    push rbx                     ; 先压非易失寄存器再 sub，保证 call 时 16 对齐
    sub rsp, 56                  ; 8+8+56 = 72，entry rsp≡8 -> call 时 ≡0

    ; ---- 打包 RGB565：r[15:11] g[10:5] b[4:0] ----
    mov rax, [red]
    and rax, mask_r
    shl rax, 11                 ; 红色移到位段 15:11
    mov rcx, [green]
    and rcx, mask_g
    shl rcx, 5                  ; 绿色到位段 10:5
    mov rdx, [blue]
    and rdx, mask_b             ; 蓝色已在位段 4:0
    or rax, rcx
    or rax, rdx
    mov [packed], rax

    lea rcx, [fmt_pack]
    mov rdx, [red]
    mov r8, [green]
    mov r9, [blue]
    mov [rsp+32], rax           ; 第 5 参：打包结果
    call printf

    ; ---- 解包 ----
    mov rax, [packed]
    mov r11, rax
    shr r11, 11
    and r11, mask_r             ; r
    mov r12, rax
    shr r12, 5
    and r12, mask_g             ; g
    mov r13, rax
    and r13, mask_b             ; b

    lea rcx, [fmt_unp]
    mov rdx, r11
    mov r8, r12
    mov r9, r13
    call printf

    ; ---- bt / bts / btr / btc：对第 7 位依次 读/置/清/取反 ----
    mov rbx, [bitsv]
    bt  rbx, 7
    setc r8b
    movzx r8d, r8b              ; bt:   1
    bts rbx, 7
    bt  rbx, 7
    setc r9b
    movzx r9d, r9b              ; bts 后: 1
    btr rbx, 7
    bt  rbx, 7
    setc r10b
    movzx r10d, r10b            ; btr 后: 0
    btc rbx, 7
    bt  rbx, 7
    setc r11b
    movzx r11d, r11b            ; btc 后: 1
    lea rcx, [fmt_bt]
    mov edx, r8d
    mov r8d, r9d
    mov r9d, r10d
    mov [rsp+32], r11           ; 第 5 参：toggle 结果
    call printf

    ; ---- popcount：循环版 vs popcnt 指令版 ----
    mov rax, [popval]
    xor ecx, ecx
.loop:
    test rax, rax
    jz .done
    shr rax, 1
    adc ecx, 0                  ; 把移出的位加进 ECX（借 CF 数 1）
    jmp .loop
.done:
    mov r12d, ecx               ; 循环版结果
    mov rax, [popval]
    popcnt rax, rax             ; SSE4.2 单指令版
    mov r13d, eax

    lea rcx, [fmt_pop]
    mov edx, r12d
    mov r8d, r13d
    call printf

    add rsp, 56
    pop rbx
    xor ecx, ecx
    call ExitProcess
