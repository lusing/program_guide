; [n2m auto-translated from NASM -> ml64 MASM syntax]
option casemap:none
extern printf : PROC
extern ExitProcess : PROC

.data
    align 8
    red    QWORD 1Fh
    green  QWORD 3Fh
    blue   QWORD 1Fh
    packed QWORD 0

    mask_r  EQU 1Fh
    mask_g  EQU 3Fh
    mask_b  EQU 1Fh

    bitsv   QWORD 80h
    popval  QWORD 8000000000000001h

    fmt_pack BYTE "RGB565 pack  : r=0x%llX g=0x%llX b=0x%llX -> 0x%llX", 10, 0
    fmt_unp  BYTE "RGB565 unpack: r=0x%llX g=0x%llX b=0x%llX (roundtrip OK)", 10, 0
    fmt_bt   BYTE "bt/bts/btr/btc on bit 7 of 0x80: %d -> set %d -> clear %d -> toggle %d", 10, 0
    fmt_pop  BYTE "popcount(0x8000000000000001) = %d (loop)  | %d (popcnt, needs SSE4.2)", 10, 0


.code

main PROC
    push rbp
    mov rbp, rsp
    push rbx                     ; 先压非易失寄存器再 sub，保证 call 时 16 对齐
    sub rsp, 56                  ; 8+8+56 = 72，entry rsp≡8 -> call 时 ≡0

    ; ---- 打包 RGB565：r[15:11] g[10:5] b[4:0] ----
    mov rax, [red]
    and rax, mask_r
    shl rax, 11                 ; 红色移到位段 15:11
    mov rcx, QWORD PTR [green]
    and rcx, mask_g
    shl rcx, 5                  ; 绿色到位段 10:5
    mov rdx, QWORD PTR [blue]
    and rdx, mask_b             ; 蓝色已在位段 4:0
    or rax, rcx
    or rax, rdx
    mov QWORD PTR [packed], rax

    lea rcx, fmt_pack
    mov rdx, [red]
    mov r8, QWORD PTR [green]
    mov r9, QWORD PTR [blue]
    mov [rsp+32], rax           ; 第 5 参：打包结果
    call printf

    ; ---- 解包 ----
    mov rax, QWORD PTR [packed]
    mov r11, rax
    shr r11, 11
    and r11, mask_r             ; r
    mov r12, rax
    shr r12, 5
    and r12, mask_g             ; g
    mov r13, rax
    and r13, mask_b             ; b

    lea rcx, fmt_unp
    mov rdx, r11
    mov r8, r12
    mov r9, r13
    call printf

    ; ---- bt / bts / btr / btc：对第 7 位依次 读/置/清/取反 ----
    mov rbx, QWORD PTR [bitsv]
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
    lea rcx, fmt_bt
    mov edx, r8d
    mov r8d, r9d
    mov r9d, r10d
    mov [rsp+32], r11           ; 第 5 参：toggle 结果
    call printf

    ; ---- popcount：循环版 vs popcnt 指令版 ----
    mov rax, QWORD PTR [popval]
    xor ecx, ecx
mainloop:
    test rax, rax
    jz maindone
    shr rax, 1
    adc ecx, 0                  ; 把移出的位加进 ECX（借 CF 数 1）
    jmp mainloop
maindone:
    mov r12d, ecx               ; 循环版结果
    mov rax, QWORD PTR [popval]
    popcnt rax, rax             ; SSE4.2 单指令版
    mov r13d, eax

    lea rcx, fmt_pop
    mov edx, r12d
    mov r8d, r13d
    call printf

    add rsp, 56
    pop rbx
    xor ecx, ecx
    call ExitProcess
main ENDP
END
