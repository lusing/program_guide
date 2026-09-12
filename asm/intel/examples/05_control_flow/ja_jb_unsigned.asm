; ============================================================
; 文件: 05_control_flow/ja_jb_unsigned.asm
; 指令: JA, JAE, JB, JBE (无符号条件跳转)
; 描述: 演示无符号比较跳转，对比有符号/无符号解读差异
; 编译: nasm -f win64 ja_jb_unsigned.asm -o ja_jb_unsigned.obj
; 链接: link /subsystem:console /entry:main ja_jb_unsigned.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
; 预期输出:
;   JA:  255 > 1 (unsigned)  -> Above (JA taken)
;   JB:  1 < 255 (unsigned)  -> Below (JB taken)
;   Unsigned: 0xFFFFFFFF > 1 -> Above (JA taken)
;   Signed:   0xFFFFFFFF < 1 -> Less  (JL taken)
;   Key: Same CMP, different jumps interpret flags differently!
;
; 无符号跳转指令说明:
;   JA  (Jump if Above)          : CF=0 且 ZF=0  (无符号大于)
;   JAE (Jump if Above or Equal) : CF=0          (无符号大于等于)
;   JB  (Jump if Below)          : CF=1          (无符号小于)
;   JBE (Jump if Below or Equal) : CF=1 或 ZF=1  (无符号小于等于)
;
; 关键概念:
;   CMP 指令只做一次减法并设置所有标志位
;   有符号跳转 (JG/JL) 读取 SF 和 OF
;   无符号跳转 (JA/JB) 读取 CF
;   同一个 CMP 结果，用不同跳转指令会得到不同结论！
; ============================================================
default rel

section .data
    fmt_ja    db "JA:  255 > 1 (unsigned)  -> Above (JA taken)", 10, 0
    fmt_jb    db "JB:  1 < 255 (unsigned)  -> Below (JB taken)", 10, 0
    fmt_ja_u  db "Unsigned: 0xFFFFFFFF > 1 -> Above (JA taken)", 10, 0
    fmt_jl_s  db "Signed:   0xFFFFFFFF < 1 -> Less  (JL taken)", 10, 0
    fmt_key   db "Key: Same CMP, different jumps interpret flags differently!", 10, 0

section .text
    global main
    extern printf
    extern ExitProcess

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32              ; shadow space

    ; -------------------------------------------------------
    ; JA: 无符号大于跳转
    ; 比较 255 和 1 (32位): 255 > 1 (无符号), JA 跳转
    ; CMP 计算 EAX - EDX = 255 - 1 = 254, CF=0, ZF=0
    ; JA 条件: CF=0 且 ZF=0 -> 跳转
    ; -------------------------------------------------------
    mov eax, 255
    mov edx, 1
    cmp eax, edx
    ja .ja_taken             ; 无符号: 255 > 1, 跳转
    ; 不会执行到这里
    jmp .after_ja
.ja_taken:
    lea rcx, [fmt_ja]
    call printf
.after_ja:

    ; -------------------------------------------------------
    ; JB: 无符号小于跳转
    ; 比较 1 和 255 (32位): 1 < 255 (无符号), JB 跳转
    ; CMP 计算 1 - 255: 需要借位, CF=1
    ; JB 条件: CF=1 -> 跳转
    ; -------------------------------------------------------
    mov eax, 1
    mov edx, 255
    cmp eax, edx
    jb .jb_taken            ; 无符号: 1 < 255, 跳转
    ; 不会执行到这里
    jmp .after_jb
.jb_taken:
    lea rcx, [fmt_jb]
    call printf
.after_jb:

    ; -------------------------------------------------------
    ; 关键演示: 同一个CMP，不同的跳转指令给出不同结果！
    ;
    ; 0xFFFFFFFF 作为32位值的两种解读:
    ;   无符号: 4294967295 (32位最大无符号数) -> 大于 1
    ;   有符号: -1                                      -> 小于 1
    ;
    ; CMP EAX, EDX 计算 0xFFFFFFFF - 1 = 0xFFFFFFFE:
    ;   CF=0 (无借位, 4294967295 >= 1)
    ;   SF=1, OF=0 (有符号: 结果为负, 无溢出)
    ;
    ; 因此:
    ;   JA (读CF): CF=0 且 ZF=0 -> 跳转 (无符号大于)
    ;   JL (读SF/OF): SF!=OF -> 跳转 (有符号小于)
    ;   两个跳转都会被执行！
    ; -------------------------------------------------------

    ; --- 测试1: JA (无符号) 对 0xFFFFFFFF vs 1 ---
    mov eax, 0xFFFFFFFF       ; 32位: 无符号=4294967295, 有符号=-1
    mov edx, 1
    cmp eax, edx              ; 设置标志位
    ja .unsigned_above        ; 无符号: 4294967295 > 1, 跳转
    ; 会跳转，不会执行到这里
.unsigned_above:
    lea rcx, [fmt_ja_u]
    call printf

    ; --- 测试2: JL (有符号) 对同样的 0xFFFFFFFF vs 1 ---
    ; 注意: 必须重新执行 CMP，因为上面的 printf 调用改变了标志位
    mov eax, 0xFFFFFFFF
    mov edx, 1
    cmp eax, edx              ; 重新设置标志位
    jl .signed_less          ; 有符号: -1 < 1, 跳转
    ; 会跳转，不会执行到这里
.signed_less:
    lea rcx, [fmt_jl_s]
    call printf

    ; --- 打印关键结论 ---
    lea rcx, [fmt_key]
    call printf

    ; --- 退出进程 ---
    xor ecx, ecx             ; exit code = 0
    call ExitProcess
